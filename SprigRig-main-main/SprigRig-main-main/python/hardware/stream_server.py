#!/usr/bin/env python3
from flask import Flask, Response
import subprocess
import signal
import sys

app = Flask(__name__)
processes = {}

def generate_frames(camera_index):
    """Generate MJPEG frames from rpicam-vid"""
    process = subprocess.Popen(
        ['rpicam-vid', '-t', '0', '--camera', str(camera_index),
         '--width', '640', '--height', '480', '--codec', 'mjpeg',
         '--inline', '-o', '-'],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL
    )
    processes[camera_index] = process
    
    buffer = b''
    while True:
        chunk = process.stdout.read(4096)
        if not chunk:
            break
        buffer += chunk
        
        # Find JPEG frames (FFD8 = start, FFD9 = end)
        while True:
            start = buffer.find(b'\xff\xd8')
            end = buffer.find(b'\xff\xd9')
            if start != -1 and end != -1 and end > start:
                frame = buffer[start:end+2]
                buffer = buffer[end+2:]
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
            else:
                break

@app.route('/stream/<int:camera_index>')
def video_feed(camera_index):
    return Response(
        generate_frames(camera_index),
        mimetype='multipart/x-mixed-replace; boundary=frame'
    )

@app.route('/health')
def health():
    return {'status': 'ok'}

def cleanup(sig, frame):
    for proc in processes.values():
        proc.terminate()
    sys.exit(0)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081, threaded=True)
