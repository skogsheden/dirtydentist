-- button.lua
-- Button component for DD-GUI

local M = {}

function M.toggleActive(self, node, enabled)
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")
	if not enabled then
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.inactive)
	else
		gui.set_color(textNode, D.colors.black)
	end
end

function M.togglebutton(self, action_id, action, node, enabled, text)
	if action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Get nodes
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")

	-- Initialize pressed_buttons if it doesn't exist
	self.pressed_buttons = self.pressed_buttons or {}
	local pressed = self.pressed_buttons[node] or false
	self.selectedNode = D.nodes["active"] or nil
	
	-- Set text if provided
	if text then
		gui.set_text(textNode, text)
	end

	if enabled and (self.selectedNode == nil or self.selectedNode == node) then
		if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) then
			if action_id == hash("touch") and action.pressed then
				pressed = not pressed
				self.pressed_buttons[node] = pressed
				gui.set_color(bgNode, pressed and D.colors.accent or D.colors.hover)
				gui.set_color(textNode, pressed and D.colors.white or D.colors.black)	
				return pressed
			else
				gui.set_color(bgNode, pressed and D.colors.accenthover or D.colors.hover)
				gui.set_color(textNode, pressed and D.colors.white or D.colors.black)
				return pressed	
			end
		else
			gui.set_color(bgNode, pressed and D.colors.accent or D.colors.active)
			return pressed
		end
	elseif not enabled then
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.inactive)
		return false
	end

	return false
end

function M.button(self, action_id, action, node, enabled, accent, text)
	if action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Get nodes
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")

	-- Initialize pressed_buttons if it doesn't exist
	self.pressed_buttons = self.pressed_buttons or {}
	local pressed = self.pressed_buttons[node] or false
	self.selectedNode = D.nodes["active"] or nil
	
	-- Set text if provided
	if text then
		gui.set_text(textNode, text)
	end

	-- Handle disabled state
	if not enabled then
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.inactive)
		return false
	end

	-- Set text color based on accent
	gui.set_color(textNode, accent and D.colors.white or D.colors.black)

	if enabled and (self.selectedNode == nil or self.selectedNode == node) then
		-- Check if the cursor is over the button
		if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) then
			if action_id == hash("touch") and action.pressed then
				-- Button is pressed
				pressed = true
				self.pressed_buttons[node] = pressed
				gui.set_color(bgNode, accent and D.colors.accent or D.colors.active)
				return true
			elseif action_id == hash("touch") and action.released then
				-- Button is released
				pressed = false
				self.pressed_buttons[node] = pressed
				gui.set_color(bgNode, accent and D.colors.accenthover or D.colors.hover)
				return false
			elseif pressed then
				-- Button is held down
				gui.set_color(bgNode, accent and D.colors.accent or D.colors.active)
			else
				-- Button is hovered but not pressed
				gui.set_color(bgNode, accent and D.colors.accenthover or D.colors.hover)
			end
		else
			-- Cursor is not over the button
			pressed = false
			self.pressed_buttons[node] = pressed
			gui.set_color(bgNode, accent and D.colors.accent or D.colors.active)
		end
	end

	return false
end

return M