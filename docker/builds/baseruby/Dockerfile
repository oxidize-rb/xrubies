FROM buildpack-deps as ruby-3.1

ARG RUBY_VERSION="3.1.3"
ARG RUBY_MINOR="3.1"
ARG RUBY_SHA256="5ea498a35f4cd15875200a52dde42b6eb179e1264e17d78732c3a57cd1c6ab9e"

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
  LDFLAGS=-pipe ./configure --prefix=/opt/rubies/$RUBY_MINOR --disable-install-doc --disable-install-rdoc --disable-install-capi --with-static-linked-ext --disable-jit-support --disable-shared; \
  make -j "$(nproc)" install; \
  /vendor-libs.sh /opt/rubies/$RUBY_MINOR; \
  apt-get --purge autoremove -y -qq patchelf libffi-dev libgdbm-dev libgmp-dev libncurses5-dev libreadline-dev libssl-dev libyaml-dev zlib1g-dev; \
  rm -rf /usr/src/ruby /opt/rubies/$RUBY_MINOR/share /var/apt/lists/*;

FROM scratch

COPY --from=ruby-3.1 /opt/rubies/3.1  /opt/rubies/3.1
