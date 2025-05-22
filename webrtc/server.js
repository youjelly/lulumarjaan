// Simple WebRTC signaling server using Node.js and WebSockets
const http = require('http');
const WebSocket = require('ws');

const port = process.env.PORT || 8080;

// Create HTTP server
const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('WebRTC Signaling Server\n');
});

// Create WebSocket server
const wss = new WebSocket.Server({ server });

// Store active connections
const rooms = new Map();

// Connection handler
wss.on('connection', (ws) => {
    console.log('New WebSocket connection established');
    
    let userId = null;
    let roomId = null;
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            console.log('Received message:', data);
            
            if (data.type === 'join') {
                // Handle join room
                roomId = data.roomId;
                userId = data.userId;
                
                if (!roomId || !userId) {
                    console.error('Room ID and User ID required');
                    return;
                }
                
                // Get or create room
                if (!rooms.has(roomId)) {
                    rooms.set(roomId, new Map());
                    console.log(`Created new room: ${roomId}`);
                }
                
                const room = rooms.get(roomId);
                
                // Add peer to room
                room.set(userId, ws);
                console.log(`Peer ${userId} joined room ${roomId}`);
                
                // Notify existing peers
                room.forEach((peer, id) => {
                    if (id !== userId) {
                        peer.send(JSON.stringify({
                            type: 'peer-joined',
                            userId: userId,
                            roomId: roomId
                        }));
                    }
                });
            } else if (data.type === 'offer' || data.type === 'answer' || data.type === 'ice') {
                // Forward signaling messages to appropriate peer
                if (!roomId || !data.targetId) return;
                
                const room = rooms.get(roomId);
                if (!room) return;
                
                const targetPeer = room.get(data.targetId);
                if (targetPeer) {
                    // Forward the message
                    targetPeer.send(JSON.stringify({
                        type: data.type,
                        sdp: data.sdp,
                        ice: data.ice,
                        userId: userId
                    }));
                }
            } else if (data.type === 'leave') {
                handlePeerLeave();
            }
        } catch (error) {
            console.error('Error processing message:', error);
        }
    });
    
    ws.on('close', () => {
        handlePeerLeave();
    });
    
    function handlePeerLeave() {
        if (roomId && userId) {
            console.log(`Peer ${userId} is leaving room ${roomId}`);
            
            const room = rooms.get(roomId);
            if (room) {
                // Remove peer from room
                room.delete(userId);
                
                // Notify other peers
                room.forEach(peer => {
                    peer.send(JSON.stringify({
                        type: 'peer-left',
                        userId: userId,
                        roomId: roomId
                    }));
                });
                
                // If room is empty, delete it
                if (room.size === 0) {
                    rooms.delete(roomId);
                    console.log(`Room ${roomId} is now empty and has been deleted`);
                }
            }
            
            console.log(`Peer ${userId} has left room ${roomId}`);
        }
    }
});

// Start server
server.listen(port, () => {
    console.log(`WebRTC signaling server running on port ${port}`);
});