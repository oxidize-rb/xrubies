ARG BASE_IMAGE_TAG
ARG RUST_TARGET
ARG RUBY_VERSION

FROM ghcr.io/cross-rs/$RUST_TARGET:$BASE_IMAGE_TAG as base

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

ARG RUBY_TARGET
ARG RUST_TARGET

ENV RUBY_TARGET="$RUBY_TARGET" \
    RUST_TARGET="$RUST_TARGET" \
    RUBY_SHIM_RUNNER="$CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER" \
    TARGET_DEB_ARCH="arm64"

COPY docker/scripts/helpers.sh /

FROM base as builder

COPY docker/scripts/build-packages.sh /
COPY docker/scripts/build-ruby.sh /

RUN set -ex; \
    CHOST=aarch64-linux-musl /build-packages.sh zlib; \
    /build-packages.sh openssl_1_1 linux-aarch64; \
    /build-packages.sh yaml --host=aarch64-linux-musl --build=aarch64-linux-musl; \
    /build-packages.sh ffi --host=aarch64-linux-musl --build=aarch64-linux-musl; \
    /build-packages.sh readline --host=aarch64-linux-musl --build=aarch64-linux-musl;


RUN set -ex; \
    PKG_CONFIG_PATH="$(/build-packages.sh --pkgconfig)" \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-openssl-dir=/tmp/pkg/openssl_1_1 \
      --with-zlib-dir=/tmp/pkg/zlib \
      --with-libyaml-dir=/tmp/pkg/yaml \
      --enable-static \
      --disable-jit-support;

FROM base

COPY --from=builder /opt/xrubies /opt/xrubies

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"
