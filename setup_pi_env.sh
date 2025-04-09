#!/bin/bash

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing system dependencies..."
sudo apt install -y python3-pip python3-venv python3-gps netatalk

echo " Configuring /etc/default/gpsd..."

sudo tee /etc/default/gpsd > /dev/null <<EOF
START_DAEMON="true"
GPSD_OPTIONS="-n"
DEVICES="/dev/serial0"
GPSD_SOCKET="/var/run/gpsd.sock"
EOF

echo "Restarting gpsd service..."
sudo systemctl stop gpsd.socket
sudo systemctl disable gpsd.socket
sudo systemctl restart gpsd

echo "📁 Setting up AFP share at /home/pi/MacShare..."

# Create the shared folder if it doesn't exist
mkdir -p /home/pi/MacShare

# Append AFP share config if not already present
if ! grep -q "\[MacShare\]" /etc/netatalk/afp.conf; then
  sudo tee -a /etc/netatalk/afp.conf > /dev/null <<EOF

[MacShare]
path = /home/pi/MacShare
time machine = no
EOF
  echo "✅ AFP share configuration added."
else
  echo "ℹ️ AFP share [MacShare] already exists in afp.conf. Skipping."
fi

# Restart netatalk to apply changes
sudo systemctl restart netatalk


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


echo "Creating systemd service: gpslogger.service..."

sudo tee /etc/systemd/system/gpslogger.service > /dev/null <<EOF
[Unit]
Description=GPS and Video Logger
After=network.target

[Service]
# ExecStart=/usr/bin/python3 /home/pi/gps_cam/gps_vidV0.py
WorkingDirectory=/home/pi
StandardOutput=inherit
StandardError=inherit
User=pi

[Install]
WantedBy=multi-user.target
EOF

echo "🔁 Enabling and starting gpslogger service..."
sudo systemctl daemon-reload
sudo systemctl enable gpslogger.service
sudo systemctl start gpslogger.service


echo "Environment setup complete!"
echo "To activate your Python environment later, run:"
echo "   source $VENV_DIR/bin/activate"
