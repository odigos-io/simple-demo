PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
VERSION := v0.1.16
REGISTRY := us-central1-docker.pkg.dev/odigos-cloud/components

.PHONY: generate-webapp
generate-webapp:
	@echo "Generating webapp..."
	@cd $(PROJECT_DIR)frontend/webapp && yarn && yarn build
	rm -rf $(PROJECT_DIR)/frontend/src/main/resources/static/*
	cp -r $(PROJECT_DIR)frontend/webapp/out/* $(PROJECT_DIR)/frontend/src/main/resources/static/

.PHONY: build-images
build-images:
	@echo "Building images..."
	docker build -t dev/frontend:dev $(PROJECT_DIR)frontend -f $(PROJECT_DIR)frontend/Dockerfile
	docker build -t dev/inventory:dev $(PROJECT_DIR)inventory -f $(PROJECT_DIR)inventory/Dockerfile
	docker build -t dev/pricing:dev $(PROJECT_DIR)pricing -f $(PROJECT_DIR)pricing/Dockerfile
	docker build -t dev/coupon:dev $(PROJECT_DIR)coupon -f $(PROJECT_DIR)coupon/Dockerfile
	docker build -t dev/membership:dev $(PROJECT_DIR)membership -f $(PROJECT_DIR)membership/Dockerfile
	docker build -t dev/currency:dev $(PROJECT_DIR)currency -f $(PROJECT_DIR)currency/Dockerfile

.PHONY: load-to-kind
load-to-kind:
	@echo "Loading images to kind..."
	kind load docker-image dev/frontend:dev
	kind load docker-image dev/inventory:dev
	kind load docker-image dev/pricing:dev
	kind load docker-image dev/coupon:dev
	kind load docker-image dev/membership:dev
	kind load docker-image dev/currency:dev

.PHONY: deploy
deploy:
	@echo "Deploying to Kubernetes..."
	kubectl apply -f $(PROJECT_DIR)pricing/deployment/
	kubectl apply -f $(PROJECT_DIR)inventory/deployment/
	kubectl apply -f $(PROJECT_DIR)frontend/deployment/
	kubectl apply -f $(PROJECT_DIR)coupon/deployment/
	kubectl apply -f $(PROJECT_DIR)membership/deployment/
	kubectl apply -f $(PROJECT_DIR)currency/deployment/

.PHONY: delete
delete:
	@echo "Deleting from Kubernetes..."
	kubectl delete -f $(PROJECT_DIR)pricing/deployment/
	kubectl delete -f $(PROJECT_DIR)inventory/deployment/
	kubectl delete -f $(PROJECT_DIR)frontend/deployment/
	kubectl delete -f $(PROJECT_DIR)coupon/deployment/
	kubectl delete -f $(PROJECT_DIR)membership/deployment/
	kubectl delete -f $(PROJECT_DIR)currency/deployment/

.PHONY: build-push-images-prod
build-push-images-prod:
	@echo "Building images..."
	docker buildx build -t ${REGISTRY}/odigos-demo-frontend:${VERSION} $(PROJECT_DIR)frontend -f $(PROJECT_DIR)frontend/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t ${REGISTRY}/odigos-demo-inventory:${VERSION} $(PROJECT_DIR)inventory -f $(PROJECT_DIR)inventory/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t ${REGISTRY}/odigos-demo-pricing:${VERSION} $(PROJECT_DIR)pricing -f $(PROJECT_DIR)pricing/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t ${REGISTRY}/odigos-demo-coupon:${VERSION} $(PROJECT_DIR)coupon -f $(PROJECT_DIR)coupon/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t ${REGISTRY}/odigos-demo-membership:${VERSION} $(PROJECT_DIR)membership -f $(PROJECT_DIR)membership/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t ${REGISTRY}/odigos-demo-currency:${VERSION} $(PROJECT_DIR)currency -f $(PROJECT_DIR)currency/Dockerfile --platform linux/amd64,linux/arm64 --push


.PHONY: deploy-currency
deploy-currency:
	@echo "Deploying currency to Kubernetes..."
	docker build -t dev/currency:dev $(PROJECT_DIR)currency -f $(PROJECT_DIR)currency/Dockerfile
	kind load docker-image dev/currency:dev
	kubectl apply -f $(PROJECT_DIR)currency/deployment/
	kubectl rollout restart deployment currency

.PHONY: deploy-membership
deploy-membership:
	@echo "Deploying membership to Kubernetes..."
	docker build -t dev/membership:dev $(PROJECT_DIR)membership -f $(PROJECT_DIR)membership/Dockerfile
	kind load docker-image dev/membership:dev
	kubectl apply -f $(PROJECT_DIR)membership/deployment/
	kubectl rollout restart deployment membership

.PHONY: deploy-inventory
deploy-inventory:
	@echo "Deploying inventory to Kubernetes..."
	docker build -t dev/inventory:dev $(PROJECT_DIR)inventory -f $(PROJECT_DIR)inventory/Dockerfile
	kind load docker-image dev/inventory:dev
	kubectl apply -f $(PROJECT_DIR)inventory/deployment/
	kubectl rollout restart deployment inventory

.PHONY: deploy-coupon
deploy-coupon:
	@echo "Deploying coupon to Kubernetes..."
	docker build -t dev/coupon:dev $(PROJECT_DIR)coupon -f $(PROJECT_DIR)coupon/Dockerfile
	kind load docker-image dev/coupon:dev
	kubectl apply -f $(PROJECT_DIR)coupon/deployment/
	kubectl rollout restart deployment coupon4

.PHONY: deploy-pricing
deploy-pricing:
	@echo "Deploying pricing to Kubernetes..."
	docker build -t dev/pricing:dev $(PROJECT_DIR)pricing -f $(PROJECT_DIR)pricing/Dockerfile
	kind load docker-image dev/pricing:dev
	kubectl apply -f $(PROJECT_DIR)pricing/deployment/
	kubectl rollout restart deployment pricing

.PHONY: deploy-frontend
deploy-frontend:
	@echo "Deploying frontend to Kubernetes..."
	docker build -t dev/frontend:dev $(PROJECT_DIR)frontend -f $(PROJECT_DIR)frontend/Dockerfile
	kind load docker-image dev/frontend:dev
	kubectl apply -f $(PROJECT_DIR)frontend/deployment/
	kubectl rollout restart deployment frontend
