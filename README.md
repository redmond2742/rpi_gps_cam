# Raspberry Pi GPS and Video Logger
Simple raspberry pi config to log GPS and Video.

## Hardware
* $25 Raspberry Pi (3A+) - Eventually trying to get a Zero W to work
* $20 RPi Camera
* $20 GPS Hat
* USB Drive for GPX and video files
* SD Card for OS (not for logging)

### Software Setup and Notes
* Note: Needs Python 3.9 for some python packages
* Using Raspberry Pi OS - Bullsye (Legacy) 64 bit lite OS (no desktop version)
* Enable Wifi (WPA supplicant file) and SSH on device
* Download and run setup bash script (in this repo) \
  $ bash <(curl -s https://raw.githubusercontent.com/redmond2742/rpi_gps_cam/main/setup_pi_env.sh



Configure Netatalk file. -Todo: add to script above
$ sudo raspi-config to:
  * Enable camera interface
  * Enable GPIO pins
Download Service file (add to repo)
Config GPS Device to use Serial Connection pins

Test run python script in virtual enviornment



