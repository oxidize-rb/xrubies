#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="libffi"
export version="3.2.1"
export source="https://ftp.osuosl.org/pub/blfs/conglomeration/libffi/$name-$version.tar.gz"
export sha256="d06ebb8e1d9a22d19e38d63fdb83954253f39bedc5d46232a05645685722ca37"
export srcdir="$name-$version"

build() {
  cd "${srcdir}" || exit 1

  with_build_environment ./configure \
    --host="$cross_target" \
    --build="$cross_target" \
    --prefix="$install_dir"

  make -j "$(nproc)" > /dev/null
}

check() {
  cd "${srcdir}" || exit 1

  make check
}

install() {
  cd "${srcdir}" || exit 1

  make install > /dev/null
}
