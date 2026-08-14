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
   calculations. Alternatively, let the companion app do this for you — see
   *Auto-Configure Hub* in section 7.
5. **Speaker Check.** Connect speakers to the waterproof connectors. Confirm
   audio output by playing the test tone in Manual mode.
6. **Set Time (if needed).** The device includes a battery-backed real-time
   clock (RTC) that maintains accurate time. If the time appears incorrect, set
   it manually under **Settings → Time & Date**, or set it from your phone with
   the app's Auto-Configure Hub.
7. **Install the companion app.** Once the unit is running, install the app on
   your phone (section 7). It is how you will manage the unit in the field, and
   it lets you leave the touchscreen switched off — see section 9.
8. **Create your portal account.** Register at **gaiaforge.tech/portal** to get
   your documentation and software updates — see below.

::: note
**NO ASSEMBLY REQUIRED**
Orpheus comes preloaded with all necessary software. No image flashing or
assembly is required.
:::

### Creating your portal account

The customer portal at **gaiaforge.tech/portal** is where you download software
updates and the latest documentation, and where your device is registered to
you. Create the account once, when you first set the unit up.

You will need your **device serial number** to register.

#### Finding your serial number

On the unit's touchscreen, open the **About** tab — the **(i)** icon along the
top of the screen. Your serial number is listed there. It is also printed on the
device label.

#### Registering

1. Go to **gaiaforge.tech/portal** and choose **Register**.
2. Select your product — Orpheus.
3. Enter your device serial number, your name, email address and a password.
4. Sign in.

Your Orpheus dashboard then gives you the current software update with its
release notes, the companion app, and your documentation — this manual, the
Quick Start Guide, the Solar Panel Alignment Guide, and for Pro owners the
Recording & Field Guide.

::: note
**ONE ACCOUNT, EVERY DEVICE**
Register once. Additional units are added to the same account, so a fleet of
Orpheus devices is managed from a single login.
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

The companion mobile app is the main way to work with Orpheus in the field. It
connects over Bluetooth Low Energy (BLE), and can **wake a sleeping unit** — you
do not need to open the enclosure or touch the screen to check on a deployment.

### Getting the App

- **Android** — download the APK from **gaiaforge.tech/orpheus** or from your
  customer portal, and install it on your phone. You may need to allow
  installation from unknown sources when prompted.
- **iOS** — the iPhone app is currently pending App Store approval.

### Connecting to Your Device

1. Open the Orpheus app on your phone.
2. The app scans for nearby Orpheus devices via Bluetooth automatically.
3. Tap your device in the list (e.g. "Orpheus-91BD").
4. The app connects over BLE and, if the unit is asleep, **wakes it**. The
   status text keeps you informed while it boots.
5. The app then activates the unit's WiFi hotspot — `Orpheus-XXXX`, an open
   network with no password — and joins it for you.
6. The full dashboard loads over WiFi.

### How long connecting takes

The whole sequence is automatic — you only tap your device in the list — but how
long it takes depends on whether the unit is already awake:

| Unit state | Time to the dashboard |
|---|---|
| Already booted and awake | about 20–40 seconds |
| Asleep or powered off | up to a minute, sometimes slightly more |

A sleeping unit has to boot before it can answer, which takes roughly a minute
on its own. The app shows a progress message while it waits, then brings up the
hotspot and joins it.

::: note
**THIS IS NORMAL**
A wait of up to a minute on a sleeping unit is expected behaviour, not a fault.
Leave the app on the connecting screen and let it finish — it is waiting for the
unit to finish booting before it can join the hotspot.
:::

### App Features

- View real-time battery voltage, charge state, and solar input
- Configure playback modes and schedules remotely
- Set device time, timezone, and location — see Auto-Configure below
- Send commands: sleep, wake, restart
- Configure recording quality, thresholds and schedules *(Pro)*
- View environmental sensor data *(Pro)*
- Access diagnostics and system status

### Auto-Configure Hub (GPS & Time)

