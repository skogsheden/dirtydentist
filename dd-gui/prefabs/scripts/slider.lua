-- slider.lua
-- Slider component for DD-GUI

local M = {}

function M.resetSlider(self, node)
	local slidebg = gui.get_node(node .. "/slider_bg")
	local slidelevel = gui.get_node(node .. "/slider_level")
	local handle = gui.get_node(node .. "/handle")

	local sliderBgSize = gui.get_size(slidebg)
	local slider_fillsize = gui.get_size(slidelevel)
	
	gui.set_position(handle, vmath.vector3(0, 0, 0))
	gui.set_size(slidelevel, vmath.vector3(sliderBgSize.x/2, slider_fillsize.y, slider_fillsize.z))
	self.slider[node].value = (self.slider[node].min + self.slider[node].max)/2
end

function M.setvalueSlider(self, node, value, min, max)
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

	-- Kontrollera att värdet ligger inom intervallet
	value = math.max(min, math.min(value, max))

	-- Normalisera värdet till intervallet [0, 1]
	local range = max - min
	local normalized_value = (value - min) / range

	-- Beräkna längd och position
	local length = normalized_value * sliderBgSize.x
	local handle_position = sliderBgSize.x * normalized_value - sliderBgSize.x / 2

	-- Uppdatera reglaget och handtaget
	gui.set_position(handle, vmath.vector3(handle_position, 0, 0))
	gui.set_size(slidelevel, vmath.vector3(length, slider_fillsize.y, slider_fillsize.z))

	-- Spara det aktuella värdet
	self.slider[node].value = value
end


function M.slider(self, action_id, action, node, enabled, showpopup, min, max)
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

	-- I values for min max not set	
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
			print("action relerased")
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

		-- Update text if to be shown
		if showpopup then
			gui.set_text(text, self.slider[node].value)
			local text_width = gui.get_text_metrics_from_node(text).width
			local current_size = gui.get_size(text)
			gui.set_size(textbox, vmath.vector3(text_width + 20, current_size.y, current_size.z))
			gui.set_size(text, vmath.vector3(text_width + 20, current_size.y, current_size.z))
		end
	elseif not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.selectedNode == node then
		D.nodes["active"] = nil
		self.slider[node].pressed = false
		gui.set_scale(handleCenter, vmath.vector3(1,1,0))
		gui.set_color(handleCenter, D.colors.accent)
	end

	-- Calculate value
	local currentValue = (gui.get_position(handle).x+slider_size.x/2)/(slider_size.x)
	local recalculated_value = self.slider[node].min + (self.slider[node].max - self.slider[node].min) * currentValue
	recalculated_value = math.floor(recalculated_value)
	self.slider[node].value = recalculated_value
	return self.slider[node].value
end

return M