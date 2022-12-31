#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="yaml"
export version="0.2.5"
export source="https://pyyaml.org/download/libyaml/$name-$version.tar.gz"
export sha256="c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4"
export srcdir="$name-$version"

build() {
  cd "${srcdir}" || exit 1

  with_build_environment \
    ./configure \
      --prefix="$install_dir" \
      --host="$cross_target" \
      --build="$cross_target"

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
