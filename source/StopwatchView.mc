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

        var p = hintPoint(cx, cy, d, -45);
        var x = p[0];
        var y = p[1];
        if (running) {
            dc.fillRectangle(x - gs / 2, y - gs / 2, gs / 3, gs);
            dc.fillRectangle(x + gs / 6, y - gs / 2, gs / 3, gs);
        } else {
            dc.fillPolygon([[x - gs / 2, y - gs / 2], [x + gs / 2, y], [x - gs / 2, y + gs / 2]] as Lang.Array<Graphics.Point2D>);
        }

        p = hintPoint(cx, cy, d, 45);
        x = p[0];
        y = p[1];
        dc.drawLine(x + gs / 2, y, x - gs / 2, y);
        dc.drawLine(x - gs / 2, y, x - gs / 2 + gs / 3, y - gs / 3);
        dc.drawLine(x - gs / 2, y, x - gs / 2 + gs / 3, y + gs / 3);

        p = hintPoint(cx, cy, d, 180);
        x = p[0];
        y = p[1];
        dc.drawArc(x, y, gs / 2, Graphics.ARC_CLOCKWISE, 20, 340);
        var tipX = x + (gs / 2 * 94) / 100;
        var tipY = y - (gs / 2 * 34) / 100;
        var a = gs / 4;
        var b = gs / 6;
        dc.drawLine(tipX, tipY, tipX - (a * 34) / 100 + (b * 94) / 100, tipY - (a * 94) / 100 - (b * 34) / 100);
        dc.drawLine(tipX, tipY, tipX - (a * 34) / 100 - (b * 94) / 100, tipY - (a * 94) / 100 + (b * 34) / 100);

        var dots = [125, 135, 145];
        for (var i = 0; i < dots.size(); i++) {
            p = hintPoint(cx, cy, d, dots[i]);
            dc.fillCircle(p[0], p[1], gs / 6 > 2 ? gs / 6 : 2);
        }
    }
}
