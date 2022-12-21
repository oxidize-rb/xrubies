require "json"

namespace(:build) do
  def ruby_build_args(ruby)
    ruby.map { |k, v| "--build-arg RUBY_#{k.upcase}=#{v}" }.join(" ")
  end

  def platform_build_args(platform)
    "--build-arg RUBY_TARGET=#{platform.fetch("slug")} --build-arg RUST_TARGET=#{platform.fetch("rust-target")}"
  end

  def docker_tags(platform_slug, ruby, os_tag)
    [ruby.fetch("version"), ruby.fetch("slug")].map do |ruby_version_tag|
      "ghcr.io/oxidize-rb/xrubies/#{platform_slug}:#{ruby_version_tag}-#{os_tag}"
    end
  end

  RUBY_PLATFORMS.each do |ruby_platform|
    ruby_platform_slug = ruby_platform["slug"]

    ruby_platform.fetch("images").each do |image|
      RUBIES.each do |ruby|
        ruby_platform_slug = ruby_platform.fetch("slug")
        image_slug = image.fetch("slug")

        tags = docker_tags(ruby_platform_slug, ruby, image_slug)
        tags_arg = tags.map { |t| "-t #{t}" }.join(" ")

        desc("Build #{ruby["version"]} for #{ruby_platform_slug} (#{image["slug"]})")
        task([ruby_platform.fetch("slug"), image.fetch("slug"), ruby.fetch("slug")].join(":")) do
          sh(
            <<~CMD
              #{DOCKER_BUILD} \
                --platform=#{image.fetch("docker-platforms").join(",")} \
                #{ruby_build_args(ruby)} \
                #{platform_build_args(ruby_platform)} \
                #{tags_arg} \
                --build-arg BASE_IMAGE_TAG=#{image.fetch("tag")} \
                -f #{ruby_platform["dir"]}/Dockerfile \
                .
            CMD
          )

          GHA.set_output("docker-tags", tags.to_json)
        end
      end
    end
  end
end
