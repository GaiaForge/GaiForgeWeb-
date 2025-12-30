---
description: How to deploy SprigRig to Raspberry Pi 5
---

# Deploying to Raspberry Pi 5

Follow these steps to get SprigRig running on your Raspberry Pi.

## 1. Prerequisites
Ensure your Raspberry Pi is running Raspberry Pi OS (64-bit recommended) and is connected to the internet.

### Install Dependencies
Open a terminal on your Raspberry Pi and run:
```bash
sudo apt-get update
sudo apt-get install -y git curl cmake ninja-build clang pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev libjsoncpp-dev libsecret-1-0
```

### Install Flutter
1.  Download Flutter for Linux (ARM64):
    ```bash
    cd ~
    git clone https://github.com/flutter/flutter.git -b stable
    ```
2.  Add Flutter to your path:
    ```bash
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    source ~/.bashrc
    ```
3.  Verify installation:
    ```bash
    flutter doctor
    ```

## 2. Get the Code
Clone the repository to your Raspberry Pi:
```bash
git clone https://github.com/GaiaForge/SprigRig-main.git
cd SprigRig-main
```

## 3. Configure Cameras (RPi 5)
For dual cameras on RPi 5, ensure your `/boot/firmware/config.txt` is configured correctly (usually automatic, but verify if needed).
You may need to add `dtoverlay=imx219,cam1` etc., depending on your camera modules.

## 4. Build and Run
### Development Mode (Hot Reload)
To run with logs and hot reload:
```bash
flutter run -d linux
```

### Release Build (Optimized)
To build a standalone executable:
```bash
flutter build linux --release
```
The executable will be located at `build/linux/arm64/release/bundle/sprigrig`.

## 5. Auto-Start (Optional)
To start SprigRig automatically on boot:
1.  Create an autostart entry:
    ```bash
    mkdir -p ~/.config/autostart
    nano ~/.config/autostart/sprigrig.desktop
    ```
2.  Add the following content:
    ```ini
    [Desktop Entry]
    Type=Application
    Name=SprigRig
    Exec=/home/pi/SprigRig-main/build/linux/arm64/release/bundle/sprigrig
    Terminal=false
    ```
