import os
import io
import uuid
import time
import json
import logging
import tempfile
import shutil
from pathlib import Path
import numpy as np
import torch
import torchaudio
import librosa
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import soundfile as sf
from dotenv import load_dotenv
from pydub import AudioSegment

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
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
BASE_MODEL_PATH = os.getenv('BASE_MODEL_PATH', './models/base_model')
SPEAKER_EMBEDDINGS_PATH = os.getenv('SPEAKER_EMBEDDINGS_PATH', './models/speaker_embeddings')
CUSTOM_VOICES_PATH = os.getenv('CUSTOM_VOICES_PATH', './voices')
SERVE_PORT = int(os.getenv('TTS_PORT', 6000))
DEFAULT_SAMPLING_RATE = 24000

# Ensure directories exist
os.makedirs(CUSTOM_VOICES_PATH, exist_ok=True)
os.makedirs(BASE_MODEL_PATH, exist_ok=True)
os.makedirs(SPEAKER_EMBEDDINGS_PATH, exist_ok=True)

# Global variables for models
base_model = None
speaker_encoder = None
vocoder = None

def load_models():
    """Load TTS models and components"""
    global base_model, speaker_encoder, vocoder
    
    try:
        # Import OpenVoice modules here to avoid importing at the top level
        # This allows the app to start even if OpenVoice is not fully installed yet
        from openvoice.api import ToneColorConverter, load_voice_conversion_models
        
        logger.info("Loading OpenVoice models...")
        
        # Load models
        base_vocoder_path = os.path.join(BASE_MODEL_PATH, "vocoder.pt")
        base_model_path = os.path.join(BASE_MODEL_PATH, "base_model.pt")
        speaker_encoder_path = os.path.join(SPEAKER_EMBEDDINGS_PATH, "speaker_encoder.pt")
        
        # Check if models exist, if not print warning
        if not os.path.exists(base_vocoder_path) or not os.path.exists(base_model_path) or not os.path.exists(speaker_encoder_path):
            logger.warning("Some models are missing. TTS functionality will be limited until models are downloaded.")
            logger.warning(f"Please ensure the following files exist:")
            logger.warning(f"- {base_vocoder_path}")
            logger.warning(f"- {base_model_path}")
            logger.warning(f"- {speaker_encoder_path}")
            return
        
        # Load the base models
        base_model, speaker_encoder, vocoder = load_voice_conversion_models(
            base_model_path,
            speaker_encoder_path,
            base_vocoder_path,
            device=DEVICE
        )
        
        logger.info("Models loaded successfully")
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        base_model, speaker_encoder, vocoder = None, None, None

def get_available_voices():
    """Get list of available voice models"""
    voices = []
    
    # Add default voices
    default_voices = [
        {"id": "default", "name": "Default", "type": "base"},
        {"id": "warm", "name": "Warm", "type": "base"},
        {"id": "bright", "name": "Bright", "type": "base"},
        {"id": "calm", "name": "Calm", "type": "base"},
    ]
    voices.extend(default_voices)
    
    # Add custom voices
    if os.path.exists(CUSTOM_VOICES_PATH):
        for voice_dir in os.listdir(CUSTOM_VOICES_PATH):
            voice_path = os.path.join(CUSTOM_VOICES_PATH, voice_dir)
            if os.path.isdir(voice_path):
                # Check for metadata file
                metadata_path = os.path.join(voice_path, "metadata.json")
                if os.path.exists(metadata_path):
                    try:
                        with open(metadata_path, 'r') as f:
                            metadata = json.load(f)
                            voices.append({
                                "id": voice_dir,
                                "name": metadata.get("name", voice_dir),
                                "description": metadata.get("description", ""),
                                "created_at": metadata.get("created_at", ""),
                                "type": "custom"
                            })
                    except Exception as e:
                        logger.error(f"Error reading metadata for voice {voice_dir}: {e}")
                        voices.append({
                            "id": voice_dir,
                            "name": voice_dir,
                            "type": "custom"
                        })
                else:
                    voices.append({
                        "id": voice_dir,
                        "name": voice_dir,
                        "type": "custom"
                    })
    
    return voices

def ensure_models_loaded():
    """Ensure models are loaded before processing requests"""
    global base_model, speaker_encoder, vocoder
    
    if base_model is None or speaker_encoder is None or vocoder is None:
        load_models()
        
    if base_model is None or speaker_encoder is None or vocoder is None:
        raise RuntimeError("Models not loaded. Please check logs for details.")

def synthesize_speech(text, voice_id="default", speed=1.0):
    """Synthesize speech from text using the specified voice"""
    ensure_models_loaded()
    
    try:
        # Import OpenVoice modules
        from openvoice.api import ToneColorConverter
        
        # Create converter
        converter = ToneColorConverter(base_model, speaker_encoder, vocoder)
        
        # Configure TTS settings
        use_custom_voice = voice_id not in ["default", "warm", "bright", "calm"]
        
        # For custom voices, load the reference audio
        if use_custom_voice:
            voice_dir = os.path.join(CUSTOM_VOICES_PATH, voice_id)
            if not os.path.exists(voice_dir):
                logger.error(f"Custom voice directory not found: {voice_dir}")
                raise ValueError(f"Voice not found: {voice_id}")
            
            # Find reference audio file
            reference_files = list(Path(voice_dir).glob("*.wav"))
            if not reference_files:
                logger.error(f"No reference audio found in {voice_dir}")
                raise ValueError(f"No reference audio found for voice: {voice_id}")
            
            reference_audio_path = str(reference_files[0])
            
            # Generate speech with custom voice
            audio_array = converter.tts_with_reference(
                text,
                reference_audio_path,
                speed_modifier=speed
            )
        else:
            # Use built-in voice
            audio_array = converter.tts(
                text,
                voice_preset=voice_id,
                speed_modifier=speed
            )
        
        # Save to in-memory file
        buffer = io.BytesIO()
        sf.write(buffer, audio_array, DEFAULT_SAMPLING_RATE, format='WAV')
        buffer.seek(0)
        
        return buffer
    
    except Exception as e:
        logger.error(f"Error in speech synthesis: {e}")
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "ok"}), 200

