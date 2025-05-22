#!/usr/bin/env python3
"""
Mock TTS server that responds to API requests but doesn't actually generate speech.
This is a temporary workaround until the full TTS service can be made to work.
"""

import os
import io
import json
import logging
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from dotenv import load_dotenv

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
SERVE_PORT = int(os.getenv('TTS_PORT', 6000))
CUSTOM_VOICES_PATH = os.getenv('CUSTOM_VOICES_PATH', './voices')

# Ensure directories exist
os.makedirs(CUSTOM_VOICES_PATH, exist_ok=True)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "ok"}), 200

@app.route('/voices', methods=['GET'])
def list_voices():
    """List available voices"""
    voices = [
        {"id": "default", "name": "Default", "type": "base"},
        {"id": "warm", "name": "Warm", "type": "base"},
        {"id": "bright", "name": "Bright", "type": "base"},
        {"id": "calm", "name": "Calm", "type": "base"},
    ]
    return jsonify({"voices": voices})

@app.route('/tts', methods=['POST'])
def text_to_speech():
    """Text-to-speech endpoint (mock)"""
    data = request.json
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    text = data.get('text')
    voice = data.get('voice', 'default')
    format = data.get('format', 'mp3')
    
    if not text:
        return jsonify({"error": "Text is required"}), 400
    
    try:
        # Generate a silent audio file
        logger.info(f"Mock TTS request for text: {text[:30]}... (voice: {voice})")
        
        # Create a small silent WAV file in memory
        buffer = io.BytesIO()
        with open("silence.wav", "rb") as f:
            buffer.write(f.read())
        buffer.seek(0)
        
        # Return audio file
        return send_file(
            buffer,
            mimetype=f'audio/{format.lower()}',
            as_attachment=True,
            download_name=f'speech.{format.lower()}'
        )
    
    except Exception as e:
        logger.error(f"Error in TTS: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/clone', methods=['POST'])
def clone_voice():
    """Voice cloning endpoint (mock)"""
    if 'audioFile' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400
    
    audio_file = request.files['audioFile']
    name = request.form.get('name', 'Custom Voice')
    
    # Generate unique voice ID
    voice_id = "mock-voice-1"
    
    return jsonify({
        "id": voice_id,
        "name": name,
        "description": "Mock voice (TTS service not fully functional)",
        "created_at": "2025-05-21",
        "status": "success"
    })

@app.errorhandler(Exception)
def handle_exception(e):
    """General error handler"""
    logger.error(f"Error: {str(e)}")
    return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Create a simple silent WAV file
    with open("silence.wav", "wb") as f:
        # WAV header for a 1-second silent audio
        f.write(b'RIFF$\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00')
    
    logger.info(f"Starting mock TTS server on port {SERVE_PORT}")
    app.run(host='0.0.0.0', port=SERVE_PORT, debug=False)