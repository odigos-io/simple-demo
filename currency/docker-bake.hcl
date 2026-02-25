# Currency: build and package targets (use from currency dir: docker buildx bake -f docker-bake.hcl [target])
# Override: docker buildx bake -f docker-bake.hcl --var VERSION=1.0.0 app

variable "VERSION" {
  default = "dev"
}

variable "REGISTRY" {
  default = "registry.odigos.io"
}

variable "IMAGE" {
  default = "currency-package"
}

variable "APP_IMAGE" {
  default = "${REGISTRY}/odigos-demo-currency"
}

# --- Local arch only (default) ---
target "app" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "app"
  tags       = ["${APP_IMAGE}:${VERSION}"]
  output     = ["type=docker"]
}

target "package" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "package"
  tags       = ["${IMAGE}:${VERSION}"]
  args       = { VERSION = VERSION }
  output     = ["type=docker"]
}

# --- Multi-arch (consolidated manifest; run with --push to publish) ---
target "app-all" {
  inherits   = ["app"]
  platforms  = ["linux/amd64", "linux/arm64"]
  tags       = ["${APP_IMAGE}:${VERSION}"]
  output     = ["type=image"]
}

# --- Single-arch app (for build-amd / build-arm) ---
target "app-amd64" {
  inherits  = ["app"]
  platforms = ["linux/amd64"]
}

target "app-arm64" {
  inherits  = ["app"]
  platforms = ["linux/arm64"]
}

# --- Per-platform package images (for extracting artifacts to bin/) ---
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

group "build-all" {
  targets = ["app-amd64", "app-arm64"]
}

group "package-all" {
  targets = ["package-amd64", "package-arm64"]
}
