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
  readonly property bool shown: movable ? service.widgetOn(widgetId) : true
  readonly property var look: service.styleOf(widgetId)
  visible: !movable || shown

  // Size: scaled from the top-left corner. While the corner handle is being
  // dragged the live value wins; it is saved on release.
  property real liveZoom: -1
  readonly property real zoom: movable ? (liveZoom > 0 ? liveZoom : look.scale) : 1
  scale: zoom
  transformOrigin: Item.TopLeft
  // The size it takes on screen, for placing, snapping and the input mask.
  readonly property real vw: width * zoom
  readonly property real vh: height * zoom

  default property alias content: body.data
  // Natural width; the user can stretch it (grip) to any width from 60 %.
  property int defaultWidth: Style.space(260)
  property real liveWidth: -1
  property real liveHeight: -1
  readonly property real stretchWidth: liveWidth > 0 ? liveWidth : (movable ? look.width : 0)
  readonly property real stretchHeight: liveHeight > 0 ? liveHeight : (movable ? look.height : 0)
  readonly property int contentWidth: stretchWidth > 0
    ? Math.round(Math.max(defaultWidth * 0.6, stretchWidth)) : defaultWidth
  // Content stretched taller than it is sits in the middle (the clock).
  property bool centerContent: false
  // The height the content should fill when stretched (0 = its own).
  readonly property real contentHeight: Math.max(body.implicitHeight, stretchHeight)
  // For children that need clicks of their own (note to-dos).
  readonly property bool dragging: dragArea.drag.active

  readonly property color fg: Commons.Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.4)
  // The theme's colours (ThemeColors.qml). Cards can be built before the
  // service's palette is bound, so they fall back to plain text colours.
  readonly property var pal: service && service.colors ? service.colors
    : ({ red: fg, green: fg, yellow: fg, blue: fg, magenta: fg, cyan: fg, grey: dim })

  // The theme's popup background at this widget's own opacity; the
  // settings and note cards stay solid so they are always readable.
  readonly property color baseBackground: Commons.Color.popups.background
  color: movable
    ? Qt.rgba(baseBackground.r, baseBackground.g, baseBackground.b, baseBackground.a * look.background)
    : baseBackground
  opacity: movable ? look.opacity : 1
  borderSpec: Border.localOrSurfaceSpec("popups", "border", Commons.Color.popups.border,
    Commons.Color.popups.border, Math.max(1, Style.space(2)))
  radius: Style.cornerRadius
  padding: Style.spacing.popupPadding

  width: contentWidth + leftPadding + rightPadding + borderLeft + borderRight
  height: contentHeight + topPadding + bottomPadding + borderTop + borderBottom

  function place() {
    if (!movable) return
    var p = service.positionFor(screenName, widgetId)
    var px = p ? p.x : defaultX
    var py = p ? p.y : defaultY
    // Keep it on screen if the resolution changed since it was saved.
    x = Math.max(0, Math.min(px, (parent ? parent.width : px + vw) - vw))
    y = Math.max(0, Math.min(py, (parent ? parent.height : py + vh) - vh))
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
    drag.maximumX: card.parent ? card.parent.width - card.vw : 0
    drag.maximumY: card.parent ? card.parent.height - card.vh : 0
    hoverEnabled: true
    onPressed: function(mouse) {
      if (mouse.button === Qt.RightButton && card.movable)
        card.service.openSettings(card.screenName, card.x + mouse.x, card.y + mouse.y, card.widgetId)
    }
    // The desk (WidgetsWindow) draws the grid and guides while a card moves
    // and says where it should land.
    onPositionChanged: if (drag.active && card.parent && card.parent.cardMoved) card.parent.cardMoved(card)
    onReleased: function(mouse) {
      if (!(mouse.button === Qt.LeftButton && card.movable && drag.target)) return
      var to = card.parent && card.parent.cardReleased ? card.parent.cardReleased(card) : null
      if (to && (to.x !== card.x || to.y !== card.y)) {
        snapX.to = to.x
        snapY.to = to.y
        snapAnim.restart()
      } else {
        card.service.savePosition(card.screenName, card.widgetId, card.x, card.y)
      }
    }
  }

  ParallelAnimation {
    id: snapAnim
    NumberAnimation { id: snapX; target: card; property: "x"; duration: 120; easing.type: Easing.OutCubic }
    NumberAnimation { id: snapY; target: card; property: "y"; duration: 120; easing.type: Easing.OutCubic }
    onFinished: card.service.savePosition(card.screenName, card.widgetId, card.x, card.y)
  }

  // Stretch: a corner grip, shown on hover when the widgets aren't locked.
  // Drag it to make the widget wider, narrower or taller (widths snap to the
  // grid); double-click it to go back to the natural size. The Size slider
  // in settings scales the whole widget instead.
  Item {
    id: grip
    z: 10
    visible: card.movable && !card.service.locked && (dragArea.containsMouse || gripMouse.containsMouse || gripMouse.pressed)
    width: Style.space(18)
    height: width
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    // Three steps of pixels, Omarchy-square.
    Repeater {
      model: [[2, 0], [1, 1], [2, 1], [0, 2], [1, 2], [2, 2]]
      Rectangle {
        required property var modelData
        readonly property real cell: grip.width / 4
        x: cell * 0.5 + modelData[0] * cell
        y: cell * 0.5 + modelData[1] * cell
        width: cell * 0.7
        height: width
        color: gripMouse.containsMouse || gripMouse.pressed ? Commons.Color.accent : card.dim
      }
    }

    MouseArea {
      id: gripMouse
      anchors.fill: parent
      anchors.margins: -Style.space(4)
      hoverEnabled: true
      cursorShape: Qt.SizeFDiagCursor
      property point start
      property real startW: 0
      property real startH: 0
      onPressed: function(m) {
        start = mapToItem(card.parent, m.x, m.y)
        startW = card.contentWidth
        startH = card.contentHeight
      }
      onPositionChanged: function(m) {
        if (!pressed) return
        var p = mapToItem(card.parent, m.x, m.y)
        var g = card.service.snap ? card.service.gridSize : 1
        var maxW = (card.parent ? card.parent.width - card.x : 4000) / card.zoom - (card.width - card.contentWidth)
        var maxH = (card.parent ? card.parent.height - card.y : 4000) / card.zoom - (card.height - card.contentHeight)
        var w = startW + (p.x - start.x) / card.zoom
        // Snap the right edge to the grid.
        w = Math.round((card.x + w * card.zoom) / g) * g / card.zoom - card.x / card.zoom
        w = Math.max(card.defaultWidth * 0.6, Math.min(maxW, w))
        var h = Math.max(body.implicitHeight, Math.min(maxH, startH + (p.y - start.y) / card.zoom))
        // Let the desk snap the on-screen size to other widgets' sizes and edges.
        var chrome = card.width - card.contentWidth, chromeH = card.height - card.contentHeight
        if (card.parent && card.parent.cardStretched) {
          var snapped = card.parent.cardStretched(card, (w + chrome) * card.zoom, (h + chromeH) * card.zoom)
          w = snapped.w / card.zoom - chrome
          h = snapped.h / card.zoom - chromeH
        }
        card.liveWidth = Math.max(card.defaultWidth * 0.6, w)
        card.liveHeight = Math.max(0, h)
      }
      onReleased: {
        card.service.setStyle(card.widgetId, "width", Math.round(card.liveWidth))
        // Only keep a height taller than the content needs.
        card.service.setStyle(card.widgetId, "height", card.liveHeight > body.implicitHeight + 2 ? Math.round(card.liveHeight) : 0)
        card.liveWidth = -1
        card.liveHeight = -1
        if (card.parent && card.parent.cardStretchEnded) card.parent.cardStretchEnded()
        card.place()
        card.service.savePosition(card.screenName, card.widgetId, card.x, card.y)
      }
      onDoubleClicked: card.service.resetSize(card.widgetId)
    }
  }

  Column {
    id: body
    x: card.contentLeftInset
    y: card.contentTopInset + (card.centerContent ? Math.round((card.contentHeight - implicitHeight) / 2) : 0)
    width: card.contentWidth
    spacing: Style.spacing.rowGap
  }
}
