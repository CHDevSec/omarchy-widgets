import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// One widget on the desktop, drawn exactly like an Omarchy popup: the
// popups' background, border spec, corner radius and padding, so it follows
// every theme switch. Drag it anywhere; the position is remembered.
BorderSurface {
  id: card

  required property string widgetId
  required property var service
  required property string screenName
  // Where it sits before the user moves it.
  property real defaultX: 0
  property real defaultY: 0

  default property alias content: body.data
  property int contentWidth: Style.space(260)

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
    var p = service.positionFor(screenName, widgetId)
    var px = p ? p.x : defaultX
    var py = p ? p.y : defaultY
    // Keep it on screen if the resolution changed since it was saved.
    x = Math.max(0, Math.min(px, (parent ? parent.width : px + width) - width))
    y = Math.max(0, Math.min(py, (parent ? parent.height : py + height) - height))
  }

  Component.onCompleted: place()
  Connections {
    target: card.service
    function onPrefsChanged() { if (!dragArea.drag.active) card.place() }
  }
  Connections {
    target: card.parent
    function onWidthChanged() { card.place() }
    function onHeightChanged() { card.place() }
  }

  Column {
    id: body
    x: card.contentLeftInset
    y: card.contentTopInset
    width: card.contentWidth
    spacing: Style.spacing.rowGap
  }

  MouseArea {
    id: dragArea
    anchors.fill: parent
    cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor
    drag.target: card
    drag.threshold: 4
    drag.minimumX: 0
    drag.minimumY: 0
    drag.maximumX: card.parent ? card.parent.width - card.width : 0
    drag.maximumY: card.parent ? card.parent.height - card.height : 0
    onReleased: card.service.savePosition(card.screenName, card.widgetId, card.x, card.y)
  }
}
