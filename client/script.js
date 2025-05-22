// Configuration
const API_URL = 'http://localhost:3000';
const LLM_URL = 'http://localhost:5000';
const TTS_URL = 'http://localhost:5001';
const WEBRTC_WS_URL = 'ws://localhost:8080/ws';

// DOM Elements
const chatContainer = document.getElementById('chatContainer');
const userInput = document.getElementById('userInput');
const sendTextBtn = document.getElementById('sendTextBtn');
const recordBtn = document.getElementById('recordBtn');
const stopRecordBtn = document.getElementById('stopRecordBtn');
const statusText = document.getElementById('statusText');
const visualizer = document.getElementById('visualizer');
const responseAudio = document.getElementById('responseAudio');
const voiceSelect = document.getElementById('voiceSelect');
const speedRange = document.getElementById('speedRange');
const speedValue = document.getElementById('speedValue');
const voiceFileInput = document.getElementById('voiceFileInput');
const selectedFileName = document.getElementById('selectedFileName');
const voiceName = document.getElementById('voiceName');
const cloneVoiceBtn = document.getElementById('cloneVoiceBtn');
const connectRTCBtn = document.getElementById('connectRTCBtn');
const disconnectRTCBtn = document.getElementById('disconnectRTCBtn');
const rtcStatus = document.getElementById('rtcStatus');
const roomIdInput = document.getElementById('roomIdInput');

// Variables for recording
let mediaRecorder;
let audioChunks = [];
let isRecording = false;
let audioContext;
let analyser;
let visualizerBars = [];
let animationId;

// Variables for WebRTC
let webrtcConnection;
let webrtcDataChannel;
let webrtcSocket;
let userId = generateUserId();

// Initialize application
function init() {
    createVisualizerBars();
    setupEventListeners();
    loadVoices();
    
    // Update status
    updateStatus('Ready');
}

// Create visualizer bars
function createVisualizerBars() {
    const barCount = 50;
    for (let i = 0; i < barCount; i++) {
        const bar = document.createElement('div');
        bar.className = 'bar';
        bar.style.height = '0px';
        visualizer.appendChild(bar);
        visualizerBars.push(bar);
    }
}

// Setup event listeners
function setupEventListeners() {
    // Text chat
    sendTextBtn.addEventListener('click', sendTextMessage);
    userInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendTextMessage();
        }
    });
    
    // Voice recording
    recordBtn.addEventListener('click', startRecording);
    stopRecordBtn.addEventListener('click', stopRecording);
    
    // Voice settings
    speedRange.addEventListener('input', () => {
        speedValue.textContent = speedRange.value;
    });
    
    // Voice file upload
    voiceFileInput.addEventListener('change', () => {
        if (voiceFileInput.files.length > 0) {
            selectedFileName.textContent = voiceFileInput.files[0].name;
        } else {
            selectedFileName.textContent = 'No file selected';
        }
    });
    
    // Voice cloning
    cloneVoiceBtn.addEventListener('click', cloneVoice);
    
    // WebRTC
    connectRTCBtn.addEventListener('click', connectWebRTC);
    disconnectRTCBtn.addEventListener('click', disconnectWebRTC);
}

// Load available voices
function loadVoices() {
    fetch(`${API_URL}/v1/voices`)
        .then(response => response.json())
        .then(data => {
            // Clear existing custom voices
            const options = Array.from(voiceSelect.options);
            for (const option of options) {
                if (option.dataset.type === 'custom') {
                    voiceSelect.removeChild(option);
                }
            }
            
            // Add custom voices
            if (data.voices) {
                const customVoices = data.voices.filter(voice => voice.type === 'custom');
                for (const voice of customVoices) {
                    const option = document.createElement('option');
                    option.value = voice.id;
                    option.textContent = voice.name;
                    option.dataset.type = 'custom';
                    voiceSelect.appendChild(option);
                }
            }
        })
        .catch(error => {
            console.error('Error loading voices:', error);
            updateStatus('Error loading voices');
        });
}

// Send text message
function sendTextMessage() {
    const text = userInput.value.trim();
    if (!text) return;
    
    // Add user message to chat
    addMessage(text, 'user');
    
    // Clear input
    userInput.value = '';
    
    // Update status
    updateStatus('Sending message...');
    
    // Send to LLM
    fetch(`${API_URL}/v1/chat/completions`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            model: 'llama-3',
            messages: [
                { role: 'user', content: text }
            ],
            max_tokens: 200,
            temperature: 0.7
        })
    })
    .then(response => response.json())
    .then(data => {
        // Process LLM response
        const botResponse = data.choices[0].message.content;
        
        // Add bot message to chat
        addMessage(botResponse, 'bot');
        
        // Update status
        updateStatus('Converting to speech...');
        
        // Send to TTS
        return fetch(`${API_URL}/v1/audio/speech`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                text: botResponse,
                voice: voiceSelect.value,
                speed: parseFloat(speedRange.value)
            })
        });
    })
    .then(response => response.blob())
    .then(blob => {
        // Play audio
        const audioUrl = URL.createObjectURL(blob);
        responseAudio.src = audioUrl;
        responseAudio.play();
        
        // Update status
        updateStatus('Ready');
        
        // Send via WebRTC if connected
        if (webrtcDataChannel && webrtcDataChannel.readyState === 'open') {
            webrtcDataChannel.send(JSON.stringify({
                type: 'response',
                text: document.querySelector('.bot-message:last-child .message-text').textContent
            }));
        }
    })
    .catch(error => {
        console.error('Error:', error);
        updateStatus('Error: ' + error.message);
    });
}

