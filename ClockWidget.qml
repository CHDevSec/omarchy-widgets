import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The time, centred in its card, in the face and format chosen in its
// settings:
//   face    "theme" (the Omarchy font), "pixel" (block digits), or an
//           installed family from `faces`
//   format  "24h", "12h", "stacked" (hours over minutes), "analog"
//   seconds true shows them
Card {
  id: card
  widgetId: "clock"

  readonly property string face: service.option("clock", "face", "theme")
  readonly property string format: service.option("clock", "format", "24h")
  readonly property bool seconds: service.option("clock", "seconds", false) === true
  readonly property string family: face === "theme" || face === "pixel" ? Style.font.family : face
  readonly property color accent: pal.blue
  readonly property bool twelve: format === "12h"

  property date now: new Date()
  Timer {
    // Only tick every second when something on screen changes that often.
    interval: card.seconds ? 1000 : 10000
    running: card.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: card.now = new Date()
  }

  readonly property string hours: twelve ? String(now.getHours() % 12 || 12) : Qt.formatTime(now, "HH")
  readonly property string minutes: Qt.formatTime(now, "mm")
  readonly property string secs: Qt.formatTime(now, "ss")
  readonly property string ampm: now.getHours() < 12 ? "AM" : "PM"
  readonly property string line: hours + ":" + minutes + (seconds ? ":" + secs : "")

  readonly property real bigSize: Math.round(Style.font.displayLarge * (seconds ? 1.7 : 2.2))

  // ------------------------------------------------------------- digital
  Item {
    visible: card.format !== "analog" && card.format !== "stacked"
    width: parent.width
    height: card.face === "pixel" ? pixelLine.height : textLine.implicitHeight

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.spacing.md
      visible: card.face !== "pixel"
      Text {
        id: textLine
        text: card.line
        color: card.fg
        font.family: card.family
        font.pixelSize: card.bigSize
        font.bold: true
        textFormat: Text.PlainText
      }
      Text {
        visible: card.twelve
        anchors.baseline: textLine.baseline
        text: card.ampm
        color: card.accent
        font.family: card.family
        font.pixelSize: Style.font.title
        font.bold: true
      }
    }

    PixelText {
      id: pixelLine
      visible: card.face === "pixel"
      anchors.horizontalCenter: parent.horizontalCenter
      text: card.line + (card.twelve ? " " + card.ampm : "")
      dot: Math.max(3, Math.floor(card.contentWidth / ((text.length * 6) * 1.1)))
      color: card.fg
    }
  }

  // ------------------------------------------------------------- stacked
  Column {
    visible: card.format === "stacked"
    width: parent.width
    spacing: card.face === "pixel" ? Style.spacing.md : -Math.round(card.bigSize * 0.25)

    Repeater {
      model: [card.hours.length < 2 ? "0" + card.hours : card.hours, card.minutes]
      Item {
        required property string modelData
        required property int index
        width: card.contentWidth
        height: card.face === "pixel" ? px.height : tx.implicitHeight
        Text {
          id: tx
          visible: card.face !== "pixel"
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData
          color: index === 0 ? card.fg : card.accent
          font.family: card.family
          font.pixelSize: Math.round(Style.font.displayLarge * 2.8)
          font.bold: true
        }
        PixelText {
          id: px
          visible: card.face === "pixel"
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData
          dot: 9
          color: index === 0 ? card.fg : card.accent
        }
      }
    }
  }

  // -------------------------------------------------------------- analog
  Item {
    visible: card.format === "analog"
    width: parent.width
    height: Style.space(150)

    Canvas {
      id: dial
      anchors.centerIn: parent
      width: parent.height
      height: parent.height
      // Square ticks and flat hands: Omarchy's look, not a round watch face.
      onPaint: {
        var ctx = getContext("2d")
        var w = width, c = w / 2, r = c - 2
        ctx.reset()
        ctx.strokeStyle = Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.35)
        ctx.lineWidth = 1
        ctx.strokeRect(1.5, 1.5, w - 3, w - 3)
        for (var i = 0; i < 12; i++) {
          var a = i * Math.PI / 6
          var big = i % 3 === 0
          var len = big ? 10 : 5
          ctx.fillStyle = big ? card.accent : Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.6)
          ctx.save()
          ctx.translate(c, c)
          ctx.rotate(a)
          ctx.fillRect(-(big ? 2 : 1), -r + 4, big ? 4 : 2, len)
          ctx.restore()
        }
        var d = card.now
        function hand(angle, length, width, color) {
          ctx.save()
          ctx.translate(c, c)
          ctx.rotate(angle)
          ctx.fillStyle = color
          ctx.fillRect(-width / 2, -length, width, length + 6)
          ctx.restore()
        }
        hand((d.getHours() % 12 + d.getMinutes() / 60) * Math.PI / 6, r * 0.5, 5, card.fg)
        hand((d.getMinutes() + d.getSeconds() / 60) * Math.PI / 30, r * 0.78, 3, card.fg)
        if (card.seconds) hand(d.getSeconds() * Math.PI / 30, r * 0.85, 1, card.pal.red)
        ctx.fillStyle = card.accent
        ctx.fillRect(c - 4, c - 4, 8, 8)
      }
      Connections {
        target: card
        function onNowChanged() { if (card.format === "analog") dial.requestPaint() }
        function onFgChanged() { dial.requestPaint() }
        function onSecondsChanged() { dial.requestPaint() }
      }
    }
  }

  // ---------------------------------------------------------------- date
  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: card.now.toLocaleDateString(Qt.locale(), "dddd").toUpperCase()
    color: card.accent
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 2
    textFormat: Text.PlainText
  }
  Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: card.now.toLocaleDateString(Qt.locale(), "d MMMM yyyy").toUpperCase()
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
    font.letterSpacing: 1.2
    textFormat: Text.PlainText
  }
}
