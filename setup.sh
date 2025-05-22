#!/bin/bash

# LuluMarjan Project Setup Script
# This script sets up the entire project structure and environment

# Create shared storage directories
echo "Creating shared storage directories..."
mkdir -p ./shared_storage/models/llm
mkdir -p ./shared_storage/models/tts/base_model
mkdir -p ./shared_storage/models/tts/speaker_embeddings
mkdir -p ./shared_storage/voices
mkdir -p ./shared_storage/data/mongodb

# Set permissions
echo "Setting directory permissions..."
chmod -R 777 ./shared_storage

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
else
    echo ".env file already exists, skipping..."
fi

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if NVIDIA Container Toolkit is installed (for GPU support)
if docker info | grep -q "Runtimes: nvidia"; then
    echo "NVIDIA Container Toolkit is installed."
else
    echo "WARNING: NVIDIA Container Toolkit not detected. GPU acceleration may not be available."
    echo "See https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html for installation instructions."
fi

# Ask about building base images
read -p "Do you want to build base Docker images locally? (Y/n): " build_base
if [[ "$build_base" =~ ^([yY]|[yY][eE][sS]|"")$ ]]; then
    echo "Building base Docker images locally..."
    echo "This may take some time but makes future builds faster."

    # Set DockerHub username
    DOCKER_USERNAME="usamazaidi"
    echo "Using DockerHub username: $DOCKER_USERNAME"
    
    echo "Building WebRTC base image..."
    docker build -t $DOCKER_USERNAME/webrtc-base:latest -f webrtc/Dockerfile.base webrtc/

    echo "Building LLM base image..."
    docker build -t $DOCKER_USERNAME/llm-base:latest -f llm/Dockerfile.base llm/

    echo "Building TTS base image..."
    docker build -t $DOCKER_USERNAME/tts-base:latest -f tts/Dockerfile.base tts/

    echo "All base images built locally successfully!"
    
    echo "If you want to push these images to DockerHub later, use:"
    echo "./push-base-images.sh"
else
    echo "Skipping base image builds."
    echo "Make sure the base images are available locally or in your Dockerfiles."
fi

# Ask user if they want to start the services
read -p "Do you want to start the services now? (Y/n): " start_services
if [[ "$start_services" =~ ^([yY]|[yY][eE][sS]|"")$ ]]; then
    echo "Starting services with Docker Compose..."
    docker-compose up -d
    
    echo ""
    echo "Services have been started:"
    echo "- API Gateway: http://localhost:3000"
    echo "- WebRTC Server: ws://localhost:8080/ws"
    echo "- Web Client: http://localhost:8000"
    
    echo ""
    echo "You can stop the services with: docker-compose down"
    echo "You can view logs with: docker-compose logs -f"
else
    echo ""
    echo "Setup completed. You can start the services later with:"
    echo "docker-compose up -d"
fi

echo ""
echo "LuluMarjan setup completed!"