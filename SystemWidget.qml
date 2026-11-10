import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// CPU, memory, disk and battery as four square tiles, each in its own
// theme colour (the way btop colours them): a big number, its label, and a
// block meter along the bottom. A tile turns the theme's red when it runs
// hot (90 %+) or the battery runs low.
Card {
  id: card
  widgetId: "system"

  required property var stats

  PanelSectionHeader {
    text: "SYSTEM"
    foreground: card.fg
  }

  component Tile: Rectangle {
    id: tile
    property string label
    property string detail
    property real value: 0
    property color tint: card.fg
    property bool warn: value >= 0.9
    readonly property color shown: warn ? card.pal.red : tint

    width: (card.contentWidth - Style.spacing.md) / 2
    height: tileBody.implicitHeight + Style.spacing.lg * 2
    radius: Style.cornerRadius
    color: Qt.rgba(shown.r, shown.g, shown.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(shown.r, shown.g, shown.b, 0.35)

    Column {
      id: tileBody
      x: Style.spacing.lg
      y: Style.spacing.lg
      width: parent.width - Style.spacing.lg * 2
      spacing: Style.spacing.xs

      Text {
        text: Math.round(tile.value * 100) + "%"
        color: tile.shown
        font.family: Style.font.family
        font.pixelSize: Style.font.display
        font.bold: true
      }
      Text {
        width: parent.width
        text: tile.label + (tile.detail ? "  ·  " + tile.detail : "")
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        elide: Text.ElideRight
        textFormat: Text.PlainText
      }
      // Ten square blocks, lit up to the value.
      Row {
        spacing: 2
        Repeater {
          model: 10
          Rectangle {
            width: (tileBody.width - 2 * 9) / 10
            height: Style.space(5)
            color: index < Math.round(tile.value * 10)
              ? tile.shown : Qt.rgba(tile.shown.r, tile.shown.g, tile.shown.b, 0.15)
          }
        }
      }
    }
  }

  Grid {
    columns: 2
    spacing: Style.spacing.md

    Tile {
      label: "CPU"
      value: card.stats.cpu
      tint: card.pal.blue
    }
    Tile {
      label: "MEM"
      detail: card.stats.memoryUsedGiB.toFixed(1) + "G"
      value: card.stats.memory
      tint: card.pal.magenta
    }
    Tile {
      label: "DISK"
      detail: Math.round(card.stats.diskUsedGiB) + "G"
      value: card.stats.disk
      tint: card.pal.cyan
    }
    Tile {
      visible: card.stats.battery >= 0
      label: card.stats.batteryStatus === "Charging" ? "BAT ⚡" : "BAT"
      value: Math.max(0, card.stats.battery) / 100
      tint: card.pal.green
      warn: card.stats.battery >= 0 && card.stats.battery <= 15 && card.stats.batteryStatus !== "Charging"
    }
  }
}
