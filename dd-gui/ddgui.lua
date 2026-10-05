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

-- Shared variables
--
-- The colors of the widgets: a dark, flat look with white text. The scripts
-- tint the widgets' images with these (gui.set_color), so a color can be
-- changed here - or from your own script, before the first widget is drawn -
-- without touching the images. The images are white where the color is to show
-- at full strength (frames, the line under a text box) and grey where it is to
-- be darker (the fill), see dd-gui/images.
--
-- NOTE: the prefabs (dd-gui/prefabs/*.gui) carry the idle colors too, because
-- that is what is shown until the first input reaches the gui. If you change
-- active, field, box, row, track, panel or text, change the prefabs as well.
D.colors = {
	-- Buttons
	active		= vmath.vector4(0.33, 0.33, 0.33, 1),	-- idle
	hover		= vmath.vector4(0.42, 0.42, 0.42, 1),	-- the pointer is on it
	select		= vmath.vector4(0.50, 0.50, 0.50, 1),	-- held down
	inactive	= vmath.vector4(0.27, 0.27, 0.27, 0.6),	-- disabled
	-- The accent: accent buttons, a toggle button that is on, a ticked checkbox,
	-- the level of a slider, the arrow of a combobox
	accent		= vmath.vector4(0.17, 0.50, 0.79, 1),
	accenthover	= vmath.vector4(0.27, 0.59, 0.87, 1),
	accentselect	= vmath.vector4(0.38, 0.67, 0.93, 1),
	-- Text
	text		= vmath.vector4(1, 1, 1, 1),
	text_inactive	= vmath.vector4(1, 1, 1, 0.38),		-- disabled, placeholders
	-- Text boxes and the box of a combobox (images/field.png)
	field		= vmath.vector4(0.58, 0.58, 0.58, 1),
	field_hover	= vmath.vector4(0.72, 0.72, 0.72, 1),	-- the pointer is on it, or it has the focus
	field_inactive	= vmath.vector4(0.42, 0.42, 0.42, 0.5),
	-- Checkbox and radio button, not ticked (images/checkbox.png, radio.png)
	box		= vmath.vector4(0.66, 0.66, 0.66, 1),
	box_hover	= vmath.vector4(0.90, 0.90, 0.90, 1),
	box_inactive	= vmath.vector4(0.40, 0.40, 0.40, 0.5),
	-- The rows of a dropdown list. The list keeps track of its rows by their
	-- color, so these four must differ from each other.
	row		= vmath.vector4(0.14, 0.14, 0.14, 1),
	row_chosen	= vmath.vector4(0.20, 0.20, 0.20, 1),	-- the chosen row
	row_hover	= vmath.vector4(0.27, 0.27, 0.27, 1),	-- the row the pointer or the arrow keys are on
	row_select	= vmath.vector4(0.34, 0.34, 0.34, 1),	-- the pointer is on the chosen row
	-- The track of a slider, the background of a text block
	track		= vmath.vector4(0.36, 0.36, 0.36, 1),
	panel		= vmath.vector4(0.15, 0.15, 0.15, 1),
	panel_inactive	= vmath.vector4(0.15, 0.15, 0.15, 0.5),
	-- For marking an answer from your own script (see D.mark)
	correct		= vmath.vector4(0.30, 0.78, 0.36, 1),
	wrong		= vmath.vector4(0.92, 0.32, 0.30, 1),
	-- Plain colors
	green		= vmath.vector4(0.1, 1, 0.1, 1),
	red			= vmath.vector4(1, 0.1, 0.1, 1),
	black		= vmath.vector4(0, 0, 0,  1),
	white		= vmath.vector4(1, 1, 1,  1)
}

-- True on phones and tablets (set by D.check_device, which runs when this module is loaded)
D.isMobileDevice = false
-- True while the pointer is a finger: on a mobile device, or when the last input came from a touch screen
D.touchInput = false
-- Touch screens: small controls (checkbox, radio button, the handle and the track
-- of a slider) can be hit this far outside their edges. 0 turns it off.
D.touchPadding = 10
-- A dropdown list that is dragged further than this is being scrolled: the release does not choose a row.
D.dragThreshold = 10
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
	self.ddStarted = true -- see with_touch: the focus set here is this scene's own
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

-- Give the widgets another accent color (accent buttons, a toggle button that is
-- on, a ticked checkbox, the level of a slider, the arrow of a combobox). The
-- hover and pressed variants are made from it. Call it in init(), before the
-- first widget call - D is shared, so the scene that comes next must set its own.
--   D.setAccent(vmath.vector4(0.85, 0.64, 0.25, 1))
function D.setAccent(color)
	local function lighter(amount)
		return vmath.vector4(color.x + (1 - color.x) * amount, color.y + (1 - color.y) * amount, color.z + (1 - color.z) * amount, 1)
	end
	D.colors.accent = vmath.vector4(color.x, color.y, color.z, 1)
	D.colors.accenthover = lighter(0.14)
	D.colors.accentselect = lighter(0.28)
end

-- Mark a widget as a correct or wrong answer (or with any color), or take the
-- mark away. Call it AFTER the widget's own call in on_input - the widget sets
-- its normal color every time it runs.
--   D.mark(self, "answer", "correct")          -- or "wrong", or a vmath.vector4
--   D.mark(self, "answer", "wrong", true)      -- dimmed, for a locked answer
--   D.mark(self, "answer", nil)                -- no mark: nothing is changed
-- Works for text boxes, comboboxes, auto-suggest boxes, checkboxes and radio buttons.
function D.mark(self, node, state, dimmed)
	if state == nil then
		return
	end
	local color = D.colors[state] or state
	if dimmed then
		color = vmath.vector4(color.x, color.y, color.z, color.w * 0.5)
	end
	-- the box of a combobox is called "textbox", everything else is tinted on "bg"
	local ok, target = pcall(gui.get_node, node .. "/textbox")
	if not ok then
		target = gui.get_node(node .. "/bg")
	end
	gui.set_color(target, color)
end

-- Function to set localization strings
function D.set_localization_strings(no_entries_str, select_value_str)
	D.no_entries = no_entries_str
	D.select_a_value = select_value_str
end

-- ---------------------------------------------------------------------------
-- Pointer and touch
-- ---------------------------------------------------------------------------

-- Where the pointer "is" when the finger has left the screen.
local AWAY = { x = -100000, y = -100000 }
local TOUCH = hash("touch")

-- Remember where the pointer is. Every widget calls this first.
function D.pointer(action)
	if action ~= nil and action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
		if action ~= AWAY then
			D.touchInput = D.isMobileDevice or action.touch ~= nil
		end
	end
end

-- Is (x, y) within pad_x / pad_y of the node? Tested with the node's own
-- picking at points around (x, y), so it follows the node's scale and rotation.
local function pick_padded(node, x, y, pad_x, pad_y)
	local size = gui.get_size(node)
	local nx = pad_x > 0 and math.ceil(pad_x / math.max(math.abs(size.x), 1)) or 0
	local ny = pad_y > 0 and math.ceil(pad_y / math.max(math.abs(size.y), 1)) or 0
	for ix = -nx, nx do
		for iy = -ny, ny do
			local px = nx > 0 and x + pad_x * ix / nx or x
			local py = ny > 0 and y + pad_y * iy / ny or y
			if gui.pick_node(node, px, py) then
				return true
			end
		end
	end
	return false
end

-- Is the pointer on the node or within pad_x / pad_y of it? (Mouse and touch alike.)
function D.pickNear(node, pad_x, pad_y)
	return pick_padded(node, D.currentMousePos.x, D.currentMousePos.y, pad_x or 0, pad_y or 0)
end

-- Is the pointer on the node? For the small controls. With a mouse this is
-- gui.pick_node. With a finger the node can also be hit a little outside its
-- edges (D.touchPadding, or pad_x / pad_y) - unless the finger is right on
-- another small control, which then keeps its touch.
function D.pick(self, node, pad_x, pad_y)
	local x, y = D.currentMousePos.x, D.currentMousePos.y
	local id = gui.get_id(node)
	self.ddTouchTargets = self.ddTouchTargets or {}
	self.ddTouchTargets[id] = node
	if gui.pick_node(node, x, y) then
		return true
	end
	if not D.touchInput then
		return false
	end
	pad_x = pad_x or D.touchPadding
	pad_y = pad_y or D.touchPadding
	if (pad_x <= 0 and pad_y <= 0) or not pick_padded(node, x, y, pad_x, pad_y) then
		return false
	end
	for other_id, other in pairs(self.ddTouchTargets) do
		if other_id ~= id then
			-- pcall: the node may have been deleted since it was last used
			local ok, hit = pcall(function()
				return gui.pick_node(other, x, y) and gui.is_enabled(other, true)
			end)
			if ok and hit then
				return false
			end
		end
	end
	return true
end

-- A finger does not hover: when it is lifted the pointer is gone, while a mouse
-- stays where it was. Without this a widget would keep its hover color and its
-- tooltip after a tap, and keep the focus so that the next tap on another
-- widget is lost. So after a release from a touch screen the widget is run once
-- more with the pointer far away - just what happens when a mouse is moved off it.
local function with_touch(widget)
	return function(self, action_id, action, ...)
		-- The first widget call of a gui scene: a focus that is still set belongs to
		-- a scene that was left (a collection proxy that was unloaded while a text box
		-- had the focus, say) and would lock every widget of this one. D is shared by
		-- all scripts when shared_state is on, so nobody else clears it.
		if self.ddStarted == nil then
			self.ddStarted = true
			D.nodes["active"] = nil
			D.nodes["tab"] = false
		end
		D.pointer(action)
		local value, changed = widget(self, action_id, action, ...)
		if action_id == TOUCH and action ~= nil and action.released and D.touchInput then
			widget(self, nil, AWAY, ...)
		end
		return value, changed
	end
end

for _, name in ipairs({
	"button", "togglebutton", "checkbox", "checkboxSelectall", "radiobutton", "textbox",
	"textboxMultiline", "slider", "combobox", "auto_suggestbox", "textblock",
}) do
	D[name] = with_touch(D[name])
end

-- Function to check device type. Runs when the module is loaded; call it again if you need to.
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

-- ---------------------------------------------------------------------------
-- Text metrics
-- gui.get_text_metrics_from_node() was removed from the gui API. The
-- replacement is resource.get_text_metrics() together with the font resource
-- fetched via gui.get_font_resource(). This helper wraps that and forwards the
-- node's own text settings so the result matches what is actually rendered.
--
--   local w = D.getTextMetrics(textNode).width
--
-- Returns a table with width, height, max_ascent and max_descent.
-- Optionally measure a different string than the node's current text:
--   D.getTextMetrics(textNode, "some other string")
-- Note: metrics are always unscaled - multiply by gui.get_scale(node) yourself
-- if the node is scaled.
-- ---------------------------------------------------------------------------
local font_resource_cache = {}

local function get_font_resource(font_name)
	local res = font_resource_cache[font_name]
	if not res then
		res = gui.get_font_resource(font_name)
		font_resource_cache[font_name] = res
	end
	return res
end

-- Reused between calls to avoid allocating a new table every frame
local metrics_options = {}

function D.getTextMetrics(node, text)
	metrics_options.width      = gui.get_size(node).x
	metrics_options.tracking   = gui.get_tracking(node)
	metrics_options.leading    = gui.get_leading(node)
	metrics_options.line_break = gui.get_line_break(node)

	return resource.get_text_metrics(
		get_font_resource(gui.get_font(node)),
		text or gui.get_text(node) or "",
		metrics_options
	)
end

-- Convenience wrapper when only the width is needed.
function D.getTextWidth(node, text)
	return D.getTextMetrics(node, text).width
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

-- Pulsation of markers: the text color, fading out and in
function D.pulsate(node)
	local current_color = D.colors.text
	local target_color = vmath.vector4(current_color.x, current_color.y, current_color.z, 0.15)
	gui.set_color(node, current_color)
	gui.animate(node, gui.PROP_COLOR, target_color, gui.EASING_INOUTSINE, pulsate_duration, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end

function D.stop_pulsate(node)
	-- Function to stop the pulsating effect
	gui.cancel_animations(node, gui.PROP_COLOR) -- Cancel all animations on color, not just loop
end

D.check_device()

return D