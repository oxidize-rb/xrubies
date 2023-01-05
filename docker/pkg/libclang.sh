#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="libclang"
export version="14.0.6"

case "$cross_target" in
  x86_64*)
    export sha256="83322ab57db18f3dc306a0b15f95fed3728250430b4de433c1a871cb61b51e64"
    pkg_arch="x86_64-linux"
    ;;
  aarch64*)
    export sha256="7e3d975f75caf0f6cf5d2bf1f631a95b80382d073784ed52c04bb0cab7d37ab0"
    pkg_arch="aarch64-linux"
    ;;
  *)
    abort "Unsupported target: $cross_target"
    ;;
esac

export source="https://rubygems.org/downloads/libclang-$version-$pkg_arch.gem"
export srcdir="$name-$version-$pkg_arch"

build() {
  tar -xzf data.tar.gz
}

check() {
  test -f vendor/lib/libclang.so
}

install() {
  for lib in vendor/lib/*; do
    cp "$lib" "$install_dir/lib"
  done
}
