#!/bin/bash

# Configuration
# Default values (can be overridden by arguments)
RPI_USER="${1:-sprigrig}"
RPI_HOST="${2:-192.168.2.215}"
RPI_PASS="1"
RPI_DIR="/home/$RPI_USER/SprigRig-main"

if ! command -v sshpass &> /dev/null; then
    echo "Error: sshpass is not installed."
    echo "Please install it using: brew install sshpass (on macOS) or sudo apt-get install sshpass (on Linux)"
    exit 1
fi

if [ -z "$1" ] && [ -z "$2" ]; then
    echo "Usage: ./deploy_to_pi.sh <username> <ip_address>"
    echo "Using defaults: $RPI_USER@$RPI_HOST"
    echo "Press ENTER to continue or Ctrl+C to cancel..."
    read
fi

echo "Deploying SprigRig to $RPI_USER@$RPI_HOST..."

# 1. Create directory on Pi
echo "Creating directory on Pi..."
sshpass -p "$RPI_PASS" ssh $RPI_USER@$RPI_HOST "mkdir -p $RPI_DIR"

# 2. Sync files (excluding build artifacts and hidden files)
echo "Syncing files..."
sshpass -p "$RPI_PASS" rsync -avz --exclude 'build/' --exclude '.dart_tool/' --exclude '.git/' --exclude '.idea/' --exclude '.vscode/' ./ $RPI_USER@$RPI_HOST:$RPI_DIR/

# 2.5 Deploy Python hardware scripts
echo "Deploying Python scripts to /opt/sprigrig..."
sshpass -p "$RPI_PASS" ssh $RPI_USER@$RPI_HOST "sudo mkdir -p /opt/sprigrig/python/hardware && sudo cp -r $RPI_DIR/python/hardware/* /opt/sprigrig/python/hardware/ && sudo chmod +x /opt/sprigrig/python/hardware/*.py"

# 3. Build and Run on Pi
echo "Building and running on Pi..."
sshpass -p "$RPI_PASS" ssh -t $RPI_USER@$RPI_HOST "cd $RPI_DIR && /home/$RPI_USER/flutter-elinux/bin/flutter-elinux pub get && /home/$RPI_USER/flutter-elinux/bin/flutter-elinux run -d linux"
