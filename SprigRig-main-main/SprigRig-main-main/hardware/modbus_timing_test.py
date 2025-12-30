#!/usr/bin/env python3
"""
Modbus Timing Test Script with Manual Direction Control
"""

import serial
import time
import RPi.GPIO as GPIO

PORT = '/dev/ttySC0'
BAUDRATE = 9600
TXDEN_1 = 27  # Direction control pin for channel 0


def crc16(data):
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if (crc & 1) else crc >> 1
    return crc.to_bytes(2, 'little')


def build_command(cmd_type, relay=0, state=True):
    if cmd_type == "write_single":
        cmd = bytes([0x01, 0x05, 0x00, relay, 0xFF if state else 0x00, 0x00])
    elif cmd_type == "read_coils":
        cmd = bytes([0x01, 0x01, 0x00, 0x00, 0x00, 0x08])
    elif cmd_type == "write_all":
        data = 0xFF if state else 0x00
        cmd = bytes([0x01, 0x0F, 0x00, 0x00, 0x00, 0x08, 0x01, data])
    return cmd + crc16(cmd)


def validate_crc(response):
    if len(response) < 4:
        return False
    received_crc = response[-2] | (response[-1] << 8)
    calc_crc = 0xFFFF
    for byte in response[:-2]:
        calc_crc ^= byte
        for _ in range(8):
            calc_crc = (calc_crc >> 1) ^ 0xA001 if (calc_crc & 1) else calc_crc >> 1
    return calc_crc == received_crc


def test_command(ser, name, command, post_write_delay):
    print(f"\n--- {name} (delay: {post_write_delay}ms) ---")
    print(f"TX: {command.hex()}")
    
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    
    # Enable TX mode
    GPIO.output(TXDEN_1, GPIO.LOW)
    
    ser.write(command)
    ser.flush()
    time.sleep(0.005)  # Wait for TX to complete
    
    # Switch to RX mode
    GPIO.output(TXDEN_1, GPIO.HIGH)
    
    time.sleep(post_write_delay / 1000.0)
    
    # Poll for response
    response = b''
    start = time.time()
    while time.time() - start < 1.0:
        chunk = ser.read(ser.in_waiting or 1)
        if chunk:
            response += chunk
            time.sleep(0.01)
        elif response:
            break
        time.sleep(0.01)
    
    if response:
        print(f"RX ({len(response)} bytes): {response.hex()}")
        if validate_crc(response):
            print("✓ CRC VALID")
            return True, response
        else:
            print("✗ CRC INVALID")
            return True, response
    else:
        print("No response")
        return False, None


def main():
    print("Modbus Timing Test (Manual Direction Control)")
    print(f"Port: {PORT} @ {BAUDRATE} baud")
    print(f"Direction pin: GPIO {TXDEN_1}")
    print("=" * 50)
    
    # Setup GPIO for direction control
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    GPIO.setup(TXDEN_1, GPIO.OUT)
    GPIO.output(TXDEN_1, GPIO.HIGH)  # Start in RX mode
    
    try:
        ser = serial.Serial(
            port=PORT,
            baudrate=BAUDRATE,
            bytesize=8,
            parity='N',
            stopbits=1,
            timeout=0.1
        )
        print(f"Opened: {ser.name}\n")
        
        delays = [10, 20, 50, 100, 150, 200]
        
        write_cmd = build_command("write_single", 0, True)
        read_cmd = build_command("read_coils")
        
        print("=" * 50)
        print("WRITE COMMAND TESTS")
        print("=" * 50)
        
        successful = []
        for delay in delays:
            success, resp = test_command(ser, "write_relay_1_on", write_cmd, delay)
            if success and resp:
                successful.append(('write', delay, resp))
            time.sleep(0.2)
        
        print("\n" + "=" * 50)
        print("READ COMMAND TESTS")
        print("=" * 50)
        
        for delay in delays:
            success, resp = test_command(ser, "read_all_coils", read_cmd, delay)
            if success and resp:
                successful.append(('read', delay, resp))
            time.sleep(0.2)
        
        print("\n" + "=" * 50)
        print("SUMMARY")
        print("=" * 50)
        
        if successful:
            print(f"✅ {len(successful)} successful responses:")
            for cmd_type, delay, resp in successful:
                print(f"  • {cmd_type} @ {delay}ms: {resp.hex()}")
        else:
            print("❌ No responses received")
        
    except serial.SerialException as e:
        print(f"Serial Error: {e}")
    except KeyboardInterrupt:
        print("\nInterrupted")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("\nPort closed")
        GPIO.cleanup()


if __name__ == "__main__":
    main()