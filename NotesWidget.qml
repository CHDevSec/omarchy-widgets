import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Quick notes and to-dos from notes.md. Click a to-do to tick it.
Card {
  id: card
  widgetId: "notes"
  contentWidth: Style.space(280)

  required property var notes
  readonly property int maxShown: 10
  readonly property int openCount: {
    var n = 0
    for (var i = 0; i < notes.items.length; i++) if (notes.items[i].todo && !notes.items[i].done) n++
    return n
  }
  readonly property bool anyDone: {
    for (var i = 0; i < notes.items.length; i++) if (notes.items[i].done) return true
    return false
  }

  Item {
    width: parent.width
    height: header.implicitHeight
    PanelSectionHeader {
      id: header
      text: "NOTES" + (card.openCount > 0 ? "  ·  " + card.openCount + " OPEN" : "")
      foreground: card.fg
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Text {
    visible: card.notes.items.length === 0
    width: parent.width
    text: "Nothing here. Add lines to ~/.local/share/omarchy-widgets/notes.md"
    wrapMode: Text.Wrap
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    textFormat: Text.PlainText
  }

  Repeater {
    model: card.notes.items.slice(0, card.maxShown)

    Item {
      id: row
      required property var modelData
      width: parent.width
      height: Math.max(mark.implicitHeight, label.implicitHeight) + Style.spacing.xs

      Text {
        id: mark
        text: row.modelData.todo ? (row.modelData.done ? "󰄵" : "󰄱") : "•"
        color: row.modelData.done ? card.dim : (rowMouse.containsMouse ? Commons.Color.accent : card.fg)
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        width: Style.font.body * 1.6
      }

      Text {
        id: label
        anchors.left: mark.right
        anchors.right: parent.right
        text: row.modelData.text
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        color: row.modelData.done ? card.dim : card.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.strikeout: row.modelData.done
        textFormat: Text.PlainText
      }

      MouseArea {
        id: rowMouse
        anchors.fill: parent
        enabled: row.modelData.todo
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.notes.toggle(row.modelData)
      }
    }
  }

  Text {
    visible: card.notes.items.length > card.maxShown
    text: "+" + (card.notes.items.length - card.maxShown) + " more"
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Button {
    visible: card.anyDone
    text: "Clear done"
    bordered: true
    foreground: card.fg
    fontSize: Style.font.caption
    onClicked: card.notes.clearDone()
  }
}
