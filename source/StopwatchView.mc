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
    var timer as Timer.Timer or Null = null;
    var timerIntervalSec = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function startPause() as Void {
        if (running) {
            elapsedMs += System.getTimer() - startMs;
            running = false;
            paused = true;
            stopTimer();
        } else {
            running = true;
            paused = false;
            startMs = System.getTimer();
            startTimer(Settings.getIntervalSec());
        }
        WatchUi.requestUpdate();
    }

    function reset() as Void {
        stopTimer();
        running = false;
        paused = false;
        elapsedMs = 0;
        ticks = 0;
        startMs = 0;
        WatchUi.requestUpdate();
    }

    function stopTimer() as Void {
        if (timer != null) {
            timer.stop();
        }
    }

    function startTimer(intervalSec as Lang.Number) as Void {
        stopTimer();
        timer = new Timer.Timer();
        timerIntervalSec = intervalSec;
        timer.start(method(:onTick), intervalSec * 1000, true);
    }

    function onTick() as Void {
        ticks += 1;
        Alert.tick(Settings.getAlertMode());
        var intervalSec = Settings.getIntervalSec();
        if (running && intervalSec != timerIntervalSec) {
            startTimer(intervalSec);
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
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        var status = "READY";
        if (running) {
            status = "RUNNING";
        } else if (paused) {
            status = "PAUSED";
        }
        dc.drawText(w / 2, h * 16 / 100, Graphics.FONT_MEDIUM, status, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, h * 40 / 100, Graphics.FONT_NUMBER_HOT, formatTime(getElapsedMs()), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, h * 64 / 100, Graphics.FONT_LARGE, Lang.format("TICKS $1$", [ticks]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, h * 78 / 100, Graphics.FONT_SMALL, Lang.format("Every $1$s - $2$", [Settings.getIntervalSec(), Settings.alertModeLabel(Settings.getAlertMode())]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, h * 88 / 100, Graphics.FONT_TINY, "START start/pause - UP reset", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 95 / 100, Graphics.FONT_TINY, "DOWN settings - tap screen", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
