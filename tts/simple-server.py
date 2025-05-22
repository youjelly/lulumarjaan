#!/usr/bin/env python3
"""
Simple mock TTS server that responds to API requests.
"""

import os
import io
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
port = int(os.getenv('TTS_PORT', 6000))

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
    
    if not text:
        return jsonify({"error": "Text is required"}), 400
    
    # Create a simple WAV file in memory with silence
    buffer = io.BytesIO()
    
    # Simple WAV header for 1 second silence
    buffer.write(b'RIFF$\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00')
    buffer.seek(0)
    
    # Return audio file
    return send_file(
        buffer,
        mimetype='audio/wav',
        as_attachment=True,
        download_name='speech.wav'
    )

@app.route('/clone', methods=['POST'])
def clone_voice():
    """Voice cloning endpoint (mock)"""
    return jsonify({
        "id": "mock-voice-1",
        "name": "Mock Voice",
        "description": "Mock voice",
        "created_at": "2025-05-21",
        "status": "success"
    })

if __name__ == '__main__':
    print(f"Starting simple TTS mock server on port {port}")
    app.run(host='0.0.0.0', port=port)