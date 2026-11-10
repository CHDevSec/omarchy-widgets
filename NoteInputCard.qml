import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Type a note; Enter adds it as a to-do, Shift+Enter as a plain note.
Card {
  id: card
  widgetId: "note-input"
  movable: false
  contentWidth: Style.space(320)

  required property var notes
  property bool active: false

  onActiveChanged: if (active) { field.text = ""; field.forceActiveFocus() }

  function submit(asNote) {
    var t = field.text.trim()
    if (t !== "") card.notes.add(t, !asNote)
    card.service.closeSettings()
  }

  PanelSectionHeader { text: "NEW NOTE"; foreground: card.fg }

  TextField {
    id: field
    width: parent.width
    foreground: card.fg
    placeholderText: "What do you need to remember?"
    Keys.onReturnPressed: function(e) { card.submit((e.modifiers & Qt.ShiftModifier) !== 0) }
    Keys.onEnterPressed: function(e) { card.submit((e.modifiers & Qt.ShiftModifier) !== 0) }
    Keys.onEscapePressed: card.service.closeSettings()
  }

  Text {
    width: parent.width
    text: "Enter adds a to-do · Shift+Enter a plain note · Esc cancels"
    wrapMode: Text.Wrap
    color: card.dim
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    textFormat: Text.PlainText
  }
}
