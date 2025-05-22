#!/bin/bash

# Complete setup script for all services

echo "Setting up Ultravox clone system..."

# Kill any running services
echo "Stopping any existing services..."
pkill -f "node index.js" || true
pkill -f "python app.py" || true
pkill -f "python server.py" || true
pkill -f "python simple-app.py" || true
pkill -f "python simple-server.py" || true
pkill -f "go run cmd/server/main.go" || true
pkill -f "node server.js" || true
pkill -f "python -m http.server 8000" || true

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

# Create virtual environment for simplified services
echo "Creating virtual environment for simplified services..."
python3 -m venv simple-venv

# Activate virtual environment
source simple-venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install flask flask-cors python-dotenv

# Create mock files
echo "Creating mock files..."

# Create a simple mock TTS WAV file
echo "Creating mock TTS audio file..."
cat > tts/silence.wav << 'EOF'
RIFF$    WAVEfmt      @     data    
EOF

# Deactivate virtual environment
deactivate

# Set up API service
echo "Setting up API service..."
cd api
npm install
cd ..

echo "Setup complete!"
echo "Run ./start-simple.sh to start all services."