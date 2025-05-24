#!/bin/bash

# Setup script for REAL services with GPU support
echo "Setting up real services with GPU support..."

# Check for GPU
if ! nvidia-smi > /dev/null 2>&1; then
    echo "Error: No GPU detected. Real services require a GPU."
    exit 1
fi

echo "GPU detected:"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv ffmpeg libsndfile1 git

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Use /mnt/data for virtual environment to avoid disk space issues
VENV_PATH="${VENV_PATH:-/mnt/data/real-venv}"

# Create virtual environment for real services
echo "Creating Python virtual environment for real services at $VENV_PATH..."
python3 -m venv $VENV_PATH

# Create symlink for backward compatibility
ln -sf $VENV_PATH real-venv

# Activate virtual environment
source $VENV_PATH/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install PyTorch with CUDA support
echo "Installing PyTorch with CUDA support..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install transformers and related packages for LLM
echo "Installing LLM dependencies..."
pip install transformers>=4.40.0 accelerate>=0.30.0 bitsandbytes>=0.43.0 sentencepiece protobuf

# Install additional dependencies for Ultravox
pip install librosa soundfile

# Install Flask and API dependencies
echo "Installing API dependencies..."
pip install flask flask-cors python-dotenv

# Install TTS dependencies
echo "Installing TTS dependencies..."
pip install numpy==1.24.3 scipy librosa==0.10.0 soundfile pydub

# Try to install OpenVoice (may need special handling)
echo "Installing OpenVoice..."
pip install git+https://github.com/myshell-ai/OpenVoice.git --no-deps || echo "OpenVoice installation may need manual setup"

# Additional audio processing libraries
pip install webrtcvad
# Skip pyaudio - not required for core functionality
# pip install pyaudio  # Requires portaudio19-dev system package

# Create model directories using /mnt/data
SHARED_STORAGE="${SHARED_STORAGE:-/mnt/data/shared_storage}"
echo "Creating model directories at $SHARED_STORAGE..."
mkdir -p $SHARED_STORAGE/models/llm
mkdir -p $SHARED_STORAGE/models/tts/base_model
mkdir -p $SHARED_STORAGE/models/tts/speaker_embeddings
mkdir -p $SHARED_STORAGE/voices
mkdir -p $SHARED_STORAGE/data/mongodb
mkdir -p ./logs

# Create symlink for backward compatibility
ln -sf $SHARED_STORAGE shared_storage

# Create Hugging Face cache directory
HF_HOME="${HF_HOME:-/mnt/data/huggingface_cache}"
echo "Creating Hugging Face cache directory at $HF_HOME..."
mkdir -p $HF_HOME

# Set permissions
chmod -R 777 $SHARED_STORAGE
chmod -R 777 $HF_HOME
chmod -R 777 ./logs

# Deactivate virtual environment
deactivate

# Update .env to use real services
echo ""
echo "=== IMPORTANT: Next Steps ==="
echo "1. Add your Hugging Face token to .env file:"
echo "   nano .env"
echo "   HF_TOKEN=hf_your_actual_token_here"
echo ""
echo "2. Run the real services:"
echo "   ./start-real.sh"
echo ""
echo "The first run will download the models (several GB) which may take 10-20 minutes."
echo ""
echo "Setup complete!"