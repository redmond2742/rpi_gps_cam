import time
import gpsd
import datetime
import subprocess

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

def write_gpx_header(file_path):
    with open(file_path, "w") as file:
        file.write("""<?xml version="1.0" encoding="UTF-8"?>
<gpx><trk><trkseg>
""")

def write_gpx_footer(file_path):
    with open(file_path, "a") as file:
        file.write("</trkseg></trk></gpx>\n")

def start_camera_recording(video_filename):
    print(f"Starting camera recording: {video_filename}")
    subprocess.Popen(["raspivid", "-o", video_filename, "-t", "0"])  # Record until manually stopped

def log_gps():
    timestamp = get_timestamp()
    log_filename = f"/home/pi/gps_log_{timestamp}.gpx"
    video_filename = f"/home/pi/video_{timestamp}.h264"
    
    write_gpx_header(log_filename)
    print(f"Logging GPS data to {log_filename} and recording video to {video_filename}. Press Ctrl+C to stop.")
    
    start_camera_recording(video_filename)
    
    try:
        while True:
            gps_data = get_gps_data()
            if gps_data:
                lat, lon, timestamp = gps_data
                with open(log_filename, "a") as file:
                    file.write(f'<trkpt lat="{lat}" lon="{lon}"><time>{timestamp}</time></trkpt>\n')
                print(f"Logged: {lat}, {lon} at {timestamp}")
            else:
                print("No GPS fix yet...")
            time.sleep(1)  # Wait 1 second before logging the next point
    except KeyboardInterrupt:
        print("\nStopping GPS logging and camera recording.")
        write_gpx_footer(log_filename)
        subprocess.run(["pkill", "raspivid"])  # Stop the camera recording

if __name__ == "__main__":
    connect_gpsd()
    log_gps()

