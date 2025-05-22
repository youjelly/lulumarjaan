#!/bin/bash

# Script to push previously built LuluMarjan base images to DockerHub
# Run this after you've authenticated with 'docker login'

echo "===== Pushing LuluMarjan Base Images to DockerHub ====="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if user is logged in to DockerHub
if ! docker info | grep -q "Username"; then
    echo "Error: You are not logged in to DockerHub."
    echo "Please run 'docker login' first."
    exit 1
fi

# Set DockerHub username
DOCKER_USERNAME="usamazaidi"
echo "Using DockerHub username: $DOCKER_USERNAME"

# Confirm pushing to repository
echo "This will push images to the following repositories:"
echo "- $DOCKER_USERNAME/webrtc-base:latest"
echo "- $DOCKER_USERNAME/llm-base:latest"
echo "- $DOCKER_USERNAME/tts-base:latest"
echo ""

read -p "Do you want to continue? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 0
fi

# Tag and push WebRTC base image
echo "===== Pushing WebRTC Base Image ====="
docker tag lulumarjan/webrtc-base:latest $DOCKER_USERNAME/webrtc-base:latest
docker push $DOCKER_USERNAME/webrtc-base:latest
echo "WebRTC base image pushed successfully."
echo ""

# Tag and push LLM base image
echo "===== Pushing LLM Base Image ====="
docker tag lulumarjan/llm-base:latest $DOCKER_USERNAME/llm-base:latest
docker push $DOCKER_USERNAME/llm-base:latest
echo "LLM base image pushed successfully."
echo ""

# Tag and push TTS base image
echo "===== Pushing TTS Base Image ====="
docker tag lulumarjan/tts-base:latest $DOCKER_USERNAME/tts-base:latest
docker push $DOCKER_USERNAME/tts-base:latest
echo "TTS base image pushed successfully."
echo ""

echo "===== All Base Images Pushed Successfully ====="
echo ""
echo "Now you need to update your Dockerfiles to use these images:"
echo "1. Edit webrtc/Dockerfile: FROM $DOCKER_USERNAME/webrtc-base:latest"
echo "2. Edit llm/Dockerfile: FROM $DOCKER_USERNAME/llm-base:latest"
echo "3. Edit tts/Dockerfile: FROM $DOCKER_USERNAME/tts-base:latest"
echo ""
echo "After updating the Dockerfiles, you can build and run the application with:"
echo "docker-compose up --build -d"