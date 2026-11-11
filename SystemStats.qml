import QtQuick
import Quickshell.Io

// CPU, memory, disk and battery. CPU, memory and battery are read straight
// from /proc and /sys every two seconds (no process started); disk use
// barely moves, so df runs once a minute. Nothing is sampled while no
// System widget is on a visible desktop (viewers = 0). CPU needs two
// samples, so the first reading after a pause shows the last value.
QtObject {
  id: root

  property real cpu: 0          // 0..1
  property real memory: 0       // 0..1
  property real memoryUsedGiB: 0
  property real memoryTotalGiB: 0
  property real disk: 0         // 0..1
  property real diskUsedGiB: 0
  property real diskTotalGiB: 0
  property int battery: -1      // percent, -1 = no battery
  property string batteryStatus: ""

  // How many System widgets can be seen right now (one per screen).
  property int viewers: 0
  readonly property bool active: viewers > 0
  onActiveChanged: if (active) { _prevCpu = null; sample(); diskProc.running = true }

  property var _prevCpu: null
  // The first BAT* under /sys/class/power_supply, found once.
  property string batteryDir: ""

  function parseStat(text) {
    var f = String(text || "").split("\n")[0].trim().split(/\s+/)
    if (f[0] !== "cpu") return
    var nums = f.slice(1).map(Number)
    var idle = nums[3] + (nums[4] || 0)
    var total = 0
    for (var j = 0; j < nums.length; j++) total += nums[j]
    if (_prevCpu) {
      var dt = total - _prevCpu.total, di = idle - _prevCpu.idle
      if (dt > 0) cpu = Math.max(0, Math.min(1, 1 - di / dt))
    }
    _prevCpu = { total: total, idle: idle }
  }

  function parseMem(text) {
    var m = /MemTotal:\s+(\d+)/.exec(text), a = /MemAvailable:\s+(\d+)/.exec(text)
    if (!m || !a) return
    memoryTotalGiB = Number(m[1]) / 1048576
    memoryUsedGiB = Math.max(0, memoryTotalGiB - Number(a[1]) / 1048576)
    memory = memoryTotalGiB > 0 ? memoryUsedGiB / memoryTotalGiB : 0
  }

  function sample() {
    statFile.reload()
    memFile.reload()
    if (batteryDir) { capFile.reload(); statusFile.reload() }
  }

  property FileView statFile: FileView {
    path: "/proc/stat"
    onLoaded: root.parseStat(text())
  }
  property FileView memFile: FileView {
    path: "/proc/meminfo"
    onLoaded: root.parseMem(text())
  }
  property FileView capFile: FileView {
    path: root.batteryDir ? root.batteryDir + "/capacity" : ""
    printErrors: false
    onLoaded: root.battery = Number(text().trim())
  }
  property FileView statusFile: FileView {
    path: root.batteryDir ? root.batteryDir + "/status" : ""
    printErrors: false
    onLoaded: root.batteryStatus = text().trim()
  }

  property Process findBattery: Process {
    running: true
    command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && echo \"$b\" && break; done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.batteryDir = text.trim()
    }
  }

  property Process diskProc: Process {
    command: ["df", "-B1", "--output=size,used", "/"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var f = text.trim().split("\n").pop().trim().split(/\s+/)
        root.diskTotalGiB = Number(f[0]) / 1073741824
        root.diskUsedGiB = Number(f[1]) / 1073741824
        root.disk = root.diskTotalGiB > 0 ? root.diskUsedGiB / root.diskTotalGiB : 0
      }
    }
  }

  property Timer tick: Timer {
    interval: 2000
    running: root.active
    repeat: true
    onTriggered: root.sample()
  }
  property Timer diskTick: Timer {
    interval: 60000
    running: root.active
    repeat: true
    onTriggered: if (!root.diskProc.running) root.diskProc.running = true
  }
}
