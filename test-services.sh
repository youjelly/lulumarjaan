#!/bin/bash

echo "Testing Ultravox clone services..."

# Test API service
echo ""
echo "Testing API service..."
curl -v http://localhost:3002/health
echo ""

# Test LLM service
echo ""
echo "Testing LLM service..."
curl -v http://localhost:5000/health
echo ""

# Test TTS service
echo ""
echo "Testing TTS service..."
curl -v http://localhost:6000/health
echo ""

# Test simple text generation
echo ""
echo "Testing text generation via API..."
curl -s -X POST http://localhost:3002/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bloom",
    "messages": [{"role": "user", "content": "Give me a short greeting in 10 words or less."}],
    "max_tokens": 50,
    "temperature": 0.7
  }'
echo ""

# Test voice list
echo ""
echo "Testing voice list via TTS service..."
curl -s http://localhost:6000/voices
echo ""

echo ""
echo "Testing complete!"