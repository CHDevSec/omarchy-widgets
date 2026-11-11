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
// Everything is set from the widgets themselves (right-click any card) and
// kept in ~/.local/state/omarchy-widgets/settings.json:
//   monitor    "all" or a screen name
//   locked     true stops dragging
//   snap       false turns off the drag grid and edge guides
//   gridSize   grid step in px (12, 24 or 48)
//   widgets    { id: false } hides one
//   screens    { screenName: { id: { x, y } } } dragged positions
Item {
  id: root

  // Injected by omarchy-shell's service loader.
  property var shell: null

  // Every widget the plugin draws, in the order Settings lists them.
  readonly property var catalog: [
    { id: "clock", name: "Clock", description: "The time, large, with the date" },
    { id: "calendar", name: "Calendar", description: "This month, today marked" },
    { id: "system", name: "System", description: "CPU, memory, disk and battery" },
    { id: "notes", name: "Notes", description: "Quick notes and to-dos, Claude's included" },
    { id: "week", name: "Week", description: "This week's events and meetings, from Google Calendar" },
    { id: "trello", name: "Trello", description: "Cards that need you, kept up to date by Claude" },
    { id: "weather", name: "Weather", description: "Now and the next days, from wttr.in" },
    { id: "media", name: "Now Playing", description: "Whatever is playing, with controls" },
    { id: "worldclock", name: "World Clock", description: "The cities from the bar's Elsewhen" }
  ]

  // The clock's faces and formats, as Settings offers them. Font faces
  // missing on this machine are left out there.
  readonly property var clockFaces: [
    { id: "theme", name: "Omarchy" },
    { id: "pixel", name: "Pixel" },
    { id: "Adwaita Sans", name: "Sans" },
    { id: "Nimbus Sans Narrow", name: "Narrow" },
    { id: "C059", name: "Serif" },
    { id: "iA Writer Quattro S", name: "Writer" }
  ]
  readonly property var clockFormats: [
    { id: "24h", name: "24h" },
    { id: "12h", name: "12h" },
    { id: "stacked", name: "Stacked" },
    { id: "analog", name: "Analog" }
  ]

  // ------------------------------------------------------------- settings
  property var prefs: ({})

  readonly property string monitor: String(prefs.monitor || "all")
  readonly property bool locked: prefs.locked === true
  // Dragging snaps to a grid (shown while you drag) and to other widgets' edges.
  readonly property bool snap: prefs.snap !== false
  readonly property int gridSize: Number(prefs.gridSize) > 0 ? Number(prefs.gridSize) : 24

  // Each widget's own look, never a global one:
  //   background  card background opacity
  //   opacity     the whole widget's opacity
  function styleOf(id) {
    var st = prefs.style && prefs.style[id] ? prefs.style[id] : {}
    return {
      // Unset: the old shared value from 0.3, else 0.85.
      background: st.background !== undefined ? Number(st.background)
        : prefs.backgroundOpacity !== undefined ? Number(prefs.backgroundOpacity) : 0.85,
      opacity: st.opacity !== undefined ? Number(st.opacity)
        : prefs.widgetOpacity !== undefined ? Number(prefs.widgetOpacity) : 1.0,
      // Size: the whole widget scaled, 0.6× to 2×.
      scale: Number(st.scale) > 0 ? Math.max(0.6, Math.min(2, Number(st.scale))) : 1.0,
      // Stretch: the content's width and height in px; 0 = its natural size.
      width: Number(st.width) > 0 ? Number(st.width) : 0,
      height: Number(st.height) > 0 ? Number(st.height) : 0
    }
  }
  // A widget's own option (clock face, format…), with a default.
  function option(id, key, fallback) {
    var st = prefs.style && prefs.style[id] ? prefs.style[id] : {}
    return st[key] === undefined ? fallback : st[key]
  }

  function setStyle(id, key, value) {
    update(function(p) {
      if (!p.style) p.style = {}
      if (!p.style[id]) p.style[id] = {}
      p.style[id][key] = typeof value === "number" ? Math.round(value * 100) / 100 : value
    })
  }
  readonly property var targetScreens: {
    var all = Quickshell.screens
    if (root.monitor === "all") return all
    for (var i = 0; i < all.length; i++)
      if (all[i].name === root.monitor) return [all[i]]
    return all
  }

  function widgetOn(id) {
    return !(prefs.widgets && prefs.widgets[id] === false)
  }

  function update(mutate) {
    var next = JSON.parse(JSON.stringify(prefs || {}))
    mutate(next)
    prefs = next
    saveTimer.restart()
  }

  function setMonitor(name) { update(function(p) { p.monitor = name }) }
  function setLocked(on) { update(function(p) { p.locked = !!on }) }
  function setSnap(on) { update(function(p) { p.snap = !!on }) }
  function setGridSize(n) { update(function(p) { p.gridSize = n }) }
  // Back to the natural size: no stretch, no scale.
  function resetSize(id) {
    update(function(p) {
      if (p.style && p.style[id]) { delete p.style[id].width; delete p.style[id].height; delete p.style[id].scale }
    })
  }
  function setWidget(id, on) {
    update(function(p) { if (!p.widgets) p.widgets = {}; p.widgets[id] = !!on })
  }
  function resetPositions() { update(function(p) { delete p.screens }) }

  function positionFor(screenName, widgetId) {
    var s = prefs.screens && prefs.screens[screenName]
    return s && s[widgetId] ? s[widgetId] : null
  }

  function savePosition(screenName, widgetId, x, y) {
    update(function(p) {
      if (!p.screens) p.screens = {}
      if (!p.screens[screenName]) p.screens[screenName] = {}
      p.screens[screenName][widgetId] = { x: Math.round(x), y: Math.round(y) }
    })
  }

  // The card floating over windows: "settings" or "note" (add a note), on
  // which screen and where (-1 = centred). "" = closed.
  property string overlayKind: ""
  // The widget the settings card edits; right-clicking one picks it.
  property string settingsTarget: "clock"
  property string overlayScreen: ""
  property point overlayAt: Qt.point(-1, -1)
  function openOverlay(kind, screenName, x, y) {
    overlayAt = Qt.point(x, y)
    overlayScreen = screenName
    overlayKind = kind
  }
  function openSettings(screenName, x, y, widgetId) {
    if (widgetId) settingsTarget = widgetId
    openOverlay("settings", screenName, x, y)
  }
  function openNoteInput(screenName, x, y) { openOverlay("note", screenName, x, y) }
  function closeSettings() { overlayKind = "" }

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy-widgets"

  Process {
    command: ["mkdir", "-p", root.stateDir]
    running: true
  }

  FileView {
    id: settingsFile
    path: root.stateDir + "/settings.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try { root.prefs = JSON.parse(text() || "{}") || {} } catch (e) { root.prefs = {} }
    }
  }

  Timer {
    id: saveTimer
    interval: 400
    onTriggered: settingsFile.setText(JSON.stringify(root.prefs, null, 2) + "\n")
  }

  // `omarchy-shell omarchy-widgets settings`, for a keybind.
  IpcHandler {
    target: "omarchy-widgets"
    function settings(): void {
      var t = root.targetScreens
      root.openSettings(t.length > 0 ? t[0].name : "", -1, -1)
    }
    function close(): void { root.closeSettings() }
    function lock(): void { root.setLocked(true) }
    function unlock(): void { root.setLocked(false) }
    function resetsize(id: string): void { root.resetSize(id) }
    function toggle(id: string): void { root.setWidget(id, !root.widgetOn(id)) }
    // `set clock face pixel`, `set clock seconds true`
    function set(id: string, key: string, value: string): void {
      root.setStyle(id, key, value === "true" ? true : value === "false" ? false : value)
    }
    function note(): void {
      var t = root.targetScreens
      root.openNoteInput(t.length > 0 ? t[0].name : "", -1, -1)
    }
  }

  // ---------------------------------------------------------------- data
  // Shared by every screen's cards.
  // The theme's own colours, one per widget.
  readonly property var colors: paletteObj
  ThemeColors { id: paletteObj }

  SystemStats { id: statsObj }
  // Notes live in the widget's own file, or in a note of an Obsidian vault:
  // style.notes.vaultFile in settings.json, a path ("~/" allowed), e.g.
  //   omarchy-shell omarchy-widgets set notes vaultFile "~/Vault/Inbox.md"
  // Without one, Settings offers only the widget's own file.
  readonly property string vaultNotes: {
    var p = String(option("notes", "vaultFile", "") || "").trim()
    return p.indexOf("~/") === 0 ? Quickshell.env("HOME") + p.substring(1) : p
  }
  readonly property bool notesInVault: vaultNotes !== "" && option("notes", "source", "local") === "obsidian"
  NotesModel {
    id: notesObj
    path: root.notesInVault ? root.vaultNotes
      : Quickshell.env("HOME") + "/.local/share/omarchy-widgets/notes.md"
    inVault: root.notesInVault
  }
  TrelloModel { id: trelloObj }

  // Hyprland's gaps, so widgets keep to the area windows tile into: as far
  // from the bar, dock and screen edges as windows are (gaps_out), and as
  // far apart as two windows (gaps_in on each).
  property int gapsOut: 10
  property int gapsIn: 5
  Process {
    running: true
    command: ["sh", "-c", "hyprctl getoption general:gaps_out -j; echo; hyprctl getoption general:gaps_in -j"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.split("\n").filter(function(l) { return l.trim().length })
        function first(l) {
          try { var o = JSON.parse(l); return parseInt(String(o.css !== undefined ? o.css : o.int).split(" ")[0]) } catch (e) { return NaN }
        }
        var go = first(parts[0] || ""), gi = first(parts[1] || "")
        if (!isNaN(go)) root.gapsOut = go
        if (!isNaN(gi)) root.gapsIn = gi
      }
    }
  }
  AgendaModel { id: agendaObj }
  WeatherModel { id: weatherObj; active: root.widgetOn("weather") }
  WorldClockModel { id: worldObj; active: root.widgetOn("worldclock") }

  Variants {
    model: root.targetScreens

    delegate: Component {
      Scope {
        id: perScreen
        required property var modelData

        WidgetsWindow {
          screen: perScreen.modelData
          service: root
          stats: statsObj
          notes: notesObj
          trello: trelloObj
          agenda: agendaObj
          weather: weatherObj
          world: worldObj
        }

        // Settings float over windows, so they can be opened from anywhere.
        CardOverlayWindow {
          screen: perScreen.modelData
          service: root
          notes: notesObj
        }
      }
    }
  }
}
