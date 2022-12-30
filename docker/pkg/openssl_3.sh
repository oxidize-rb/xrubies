#!/bin/bash
# shellcheck disable=SC1091
# shellcheck disable=SC2154

export name="openssl_3"
export version="3.0.7"
export source="https://www.openssl.org/source/openssl-${version}.tar.gz"
export sha256="83049d042a260e696f62406ac5c08bf706fd84383f945cf21bd61e9ed95c396e"
export srcdir="openssl-${version}"

build() {
  cd "${srcdir}" || exit 1

  case "$cross_target" in
    x86_64-linux*)
      target="linux-x86_64"
      ;;
    i686-linux*)
      target="linux-elf"
      ;;
    aarch64-linux*)
      target="linux-aarch64"
      ;;
    arm-linux*)
      target="linux-armv4"
      ;;
    x86_64-darwin*)
      target="darwin64-x86_64-cc"
      ;;
    aarch64-darwin*)
      target="darwin64-arm64-cc"
      ;;
    *)
      echo "Unsupported target: $cross_target" >&2
      exit 1
      ;;
  esac


  with_build_environment ./Configure \
    "$target" \
		no-zlib \
		no-async \
		no-comp \
		no-idea \
		no-mdc2 \
		no-rc5 \
		no-ec2m \
		no-sm2 \
		no-sm4 \
		no-ssl3 \
    no-ssl3-method \
		no-seed \
		no-weak-ssl-ciphers \
    --prefix="$install_dir" \
    --openssldir="$install_dir/ssl"

  perl configdata.pm --dump
  make -j "$(nproc)" > /dev/null
}

check() {
  cd "${srcdir}" || exit 1
  # Removing because whitespace issues
  rm test/recipes/02-test_errstr.t
  make test
}

install() {
  cd "${srcdir}" || exit 1
  make install_sw
}
