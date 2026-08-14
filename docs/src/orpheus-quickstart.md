<!--
  Orpheus Quick Start Guide — editable source.

  Edit this file, then run:  node docs/build.mjs quickstart
  That regenerates html/orpheus-quickstart.html (website page) and
  html/downloads/Orpheus-Quick-Start-Guide.pdf (download). Commit all three.

  This guide is unified: it covers Basic and Pro. Pro recording setup gets a
  short section that points at the Recording & Field Guide — keep it that way,
  the detail lives in that guide.
-->

## 1. Initial Setup

Six steps from a boxed unit to a working device. Sections marked *(Pro only)*
apply to Orpheus Pro.

### 1. Connect Power

Plug in the LiFePO4 battery using the **XT60** connector. If you have a solar
panel, connect it via the **MC4** connectors, matching positive (+) to positive
and negative (−) to negative.

### 2. Power On

Flip the power switch. The touchscreen will display the Orpheus interface after
approximately **60 seconds**. If nothing happens, press the manual wake button
on the enclosure.

### 3. Connect Speakers

Attach speakers to the waterproof connectors on the enclosure. Test audio by
switching to **Manual** mode and playing the test tone.

### 4. Set Your Location

Go to **Settings → Astral Setup**. Enter your GPS coordinates (latitude and
longitude) and select your timezone. This is required for the sunrise/sunset
calculations used by Astral and Seasonal modes.

### 5. Verify Time

Check the clock displayed on screen. If it is incorrect, go to **Settings → Time
& Date** to set it manually. The built-in battery-backed clock maintains
accurate time from this point forward, even when the device is powered off.

### 6. Load Audio Files

Insert a USB flash drive containing your audio files (**WAV or MP3**). Open the
**Audio File Manager** from the toolbar and use USB Import to copy files to the
device.

## 2. Playback Modes

Orpheus has four playback modes. Choose one from the mode selector at the top of
the screen.

### Manual

Direct control for quick tests and on-demand use. Tap **Load Audio**, choose a
file, and use Play, Pause and Stop. Adjust volume from the toolbar.

### Interval

Playback during specific time windows.

1. Tap **Add Interval** to create a schedule entry.
2. Set the Start Time and End Time (e.g. 06:00 to 08:00).
3. Choose the days: Daily, Weekdays, Weekends, or specific days.
4. Tap **Select Audio** to assign one or more files. Multiple files play in
   sequence and loop for the duration of the interval.
5. Save. Tap any interval to edit it later.

*Example — a bird ringing station:* morning lure 05:30–07:00 daily; midday call
12:00–12:30 weekdays; evening session 17:00–18:30 daily.

### Astral

Playback relative to sunrise and sunset, shifting automatically as day length
changes through the season.

1. Tap **Add Astral Interval**.
2. Choose Sunrise or Sunset as the reference event.
3. Set the offset — for example "30 minutes before sunrise" or "1 hour after
   sunset".
4. Set the duration of the playback window.
5. Assign your audio files and save.

*Example — a dawn chorus study:* start 30 min before sunrise, play for 90
minutes; and at sunset, play for 60 minutes.

### Seasonal

Different schedules for different times of year. Each season has its own
playlist of events, and Orpheus switches between them automatically by calendar
date.

**Natural seasons** — leave Custom Seasons off and tap **Setup Natural
Seasons**. Edit any of Spring, Summer, Fall or Winter to open its playlist
editor, then add events with **Add Astral** (sunrise/sunset-relative) or **Add
Fixed Time** (specific time of day).

**Custom seasons** — for research that does not align with standard seasons,
toggle **Custom Seasons** on. Name a season (e.g. "Spring Migration"), set its
start and end dates with the calendar picker, save, then build its playlist the
same way. Seasons may overlap.

*Example — a migration study:* Pre-Migration (Feb 15 – Mar 10), low-intensity
calls at dawn only; Peak Migration (Mar 10 – Apr 20), full dawn and dusk
playlist; Post-Migration (Apr 20 – May 15), monitoring calls only.

## 3. Recording (Pro only)

Orpheus Pro records audio to a USB drive alongside its playback role.

To make a first test recording:

