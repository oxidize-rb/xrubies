# `xrubies`

This repo contains a collection of Rubies compiled for different architectures.
Check out the [releases][releases] page to download the Rubies in tarball form.

### Usage

You can download the tarball and extract it on a Linux machine, docker container, etc.

```dockerfile
FROM buildpack-deps

ARG RUBY_VERSION
ARG RUBY_PLATFORM

ENV \
  RUBY_VERSION=${RUBY_VERSION} \
  RUBY_PLATFORM=${RUBY_PLATFORM} \
  PATH=/opt/xrubies/${RUBY_VERSION}-${RUBY_PLATFORM}/bin:$PATH

RUN apt-get update && apt-get install -y -qq \
  zlib1g-dev \
  libssl-dev \
  libyaml-dev \
  libgdbm-dev \
  libreadline-dev \
  libncurses5-dev;

# Install ruby
RUN curl -Lo /tmp/ruby.tar.gz https://github.com/oxidize-rb/xrubies/releases/download/v0.0.2/${RUBY_VERSION}-${RUBY_PLATFORM}.tar.gz
RUN tar xf /tmp/ruby.tar.gz

# Info
RUN ruby -v && gem -v && bundle -v
```

To build:

```bash
$ docker build --progress=plain --build-arg RUBY_VERSION=3.1.2 --build-arg RUBY_PLATFORM=aarch64-linux .
```

[releases]: https://github.com/oxidize-rb/xrubies/releases
