#!/bin/bash

echo "Testing Ultravox clone services..."

# Test API service
echo ""
echo "Testing API service..."
curl -s http://localhost:4000/health || echo "API service not responding"

# Test LLM service
echo ""
echo "Testing LLM service..."
curl -s http://localhost:5000/health || echo "LLM service not responding"

# Test TTS service
echo ""
echo "Testing TTS service..."
curl -s http://localhost:6000/health || echo "TTS service not responding"

# Test WebRTC service
echo ""
echo "Testing WebRTC service..."
curl -s http://localhost:8080 || echo "WebRTC service not responding"

# Test simple text generation
echo ""
echo "Testing text generation via API..."
curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bloom",
    "messages": [{"role": "user", "content": "Give me a short greeting in 10 words or less."}],
    "max_tokens": 50,
    "temperature": 0.7
  }' || echo "Text generation API not responding"

# Test voice list
echo ""
echo "Testing voice list via TTS service..."
curl -s http://localhost:6000/voices || echo "TTS voices API not responding"

echo ""
echo "Testing complete!"
echo ""
echo "You can now use the Ultravox clone through the web interface at:"
echo "http://localhost:8000"