1. Insert a USB drive with free space.
2. Open **Recording** mode.
3. On the **Audio** tab choose bit depth (16-bit or 24-bit), sample rate (44.1,
   48 or 96 kHz) and mono or stereo.
4. On the **Levels** tab press **Auto-Set Gain** while the loudest sound you
   expect is happening, so peaks land safely below clipping.
5. Press **Record Now**, capture a short sample, and play it back to check.

Beyond manual recording, Orpheus Pro can record on a **schedule**, relative to
**sunrise/sunset** (astral), or only when sound crosses a **threshold** you set.

::: note
**BEFORE YOUR FIRST DEPLOYMENT**
Recording level is the one setting that cannot be corrected afterwards. The
**Orpheus Pro Recording & Field Guide** covers levels and gain, microphone
placement, wind protection, threshold tuning and storage planning, and ends with
a pre-deployment checklist. Find it in your customer portal at
gaiaforge.tech/portal.
:::

## 4. Companion App

The companion app gives you remote control over Bluetooth, and is the easiest
way to set location and time.

1. **Android** — download the APK from **gaiaforge.tech/orpheus**. When
   prompted, allow installation from unknown sources. *(iOS: coming soon.)*
2. Open the app. It scans for nearby Orpheus devices automatically.
3. Tap your device in the list (e.g. "Orpheus-91BD"). The app connects over
   BLE, wakes the device if it is sleeping, and switches on its WiFi hotspot.
4. Join the `Orpheus-XXXX` WiFi network on your phone — it is open, with no
   password.
5. The full dashboard loads over WiFi: battery and solar status, schedules,
   device time and location, and diagnostics.

::: note
**HOTSPOT TIMEOUT**
The WiFi hotspot switches off after 5 minutes of inactivity to save power.
Reactivate it from the app when you need it.
:::

## 5. Deploy

### Enable Deep Sleep

To maximise battery life, enable **Deep Sleep** under **Settings → Power
Management**. Orpheus will power down between scheduled events and wake just
before the next one. A unit with adequate solar input can run indefinitely in
this mode.

You can always wake the device manually with the wake button on the enclosure,
or remotely from the companion app over Bluetooth.

### Pre-deployment checklist

::: checklist
- **Power** — battery connected via XT60; solar panel connected and facing the
  sun (south in the Northern Hemisphere, north in the Southern).
- **Time & location** — clock correct, GPS coordinates and timezone set.
- **Audio** — files imported; test tone plays through the speakers.
- **Schedule** — your interval, astral or seasonal schedule saved and enabled.
- **Sleep** — Deep Sleep enabled if you want autonomous operation.
- **Recording** *(Pro)* — USB drive fitted with room for the planned hours;
  levels set with Auto-Set Gain.
- **Seals** — enclosure closed, all connectors seated and weatherproof.
:::

### First few days

Check battery levels and playback logs for the first few days to confirm the
system is behaving as expected before leaving it unattended.

## 6. Quick Reference

| Item | Value |
|---|---|
| Battery connector | XT60 |
| Solar connector | MC4 |
| Audio formats | WAV, MP3 |
| WiFi hotspot SSID | `Orpheus-XXXX` (unique per device) |
| WiFi password | None (open network) |
| WiFi auto-off | 5 minutes of inactivity |
| Bluetooth range | ~10 metres |
| Boot time | ~60 seconds |
| RTC battery life | 3–6 years |
| Recording bit depth *(Pro)* | 16-bit or 24-bit |
| Recording sample rate *(Pro)* | 44.1, 48 or 96 kHz |
| Support | contact@gaiaforge.tech |

For the complete manual — troubleshooting, power management detail and full
companion app instructions — visit **gaiaforge.tech/orpheus** or your customer
portal at **gaiaforge.tech/portal**.

::: warn
**LEGAL COMPLIANCE**
Some jurisdictions regulate or prohibit the use of recorded calls to attract
wildlife. Ensure you have all necessary permits and comply with local laws
before deploying Orpheus in the field. GaiaForge Technology assumes no liability
for misuse.
:::

::: contact
**GaiaForge** · Rheinland-Pfalz, Germany · contact@gaiaforge.tech ·
+49 171 2002495 · gaiaforge.tech

Orpheus is a trademark of GaiaForge. © 2026 GaiaForge Technology. All rights
reserved.
:::
