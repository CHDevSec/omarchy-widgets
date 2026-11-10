import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// This month. Its colour is the theme's red, as the macOS calendar's is:
// the month name, and today as a solid square block with the day cut out.
// Weekends are dimmed, days of other months left blank.
Card {
  id: card
  widgetId: "calendar"

  readonly property color tint: pal.red

  property date today: new Date()
  // Rolls over at midnight.
  Timer {
    interval: 60000
    running: card.visible
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
  readonly property real cell: contentWidth / 7

  // Header: the month large in the calendar's colour, the year beside it.
  Row {
    spacing: Style.spacing.md
    Text {
      text: card.locale.standaloneMonthName(card.month, Locale.LongFormat).toUpperCase()
      color: card.tint
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
      textFormat: Text.PlainText
    }
    Text {
      anchors.baseline: parent.children[0].baseline
      text: card.year
      color: card.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  Grid {
    columns: 7
    width: parent.width

    Repeater {
      model: 7
      Text {
        readonly property int weekday: (card.firstDay + index) % 7
        width: card.cell
        horizontalAlignment: Text.AlignHCenter
        text: card.locale.dayName(weekday, Locale.NarrowFormat).toUpperCase()
        color: weekday === 0 || weekday === 6 ? Qt.darker(card.dim, 1.3) : card.dim
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
        readonly property int weekday: (card.firstDay + index) % 7
        readonly property bool inMonth: day >= 1 && day <= card.daysInMonth
        readonly property bool isToday: inMonth && day === card.today.getDate()
        readonly property bool past: inMonth && day < card.today.getDate()
        width: card.cell
        height: Math.round(card.cell * 0.82)

        Rectangle {
          anchors.centerIn: parent
          width: Math.min(parent.width, parent.height) + Style.space(6)
          height: parent.height - Style.space(2)
          visible: parent.isToday
          radius: Style.cornerRadius
          color: card.tint
        }

        Text {
          anchors.centerIn: parent
          visible: parent.inMonth
          text: parent.day
          color: parent.isToday ? Commons.Color.background
            : (parent.weekday === 0 || parent.weekday === 6) ? card.dim
            : parent.past ? Qt.darker(card.fg, 1.25)
            : card.fg
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: parent.isToday
          textFormat: Text.PlainText
        }
      }
    }
  }
}
