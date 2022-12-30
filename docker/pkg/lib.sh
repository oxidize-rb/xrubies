#!/bin/bash

with_build_environment() {
  log "Running with build env: \"$*\""

  env \
    CC="${CROSS_TOOLCHAIN_PREFIX:-}gcc" \
    CFLAGS="${CFLAGS:-} ${CROSS_CMAKE_OBJECT_FLAGS:-}" \
    AR="${CROSS_TOOLCHAIN_PREFIX:-}ar" \
    CXX="${CROSS_TOOLCHAIN_PREFIX:-}g++" \
    "$@"
}

log() {
  echo "[xrubies] $*" >&2
}
