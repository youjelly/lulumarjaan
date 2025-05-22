#!/bin/bash

# Stop script for terminating all host-based services

echo "Stopping all services..."

# Stop Node.js services
pkill -f "node index.js" || true
pkill -f "node server.js" || true

# Stop Python services
pkill -f "python app.py" || true
pkill -f "python server.py" || true
pkill -f "python -m http.server 8000" || true

# Stop Go services
pkill -f "go run cmd/server/main.go" || true

# Stop MongoDB
if command -v mongod &> /dev/null; then
    echo "Stopping MongoDB..."
    mongod --shutdown --dbpath "$(pwd)/shared_storage/data/mongodb" 2>/dev/null || true
fi

echo "All services stopped!"