APP_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BIN_DIR    := $(APP_DIR)bin
TAG        ?= v0.0.0
REGISTRY   ?= registry.odigos.io
IMAGE      := coupon-package
APP_IMAGE  := $(REGISTRY)/odigos-demo-coupon
PKG_NAME   := odigos-demo-coupon

# Local arch only (override with ARCH=amd64 or ARCH=arm64)
ARCH ?= $(shell uname -m)
BUILD_ARCH := $(if $(filter x86_64 amd64,$(ARCH)),amd,arm)
PACKAGE_ARCH := $(BUILD_ARCH)

.PHONY: package clean build build-all build-amd build-arm package-amd package-arm install install-apt install-yum uninstall uninstall-apt uninstall-yum

# Build runtime image for local arch only
build: build-$(BUILD_ARCH)
	@:

# build-all: multi-arch image with correct manifest (docker-container driver); set PUSH=1 to push to REGISTRY.
# Always loads the local arch into the Docker daemon so the image appears in docker images.
build-all:
	@docker buildx create --driver docker-container --name multibuilder --use 2>/dev/null || true; \
	cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl \
		$(if $(filter 1 true yes,$(PUSH)),--set "app-all.output=type=registry" --push,) \
		app-all; \
	cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl app-$(BUILD_ARCH)64
	@echo "Created image: $(APP_IMAGE):$(TAG) (multi-arch, local arch loaded)"

# build-amd / build-arm: single-arch app image
build-amd:
	@cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl app-amd64
	@echo "Created image: $(APP_IMAGE):$(TAG) (amd64)"

build-arm:
	@cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl app-arm64
	@echo "Created image: $(APP_IMAGE):$(TAG) (arm64)"

# Package for local arch only
package: package-$(PACKAGE_ARCH)
	@:

# package-all: both architectures (for release)
package-all:
	@cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl --set "*.args.VERSION=$(TAG)" package-all; \
	mkdir -p $(BIN_DIR); \
	cid=$$(docker create $(IMAGE):amd64); docker cp $$cid:/packages/. $(BIN_DIR)/; docker rm $$cid; \
	cid=$$(docker create $(IMAGE):arm64); docker cp $$cid:/packages/. $(BIN_DIR)/; docker rm $$cid; \
	chown -R $$(id -u):$$(id -g) $(BIN_DIR)

# package-amd / package-arm: single-arch (bake one target, then copy)
package-amd:
	@cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl --set "*.args.VERSION=$(TAG)" package-amd64; \
	mkdir -p $(BIN_DIR); cid=$$(docker create $(IMAGE):amd64); docker cp $$cid:/packages/. $(BIN_DIR)/; docker rm $$cid; \
	chown -R $$(id -u):$$(id -g) $(BIN_DIR)

package-arm:
	@cd $(APP_DIR) && REGISTRY="$(REGISTRY)" VERSION="$(TAG)" docker buildx bake -f docker-bake.hcl --set "*.args.VERSION=$(TAG)" package-arm64; \
	mkdir -p $(BIN_DIR); cid=$$(docker create $(IMAGE):arm64); docker cp $$cid:/packages/. $(BIN_DIR)/; docker rm $$cid; \
	chown -R $$(id -u):$$(id -g) $(BIN_DIR)

clean:
	@rm -rf $(BIN_DIR)
	@rm -rf $(APP_DIR)dist

# Install: copy from bin/ to /tmp and run package manager
install-apt:
	@arch=$$(uname -m); deb_arch=$$([ "$$arch" = x86_64 ] && echo amd64 || echo arm64); \
	f=$$(ls $(BIN_DIR)/$(PKG_NAME)_*_$$deb_arch.deb 2>/dev/null | head -1); \
	test -n "$$f" || { echo "No .deb for $$deb_arch in $(BIN_DIR)"; exit 1; }; \
	cp "$$f" /tmp/; sudo apt-get install --reinstall -y /tmp/$$(basename "$$f")

install-yum:
	@arch=$$(uname -m); rpm_arch=$$([ "$$arch" = x86_64 ] && echo x86_64 || echo aarch64); \
	f=$$(ls $(BIN_DIR)/$(PKG_NAME)-*.$$rpm_arch.rpm 2>/dev/null | head -1); \
	test -n "$$f" || { echo "No .rpm for $$rpm_arch in $(BIN_DIR)"; exit 1; }; \
	cp "$$f" /tmp/; sudo dnf install -y /tmp/$$(basename "$$f") || sudo yum install -y /tmp/$$(basename "$$f")

install:
	@command -v apt-get >/dev/null 2>&1 && $(MAKE) install-apt || $(MAKE) install-yum

uninstall:
	@command -v apt-get >/dev/null 2>&1 && $(MAKE) uninstall-apt || $(MAKE) uninstall-yum

uninstall-apt:
	@sudo apt-get remove -y $(PKG_NAME)

uninstall-yum:
	@sudo dnf remove -y $(PKG_NAME) || sudo yum remove -y $(PKG_NAME)
