# Image names
IMAGE_NAME=opencyber-dns-lab
# Host port for the lookalike page + capture server (override if 8088 is busy, e.g. `HOST_PORT=9090 make run`)
HOST_PORT ?= 8088

# Default target: build the lab image
all: student

# Build the lab image
student:
	docker build -t $(IMAGE_NAME):local -f docker/Dockerfile .

# Run an interactive container from the local build (builds first if needed).
# Container serves the lookalike page + capture server on 8080; mapped to $(HOST_PORT) on the host.
run: student
	docker run --rm -it -p $(HOST_PORT):8080 $(IMAGE_NAME):local

# Clean up dangling images (optional)
clean:
	docker image prune -f

# Run the image from GitHub Container Registry
ghcr:
	docker run --rm -it -p $(HOST_PORT):8080 ghcr.io/codepath/$(IMAGE_NAME):latest

# Build and push to GitHub Container Registry (requires docker login ghcr.io)
push:
	docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/codepath/$(IMAGE_NAME):latest -f docker/Dockerfile --push .
