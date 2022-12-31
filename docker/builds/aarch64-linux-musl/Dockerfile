ARG BASE_IMAGE_TAG
ARG RUST_TARGET
ARG RUBY_VERSION

FROM ghcr.io/cross-rs/$RUST_TARGET:$BASE_IMAGE_TAG as base

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

ARG RUBY_TARGET
ARG RUST_TARGET

ARG FORCE_DISABLE_XRUBIES_PKG_CHECK=false

ENV RUBY_TARGET="$RUBY_TARGET" \
    RUST_TARGET="$RUST_TARGET" \
    RUBY_SHIM_RUNNER="$CROSS_TARGET_RUNNER" \
    TARGET_DEB_ARCH="arm64" \
    XRUBIES_CROSS_TARGET="aarch64-linux-musl" \
    XRUBIES_PKG_ROOT="/tmp/pkg" \
    FORCE_DISABLE_XRUBIES_PKG_CHECK="$FORCE_DISABLE_XRUBIES_PKG_CHECK"

COPY docker/pkg/install docker/pkg/patchelf.sh docker/pkg/lib.sh /opt/_internal/pkg/
RUN /opt/_internal/pkg/install --install-dir /usr/local --cross-target native \
        patchelf;

COPY docker/scripts/helpers.sh /

COPY docker/pkg/install docker/pkg/patchelf.sh docker/pkg/lib.sh /opt/_internal/pkg/
RUN set -ex; \
    /opt/_internal/pkg/install \
        --install-dir /usr/local \
        --cross-target native \
        patchelf; \
    rm -rf /opt/_internal/pkg;

FROM base as builder

COPY docker/scripts/build-ruby.sh /
COPY docker/pkg/ /opt/_internal/pkg/

RUN /opt/_internal/pkg/install \
      zlib \
      yaml \
      readline \
      libffi \
      gdbm \
      openssl && \
    ls -R "$XRUBIES_PKG_ROOT";

RUN set -ex; \
    PKG_CONFIG_PATH="$(/opt/_internal/pkg/install --pkgconfig)" \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-openssl-dir="$XRUBIES_PKG_ROOT" \
      --with-zlib-dir="$XRUBIES_PKG_ROOT" \
      --with-libyaml-dir="$XRUBIES_PKG_ROOT" \
      --with-libffi-dir="$XRUBIES_PKG_ROOT" \
      --with-readline-dir="$XRUBIES_PKG_ROOT" \
      --with-gdbm-dir="$XRUBIES_PKG_ROOT" \
      --enable-static;

FROM base

COPY --from=base /usr/local/bin/patchelf /usr/local/bin/
COPY --from=builder /opt/xrubies /opt/xrubies

RUN set -ex; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*;

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"
