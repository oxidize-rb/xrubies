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
    RUBY_SHIM_RUNNER="$CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUNNER" \
    TARGET_DEB_ARCH="amd64"

COPY docker/scripts/helpers.sh /

FROM base as builder

COPY docker/scripts/build-packages.sh /
COPY docker/scripts/build-ruby.sh /

RUN set -ex; \
    /build-packages.sh openssl_1_1 linux-x86_64; \
    CHOST=x86_64-linux-musl /build-packages.sh zlib; \
    /build-packages.sh yaml --host x86_64-linux-musl; \
    rm /build-packages.sh;

RUN set -ex; \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --enable-static \
      --disable-jit-support;

FROM base

COPY --from=builder /opt/xrubies /opt/xrubies

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"

