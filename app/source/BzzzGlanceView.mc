import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BzzzGlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        BzzzState.load();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var dotColor = Graphics.COLOR_WHITE;
        if (BzzzState.running) {
            dotColor = Graphics.COLOR_GREEN;
        }
        dc.setColor(dotColor, Graphics.COLOR_BLACK);
        dc.fillCircle(w * 16 / 100, h / 2, h * 9 / 100);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(w * 55 / 100, h * 35 / 100, Graphics.FONT_NUMBER_MEDIUM, BzzzState.formatTime(BzzzState.nowElapsedMs()), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w * 55 / 100, h * 72 / 100, Graphics.FONT_MEDIUM, Lang.format("$1$", [BzzzState.ticks]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
