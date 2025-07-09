#!/bin/bash

# Load token from .env if exists
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

DEFAULT_IMAGE_NAME="ghcr.io/svutheareak/samplephp:latest"
GITHUB_USER="svutheareak"

echo "What do you want to do? (buildimage|deploy|remove|list|update): "
read ACTION

if [ "$ACTION" == "buildimage" ]; then
    echo "🔐 Logging in to GHCR..."
    echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

    echo "🐳 Building Docker image..."
    docker build -t "$DEFAULT_IMAGE_NAME" .

    echo "📦 Pushing image to GHCR..."
    docker push "$DEFAULT_IMAGE_NAME"

    echo "✅ Done! Your image is now available at: $DEFAULT_IMAGE_NAME"

    echo "Do you want to deploy or update the image now? (deploy/update/end): "
    read NEXT_ACTION

    if [ "$NEXT_ACTION" == "deploy" ]; then
        ACTION="deploy"
    elif [ "$NEXT_ACTION" == "update" ]; then
        ACTION="update"
    else
        echo "End of process."
        exit 0
    fi
fi

if [ "$ACTION" == "deploy" ]; then
    echo "# Case: Deploy"
    read -p "Enter container name: " CONTAINER_NAME
    read -p "Enter host port to map (example: 9001): " HOST_PORT

    if docker ps --format '{{.Ports}}' | grep -q ":$HOST_PORT->"; then
        echo "🤖 Message 🤖"
        echo "Port $HOST_PORT is already mapped to another running container. Please choose another port."
        exit 1
    fi

    echo "📦 Pulling latest GHCR image..."
    docker pull "$DEFAULT_IMAGE_NAME" || {
        echo "❌ Failed to pull image. Aborting."
        exit 1
    }

    echo "🚀 Running container..."
    docker run -d --restart unless-stopped \
        --name "$CONTAINER_NAME" \
        -p "$HOST_PORT:80" \
        "$DEFAULT_IMAGE_NAME"

    echo "✅ Deployment complete!"

elif [ "$ACTION" == "update" ]; then
    echo "# Case: Update Existing Deployment"
    echo "Here is a list of existing containers:"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
    echo ""
    read -p "Enter existing container ID or name: " CONTAINER_ID

    if ! docker ps -a --format '{{.ID}} {{.Names}}' | grep -wq "$CONTAINER_ID"; then
        echo "❌ Container '$CONTAINER_ID' not found."
        exit 1
    fi

    CONTAINER_NAME=$(docker ps -a --format '{{.ID}} {{.Names}}' | grep -w "$CONTAINER_ID" | awk '{print $2}')
    EXISTING_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' "$CONTAINER_NAME")
    echo "🌐 Existing container '$CONTAINER_NAME' is using port: $EXISTING_PORT"

    echo "Choose update image source:"
    echo "1. Use GHCR by digest (sha256:...)"
    echo "2. Use local image"
    read -p "Enter choice (1 or 2): " IMG_OPTION

    if [ "$IMG_OPTION" == "1" ]; then
        read -p "Enter full GHCR image path (e.g., ghcr.io/svutheareak/samplephp@sha256:...): " CUSTOM_IMAGE
        IMAGE_TO_RUN="$CUSTOM_IMAGE"

        echo "📦 Pulling specific GHCR version..."
        docker pull "$IMAGE_TO_RUN" || {
            echo "❌ Failed to pull GHCR image. Aborting."
            exit 1
        }

    elif [ "$IMG_OPTION" == "2" ]; then
        read -p "Enter local image name (e.g., samplephp:local): " CUSTOM_IMAGE

        if ! docker image inspect "$CUSTOM_IMAGE" > /dev/null 2>&1; then
            echo "❌ Local image not found. Aborting."
            exit 1
        fi

        IMAGE_TO_RUN="$CUSTOM_IMAGE"
    else
        echo "❌ Invalid image option."
        exit 1
    fi

    echo "🚧 Stopping and removing old container..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"

    echo "🚀 Running updated container..."
    docker run -d --restart unless-stopped \
        --name "$CONTAINER_NAME" \
        -p "$EXISTING_PORT:80" \
        "$IMAGE_TO_RUN"

    echo "✅ Updated container '$CONTAINER_NAME' to image '$IMAGE_TO_RUN'"

elif [ "$ACTION" == "remove" ]; then
    echo "# Case: Remove"
    echo "📦 Containers and their images:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

    read -p "Which container do you want to remove? " CONTAINER_NAME

    if [ -z "$CONTAINER_NAME" ]; then
        echo "Container name cannot be empty. Operation aborted."
        exit 1
    fi

    if ! docker ps -a --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
        echo "No such container: $CONTAINER_NAME"
        exit 1
    fi

    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    echo "🗑️ Container '$CONTAINER_NAME' has been removed."

elif [ "$ACTION" == "list" ]; then
    echo "# Case: List Containers and Docker Images"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

else
    echo "⏩ Invalid input. Please choose: buildimage | deploy | update | remove | list."
fi
