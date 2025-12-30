#!/usr/bin/env python3
import argparse
import sys
import time
import subprocess
import os
import re

def capture_csi(args):
    try:
        # Use rpicam-still
        cmd = [
            'rpicam-still',
            '-t', '2000', # 2s timeout for AWB
            '-o', args.output,
            '--width', str(args.width),
            '--height', str(args.height),
            '--nopreview'
        ]
        
        if args.camera is not None:
             cmd.extend(['--camera', str(args.camera)])
        
        subprocess.run(cmd, check=True)
        print(args.output)
        
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"Error capturing CSI image: {e}\n")
        sys.exit(1)
    except Exception as e:
        sys.stderr.write(f"Error capturing CSI image: {e}\n")
        sys.exit(1)

def capture_usb(args):
    try:
        import cv2
        
        dev_id = 0
        if args.camera is not None:
            dev_id = int(args.camera)
        elif args.device:
            match = re.search(r'video(\d+)', args.device)
            if match:
                dev_id = int(match.group(1))
        
        cap = cv2.VideoCapture(dev_id)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)
        
        if not cap.isOpened():
            sys.stderr.write(f"Error: Could not open USB device {dev_id}\n")
            sys.exit(1)
        
        # Warmup
        for _ in range(10):
            cap.read()
        
        ret, frame = cap.read()
        if ret:
            cv2.imwrite(args.output, frame, [cv2.IMWRITE_JPEG_QUALITY, 90])
            print(args.output)
        else:
            sys.stderr.write("Error: Failed to capture frame\n")
            sys.exit(1)
        
        cap.release()
        
    except ImportError:
        sys.stderr.write("Error: opencv-python not installed\n")
        sys.exit(1)
    except Exception as e:
        sys.stderr.write(f"Error capturing USB image: {e}\n")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Capture image from camera')
    parser.add_argument('--device', help='Device path')
    parser.add_argument('--camera', type=int, help='Camera index')
    parser.add_argument('--width', type=int, required=True, help='Image width')
    parser.add_argument('--height', type=int, required=True, help='Image height')
    parser.add_argument('--output', required=True, help='Output file path')
    
    args = parser.parse_args()
    
    # Ensure directory exists
    if os.path.dirname(args.output):
        os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    # If --camera is provided, try CSI first (as per user request for rpicam-still)
    if args.camera is not None:
        capture_csi(args)
    elif args.device:
        # Legacy/USB path
        if '/base/' in args.device or 'i2c' in args.device:
            capture_csi(args)
        else:
            capture_usb(args)
    else:
        sys.stderr.write("Error: Either --device or --camera must be specified\n")
        sys.exit(1)

if __name__ == "__main__":
    main()