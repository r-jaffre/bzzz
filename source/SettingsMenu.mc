import Toybox.Lang;
import Toybox.WatchUi;

function makeSettingsMenu() as WatchUi.Menu {
    var menu = new WatchUi.Menu();
    menu.setTitle("Bzzz");
    menu.addItem(Lang.format("Interval: $1$s", [Settings.getIntervalSec()]), :interval);
    menu.addItem("Alert: " + Settings.alertModeLabel(Settings.getAlertMode()), :alert);
    menu.addItem("Back", :back);
    return menu;
}

class SettingsMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :interval) {
            Settings.setIntervalSec(Settings.nextInterval(Settings.getIntervalSec()));
            WatchUi.switchToView(makeSettingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (item == :alert) {
            Settings.setAlertMode(Settings.nextAlertMode(Settings.getAlertMode()));
            WatchUi.switchToView(makeSettingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.popView();
        }
    }

    function onDone() as Void {
        WatchUi.popView();
    }
}
