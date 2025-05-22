#!/bin/bash

# Script to install the latest MongoDB on Debian 11 (Bullseye)

echo "Installing latest MongoDB on Debian 11..."

# Install necessary dependencies
echo "Installing necessary dependencies..."
sudo apt-get update
sudo apt-get install -y gnupg curl libssl1.1

# Import the MongoDB public GPG key
echo "Importing MongoDB public GPG key..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

# Create a list file for MongoDB
echo "Creating MongoDB repository list file..."
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update package database
echo "Updating package database..."
sudo apt-get update

# Force install specific versions that are compatible with Debian 11
echo "Installing MongoDB packages..."
sudo apt-get install -y mongodb-org-server=7.0.7 mongodb-org-mongos=7.0.7 mongodb-org-shell=7.0.7 mongodb-org-database-tools=7.0.7 mongodb-org-tools=7.0.7 mongodb-mongosh

# Create systemd service file if needed
if [ ! -f /lib/systemd/system/mongod.service ]; then
    echo "Creating systemd service file..."
    cat <<EOF | sudo tee /lib/systemd/system/mongod.service
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
User=mongodb
Group=mongodb
EnvironmentFile=-/etc/default/mongod
ExecStart=/usr/bin/mongod --config /etc/mongod.conf
PIDFile=/var/run/mongodb/mongod.pid
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false
# Recommended limits for mongod as specified in
# https://docs.mongodb.org/manual/reference/ulimit/#recommended-ulimit-settings

[Install]
WantedBy=multi-user.target
EOF
fi

# Create MongoDB data directory
echo "Creating MongoDB data directory..."
sudo mkdir -p /var/lib/mongodb
sudo chown -R mongodb:mongodb /var/lib/mongodb

# Create MongoDB log directory
echo "Creating MongoDB log directory..."
sudo mkdir -p /var/log/mongodb
sudo chown -R mongodb:mongodb /var/log/mongodb

# Check if MongoDB configuration exists
if [ ! -f /etc/mongod.conf ]; then
    echo "Creating MongoDB configuration file..."
    cat <<EOF | sudo tee /etc/mongod.conf
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
EOF
fi

# Reload systemd to recognize new service file
echo "Reloading systemd..."
sudo systemctl daemon-reload

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
echo "MongoDB installation completed!"
echo "If MongoDB is not running, try: sudo systemctl start mongod"
echo "To check status: sudo systemctl status mongod"