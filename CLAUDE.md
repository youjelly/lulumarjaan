# CLAUDE.md - Ultravox Clone Project

This file contains guidance and progress for the Ultravox clone project.

## Project Overview

This project aims to build a clone of Ultravox using:
- Hugging Face Llama-3 model (or BLOOM as an alternative)
- OpenVoice v2 for text-to-speech
- WebRTC using Pion for real-time communication
- Express.js for REST API endpoints
- MongoDB for data persistence

## Project Structure

```
/home/usama/lulumarjan/
├── api/                   # Express.js API server
├── client/                # Web client frontend
├── database/              # MongoDB configuration
├── llm/                   # Language model service
├── shared_storage/        # Shared storage for models and data
├── tts/                   # Text-to-speech service
└── webrtc/                # WebRTC signaling service
```

## Setup Commands

### Full Setup (with Docker)

```bash
# Clone the repository
git clone https://github.com/your-username/lulumarjan.git
cd lulumarjan

# With Docker
docker-compose up
```

### Host-Based Setup (without Docker)

```bash
# Clean setup all services
./setup-all.sh

# Start simplified services
./final-start.sh

# Test if services are working
./test-final.sh
```

## Port Configuration

| Service | Port | URL |
|---------|------|-----|
| API + Web Client | 3000 | http://localhost:3000 |
| LLM | 5000 | http://localhost:5000 |
| TTS | 6000 | http://localhost:6000 |
| WebRTC | 8080 | ws://localhost:8080 |

Note: The web client is now served directly by the API server on port 3000.

## Common Issues and Solutions

### Port Conflicts

If you encounter port conflicts, try:

```bash
# Check what's using the ports
sudo netstat -tuln | grep PORT_NUMBER

# Force kill processes
pkill -9 -f "python"
pkill -9 -f "node"
```

### TTS Service Issues

The TTS service requires specific versions of dependencies:

```bash
# Fix TTS dependencies
cd tts
python -m venv venv
source venv/bin/activate
pip install numpy==1.22.0 librosa==0.9.1 flask==2.3.3 flask-cors==4.0.0
pip install git+https://github.com/myshell-ai/OpenVoice.git --no-deps
deactivate
```

### Python Environment Issues

If you encounter Python environment issues, use the simplified services:

```bash
# Stop all services
./stop-host.sh

# Set up simplified services
./setup-all.sh

# Start simplified services
./final-start.sh
```

## API Documentation

### LLM API

```
POST /v1/chat/completions
```

Request:
```json
{
  "model": "bloom",
  "messages": [{"role": "user", "content": "Hello!"}],
  "max_tokens": 50,
  "temperature": 0.7
}
```

### TTS API

```
POST /v1/audio/speech
```

Request:
```json
{
  "text": "Hello, how are you?",
  "voice": "default",
  "format": "mp3",
  "speed": 1.0
}
```

### Voice Cloning API

```
POST /v1/audio/clone
```

Multipart form data:
- audioFile: Audio file with voice sample
- name: Name for the cloned voice
- description: Description of the voice

## Script Overview

### Maintenance Scripts

- `cleanup-root-disk.sh`: Clean up old files from root partition
  - Removes old Hugging Face cache from `~/.cache/huggingface`
  - Removes old virtual environments if they're not symlinks
  - Removes old shared_storage if it's not a symlink
  - Cleans up downloaded tar files
  - Cleans pip and apt caches
  - Shows disk usage before and after cleanup

- `download-models.sh`: Download AI models before starting services
  - Sets up environment variables from .env
  - Activates the virtual environment
  - Downloads models to /mnt/data/huggingface_cache
  - Shows download progress and final size
  
- `download-model.py`: Python script for model downloading
  - Downloads Ultravox model and processor
  - Supports resume on interruption
  - Validates environment before downloading

### Primary Standalone Installation Scripts

There are two sets of standalone scripts:

