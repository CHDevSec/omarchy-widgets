import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The whole week as one wide card, like a calendar app's week view: a
// column per day (Monday first), hours down the side, each event a block in
// its Google Calendar colour, today marked and the current time as a red
// line. Click an event to join its Meet, or open it in Calendar.
Card {
  id: card
  widgetId: "week"
  contentWidth: Style.space(760)

  required property var agenda

  property date now: new Date()
  Timer {
    interval: 60000
    running: card.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: card.now = new Date()
  }

  // Monday 00:00 of this week, and the seven days from it.
  readonly property date monday: {
    var d = new Date(now.getFullYear(), now.getMonth(), now.getDate())
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
  readonly property var weekEvents: {
    var end = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 7)
    return agenda.events.filter(function(e) { return e.end > monday && e.start < end })
  }

  // Hours shown: from the earliest event to the latest, at least 8–18.
  readonly property int firstHour: {
    var h = 8
    for (var i = 0; i < weekEvents.length; i++) if (!weekEvents[i].allDay) h = Math.min(h, weekEvents[i].start.getHours())
    return Math.max(0, h)
  }
  readonly property int lastHour: {
    var h = 18
    for (var i = 0; i < weekEvents.length; i++) {
      var e = weekEvents[i]
      if (!e.allDay) h = Math.max(h, e.end.getHours() + (e.end.getMinutes() > 0 ? 1 : 0))
    }
    return Math.min(24, h)
  }
  readonly property real hourHeight: Style.space(24)
  readonly property real gutter: Style.space(36)
  readonly property real dayWidth: (contentWidth - gutter) / 7

  // Google Calendar colour ids, mapped onto the theme's colours.
  function tintFor(id) {
    var m = { "1": pal.blue, "2": pal.green, "3": pal.magenta, "4": pal.red, "5": pal.yellow, "6": pal.yellow,
              "7": pal.cyan, "8": pal.grey, "9": pal.blue, "10": pal.green, "11": pal.red }
    return m[id] || pal.cyan
  }
  function open(e) {
    if (e.meet) Qt.openUrlExternally(e.meet)
    else if (e.url) Quickshell.execDetached(["omarchy-launch-webapp", e.url])
  }

  readonly property var next: {
    for (var i = 0; i < weekEvents.length; i++)
      if (!weekEvents[i].allDay && weekEvents[i].end > now) return weekEvents[i]
    return null
  }
  readonly property bool nextIsNow: next !== null && next.start <= now

  // ------------------------------------------------------------- header
  Item {
    width: parent.width
    height: Math.max(title.implicitHeight, nextPill.height)

    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.md
      PanelSectionHeader {
        id: title
        text: "SEMANA"
        foreground: card.fg
        color: card.pal.cyan
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: card.days[0].getDate() + "–" + card.days[6].getDate() + " "
          + card.days[6].toLocaleDateString(Qt.locale(), "MMM").toUpperCase().replace(".", "")
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    // What's next, and how soon; a solid block when it has started.
    Rectangle {
      id: nextPill
      visible: card.next !== null
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      readonly property color tint: card.next ? card.tintFor(card.next.color) : card.fg
      width: pillText.implicitWidth + Style.spacing.md * 2
      height: pillText.implicitHeight + Style.spacing.xs * 2
      radius: Style.cornerRadius
      color: card.nextIsNow ? tint : "transparent"
      border.width: 1
      border.color: tint
      Text {
        id: pillText
        anchors.centerIn: parent
        text: !card.next ? "" : (card.nextIsNow ? "AGORA  " : (card.sameDay(card.next.start, card.now)
            ? Qt.formatTime(card.next.start, "HH:mm") + "  " : card.next.start.toLocaleDateString(Qt.locale(), "ddd").toUpperCase() + " " + Qt.formatTime(card.next.start, "HH:mm") + "  "))
          + (card.next ? card.next.title : "") + (card.next && card.next.meet ? "  󰍫" : "")
        color: card.nextIsNow ? Commons.Color.background : parent.tint
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        elide: Text.ElideRight
        width: Math.min(implicitWidth, card.contentWidth * 0.5)
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (card.next) card.open(card.next)
      }
    }
  }

  Text {
    visible: !card.agenda.loaded
    width: parent.width
    text: "Ainda sem agenda. Peça ao Claude: \"atualiza a agenda\"."
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  // ---------------------------------------------------------- day heads
  Row {
    x: card.gutter
    Repeater {
      model: card.days
      Item {
        required property var modelData
        required property int index
        readonly property bool today: card.sameDay(modelData, card.now)
        width: card.dayWidth
        height: dayNum.height + Style.spacing.xs
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.spacing.sm
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.toLocaleDateString(Qt.locale(), "ddd").toUpperCase().replace(".", "")
            color: parent.parent.today ? card.pal.cyan : (index >= 5 ? Qt.darker(card.dim, 1.2) : card.dim)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Rectangle {
            id: dayNum
            width: Math.max(numText.implicitWidth + Style.spacing.sm * 2, height)
            height: numText.implicitHeight + Style.spacing.xxs * 2
            radius: Style.cornerRadius
            color: parent.parent.today ? card.pal.cyan : "transparent"
            Text {
              id: numText
              anchors.centerIn: parent
              text: modelData.getDate()
              color: parent.parent.parent.today ? Commons.Color.background : card.fg
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }
        }
      }
    }
  }

  // --------------------------------------------------------------- grid
  Item {
    id: grid
    width: parent.width
    height: (card.lastHour - card.firstHour) * card.hourHeight
    clip: true

    // Today's column, lightly filled; weekends a shade darker.
    Repeater {
      model: 7
      Rectangle {
        required property int index
        x: card.gutter + index * card.dayWidth
        width: card.dayWidth
        height: grid.height
        color: card.sameDay(card.days[index], card.now) ? Qt.rgba(card.pal.cyan.r, card.pal.cyan.g, card.pal.cyan.b, 0.07)
          : index >= 5 ? Qt.rgba(0, 0, 0, 0.12) : "transparent"
        Rectangle { width: 1; height: parent.height; color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.08) }
      }
    }

    // Hour lines and labels.
    Repeater {
      model: card.lastHour - card.firstHour
      Item {
        required property int index
        y: index * card.hourHeight
        width: grid.width
        height: card.hourHeight
        Rectangle {
          x: card.gutter
          width: parent.width - card.gutter
          height: 1
          color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.08)
        }
        Text {
          y: -Style.space(1)
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
      model: card.weekEvents.filter(function(e) { return !e.allDay })
      Rectangle {
        id: ev
        required property var modelData
        readonly property int day: Math.floor((new Date(modelData.start.getFullYear(), modelData.start.getMonth(), modelData.start.getDate()) - card.monday) / 86400000)
        readonly property real startH: modelData.start.getHours() + modelData.start.getMinutes() / 60
        readonly property real endH: card.sameDay(modelData.start, modelData.end)
          ? modelData.end.getHours() + modelData.end.getMinutes() / 60 : 24
        readonly property color tint: card.tintFor(modelData.color)
        readonly property bool past: modelData.end < card.now
        readonly property bool live: modelData.start <= card.now && modelData.end > card.now
        visible: day >= 0 && day < 7
        x: card.gutter + day * card.dayWidth + 2
        y: (startH - card.firstHour) * card.hourHeight + 1
        width: card.dayWidth - 4
        height: Math.max(Style.space(12), (endH - startH) * card.hourHeight - 2)
        radius: Math.min(Style.cornerRadius, 3)
        color: Qt.rgba(tint.r, tint.g, tint.b, live ? 0.4 : (evMouse.containsMouse ? 0.32 : 0.2))
        border.width: live ? 1 : 0
        border.color: tint
        opacity: past ? 0.45 : 1
        clip: true

        Rectangle { width: 3; height: parent.height; color: ev.tint }

        Column {
          x: 3 + Style.spacing.sm
          y: Style.space(2)
          width: parent.width - x - Style.spacing.xs
          Text {
            width: parent.width
            text: (ev.modelData.meet ? "󰍫 " : "") + ev.modelData.title
            color: card.fg
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            elide: Text.ElideRight
            wrapMode: ev.height > card.hourHeight * 1.4 ? Text.Wrap : Text.NoWrap
            maximumLineCount: 2
            textFormat: Text.PlainText
          }
          Text {
            visible: ev.height > card.hourHeight * 0.9
            text: Qt.formatTime(ev.modelData.start, "HH:mm") + "–" + Qt.formatTime(ev.modelData.end, "HH:mm")
            color: card.dim
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

    // Now: a red line over today's column, with a square at its start.
    Item {
      readonly property int day: Math.floor((new Date(card.now.getFullYear(), card.now.getMonth(), card.now.getDate()) - card.monday) / 86400000)
      readonly property real h: card.now.getHours() + card.now.getMinutes() / 60
      visible: h >= card.firstHour && h <= card.lastHour
      x: card.gutter + day * card.dayWidth
      y: (h - card.firstHour) * card.hourHeight
      width: card.dayWidth
      Rectangle { y: -1; width: parent.width; height: 2; color: card.pal.red }
      Rectangle { x: -3; y: -3; width: 6; height: 6; color: card.pal.red }
    }
  }
}
