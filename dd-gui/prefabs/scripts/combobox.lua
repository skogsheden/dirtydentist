-- combobox.lua
-- Combobox component for DD-GUI

local M = {}

function M.setValueCombobox(self, node, value)
	self.comboboxData[node].value = value
	local selected_text = gui.get_node(node .. "/selecttext")
	gui.set_text(selected_text, value)
end

function M.setValueAutobox(self, node, value, active)
	local textbox = gui.get_node(node .. "/textbox")
	local selected_text = gui.get_node(node .. "/selecttext")
	local hiddenText = gui.get_node(node .. "/hiddentext")
	local arrow = gui.get_node(node .. "/arrow")
	
	self.selectedNode = D.nodes["active"] or nil
	self.comboboxData = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}

	-- Fill with selected value
	if value == nil or value == "" then
		gui.set_text(selected_text, D.select_a_value)
		gui.set_text(hiddenText, D.select_a_value)
		self.comboboxData[node].value = value
	else
		gui.set_text(selected_text, value)
		gui.set_text(hiddenText, value)
		self.comboboxData[node].value = value
	end

	-- Set color of arrow
	if active then
		gui.set_color(arrow, D.colors.accent)
	else
		gui.set_color(arrow, D.colors.inactive)
	end
end

function M.initialize(self, node, list, up, enabled)
	-- get nodes
	local textbox = gui.get_node(node .. "/textbox")
	local mask = gui.get_node(node .. "/bg")
	
	self.comboboxData[node].open = false -- start as closed
	self.comboboxData[node].scrolling = false -- Not scrolling

	-- choose side to which way to isOpen
	if up then
		local pos = gui.get_position(mask)
		pos.y = pos.y + 230
		gui.set_position(mask, pos)
	end

	-- If enabled set color of the dropbox
	if enabled then
		gui.set_color(textbox, D.colors.active)
	else
		gui.set_color(textbox, D.colors.inactive)
	end
	gui.set_enabled(mask, false)
	self.comboboxData[node].initialize = true
end

function M.deleteCombobox(self,node)
	local dd_obj = gui.get_node(node .. "/dddrag")

	if self.comboboxData[node].count >= 1 then 
		for i=1, self.comboboxData[node].count do
			gui.delete_node(gui.get_node(node .. "/button" .. i))
			gui.delete_node(gui.get_node(node .. "/text" .. i))
			gui.delete_node(gui.get_node(node .. "/selected" .. i))
		end
		gui.set_position(dd_obj, vmath.vector3(0,0,0))
	end
end

function M.createComboboxList(self, node, list, use_mag)
	-- setup nodes 	
	local orginalnode = gui.get_node(node .. "/button")
	local orginaltext = gui.get_node(node .. "/text")
	local orginalselect = gui.get_node(node .. "/selected")
	local dd_obj = gui.get_node(node .. "/dddrag")

	if use_mag then
		self.comboboxData[node].mag = D.textMagnification
		gui.set_size(orginaltext, gui.get_size(orginaltext)/D.textMagnification)
	else
		self.comboboxData[node].mag = 1
	end
	gui.set_scale(orginaltext, vmath.vector3(self.comboboxData[node].mag,self.comboboxData[node].mag,1))
	
	--Reset color of node
	gui.set_color(orginalnode,D.colors.active)

	-- assign templet button first value or error message
	if #list == 0 or #list == nil  then 
		gui.set_text(gui.get_node(node .. "/text"), D.no_entries)
	else
		-- Get values from list
		self.comboboxData[node].size = #list * 30
		self.comboboxData[node].count = #list - 1 -- onenode is allready created

		-- Set size of dragbox
		local currentsize = gui.get_size(dd_obj)
		currentsize.y = self.comboboxData[node].size
		gui.set_size(dd_obj, currentsize)
		gui.set_position(dd_obj, vmath.vector3(0,0,0))

		if list[1] == self.comboboxData[node].value then
			gui.set_text(gui.get_node(node .. "/text"), list[1])
			gui.set_color(orginalnode, D.colors.hover)
			gui.set_position(dd_obj, vmath.vector3(0,0,0))
			gui.set_enabled(orginalselect, true)
		else
			gui.set_text(gui.get_node(node .. "/text"), list[1])
			gui.set_color(orginalnode, D.colors.active)
			gui.set_enabled(orginalselect, false)
		end

		-- fill up list
		if #list > 1 then
			for k in pairs (list) do
				-- create new node
				if k+1 <= #list then
					local newnode = gui.clone(orginalnode)
					local newtext = gui.clone(orginaltext)
					local newselect = gui.clone(orginalselect)
					
					-- assagin to correct template
					gui.set_parent(newtext, newnode)
					gui.set_parent(newnode, dd_obj)	
					gui.set_parent(newselect, newnode)	
					gui.set_id(newnode, node .. "/button" .. k)
					gui.set_id(newtext, node .. "/text" .. k)
					gui.set_id(newselect, node .. "/selected" .. k)
					
					--set text value, position and check if selected 
					if list[k+1] == self.comboboxData[node].value then
						gui.set_text(newtext, list[k+1])
						gui.set_color(newnode, D.colors.hover)
						gui.set_enabled(newselect, true)
						if #list > 7 then
							gui.set_position(dd_obj, vmath.vector3(0,D.valuelimit((k*30),0,(self.comboboxData[node].size-170)),0))
						end
					else
						gui.set_text(newtext, list[k+1])
						gui.set_color(newnode, D.colors.active)
						gui.set_enabled(newselect, false)
					end
					gui.set_position(newnode, vmath.vector3(0,-30*k,0))
				end
			end
		end	
	end
