PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# Apps that have a Docker image (build + dev-deploy)
APPS = load-generator coupon currency frontend geolocation inventory membership pricing
# All apps that produce Linux packages (includes demo meta-package)
PACKAGE_APPS = $(APPS) demo

# Default to local architecture: x86_64 -> build-amd; aarch64/arm64 -> build-arm
ARCH := $(shell uname -m)
BUILD_ARCH_TARGET := $(if $(filter x86_64,$(ARCH)),build-amd,$(if $(filter aarch64 arm64,$(ARCH)),build-arm,build-amd))

.PHONY: FORCE
FORCE:
	@:

##################################################
# For development
##################################################
# Registry for dev builds; image is $(DEV_REGISTRY)/odigos-demo-<app>:dev
DEV_REGISTRY := dev

# Build the frontend webapp (Next.js etc.) and copy output into the Java app's
# static resources (frontend/src/main/resources/static/). Required when running
# the frontend locally (e.g. from IDE); Docker builds compile the webapp inside
# the image instead.
.PHONY: generate-webapp
generate-webapp:
	@echo "Generating webapp..."
	@cd $(PROJECT_DIR)frontend/webapp && yarn && yarn build
	@rm -rf $(PROJECT_DIR)frontend/src/main/resources/static/*
	@cp -r $(PROJECT_DIR)frontend/webapp/out/* $(PROJECT_DIR)frontend/src/main/resources/static/

dev-deploy-%: FORCE
	@if ! echo " $(APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Deploying $* to Kubernetes (local arch: $(ARCH))..."
	$(MAKE) -C $(PROJECT_DIR)$* $(BUILD_ARCH_TARGET) TAG=dev REGISTRY=$(DEV_REGISTRY)
	docker tag $(DEV_REGISTRY)/odigos-demo-$*:dev dev/$*:dev
	@echo "Loading docker image dev/$*:dev (local arch only) into kind cluster..."
	kind load docker-image dev/$*:dev
	kubectl apply -f $(PROJECT_DIR)$*/deployment/
	-kubectl rollout restart deployment $*

# Use: make -j dev-deploy  (parallel) or make dev-deploy (sequential)
.PHONY: dev-deploy
dev-deploy: $(addprefix dev-deploy-,$(APPS))
	@:

##################################################
# Build and package (delegate to each app's Makefile)
##################################################

VERSION ?= v0.1.31

# Run make build in each app (builds Docker app image for all platforms).
# Use: make -j build [VERSION=v0.1.123]  (parallel) or make build (sequential)
.PHONY: build

build: $(addprefix build-,$(APPS))
	@:

build-%: FORCE
	@if ! echo " $(APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Building $*..."
	$(MAKE) -C "$(PROJECT_DIR)$*" build TAG="$(VERSION)"

# Run make package in each app (produces .deb/.rpm in each app's bin/).
# Use: make -j package [VERSION=v0.1.123]  (parallel) or make package (sequential)
.PHONY: package $(addprefix package-,$(PACKAGE_APPS))
package: $(addprefix package-,$(PACKAGE_APPS))
	@:

package-%: FORCE
	@if ! echo " $(PACKAGE_APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Packaging $*..."
	$(MAKE) -C "$(PROJECT_DIR)$*" package TAG="$(VERSION)"

##################################################
# For production (requires Google Cloud permissions)
##################################################

.PHONY: prod-deploy
prod-deploy:
	@echo "Building images..."
	@set -e; \
	for app in $(APPS); do \
		echo "Building $$app..."; \
		$(MAKE) -C $(PROJECT_DIR)$$app build TAG=$(VERSION); \
	done
