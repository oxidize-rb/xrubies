#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="readline"
export version="8.2"
export source="https://ftp.gnu.org/gnu/readline/$name-$version.tar.gz"
export sha256="3feb7171f16a84ee82ca18a36d7b9be109a52c04f492a053331d7d1095007c35"
export srcdir="$name-$version"

build() {
  cd "${srcdir}" || exit 1

  with_build_environment \
    ./configure \
      --prefix="$install_dir" \
      --host="$cross_target" \
      --build="$cross_target" \
      --enable-static \
      --enable-shared

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