@app.route('/voices', methods=['GET'])
def list_voices():
    """List available voices"""
    voices = get_available_voices()
    return jsonify({"voices": voices})

@app.route('/tts', methods=['POST'])
def text_to_speech():
    """Text-to-speech endpoint"""
    data = request.json
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    text = data.get('text')
    voice = data.get('voice', 'default')
    format = data.get('format', 'mp3')
    speed = float(data.get('speed', 1.0))
    
    if not text:
        return jsonify({"error": "Text is required"}), 400
    
    try:
        # Generate speech
        output_buffer = synthesize_speech(text, voice, speed)
        
        # Convert to requested format if not WAV
        if format.lower() != 'wav':
            wav_audio = AudioSegment.from_wav(output_buffer)
            
            format_buffer = io.BytesIO()
            wav_audio.export(format_buffer, format=format.lower())
            format_buffer.seek(0)
            output_buffer = format_buffer
        
        # Return audio file
        return send_file(
            output_buffer,
            mimetype=f'audio/{format.lower()}',
            as_attachment=True,
            download_name=f'speech.{format.lower()}'
        )
    
    except Exception as e:
        logger.error(f"Error in TTS: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/clone', methods=['POST'])
def clone_voice():
    """Voice cloning endpoint"""
    if 'audioFile' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400
    
    audio_file = request.files['audioFile']
    name = request.form.get('name', 'Custom Voice')
    description = request.form.get('description', '')
    
    # Generate unique ID for the voice
    voice_id = str(uuid.uuid4())
    voice_dir = os.path.join(CUSTOM_VOICES_PATH, voice_id)
    os.makedirs(voice_dir, exist_ok=True)
    
    try:
        # Save the uploaded audio file
        audio_path = os.path.join(voice_dir, "reference.wav")
        
        # Convert to mono WAV if needed
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
            audio_file.save(temp_file.name)
            
            # Load and resample audio to proper format
            y, sr = librosa.load(temp_file.name, sr=DEFAULT_SAMPLING_RATE, mono=True)
            sf.write(audio_path, y, DEFAULT_SAMPLING_RATE)
            
            # Clean up temp file
            os.unlink(temp_file.name)
        
        # Create metadata file
        metadata = {
            "id": voice_id,
            "name": name,
            "description": description,
            "created_at": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        
        with open(os.path.join(voice_dir, "metadata.json"), 'w') as f:
            json.dump(metadata, f)
        
        # Extract voice embedding (this would be done in a real implementation)
        # Here we're just pretending we did it
        
        return jsonify({
            "id": voice_id,
            "name": name,
            "description": description,
            "created_at": metadata["created_at"],
            "status": "success"
        })
    
    except Exception as e:
        logger.error(f"Error in voice cloning: {e}")
        # Clean up in case of error
        if os.path.exists(voice_dir):
            shutil.rmtree(voice_dir)
        return jsonify({"error": str(e)}), 500

@app.route('/clone/<voice_id>', methods=['GET'])
def get_voice(voice_id):
    """Get voice info"""
    voice_dir = os.path.join(CUSTOM_VOICES_PATH, voice_id)
    
    if not os.path.exists(voice_dir):
        return jsonify({"error": "Voice not found"}), 404
    
    # Read metadata
    metadata_path = os.path.join(voice_dir, "metadata.json")
    if os.path.exists(metadata_path):
        with open(metadata_path, 'r') as f:
            metadata = json.load(f)
        return jsonify(metadata)
    else:
        return jsonify({
            "id": voice_id,
            "name": voice_id,
            "status": "available" 
        })

@app.route('/clone/<voice_id>', methods=['DELETE'])
def delete_voice(voice_id):
    """Delete a cloned voice"""
    voice_dir = os.path.join(CUSTOM_VOICES_PATH, voice_id)
    
    if not os.path.exists(voice_dir):
        return jsonify({"error": "Voice not found"}), 404
    
    try:
        # Delete the voice directory
        shutil.rmtree(voice_dir)
        return jsonify({"status": "success", "message": "Voice deleted"})
    
    except Exception as e:
        logger.error(f"Error deleting voice: {e}")
        return jsonify({"error": str(e)}), 500

@app.errorhandler(Exception)
def handle_exception(e):
    """General error handler"""
    logger.error(f"Error: {str(e)}")
    return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Try to load models at startup
    try:
        load_models()
    except Exception as e:
        logger.error(f"Error loading models at startup: {e}")
        logger.info("The server will continue to run, but TTS functionality may be limited")
    
    # Start the Flask app
    app.run(host='0.0.0.0', port=SERVE_PORT, debug=False)