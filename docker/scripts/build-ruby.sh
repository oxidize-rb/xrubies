#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source /helpers.sh

download_ruby() {
  local ruby_version="$1"
  local ruby_minor="$2"
  local ruby_sha256="$3"
  mkdir -p src
  curl --retry 5 -fsSL "https://cache.ruby-lang.org/pub/ruby/$ruby_minor/ruby-$ruby_version.tar.gz" -o ruby.tar.gz
  echo "$ruby_sha256 *ruby.tar.gz" | sha256sum --check --strict
  tar -xf ruby.tar.gz -C "$PWD/src" --strip-components=1
  cd src
}

configure() {
  echo "Configuring ruby" >&2
  local ruby_install_dir="$1"
  shift

  autoreconf
  local ruby_cc
  local archdir

  ruby_cc="${CROSS_TOOLCHAIN_PREFIX}gcc"
  archdir="$($ruby_cc -dumpmachine)"


  # Omitting the following flags:
  #   1. no-omit-frame-pointer:
  #   2. no-strict-aliasing: can have large negative impacts on loop
  #      vectorization, if you are relying on it, ideally you can fix the code to
  #      avoid aliasing. If you can't fix the code, you can use the
  #      -fno-strict-aliasing flag to disable strict aliasing for the your
  #      gem.
  env
    CC="$ruby_cc" \
    CXX="${CROSS_TOOLCHAIN_PREFIX}g++" \
    AR="${CROSS_TOOLCHAIN_PREFIX}ar" \
    CFLAGS="${CFLAGS:-} ${CROSS_CMAKE_OBJECT_FLAGS:-} -fno-fast-math -fstack-protector-strong -O3" \
    CPPFLAGS="${CPPFLAGS:-} ${CROSS_CMAKE_OBJECT_FLAGS:-} -fno-fast-math -fstack-protector-strong -O3" \
    LDFLAGS="-pipe" \
      ./configure \
        --prefix="$ruby_install_dir" \
        --target="$RUBY_TARGET" \
        --build="$RUBY_TARGET" \
        --host="$RUBY_TARGET" \
        --with-opt-dir="${CROSS_SYSROOT:-/usr/lib/$archdir}" \
        --disable-install-doc \
        --enable-shared \
        --enable-install-static-library \
        --disable-jit-support \
        "$@" \
      || (cat config.log && false)

  echo "Configuring ruby done" >&2
}

install() {
  echo "Installing ruby" >&2

  if make -j "$(nproc)" install; then
    echo "Successfully installed Ruby" >&2
  else
    echo "Ruby install failed, printing mkmf.log files" >&2

    # shellcheck disable=SC2044
    for f in $(find ./ext -name mkmf.log); do
      echo "========== $f ==========" >&2
      cat "$f"
    done

    exit 1
  fi
}

install_shim() {
  echo "Installing shim for xruby" >&2

  local ruby_install_dir="$1"

  mv "$ruby_install_dir"/bin/ruby "$ruby_install_dir"/bin/__realruby

  cat <<EOF > "$ruby_install_dir"/bin/ruby
#!/bin/sh

# This is an auto-generated shim for the ruby executable allows Ruby to be run
# in a on various CPU architectures.

exec $RUBY_SHIM_RUNNER $ruby_install_dir/bin/__realruby "\$@"
EOF

  chmod +x "$ruby_install_dir"/bin/ruby
  "$ruby_install_dir"/bin/ruby -v
}

find_lib() {
  local dir="$1"
  local name
  name="$(basename "$2")"

  lib_path="$(find "$dir" -name "$name" | grep "." | head -n 1)"

  if [[ -z "$lib_path" ]]; then
    echo "Could not find $lib in $ruby_install_dir" >&2
    false
  else
    echo "$lib_path"
  fi
}

