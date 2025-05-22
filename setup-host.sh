#!/bin/bash

# Setup script for installing dependencies to run LuluMarjan on host

echo "===== LuluMarjan Host Setup ====="
echo ""

# Check for required package managers
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed. You will need to install it to run the $2 service."
        return 1
    else
        echo "$1 is installed."
        return 0
    fi
}

# Create shared storage directories
echo "Creating shared storage directories..."
mkdir -p ./shared_storage/models/llm
mkdir -p ./shared_storage/models/tts/base_model
mkdir -p ./shared_storage/models/tts/speaker_embeddings
mkdir -p ./shared_storage/voices
mkdir -p ./shared_storage/data/mongodb

# Set permissions
echo "Setting directory permissions..."
chmod -R 777 ./shared_storage

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
fi

# Check for required tools
echo "Checking for required tools..."
check_command "python3" "Python" || MISSING_DEPS=1
check_command "pip" "Python" || MISSING_DEPS=1
check_command "python3-venv" "Python" || echo "python3-venv not found. Will attempt to install."
check_command "node" "Node.js" || MISSING_DEPS=1
check_command "npm" "Node.js" || MISSING_DEPS=1
check_command "go" "Go" || MISSING_DEPS=1
check_command "mongod" "MongoDB" || MISSING_DEPS=1

if [ "$MISSING_DEPS" == "1" ]; then
    echo ""
    echo "Some dependencies are missing. Install them based on your operating system:"
    echo ""
    echo "For Debian 12:"
    echo "sudo apt update"
    echo "sudo apt install python3 python3-pip python3-venv python3-full python3.11-venv nodejs npm golang mongodb"
    echo ""
    echo "For macOS (using Homebrew):"
    echo "brew update"
    echo "brew install python3 node go"
    echo ""
    echo "After installing dependencies, run this script again."
    exit 1
fi

# Install python3-venv if needed
if ! dpkg -l | grep python3.11-venv > /dev/null 2>&1; then
    echo "Installing Python virtual environment package..."
    sudo apt-get update
    sudo apt-get install -y python3-venv python3-full python3.11-venv
fi

# Setup Python virtual environments
echo "Setting up Python virtual environments..."

# LLM service venv
echo "Creating Python virtual environment for LLM service..."
cd llm
rm -rf venv
python3 -m venv venv
if [ -d venv ]; then
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
else
    echo "Failed to create virtual environment for LLM service."
    echo "Try running: sudo apt install python3-venv python3-full python3.11-venv"
fi
cd ..

# TTS service venv
echo "Creating Python virtual environment for TTS service..."
cd tts
rm -rf venv
python3 -m venv venv
if [ -d venv ]; then
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install git+https://github.com/myshell-ai/OpenVoice.git
    deactivate
else
    echo "Failed to create virtual environment for TTS service."
    echo "Try running: sudo apt install python3-venv python3-full python3.11-venv"
fi
cd ..

# Install Node.js dependencies
echo "Installing Node.js dependencies for API service..."
cd api
npm install
cd ..

# Initialize Go module
echo "Setting up Go module for WebRTC service..."
cd webrtc
go mod init github.com/lulumarjan/webrtc || true
go get github.com/gorilla/websocket
go get github.com/pion/webrtc/v3
go mod tidy
cd ..

echo ""
echo "Setup completed! You can now run the services with:"
echo "./start-host.sh"