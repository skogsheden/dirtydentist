-- radiobutton.lua
-- Radio button component for DD-GUI

local M = {}

function M.radiobutton(self, action_id, action, node, enabled, group)
	if action.x ~= nil then
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
		if self.selectedNode == node then
			D.nodes["active"] = nil
		end
	end
	--return value
	return self.checkbox[node]
end

return M