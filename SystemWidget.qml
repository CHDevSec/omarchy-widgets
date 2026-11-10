import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// CPU, memory, disk and battery as Omarchy-style meters.
Card {
  id: card
  widgetId: "system"

  required property var stats

  PanelSectionHeader {
    text: "SYSTEM"
    foreground: card.fg
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  component Meter: Column {
    id: meter
    property string label
    property string detail
    property real value: 0
    property bool warn: value >= 0.9
    width: parent.width
    spacing: Style.spacing.xs

    Item {
      width: parent.width
      height: labelText.implicitHeight
      Text {
        id: labelText
        text: meter.label
        color: card.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        textFormat: Text.PlainText
      }
      Text {
        anchors.right: parent.right
        text: meter.detail
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        textFormat: Text.PlainText
      }
    }

    Rectangle {
      width: parent.width
      height: Style.space(6)
      radius: Style.cornerRadius > 0 ? height / 2 : 0
      color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.12)

      Rectangle {
        width: Math.max(0, Math.min(1, meter.value)) * parent.width
        height: parent.height
        radius: parent.radius
        color: meter.warn ? Commons.Color.urgent : card.fg
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
      }
    }
  }

  Meter {
    label: "CPU"
    value: card.stats.cpu
    detail: Math.round(card.stats.cpu * 100) + "%"
  }

  Meter {
    label: "MEMORY"
    value: card.stats.memory
    detail: card.stats.memoryUsedGiB.toFixed(1) + " / " + card.stats.memoryTotalGiB.toFixed(1) + " GiB"
  }

  Meter {
    label: "DISK"
    value: card.stats.disk
    detail: Math.round(card.stats.diskUsedGiB) + " / " + Math.round(card.stats.diskTotalGiB) + " GiB"
  }

  Meter {
    visible: card.stats.battery >= 0
    label: "BATTERY"
    value: card.stats.battery / 100
    warn: card.stats.battery >= 0 && card.stats.battery <= 15 && card.stats.batteryStatus !== "Charging"
    detail: card.stats.battery + "%" + (card.stats.batteryStatus === "Charging" ? " · charging"
      : card.stats.batteryStatus === "Full" ? " · full" : "")
  }
}
