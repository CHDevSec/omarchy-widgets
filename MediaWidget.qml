import QtQuick
import Quickshell.Services.Mpris
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Now Playing: art, title, artist, progress and controls for the player
// that is playing (else the first one there is).
Card {
  id: card
  widgetId: "media"
  contentWidth: Style.space(300)

  readonly property color tint: pal.magenta
  readonly property var players: Mpris.players.values
  readonly property var player: {
    var list = players
    for (var i = 0; i < list.length; i++) if (list[i].isPlaying) return list[i]
    return list.length > 0 ? list[0] : null
  }

  // Position isn't pushed by MPRIS; ask for it while playing.
  Timer {
    interval: 1000
    running: card.visible && card.player !== null && card.player.isPlaying
    repeat: true
    onTriggered: if (card.player) card.player.positionChanged()
  }

  function clock(seconds) {
    var s = Math.max(0, Math.floor(seconds || 0))
    return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2)
  }

  component Control: Rectangle {
    id: ctl
    property string glyph
    property bool big: false
    property bool enabledHere: true
    signal activated()
    width: big ? Style.spacing.controlHeight * 1.6 : Style.spacing.controlHeight * 1.2
    height: Style.spacing.controlHeight
    radius: Style.cornerRadius
    color: big ? card.tint : (ctlMouse.containsMouse && enabledHere ? Style.hoverFill : "transparent")
    border.width: 1
    border.color: big ? card.tint : Qt.rgba(card.fg.r, card.fg.g, card.fg.b, ctlMouse.containsMouse ? 0.6 : 0.3)
    opacity: enabledHere ? (big && ctlMouse.containsMouse ? 0.85 : 1) : 0.4
    Text {
      anchors.centerIn: parent
      text: ctl.glyph
      color: ctl.big ? Commons.Color.background : card.fg
      font.family: Style.font.family
      font.pixelSize: ctl.big ? Style.font.iconLarge : Style.font.icon
    }
    MouseArea {
      id: ctlMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: ctl.enabledHere
      cursorShape: Qt.PointingHandCursor
      onClicked: ctl.activated()
    }
  }

  PanelSectionHeader {
    width: parent.width
    text: "NOW PLAYING" + (card.player && card.player.identity ? "  ·  " + card.player.identity.toUpperCase() : "")
    foreground: card.fg
    elide: Text.ElideRight
  }

  // Idle: the Omarchy logo in pixel art, breathing, so the card is never empty.
  Column {
    visible: !card.player
    width: parent.width
    spacing: Style.spacing.md
    topPadding: Style.spacing.md
    bottomPadding: Style.spacing.sm

    OmarchyLogo {
      anchors.horizontalCenter: parent.horizontalCenter
      color: card.tint
      dot: 2
      scanColor: Qt.rgba(card.baseBackground.r, card.baseBackground.g, card.baseBackground.b, 0.6)
      animated: card.visible && !card.player
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "NOTHING PLAYING"
      color: card.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 2
    }
  }

  Row {
    visible: !!card.player
    width: parent.width
    spacing: Style.spacing.xxl

    Rectangle {
      id: art
      width: Style.space(64)
      height: width
      radius: Style.cornerRadius
      color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.08)
      border.width: 1
      border.color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.3)
      clip: true
      Image {
        anchors.fill: parent
        anchors.margins: 1
        source: card.player && card.player.trackArtUrl ? card.player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 128
        sourceSize.height: 128
      }
      Text {
        anchors.centerIn: parent
        visible: !(card.player && card.player.trackArtUrl)
        text: "󰝚"
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.display
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - art.width - parent.spacing
      spacing: Style.spacing.xxs
      Text {
        width: parent.width
        text: card.player ? (card.player.trackTitle || "Unknown") : ""
        color: card.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
        elide: Text.ElideRight
        textFormat: Text.PlainText
      }
      Text {
        width: parent.width
        text: card.player ? (card.player.trackArtist || "") : ""
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        textFormat: Text.PlainText
      }
      Text {
        width: parent.width
        visible: text !== ""
        text: card.player ? (card.player.trackAlbum || "") : ""
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        textFormat: Text.PlainText
      }
    }
  }

  // Progress: a flat Omarchy bar with the times at its ends.
  Column {
    visible: !!card.player && card.player.lengthSupported && card.player.length > 0
    width: parent.width
    spacing: Style.spacing.xs
    Rectangle {
      width: parent.width
      height: Style.space(4)
      color: Qt.rgba(card.fg.r, card.fg.g, card.fg.b, 0.12)
      Rectangle {
        height: parent.height
        width: card.player && card.player.length > 0
          ? Math.min(1, card.player.position / card.player.length) * parent.width : 0
        color: card.tint
      }
    }
    Item {
      width: parent.width
      height: posText.implicitHeight
      Text {
        id: posText
        text: card.player ? card.clock(card.player.position) : ""
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        anchors.right: parent.right
        text: card.player ? card.clock(card.player.length) : ""
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  Row {
    visible: !!card.player
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.spacing.md
    Control {
      glyph: "󰒮"
      enabledHere: !!card.player && card.player.canGoPrevious
      onActivated: card.player.previous()
    }
    Control {
      big: true
      glyph: card.player && card.player.isPlaying ? "󰏤" : "󰐊"
      enabledHere: !!card.player && card.player.canTogglePlaying
      onActivated: card.player.togglePlaying()
    }
    Control {
      glyph: "󰒭"
      enabledHere: !!card.player && card.player.canGoNext
      onActivated: card.player.next()
    }
  }
}
