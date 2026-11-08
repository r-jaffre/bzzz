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

    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new BzzzGlanceView()];
    }
}
