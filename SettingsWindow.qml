import QtQuick
import Quickshell
import Quickshell.Wayland

// The settings card, on the Overlay layer so it shows over windows too.
// Mapped only while open on this screen.
PanelWindow {
  id: win

  required property var service
  readonly property string screenName: screen ? screen.name : ""

  visible: service.settingsScreen !== "" && service.settingsScreen === screenName
  color: "transparent"
  WlrLayershell.namespace: "omarchy-widgets-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // A click anywhere off the card closes it.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: win.service.closeSettings()
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.service.closeSettings()

    SettingsCard {
      id: settings
      service: win.service
      screenName: win.screenName
      readonly property point at: win.service.settingsAt
      x: at.x < 0 ? (parent.width - width) / 2 : Math.max(0, Math.min(at.x, parent.width - width))
      y: at.y < 0 ? (parent.height - height) / 2 : Math.max(0, Math.min(at.y, parent.height - height))
    }
  }
}