end

function M.combobox(self, action_id, action, node, list, enabled, up, use_mag, standardValue)
	if action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	local textbox = gui.get_node(node .. "/textbox")
	local selected_text = gui.get_node(node .. "/selecttext")
	local mask = gui.get_node(node .. "/bg")
	local arrow = gui.get_node(node .. "/arrow")

	self.selectedNode = D.nodes["active"] or nil
	self.comboboxData = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	self.comboboxData[node].initialize = self.comboboxData[node].initialize or false
	self.comboboxData[node].scroll = self.comboboxData[node].scroll or {}	
	
	if not self.comboboxData[node].initialize then
		-- Load or initalize variables
		self.comboboxData[node].open = self.comboboxData[node].open or false
		self.comboboxData[node].size = self.comboboxData[node].size or 0
		self.comboboxData[node].count = self.comboboxData[node].count or 0
		self.comboboxData[node].init = self.comboboxData[node].init or false
		self.comboboxData[node].previous = self.comboboxData[node].previous or 0
		-- If list empty or has values
		if #list == 0 then
			self.comboboxData[node].value = self.comboboxData[node].value or D.no_entries
		else
			self.comboboxData[node].value = self.comboboxData[node].value or D.select_a_value
		end
		gui.set_text(selected_text, self.comboboxData[node].value)
		gui.set_color(arrow, D.colors.accent)

		if up then
			gui.set_size(arrow, vmath.vector3(20,20,0))
		else
			gui.set_size(arrow, vmath.vector3(20,-20,0))
		end
		
		-- Use magnification options
		if use_mag then
			self.comboboxData[node].mag = D.textMagnification
			gui.set_size(selected_text, gui.get_size(selected_text)/D.textMagnification)
		else
			self.comboboxData[node].mag = 1
		end
		gui.set_scale(selected_text, vmath.vector3(self.comboboxData[node].mag,self.comboboxData[node].mag,1))

		-- Initalize dropdown
		M.initialize(self, node, list, up, enabled)

		if standardValue == nil or standardValue == "" then
			self.comboboxData[node].value = self.comboboxData[node].value
		else
			self.comboboxData[node].value = standardValue
			gui.set_text(selected_text, standardValue)
		end
	end

	-- Set color of arrow
	if enabled then
		gui.set_color(arrow, D.colors.accent)
	else
		gui.set_color(arrow, D.colors.inactive)
	end
	
	-- Hovering and enabled
	if action ~= nil then
		if gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y) and enabled then
			gui.set_color(textbox, D.colors.hover)
			if action_id == hash("touch") and action.pressed then
				if gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y) and not self.comboboxData[node].open and self.selectedNode == nil then
					D.nodes["active"], self.selectedNode = node, node
					gui.set_enabled(mask, true)
					gui.set_text(selected_text, self.comboboxData[node].value)
					self.comboboxData[node].open = true
				elseif gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].open then
					-- Close dropdown
					gui.set_color(textbox, D.colors.active)
					gui.set_enabled(mask, false)
					gui.set_text(selected_text, self.comboboxData[node].value)
					M.deleteCombobox(self, node)
					self.comboboxData[node].init = false
					self.comboboxData[node].open = false
					D.nodes["active"], self.selectedNode = nil, nil
				end
			end
		elseif not (gui.pick_node(mask, D.currentMousePos.x, D.currentMousePos.y) or gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y)) and enabled and self.selectedNode == node then
			if action_id == hash("touch") and action.pressed then
				gui.set_color(textbox, D.colors.active)
				gui.set_enabled(mask, false)
				gui.set_text(selected_text, self.comboboxData[node].value)
				M.deleteCombobox(self, node)
				self.comboboxData[node].init = false
				self.comboboxData[node].open = false
				D.nodes["active"], self.selectedNode = nil, nil
			end
		elseif not enabled then
			gui.set_color(textbox, D.colors.inactive)
			gui.set_color(arrow, D.colors.inactive)
			
			if self.selectedNode == node then
				D.nodes["active"], self.selectedNode = nil, nil
			end
		elseif not self.comboboxData[node].open then
			gui.set_color(textbox, D.colors.active)
		elseif enabled then
			gui.set_color(arrow, D.colors.accent)
		end
	end

	-- If active start processing input
	if D.nodes["active"] == node then
		-- get nodes to use
		local dragpos = gui.get_node(node .. "/dragpos")
		local dd_obj = gui.get_node(node .. "/dddrag")
		
		-- If boxes not created
		if not self.comboboxData[node].init then
			M.createComboboxList(self, node, list, use_mag)
			self.comboboxData[node].init = true
		end

		-- Add buttons to list
		local listOfButton = {"/button"}
		local listOfText = {"/text"}
		local listOfSelect = {"/selected"}
		
		for i = 1 , self.comboboxData[node].count, 1 do 
			listOfButton[i+1] = "/button" .. i
			listOfText[i+1] = "/text" .. i
			listOfSelect[i+1] = "/selected" .. i
		end	
		
		-- Scrolling is enabeled when more than 7 items in dropdown
		if self.comboboxData[node].count < 6 then
			gui.set_enabled(dragpos, false)
		elseif self.comboboxData[node].count >= 6 then
			gui.set_enabled(dragpos, true)
			if action_id == hash("touch") and action.pressed then
				self.comboboxData[node].scroll.active = true
				self.comboboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
			elseif action_id == hash("touch") and action.released then
				self.comboboxData[node].scroll.active = false
				self.comboboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
			end
			if self.comboboxData[node].scroll.active then
				local currentPos = gui.get_position(dd_obj)
				self.comboboxData[node].scroll.delta = self.comboboxData[node].scroll.pos - vmath.vector3(action.x, action.y, 0)
				self.comboboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
				currentPos.y =  D.valuelimit(currentPos.y - self.comboboxData[node].scroll.delta.y, 0,self.comboboxData[node].size -170)
				gui.set_position(dd_obj, currentPos)
			-- Scrollwheel
			elseif self.comboboxData[node].open and action_id == hash("wheelup") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = D.valuelimit((currentPos.y - D.scrollSpeed),0,self.comboboxData[node].size -200)
				gui.set_position(dd_obj, currentPos)
			elseif self.comboboxData[node].open and action_id == hash("wheeldown") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = D.valuelimit((currentPos.y + D.scrollSpeed),0,self.comboboxData[node].size -170)
				gui.set_position(dd_obj, currentPos)
			end

			-- move indicator
			local currentPos = gui.get_position(dd_obj)
			local amountcomplete = currentPos.y / (self.comboboxData[node].size -170)
			local dragposCurrent = gui.get_position(dragpos)
			dragposCurrent.y = D.valuelimit(-170 * amountcomplete, -gui.get_size(dd_obj).y, -10)
			gui.set_position(dragpos, dragposCurrent)
		end

		-- find if any is selected
		self.comboboxData[node].previous = nil
		for k in pairs (listOfButton) do
			if gui.get_color(gui.get_node(node .. listOfButton[k])) == D.colors.hover then
				self.comboboxData[node].previous = k
				break
			end
		end	
		if self.comboboxData[node].previous == nil then
			for k in pairs (listOfButton) do
				if gui.get_color(gui.get_node(node .. listOfButton[k])) == D.colors.select then
					self.comboboxData[node].previous = k
					break
				end
			end
			if self.comboboxData[node].previous == nil then
				self.comboboxData[node].previous = 1
				gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.hover)
			end
		end
		-- Move with keys
		if action_id == hash("up") and action.pressed and self.comboboxData[node].count >= 1 and self.comboboxData[node].previous > 1 and self.comboboxData[node].open then
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous-1]), D.colors.hover)
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.active)
			if self.comboboxData[node].count > 6 then
				gui.set_position(dd_obj, vmath.vector3(0,(self.comboboxData[node].previous-1)*30-30,0))
			end
		elseif action_id == hash("down") and action.pressed and self.comboboxData[node].count >= 1 and self.comboboxData[node].previous < #listOfButton and self.comboboxData[node].open then
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous+1]), D.colors.hover)
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.active)
			if self.comboboxData[node].count > 6 then
				gui.set_position(dd_obj, vmath.vector3(0,(self.comboboxData[node].previous+1)*30-30,0))
			end
		end
		--Select hovered button
		if action_id == hash("enter") and action.pressed then
			for k in pairs (listOfButton) do
				if gui.get_color(gui.get_node(node .. listOfButton[k])) == D.colors.hover then
					self.comboboxData[node].value = gui.get_text(gui.get_node(node .. listOfText[k]))
					gui.set_text(selected_text, self.comboboxData[node].value)
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.select)
					
					-- Close dropdown
					gui.set_enabled(mask, false) 
					gui.set_text(selected_text, self.comboboxData[node].value)
					self.comboboxData[node].open = false
					M.deleteCombobox(self, node)
					self.comboboxData[node].init = false
					D.nodes["active"], self.selectedNode = nil, nil
					gui.set_color(textbox, D.colors.active)
					break
				end
			end	
		end
		-- Check if value pressed
		if gui.pick_node(mask, action.x, action.y) then
			for k in pairs (listOfButton) do
				if action_id == hash("touch") and action.released and self.comboboxData[node].open and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) then
					if gui.get_text(gui.get_node(node .. listOfText[k])) ~= D.noentries then
						self.comboboxData[node].value = gui.get_text(gui.get_node(node .. listOfText[k]))
						gui.set_text(selected_text, self.comboboxData[node].value)
						gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.hover)
						gui.set_color(textbox, D.colors.active)
						gui.set_enabled(mask, false)
						gui.set_text(selected_text, self.comboboxData[node].value)
						M.deleteCombobox(self, node)
						self.comboboxData[node].init = false
						self.comboboxData[node].open = false
						D.nodes["active"], self.selectedNode = nil, nil
						break
					end
				elseif self.comboboxData[node].open and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) and self.comboboxData[node].value ~= gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.hover)
				elseif self.comboboxData[node].open and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) and self.comboboxData[node].value == gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.select)
					gui.set_scale(gui.get_node(node .. listOfSelect[k]), vmath.vector3(1,0.75,1))
				elseif self.comboboxData[node].open and not gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) and self.comboboxData[node].value == gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.hover)
					gui.set_scale(gui.get_node(node .. listOfSelect[k]), vmath.vector3(1,1,1))
				elseif self.comboboxData[node].value ~= gui.get_text(gui.get_node(node .. listOfText[k])) and self.comboboxData[node].open then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.active)
				end
			end	
		end
	end
	return self.comboboxData[node].value
