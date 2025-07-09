#!/bin/bash

# Name of the Docker image
IMAGE_NAME="my-php-sample"
DOCKERHUB_USER="yourdockerhubusername"  # Replace this
DOCKER_TAG="$DOCKERHUB_USER/$IMAGE_NAME:latest"

echo "🔧 Building Docker image..."
docker build -t $DOCKER_TAG .

echo "📤 Pushing image to Docker Hub..."
docker push $DOCKER_TAG

echo "✅ Done!"
