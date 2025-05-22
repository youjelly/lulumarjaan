#!/usr/bin/env python3
"""
Simple mock LLM server that responds to API requests with predefined responses.
"""

import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
port = int(os.getenv('SERVE_PORT', 5000))

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "ok"}), 200

@app.route('/generate', methods=['POST'])
def generate():
    """Text generation endpoint (mock for Ultravox model)"""
    data = request.json
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    messages = data.get('messages', [])
    
    if not messages or not isinstance(messages, list):
        return jsonify({"error": "Invalid messages format"}), 400
    
    # Get the last message content
    last_message = messages[-1].get('content', '')
    
    # Generate a more sophisticated response mimicking Ultravox
    if "hello" in last_message.lower() or "hi" in last_message.lower():
        response = "Hello! I'm Ultravox, a multimodal voice assistant. I can understand both text and speech. How can I help you today?"
    elif "joke" in last_message.lower():
        response = "Why don't programmers like nature? It has too many bugs! 🐛 But seriously, I'm a speech-enabled AI assistant based on Llama 3.2."
    elif "weather" in last_message.lower():
        response = "I don't have access to real-time weather data, but I can help you with many other tasks. I'm designed to be a multimodal assistant that can process both voice and text."
    elif "voice" in last_message.lower() or "speech" in last_message.lower():
        response = "I'm designed to work with both voice and text input! While this is currently a mock version, the real Ultravox model can process audio alongside text messages."
    elif "tell me about" in last_message.lower():
        topic = last_message.lower().replace("tell me about", "").strip()
        response = f"I'd be happy to discuss {topic}! As an AI assistant based on Ultravox (Llama 3.2 + Whisper), I can help with various topics. What specifically would you like to know?"
    else:
        response = f"I understand you said: '{last_message}'. I'm Ultravox, a multimodal speech-enabled assistant. While this is a mock version, I'm designed to process both voice and text input to provide helpful responses."
    
    # Return response
    return jsonify({
        "text": response,
        "finish_reason": "stop",
        "usage": {
            "prompt_tokens": len(last_message.split()),
            "completion_tokens": len(response.split()),
            "total_tokens": len(last_message.split()) + len(response.split())
        }
    })

if __name__ == '__main__':
    print(f"Starting simple LLM mock server on port {port}")
    app.run(host='0.0.0.0', port=port)