#!/bin/bash

# Cleanup script to remove old files from root partition that were created before using /mnt/data
# This script helps free up space on the root partition

echo "=== Root Disk Cleanup Script ==="
echo "This will remove old cache files and virtual environments from the root partition"
echo ""

# Show current disk usage
echo "Current disk usage:"
df -h / /mnt/data
echo ""

# Calculate space that will be freed
SPACE_TO_FREE=0

# Check Hugging Face cache in home directory
if [ -d "$HOME/.cache/huggingface" ]; then
    HF_SIZE=$(du -sh "$HOME/.cache/huggingface" 2>/dev/null | cut -f1)
    echo "Found Hugging Face cache in $HOME/.cache/huggingface: $HF_SIZE"
    SPACE_TO_FREE=1
fi

# Check old virtual environments in project directory
if [ -d "./real-venv" ] && [ ! -L "./real-venv" ]; then
    VENV_SIZE=$(du -sh "./real-venv" 2>/dev/null | cut -f1)
    echo "Found old real-venv directory: $VENV_SIZE"
    SPACE_TO_FREE=1
fi

if [ -d "./simple-venv" ] && [ ! -L "./simple-venv" ]; then
    SIMPLE_VENV_SIZE=$(du -sh "./simple-venv" 2>/dev/null | cut -f1)
    echo "Found old simple-venv directory: $SIMPLE_VENV_SIZE"
    SPACE_TO_FREE=1
fi

# Check old shared_storage if it's not a symlink
if [ -d "./shared_storage" ] && [ ! -L "./shared_storage" ]; then
    STORAGE_SIZE=$(du -sh "./shared_storage" 2>/dev/null | cut -f1)
    echo "Found old shared_storage directory: $STORAGE_SIZE"
    SPACE_TO_FREE=1
fi

# Check for downloaded tar files
TAR_FILES=$(find . -maxdepth 1 -name "*.tar.gz" -o -name "*.tar" 2>/dev/null)
if [ ! -z "$TAR_FILES" ]; then
    echo "Found tar files:"
    ls -lh *.tar.gz *.tar 2>/dev/null | grep -v "cannot access"
    SPACE_TO_FREE=1
fi

if [ $SPACE_TO_FREE -eq 0 ]; then
    echo ""
    echo "No old files found to clean up. Root disk is already clean!"
    exit 0
fi

echo ""
read -p "Do you want to remove these files to free up space? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning up old files..."
    
    # Remove Hugging Face cache from home directory
    if [ -d "$HOME/.cache/huggingface" ]; then
        echo "Removing old Hugging Face cache..."
        rm -rf "$HOME/.cache/huggingface"
    fi
    
    # Remove old transformers cache
    if [ -d "$HOME/.cache/torch" ]; then
        echo "Removing old PyTorch cache..."
        rm -rf "$HOME/.cache/torch"
    fi
    
    # Remove old virtual environments (only if they're not symlinks)
    if [ -d "./real-venv" ] && [ ! -L "./real-venv" ]; then
        echo "Removing old real-venv directory..."
        rm -rf "./real-venv"
    fi
    
    if [ -d "./simple-venv" ] && [ ! -L "./simple-venv" ]; then
        echo "Removing old simple-venv directory..."
        rm -rf "./simple-venv"
    fi
    
    # Remove old shared_storage (only if it's not a symlink)
    if [ -d "./shared_storage" ] && [ ! -L "./shared_storage" ]; then
        echo "Removing old shared_storage directory..."
        rm -rf "./shared_storage"
    fi
    
    # Remove downloaded tar files
    if [ ! -z "$TAR_FILES" ]; then
        echo "Removing tar files..."
        rm -f *.tar.gz *.tar 2>/dev/null
    fi
    
    # Clean pip cache
    echo "Cleaning pip cache..."
    pip cache purge 2>/dev/null || true
    
    # Clean apt cache
    echo "Cleaning apt cache..."
    sudo apt-get clean 2>/dev/null || true
    
    echo ""
    echo "Cleanup complete! New disk usage:"
    df -h / /mnt/data
    
    echo ""
    echo "=== Reminder ==="
    echo "All new downloads and caches will now go to /mnt/data"
    echo "Make sure your .env file has the correct paths set"
else
    echo "Cleanup cancelled."
fi