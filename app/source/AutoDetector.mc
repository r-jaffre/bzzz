import Toybox.Lang;
import Toybox.Math;

// Classifies accelerometer batches into "moving" vs "quiet" and keeps the
// continuous duration of the current class, so the stopwatch can:
//   - declare a REST after `stillSec` of quiet time during a swim phase
//   - declare a new SWIM after sustained motion during a rest phase
//
// Motion metric: mean over each sample of
//   |x - gx| + |y - gy| + |z - gz|   (milli-G)
// where gx/gy/gz is a slow low-pass estimate of gravity (EMA, time
// constant ~1 s at 10 Hz), i.e. high-passed activity. Kicking or
// stroking produces hundreds of milli-G; floating or holding a wall
// produces a few tens at most.
class AutoDetector {
    static const MOVE_ONSET_MS = 3000;

    var sampleRate = 10;
    var thresholdMG = 50;
    var stillMs = 0;
    var moveMs = 0;
    var gx as Float = 0.0;
    var gy as Float = 0.0;
    var gz as Float = 0.0;
    var gravityInit = false;

    function initialize(rate as Lang.Number, thresh as Lang.Number) {
        sampleRate = rate;
        thresholdMG = thresh;
    }

    function reset() as Void {
        stillMs = 0;
        moveMs = 0;
        gravityInit = false;
    }

    // Feed one batch of accelerometer samples (milli-G arrays).
    // Returns true if the batch is classified as "moving".
    function ingest(xArr as Lang.Array<Lang.Number>, yArr as Lang.Array<Lang.Number>, zArr as Lang.Array<Lang.Number>) as Lang.Boolean {
        var n = xArr.size() as Lang.Number;
        if (n <= 0) {
            return false;
        }
        var acc = 0.0;
        for (var i = 0; i < n; i++) {
            var x = xArr[i] as Float;
            var y = yArr[i] as Float;
            var z = zArr[i] as Float;
            if (!gravityInit) {
                gx = x;
                gy = y;
                gz = z;
                gravityInit = true;
            } else {
                gx = gx * 9 / 10 + x / 10;
                gy = gy * 9 / 10 + y / 10;
                gz = gz * 9 / 10 + z / 10;
            }
            acc += Math.abs(x - gx) + Math.abs(y - gy) + Math.abs(z - gz);
        }
        var meanMG = acc / n;
        var moving = meanMG > thresholdMG;
        var dtMs = n * 1000 / sampleRate;
        if (moving) {
            moveMs += dtMs;
            stillMs = 0;
        } else {
            stillMs += dtMs;
            moveMs = 0;
        }
        return moving;
    }
}
