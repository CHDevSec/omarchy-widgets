import QtQuick
import Quickshell.Io

// Omarchy's own pixel-art icon (/usr/share/omarchy/icon.txt, a grid of █),
// drawn once as solid blocks. Its idle animation is cheap on purpose: the
// whole logo breathes and a scan line passes over it, both plain property
// animations on the GPU; the Canvas never repaints for them.
Item {
  id: root

  property color color: "white"
  property int dot: 2                 // one character column, in px
  property bool animated: true
  // The scan line: best the card's background, so it only shows on the logo.
  property color scanColor: Qt.rgba(0, 0, 0, 0.5)

  property var rows: []
  readonly property int columns: {
    var n = 0
    for (var i = 0; i < rows.length; i++) n = Math.max(n, rows[i].length)
    return n
  }

  // A character is about twice as tall as it is wide, so each text row is
  // two dots high and the icon comes out square, as it does in a terminal.
  implicitWidth: columns * dot
  implicitHeight: rows.length * dot * 2
  width: implicitWidth
  height: implicitHeight
  clip: true

  FileView {
    path: "/usr/share/omarchy/icon.txt"
    printErrors: false
    onLoaded: root.rows = text().replace(/\s+$/, "").split("\n")
  }

  Canvas {
    id: art
    anchors.fill: parent
    antialiasing: false
    smooth: false
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.fillStyle = root.color
      var d = root.dot
      for (var r = 0; r < root.rows.length; r++) {
        var line = root.rows[r], start = -1
        for (var c = 0; c <= line.length; c++) {
          var on = c < line.length && line[c] !== " "
          if (on && start < 0) start = c
          if (!on && start >= 0) { ctx.fillRect(start * d, r * d * 2, (c - start) * d, d * 2); start = -1 }
        }
      }
    }
    Connections {
      target: root
      function onRowsChanged() { art.requestPaint() }
      function onColorChanged() { art.requestPaint() }
      function onDotChanged() { art.requestPaint() }
    }
  }

  // Breathing.
  SequentialAnimation on opacity {
    running: root.animated && root.visible
    loops: Animation.Infinite
    NumberAnimation { from: 1.0; to: 0.55; duration: 1800; easing.type: Easing.InOutSine }
    NumberAnimation { from: 0.55; to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
  }

  // A scan line, top to bottom, then a pause.
  Rectangle {
    id: scan
    width: parent.width
    height: root.dot * 2
    color: root.scanColor
    visible: root.animated
    SequentialAnimation on y {
      running: root.animated && root.visible
      loops: Animation.Infinite
      NumberAnimation { from: -scan.height; to: root.height; duration: 1400; easing.type: Easing.Linear }
      PauseAnimation { duration: 2600 }
    }
  }
}
