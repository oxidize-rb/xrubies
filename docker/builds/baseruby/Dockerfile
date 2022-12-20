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
  ./configure --prefix=/opt/rubies/baseruby --disable-install-doc --disable-install-rdoc --disable-install-capi --with-ext=monitor --disable-jit-support --disable-install-static-librar --disable-shared --disable-dln; \
  make -j "$(nproc)" install;

FROM scratch

COPY --from=builder /opt/rubies/baseruby /opt/rubies/baseruby
