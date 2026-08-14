<!--
  Orpheus User Manual — editable source.

  Edit this file, then run:  node docs/build.mjs manual
  That regenerates html/orpheus-manual.html (website page) and
  html/downloads/Orpheus-User-Manual.pdf (download). Commit all three.

  Conventions:
    ##   numbered section  (starts a new page in the PDF)
    ###  subsection
    ::: note  / ::: warn   callout boxes; first line is a bold LABEL

  Recording detail belongs in the Orpheus Pro Recording & Field Guide,
  not here. Keep section 6's recording part to an outline plus a pointer.
-->

## 1. Introduction

Welcome to the Orpheus Audio Player System — a fully assembled, ruggedized
solution for scheduled wildlife audio playback. Orpheus was originally
developed for ornithological research in demanding field environments, with all
hardware and software components engineered to function together seamlessly.
This manual provides guidance on operating and maintaining the device, along
with important information on lawful and ethical usage.

Orpheus is available in **Basic** and **Pro** versions. Sections marked
*(Pro only)* apply to Pro units.

::: note
**YOUR DOCUMENTATION**
The latest version of this manual, the Quick Start Guide, and — for Pro
owners — the Recording & Field Guide are always available in your customer
portal at **gaiaforge.tech/portal**, and at **gaiaforge.tech/orpheus**.
:::

## 2. Legal and Ethical Use

Orpheus is intended for research, educational, and lawful observation of
wildlife. Some jurisdictions regulate or prohibit the use of recorded calls to
attract, capture, or hunt animals. Users are solely responsible for ensuring
they comply with all applicable local, regional, and national laws regarding
wildlife protection, conservation, and hunting. This may include:

- Obtaining any necessary permits or licenses
- Adhering to restrictions on using audio lures for disturbing or capturing
  protected species
- Following ethical guidelines to avoid undue stress on wildlife

::: warn
**DISCLAIMER**
GaiaForge Technology assumes no liability for damages, fines, or legal
consequences resulting from misuse or unauthorized use of this device. By
operating the Orpheus Audio Player, you acknowledge responsibility for its
deployment and agree to abide by relevant laws.
:::

## 3. System Overview

Orpheus is delivered as a fully integrated unit featuring all core hardware and
software:

- Onboard processor with dedicated power management controller
- Battery-backed real-time clock (RTC) for accurate timekeeping during sleep
- Bluetooth Low Energy (BLE) for companion app connectivity
- Class D audio amplifier and speaker system
- High-capacity LiFePO4 battery with solar charging
- Touchscreen display for on-device control
- Weatherproof enclosure and connectors

The system supports the following capabilities:

| Capability | Description |
|---|---|
| Manual Playback | Direct user control over audio (Pro includes PA mode and Bluetooth speaker connection) |
| Interval Playback | Time-based scheduling |
| Astral Playback | Scheduling based on local sunrise/sunset |
| Seasonal Playback | Timing aligned to natural or custom seasons |
| Recording Mode | Capturing environmental audio for analysis *(Pro only)* |
| Analytics | Tracking and exporting playback data *(Pro only)* |
| Companion App | Remote control and monitoring via Bluetooth from your phone |
| Power Management | Optimizing battery usage via smart sleep/wake cycles |

## 4. Getting Started

### Unboxing and Setup

1. **Inspect the Device.** Remove Orpheus from the packaging and ensure all
   components (enclosure, speaker connections, connectors) are intact.
2. **Power Connection.** Connect the provided LiFePO4 battery using the XT60
   connector. Connect the MC4 solar connectors observing polarity.
3. **First Boot.** Press the power switch. The touchscreen will display the
   Orpheus interface after approximately 60 seconds.
4. **Location Setup.** Go to **Settings → Astral Setup** and enter your GPS
   coordinates (latitude, longitude) and timezone for correct sunrise/sunset
   calculations.
5. **Speaker Check.** Connect speakers to the waterproof connectors. Confirm
   audio output by playing the test tone in Manual mode.
