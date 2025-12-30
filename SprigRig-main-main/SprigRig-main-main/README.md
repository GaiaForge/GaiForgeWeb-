# SprigRig 🌱

**Advanced Automated Growing System**

SprigRig is a comprehensive zone-based intelligent growing system featuring dynamic dashboards, astral scheduling, AI-powered monitoring, and modular hardware control. Built for home growers and commercial operations alike.

---

## Features

### Zone-Based Management
- **Multiple grow zones** with independent control and monitoring
- **Customizable dashboards** based on grow method and installed hardware
- **Per-zone configuration** for lighting, irrigation, ventilation, climate, and cameras

### Grow Methods Supported
- Soil Growing
- Hydroponics (DWC, Drip, Ebb & Flow)
- NFT (Nutrient Film Technique)
- Aeroponics

### Environmental Control
- **Lighting** — Scheduling, dimming, astral timing (sunrise/sunset sync)
- **Irrigation** — Automated watering schedules, reservoir management
- **Ventilation** — Fan control with environmental triggers
- **Climate** — Temperature and humidity automation
- **Aeration** — Air pump and oxygenation control

### Fertigation System
- Industrial pH and EC probe support (4-20mA, 0-10V)
- Peristaltic pump control for automated dosing
- Recipe-driven nutrient targets per growth phase
- Dose logging and trend analysis

### Guardian AI
- Continuous environmental monitoring with tiered alerts
- Plant health analysis using computer vision
- Nutrient deficiency and pest detection
- Recipe compliance monitoring
- Predictive warnings and actionable recommendations

### Recipe System
- Pre-built recipes for common crops (cannabis, tomatoes, peppers, herbs, microgreens)
- Phase-based growing with automatic target adjustment
- Custom recipe creation
- Environmental targets per phase (temp, humidity, pH, EC, light hours)

### Camera Integration
- Timelapse capture with grow day tagging
- Manual capture for documentation
- Integration with Guardian AI for plant health analysis
- Multi-camera support per zone

### Analytics
- Historical sensor data visualization
- Multi-sensor overlay charts
- Recipe target comparison
- Statistical analysis (min, max, average, std deviation)
- Data export (CSV, JSON)

---

## Hardware Architecture

### Controller
- **Raspberry Pi 5** (8GB recommended)
- RS485 CAN HAT for dual Modbus bus

### Relay Control
- **Waveshare 8-Channel Modbus Relay Module**
- Controls: lights, pumps, fans, heaters, etc.
- Modbus RTU protocol over RS485

### Sensor Hubs
- **Custom STM32G431-based sensor hubs**
- Modbus RTU slave devices
- DIP switch addressable (1-15)
- Inputs:
  - 2x 4-20mA current loop (industrial pH/EC probes)
  - 2x 0-10V analog (sensors, probes)
  - I2C bus (BME280, BME680, light sensors, etc.)
  - SPI bus (expansion)

### Supported Sensors
| Sensor | Type | Readings |
|--------|------|----------|
| DHT22 | Digital | Temperature, Humidity |
| BME280 | I2C | Temperature, Humidity, Pressure |
| BME680 | I2C | Temperature, Humidity, Pressure, Gas |
| Soil Moisture | Analog | Moisture % |
| pH Probe | 4-20mA / 0-10V | pH 0-14 |
| EC Probe | 4-20mA / 0-10V | Conductivity (mS/cm) |
| Light Sensor | I2C | Lux, PAR |
| CO2 Sensor | I2C | PPM |
| Water Level | Analog | Level % |
| Flow Rate | Digital | L/min |

### Cameras
- CSI cameras (IMX219, IMX477)
- USB cameras
- HDMI capture cards for IR cameras

---

## Software Stack

### Frontend
- **Flutter** (Dart)
- Cross-platform (runs on Pi, desktop for development)
- Responsive zone dashboards
- Real-time sensor displays

### Backend Services
- **Python** (FastAPI planned)
- Hardware abstraction layer
- Modbus communication
- Sensor polling and logging

