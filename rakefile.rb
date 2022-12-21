require "yaml"

MATRIX = YAML.load_file("matrix.yml")
RUBY_PLATFORMS = MATRIX.fetch("ruby-platform")
RUBIES = MATRIX.fetch("ruby")
DOCKER_BUILD = ENV.fetch("DOCKER_BUILD", "docker buildx build --load --progress=plain")

task(:fmt) do
  Dir["**/*.rb", "**/*.rake", "Rakefile"].each do |file|
    new_content = `rubyfmt < #{file}`
    File.write(file, new_content)
  end
end
