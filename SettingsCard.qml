import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Settings, opened by right-clicking any widget (or
// `omarchy-shell omarchy-widgets settings`). Everything the plugin can do is
// set here, never only in the file.
Card {
  id: card
  widgetId: "settings"
  movable: false
  contentWidth: Style.space(300)

  component Choice: Button {
    bordered: true
    foreground: card.fg
    fontSize: Style.font.bodySmall
  }

  Item {
    width: parent.width
    height: title.implicitHeight
    PanelSectionHeader { id: title; text: "WIDGETS · SETTINGS"; foreground: card.fg }
    Button {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      iconText: "󰅖"
      foreground: card.fg
      horizontalPadding: Style.spacing.xs
      verticalPadding: 0
      onClicked: card.service.closeSettings()
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  PanelSectionHeader { text: "SCREENS"; foreground: card.fg }

  Flow {
    width: parent.width
    spacing: Style.spacing.md

    Choice {
      text: "All screens"
      selected: card.service.monitor === "all"
      onClicked: card.service.setMonitor("all")
    }
    Repeater {
      model: Quickshell.screens
      Choice {
        required property var modelData
        text: modelData.name
        selected: card.service.monitor === modelData.name
        onClicked: card.service.setMonitor(modelData.name)
      }
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Toggle {
    width: parent.width
    label: "Lock widgets"
    description: "Keep them where they are; no dragging"
    checked: card.service.locked
    foreground: card.fg
    onClicked: card.service.setLocked(!card.service.locked)
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  component OpacityRow: Column {
    id: orow
    property string label
    property real value
    property real minimum: 0
    signal picked(real v)
    width: parent.width
    spacing: Style.spacing.xs
    Item {
      width: parent.width
      height: olabel.implicitHeight
      Text {
        id: olabel
        text: orow.label
        color: card.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        textFormat: Text.PlainText
      }
      Text {
        anchors.right: parent.right
        text: Math.round(slider.liveValue * 100) + "%"
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        textFormat: Text.PlainText
      }
    }
    PanelSlider {
      id: slider
      width: parent.width
      minimum: orow.minimum
      maximum: 1
      step: 0.05
      value: orow.value
      trackColor: Style.selectedFillFor(card.fg, Commons.Color.accent)
      fillColor: card.fg
      knobColor: card.fg
      onMoved: function(v) { orow.picked(v) }
      onReleased: function(v) { orow.picked(v) }
    }
  }

  PanelSectionHeader { text: "OPACITY"; foreground: card.fg }

  OpacityRow {
    label: "Background"
    value: card.service.backgroundOpacity
    onPicked: function(v) { card.service.setBackgroundOpacity(v) }
  }

  OpacityRow {
    label: "Whole widget"
    minimum: 0.2
    value: card.service.widgetOpacity
    onPicked: function(v) { card.service.setWidgetOpacity(v) }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  PanelSectionHeader { text: "SHOW"; foreground: card.fg }

  Repeater {
    model: card.service.catalog
    Toggle {
      required property var modelData
      width: parent.width
      label: modelData.name
      description: modelData.description
      checked: card.service.widgetOn(modelData.id) && card.service.prefs !== null
      foreground: card.fg
      onClicked: card.service.setWidget(modelData.id, !card.service.widgetOn(modelData.id))
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Choice {
    text: "Reset positions"
    iconText: "󰑓"
    onClicked: card.service.resetPositions()
  }
}
