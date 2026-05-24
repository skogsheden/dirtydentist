-- checkbox.lua
-- Checkbox component for DD-GUI

local M = {}

-- Apply checked/unchecked visual state (enabled appearance).
local function applyCheckState(bgNode, checkNode, value)
	gui.set_enabled(checkNode, value)
	gui.set_color(bgNode, value and D.colors.accent or D.colors.active)
end

-- Show and size the hover tooltip box next to a checkbox.
local function showTooltip(txtBox, txtNode, text)
	if text then
		gui.set_text(txtNode, text)
		local w = gui.get_text_metrics_from_node(txtNode).width
		local s = gui.get_size(txtBox)
		gui.set_size(txtBox, vmath.vector3(w + 20, s.y, s.z))
		gui.set_enabled(txtBox, true)
	end
end

function M.initializeCheckbox(self, node, value, enabled)
	local bgNode    = gui.get_node(node .. "/bg")
	local checkNode = gui.get_node(node .. "/check")

	self.checkbox       = self.checkbox or {}
	self.checkbox[node] = self.checkbox[node] or {}
	self.checkbox[node].value     = value
	self.checkbox[node].lastValue = value  -- prevent spurious changed on first frame
	self.checkbox[node].enabled   = enabled

	if enabled then
		applyCheckState(bgNode, checkNode, value)
	else
		gui.set_enabled(checkNode, false)
		gui.set_color(bgNode, D.colors.inactive)
		self.checkbox[node].enabled = false
	end
end


function M.clearCheckbox (self, node)
	local bgNode = gui.get_node(node .. "/bg")
	local checkNode = gui.get_node(node .. "/check")
	local txtBox = gui.get_node(node .. "/txtbox")

	self.checkbox = self.checkbox or {}
	self.checkbox[node] = self.checkbox[node] or {}
	self.checkbox[node].value     = false
	self.checkbox[node].lastValue = false  -- prevent spurious changed after clear
	gui.set_enabled(checkNode, false)
	gui.set_color(bgNode, D.colors.active)
	gui.set_enabled(txtBox, false)
end


function M.checkbox(self, action_id, action, node, enabled, standard_value, text)
	if action ~= nil and action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Load nodes
	local bgNode = gui.get_node(node .. "/bg")
	local checkNode = gui.get_node(node .. "/check")
	local txtBox = gui.get_node(node .. "/txtbox")
	local txtNode = gui.get_node(node .. "/txt")

	-- Check current value
	self.checkbox = self.checkbox or {}
	self.checkbox[node] = self.checkbox[node] or {}
	self.checkbox[node].init = self.checkbox[node].init or false
	self.checkbox[node].value = self.checkbox[node].value or false
	self.checkbox[node].enabled = enabled 
	D.nodes["active"] = D.nodes["active"] or nil

	if enabled then
		if not self.checkbox[node].init then
			if standard_value ~= nil then
				self.checkbox[node].value = standard_value
			end
			self.checkbox[node].init = true
		end
		applyCheckState(bgNode, checkNode, self.checkbox[node].value)
	else
		gui.set_enabled(checkNode, false)
		gui.set_color(bgNode, D.colors.inactive)
	end

	-- Check if hovering above
	if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and enabled and (D.nodes["active"]== nil or D.nodes["active"] == node) then
		-- Set as active node
		D.nodes["active"] = node
		if self.checkbox[node].value then
			gui.set_color(bgNode, D.colors.accenthover)
		else
			gui.set_color(bgNode, D.colors.hover)
		end
		showTooltip(txtBox, txtNode, text)
		-- When pressed check if to be activated or deactivated
		if action_id == hash("touch") and action.pressed and self.checkbox[node].value then
			self.checkbox[node].value = false
			gui.set_enabled(checkNode, false)
			gui.set_color(bgNode, D.colors.hover)
		elseif action_id == hash("touch") and action.pressed and self.checkbox[node].value ~= true then
			self.checkbox[node].value = true
			gui.set_enabled(checkNode, true)
			gui.set_color(bgNode, D.colors.accenthover)
		end
	elseif enabled and not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and D.nodes["active"] == node then
		gui.set_enabled(txtBox, false)
		gui.set_color(bgNode, D.colors.active)
		D.nodes["active"] = nil
		if self.checkbox[node].value then
			gui.set_color(bgNode, D.colors.accent)
		else
			gui.set_color(bgNode, D.colors.active)
		end
	elseif enabled == false then
		gui.set_color(bgNode, D.colors.inactive)
		if self.selectedNode == node then
			D.nodes["active"] = nil
		end
		gui.set_enabled(txtBox, false)
	end
	--return value
	local value = self.checkbox[node].value
	local prev = self.checkbox[node].lastValue
	if prev == nil then prev = value end -- no spurious change on first frame
	local changed = (value ~= prev)
	self.checkbox[node].lastValue = value
	return value, changed
end

