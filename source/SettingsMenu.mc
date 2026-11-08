import Toybox.Lang;
import Toybox.WatchUi;

function alertModeRes(mode as Lang.Number) as Lang.ResourceId {
    if (mode == Settings.ALERT_SOUND) {
        return Rez.Strings.AlertSound;
    }
    if (mode == Settings.ALERT_BOTH) {
        return Rez.Strings.AlertBoth;
    }
    return Rez.Strings.AlertVibrate;
}

function menuItemLabel(id as Lang.Symbol) as Lang.String {
    if (id == :interval) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuInterval), [Settings.getIntervalSec()]);
    } else if (id == :alert) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuAlert), [WatchUi.loadResource(alertModeRes(Settings.getAlertMode()))]);
    } else if (id == :power) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuPower), [Settings.getVibePower()]);
    }
    return WatchUi.loadResource(Rez.Strings.MenuBack);
}

function makeSettingsMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.AppName)});
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:interval), null, :interval, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:alert), null, :alert, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:power), null, :power, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:back), null, :back, null));
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
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:interval), null, :interval, null), 0);
        } else if (id == :alert) {
            Settings.setAlertMode(Settings.nextAlertMode(Settings.getAlertMode()));
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:alert), null, :alert, null), 1);
        } else if (id == :power) {
            Settings.setVibePower(Settings.nextVibePower(Settings.getVibePower()));
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:power), null, :power, null), 2);
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
