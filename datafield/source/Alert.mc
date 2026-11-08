import Toybox.Attention;
import Toybox.Lang;

class Alert {
    static function tick(mode as Lang.Number, power as Lang.Number) as Void {
        if (mode == Settings.ALERT_SOUND || mode == Settings.ALERT_BOTH) {
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_LOUD_BEEP);
            }
        }
        if (mode == Settings.ALERT_VIBRATE || mode == Settings.ALERT_BOTH) {
            if (Attention has :vibrate) {
                var len = 100 + power * 40;
                Attention.vibrate([new Attention.VibeProfile(100, len)]);
            }
        }
    }

    static function testSound() as Void {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
    }

    static function confirm() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 60),
                new Attention.VibeProfile(0, 70),
                new Attention.VibeProfile(100, 60)
            ]);
        }
    }

    static function resetBuzz() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 250)]);
        }
    }
}
