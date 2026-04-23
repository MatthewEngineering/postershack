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
		-v diffuser-model-cache:/root/.cache/huggingface \
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