6. **Set Time (if needed).** The device includes a battery-backed real-time
   clock (RTC) that maintains accurate time. If the time appears incorrect, set
   it manually under **Settings → Time & Date**.

::: note
**NO ASSEMBLY REQUIRED**
Orpheus comes preloaded with all necessary software. No image flashing or
assembly is required.
:::

## 5. Main Interface

- **Mode Selector** — touchscreen menu offering Manual, Interval, Astral,
  Seasonal, or Recording modes.
- **Toolbar** — quick access to System Settings, File Management, Analytics,
  and Power options.
- **Status Area** — displays current date/time, active playback status, and
  battery level.
- **Main Panel** — changes based on the mode selected.

## 6. Playback Modes

### Manual Playback

- Select **Load Audio** to choose a file.
- Use **Play**, **Pause**, or **Stop** buttons.
- Track information appears in the Status Area.

### Interval Playback

- Select **Set Interval** to create a time-based schedule (daily, weekdays,
  weekends, or custom).
- Set start/end times and assign audio files or playlists.
- Orpheus automatically plays audio during those intervals.

### Astral Playback

- Under **Set Astral Interval**, choose Sunrise or Sunset as your baseline.
- Define how many hours before/after these times playback should occur.
- Orpheus recalculates sunrise/sunset daily using your GPS coordinates.

::: note
**DAWN CHORUS**
For dawn chorus studies, set playback to begin 30 minutes before sunrise.
Orpheus will automatically shift the schedule as sunrise times change with the
seasons.
:::

### Seasonal Playback

- Choose **Natural Seasons** (Spring, Summer, Fall, Winter) or enable **Custom
  Seasons** to define your own date ranges.
- Assign audio files, playlists, or interval schedules to each season.
- Particularly useful for matching migration patterns or breeding seasons.

### Recording Mode (Pro only)

Orpheus Pro records audio to a USB drive alongside its playback role. There are
four ways to record:

- **Manual** — *Record Now* starts and stops by hand. Best for tests and setup.
- **Scheduled** — set a start and end time and a repeat pattern; the unit wakes,
  records the window, and returns to sleep.
- **Astral** — schedule relative to sunrise or sunset, recalculated daily from
  your GPS location, so the recording tracks the dawn or dusk chorus through the
  season without reprogramming.
- **Threshold (triggered)** — record only when sound exceeds a level you set,
  saving storage and power on quiet sites.

Bit depth (16-bit or 24-bit), sample rate (44.1, 48 or 96 kHz) and mono or
stereo are chosen on the **Audio** tab before recording. Files are written as
WAV to the USB drive, each with an embedded GUANO metadata block recording when,
where and how it was made.

::: note
**FULL RECORDING GUIDANCE**
Input levels and Auto-Set Gain, microphone placement, wind protection, threshold
tuning, file naming, storage planning and the pre-deployment checklist are
covered in the **Orpheus Pro Recording & Field Guide**, available in your
customer portal. Read it before your first recording deployment — level is the
one setting that cannot be fixed afterwards.
:::

## 7. Companion App

Orpheus includes a companion mobile app for remote control and monitoring via
Bluetooth Low Energy (BLE).

### Getting the App

- **Android** — download the APK from **gaiaforge.tech/orpheus** and install it
  on your device. You may need to enable "Install from unknown sources" in your
  phone's settings.
- **iOS** — available on the App Store (coming soon).

### Connecting to Your Device

1. Open the Orpheus app on your phone.
2. The app will scan for nearby Orpheus devices via Bluetooth.
3. Tap your device in the list (e.g. "Orpheus-91BD").
4. The app will connect via BLE, wake the device if sleeping, and activate the
   WiFi hotspot.
5. Join the Orpheus WiFi hotspot on your phone (e.g. `Orpheus-XXXX`, where XXXX
   is your device ID). The hotspot is an open network with no password.
