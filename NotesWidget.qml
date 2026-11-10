import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Quick notes and to-dos from notes.md, as Omarchy list rows: square check
// boxes, hover fill, a remove button on hover. Click a to-do to tick it;
// "+" adds one (it opens a small input over your windows).
Card {
  id: card
  widgetId: "notes"
  defaultWidth: Style.space(300)

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

  component SquareButton: Rectangle {
    id: sb
    property string glyph
    signal activated()
    width: Style.spacing.controlHeight * 0.8
    height: width
    radius: Style.cornerRadius
    color: sbMouse.containsMouse ? Style.hoverFill : "transparent"
    border.width: 1
    border.color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, sbMouse.containsMouse ? 0.6 : 0.3)
    Text {
      anchors.centerIn: parent
      text: sb.glyph
      color: card.fg
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
    MouseArea {
      id: sbMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: sb.activated()
    }
  }

  // Header: title, how many are open, and add.
  Item {
    width: parent.width
    height: Math.max(header.implicitHeight, addButton.height)

    PanelSectionHeader {
      id: header
      anchors.verticalCenter: parent.verticalCenter
      text: "NOTES"
      foreground: card.fg
      color: card.pal.yellow
    }
    Text {
      anchors.left: header.right
      anchors.leftMargin: Style.spacing.md
      anchors.verticalCenter: parent.verticalCenter
      visible: card.openCount > 0
      text: card.openCount + " OPEN"
      color: card.pal.yellow
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
    SquareButton {
      id: addButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      glyph: "+"
      onActivated: {
        var p = card.mapToItem(card.parent, card.width, 0)
        card.service.openNoteInput(card.screenName, p.x - Style.space(340), p.y)
      }
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Text {
    visible: card.notes.items.length === 0
    width: parent.width
    text: "No notes. Press + to add one."
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    textFormat: Text.PlainText
  }

  Column {
    width: parent.width
    spacing: Style.spacing.xxs

    Repeater {
      model: card.notes.items.slice(0, card.maxShown)

      Rectangle {
        id: row
        required property var modelData
        readonly property bool hot: rowMouse.containsMouse || removeMouse.containsMouse
        width: parent.width
        height: Math.max(Style.spacing.popupRowHeight, label.implicitHeight + Style.spacing.md * 2)
        radius: Style.cornerRadius
        color: hot ? Style.hoverFill : "transparent"
        border.width: hot ? 1 : 0
        border.color: Style.hoverBorderColor

        // Square check box, or a square bullet for a plain note.
        Rectangle {
          id: box
          anchors.left: parent.left
          anchors.leftMargin: Style.spacing.md
          anchors.verticalCenter: parent.verticalCenter
          readonly property int side: Math.round(Style.font.body * 0.95)
          width: row.modelData.todo ? side : Math.round(side * 0.4)
          height: width
          radius: 0
          color: row.modelData.todo
            ? (row.modelData.done ? card.pal.green : "transparent")
            : card.dim
          border.width: row.modelData.todo ? 1 : 0
          border.color: row.modelData.done ? card.pal.green
            : Qt.rgba(card.fg.r, card.fg.g, card.fg.b, row.hot ? 0.9 : 0.5)
          Text {
            anchors.centerIn: parent
            visible: row.modelData.done
            text: "󰄬"
            color: Commons.Color.popups.background
            font.family: Style.font.family
            font.pixelSize: Math.round(box.side * 0.8)
          }
        }

        Text {
          id: label
          anchors.left: parent.left
          anchors.leftMargin: Style.spacing.md + Math.round(Style.font.body * 0.95) + Style.spacing.lg
          anchors.right: removeButton.left
          anchors.rightMargin: Style.spacing.sm
          anchors.verticalCenter: parent.verticalCenter
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
          hoverEnabled: true
          cursorShape: row.modelData.todo ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: card.notes.toggle(row.modelData)
        }

        // Remove, shown on hover.
        Text {
          id: removeButton
          anchors.right: parent.right
          anchors.rightMargin: Style.spacing.md
          anchors.verticalCenter: parent.verticalCenter
          opacity: row.hot ? 1 : 0
          text: "󰅖"
          color: removeMouse.containsMouse ? Commons.Color.urgent : card.dim
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          MouseArea {
            id: removeMouse
            anchors.fill: parent
            anchors.margins: -Style.spacing.xs
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.notes.remove(row.modelData)
          }
        }
      }
    }
  }

  Item {
    width: parent.width
    height: clearButton.visible || more.visible ? Math.max(clearButton.implicitHeight, more.implicitHeight) : 0
    visible: height > 0

    Text {
      id: more
      anchors.verticalCenter: parent.verticalCenter
      visible: card.notes.items.length > card.maxShown
      text: "+" + (card.notes.items.length - card.maxShown) + " MORE"
      color: card.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Button {
      id: clearButton
      anchors.right: parent.right
      visible: card.anyDone
      text: "Clear done"
      bordered: true
      foreground: card.fg
      fontSize: Style.font.caption
      onClicked: card.notes.clearDone()
    }
  }
}
