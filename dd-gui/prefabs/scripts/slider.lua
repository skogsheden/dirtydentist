-- slider.lua
-- Slider component for DD-GUI

local M = {}

-- Defold 1.13 removed gui.get_text_metrics_from_node(). This restores the
-- same behavior (text metrics for a node's current text, honoring the
-- node's own line-break/width/leading/tracking and gui scale) on top of
-- the new resource.get_text_metrics().
local function get_text_metrics_from_node(node)
	local font = gui.get_font_resource(node)
	local text = gui.get_text(node)
	local size = gui.get_size(node)
	local options = {
		width = size.x,
		leading = gui.get_leading(node),
		tracking = gui.get_tracking(node),
		line_break = gui.get_line_break(node),
	}
	local metrics = resource.get_text_metrics(font, text, options)
	local scale = gui.get_scale(node)
	metrics.width = metrics.width * scale.x
	metrics.height = metrics.height * scale.y
	return metrics
end

function M.resetSlider(self, node)
	self.slider = self.slider or {}
	if not self.slider[node] then
		return -- Slider not yet initialized, nothing to reset
	end

	local slidebg = gui.get_node(node .. "/slider_bg")
	local slidelevel = gui.get_node(node .. "/slider_level")
	local handle = gui.get_node(node .. "/handle")

	local sliderBgSize = gui.get_size(slidebg)
	local slider_fillsize = gui.get_size(slidelevel)

	gui.set_position(handle, vmath.vector3(0, 0, 0))
	gui.set_size(slidelevel, vmath.vector3(sliderBgSize.x/2, slider_fillsize.y, slider_fillsize.z))
	self.slider[node].value = (self.slider[node].min + self.slider[node].max)/2
end

function M.setValueSlider(self, node, value, min, max, step)
	self.slider = self.slider or {}
	if self.slider[node] == nil then
		self.slider[node] = {}
		self.slider[node].value = 0
		self.slider[node].pressed = false
		self.slider[node].max = max
		self.slider[node].min = min
	end

	local slidebg = gui.get_node(node .. "/slider_bg")
	local slidelevel = gui.get_node(node .. "/slider_level")
	local handle = gui.get_node(node .. "/handle")

	local sliderBgSize = gui.get_size(slidebg)
	local slider_fillsize = gui.get_size(slidelevel)

	-- Clamp value to [min, max]
	value = math.max(min, math.min(value, max))

	-- Snap to step grid if provided
	if step and step > 0 then
		value = math.floor(value / step + 0.5) * step
		value = math.max(min, math.min(value, max))
	end

	-- Normalize value to [0, 1]
	local range = max - min
	local normalized_value = (value - min) / range

	-- Calculate fill length and handle position
	local length = normalized_value * sliderBgSize.x
	local handle_position = sliderBgSize.x * normalized_value - sliderBgSize.x / 2

	-- Apply to nodes
	gui.set_position(handle, vmath.vector3(handle_position, 0, 0))
	gui.set_size(slidelevel, vmath.vector3(length, slider_fillsize.y, slider_fillsize.z))

	-- Store current value
	self.slider[node].value = value
end


function M.slider(self, action_id, action, node, enabled, showpopup, min, max, step)
	if action ~= nil and action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Check if can be activated
	self.selectedNode = D.nodes["active"] or nil
	self.slider = self.slider or {}
	
	local bgNode = gui.get_node(node .. "/bg")
	local slidebg = gui.get_node(node .. "/slider_bg")
	local slidelevel = gui.get_node(node .. "/slider_level")
	local handle = gui.get_node(node .. "/handle")
	local handleCenter = gui.get_node(node .. "/accent")
	local textbox = gui.get_node(node .. "/txtbox")
	local text = gui.get_node(node .. "/txt")
	local slider_size = gui.get_size(slidebg)
	

	if self.slider[node] == nil then
		self.slider[node] = {}
		self.slider[node].value = 0
		self.slider[node].pressed = false
		gui.set_color(slidelevel, D.colors.accent)
		gui.set_color(handleCenter, D.colors.accent)
		gui.set_color(slidebg, D.colors.active)
	end

	-- Fall back to 0-100 if min/max not provided
	if min == nil or max == nil then
		min = 0
		max = 100
	end
	self.slider[node].min = min
	self.slider[node].max = max
	
	if (gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and enabled and (self.selectedNode == nil or self.selectedNode == node)) or self.slider[node].pressed then
		-- Get size
		local slider_pos = gui.get_screen_position(slidebg)
		local slider_fillsize = gui.get_size(slidelevel)
		local slider_fillpos = gui.get_screen_position(slidelevel)
		local handle_start = gui.get_screen_position(handle)	
		D.nodes["active"], self.selectedNode = node, node
		local widthmod = window.get_size()/sys.get_config_int("display.width")

		-- Handle input
		if action_id == hash("touch") and gui.pick_node(handle, D.currentMousePos.x, D.currentMousePos.y) and action.pressed and self.slider[node].pressed == false then
			self.slider[node].pressed = true
		elseif self.slider[node].pressed and action_id == hash("touch") and action.released then
				self.slider[node].pressed = false
			if gui.pick_node(handle, action.x, action.y) then
				gui.set_scale(handleCenter, vmath.vector3(1.5,1.5,0))
				gui.set_color(handleCenter, D.colors.accenthover)
			else
				gui.set_scale(handleCenter, vmath.vector3(1,1,0))
				gui.set_color(handleCenter, D.colors.accent)
			end
		elseif gui.pick_node(handle, action.x, action.y) then
			gui.set_scale(handleCenter, vmath.vector3(1.5,1.5,0))
			gui.set_color(handleCenter, D.colors.accenthover)
		end

		-- If slider is activated follow mouse until button released
		if self.slider[node].pressed then
			gui.set_screen_position(handle, vmath.vector3(D.valuelimit(action.x*widthmod, slider_fillpos.x, slider_fillpos.x + 2*(slider_pos.x-slider_fillpos.x)),handle_start.y, handle_start.z ))
			gui.set_size(slidelevel, vmath.vector3(gui.get_position(handle).x + (slider_size.x/2), slider_fillsize.y, slider_fillsize.z))	
			gui.set_scale(handleCenter, vmath.vector3(0.75,0.75,0))
			gui.set_color(handleCenter, D.colors.accenthover)
			if showpopup then
				gui.set_enabled(textbox, true)
			end
		-- I pressed on slider
	elseif action_id == hash("touch") and gui.pick_node(slidebg, D.currentMousePos.x, D.currentMousePos.y) and action.pressed and not gui.pick_node(handle, D.currentMousePos.x, D.currentMousePos.y) then
		gui.set_screen_position(handle, vmath.vector3(D.valuelimit(D.currentMousePos.x*widthmod, slider_fillpos.x, slider_fillpos.x + 2*(slider_pos.x-slider_fillpos.x)),handle_start.y, handle_start.z ))
			gui.set_size(slidelevel, vmath.vector3(gui.get_position(handle).x + (slider_size.x/2), slider_fillsize.y, slider_fillsize.z))
		elseif not gui.pick_node(handle, D.currentMousePos.x, D.currentMousePos.y) then
			if showpopup then
				gui.set_enabled(textbox, false)
			end
		end

		-- Update text if to be shown.
		-- Compute the display value from the current handle position so the popup
		-- is always in sync with the handle rather than showing the previous frame's value.
		if showpopup then
			local curPos  = gui.get_position(handle)
			local curVal  = self.slider[node].min + (self.slider[node].max - self.slider[node].min) * (curPos.x + slider_size.x / 2) / slider_size.x
			if step and step > 0 then
				curVal = math.floor(curVal / step + 0.5) * step
				curVal = math.max(self.slider[node].min, math.min(curVal, self.slider[node].max))
			else
				curVal = math.floor(curVal)
			end
			gui.set_text(text, tostring(curVal))
			local text_width  = get_text_metrics_from_node(text).width
			local current_size = gui.get_size(text)
			gui.set_size(textbox, vmath.vector3(text_width + 20, current_size.y, current_size.z))
			gui.set_size(text,    vmath.vector3(text_width + 20, current_size.y, current_size.z))
		end
	elseif not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.selectedNode == node then
		D.nodes["active"] = nil
		self.slider[node].pressed = false
		gui.set_scale(handleCenter, vmath.vector3(1,1,0))
		gui.set_color(handleCenter, D.colors.accent)
	end

	-- Apply disabled visual state to the handle so it looks inactive,
	-- and restore the normal accent color the moment it becomes enabled
	-- again (only once on the transition, so it doesn't fight with the
	-- hover/press coloring above on every frame).
	if not enabled then
		gui.set_color(handleCenter, D.colors.inactive)
		gui.set_color(slidelevel,   D.colors.inactive)
	elseif self.slider[node].wasEnabled == false then
		gui.set_color(handleCenter, D.colors.accent)
		gui.set_color(slidelevel,   D.colors.accent)
	end
	self.slider[node].wasEnabled = enabled

	-- Calculate value
	local currentValue = (gui.get_position(handle).x+slider_size.x/2)/(slider_size.x)
	local recalculated_value = self.slider[node].min + (self.slider[node].max - self.slider[node].min) * currentValue
	if step and step > 0 then
		recalculated_value = math.floor(recalculated_value / step + 0.5) * step
		recalculated_value = math.max(self.slider[node].min, math.min(recalculated_value, self.slider[node].max))
	else
		recalculated_value = math.floor(recalculated_value)
	end
	local prev = self.slider[node].lastValue
	if prev == nil then prev = recalculated_value end -- no spurious change on first frame
	local changed = (recalculated_value ~= prev)
	self.slider[node].value = recalculated_value
	self.slider[node].lastValue = recalculated_value
	return self.slider[node].value, changed
end

-- Change a slider's min/max range at runtime without resetting the handle position.
-- The stored value is not updated here; call setValueSlider afterwards if needed.
function M.setMinMax(self, node, min, max)
	self.slider = self.slider or {}
	self.slider[node] = self.slider[node] or {}
	self.slider[node].min = min
	self.slider[node].max = max
end

-- Deprecated alias – use setValueSlider
M.setvalueSlider = M.setValueSlider

return M