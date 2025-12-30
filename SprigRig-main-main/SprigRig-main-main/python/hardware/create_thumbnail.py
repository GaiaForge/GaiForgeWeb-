#!/usr/bin/env python3
import argparse
from PIL import Image
import sys
import os


def main():
    parser = argparse.ArgumentParser(description='Create thumbnail')
    parser.add_argument('--input', required=True, help='Input image path')
    parser.add_argument('--output', required=True, help='Output thumbnail path')
    parser.add_argument('--size', type=int, default=320, help='Max dimension')
    args = parser.parse_args()
    
    try:
        if os.path.dirname(args.output):
            os.makedirs(os.path.dirname(args.output), exist_ok=True)
        
        with Image.open(args.input) as img:
            img.thumbnail((args.size, args.size))
            img.save(args.output, "JPEG", quality=85)
        
        print(args.output)
        
    except Exception as e:
        sys.stderr.write(f"Error creating thumbnail: {e}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()