# DirtyDentist-GUI (DD-GUI)
![Logo](/logo.png)

A GUI component library for [Defold](https://defold.com), originally developed for educational software. Covers buttons, toggle buttons, checkboxes, radio buttons, sliders, single- and multi-line text inputs, comboboxes, auto-suggest boxes, and scrollable text blocks. Text inputs support mid-string editing and cursor navigation with arrow keys.

Dark, flat visual style: white text on grey surfaces with a blue accent. Made for mouse and touch.

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

### HTML5 template

`dd-gui/HTML/engine_template.html` is an HTML5 template with a loading page in the same dark look: black, the title of the project in small capitals, "Loading …" ("Laddar …" in a Swedish browser) and a thin progress bar, where the loading screen of an application built with these widgets has them. To use it, point `game.project` at it:

```
[html5]
htmlfile = /dd-gui/HTML/engine_template.html
```

The splash image of `game.project` is not shown. Nothing in how the engine is loaded differs from Defold's own template; the texts lie behind the canvas, which covers them when the engine starts to draw.

---

## Global settings

```lua
D.scrollSpeed          -- scroll distance per wheel tick (default 18)
D.textMagnification    -- text scale used by magnified comboboxes (default 0.75)
D.isMobileDevice       -- true on phones and tablets (detected when the module is loaded)
D.touchPadding         -- touch screens: how far outside its edges a small control can be hit (default 10, 0 = off)
D.dragThreshold        -- a dropdown list dragged further than this is scrolled, not clicked (default 10)
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

Runs by itself when the module is loaded, so you only need to call it if you want to detect again.

### Touch screens

On a phone or tablet (`D.isMobileDevice`), and whenever an input action comes from a touch screen (`action.touch`), the widgets adapt to a finger instead of a mouse:

- **No hover is left behind.** A finger has no position once it is lifted, so after a tap the widget goes back to its idle color, its tooltip is hidden and the focus is released. (A mouse stays on the widget, which keeps its hover color - as before.)
- **Larger hit areas for small controls.** Checkboxes, radio buttons and the handle of a slider can be hit `D.touchPadding` outside their edges. A touch right on another small control always belongs to that control.
- **Sliders:** pressing anywhere on the track takes hold of the handle - it jumps to the finger and follows it. (This also works with a mouse.)
- **Dropdown lists:** dragging the list scrolls it without choosing the row where the finger is lifted. A tap chooses.

If you have your own small control that should get the same larger hit area, pick it with `D.pick(self, node)` instead of `gui.pick_node`.

### Several gui scenes

`D` is one table shared by every script (with `shared_state` on), so the focus is shared too. The first time a gui scene calls a widget, any focus left behind by a scene that has been unloaded is cleared - otherwise a text box that still had the focus when its collection proxy was unloaded would lock every widget of the next scene.

### Marking answers

```lua
local value = D.combobox(self, action_id, action, "answer", list, true)
D.mark(self, "answer", is_right and "correct" or "wrong")   -- after the widget call
```

### Accent color

```lua
D.setAccent(vmath.vector4(0.85, 0.64, 0.25, 1))   -- in init(), before the first widget call
```

Sets `D.colors.accent` and makes the hover and pressed variants from it. `D` is shared between all scripts, so every scene that cares should set its own accent.

`D.mark(self, node, state, dimmed)` tints a text box, combobox, auto-suggest box, checkbox or radio button with `D.colors.correct` / `D.colors.wrong` (or any color you pass). `dimmed` halves the opacity, for an answer that can no longer be changed. `nil` as state leaves the widget alone.

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
D.textblock(self, action_id, action, node, enabled)
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

The widgets are drawn with white and grey images that the scripts tint (`gui.set_color`), so the whole look is in `D.colors`. Colors can be overridden by replacing entries after `require`:

```lua
-- Buttons
D.colors.active          -- idle
D.colors.hover           -- the pointer is on it
D.colors.select          -- held down
D.colors.inactive        -- disabled
-- Accent (accent buttons, a toggle button that is on, a ticked checkbox, slider level, combobox arrow)
D.colors.accent
D.colors.accenthover
D.colors.accentselect
-- Text
D.colors.text
D.colors.text_inactive   -- disabled widgets and placeholders
-- Text boxes and the box of a combobox / auto-suggest box
D.colors.field
D.colors.field_hover     -- the pointer is on it, or it has the focus
D.colors.field_inactive
-- Checkbox and radio button (not ticked)
D.colors.box
D.colors.box_hover
D.colors.box_inactive
-- Rows of a dropdown list (the four must differ from each other)
D.colors.row
D.colors.row_chosen
D.colors.row_hover
D.colors.row_select
-- Slider track, background of a text block
D.colors.track
D.colors.panel
D.colors.panel_inactive
-- Marking answers (D.mark)
D.colors.correct
D.colors.wrong
-- Plain colors
D.colors.green
D.colors.red
D.colors.black
D.colors.white
```

The images are white where the color is to show at full strength (frames, the line under a text box) and grey where it is to be darker (the fill). So a widget stays readable with white text whatever color it is given - also one you set yourself, for instance to mark an answer:

```lua
local value = D.combobox(self, action_id, action, "answer", list, true)
D.mark(self, "answer", "correct")   -- after the widget call; or gui.set_color(gui.get_node("answer/textbox"), <any color>)
```

The prefabs carry the idle colors too (that is what is shown until the first input reaches the gui). If you change `active`, `field`, `box`, `row`, `track`, `panel` or `text`, change the prefabs to match.

The images are drawn by a small script (`tools/make_ddgui_images.py`, Python with Pillow) - run it again if you want other proportions between frame and fill.

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

**0.5.0**
- New look: dark and flat, white text, square corners. All colors are in `D.colors` (new entries for text, text boxes, checkboxes, list rows, slider track and text block); the images are white/grey and tinted by the scripts
- New images `field`, `checkbox`, `knob`; the prefabs have the same nodes as before (only the inside of the slider has new sizes), so scenes that use them need no changes
- Buttons show their own color while held down (`D.colors.select` / `accentselect`)
- Disabled text boxes and comboboxes dim their text
- Touch screens: no hover, tooltip or focus is left behind after a tap; larger hit areas for checkbox, radio button and slider (`D.touchPadding`, `D.pick`); dragging a dropdown list scrolls without choosing (`D.dragThreshold`)
- Slider: thinner track and a smaller handle; pressing on (or just beside) the track takes hold of the handle; the value popup is hidden when the pointer leaves
- Dropdown lists (combobox, auto-suggest box): the list is as wide as the box and as tall as its rows (at most six, then it scrolls); the rows go edge to edge with their text under the text of the box; the chosen row has an accent bar and its own color `D.colors.row_chosen`; a scroll indicator that shows how much of the list is in view; the arrow keys no longer scroll past the end of the list
- `D.mark` and `D.colors.correct` / `wrong` for marking answers
- `D.setAccent(color)`; the marker of the chosen row in a dropdown list and a slider given a value in `init()` now follow `D.colors`
- A focus left behind by an unloaded gui scene no longer locks the widgets of the next scene
- `D.check_device` runs when the module is loaded
- HTML5: `dd-gui/HTML/engine_template.html` shows a dark loading page (the project's title, "Loading …" and a thin progress bar) instead of Defold's white page with the splash image
- `D.colors.active`, `hover`, `select` and `inactive` are now the button colors (they used to be shared by all widgets)

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
