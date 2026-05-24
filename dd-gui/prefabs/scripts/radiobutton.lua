-- radiobutton.lua
-- Radio button component for DD-GUI

local M = {}

function M.radiobutton(self, action_id, action, node, enabled, group)
	if action ~= nil and action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Load nodes
	local bgNode = gui.get_node(node .. "/bg")
	local centerNode = gui.get_node(node .. "/center")

	-- Check current value
	self.radiobutton = self.radiobutton or {}
	self.selectedNode = D.nodes["active"] or nil

	-- Check if hovering above
	if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and enabled and (self.selectedNode == nil or self.selectedNode == node) then
		-- Set as active node
		D.nodes["active"] = node
		if self.radiobutton[node] then
			gui.set_color(bgNode, D.colors.accenthover)
		else
			gui.set_color(bgNode, D.colors.hover)
		end

		-- When pressed check if to be activated or deactivated
		if action_id == hash("touch") and action.pressed and self.radiobutton[node] then
			self.radiobutton[node] = false
			gui.set_enabled(centerNode, false)
			gui.set_color(bgNode, D.colors.hover)
		elseif action_id == hash("touch") and action.pressed and self.radiobutton[node] ~= true then
			self.radiobutton[node] = true
			gui.set_enabled(centerNode, true)
			gui.set_color(bgNode, D.colors.accenthover)

			-- Turn of other nodes
			for i = 1, #group do
				if group[i] ~= node then
					local otherBgNode = gui.get_node(group[i] .. "/bg")
					local otherCenterNode = gui.get_node(group[i] .. "/center")
					self.radiobutton[group[i]] = false
					gui.set_enabled(otherCenterNode, false)
					gui.set_color(otherBgNode, D.colors.active)
				end
			end
		end
		gui.set_scale(centerNode, vmath.vector3(1.5,1.5,1))
	elseif enabled and not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.selectedNode == node then
		D.nodes["active"] = nil
		if self.radiobutton[node] then
			gui.set_color(bgNode, D.colors.accent)
		else
			gui.set_color(bgNode, D.colors.active)
		end
		gui.set_scale(centerNode, vmath.vector3(1,1,1))
	elseif enabled == false then
		gui.set_color(bgNode, D.colors.inactive)
		gui.set_scale(centerNode, vmath.vector3(1, 1, 1))
		if self.selectedNode == node then
			D.nodes["active"] = nil
		end
	else
		-- Idle state: not hovered, not previously active
		if self.radiobutton[node] then
			gui.set_color(bgNode, D.colors.accent)
		else
			gui.set_color(bgNode, D.colors.active)
		end
	end
	--return value
	local value = self.radiobutton[node] or false
	local prev = self.radiobutton[node .. "_prev"]
	if prev == nil then prev = value end -- no spurious change on first frame
	local changed = (value ~= prev)
	self.radiobutton[node .. "_prev"] = value
	return value, changed
end

-- Set a single radio button's visual state without input handling.
-- Pass the full group so siblings are deselected when value is true.
function M.initializeRadiobutton(self, node, value, enabled)
	local bgNode = gui.get_node(node .. "/bg")
	local centerNode = gui.get_node(node .. "/center")

	self.radiobutton = self.radiobutton or {}
	self.radiobutton[node] = value or false
	self.radiobutton[node .. "_prev"] = self.radiobutton[node] -- prevent spurious changed

	gui.set_scale(centerNode, vmath.vector3(1, 1, 1))
	if enabled == false then
		gui.set_color(bgNode, D.colors.inactive)
		gui.set_enabled(centerNode, false)
	elseif self.radiobutton[node] then
		gui.set_color(bgNode, D.colors.accent)
		gui.set_enabled(centerNode, true)
	else
		gui.set_color(bgNode, D.colors.active)
		gui.set_enabled(centerNode, false)
	end
end

-- Programmatically select a radio button and deselect the rest of its group.
function M.setRadiobutton(self, node, value, group)
	local bgNode = gui.get_node(node .. "/bg")
	local centerNode = gui.get_node(node .. "/center")

	self.radiobutton = self.radiobutton or {}
	self.radiobutton[node] = value

	gui.set_scale(centerNode, vmath.vector3(1, 1, 1))
	if value then
		gui.set_color(bgNode, D.colors.accent)
		gui.set_enabled(centerNode, true)
		-- Deselect all siblings
		if group then
			for i = 1, #group do
				if group[i] ~= node then
					local otherBg = gui.get_node(group[i] .. "/bg")
					local otherCenter = gui.get_node(group[i] .. "/center")
					self.radiobutton[group[i]] = false
					self.radiobutton[group[i] .. "_prev"] = false
					gui.set_color(otherBg, D.colors.active)
					gui.set_enabled(otherCenter, false)
					gui.set_scale(otherCenter, vmath.vector3(1, 1, 1))
				end
			end
		end
	else
		gui.set_color(bgNode, D.colors.active)
		gui.set_enabled(centerNode, false)
	end
	self.radiobutton[node .. "_prev"] = value -- prevent spurious changed
end

-- Clear every button in a group (none selected).
function M.clearRadiogroup(self, group)
	self.radiobutton = self.radiobutton or {}
	for i = 1, #group do
		local bgNode = gui.get_node(group[i] .. "/bg")
		local centerNode = gui.get_node(group[i] .. "/center")
		self.radiobutton[group[i]] = false
		self.radiobutton[group[i] .. "_prev"] = false
		gui.set_color(bgNode, D.colors.active)
		gui.set_enabled(centerNode, false)
		gui.set_scale(centerNode, vmath.vector3(1, 1, 1))
	end
end

-- Return the node ID of the currently-selected button in a group, or nil if none.
function M.getSelectedInGroup(self, group)
	self.radiobutton = self.radiobutton or {}
	for i = 1, #group do
		if self.radiobutton[group[i]] then
			return group[i]
		end
	end
	return nil
end

return M