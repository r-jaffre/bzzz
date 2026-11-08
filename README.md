# Bzzz

A Garmin Connect IQ stopwatch app for the **Forerunner 255** (fr255 / fr255s / fr255m / fr255sm) that gives a short vibration tick at a regular interval — built for visually impaired swimmers who want to count rest time against the pool clock without looking at the watch.

## How it works

- Press **START** (or tap the screen) to start the stopwatch.
- Every **N seconds** (default **15 s**, matching the pool pace clock) the watch gives a short buzz and the on-screen tick counter increases, so each buzz = one pool-clock interval of rest.
- Press **START** again to pause, once more to resume. Pausing keeps the buzz cadence aligned with the chronometer: the next buzz still lands on the same 15 s grid, not a full interval after resuming.
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

## Prebuilt packages

Signed `.prg` files built with Connect IQ SDK 9.2.0 are committed under [`dist/`](dist/):

- `dist/Bzzz_fr255.prg` — Forerunner 255
- `dist/Bzzz_fr255s.prg` — Forerunner 255s
- `dist/Bzzz_fr255m.prg` — Forerunner 255 Music
- `dist/Bzzz_fr255sm.prg` — Forerunner 255s Music
- `dist/Bzzz_fr255_sim.prg` — simulator build (`fr255_sim`, for use with `monkeydo`)

## Installing on the watch

Sideload: connect the watch over USB (it appears as a mass-storage drive) and copy the matching `dist/Bzzz_fr255.prg` into `GARMIN/APPS/` on the watch. The app then appears in the watch's app list. (Built with SDK 9.2.0, signed with a locally generated developer key, so this works for sideloading; store submission would use a Garmin-issued key.)

## Building from source

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/), download SDK 9.2.x and the `fr255` device pack.
2. Generate a developer key (VS Code "Monkey C: Generate Developer Key", or `openssl genrsa -out developer_key.pem 4096 && openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt`), keep it in the repo root (git-ignored, never commit it).
3. Build a signed `.prg`:

   ```
   monkeyc -d fr255 -o bin/Bzzz_fr255.prg -f monkey.jungle -y developer_key.der -w
   ```

   Replace `-d fr255` with `fr255s` / `fr255m` / `fr255sm` / `fr255_sim` for the other targets.

### Run in the simulator from VS Code

1. Install the **Monkey C** extension (Garmin) in VS Code, and make sure the SDK Manager has SDK 9.2.0 + the Forerunner 255 device pack installed. Run Command Palette → **Monkey C: Verify Installation** to check the extension sees the SDK and Java.
2. Command Palette → **Monkey C: Generate Developer Key** once (stores the key path in settings; needed to sign builds).
3. Open any `source/*.mc` file, then use the **Run and Debug** sidebar (Ctrl+Shift+D) and press the play button, or **Run → Run Without Debugging (Ctrl+F5)**. Pick `fr255` when prompted — the simulator starts with the app loaded. The repo ships a ready-made `.vscode/launch.json` ("Run App (fr255)" / "Run App (pick device)").
4. To just build without running: Command Palette → **Monkey C: Build Current Project**.

Alternatively from the command line with the SDK's `bin` on your PATH: `monkeyc -d fr255_sim -o bin/Bzzz_fr255_sim.prg -f monkey.jungle -y developer_key.der`, start the simulator (`bin/connectiq` / `ConnectIQ.app` / `ConnectIQ.exe`), then `monkeydo bin/Bzzz_fr255_sim.prg fr255`.

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
