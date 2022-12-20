FROM buildpack-deps as ruby

ARG RUBY_VERSION
ARG RUBY_MINOR
ARG RUBY_SHA256

LABEL org.oxidize-rb.ruby.version="$RUBY_VERSION" \
      org.oxidize-rb.ruby.minor="$RUBY_MINOR" \
      org.oxidize-rb.ruby.sha256="$RUBY_SHA256"

COPY vendor-libs.sh /

RUN set -ex; \
  curl -fsSL -o ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/$RUBY_MINOR/ruby-$RUBY_VERSION.tar.gz"; \
  echo "$RUBY_SHA256 *ruby.tar.gz" | sha256sum -c -; \
  mkdir -p /usr/src/ruby; \
  tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1; \
  rm ruby.tar.gz; \
  cd /usr/src/ruby; \
  apt-get update -y -qq; \
  apt-get install -y -qq \
    patchelf \
    libffi-dev \
    libgdbm-dev \
    libgmp-dev \
    libncurses5-dev \
    libreadline-dev \
    libssl-dev \
    libyaml-dev \
    zlib1g-dev; \
  ./autogen.sh; \
  LDFLAGS=-pipe ./configure --prefix=/opt/rubies/baseruby --disable-install-doc --disable-install-rdoc --disable-install-capi --with-static-linked-ext --disable-jit-support --disable-shared; \
  make -j "$(nproc)" install; \
  /vendor-libs.sh /opt/rubies/baseruby; \
  apt-get --purge autoremove -y -qq patchelf libffi-dev libgdbm-dev libgmp-dev libncurses5-dev libreadline-dev libssl-dev libyaml-dev zlib1g-dev; \
  rm -rf /usr/src/ruby /opt/rubies/baseruby/share /var/apt/lists/*;

FROM scratch

COPY --from=ruby /opt/rubies/baseruby  /
