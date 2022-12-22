$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "yaml"
require "xrubies/matrix"

DOCKER_BUILD = ENV.fetch("DOCKER_BUILD", "docker buildx build --load --progress=plain")

task(:fmt) do
  Dir["**/*.rb", "**/*.rake", "Rakefile"].each do |file|
    new_content = `rubyfmt < #{file}`
    File.write(file, new_content)
  end
end
