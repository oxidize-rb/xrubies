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

      File.open(io, "a") { |f| f.write to_write }
    else
      puts "::set-output name=#{key}::#{value}"
    end
  end
end

namespace :github do
  namespace :actions do
    desc "Generate GitHub Actions matrix"
    task :matrix do
      matrix = Rake::Task.tasks.select { |t| t.name.start_with?("build:") }.map do |t|
        { "name" => t.name, "rake-task" => t.name }
      end

     GHA.set_output(:matrix, JSON.dump(include: matrix))
    end

    desc "Simulate GitHub action build locally"
    task :local do
      sh "act push --container-architecture linux/amd64 --rm"
    end
  end
end
