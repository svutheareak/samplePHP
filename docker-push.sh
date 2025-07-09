#!/bin/bash

# Load token from .env
set -o allexport
source .env
set +o allexport

# Configuration
IMAGE_NAME="ghcr.io/svutheareak/samplephp:latest"
GITHUB_USER="svutheareak"

# Build and push
echo "🔐 Logging in to GHCR..."
echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

echo "🐳 Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "📦 Pushing image to GHCR..."
docker push "$IMAGE_NAME"

echo "✅ Done! Your image is now available at: $IMAGE_NAME"
