IMAGE_NAME ?= portfolio__platform__dbt_runtime
VERSION ?= 1.2
SQLFLUFF_VERSION ?= >=3.0.0

# Extract attributes from versions.json for the selected VERSION (defaults to 1.2)
DBT_PACKAGES ?= $(shell python3 -c 'import json; data=json.load(open("versions.json")); v=next((x for x in data if x["id"]=="$(VERSION)"), data[0]); print(v["dbt_packages"])')
TOOLS_VERSION ?= $(shell python3 -c 'import json; data=json.load(open("versions.json")); v=next((x for x in data if x["id"]=="$(VERSION)"), data[0]); print(v["tools_version"])')
TAG ?= $(shell python3 -c 'import json; data=json.load(open("versions.json")); v=next((x for x in data if x["id"]=="$(VERSION)"), data[0]); print(v["version_tag"])')

.PHONY: help list-versions build test run

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

list-versions: ## List all configured versions in versions.json
	@echo "Available versions in versions.json:"
	@python3 -c 'import json; [print("  - %s: %s (tag: %s)" % (x["id"], x["description"], x["version_tag"])) for x in json.load(open("versions.json"))]'

build: ## Build image for a version from versions.json (Usage: make build [VERSION=1.2|2.0])
	@echo "==> Building $(IMAGE_NAME):$(TAG) (VERSION=$(VERSION))..."
	docker build \
		--build-arg DBT_PACKAGES="$(DBT_PACKAGES)" \
		--build-arg SQLFLUFF_VERSION="$(SQLFLUFF_VERSION)" \
		--build-arg TOOLS_VERSION=$(TOOLS_VERSION) \
		-t $(IMAGE_NAME):$(TAG) .

test: build ## Build and smoke test image for a version (Usage: make test [VERSION=1.2|2.0])
	@echo "==> Testing dbt..."
	docker run --rm $(IMAGE_NAME):$(TAG) dbt --version
	@echo "==> Testing sqlfluff..."
	docker run --rm $(IMAGE_NAME):$(TAG) sqlfluff --version
	@echo "==> Testing duckdb..."
	docker run --rm $(IMAGE_NAME):$(TAG) python -c "import duckdb; print('duckdb:', duckdb.__version__)"
	@echo "==> All checks passed for $(IMAGE_NAME):$(TAG)!"

run: ## Open an interactive bash shell in the container (Usage: make run [VERSION=1.2|2.0])
	docker run --rm -it $(IMAGE_NAME):$(TAG) /bin/bash
