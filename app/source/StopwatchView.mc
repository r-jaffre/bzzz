import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Swim/rest interval trainer:
//   START (idle)  -> swim phase: chrono times the current swim from 0, silent.
//   START (swim)  -> rest phase: rest time from 0, buzz now, then one buzz per
//                   interval; the big number counts completed rest intervals.
//   START (rest)  -> back to a fresh swim phase; rest count and chrono reset.
//   DOWN          -> reset everything to idle.
class StopwatchView extends WatchUi.View {
    static const PHASE_READY = 0;
    static const PHASE_SWIM = 1;
    static const PHASE_REST = 2;

    var phase = 0;
    var phaseStartMs = 0;
    var ticks = 0;
    var intervalMs = 15000;
    var uiTimer as Timer.Timer or Null = null;
    var lastSec = -1;
    var detector as AutoDetector or Null = null;
    var sensorOn = false;
    var sensorFailed = false;

    // Build marker drawn on the ready screen, so the installed build can be
    // verified on the actual watch (MTP sideloading gives no feedback).
    static const BUILD_TAG = "v1.2";

    function initialize() {
        View.initialize();
    }

    var arcsBmp as Graphics.BitmapType or Null = null;

    function onLayout(dc as Graphics.Dc) as Void {
        arcsBmp = WatchUi.loadResource(dc.getWidth() >= 260 ? Rez.Drawables.EdgeArcs260 : Rez.Drawables.EdgeArcs218);
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    // START button: advance the phase cycle (always works, even in auto mode).
    function advancePhase() as Void {
        if (phase == StopwatchView.PHASE_SWIM) {
            enterRest(false);
        } else {
            enterSwim();
        }
    }

    // Shared by button presses and auto detection: at the wall = rest begins.
    // For auto detection, backdate the rest clock to when movement ACTUALLY
    // stopped, so the interval grid is aligned with the true rest start
    // (the first interval buzz lands a full interval after the swimmer
    // stopped, not a full interval after detection).
    function enterRest(backdate as Lang.Boolean) as Void {
        var now = System.getTimer();
        phase = StopwatchView.PHASE_REST;
        if (backdate && detector != null) {
            phaseStartMs = now - detector.stillMs;
        } else {
            phaseStartMs = now;
        }
        ticks = 0;
        // Lock the interval for the whole rest phase so the buzz grid
        // never shifts mid-rest (settings changes apply next phase).
        intervalMs = Settings.getIntervalSec() * 1000;
        if (intervalMs <= 0) {
            intervalMs = Settings.DEFAULT_INTERVAL_SEC * 1000;
        }
        // Backdated rest may have already crossed whole intervals while
        // stillness was being confirmed (short interval + long delay):
        // adopt that count silently; the next grid slot buzzes as usual.
        var elapsed = getElapsedMs();
        var startCount = elapsed / intervalMs;
        if (startCount > ticks) {
            ticks = startCount;
        }
        startUiTimer();
        // Distinct triple pulse: "rest is counting now".
        Alert.restStart();
        lastSec = -1;
        WatchUi.requestUpdate();
    }

    // Shared by button presses and auto detection: back to a fresh swim.
    function enterSwim() as Void {
        var now = System.getTimer();
        phase = StopwatchView.PHASE_SWIM;
        phaseStartMs = now;
        ticks = 0;
        startUiTimer();
        if (Settings.getAutoMode() == Settings.AUTO_ON) {
            startSensor();
        }
        // Two medium pulses: new swim phase, rest count wiped.
        Alert.swimStart();
        lastSec = -1;
        WatchUi.requestUpdate();
    }

    // --- Automatic rest detection (accelerometer) ---

    function startSensor() as Void {
        if (sensorOn || sensorFailed) {
            return;
        }
        try {
            if (Sensor has :registerSensorDataListener) {
                if (detector == null) {
                    detector = new AutoDetector(10, Settings.getMotionThreshold());
                }
                detector.reset();
                // Clamp the requested sample rate to what the hardware
                // supports. Guarded separately: this call itself must
                // never be able to take the session down.
                var rate = 10;
                try {
                    if ((Sensor has :getMaxSampleRateForSensorType)) {
                        var maxRate = Sensor.getMaxSampleRateForSensorType(:accelerometer);
                        if (maxRate instanceof Lang.Number && maxRate > 0 && maxRate < rate) {
                            rate = maxRate;
                        }
                    }
                } catch (eRate) {
                }
                Sensor.registerSensorDataListener(method(:onSensorData), {
                    :period => 1,
                    :accelerometer => {
                        :enabled => true,
                        :sampleRate => rate
                    }
                });
                sensorOn = true;
            }
        } catch (e) {
            // Nothing in the sensing setup may ever kill the session:
            // disable auto detection and keep going button-driven.
            onSensorFail();
        }
    }

    // Single place for "auto mode is unavailable, running manual instead".
    // Buzzes once so the user knows auto is off, and shows a marker on screen.
    function onSensorFail() as Void {
        if (!sensorFailed) {
            sensorFailed = true;
            stopSensor();
            Alert.autoDisabled();
            WatchUi.requestUpdate();
        }
    }

    function stopSensor() as Void {
        if (sensorOn && (Sensor has :unregisterSensorDataListener)) {
            try {
                Sensor.unregisterSensorDataListener();
            } catch (e) {
            }
        }
        sensorOn = false;
    }

    // Sensor data callback. Runs in a context we cannot debug on hardware,
    // so any failure here must degrade gracefully to manual mode instead of
    // killing the session (an uncaught exception = CIQ failure screen).
    function onSensorData(sensorData as Sensor.SensorData) as Void {
        try {
            if (detector == null) {
                return;
            }
            if (sensorData has :accelerometerData) {
                var d = sensorData.accelerometerData;
                // The axis arrays are individually nullable per the docs.
                if (d != null && d.x != null && d.y != null && d.z != null) {
                    detector.ingest(d.x, d.y, d.z);
                    evaluateAutoTransitions();
                }
            }
        } catch (e) {
            // Never let a sensor issue abort the workout: stop sensing and
            // keep running with button-driven (manual) behavior.
            onSensorFail();
        }
    }

    // Auto phase transitions: still too long while swimming -> rest;
    // moving again while resting -> new swim. Buttons override anytime.
    function evaluateAutoTransitions() as Void {
        if (detector == null || Settings.getAutoMode() != Settings.AUTO_ON) {
            return;
        }
        if (phase == StopwatchView.PHASE_SWIM) {
            if (detector.stillMs >= Settings.getStillSec() * 1000) {
                enterRest(true);
            }
        } else if (phase == StopwatchView.PHASE_REST) {
            if (detector.moveMs >= AutoDetector.MOVE_ONSET_MS) {
                enterSwim();
            }
        }
    }

    function reset() as Void {
        stopAllTimers();
        stopSensor();
        sensorFailed = false;
        Alert.resetBuzz();
        lastSec = -1;
        phase = StopwatchView.PHASE_READY;
        phaseStartMs = 0;
        ticks = 0;
        intervalMs = Settings.DEFAULT_INTERVAL_SEC * 1000;
        WatchUi.requestUpdate();
    }

    function stopAllTimers() as Void {
        stopSensor();
        if (uiTimer != null) {
            uiTimer.stop();
        }
    }

    function startUiTimer() as Void {
        if (uiTimer == null) {
            uiTimer = new Timer.Timer();
        }
        uiTimer.stop();
        uiTimer.start(method(:onUiTick), 250, true);
    }

    function onUiTick() as Void {
        // Keep motion sensing in sync with settings (menu can change mid-session).
        if (Settings.getAutoMode() == Settings.AUTO_ON && sensorOn == false && sensorFailed == false && phase != StopwatchView.PHASE_READY) {
            startSensor();
        }
        if (detector != null) {
            detector.thresholdMG = Settings.getMotionThreshold();
        }
        var elapsed = getElapsedMs();
        if (phase == StopwatchView.PHASE_REST) {
            var tickIndex = elapsed / intervalMs;
            if (tickIndex > ticks) {
                ticks = tickIndex;
                Alert.tick(Settings.getAlertMode(), Settings.getVibePower());
            }
        }
        var sec = elapsed / 1000;
        if (sec != lastSec) {
            lastSec = sec;
            WatchUi.requestUpdate();
        }
    }

    function getElapsedMs() as Lang.Number {
        if (phase == StopwatchView.PHASE_READY) {
            return 0;
        }
        return System.getTimer() - phaseStartMs;
    }

    function formatTime(ms as Lang.Number) as Lang.String {
        var totalSec = ms / 1000;
        var minutes = totalSec / 60;
        var seconds = totalSec % 60;
        return Lang.format("$1$:$2$", [pad2(minutes), pad2(seconds)]);
    }

    function pad2(n as Lang.Number) as Lang.String {
        if (n < 10) {
            return Lang.format("0$1$", [n]);
        }
        return Lang.format("$1$", [n]);
    }

    // Huge count rendering: Roboto Black rasterized at three sizes
    // (resources/fonts/fonts.xml); pick the largest that fits the screen.
    var bigFonts as Lang.Array<Graphics.FontType> = [];
    var bigFontsTried = false;

    function loadBigFonts() as Void {
        if (!bigFontsTried) {
            bigFontsTried = true;
            bigFonts = [
                WatchUi.loadResource(Rez.Fonts.BigCount290),
                WatchUi.loadResource(Rez.Fonts.BigCount185),
                WatchUi.loadResource(Rez.Fonts.BigCount125)
            ];
        }
    }

    // Pick the biggest bundled font whose rendering of txt fits in
    // (maxW x maxH). Falls back to the smallest bundled font.
    function pickBigFont(dc as Graphics.Dc, txt as Lang.String, maxW as Lang.Number, maxH as Lang.Number) as Graphics.FontType {
        loadBigFonts();
        var best = bigFonts[bigFonts.size() - 1];
        for (var i = 0; i < bigFonts.size(); i++) {
            var f = bigFonts[i];
            var dim = dc.getTextDimensions(txt, f);
            if (dim[0] <= maxW && dim[1] <= maxH) {
                return f;
            }
            best = f;
        }
        return best;
    }

    // Text height of the big count on this screen (for layout).
    function bigDigitsHeight(dc as Graphics.Dc, w as Lang.Number, h as Lang.Number, value as Lang.Number) as Lang.Number {
        var txt = Lang.format("$1$", [value]);
        var f = pickBigFont(dc, txt, w * 86 / 100, h * 88 / 100);
        var dim = dc.getTextDimensions(txt, f);
        return dim[1];
    }

    // Draw value as huge Roboto Black digits centered on cy.
    function drawBigCount(dc as Graphics.Dc, w as Lang.Number, cy as Lang.Number, value as Lang.Number, h as Lang.Number) as Void {
        var txt = Lang.format("$1$", [value]);
        var f = pickBigFont(dc, txt, w * 86 / 100, h * 88 / 100);
        dc.drawText(w / 2, cy, f, txt, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        if (arcsBmp != null) {
            dc.drawBitmap(0, 0, arcsBmp);
        }

        var isSwim = phase == StopwatchView.PHASE_SWIM;
        var isRest = phase == StopwatchView.PHASE_REST;

        var statusColor = Graphics.COLOR_WHITE;
        if (isSwim) {
            statusColor = Graphics.COLOR_GREEN;
        } else if (isRest) {
            statusColor = Graphics.COLOR_YELLOW;
        }

        // Choose the big / medium figures for the current view.
        var chronoTxt = formatTime(getElapsedMs());
        var bigHotTxt = "";   // drawn with FONT_NUMBER_HOT
        var bigCountValue = -1; // >= 0 -> drawn as huge Roboto Black digits
        var medTxt = "";
        var medFont = Graphics.FONT_NUMBER_MEDIUM; // digits only
        var noDot = false;      // rest screen: count only, no status dot
        if (Settings.getViewMode() == Settings.VIEW_CHRONO) {
            // Classic view: phase chrono big, tick count below.
            bigHotTxt = chronoTxt;
            medTxt = Lang.format("$1$", [ticks]);
        } else if (isRest) {
            // Intervals view resting: ONLY the rest interval count fills the screen.
            bigCountValue = ticks;
            noDot = true;
        } else if (isSwim) {
            // Intervals view while swimming: swim chrono big.
            bigHotTxt = chronoTxt;
        } else {
            // Intervals view ready: the swim chrono at 0:00, ready to go,
            // with a small reminder of the rest interval below.
            // A TEXT font is required here: stock number fonts have no letters.
            bigHotTxt = chronoTxt;
            medTxt = Lang.format(WatchUi.loadResource(Rez.Strings.HintInterval), [Settings.getIntervalSec()]);
            medFont = Graphics.FONT_MEDIUM;
        }

        var timeY = h * 47 / 100;
        var th = dc.getFontHeight(Graphics.FONT_NUMBER_HOT);
        var mh = dc.getFontHeight(medFont);
        var dotR = h * 45 / 1000;
        var gap = h * 4 / 100;
        // Vertical extent of the big element (custom digits or hot font).
        var bigH = bigCountValue >= 0 ? bigDigitsHeight(dc, w, h, bigCountValue) : th;

        // Layout: with a medium row -> classic two-row layout around 47%.
        // Without -> centered stack; while resting ONLY the big number shows.
        var dotY = 0;
        var bigY = 0;
        var medY = -1;
        if (medTxt != "") {
            bigY = timeY;
            dotY = bigY - bigH / 2 - gap - dotR;
            medY = bigY + bigH / 2 + gap + mh / 2;
        } else if (noDot) {
            bigY = h / 2 - h * 2 / 100;
        } else {
            var blockH = dotR * 2 + gap + bigH;
            var blockTop = (h - blockH) / 2 - h * 2 / 100;
            dotY = blockTop + dotR;
            bigY = blockTop + dotR * 2 + gap + bigH / 2;
        }

        // Status dot: ring = ready, filled = swimming, half disc = resting.
        if (noDot) {
            // Resting: count only, nothing else on screen.
        } else if (isSwim) {
            dc.setColor(statusColor, Graphics.COLOR_BLACK);
            dc.fillCircle(w / 2, dotY, dotR);
        } else if (isRest) {
            dc.setColor(statusColor, Graphics.COLOR_BLACK);
            var pts = [];
            var n = 16;
            for (var i = 0; i <= n; i++) {
                var a = (-90 + i * 180 / n) * 0.0174533;
                pts.add([w / 2 + (dotR * Math.cos(a)).toNumber(), dotY + (dotR * Math.sin(a)).toNumber()]);
            }
            dc.fillPolygon(pts as Lang.Array<Graphics.Point2D>);
        } else {
            dc.setColor(statusColor, Graphics.COLOR_BLACK);
            dc.setPenWidth(2);
            dc.drawCircle(w / 2, dotY, dotR);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        if (bigCountValue >= 0) {
            drawBigCount(dc, w, bigY, bigCountValue, h);
        } else {
            dc.drawText(w / 2, bigY, Graphics.FONT_NUMBER_HOT, bigHotTxt, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (medTxt != "") {
            dc.drawText(w / 2, medY, medFont, medTxt, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Build tag on the ready screen: confirms which build is on the
        // watch (tiny gray text, diagnostic only).
        if (phase == StopwatchView.PHASE_READY) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            dc.drawText(w / 2, h * 95 / 100, Graphics.FONT_TINY, StopwatchView.BUILD_TAG, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        // Auto mode was requested but the sensor failed: say so, or the
        // silent manual fallback is indistinguishable from a broken feature.
        if (sensorFailed && Settings.getAutoMode() == Settings.AUTO_ON && phase != StopwatchView.PHASE_READY) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            dc.drawText(w / 2, h * 5 / 100, Graphics.FONT_TINY, "auto off", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        try {
            drawButtonHints(dc, w, h);
        } catch (e) {
        }
    }

    function hintPoint(cx as Lang.Number, cy as Lang.Number, d as Lang.Number, deg as Lang.Number) as Lang.Array<Lang.Number> {
        var rad = deg * 0.0174533;
        return [cx + (d * Math.cos(rad)).toNumber(), cy + (d * Math.sin(rad)).toNumber()];
    }

    function drawButtonHints(dc as Graphics.Dc, w as Lang.Number, h as Lang.Number) as Void {
        var cx = w / 2;
        var cy = h / 2;
        var r = (w < h ? w : h) / 2;
        var d = r * 85 / 100;
        var gs = w * 50 / 1000;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);

        var p = hintPoint(cx, cy, d, -30);
        var x = p[0];
        var y = p[1];
        if (phase == StopwatchView.PHASE_SWIM) {
            // Two bars: press to interrupt the swim and start resting.
            dc.fillRectangle(x - gs / 2, y - gs / 2, gs / 3, gs);
            dc.fillRectangle(x + gs / 6, y - gs / 2, gs / 3, gs);
        } else {
            // Triangle: press to swim.
            dc.fillPolygon([[x - gs / 2, y - gs / 2], [x + gs / 2, y], [x - gs / 2, y + gs / 2]] as Lang.Array<Graphics.Point2D>);
        }

        var dots = [176, 180, 184];
        for (var i = 0; i < dots.size(); i++) {
            p = hintPoint(cx, cy, d, dots[i]);
            dc.fillCircle(p[0], p[1], gs / 6 > 2 ? gs / 6 : 2);
        }

        p = hintPoint(cx, cy, d, 150);
        x = p[0];
        y = p[1];
        var rr = gs / 2;
        var prevX = x + (rr * Math.cos(20 * 0.0174533)).toNumber();
        var prevY = y + (rr * Math.sin(20 * 0.0174533)).toNumber();
        for (var i = 1; i <= 32; i++) {
            var a = (20 + i * 10) * 0.0174533;
            var sx = x + (rr * Math.cos(a)).toNumber();
            var sy = y + (rr * Math.sin(a)).toNumber();
            dc.drawLine(prevX, prevY, sx, sy);
            prevX = sx;
            prevY = sy;
        }
        var tipA = 340 * 0.0174533;
        var ex = x + (rr * Math.cos(tipA)).toNumber();
        var ey = y + (rr * Math.sin(tipA)).toNumber();
        var tx = (-Math.sin(tipA)).toNumber();
        var ty = (Math.cos(tipA)).toNumber();
        var nx = (Math.cos(tipA)).toNumber();
        var ny = (Math.sin(tipA)).toNumber();
        var tipX = ex + (rr * 9 / 10) * tx;
        var tipY = ey + (rr * 9 / 10) * ty;
        var b1x = ex - (rr / 10) * tx + (rr * 11 / 20) * nx;
        var b1y = ey - (rr / 10) * ty + (rr * 11 / 20) * ny;
        var b2x = ex - (rr / 10) * tx - (rr * 11 / 20) * nx;
        var b2y = ey - (rr / 10) * ty - (rr * 11 / 20) * ny;
        dc.fillPolygon([[tipX, tipY], [b1x, b1y], [b2x, b2y]] as Lang.Array<Graphics.Point2D>);
    }
}
