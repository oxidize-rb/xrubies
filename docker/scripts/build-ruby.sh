#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source /lib.sh

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

install_deps() {
  if_centos install_packages \
    zlib-devel \
    readline-devel \
    sqlite-devel \
    openssl-devel \
    libyaml-devel \
    libffi-devel \
    gdbm-devel \
    ncurses-devel

  if_ubuntu dpkg --add-architecture "$DEB_ARCH"

  if_ubuntu install_packages \
    zlib1g-dev:"$DEB_ARCH" \
    libreadline-dev:"$DEB_ARCH" \
    libsqlite0-dev:"$DEB_ARCH" \
    libssl-dev:"$DEB_ARCH" \
    libyaml-dev:"$DEB_ARCH" \
    libffi-dev:"$DEB_ARCH" \
    libgdbm-dev:"$DEB_ARCH" \
    libncurses5-dev:"$DEB_ARCH"
}

configure() {
  echo "Configuring ruby" >&2
  local ruby_install_dir="$1"
  shift

  autoreconf

  env
    CC="${CROSS_TOOLCHAIN_PREFIX}gcc" \
    CXX="${CROSS_TOOLCHAIN_PREFIX}g++" \
    AR="${CROSS_TOOLCHAIN_PREFIX}ar" \
    CFLAGS="-fno-omit-frame-pointer -fno-fast-math -fstack-protector-strong" \
    LDFLAGS="-pipe" \
      ./configure \
        --prefix="$ruby_install_dir" \
        --target="$RUBY_TARGET" \
        --build="$RUBY_TARGET" \
        --host="$RUBY_TARGET" \
        --with-opt-dir="/usr/lib/$("${CROSS_TOOLCHAIN_PREFIX}"gcc -dumpmachine)" \
        --disable-install-doc \
        --enable-shared \
        --enable-install-static-library \
        "$@" \
      || (cat config.log && false)
}w


install() {
  echo "Installing ruby" >&2
  make -j "$(nproc)" install
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

install_patchelf() {
  local td
  td="$(mktemp -d)"
  local cpu_type="$(uname -m)"


  echo "Installing patchelf for $cpu_type" >&2

  local url
  url="https://github.com/NixOS/patchelf/releases/download/0.17.0/patchelf-0.17.0-$cpu_type.tar.gz"
  curl -fsSL "$url" | tar -xz -C "$td"


  mv "$td/bin/patchelf" /usr/local/bin
  rm -rf "$td"
  echo "Installed patchelf: $(patchelf --version)" >&2
}

vendor_libs() {
  echo "Copying all the libraries into the vendor directory" >&2;
  local ruby_install_dir="$1"
  install_patchelf

  mkdir -p "$ruby_install_dir"/vendor/lib
  ruby_main="$ruby_install_dir/bin/ruby"
  libs_to_patch="$(find "$ruby_install_dir" -name '*.so')"

  mkdir -p "$ruby_install_dir/vendor/lib"

  needed=()

  for lib_or_libsymlink in ${libs_to_patch}; do
    lib="$(readlink -f "$lib_or_libsymlink")"
    echo "Checking $lib with patchelf" >&2
    for dep in $(patchelf --print-needed "$lib" | grep -E '(libffi|libnurses|libreadline|libsqlite|libssl|libyaml|libz|libcrypto|libcrypt)'); do
      found="$(ldd "$lib" | grep "$dep" | cut -f 3 -d ' ' || find /usr/lib/"$("${CROSS_TOOLCHAIN_PREFIX}"gcc -dumpmachine)" -name "$dep" || find /usr/lib -name "$dep")"
      needed+=("$found")
    done
  done

  for lib in "${needed[@]}"; do
    basename="$(basename "$lib")"
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

  patchelf --set-rpath "\$ORIGIN/../lib:$(patchelf --print-rpath "$ruby_install_dir/bin/ruby")" "$ruby_main";

  echo "Final rpath of ruby bin: $(patchelf --print-rpath "$ruby_install_dir/bin/ruby")" >&2
  echo "Final rpath of ruby libs: $(patchelf --print-rpath "$ruby_install_dir/lib/libruby.so")" >&2
  echo "Listing contents of vendor/lib" >&2
  ls -l "$ruby_install_dir/vendor/lib" >&2

  rm /usr/local/bin/patchelf
}

main() {
  build_dir="$(mktemp -d)"
  cd "$build_dir"

  local ruby_version="$1"
  local ruby_minor="$2"
  local ruby_sha256="$3"
  shift; shift; shift

  local ruby_install_dir="/opt/xrubies/$ruby_minor"

  if [ ! -d "$ruby_install_dir" ]; then
    download_ruby "$ruby_version" "$ruby_minor" "$ruby_sha256"
    install_deps
    configure "$ruby_install_dir" "$@"
    install
  fi

  if [ "${DOCKER_CHECKPOINT:-false}" == "true" ]; then
    echo "Checkpointing ruby build" >&2
    exit 0
  fi

  vendor_libs "$ruby_install_dir"
  cd /
  install_shim "$ruby_install_dir"
  purge_packages

  rm -rf "$build_dir" "${0}"
}

main "$@"
