import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons

// The current Omarchy theme's sixteen terminal colours (colors.toml), so
// each widget can have its own colour and still follow every theme switch.
// Missing keys fall back to the shell's own palette roles.
QtObject {
  id: root

  property var raw: ({})

  function pick(key, fallback) { return raw[key] ? raw[key] : fallback }

  readonly property color red: pick("color1", Commons.Color.urgent)
  readonly property color green: pick("color2", Commons.Color.accent)
  readonly property color yellow: pick("color3", Commons.Color.accent)
  readonly property color blue: pick("color4", Commons.Color.accent)
  readonly property color magenta: pick("color5", Commons.Color.accent)
  readonly property color cyan: pick("color6", Commons.Color.accent)
  readonly property color grey: pick("color8", Commons.Color.muted)

  property FileView file: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var out = {}
      var lines = text().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var m = lines[i].match(/^\s*([a-z0-9_]+)\s*=\s*"(#[0-9a-fA-F]{6,8})"/)
        if (m) out[m[1]] = m[2]
      }
      root.raw = out
    }
  }
}
