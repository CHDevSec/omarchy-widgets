import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons

// The desktop layer for one screen: transparent, on the Bottom layer (over
// the wallpaper, under windows), never taking the keyboard, and taking the
// pointer only over the cards.
PanelWindow {
  id: win

  required property var service
  required property var stats
  required property var notes
  required property var trello
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
    Region { item: trelloCard.visible ? trelloCard : null }
  }

  readonly property int edge: Style.space(28)
  readonly property int gap: Style.space(16)

  function below(cards) {
    var y = edge
    for (var i = 0; i < cards.length; i++) if (cards[i].shown) y += cards[i].height + gap
    return y
  }

  Item {
    id: desk
    anchors.fill: parent

    readonly property var cards: [clock, calendar, system, notesCard, weatherCard, mediaCard, worldCard, trelloCard]
    // The card being dragged and where it would land; null when none.
    property var moving: null
    property var target: null

    // Where a card at (x, y) lands: on another widget's edge or centre, or
    // the screen margin, when one is near (a guide line shows it); else on
    // the grid. Left or right edge, whichever grid line is closer.
    function landing(c) {
      var g = win.service.gridSize, m = win.edge, W = width, H = height
      var near = Math.max(8, g * 0.5)
      var xs = [{ v: m, line: m }, { v: W - c.width - m, line: W - m }]
      var ys = [{ v: m, line: m }, { v: H - c.height - m, line: H - m }]
      for (var i = 0; i < cards.length; i++) {
        var o = cards[i]
        if (o === c || !o.visible) continue
        xs.push({ v: o.x, line: o.x }, { v: o.x + o.width - c.width, line: o.x + o.width },
                { v: o.x + (o.width - c.width) / 2, line: o.x + o.width / 2 },
                { v: o.x + o.width + win.gap, line: o.x + o.width + win.gap },
                { v: o.x - c.width - win.gap, line: o.x - win.gap })
        ys.push({ v: o.y, line: o.y }, { v: o.y + o.height - c.height, line: o.y + o.height },
                { v: o.y + o.height + win.gap, line: o.y + o.height + win.gap },
                { v: o.y - c.height - win.gap, line: o.y - win.gap })
      }
      function pick(list, at) {
        var best = null
        for (var j = 0; j < list.length; j++) {
          var d = Math.abs(list[j].v - at)
          if (d <= near && (!best || d < best.d)) best = { v: list[j].v, line: list[j].line, d: d }
        }
        return best
      }
      function grid(at, size, span) {
        var left = m + Math.round((at - m) / g) * g
        var right = m + Math.round((at + size - m) / g) * g - size
        var v = Math.abs(left - at) <= Math.abs(right - at) ? left : right
        return Math.max(0, Math.min(v, span - size))
      }
      var gx = pick(xs, c.x), gy = pick(ys, c.y)
      return {
        x: Math.round(Math.max(0, Math.min(gx ? gx.v : grid(c.x, c.width, W), W - c.width))),
        y: Math.round(Math.max(0, Math.min(gy ? gy.v : grid(c.y, c.height, H), H - c.height))),
        lineX: gx ? gx.line : -1,
        lineY: gy ? gy.line : -1,
        w: c.width,
        h: c.height
      }
    }

    function cardMoved(c) {
      if (!win.service.snap) return
      for (var i = 0; i < cards.length; i++) cards[i].z = cards[i] === c ? 2 : 0
      moving = c
      target = landing(c)
    }
    function cardReleased(c) {
      var t = win.service.snap ? landing(c) : null
      moving = null
      target = null
      return t
    }

    // ------------------------------------------------ guides while dragging
    Item {
      id: guides
      anchors.fill: parent
      visible: desk.moving !== null
      readonly property color accent: Commons.Color.accent
      readonly property color fg: Commons.Color.popups.text

      // Square dots on every grid point, drawn once each time it shows.
      Canvas {
        id: gridDots
        anchors.fill: parent
        visible: parent.visible
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var g = win.service.gridSize, m = win.edge, s = 2
          ctx.fillStyle = Qt.rgba(guides.fg.r, guides.fg.g, guides.fg.b, 0.28)
          for (var x = m; x <= width - m; x += g)
            for (var y = m; y <= height - m; y += g)
              ctx.fillRect(Math.round(x) - 1, Math.round(y) - 1, s, s)
          // Every fourth line a little stronger, to judge distances.
          ctx.fillStyle = Qt.rgba(guides.fg.r, guides.fg.g, guides.fg.b, 0.5)
          for (var x2 = m; x2 <= width - m; x2 += g * 4)
            for (var y2 = m; y2 <= height - m; y2 += g * 4)
              ctx.fillRect(Math.round(x2) - 2, Math.round(y2) - 2, 4, 4)
        }
      }

      // Where the card will land.
      Rectangle {
        visible: desk.target !== null
        x: desk.target ? desk.target.x : 0
        y: desk.target ? desk.target.y : 0
        width: desk.target ? desk.target.w : 0
        height: desk.target ? desk.target.h : 0
        radius: Style.cornerRadius
        color: Qt.rgba(guides.accent.r, guides.accent.g, guides.accent.b, 0.10)
        border.width: 2
        border.color: guides.accent
      }

      // Lined up with another widget or the margin.
      Rectangle {
        visible: desk.target !== null && desk.target.lineX >= 0
        x: desk.target ? Math.round(desk.target.lineX) : 0
        width: 1
        height: parent.height
        color: guides.accent
      }
      Rectangle {
        visible: desk.target !== null && desk.target.lineY >= 0
        y: desk.target ? Math.round(desk.target.lineY) : 0
        height: 1
        width: parent.width
        color: guides.accent
      }
    }

    // Default layout: a column at the top right, like macOS's, and notes
    // at the top left.
    ClockWidget {
      id: clock
      service: win.service
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.edge
    }

    CalendarWidget {
      id: calendar
      service: win.service
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.below([clock])
    }

    SystemWidget {
      id: system
      service: win.service
      stats: win.stats
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.below([clock, calendar])
    }

    NotesWidget {
      id: notesCard
      service: win.service
      notes: win.notes
      screenName: win.screenName
      defaultX: win.edge
      defaultY: win.edge
    }

    WeatherWidget {
      id: weatherCard
      service: win.service
      weather: win.weather
      screenName: win.screenName
      defaultX: win.edge
      defaultY: win.below([notesCard])
    }

    MediaWidget {
      id: mediaCard
      service: win.service
      screenName: win.screenName
      defaultX: win.edge
      defaultY: win.below([notesCard, weatherCard])
    }

    WorldClockWidget {
      id: worldCard
      service: win.service
      world: win.world
      screenName: win.screenName
      defaultX: desk.width - width - win.edge
      defaultY: win.below([clock, calendar, system])
    }
  
    TrelloWidget {
      id: trelloCard
      service: win.service
      trello: win.trello
      screenName: win.screenName
      defaultX: win.edge + notesCard.width + win.gap
      defaultY: win.edge
    }
  }
}
