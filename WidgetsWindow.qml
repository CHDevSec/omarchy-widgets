import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// The desktop layer for one screen: transparent, on the Bottom layer (over
// the wallpaper, under windows), never taking the keyboard, and taking the
// pointer only over the cards.
PanelWindow {
  id: win

  required property var service
  required property var stats

  color: "transparent"
  WlrLayershell.namespace: "omarchy-widgets"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  // Inside the area the bar and dock leave free.
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  mask: Region {
    Region { item: clock }
    Region { item: calendar }
    Region { item: system }
  }

  readonly property int edge: Style.space(28)
  readonly property int gap: Style.space(16)

  Item {
    id: desk
    anchors.fill: parent

    // Default layout: a column at the top right, like macOS's.
    ClockWidget {
      id: clock
      service: win.service
      screenName: win.screen ? win.screen.name : ""
      defaultX: desk.width - width - win.edge
      defaultY: win.edge
    }

    CalendarWidget {
      id: calendar
      service: win.service
      screenName: win.screen ? win.screen.name : ""
      defaultX: desk.width - width - win.edge
      defaultY: win.edge + clock.height + win.gap
    }

    SystemWidget {
      id: system
      service: win.service
      stats: win.stats
      screenName: win.screen ? win.screen.name : ""
      defaultX: desk.width - width - win.edge
      defaultY: win.edge + clock.height + win.gap + calendar.height + win.gap
    }
  }
}
