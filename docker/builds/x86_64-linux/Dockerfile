ARG BASE_IMAGE_TAG

FROM ghcr.io/cross-rs/x86_64-unknown-linux-gnu:$BASE_IMAGE_TAG

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

ENV RUBY_TARGET="x86_64-linux" \
    RUST_TARGET="x86_64-unknown-linux-gnu" \
    DEB_ARCH="amd64"

COPY docker/scripts/build-ruby.sh /
RUN /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --disable-jit-support;

COPY docker/scripts/run-tests.sh test/tests.rb /
RUN /run-tests.sh

