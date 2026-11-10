import QtQuick

// Text drawn as solid square blocks on a 5×7 grid (the classic LCD font):
// real pixel art that needs no font installed, in any theme colour. One
// Canvas, repainted only when the text, size or colour changes, so a line
// costs one item, not one rectangle per pixel.
Canvas {
  id: root

  property string text: ""
  property int dot: 6                 // one pixel, in px (whole, so it stays crisp)
  property color color: "white"
  // A second colour for some characters (e.g. the colon), or the same.
  property color markColor: color
  property string marks: ":"
  // A drop shadow one pixel down-right, in this colour; transparent for none.
  property color shadowColor: "transparent"

  readonly property var glyphs: ({
    "0": ["01110","10001","10011","10101","11001","10001","01110"],
    "1": ["00100","01100","00100","00100","00100","00100","01110"],
    "2": ["01110","10001","00001","00010","00100","01000","11111"],
    "3": ["11111","00010","00100","00010","00001","10001","01110"],
    "4": ["00010","00110","01010","10010","11111","00010","00010"],
    "5": ["11111","10000","11110","00001","00001","10001","01110"],
    "6": ["00110","01000","10000","11110","10001","10001","01110"],
    "7": ["11111","00001","00010","00100","01000","01000","01000"],
    "8": ["01110","10001","10001","01110","10001","10001","01110"],
    "9": ["01110","10001","10001","01111","00001","00010","01100"],
    "A": ["01110","10001","10001","11111","10001","10001","10001"],
    "B": ["11110","10001","10001","11110","10001","10001","11110"],
    "C": ["01110","10001","10000","10000","10000","10001","01110"],
    "D": ["11100","10010","10001","10001","10001","10010","11100"],
    "E": ["11111","10000","10000","11110","10000","10000","11111"],
    "F": ["11111","10000","10000","11110","10000","10000","10000"],
    "G": ["01110","10001","10000","10111","10001","10001","01111"],
    "H": ["10001","10001","10001","11111","10001","10001","10001"],
    "I": ["01110","00100","00100","00100","00100","00100","01110"],
    "J": ["00111","00010","00010","00010","00010","10010","01100"],
    "K": ["10001","10010","10100","11000","10100","10010","10001"],
    "L": ["10000","10000","10000","10000","10000","10000","11111"],
    "M": ["10001","11011","10101","10101","10001","10001","10001"],
    "N": ["10001","10001","11001","10101","10011","10001","10001"],
    "O": ["01110","10001","10001","10001","10001","10001","01110"],
    "P": ["11110","10001","10001","11110","10000","10000","10000"],
    "Q": ["01110","10001","10001","10001","10101","10010","01101"],
    "R": ["11110","10001","10001","11110","10100","10010","10001"],
    "S": ["01111","10000","10000","01110","00001","00001","11110"],
    "T": ["11111","00100","00100","00100","00100","00100","00100"],
    "U": ["10001","10001","10001","10001","10001","10001","01110"],
    "V": ["10001","10001","10001","10001","10001","01010","00100"],
    "W": ["10001","10001","10001","10101","10101","10101","01010"],
    "X": ["10001","10001","01010","00100","01010","10001","10001"],
    "Y": ["10001","10001","10001","01010","00100","00100","00100"],
    "Z": ["11111","00001","00010","00100","01000","10000","11111"],
    ":": ["0","0","1","0","1","0","0"],
    ".": ["0","0","0","0","0","0","1"],
    ",": ["00","00","00","00","00","01","10"],
    "-": ["000","000","000","111","000","000","000"],
    "/": ["00001","00001","00010","00100","01000","10000","10000"],
    " ": ["000","000","000","000","000","000","000"]
  })

  // Upper case, accents dropped (TERÇA → TERCA), unknown characters as spaces.
  readonly property var chars: {
    var t = String(text).toUpperCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
    var out = []
    for (var i = 0; i < t.length; i++) out.push(glyphs[t[i]] ? t[i] : " ")
    return out
  }
  // Width in pixels: each glyph's columns plus one blank column between.
  readonly property int columns: {
    var n = 0
    for (var i = 0; i < chars.length; i++) n += glyphs[chars[i]][0].length + (i > 0 ? 1 : 0)
    return n
  }
  readonly property bool shadowed: shadowColor.a > 0

  width: columns * dot + (shadowed ? dot : 0)
  height: 7 * dot + (shadowed ? dot : 0)
  // Shown at the size it was drawn; never smoothed.
  renderStrategy: Canvas.Cooperative
  antialiasing: false
  smooth: false

  function drawText(ctx, offset, solid) {
    var x = 0
    for (var i = 0; i < chars.length; i++) {
      var ch = chars[i], rows = glyphs[ch]
      ctx.fillStyle = solid ? solid : (marks.indexOf(ch) >= 0 ? markColor : color)
      for (var r = 0; r < rows.length; r++)
        for (var c = 0; c < rows[r].length; c++)
          if (rows[r][c] === "1")
            ctx.fillRect((x + c) * dot + offset, r * dot + offset, dot, dot)
      x += rows[0].length + 1
    }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    if (shadowed) drawText(ctx, dot, shadowColor)
    drawText(ctx, 0, null)
  }

  onCharsChanged: requestPaint()
  onDotChanged: requestPaint()
  onColorChanged: requestPaint()
  onMarkColorChanged: requestPaint()
  onShadowColorChanged: requestPaint()
  onWidthChanged: requestPaint()
}
