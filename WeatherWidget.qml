import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Now, large, and the next days beneath, like macOS's medium weather widget.
Card {
  id: card
  widgetId: "weather"
  defaultWidth: Style.space(280)

  required property var weather

  // The icon in the colour of the sky: sun yellow, rain blue, snow cyan,
  // storms magenta, cloud and fog plain. The temperature warms with it.
  function skyColor(code, night) {
    var c = parseInt(String(code || "0"), 10)
    if (c === 113) return night ? card.pal.blue : card.pal.yellow
    if (c === 116) return night ? card.pal.blue : card.pal.yellow
    if ([200, 386, 389, 392, 395].indexOf(c) !== -1) return card.pal.magenta
    if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(c) !== -1) return card.pal.cyan
    if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359].indexOf(c) !== -1) return card.pal.blue
    return card.fg
  }
  function tempColor(t) {
    var n = Number(t)
    if (isNaN(n)) return card.fg
    if (n >= 33) return card.pal.red
    if (n >= 27) return card.pal.yellow
    if (n <= 12) return card.pal.blue
    return card.fg
  }

  PanelSectionHeader {
    width: parent.width
    text: "WEATHER" + (card.weather.place ? "  ·  " + card.weather.place.toUpperCase() : "")
    foreground: card.fg
    elide: Text.ElideRight
  }

  Text {
    visible: !card.weather.ready
    text: "Loading…"
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Row {
    visible: card.weather.ready
    width: parent.width
    spacing: Style.spacing.xxl

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: card.weather.icon(card.weather.code, card.weather.night)
      color: card.skyColor(card.weather.code, card.weather.night)
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.displayLarge * 1.6)
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: card.weather.temp + "°"
        color: card.tempColor(card.weather.temp)
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.displayLarge * 1.4)
        font.bold: true
      }
      Text {
        text: card.weather.condition
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        textFormat: Text.PlainText
      }
    }
  }

  Text {
    visible: card.weather.ready
    width: parent.width
    text: "FEELS " + card.weather.feels + "°  ·  HUMIDITY " + card.weather.humidity + "%  ·  WIND " + card.weather.wind + " KM/H"
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
    elide: Text.ElideRight
  }

  PanelSeparator { visible: card.weather.ready; width: parent.width; foreground: card.fg }

  Row {
    visible: card.weather.ready
    width: parent.width
    Repeater {
      model: card.weather.days
      Column {
        required property var modelData
        required property int index
        width: card.contentWidth / Math.max(1, card.weather.days.length)
        spacing: Style.spacing.xs
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: index === 0 ? "TODAY"
            : new Date(modelData.date + "T12:00:00").toLocaleDateString(Qt.locale(), "ddd").toUpperCase()
          color: card.dim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: card.weather.icon(modelData.code, false)
          color: card.skyColor(modelData.code, false)
          font.family: Style.font.family
          font.pixelSize: Style.font.iconLarge
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.max + "° / " + modelData.min + "°"
          color: card.fg
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
