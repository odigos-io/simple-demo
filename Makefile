PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
APPS = load-generator coupon currency frontend geolocation inventory membership pricing
SERVICES = coupon currency frontend geolocation inventory membership pricing
PACKAGE_VERSION := 1.0.0
PACKAGE_ARCH := amd64

##################################################
# For development
##################################################

.PHONY: generate-webapp
generate-webapp:
	@echo "Generating webapp..."
	@cd $(PROJECT_DIR)frontend/webapp && yarn && yarn build
	rm -rf $(PROJECT_DIR)/frontend/src/main/resources/static/*
	@if [ -d "$(PROJECT_DIR)frontend/webapp/out" ]; then \
		cp -r $(PROJECT_DIR)frontend/webapp/out/* $(PROJECT_DIR)/frontend/src/main/resources/static/; \
	else \
		echo "Error: webapp/out directory not found after build"; \
		exit 1; \
	fi

dev-deploy-%:
	@echo "Deploying $* to Kubernetes..."
	docker build -t dev/$*:dev $(PROJECT_DIR)$* -f $(PROJECT_DIR)$*/Dockerfile
	kind load docker-image dev/$*:dev
	kubectl apply -f $(PROJECT_DIR)$*/deployment/
	-kubectl rollout restart deployment $*

.PHONY: dev-deploy
dev-deploy:
	@set -e; \
	for app in $(APPS); do \
		$(MAKE) dev-deploy-$$app; \
	done

##################################################
# For production (requires Google Cloud permissions)
##################################################

VERSION := v0.1.31
REGISTRY := us-central1-docker.pkg.dev/odigos-cloud/components

.PHONY: prod-deploy
prod-deploy:
	@echo "Building images..."
	@set -e; \
	for app in $(APPS); do \
		docker buildx build -t ${REGISTRY}/odigos-demo-$$app:${VERSION} $(PROJECT_DIR)$$app -f $(PROJECT_DIR)$$app/Dockerfile --platform linux/amd64,linux/arm64 --push; \
	done

##################################################
# Package building for systemd deployment
##################################################

.PHONY: check-deps
check-deps:
	@echo "Checking build dependencies..."
	@command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting."; exit 1; }
	@command -v nfpm >/dev/null 2>&1 || { echo "nfpm is required but not installed. Install with: go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest"; exit 1; }
	@echo "All dependencies found."

.PHONY: build-service
build-service:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make build-service SERVICE=<service-name>"; exit 1; fi
	@if [ "$(SERVICE)" = "frontend" ]; then \
		echo "Building frontend service (with webapp)..."; \
		$(MAKE) generate-webapp; \
	fi
	@echo "Building $(SERVICE) service..."
	@cd $(PROJECT_DIR)$(SERVICE) && \
	docker build -t $(SERVICE) . && \
	docker rm -f tc-$(SERVICE) 2>/dev/null || true && \
	docker create --name tc-$(SERVICE) $(SERVICE) && \
	mkdir -p ./dist && \
	sh ./distribution/copy-assets.sh && \
	docker rm tc-$(SERVICE)
	@echo "Built $(SERVICE) service files"

.PHONY: package-service
package-service:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make package-service SERVICE=<service-name>"; exit 1; fi
	@echo "Packaging $(SERVICE) service..."
	@cd $(PROJECT_DIR)$(SERVICE) && \
	sed -i -E 's/version: .*$$/version: $(PACKAGE_VERSION)/' nfpm.yaml && \
	sed -i -E 's/arch: .*$$/arch: $(PACKAGE_ARCH)/' nfpm.yaml && \
	nfpm pkg --packager deb --target dist/ --config nfpm.yaml && \
	nfpm pkg --packager rpm --target dist/ --config nfpm.yaml
	@echo "Packaged $(SERVICE) service"

.PHONY: package-service-deb
package-service-deb:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make package-service-deb SERVICE=<service-name>"; exit 1; fi
	@echo "Packaging $(SERVICE) service (DEB only)..."
	@cd $(PROJECT_DIR)$(SERVICE) && \
	sed -i -E 's/version: .*$$/version: $(PACKAGE_VERSION)/' nfpm.yaml && \
	sed -i -E 's/arch: .*$$/arch: $(PACKAGE_ARCH)/' nfpm.yaml && \
	nfpm pkg --packager deb --target dist/ --config nfpm.yaml
	@echo "Packaged $(SERVICE) service (DEB)"

.PHONY: build-package
build-package:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make build-package SERVICE=<service-name>"; exit 1; fi
	@$(MAKE) build-service SERVICE=$(SERVICE)
	@$(MAKE) package-service SERVICE=$(SERVICE)

.PHONY: cleanup-containers
cleanup-containers:
	@echo "Cleaning up any existing containers..."
	@for service in $(SERVICES); do \
		docker rm -f tc-$$service 2>/dev/null || true; \
	done

# Calculate optimal job count (max 8 jobs to avoid overwhelming the system)
JOBS := $(shell echo $$(($(shell nproc) > 8 ? 8 : $(shell nproc))))

.PHONY: show-parallel-info
show-parallel-info:
	@echo "Parallel execution configuration:"
	@echo "  Available CPU cores: $(shell nproc)"
	@echo "  Optimal job count: $(JOBS)"
	@echo "  Services to build: $(SERVICES)"
	@echo "  Total services: $(words $(SERVICES))"

.PHONY: build-all-services
build-all-services: cleanup-containers
	@echo "Building all services in parallel (using $(JOBS) jobs)..."
	@$(MAKE) -j$(JOBS) $(addprefix build-service-,$(SERVICES))
	@echo "All services built successfully"