### Database
- **SQLite**
- Sensor readings history
- Schedule storage
- Recipe and grow tracking
- Configuration persistence

### Communication
- **Modbus RTU** over RS485
- Dual bus architecture:
  - Bus 1: Relay modules
  - Bus 2: Sensor hubs

---

## Installation

### Prerequisites
- Raspberry Pi 5 with Raspberry Pi OS (64-bit)
- RS485 CAN HAT (B) installed
- Flutter SDK
- Python 3.11+

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/sprigrig.git
cd sprigrig
```

2. **Configure device tree overlays** (`/boot/config.txt`)
```
dtoverlay=sc16is752-spi1,int_pin=25
dtoverlay=imx219
```

3. **Install Flutter dependencies**
```bash
flutter pub get
```

4. **Run the application**
```bash
flutter run -d linux
```

### Development Mode
Set environment variable to mock hardware:
```bash
export SPRIGRIG_DEV=true
flutter run
```

---

## Configuration

### Modbus Settings
Configure in Settings → Modbus tab:
- Relay Port: `/dev/ttySC0` (default)
- Hub Port: `/dev/ttySC1` (default)
- Baud Rate: 9600 (default)

### Sensor Hub Addressing
Use DIP switches on each hub to set Modbus address:

| SW1 | SW2 | SW3 | SW4 | Address |
|-----|-----|-----|-----|---------|
| ON  | OFF | OFF | OFF | 1 |
| OFF | ON  | OFF | OFF | 2 |
| ON  | ON  | OFF | OFF | 3 |
| OFF | OFF | ON  | OFF | 4 |
| ... | ... | ... | ... | ... |
| ON  | ON  | ON  | ON  | 15 |

---

## Project Structure

```
sprigrig/
├── lib/
│   ├── app.dart                 # App entry point
│   ├── models/                  # Data models
│   │   ├── zone.dart
│   │   ├── sensor.dart
│   │   ├── grow.dart
│   │   └── ...
│   ├── screens/                 # UI screens
│   │   ├── setup/               # Setup wizard
│   │   ├── dashboard/           # Zone dashboards
│   │   ├── home/                # Main navigation
│   │   └── settings/            # Configuration
│   ├── services/                # Business logic
│   │   ├── database_helper.dart
│   │   ├── hardware_service.dart
│   │   ├── modbus_service.dart
│   │   ├── timer_manager.dart
│   │   ├── astral_service.dart
│   │   └── camera_service.dart
│   └── widgets/                 # Reusable components
├── firmware/                    # STM32 hub firmware
│   └── Core/
│       ├── Inc/
│       └── Src/
├── python/                      # Python hardware scripts
│   └── hardware/
└── assets/                      # Images, fonts
```

---

## Hardware Design

### Sensor Hub PCB
- **MCU**: STM32G431CBT6
- **RS485 Transceiver**: MAX485E
- **Power**: 24V input → 12V → 3.3V regulation
- **Analog Front-End**: MCP6002 op-amps for signal conditioning
- **Connectors**: JST-XH for sensors, screw terminals for power/RS485

### Rev 2 Additions (Planned)
- USB-C debug port (CH340C)
- Reverse polarity protection (P-FET)
- Additional I2C expansion

---

## Roadmap

- [x] Zone-based architecture
- [x] Modbus relay control
- [x] Sensor hub hardware design
- [x] Recipe system with phases
- [x] Camera timelapse
- [x] Astral scheduling
- [ ] Fertigation automation
- [ ] Guardian AI integration
- [ ] Analytics dashboard
- [ ] Mobile app
- [ ] Cloud sync (optional)

---

## Contributing

Contributions welcome! Please read the contributing guidelines before submitting PRs.

---

## License

[License TBD]

---

## Acknowledgments

Built with passion for growing and technology. SprigRig represents a philosophy where technology partners with nature — not to dominate, but to nurture.

*"Gaia doesn't just watch anymore. She speaks."* 🌍
