#!/bin/bash

# Script to test the LLM service

echo "Testing LLM service at http://localhost:5000..."

# Check if the service is running
if ! curl -s http://localhost:5000/health > /dev/null; then
  echo "Error: LLM service is not running. Please start it with ./start-llm.sh"
  exit 1
fi

# Get the model information
echo "Getting model information..."
MODEL_INFO=$(curl -s http://localhost:5000/models | jq -r '.data[0].id')
echo "Using model: $MODEL_INFO"

# Test a simple generation
echo -e "\nTesting generation with a simple prompt..."
curl -s -X POST http://localhost:5000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "system", "content": "You are a helpful voice assistant."},
      {"role": "user", "content": "Tell me a brief joke about programming."}
    ],
    "max_tokens": 100,
    "temperature": 0.7
  }' | jq

echo -e "\nLLM service test complete!"