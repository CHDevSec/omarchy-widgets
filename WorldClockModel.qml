import QtQuick
import Quickshell
import Quickshell.Io

// The cities from the bar's Elsewhen widget (shell.json), with each zone's
// UTC offset read from tzdata through `date`, refreshed every ten minutes
// so daylight-saving changes are picked up. Times are worked out from the
// offsets every second, without a process per tick.
QtObject {
  id: root

  property bool active: true
  // [{ name, zone, offsetMinutes }]
  property var cities: []
  property var _pending: []

  readonly property var fallback: [
    { name: "London", zone: "Europe/London" },
    { name: "New York", zone: "America/New_York" },
    { name: "Tokyo", zone: "Asia/Tokyo" }
  ]

  function findElsewhen(node) {
    if (!node || typeof node !== "object") return null
    if (node.id === "omarchy.elsewhen" && Array.isArray(node.cities)) return node.cities
    for (var k in node) {
      var found = findElsewhen(node[k])
      if (found) return found
    }
    return null
  }

  function load(raw) {
    var list = null
    try { list = findElsewhen(JSON.parse(raw || "{}")) } catch (e) { list = null }
    root._pending = (list && list.length ? list : root.fallback)
      .filter(function(c) { return c && /^[A-Za-z0-9_+\-\/]+$/.test(String(c.zone || "")) })
    root.readOffsets()
  }

  function readOffsets() {
    if (!root.active || proc.running || root._pending.length === 0) return
    var args = ["sh", "-c", "for z in \"$@\"; do TZ=\"$z\" date +%z; done", "sh"]
    for (var i = 0; i < root._pending.length; i++) args.push(String(root._pending[i].zone))
    proc.command = args
    proc.running = true
  }

  function parseOffsets(text) {
    var lines = String(text || "").trim().split("\n")
    var out = []
    for (var i = 0; i < root._pending.length && i < lines.length; i++) {
      var m = lines[i].trim().match(/^([+-])(\d\d)(\d\d)$/)
      if (!m) continue
      var mins = (Number(m[2]) * 60 + Number(m[3])) * (m[1] === "-" ? -1 : 1)
      out.push({ name: root._pending[i].name, zone: root._pending[i].zone, offsetMinutes: mins })
    }
    root.cities = out
  }

  // The wall-clock Date in a city, for formatting (its UTC fields are local).
  function timeIn(city, now) {
    var utc = now.getTime() + now.getTimezoneOffset() * 60000
    return new Date(utc + city.offsetMinutes * 60000)
  }

  property Process proc: Process {
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseOffsets(text)
    }
  }

  property FileView config: FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.load(text())
    onLoadFailed: root.load("")
  }

  property Timer refresh: Timer {
    interval: 10 * 60 * 1000
    running: root.active
    repeat: true
    onTriggered: root.readOffsets()
  }

  onActiveChanged: if (active) readOffsets()
}
