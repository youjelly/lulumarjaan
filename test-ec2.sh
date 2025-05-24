#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please run ./setup-ec2.sh first."
    exit 1
fi

echo "Testing Ultravox clone services on EC2..."
echo "Public IP: $PUBLIC_IP"

# Test API service
echo ""
echo "Testing API service..."
curl -s http://localhost:$API_PORT/health || echo "API service not responding locally"
echo ""
curl -s http://$PUBLIC_IP:$API_PORT/health || echo "API service not responding on public IP"

# Test LLM service
echo ""
echo "Testing LLM service..."
curl -s http://localhost:$LLM_PORT/health || echo "LLM service not responding locally"

# Test TTS service
echo ""
echo "Testing TTS service..."
curl -s http://localhost:$TTS_PORT/health || echo "TTS service not responding locally"

# Test WebRTC service
echo ""
echo "Testing WebRTC service..."
curl -s http://localhost:$WEBRTC_PORT || echo "WebRTC service not responding locally"

# Test simple text generation
echo ""
echo "Testing text generation via API..."
curl -s -X POST http://localhost:$API_PORT/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bloom",
    "messages": [{"role": "user", "content": "Give me a short greeting in 10 words or less."}],
    "max_tokens": 50,
    "temperature": 0.7
  }' | jq . || echo "Text generation API not responding"

# Test from public IP
echo ""
echo "Testing text generation via public IP..."
curl -s -X POST http://$PUBLIC_IP:$API_PORT/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bloom",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50,
    "temperature": 0.7
  }' | jq . || echo "Text generation API not responding on public IP"

# Test voice list
echo ""
echo "Testing voice list via TTS service..."
curl -s http://localhost:$TTS_PORT/voices | jq . || echo "TTS voices API not responding"

echo ""
echo "Testing complete!"
echo ""
echo "You can now access the Ultravox clone through the web interface at:"
echo "http://$PUBLIC_IP:$CLIENT_PORT"
echo ""
echo "If some services are not responding on the public IP, make sure your EC2 security group"
echo "allows inbound traffic on ports: $API_PORT, $LLM_PORT, $TTS_PORT, $WEBRTC_PORT, $CLIENT_PORT"