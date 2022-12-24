#!/bin/bash

set -euo pipefail

XRUBIES_PKG_ROOT="/tmp/pkg"

main() {
  case "$1" in
    openssl_1_1)
      shift
      build_openssl_1_1 "$@"
      ;;
    zlib)
      shift
      build_zlib "$@"
      ;;
    yaml)
      shift
      build_yaml "$@"
      ;;
    ffi)
      shift
      build_ffi "$@"
      ;;
    readline)
      shift
      build_readline "$@"
      ;;
    *)
      echo "Unknown package $1" >&2
      exit 1
      ;;
  esac
}

enter_build_dir() {
    local dir
    dir="$(mktemp -d)"
    mkdir -p "$dir"
    pushd "$dir"
}

download_source() {
    local url="$1"
    local file="$2"
    local sha256="$3"

    if [ -f "$file" ]; then
        echo "File $file already exists, skipping download" >&2
        return
    fi

    echo "Downloading $url to $PWD/$file" >&2
    curl -fsSLo "$file" "$url"
    echo "Verifying checksum of $file" >&2
    echo "$sha256  $file" | sha256sum -c - >&2
}

with_build_env() {
  echo "Running with build env: \"$*\"" >&2

  env \
    CC="${CROSS_TOOLCHAIN_PREFIX}gcc" \
    CFLAGS="${CFLAGS:-} ${CROSS_CMAKE_OBJECT_FLAGS:-}" \
    AR="${CROSS_TOOLCHAIN_PREFIX}ar" \
    CXX="${CROSS_TOOLCHAIN_PREFIX}g++" \
    "$@"
}

build_openssl_1_1() {
  local url="https://www.openssl.org/source/openssl-1.1.1s.tar.gz"
  local sha256="c5ac01e760ee6ff0dab61d6b2bbd30146724d063eb322180c6f18a6f74e4b6aa"
  local file="openssl-1.1.1s.tar.gz"
  local install_dir="$XRUBIES_PKG_ROOT/openssl_1_1"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./Configure no-shared no-async --prefix="$install_dir" --openssldir="$install_dir/openssl_1_1" "$@"

  make -j "$(nproc)"
  make install_sw
  popd
  echo "Built openssl 1.1 to $install_dir" >&2
}

build_zlib() {
  local url="https://zlib.net/zlib-1.2.13.tar.gz"
  local sha256="b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30"
  local file="zlib-1.2.13.tar.gz"
  local install_dir="$XRUBIES_PKG_ROOT/zlib"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./configure --prefix="$install_dir" --shared "$@"

  make -j "$(nproc)"
  make install
  popd
  echo "Built libz to $install_dir" >&2
}

build_yaml() {
  local url="https://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz"
  local sha256="c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4"
  local file="yaml-0.2.5.tar.gz"
  local install_dir="$XRUBIES_PKG_ROOT/yaml"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./configure --prefix="$install_dir" "$@"
  make -j "$(nproc)"
  make install
  popd
  echo "Built libyaml to $install_dir" >&2
}

build_ffi() {
  local url="https://github.com/libffi/libffi/archive/refs/tags/v3.4.4.tar.gz"
  local sha256="d66c56ad259a82cf2a9dfc408b32bf5da52371500b84745f7fb8b645712df676"
  local file="libffi-3.4.4.tar.gz"
  local install_dir="$XRUBIES_PKG_ROOT/ffi"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1
  with_build_env ./configure --prefix="$install_dir" "$@"

  make -j "$(nproc)"
  make install
  popd
  echo "Built libffi to $install_dir" >&2
}

build_readline() {
  local url="https://ftp.gnu.org/gnu/readline/readline-8.2.tar.gz"
  local sha256="3feb7171f16a84ee82ca18a36d7b9be109a52c04f492a053331d7d1095007c35"
  local file="readline-8.2.tar.gz"
  local install_dir="$XRUBIES_PKG_ROOT/readline"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./configure --prefix="$install_dir" --enable-static --enable-shared "$@"
  make -j "$(nproc)"
  make install
  popd
  echo "Built readline to $install_dir" >&2
}

if [ "$1" == '--pkgconfig' ]; then
  dirs="$(find "$XRUBIES_PKG_ROOT" -name 'pkgconfig' -type d)"
  path="$(echo "$dirs" | tr ' ' ':')"

  echo "$path:${PKG_CONFIG_PATH:-}" | tr ':' '\n' | sort -u | tr '\n' ':' | sed 's/:$//'
else
  main "$@"
fi

