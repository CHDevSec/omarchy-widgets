import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Now, large, and the next days beneath, like macOS's medium weather widget.
Card {
  id: card
  widgetId: "weather"
  contentWidth: Style.space(280)

  required property var weather

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
      color: card.fg
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.displayLarge * 1.6)
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: card.weather.temp + "°"
        color: card.fg
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
          color: card.fg
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
