# Bzzz

A Garmin Connect IQ app for the **Forerunner 255** (fr255 / fr255s / fr255m / fr255sm) that gives a short vibration tick at a regular interval — built for visually impaired swimmers who want to count rest time against the pool clock without looking at the watch.

The app works like a **swim / rest interval trainer**: one button (START) drives the whole cycle, inspired by the rest detection of Garmin's native pool swim.

- Press **START** (or tap the screen) → **swim phase**: the chrono times your current swim from 0:00, silent (no buzzes while swimming).
- Press **START** at the wall → **rest phase**: rest time starts from 0 and the watch gives an immediate buzz (the "rest starts" buzz). Then it buzzes every interval (see settings), and the big interval number counts 0 → 1 → 2… so you always know how many pool-clock intervals you've rested without looking.
- Press **START** to push off again → everything resets (rest count and chrono back to zero) and a fresh swim phase starts.
- Press **DOWN** (bottom-left button on the FR255) to reset the whole session to idle (white ring dot).
- Press **UP** (middle-left button on the FR255) to open settings.
- **BACK** (bottom-right button on the FR255) exits the app via the default back behavior.

The screen is high-contrast (white on black) with a status dot (white ring = ready, green dot = swimming, yellow half-disc = resting) and large digits.

**Views** (settings → `Default view`):

- **Intervals** (default): while resting, a big number shows the count of completed rest intervals, with the rest chrono below it. While swimming it shows the swim chrono. Idle shows a big 0.
- **Chronometer**: the classic layout — the current phase's chrono big, with the tick count below.

The rest interval is locked at the moment the rest phase starts, so the buzz grid never shifts mid-rest; changing the interval in settings applies from the next rest phase.

## Languages

English (default) and French (`fre`). French strings live in `resources-fre/strings/strings.xml` and the manifest declares `<iq:language>fre</iq:language>`; set the watch system language to French and the app, settings menu, and Garmin Connect settings all show French (e.g. « Intervalle : 15s », « Alerte : Vibration », « Puissance : 3 », « Retour »).

## How it works

- Press **START** (or tap the screen) to start the swim phase — a short confirmation buzz, then the chrono times your swim in silence.
- When you stop at the wall, press **START** again: the rest phase begins with a buzz, and every **N seconds** (default **15 s**, matching the pool pace clock) the watch gives a short buzz. Each buzz = one pool-clock interval of rest, and the big on-screen counter increases (0 → 1 → 2…).
- Press **START** once more to go back to swimming: the rest counter and chrono reset to zero and the swim chrono starts fresh.
- Press **UP** (middle-left button on the FR255) to open settings.
- Press **DOWN** (bottom-left button on the FR255) to reset the app to idle (long buzz).
- **BACK** (bottom-right button on the FR255) exits the app via the default back behavior.

## Settings

Configurable both in the app (DOWN button) and in Garmin Connect / Garmin Express (app settings):

- **Tick interval**: 5, 10, 15 (default), 20, 30, 45, 60, 90 or 120 seconds — the rest buzz cadence.
- **Alert on each tick**: Vibrate (default), Sound, or Vibrate + sound.
- **Vibration power**: 1–5.
- **Default view**: Intervals (default — big rest-interval count) or Chronometer (classic chrono + tick count).

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

If the watch ever shows **"Manifest file is not in the correct format"** when starting a sideloaded app: the loader keeps stale metadata keyed to the app UUID. Fix = remove the app on the watch (app list → hold → Remove App), restart the watch, then sideload a build whose manifest has a **fresh app UUID** and a fresh `.prg` filename. (This repo now uses a fresh UUID after hitting exactly that error.)

Sideload: connect the watch over USB (it appears as a mass-storage drive) and copy the matching `dist/Bzzz_fr255.prg` into `GARMIN/APPS/` on the watch. The app then appears in the watch's app list. (Built with SDK 9.2.0, signed with a locally generated developer key, so this works for sideloading; store submission would use a Garmin-issued key.)

