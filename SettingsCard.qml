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
  defaultWidth: Style.space(300)

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

  Toggle {
    width: parent.width
    visible: !card.service.locked
    label: "Snap to grid"
    description: "Show a grid while dragging; line up with other widgets"
    checked: card.service.snap
    foreground: card.fg
    onClicked: card.service.setSnap(!card.service.snap)
  }

  Flow {
    width: parent.width
    visible: !card.service.locked && card.service.snap
    spacing: Style.spacing.md
    Repeater {
      model: [{ n: 12, name: "Fine" }, { n: 24, name: "Medium" }, { n: 48, name: "Coarse" }]
      Choice {
        required property var modelData
        text: modelData.name
        fontSize: Style.font.caption
        selected: card.service.gridSize === modelData.n
        onClicked: card.service.setGridSize(modelData.n)
      }
    }
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  component OpacityRow: Column {
    id: orow
    property string label
    property real value
    property real minimum: 0
    property real maximum: 1
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
      maximum: orow.maximum
      step: 0.05
      value: orow.value
      trackColor: Style.selectedFillFor(card.fg, Commons.Color.accent)
      fillColor: card.fg
      knobColor: card.fg
      onMoved: function(v) { orow.picked(v) }
      onReleased: function(v) { orow.picked(v) }
    }
  }

  // ------------------------------------------------- this widget's look
  readonly property string target: card.service.settingsTarget
  readonly property var targetLook: card.service.styleOf(target)
  readonly property string targetName: {
    var c = card.service.catalog
    for (var i = 0; i < c.length; i++) if (c[i].id === target) return c[i].name
    return target
  }

  PanelSectionHeader { text: "LOOK  ·  " + card.targetName.toUpperCase(); foreground: card.fg }

  // Which widget the controls below change; right-clicking one picks it.
  Flow {
    width: parent.width
    spacing: Style.spacing.sm
    Repeater {
      model: card.service.catalog.filter(function(w) { return card.service.widgetOn(w.id) })
      Choice {
        required property var modelData
        text: modelData.name
        fontSize: Style.font.caption
        selected: card.target === modelData.id
        onClicked: card.service.settingsTarget = modelData.id
      }
    }
  }

  // Where the notes live.
  Column {
    visible: card.target === "notes"
    width: parent.width
    spacing: Style.spacing.rowGap
    PanelSectionHeader { text: "SOURCE"; foreground: card.fg }
    Flow {
      width: parent.width
      spacing: Style.spacing.md
      Repeater {
        model: [{ id: "local", name: "Widget" }, { id: "obsidian", name: "Obsidian · Notas Rápidas" }]
        Choice {
          required property var modelData
          text: modelData.name
          fontSize: Style.font.caption
          selected: card.service.option("notes", "source", "local") === modelData.id
          onClicked: card.service.setStyle("notes", "source", modelData.id)
        }
      }
    }
  }

  // The clock's own options.
  Column {
    visible: card.target === "clock"
    width: parent.width
    spacing: Style.spacing.rowGap

    readonly property var installed: Qt.fontFamilies()

    PanelSectionHeader { text: "FACE"; foreground: card.fg }
    Flow {
      width: parent.width
      spacing: Style.spacing.sm
      Repeater {
        model: card.service.clockFaces.filter(function(f) {
          return f.id === "theme" || f.id === "pixel" || parent.parent.installed.indexOf(f.id) !== -1
        })
        Choice {
          required property var modelData
          text: modelData.name
          fontSize: Style.font.caption
          selected: card.service.option("clock", "face", "theme") === modelData.id
          onClicked: card.service.setStyle("clock", "face", modelData.id)
        }
      }
    }

    PanelSectionHeader { text: "FORMAT"; foreground: card.fg }
    Flow {
      width: parent.width
      spacing: Style.spacing.sm
      Repeater {
        model: card.service.clockFormats
        Choice {
          required property var modelData
          text: modelData.name
          fontSize: Style.font.caption
          selected: card.service.option("clock", "format", "24h") === modelData.id
          onClicked: card.service.setStyle("clock", "format", modelData.id)
        }
      }
    }

    Toggle {
      width: parent.width
      label: "Seconds"
      description: "Tick every second"
      checked: card.service.option("clock", "seconds", false) === true
      foreground: card.fg
      onClicked: card.service.setStyle("clock", "seconds", !(card.service.option("clock", "seconds", false) === true))
    }
  }

  OpacityRow {
    label: "Size"
    minimum: 0.6
    maximum: 2
    value: card.targetLook.scale
    onPicked: function(v) { card.service.setStyle(card.target, "scale", v) }
  }

  OpacityRow {
    label: "Background"
    value: card.targetLook.background
    onPicked: function(v) { card.service.setStyle(card.target, "background", v) }
  }

  OpacityRow {
    label: "Whole widget"
    minimum: 0.2
    value: card.targetLook.opacity
    onPicked: function(v) { card.service.setStyle(card.target, "opacity", v) }
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
