#!/bin/bash

echo "Fixing TTS service..."

# Stop any running TTS service
pkill -f "python server.py" || true

# Navigate to TTS directory
cd /home/usama/lulumarjan/tts

# Remove existing virtual environment
echo "Removing existing virtual environment..."
rm -rf venv

# Create new virtual environment
echo "Creating new virtual environment..."
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install specific versions of dependencies
echo "Installing dependencies with specific versions..."
pip install --no-cache-dir numpy==1.22.0
pip install --no-cache-dir librosa==0.9.1
pip install --no-cache-dir flask==2.3.3 flask-cors==4.0.0 python-dotenv==1.0.0
pip install --no-cache-dir torch==2.0.1 torchaudio==2.0.2
pip install --no-cache-dir soundfile==0.12.1 pydub==0.25.1 werkzeug==2.3.7 gunicorn==21.2.0

# Install OpenVoice with no dependencies to avoid version conflicts
echo "Installing OpenVoice..."
pip install git+https://github.com/myshell-ai/OpenVoice.git --no-deps

# Show installed packages
echo "Installed packages:"
pip list

deactivate

echo "TTS service fixed successfully. Run start-host.sh to start all services."