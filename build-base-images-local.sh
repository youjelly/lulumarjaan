#!/bin/bash

# Script to build all base images for LuluMarjan project locally
# This will build base images for WebRTC, LLM, and TTS services without pushing to Docker Hub

echo "===== Building LuluMarjan Base Images Locally ====="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Set DockerHub username
DOCKER_USERNAME="usamazaidi"
echo "Using DockerHub username: $DOCKER_USERNAME"
echo ""

# Build WebRTC base image
echo "===== Building WebRTC Base Image ====="
docker build -t $DOCKER_USERNAME/webrtc-base:latest -f webrtc/Dockerfile.base webrtc/
echo "WebRTC base image built successfully."
echo ""

# Build LLM base image
echo "===== Building LLM Base Image ====="
docker build -t $DOCKER_USERNAME/llm-base:latest -f llm/Dockerfile.base llm/
echo "LLM base image built successfully."
echo ""

# Build TTS base image
echo "===== Building TTS Base Image ====="
docker build -t $DOCKER_USERNAME/tts-base:latest -f tts/Dockerfile.base tts/
echo "TTS base image built successfully."
echo ""

echo "===== All Base Images Built Successfully ====="
echo ""
echo "You can now build and run the full application with:"
echo "docker-compose up --build -d"