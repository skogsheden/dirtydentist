-- ddgui.lua
-- Main module for Dirty Dentist GUI

D = {}

-- Require submodules
local button = require "dd-gui.prefabs.scripts.button"
local checkbox = require "dd-gui.prefabs.scripts.checkbox"
local radiobutton = require "dd-gui.prefabs.scripts.radiobutton"
local textbox = require "dd-gui.prefabs.scripts.textbox"
local slider = require "dd-gui.prefabs.scripts.slider"
local combobox = require "dd-gui.prefabs.scripts.combobox"
local textblock = require "dd-gui.prefabs.scripts.textblock"

-- Pulsate functions for markers
local pulsate_duration = 0.8 -- Duration for one full fade cycle

-- Expose input methods
D.button = button.button
D.togglebutton = button.togglebutton
D.checkbox = checkbox.checkbox
D.checkboxSelectall = checkbox.checkboxSelectall
D.radiobutton = radiobutton.radiobutton
D.textbox = textbox.textbox
D.textboxMultiline = textbox.textboxMultiline
D.slider = slider.slider
D.combobox = combobox.combobox
D.auto_suggestbox = combobox.auto_suggestbox

-- Expose display methods
D.textblock = textblock.textBlock

-- Expose additional functions
D.clearTextbox              = textbox.clearTextbox
D.setTextbox                = textbox.setTextbox
D.clearTextboxMultiline     = textbox.clearTextboxMultiline
D.setTextboxMultiline       = textbox.setTextboxMultiline
D.appendLineTextboxMultiline = textbox.appendLineTextboxMultiline
D.toggleActive              = button.toggleActive
D.setTogglebutton           = button.setTogglebutton
D.initializeCombo           = combobox.initialize
D.setValueCombobox          = combobox.setValueCombobox
D.setValueAutobox           = combobox.setValueAutobox
D.clearCombobox             = combobox.clearCombobox
D.clearAutobox              = combobox.clearAutobox
D.setListCombobox           = combobox.setListCombobox
D.setListAutobox            = combobox.setListAutobox
D.initializeAutobox         = combobox.initializeAutobox
D.resetSlider               = slider.resetSlider
D.setValueSlider            = slider.setValueSlider
D.setvalueSlider            = slider.setvalueSlider -- deprecated alias, use setValueSlider
D.setMinMax                 = slider.setMinMax
D.initializeCheckbox        = checkbox.initializeCheckbox
D.clearCheckbox             = checkbox.clearCheckbox
D.setCheckbox               = checkbox.setCheckbox
D.toggleCheckbox            = checkbox.toggleCheckbox
D.setTextblock              = textblock.setTextblock
D.clearTextblock            = textblock.clearTextblock
D.appendTextblock           = textblock.appendTextblock
D.scrollToBottomTextblock   = textblock.scrollToBottomTextblock
D.scrollToTopTextblock      = textblock.scrollToTopTextblock
D.getTextblock              = textblock.getTextblock
D.initializeRadiobutton     = radiobutton.initializeRadiobutton
D.setRadiobutton            = radiobutton.setRadiobutton
D.clearRadiogroup           = radiobutton.clearRadiogroup
D.getSelectedInGroup        = radiobutton.getSelectedInGroup

-- Shared variables (if needed)
D.colors = {
	active		= vmath.vector4(1, 1, 1, 1),
	hover		= vmath.vector4(0.85, 0.85, 0.85, 1),
	select		= vmath.vector4(0.8, 0.8, 0.8, 0.95),
	inactive	= vmath.vector4(0.3, 0.3, 0.3, 0.5),
	accent		= vmath.vector4(0.17, 0.50, 0.79, 1),
	accenthover	= vmath.vector4(0.17, 0.50, 0.79, 0.8),
	green		= vmath.vector4(0.1, 1, 0.1, 1),
	red			= vmath.vector4(1, 0.1, 0.1, 1),
	black		= vmath.vector4(0, 0, 0,  1),
	white		= vmath.vector4(1, 1, 1,  1)
}

