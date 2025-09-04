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
	-- Check if comboboxData exists for this node
	if not self.comboboxData or not self.comboboxData[node] then
		return
	end

	-- Check if there's actually something to delete
	if not self.comboboxData[node].count or self.comboboxData[node].count < 1 then
		return
	end

	local dd_obj = gui.get_node(node .. "/dddrag")
	if not dd_obj then
		return
	end

	-- Safely delete each node with existence checks
	for i = 1, self.comboboxData[node].count do
		local buttonNode = gui.get_node(node .. "/button" .. i)
		local textNode = gui.get_node(node .. "/text" .. i) 
		local selectedNode = gui.get_node(node .. "/selected" .. i)

		-- Only delete if nodes actually exist
		if buttonNode then
			local success = pcall(gui.delete_node, buttonNode)
			if not success then
				print("Failed to delete button node: " .. node .. "/button" .. i)
			end
		end

		if textNode then
			local success = pcall(gui.delete_node, textNode)
			if not success then
				print("Failed to delete text node: " .. node .. "/text" .. i)
			end
		end

		if selectedNode then
			local success = pcall(gui.delete_node, selectedNode)
			if not success then
				print("Failed to delete selected node: " .. node .. "/selected" .. i)
			end
		end
	end

	-- Reset position safely
	local success = pcall(gui.set_position, dd_obj, vmath.vector3(0,0,0))
	if not success then
		print("Failed to reset dd_obj position for node: " .. node)
	end

	-- Reset count after successful deletion
	self.comboboxData[node].count = 0
end

function M.createComboboxList(self, node, list, use_mag)
	if self.comboboxData[node].rebuilding_list then
		return -- Avbryt om redan pågår
	end
	
	-- setup nodes 	
	local orginalnode = gui.get_node(node .. "/button")
	local orginaltext = gui.get_node(node .. "/text")
	local orginalselect = gui.get_node(node .. "/selected")
	local dd_obj = gui.get_node(node .. "/dddrag")

	self.comboboxData[node].rebuilding_list = true

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
		self.comboboxData[node].rebuilding_list = false  -- Lägg till denna rad
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
		self.comboboxData[node].rebuilding_list = false
	end
end

