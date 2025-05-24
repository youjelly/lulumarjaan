// Configuration for client
// This file is loaded before script.js and sets up the API endpoints

// Get the current host - if we're accessing via public IP, use that
const currentHost = window.location.hostname;
const isLocalhost = currentHost === 'localhost' || currentHost === '127.0.0.1';

// Define ports
const API_PORT = 3000;
const WEBRTC_PORT = 8080;

// Since client is now served from API server, use relative URLs for API
window.API_URL = ''; // Empty string means same origin

// WebRTC still runs on separate port
window.WEBRTC_WS_URL = isLocalhost
    ? `ws://localhost:${WEBRTC_PORT}/ws`
    : `ws://${currentHost}:${WEBRTC_PORT}/ws`;

// Log configuration for debugging
console.log('Client configuration:', {
    host: currentHost,
    isLocalhost: isLocalhost,
    API_URL: window.API_URL,
    WEBRTC_WS_URL: window.WEBRTC_WS_URL
});