import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The week, in two parts side by side:
//   left   today, like a desk calendar: the date large, then today's
//          events as a list (what's on now, what's next and how soon)
//   right  the week grid: a column per day (Monday first), hours down the
//          side, events as blocks in their colours, the time as a red line
// Stretch it (corner grip) and the grid's hours grow to fill the height.
// Click an event to join its Meet, or open it in Google Calendar.
Card {
  id: card
  widgetId: "week"
  defaultWidth: Style.space(880)

  required property var agenda

  property date now: new Date()
  Timer {
    interval: 30000
    running: card.live
    repeat: true
    triggeredOnStart: true
    onTriggered: card.now = new Date()
  }

  readonly property color accent: Commons.Color.accent

  // ---------------------------------------------------------------- data
  readonly property date today: new Date(now.getFullYear(), now.getMonth(), now.getDate())
  readonly property date monday: {
    var d = new Date(today)
    d.setDate(d.getDate() - (d.getDay() + 6) % 7)
    return d
  }
  readonly property var days: {
    var out = []
    for (var i = 0; i < 7; i++) out.push(new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i))
    return out
  }
  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  }
  function dayIndex(d) {
    return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - monday) / 86400000)
  }
  readonly property var weekEvents: {
    var end = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 7)
    return agenda.events.filter(function(e) { return !e.allDay && e.end > monday && e.start < end })
  }
  readonly property var todayEvents: weekEvents.filter(function(e) { return sameDay(e.start, now) })
  readonly property var next: {
    for (var i = 0; i < todayEvents.length; i++) if (todayEvents[i].end > now) return todayEvents[i]
    return null
  }

  // Colour: the event's Google colour mapped onto the theme; events without
  // one get a colour from their title, so different things look different.
  readonly property var tints: [pal.blue, pal.magenta, pal.green, pal.yellow, pal.cyan, pal.red]
  function tintFor(e) {
    var m = { "1": pal.blue, "2": pal.green, "3": pal.magenta, "4": pal.red, "5": pal.yellow, "6": pal.yellow,
              "7": pal.cyan, "8": pal.grey, "9": pal.blue, "10": pal.green, "11": pal.red }
    if (m[e.color]) return m[e.color]
    var h = 0, t = e.title.replace(/\s*-.*$/, "")
    for (var i = 0; i < t.length; i++) h = (h * 31 + t.charCodeAt(i)) % 1009
    return tints[h % tints.length]
  }
  function open(e) {
    if (e.meet) Qt.openUrlExternally(e.meet)
    else if (e.url) Quickshell.execDetached(["omarchy-launch-webapp", e.url])
  }
  function hm(d) { return Qt.formatTime(d, "HH:mm") }
  function until(d) {
    var m = Math.round((d - now) / 60000)
    if (m < 60) return m + " MIN"
    return Math.floor(m / 60) + "H" + (m % 60 ? ("0" + m % 60).slice(-2) : "")
  }

  // Hours: from the earliest event to the latest this week, at least 8–18.
  readonly property int firstHour: {
    var h = 8
    for (var i = 0; i < weekEvents.length; i++) h = Math.min(h, weekEvents[i].start.getHours())
    return Math.max(0, h)
  }
  readonly property int lastHour: {
    var h = 18
    for (var i = 0; i < weekEvents.length; i++) {
      var e = weekEvents[i]
      h = Math.max(h, sameDay(e.start, e.end) ? e.end.getHours() + (e.end.getMinutes() > 0 ? 1 : 0) : 24)
    }
    return Math.min(24, h)
  }
  readonly property int hours: lastHour - firstHour

  // ------------------------------------------------------------- layout
  readonly property real gap: Style.spacing.xxl
  readonly property real sideWidth: Math.round(Math.max(Style.space(200), contentWidth * 0.26))
  readonly property real gridWidth: contentWidth - sideWidth - gap - 1
  readonly property real gutter: Style.space(34)
  readonly property real dayWidth: (gridWidth - gutter) / 7
  // Grid height: what the stretch leaves, else 22 px an hour.
  readonly property real headsHeight: heads.height + Style.spacing.sm
  readonly property real hourHeight: stretchHeight > 0
    ? Math.max(Style.space(14), (stretchHeight - headsHeight) / Math.max(1, hours))
    : Style.space(22)

  Row {
    width: parent.width
    spacing: card.gap

    // ======================================================== today side
    Column {
      id: side
      width: card.sideWidth
      spacing: Style.spacing.md

      Text {
        text: card.now.toLocaleDateString(Qt.locale(), "dddd").toUpperCase()
        color: card.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 2
        textFormat: Text.PlainText
      }
      Row {
        spacing: Style.spacing.md
        Text {
          id: bigDay
          text: card.now.getDate()
          color: card.fg
          font.family: Style.font.family
          font.pixelSize: Math.round(Style.font.displayLarge * 1.9)
          font.bold: true
          lineHeight: 0.85
        }
        Column {
          anchors.bottom: bigDay.bottom
          anchors.bottomMargin: Style.space(6)
          Text {
            text: card.now.toLocaleDateString(Qt.locale(), "MMMM").toUpperCase()
            color: card.fg
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            textFormat: Text.PlainText
          }
          Text {
            text: card.todayEvents.length === 0 ? "LIVRE HOJE"
              : card.todayEvents.length + (card.todayEvents.length === 1 ? " EVENTO" : " EVENTOS")
            color: card.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }

      // What's on now / next, as a solid block in its colour.
      Rectangle {
        visible: card.next !== null
        width: parent.width
        height: nextBody.implicitHeight + Style.spacing.md * 2
        radius: Style.cornerRadius
        readonly property bool live: card.next !== null && card.next.start <= card.now
        readonly property color tint: card.next ? card.tintFor(card.next) : card.fg
        color: live ? tint : Qt.rgba(tint.r, tint.g, tint.b, 0.16)
        border.width: 1
        border.color: tint
        Column {
          id: nextBody
          x: Style.spacing.md
          y: Style.spacing.md
          width: parent.width - Style.spacing.md * 2
          spacing: Style.spacing.xxs
          readonly property color ink: parent.live ? Commons.Color.background : card.fg
          Text {
            text: !card.next ? "" : parent.parent.live
              ? "AGORA  ·  ATÉ " + card.hm(card.next.end)
              : "EM " + card.until(card.next.start) + "  ·  " + card.hm(card.next.start)
            color: parent.parent.live ? Commons.Color.background : parent.parent.tint
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            width: parent.width
            text: card.next ? card.next.title : ""
            color: nextBody.ink
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
          }
          Text {
            visible: card.next !== null && card.next.meet !== ""
            text: "󰍫  ENTRAR NO MEET"
            color: nextBody.ink
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (card.next) card.open(card.next)
        }
      }

      // The rest of today.
      Repeater {
        model: card.todayEvents.filter(function(e) { return e !== card.next })
        Item {
          id: item
          required property var modelData
          readonly property bool past: modelData.end <= card.now
          width: side.width
          height: Math.max(itTime.implicitHeight, itTitle.implicitHeight) + Style.spacing.xs * 2
          opacity: past ? 0.4 : 1
          Rectangle {
            y: Style.spacing.xs
            width: 3
            height: parent.height - Style.spacing.xs * 2
            color: card.tintFor(item.modelData)
          }
          Text {
            id: itTime
            x: 3 + Style.spacing.md
            y: Style.spacing.xs
            text: card.hm(item.modelData.start)
            color: card.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            id: itTitle
            x: itTime.x + Style.space(42)
            y: Style.spacing.xs
            width: parent.width - x
            text: item.modelData.title
            color: card.fg
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.strikeout: item.past
            elide: Text.ElideRight
            textFormat: Text.PlainText
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: card.open(item.modelData)
          }
        }
      }

      Text {
        visible: !card.agenda.loaded
        width: parent.width
        wrapMode: Text.Wrap
        text: "Sem agenda ainda. Peça ao Claude: \"atualiza a agenda\"."
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    // A thin divider between the two halves.
    Rectangle {
      width: 1
      height: Math.max(side.height, weekGrid.height)
      color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.12)
    }

    // ========================================================= week grid
    Column {
      id: weekGrid
      width: card.gridWidth
      spacing: Style.spacing.sm

      // Day heads: weekday over the date; today as a solid block.
      Row {
        id: heads
        x: card.gutter
        Repeater {
          model: card.days
          Item {
            id: head
            required property var modelData
            required property int index
            readonly property bool isToday: card.sameDay(modelData, card.now)
            width: card.dayWidth
            height: headCol.implicitHeight
            Rectangle {
              anchors.fill: parent
              anchors.margins: 1
              radius: Style.cornerRadius
              color: head.isToday ? card.accent : "transparent"
            }
            Column {
              id: headCol
              anchors.horizontalCenter: parent.horizontalCenter
              topPadding: Style.spacing.xs
              bottomPadding: Style.spacing.xs
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: head.modelData.toLocaleDateString(Qt.locale(), "ddd").toUpperCase().replace(".", "")
                color: head.isToday ? Commons.Color.background : (head.index >= 5 ? Qt.darker(card.dim, 1.25) : card.dim)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: head.modelData.getDate()
                color: head.isToday ? Commons.Color.background : card.fg
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }
            }
          }
        }
      }

      Item {
        id: grid
        width: parent.width
        height: card.hours * card.hourHeight
        clip: true

        // Columns: past days dimmed, weekends shaded, thin dividers.
        Repeater {
          model: 7
          Rectangle {
            required property int index
            x: card.gutter + index * card.dayWidth
            width: card.dayWidth
            height: grid.height
            color: index >= 5 ? Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.03) : "transparent"
            Rectangle { width: 1; height: parent.height; color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.07) }
          }
        }

        // Hour lines; a label on every other hour so it stays quiet.
        Repeater {
          model: card.hours
          Item {
            required property int index
            y: index * card.hourHeight
            width: grid.width
            Rectangle {
              x: card.gutter
              width: parent.width - card.gutter
              height: 1
              color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, (card.firstHour + index) % 2 === 0 ? 0.09 : 0.04)
            }
            Text {
              visible: (card.firstHour + index) % 2 === 0 || card.hourHeight >= Style.space(26)
              y: -Math.round(implicitHeight / 2)
              width: card.gutter - Style.spacing.sm
              horizontalAlignment: Text.AlignRight
              text: ("0" + (card.firstHour + index)).slice(-2)
              color: card.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        // Events.
        Repeater {
          model: card.weekEvents
          Rectangle {
            id: ev
            required property var modelData
            readonly property int day: card.dayIndex(modelData.start)
            readonly property real startH: modelData.start.getHours() + modelData.start.getMinutes() / 60
            readonly property real endH: card.sameDay(modelData.start, modelData.end)
              ? modelData.end.getHours() + modelData.end.getMinutes() / 60 : 24
            readonly property color tint: card.tintFor(modelData)
            readonly property bool past: modelData.end <= card.now
            readonly property bool live: modelData.start <= card.now && modelData.end > card.now
            readonly property bool roomy: height >= Style.font.caption * 2.6
            visible: day >= 0 && day < 7
            x: card.gutter + day * card.dayWidth + 2
            y: (startH - card.firstHour) * card.hourHeight + 1
            width: card.dayWidth - 4
            height: Math.max(Style.space(8), (endH - startH) * card.hourHeight - 2)
            radius: Math.min(Style.cornerRadius, 3)
            color: live ? tint : Qt.rgba(tint.r, tint.g, tint.b, evMouse.containsMouse ? 0.34 : 0.2)
            opacity: past ? 0.4 : 1
            clip: true

            Rectangle { width: 3; height: parent.height; color: ev.tint; visible: !ev.live }

            Column {
              x: 3 + Style.spacing.sm
              y: ev.roomy ? Style.space(3) : (ev.height - implicitHeight) / 2
              width: ev.width - x - Style.spacing.xs
              Text {
                width: parent.width
                visible: ev.height >= Style.font.caption
                text: ev.modelData.title
                color: ev.live ? Commons.Color.background : card.fg
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                elide: Text.ElideRight
                wrapMode: ev.height > Style.font.caption * 4 ? Text.Wrap : Text.NoWrap
                maximumLineCount: Math.max(1, Math.floor((ev.height - Style.font.caption * 1.6) / (Style.font.caption * 1.3)))
                textFormat: Text.PlainText
              }
              Text {
                visible: ev.roomy
                text: card.hm(ev.modelData.start) + (ev.modelData.meet ? "  󰍫" : "")
                color: ev.live ? Commons.Color.background : card.dim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }

            MouseArea {
              id: evMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: card.open(ev.modelData)
            }
          }
        }

        // Now: a red line across today with the time on the side.
        Item {
          readonly property real h: card.now.getHours() + card.now.getMinutes() / 60
          visible: h >= card.firstHour && h <= card.lastHour
          y: Math.round((h - card.firstHour) * card.hourHeight)
          width: grid.width
          Rectangle {
            x: card.gutter + card.dayIndex(card.now) * card.dayWidth
            y: -1
            width: card.dayWidth
            height: 2
            color: card.pal.red
          }
          Rectangle {
            x: 0
            y: -Math.round(height / 2)
            width: card.gutter - Style.spacing.xs
            height: nowText.implicitHeight + 2
            radius: 2
            color: card.pal.red
            Text {
              id: nowText
              anchors.centerIn: parent
              text: card.hm(card.now)
              color: Commons.Color.background
              font.family: Style.font.family
              font.pixelSize: Math.round(Style.font.caption * 0.9)
              font.bold: true
            }
          }
        }
      }
    }
  }
}
