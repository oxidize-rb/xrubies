ARG BASE_IMAGE_TAG
ARG RUST_TARGET

FROM ghcr.io/cross-rs/$RUST_TARGET:$BASE_IMAGE_TAG as base

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

ARG RUBY_TARGET
ARG RUST_TARGET

LABEL org.oxidize-rb.ruby.version="$RUBY_VERSION" \
      org.oxidize-rb.ruby.minor="$RUBY_MINOR" \
      org.oxidize-rb.ruby.sha256="$RUBY_SHA256" \
      org.oxidize-rb.ruby.platform="$RUBY_TARGET" \
      org.oxidize-rb.rust.target="$RUST_TARGET"

ENV RUBY_TARGET="$RUBY_TARGET" \
    RUST_TARGET="$RUST_TARGET" \
    RUBY_SHIM_RUNNER="$CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUNNER" \
    DEB_ARCH="amd64"

FROM base as builder

COPY docker/scripts/build-ruby.sh /
RUN /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --disable-jit-support;

FROM base

COPY --from=builder /opt/xrubies /opt/xrubies

ENV PATH="/opt/xrubies/$RUBY_MINOR/bin:$PATH"

