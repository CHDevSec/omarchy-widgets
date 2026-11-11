# Omarchy Widgets

Desktop widgets for [Omarchy](https://omarchy.org/), macOS style: they sit on
the wallpaper, under your windows, and are drawn with Omarchy's own panels,
borders, fonts and theme colours, so they change with every theme switch.

An Omarchy shell plugin (Quickshell), id `io.github.chdevsec.omarchy-widgets`.

## Widgets

- **Clock**: 24h, 12h, stacked or analog, in several faces, including a
  pixel-art one drawn as solid blocks.
- **Calendar**: this month, with today marked.
- **System**: CPU, memory, disk and battery tiles that turn red when they
  run hot or low.
- **Notes**: quick to-dos, kept in a Markdown file. It can also point at a
  note in an Obsidian vault, so both apps edit the same list.
- **Week**: this week's events and meetings in a timeline, with the next
  meeting, a "now" line and one-click Meet links.
- **Trello**: the cards that need you (doing, in review, urgent in the
  backlog). Click a card to open it in the Trello web app.
- **Weather**: now and the next days, from wttr.in, for the place set in
  Omarchy's weather panel.
- **Now Playing**: whatever MPRIS player is playing, with controls. When
  nothing plays, it shows the Omarchy logo in pixel art.
- **World Clock**: the cities from the bar's Elsewhen.

## Moving and sizing

- **Drag** a widget anywhere. A guided grid shows while you drag.
- **Snapping**: widgets snap to the grid, to other widgets' edges and
  centres, to the same margin another widget keeps from the screen's sides,
  and to the same spacing already used between widgets.
- **Bounds**: widgets stay inside the area your windows tile into (Hyprland's
  `gaps_out`) and keep `2 × gaps_in` apart, like windows do.
- **Resizing**: drag the corner grip to stretch a widget. It snaps to other
  widgets' sizes, so you can match them. Double-click the grip to reset it.
  The zoom is in Settings.
- **Settings**: right-click any widget. From there you can show or hide each
  widget, pick screens, set opacity, background and size, change the clock
  face, lock positions and set the grid size.

## Light on the system

- **Paused while covered**: when a tiled or fullscreen window covers the
  desktop, nothing ticks or animates. The cards catch up the moment the
  desktop shows again.
- **No processes for stats**: system stats are read straight from `/proc`
  and `/sys`, with no process started per sample. Disk use is checked once
  a minute.
- **Minute-based updates**: clocks without seconds update once a minute, on
  the minute. Weather updates every 15 minutes.
- **Mouse input**: the layer only takes the mouse over the cards themselves.
  It never takes the keyboard.

## Install

```sh
omarchy plugin add https://github.com/CHDevSec/omarchy-widgets --enable
omarchy restart shell
```

The helper commands in `bin/` are optional. To use them, link them onto your
`PATH`:

```sh
ln -s ~/.config/omarchy/plugins/io.github.chdevsec.omarchy-widgets/bin/* ~/.local/bin/
```

## Commands

```sh
omarchy-shell omarchy-widgets settings          # open settings
omarchy-shell omarchy-widgets toggle clock      # show/hide a widget
omarchy-shell omarchy-widgets lock              # lock / unlock positions
omarchy-shell omarchy-widgets resetsize clock   # undo a resize
omarchy-shell omarchy-widgets set clock face pixel
omarchy-widgets-note "Buy milk"                 # add a to-do to Notes
```

### Notes in Obsidian

```sh
omarchy-shell omarchy-widgets set notes vaultFile "~/Vault/Inbox.md"
```

Then pick **Obsidian** under Source in the Notes settings.

### Trello and Week

These two cards show snapshots written to `~/.local/share/omarchy-widgets/`.
They need no API keys: an agent with Trello or Google Calendar access (for
example Claude with those connectors) runs the helper with what it read.

- `omarchy-widgets-trello search.json ...` writes `trello.json`.
- `omarchy-widgets-agenda events.json` writes `agenda.json`.

The cards update as soon as the files change. Desktop notifications fire
for new cards and five minutes before a meeting.

## Settings file

`~/.local/state/omarchy-widgets/settings.json` holds positions per screen,
which widgets are shown, and each widget's style. Delete it to start over.

## License

MIT
