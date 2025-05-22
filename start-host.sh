#!/bin/bash

# Start script for running services directly on the host without Docker

# Clean up any running services from previous runs
echo "Stopping any existing services..."
pkill -f "node index.js" || true
pkill -f "python app.py" || true
pkill -f "python server.py" || true
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

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    # Source the environment variables
    source .env
fi

# Environment variables
export HF_TOKEN="$HF_TOKEN"
export HUGGINGFACE_TOKEN="$HF_TOKEN"
export TRANSFORMERS_OFFLINE=0
echo "Using HF token: $HF_TOKEN"
export MODELS_STORAGE_PATH="$(pwd)/shared_storage/models"
export VOICES_STORAGE_PATH="$(pwd)/shared_storage/voices"
export DATA_STORAGE_PATH="$(pwd)/shared_storage/data"

# MongoDB is optional
if command -v mongod &> /dev/null; then
    echo "Starting MongoDB..."
    mkdir -p "$DATA_STORAGE_PATH/mongodb"
    mongod --dbpath "$DATA_STORAGE_PATH/mongodb" --fork --logpath "$DATA_STORAGE_PATH/mongodb/mongod.log" || echo "Failed to start MongoDB. Will continue without database."
else
    echo "MongoDB not found. Will continue without database features."
fi

# Function to start a service
start_service() {
    echo "Starting $1 service..."
    cd $1
    case $1 in
        "api")
            # Install dependencies if needed
            if [ ! -d "node_modules" ]; then
                echo "Installing Node.js dependencies..."
                npm install
            fi
            
            # Set environment variables for API
            export PORT=3001
            export LLM_SERVICE_URL="http://localhost:5000"
            export TTS_SERVICE_URL="http://localhost:6000"
            export WEBRTC_SERVICE_URL="http://localhost:8080"
            # Only set MongoDB URI if MongoDB is available
            if command -v mongod &> /dev/null; then
                export MONGODB_URI="mongodb://localhost:27017/lulumarjan"
            else
                export SKIP_DATABASE=true
            fi
            
            # Start API service
            node index.js &
            ;;
            
        "llm")
            # Create Python virtual environment if it doesn't exist
            if [ ! -d "venv" ]; then
                echo "Creating Python virtual environment for LLM service..."
                python -m venv venv
            fi
            
            # Activate virtual environment
            source venv/bin/activate
            
            # Install dependencies
            pip install -r requirements.txt
            
            # Set environment variables for LLM
            export MODEL_ID="bigscience/bloom-560m"
            export USE_4BIT="true"
            export LOAD_IN_8BIT="false"
            export SERVE_PORT=5000
            export TRANSFORMERS_CACHE="$MODELS_STORAGE_PATH/llm"
            export PYTHONUNBUFFERED=1
            
            # Start LLM service
            python app.py &
            
            # Deactivate virtual environment
            deactivate
            ;;
            
        "tts")
            # Create Python virtual environment if it doesn't exist
            if [ ! -d "venv" ]; then
                echo "Creating Python virtual environment for TTS service..."
                python -m venv venv
            fi
            
            # Activate virtual environment
            source venv/bin/activate
            
            # Install dependencies with proper versions for OpenVoice
            pip install -r requirements.txt --force-reinstall
            
            # Install OpenVoice v2 (simplified installation without cloning repo)
            if ! pip list | grep -q "myshell-openvoice"; then
                echo "Installing OpenVoice..."
                pip install git+https://github.com/myshell-ai/OpenVoice.git --no-deps
            fi
            
            # Set environment variables for TTS
            export TTS_PORT=6000
            export BASE_MODEL_PATH="$MODELS_STORAGE_PATH/tts/base_model"
            export SPEAKER_EMBEDDINGS_PATH="$MODELS_STORAGE_PATH/tts/speaker_embeddings"
            export CUSTOM_VOICES_PATH="$VOICES_STORAGE_PATH"
            export PYTHONUNBUFFERED=1
            
            # Start TTS service
            if python server.py &
            then
                echo "TTS service started successfully"
            else
                echo "TTS service failed to start, using mock server instead"
                python mock-server.py &
            fi
            
            # Deactivate virtual environment
            deactivate
            ;;
            
        "webrtc")
            # Make sure Go is installed
            if ! command -v go &> /dev/null; then
                echo "Go is not installed. Please install Go to run the WebRTC service."
                echo "Visit https://go.dev/doc/install for installation instructions."
                return 1
            fi
            
            # Check if Node.js WebRTC server should be used as fallback
            if ! go version | grep -q "go1.1"; then
                echo "Using Go for WebRTC server"
                # Get dependencies
                go mod tidy || go get github.com/gorilla/websocket github.com/pion/webrtc/v3
                
                # Build and start WebRTC service
                go run cmd/server/main.go &
            else
                echo "Using Node.js fallback for WebRTC server"
                # Check if we need to install ws package
                if [ ! -f "node_modules/ws/package.json" ]; then
                    npm install ws
                fi
                # Run the Node.js version
                node server.js &
            fi
            ;;
    esac
    cd ..
}

# Start each service
start_service "webrtc"
start_service "llm"
start_service "tts"
start_service "api"

# Serve client files with Python HTTP server
echo "Starting web client on http://localhost:8000..."
cd client
python3 -m http.server 8000 &
cd ..

echo ""
echo "All services started!"
echo "- API Gateway: http://localhost:3001"
echo "- LLM Service: http://localhost:5000"
echo "- TTS Service: http://localhost:6000"
echo "- WebRTC Server: ws://localhost:8080/ws"
echo "- Web Client: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop all services."

# Wait for user to press Ctrl+C
wait