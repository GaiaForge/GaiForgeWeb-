#!/usr/bin/env python3
import json
import subprocess
import re
import sys

def detect_cameras():
    try:
        # Run rpicam-hello --list-cameras
        result = subprocess.run(
            ['rpicam-hello', '--list-cameras'],
            capture_output=True,
            text=True,
            check=False  # Don't raise exception on non-zero exit code immediately
        )

        if result.returncode != 0:
            # Check if command not found
            if "No such file or directory" in result.stderr:
                 return json.dumps({"error": "rpicam-hello not found. Ensure libcamera-apps is installed."})
            # It might return non-zero if no cameras, but usually it just prints "No cameras available"
            # Let's proceed to parse output anyway, or return error if stderr is significant
            pass

        output = result.stdout
        cameras = []
        
        # Regex to find camera entries
        # Example line: 0 : imx219 [3280x2464 10-bit RGGB] (/base/axi/pcie@1000120000/rp1/i2c@88000/imx219@10)
        # We want to extract index (0) and model (imx219)
        
        # Split by lines and iterate
        lines = output.split('\n')
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            match = re.match(r'(\d+)\s*:\s*(\S+)\s*\[(\d+)x(\d+).*\]', line)
            if match:
                index = int(match.group(1))
                model = match.group(2)
                width = int(match.group(3))
                height = int(match.group(4))
                cameras.append({
                  'id': index,
                  'name': f'CSI Camera {index}',
                  'type': 'csi',
                  'model': model,
                  'port': f'/dev/video{index}',
                  'max_width': width,
                  'max_height': height,
                  'index': index,
                })
                
        return cameras
    except FileNotFoundError:
        return [] # rpicam-hello not found, assume no CSI cameras
    except Exception as e:
        sys.stderr.write(f"Error detecting CSI cameras: {e}\n")
        return []

def get_usb_cameras():
    cameras = []
    try:
        # List V4L2 devices
        # v4l2-ctl --list-devices
        result = subprocess.run(
            ['v4l2-ctl', '--list-devices'],
            capture_output=True,
            text=True,
            check=True
        )
        output = result.stdout
        
        lines = output.split('\n')
        current_device = None
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            if not line.startswith('/dev/'):
                # New device block
                # Filter out codecs and ISP
                if any(x in line for x in ['bcm2835-codec', 'bcm2835-isp', 'rpivid', 'pispbe', 'rp1-cfe', 'rpi-hevc-dec']):
                    current_device = None
                else:
                    # Clean up name "C920 Pro HD Webcam (usb-0000:01:00.0-1.4):"
                    name = line.split('(')[0].strip()
                    current_device = {"name": name}
            elif current_device:
                # Device path
                # Only take the first one for a device usually, or check capabilities
                # For simplicity, we take the first /dev/video node
                if "device_path" not in current_device:
                    current_device["device_path"] = line
                    # We need resolution. v4l2-ctl --list-formats-ext -d /dev/videoX
                    # This is slow, maybe skip for now or implement simple check
                    # For now default to 1920x1080 for USB or try to fetch
                    width, height = get_usb_resolution(line)
                    current_device["max_width"] = width
                    current_device["max_height"] = height
                    current_device["type"] = "usb"
                    current_device["id"] = len(cameras) + 100 # Offset ID for USB
                    current_device["sensor"] = "usb"
                    cameras.append(current_device)
                    current_device = None # Done with this device block
                    
    except FileNotFoundError:
        pass
    except Exception as e:
        sys.stderr.write(f"Error detecting USB cameras: {e}\n")
        
    return cameras

def get_usb_resolution(device_path):
    try:
        res = subprocess.run(['v4l2-ctl', '-d', device_path, '--list-formats-ext'], capture_output=True, text=True)
        # Find max resolution
        max_w = 640
        max_h = 480
        for line in res.stdout.split('\n'):
            match = re.search(r'Size: Discrete (\d+)x(\d+)', line)
            if match:
                w = int(match.group(1))
                h = int(match.group(2))
                if w * h > max_w * max_h:
                    max_w = w
                    max_h = h
        return max_w, max_h
    except:
        return 1920, 1080

def main():
    csi = detect_cameras()
    usb = get_usb_cameras()
    print(json.dumps(csi + usb, indent=2))

if __name__ == "__main__":
    main()
