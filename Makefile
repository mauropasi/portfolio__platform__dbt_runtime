IMAGE_NAME ?= portfolio__platform__dbt_runtime
IMAGE_TAG ?= local
DBT_PACKAGES ?= dbt-core==1.12.5 dbt-duckdb duckdb
SQLFLUFF_VERSION ?= >=3.0.0
TOOLS_VERSION ?= v1

.PHONY: help build build-v1 build-v2 test run

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image locally (default: dbt 1.12)
	docker build \
		--build-arg DBT_PACKAGES="$(DBT_PACKAGES)" \
		--build-arg SQLFLUFF_VERSION="$(SQLFLUFF_VERSION)" \
		--build-arg TOOLS_VERSION=$(TOOLS_VERSION) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

build-v1: ## Build dbt 1.12 (Latest 1.x) image locally
	$(MAKE) build DBT_PACKAGES="dbt-core==1.12.5 dbt-duckdb duckdb" TOOLS_VERSION=v1 IMAGE_TAG=1.12

build-v2: ## Build dbt v2 (Next gen) image locally
	$(MAKE) build DBT_PACKAGES="dbt>=2.0.0 duckdb" TOOLS_VERSION=v1 IMAGE_TAG=2.0

test: build ## Verify image builds and key CLIs are functioning
	@echo "==> Testing dbt..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) dbt --version
	@echo "==> Testing sqlfluff..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) sqlfluff --version
	@echo "==> Testing duckdb..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) python -c "import duckdb; print('duckdb:', duckdb.__version__)"
	@echo "==> All CLI checks passed successfully!"

run: ## Open an interactive bash shell in the container
	docker run --rm -it $(IMAGE_NAME):$(IMAGE_TAG) /bin/bash
