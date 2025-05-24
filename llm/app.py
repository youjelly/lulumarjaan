import os
import time
import json
import logging
import threading
import torch
import numpy as np
from flask import Flask, request, jsonify, Response, stream_with_context
from flask_cors import CORS
from dotenv import load_dotenv
from transformers import (
    AutoTokenizer, 
    BitsAndBytesConfig, 
    TextIteratorStreamer,
    pipeline
)

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment variables
MODEL_ID = os.getenv('MODEL_ID', 'fixie-ai/ultravox-v0_5-llama-3_2-1b')
DEVICE = os.getenv('DEVICE', 'cuda' if torch.cuda.is_available() else 'cpu')
USE_4BIT = os.getenv('USE_4BIT', 'True').lower() == 'true'
LOAD_IN_8BIT = os.getenv('LOAD_IN_8BIT', 'False').lower() == 'true'
SERVE_PORT = int(os.getenv('SERVE_PORT', 5000))

app = Flask(__name__)
CORS(app)

# Global variables for model and tokenizer
model_pipeline = None
tokenizer = None

def load_model():
    """Load the LLM model using the pipeline for Ultravox support"""
    global model_pipeline, tokenizer
    
    logger.info(f"Loading model: {MODEL_ID}")
    logger.info(f"Device: {DEVICE}")
    logger.info(f"8-bit quantization: {LOAD_IN_8BIT}")
    logger.info(f"4-bit quantization: {USE_4BIT}")
    
    # Check if model exists locally
    import os
    from pathlib import Path
    cache_dir = os.environ.get("HF_HOME", os.path.expanduser("~/.cache/huggingface"))
    # Try both possible paths
    model_path1 = Path(cache_dir) / f"models--{MODEL_ID.replace('/', '--')}"
    model_path2 = Path(cache_dir) / "hub" / f"models--{MODEL_ID.replace('/', '--')}"
    
    if not model_path1.exists() and not model_path2.exists():
        logger.error(f"Model not found in cache at {model_path1} or {model_path2}")
        logger.error(f"Please download the model first using:")
        logger.error(f"python -c \"from transformers import AutoModel, AutoProcessor; model_id='{MODEL_ID}'; AutoModel.from_pretrained(model_id, trust_remote_code=True); AutoProcessor.from_pretrained(model_id)\"")
        raise FileNotFoundError(f"Model {MODEL_ID} not found in cache. Please download it first.")
    
    # Configure quantization
    quantization_config = None
    if USE_4BIT or LOAD_IN_8BIT:
        quantization_config = BitsAndBytesConfig(
            load_in_4bit=USE_4BIT,
            load_in_8bit=LOAD_IN_8BIT,
            bnb_4bit_compute_dtype=torch.bfloat16,
            bnb_4bit_use_double_quant=True,
            bnb_4bit_quant_type="nf4"
        )
    
    # Use pipeline for loading Ultravox model
    try:
        if quantization_config:
            model_pipeline = pipeline(
                model=MODEL_ID,
                device_map="auto",
                trust_remote_code=True,
                model_kwargs={"quantization_config": quantization_config, "local_files_only": True},
                torch_dtype=torch.bfloat16 if DEVICE == "cuda" else torch.float32,
                local_files_only=True,
            )
        else:
            model_pipeline = pipeline(
                model=MODEL_ID,
                device_map=DEVICE,
                trust_remote_code=True,
                torch_dtype=torch.bfloat16 if DEVICE == "cuda" else torch.float32,
                local_files_only=True,
            )
        
        # Try to get the tokenizer from the pipeline
        tokenizer = model_pipeline.tokenizer
        
        logger.info(f"Model loaded successfully with {'8-bit' if LOAD_IN_8BIT else '4-bit' if USE_4BIT else 'full'} precision")
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        raise

def format_chat_prompt(messages):
    """Format chat messages into prompt format expected by the model"""
    turns = []
    
    for message in messages:
        role = message.get("role", "").lower()
        content = message.get("content", "")
        
        # Create turn in the format expected by Ultravox
        turns.append({
            "role": role,
            "content": content
        })
    
    return turns

def count_tokens(text):
    """Count the number of tokens in the text"""
    global tokenizer
    if tokenizer is None:
        return 0
    return len(tokenizer.encode(text))

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    if model_pipeline is None:
        return jsonify({"status": "error", "message": "Model not loaded"}), 503
    return jsonify({"status": "ok"}), 200

@app.route('/generate', methods=['POST'])
def generate():
    """Text generation endpoint"""
    data = request.json
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    # Extract parameters
    messages = data.get('messages', [])
    max_tokens = int(data.get('max_tokens', 256))
    temperature = float(data.get('temperature', 0.7))
    
    if not messages:
        return jsonify({"error": "No messages provided"}), 400
    
    # Format prompt as expected by Ultravox
    turns = format_chat_prompt(messages)
    
    try:
        # Use the pipeline to generate a response
        response = model_pipeline(
            {"turns": turns},
            max_new_tokens=max_tokens,
            temperature=temperature,
            do_sample=temperature > 0
        )
        
        # Extract the generated text
        if isinstance(response, dict) and "generated_text" in response:
            generated_text = response["generated_text"]
        elif isinstance(response, str):
            generated_text = response
        else:
            # Try to get the best guess of the response
            generated_text = str(response)
        
        # Calculate token counts (approximate)
        prompt_tokens = sum(count_tokens(msg['content']) for msg in messages)
        completion_tokens = count_tokens(generated_text)
        
        return jsonify({
            "text": generated_text.strip(),
            "usage": {
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens
            },
            "finish_reason": "stop"
        })
    except Exception as e:
        logger.error(f"Generation error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/models', methods=['GET'])
def list_models():
    """List available models"""
    return jsonify({
        "data": [
            {
                "id": MODEL_ID,
                "object": "model",
                "created": int(time.time()),
                "owned_by": "user"
            }
        ]
    })

@app.errorhandler(Exception)
def handle_exception(e):
    """General error handler"""
    logger.error(f"Error: {str(e)}")
    return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Load the model when the app starts
    load_model()
    
    # Start the Flask app
    app.run(host='0.0.0.0', port=SERVE_PORT, debug=False)
    logger.info(f"LLM service started on http://0.0.0.0:{SERVE_PORT}")