#### A. Simplified/Mock Services (for testing)
- `setup-all.sh`: Setup for simplified mock services
  - Creates virtual environment in `simple-venv`
  - Creates shared storage directories
  - Installs basic Python dependencies
  
- `final-start.sh`: Start mock services
  - Uses `simple-app.py` and `simple-server.py` for mock LLM and TTS
  - No actual model downloads

#### B. Real Services with Models (Currently Used for Production)
- `setup-real-services.sh` or `setup-ec2.sh`: Setup for real services with GPU
  - Creates virtual environment in `real-venv`
  - Installs PyTorch with CUDA support
  - Installs transformers, accelerate, bitsandbytes for LLM
  - Installs OpenVoice dependencies for TTS
  - Downloads actual models (Ultravox, OpenVoice)
  
- `start-real.sh` or `start-ec2.sh`: Start real services
  - Uses `app.py` for real LLM service with Ultravox model
  - Uses `server.py` for real TTS service with OpenVoice
  - Requires GPU and downloads large models on first run
  - Creates logs in `logs/` directory

- `test-ec2.sh`: Test real services
- `stop-host.sh`: Stop all running services

### Storage Locations

For real services (updated to use `/mnt/data` to avoid disk space issues):
- Virtual environment: `/mnt/data/real-venv` (symlinked to `./real-venv`)
- Shared storage: `/mnt/data/shared_storage` (symlinked to `./shared_storage`)
- Model downloads: `/mnt/data/huggingface_cache` (set via HF_HOME environment variable)
- Logs: `./logs/`

### Important: Disk Space Configuration

To avoid running out of disk space on the root partition, all large files are stored on `/mnt/data`:

1. **Environment Variables** (set in `.env`):
   ```bash
   HF_HOME=/mnt/data/huggingface_cache
   TRANSFORMERS_CACHE=/mnt/data/huggingface_cache
   HF_DATASETS_CACHE=/mnt/data/huggingface_cache/datasets
   SHARED_STORAGE=/mnt/data/shared_storage
   VENV_PATH=/mnt/data/real-venv
   ```

2. **Setup Process**:
   - Copy `.env.example` to `.env` and update with your HF token
   - Run `./setup-real-services.sh` or `./setup-ec2.sh` 
   - This will create all directories on `/mnt/data` automatically

3. **Model Downloads**:
   - All Hugging Face models will be cached in `/mnt/data/huggingface_cache`
   - Ultravox model (~2-5GB depending on version)
   - OpenVoice models (~1-2GB)

## Recent Updates (May 24, 2025)

1. **Disk Space Management**
   - Configured all services to use `/mnt/data` for storage
   - Model downloads go to `/mnt/data/huggingface_cache`
   - Virtual environments at `/mnt/data/real-venv`
   - Added cleanup script for root partition

2. **Model Download Process**
   - Created `download-models.sh` for pre-downloading models
   - Modified `app.py` to prevent automatic downloads
   - Model must be downloaded before starting services

3. **Unified Web Serving**
   - Web client now served by API server on port 3000
   - Eliminated separate Python http.server on port 8000
   - Simplified deployment with single entry point

4. **Working Configuration**
   - Ultravox model running at full precision (~32GB GPU)
   - All services functional and tested
   - Proper environment variable handling

## Future Improvements

1. Add authentication and API key validation
2. Improve WebRTC connections for voice streaming
3. Implement voice cloning with OpenVoice
4. Add proper production deployment (systemd services)
5. Implement model quantization options for smaller GPUs
6. Add monitoring and metrics
7. Improve error handling and recovery
8. Add support for streaming responses

## Troubleshooting

If services don't respond after starting:
1. Check if they're actually running with `ps aux | grep python` and `ps aux | grep node`
2. Look for errors in the terminal output
3. Try starting each service manually
4. Verify no other services are using the same ports
5. Check firewall settings if accessing remotely