#!/usr/bin/env python3
"""
Download Ultravox model to local cache
This script downloads the model to avoid doing it during service startup
"""

import os
import sys
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def download_model(model_id):
    """Download the specified model and processor"""
    try:
        # Import here to show any import errors clearly
        from transformers import AutoModel, AutoProcessor
        
        logger.info(f"Starting download of model: {model_id}")
        logger.info(f"Cache directory: {os.environ.get('HF_HOME', '~/.cache/huggingface')}")
        
        # Download model
        logger.info("Downloading model files...")
        model = AutoModel.from_pretrained(
            model_id, 
            trust_remote_code=True,
            resume_download=True  # Resume if interrupted
        )
        
        # Download processor
        logger.info("Downloading processor files...")
        processor = AutoProcessor.from_pretrained(model_id)
        
        # Get model size
        cache_dir = os.environ.get("HF_HOME", os.path.expanduser("~/.cache/huggingface"))
        model_path = Path(cache_dir) / "hub" / f"models--{model_id.replace('/', '--')}"
        
        if model_path.exists():
            # Calculate size
            total_size = sum(f.stat().st_size for f in model_path.rglob('*') if f.is_file())
            size_gb = total_size / (1024**3)
            logger.info(f"Model downloaded successfully! Total size: {size_gb:.2f} GB")
            logger.info(f"Model location: {model_path}")
        else:
            logger.warning("Model path not found after download")
            
        return True
        
    except ImportError as e:
        logger.error(f"Import error: {e}")
        logger.error("Make sure you have activated the virtual environment:")
        logger.error("source /mnt/data/real-venv/bin/activate")
        return False
    except Exception as e:
        logger.error(f"Error downloading model: {e}")
        return False

def main():
    """Main function"""
    # Check environment
    if 'HF_HOME' not in os.environ:
        logger.warning("HF_HOME not set, using default cache location")
        logger.info("To use /mnt/data, run: export HF_HOME=/mnt/data/huggingface_cache")
    
    if 'HF_TOKEN' not in os.environ:
        logger.error("HF_TOKEN not set!")
        logger.error("Please set your Hugging Face token:")
        logger.error("export HF_TOKEN=your_token_here")
        sys.exit(1)
    
    # Model to download
    model_id = "fixie-ai/ultravox-v0_5-llama-3_1-8b"
    
    logger.info("=" * 60)
    logger.info("Ultravox Model Downloader")
    logger.info("=" * 60)
    logger.info(f"Model: {model_id}")
    logger.info(f"Cache: {os.environ.get('HF_HOME', '~/.cache/huggingface')}")
    logger.info("=" * 60)
    
    # Confirm before downloading
    response = input("\nThis will download ~32GB of model files. Continue? (y/N): ")
    if response.lower() != 'y':
        logger.info("Download cancelled")
        sys.exit(0)
    
    # Download
    success = download_model(model_id)
    
    if success:
        logger.info("\n✅ Model download complete!")
        logger.info("You can now start the services with: ./start-real.sh")
    else:
        logger.error("\n❌ Model download failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()