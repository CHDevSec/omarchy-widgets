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
  required property var agenda
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
    Region { x: clock.x; y: clock.y; width: clock.visible ? clock.vw : 0; height: clock.visible ? clock.vh : 0 }
    Region { x: calendar.x; y: calendar.y; width: calendar.visible ? calendar.vw : 0; height: calendar.visible ? calendar.vh : 0 }
    Region { x: system.x; y: system.y; width: system.visible ? system.vw : 0; height: system.visible ? system.vh : 0 }
    Region { x: notesCard.x; y: notesCard.y; width: notesCard.visible ? notesCard.vw : 0; height: notesCard.visible ? notesCard.vh : 0 }
    Region { x: weatherCard.x; y: weatherCard.y; width: weatherCard.visible ? weatherCard.vw : 0; height: weatherCard.visible ? weatherCard.vh : 0 }
    Region { x: mediaCard.x; y: mediaCard.y; width: mediaCard.visible ? mediaCard.vw : 0; height: mediaCard.visible ? mediaCard.vh : 0 }
    Region { x: worldCard.x; y: worldCard.y; width: worldCard.visible ? worldCard.vw : 0; height: worldCard.visible ? worldCard.vh : 0 }
    Region { x: weekCard.x; y: weekCard.y; width: weekCard.visible ? weekCard.vw : 0; height: weekCard.visible ? weekCard.vh : 0 }
    Region { x: trelloCard.x; y: trelloCard.y; width: trelloCard.visible ? trelloCard.vw : 0; height: trelloCard.visible ? trelloCard.vh : 0 }
  }

  // Same spacing as windows: gaps_out from the edges, 2 × gaps_in apart.
  readonly property int edge: service.gapsOut
  readonly property int gap: service.gapsIn * 2

  function below(cards) {
    var y = edge
    for (var i = 0; i < cards.length; i++) if (cards[i].shown) y += cards[i].vh + gap
    return y
  }

  Item {
    id: desk
    anchors.fill: parent

    // Cards stay inside this margin (the windows' gaps_out).
    readonly property int inset: win.edge

    readonly property var cards: [clock, calendar, system, notesCard, weatherCard, mediaCard, worldCard, trelloCard, weekCard]
    // The card being dragged and where it would land; null when none.
    property var moving: null
    property var target: null

    // Where a card at (x, y) lands: on another widget's edge or centre, or
    // the screen margin, when one is near (a guide line shows it); else on
    // the grid. Left or right edge, whichever grid line is closer.
    function landing(c) {
      var g = win.service.gridSize, m = win.edge, W = width, H = height
      var near = Math.max(8, g * 0.5)
      var xs = [{ v: m, line: m }, { v: W - c.vw - m, line: W - m }]
      var ys = [{ v: m, line: m }, { v: H - c.vh - m, line: H - m }]
      var others = cards.filter(function(o) { return o !== c && o.visible })

      // Margins other widgets keep from the screen's sides: offer the same
      // margin on every side (the clock 40 px from the right edge → this one
      // 40 px from the left), with the other widget's edge as a second guide.
      function margin(list, mg, size, span, refLine) {
        if (mg <= m + 1 || mg > span / 3) return
        var label = "MARGEM " + Math.round(mg)
        list.push({ v: mg, line: mg, ref: refLine, label: label },
                  { v: span - size - mg, line: span - mg, ref: refLine, label: label })
      }
      // Gaps between two widgets side by side: offer the same gap again.
      var gapsX = [], gapsY = []
      for (var a = 0; a < others.length; a++) for (var b = 0; b < others.length; b++) {
        var p = others[a], q = others[b]
        if (p === q) continue
        var overlapY = p.y < q.y + q.vh && q.y < p.y + p.vh
        var overlapX = p.x < q.x + q.vw && q.x < p.x + p.vw
        var gx0 = q.x - (p.x + p.vw), gy0 = q.y - (p.y + p.vh)
        if (overlapY && gx0 > win.gap + 1 && gx0 < W / 4) gapsX.push(gx0)
        if (overlapX && gy0 > win.gap + 1 && gy0 < H / 4) gapsY.push(gy0)
      }

      for (var i = 0; i < others.length; i++) {
        var o = others[i]
        xs.push({ v: o.x, line: o.x }, { v: o.x + o.vw - c.vw, line: o.x + o.vw },
                { v: o.x + (o.vw - c.vw) / 2, line: o.x + o.vw / 2 },
                { v: o.x + o.vw + win.gap, line: o.x + o.vw + win.gap },
                { v: o.x - c.vw - win.gap, line: o.x - win.gap })
        ys.push({ v: o.y, line: o.y }, { v: o.y + o.vh - c.vh, line: o.y + o.vh },
                { v: o.y + o.vh + win.gap, line: o.y + o.vh + win.gap },
                { v: o.y - c.vh - win.gap, line: o.y - win.gap })
        margin(xs, o.x, c.vw, W, o.x)
        margin(xs, W - o.x - o.vw, c.vw, W, o.x + o.vw)
        margin(ys, o.y, c.vh, H, o.y)
        margin(ys, H - o.y - o.vh, c.vh, H, o.y + o.vh)
        for (var k = 0; k < gapsX.length; k++)
          xs.push({ v: o.x + o.vw + gapsX[k], line: o.x + o.vw + gapsX[k], label: "ESPAÇO " + Math.round(gapsX[k]) },
                  { v: o.x - c.vw - gapsX[k], line: o.x - gapsX[k], label: "ESPAÇO " + Math.round(gapsX[k]) })
        for (var k2 = 0; k2 < gapsY.length; k2++)
          ys.push({ v: o.y + o.vh + gapsY[k2], line: o.y + o.vh + gapsY[k2], label: "ESPAÇO " + Math.round(gapsY[k2]) },
                  { v: o.y - c.vh - gapsY[k2], line: o.y - gapsY[k2], label: "ESPAÇO " + Math.round(gapsY[k2]) })
      }
      function pick(list, at) {
        var best = null
        for (var j = 0; j < list.length; j++) {
          var d = Math.abs(list[j].v - at)
          // Ties go to the labelled (margin / spacing) match.
          if (d <= near && (!best || d < best.d || (d === best.d && list[j].label && !best.label)))
            best = { v: list[j].v, line: list[j].line, ref: list[j].ref, label: list[j].label, d: d }
        }
        return best
      }
      function grid(at, size, span) {
        var left = m + Math.round((at - m) / g) * g
        var right = m + Math.round((at + size - m) / g) * g - size
        var v = Math.abs(left - at) <= Math.abs(right - at) ? left : right
        return Math.max(m, Math.min(v, span - size - m))
      }
      var gx = pick(xs, c.x), gy = pick(ys, c.y)
      var labels = []
      if (gx && gx.label) labels.push("↔ " + gx.label)
      if (gy && gy.label) labels.push("↕ " + gy.label)
      return {
        x: Math.round(Math.max(m, Math.min(gx ? gx.v : grid(c.x, c.vw, W), W - c.vw - m))),
        y: Math.round(Math.max(m, Math.min(gy ? gy.v : grid(c.y, c.vh, H), H - c.vh - m))),
        lineX: gx ? gx.line : -1,
        lineY: gy ? gy.line : -1,
        refX: gx && gx.ref !== undefined ? gx.ref : -1,
        refY: gy && gy.ref !== undefined ? gy.ref : -1,
        label: labels.join("   "),
        w: c.vw,
        h: c.vh
      }
    }

    // While a card is being stretched: its size snaps to another widget's
    // width or height (to make them match) and its edges to other widgets'
    // edges; the guide says which.
    function cardStretched(c, vw, vh) {
      if (!win.service.snap) { moving = null; target = null; return { w: vw, h: vh } }
      var near = Math.max(8, win.service.gridSize * 0.5)
      var bestW = null, bestH = null
      for (var i = 0; i < cards.length; i++) {
        var o = cards[i]
        if (o === c || !o.visible) continue
        var name = o.widgetId.charAt(0).toUpperCase() + o.widgetId.slice(1)
        var ws = [{ v: o.vw, label: "= " + name, line: c.x + o.vw },
                  { v: o.x + o.vw - c.x, label: "", line: o.x + o.vw },
                  { v: o.x - win.gap - c.x, label: "", line: o.x - win.gap }]
        var hs = [{ v: o.vh, label: "= " + name, line: c.y + o.vh },
                  { v: o.y + o.vh - c.y, label: "", line: o.y + o.vh },
                  { v: o.y - win.gap - c.y, label: "", line: o.y - win.gap }]
        for (var j = 0; j < 3; j++) {
          var dw = Math.abs(ws[j].v - vw)
          if (ws[j].v > 0 && dw <= near && (!bestW || dw < bestW.d)) bestW = { v: ws[j].v, d: dw, label: ws[j].label, line: ws[j].line }
          var dh = Math.abs(hs[j].v - vh)
          if (hs[j].v > 0 && dh <= near && (!bestH || dh < bestH.d)) bestH = { v: hs[j].v, d: dh, label: hs[j].label, line: hs[j].line }
        }
      }
      var w = bestW ? bestW.v : vw, h = bestH ? bestH.v : vh
      moving = c
      target = { x: c.x, y: c.y, w: w, h: h, lineX: bestW ? bestW.line : -1, lineY: bestH ? bestH.line : -1,
                 label: [bestW ? bestW.label : "", bestH ? bestH.label.replace("=", "↕ =") : ""].filter(function(t) { return t }).join("   ")
                   || Math.round(w) + " × " + Math.round(h) }
      return { w: w, h: h }
    }
    function cardStretchEnded() { moving = null; target = null }

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

        // While stretching: the size, or which widget it now matches.
        Rectangle {
          visible: desk.target !== null && desk.target.label !== undefined && desk.target.label !== ""
          anchors.right: parent.right
          anchors.top: parent.bottom
          anchors.topMargin: Style.spacing.xs
          width: sizeText.implicitWidth + Style.spacing.md * 2
          height: sizeText.implicitHeight + Style.spacing.xs * 2
          radius: Style.cornerRadius
          color: guides.accent
          Text {
            id: sizeText
            anchors.centerIn: parent
            text: desk.target && desk.target.label ? desk.target.label : ""
            color: Commons.Color.background
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }

      // Lined up with another widget or the margin.
      Rectangle {
        visible: desk.target !== null && desk.target.lineX >= 0
        x: desk.target ? Math.round(desk.target.lineX) : 0
        width: 1
        height: parent.height
        color: guides.accent
      }
      // The other widget's edge it mirrors, fainter.
      Rectangle {
        visible: desk.target !== null && desk.target.refX !== undefined && desk.target.refX >= 0
        x: desk.target && desk.target.refX !== undefined ? Math.round(desk.target.refX) : 0
        width: 1
        height: parent.height
        color: Qt.rgba(guides.accent.r, guides.accent.g, guides.accent.b, 0.45)
      }
      Rectangle {
        visible: desk.target !== null && desk.target.refY !== undefined && desk.target.refY >= 0
        y: desk.target && desk.target.refY !== undefined ? Math.round(desk.target.refY) : 0
        height: 1
        width: parent.width
        color: Qt.rgba(guides.accent.r, guides.accent.g, guides.accent.b, 0.45)
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
      defaultX: desk.width - vw - win.edge
      defaultY: win.edge
    }

    CalendarWidget {
      id: calendar
      service: win.service
      screenName: win.screenName
      defaultX: desk.width - vw - win.edge
      defaultY: win.below([clock])
    }

    SystemWidget {
      id: system
      service: win.service
      stats: win.stats
      screenName: win.screenName
      defaultX: desk.width - vw - win.edge
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
      defaultX: desk.width - vw - win.edge
      defaultY: win.below([clock, calendar, system])
    }
  
    TrelloWidget {
      id: trelloCard
      service: win.service
      trello: win.trello
      screenName: win.screenName
      defaultX: win.edge + notesCard.vw + win.gap
      defaultY: win.edge
    }
  
    // Wide, along the bottom, centred.
    WeekWidget {
      id: weekCard
      service: win.service
      agenda: win.agenda
      screenName: win.screenName
      defaultX: Math.round((desk.width - vw) / 2)
      defaultY: desk.height - vh - win.edge
    }
  }
}
