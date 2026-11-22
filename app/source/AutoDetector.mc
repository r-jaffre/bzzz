import Toybox.Lang;
import Toybox.Math;

// Classifies accelerometer batches into "quiet" vs "moving" and keeps the
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
//
// Classification is a 3-zone hysteresis (NOT binary): hand tremor and
// water motion sit in a middle zone that must neither build "move"
// credit nor fully erase "still" credit, otherwise holding the watch
// in hand exits rest after a few seconds of micro-shakes.
//   quiet:   meanMG <= thresholdMG (rest ends ONLY on sustained motion)
//   strong:  meanMG >= thresholdMG * MOTION_FACTOR (real swimming)
//   middle:  in between (tremor, gentle drift)
// Counters leak instead of resetting to zero, so one noisy second
// costs a fraction of the accumulated credit:
//   - waiting for stillness (swim phase): quiet +dt, middle +dt/3,
//     strong -3dt (a push-off / wall turn almost resets it)
//   - waiting for motion (rest phase): strong +dt, quiet -dt,
//     middle -dt/2 - only sustained real swimming can cross
//     MOVE_ONSET_MS, never intermittent tremor.
class AutoDetector {
    // Sustained strong motion required to end a rest: 5s of consecutive
    // strong seconds (middle/quiet seconds bleed credit, so intermittent
    // hand motion can never accumulate this).
    static const MOVE_ONSET_MS = 5000;
    static const MOTION_FACTOR = 4;

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

    // Absolute value without Toybox.Math.abs (see ingest).
    static function absVal(v) {
        return v < 0 ? -v : v;
    }

    // Feed one batch of accelerometer samples (milli-G arrays).
    // Params are intentionally untyped: the platform may deliver
    // Array<Float> or Array<Number> and a declared type mismatch
    // throws at runtime on hardware.
    // Returns true if the batch is classified as "moving".
    function ingest(xArr, yArr, zArr) as Lang.Boolean {
        if (xArr == null || yArr == null || zArr == null) {
            return false;
        }
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
            // Math.abs is @since CIQ 6.0.3 and is NOT reliably present in
            // older device runtimes (hard "Symbol Not Found" VM abort on a
            // FR255 with CIQ 6.0.4 / FW 29.52 - it cannot be caught).
            // A plain conditional works on every firmware.
            acc += AutoDetector.absVal(x - gx) + AutoDetector.absVal(y - gy) + AutoDetector.absVal(z - gz);
        }
        var meanMG = acc / n;
        var dtMs = n * 1000 / sampleRate;
        if (meanMG >= thresholdMG * AutoDetector.MOTION_FACTOR) {
            // Sustained real motion (kicks, push-off).
            moveMs += dtMs;
            stillMs = stillMs > 3 * dtMs ? stillMs - 3 * dtMs : 0;
        } else if (meanMG <= thresholdMG) {
            // Clear quiet: build still credit, bleed move credit.
            stillMs += dtMs;
            moveMs = moveMs > dtMs ? moveMs - dtMs : 0;
        } else {
            // Middle zone (hand tremor, gentle drift): accrue stillness
            // slowly and bleed move credit, so micro-shakes can never
            // quickly end a rest but a wall-hold still gets there.
            stillMs += dtMs / 3;
            moveMs = moveMs > dtMs / 2 ? moveMs - dtMs / 2 : 0;
        }
        return meanMG >= thresholdMG * AutoDetector.MOTION_FACTOR;
    }
}
