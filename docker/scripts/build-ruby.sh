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
        --disable-install-doc \
        --enable-shared \
        --enable-install-static-library \
        "$@" \
      || (cat config.log && false)
}


install() {
  echo "Installing ruby" >&2
  make V=1 -j "$(nproc)" install
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
  local cpu_type

  if [ "$DEB_ARCH" = "arm64" ]; then
    cpu_type="aarch64"
  elif [ "$DEB_ARCH" = "amd64" ]; then
    cpu_type="x86_64"
  else
    echo "Unsupported architecture: $DEB_ARCH" >&2
    exit 1
  fi

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
  ruby_libs="$(find "$ruby_install_dir" -type f -name '*.so')"
  libs_to_patch="$ruby_main $ruby_libs"

  mkdir -p "$ruby_install_dir/vendor/lib"

  needed=()

  for lib in ${libs_to_patch}; do
    echo "Checking $lib with patchelf" >&2
    for dep in $(patchelf --print-needed "$lib" | grep -E '(libffi|libnurses|libreadline|libsqlite|libssl|libyaml|libz|libcrypto|libcrypt)'); do
      found="$(ldd "$lib" | grep "$dep" | cut -f 3 -d ' ' || find /usr/lib/"$("${CROSS_TOOLCHAIN_PREFIX}"gcc -dumpmachine)" -name "$dep" || find /usr/lib -name "$dep")"
      needed+=("$found")
    done
  done

  for lib in "${needed[@]}"; do
    if [ ! -f "$ruby_install_dir/vendor/lib/$lib" ]; then
      echo "Vendoring $lib" >&2
      cp -v "$lib" "$ruby_install_dir/vendor/lib"
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


  patchelf --set-rpath "\$ORIGIN/../lib:$(patchelf --print-rpath "$ruby_install_dir/bin/ruby")" "$ruby_install_dir/bin/ruby";

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
