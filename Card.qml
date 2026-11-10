import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// One widget on the desktop, drawn exactly like an Omarchy popup: the
// popups' background, border spec, corner radius and padding, so it follows
// every theme switch. Drag it anywhere (unless locked); right-click for
// settings.
BorderSurface {
  id: card

  required property string widgetId
  required property var service
  required property string screenName
  // Where it sits before the user moves it.
  property real defaultX: 0
  property real defaultY: 0
  // The settings card is not a widget: it neither drags nor saves.
  property bool movable: true

  default property alias content: body.data
  property int contentWidth: Style.space(260)
  // For children that need clicks of their own (note to-dos).
  readonly property bool dragging: dragArea.drag.active

  readonly property color fg: Commons.Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.4)

  color: Commons.Color.popups.background
  borderSpec: Border.localOrSurfaceSpec("popups", "border", Commons.Color.popups.border,
    Commons.Color.popups.border, Math.max(1, Style.space(2)))
  radius: Style.cornerRadius
  padding: Style.spacing.popupPadding

  width: contentWidth + leftPadding + rightPadding + borderLeft + borderRight
  height: body.implicitHeight + topPadding + bottomPadding + borderTop + borderBottom

  function place() {
    if (!movable) return
    var p = service.positionFor(screenName, widgetId)
    var px = p ? p.x : defaultX
    var py = p ? p.y : defaultY
    // Keep it on screen if the resolution changed since it was saved.
    x = Math.max(0, Math.min(px, (parent ? parent.width : px + width) - width))
    y = Math.max(0, Math.min(py, (parent ? parent.height : py + height) - height))
  }

  Component.onCompleted: place()
  onDefaultXChanged: place()
  onDefaultYChanged: place()
  Connections {
    target: card.service
    function onPrefsChanged() { if (!dragArea.drag.active) card.place() }
  }
  Connections {
    target: card.parent
    function onWidthChanged() { card.place() }
    function onHeightChanged() { card.place() }
  }

  // Under the content, so buttons and to-dos inside get their clicks first.
  MouseArea {
    id: dragArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor
    drag.target: card.movable && !card.service.locked ? card : null
    drag.threshold: 4
    drag.minimumX: 0
    drag.minimumY: 0
    drag.maximumX: card.parent ? card.parent.width - card.width : 0
    drag.maximumY: card.parent ? card.parent.height - card.height : 0
    onPressed: function(mouse) {
      if (mouse.button === Qt.RightButton && card.movable)
        card.service.openSettings(card.screenName, card.x + mouse.x, card.y + mouse.y)
    }
    onReleased: function(mouse) {
      if (mouse.button === Qt.LeftButton && card.movable && drag.target)
        card.service.savePosition(card.screenName, card.widgetId, card.x, card.y)
    }
  }

  Column {
    id: body
    x: card.contentLeftInset
    y: card.contentTopInset
    width: card.contentWidth
    spacing: Style.spacing.rowGap
  }

  // A small lock mark while widgets are locked.
  Text {
    visible: card.movable && card.service.locked
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: card.padding
    text: "󰌾"
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
