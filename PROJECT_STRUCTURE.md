# LuluMarjan Project Structure

This document explains the organization of the LuluMarjan project.

## Service Architecture

```
┌─────────────┐       ┌─────────────┐      ┌─────────────┐
│    Client   │◄─────►│     API     │◄────►│     LLM     │
│  Web/Mobile │       │   Gateway   │      │   Service   │
└─────────────┘       └─────────────┘      └─────────────┘
       ▲                     ▲                    ▲
       │                     │                    │
       │                     │                    │
       │                     ▼                    │
       │              ┌─────────────┐            │
       └─────────────►│   WebRTC    │◄───────────┘
                      │   Server    │
                      └─────────────┘
                             ▲
                             │
                             ▼
                      ┌─────────────┐
                      │     TTS     │
                      │   Service   │
                      └─────────────┘
                             ▲
                             │
                             ▼
                      ┌─────────────┐
                      │  Database   │
                      │  (MongoDB)  │
                      └─────────────┘
```

## Directory Structure

```
lulumarjan/
├── api/                    # Node.js Express API Gateway
│   ├── Dockerfile          # Container definition
│   ├── index.js            # Main server file
│   └── package.json        # Node.js dependencies
│
├── client/                 # Web client for testing
│   ├── index.html          # Client interface
│   └── script.js           # Client JavaScript
│
├── database/               # MongoDB database
│   ├── Dockerfile          # Container definition
│   └── mongod.conf.example # MongoDB configuration
│
├── llm/                    # Llama-3 Language Model service
│   ├── Dockerfile          # Container definition
│   ├── app.py              # Flask server
│   └── requirements.txt    # Python dependencies
│
├── tts/                    # OpenVoice v2 Text-to-Speech service
│   ├── Dockerfile          # Container definition
│   ├── server.py           # Flask server
│   └── requirements.txt    # Python dependencies
│
├── webrtc/                 # Pion WebRTC service (Go)
│   ├── Dockerfile          # Container definition
│   ├── cmd/server/main.go  # WebRTC server implementation
│   └── go.mod              # Go dependencies
│
├── shared_storage/         # Mounted storage shared between services
│   ├── models/             # ML model files
│   │   ├── llm/            # LLM model cache
│   │   └── tts/            # TTS model files
│   │       ├── base_model/
│   │       └── speaker_embeddings/
│   ├── voices/             # Cloned voice samples and metadata
│   └── data/               # Persistent data
│       └── mongodb/        # MongoDB data files
│
├── .env.example            # Environment variables template
├── .dockerignore           # Files to exclude from Docker build
├── .gitignore              # Files to exclude from git
├── docker-compose.yml      # Service orchestration
├── README.md               # Project documentation
├── PROJECT_STRUCTURE.md    # This file
├── setup.sh                # Project setup script
└── start.sh                # Development startup script
```

## Shared Storage

The `shared_storage` directory contains data that needs to persist across container restarts and be shared between services:

1. **Models** - Machine learning model files
   - LLM models from Hugging Face (cached)
   - TTS base models and speaker embeddings

2. **Voices** - Cloned voice samples and metadata
   - Reference audio files
   - Voice embeddings
   - Metadata files

3. **Data** - Database and application data
   - MongoDB data files
   - Other persistent application data

## Communication Flow

1. **Text Chat Flow**:
   - Client sends text message to API Gateway
   - API forwards to LLM Service
   - LLM generates response text
   - API sends text to TTS Service
   - TTS generates audio file
   - Audio file returned to client

2. **Voice Chat Flow**:
   - Client records audio via microphone
   - WebRTC streams audio to server
   - Audio transcribed to text (simulated in demo)
   - Text sent to LLM for processing
   - LLM response sent to TTS
   - TTS generates speech audio
   - Audio streamed back to client

3. **Voice Cloning Flow**:
   - Client uploads voice sample to API
   - API forwards to TTS Service
   - TTS extracts voice characteristics
   - Voice embedding stored in shared storage
   - Voice ID returned to client
   - Client can use voice ID for future TTS requests