IMAGE_NAME ?= portfolio__platform__dbt_runtime
IMAGE_TAG ?= local

.PHONY: help build test run

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image locally
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

test: build ## Verify image builds and key CLIs are functioning
	@echo "==> Testing dbt..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) dbt --version
	@echo "==> Testing sqlfluff..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) sqlfluff --version
	@echo "==> All CLI checks passed successfully!"

run: ## Open an interactive bash shell in the container
	docker run --rm -it $(IMAGE_NAME):$(IMAGE_TAG) /bin/bash
