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

function viewModeRes(mode as Lang.Number) as Lang.ResourceId {
    if (mode == Settings.VIEW_CHRONO) {
        return Rez.Strings.ViewChrono;
    }
    return Rez.Strings.ViewIntervals;
}

function autoModeRes(mode as Lang.Number) as Lang.ResourceId {
    if (mode == Settings.AUTO_OFF) {
        return Rez.Strings.ModeManual;
    }
    return Rez.Strings.ModeAuto;
}

function sensitivityRes(s as Lang.Number) as Lang.ResourceId {
    if (s == Settings.SENS_HIGH) {
        return Rez.Strings.SensHigh;
    }
    if (s == Settings.SENS_LOW) {
        return Rez.Strings.SensLow;
    }
    return Rez.Strings.SensMedium;
}

function menuItemLabel(id as Lang.Symbol) as Lang.String {
    if (id == :interval) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuInterval), [Settings.getIntervalSec()]);
    } else if (id == :alert) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuAlert), [WatchUi.loadResource(alertModeRes(Settings.getAlertMode()))]);
    } else if (id == :power) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuPower), [Settings.getVibePower()]);
    } else if (id == :view) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuView), [WatchUi.loadResource(viewModeRes(Settings.getViewMode()))]);
    } else if (id == :mode) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuMode), [WatchUi.loadResource(autoModeRes(Settings.getAutoMode()))]);
    } else if (id == :sens) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuSensitivity), [WatchUi.loadResource(sensitivityRes(Settings.getSensitivity()))]);
    } else if (id == :still) {
        return Lang.format(WatchUi.loadResource(Rez.Strings.MenuStillDelay), [Settings.getStillSec()]);
    }
    if (id == :test) {
        return WatchUi.loadResource(Rez.Strings.MenuTest);
    }
    return WatchUi.loadResource(Rez.Strings.MenuBack);
}

function makeSettingsMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.AppName)});
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:interval), null, :interval, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:alert), null, :alert, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:power), null, :power, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:view), null, :view, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:mode), null, :mode, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:sens), null, :sens, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:still), null, :still, null));
    menu.addItem(new WatchUi.MenuItem(menuItemLabel(:test), null, :test, null));
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
        } else if (id == :view) {
            Settings.setViewMode(Settings.nextViewMode(Settings.getViewMode()));
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:view), null, :view, null), 3);
        } else if (id == :mode) {
            Settings.setAutoMode(Settings.nextAutoMode(Settings.getAutoMode()));
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:mode), null, :mode, null), 4);
        } else if (id == :sens) {
            Settings.setSensitivity(Settings.nextSensitivity(Settings.getSensitivity()));
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:sens), null, :sens, null), 5);
        } else if (id == :still) {
            Settings.setStillSec(Settings.nextStillSec(Settings.getStillSec()));
            menu.updateItem(new WatchUi.MenuItem(menuItemLabel(:still), null, :still, null), 6);
        } else if (id == :test) {
            Alert.testSound();
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