6. The app will automatically connect to the full dashboard over WiFi.

### App Features

- View real-time battery voltage, charge state, and solar input
- Configure playback modes and schedules remotely
- Set device time, timezone, and location
- Send commands: sleep, wake, restart
- View environmental sensor data *(Pro)*
- Access diagnostics and system status

::: note
**HOTSPOT TIMEOUT**
The WiFi hotspot automatically turns off after 5 minutes of inactivity to save
power. Use the app to reactivate it when needed.
:::

## 8. System Settings

### Audio File Management

- Access via the "Audio" icon or from the main menu.
- Review, delete, and manage files stored on Orpheus.
- **USB Import** — connect a USB flash drive to add audio tracks.
- **USB Export** — copy audio tracks from the device to a USB flash drive.
- Supported formats: WAV and MP3.

### Astral Setup

- Enter or confirm GPS coordinates and local timezone.
- Define a device nickname (e.g. "Zone 1") for easy identification.
- The device uses these coordinates to calculate accurate sunrise and sunset
  times for your location.

### Time and Date

- Orpheus includes a battery-backed real-time clock that maintains accurate time
  even when the device is powered off or in deep sleep.
- The RTC battery lasts 3–6 years under normal use.
- Time can be set manually through the touchscreen or synced via the companion
  app.
- The system clock automatically syncs from the RTC on every boot and
  periodically during operation.

### GPIO Settings

- The GPIO controls the amplifier power relay. This can be toggled on/off in
  settings.
- Only disable if you are using an external amplifier.

### Analytics (Pro only)

- **Enable Logging** — store detailed data on playback events with timestamps
  and location.
- **Filter Logs** — browse logs by date.
- **Export** — save logs to USB, or double-tap for a preview on the touchscreen.

## 9. Power Management

Orpheus uses a sophisticated power management system with a dedicated low-power
controller and battery-backed real-time clock.

### How It Works

1. When playback is complete or during scheduled downtime, the system calculates
   the next required wake time and stores it in the power controller.
2. The main processor shuts down completely, and the power controller cuts power
   to it.
3. The power controller enters a low-power state, monitoring the clock for the
   next scheduled wake time.
4. When the wake time arrives, the power controller restores power and the
   system boots and resumes operation.

### Deep Sleep Mode

- Enable or disable deep sleep under **Settings → Power Management**.
- When enabled, the device automatically sleeps between scheduled events,
  drastically reducing power consumption.
- The manual wake button on the enclosure can bring the system online at any
  time.
- The companion app can also wake the device remotely via BLE.

### Solar Charging

- Connect solar panels via the MC4 connectors, observing correct polarity.
- The Pro version includes real-time solar monitoring showing voltage, current,
  and power flow.
- For optimal results, position the solar panel facing south (Northern
  Hemisphere) or north (Southern Hemisphere) at an angle matching your latitude.

::: note
**BATTERY LIFE**
Longer intervals between playback events yield greater battery savings. A
typical deployment with 2–3 hours of daily playback and adequate solar input can
run indefinitely.
:::

## 10. Field Deployment Tips

- **Initial Monitoring** — for the first few days after deployment, check
  battery levels and playback logs to confirm the system is operating as
  expected.
- **Weather Protection** — Orpheus ships in a weather-sealed enclosure. Ensure
  all connectors remain properly seated and sealed.
- **Speaker Placement** — position speakers to project sound toward the target
  area. Avoid placing speakers directly on the ground where moisture can
  collect.
- **WiFi Hotspot** — each Orpheus unit broadcasts its own WiFi hotspot (SSID
  format `Orpheus-XXXX`). Connect to this network from your phone to access the
  companion app dashboard. The hotspot has a range of approximately 30 metres
  and automatically deactivates after 5 minutes to conserve power.
- **Data Collection** — regularly export logs and recordings via USB for
  analysis.
- **Time Accuracy** — the onboard RTC maintains time to within a few seconds per
  month. If the device has been in storage for an extended period, verify the
  time after the first boot.

