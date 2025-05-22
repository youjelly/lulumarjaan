require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const axios = require('axios');
const path = require('path');
const { Server } = require('socket.io');
const http = require('http');
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');
const fs = require('fs');

// Configure environment
const PORT = process.env.PORT || 3001;
const LLM_SERVICE_URL = process.env.LLM_SERVICE_URL || 'http://localhost:5000';
const TTS_SERVICE_URL = process.env.TTS_SERVICE_URL || 'http://localhost:6000';
const WEBRTC_SERVICE_URL = process.env.WEBRTC_SERVICE_URL || 'http://localhost:8080';

// Setup temporary storage for uploaded files
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${uuidv4()}-${file.originalname}`);
  }
});
const upload = multer({ storage });

// Initialize express app
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(morgan('dev'));

// WebSocket/Socket.io for WebRTC signaling
io.on('connection', (socket) => {
  console.log('New WebSocket connection established');

  socket.on('join-room', (roomId, userId) => {
    socket.join(roomId);
    socket.to(roomId).emit('user-connected', userId);
    console.log(`User ${userId} joined room ${roomId}`);

    socket.on('disconnect', () => {
      socket.to(roomId).emit('user-disconnected', userId);
      console.log(`User ${userId} left room ${roomId}`);
    });

    // WebRTC signaling
    socket.on('signal', (toId, signal) => {
      io.to(toId).emit('signal', socket.id, signal);
    });
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// LLM API routes (similar to OpenAI's format)
app.post('/v1/chat/completions', async (req, res) => {
  try {
    const { model, messages, max_tokens, temperature, stream } = req.body;
    
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'Invalid messages format' });
    }

    // Forward request to LLM service
    const response = await axios.post(`${LLM_SERVICE_URL}/generate`, {
      model: model || 'llama-3',
      messages,
      max_tokens: max_tokens || 100,
      temperature: temperature || 0.7,
      stream: stream || false
    });

    if (stream) {
      // Handle streaming response
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      response.data.pipe(res);
    } else {
      // Handle regular response
      res.json({
        id: uuidv4(),
        object: 'chat.completion',
        created: Math.floor(Date.now() / 1000),
        model: model || 'llama-3',
        choices: [
          {
            index: 0,
            message: {
              role: 'assistant',
              content: response.data.text
            },
            finish_reason: response.data.finish_reason || 'stop'
          }
        ],
        usage: response.data.usage || {
          prompt_tokens: 0,
          completion_tokens: 0,
          total_tokens: 0
        }
      });
    }
  } catch (error) {
    console.error('Error in LLM request:', error.message);
    res.status(500).json({ 
      error: {
        message: 'Error processing LLM request',
        type: 'server_error'
      }
    });
  }
});

// TTS API routes
app.post('/v1/audio/speech', async (req, res) => {
  try {
    const { text, voice, format, speed } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }

    // Forward request to TTS service
    const response = await axios.post(`${TTS_SERVICE_URL}/tts`, {
      text,
      voice: voice || 'default',
      format: format || 'mp3',
      speed: speed || 1.0
    }, {
      responseType: 'arraybuffer'
    });

    const contentType = response.headers['content-type'];
    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Disposition', `attachment; filename="speech.${format || 'mp3'}"`);
    res.send(Buffer.from(response.data));
  } catch (error) {
    console.error('Error in TTS request:', error.message);
    res.status(500).json({ 
      error: {
        message: 'Error processing TTS request',
        type: 'server_error'
      }
    });
  }
});

// Voice cloning endpoint
app.post('/v1/audio/clone', upload.single('audioFile'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Audio file is required' });
    }

    const { name, description } = req.body;
    const filePath = req.file.path;

    // Create form data for the TTS service
    const FormData = require('form-data');
    const formData = new FormData();
    formData.append('audioFile', fs.createReadStream(filePath));
    formData.append('name', name || 'Custom Voice');
    formData.append('description', description || '');

    const response = await axios.post(`${TTS_SERVICE_URL}/clone`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });

    // Clean up the temporary file
    fs.unlinkSync(filePath);

    res.json({
      id: response.data.id,
      name: response.data.name,
      status: 'success',
      created_at: response.data.created_at
    });
  } catch (error) {
    console.error('Error in voice cloning request:', error.message);
    res.status(500).json({ 
      error: {
        message: 'Error processing voice cloning request',
        type: 'server_error'
      }
    });
  }
});

// WebRTC signaling proxy endpoint (alternative to WebSocket)
app.post('/webrtc/signal', async (req, res) => {
  try {
    const { signal, roomId, userId, targetId } = req.body;
    
    if (!signal || !roomId || !userId) {
      return res.status(400).json({ error: 'Invalid signaling data' });
    }

    // Forward to WebRTC service
    await axios.post(`${WEBRTC_SERVICE_URL}/signal`, {
      signal,
      roomId,
      userId,
      targetId
    });

    res.status(200).json({ status: 'signal sent' });
  } catch (error) {
    console.error('Error in WebRTC signaling:', error.message);
    res.status(500).json({ error: 'Error in WebRTC signaling' });
  }
});

// Start server
server.listen(PORT, () => {
  console.log(`API server running on port ${PORT}`);
});