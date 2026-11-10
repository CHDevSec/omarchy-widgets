import QtQuick
import Quickshell
import Quickshell.Io

// Quick notes, kept as plain Markdown in
// ~/.local/share/omarchy-widgets/notes.md so anything can write them:
// you, a script, or Claude (`bin/omarchy-widgets-note "text"`).
//
//   - [ ] a to-do          (click it on the widget to tick it)
//   - [x] a done to-do
//   - a plain note
//
// Other lines (headings, blank lines) are kept but not shown.
QtObject {
  id: root

  readonly property string dir: Quickshell.env("HOME") + "/.local/share/omarchy-widgets"
  readonly property string path: dir + "/notes.md"

  // [{ line, text, todo, done }]
  property var items: []
  property var _lines: []

  function parse(text) {
    var lines = String(text || "").split("\n")
    var out = []
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*[-*]\s+\[( |x|X)\]\s+(.*)$/)
      if (m) { out.push({ line: i, text: m[2], todo: true, done: m[1] !== " " }); continue }
      m = lines[i].match(/^\s*[-*]\s+(.*)$/)
      if (m) out.push({ line: i, text: m[1], todo: false, done: false })
    }
    root._lines = lines
    root.items = out
  }

  function toggle(item) {
    if (!item || !item.todo) return
    var lines = root._lines.slice()
    var l = lines[item.line]
    if (l === undefined) return
    lines[item.line] = item.done ? l.replace(/\[(x|X)\]/, "[ ]") : l.replace(/\[ \]/, "[x]")
    file.setText(lines.join("\n"))
  }

  function clearDone() {
    var lines = root._lines.filter(function(l) { return !/^\s*[-*]\s+\[(x|X)\]\s+/.test(l) })
    file.setText(lines.join("\n"))
  }

  property Process mkdir: Process {
    command: ["sh", "-c", "mkdir -p \"$1\" && [ -e \"$2\" ] || printf '%s\\n' '- [ ] Right-click a widget for settings' > \"$2\"", "sh", root.dir, root.path]
    running: true
    onExited: file.reload()
  }

  property FileView file: FileView {
    path: root.path
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.parse(text())
    onFileChanged: reload()
  }
}
