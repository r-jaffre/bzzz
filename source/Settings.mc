import Toybox.Application.Properties;
import Toybox.Lang;

class Settings {
    static const ALERT_VIBRATE = 0;
    static const ALERT_SOUND = 1;
    static const ALERT_BOTH = 2;
    static const DEFAULT_INTERVAL_SEC = 15;

    static function getIntervalSec() as Lang.Number {
        return Properties.getValue("intervalSec") as Lang.Number;
    }

    static function setIntervalSec(value as Lang.Number) as Void {
        Properties.setValue("intervalSec", value);
    }

    static function getAlertMode() as Lang.Number {
        return Properties.getValue("alertMode") as Lang.Number;
    }

    static function setAlertMode(value as Lang.Number) as Void {
        Properties.setValue("alertMode", value);
    }

    static function intervals() as Lang.Array<Lang.Number> {
        return [5, 10, 15, 20, 30, 45, 60, 90, 120];
    }

    static function nextInterval(current as Lang.Number) as Lang.Number {
        var list = Settings.intervals();
        for (var i = 0; i < list.size(); i++) {
            if (list[i] > current) {
                return list[i];
            }
        }
        return list[0];
    }

    static function nextAlertMode(current as Lang.Number) as Lang.Number {
        return (current + 1) % 3;
    }

    static function alertModeLabel(mode as Lang.Number) as Lang.String {
        if (mode == Settings.ALERT_SOUND) {
            return "Sound";
        }
        if (mode == Settings.ALERT_BOTH) {
            return "Vibrate + sound";
        }
        return "Vibrate";
    }
}
