#!/bin/bash

# Start script for running simplified services directly on the host

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
export PORT=3002
export LLM_SERVICE_URL="http://localhost:5000"
export TTS_SERVICE_URL="http://localhost:6000"
export WEBRTC_SERVICE_URL="http://localhost:8080"
export SERVE_PORT=5000
export TTS_PORT=6000

# Start WebRTC service
echo "Starting WebRTC service..."
cd webrtc
node server.js &
cd ..

# Start LLM service
echo "Starting LLM service..."
cd llm
../simple-venv/bin/python simple-app.py &
cd ..

# Start TTS service
echo "Starting TTS service..."
cd tts
../simple-venv/bin/python simple-server.py &
cd ..

# Start API service
echo "Starting API service..."
cd api
if [ ! -d "node_modules" ]; then
    echo "Installing Node.js dependencies..."
    npm install
fi
node index.js &
cd ..

# Serve client files
echo "Starting web client on http://localhost:8000..."
cd client
python3 -m http.server 8000 &
cd ..

echo ""
echo "All simplified services started!"
echo "- API Gateway: http://localhost:3002"
echo "- LLM Service: http://localhost:5000"
echo "- TTS Service: http://localhost:6000"
echo "- WebRTC Server: ws://localhost:8080/ws"
echo "- Web Client: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop all services."

# Wait for user to press Ctrl+C
wait