D.isMobileDevice = false
D.scrollSpeed = 18
D.textMagnification = 0.75
D.nodes = {}
D.currentMousePos = {x = 0, y = 0}

-- Localization strings
D.no_entries = "No entries found"
D.select_a_value = "Select a value"

-- Return the current stored value for any widget node.
-- Works for textbox, combobox/autobox (comboboxData.value),
-- slider (sliderData.value), checkbox, radiobutton, and togglebutton.
function D.getValue(self, node)
	if self.textboxData and self.textboxData[node] then
		-- textboxMultiline returns the joined text string
		if self.textboxData[node].lines then
			local parts = {}
			for i = 1, #self.textboxData[node].lines do
				parts[i] = gui.get_text(self.textboxData[node].lines[i].text)
			end
			return table.concat(parts, "\n")
		end
		return self.textboxData[node].text or ""
	elseif self.comboboxData and self.comboboxData[node] then
		return self.comboboxData[node].value
	elseif self.slider and self.slider[node] then
		return self.slider[node].value
	elseif self.checkbox and self.checkbox[node] then
		return self.checkbox[node].value
	elseif self.radiobutton and self.radiobutton[node] then
		return self.radiobutton[node]
	elseif self.pressed_buttons and self.pressed_buttons[node] ~= nil then
		return self.pressed_buttons[node]
	end
	return nil
end

-- Programmatically give focus to a textbox node (single-line or multi-line).
-- Activates the pulsating marker so keyboard input is routed to that node.
function D.focusNode(self, node)
	D.nodes["active"] = node
	D.nodes["tab"]    = true  -- triggers the multiline path to sync the marker
end

-- Release focus from whichever widget currently has it.
function D.clearFocus(self)
	D.nodes["active"] = nil
	D.nodes["tab"]    = false
end

-- Cross-widget enabled/disabled state helpers.
-- Store a per-node enabled flag that calling scripts can read back via D.getEnabled.
-- The widget functions themselves still receive 'enabled' directly, but these helpers
-- let you centralise enable/disable decisions across scenes without re-checking every
-- individual widget state.
function D.setEnabled(self, node, bool)
	self.widgetEnabled       = self.widgetEnabled or {}
	self.widgetEnabled[node] = bool
end

-- Returns the stored enabled state for a node, or true if none has been set.
function D.getEnabled(self, node)
	if self.widgetEnabled and self.widgetEnabled[node] ~= nil then
		return self.widgetEnabled[node]
	end
	return true
end

-- Function to set localization strings
function D.set_localization_strings(no_entries_str, select_value_str)
	D.no_entries = no_entries_str
	D.select_a_value = select_value_str
end

-- Function to check device type (if needed)
function D.check_device(self)
	local info = sys.get_sys_info()
	local user_agent = info.user_agent or ""

	if info.system_name == "HTML5" then
		local user_agent_lower = user_agent:lower()
		if user_agent_lower:find("android") or user_agent_lower:find("iphone") or user_agent_lower:find("ipad") then
			D.isMobileDevice = true
		end
	elseif info.system_name == "Android" then 
		D.isMobileDevice = true
	elseif  info.system_name == "iPhone OS" then
		D.isMobileDevice = true
	end
end

-- Function that limits input values
function D.valuelimit(v, min, max)
	if v < min then
		return min
	elseif v > max then
		return max
	end
	return v
end

-- Pulsation of markers
function D.pulsate(node)
	local current_color = D.colors.hover
	local target_color = vmath.vector4(current_color.x, current_color.y, current_color.z, 1)
	gui.set_color(node, D.colors.black)
	gui.animate(node, gui.PROP_COLOR, target_color, gui.EASING_INOUTSINE, pulsate_duration, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

function D.stop_pulsate(node)
	-- Function to stop the pulsating effect
	gui.cancel_animation(node, gui.PROP_COLOR) -- Cancel all animations on color, not just loop
end

return D