# Individual build targets for parallel execution
$(addprefix build-service-,$(SERVICES)): build-service-%:
	@echo "Building $* service..."
	@$(MAKE) build-service SERVICE=$*

.PHONY: package-all-services
package-all-services:
	@echo "Packaging all services in parallel (using $(JOBS) jobs)..."
	@$(MAKE) -j$(JOBS) $(addprefix package-service-,$(SERVICES))
	@echo "All services packaged successfully"

# Individual package targets for parallel execution (DEB + RPM)
$(addprefix package-service-,$(SERVICES)): package-service-%:
	@echo "Packaging $* service..."
	@$(MAKE) package-service SERVICE=$*

.PHONY: package-all-services-deb
package-all-services-deb:
	@echo "Packaging all services (DEB only) in parallel (using $(JOBS) jobs)..."
	@$(MAKE) -j$(JOBS) $(addprefix package-service-deb-,$(SERVICES))
	@echo "All services packaged successfully (DEB)"

# Individual package targets for parallel execution
$(addprefix package-service-deb-,$(SERVICES)): package-service-deb-%:
	@echo "Packaging $* service (DEB)..."
	@$(MAKE) package-service-deb SERVICE=$*

.PHONY: build-packages
build-packages: check-deps generate-webapp build-all-services package-all-services
	@echo "All packages built successfully"

.PHONY: package-local
package-local: check-deps generate-webapp build-all-services package-all-services
	@echo "Creating local package..."
	@mkdir -p $(PROJECT_DIR)release
	@rm -f $(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION).tar.gz
	@cd $(PROJECT_DIR) && \
	find . -name "*.deb" -path "*/dist/*" -exec cp {} release/ \; && \
	find . -name "*.rpm" -path "*/dist/*" -exec cp {} release/ \;
	@cd $(PROJECT_DIR)release && \
	tar -czf odigos-demo-packages-$(PACKAGE_VERSION).tar.gz *.deb *.rpm && \
	rm -f *.deb *.rpm
	@echo "✅ Package created: $(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION).tar.gz"
	@ls -lh $(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION).tar.gz

# This target already builds packages in parallel via build-all-services and package-all-services-deb
.PHONY: package-local-deb
package-local-deb: check-deps generate-webapp build-all-services package-all-services-deb
	@echo "Creating local package (DEB only)..."
	@mkdir -p $(PROJECT_DIR)release
	@rm -f $(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION)-deb.tar.gz
	@cd $(PROJECT_DIR) && \
	find . -name "*.deb" -path "*/dist/*" -exec cp {} release/ \;
	@cd $(PROJECT_DIR)release && \
	tar -czf odigos-demo-packages-$(PACKAGE_VERSION)-deb.tar.gz *.deb && \
	rm -f *.deb
	@echo "✅ DEB Package created: $(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION)-deb.tar.gz"
	@ls -lh $(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION)-deb.tar.gz

.PHONY: create-release-package
create-release-package: package-local

.PHONY: clean-packages
clean-packages:
	@echo "Cleaning package artifacts..."
	@find $(PROJECT_DIR) -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
	@rm -rf $(PROJECT_DIR)release
	@echo "Package artifacts cleaned"

.PHONY: install-from-release
install-from-release:
	@if [ ! -f "$(PROJECT_DIR)release/odigos-demo-packages-$(PACKAGE_VERSION).tar.gz" ]; then \
		echo "Release package not found. Run 'make create-release-package' first."; \
		exit 1; \
	fi
	@echo "Installing packages from release..."
	@cd $(PROJECT_DIR)release && \
	tar -xzf odigos-demo-packages-$(PACKAGE_VERSION).tar.gz && \
	sudo dpkg -i *.deb || sudo apt-get install -f
	@echo "All packages installed successfully"

.PHONY: help-packages
help-packages:
	@echo "🚀 Simplified Package Workflow:"
	@echo ""
	@echo "1. Create package (DEB + RPM):"
	@echo "   make package-local"
	@echo ""
	@echo "1. Create package (DEB only):"
	@echo "   make package-local-deb"
	@echo ""
	@echo "2. Install from package:"
	@echo "   ./install-from-package.sh"
	@echo ""
	@echo "3. Remove all services:"
	@echo "   ./uninstall-demo.sh"
	@echo ""
	@echo "📦 Individual Package Targets:"
	@echo "  build-service SERVICE=<name>      - Build a specific service"
	@echo "  package-service SERVICE=<name>   - Package a specific service (DEB+RPM)"
	@echo "  package-service-deb SERVICE=<name> - Package a specific service (DEB only)"
	@echo "  build-package SERVICE=<name>     - Build and package a specific service"
	@echo "  build-all-services               - Build all services"
	@echo "  package-all-services             - Package all services (DEB+RPM)"
	@echo "  package-all-services-deb         - Package all services (DEB only)"
	@echo "  package-local                    - Create .tar.gz with all packages"
	@echo "  package-local-deb                - Create .tar.gz with DEB packages only"
	@echo "  clean-packages                   - Clean package artifacts"
	@echo ""
	@echo "🔧 Variables:"
	@echo "  PACKAGE_VERSION=$(PACKAGE_VERSION)"
	@echo "  PACKAGE_ARCH=$(PACKAGE_ARCH)"
	@echo ""
	@echo "📋 Examples:"
	@echo "  make package-local-deb                 # Create DEB-only package"
	@echo "  make package-local                     # Create complete package"
	@echo "  make build-package SERVICE=frontend    # Build specific service"
	@echo "  ./install-from-package.sh status       # Check service status"
	@echo "  ./uninstall-demo.sh status             # Check installed packages"
