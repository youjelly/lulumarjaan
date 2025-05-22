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
| API | 4000 | http://localhost:4000 |
| LLM | 5000 | http://localhost:5000 |
| TTS | 6000 | http://localhost:6000 |
| WebRTC | 8080 | ws://localhost:8080 |
| Web Client | 8000 | http://localhost:8000 |

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

- `setup-all.sh`: Complete setup for simplified services
- `final-start.sh`: Start all services with proper port configuration
- `test-final.sh`: Test if services are responding correctly
- `stop-host.sh`: Stop all running services
- `fix-tts.sh`: Fix TTS service environment and dependencies

## Future Improvements

1. Fix remaining service connectivity issues
2. Improve mock service functionality to better simulate real behavior
3. Implement proper error handling in all services
4. Add authentication and API key validation
5. Improve WebRTC connections for voice streaming
6. Implement proper model caching
7. Add comprehensive logging
8. Create proper systemd services for production use

## Troubleshooting

If services don't respond after starting:
1. Check if they're actually running with `ps aux | grep python` and `ps aux | grep node`
2. Look for errors in the terminal output
3. Try starting each service manually
4. Verify no other services are using the same ports
5. Check firewall settings if accessing remotely