import Toybox.Attention;

class Alert {
    static const VIBE_DUTY_CYCLE = 40;
    static const VIBE_LENGTH_MS = 150;

    static function tick(mode as Number) as Void {
        if (mode == Settings.ALERT_SOUND || mode == Settings.ALERT_BOTH) {
            if (Attention has :playTone) {
                Attention.playTone(Attention.TONE_KEY);
            }
        }
        if (mode == Settings.ALERT_VIBRATE || mode == Settings.ALERT_BOTH) {
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(Alert.VIBE_DUTY_CYCLE, Alert.VIBE_LENGTH_MS)]);
            }
        }
    }
}
