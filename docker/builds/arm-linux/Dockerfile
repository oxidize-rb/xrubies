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
    TARGET_DEB_ARCH="arm" \
    XRUBIES_CROSS_TARGET="arm-unknown-linux-gnueabihf" \
    XRUBIES_PKG_ROOT="/tmp/pkg" \
    FORCE_DISABLE_XRUBIES_PKG_CHECK="$FORCE_DISABLE_XRUBIES_PKG_CHECK"

COPY docker/scripts/helpers.sh /
COPY docker/pkg/ /opt/_internal/pkg/

FROM base as builder

COPY docker/scripts/build-ruby.sh /

RUN set -ex; \
    /opt/_internal/pkg/install --install-dir /usr/local --cross-target native \
      patchelf; \
    /opt/_internal/pkg/install \
      zlib \
      yaml \
      readline \
      libffi \
      openssl; \
    export PKG_CONFIG_PATH="$XRUBIES_PKG_ROOT/lib/pkgconfig"; \
    export CFLAGS="${CFLAGS:-} -pthread"; \
    /build-ruby.sh "$RUBY_VERSION" "$RUBY_MINOR" "$RUBY_SHA256" \
      --with-openssl-dir="$XRUBIES_PKG_ROOT" \
      --with-zlib-dir="$XRUBIES_PKG_ROOT" \
      --with-libyaml-dir="$XRUBIES_PKG_ROOT" \
      --with-libffi-dir="$XRUBIES_PKG_ROOT" \
      --with-readline-dir="$XRUBIES_PKG_ROOT"; \
    rm -rf /opt/_internal/pkg /tmp /usr/local/bin/patchelf;

FROM base

ARG RUBY_VERSION
ARG RUBY_MINOR

COPY --from=builder /opt/xrubies /opt/xrubies

ENV RUBY_ROOT="/opt/xrubies/$RUBY_MINOR" \
    GEM_HOME="$RUBY_ROOT/bundle" \
    PATH="$GEM_HOME/bin:$RUBY_ROOT/bin:$PATH" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME" \
    RUBY_VERSION="$RUBY_VERSION"

# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

RUN bash -c "source /helpers.sh && install_persistent_packages ca-certificates"
