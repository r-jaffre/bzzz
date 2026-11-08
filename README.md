# Bzzz

A Garmin Connect IQ stopwatch app for the **Forerunner 255** (fr255 / fr255s / fr255m / fr255sm) that gives a short vibration tick at a regular interval — built for visually impaired swimmers who want to count rest time against the pool clock without looking at the watch.

## How it works

- Press **START** (or tap the screen) to start the stopwatch.
- Every **N seconds** (default **15 s**, matching the pool pace clock) the watch gives a short buzz and the on-screen tick counter increases, so each buzz = one pool-clock interval of rest.
- Press **START** again to pause, once more to resume.
- Press **UP** to reset the stopwatch to zero.
- Press **DOWN** (or the menu button on devices that have one) to open settings.
- **BACK** exits the app.

The screen is high-contrast (white on black) with large digits: status, elapsed `MM:SS`, tick count, and the current interval/alert mode.

## Settings

Configurable both in the app (DOWN button) and in Garmin Connect / Garmin Express (app settings):

- **Tick interval**: 5, 10, 15 (default), 20, 30, 45, 60, 90 or 120 seconds.
- **Alert on each tick**: Vibrate (default), Sound, or Vibrate + sound.

Notes on alerts:

- Forerunner devices run the vibration motor at a fixed duty cycle, so the "lightness" of the buzz comes from its short length (~150 ms), not the strength setting.
- The sound option plays a soft `TONE_KEY` beep on each tick.

## Building

Requires the Connect IQ SDK 4.2+ (Java 8+ for the `monkeyc` compiler):

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) and download SDK 4.2.x.
2. Generate a developer key (VS Code "Monkey C: Generate Developer Key", or `sdkmanager`), place it as `developer_key` in the repo root (git-ignored).
3. Build a signed `.prg`:

   ```
   monkeyc -o bin/Bzzz.prg -f monkey.jungle -y developer_key
   ```

   or use the VS Code Monkey C extension ("Monkey C: Build for device" / run in simulator with the `fr255` device).

## Installing on the watch

- Via Garmin Express / Garmin Connect (sideload): copy `bin/Bzzz.prg` to the `GARMIN/APPS` folder of the watch connected over USB (rename to a 8.3-style name if needed, e.g. `GARMIN/APPS/BZZZ.PRG`).
- Or from the Connect IQ Mobile app once published to the store.

## Project layout

```
manifest.xml                     app metadata, products (fr255 family), entry point
monkey.jungle                    build configuration
source/BzzzApp.mc                app entry (AppBase)
source/StopwatchView.mc          stopwatch state, interval timer, screen drawing
source/StopwatchDelegate.mc      button/touch handling
source/SettingsMenu.mc           in-app settings menu (interval, alert mode)
source/Settings.mc               properties access + presets
source/Alert.mc                  vibration/tone on each tick
resources/                       strings, settings, launcher icon
```

## Possible extension

If you ever want the ticking during a recorded swim activity (apps cannot be opened mid-activity on the Forerunner 255), the same `Alert`/`Settings` logic can be reused in a Connect IQ **data field** that runs inside the swim activity screen.
