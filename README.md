# Bzzz

A Garmin Connect IQ app for the **Forerunner 255** (fr255 / fr255s / fr255m / fr255sm) that counts rest intervals by vibration — built for visually impaired swimmers and freedivers who want to count rest time without looking at the watch.

Press **START** once, then the watch runs the session by itself (see [How it works](#how-it-works)). At any time **START** overrides the machine, **UP** (middle-left) opens settings, **DOWN** (bottom-left) resets the session, and **BACK** exits.

The screen is high-contrast (white on black) with a status dot (white ring = ready, green dot = swimming) and the rest count in huge bundled Roboto Black digits (LOW vision friendly: a single-digit count fills ~82% of the FR255 face).

**Views** (settings → `Default view`):

- **Intervals** (default): ready shows the swim chrono at 0:00 with a `rest: 15 s` hint; swimming shows the status dot above the swim chrono; **resting shows ONLY the interval count** — huge Roboto Black digits (single digit ~82% of a FR255 face, two digits ~52%, three ~35%). The font ships at three raster sizes (via `tools/genfont.py`) and the app picks the largest that fits.
- **Chronometer**: the classic layout — the current phase's chrono big, with the tick count below.

The rest interval is locked at the moment the rest phase starts, so the buzz grid never shifts mid-rest; changing the interval in settings applies from the next rest phase.

## Languages

English (default) and French (`fre`). French strings live in `resources-fre/strings/strings.xml` and the manifest declares `<iq:language>fre</iq:language>`; set the watch system language to French and the app, settings menu, and Garmin Connect settings all show French (e.g. « Intervalle : 15s », « Alerte : Vibration », « Puissance : 3 », « Retour »).

## How it works

Bzzz is a **hands-free swim/rest interval trainer** for freedivers: press START once, and from then on the watch senses movement and runs the whole cycle by itself.

- **Auto mode** (default, "Mode: Auto (motion)"): the FR255's accelerometer classifies you as **swimming** while you're moving and **resting** once you've been still for the *rest delay* (default 10 s — long enough that a streamlined glide underwater never counts as rest, but a stop at the wall does).
  - Rest begins **automatically** after the stillness delay: a triple buzz, then the giant rest-interval count ticks at your interval. **The rest clock is backdated to when you actually stopped moving**, so the first interval buzz lands exactly one interval (15 s by default) after you stopped - the count matches the pool clock, not the detection delay.
  - You kick off for the next dive: after ~3 s of motion the watch is back to **swimming** — count and chrono reset, double buzz, no button touched underwater.
  - At any moment **START overrides the machine** (press to force a phase change) and **DOWN resets the session**.
- **Manual mode** ("Mode: Manual (button)"): the same cycle, driven entirely by START presses (the classic behavior).

Buzz vocabulary:

- **Rest starts** — 3 quick pulses
- **Interval tick** — a single short pulse at every interval of rest (15 s default; the cadence is the product)
- **Back to swimming** — 2 medium pulses (slate wiped)
- **Reset** — 1 long pulse

Screens (settings → `Default view`):

- **Intervals** (default): **ready** shows the swim chrono frozen at 0:00 with a small `rest: 15 s` hint; **swimming** shows the status dot above the swim chrono; **resting shows ONLY the rest-interval count** in huge bundled Roboto Black digits (a single digit fills ~82% of a FR255 face).
- **Chronometer**: the classic two-row layout (chrono big, tick count below).

Tuning (in-app menu or Garmin Connect settings):

- **Tick interval** (5–120 s, default 15 s) — the rest buzz cadence.
- **Alert** (vibrate / sound / both) and **vibe power** (1–5).
- **Automation**: Auto (motion) or Manual (button).
- **Motion sensitivity** (high / medium / low): threshold for what counts as "moving", in case you scull gently while resting or want only strong kicks to count.
- **Rest delay** (5 / 10 / 15 s): how long you must be still at the wall before rest is declared.

The rest interval is locked at rest start, so the buzz grid never shifts mid-rest; settings changes apply from the next phase.

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

Signed `.prg` files built with Connect IQ SDK 9.3.0 are committed under [`dist/`](dist/):

- `dist/Bzzz_fr255.prg` — Forerunner 255
- `dist/Bzzz_fr255s.prg` — Forerunner 255s
- `dist/Bzzz_fr255m.prg` — Forerunner 255 Music
- `dist/Bzzz_fr255sm.prg` — Forerunner 255s Music
- `dist/Bzzz_fr255_sim.prg` — simulator build (fr255 device, for use with `monkeydo`)

## Installing on the watch

If the watch ever shows **"Manifest file is not in the correct format"** when starting a sideloaded app: the loader keeps stale metadata keyed to the app UUID. Fix = remove the app on the watch (app list → hold → Remove App), restart the watch, then sideload a build whose manifest has a **fresh app UUID** and a fresh `.prg` filename. (This repo now uses a fresh UUID after hitting exactly that error.)

Sideload: connect the watch over USB (it appears as a mass-storage drive) and copy the matching `dist/Bzzz_fr255.prg` into `GARMIN/APPS/` on the watch. The app then appears in the watch's app list. (Built with SDK 9.3.0, signed with a locally generated developer key, so this works for sideloading; store submission would use a Garmin-issued key.)

## Building from source

The repo has two projects: `app/` (the watch app with glance) and `datafield/` (the in-activity data field). Build each from its own folder (the compiler scans the whole project dir for `.mc` files, so don't build from the repo root).

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) — on macOS `brew install --cask connectiq-sdk-manager` works — log in with a Garmin account, download an SDK (this machine has **9.3.0**) and the `fr255` device packs (fr255 / fr255s / fr255m / fr255sm). The manager keeps everything under `~/Library/Application Support/Garmin/ConnectIQ/` (`Sdks/` + `Devices/`). `monkeyc` resolves devices from that `Devices/` folder automatically.
2. Install Java 17 (`brew install openjdk@17`) — `monkeyc` needs `java` on its PATH.
3. Generate a developer key (VS Code "Monkey C: Generate Developer Key", or `openssl genrsa -out developer_key.pem 4096 && openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt`), keep it in the repo root (git-ignored, never commit it).
4. Build signed packages (put the SDK's `bin` and Java on your PATH first):

   ```
   export CIQ="$HOME/Library/Application Support/Garmin/ConnectIQ"
   export PATH="$CIQ/Sdks/connectiq-sdk-mac-9.3.0-2026-10-20-95888f262/bin:$(/usr/libexec/java_home -v 17)/bin:$PATH"

   cd app && monkeyc -d fr255 -o ../bin/Bzzz_fr255.prg -f monkey.jungle -y ../developer_key.der -w
   cd datafield && monkeyc -d fr255 -o ../bin/BzzzDatafield_fr255.prg -f monkey.jungle -y ../developer_key.der -w
   ```

   Replace `-d fr255` with `fr255s` / `fr255m` / `fr255sm`. (Avoid `-o ../dist/...`: the compiler drops debug byproducts next to the output, and `dist/` holds only signed `.prg` files.)

### Run in the simulator from VS Code

1. Install the **Monkey C** extension (Garmin) in VS Code, and make sure the SDK Manager has SDK 9.3.0 + the Forerunner 255 device packs installed. Run Command Palette → **Monkey C: Verify Installation** to check the extension sees the SDK and Java.
2. Command Palette → **Monkey C: Generate Developer Key** once (stores the key path in settings; needed to sign builds).
3. Open any `source/*.mc` file, then use the **Run and Debug** sidebar (Ctrl+Shift+D) and press the play button, or **Run → Run Without Debugging (Ctrl+F5)**. Pick `fr255` when prompted — the simulator starts with the app loaded. The repo ships a ready-made `.vscode/launch.json` ("Run App (fr255)" / "Run App (pick device)").
4. To just build without running: Command Palette → **Monkey C: Build Current Project**.

Alternatively from the command line with the SDK's `bin` on your PATH: start the simulator (`ConnectIQ.app` in the SDK's `bin/`), then `monkeydo bin/Bzzz_fr255.prg fr255` — a regular fr255 build runs in the simulator.

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