// Add message to chat
function addMessage(text, role) {
    const messageElem = document.createElement('div');
    messageElem.className = `message ${role}-message`;
    
    const messageText = document.createElement('div');
    messageText.className = 'message-text';
    messageText.textContent = text;
    
    const messageTime = document.createElement('div');
    messageTime.className = 'message-time';
    messageTime.textContent = new Date().toLocaleTimeString();
    
    messageElem.appendChild(messageText);
    messageElem.appendChild(messageTime);
    
    chatContainer.appendChild(messageElem);
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

// Update status text
function updateStatus(message) {
    statusText.textContent = message;
}

// Start voice recording
async function startRecording() {
    try {
        // Request microphone access
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        
        // Setup AudioContext for visualization
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        analyser = audioContext.createAnalyser();
        const source = audioContext.createMediaStreamSource(stream);
        source.connect(analyser);
        analyser.fftSize = 256;
        
        // Setup MediaRecorder
        mediaRecorder = new MediaRecorder(stream);
        audioChunks = [];
        
        mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) {
                audioChunks.push(event.data);
            }
        };
        
        mediaRecorder.onstop = processRecording;
        
        // Start recording
        mediaRecorder.start();
        isRecording = true;
        
        // Update UI
        recordBtn.disabled = true;
        stopRecordBtn.disabled = false;
        updateStatus('Recording...');
        
        // Start visualization
        visualize();
    } catch (error) {
        console.error('Error starting recording:', error);
        updateStatus('Error accessing microphone');
    }
}

// Stop voice recording
function stopRecording() {
    if (mediaRecorder && isRecording) {
        mediaRecorder.stop();
        isRecording = false;
        
        // Update UI
        recordBtn.disabled = false;
        stopRecordBtn.disabled = true;
        updateStatus('Processing recording...');
        
        // Stop visualization
        cancelAnimationFrame(animationId);
        resetVisualizerBars();
    }
}

