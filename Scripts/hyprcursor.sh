#!/bin/bash

# Script to build and install hyprcursor
set -e  # Exit immediately if a command exits with a non-zero status

# Variables
REPO_URL="https://github.com/hyprwm/hyprcursor.git"
BUILD_DIR="./build"
INSTALL_PREFIX="/usr"

# Clone the repository
if [ ! -d "hyprcursor" ]; then
    echo "Cloning the hyprcursor repository..."
    git clone "$REPO_URL"
else
    echo "Repository already exists. Pulling the latest changes..."
    cd hyprcursor
    git pull
    cd ..
fi

# Navigate to the repository
cd hyprcursor

# Configure the build
echo "Configuring the build with CMake..."
cmake --no-warn-unused-cli \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_PREFIX" \
    -S . \
    -B "$BUILD_DIR"

# Build the project
echo "Building the project..."
cmake --build "$BUILD_DIR" --config Release --target all -j$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)

# Install the project
echo "Installing the project..."
sudo cmake --install "$BUILD_DIR"

echo "hyprcursor installation completed successfully!"
