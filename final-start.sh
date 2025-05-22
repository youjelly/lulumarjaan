#!/bin/bash

# Simple start script for running services directly on the host

echo "Starting Ultravox clone services..."

# Clean up any running services
echo "Stopping any existing services..."
pkill -f "node index.js" || true
pkill -f "python app.py" || true
pkill -f "python server.py" || true
pkill -f "python simple-app.py" || true
pkill -f "python simple-server.py" || true
pkill -f "go run cmd/server/main.go" || true
pkill -f "node server.js" || true
pkill -f "python -m http.server 8000" || true

# Set environment variables
export PORT=4000
export LLM_SERVICE_URL="http://localhost:5000"
export TTS_SERVICE_URL="http://localhost:6000"
export WEBRTC_SERVICE_URL="http://localhost:8080"
export SERVE_PORT=5000
export TTS_PORT=6000

# Start WebRTC service
echo "Starting WebRTC service..."
cd webrtc
export PORT=8080
node server.js &
cd ..
sleep 2
echo "WebRTC service started on port 8080"

# Start LLM service
echo "Starting LLM service..."
cd llm
../simple-venv/bin/python simple-app.py &
cd ..
sleep 2
echo "LLM service started on port 5000"

# Start TTS service
echo "Starting TTS service..."
cd tts
../simple-venv/bin/python simple-server.py &
cd ..
sleep 2
echo "TTS service started on port 6000"

# Start API service
echo "Starting API service..."
cd api
node index.js &
cd ..
sleep 2
echo "API service started on port 4000"

# Serve client files
echo "Starting web client..."
cd client
python3 -m http.server 8000 &
cd ..
sleep 2
echo "Web client started on port 8000"

echo ""
echo "All services started successfully!"
echo "- API Gateway: http://localhost:4000"
echo "- LLM Service: http://localhost:5000"
echo "- TTS Service: http://localhost:6000"
echo "- WebRTC Server: ws://localhost:8080"
echo "- Web Client: http://localhost:8000"
echo ""
echo "To test services, run: ./test-final.sh"
echo ""
echo "Press Ctrl+C to stop all services."

# Wait for user to press Ctrl+C
wait