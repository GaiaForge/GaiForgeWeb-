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

Check the clock displayed on screen. If it is incorrect, either set it manually
under **Settings → Time & Date**, or let the companion app do it — tap
**Auto-Configure Hub (GPS & Time)** in the app and it sets the clock, timezone
and GPS position from your phone in one step (see section 4).

The built-in battery-backed clock maintains accurate time from this point
forward, even when the device is powered off.

### 6. Load Audio Files

Insert a USB flash drive containing your audio files (**WAV or MP3**). Open the
**Audio File Manager** from the toolbar and use USB Import to copy files to the
device.

### 7. Create Your Portal Account

Register at **gaiaforge.tech/portal** to get your software updates, the
companion app and your documentation.

You will need your **device serial number**. Find it on the unit's touchscreen
under the **About** tab — the **(i)** icon at the top of the screen. It is also
printed on the device label.

Choose Register, select Orpheus, then enter the serial number along with your
name, email and a password.

::: note
**OPTIONAL, AND YOUR DATA STAYS YOURS**
Orpheus works fully offline — an account is only needed for updates,
documentation and optional cloud sync of your logs. Nothing is uploaded unless
you sign in inside the app, and audio recordings are never uploaded at all. See
the User Manual, section 13, for the detail.
:::

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

The companion app is how you manage a deployed unit. It works over Bluetooth,
**wakes a sleeping unit for you**, and is the easiest way to set location and
time — so once a unit is in the field you rarely need to open the enclosure.

### Install it

**Android** — download the APK from **gaiaforge.tech/orpheus** or your customer
portal. When prompted, allow installation from unknown sources.

**iOS** — the iPhone app is currently pending App Store approval.

### Connect

1. Open the app. It scans for nearby Orpheus devices automatically.
2. Tap your device in the list (e.g. "Orpheus-91BD").
3. That is the only step you take. The app connects over BLE, wakes the unit if
   it is asleep, switches on its `Orpheus-XXXX` WiFi hotspot, joins it, and
   loads the dashboard: battery and solar status, schedules, device time and
   location, and diagnostics.

**How long it takes:** about **20–40 seconds** if the unit is already awake, and
**up to a minute or slightly more** if it is asleep or switched off — a sleeping
unit has to boot before it can answer. The app shows its progress while it
waits, so leave it running rather than retrying.

### Auto-Configure Hub (GPS & Time)

In the app's **Settings** screen, pick your timezone and tap **Auto-Configure
Hub (GPS & Time)**. The app reads your phone's GPS, sends the position, timezone
and current time to the unit, and reads the clock back to confirm — setting
everything Astral and Seasonal scheduling need, with no typing.

::: note
**HOTSPOT TIMEOUT**
The WiFi hotspot switches off after 5 minutes of inactivity to save power.
Reconnecting from the app switches it back on.
:::

## 5. Deploy

### Enable Deep Sleep

To maximise battery life, enable **Deep Sleep** under **Settings → Power
Management**. Orpheus will power down between scheduled events and wake just
before the next one. A unit with adequate solar input can run indefinitely in
this mode.

You can always wake the device manually with the wake button on the enclosure,
or remotely from the companion app over Bluetooth.

### Switch the monitor off

The touchscreen has its own switch on the front panel. **Turn the monitor off
for normal use** — switch it on only when you need to work on the unit directly.

Orpheus runs exactly the same with the screen off, and you keep full control
through the app. The display is one of the biggest continuous power draws on the
unit, so leaving it on eats into your deployment time for nothing.

### Pre-deployment checklist

::: checklist
- **Power** — battery connected via XT60; solar panel connected and facing the
  sun (south in the Northern Hemisphere, north in the Southern).
- **Time & location** — clock correct, GPS coordinates and timezone set (or run
  Auto-Configure Hub from the app).
- **Audio** — files imported; test tone plays through the speakers.
- **Schedule** — your interval, astral or seasonal schedule saved and enabled.
- **Sleep** — Deep Sleep enabled if you want autonomous operation.
- **Recording** *(Pro)* — USB drive fitted with room for the planned hours;
  levels set with Auto-Set Gain.
- **App** — paired and connecting, so you can reach the unit without opening it.
- **Monitor** — front-panel screen switch turned off.
- **Seals** — enclosure closed, all connectors seated and weatherproof.
:::

### First few days

Check battery levels and playback logs for the first few days to confirm the
system is behaving as expected before leaving it unattended.

## 6. Updates

Orpheus updates from a USB stick, using a single file that contains both the
device application and the firmware.

1. Download `orpheus_update.zip` from your customer portal at
   **gaiaforge.tech/portal** — the Orpheus dashboard lists the current release
   and its notes.
2. Create a folder on a USB stick named exactly `orpheus_update` and put the zip
   inside it, still zipped.
3. Insert the stick, then on the unit go to **Settings → Updates** and tap
   **Scan for USB**, then **Update App**, then **Update Firmware**.

It takes about 3–5 minutes, with a progress display throughout.

::: warn
**TWO THINGS TO GET RIGHT**
The folder name `orpheus_update` is **case sensitive** — all lower case, with an
underscore. And **do not power the unit off** during an update; wait for the
completion message. The unit restarts its own application when finished and does
not reboot.
:::

## 7. Quick Reference

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
| App connect — unit awake | ~20–40 seconds |
| App connect — unit asleep | up to ~1 minute or a little more |
| Monitor (front-panel switch) | Off for normal use |
| Update folder on USB | `orpheus_update` (case sensitive) |
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
