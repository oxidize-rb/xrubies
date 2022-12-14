require "json"
require "securerandom"

module GHA
  extend self

  def set_output(key, value)
    if ENV["GITHUB_OUTPUT"]
      eol = $/
      delimiter = "ghadelimiter_#{SecureRandom.uuid}"
      to_write = "#{key}<<#{delimiter}#{eol}#{value}#{eol}#{delimiter}#{eol}"
      io = ENV.fetch("GITHUB_OUTPUT")

      File.open(io, "a") { |f| f.write(to_write) }
    else
      puts("::set-output name=#{key}::#{value}")
    end
  end
end

namespace(:github) do
  namespace(:actions) do
    desc("Generate GitHub Actions matrix")
    task(:matrix) do
      matrix = Xrubies::Matrix.new.map do |entry|
        entry.to_h
      end

      GHA.set_output(:matrix, JSON.dump(include: matrix))
    end

    desc("Generate GitHub Actions matrix for a specific Ruby platform (include multiple Ruby versions)")
    task(:platform_matrix) do
      matrix = Xrubies::Matrix.new.group_by(&:ruby_platform_slug).map do |ruby_platform_slug, entries|
        xrubies = entries.map do |entry|
          {"ruby-minor" => entry.ruby_minor, "docker-image" => entry.docker_image_name_full}
        end

        {"ruby-platform" => ruby_platform_slug, "xrubies" => xrubies}
      end

      GHA.set_output(:matrix, JSON.dump(include: matrix))
    end

    desc("Simulate GitHub action build locally")
    task(:act, [:workflow]) do |t, args|
      require "rbconfig"

      arch = RbConfig::CONFIG["host_cpu"] == "x86_64" ? "linux/amd64" : "linux/arm64"
      sh("act push --container-architecture #{arch} --rm --workflows .github/workflows/#{args[:workflow]}.yml")
    end
  end
end