The fastest way to set up a unit at a new site. In the app's **Settings**
screen, choose your timezone and tap **Auto-Configure Hub (GPS & Time)**. The
app then:

1. Reads your phone's GPS position;
2. Sends the latitude, longitude and timezone to the unit;
3. Sets the unit's clock from your phone;
4. Reads the time back from the unit's real-time clock to confirm it took.

This sets everything Astral and Seasonal scheduling depend on in one step, with
no typing of coordinates.

::: note
**HOTSPOT TIMEOUT**
The WiFi hotspot automatically turns off after 5 minutes of inactivity to save
power. Reconnecting from the app switches it back on.
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
- The system clock automatically syncs from the RTC on every boot and
  periodically during operation.

There are two ways to set the clock:

- **From the app (recommended).** Tap **Auto-Configure Hub (GPS & Time)** in the
  app's Settings screen. The unit's clock is set from your phone, along with
  your GPS position and timezone, and the app reads the time back from the RTC
  to confirm. This is the quickest and least error-prone method, and it sets
  location at the same time.
- **On the touchscreen.** Set the time and date manually under **Settings → Time
  & Date**.

Either method also updates the RTC, so the new time survives power loss and
deep sleep.

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

### Turn the monitor off for normal use

The touchscreen has its own switch on the front panel. **Leave the monitor
switched off for day-to-day operation** and switch it on only when you need to
work on the unit directly.

Orpheus runs perfectly well with the screen off — playback, scheduling, sleep
and wake are all unaffected, and you can still do everything from the companion
app. The display is one of the larger continuous power draws on the unit, so
leaving it on needlessly shortens how long a deployment lasts between charges.

::: note
**THE SCREEN IS FOR SETUP, THE APP IS FOR THE FIELD**
Use the touchscreen to commission a unit, then switch the monitor off and manage
the deployment from your phone. The app wakes the unit and gives you status,
schedules and diagnostics without touching the enclosure.
:::

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

- **Monitor Off** — switch the touchscreen off at the front panel before you
  leave the site. The unit operates normally without it and the saved power goes
  into your deployment time. Manage the unit from the companion app instead.
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

- **Give it time first.** A unit that is awake takes about 20–40 seconds to
  reach the dashboard; one that is asleep or off takes up to a minute or a
  little more, because it has to boot before it can respond. Let the connecting
  screen run to completion before assuming a fault.
- Ensure Bluetooth is enabled on your phone and the phone is within range
  (approximately 10 metres).
- On Android, grant "Nearby devices" and "Location" permissions to the Orpheus
  app. Location permission is used only to send your position to the device —
  it is not used to track you.
- If the hotspot join fails, join the `Orpheus-XXXX` network manually in your
  phone's WiFi settings and return to the app.
- If the unit has been idle a long time, the hotspot may have timed out;
  reconnecting from the app switches it back on.

### Recording Issues (Pro only)

- Confirm sufficient storage space on the USB device.
- Check microphone or external audio input connections.
- Ensure the USB device is properly formatted (FAT32 or exFAT recommended).
- If recordings are empty, a threshold may be set too high for the site — see
  the Recording & Field Guide.

## 12. Maintenance

### Software Updates (OTA)

Orpheus updates itself from a USB stick. A single update file contains both the
device application and the ESP32 firmware, and you apply it from the unit's own
touchscreen — no service visit and no tools required.

**1. Download the update.** Sign in to your customer portal at
**gaiaforge.tech/portal**. The Orpheus dashboard lists the current release with
its version, date and release notes. Download `orpheus_update.zip`.

**2. Put it on a USB stick.** Create a folder on the stick named exactly
`orpheus_update` and place the zip file inside it.

::: warn
**THE FOLDER NAME IS CASE SENSITIVE**
The folder must be named `orpheus_update` — all lower case, with an underscore.
`Orpheus_Update` or `orpheus update` will not be found. The zip goes *inside*
that folder; do not unzip it.
:::

**3. Install it.** Insert the stick into the unit's USB port, then on the
touchscreen go to **Settings → Updates**:

