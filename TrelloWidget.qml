import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Trello: what needs you, grouped the way you work — doing, waiting for
// your review, and the P0s still in the queue. Each board keeps one theme
// colour; click a card to open it in the browser.
Card {
  id: card
  widgetId: "trello"
  contentWidth: Style.space(320)

  required property var trello
  readonly property int maxPerSection: 4

  property date now: new Date()
  Timer {
    interval: 60000
    running: card.visible
    repeat: true
    onTriggered: card.now = new Date()
  }

  readonly property var sectionColors: ({ doing: pal.blue, review: pal.yellow, queue: pal.red })
  readonly property var boardPalette: [pal.cyan, pal.magenta, pal.green, pal.blue, pal.yellow, pal.red]
  function boardColor(name) {
    var h = 0
    for (var i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 997
    return boardPalette[h % boardPalette.length]
  }
  function ago(d) {
    var m = Math.max(0, Math.round((now - d) / 60000))
    if (m < 1) return "AGORA"
    if (m < 60) return m + " MIN"
    if (m < 60 * 24) return Math.round(m / 60) + " H"
    return Math.round(m / 1440) + " D"
  }

  // Header: title, how many need you, when Claude last looked.
  Item {
    width: parent.width
    height: head.implicitHeight
    PanelSectionHeader {
      id: head
      text: "TRELLO"
      foreground: card.fg
      color: card.pal.blue
    }
    Text {
      anchors.left: head.right
      anchors.leftMargin: Style.spacing.md
      anchors.verticalCenter: head.verticalCenter
      visible: card.trello.total > 0
      text: card.trello.total + " PRA VOCÊ"
      color: card.pal.blue
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
    Text {
      anchors.right: parent.right
      anchors.verticalCenter: head.verticalCenter
      visible: card.trello.loaded
      text: "󰚰 " + card.ago(card.trello.updated)
      color: card.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Text {
    visible: !card.trello.loaded
    width: parent.width
    wrapMode: Text.Wrap
    text: "Ainda sem dados. Peça ao Claude: \"atualiza o Trello\"."
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    textFormat: Text.PlainText
  }

  Repeater {
    model: card.trello.sections

    Column {
      id: section
      required property var modelData
      readonly property color tint: card.sectionColors[modelData.id] || card.fg
      visible: modelData.items.length > 0
      width: parent.width
      spacing: Style.spacing.xxs

      // Section title as a solid tag in its colour.
      Row {
        spacing: Style.spacing.md
        Rectangle {
          width: tag.implicitWidth + Style.spacing.md * 2
          height: tag.implicitHeight + Style.spacing.xxs * 2
          color: section.tint
          radius: Style.cornerRadius
          Text {
            id: tag
            anchors.centerIn: parent
            text: section.modelData.title
            color: Commons.Color.background
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: section.modelData.items.length
          color: section.tint
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      Repeater {
        model: section.modelData.items.slice(0, card.maxPerSection)

        Rectangle {
          id: row
          required property var modelData
          width: section.width
          height: rowBody.implicitHeight + Style.spacing.sm * 2
          radius: Style.cornerRadius
          color: rowMouse.containsMouse ? Style.hoverFill : "transparent"
          border.width: rowMouse.containsMouse ? 1 : 0
          border.color: Style.hoverBorderColor

          // The board's colour as a bar on the left.
          Rectangle {
            x: Style.spacing.sm
            y: Style.spacing.sm
            width: 3
            height: parent.height - Style.spacing.sm * 2
            color: card.boardColor(row.modelData.board)
          }

          Column {
            id: rowBody
            x: Style.spacing.sm + 3 + Style.spacing.md
            y: Style.spacing.sm
            width: parent.width - x - Style.spacing.sm
            Text {
              width: parent.width
              text: (row.modelData.prio ? row.modelData.prio + "  " : "") + row.modelData.name
              color: card.fg
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              textFormat: Text.PlainText
            }
            Text {
              width: parent.width
              text: row.modelData.board.toUpperCase()
              color: card.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              elide: Text.ElideRight
              textFormat: Text.PlainText
            }
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(row.modelData.url)
          }
        }
      }

      Text {
        visible: section.modelData.items.length > card.maxPerSection
        text: "+" + (section.modelData.items.length - card.maxPerSection) + " MAIS"
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }
}