function M.checkboxSelectall(self, action_id, action, node, othernodes, enabled, standard_value, text)
	-- Load nodes
	local bgNode = gui.get_node(node .. "/bg")
	local checkNode = gui.get_node(node .. "/check")
	local txtBox = gui.get_node(node .. "/txtbox")
	local txtNode = gui.get_node(node .. "/txt")

	-- Check current value
	self.checkbox = self.checkbox or {}
	self.checkbox[node] = self.checkbox[node] or {}
	self.checkbox[node].init = self.checkbox[node].init or false
	self.checkbox[node].value = self.checkbox[node].value or false
	self.checkbox[node].enabled = enabled
	D.nodes["active"] = D.nodes["active"] or nil

	-- Initialize on first frame
	if not self.checkbox[node].init and enabled then
		if standard_value ~= nil then
			self.checkbox[node].value = standard_value
		end
		applyCheckState(bgNode, checkNode, self.checkbox[node].value)
		if self.checkbox[node].value then
			-- Propagate initial selection to sibling checkboxes
			for i = 1, #othernodes do
				local otherBg    = gui.get_node(othernodes[i] .. "/bg")
				local otherCheck = gui.get_node(othernodes[i] .. "/check")
				if self.checkbox[othernodes[i]] and self.checkbox[othernodes[i]].enabled then
					self.checkbox[othernodes[i]].value = true
					applyCheckState(otherBg, otherCheck, true)
				else
					self.checkbox[othernodes[i]].value = false
					gui.set_enabled(otherCheck, false)
					gui.set_color(otherBg, D.colors.inactive)
				end
			end
		end
		self.checkbox[node].init = true
	end

	-- Run input
	if enabled and self.checkbox[node].init then
		-- Check other checkboxes
		local numberActive = 0
		for i = 1, #othernodes do
			if self.checkbox[othernodes[i]].value then
				numberActive = numberActive + 1
			end
		end
		if numberActive > 0 and numberActive < #othernodes then
			gui.set_enabled(checkNode, true)
			gui.play_flipbook(checkNode, "line")
			self.checkbox[node].value = true
			gui.set_color(bgNode, D.colors.accent)
		elseif numberActive == #othernodes then
			gui.set_enabled(checkNode, true)
			gui.play_flipbook(checkNode, "check")
			self.checkbox[node].value = true
			gui.set_color(bgNode, D.colors.accent)
		else
			gui.set_enabled(checkNode, false)
			self.checkbox[node].value = false
			gui.set_color(bgNode, D.colors.active)
		end
	end

	-- Check if hovering above
	if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and (D.nodes["active"]  == nil or D.nodes["active"]  == node) and enabled then
		-- Set as active node
		D.nodes["active"] = node
		if self.checkbox[node].value then
			gui.set_color(bgNode, D.colors.accenthover)
		else
			gui.set_color(bgNode, D.colors.hover)
		end

		showTooltip(txtBox, txtNode, text)
		-- When pressed check if to be activated or deactivated
		if action_id == hash("touch") and action.pressed and self.checkbox[node].value then
			self.checkbox[node].value = false
			gui.set_enabled(checkNode, false)
			gui.set_color(bgNode, D.colors.hover)
			-- Deactivate all other
			for i = 1, #othernodes do
				local otherBgNode = gui.get_node(othernodes[i] .. "/bg")
				local otherCheckNode = gui.get_node(othernodes[i] .. "/check")
				self.checkbox[othernodes[i]].value = false
				gui.set_enabled(otherCheckNode, false)
				gui.set_color(otherBgNode, D.colors.active)
			end
		elseif action_id == hash("touch") and action.pressed and self.checkbox[node].value ~= true then
			self.checkbox[node].value = true
			gui.set_enabled(checkNode, true)
			gui.set_color(bgNode, D.colors.accenthover)
			gui.play_flipbook(checkNode, "check")
			for i = 1, #othernodes do
				local otherBgNode = gui.get_node(othernodes[i] .. "/bg")
				local otherCheckNode = gui.get_node(othernodes[i] .. "/check")
				self.checkbox[othernodes[i]].value = true
				gui.set_enabled(otherCheckNode, true)
				gui.set_color(otherBgNode, D.colors.accent)
			end
		end
	elseif enabled and not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and D.nodes["active"] == node then
		gui.set_enabled(txtBox, false)
		gui.set_color(bgNode, D.colors.active)
		D.nodes["active"] = nil
		if self.checkbox[node].value then
			gui.set_color(bgNode, D.colors.accent)
		else
			gui.set_color(bgNode, D.colors.active)
		end
	elseif enabled == false then
		gui.set_color(bgNode, D.colors.inactive)
		if D.nodes["active"]  == node then
			D.nodes["active"] = nil
		end
		gui.set_enabled(txtBox, false)
	end
	--return value
	local value = self.checkbox[node].value
	local prev = self.checkbox[node].lastValue
	if prev == nil then prev = value end -- no spurious change on first frame
	local changed = (value ~= prev)
	self.checkbox[node].lastValue = value
	return value, changed
end

-- Programmatically set a checkbox value and update its visual state.
-- Sets lastValue to prevent a spurious 'changed' on the next frame.
function M.setCheckbox(self, node, value)
	local bgNode    = gui.get_node(node .. "/bg")
	local checkNode = gui.get_node(node .. "/check")
	self.checkbox       = self.checkbox or {}
	self.checkbox[node] = self.checkbox[node] or {}
	self.checkbox[node].value     = value
	self.checkbox[node].lastValue = value  -- prevent spurious changed
	applyCheckState(bgNode, checkNode, value)
end

-- Toggle a checkbox between checked and unchecked.
function M.toggleCheckbox(self, node)
	self.checkbox       = self.checkbox or {}
	self.checkbox[node] = self.checkbox[node] or {}
	local newValue = not (self.checkbox[node].value or false)
	M.setCheckbox(self, node, newValue)
end

return M