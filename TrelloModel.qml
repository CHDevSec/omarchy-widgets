import QtQuick
import Quickshell
import Quickshell.Io

// The Trello cards that need you, as a snapshot Claude writes through its
// Trello connector (`bin/omarchy-widgets-trello`), so no API key lives on
// this machine. The widget only reads it; it updates whenever Claude runs
// the snapshot again.
//
// ~/.local/share/omarchy-widgets/trello.json:
//   { "updated": ISO date,
//     "sections": [ { "id", "title", "items": [ { "name", "board", "list", "url", "prio" } ] } ] }
QtObject {
  id: root

  readonly property string path: Quickshell.env("HOME") + "/.local/share/omarchy-widgets/trello.json"

  property var sections: []
  property date updated: new Date(0)
  readonly property bool loaded: updated.getTime() > 0
  readonly property int total: {
    var n = 0
    for (var i = 0; i < sections.length; i++) n += sections[i].items.length
    return n
  }

  property FileView file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var d = JSON.parse(text() || "{}")
        root.sections = d.sections || []
        root.updated = d.updated ? new Date(d.updated) : new Date(0)
      } catch (e) {
        root.sections = []
      }
    }
    onFileChanged: reload()
  }
}