end

function M.auto_suggestbox(self, action_id, action, node, list, enabled, up, use_mag, id, tab_to)
	if action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	local textbox = gui.get_node(node .. "/textbox")
	local selected_text = gui.get_node(node .. "/selecttext")
	local mask = gui.get_node(node .. "/bg")
	local arrow = gui.get_node(node .. "/arrow")
	local idNode = gui.get_node(node .. "/ID")
	local markerNode = gui.get_node(node .. "/marker")
	local hiddenText = gui.get_node(node .. "/hiddentext")
	

	self.selectedNode = D.nodes["active"] or nil
	self.comboboxData = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	self.comboboxData[node].initialize = self.comboboxData[node].initialize or false
	self.comboboxData[node].scroll = self.comboboxData[node].scroll or {}		

	if not self.comboboxData[node].initialize then
		-- Load or initalize variables
		self.comboboxData[node].open = self.comboboxData[node].open or false
		self.comboboxData[node].size = self.comboboxData[node].size or 0
		self.comboboxData[node].count = self.comboboxData[node].count or 0
		self.comboboxData[node].init = self.comboboxData[node].init or false
		self.comboboxData[node].previous = self.comboboxData[node].previous or 0
		self.comboboxData[node].scrolling = self.comboboxData[node].scrolling or false
		-- If list empty or has values
		if #list == 0 then
			self.comboboxData[node].value = self.comboboxData[node].value or D.no_entries
		else
			self.comboboxData[node].value = self.comboboxData[node].value or D.select_a_value
		end
		gui.set_text(selected_text, self.comboboxData[node].value)
		gui.set_color(arrow, D.colors.accent)
		if up then
			gui.set_size(arrow, vmath.vector3(20,20,0))
		else
			gui.set_size(arrow, vmath.vector3(20,-20,0))
		end
		-- Set id
		if id ~= nil or id ~= "" then
			gui.set_text(idNode, id)
		end
		-- Use magnification options
		if use_mag then
			self.comboboxData[node].mag = D.textMagnification
			gui.set_size(selected_text, gui.get_size(selected_text)/D.textMagnification)
			gui.set_size(hiddenText, gui.get_size(hiddenText)/D.textMagnification)
			
		else
			self.comboboxData[node].mag = 1
		end
		gui.set_scale(selected_text, vmath.vector3(self.comboboxData[node].mag,self.comboboxData[node].mag,1))
		gui.set_scale(hiddenText, vmath.vector3(self.comboboxData[node].mag,self.comboboxData[node].mag,1))
		
		-- Initalize dropdown
		M.initialize(self, node, list, up, enabled)
	end

	if self.comboboxData[node].value == "" and self.selectedNode ~= node then
		gui.set_text(selected_text, D.select_a_value)
	end

	-- Set color of arrow
	if enabled then
		gui.set_color(arrow, D.colors.accent)
	else
		gui.set_color(arrow, D.colors.inactive)
	end

	-- Hovering and enabled
	if action ~= nil then
		if gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y) and enabled then
			gui.set_color(textbox, D.colors.hover)
			if action_id == hash("touch") and action.pressed then
				if gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y) and not self.comboboxData[node].open and self.selectedNode == nil then
					D.nodes["active"], self.selectedNode = node, node
					gui.set_enabled(mask, true)
					gui.set_text(selected_text, self.comboboxData[node].value)
					M.createComboboxList(self, node, list, use_mag)
					self.comboboxData[node].open = true
					if D.isMobileDevice then
						gui.show_keyboard(gui.KEYBOARD_TYPE_DEFAULT, true)
					end
				elseif gui.pick_node(arrow, D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].open then
					-- Close dropdown
					gui.set_color(textbox, D.colors.active)
					gui.set_enabled(mask, false)
					gui.set_text(selected_text, self.comboboxData[node].value)
					M.deleteCombobox(self, node)
					self.comboboxData[node].init = false
					self.comboboxData[node].open = false
					gui.set_enabled(markerNode, false)
					D.stop_pulsate(markerNode)
					D.nodes["active"], self.selectedNode = nil, nil
					if D.isMobileDevice then
						gui.reset_keyboard()
						gui.hide_keyboard()
					end
				end
			end
		elseif not (gui.pick_node(mask, D.currentMousePos.x, D.currentMousePos.y) or gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y)) and enabled and self.selectedNode == node then
			if action_id == hash("touch") and action.pressed then
				gui.set_color(textbox, D.colors.active)
				gui.set_enabled(mask, false)
				gui.set_text(selected_text, self.comboboxData[node].value)
				M.deleteCombobox(self, node)
				self.comboboxData[node].init = false
				self.comboboxData[node].open = false
				gui.set_enabled(markerNode, false)
				D.stop_pulsate(markerNode)
				D.nodes["active"], self.selectedNode = nil, nil
				if D.isMobileDevice then
					gui.reset_keyboard()
					gui.hide_keyboard()
				end
			end
		elseif not enabled and D.nodes["tab"] == false then
			gui.set_color(textbox, D.colors.inactive)
			gui.set_color(arrow, D.colors.inactive)
			
			if self.selectedNode == node then
				gui.set_enabled(markerNode, false)
				D.stop_pulsate(markerNode)
				D.nodes["active"], self.selectedNode = nil, nil
				if D.isMobileDevice then
					gui.reset_keyboard()
					gui.hide_keyboard()
				end
			end
		elseif not self.comboboxData[node].open and D.nodes["tab"] == false then
			gui.set_color(textbox, D.colors.active)
		elseif enabled then
			gui.set_color(arrow, D.colors.accent)
		end
	end
		

	-- If tab to
	if action_id == hash("tab") and action.pressed and tab_to ~= nil and D.nodes["tab"] == false and D.nodes["active"] == node then
		gui.set_color(textbox, D.colors.active)
		gui.set_enabled(mask, false)
		gui.set_text(selected_text, self.comboboxData[node].value)
		M.deleteCombobox(self, node)
		self.comboboxData[node].init = false
		self.comboboxData[node].open = false
		gui.set_enabled(markerNode, false)
		D.nodes["active"], self.selectedNode = nil, nil
		D.nodes["active"] = tab_to
		D.nodes["tab"] = true
	end
	if D.nodes["tab"] == true and D.nodes["active"] == node and enabled == false then
		print("jump to next")
		M.deleteCombobox(self, node)
		D.nodes["active"], self.selectedNode = nil, nil
		D.nodes["active"] = tab_to
		D.nodes["tab"] = true
	end

	if D.nodes["active"] == node then
		-- get nodes to use
		local dd_obj = gui.get_node(node .. "/dddrag")
		local dragpos = gui.get_node(node .. "/dragpos")

		-- List to store matching values
		local foundInList = {}

		-- Calculate width modifier
		widthmod = window.get_size()/sys.get_config_int("display.width")

		-- active textinput
		if action_id == hash("touch") and action.pressed and gui.pick_node(selected_text, action.x, action.y) then
			gui.set_enabled(markerNode, true)
			D.pulsate(markerNode)
			
			gui.set_color(textbox, D.colors.hover)
			if gui.get_text(selected_text) == D.select_a_value or gui.get_text(selected_text) == D.no_entries then
				gui.set_text(selected_text, "")
				gui.set_text(hiddenText,"")
			end
			gui.set_text(hiddenText, gui.get_text(selected_text))

			-- Set marker
			gui.set_screen_position(markerNode, vmath.vector3(action.x*widthmod,action.y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			while gui.get_text_metrics_from_node(hiddenText).width * self.comboboxData[node].mag - 90 > markpos.x do -- Adjust hidden string to fit hiddenstring
				local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
				gui.set_text(hiddenText, shortenstring)
				if utf8.len(shortenstring) <= 1 then
					break
				end
			end
			markpos.x = gui.get_text_metrics_from_node(hiddenText).width * self.comboboxData[node].mag - 90 -- Update marker to be at the end the hiddenstring
			gui.set_position(markerNode, markpos)
		end
		if D.nodes["tab"] then 
			gui.set_enabled(mask, true)
			gui.set_text(selected_text, self.comboboxData[node].value)
			M.createComboboxList(self, node, list, use_mag)
			self.comboboxData[node].open = true
			gui.set_enabled(markerNode, true)
			D.pulsate(markerNode)
			
			gui.set_color(textbox, D.colors.hover)
			if gui.get_text(selected_text) == D.select_a_value or gui.get_text(selected_text) == D.no_entries then
				gui.set_text(selected_text, "")
				gui.set_text(hiddenText,"")
			end
			gui.set_text(hiddenText, gui.get_text(selected_text))

			-- Set marker
			gui.set_screen_position(markerNode, vmath.vector3((gui.get_position(textbox).x + gui.get_size(textbox).x)*widthmod,gui.get_position(textbox).y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			while gui.get_text_metrics_from_node(hiddenText).width * self.comboboxData[node].mag - 90 > markpos.x do -- Adjust hidden string to fit hiddenstring
				local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
				gui.set_text(hiddenText, shortenstring)
				if utf8.len(shortenstring) <= 1 then
					break
				end
			end
			markpos.x = gui.get_text_metrics_from_node(hiddenText).width * self.comboboxData[node].mag - 90 -- Update marker to be at the end the hiddenstring
			gui.set_position(markerNode, markpos)
			D.nodes["tab"] = false
		end

		if action_id == hash("left") and action.pressed and utf8.len(gui.get_text(hiddenText)) > 0 then
			local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
			gui.set_text(hiddenText, shortenstring)
			local markerPos = gui.get_position(markerNode)
			markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*self.comboboxData[node].mag - 90
			gui.set_position(markerNode, markerPos)
		elseif action_id == hash("right") and action.pressed and utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(selected_text)) then
			local lengthNew = utf8.len(gui.get_text(hiddenText))
			local lenDiff = utf8.len(gui.get_text(selected_text)) - lengthNew
			local shortenstring = utf8.sub(gui.get_text(selected_text), 1, -lenDiff)
			gui.set_text(hiddenText, shortenstring)
			local markerPos = gui.get_position(markerNode)
			markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*self.comboboxData[node].mag - 90
			gui.set_position(markerNode, markerPos)
		end
		-- handle input of text
		if action_id == hash("text") then	
			M.deleteCombobox(self, node)			
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(selected_text)) then -- Hidden is shorter add text for that point
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = text .. action.text
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(selected_text), hiddenlength + 1, -1)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*self.comboboxData[node].mag - 90
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(selected_text)) then -- If equal add text at the end
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(selected_text)
				text = text .. action.text
				gui.set_text(hiddenText, text)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(selected_text).width*self.comboboxData[node].mag - 90
				gui.set_position(markerNode, markerPos)
			end
			-- clear check if input is in list and store matching ids in foundInList
			for i = 0, #foundInList do foundInList[i] = nil end
			for k in pairs(list) do
				if utf8.find(utf8.lower(list[k]),utf8.lower(gui.get_text(selected_text))) ~= nil then
					foundInList[#foundInList+1] = list[k]
				end
			end	
			self.comboboxData[node].count = #foundInList
			M.createComboboxList(self, node, foundInList, use_mag)
			gui.set_position(dd_obj, vmath.vector3(0,0,0))
			self.comboboxData[node].value = gui.get_text(selected_text)
			gui.set_enabled(mask, true)
			self.comboboxData[node].open = true
		end

		if action_id == hash("backspace") and action.repeated then
			M.deleteCombobox(self, node)
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(selected_text)) then -- If hidden is shorter remove text from that point
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = utf8.sub(text, 1, -2)
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(selected_text), hiddenlength+1, -1)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*self.comboboxData[node].mag - 90
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(selected_text)) then -- If equal remove from the end
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = utf8.sub(text, 1, -2)
				gui.set_text(hiddenText, text)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*self.comboboxData[node].mag - 90
				gui.set_position(markerNode, markerPos)
			end

			for i=0, #foundInList do foundInList[i]=nil end
			for k in pairs(list) do
				if utf8.find(utf8.lower(list[k]),utf8.lower(gui.get_text(selected_text))) ~= nil then
					foundInList[#foundInList+1] = list[k]
				end
			end	
			self.comboboxData[node].count = #foundInList
			M.createComboboxList(self, node, foundInList, use_mag)
			gui.set_position(dd_obj, vmath.vector3(0,0,0))
			self.comboboxData[node].value = gui.get_text(selected_text)
			gui.set_enabled(mask, true)
			self.comboboxData[node].open = true
		end

		if action_id == hash("delete") and action.repeated then
			M.deleteCombobox(self, node)
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(selected_text)) then
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(selected_text), hiddenlength+2, -1)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*self.comboboxData[node].mag - 90
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(selected_text)) then -- If marker at end there is nothing to delete
				print("nothing to delete")
			end
			for i=0, #foundInList do foundInList[i]=nil end
			for k in pairs(list) do
				if utf8.find(utf8.lower(list[k]),utf8.lower(gui.get_text(selected_text))) ~= nil then
					foundInList[#foundInList+1] = list[k]
				end
			end	
		self.comboboxData[node].count = #foundInList
		M.createComboboxList(self, node, foundInList, use_mag)
		gui.set_position(dd_obj, vmath.vector3(0,0,0))
		self.comboboxData[node].value = gui.get_text(selected_text)
		gui.set_enabled(mask, true)
		self.comboboxData[node].open = true
	end

		-- Add buttons to list
		local listOfButton = {"/button"}
		local listOfText = {"/text"}
		local listOfSelect = {"/selected"}

		for i = 1 , self.comboboxData[node].count, 1 do 
			listOfButton[i+1] = "/button" .. i
			listOfText[i+1] = "/text" .. i
			listOfSelect[i+1] = "/selected" .. i
		end	

		-- Scrolling is enabeled when more than 6 items in dropdown
		if self.comboboxData[node].count < 6 then
			gui.set_enabled(dragpos, false)
		elseif self.comboboxData[node].count >= 6 then
			gui.set_enabled(dragpos, true)
			if action_id == hash("touch") and action.pressed then
				self.comboboxData[node].scroll.active = true
				self.comboboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
			elseif action_id == hash("touch") and action.released then
				self.comboboxData[node].scroll.active = false
				self.comboboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
			end
			if self.comboboxData[node].scroll.active then
				local currentPos = gui.get_position(dd_obj)
				self.comboboxData[node].scroll.delta = self.comboboxData[node].scroll.pos - vmath.vector3(action.x, action.y, 0)
				self.comboboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
				currentPos.y =  D.valuelimit(currentPos.y - self.comboboxData[node].scroll.delta.y, 0,self.comboboxData[node].size -170)
				gui.set_position(dd_obj, currentPos)
			-- Scrollwheel
			elseif self.comboboxData[node].open and action_id == hash("wheelup") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = D.valuelimit((currentPos.y - D.scrollSpeed),0,self.comboboxData[node].size -200)
				gui.set_position(dd_obj, currentPos)
			elseif self.comboboxData[node].open and action_id == hash("wheeldown") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = D.valuelimit((currentPos.y + D.scrollSpeed),0,self.comboboxData[node].size -170)
				gui.set_position(dd_obj, currentPos)
			end

			-- move indicator
			local currentPos = gui.get_position(dd_obj)
			local amountcomplete = currentPos.y / (self.comboboxData[node].size -170)
			local dragposCurrent = gui.get_position(dragpos)
			dragposCurrent.y = D.valuelimit(-170 * amountcomplete, -gui.get_size(dd_obj).y, -10)
			gui.set_position(dragpos, dragposCurrent)
		end

		-- find if any is selected
		self.comboboxData[node].previous = nil
		for k in pairs (listOfButton) do
			if gui.get_color(gui.get_node(node .. listOfButton[k])) == D.colors.hover then
				self.comboboxData[node].previous = k
				break
			end
		end	
		if self.comboboxData[node].previous == nil then
			for k in pairs (listOfButton) do
				if gui.get_color(gui.get_node(node .. listOfButton[k])) == D.colors.select then
					self.comboboxData[node].previous = k
					break
				end
			end
			if self.comboboxData[node].previous == nil then
				self.comboboxData[node].previous = 1
				gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.hover)
			end
		end
		-- Move with keys
		if action_id == hash("up") and action.pressed and self.comboboxData[node].count >= 1 and self.comboboxData[node].previous > 1 and self.comboboxData[node].open then
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous-1]), D.colors.hover)
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.active)
			if self.comboboxData[node].count > 6 then
				gui.set_position(dd_obj, vmath.vector3(0,(self.comboboxData[node].previous-1)*30-30,0))
			end
		elseif action_id == hash("down") and action.pressed and self.comboboxData[node].count >= 1 and self.comboboxData[node].previous < #listOfButton and self.comboboxData[node].open then
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous+1]), D.colors.hover)
			gui.set_color(gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.active)
			if self.comboboxData[node].count > 6 then
				gui.set_position(dd_obj, vmath.vector3(0,(self.comboboxData[node].previous+1)*30-30,0))
			end
		end
		--Select hovered button
		if action_id == hash("enter") and action.pressed then
			for k in pairs (listOfButton) do
				if gui.get_color(gui.get_node(node .. listOfButton[k])) == D.colors.hover then
					self.comboboxData[node].value = gui.get_text(gui.get_node(node .. listOfText[k]))
					gui.set_text(selected_text, self.comboboxData[node].value)
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.select)

					-- Close dropdown
					gui.set_enabled(mask, false) 
					gui.set_text(selected_text, self.comboboxData[node].value)
					self.comboboxData[node].open = false
					M.deleteCombobox(self, node)
					self.comboboxData[node].init = false
					D.nodes["active"], self.selectedNode = nil, nil
					gui.set_color(textbox, D.colors.active)
					gui.set_enabled(markerNode, false)
					break
				end
			end
			if D.isMobileDevice then
				gui.reset_keyboard()
				gui.hide_keyboard()
			end	
		end
		-- Check if value pressed
		if gui.pick_node(mask, D.currentMousePos.x, D.currentMousePos.y) then
			for k in pairs (listOfButton) do
				if action_id == hash("touch") and action.released and self.comboboxData[node].open and gui.pick_node(gui.get_node(node .. listOfButton[k]), D.currentMousePos.x, D.currentMousePos.y) then
					if gui.get_text(gui.get_node(node .. listOfText[k])) ~= D.noentries then
						self.comboboxData[node].value = gui.get_text(gui.get_node(node .. listOfText[k]))
						gui.set_text(selected_text, self.comboboxData[node].value)
						gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.hover)
						gui.set_color(textbox, D.colors.active)
						gui.set_enabled(mask, false)
						gui.set_text(selected_text, self.comboboxData[node].value)
						M.deleteCombobox(self, node)
						self.comboboxData[node].init = false
						self.comboboxData[node].open = false
						D.nodes["active"], self.selectedNode = nil, nil
						gui.set_enabled(markerNode, false)
						break
					end
				elseif self.comboboxData[node].open and gui.pick_node(gui.get_node(node .. listOfButton[k]), D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].value ~= gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.hover)
				elseif self.comboboxData[node].open and gui.pick_node(gui.get_node(node .. listOfButton[k]), D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].value == gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.select)
					gui.set_scale(gui.get_node(node .. listOfSelect[k]), vmath.vector3(1,0.75,1))
				elseif self.comboboxData[node].open and not gui.pick_node(gui.get_node(node .. listOfButton[k]), D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].value == gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.hover)
					gui.set_scale(gui.get_node(node .. listOfSelect[k]), vmath.vector3(1,1,1))
				elseif self.comboboxData[node].value ~= gui.get_text(gui.get_node(node .. listOfText[k])) and self.comboboxData[node].open then
					gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.active)
				end
			end	
		end
	end
	return self.comboboxData[node].value
end

return M