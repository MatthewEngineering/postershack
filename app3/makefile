# Default target (runs when you just type `make`)
.DEFAULT_GOAL := help

# ── Config — override on the command line: make build IMAGE=myrepo/myapp ──────
IMAGE  ?= huggingface-app
TAG    ?= latest

# ── Docker ────────────────────────────────────────────────────────────────────

# Build the image
build:
	docker build -t $(IMAGE):$(TAG) .

# Run locally — mounts a model cache so re-runs don't re-download weights
run:
	docker run -d \
		--name $(IMAGE) \
		-p 7860:7860 \
		--env-file .env \
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


# -- terraform -──────────────────────────────────────────────────────────────────────

TF_DIR    := terraform
# Load secrets from .env so they don't need to be typed each time
include .env
export HF_TOKEN
export AZURE_STORAGE_CONNECTION_STRING
TF_VARS   := -var="hf_token=$(HF_TOKEN)"

tf-init:
	terraform -chdir=$(TF_DIR) init

tf-plan:
	terraform -chdir=$(TF_DIR) plan $(TF_VARS)

tf-apply:
	terraform -chdir=$(TF_DIR) apply -auto-approve $(TF_VARS)

tf-destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve $(TF_VARS)

tf-output:
	terraform -chdir=$(TF_DIR) output

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "Docker:"
	@echo "  make build          Build the image (IMAGE=name TAG=tag)"
	@echo "  make run            Run locally at http://localhost:7860"
	@echo "  make stop           Stop and remove the container"
	@echo "  make logs           Tail container logs"
	@echo "  make push           Push image to registry"
	@echo "  make shell          Open bash inside running container"
	@echo ""
	@echo "Terraform:"
	@echo "  make tf-init        terraform init"
	@echo "  make tf-plan        terraform plan  (HF_TOKEN loaded from .env)"
	@echo "  make tf-apply       terraform apply (HF_TOKEN loaded from .env)"
	@echo "  make tf-destroy     terraform destroy"
	@echo "  make tf-output      Show terraform outputs"
	@echo ""
