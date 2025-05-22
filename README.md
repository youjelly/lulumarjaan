# LuluMarjan - Ultravox Clone

A real-time voice assistant system inspired by Ultravox, combining Llama-3 LLM and OpenVoice v2 for advanced text-to-speech capabilities.

## Architecture

This project consists of 5 microservices:

1. **WebRTC Server** - Golang-based Pion WebRTC service for real-time audio communication
2. **API Gateway** - Node.js Express server that provides REST endpoints and WebSocket connections
3. **LLM Service** - Python service running Llama-3 for text generation
4. **TTS Service** - Python service running OpenVoice v2 for text-to-speech and voice cloning
5. **Database** - MongoDB for persistent storage of user data and voice models

## Features

- Real-time voice conversations through WebRTC
- Text chat with Llama-3 LLM
- High-quality text-to-speech using OpenVoice v2
- Voice cloning capabilities
- OpenAI-compatible API endpoints

## Prerequisites

- Docker and Docker Compose
- NVIDIA GPU with CUDA support (for optimal LLM and TTS performance)
- Docker NVIDIA Container Toolkit (for GPU support)

## Getting Started

### Installation

1. Clone this repository:

```bash
git clone https://github.com/yourusername/lulumarjan.git
cd lulumarjan
```

2. Build and start the services:

```bash
docker-compose up -d
```

3. Access the web client at: http://localhost:3000/

## Service Endpoints

### API Gateway (port 3000)

- `/v1/chat/completions` - LLM text generation (OpenAI-compatible)
- `/v1/audio/speech` - Text-to-speech conversion
- `/v1/audio/clone` - Voice cloning
- WebSocket for real-time communication

### LLM Service (port 5000)

- `/generate` - Text generation with Llama-3
- `/models` - List available models

### TTS Service (port 6000)

- `/tts` - Text-to-speech conversion
- `/clone` - Voice cloning
- `/voices` - List available voices

### WebRTC Server (port 8080)

- `/ws` - WebSocket endpoint for WebRTC signaling

## Development

To develop each service individually:

### WebRTC Server

```bash
cd webrtc
go mod download
go run cmd/server/main.go
```

### API Gateway

```bash
cd api
npm install
npm run dev
```

### LLM Service

```bash
cd llm
pip install -r requirements.txt
python app.py
```

### TTS Service

```bash
cd tts
pip install -r requirements.txt
python server.py
```

## License

MIT
