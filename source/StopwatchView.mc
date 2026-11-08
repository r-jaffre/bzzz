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

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
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
        } else {
            running = true;
            paused = false;
            startMs = now;
            intervalMs = Settings.getIntervalSec() * 1000;
            startUiTimer();
        }
        WatchUi.requestUpdate();
    }

    function reset() as Void {
        stopAllTimers();
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
        var tickIndex = elapsed / intervalMs;
        if (tickIndex > ticks) {
            ticks = tickIndex;
            Alert.tick(Settings.getAlertMode());
        }
        WatchUi.requestUpdate();
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

        var status = "READY";
        var statusColor = Graphics.COLOR_WHITE;
        if (running) {
            status = "RUNNING";
            statusColor = Graphics.COLOR_GREEN;
        } else if (paused) {
            status = "PAUSED";
            statusColor = Graphics.COLOR_YELLOW;
        }
        dc.setColor(statusColor, Graphics.COLOR_BLACK);
        dc.drawText(w / 2, h * 18 / 100, Graphics.FONT_MEDIUM, status, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(w / 2, h * 46 / 100, Graphics.FONT_NUMBER_HOT, formatTime(getElapsedMs()), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, h * 74 / 100, Graphics.FONT_LARGE, Lang.format("TICKS $1$", [ticks]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawButtonHints(dc, w, h);
    }

    function hintPoint(cx as Lang.Number, cy as Lang.Number, d as Lang.Number, deg as Lang.Number) as Lang.Array<Lang.Number> {
        var rad = deg * 0.0174533;
        return [cx + (d * Math.cos(rad)).toNumber(), cy + (d * Math.sin(rad)).toNumber()];
    }

    function drawButtonHints(dc as Graphics.Dc, w as Lang.Number, h as Lang.Number) as Void {
        var cx = w / 2;
        var cy = h / 2;
        var r = (w < h ? w : h) / 2;
        var d = r * 90 / 100;
        var gs = w * 50 / 1000;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);

        var p = hintPoint(cx, cy, d, -40);
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
            dc.fillCircle(p[0], p[1], gs / 8 > 1 ? gs / 8 : 1);
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
        var tipX = x + (rr * Math.cos(tipA)).toNumber();
        var tipY = y + (rr * Math.sin(tipA)).toNumber();
        var tx = (-Math.sin(tipA)).toNumber();
        var ty = (Math.cos(tipA)).toNumber();
        var nx = (Math.cos(tipA)).toNumber();
        var ny = (Math.sin(tipA)).toNumber();
        var a2 = (rr * 8) / 10;
        var b2 = (rr * 11) / 20;
        dc.fillPolygon([
            [tipX, tipY],
            [tipX - a2 * tx + b2 * nx, tipY - a2 * ty + b2 * ny],
            [tipX - a2 * tx - b2 * nx, tipY - a2 * ty - b2 * ny]
        ] as Lang.Array<Graphics.Point2D>);
    }
}
