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
    var tickTimer as Timer.Timer or Null = null;
    var uiTimer as Timer.Timer or Null = null;
    var intervalMs = 0;
    var nextTickAt = 0;
    var remainingTickMs = 0;

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
            remainingTickMs = nextTickAt - now;
            if (remainingTickMs < 0) {
                remainingTickMs = 0;
            }
            stopAllTimers();
        } else {
            running = true;
            paused = false;
            startMs = now;
            intervalMs = Settings.getIntervalSec() * 1000;
            if (paused && remainingTickMs > 0) {
                nextTickAt = now + remainingTickMs;
                armTick(remainingTickMs);
            } else {
                nextTickAt = now + intervalMs;
                armTick(intervalMs);
            }
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
        nextTickAt = 0;
        remainingTickMs = 0;
        WatchUi.requestUpdate();
    }

    function stopAllTimers() as Void {
        if (tickTimer != null) {
            tickTimer.stop();
        }
        if (uiTimer != null) {
            uiTimer.stop();
        }
    }

    function armTick(delayMs as Lang.Number) as Void {
        if (tickTimer == null) {
            tickTimer = new Timer.Timer();
        }
        tickTimer.stop();
        tickTimer.start(method(:onTick), delayMs, false);
    }

    function startUiTimer() as Void {
        if (uiTimer == null) {
            uiTimer = new Timer.Timer();
        }
        uiTimer.stop();
        uiTimer.start(method(:onUiTick), 1000, true);
    }

    function onTick() as Void {
        ticks += 1;
        Alert.tick(Settings.getAlertMode());
        var now = System.getTimer();
        nextTickAt = now + intervalMs;
        if (running) {
            armTick(intervalMs);
        }
        WatchUi.requestUpdate();
    }

    function onUiTick() as Void {
        var iv = Settings.getIntervalSec() * 1000;
        if (running && iv != intervalMs) {
            intervalMs = iv;
            nextTickAt = System.getTimer() + iv;
            armTick(iv);
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
    }
}
