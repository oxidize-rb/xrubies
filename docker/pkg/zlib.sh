#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="zlib"
export version="1.2.13"
export source="https://zlib.net/zlib-$version.tar.gz"
export sha256="b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30"
export srcdir="zlib-$version"

build() {
  cd "${srcdir}" || exit 1

  CHOST="$cross_target" with_build_environment \
    ./configure \
      --prefix="$install_dir" \
      --shared

  make -j "$(nproc)" > /dev/null
}

install() {
  cd "${srcdir}" || exit 1

  make install > /dev/null
}
