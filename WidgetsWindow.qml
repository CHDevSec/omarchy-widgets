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
  required property var notes
  required property var weather
  required property var world

  readonly property string screenName: screen ? screen.name : ""

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
    Region { item: clock.visible ? clock : null }
    Region { item: calendar.visible ? calendar : null }
    Region { item: system.visible ? system : null }
    Region { item: notesCard.visible ? notesCard : null }
    Region { item: weatherCard.visible ? weatherCard : null }
    Region { item: mediaCard.visible ? mediaCard : null }
    Region { item: worldCard.visible ? worldCard : null }
  }

  readonly property int edge: Style.space(28)
  readonly property int gap: Style.space(16)

  function below(cards) {
    var y = edge
    for (var i = 0; i < cards.length; i++) if (cards[i].visible) y += cards[i].height + gap
    return y
  }

  Item {
    id: desk
    anchors.fill: parent

    // Default layout: a column at the top right, like macOS's, and notes
    // at the top left.
    ClockWidget {
      id: clock
      visible: win.service.widgetOn("clock")
      service: win.service
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.edge
    }

    CalendarWidget {
      id: calendar
      visible: win.service.widgetOn("calendar")
      service: win.service
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.below([clock])
    }

    SystemWidget {
      id: system
      visible: win.service.widgetOn("system")
      service: win.service
      stats: win.stats
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.below([clock, calendar])
    }

    NotesWidget {
      id: notesCard
      visible: win.service.widgetOn("notes")
      service: win.service
      notes: win.notes
      screenName: win.screenName
      defaultX: win.edge
      defaultY: win.edge
    }

    WeatherWidget {
      id: weatherCard
      visible: win.service.widgetOn("weather")
      service: win.service
      weather: win.weather
      screenName: win.screenName
      defaultX: win.edge
      defaultY: win.below([notesCard])
    }

    MediaWidget {
      id: mediaCard
      visible: win.service.widgetOn("media")
      service: win.service
      screenName: win.screenName
      defaultX: win.edge
      defaultY: win.below([notesCard, weatherCard])
    }

    WorldClockWidget {
      id: worldCard
      visible: win.service.widgetOn("worldclock")
      service: win.service
      world: win.world
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.below([clock, calendar, system])
    }
  }
}
