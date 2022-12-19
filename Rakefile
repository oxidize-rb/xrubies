require "yaml"

MATRIX = YAML.load_file("matrix.yml")
RUBY_PLATFORMS = MATRIX.fetch("ruby-platform")
DOCKER_PLATFORMS = MATRIX.fetch("docker-platform")
RUBIES = MATRIX.fetch("ruby")
DOCKER_BUILD = ENV.fetch("DOCKER_BUILD", "docker buildx build --load")
