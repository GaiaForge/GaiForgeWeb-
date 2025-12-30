#!/usr/bin/env python3
import argparse
import subprocess
import os
import sys
import re

def create_timelapse(image_dir, output_file, fps, width, height, pattern):
    """
    Creates a timelapse video using ffmpeg.
    """
    # Check if ffmpeg is installed
    if subprocess.call(['which', 'ffmpeg'], stdout=subprocess.DEVNULL) != 0:
        print("Error: ffmpeg is not installed")
        sys.exit(1)

    # Construct ffmpeg command
    # -y: Overwrite output file
    # -framerate: Input frame rate
    # -i: Input file pattern (e.g., image_%04d.jpg)
    # -c:v libx264: Video codec
    # -pix_fmt yuv420p: Pixel format for compatibility
    # -vf: Video filters (scale)
    
    # We need to create a temporary file list because images might not be sequentially numbered perfectly for ffmpeg's %d pattern if we are filtering them
    # However, the user request implies we might be passing a list or a pattern.
    # Let's try to use the glob pattern if possible, but if we have a specific range, we might need to be more clever.
    # For now, let's assume we are passing a directory and a glob pattern that matches the files we want.
    # But wait, the user selects a range in the UI. 
    # The easiest way to handle arbitrary selections is to create a temporary directory with symlinks or a text file input for ffmpeg.
    # Text file input (concat demuxer) is safer for non-sequential files.
    
    pass

def main():
    parser = argparse.ArgumentParser(description='Create timelapse video from images')
    parser.add_argument('--input_list', required=True, help='Path to text file containing list of images')
    parser.add_argument('--output', required=True, help='Output video file path')
    parser.add_argument('--fps', type=int, default=24, help='Frames per second')
    parser.add_argument('--width', type=int, default=1920, help='Output width')
    parser.add_argument('--height', type=int, default=1080, help='Output height')
    
    args = parser.parse_args()

    # ffmpeg -f concat -safe 0 -i input.txt -vsync vfr -pix_fmt yuv420p output.mp4
    # We also need to add scaling: -vf scale=width:height:force_original_aspect_ratio=decrease,pad=width:height:(ow-iw)/2:(oh-ih)/2
    
    scale_filter = f"scale={args.width}:{args.height}:force_original_aspect_ratio=decrease,pad={args.width}:{args.height}:(ow-iw)/2:(oh-ih)/2"
    
    cmd = [
        'ffmpeg',
        '-y', # Overwrite
        '-f', 'concat',
        '-safe', '0',
        '-r', str(args.fps), # Input fps (read rate)
        '-i', args.input_list,
        '-c:v', 'libx264',
        '-pix_fmt', 'yuv420p',
        '-vf', scale_filter,
        '-r', str(args.fps), # Output fps
        args.output
    ]
    
    print(f"Running command: {' '.join(cmd)}")
    
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True
    )

    # Parse output for progress
    # ffmpeg output looks like: frame=  234 fps= 24 q=28.0 size=     512kB time=00:00:09.75 bitrate= 430.1kbits/s speed=1.23x
    duration = 0
    
    # First pass to estimate duration? No, we know the number of images.
    # We can estimate total frames from the input list.
    with open(args.input_list, 'r') as f:
        total_frames = sum(1 for line in f if line.strip().startswith('file '))
        
    print(f"Total frames to process: {total_frames}")

    for line in process.stdout:
        line = line.strip()
        if 'frame=' in line:
            match = re.search(r'frame=\s*(\d+)', line)
            if match:
                current_frame = int(match.group(1))
                progress = (current_frame / total_frames) * 100
                print(f"PROGRESS:{progress:.1f}")
        
    process.wait()
    
    if process.returncode == 0:
        print("SUCCESS")
    else:
        print("FAILURE")
        sys.exit(1)

if __name__ == '__main__':
    main()
