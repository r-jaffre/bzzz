import Toybox.Application.Properties;
import Toybox.Lang;

class Settings {
    static const ALERT_VIBRATE = 0;
    static const ALERT_SOUND = 1;
    static const ALERT_BOTH = 2;
    static const DEFAULT_INTERVAL_SEC = 15;
    static const VIEW_INTERVALS = 0;
    static const VIEW_CHRONO = 1;
    static const AUTO_OFF = 0;
    static const AUTO_ON = 1;
    static const SENS_HIGH = 1;
    static const SENS_MEDIUM = 2;
    static const SENS_LOW = 3;
    static const DEFAULT_STILL_SEC = 10;

    static function getIntervalSec() as Lang.Number {
        var v = Properties.getValue("intervalSec") as Lang.Number;
        return v > 0 ? v : Settings.DEFAULT_INTERVAL_SEC;
    }

    static function setIntervalSec(value as Lang.Number) as Void {
        Properties.setValue("intervalSec", value);
    }

    static function getAlertMode() as Lang.Number {
        var v = Properties.getValue("alertMode") as Lang.Number;
        if (v < 0) { return 0; }
        return v > 2 ? 2 : v;
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

    static function getVibePower() as Lang.Number {
        var v = Properties.getValue("vibePower") as Lang.Number;
        if (v < 1) { return 1; }
        return v > 5 ? 5 : v;
    }

    static function setVibePower(value as Lang.Number) as Void {
        Properties.setValue("vibePower", value);
    }

    static function nextVibePower(current as Lang.Number) as Lang.Number {
        return current >= 5 ? 1 : current + 1;
    }

    static function getViewMode() as Lang.Number {
        var v = Properties.getValue("viewMode") as Lang.Number;
        if (v != Settings.VIEW_INTERVALS && v != Settings.VIEW_CHRONO) {
            return Settings.VIEW_INTERVALS;
        }
        return v;
    }

    static function setViewMode(value as Lang.Number) as Void {
        Properties.setValue("viewMode", value);
    }

    static function nextViewMode(current as Lang.Number) as Lang.Number {
        return current == Settings.VIEW_INTERVALS ? Settings.VIEW_CHRONO : Settings.VIEW_INTERVALS;
    }

    static function getAutoMode() as Lang.Number {
        var v = Properties.getValue("autoMode") as Lang.Number;
        if (v != Settings.AUTO_OFF && v != Settings.AUTO_ON) {
            return Settings.AUTO_ON;
        }
        return v;
    }

    static function setAutoMode(value as Lang.Number) as Void {
        Properties.setValue("autoMode", value);
    }

    static function nextAutoMode(current as Lang.Number) as Lang.Number {
        return current == Settings.AUTO_ON ? Settings.AUTO_OFF : Settings.AUTO_ON;
    }

    static function getSensitivity() as Lang.Number {
        var v = Properties.getValue("sensitivity") as Lang.Number;
        if (v < Settings.SENS_HIGH || v > Settings.SENS_LOW) {
            return Settings.SENS_MEDIUM;
        }
        return v;
    }

    static function setSensitivity(value as Lang.Number) as Void {
        Properties.setValue("sensitivity", value);
    }

    static function nextSensitivity(current as Lang.Number) as Lang.Number {
        return current >= Settings.SENS_LOW ? Settings.SENS_HIGH : current + 1;
    }

    // Batch-mean motion threshold in milli-G for the current sensitivity.
    // High sensitivity = small movements count as swimming (lower threshold).
    static function getMotionThreshold() as Lang.Number {
        var s = Settings.getSensitivity();
        if (s == Settings.SENS_HIGH) {
            return 25;
        }
        if (s == Settings.SENS_LOW) {
            return 100;
        }
        return 50;
    }

    static function stillDelays() as Lang.Array<Lang.Number> {
        return [5, 10, 15];
    }

    static function getStillSec() as Lang.Number {
        var v = Properties.getValue("stillSec") as Lang.Number;
        var list = Settings.stillDelays();
        for (var i = 0; i < list.size(); i++) {
            if (list[i] == v) {
                return v;
            }
        }
        return Settings.DEFAULT_STILL_SEC;
    }

    static function setStillSec(value as Lang.Number) as Void {
        Properties.setValue("stillSec", value);
    }

    static function nextStillSec(current as Lang.Number) as Lang.Number {
        if (current <= 0) {
            return Settings.DEFAULT_STILL_SEC;
        }
        var list = Settings.stillDelays();
        for (var i = 0; i < list.size(); i++) {
            if (list[i] > current) {
                return list[i];
            }
        }
        return list[0];
    }

}