## Building from source

The repo has two projects: `app/` (the watch app with glance) and `datafield/` (the in-activity data field). Build each from its own folder (the compiler scans the whole project dir for `.mc` files, so don't build from the repo root).

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/), download SDK 9.2.x and the `fr255` device pack.
2. Generate a developer key (VS Code "Monkey C: Generate Developer Key", or `openssl genrsa -out developer_key.pem 4096 && openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt`), keep it in the repo root (git-ignored, never commit it).
3. Build signed packages:

   ```
   cd app && monkeyc -d fr255 -o ../bin/Bzzz_fr255.prg -f monkey.jungle -y ../developer_key.der -w
   cd datafield && monkeyc -d fr255 -o ../bin/BzzzDatafield_fr255.prg -f monkey.jungle -y ../developer_key.der -w
   ```

   Replace `-d fr255` with `fr255s` / `fr255m` / `fr255sm` (and `fr255_sim` for the app simulator).

### Run in the simulator from VS Code

1. Install the **Monkey C** extension (Garmin) in VS Code, and make sure the SDK Manager has SDK 9.2.0 + the Forerunner 255 device pack installed. Run Command Palette → **Monkey C: Verify Installation** to check the extension sees the SDK and Java.
2. Command Palette → **Monkey C: Generate Developer Key** once (stores the key path in settings; needed to sign builds).
3. Open any `source/*.mc` file, then use the **Run and Debug** sidebar (Ctrl+Shift+D) and press the play button, or **Run → Run Without Debugging (Ctrl+F5)**. Pick `fr255` when prompted — the simulator starts with the app loaded. The repo ships a ready-made `.vscode/launch.json` ("Run App (fr255)" / "Run App (pick device)").
4. To just build without running: Command Palette → **Monkey C: Build Current Project**.

Alternatively from the command line with the SDK's `bin` on your PATH: `monkeyc -d fr255_sim -o bin/Bzzz_fr255_sim.prg -f monkey.jungle -y developer_key.der`, start the simulator (`bin/connectiq` / `ConnectIQ.app` / `ConnectIQ.exe`), then `monkeydo bin/Bzzz_fr255_sim.prg fr255`.

## Features beyond the basic stopwatch

- **Data field** (`datafield/`): a Connect IQ data field that runs inside activities (e.g. swim) — it follows the activity timer (start/pause/resume/stop/reset) and buzzes every interval. Add it to a swim activity page; it has its own settings (interval/alert/power). Note: `Settings.mc`/`Alert.mc` are duplicated into `datafield/source/` because the compiler scans each project dir separately.
- **Haptics**: distinct patterns — rest tick = single pulse (length = power), swim start = double short pulse, reset = one long pulse.
- **Progress ring**: while running, a thin ring at 93% radius fills over the current interval.
- **Battery**: UI redraws only when the displayed second changes (tick checks stay at 250 ms so the buzz grid stays exact).

## Project layout

```
app/                             watch app project (manifest, source, resources)
  source/BzzzApp.mc              app entry (AppBase) + glance view
  source/StopwatchView.mc        stopwatch state, timers, screen drawing, progress ring
  source/StopwatchDelegate.mc    button/touch handling
  source/SettingsMenu.mc         in-app settings menu (interval, alert, power)
  source/Settings.mc             properties access + presets
  source/Alert.mc                vibration/tone patterns
  resources/                     strings, settings, icons, edge-arc bitmaps
datafield/                       in-activity data field project (own manifest/resources)
dist/                            signed prebuilt packages (app + datafield)
docs/ tools/                     preview PNGs + generator
```

## Possible extension

If you ever want the ticking during a recorded swim activity (apps cannot be opened mid-activity on the Forerunner 255), the same `Alert`/`Settings` logic can be reused in a Connect IQ **data field** that runs inside the swim activity screen.
