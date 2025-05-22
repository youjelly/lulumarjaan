#!/bin/bash

# Setup script for simplified services

echo "Setting up simplified services..."

# Create virtual environment
echo "Creating virtual environment for simplified services..."
python3 -m venv simple-venv

# Activate virtual environment
source simple-venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install flask flask-cors

# Deactivate virtual environment
deactivate

echo "Setup complete!"