import Toybox.WatchUi;

class StopwatchDelegate extends WatchUi.BehaviorDelegate {
    var view as StopwatchView;

    function initialize(v as StopwatchView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            view.startPause();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            view.reset();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            WatchUi.pushView(makeSettingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        view.startPause();
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(makeSettingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() as Boolean {
        view.stopTimer();
        return false;
    }
}
