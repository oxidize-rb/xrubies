ARG BASE_IMAGE_TAG
ARG RUST_TARGET

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
    TARGET_DEB_ARCH="amd64" \
    FORCE_DISABLE_XRUBIES_PKG_CHECK="$FORCE_DISABLE_XRUBIES_PKG_CHECK" \
    XRUBIES_PKG_ROOT="/tmp/pkg" \
    XRUBIES_CROSS_TARGET="x86_64-linux"

COPY docker/pkg /opt/_internal/pkg
RUN set -ex; \
    /opt/_internal/pkg/install \
        --install-dir /usr/local \
        --cross-target native \
        patchelf;

COPY docker/scripts/helpers.sh /

FROM base as builder

RUN set -ex; \
    /opt/_internal/pkg/install \
      zlib \
      yaml \
      readline \
      libffi \
      openssl && \
    rm -rf /opt/_internal/pkg;

COPY docker/scripts/build-ruby.sh /
RUN /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-openssl-dir="$XRUBIES_PKG_ROOT" \
      --with-zlib-dir="$XRUBIES_PKG_ROOT" \
      --with-libyaml-dir="$XRUBIES_PKG_ROOT" \
      --with-libffi-dir="$XRUBIES_PKG_ROOT" \
      --with-readline-dir="$XRUBIES_PKG_ROOT";

FROM base

COPY --from=base /usr/local/bin/patchelf /usr/local/bin/
COPY --from=builder /opt/xrubies /opt/xrubies

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"

