#!/bin/bash

# Build and push the TTS base image to DockerHub
# This script requires Docker to be installed and you to be logged in to DockerHub

# Configuration
BASE_IMAGE_NAME="lulumarjan/tts-base"
BASE_IMAGE_TAG="latest"

echo "Building TTS base image..."
docker build -t ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} -f Dockerfile.base .

echo "Pushing TTS base image to DockerHub..."
docker push ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

echo "TTS base image build and push complete!"
echo "Base image: ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"
echo ""
echo "You can now build the main TTS container using:"
echo "docker-compose build tts"