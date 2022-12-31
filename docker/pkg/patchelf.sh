#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="patchelf"
export version="0.17.0"

case "$cross_target" in
  x86_64*)
    export sha256="f569b8d5868a5968012d7ff80eb5ca496d6308c481089e6b103855f162080164"
    pkg_arch="x86_64"
    ;;
  aarch64*)
    export sha256="78bcba9452d4f9cd8162ea0acdffd67073c3ded331fc8ca81196a88017cfd214"
    pkg_arch="aarch64"
    ;;
  *)
    abort "Unsupported target: $cross_target"
    ;;
esac

export source="https://github.com/NixOS/patchelf/releases/download/$version/$name-$version-$pkg_arch.tar.gz"
export srcdir="$name-$version-$pkg_arch"

build() {
  chmod +x ./bin/patchelf
}

check() {
  ./bin/patchelf --version
}

install() {
  cp bin/patchelf "$install_dir/bin/patchelf"
}
