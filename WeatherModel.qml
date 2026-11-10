import QtQuick
import Quickshell
import Quickshell.Io

// Weather from wttr.in, every 15 minutes, for the place Omarchy's own
// weather panel uses (~/.local/state/omarchy/settings/weather.json), or
// wttr.in's own guess from this machine's address when none is set.
// Stale data stays on screen if a fetch fails.
QtObject {
  id: root

  property bool active: true

  property bool ready: false
  property string place: ""
  property string temp: ""
  property string feels: ""
  property string condition: ""
  property string humidity: ""
  property string wind: ""
  property int code: 0
  property bool night: false
  // [{ day, max, min, code }]
  property var days: []

  property string query: ""

  // Glyphs for wttr.in's codes, copied from Omarchy's weather panel
  // (shell/plugins/panels/weather/Model.js) so they match it.
  function icon(code, night) { return iconForCode(code, night) }

  function iconForCode(code, night) {
    var c = parseInt(String(code || "0"), 10)
    switch (c) {
      case 113: return night ? "" : ""
      case 116: return night ? "" : ""
      case 119: case 122: return ""
      case 143: case 248: case 260: return night ? "\ue346" : "\ue313"
      case 176: case 263: case 353: return night ? "" : ""
      case 179: case 227: case 230: case 323: case 326: case 368: return night ? "" : ""
      case 182: case 185: case 281: case 284: case 311: case 314:
      case 317: case 320: case 350: case 362: case 365: case 374: case 377: return ""
      case 200: case 386: case 389: case 392: case 395: return ""
      case 266: case 293: case 296: case 299: case 302: case 305: case 308: case 356: case 359: return ""
      case 329: case 332: case 335: case 338: case 371: return ""
      default: return ""
    }
  }

  function parse(raw) {
    var r
    try { r = JSON.parse(raw) } catch (e) { return }
    var cur = r.current_condition && r.current_condition[0]
    if (!cur) return
    root.temp = cur.temp_C
    root.feels = cur.FeelsLikeC
    root.condition = cur.weatherDesc && cur.weatherDesc[0] ? cur.weatherDesc[0].value : ""
    root.humidity = cur.humidity
    root.wind = cur.windspeedKmph
    root.code = parseInt(cur.weatherCode, 10)
    var area = r.nearest_area && r.nearest_area[0]
    if (area && !root.place) root.place = area.areaName && area.areaName[0] ? area.areaName[0].value : ""
    var hour = new Date().getHours()
    root.night = hour < 6 || hour >= 19
    var out = []
    var w = r.weather || []
    for (var i = 0; i < w.length; i++) {
      var mid = w[i].hourly && w[i].hourly[4] ? w[i].hourly[4].weatherCode : 116
      out.push({ date: w[i].date, max: w[i].maxtempC, min: w[i].mintempC, code: mid })
    }
    root.days = out
    root.ready = true
  }

  property FileView location: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        var l = JSON.parse(text() || "{}")
        var lat = parseFloat(String(l.latitude)), lon = parseFloat(String(l.longitude))
        root.place = l.name || l.location || ""
        root.query = !isNaN(lat) && !isNaN(lon) ? lat + "," + lon : encodeURIComponent(String(l.name || l.location || ""))
      } catch (e) { root.query = "" }
      root.fetch()
    }
    onLoadFailed: { root.query = ""; root.fetch() }
  }

  function fetch() {
    if (!root.active || proc.running) return
    proc.command = ["curl", "-fsS", "--max-time", "8", "https://wttr.in/" + root.query + "?format=j1"]
    proc.running = true
  }

  property Process proc: Process {
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
  }

  property Timer tick: Timer {
    interval: 15 * 60 * 1000
    running: root.active
    repeat: true
    onTriggered: root.fetch()
  }

  onActiveChanged: if (active) fetch()
}
