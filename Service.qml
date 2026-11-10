import QtQuick
import Quickshell
import Quickshell.Io

// Omarchy Widgets: desktop widgets on the wallpaper, under every window.
//
// One layer-shell surface per screen on the Bottom layer (above the
// wallpaper, below windows), so the widgets show on an empty workspace and
// windows cover them, the way macOS desktop widgets behave. Only the cards
// take input; the rest of the surface lets clicks through.
//
// Positions are dragged in place and remembered per screen in
// ~/.local/state/omarchy-widgets/positions.json.
Item {
  id: root

  // Injected by omarchy-shell's service loader.
  property var shell: null

  // The screen the widgets live on: the one named in positions.json's
  // "monitor" key, else the first screen.
  readonly property string monitor: String(prefs.monitor || "")
  readonly property var targetScreens: {
    var all = Quickshell.screens
    for (var i = 0; i < all.length; i++)
      if (all[i].name === root.monitor) return [all[i]]
    return all.length > 0 ? [all[0]] : []
  }

  // ------------------------------------------------------------ positions
  property var prefs: ({})

  function positionFor(screenName, widgetId) {
    var s = prefs.screens && prefs.screens[screenName]
    return s && s[widgetId] ? s[widgetId] : null
  }

  function savePosition(screenName, widgetId, x, y) {
    var next = JSON.parse(JSON.stringify(prefs || {}))
    if (!next.screens) next.screens = {}
    if (!next.screens[screenName]) next.screens[screenName] = {}
    next.screens[screenName][widgetId] = { x: Math.round(x), y: Math.round(y) }
    prefs = next
    saveTimer.restart()
  }

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy-widgets"

  Process {
    id: mkdir
    command: ["mkdir", "-p", root.stateDir]
    running: true
  }

  FileView {
    id: stateFile
    path: root.stateDir + "/positions.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try { root.prefs = JSON.parse(text() || "{}") || {} } catch (e) { root.prefs = {} }
    }
  }

  // Dragging writes once it settles, not on every release.
  Timer {
    id: saveTimer
    interval: 400
    onTriggered: stateFile.setText(JSON.stringify(root.prefs, null, 2) + "\n")
  }

  // ---------------------------------------------------------------- stats
  // One shared sampler for every screen's system card.
  SystemStats { id: statsObj }

  Variants {
    model: root.targetScreens

    delegate: Component {
      WidgetsWindow {
        required property var modelData
        screen: modelData
        service: root
        stats: statsObj
      }
    }
  }
}
