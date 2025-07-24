# DirtyDentist-GUI (DD-GUI)
![Logo](/logo.png)

A basic GUI library for Defold developed for use in a educational software. It covers the essentials including; comboboxes, auto-suggestbox, simple buttons, checkboxes, radio buttons, text fields, text boxes and text blocks. Notably, the text components allow for mid-string editing and navigation using arrow keys.

Graphics inspired by WinUI 3.

Since rebuild in 0.3.0 functions and implementations have changed but old codebase is included for compability.

[HTML5 Example](https://skogsheden.se/dirtydentist)

![Screenshot](/screenshot.png)

## Changelog

**0.3.0:**

- New release with imporved funcionality and rewritten codebase

**0.3.1:**

- Added scrollable textblock
- Improved tab function
- Added animations to markers
- Bugfixes

**0.3.2:**

- Fix breaking change in action from Defold

**0.3.3:**

- Bugfix

## Implementation

Use included prefabs and name after hearts content. Implement in GUI script under function on_input(self, action_id, action) as described below if not else specified. 

### Buttons

**Simple button:**

*Function returns true or false*

```lua
button(self, action_id, action, node, enabled, accent, text)
```

*Turn button on and of not trough input method*

```lua
toggleActive(self, node, enabled)
```

**Toggle button:**

*Toggle button - turns on and off*

```lua
togglebutton(self, action_id, action, node, enabled, text)
```

**Checkbox:**

*Function returns true or false*

```lua
checkbox(self, action_id, action, node, enabled, standard_value, text)
```

*Clear checkboxs trough script*

```lua
clearCheckbox (self, node)
```

*Select all/three state checkbox*

```lua
checkboxSelectall(self, action_id, action, node, othernodes, enabled, standard_value, text)
```

*Initialize value of checkbox in the inti function*

```lua
initializeCheckbox(self, node, value, enabled)
```

**Radiobutton:**

*Function which button that is selected*

```lua
radiobutton(self, action_id, action, node, enabled, group)
```

### Slider

*Function returns value between min and max*

```lua
slider(self, action_id, action, node, enabled, showpopup, min, max)
```

*Reset values*

```lua
resetSlider(self, node)
```

### Combobox

**Simple dropdown:**

*Returns selected value*

```lua
dropdown_interact(self, action_id, action, "NodeName",ListName, active(boolean), "TabToNodeName")
```

**Combobox:**

*Returns selected value*

```lua
combobox(self, action_id, action, node, list, enabled, up, use_mag, standardValue)
```

*Set values trough script*

```lua
setValueCombobox(self, node, value)
```

**Auto suggestbox:**

*Returns selected value and takes text input for search*

```lua
auto_suggestbox(self, action_id, action, node, list, enabled, up, use_mag, id, tab_to)
```

*Set values trough script*

```lua
setValueAutobox(self, node, value, active)
```

*Localise standard values*

```lua
localisation_of_strings("Nothing found", "Select")
```

### Text

**Textbox:**

*Returns text*

```lua
textbox(self, action_id, action, node, enabled, tab_to)
```

*Clear textbox*

```lua
clearTextbox(self, node)
```

*Set textbox*
```lua
setTextbox(self, node, text)
```

**Multi-line textbox:**

*Returns text*

```lua
textboxMultiline(self, action_id, action, node, enabled, tab_to)
```

*Clear textbox and input trough script*

```lua
clearTextbox(self, node)
```

**Textblock:**

*Change text in textblock*

```lua
setTextblock(self, node, text)
```

*Returns nothing but displays a scrollobale textblock*

```lua
textBlock(self, action_id, action, node, enabled)
```