1. Tap **Scan for USB**. The unit finds the update and shows its version.
2. Tap **Update App** to install the device application.
3. Tap **Update Firmware** to install the ESP32 firmware.

A full-screen progress display takes over, labelled *Step 1 of 2* and *Step 2 of
2*, with a percentage and estimated time remaining. The whole process takes
about **3 to 5 minutes**, most of it transferring firmware.

::: warn
**DO NOT POWER OFF DURING AN UPDATE**
Interrupting an update part-way through can leave the unit unable to start. Wait
for the completion message. Make sure the battery is adequately charged, or the
unit is on solar, before you begin.
:::

When it finishes you will see a confirmation with the installed version, and the
application restarts by itself. **The unit does not reboot** — if the screen goes
black for a long period, something has gone wrong.

If an update fails, the unit reports the reason on screen and restarts the
application anyway, so it is never left stranded. A diagnostic log is kept on the
device and survives restarts; quote the version you were installing when
contacting support.

### File Management

- Regularly remove unused audio or log files to free storage space.
- Back up important configurations and recordings to USB.

### Hardware Maintenance

- Periodically inspect connectors and seals for wear or moisture ingress.
- Clean solar panels to maintain charging efficiency.
- The internal clock battery should be replaced every 3–6 years if timekeeping
  becomes unreliable. Contact GaiaForge for service.

## 13. Your Data and Privacy

Orpheus is designed to work completely offline. Sending anything to the cloud is
your choice, and nothing leaves the device unless you make it happen.

### What the device records

Orpheus keeps its own logs on the unit, on its internal storage:

| Data | Detail |
|---|---|
| Playback events | Which file played, when, and for how long |
| Battery and solar | Voltage, charge state and solar input over time |
| System events | Sleep, wake, restarts and errors |
| Environmental readings *(Pro)* | Temperature, humidity and barometric pressure |
| Deployment settings | GPS coordinates, timezone and the nickname you give the unit |
| Recordings *(Pro)* | WAV files on your USB drive, with embedded GUANO metadata |

This is operational and scientific data about a device and a location. It is not
information about people.

### What leaves the device

Nothing, unless you ask for it. There are three ways data can move:

- **USB export** — you copy logs or recordings to a USB drive yourself.
- **The companion app** — when you connect, the app can read recent logs onto
  your phone so you can see charts and status.
- **The cloud portal** — *only if you create an account and sign in inside the
  app.* Until you do, no data is uploaded anywhere.

If you are signed in, the app caches the last 30 days of environmental,
battery, playback and system logs when it connects, and uploads them to your
portal account once your phone has an internet connection. (The unit's own
hotspot has no internet, so the upload happens later, when you are back on a
normal network.)

::: note
**YOUR RECORDINGS STAY WITH YOU**
Audio recordings are **never uploaded to the cloud**. They are written to your
USB drive and stay there. Only the small operational logs listed above are ever
synced, and only when you are signed in.
:::

### Working entirely offline

If you never create a portal account, Orpheus still does everything described in
this manual. You lose only the online extras — software updates and
documentation downloads, which you can also request by email — and your data
stays entirely on the device, your USB drives and your phone.

### Your rights over your data

You own your data. Under the EU General Data Protection Regulation (GDPR), and
as a matter of how we operate for every customer regardless of location, you can
at any time:

- **Retrieve your data** — export it from the portal in a machine-readable
  format (CSV), or take it straight off the unit by USB.
- **Correct it** — request correction of anything inaccurate.
- **Delete it** — delete your account and all data associated with it. You can
  do this yourself from the companion app, or ask us to.
- **Restrict or object to processing**, and lodge a complaint with your national
  data protection authority.

We do not sell your data, and we do not share it with third parties for their
own purposes.

::: note
**FULL POLICY**
This section summarises how Orpheus handles data. The complete and authoritative
statement — including the limited circumstances in which data may be processed
on our behalf, and how to exercise each right — is the GaiaForge Privacy Policy
at **gaiaforge.tech/privacy-policy.html**. For data protection enquiries, write
to contact@gaiaforge.tech.
:::

## 14. Support

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
