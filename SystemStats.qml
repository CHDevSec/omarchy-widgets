import QtQuick
import Quickshell.Io

// CPU, memory, disk and battery, sampled every two seconds from /proc,
// df and /sys. CPU needs two samples, so the first reading shows 0.
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

  property var _prevCpu: null

  readonly property string script:
    "head -1 /proc/stat; " +
    "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " +
    "df -B1 --output=size,used / | tail -1 | sed 's/^/DISK /'; " +
    "for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] && " +
    "echo \"BAT $(cat $b/capacity) $(cat $b/status)\" && break; done"

  function parse(text) {
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var f = lines[i].trim().split(/\s+/)
      if (f[0] === "cpu") {
        var nums = f.slice(1).map(Number)
        var idle = nums[3] + (nums[4] || 0)
        var total = 0
        for (var j = 0; j < nums.length; j++) total += nums[j]
        if (root._prevCpu) {
          var dt = total - root._prevCpu.total
          var di = idle - root._prevCpu.idle
          if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt))
        }
        root._prevCpu = { total: total, idle: idle }
      } else if (f[0] === "MemTotal:") {
        root.memoryTotalGiB = Number(f[1]) / 1048576
      } else if (f[0] === "MemAvailable:") {
        var avail = Number(f[1]) / 1048576
        root.memoryUsedGiB = Math.max(0, root.memoryTotalGiB - avail)
        root.memory = root.memoryTotalGiB > 0 ? root.memoryUsedGiB / root.memoryTotalGiB : 0
      } else if (f[0] === "DISK") {
        root.diskTotalGiB = Number(f[1]) / 1073741824
        root.diskUsedGiB = Number(f[2]) / 1073741824
        root.disk = root.diskTotalGiB > 0 ? root.diskUsedGiB / root.diskTotalGiB : 0
      } else if (f[0] === "BAT") {
        root.battery = Number(f[1])
        root.batteryStatus = f.slice(2).join(" ")
      }
    }
  }

  property Process sampler: Process {
    command: ["sh", "-c", root.script]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
  }

  property Timer tick: Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!root.sampler.running) root.sampler.running = true
  }
}
