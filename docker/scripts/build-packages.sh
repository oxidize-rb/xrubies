#!/bin/bash

set -euo pipefail

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
  env \
    CC="${CROSS_TOOLCHAIN_PREFIX}gcc" \
    AR="${CROSS_TOOLCHAIN_PREFIX}ar" \
    CXX="${CROSS_TOOLCHAIN_PREFIX}g++" \
    "$@"
}

build_openssl_1_1() {
  local url="https://www.openssl.org/source/openssl-1.1.1s.tar.gz"
  local sha256="c5ac01e760ee6ff0dab61d6b2bbd30146724d063eb322180c6f18a6f74e4b6aa"
  local file="openssl-1.1.1s.tar.gz"
  local install_dir="/tmp/pkg"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./Configure no-shared no-async --prefix="$install_dir" --openssldir="$install_dir/openssl_1_1" "$@"

  make
  make install_sw
  popd
  echo "Built openssl 1.1 to $install_dir" >&2
}

build_zlib() {
  local url="https://zlib.net/zlib-1.2.13.tar.gz"
  local sha256="b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30"
  local file="zlib-1.2.13.tar.gz"
  local install_dir="/tmp/pkg"

  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./configure --prefix="$install_dir" "$@"

  make
  make install
  popd
  echo "Built libz to $install_dir" >&2
}

build_yaml() {
  local url="https://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz"
  local sha256="c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4"
  local file="yaml-0.2.5.tar.gz"

  local install_dir="/tmp/pkg"
  enter_build_dir
  download_source "$url" "$file" "$sha256"
  tar -xf "$file" --strip-components=1

  with_build_env ./configure --prefix="$install_dir" "$@"
  make
  make install
  popd
  echo "Built libyaml to $install_dir" >&2
}

main "$@"
