ARG BASE_IMAGE_TAG
ARG RUST_TARGET

FROM ghcr.io/oxidize-rb/baseruby:latest as baseruby
FROM ghcr.io/cross-rs/$RUST_TARGET:$BASE_IMAGE_TAG

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

ARG RUBY_TARGET
ARG RUST_TARGET

ENV RUBY_TARGET="$RUBY_TARGET" \
    RUST_TARGET="$RUST_TARGET" \
    DEB_ARCH="arm64"

COPY --from=baseruby /miniruby /miniruby

COPY docker/scripts/build-ruby.sh /
RUN /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-baseruby=/miniruby \
      --disable-jit-support;

RUN rm /miniruby

COPY docker/scripts/run-tests.sh test/tests.rb /
RUN /run-tests.sh

