# `xrubies`

WIP to make cross-compiling native Ruby gems easier. You can find the [latest builds here][packages].

## Usage

### Just to prove it works

```
$ docker run --rm -it ghcr.io/oxidize-rb/xrubies/aarch64-linux:3.1-ubuntu \
  /opt/xrubies/3.1/bin/ruby -v
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [aarch64-linux-gnu]
```

```sh
docker run --rm -it ghcr.io/oxidize-rb/xrubies/x86_64-linux:3.2-rc1-centos \
  /opt/xrubies/3.2/bin/ruby -v
ruby 3.2.0rc1 (2022-12-06 master 81e274c990) [x86_64-linux-gnu]
```

### Building a custom image

```dockerfile
FROM ghcr.io/oxidize-rb/xrubies/arch64-linux:3.1-ubuntu as ruby-3.1
FROM ghcr.io/oxidize-rb/xrubies/arch64-linux:3.0-ubuntu as ruby-3.0
FROM ghcr.io/oxidize-rb/xrubies/arch64-linux:2.7-ubuntu as ruby-2.7

# Copy the Ruby binaries from the build containers
COPY --from=ruby-3.1 /opt/xrubies/3.1 /opt/xrubies/3.1
COPY --from=ruby-3.0 /opt/xrubies/3.0 /opt/xrubies/3.0
COPY --from=ruby-2.7 /opt/xrubies/2.7 /opt/xrubies/2.7

FROM ghcr.io/oxidize-rb/arch64-linux:ubuntu

# Now you can use the Ruby binaries like normal...
RUN /opt/xrubies/3.1/bin/ruby -v
RUN /opt/xrubies/3.0/bin/ruby -v
RUN /opt/xrubies/2.7/bin/ruby -v
```

## FAQ

### How is this different than `rake-compiler-dock`?

This tool takes a lot of inspiration from `rake-compiler-dock`, but differs in a few key ways.

1. The rubies in this project are blissfully unaware of the host system (i.e.
   `--host` == `--build` == `--target`). Ruby is treated as a "regular", native
   compiled Ruby. This means we never have to fake any values in `RbConfig` or
   `rbconfig.rb`.

2. You can actually execute the Ruby binaries like normal. This means you can
   run `rake test` as you normally would, and it will work. To accomplish this, we
   directly leverage `qemu` to emulate the target architecture.

3. Each version of includes all of the normal extensions (openssl, libyaml,
   etc.) and vendors them so they do not need to be installed on the host system.
   As a side benefit, the compiled Ruby binaries should be shareable if someone
   wants to use another build container.

4. Images are based on the [`cross-rs`][cross-rs] Docker images, which have
   great support for Rust and an huge variety of supported architectures.

5. (Eventually) will have full support for M1 macOS builds, without emulation.
   This means Rust compilation times will be much faster on Apple Silicon.

6. (Eventually) will support the ability the vendor dylibs installed used by
   gems by using. We [already do this for `libruby`][vendor-libs] using patchelf,
   but we can do the same for other gems. This is what
   [`auditwheel`][auditwheel] does for python.

[cross-rs]: https://github.com/cross-rs/cross
[packages]: https://github.com/oxidize-rb/xrubies/packages
[vendor-libs]: https://github.com/oxidize-rb/xrubies/blob/1f5402baa7982d25931183091b9515b20e90c0e7/docker/scripts/build-ruby.sh#L120
[auditwheel]: https://github.com/pypa/auditwheel
