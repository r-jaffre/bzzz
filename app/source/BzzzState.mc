import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;

class BzzzState {
    static var running = false;
    static var elapsedMs = 0;
    static var ticks = 0;
    static var savedAt = 0;

    static function nowElapsedMs() as Lang.Number {
        if (running) {
            return elapsedMs + (System.getTimer() - savedAt);
        }
        return elapsedMs;
    }

    static function save() as Void {
        savedAt = System.getTimer();
        Storage.setValue("bzzz", [running ? 1 : 0, elapsedMs, ticks, savedAt]);
    }

    static function load() as Void {
        var v = Storage.getValue("bzzz") as Lang.Array or Null;
        if (v != null) {
            running = v[0] == 1;
            elapsedMs = v[1] as Lang.Number;
            ticks = v[2] as Lang.Number;
            savedAt = v[3] as Lang.Number;
        }
    }

    static function formatTime(ms as Lang.Number) as Lang.String {
        var totalSec = ms / 1000;
        var minutes = totalSec / 60;
        var seconds = totalSec % 60;
        return Lang.format("$1$:$2$", [pad2(minutes), pad2(seconds)]);
    }

    static function pad2(n as Lang.Number) as Lang.String {
        if (n < 10) {
            return Lang.format("0$1$", [n]);
        }
        return Lang.format("$1$", [n]);
    }
}
