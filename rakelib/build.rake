require "json"

namespace(:build) do
  def ruby_build_args(ruby)
    ruby.map { |k, v| "--build-arg RUBY_#{k.upcase}=#{v}" }.join(" ")
  end

  def platform_build_args(platform)
    "--build-arg RUBY_TARGET=#{platform.fetch("slug")} --build-arg RUST_TARGET=#{platform.fetch("rust-target")}"
  end

  def docker_tags(repo, ruby, os_tag)
    [ruby.fetch("version"), ruby.fetch("slug")].map do |ruby_version_tag|
      "#{repo}:#{ruby_version_tag}-#{os_tag}"
    end
  end

  def docker_extra_labels_from_environment
    return unless ENV["DOCKER_EXTRA_LABELS_JSON"]

    labels = JSON.parse(ENV["DOCKER_EXTRA_LABELS_JSON"])
    labels_value = labels.map { |k, v| "#{k}=#{v}" }.join(",")
    "--label #{labels_value}"
  end

  def docker_repo(platform_slug)
    "ghcr.io/oxidize-rb/#{platform_slug}"
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
                #{docker_extra_labels_from_environment} \
                --build-arg BASE_IMAGE_TAG=#{image.fetch("tag")} \
                -f #{File.join(ruby_platform["dir"]}, "Dockerfile")} \
                #{extra_args} \
                .
            CMD
          end

          repo = docker_repo(ruby_platform_slug)
          base_tag = "#{repo}:base-#{os_tag}"
          sh generate_command.call("--tag #{base_tag} --target base")

          ruby_tags = docker_tags(repo, ruby, os_tag)
          ruby_tags_arg = ruby_tags.map { |t| "-t #{t}" }.join(" ")
          sh generate_command.call(ruby_tags_arg)

          docker_tags = {
            "base" => base_tag,
            "ruby" => ruby_tags,
            "main" => ruby_tags.first,
            "repo" => repo
          }

          GHA.set_output("docker-tags", docker_tags.to_json)
        end
      end
    end
  end
end
