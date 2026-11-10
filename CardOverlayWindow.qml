import QtQuick
import Quickshell
import Quickshell.Wayland

// The card that floats over windows (settings, or adding a note), on the
// Overlay layer so it shows wherever you are. Mapped only while open on this
// screen; a click off the card or Escape closes it.
PanelWindow {
  id: win

  required property var service
  required property var notes
  readonly property string screenName: screen ? screen.name : ""
  readonly property string kind: service.overlayScreen === screenName ? service.overlayKind : ""

  visible: kind !== ""
  color: "transparent"
  WlrLayershell.namespace: "omarchy-widgets-overlay"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: kind === "note" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: win.service.closeSettings()
  }

  Item {
    id: stage
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.service.closeSettings()

    readonly property point at: win.service.overlayAt
    function placeX(w) { return at.x < 0 ? (width - w) / 2 : Math.max(0, Math.min(at.x, width - w)) }
    function placeY(h) { return at.y < 0 ? (height - h) / 2 : Math.max(0, Math.min(at.y, height - h)) }

    SettingsCard {
      visible: win.kind === "settings"
      service: win.service
      screenName: win.screenName
      x: stage.placeX(width)
      y: stage.placeY(height)
    }

    NoteInputCard {
      visible: win.kind === "note"
      active: visible
      service: win.service
      notes: win.notes
      screenName: win.screenName
      x: stage.placeX(width)
      y: stage.placeY(height)
    }
  }
}
