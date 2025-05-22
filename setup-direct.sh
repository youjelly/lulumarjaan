#!/bin/bash

# Setup script for LuluMarjan project without base images

echo "===== LuluMarjan Setup ====="
echo ""

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