import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// This month, with today marked the way Omarchy marks a selected row.
Card {
  id: card
  widgetId: "calendar"

  property date today: new Date()
  // Rolls over at midnight.
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: {
      var d = new Date()
      if (d.getDate() !== card.today.getDate()) card.today = d
    }
  }

  readonly property var locale: Qt.locale()
  // Qt: 0 = Sunday … 6 = Saturday; Locale.firstDayOfWeek uses the same.
  readonly property int firstDay: locale.firstDayOfWeek % 7
  readonly property int year: today.getFullYear()
  readonly property int month: today.getMonth()
  readonly property int lead: (new Date(year, month, 1).getDay() - firstDay + 7) % 7
  readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
  readonly property int cells: Math.ceil((lead + daysInMonth) / 7) * 7
  readonly property real cell: width > 0 ? contentWidth / 7 : 0

  PanelSectionHeader {
    text: card.locale.standaloneMonthName(card.month, Locale.LongFormat).toUpperCase() + " " + card.year
    foreground: card.fg
  }

  PanelSeparator { width: parent.width; foreground: card.fg }

  Grid {
    columns: 7
    width: parent.width

    Repeater {
      model: 7
      Text {
        width: card.cell
        horizontalAlignment: Text.AlignHCenter
        text: card.locale.dayName((card.firstDay + index) % 7, Locale.NarrowFormat).toUpperCase()
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        textFormat: Text.PlainText
      }
    }

    Repeater {
      model: card.cells
      Item {
        readonly property int day: index - card.lead + 1
        readonly property bool inMonth: day >= 1 && day <= card.daysInMonth
        readonly property bool isToday: inMonth && day === card.today.getDate()
        width: card.cell
        height: Math.round(card.cell * 0.82)

        BorderSurface {
          anchors.centerIn: parent
          width: Math.min(parent.width, parent.height) + Style.space(4)
          height: parent.height - Style.space(2)
          visible: parent.isToday
          radius: Style.cornerRadius
          color: Style.selectedAccentFill
          borderSpec: Border.flat(Style.selectedBorderColor, Math.max(1, Style.selectedBorderWidth))
        }

        Text {
          anchors.centerIn: parent
          visible: parent.inMonth
          text: parent.day
          color: parent.isToday ? Commons.Color.accent : card.fg
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: parent.isToday
          textFormat: Text.PlainText
        }
      }
    }
  }
}
