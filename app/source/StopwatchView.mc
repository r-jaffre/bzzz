import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class StopwatchView extends WatchUi.View {
    var running = false;
    var paused = false;
    var startMs = 0;
    var elapsedMs = 0;
    var ticks = 0;
    var uiTimer as Timer.Timer or Null = null;
    var intervalMs = 0;
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

    function startPause() as Void {
        var now = System.getTimer();
        if (running) {
            elapsedMs += now - startMs;
            running = false;
            paused = true;
            stopAllTimers();
            Alert.confirm();
            lastSec = -1;
        } else {
            running = true;
            paused = false;
            startMs = now;
            intervalMs = Settings.getIntervalSec() * 1000;
            startUiTimer();
            Alert.confirm();
            lastSec = -1;
        }
        WatchUi.requestUpdate();
    }

    function reset() as Void {
        stopAllTimers();
        Alert.resetBuzz();
        lastSec = -1;
        running = false;
        paused = false;
        elapsedMs = 0;
        ticks = 0;
        startMs = 0;
        intervalMs = 0;
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
        var iv = Settings.getIntervalSec() * 1000;
        if (iv > 0) {
            intervalMs = iv;
        }
        if (intervalMs <= 0) {
            intervalMs = 15000;
        }
        var tickIndex = elapsed / intervalMs;
        if (tickIndex > ticks) {
            ticks = tickIndex;
            Alert.tick(Settings.getAlertMode(), Settings.getVibePower());
        }
        var sec = elapsed / 1000;
        if (sec != lastSec) {
            lastSec = sec;
            if (running && sec % 5 == 0) {
            }
            WatchUi.requestUpdate();
        }
    }

    function getElapsedMs() as Lang.Number {
        if (running) {
            return elapsedMs + (System.getTimer() - startMs);
        }
        return elapsedMs;
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

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        if (arcsBmp != null) {
            dc.drawBitmap(0, 0, arcsBmp);
        }

        var statusColor = Graphics.COLOR_WHITE;
        if (running) {
            statusColor = Graphics.COLOR_GREEN;
        } else if (paused) {
            statusColor = Graphics.COLOR_YELLOW;
        }
        var timeY = h * 47 / 100;
        var th = dc.getFontHeight(Graphics.FONT_NUMBER_HOT);
        var mh = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        var dotR = h * 45 / 1000;
        var gap = h * 4 / 100;
        var dotY = timeY - th / 2 - gap - dotR;
        var ticksY = timeY + th / 2 + gap + mh / 2;
        if (running) {
            dc.setColor(statusColor, Graphics.COLOR_BLACK);
            dc.fillCircle(w / 2, dotY, dotR);
        } else if (paused) {
            dc.setColor(statusColor, Graphics.COLOR_BLACK);
            dc.fillCircle(w / 2, dotY, dotR);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.fillCircle(w / 2 - dotR / 2, dotY, dotR / 2);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.fillCircle(w / 2 - dotR / 5, dotY, dotR * 9 / 20);
        } else {
            dc.setColor(statusColor, Graphics.COLOR_BLACK);
            dc.setPenWidth(2);
            dc.drawCircle(w / 2, dotY, dotR);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var txt = formatTime(getElapsedMs());
        dc.drawText(w / 2, timeY, Graphics.FONT_NUMBER_HOT, txt, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, ticksY, Graphics.FONT_NUMBER_MEDIUM, Lang.format("$1$", [ticks]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

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
        if (running) {
            dc.fillRectangle(x - gs / 2, y - gs / 2, gs / 3, gs);
            dc.fillRectangle(x + gs / 6, y - gs / 2, gs / 3, gs);
        } else {
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
