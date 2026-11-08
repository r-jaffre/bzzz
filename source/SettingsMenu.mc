import Toybox.Lang;
import Toybox.WatchUi;

function makeSettingsMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => "Bzzz"});
    menu.addItem(new WatchUi.MenuItem(Lang.format("Interval: $1$s", [Settings.getIntervalSec()]), null, :interval, null));
    menu.addItem(new WatchUi.MenuItem("Alert: " + Settings.alertModeLabel(Settings.getAlertMode()), null, :alert, null));
    menu.addItem(new WatchUi.MenuItem(Lang.format("Vibe power: $1$", [Settings.getVibePower()]), null, :power, null));
    menu.addItem(new WatchUi.MenuItem("Back", null, :back, null));
    return menu;
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var menu as WatchUi.Menu2;

    function initialize(m as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        menu = m;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :interval) {
            Settings.setIntervalSec(Settings.nextInterval(Settings.getIntervalSec()));
            menu.updateItem(new WatchUi.MenuItem(Lang.format("Interval: $1$s", [Settings.getIntervalSec()]), null, :interval, null), 0);
        } else if (id == :alert) {
            Settings.setAlertMode(Settings.nextAlertMode(Settings.getAlertMode()));
            menu.updateItem(new WatchUi.MenuItem("Alert: " + Settings.alertModeLabel(Settings.getAlertMode()), null, :alert, null), 1);
        } else if (id == :power) {
            Settings.setVibePower(Settings.nextVibePower(Settings.getVibePower()));
            menu.updateItem(new WatchUi.MenuItem(Lang.format("Vibe power: $1$", [Settings.getVibePower()]), null, :power, null), 2);
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
