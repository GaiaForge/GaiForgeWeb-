# Orpheus Audio Player User Manual

*Unified Manual for Orpheus Basic and Orpheus Pro*

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [User Interface Overview](#user-interface-overview)
4. [Playback Modes](#playback-modes)
5. [Pro Features](#pro-features)
6. [Companion Mobile App](#companion-mobile-app)
7. [System Settings](#system-settings)
8. [Power Management](#power-management)
9. [Field Deployment](#field-deployment)
10. [Troubleshooting](#troubleshooting)
11. [Maintenance](#maintenance)
12. [Technical Specifications](#technical-specifications)
13. [Legal Compliance & Support](#legal-compliance--support)

---

## Introduction

### Welcome to Orpheus

Orpheus is an advanced audio broadcasting platform designed for wildlife research, conservation efforts, and environmental monitoring. Built for deployment in remote locations, Orpheus combines sophisticated audio playback capabilities with solar-powered operation and intelligent power management.

Whether you're conducting bioacoustic research, managing wildlife populations, or studying animal behavior, Orpheus provides the tools you need for reliable, long-term field deployment.

### Basic vs Pro Feature Comparison

| Feature | Orpheus Basic | Orpheus Pro |
|---------|---------------|-------------|
| Manual Playback | Yes | Yes |
| Interval Playback | Yes | Yes |
| Astral Playback (Sunrise/Sunset) | Yes | Yes |
| Seasonal Playback | Yes | Yes |
| Solar Power Integration | Yes | Yes |
| Deep Sleep Power Management | Yes | Yes |
| Audio Recording | - | **[PRO]** |
| Environmental Monitoring | - | **[PRO]** |
| Solar Monitoring Dashboard | - | **[PRO]** |
| Advanced Analytics & Export | - | **[PRO]** |
| Playback logging | - | **[PRO]** |

### Legal and Ethical Use Notice

> **Important:** Users are responsible for ensuring compliance with all local, state, and federal regulations regarding wildlife interaction and audio broadcasting in natural habitats. Some jurisdictions may have specific rules about broadcasting audio to wildlife. Always obtain necessary permits and follow ethical guidelines for wildlife research.

---

## Getting Started

### Unboxing Checklist

Your Orpheus unit should include:

- [ ] Orpheus main unit with weatherproof enclosure
- [ ] LiFePO4 battery (pre-installed or separate)
- [ ] MC4 solar panel connectors
- [ ] External speaker (or speaker connection cables)
- [ ] Quick start guide
- [ ] USB drive with sample audio files

![Unboxing contents](images/placeholder-unboxing.png)
*Caption: Orpheus unit contents and accessories*

### Power Connection

#### Battery Installation

Orpheus uses a LiFePO4 (Lithium Iron Phosphate) battery system operating at 12.8V nominal voltage. This chemistry was chosen for its:

- Excellent cycle life (2000+ cycles)
- Stable discharge characteristics
- Safe operation in varying temperatures
- No memory effect

If your battery is not pre-installed:

1. Open the enclosure using the provided key
2. Connect the battery via the yellow battery connector
3. Place the battery in the lower section of the enclosure
4. Close and seal the enclosure using the key

#### Solar Panel Connection

1. Locate the MC4 connectors on the enclosure exterior
2. Connect your solar panel's MC4 cables (positive to positive, negative to negative)
3. Ensure connections are tight and weatherproof
4. Position panel for optimal sun exposure (see [Solar Panel Guide](solar-panel-guide.md))

![Solar connection diagram](images/placeholder-solar-connection.png)
*Caption: MC4 solar panel connection points*

### Initial Setup

#### First Boot

1. Press the power button to turn on the unit, startup can take up to 2 minutes
2. Wait for the system to initialize (approximately 6 seconds)

   > **Note:** During startup, the system performs initialization tasks including loading the database, syncing power management data, and updating battery levels to the interface. This brief non-responsive period is normal behavior.

3. The battery level will appear once initialization is complete

#### Location Configuration

For accurate sunrise/sunset calculations:

1. Navigate to **Settings > Astral Setup**
2. Enter your GPS coordinates (latitude and longitude) either manually or pushed to the unit automatically via the OrpheusRemote app.
3. Set your timezone
4. Optionally add a nickname for this deployment  (Nickname for pro units is logged so the user can differentiate different units in the field when doing analysis on data)

### Speaker Connection

1. Connect your external speaker to waterproof audio connectors
2. Navigate to **Manual Playback, load a test file**
3. Play a test tone to verify speaker operation
4. Adjust volume as needed (volume is persistent meaning it will persist through restarts)

![Speaker connection](images/placeholder-speaker.png)
*Caption: Speaker connection terminals on the enclosure*

---

## User Interface Overview

### Main Interface Layout

The Orpheus interface is designed for clarity and ease of use, even in bright outdoor conditions.

![Main interface](images/placeholder-main-interface.png)
*Caption: Orpheus main interface layout*

### Key Interface Elements

#### Mode Selector

Located at the top of the screen, the mode selector bar allows you to switch between:

- **Manual** - Direct playback control
- **Interval** - Time-based scheduled playback
- **Astral** - Sunrise/sunset-based scheduling
- **Seasonal** - Season-aware playlist management
- **Record** **[PRO]** - Audio recording mode

#### Toolbar

The toolbar provides quick access to:

- Volume control
- System settings
- Power management
- Status information
- Solar output information
- Environmental sensor readings
- System information screen


#### Status Area

Displays current system status including:

- Battery level
- Solar charging status (when connected)
- Current time
- Active mode indicator
- **[PRO]** Environmental sensor readings

### Navigation

- **Touch** - Tap buttons and controls directly
- **Scroll** - Swipe to scroll through lists
- **Back** - Use the back or close buttons to return to previous screens

---

## Playback Modes

### Manual Playback

Manual mode gives you direct control over audio playback. It can also be triggered remotely via the app.

![Manual playback screen](images/placeholder-manual-playback.png)
*Caption: Manual playback interface*

#### Controls

- **Load** - Select an audio file from local storage
- **Play** - Start playback
- **Pause** - Pause current playback
- **Stop** - Stop playback completely
- **Volume** - Adjust output level

#### Supported Formats

- WAV (recommended for highest quality)
- MP3
- OGG
- FLAC

### Interval Playback

Schedule audio playback at specific times throughout the day.

![Interval playback screen](images/placeholder-interval-playback.png)
*Caption: Interval playback scheduling interface*

#### Schedule Types

- **Daily** - Same schedule every day
- **Weekdays** - Monday through Friday only
- **Weekends** - Saturday and Sunday only
- **Custom** - Define specific days

#### Creating an Interval Schedule

1. Select **Interval** mode
2. Tap **Add Schedule**
3. Set start time
4. Set end time 
5. Select audio file(s)
6. If multiple audio files are selected they will loop sequentially
7. Save schedule

### Astral Playback

Synchronize playback with natural light cycles using sunrise and sunset times.

![Astral playback screen](images/placeholder-astral-playback.png)
*Caption: Astral playback configuration*

#### Timing Options

- **At Sunrise** - Begin playback at sunrise
- **Before Sunrise** - Start a specified time before sunrise
- **After Sunrise** - Start a specified time after sunrise
- **At Sunset** - Begin playback at sunset
- **Before Sunset** - Start a specified time before sunset
- **After Sunset** - Start a specified time after sunset

#### Dawn/Dusk Chorus

Create schedules that span the dawn or dusk period:

1. Set start time relative to sunrise/sunset
2. Set duration or end time
3. Orpheus automatically adjusts daily as sunrise/sunset times change

> **Tip:** Ensure your GPS coordinates and timezone are correctly configured in Settings for accurate calculations.

### Seasonal Playback

Manage different playlists for different seasons, reflecting natural animal behavior patterns.

![Seasonal playback screen](images/placeholder-seasonal-playback.png)
*Caption: Seasonal playback management*

#### Season Configuration

**Natural Seasons** (automatic based on hemisphere):
- Spring
- Summer
- Autumn
- Winter

**Custom Seasons:**
Define your own seasonal periods based on local wildlife activity patterns.

#### Assigning Playlists

1. Select a season
2. Choose playlist(s) for that season
3. Set playback schedule within the season
4. Repeat for each season
5. Device will auto switch to the new season and playlist when appropriate

---

## Pro Features

> **Note:** Features in this section are available on Orpheus Pro units only.

### Recording Mode [PRO]

Capture high-quality audio recordings for research and analysis directly to a USB drive.


![Recording interface](images/placeholder-recording.png)
*Caption: Pro recording interface*

#### Recording Quality Settings

| Setting | Sample Rate | Bit Depth | Use Case |
|---------|-------------|-----------|----------|
| Standard | 44.1 kHz | 16-bit | General purpose |
| High | 48 kHz | 24-bit | Professional research |
| Maximum | 96 kHz | 32-bit | Detailed acoustic analysis |

#### Recording Modes

- **Manual Recording** - Start and stop manually
- **Scheduled Recording** - Set specific times
- **Triggered Recording** - Record based on audio detection thresholds

#### Storage Management

- Monitor available storage space
- Set automatic file rotation
- Configure filename patterns with timestamps

### Environmental Monitoring [PRO]

Track environmental conditions alongside your audio operations.

![Environmental dashboard](images/placeholder-environmental.png)
*Caption: Environmental monitoring dashboard*

#### Sensors

- **Temperature** - Ambient temperature monitoring
- **Humidity** - Relative humidity percentage
- **Barometric Pressure** - Atmospheric pressure readings

#### Data Logging

- Automatic logging at configurable intervals
- CSV export for analysis
- Real-time display on dashboard

### Solar Monitoring [PRO]

Monitor your solar power system performance in real-time.

![Solar monitoring screen](images/placeholder-solar-monitoring.png)
*Caption: Solar monitoring dashboard*

#### Metrics Displayed

- Current solar input (watts)
- Battery voltage
- Battery charge percentage
- Charging status
- Historical power generation charts

#### Power Optimization

Use solar data to:
- Identify optimal deployment locations
- Adjust schedules for power availability
- Plan maintenance visits

### Advanced Analytics [PRO]

Comprehensive data logging and export capabilities.

![Analytics screen](images/placeholder-analytics.png)
*Caption: Advanced analytics interface*

#### Playback Logging

- Track all playback events
- Duration and timing statistics
- File usage reports

#### Data Export

- **CSV Export** - Download data as spreadsheets
- **InfluxDB Integration** - Stream data to InfluxDB for advanced visualization
- **Custom Reports** - Generate summary reports

### Bluetooth Control 

Control your Orpheus unit remotely via Bluetooth.

![Bluetooth settings](images/placeholder-bluetooth.png)
*Caption: Bluetooth pairing interface*

#### Pairing Process



1. Ensure Orpheus unit(s) are connected to a battery
2. Start app, it will begin searching for orpheus devics in range automatically
3. Accept location request if prompted (used to push location data to the device only) 
This is not uses to track your location.


#### Remote Capabilities

- Start/stop playback
- Adjust volume
- Schedule playback events in each mode
- View status information
- Access settings 

---

## Companion Mobile App

The Orpheus Companion App extends your control capabilities with a mobile interface.

### App Overview

![App main screen](images/placeholder-app-main.png)
*Caption: Orpheus Companion App main screen*

Available for:
- Android (Google Play Store)
- iOS (Apple App Store)

### Bluetooth Pairing Process

1. Install the Orpheus Companion App
2. Enable Bluetooth on your mobile device3. 
3. Select your Orpheus unit from the list
4. Open the app and tap **Connect Device**
6. Connection established

### Remote Control Features

#### Basic Controls (All Units)

- Play/Pause/Stop
- Volume adjustment
- Mode selection
- Schedule viewing and editing

#### Configuration via App

- Edit playback schedules
- Manage audio files
- Adjust settings
- View system status

### Pro App Features [PRO]

Additional capabilities for Orpheus Pro users:

- **Solar Monitoring** - View real-time solar data on your phone
- **Environmental Data** - Check temperature, humidity, and pressure remotely
- **Recording Control** - Start/stop recordings remotely
- **Analytics Dashboard** - View playback statistics and charts
- **Data Export** - Export data directly from the app

![Pro app features](images/placeholder-app-pro.png)
*Caption: Pro-exclusive app features*

---

## System Settings

### Astral Setup

Configure location data for accurate sunrise/sunset calculations.

- **Latitude** - GPS latitude coordinate
- **Longitude** - GPS longitude coordinate
- **Timezone** - Local timezone setting
- **Nickname** - Friendly name for this location

### Time & Date Configuration

- **Automatic** - Sync time via phone GPS (in settings menu in app)
- **Manual** - Set time and date manually

### GPIO Settings


### Audio File Management

#### USB Import/Export

1. Insert USB drive into the USB port
2. Navigate to **Settings > File Management**
3. Select **Import** or **Export**
4. Choose files to transfer
5. Wait for transfer to complete

#### File Organization

- Organize files into folders by project or season
- Use descriptive filenames
- Supported formats: WAV, MP3, OGG, FLAC

### Analytics Configuration

**[PRO]** Configure data logging and export settings:

- Logging interval
- Data retention period
- Export format preferences
- InfluxDB connection settings

---

## Power Management

Understanding Orpheus power management is essential for successful field deployment.

### How Sleep/Wake Works

Orpheus uses an intelligent two-processor architecture for power management:

1. **Main Processor** - Runs the full Orpheus application
2. **Power Manager MCU** - Low-power microcontroller that manages sleep/wake cycles

#### The Sleep/Wake Cycle

1. When entering deep sleep, Orpheus calculates the next scheduled wake time
2. The power manager MCU stores this wake time
3. The main processor shuts down completely (near-zero power consumption)
4. The power manager MCU monitors time using minimal power
5. At the scheduled wake time, the MCU powers on the main processor
6. The system boots and resumes normal operation

This approach allows Orpheus to achieve extremely low sleep power consumption (~50mA) while maintaining precise wake timing.

### Sleep Countdown Dialog

When entering sleep mode (if next scheduled event is >10 minutes away), a 60-second countdown dialog appears:

![Sleep countdown](images/placeholder-sleep-countdown.png)
*Caption: Sleep countdown dialog*

- **Countdown Timer** - Shows seconds remaining before sleep
- **Cancel Button** - Stops the current sleep sequence

#### Understanding "Snooze" Behavior

> **Important:** Pressing Cancel during the countdown does NOT permanently disable sleep. It functions as a "snooze" - the system will delay sleep for 10 minutes and attempt to enter sleep mode again later.

If you need the system to stay awake indefinitely, use the deep sleep disable option in Settings.

### Disabling Deep Sleep

For applications requiring 24/7 operation:

1. Navigate to **Settings > Power Management**
2. Toggle **Enable Deep Sleep** to OFF
3. Confirm your choice

> **Warning:** Disabling deep sleep significantly increases power consumption. Ensure you have adequate solar input or plan for more frequent battery maintenance.

### Self-Healing Recovery

Orpheus includes a self-healing recovery feature for unexpected power loss situations:

- If power is lost unexpectedly (battery depleted, disconnection, etc.)
- The power manager MCU preserves the last known wake schedule
- When power is restored, the system automatically recovers by waking the system and looking at future scheduled events. If the event is >10 minutes in the future the system stores the next wake time and puts the main unit back to sleep until the next playback event.
- Normal operation resumes without user intervention

This ensures your research continues even after unexpected power events, or multiple days of cloudy weather.

### Wake Time Verification

As a safety measure, Orpheus verifies a valid wake time exists before allowing sleep:

- The system will not enter deep sleep without a scheduled wake time
- This prevents the unit from sleeping indefinitely
- You will be prompted to set a schedule if none exists

### Battery Threshold Protection

Orpheus implements a battery threshold check before restart:

> **Requirement:** Battery level must be above 25% before the system will allow a restart/wake cycle.

This ensures there is adequate power buffer to:
- Complete the boot sequence
- Run scheduled operations
- Handle unexpected power demands

If battery level is below 25%, the system will wait for additional charging before restarting.

### Startup Initialization Period

When Orpheus boots up, expect a start period of approximately 2 minutes:

During this time, the system:y
1. Boots the operating system
2. Loads the database
3. Syncs buffered data from the power manager
4. Updates battery level to the interface
5. Initializes all subsystems

> **Note:** The interface may appear unresponsive during this initialization. This is normal behavior and not a malfunction. Wait for initialization (battery indicator populates) to complete before interacting with the interface.

### Battery Optimization Tips

Maximize your deployment duration:

1. **Use appropriate schedules** - Only play audio when needed
2. **Enable deep sleep** - Let the system sleep between activities
3. **Optimize solar placement** - Maximize charging during daylight
4. **Monitor battery health** - Check voltage and capacity periodically
5. **Reduce volume when possible** - Lower volume uses less power

### Solar Monitoring Integration [PRO]

Pro users can leverage solar monitoring for power optimization:

- View real-time charging rates
- Identify low-production periods
- Adjust schedules based on power availability
- Set alerts for low battery conditions

---

## Field Deployment

### Site Selection Tips

Choose deployment locations carefully:

- **Solar Exposure** - Ensure adequate sunlight for charging
- **Weather Protection** - While IP65 rated, additional shelter extends life
- **Audio Coverage** - Position speakers for optimal sound distribution
- **Security** - Consider visibility and accessibility
- **Wildlife Activity** - Place near areas of target species activity

### Weather Protection

Orpheus carries an IP65 weather resistance rating:

- **IP6** - Dust tight (no ingress of dust)
- **5** - Protected against water jets from any direction

This means Orpheus can handle:
- Rain and storms
- Dusty environments
- Humidity and condensation

> **Tip:** While IP65 provides excellent protection, mounting under partial cover (tree canopy, shelter) extends equipment life.

### Battery Life Optimization

Expected operation times (approximate):

| Configuration | Active Hours | Sleep Hours | Total Cycle |
|---------------|--------------|-------------|-------------|
| Heavy Use | 4 hours | 20 hours | ~7 days* |
| Moderate Use | 2 hours | 22 hours | ~14 days* |
| Light Use | 1 hour | 23 hours | ~21 days* |

*With adequate solar charging

### Data Collection Best Practices

1. **Regular Downloads** - Don't let storage fill completely
2. **Backup Schedules** - Export your schedules periodically
3. **Document Deployments** - Record GPS, settings, and observations
4. **Check Sensors** - Verify sensor readings are reasonable

### Remote Access Options

#### WiFi Access

When within WiFi range:
- Connect to the unit's access point
- Access web interface for configuration
- Download data without physical access

#### Bluetooth Access [PRO]

- Range: approximately 10 meters (30 feet)
- Use Companion App for control
- Quick status checks without opening enclosure

---

## Troubleshooting

### System Won't Power On

1. **Check battery connection** - Ensure terminals are secure
2. **Check battery level** - May need charging before startup
3. **Check for damage** - Inspect for physical damage
4. **Try hard reset** - Hold power button for 10 seconds

### No Audio Output

1. **Check speaker connection** - Verify terminals are secure
2. **Check volume level** - Ensure volume is not at zero or muted
3. **Test with different file** - Rule out file corruption

### Scheduled Playback Not Triggering

1. **Verify schedule is active** - Check schedule is enabled
2. **Check time settings** - Ensure time and timezone are correct
3. **Check astral settings** - For astral mode, verify GPS coordinates
4. **Check audio files** - Ensure scheduled files exist
5. **Review power settings** - Ensure unit wakes in time for schedule

### Recording Issues [PRO]

1. **Check storage space** - Ensure adequate free space
2. **Check microphone connection** - Verify input is connected
3. **Test input levels** - Check gain settings
4. **Verify file permissions** - Ensure write access to storage

### Connection Problems

#### WiFi Issues
1. Check WiFi is enabled
2. Verify correct network credentials
3. Ensure unit is within range
4. Restart WiFi interface

#### Bluetooth Issues [PRO]
1. Ensure Bluetooth is enabled on both devices
2. Unpair and re-pair if necessary
3. Check for interference from other devices
4. Restart Bluetooth service

### Sensor Issues [PRO]

1. **Erratic readings** - May indicate sensor damage
2. **No readings** - Check sensor connections
3. **Out of range values** - Sensor may need replacement
4. **Slow updates** - Normal during high system load

---

## Maintenance

### Software Updates

Orpheus supports over-the-air (OTA) updates:

1. Connect to WiFi network with internet access
2. Navigate to **Settings > System > Updates**
3. Check for available updates
4. Download and install when prompted
5. System will restart after update

### File Management

Regular file maintenance ensures smooth operation:

- Delete old, unused audio files
- Archive recordings to external storage
- Organize files into logical folders
- Clear temporary files periodically

### Battery Care

LiFePO4 batteries require minimal maintenance:

- **Storage** - Store at 50% charge for long periods
- **Temperature** - Avoid extreme temperatures when possible
- **Cycling** - Regular use is beneficial for battery health
- **Monitoring** - Check voltage periodically for degradation

### Enclosure Maintenance

- **Seals** - Inspect and replace worn seals annually
- **Connectors** - Clean MC4 connectors periodically
- **Ventilation** - Ensure vents are not blocked
- **Mounting** - Check mounting hardware for looseness

---

## Technical Specifications

### Hardware Overview

| Component | Description |
|-----------|-------------|
| Main Processor | Single-board computer running Linux |
| Power Manager | Low-power MCU for sleep/wake management |
| Display | Touchscreen interface |
| Audio Output | High-quality DAC with amplifier |
| Storage | Internal 16Gb industrial SD card + USB expansion |

### Power Specifications

| Parameter | Value |
|-----------|-------|
| Battery Type | LiFePO4 (Lithium Iron Phosphate) |
| Nominal Voltage | 12.8V (4S configuration) |
| Operating Current | ~280mA typical |
| Sleep Current | ~50mA |
| Solar Input | MC4 connectors, 18V nominal |

### Audio System

| Parameter | Value |
|-----------|-------|
| DAC Resolution | 24-bit |
| Amplifier Type | Class-D |
| Output Power | Dependent on connected amplifier |
| Supported Formats | WAV, MP3, OGG, FLAC |

### Environmental Ratings

| Parameter | Rating |
|-----------|--------|
| Enclosure | IP65 |
| Operating Temperature | -20°C to 50°C |
| Storage Temperature | -40°C to 60°C |
| Humidity | 0-95% non-condensing |

### Connectivity

| Interface | Specification |
|-----------|---------------|
| WiFi | 802.11 b/g/n |
| Bluetooth | Bluetooth LE (Pro only) |
| USB | USB 2.0 Host |
| GPIO | Configurable digital I/O |

---

## Legal Compliance & Support

### Compliance Notice

Orpheus is designed for legitimate wildlife research, conservation, and educational purposes. Users must:

- Obtain all necessary permits for wildlife research
- Follow local regulations regarding audio broadcasting
- Respect protected areas and species restrictions
- Use equipment ethically and responsibly

### Disclaimer

GaiaForge provides Orpheus as a tool for wildlife research and conservation. We are not responsible for:

- Misuse of equipment
- Violation of local laws or regulations
- Impact on wildlife from improper use
- Data loss or equipment damage from field conditions

Always consult with relevant authorities and wildlife experts before deploying audio equipment in natural habitats.

### Contact & Support

**GaiaForge**

- **Website:** [https://gaiaforge.tech](https://gaiaforge.tech)
- **Email:** [contact@gaiaforge.tech](mailto:contact@gaiaforge.tech)
- **Phone:** +49 1712002495
- **Address:** Rheinland-Pfalz, Germany

**Documentation & Resources:**
- [Quick Start Guide](orpheus-quickstart.md)
- [Solar Panel Guide](solar-panel-guide.md)
- [Blog & Field Reports](https://blog.gaiaforge.tech)

---

*Orpheus is a trademark of GaiaForge. All rights reserved.*

*Document Version: 1.0*
*Last Updated: December 2025*
