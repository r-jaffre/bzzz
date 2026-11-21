import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
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

    // START button: advance the phase cycle.
    function advancePhase() as Void {
        var now = System.getTimer();
        if (phase == StopwatchView.PHASE_SWIM) {
            // At the wall: enter the rest phase.
            phase = StopwatchView.PHASE_REST;
            phaseStartMs = now;
            ticks = 0;
            // Lock the interval for the whole rest phase so the buzz grid
            // never shifts mid-rest (settings changes apply next phase).
            intervalMs = Settings.getIntervalSec() * 1000;
            if (intervalMs <= 0) {
                intervalMs = Settings.DEFAULT_INTERVAL_SEC * 1000;
            }
            startUiTimer();
            // First buzz = rest starts (count stays 0 until a full interval).
            Alert.tick(Settings.getAlertMode(), Settings.getVibePower());
        } else {
            // Idle or leaving rest: new swim phase, everything from zero.
            phase = StopwatchView.PHASE_SWIM;
            phaseStartMs = now;
            ticks = 0;
            startUiTimer();
            Alert.confirm();
        }
        lastSec = -1;
        WatchUi.requestUpdate();
    }

    function reset() as Void {
        stopAllTimers();
        Alert.resetBuzz();
        lastSec = -1;
        phase = StopwatchView.PHASE_READY;
        phaseStartMs = 0;
        ticks = 0;
        intervalMs = Settings.DEFAULT_INTERVAL_SEC * 1000;
        WatchUi.requestUpdate();
    }

    function stopAllTimers() as Void {
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

    // 7-segment digit table: a b c d e f g (top, top-right, bottom-right,
    // bottom, bottom-left, top-left, middle), 1 = on.
    static const SEG_TABLE = [
        [1, 1, 1, 1, 1, 1, 0], // 0
        [0, 1, 1, 0, 0, 0, 0], // 1
        [1, 1, 0, 1, 1, 0, 1], // 2
        [1, 1, 1, 1, 0, 0, 1], // 3
        [0, 1, 1, 0, 0, 1, 1], // 4
        [1, 0, 1, 1, 0, 1, 1], // 5
        [1, 0, 1, 1, 1, 1, 1], // 6
        [1, 1, 1, 0, 0, 0, 0], // 7
        [1, 1, 1, 1, 1, 1, 1], // 8
        [1, 1, 1, 1, 0, 1, 1]  // 9
    ];

    // Height of the big digits for a given value (device width w, height h).
    function bigDigitsHeight(w as Lang.Number, h as Lang.Number, value as Lang.Number) as Lang.Number {
        var n = 1;
        var rem = value;
        while (rem >= 10) {
            n++;
            rem = rem / 10;
        }
        var gap = w * 3 / 100;
        var maxW = w * 82 / 100;
        var dw = (maxW - gap * (n - 1)) / n;
        var dh = dw * 2;
        if (dh > h * 60 / 100) {
            dh = h * 60 / 100;
        }
        return dh;
    }

    // Draw value as large scoreboard-style digits centered on cy.
    function drawBigCount(dc as Graphics.Dc, w as Lang.Number, cy as Lang.Number, value as Lang.Number, h as Lang.Number) as Void {
        var n = 1;
        var rem = value;
        while (rem >= 10) {
            n++;
            rem = rem / 10;
        }
        var gap = w * 3 / 100;
        var maxW = w * 82 / 100;
        var dw = (maxW - gap * (n - 1)) / n;
        var dh = dw * 2;
        if (dh > h * 60 / 100) {
            dh = h * 60 / 100;
            dw = dh / 2;
        }
        var th = dw * 30 / 100;  // segment thickness
        var totalW = dw * n + gap * (n - 1);
        var x0 = (w - totalW) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var pow = 1;
        for (var i = 1; i < n; i++) {
            pow = pow * 10;
        }
        for (var i = 0; i < n; i++) {
            // Extract digit i (most significant first).
            var digit = (value / pow) % 10;
            pow = pow / 10;
            var segs = StopwatchView.SEG_TABLE[digit];
            var dx = x0 + i * (dw + gap);
            var dy = cy - dh / 2;
            var inset = th / 2;
            var vLen = dh / 2 - th;
            var x1 = dx + dw - th;
            if (segs[0] == 1) {
                dc.fillRectangle(dx + inset, dy, dw - th, th);            // a: top
            }
            if (segs[1] == 1) {
                dc.fillRectangle(x1, dy + inset, th, vLen);               // b: top-right
            }
            if (segs[2] == 1) {
                dc.fillRectangle(x1, dy + dh / 2, th, vLen);              // c: bottom-right
            }
            if (segs[3] == 1) {
                dc.fillRectangle(dx + inset, dy + dh - th, dw - th, th);  // d: bottom
            }
            if (segs[4] == 1) {
                dc.fillRectangle(dx, dy + dh / 2, th, vLen);               // e: bottom-left
            }
            if (segs[5] == 1) {
                dc.fillRectangle(dx, dy + inset, th, vLen);                // f: top-left
            }
            if (segs[6] == 1) {
                dc.fillRectangle(dx + inset, dy + dh / 2 - inset, dw - th, th); // g: middle
            }
        }
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
        var bigCountValue = -1; // >= 0 -> drawn as huge scoreboard digits
        var medTxt = "";
        if (Settings.getViewMode() == Settings.VIEW_CHRONO) {
            // Classic view: phase chrono big, tick count below.
            bigHotTxt = chronoTxt;
            medTxt = Lang.format("$1$", [ticks]);
        } else if (isRest) {
            // Intervals view: rest interval count big, rest chrono below.
            bigCountValue = ticks;
            medTxt = chronoTxt;
        } else if (isSwim) {
            // Intervals view while swimming: swim chrono big.
            bigHotTxt = chronoTxt;
        } else {
            // Intervals view idle: a big 0.
            bigCountValue = 0;
        }

        var timeY = h * 47 / 100;
        var th = dc.getFontHeight(Graphics.FONT_NUMBER_HOT);
        var mh = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        var dotR = h * 45 / 1000;
        var gap = h * 4 / 100;
        // Vertical extent of the big element (custom digits or hot font).
        var bigH = bigCountValue >= 0 ? bigDigitsHeight(w, h, bigCountValue) : th;
        var dotY = timeY - bigH / 2 - gap - dotR;
        var ticksY = timeY + bigH / 2 + gap + mh / 2;

        // Status dot: ring = ready, filled = swimming, half disc = resting.
        if (isSwim) {
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
            drawBigCount(dc, w, timeY, bigCountValue, h);
        } else {
            dc.drawText(w / 2, timeY, Graphics.FONT_NUMBER_HOT, bigHotTxt, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (medTxt != "") {
            dc.drawText(w / 2, ticksY, Graphics.FONT_NUMBER_MEDIUM, medTxt, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