## 11. Troubleshooting

### System Won't Power On

- Check the battery connection and verify the power switch is on.
- Press the manual wake button on the enclosure.
- If the system still won't start, press the master power switch to perform a
  full reset.
- Contact support if none of these methods work.

### No Audio Output

- Confirm GPIO amplifier control is enabled under **Settings → GPIO Settings**.
- Verify volume levels are not set to zero.
- Ensure Mute is not activated in the current playback mode.
- Check speaker connections at the waterproof connectors.

### Scheduled Playback Not Triggering

- Verify the system time is correct under **Settings → Time & Date**.
- Check that GPS coordinates and timezone are set correctly.
- Review the interval or astral/seasonal configuration for errors.
- Ensure the assigned audio file is not corrupted (WAV or MP3 format only).

### Time Appears Incorrect After Reboot

- The system automatically syncs from the RTC on boot. If time is wrong, the RTC
  battery may need replacement.
- Set the time manually via the touchscreen or companion app, which will also
  update the RTC.
- Check the RTC status indicator under **Settings → Time & Date**.

### Companion App Won't Connect

- Ensure Bluetooth is enabled on your phone and the phone is within range
  (approximately 10 metres).
- On Android, grant "Nearby devices" and "Location" permissions to the Orpheus
  app.
- After connecting via BLE, join the Orpheus WiFi hotspot on your phone.
- If the dashboard doesn't load, wait 15–20 seconds — the WiFi connection can
  take a moment to establish.

### Recording Issues (Pro only)

- Confirm sufficient storage space on the USB device.
- Check microphone or external audio input connections.
- Ensure the USB device is properly formatted (FAT32 or exFAT recommended).
- If recordings are empty, a threshold may be set too high for the site — see
  the Recording & Field Guide.

## 12. Maintenance

### Software Updates

Software updates are deployed by your GaiaForge representative using the Orpheus
Updater tool. During a service visit or when connected to your device's WiFi
hotspot, the representative will transfer updated files and rebuild the
application. No user action is typically required.

If you need to perform an update yourself, contact
[contact@gaiaforge.tech](mailto:contact@gaiaforge.tech) for instructions.

### File Management

- Regularly remove unused audio or log files to free storage space.
- Back up important configurations and recordings to USB.

### Hardware Maintenance

- Periodically inspect connectors and seals for wear or moisture ingress.
- Clean solar panels to maintain charging efficiency.
- The internal clock battery should be replaced every 3–6 years if timekeeping
  becomes unreliable. Contact GaiaForge for service.

## 13. Support

- **Email** — [contact@gaiaforge.tech](mailto:contact@gaiaforge.tech)
- **Portal** — sign in at **gaiaforge.tech/portal** for your documentation,
  device registration and downloads.
- **Downloads** — visit **gaiaforge.tech/orpheus** for the latest app and
  documentation.
- For questions on legal usage, contact local authorities or your institution's
  compliance office.

### Related documentation

| Document | For |
|---|---|
| Quick Start Guide | First-time setup, from unboxing to a running schedule |
| Orpheus Pro Recording & Field Guide | Recording quality, levels, mic placement and triggering *(Pro)* |
| Solar Panel Alignment Guide | Positioning panels for your site and latitude |

::: warn
**LEGAL COMPLIANCE**
Use of recorded calls for wildlife attraction, capture, or hunting may be
restricted or prohibited in your jurisdiction. Obtain all necessary permits. You
are responsible for complying with environmental, conservation, and hunting
regulations. High-volume or constant playback may disturb wildlife — use
responsibly to minimise ecological impact.
:::

::: contact
**GaiaForge** · Rheinland-Pfalz, Germany · contact@gaiaforge.tech ·
+49 171 2002495 · gaiaforge.tech

Orpheus is a trademark of GaiaForge. © 2026 GaiaForge Technology. All rights
reserved.
:::
