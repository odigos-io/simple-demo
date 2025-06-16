PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
APPS = coupon currency frontend geolocation inventory membership pricing

##################################################
# For development
##################################################

.PHONY: generate-webapp
generate-webapp:
	@echo "Generating webapp..."
	@cd $(PROJECT_DIR)frontend/webapp && yarn && yarn build
	rm -rf $(PROJECT_DIR)/frontend/src/main/resources/static/*
	cp -r $(PROJECT_DIR)frontend/webapp/out/* $(PROJECT_DIR)/frontend/src/main/resources/static/

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

VERSION := v0.1.22
REGISTRY := us-central1-docker.pkg.dev/odigos-cloud/components

.PHONY: prod-deploy
prod-deploy:
	@echo "Building images..."
	@set -e; \
	for app in $(APPS); do \
		docker buildx build -t ${REGISTRY}/odigos-demo-$$app:${VERSION} $(PROJECT_DIR)$$app -f $(PROJECT_DIR)$$app/Dockerfile --platform linux/amd64,linux/arm64 --push; \
	done
