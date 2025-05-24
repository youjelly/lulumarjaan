#!/bin/bash

# Start script for REAL services with actual models
echo "Starting Ultravox clone with REAL services on EC2..."

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please run ./setup-real-services.sh first."
    exit 1
fi

# Export Hugging Face cache paths to ensure models download to /mnt/data
export HF_HOME="${HF_HOME:-/mnt/data/huggingface_cache}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-/mnt/data/huggingface_cache}"
export HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-/mnt/data/huggingface_cache/datasets}"

# Use the virtual environment from /mnt/data
VENV_PATH="${VENV_PATH:-/mnt/data/real-venv}"

# Check if HF token is set
if [ "$HF_TOKEN" = "your_hugging_face_token_here" ] || [ -z "$HF_TOKEN" ]; then
    echo "Error: Please set your Hugging Face token in .env file"
    echo "Get your token from: https://huggingface.co/settings/tokens"
    exit 1
fi

# Clean up any running services
echo "Stopping any existing services..."
pkill -f "node index.js" || true
pkill -f "python app.py" || true
pkill -f "python server.py" || true
pkill -f "python simple-app.py" || true
pkill -f "python simple-server.py" || true
pkill -f "go run cmd/server/main.go" || true
pkill -f "node server.js" || true

# Export environment variables for services
export PORT=$API_PORT
export LLM_SERVICE_URL="http://localhost:$LLM_PORT"
export TTS_SERVICE_URL="http://localhost:$TTS_PORT"
export WEBRTC_SERVICE_URL="http://localhost:$WEBRTC_PORT"
export SERVE_PORT=$LLM_PORT
export TTS_PORT=$TTS_PORT
export DEVICE="cuda"

# Create logs directory if it doesn't exist
mkdir -p logs

# Start WebRTC service
echo "Starting WebRTC service..."
cd webrtc
PORT=$WEBRTC_PORT node server.js > ../logs/webrtc.log 2>&1 &
cd ..
sleep 2
echo "WebRTC service started on port $WEBRTC_PORT"

# Start REAL LLM service with Ultravox model
echo "Starting REAL LLM service with Ultravox model..."
echo "This may take a few minutes on first run to download the model..."
cd llm
$VENV_PATH/bin/python app.py > ../logs/llm.log 2>&1 &
cd ..
echo "Waiting for LLM service to initialize..."
sleep 10

# Check if LLM service started
for i in {1..30}; do
    if curl -s http://localhost:$LLM_PORT/health > /dev/null; then
        echo "LLM service is ready!"
        break
    fi
    echo "Waiting for LLM service... ($i/30)"
    sleep 5
done

# Start REAL TTS service with OpenVoice
echo "Starting REAL TTS service with OpenVoice..."
cd tts
$VENV_PATH/bin/python server.py > ../logs/tts.log 2>&1 &
cd ..
echo "Waiting for TTS service to initialize..."
sleep 10

# Check if TTS service started
for i in {1..30}; do
    if curl -s http://localhost:$TTS_PORT/health > /dev/null; then
        echo "TTS service is ready!"
        break
    fi
    echo "Waiting for TTS service... ($i/30)"
    sleep 5
done

# Start API service
echo "Starting API service..."
cd api
PORT=$API_PORT node index.js > ../logs/api.log 2>&1 &
cd ..
sleep 2
echo "API service started on port $API_PORT"

# Client is now served by API server on port $API_PORT
echo "Web client served by API server on port $API_PORT"

echo ""
echo "All services started successfully!"
echo ""
echo "=== GPU Status ==="
nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader
echo ""
echo "=== Access URLs ==="
echo "Web Client & API: http://$PUBLIC_IP:$API_PORT"
echo "LLM Service: http://$PUBLIC_IP:$LLM_PORT"
echo "TTS Service: http://$PUBLIC_IP:$TTS_PORT"
echo "WebRTC Server: ws://$PUBLIC_IP:$WEBRTC_PORT"
echo ""
echo "=== Model Configuration ==="
echo "Model: $MODEL_ID"
echo "8-bit precision: $LOAD_IN_8BIT"
echo "4-bit precision: $USE_4BIT"
echo ""
echo "To monitor logs:"
echo "  tail -f logs/llm.log    # LLM service logs"
echo "  tail -f logs/tts.log    # TTS service logs"
echo "  tail -f logs/api.log    # API service logs"
echo ""
echo "To test services, run: ./test-ec2.sh"
echo ""
echo "Press Ctrl+C to stop all services."

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping all services..."
    pkill -f "node index.js" || true
    pkill -f "python app.py" || true
    pkill -f "python server.py" || true
    pkill -f "go run cmd/server/main.go" || true
    pkill -f "node server.js" || true
    echo "All services stopped."
    exit 0
}

# Set trap for cleanup
trap cleanup INT TERM

# Wait for user to press Ctrl+C
wait