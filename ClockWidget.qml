import QtQuick
import qs.Commons
import qs.Ui

// The time, large, with the day beneath it.
Card {
  id: card
  widgetId: "clock"

  property date now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: card.now = new Date()
  }

  PanelSectionHeader {
    text: "CLOCK"
    foreground: card.fg
  }

  Text {
    text: Qt.formatTime(card.now, "HH:mm")
    color: card.fg
    font.family: Style.font.family
    font.pixelSize: Math.round(Style.font.displayLarge * 2.2)
    font.bold: true
    textFormat: Text.PlainText
  }

  Text {
    width: parent.width
    text: card.now.toLocaleDateString(Qt.locale(), "dddd · d MMMM yyyy").toUpperCase()
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 1.2
    elide: Text.ElideRight
    textFormat: Text.PlainText
  }
}
