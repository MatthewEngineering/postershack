# Default target (runs when you just type `make`)
.DEFAULT_GOAL := help

# ── Config — override on the command line: make build IMAGE=myrepo/myapp ──────
IMAGE  ?= diffuser-mvp
TAG    ?= latest

# Show available commands
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Docker:"
	@echo "  build     Build the Docker image (IMAGE=diffuser-mvp TAG=latest)"
	@echo "  run       Run the container locally on http://localhost:7860"
	@echo "  stop      Stop the running container"
	@echo "  logs      Tail container logs"
	@echo "  push      Push image to registry (set IMAGE=yourregistry/diffuser-mvp)"
	@echo "  shell     Open a shell inside the running container"
	@echo ""
	@echo "Terraform:"
	@echo "  init      Initialize Terraform (providers, backend)"
	@echo "  plan      Preview infrastructure changes"
	@echo "  apply     Apply changes to infrastructure"
	@echo "  destroy   Destroy all managed infrastructure"
	@echo "  fmt       Format Terraform files"
	@echo "  validate  Validate Terraform configuration"
	@echo "  show      Show current state"
	@echo "  output    Show output variables"
	@echo "  clean     Remove local Terraform cache"

# ── Docker ────────────────────────────────────────────────────────────────────

# Build the image
build:
	docker build -t $(IMAGE):$(TAG) .

# Run locally — mounts a model cache so re-runs don't re-download weights
run:
	docker run -d \
		--name $(IMAGE) \
		-p 7860:7860 \
		-v diffuser-model-cache:/root/.cache/huggingface \
		$(IMAGE):$(TAG)
	@echo "Running at http://localhost:7860"

# Stop and remove the container
stop:
	docker stop $(IMAGE) && docker rm $(IMAGE)

# Tail logs from the running container
logs:
	docker logs -f $(IMAGE)

# Push to a container registry (e.g. Azure Container Registry)
push:
	docker push $(IMAGE):$(TAG)

# Open a shell inside the running container (for debugging)
shell:
	docker exec -it $(IMAGE) /bin/bash

# ── Terraform ─────────────────────────────────────────────────────────────────

# Initialize Terraform (downloads providers, sets up backend)
init:
	terraform init

# Preview changes without applying (safe diff)
plan:
	terraform plan

# Apply planned changes (creates/updates infra)
apply:
	terraform apply

# Destroy all resources managed by Terraform
destroy:
	terraform destroy

# Format .tf files for consistency
fmt:
	terraform fmt -recursive

# Validate syntax and config
validate:
	terraform validate

# Display current state details
show:
	terraform show

# Print defined output variables
output:
	terraform output

# Clean local Terraform files (cache, lock file)
clean:
	rm -rf .terraform .terraform.lock.hcl