function M.combobox(self, action_id, action, node, list, enabled, up, use_mag, standardValue)
	if action ~= nil and action.x ~= nil then
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

		-- Add buttons to list (with safety checks)
		local listOfButton = {}
		local listOfText = {}
		local listOfSelect = {}

		-- Only build lists if nodes actually exist and we're not rebuilding
		if not self.comboboxData[node].rebuilding_list and self.comboboxData[node].count and self.comboboxData[node].count > 0 then
			-- Check if base button exists first
			local baseButton = gui.get_node(node .. "/button")
			if baseButton then
				listOfButton[1] = "/button"
				listOfText[1] = "/text" 
				listOfSelect[1] = "/selected"

				-- Only add additional buttons if they actually exist
				for i = 1, self.comboboxData[node].count do
					local buttonNode = gui.get_node(node .. "/button" .. i)
					local textNode = gui.get_node(node .. "/text" .. i)
					local selectedNode = gui.get_node(node .. "/selected" .. i)

					if buttonNode and textNode and selectedNode then
						listOfButton[i+1] = "/button" .. i
						listOfText[i+1] = "/text" .. i
						listOfSelect[i+1] = "/selected" .. i
					else
						-- If any node is missing, truncate the lists here
						break
					end
				end
			end
		end

		-- Only proceed with node operations if we have valid lists
		if #listOfButton == 0 then
			return self.comboboxData[node].value
		end

		-- Scrolling is enabeled when more than 7 items in dropdown
		if self.comboboxData[node].count < 6 then
			gui.set_enabled(dragpos, false)
		elseif self.comboboxData[node].count >= 6 then
			gui.set_enabled(dragpos, true)
			if action_id == hash("touch") and action.pressed then
				self.comboboxData[node].scroll.active = true
				self.comboboxData[node].scroll.pos = vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
			elseif action_id == hash("touch") and action.released then
				self.comboboxData[node].scroll.active = false
				self.comboboxData[node].scroll.pos = vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
			end
			if self.comboboxData[node].scroll.active then
				local currentPos = gui.get_position(dd_obj)
				self.comboboxData[node].scroll.delta = self.comboboxData[node].scroll.pos - vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
				self.comboboxData[node].scroll.pos = vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
				currentPos.y =  D.valuelimit(currentPos.y - self.comboboxData[node].scroll.delta.y, 0,self.comboboxData[node].size -170)
				gui.set_position(dd_obj, currentPos)
				-- Scrollwheel
			elseif self.comboboxData[node].open and action_id == hash("wheelup") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = D.valuelimit((currentPos.y - D.scrollSpeed),0,self.comboboxData[node].size -200)
				gui.set_position(dd_obj, currentPos)
			elseif self.comboboxData[node].open and action_id == hash("wheeldown") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
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

		-- find if any is selected (now safe because we've verified nodes exist)
		self.comboboxData[node].previous = nil
		for k in pairs (listOfButton) do
			local success, color = pcall(gui.get_color, gui.get_node(node .. listOfButton[k]))
			if success and color == D.colors.hover then
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
-- Förbättrad helper function för säker dropdown-uppdatering
local function updateDropdownSafe(self, node, list, currentText, use_mag)
	-- Förhindra samtidiga uppdateringar
	if self.comboboxData[node].updating_dropdown then
		return false
	end

	self.comboboxData[node].updating_dropdown = true

	local foundInList = {}

	-- Filtrera lista baserat på aktuell text
	if currentText and utf8.len(currentText) > 0 then
		local lowerCurrentText = utf8.lower(currentText)
		for i = 1, #list do
			if list[i] and utf8.find(utf8.lower(list[i]), lowerCurrentText, 1, true) ~= nil then
				foundInList[#foundInList + 1] = list[i]
			end
		end
	else
		-- Visa alla alternativ om tom text
		for i = 1, #list do
			if list[i] then
				foundInList[#foundInList + 1] = list[i]
			end
		end
	end

	-- Uppdatera dropdown säkert
	local success = pcall(M.deleteCombobox, self, node)
	if success then
		self.comboboxData[node].count = math.max(0, #foundInList - 1)
		if #foundInList > 0 then
			success = pcall(M.createComboboxList, self, node, foundInList, use_mag)
			if success then
				local dd_obj = gui.get_node(node .. "/dddrag")
				gui.set_position(dd_obj, vmath.vector3(0,0,0))
				local mask = gui.get_node(node .. "/bg")
				gui.set_enabled(mask, true)
				self.comboboxData[node].open = true
				self.comboboxData[node].init = true
				self.comboboxData[node].updating_dropdown = false
				return true
			end
		else
			-- Ingen matchning hittades - skapa tom lista men behåll dropdown öppen
			self.comboboxData[node].count = 0
			local emptyList = {D.no_entries or "No entries"}
			success = pcall(M.createComboboxList, self, node, emptyList, use_mag)
			if success then
				local dd_obj = gui.get_node(node .. "/dddrag")
				gui.set_position(dd_obj, vmath.vector3(0,0,0))
				local mask = gui.get_node(node .. "/bg")
				gui.set_enabled(mask, true)
				self.comboboxData[node].open = true
				self.comboboxData[node].init = true
			end
		end
	end

	self.comboboxData[node].updating_dropdown = false
	return false
end

-- Separat funktion för att hantera textuppdateringar
local function updateTextDisplay(self, node, newText, updateMarker)
	local selected_text = gui.get_node(node .. "/selecttext")
	local hiddenText = gui.get_node(node .. "/hiddentext")
	local markerNode = gui.get_node(node .. "/marker")
	local textbox = gui.get_node(node .. "/textbox")

	-- Kontrollera textbredd
	gui.set_text(hiddenText, newText)
	local success, metrics = pcall(gui.get_text_metrics_from_node, hiddenText)
	local textWidth = 0
	if success and metrics then
		textWidth = metrics.width * (self.comboboxData[node].mag or 1)
	end

	local maxWidth = gui.get_size(textbox).x - 25
	if textWidth > maxWidth then
		return false -- Text för bred
	end

	-- Uppdatera text
	gui.set_text(selected_text, newText)
	self.comboboxData[node].value = newText

	-- Uppdatera marker om begärt
	if updateMarker then
		local markerPos = gui.get_position(markerNode)
		local hiddenTextContent = gui.get_text(hiddenText) or ""
		local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
		if success and width then
			markerPos.x = math.min(math.max(-90, width.width * (self.comboboxData[node].mag or 1) - 90), maxWidth - 15)
		else
			markerPos.x = -90
		end
		gui.set_position(markerNode, markerPos)
	end

	return true
end

-- Förbättrad funktion för att hantera lista-uppdateringar med smartare debouncing
local function scheduleListUpdate(self, node, list, currentText, use_mag)
	local currentTime = socket.gettime and socket.gettime() or os.time()

	-- Spara pending uppdatering
	self.comboboxData[node].pendingText = currentText
	self.comboboxData[node].pendingUpdateTime = currentTime

	-- Om det är första gången eller om mycket tid har gått, uppdatera direkt
	if not self.comboboxData[node].lastUpdateTime or 
	(currentTime - self.comboboxData[node].lastUpdateTime) > 1.0 then
		updateDropdownSafe(self, node, list, currentText, use_mag)
		self.comboboxData[node].lastUpdateTime = currentTime
		self.comboboxData[node].pendingText = ""
		return
	end

	-- Annars använd kortare debouncing för snabbare respons
	if self.comboboxData[node].updateTimer then
		timer.cancel(self.comboboxData[node].updateTimer)
	end

	self.comboboxData[node].updateTimer = timer.delay(0.15, false, function()
		-- Kontrollera om vi fortfarande ska uppdatera
		if self.comboboxData[node].pendingText and 
		self.comboboxData[node].open then

			updateDropdownSafe(self, node, list, self.comboboxData[node].pendingText, use_mag)
			self.comboboxData[node].lastUpdateTime = socket.gettime and socket.gettime() or os.time()
			self.comboboxData[node].pendingText = ""
		end
		self.comboboxData[node].updateTimer = nil
	end)
end

function M.auto_suggestbox(self, action_id, action, node, list, enabled, up, use_mag, id, tab_to)
	if action ~= nil and action.x ~= nil then
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

	-- Nya variabler för separerad hantering
	self.comboboxData[node].updating_dropdown = self.comboboxData[node].updating_dropdown or false
	self.comboboxData[node].updateScheduled = self.comboboxData[node].updateScheduled or false
	self.comboboxData[node].pendingText = self.comboboxData[node].pendingText or ""
	self.comboboxData[node].lastUpdateTime = self.comboboxData[node].lastUpdateTime or 0

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
		if id ~= nil and id ~= "" then
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
					-- Skapa initial lista utan text-filtrering
					updateDropdownSafe(self, node, list, "", use_mag)
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
		local dragpos = gui.get_node(node .. "/dragpos")
		local dd_obj = gui.get_node(node .. "/dddrag")

		-- Calculate width modifier
		widthmod = window.get_size()/sys.get_config_int("display.width")

		-- active textinput
		if action_id == hash("touch") and action.pressed and gui.pick_node(selected_text, D.currentMousePos.x, D.currentMousePos.y) then
			gui.set_enabled(markerNode, true)
			D.pulsate(markerNode)

			gui.set_color(textbox, D.colors.hover)
			if gui.get_text(selected_text) == D.select_a_value or gui.get_text(selected_text) == D.no_entries then
				gui.set_text(selected_text, "")
				gui.set_text(hiddenText,"")
			end
			gui.set_text(hiddenText, gui.get_text(selected_text))

			-- Set marker med säkrare beräkning
			gui.set_screen_position(markerNode, vmath.vector3(D.currentMousePos.x*widthmod,D.currentMousePos.y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			-- SÄKRARE TEXTBERÄKNING
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			while utf8.len(hiddenTextContent) > 0 do
				local textWidth = 0
				local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
				if success and width then
					textWidth = width.width * self.comboboxData[node].mag
				else
					break
				end

				if textWidth - 90 <= markpos.x then
					break
				end

				local shortenstring = utf8.sub(hiddenTextContent, 1, -2)
				if utf8.len(shortenstring) <= 1 then
					break
				end
				gui.set_text(hiddenText, shortenstring)
				hiddenTextContent = shortenstring
			end

			-- Uppdatera marker position säkert
			local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
			if success and width then
				markpos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
			else
				markpos.x = -90
			end
			gui.set_position(markerNode, markpos)
		end

		-- Tab handling
		if D.nodes["tab"] then 
			gui.set_enabled(mask, true)
			gui.set_text(selected_text, self.comboboxData[node].value)
			-- Använd nya updateDropdownSafe funktionen
			updateDropdownSafe(self, node, list, self.comboboxData[node].value or "", use_mag)
			gui.set_enabled(markerNode, true)
			D.pulsate(markerNode)

			gui.set_color(textbox, D.colors.hover)
			if gui.get_text(selected_text) == D.select_a_value or gui.get_text(selected_text) == D.no_entries then
				gui.set_text(selected_text, "")
				gui.set_text(hiddenText,"")
			end
			gui.set_text(hiddenText, gui.get_text(selected_text))

			-- Säkrare markerposition
			gui.set_screen_position(markerNode, vmath.vector3((gui.get_position(textbox).x + gui.get_size(textbox).x)*widthmod,gui.get_position(textbox).y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			local hiddenTextContent = gui.get_text(hiddenText) or ""
			while utf8.len(hiddenTextContent) > 0 do
				local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
				if not success or not width then break end

				if width.width * self.comboboxData[node].mag - 90 <= markpos.x then
					break
				end

				local shortenstring = utf8.sub(hiddenTextContent, 1, -2)
				if utf8.len(shortenstring) <= 1 then break end

				gui.set_text(hiddenText, shortenstring)
				hiddenTextContent = shortenstring
			end

			local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
			if success and width then
				markpos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
			else
				markpos.x = -90
			end
			gui.set_position(markerNode, markpos)
			D.nodes["tab"] = false
		end

		-- Piltangenter
		if action_id == hash("left") and action.pressed then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			if utf8.len(hiddenTextContent) > 0 then
				local shortenstring = utf8.sub(hiddenTextContent, 1, -2)
				gui.set_text(hiddenText, shortenstring)
				local markerPos = gui.get_position(markerNode)
				local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
				if success and width then
					markerPos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
				else
					markerPos.x = -90
				end
				gui.set_position(markerNode, markerPos)
			end
		elseif action_id == hash("right") and action.pressed then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			local selectedTextContent = gui.get_text(selected_text) or ""
			if utf8.len(hiddenTextContent) < utf8.len(selectedTextContent) then
				local lengthNew = utf8.len(hiddenTextContent)
				local lenDiff = utf8.len(selectedTextContent) - lengthNew
				if lenDiff > 0 then
					local shortenstring = utf8.sub(selectedTextContent, 1, -lenDiff)
					gui.set_text(hiddenText, shortenstring)
					local markerPos = gui.get_position(markerNode)
					local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
					if success and width then
						markerPos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
					else
						markerPos.x = -90
					end
					gui.set_position(markerNode, markerPos)
				end
			end
		end

		-- Textinmatning med separerad lista-uppdatering
		if action_id == hash("text") then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			local selectedTextContent = gui.get_text(selected_text) or ""
			local newText = ""

			-- Bygg ny text baserat på nuvarande position
			if utf8.len(hiddenTextContent) < utf8.len(selectedTextContent) then
				local hiddenlength = utf8.len(hiddenTextContent)
				local newHiddenText = hiddenTextContent .. action.text
				local remainingText = ""
				if hiddenlength < utf8.len(selectedTextContent) then
					remainingText = utf8.sub(selectedTextContent, hiddenlength + 1, -1)
				end
				newText = newHiddenText .. remainingText
				gui.set_text(hiddenText, newHiddenText)
			elseif utf8.len(hiddenTextContent) == utf8.len(selectedTextContent) then
				newText = selectedTextContent .. action.text
				gui.set_text(hiddenText, newText)
			end

			-- Uppdatera text omedelbart
			local textSuccess = updateTextDisplay(self, node, newText, true)
			if not textSuccess then
				return self.comboboxData[node].value -- Text för bred
			end

			-- Schemalägg lista-uppdatering separat
			scheduleListUpdate(self, node, list, newText, use_mag)
		end

		-- Backspace med separerad lista-uppdatering
		if action_id == hash("backspace") and action.pressed then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			local selectedTextContent = gui.get_text(selected_text) or ""

			-- Kontrollera om det finns något att radera
			if hiddenTextContent == "" and selectedTextContent == "" then
				return self.comboboxData[node].value
			end

			if selectedTextContent == D.select_a_value or selectedTextContent == D.no_entries then
				return self.comboboxData[node].value
			end

			local newText = ""
			local newHiddenText = ""

			-- Hantera backspace baserat på cursor-position
			if utf8.len(hiddenTextContent) == 0 and utf8.len(selectedTextContent) == 0 then
				newText = ""
				newHiddenText = ""
			elseif utf8.len(hiddenTextContent) < utf8.len(selectedTextContent) then 
				if utf8.len(hiddenTextContent) > 0 then
					newHiddenText = utf8.sub(hiddenTextContent, 1, utf8.len(hiddenTextContent) - 1)
					local remainingText = ""
					local hiddenlength = utf8.len(newHiddenText)
					if hiddenlength < utf8.len(selectedTextContent) then
						remainingText = utf8.sub(selectedTextContent, hiddenlength + 1, -1)
					end
					newText = newHiddenText .. remainingText
				else
					if utf8.len(selectedTextContent) > 0 then
						newText = utf8.sub(selectedTextContent, 2, -1)
						newHiddenText = ""
					end
				end
			elseif utf8.len(hiddenTextContent) == utf8.len(selectedTextContent) then 
				if utf8.len(hiddenTextContent) > 0 then
					newText = utf8.sub(hiddenTextContent, 1, utf8.len(hiddenTextContent) - 1)
					newHiddenText = newText
				end
			end

			gui.set_text(hiddenText, newHiddenText)

			-- Uppdatera text omedelbart
			updateTextDisplay(self, node, newText, true)

			-- Schemalägg lista-uppdatering separat
			scheduleListUpdate(self, node, list, newText, use_mag)
		end

		-- Delete hantering
		if action_id == hash("delete") and action.repeated then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			local selectedTextContent = gui.get_text(selected_text) or ""

			if utf8.len(hiddenTextContent) < utf8.len(selectedTextContent) then
				local hiddenlength = utf8.len(hiddenTextContent)
				local markerPos = gui.get_position(markerNode)
				local text = hiddenTextContent
				gui.set_text(hiddenText, text)
				if hiddenlength + 2 <= utf8.len(selectedTextContent) then
					text = text .. utf8.sub(selectedTextContent, hiddenlength+2, -1)
				end
				gui.set_text(selected_text, text)
				self.comboboxData[node].value = text

				local success, width = pcall(gui.get_text_metrics_from_node, hiddenText)
				if success and width then
					markerPos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
				end
				gui.set_position(markerNode, markerPos)

				-- Schemalägg lista-uppdatering separat
				scheduleListUpdate(self, node, list, text, use_mag)
			elseif utf8.len(hiddenTextContent) == utf8.len(selectedTextContent) then
				print("nothing to delete")
			end
		end

		-- Add buttons to list med säkerhetskontroller
		local listOfButton = {}
		local listOfText = {}
		local listOfSelect = {}

		-- Only build lists if nodes actually exist and we're not rebuilding
		if not self.comboboxData[node].updating_dropdown and 
		not self.comboboxData[node].rebuilding_list and 
		self.comboboxData[node].count and 
		self.comboboxData[node].count >= 0 then

			-- Check if base button exists first
			local baseButton = gui.get_node(node .. "/button")
			if baseButton then
				listOfButton[1] = "/button"
				listOfText[1] = "/text" 
				listOfSelect[1] = "/selected"

				-- Only add additional buttons if they actually exist
				for i = 1, self.comboboxData[node].count do
					local buttonNode = gui.get_node(node .. "/button" .. i)
					local textNode = gui.get_node(node .. "/text" .. i)
					local selectedNode = gui.get_node(node .. "/selected" .. i)

					if buttonNode and textNode and selectedNode then
						listOfButton[i+1] = "/button" .. i
						listOfText[i+1] = "/text" .. i
						listOfSelect[i+1] = "/selected" .. i
					else
						-- If any node is missing, truncate the lists here
						break
					end
				end
			end
		end

		-- Only proceed with node operations if we have valid lists
		if #listOfButton > 0 then
			-- Scrolling is enabled when more than 6 items in dropdown
			if self.comboboxData[node].count < 6 then
				gui.set_enabled(dragpos, false)
			elseif self.comboboxData[node].count >= 6 then
				gui.set_enabled(dragpos, true)
				if action_id == hash("touch") and action.pressed then
					self.comboboxData[node].scroll.active = true
					self.comboboxData[node].scroll.pos = vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
				elseif action_id == hash("touch") and action.released then
					self.comboboxData[node].scroll.active = false
					self.comboboxData[node].scroll.pos = vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
				end
				if self.comboboxData[node].scroll.active then
					local currentPos = gui.get_position(dd_obj)
					self.comboboxData[node].scroll.delta = self.comboboxData[node].scroll.pos - vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
					self.comboboxData[node].scroll.pos = vmath.vector3(D.currentMousePos.x, D.currentMousePos.y, 0)
					currentPos.y =  D.valuelimit(currentPos.y - self.comboboxData[node].scroll.delta.y, 0,self.comboboxData[node].size -170)
					gui.set_position(dd_obj, currentPos)
				elseif self.comboboxData[node].open and action_id == hash("wheelup") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
					local currentPos = gui.get_position(dd_obj)
					currentPos.y = D.valuelimit((currentPos.y - D.scrollSpeed),0,self.comboboxData[node].size -200)
					gui.set_position(dd_obj, currentPos)
				elseif self.comboboxData[node].open and action_id == hash("wheeldown") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
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

			-- find if any is selected (now safe because we've verified nodes exist)
			self.comboboxData[node].previous = nil
			for k in pairs (listOfButton) do
				local success, color = pcall(gui.get_color, gui.get_node(node .. listOfButton[k]))
				if success and color == D.colors.hover then
					self.comboboxData[node].previous = k
					break
				end
			end
			if self.comboboxData[node].previous == nil then
				for k in pairs (listOfButton) do
					local success, color = pcall(gui.get_color, gui.get_node(node .. listOfButton[k]))
					if success and color == D.colors.select then
						self.comboboxData[node].previous = k
						break
					end
				end
				if self.comboboxData[node].previous == nil and #listOfButton > 0 then
					self.comboboxData[node].previous = 1
					local success = pcall(gui.set_color, gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.hover)
					if not success then
						print("Warning: Failed to set button color")
					end
				end
			end

			-- Move with keys
			if action_id == hash("up") and action.pressed and self.comboboxData[node].count >= 1 and self.comboboxData[node].previous and self.comboboxData[node].previous > 1 and self.comboboxData[node].open then
				pcall(gui.set_color, gui.get_node(node .. listOfButton[self.comboboxData[node].previous-1]), D.colors.hover)
				pcall(gui.set_color, gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.active)
				if self.comboboxData[node].count > 6 then
					gui.set_position(dd_obj, vmath.vector3(0,(self.comboboxData[node].previous-1)*30-30,0))
				end
			elseif action_id == hash("down") and action.pressed and self.comboboxData[node].count >= 1 and self.comboboxData[node].previous and self.comboboxData[node].previous < #listOfButton and self.comboboxData[node].open then
				pcall(gui.set_color, gui.get_node(node .. listOfButton[self.comboboxData[node].previous+1]), D.colors.hover)
				pcall(gui.set_color, gui.get_node(node .. listOfButton[self.comboboxData[node].previous]), D.colors.active)
				if self.comboboxData[node].count > 6 then
					gui.set_position(dd_obj, vmath.vector3(0,(self.comboboxData[node].previous+1)*30-30,0))
				end
			end

			--Select hovered button
			if action_id == hash("enter") and action.pressed then
				for k in pairs (listOfButton) do
					local success, color = pcall(gui.get_color, gui.get_node(node .. listOfButton[k]))
					if success and color == D.colors.hover then
						local textSuccess, textValue = pcall(gui.get_text, gui.get_node(node .. listOfText[k]))
						if textSuccess and textValue then
							self.comboboxData[node].value = textValue
							gui.set_text(selected_text, textValue)
							pcall(gui.set_color, gui.get_node(node .. listOfButton[k]), D.colors.select)

							-- Close dropdown
							gui.set_enabled(mask, false) 
							gui.set_text(selected_text, textValue)
							self.comboboxData[node].open = false
							M.deleteCombobox(self, node)
							self.comboboxData[node].init = false
							D.nodes["active"], self.selectedNode = nil, nil
							gui.set_color(textbox, D.colors.active)
							gui.set_enabled(markerNode, false)
							D.stop_pulsate(markerNode)
							break
						end
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
					local buttonNode = gui.get_node(node .. listOfButton[k])
					local textNode = gui.get_node(node .. listOfText[k])
					local selectNode = gui.get_node(node .. listOfSelect[k])

					if buttonNode and textNode and selectNode then
						if action_id == hash("touch") and action.released and self.comboboxData[node].open and gui.pick_node(buttonNode, D.currentMousePos.x, D.currentMousePos.y) then
							local textValue = gui.get_text(textNode)
							if textValue ~= D.noentries then
								self.comboboxData[node].value = textValue
								gui.set_text(selected_text, textValue)
								gui.set_color(buttonNode, D.colors.hover)
								gui.set_color(textbox, D.colors.active)
								gui.set_enabled(mask, false)
								gui.set_text(selected_text, textValue)
								M.deleteCombobox(self, node)
								self.comboboxData[node].init = false
								self.comboboxData[node].open = false
								D.nodes["active"], self.selectedNode = nil, nil
								gui.set_enabled(markerNode, false)
								D.stop_pulsate(markerNode)
								if D.isMobileDevice then
									gui.reset_keyboard()
									gui.hide_keyboard()
								end
								break
							end
						elseif self.comboboxData[node].open and gui.pick_node(buttonNode, D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].value ~= gui.get_text(textNode) then
							gui.set_color(buttonNode, D.colors.hover)
						elseif self.comboboxData[node].open and gui.pick_node(buttonNode, D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].value == gui.get_text(textNode) then
							gui.set_color(buttonNode, D.colors.select)
							gui.set_scale(selectNode, vmath.vector3(1,0.75,1))
						elseif self.comboboxData[node].open and not gui.pick_node(buttonNode, D.currentMousePos.x, D.currentMousePos.y) and self.comboboxData[node].value == gui.get_text(textNode) then
							gui.set_color(buttonNode, D.colors.hover)
							gui.set_scale(selectNode, vmath.vector3(1,1,1))
						elseif self.comboboxData[node].value ~= gui.get_text(textNode) and self.comboboxData[node].open then
							gui.set_color(buttonNode, D.colors.active)
						end
					end
				end	
			end
		end
	end

	return self.comboboxData[node].value
end

return M