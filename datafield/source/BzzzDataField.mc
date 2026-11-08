import Toybox.Activity;
import Toybox.FitContributor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class BzzzDataField extends WatchUi.DataField {
    var timer as Timer.Timer or Null = null;
    var running = false;
    var startMs = 0;
    var elapsedMs = 0;
    var ticks = 0;
    var intervalMs = 15000;
    var lastSec = -1;
    var field as FitContributor.Field or Null = null;

    function initialize() {
        DataField.initialize();
        field = createField(WatchUi.loadResource(Rez.Strings.AppName), 0, FitContributor.DATA_TYPE_UINT16, {:mesg => "tics"});
        intervalMs = Settings.getIntervalSec() * 1000;
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = getBackgroundColor();
        dc.setColor(bg, bg);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var fg = bg == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fg, bg);
        dc.drawText(w / 2, h * 38 / 100, Graphics.FONT_NUMBER_MEDIUM, formatTime(getElapsedMs()), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 72 / 100, Graphics.FONT_LARGE, Lang.format("$1$", [ticks]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function compute(info as Activity.Info) as Void {
        if (field != null) {
            field.setData(ticks);
        }
    }

    function onTimerStart() as Void {
        startBuzz();
    }

    function onTimerResume() as Void {
        startBuzz();
    }

    function onTimerPause() as Void {
        elapsedMs += System.getTimer() - startMs;
        running = false;
        stopTimer();
        Alert.confirm();
        lastSec = -1;
        WatchUi.requestUpdate();
    }

    function onTimerStop() as Void {
        stopTimer();
        running = false;
    }

    function onTimerReset() as Void {
        stopTimer();
        running = false;
        elapsedMs = 0;
        ticks = 0;
        startMs = 0;
        lastSec = -1;
        Alert.resetBuzz();
        WatchUi.requestUpdate();
    }

    function startBuzz() as Void {
        running = true;
        startMs = System.getTimer();
        intervalMs = Settings.getIntervalSec() * 1000;
        if (timer == null) {
            timer = new Timer.Timer();
        }
        timer.stop();
        timer.start(method(:onTick), 250, true);
        Alert.confirm();
        lastSec = -1;
        WatchUi.requestUpdate();
    }

    function stopTimer() as Void {
        if (timer != null) {
            timer.stop();
        }
    }

    function onTick() as Void {
        var elapsed = getElapsedMs();
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
}
