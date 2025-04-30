#!/bin/bash

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

sudo apt install netatalk -y


echo "Installing system dependencies..."
sudo apt install -y python3-pip python3-venv python3-gps netatalk

echo "📦 Installing usbmount dependencies..."
sudo apt install -y udisks2

echo "Allow for exFat usb file partitions"
sudo apt install -y exfat-fuse
sudo apt install -y exfatprogs

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

echo "📁 Setting up AFP share at /home/pi..."

# Create a special shared folder if it doesn't exist, just use home directory
# mkdir -p /home/pi/SpecialFolder

# Append AFP share config if not already present
if ! grep -q "\[PiShare\]" /etc/netatalk/afp.conf; then
  sudo tee -a /etc/netatalk/afp.conf > /dev/null <<EOF

[PiShare]
path = /home/pi/
time machine = no
EOF
  echo "✅ AFP share configuration added."
else
  echo "ℹ️ AFP share [PiShare] already exists in afp.conf. Skipping."
fi

# Restart netatalk to apply changes
sudo systemctl restart netatalk


echo "Installing virtualenv..."
pip3 install --user virtualenv

# Create Python virtual environment
VENV_DIR="$HOME/gps_cam"

mkdir $VENV_DIR
if [ ! -d "$VENV_DIR/.env" ]; then
  echo "🌱 Creating Python virtual environment at $VENV_DIR"
  cd "$VENV_DIR"
  python3 -m venv .env
fi

# Activate the virtual environment and install pip packages
source "$VENV_DIR/.env/bin/activate"

echo "Installing pip packages inside virtual environment..."
pip install --upgrade pip
pip install \
    gpsd-py3 \
    haversine \
    geonamescache \
    RPi.GPIO \
    gpxpy


echo "Downloading gps_vidV0.py from GitHub..."

mkdir -p /home/pi/gps_cam

curl -fsSL -o /home/pi/gps_cam/gps_vid_prod.py \
  https://raw.githubusercontent.com/redmond2742/rpi_gps_cam/refs/heads/main/gps_vid_production.py

chmod +x /home/pi/gps_cam/gps_vid_production.py

curl -fsSL -o /home/pi/startup.sh \
  https://raw.githubusercontent.com/redmond2742/rpi_gps_cam/refs/heads/main/startup.sh

chmod +x /home/pi/startup.sh

echo "Downloaded and prepared python and statup files"


echo "Creating systemd service: gpslogger.service..."

sudo tee /etc/systemd/system/gpslogger.service > /dev/null <<EOF
[Unit]
Description=GPS and Video Logger
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/gps_cam/gps_vidV1.py
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


echo "⚙️ Creating USB automount script..."
sudo tee /usr/local/bin/mount-usb.sh > /dev/null <<'EOF'
#!/bin/bash

MOUNT_POINT="/mnt/usb"

for DEV in /dev/sd[a-z][1-9]*; do
    if ! mount | grep -q "$DEV"; then
        mkdir -p "$MOUNT_POINT"
        mount "$DEV" "$MOUNT_POINT" && chown -R pi:pi "$MOUNT_POINT"
        echo "🔌 USB mounted at $MOUNT_POINT"
        exit 0
    fi
done
EOF

sudo chmod +x /usr/local/bin/mount-usb.sh

echo "📝 Creating udev rule for USB automount..."
sudo tee /etc/udev/rules.d/99-usb-mount.rules > /dev/null <<EOF
ACTION=="add", SUBSYSTEMS=="usb", KERNEL=="sd*[0-9]", RUN+="/usr/local/bin/mount-usb.sh"
EOF

# Apply new udev rules
sudo udevadm control --reload-rules

echo "🛠 Updating /boot/config.txt for libcamera support..."

sudo sed -i 's/^start_x=1/#start_x=1/' /boot/config.txt
sudo sed -i 's/^gpu_mem=128/#gpu_mem=128/' /boot/config.txt

# Only add the new lines if they're not already present
grep -q "^dtoverlay=vc4-kms-v3d" /boot/config.txt || echo "dtoverlay=vc4-kms-v3d" | sudo tee -a /boot/config.txt
grep -q "^camera_auto_detect=1" /boot/config.txt || echo "camera_auto_detect=1" | sudo tee -a /boot/config.txt

echo "✅ /boot/config.txt updated."




