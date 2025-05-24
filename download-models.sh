#!/bin/bash

# Script to download models with proper environment setup

echo "Setting up environment for model download..."

# Load environment variables from .env
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found!"
    echo "Please ensure .env file exists with your HF_TOKEN"
    exit 1
fi

# Export necessary environment variables
export HF_HOME="${HF_HOME:-/mnt/data/huggingface_cache}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-/mnt/data/huggingface_cache}"
export HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-/mnt/data/huggingface_cache/datasets}"
export HF_TOKEN="${HF_TOKEN}"

# Check if HF_TOKEN is set
if [ -z "$HF_TOKEN" ] || [ "$HF_TOKEN" = "hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    echo "Error: HF_TOKEN not properly set in .env file"
    echo "Please edit .env and add your Hugging Face token"
    exit 1
fi

echo "HF_TOKEN is set (first 10 chars): ${HF_TOKEN:0:10}..."

# Activate virtual environment
VENV_PATH="${VENV_PATH:-/mnt/data/real-venv}"
if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found at $VENV_PATH"
    echo "Please run ./setup-real-services.sh first"
    exit 1
fi

echo "Activating virtual environment..."
source $VENV_PATH/bin/activate

# Create cache directory if it doesn't exist
mkdir -p $HF_HOME

echo ""
echo "Environment configured:"
echo "- HF_HOME: $HF_HOME"
echo "- Virtual env: $VENV_PATH"
echo "- Model: fixie-ai/ultravox-v0_5-llama-3_1-8b"
echo ""

# Run the download script
python download-model.py

# Deactivate virtual environment
deactivate

echo ""
echo "Download process complete!"