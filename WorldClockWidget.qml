import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// A row per city: name, how far from here, and the time there.
Card {
  id: card
  widgetId: "worldclock"
  contentWidth: Style.space(260)

  required property var world

  property date now: new Date()
  Timer {
    interval: 1000
    running: card.visible
    repeat: true
    onTriggered: card.now = new Date()
  }

  // Bound once on the card: city rows can be made before the palette is.
  readonly property color sun: pal.yellow
  readonly property color moon: pal.blue
  readonly property color tint: pal.cyan

  readonly property int hereOffset: -now.getTimezoneOffset()

  PanelSectionHeader { text: "WORLD CLOCK"; foreground: card.fg; color: card.tint }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Repeater {
    model: card.world.cities

    Item {
      id: row
      required property var modelData
      readonly property date there: card.world.timeIn(modelData, card.now)
      readonly property bool day: there.getHours() >= 6 && there.getHours() < 18
      readonly property int diff: Math.round((modelData.offsetMinutes - card.hereOffset) / 60)
      readonly property string dayHint: {
        var d = there.getDate() - card.now.getDate()
        return d > 0 || d < -20 ? "TOMORROW" : (d < 0 || d > 20 ? "YESTERDAY" : "TODAY")
      }
      width: parent.width
      height: Math.max(time.implicitHeight, names.implicitHeight)

      Column {
        id: names
        anchors.verticalCenter: parent.verticalCenter
        Text {
          text: row.modelData.name
          color: card.fg
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          textFormat: Text.PlainText
        }
        Text {
          text: row.dayHint + "  ·  " + (row.diff === 0 ? "SAME TIME" : (row.diff > 0 ? "+" : "") + row.diff + "H")
          color: card.dim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.md
        // Sun or moon, in the sky's colour.
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: row.day ? "󰖙" : "󰖔"
          color: row.day ? card.sun : card.moon
          font.family: Style.font.family
          font.pixelSize: Style.font.iconLarge
        }
      Text {
        id: time
        text: Qt.formatTime(row.there, "HH:mm")
        color: row.day ? card.fg : card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.display
        font.bold: true
      }
      }
    }
  }
}
