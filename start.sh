#!/bin/bash

# Start script for development without Docker

# Check if .env file exists, if not, create from example
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example"
    cp .env.example .env
    # Source the environment variables
    source .env
fi

# Create shared storage directories
mkdir -p "${MODELS_STORAGE_PATH:-./shared_storage/models}/llm"
mkdir -p "${MODELS_STORAGE_PATH:-./shared_storage/models}/tts/base_model"
mkdir -p "${MODELS_STORAGE_PATH:-./shared_storage/models}/tts/speaker_embeddings"
mkdir -p "${VOICES_STORAGE_PATH:-./shared_storage/voices}"
mkdir -p "${DATA_STORAGE_PATH:-./shared_storage/data}/mongodb"

# Set correct permissions
chmod -R 777 "${MODELS_STORAGE_PATH:-./shared_storage}"
chmod -R 777 "${VOICES_STORAGE_PATH:-./shared_storage/voices}"
chmod -R 777 "${DATA_STORAGE_PATH:-./shared_storage/data}"

# Function to start a service
start_service() {
    echo "Starting $1 service..."
    cd $1
    case $1 in
        "api")
            npm install
            npm run dev &
            ;;
        "webrtc")
            go mod download
            go run cmd/server/main.go &
            ;;
        "llm")
            # Set Hugging Face token for model downloads
            export HUGGINGFACE_TOKEN="${HF_TOKEN}"
            export TRANSFORMERS_CACHE="${MODELS_STORAGE_PATH:-./shared_storage/models}/llm"
            
            python -m pip install -r requirements.txt
            python app.py &
            ;;
        "tts")
            # Set Hugging Face token for model downloads
            export HUGGINGFACE_TOKEN="${HF_TOKEN}"
            
            python -m pip install -r requirements.txt
            python server.py &
            ;;
    esac
    cd ..
}

# Start each service
start_service "webrtc"
start_service "llm"
start_service "tts"
start_service "api"

# Serve client files
echo "Serving client files on http://localhost:8000"
cd client
python -m http.server &
cd ..

echo "All services started!"
echo "- API: http://localhost:3000"
echo "- WebRTC: http://localhost:8080"
echo "- Client: http://localhost:8000"
echo "- LLM: http://localhost:5000"
echo "- TTS: http://localhost:6000"
echo "Press Ctrl+C to stop all services."

# Wait for user to press Ctrl+C
wait
