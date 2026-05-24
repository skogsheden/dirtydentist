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
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.black)
	end
end

function M.togglebutton(self, action_id, action, node, enabled, text)
	if action ~= nil and action.x ~= nil then
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
			end
			gui.set_color(bgNode, pressed and D.colors.accent or D.colors.hover)
			gui.set_color(textNode, pressed and D.colors.white or D.colors.black)
		else
			gui.set_color(bgNode, pressed and D.colors.accent or D.colors.active)
		end
	elseif not enabled then
		pressed = false
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.inactive)
	end

	local prev = self.pressed_buttons[node .. "_prev"]
	if prev == nil then prev = pressed end -- no spurious change on first frame
	local changed = (pressed ~= prev)
	self.pressed_buttons[node .. "_prev"] = pressed
	return pressed, changed
end

function M.button(self, action_id, action, node, enabled, accent, text)
	if action ~= nil and action.x ~= nil then
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

	local result = false

	-- Handle disabled state
	if not enabled then
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.inactive)
	else
		-- Set text color based on accent
		gui.set_color(textNode, accent and D.colors.white or D.colors.black)

		if self.selectedNode == nil or self.selectedNode == node then
			if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) then
				if action_id == hash("touch") and action.pressed then
					pressed = true
					self.pressed_buttons[node] = pressed
					gui.set_color(bgNode, accent and D.colors.accent or D.colors.active)
					result = true
				elseif action_id == hash("touch") and action.released then
					pressed = false
					self.pressed_buttons[node] = pressed
					gui.set_color(bgNode, accent and D.colors.accenthover or D.colors.hover)
				elseif pressed then
					gui.set_color(bgNode, accent and D.colors.accent or D.colors.active)
				else
					gui.set_color(bgNode, accent and D.colors.accenthover or D.colors.hover)
				end
			else
				pressed = false
				self.pressed_buttons[node] = pressed
				gui.set_color(bgNode, accent and D.colors.accent or D.colors.active)
			end
		end
	end

	-- For a momentary button, "changed" means it fired this frame
	local changed = result
	return result, changed
end

-- Programmatically set the on/off state of a toggle button from script.
function M.setTogglebutton(self, node, value)
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")

	self.pressed_buttons = self.pressed_buttons or {}
	self.pressed_buttons[node] = value
	self.pressed_buttons[node .. "_prev"] = value -- prevent spurious changed on next frame

	if value then
		gui.set_color(bgNode, D.colors.accent)
		gui.set_color(textNode, D.colors.white)
	else
		gui.set_color(bgNode, D.colors.active)
		gui.set_color(textNode, D.colors.black)
	end
end

return M
