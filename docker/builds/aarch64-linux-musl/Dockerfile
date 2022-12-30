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
    RUBY_SHIM_RUNNER="$CROSS_TARGET_RUNNER" \
    TARGET_DEB_ARCH="arm64" \
    XRUBIES_CROSS_TARGET="aarch64-linux-musl" \
    XRUBIES_PKG_ROOT="/tmp/pkg"

COPY docker/scripts/helpers.sh /

FROM base as builder

COPY docker/scripts/build-ruby.sh /
COPY docker/pkg/ /opt/_internal/pkg/

RUN /opt/_internal/pkg/install \
      zlib \
      yaml \
      readline \
      openssl && \
    ls -R "$XRUBIES_PKG_ROOT";

RUN set -ex; \
    PKG_CONFIG_PATH="$(/opt/_internal/pkg/install --pkgconfig)" \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-openssl-dir="$XRUBIES_PKG_ROOT" \
      --with-zlib-dir="$XRUBIES_PKG_ROOT" \
      --with-libyaml-dir="$XRUBIES_PKG_ROOT" \
      --with-readline-dir="$XRUBIES_PKG_ROOT" \
      --enable-static \
      --disable-jit-support;

FROM base

COPY --from=builder /opt/xrubies /opt/xrubies

RUN set -ex; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*;

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"
