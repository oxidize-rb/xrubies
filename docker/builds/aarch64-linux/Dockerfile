ARG BASE_IMAGE_TAG
ARG RUST_TARGET
ARG RUBY_VERSION

FROM ghcr.io/oxidize-rb/rubies:$RUBY_VERSION as baseruby
FROM ghcr.io/cross-rs/$RUST_TARGET:$BASE_IMAGE_TAG

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
    RUBY_SHIM_RUNNER="$CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER" \
    DEB_ARCH="arm64"

COPY docker/scripts/build-ruby.sh /
RUN set -ex; \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-baseruby=/baseruby/bin/ruby \
      --disable-jit-support;

COPY docker/scripts/run-tests.sh test/tests.rb /
RUN /run-tests.sh

