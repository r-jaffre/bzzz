import Toybox.Lang;
import Toybox.Application;
import Toybox.WatchUi;

class BzzzApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new StopwatchView();
        return [view, new StopwatchDelegate(view)];
    }
}
