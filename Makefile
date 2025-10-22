.PHONY: help init validate format lint docs test clean

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform working directory
	@echo "Initializing Terraform..."
	terraform init

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	terraform validate

format: ## Format Terraform files
	@echo "Formatting Terraform files..."
	terraform fmt -recursive .

format-check: ## Check if Terraform files are formatted
	@echo "Checking Terraform formatting..."
	terraform fmt -check -recursive .

lint: ## Run tflint on Terraform files
	@echo "Running tflint..."
	@command -v tflint >/dev/null 2>&1 || { echo "tflint is not installed. Install from: https://github.com/terraform-linters/tflint"; exit 1; }
	tflint --init
	tflint

docs: ## Generate documentation using terraform-docs
	@echo "Generating documentation..."
	@command -v terraform-docs >/dev/null 2>&1 || { echo "terraform-docs is not installed. Install from: https://terraform-docs.io/"; exit 1; }
	terraform-docs markdown table --output-file README.md --output-mode inject .

test: ## Run terratest tests
	@echo "Running tests..."
	cd test && go test -v -timeout 30m

test-examples: ## Test example configurations
	@echo "Testing examples..."
	@for dir in examples/*/; do \
		echo "Testing $$dir..."; \
		cd $$dir && terraform init && terraform validate && cd ../..; \
	done

security: ## Run security checks with checkov
	@echo "Running security checks..."
	@command -v checkov >/dev/null 2>&1 || { echo "checkov is not installed. Install with: pip install checkov"; exit 1; }
	checkov -d . --framework terraform

clean: ## Clean up Terraform files
	@echo "Cleaning up..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.tfstate*" -exec rm -f {} + 2>/dev/null || true
	find . -type f -name "*tfplan*" -exec rm -f {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true

pre-commit: format validate lint ## Run pre-commit checks

all: init validate format lint docs test ## Run all checks and tests

