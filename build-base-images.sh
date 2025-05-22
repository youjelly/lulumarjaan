#!/bin/bash

# Master script to build all base images for LuluMarjan project
# This will build and push base images for WebRTC, LLM, and TTS services

echo "===== Building LuluMarjan Base Images ====="
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

# Build WebRTC base image
echo "===== Building WebRTC Base Image ====="
cd webrtc
./build-base-image.sh
cd ..
echo ""

# Build LLM base image
echo "===== Building LLM Base Image ====="
cd llm
./build-base-image.sh
cd ..
echo ""

# Build TTS base image
echo "===== Building TTS Base Image ====="
cd tts
./build-base-image.sh
cd ..
echo ""

echo "===== All Base Images Built Successfully ====="
echo ""
echo "You can now build and run the full application with:"
echo "docker-compose up --build -d"