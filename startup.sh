#!/bin/bash

ls /mnt/usb
echo "🔌 Mounting USB drive..."

# Check if the USB drive is already mounted
if mount | grep -q "/mnt/usb"; then
    echo "USB drive is already mounted."
else
    # Create mount point if it doesn't exist
    sudo mkdir -p /mnt/usb
    # Mount the USB drive
    sudo mount -t exfat -o uid=pi,gid=pi /dev/sdb1 /mnt/usb
    echo "USB drive mounted at /mnt/usb."
fi

echo "Restarting gpsd service..."
sudo systemctl stop gpsd.socket
sudo systemctl disable gpsd.socket
sudo systemctl restart gpsd


# E7F4-B1DD

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


#echo "⚙️ Creating USB automount script..."
#sudo tee /usr/local/bin/mount-usb.sh > /dev/null <<'EOF'

#MOUNT_POINT="/mnt/usb"

#for DEV in /dev/sd[a-z][1-9]*; do
#    if ! mount | grep -q "$DEV"; then
#        mkdir -p "$MOUNT_POINT"
#        mount "$DEV" "$MOUNT_POINT" && chown -R pi:pi "$MOUNT_POINT"
#        echo "🔌 USB mounted at $MOUNT_POINT"
#        exit 0
#    fi
#done
#EOF

#sudo chmod +x /usr/local/bin/mount-usb.sh

#echo "📝 Creating udev rule for USB automount..."
#sudo tee /etc/udev/rules.d/99-usb-mount.rules > /dev/null <<EOF
#ACTION=="add", SUBSYSTEMS=="usb", KERNEL=="sd*[0-9]", RUN+="/usr/local/bin/mount-usb.sh"
#EOF

# Apply new udev rules
#sudo udevadm control --reload-rules
