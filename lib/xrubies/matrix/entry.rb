require_relative "entry/image"
require_relative "entry/ruby_platform"
require_relative "entry/ruby_version"

module Xrubies
  class Matrix
    class Entry
      attr_reader :ruby_version, :ruby_platform, :image

      def initialize(ruby_version:, ruby_platform:, image:)
        @ruby_version = ruby_version
        @ruby_platform = ruby_platform
        @image = image
      end

      def to_h
        docker = {
          "tags" => docker_image_names,
          "file" => dockerfile_path,
          "build-args" => docker_build_args,
          "platforms" => image.docker_platforms,
          "labels" => docker_labels,
          "repo" => repo
        }

        {"short-slug" => short_slug, "docker" => docker}
      end

      def description
        "#{ruby_version.version} on #{ruby_platform.slug} on #{image.slug}"
      end

      def short_slug
        "#{ruby_platform.slug}:#{ruby_version.slug}-#{image.slug}"
      end

      def docker_build_args
        {}.merge(ruby_version.docker_build_args, ruby_platform.docker_build_args, image.docker_build_args)
      end

      def ruby_minor
        ruby_version.minor
      end

      def ruby_slug
        ruby_version.slug
      end

      def base_image
        "#{repo}:#{image.slug}"
      end

      def base_tag
        "#{repo}:base-#{image.slug}"
      end

      def docker_image_names
        [docker_image_name_full, docker_image_name_short]
      end

      def docker_image_name_full
        "#{repo}:#{ruby_version.version}-#{image.slug}"
      end

      def docker_image_name_short
        "#{repo}:#{ruby_version.slug}-#{image.slug}"
      end

      def repo
        "ghcr.io/oxidize-rb/#{ruby_platform.slug}"
      end

      def dockerfile_path
        File.join(ruby_platform.dir, "Dockerfile")
      end

      def ruby_platform_slug
        ruby_platform.slug
      end

      def rust_target
        ruby_platform.rust_target
      end

      def base_image_tag
        image.tag
      end

      def docker_labels
        {
          "org.oxidize-rb.ruby.version" => ruby_version.version,
          "org.oxidize-rb.ruby.minor" => ruby_version.minor,
          "org.oxidize-rb.ruby.slug" => ruby_version.slug,
          "org.oxidize-rb.ruby.sha256" => ruby_version.sha256,
          "org.oxidize-rb.ruby.platform" => ruby_platform.slug,
          "org.oxidize-rb.rust.target" => ruby_platform.rust_target
        }
      end
    end
  end
end
