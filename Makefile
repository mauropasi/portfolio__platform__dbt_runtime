IMAGE_NAME ?= portfolio__platform__dbt_runtime
IMAGE_TAG ?= local
DBT_VERSION ?= 1.8.10
DUCKDB_VERSION ?= 1.8.4
TOOLS_VERSION ?= v1

.PHONY: help build build-1.8 build-1.9 test run

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image locally (default: dbt 1.8)
	docker build \
		--build-arg DBT_VERSION=$(DBT_VERSION) \
		--build-arg DUCKDB_VERSION=$(DUCKDB_VERSION) \
		--build-arg TOOLS_VERSION=$(TOOLS_VERSION) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

build-1.8: ## Build dbt 1.8 (LTS) image locally
	$(MAKE) build DBT_VERSION=1.8.10 DUCKDB_VERSION=1.8.4 TOOLS_VERSION=v1 IMAGE_TAG=1.8

build-1.9: ## Build dbt 1.9 (Latest 1.x) image locally
	$(MAKE) build DBT_VERSION=1.9.11 DUCKDB_VERSION=1.9.6 TOOLS_VERSION=v1 IMAGE_TAG=1.9

test: build ## Verify image builds and key CLIs are functioning
	@echo "==> Testing dbt..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) dbt --version
	@echo "==> Testing sqlfluff..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) sqlfluff --version
	@echo "==> All CLI checks passed successfully!"

run: ## Open an interactive bash shell in the container
	docker run --rm -it $(IMAGE_NAME):$(IMAGE_TAG) /bin/bash
