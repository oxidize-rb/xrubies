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

    namespace ruby_platform_slug do
      RUBIES.each do |ruby|
        DOCKER_PLATFORMS.each do |docker_platform|
          cross_deb_arch = docker_platform.fetch('slug')
          tags = docker_tags(ruby_platform, ruby)
          tags_arg = tags.map { |t| "-t #{t}" }.join(" ")

          desc "Build #{ruby["version"]} for #{ruby_platform_slug}"
          task [ruby["slug"], cross_deb_arch].join(":") do
            sh <<~CMD
              #{DOCKER_BUILD} \
                --platform=#{docker_platform.fetch('id')} \
                #{ruby_build_args(ruby)} \
                #{tags_arg} \
                --build-arg CROSS_DEB_ARCH=#{cross_deb_arch} \
                -f #{ruby_platform["dir"]}/Dockerfile \
                .
            CMD

            GHA.set_output("docker-tags", tags.to_json)
          end
        end
      end
    end
  end
end

