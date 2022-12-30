ARG BASE_IMAGE_TAG
ARG RUST_TARGET

FROM ghcr.io/cross-rs/$RUST_TARGET:$BASE_IMAGE_TAG as base

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

ARG RUBY_TARGET
ARG RUST_TARGET

ENV RUBY_TARGET="$RUBY_TARGET" \
    RUST_TARGET="$RUST_TARGET" \
    RUBY_SHIM_RUNNER="$CROSS_TARGET_RUNNER" \
    TARGET_DEB_ARCH="amd64" \
    XRUBIES_CROSS_TARGET="x86_64-linux-musl" \
    XRUBIES_PKG_ROOT="/tmp/pkg"

COPY docker/scripts/helpers.sh /

FROM base as builder

COPY docker/scripts/build-ruby.sh /

RUN set -ex; \
    /opt/_internal/pkg/install zlib; \
    /opt/_internal/pkg/install openssl_1_1; \
    /opt/_internal/pkg/install yaml; \
    /opt/_internal/pkg/install readline;

RUN set -ex; \
    PKG_CONFIG_PATH="/tmp/pkg/lib/pkgconfig" \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-openssl-dir=/tmp/pkg \
      --with-zlib-dir=/tmp/pkg \
      --with-yaml-dir=/tmp/pkg \
      --enable-static \
      --disable-jit-support;

FROM base

COPY --from=builder /opt/xrubies /opt/xrubies

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"

