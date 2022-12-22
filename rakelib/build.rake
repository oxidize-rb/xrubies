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
      "ghcr.io/oxidize-rb/#{platform_slug}:#{ruby_version_tag}-#{os_tag}"
    end
  end

  RUBY_PLATFORMS.each do |ruby_platform|
    ruby_platform_slug = ruby_platform["slug"]

    ruby_platform.fetch("images").each do |image|
      RUBIES.each do |ruby|
        ruby_platform_slug = ruby_platform.fetch("slug")
        os_tag = image.fetch("slug")

        desc("Build #{ruby["version"]} for #{ruby_platform_slug} (#{image["slug"]})")
        task([ruby_platform.fetch("slug"), image.fetch("slug"), ruby.fetch("slug")].join(":")) do
          generate_command = proc do |extra_args = ""|
            <<~CMD
              #{DOCKER_BUILD} \
                --platform=#{image.fetch("docker-platforms").join(",")} \
                #{ruby_build_args(ruby)} \
                #{platform_build_args(ruby_platform)} \
                --build-arg BASE_IMAGE_TAG=#{image.fetch("tag")} \
                -f #{ruby_platform["dir"]}/Dockerfile \
                #{extra_args} \
                .
            CMD
          end

          base_tag = "ghcr.io/oxidize-rb/#{ruby_platform_slug}:base-#{os_tag}"
          sh generate_command.call("--tag #{base_tag} --target base")

          ruby_tags = docker_tags(ruby_platform_slug, ruby, os_tag)
          ruby_tags_arg = ruby_tags.map { |t| "-t #{t}" }.join(" ")
          sh generate_command.call(ruby_tags_arg)

          docker_tags = { "base" => base_tag, "ruby" => ruby_tags, "main" => ruby_tags.first }

          GHA.set_output("docker-tags", docker_tags.to_json)
        end
      end
    end
  end
end
