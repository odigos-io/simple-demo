# Demo meta-package: installs all Odigos demo apps via dependencies.
variable "VERSION" {
  default = "dev"
}

variable "REGISTRY" {
  default = "registry.odigos.io"
}

variable "IMAGE" {
  default = "demo-package"
}

# No app image; this is a meta-package only
target "package" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "package"
  tags       = ["${IMAGE}:${VERSION}"]
  args       = { VERSION = VERSION }
  output     = ["type=docker"]
}

target "package-amd64" {
  inherits   = ["package"]
  platforms  = ["linux/amd64"]
  tags       = ["${IMAGE}:amd64"]
  output     = ["type=docker"]
}

target "package-arm64" {
  inherits   = ["package"]
  platforms  = ["linux/arm64"]
  tags       = ["${IMAGE}:arm64"]
  output     = ["type=docker"]
}

group "package-all" {
  targets = ["package-amd64", "package-arm64"]
}
