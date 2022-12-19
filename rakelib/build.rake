require "json"

namespace :build do
  def ruby_build_args(ruby)
    ruby.map { |k, v| "--build-arg RUBY_#{k.upcase}=#{v}" }.join(" ")
  end

  def docker_tags(ruby_platform, ruby)
    [
      "ghcr.io/oxidize-rb/xrubies/#{ruby_platform.fetch("slug")}__#{ruby.fetch("version")}",
      "ghcr.io/oxidize-rb/xrubies/#{ruby_platform.fetch("slug")}__#{ruby.fetch("slug")}",
    ]
  end

  RUBY_PLATFORMS.each do |ruby_platform|
    ruby_platform_slug = ruby_platform["slug"]

    ruby_platform.fetch("images").each do |image|
      RUBIES.each do |ruby|
        tags = docker_tags(ruby_platform, ruby)
        tags_arg = tags.map { |t| "-t #{t}" }.join(" ")

        desc "Build #{ruby["version"]} for #{ruby_platform_slug} (#{image["slug"]})"
        task [ruby_platform.fetch("slug"), image.fetch("slug"), ruby.fetch("slug")].join(":") do
          sh <<~CMD
            #{DOCKER_BUILD} \
              --platform=#{image.fetch("docker-platforms").join(",")} \
              #{ruby_build_args(ruby)} \
              #{tags_arg} \
              --build-arg BASE_IMAGE_TAG=#{image.fetch('tag')} \
              -f #{ruby_platform["dir"]}/Dockerfile \
              .
          CMD

          GHA.set_output("docker-tags", tags.to_json)
        end
      end
    end
  end
end

