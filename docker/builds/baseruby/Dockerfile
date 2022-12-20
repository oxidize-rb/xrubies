FROM buildpack-deps as builder

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

RUN set -ex; \
  curl -fsSL -o ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/$RUBY_MINOR/ruby-$RUBY_VERSION.tar.gz"; \
  echo "$RUBY_SHA256 *ruby.tar.gz" | sha256sum -c -; \
  mkdir -p /usr/src/ruby; \
  tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1; \
  rm ruby.tar.gz; \
  cd /usr/src/ruby; \
  ./autogen.sh; \
  CFLAGS=-O1 LDFLAGS=-pipe ./configure --prefix=/opt/rubies/baseruby --disable-rubygems --disable-install-doc --disable-install-rdoc --disable-install-capi --with-ext=monitor,digest --with-static-linked-ext --disable-jit-support --disable-shared --disable-dln; \
  make -j "$(nproc)" miniruby;

FROM scratch

COPY --from=builder /usr/src/ruby/miniruby /miniruby
