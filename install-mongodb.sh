#!/bin/bash

# Script to install MongoDB 5.0 on Debian 11 (Bullseye)

echo "Installing MongoDB 5.0 on Debian 11..."

# Import the MongoDB public GPG key
echo "Importing MongoDB public GPG key..."
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

# Create a list file for MongoDB
echo "Creating MongoDB repository list file..."
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

# Update package database
echo "Updating package database..."
sudo apt-get update

# Install MongoDB
echo "Installing MongoDB packages..."
sudo apt-get install -y mongodb-org

# Start MongoDB service
echo "Starting MongoDB service..."
sudo systemctl start mongod

# Enable MongoDB to start on boot
echo "Enabling MongoDB to start on boot..."
sudo systemctl enable mongod

# Check MongoDB status
echo "Checking MongoDB status..."
sudo systemctl status mongod

echo ""
echo "MongoDB 5.0 installation completed!"
echo "If MongoDB is not running, try: sudo systemctl start mongod"
echo "To check status: sudo systemctl status mongod"