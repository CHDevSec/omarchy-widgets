import QtQuick
import Quickshell
import Quickshell.Io

// This week's events, as a snapshot Claude writes from Google Calendar
// through its connector (`bin/omarchy-widgets-agenda`). Also warns a few
// minutes before each event starts, with a notification that can open
// the Meet.
QtObject {
  id: root

  readonly property string path: Quickshell.env("HOME") + "/.local/share/omarchy-widgets/agenda.json"
  property int warnMinutes: 5

  // [{ title, icon, start: Date, end: Date, allDay, color, meet, url }]
  property var events: []
  property date updated: new Date(0)
  readonly property bool loaded: updated.getTime() > 0
  property var _warned: ({})

  property FileView file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var d = JSON.parse(text() || "{}")
        root.events = (d.events || []).map(function(e) {
          return { title: e.title, icon: e.icon || "", start: new Date(e.start), end: new Date(e.end),
                   allDay: !!e.allDay, color: e.color || "", meet: e.meet || "", url: e.url || "" }
        })
        root.updated = d.updated ? new Date(d.updated) : new Date(0)
      } catch (err) {
        root.events = []
      }
    }
    onFileChanged: reload()
  }

  // Look every 30 s for an event about to start.
  property Timer warn: Timer {
    interval: 30000
    running: root.events.length > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      var now = new Date()
      for (var i = 0; i < root.events.length; i++) {
        var e = root.events[i]
        if (e.allDay) continue
        var mins = (e.start - now) / 60000
        var key = e.title + e.start.getTime()
        if (mins > 0 && mins <= root.warnMinutes && !root._warned[key]) {
          root._warned[key] = true
          var body = Qt.formatTime(e.start, "HH:mm") + "–" + Qt.formatTime(e.end, "HH:mm") + (e.meet ? "  ·  Google Meet" : "")
          Quickshell.execDetached(["notify-send", "-a", "Agenda", "-u", "critical",
            "Em " + Math.ceil(mins) + " min: " + e.title, body])
        }
      }
    }
  }
}
