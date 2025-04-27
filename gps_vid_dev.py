# Recreate the updated script after code execution environment reset

# This script captures video and GPS data, logs the GPS data to a GPX file, and records the video to a file.
import time
import gpsd
import datetime
import subprocess
import signal
import sys
import os

video_proc = None
PIPE_PATH = "/tmp/vid_pipe"
PLACEHOLDER = "<!-- GPSDATA -->"

def get_timestamp():
    return datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

def connect_gpsd():
    try:
        gpsd.connect()
        print("Connected to GPSD.")
    except Exception as e:
        print(f"Failed to connect to GPSD: {e}")
        exit(1)

def get_gps_data():
    try:
        packet = gpsd.get_current()
        if packet.mode >= 2:  # Mode 2 = 2D fix, Mode 3 = 3D fix
            return packet.lat, packet.lon, packet.time
    except Exception as e:
        print(f"Error getting GPS data: {e}")
        return None

def write_gpx_template(file_path):
    with open(file_path, "w") as f:
        f.write(f'''<?xml version="1.0" encoding="UTF-8"?>
<gpx>
  <trk>
    <trkseg>
      {PLACEHOLDER}
    </trkseg>
  </trk>
</gpx>
''')

def insert_gps_point(lat, lon, timestamp, file_path):
    with open(file_path, "r") as f:
        contents = f.read()

    new_point = f'<trkpt lat="{lat}" lon="{lon}"><time>{timestamp}</time></trkpt>\\n      '

    if PLACEHOLDER in contents:
        contents = contents.replace(PLACEHOLDER, new_point + PLACEHOLDER)
        with open(file_path, "w") as f:
            f.write(contents)

def shutdown_handler(signum, frame):
    print("🛑 Shutdown signal received. Cleaning up...")
    global video_proc
    if video_proc:
        video_proc.terminate()
        video_proc.wait()
        print("🎥 Video recording stopped.")
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)

def start_camera_recording(pipe_path, output_filename):
    global video_proc

    # Create named pipe if needed
    if not os.path.exists(pipe_path):
        os.mkfifo(pipe_path)

    # Start ffmpeg
    ffmpeg_proc = subprocess.Popen([
        "ffmpeg", "-y", "-f", "h264", "-i", pipe_path,
        "-c:v", "copy", "-movflags", "+faststart", output_filename
    ])

    # Start libcamera-vid writing to the pipe
    video_proc = subprocess.Popen([
        "libcamera-vid", "-o", pipe_path,
        "-t", "0", "--framerate", "30", "--nopreview"
    ])
    return ffmpeg_proc

def log_gps():
    timestamp = get_timestamp()
    log_filename = f"/mnt/usb/gps_log_{timestamp}.gpx"
    video_filename = f"/mnt/usb/video_{timestamp}.mp4"

    write_gpx_template(log_filename)
    print(f"Logging GPS to {log_filename} and recording video to {video_filename}")

    ffmpeg_proc = start_camera_recording(PIPE_PATH, video_filename)

    try:
        while True:
            gps_data = get_gps_data()
            if gps_data:
                lat, lon, ts = gps_data
                insert_gps_point(lat, lon, ts, log_filename)
                print(f"Logged: {lat}, {lon} at {ts}")
            else:
                print("No GPS fix yet...")
            time.sleep(1)
    except KeyboardInterrupt:
        print("Exiting.")
        shutdown_handler(None, None)

if __name__ == "__main__":
    connect_gpsd()
    log_gps()



