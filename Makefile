PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# Apps that have a Docker image (build + dev-deploy)
APPS = coupon currency frontend geolocation inventory membership pricing load-generator
# All apps that produce Linux packages (includes demo meta-package)
PACKAGE_APPS = $(APPS) demo

# Default to local architecture (override with ARCH=amd64 or ARCH=arm64); passed to app Makefiles
ARCH ?= $(shell uname -m)

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
	$(MAKE) -C $(PROJECT_DIR)$* build TAG=dev REGISTRY=$(DEV_REGISTRY) ARCH="$(ARCH)"
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

# build-all and build-all-% must appear before build/build-% so BSD make (macOS) matches
# build-all-coupon to build-all-% (stem coupon) rather than build-% (stem all-coupon).
# build-all: multi-arch Docker image in each app (set PUSH=1 REGISTRY=... to push).
# Use: make -j build-all [VERSION=v0.1.123] [PUSH=1] [REGISTRY=...]
.PHONY: build build-all
build-all: $(addprefix build-all-,$(APPS))
	@:

build-all-%: FORCE
	@if ! echo " $(APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Building multi-arch $*..."
	$(MAKE) -C "$(PROJECT_DIR)$*" build-all TAG="$(VERSION)" $(if $(REGISTRY),REGISTRY="$(REGISTRY)",) PUSH="$(PUSH)" ARCH="$(ARCH)"

# Run make build in each app (local arch only; override with ARCH=arm64 or ARCH=amd64).
# Use: make -j build [VERSION=v0.1.123] [ARCH=arm64]  (parallel) or make build (sequential)
build: $(addprefix build-,$(APPS))
	@:

build-%: FORCE
	@if ! echo " $(APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Building $* (arch: $(ARCH))..."
	$(MAKE) -C "$(PROJECT_DIR)$*" build TAG="$(VERSION)" ARCH="$(ARCH)"

# package-all and package-all-% must appear before package/package-% so BSD make (macOS) matches
# package-all-coupon to package-all-% (stem coupon) rather than package-% (stem all-coupon).
# package-all: Linux packages for all architectures in each app.
# Use: make -j package-all [VERSION=v0.1.123]
.PHONY: package package-all
package-all: $(addprefix package-all-,$(PACKAGE_APPS))
	@echo "package all"
	@:

package-all-%: FORCE
	@if ! echo " $(PACKAGE_APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Packaging all archs $*..."
	$(MAKE) -C "$(PROJECT_DIR)$*" package-all TAG="$(VERSION)" ARCH="$(ARCH)"

# Run make package in each app (local arch only; override with ARCH=arm64 or ARCH=amd64).
# Use: make -j package [VERSION=v0.1.123] [ARCH=arm64]  (parallel) or make package (sequential)
package: $(addprefix package-,$(PACKAGE_APPS))
	@:

package-%: FORCE
	@if ! echo " $(PACKAGE_APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Packaging $* (arch: $(ARCH))..."
	$(MAKE) -C "$(PROJECT_DIR)$*" package TAG="$(VERSION)" ARCH="$(ARCH)"

##################################################
# For production (requires Google Cloud permissions)
##################################################

.PHONY: prod-deploy
prod-deploy:
	@echo "Building images (local arch)..."
	@set -e; \
	for app in $(APPS); do \
		echo "Building $$app..."; \
		$(MAKE) -C $(PROJECT_DIR)$$app build TAG="$(VERSION)" ARCH="$(ARCH)"; \
	done


##################################################
# Grooming
##################################################
.PHONY: clean

clean: $(addprefix clean-,$(PACKAGE_APPS))
	@echo "Cleaning all..."
	@:

clean-%: FORCE
	@if ! echo " $(PACKAGE_APPS) " | grep -q " $* "; then \
		echo "Unknown app: $*"; exit 2; \
	fi
	@echo "Cleaning $*..."
	$(MAKE) -C "$(PROJECT_DIR)$*" clean TAG="$(VERSION)"
