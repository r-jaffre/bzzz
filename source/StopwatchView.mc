import Toybox.Graphics;
import Toybox.Lang;
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

        drawButtonIcons(dc, w, h);
    }

    function drawButtonIcons(dc as Graphics.Dc, w as Lang.Number, h as Lang.Number) as Void {
        var cx = w / 2;
        var cy = h / 2;
        var r = (w < h ? w : h) / 2;
        var d = r * 78 / 100;
        var s = r * 9 / 100;
        var c = (d * 7071) / 10000;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.setPenWidth(2);

        var x = cx + c;
        var y = cy - c;
        if (running) {
            dc.fillRectangle(x - s / 2, y - s, s / 3, 2 * s);
            dc.fillRectangle(x + s / 6, y - s, s / 3, 2 * s);
        } else {
            dc.fillPolygon([[x - s / 2, y - s], [x + s, y], [x - s / 2, y + s]] as Lang.Array<Graphics.Point2D>);
        }

        x = cx - d;
        y = cy;
        dc.drawArc(x, y, s, Graphics.ARC_CLOCKWISE, 20, 340);
        var tipX = x + (s * 94) / 100;
        var tipY = y - (s * 34) / 100;
        var a = s / 2;
        var b = s / 3;
        dc.drawLine(tipX, tipY, tipX - (a * 34) / 100 + (b * 94) / 100, tipY - (a * 94) / 100 - (b * 34) / 100);
        dc.drawLine(tipX, tipY, tipX - (a * 34) / 100 - (b * 94) / 100, tipY - (a * 94) / 100 + (b * 34) / 100);

        var dots = [[-4226, 9063], [-7071, 7071], [-9063, 4226]];
        for (var i = 0; i < 3; i++) {
            var px = cx + (d * dots[i][0]) / 10000;
            var py = cy + (d * dots[i][1]) / 10000;
            var dr = s / 4;
            if (dr < 2) {
                dr = 2;
            }
            dc.fillCircle(px, py, dr);
        }
    }
}
