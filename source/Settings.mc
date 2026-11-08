import Toybox.Application.Properties;
import Toybox.Lang;

class Settings {
    static const ALERT_VIBRATE = 0;
    static const ALERT_SOUND = 1;
    static const ALERT_BOTH = 2;
    static const DEFAULT_INTERVAL_SEC = 15;

    static function getIntervalSec() as Number {
        var v = Properties.getValue("intervalSec");
        if (v == null) {
            return Settings.DEFAULT_INTERVAL_SEC;
        }
        return v as Number;
    }

    static function setIntervalSec(value as Number) as Void {
        Properties.setValue("intervalSec", value);
    }

    static function getAlertMode() as Number {
        var v = Properties.getValue("alertMode");
        if (v == null) {
            return Settings.ALERT_VIBRATE;
        }
        return v as Number;
    }

    static function setAlertMode(value as Number) as Void {
        Properties.setValue("alertMode", value);
    }

    static function intervals() as Array<Number> {
        return [5, 10, 15, 20, 30, 45, 60, 90, 120];
    }

    static function nextInterval(current as Number) as Number {
        var list = Settings.intervals();
        for (var i = 0; i < list.size(); i++) {
            if (list[i] > current) {
                return list[i];
            }
        }
        return list[0];
    }

    static function nextAlertMode(current as Number) as Number {
        return (current + 1) % 3;
    }

    static function alertModeLabel(mode as Number) as String {
        if (mode == Settings.ALERT_SOUND) {
            return "Sound";
        }
        if (mode == Settings.ALERT_BOTH) {
            return "Vibrate + sound";
        }
        return "Vibrate";
    }
}
