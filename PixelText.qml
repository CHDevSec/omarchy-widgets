import QtQuick

// Digits and a few marks drawn as blocks on a 5×7 grid: a pixel-art clock
// that needs no font, square like Omarchy, in any theme colour.
Row {
  id: root

  property string text: ""
  property real dot: 6           // one pixel, in px
  property real gap: 1           // between pixels
  property color color: "white"
  property color offColor: "transparent"
  spacing: dot + gap

  readonly property var glyphs: ({
    "0": ["01110","10001","10011","10101","11001","10001","01110"],
    "1": ["00100","01100","00100","00100","00100","00100","01110"],
    "2": ["01110","10001","00001","00010","00100","01000","11111"],
    "3": ["11110","00001","00001","01110","00001","00001","11110"],
    "4": ["00010","00110","01010","10010","11111","00010","00010"],
    "5": ["11111","10000","11110","00001","00001","10001","01110"],
    "6": ["00110","01000","10000","11110","10001","10001","01110"],
    "7": ["11111","00001","00010","00100","01000","01000","01000"],
    "8": ["01110","10001","10001","01110","10001","10001","01110"],
    "9": ["01110","10001","10001","01111","00001","00010","01100"],
    ":": ["0","0","1","0","1","0","0"],
    " ": ["0","0","0","0","0","0","0"],
    "A": ["01110","10001","10001","11111","10001","10001","10001"],
    "P": ["11110","10001","10001","11110","10000","10000","10000"],
    "M": ["10001","11011","10101","10101","10001","10001","10001"]
  })

  Repeater {
    model: root.text.split("")
    Grid {
      required property string modelData
      readonly property var rows: root.glyphs[modelData] || root.glyphs[" "]
      columns: rows[0].length
      spacing: root.gap
      Repeater {
        model: parent.rows.join("").split("")
        Rectangle {
          required property string modelData
          width: root.dot
          height: root.dot
          color: modelData === "1" ? root.color : root.offColor
        }
      }
    }
  }
}
