// group "default" {
//   targets = ["x", "webapp-dev"]
// }

target "x86_64-linux" {
  dockerfile = "docker/builds/x86_64-linux/Dockerfile"
  tags = ["docker.io/username/webapp"]
}

target "webapp-release" {
  inherits = ["webapp-dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "db" {
  dockerfile = "Dockerfile.db"
  tags = ["docker.io/username/db"]
}
