#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="gdbm"
export version="1.23"
export source="https://ftp.gnu.org/gnu/$name/$name-$version.tar.gz"
export sha256="74b1081d21fff13ae4bd7c16e5d6e504a4c26f7cde1dca0d963a484174bbcacd"
export srcdir="$name-$version"

build() {
  cd "${srcdir}" || exit 1

  with_build_environment ./configure \
    --host="$cross_target" \
    --build="$cross_target" \
    --prefix="$install_dir" \
    --enable-libgdbm-compat \
    --disable-largefile \
    --disable-dependency-tracking \
    --without-readline \
    --disable-silent-rules \
    --enable-fast-install

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
