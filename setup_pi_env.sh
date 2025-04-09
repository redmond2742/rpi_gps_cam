#!/bin/bash

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing system dependencies..."
sudo apt install -y python3-pip python3-venv python3-gps netatalk

echo "Installing virtualenv..."
pip3 install --user virtualenv

# Create Python virtual environment
VENV_DIR="$HOME/pi_env"
if [ ! -d "$VENV_DIR" ]; then
  echo "🌱 Creating Python virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment and install pip packages
source "$VENV_DIR/bin/activate"

echo "Installing pip packages inside virtual environment..."
pip install --upgrade pip
pip install \
    gpsd-py3 \
    haversine \
    geonamescache \
    RPi.GPIO \
    gpxpy

echo "Environment setup complete!"
echo "To activate your Python environment later, run:"
echo "   source $VENV_DIR/bin/activate"