vendor_libs() {
  echo "Copying all the libraries into the vendor directory" >&2;
  local ruby_install_dir="$1"

  mkdir -p "$ruby_install_dir"/vendor/lib
  ruby_main="$ruby_install_dir/bin/ruby"
  libs_to_patch="$(find "$ruby_install_dir" -name '*.so')"

  mkdir -p "$ruby_install_dir/vendor/lib"

  needed=()

  for lib_or_libsymlink in ${libs_to_patch}; do
    lib="$(readlink -f "$lib_or_libsymlink")"
    echo "Checking $lib with patchelf" >&2
    for dep in $(patchelf --print-needed "$lib" | grep -E '(libffi|libnurses|libreadline|libsqlite|libssl|libyaml|libz|libcrypto|libcrypt)'); do
      found="$(ldd "$lib" | grep "$dep" | cut -f 3 -d ' ' || find_lib "$CROSS_SYSROOT" "$dep" || find_lib /usr/lib/"$("${CROSS_TOOLCHAIN_PREFIX}"gcc -dumpmachine)" "$dep" || find_lib "${XRUBIES_PKG_ROOT:-/tmp/pkg/}" "$dep" || find_lib /usr/lib "$dep")"
      needed+=("$found")
    done
  done

  for lib in "${needed[@]}"; do
    basename="$(basename "$lib")"

    if [ -z "$basename" ]; then
      continue
    fi

    if [ ! -f "$ruby_install_dir/vendor/lib/$basename" ]; then
      echo "Vendoring $basename" >&2
      # Copy, but actually write the file to disk aka no symlinks
      cp -Lv "$lib" "$ruby_install_dir/vendor/lib"
    fi
  done

  echo "Patching rpath bundled gem dylibs" >&2
  for lib in $libs_to_patch; do
    relative_path_to_vendor_lib="$(realpath --relative-to="$(dirname "$lib")" "$ruby_install_dir"/vendor/lib)"
    patchelf --set-rpath "\$ORIGIN/$relative_path_to_vendor_lib:$(patchelf --print-rpath "$lib")" "$lib"
  done

  echo "Patching rpath of all vendored libs" >&2
  for lib in "$ruby_install_dir"/vendor/lib/*; do
    echo "Patching $lib" >&2
    patchelf --set-rpath "\$ORIGIN:$(patchelf --print-rpath "$lib")" "$lib"
  done

  patchelf --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../vendor/lib:$(patchelf --print-rpath "$ruby_install_dir/bin/ruby")" "$ruby_main";

}

shrink_rpaths() {
  local ruby_install_dir
  local ruby_main
  local dylibs
  local libs_to_patch

  echo "Shrinking rpaths" >&2

  ruby_install_dir="$1"
  ruby_main="$ruby_install_dir/bin/__realruby"
  dylibs="$(find "$ruby_install_dir" -name '*.so')"

  for lib in $dylibs; do
    echo "Shrinking rpath of $lib" >&2
    patchelf --shrink-rpath "$lib"
  done

  echo "Shrinking rpath of $ruby_install_dir/bin/ruby" >&2
  patchelf --shrink-rpath "$ruby_main"

  echo "Final rpath of ruby bin: $(patchelf --print-rpath "$ruby_main")" >&2
  echo "Final rpath of ruby libs: $(patchelf --print-rpath "$ruby_install_dir/lib/libruby.so")" >&2
  echo "Listing contents of vendor/lib" >&2
  ls -l "$ruby_install_dir/vendor/lib" >&2
}

main() {
  build_dir="$(mktemp -d)"
  cd "$build_dir"

  local ruby_version="$1"
  local ruby_minor="$2"
  local ruby_sha256="$3"
  shift; shift; shift

  local ruby_install_dir="/opt/xrubies/$ruby_minor"

  download_ruby "$ruby_version" "$ruby_minor" "$ruby_sha256"
  configure "$ruby_install_dir" "$@"
  install
  vendor_libs "$ruby_install_dir"
  cd /
  install_shim "$ruby_install_dir"
  purge_packages
  shrink_rpaths "$ruby_install_dir" || true

  rm -rf "$build_dir" "${0}"
}

main "$@"
