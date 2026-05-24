# DirtyDentist-GUI (DD-GUI)
![Logo](/logo.png)

A GUI component library for [Defold](https://defold.com), originally developed for educational software. Covers buttons, toggle buttons, checkboxes, radio buttons, sliders, single- and multi-line text inputs, comboboxes, auto-suggest boxes, and scrollable text blocks. Text inputs support mid-string editing and cursor navigation with arrow keys.

Visual style inspired by WinUI 3.

[HTML5 Example](https://skogsheden.se/dirtydentist) · [Screenshot](/screenshot.png)

---

## Setup

1. Copy the `dd-gui/` folder into your Defold project.
2. In your GUI scene, add the prefab `.gui` files you need as templates.
3. In your GUI script, require the main module at the top:

```lua
require "dd-gui.ddgui"
-- D is now a global table exposing all widget functions
```

4. Call widget functions inside `on_input(self, action_id, action)`. Every widget that takes input must be called every frame inside `on_input`.

---

## Global settings

```lua
D.scrollSpeed          -- scroll distance per wheel tick (default 18)
D.textMagnification    -- text scale used by magnified comboboxes (default 0.75)
D.isMobileDevice       -- set true to show/hide soft keyboard automatically
D.no_entries           -- placeholder shown when a list is empty (default "No entries found")
D.select_a_value       -- placeholder shown before a selection is made (default "Select a value")
```

### Localisation

```lua
D.set_localization_strings("Inga poster hittades", "Välj ett värde")
```

### Device detection

```lua
D.check_device(self)   -- auto-detects mobile and sets D.isMobileDevice
```

### Focus helpers

```lua
D.focusNode(self, node)   -- programmatically focus any textbox or auto-suggest node
D.clearFocus(self)         -- release focus from whichever widget has it
```

### Cross-widget enabled state

```lua
D.setEnabled(self, node, bool)  -- store an enabled flag for a node
D.getEnabled(self, node)        -- read it back (returns true if never set)
```

### Universal value reader

```lua
local value = D.getValue(self, node)
-- Works for textbox, textboxMultiline, combobox, auto_suggestbox,
-- slider, checkbox, radiobutton, and togglebutton.
```

---

## Buttons

All button functions live inside `on_input`.

### Simple button

Returns `true` on the frame the button is clicked, `false` otherwise.

```lua
local pressed = D.button(self, action_id, action, node, enabled, accent, text)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `node` | string | Node name in the scene |
| `enabled` | bool | Whether the button responds to input |
| `accent` | bool | Use accent colour instead of default |
| `text` | string\|nil | Tooltip text (optional) |

Enable or disable a button from script without going through input:

```lua
D.toggleActive(self, node, enabled)
```

### Toggle button

Returns `(value, changed)` — `value` is the current on/off state; `changed` is `true` only on the frame the value flips.

```lua
local value, changed = D.togglebutton(self, action_id, action, node, enabled, text)
```

Set state from script:

```lua
D.setTogglebutton(self, node, value)
```

---

## Checkbox

### Standard checkbox

Returns `(value, changed)`.

```lua
local value, changed = D.checkbox(self, action_id, action, node, enabled, standard_value, text)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `standard_value` | bool\|nil | Initial value (only applied on first frame) |
| `text` | string\|nil | Tooltip shown on hover |

### Select-all checkbox

Drives a set of sibling checkboxes. Shows a dash when some (but not all) siblings are checked.

```lua
local value, changed = D.checkboxSelectall(self, action_id, action, node, othernodes, enabled, standard_value, text)
```

`othernodes` is a table of node name strings for the sibling checkboxes.

### Programmatic control

```lua
D.initializeCheckbox(self, node, value, enabled)  -- set initial state in init()
D.setCheckbox(self, node, value)                   -- set value + visual, no spurious changed
D.toggleCheckbox(self, node)                       -- flip current value
D.clearCheckbox(self, node)                        -- reset to unchecked
```

---

## Radio button

Buttons in the same group are mutually exclusive. Returns `(value, changed)` per button — `value` is `true` if this button is selected.

```lua
local value, changed = D.radiobutton(self, action_id, action, node, enabled, group)
```

`group` is a table of all node name strings in the group (including this node).

### Programmatic control

```lua
D.initializeRadiobutton(self, node, value, enabled)   -- set initial state in init()
D.setRadiobutton(self, node, value, group)             -- select/deselect, deselects siblings
D.clearRadiogroup(self, group)                         -- deselect every button in a group
local selected = D.getSelectedInGroup(self, group)    -- returns selected node name, or nil
```

---

## Slider

Returns `(value, changed)`. Value is an integer by default; pass `step` for float snapping.

```lua
local value, changed = D.slider(self, action_id, action, node, enabled, showpopup, min, max, step)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `showpopup` | bool | Show a floating value label while dragging |
| `min` | number | Minimum value (default 0) |
| `max` | number | Maximum value (default 100) |
| `step` | number\|nil | Snap increment, e.g. `0.5`. Nil = floor to integer |

### Programmatic control

```lua
D.setValueSlider(self, node, value, min, max, step)  -- move handle to value
D.resetSlider(self, node)                             -- reset to midpoint
D.setMinMax(self, node, min, max)                     -- change range without resetting handle
```

---

## Textbox (single-line)

Returns `(text, changed)`.

```lua
local text, changed = D.textbox(self, action_id, action, node, enabled, tab_to, placeholder, maxlength, readonly)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `tab_to` | string\|nil | Node name to jump focus to on Tab |
| `placeholder` | string\|nil | Hint text shown when empty and unfocused |
| `maxlength` | number\|nil | Maximum character count (nil = unlimited) |
| `readonly` | bool\|nil | Disables focus and typing when true |

### Programmatic control

```lua
D.setTextbox(self, node, text)   -- set content
D.clearTextbox(self, node)        -- clear content
```

---

## Multi-line textbox

Returns `(text, changed)` — text is the full content with `\n` line separators.

```lua
local text, changed = D.textboxMultiline(self, action_id, action, node, enabled, tab_to)
```

Supports mouse-click positioning, arrow key navigation between lines, Enter to split lines, and touch/drag scrolling.

### Programmatic control

```lua
D.setTextboxMultiline(self, node, text)            -- replace full content (splits on \n)
D.clearTextboxMultiline(self, node)                 -- clear all lines
D.appendLineTextboxMultiline(self, node, text)      -- append one line without clearing
```

---

## Combobox

A dropdown selector. Returns `(value, changed)`.

```lua
local value, changed = D.combobox(self, action_id, action, node, list, enabled, up, use_mag, standardValue)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `list` | table | Table of string options |
| `up` | bool | Open the dropdown upward instead of downward |
| `use_mag` | bool | Apply `D.textMagnification` scale to list text |
| `standardValue` | string\|nil | Pre-selected value on first frame |

Supports keyboard navigation (↑ ↓ Enter) and scroll wheel.

### Programmatic control

```lua
D.setValueCombobox(self, node, value)       -- select a value by string
D.setListCombobox(self, node, list)          -- swap the source list at runtime
D.clearCombobox(self, node)                  -- reset to placeholder
D.initializeCombo(self, node, list, up, enabled)  -- call in init() before first frame
```

---

## Auto-suggest box

A text input that filters a list as the user types. Returns `(value, changed)`.

```lua
local value, changed = D.auto_suggestbox(self, action_id, action, node, list, enabled, up, use_mag, id, tab_to)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `list` | table | Full list of options to filter |
| `up` | bool | Open dropdown upward |
| `use_mag` | bool | Apply `D.textMagnification` scale |
| `id` | string\|nil | An optional identifier stored in the `ID` node |
| `tab_to` | string\|nil | Node to jump focus to on Tab |

### Programmatic control

```lua
D.setValueAutobox(self, node, value, active)    -- set displayed value; active styles arrow accent
D.initializeAutobox(self, node, value, active)  -- same, but also prevents spurious changed
D.setListAutobox(self, node, list)               -- swap the source list at runtime
D.clearAutobox(self, node)                        -- reset to placeholder
```

---

## Textblock

A read-only, scrollable text display. Call every frame inside `on_input`.

```lua
D.textBlock(self, action_id, action, node, enabled)
```

### Setting content

```lua
D.setTextblock(self, node, text)           -- replace content (resets scroll to top)
D.clearTextblock(self, node)                -- clear content
D.appendTextblock(self, node, text)         -- append text with automatic newline separator
```

### Reading content

```lua
local text = D.getTextblock(self, node)
```

### Scroll control

```lua
D.scrollToBottomTextblock(self, node)
D.scrollToTopTextblock(self, node)
```

---

## Color palette

Colors can be overridden by replacing entries in `D.colors` after `require`:

```lua
D.colors.active      -- default widget background  (white)
D.colors.hover       -- hovered state
D.colors.select      -- selected item in a list
D.colors.inactive    -- disabled state (grey, semi-transparent)
D.colors.accent      -- primary accent (blue)
D.colors.accenthover -- accent on hover (slightly transparent)
D.colors.green
D.colors.red
D.colors.black
D.colors.white
```

---

## Return values

Every interactive widget returns `(value, changed)`:

- `value` — current state (string, number, or bool depending on widget).
- `changed` — `true` only on the frame the value changed; `false` every other frame.

`changed` is always `false` on the very first frame so loading saved data never fires spurious change events.

```lua
local text, changed = D.textbox(self, action_id, action, "myBox", true)
if changed then
    print("User typed:", text)
end
```

---

## Changelog

**0.4.0**
- All widgets now return `(value, changed)` dual values
- Added programmatic set/clear/initialize functions for every widget type
- `setValueSlider` renamed from `setvalueSlider` (old name kept as alias)
- Slider: optional `step` parameter for float/snapping mode; new `setMinMax`
- Textbox: optional `placeholder`, `maxlength`, and `readonly` parameters
- Textbox multiline: `appendLineTextboxMultiline`
- Checkbox: `setCheckbox`, `toggleCheckbox`
- Radio button: `getSelectedInGroup`
- Combobox / autobox: `setListCombobox`, `setListAutobox`, `initializeAutobox`
- Textblock: `appendTextblock`, `scrollToBottomTextblock`, `scrollToTopTextblock`, `getTextblock`
- Cross-widget: `D.getValue`, `D.setEnabled`, `D.getEnabled`, `D.focusNode`, `D.clearFocus`
- Fixed `gui.get_node` crash in combobox when cloned dropdown nodes don't exist
- Fixed `updateDropdownSafe` overwriting node count before deletion
- All Swedish comments translated to English

**0.3.3** — Bugfix

**0.3.2** — Fix breaking change in Defold action API

**0.3.1** — Scrollable textblock, improved Tab handling, marker animations, bugfixes

**0.3.0** — Rewritten codebase, improved functionality
