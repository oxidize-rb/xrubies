#!/bin/bash

set -euo pipefail

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
  echo "$install_dir"
}

main() {
  case "$1" in
    openssl_1_1)
      shift
      build_openssl_1_1 "$@"
      ;;
    *)
      echo "Unknown package $1" >&2
      exit 1
      ;;
  esac
}

main "$@"
