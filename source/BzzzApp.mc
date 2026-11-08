import Toybox.Application;
import Toybox.WatchUi;

class BzzzApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as Array<WatchUi.Views or WatchUi.InputDelegates> {
        var view = new StopwatchView();
        return [view, new StopwatchDelegate(view)] as Array<WatchUi.Views or WatchUi.InputDelegates>;
    }
}
