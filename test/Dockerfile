FROM debian:stable

ARG RUBY_VERSION
ARG RUBY_PLATFORM
ARG EXPECTED_RUBY_ARCH
ARG EXPECTED_RUBY_VERSION

ENV \
  RUBY_VERSION=${RUBY_VERSION} \
  RUBY_PLATFORM=${RUBY_PLATFORM} \
  PATH=/opt/xrubies/${RUBY_VERSION}-${RUBY_PLATFORM}/bin:$PATH \
  EXPECTED_RUBY_ARCH=${EXPECTED_RUBY_ARCH} \
  EXPECTED_RUBY_VERSION=${EXPECTED_RUBY_VERSION}

RUN set -ex; \
  apt-get update; \
  apt-get install -y -qq \
  zlib1g-dev \
  libssl-dev \
  libyaml-dev \
  libgdbm-dev \
  libreadline-dev \
  libncurses5-dev;

# Install ruby
ADD tmp/${RUBY_VERSION}-${RUBY_PLATFORM}.tar.gz /

# Info
RUN ruby -v && gem -v && bundle -v

# Tests
RUN gem install minitest nokogiri
ADD test/ test/
RUN ruby test/tests.rb