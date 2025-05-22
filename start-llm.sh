#!/bin/bash

# Script to start the actual LLM service (not the mock version)

echo "Stopping any running LLM services..."
pkill -f "python app.py" || true
pkill -f "python simple-app.py" || true

# Set environment variables from .env file
if [ -f ".env" ]; then
  echo "Loading environment variables from .env file..."
  export $(grep -v '^#' .env | xargs)
fi

# Make sure MODEL_ID is set to Ultravox
if [ -z "$MODEL_ID" ]; then
  echo "MODEL_ID not found in .env, setting to default Ultravox model..."
  export MODEL_ID="fixie-ai/ultravox-v0_5-llama-3_2-1b"
fi

echo "Using model: $MODEL_ID"

# Check if virtual environment exists, if not create it
if [ ! -d "llm/venv" ]; then
  echo "Creating Python virtual environment for LLM service..."
  cd llm
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  deactivate
  cd ..
fi

# Start the LLM service
echo "Starting LLM service with Ultravox model..."
cd llm
source venv/bin/activate
python app.py &
deactivate
cd ..

echo "LLM service started on port ${SERVE_PORT:-5000}"
echo "Using model: $MODEL_ID"