// Process recorded audio
function processRecording() {
    // Create audio blob
    const audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
    
    // Add user message placeholder
    addMessage('🎤 [Voice Message]', 'user');
    
    // Create FormData with audio
    const formData = new FormData();
    formData.append('audioFile', audioBlob, 'recording.wav');
    
    // TODO: Send to speech-to-text service
    // For now, we'll simulate STT with a timeout
    
    setTimeout(() => {
        // Simulated text from STT
        const transcribedText = "This is a simulated transcription of the voice message.";
        
        // Update the placeholder message
        const lastUserMessage = document.querySelector('.user-message:last-child .message-text');
        if (lastUserMessage) {
            lastUserMessage.textContent = transcribedText;
        }
        
        // Process as normal text message
        fetch(`${API_URL}/v1/chat/completions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model: 'llama-3',
                messages: [
                    { role: 'user', content: transcribedText }
                ],
                max_tokens: 200,
                temperature: 0.7
            })
        })
        .then(response => response.json())
        .then(data => {
            // Process LLM response
            const botResponse = data.choices[0].message.content;
            
            // Add bot message to chat
            addMessage(botResponse, 'bot');
            
            // Update status
            updateStatus('Converting to speech...');
            
            // Send to TTS
            return fetch(`${API_URL}/v1/audio/speech`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    text: botResponse,
                    voice: voiceSelect.value,
                    speed: parseFloat(speedRange.value)
                })
            });
        })
        .then(response => response.blob())
        .then(blob => {
            // Play audio
            const audioUrl = URL.createObjectURL(blob);
            responseAudio.src = audioUrl;
            responseAudio.play();
            
            // Update status
            updateStatus('Ready');
        })
        .catch(error => {
            console.error('Error:', error);
            updateStatus('Error: ' + error.message);
        });
    }, 1000);
}

// Audio visualization during recording
function visualize() {
    if (!analyser) return;
    
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    
    function draw() {
        animationId = requestAnimationFrame(draw);
        
        analyser.getByteFrequencyData(dataArray);
        
        // Calculate visualization
        const barWidth = visualizer.clientWidth / visualizerBars.length;
        const step = Math.floor(bufferLength / visualizerBars.length);
        
        for (let i = 0; i < visualizerBars.length; i++) {
            const barIndex = i * step;
            let value = 0;
            
            // Take average of frequencies for this bar
            for (let j = 0; j < step; j++) {
                value += dataArray[barIndex + j] || 0;
            }
            
            value = value / step;
            const height = (value / 255) * visualizer.clientHeight;
            
            visualizerBars[i].style.height = `${height}px`;
        }
    }
    
    draw();
}

// Reset visualizer bars
function resetVisualizerBars() {
    for (const bar of visualizerBars) {
        bar.style.height = '0px';
    }
}

// Clone voice
function cloneVoice() {
    if (!voiceFileInput.files.length) {
        updateStatus('Please select an audio file');
        return;
    }
    
    const name = voiceName.value.trim() || 'Custom Voice';
    const file = voiceFileInput.files[0];
    
    // Create FormData
    const formData = new FormData();
    formData.append('audioFile', file);
    formData.append('name', name);
    
    // Update status
    updateStatus('Cloning voice...');
    
    // Send to voice cloning endpoint
    fetch(`${API_URL}/v1/audio/clone`, {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            throw new Error(data.error);
        }
        
        // Update status
        updateStatus('Voice cloned successfully');
        
        // Reset form
        voiceFileInput.value = '';
        selectedFileName.textContent = 'No file selected';
        voiceName.value = '';
        
        // Reload voices
        loadVoices();
    })
    .catch(error => {
        console.error('Error cloning voice:', error);
        updateStatus('Error cloning voice: ' + error.message);
    });
}

// Connect WebRTC
function connectWebRTC() {
    try {
        const roomId = roomIdInput.value.trim() || 'test-room';
        
        // Create WebSocket connection for signaling
        webrtcSocket = new WebSocket(WEBRTC_WS_URL);
        
        webrtcSocket.onopen = () => {
            updateRTCStatus('WebSocket connected, joining room...');
            
            // Join room
            webrtcSocket.send(JSON.stringify({
                type: 'join',
                roomId: roomId,
                userId: userId
            }));
            
            // Create RTCPeerConnection
            const configuration = {
                iceServers: [
                    { urls: 'stun:stun.l.google.com:19302' }
                ]
            };
            
            webrtcConnection = new RTCPeerConnection(configuration);
            
            // Create data channel
            webrtcDataChannel = webrtcConnection.createDataChannel('chat');
            
            webrtcDataChannel.onopen = () => {
                updateRTCStatus('WebRTC connected');
                connectRTCBtn.disabled = true;
                disconnectRTCBtn.disabled = false;
            };
            
            webrtcDataChannel.onclose = () => {
                updateRTCStatus('WebRTC disconnected');
            };
            
            webrtcDataChannel.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    if (data.type === 'message') {
                        addMessage(`[WebRTC] ${data.text}`, 'user');
                    }
                } catch (e) {
                    console.error('Error parsing WebRTC message:', e);
                }
            };
            
            // ICE candidate handling
            webrtcConnection.onicecandidate = (event) => {
                if (event.candidate) {
                    webrtcSocket.send(JSON.stringify({
                        type: 'ice',
                        ice: event.candidate.toJSON()
                    }));
                }
            };
            
            // Create offer
            webrtcConnection.createOffer()
                .then(offer => webrtcConnection.setLocalDescription(offer))
                .then(() => {
                    webrtcSocket.send(JSON.stringify({
                        type: 'offer',
                        sdp: webrtcConnection.localDescription.sdp
                    }));
                })
                .catch(error => {
                    console.error('Error creating offer:', error);
                    updateRTCStatus('Error creating offer');
                });
        };
        
        webrtcSocket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            
            switch (data.type) {
                case 'answer':
                    webrtcConnection.setRemoteDescription({
                        type: 'answer',
                        sdp: data.sdp
                    });
                    break;
                    
                case 'ice':
                    if (data.ice) {
                        webrtcConnection.addIceCandidate(data.ice);
                    }
                    break;
                    
                case 'peer-joined':
                    updateRTCStatus(`Peer ${data.userId} joined the room`);
                    break;
                    
                case 'peer-left':
                    updateRTCStatus(`Peer ${data.userId} left the room`);
                    break;
            }
        };
        
        webrtcSocket.onerror = (error) => {
            console.error('WebSocket error:', error);
            updateRTCStatus('WebSocket error');
        };
        
        webrtcSocket.onclose = () => {
            updateRTCStatus('WebSocket closed');
            disconnectWebRTC();
        };
    } catch (error) {
        console.error('Error connecting WebRTC:', error);
        updateRTCStatus('Error: ' + error.message);
    }
}

// Disconnect WebRTC
function disconnectWebRTC() {
    if (webrtcDataChannel) {
        webrtcDataChannel.close();
        webrtcDataChannel = null;
    }
    
    if (webrtcConnection) {
        webrtcConnection.close();
        webrtcConnection = null;
    }
    
    if (webrtcSocket) {
        webrtcSocket.close();
        webrtcSocket = null;
    }
    
    connectRTCBtn.disabled = false;
    disconnectRTCBtn.disabled = true;
    updateRTCStatus('Disconnected');
}

// Update WebRTC status
function updateRTCStatus(message) {
    rtcStatus.textContent = message;
}

// Generate random user ID
function generateUserId() {
    return 'user-' + Math.floor(Math.random() * 1000000);
}

// Initialize the application when the page loads
window.addEventListener('DOMContentLoaded', init);