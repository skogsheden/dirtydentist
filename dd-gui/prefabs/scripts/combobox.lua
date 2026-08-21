-- combobox.lua
-- Combobox component for DD-GUI

local M = {}

-- ---------------------------------------------------------------------------
-- Local helpers shared by combobox() and auto_suggestbox()
-- ---------------------------------------------------------------------------

-- Close an open dropdown and release focus.
-- The caller is responsible for any extra cleanup (marker, keyboard, etc.).
local function closeDropdown(self, node)
	local mask          = gui.get_node(node .. "/bg")
	local textbox       = gui.get_node(node .. "/textbox")
	local selected_text = gui.get_node(node .. "/selecttext")
	M.deleteCombobox(self, node)
	gui.set_enabled(mask, false)
	gui.set_text(selected_text, self.comboboxData[node].value)
	gui.set_color(textbox, D.colors.active)
	self.comboboxData[node].open = false
	self.comboboxData[node].init = false
	D.nodes["active"]   = nil
	self.selectedNode   = nil
end

-- Build the three parallel ID-suffix lists used to iterate dropdown rows.
-- Returns listOfButton, listOfText, listOfSelect (all empty if not ready).
local function buildButtonLists(self, node)
	local listOfButton, listOfText, listOfSelect = {}, {}, {}
	if self.comboboxData[node].rebuilding_list then
		return listOfButton, listOfText, listOfSelect
	end
	local count = self.comboboxData[node].count or 0
	-- gui.get_node throws (not returns nil) when a node is missing, so use pcall.
	local ok_base = pcall(gui.get_node, node .. "/button")
	if not ok_base then
		return listOfButton, listOfText, listOfSelect
	end
	listOfButton[1] = "/button"
	listOfText[1]   = "/text"
	listOfSelect[1] = "/selected"
	for i = 1, count do
		local ok_b = pcall(gui.get_node, node .. "/button"   .. i)
		local ok_t = pcall(gui.get_node, node .. "/text"     .. i)
		local ok_s = pcall(gui.get_node, node .. "/selected" .. i)
		if ok_b and ok_t and ok_s then
			listOfButton[i+1] = "/button"   .. i
			listOfText[i+1]   = "/text"     .. i
			listOfSelect[i+1] = "/selected" .. i
		else
			break
		end
	end
	return listOfButton, listOfText, listOfSelect
end

function M.setValueCombobox(self, node, value)
	self.comboboxData = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	self.comboboxData[node].value = value
	local selected_text = gui.get_node(node .. "/selecttext")
	gui.set_text(selected_text, value or "")
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

function M.deleteCombobox(self, node)
	if not self.comboboxData or not self.comboboxData[node] then return end
	local count = self.comboboxData[node].count
	if not count or count < 1 then return end

	-- gui.get_node throws when a node is missing, so both get and delete must be
	-- inside the same pcall so the error is fully contained.
	for i = 1, count do
		pcall(function() gui.delete_node(gui.get_node(node .. "/button"   .. i)) end)
		pcall(function() gui.delete_node(gui.get_node(node .. "/text"     .. i)) end)
		pcall(function() gui.delete_node(gui.get_node(node .. "/selected" .. i)) end)
	end
	pcall(function() gui.set_position(gui.get_node(node .. "/dddrag"), vmath.vector3(0, 0, 0)) end)
	self.comboboxData[node].count = 0
end

function M.createComboboxList(self, node, list, use_mag)
	if self.comboboxData[node].rebuilding_list then
		return -- Already rebuilding, skip
	end
	
	-- setup nodes 	
	local orginalnode = gui.get_node(node .. "/button")
	local orginaltext = gui.get_node(node .. "/text")
	local orginalselect = gui.get_node(node .. "/selected")
	local dd_obj = gui.get_node(node .. "/dddrag")

	self.comboboxData[node].rebuilding_list = true

	if use_mag then
		self.comboboxData[node].mag = D.textMagnification
		gui.set_scale(orginaltext, gui.get_size(orginaltext)/D.textMagnification)
	else
		self.comboboxData[node].mag = 1
	end
	gui.set_scale(orginaltext, vmath.vector3(self.comboboxData[node].mag,self.comboboxData[node].mag,1))

	--Reset color of node
	gui.set_color(orginalnode,D.colors.active)

	-- assign templet button first value or error message
	if #list == 0 then
		gui.set_text(gui.get_node(node .. "/text"), D.no_entries)
		self.comboboxData[node].rebuilding_list = false
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

		-- fill up list (k is the list index of the first item, button index = k for button naming)
		for k = 1, #list - 1 do
			local newnode = gui.clone(orginalnode)
			local newtext = gui.clone(orginaltext)
			local newselect = gui.clone(orginalselect)

			-- assign to correct template
			gui.set_parent(newtext, newnode)
			gui.set_parent(newnode, dd_obj)
			gui.set_parent(newselect, newnode)
			gui.set_id(newnode, node .. "/button" .. k)
			gui.set_id(newtext, node .. "/text" .. k)
			gui.set_id(newselect, node .. "/selected" .. k)

			-- set text value, position and check if selected
			if list[k+1] == self.comboboxData[node].value then
				gui.set_text(newtext, list[k+1])
				gui.set_color(newnode, D.colors.hover)
				gui.set_enabled(newselect, true)
				if #list > 7 then
					gui.set_position(dd_obj, vmath.vector3(0, D.valuelimit((k*30), 0, (self.comboboxData[node].size-170)), 0))
				end
			else
				gui.set_text(newtext, list[k+1])
				gui.set_color(newnode, D.colors.active)
				gui.set_enabled(newselect, false)
			end
			gui.set_position(newnode, vmath.vector3(0, -30*k, 0))
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

	-- Use a custom list override if one has been set via setListCombobox
	local effectiveList = self.comboboxData[node].customList or list

	if not self.comboboxData[node].initialize then
		-- Load or initalize variables
		self.comboboxData[node].open = self.comboboxData[node].open or false
		self.comboboxData[node].size = self.comboboxData[node].size or 0
		self.comboboxData[node].count = self.comboboxData[node].count or 0
		self.comboboxData[node].init = self.comboboxData[node].init or false
		self.comboboxData[node].previous = self.comboboxData[node].previous or 0
		-- If list empty or has values
		if #effectiveList == 0 then
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
			gui.set_scale(selected_text, gui.get_size(selected_text)/D.textMagnification)
		else
			self.comboboxData[node].mag = 1
		end
		gui.set_scale(selected_text, vmath.vector3(self.comboboxData[node].mag,self.comboboxData[node].mag,1))

		-- Initalize dropdown
		M.initialize(self, node, effectiveList, up, enabled)

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
					closeDropdown(self, node)
				end
			end
		elseif not (gui.pick_node(mask, D.currentMousePos.x, D.currentMousePos.y) or gui.pick_node(textbox, D.currentMousePos.x, D.currentMousePos.y)) and enabled and self.selectedNode == node then
			if action_id == hash("touch") and action.pressed then
				closeDropdown(self, node)
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
			M.createComboboxList(self, node, effectiveList, use_mag)
			self.comboboxData[node].init = true
		end

		local listOfButton, listOfText, listOfSelect = buildButtonLists(self, node)
		if #listOfButton > 0 then
			-- Scroll: enabled when dropdown has more than 6 items
			if self.comboboxData[node].count < 6 then
				gui.set_enabled(dragpos, false)
			else
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
					currentPos.y = D.valuelimit(currentPos.y - self.comboboxData[node].scroll.delta.y, 0, self.comboboxData[node].size - 170)
					gui.set_position(dd_obj, currentPos)
				elseif self.comboboxData[node].open and action_id == hash("wheelup") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
					local currentPos = gui.get_position(dd_obj)
					currentPos.y = D.valuelimit(currentPos.y - D.scrollSpeed, 0, self.comboboxData[node].size - 170)
					gui.set_position(dd_obj, currentPos)
				elseif self.comboboxData[node].open and action_id == hash("wheeldown") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
					local currentPos = gui.get_position(dd_obj)
					currentPos.y = D.valuelimit(currentPos.y + D.scrollSpeed, 0, self.comboboxData[node].size - 170)
					gui.set_position(dd_obj, currentPos)
				end
				-- Sync scroll indicator
				local currentPos = gui.get_position(dd_obj)
				local amountcomplete = currentPos.y / (self.comboboxData[node].size - 170)
				local dragposCurrent = gui.get_position(dragpos)
				dragposCurrent.y = D.valuelimit(-170 * amountcomplete, -gui.get_size(dd_obj).y, -10)
				gui.set_position(dragpos, dragposCurrent)
			end

			-- Track the hovered/selected row
			self.comboboxData[node].previous = nil
			for k in pairs(listOfButton) do
				local ok, color = pcall(function() return gui.get_color(gui.get_node(node .. listOfButton[k])) end)
				if ok and color == D.colors.hover then
					self.comboboxData[node].previous = k
					break
				end
			end
			if self.comboboxData[node].previous == nil then
				for k in pairs(listOfButton) do
					local ok, color = pcall(function() return gui.get_color(gui.get_node(node .. listOfButton[k])) end)
					if ok and color == D.colors.select then
						self.comboboxData[node].previous = k
						break
					end
				end
				if self.comboboxData[node].previous == nil then
					self.comboboxData[node].previous = 1
					pcall(function() gui.set_color(gui.get_node(node .. listOfButton[1]), D.colors.hover) end)
				end
			end

			-- Keyboard navigation
			local prev = self.comboboxData[node].previous
			if action_id == hash("up") and action.pressed and prev and prev > 1 and self.comboboxData[node].open then
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev - 1]), D.colors.hover) end)
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev]),     D.colors.active) end)
				if self.comboboxData[node].count > 6 then
					gui.set_position(dd_obj, vmath.vector3(0, (prev - 1) * 30 - 30, 0))
				end
			elseif action_id == hash("down") and action.pressed and prev and prev < #listOfButton and self.comboboxData[node].open then
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev + 1]), D.colors.hover) end)
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev]),     D.colors.active) end)
				if self.comboboxData[node].count > 6 then
					gui.set_position(dd_obj, vmath.vector3(0, (prev + 1) * 30 - 30, 0))
				end
			end

			-- Confirm selection with Enter
			if action_id == hash("enter") and action.pressed then
				for k in pairs(listOfButton) do
					local ok_c, color = pcall(function() return gui.get_color(gui.get_node(node .. listOfButton[k])) end)
					if ok_c and color == D.colors.hover then
						local ok_t, txt = pcall(gui.get_node, node .. listOfText[k])
						if ok_t then self.comboboxData[node].value = gui.get_text(txt) end
						pcall(function() gui.set_color(gui.get_node(node .. listOfButton[k]), D.colors.select) end)
						closeDropdown(self, node)
						break
					end
				end
			end

			-- Confirm selection with touch / update hover highlight
			if gui.pick_node(mask, D.currentMousePos.x, D.currentMousePos.y) then
				for k in pairs(listOfButton) do
					local ok_b, btn = pcall(gui.get_node, node .. listOfButton[k])
					local ok_t, txt = pcall(gui.get_node, node .. listOfText[k])
					local ok_s, sel = pcall(gui.get_node, node .. listOfSelect[k])
					if not (ok_b and ok_t and ok_s) then break end
					local hovered  = gui.pick_node(btn, D.currentMousePos.x, D.currentMousePos.y)
					local itemText = gui.get_text(txt)
					if action_id == hash("touch") and action.released and self.comboboxData[node].open and hovered then
						if itemText ~= D.no_entries then
							self.comboboxData[node].value = itemText
							closeDropdown(self, node)
							break
						end
					elseif self.comboboxData[node].open and hovered then
						if self.comboboxData[node].value == itemText then
							gui.set_color(btn, D.colors.select)
							gui.set_scale(sel, vmath.vector3(1, 0.75, 1))
						else
							gui.set_color(btn, D.colors.hover)
						end
					elseif self.comboboxData[node].open and not hovered then
						if self.comboboxData[node].value == itemText then
							gui.set_color(btn, D.colors.hover)
							gui.set_scale(sel, vmath.vector3(1, 1, 1))
						else
							gui.set_color(btn, D.colors.active)
						end
					end
				end
			end
		end -- if #listOfButton > 0
	end -- if D.nodes["active"] == node
	local value = self.comboboxData[node].value
	local prev = self.comboboxData[node].lastValue
	if prev == nil then prev = value end -- no spurious change on first frame
	local changed = (value ~= prev)
	self.comboboxData[node].lastValue = value
	return value, changed
end

-- Rebuild the dropdown list filtered by currentText, keeping it open.
local function updateDropdownSafe(self, node, list, currentText, use_mag)
	if self.comboboxData[node].updating_dropdown then return false end
	self.comboboxData[node].updating_dropdown = true

	-- Filter the source list by the typed text (case-insensitive substring)
	local foundInList = {}
	if currentText and utf8.len(currentText) > 0 then
		local lower = utf8.lower(currentText)
		for i = 1, #list do
			if list[i] and utf8.find(utf8.lower(list[i]), lower, 1, true) then
				foundInList[#foundInList + 1] = list[i]
			end
		end
	else
		-- Empty search text — show all entries
		for i = 1, #list do
			if list[i] then foundInList[#foundInList + 1] = list[i] end
		end
	end

	-- Tear down old rows, rebuild with matches (or a "no entries" placeholder).
	-- IMPORTANT: do NOT overwrite count before deleteCombobox runs — it reads the
	-- current count to know which cloned nodes exist and need to be deleted.
	-- createComboboxList sets count itself after creating the new nodes.
	local displayList = #foundInList > 0 and foundInList or {D.no_entries}

	local ok = pcall(M.deleteCombobox, self, node)
	if ok then
		ok = pcall(M.createComboboxList, self, node, displayList, use_mag)
		if ok then
			gui.set_position(gui.get_node(node .. "/dddrag"), vmath.vector3(0, 0, 0))
			gui.set_enabled(gui.get_node(node .. "/bg"), true)
			self.comboboxData[node].open = true
			self.comboboxData[node].init = true
			if #foundInList > 0 then
				self.comboboxData[node].updating_dropdown = false
				return true
			end
		end
	end

	self.comboboxData[node].updating_dropdown = false
	return false
end

-- Update the visible text and optionally the cursor marker position.
-- Returns false if the new text is wider than the textbox allows.
local function updateTextDisplay(self, node, newText, updateMarker)
	local selected_text = gui.get_node(node .. "/selecttext")
	local hiddenText    = gui.get_node(node .. "/hiddentext")
	local markerNode    = gui.get_node(node .. "/marker")
	local textbox       = gui.get_node(node .. "/textbox")

	-- Reject text that is too wide for the input field
	gui.set_text(hiddenText, newText)
	local ok, metrics = pcall(D.getTextMetrics, hiddenText)
	local textWidth = (ok and metrics) and (metrics.width * (self.comboboxData[node].mag or 1)) or 0
	local maxWidth  = gui.get_size(textbox).x - 25
	if textWidth > maxWidth then return false end

	gui.set_text(selected_text, newText)
	self.comboboxData[node].value = newText

	if updateMarker then
		local markerPos = gui.get_position(markerNode)
		local ok2, w = pcall(D.getTextMetrics, hiddenText)
		markerPos.x = ok2 and w and
			math.min(math.max(-90, w.width * (self.comboboxData[node].mag or 1) - 90), maxWidth - 15)
			or -90
		gui.set_position(markerNode, markerPos)
	end

	return true
end

-- Debounced list update: cancels any pending timer and reschedules, so rapid
-- keystrokes only trigger one rebuild once the user pauses for 150 ms.
local function scheduleListUpdate(self, node, list, currentText, use_mag)
	self.comboboxData[node].pendingText = currentText

	-- Cancel any already-pending update
	if self.comboboxData[node].updateTimer then
		timer.cancel(self.comboboxData[node].updateTimer)
		self.comboboxData[node].updateTimer = nil
	end

	self.comboboxData[node].updateTimer = timer.delay(0.15, false, function()
		if self.comboboxData[node].open then
			updateDropdownSafe(self, node, list, self.comboboxData[node].pendingText or "", use_mag)
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

	-- Use a custom list override if one has been set via setListAutobox
	local effectiveList = self.comboboxData[node].customList or list

	-- Variables for separated dropdown update handling
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
		if #effectiveList == 0 then
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
		M.initialize(self, node, effectiveList, up, enabled)
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
					-- Build initial list without text-filtering
					updateDropdownSafe(self, node, effectiveList, "", use_mag)
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
		local widthmod = window.get_size()/sys.get_config_int("display.width")

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

			-- Set cursor to click position
			gui.set_screen_position(markerNode, vmath.vector3(D.currentMousePos.x*widthmod,D.currentMousePos.y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			-- Walk back hidden text until it fits within the click position
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			while utf8.len(hiddenTextContent) > 0 do
				local textWidth = 0
				local success, width = pcall(D.getTextMetrics, hiddenText)
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

			-- Snap marker to end of trimmed hidden text
			local success, width = pcall(D.getTextMetrics, hiddenText)
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
			-- Open dropdown showing current text's matches
			updateDropdownSafe(self, node, effectiveList, self.comboboxData[node].value or "", use_mag)
			gui.set_enabled(markerNode, true)
			D.pulsate(markerNode)

			gui.set_color(textbox, D.colors.hover)
			if gui.get_text(selected_text) == D.select_a_value or gui.get_text(selected_text) == D.no_entries then
				gui.set_text(selected_text, "")
				gui.set_text(hiddenText,"")
			end
			gui.set_text(hiddenText, gui.get_text(selected_text))

			-- Set cursor to end of current text
			gui.set_screen_position(markerNode, vmath.vector3((gui.get_position(textbox).x + gui.get_size(textbox).x)*widthmod,gui.get_position(textbox).y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			local hiddenTextContent = gui.get_text(hiddenText) or ""
			while utf8.len(hiddenTextContent) > 0 do
				local success, width = pcall(D.getTextMetrics, hiddenText)
				if not success or not width then break end

				if width.width * self.comboboxData[node].mag - 90 <= markpos.x then
					break
				end

				local shortenstring = utf8.sub(hiddenTextContent, 1, -2)
				if utf8.len(shortenstring) <= 1 then break end

				gui.set_text(hiddenText, shortenstring)
				hiddenTextContent = shortenstring
			end

			local success, width = pcall(D.getTextMetrics, hiddenText)
			if success and width then
				markpos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
			else
				markpos.x = -90
			end
			gui.set_position(markerNode, markpos)
			D.nodes["tab"] = false
		end

		-- Arrow key cursor movement
		if action_id == hash("left") and action.pressed then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			if utf8.len(hiddenTextContent) > 0 then
				local shortenstring = utf8.sub(hiddenTextContent, 1, -2)
				gui.set_text(hiddenText, shortenstring)
				local markerPos = gui.get_position(markerNode)
				local success, width = pcall(D.getTextMetrics, hiddenText)
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
					local success, width = pcall(D.getTextMetrics, hiddenText)
					if success and width then
						markerPos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
					else
						markerPos.x = -90
					end
					gui.set_position(markerNode, markerPos)
				end
			end
		end

		-- Text input with correct cursor handling
		if action_id == hash("text") then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			local selectedTextContent = gui.get_text(selected_text) or ""
			local cursorPos = utf8.len(hiddenTextContent)

			-- Build new text around cursor position
			local before = hiddenTextContent
			local after  = cursorPos < utf8.len(selectedTextContent) and
				utf8.sub(selectedTextContent, cursorPos + 1, -1) or ""
			local newHiddenText = before .. action.text
			local newText       = newHiddenText .. after

			gui.set_text(hiddenText,    newHiddenText)
			gui.set_text(selected_text, newText)
			self.comboboxData[node].value = newText

			-- Advance cursor past the inserted character
			local markerPos = gui.get_position(markerNode)
			local success, width = pcall(D.getTextMetrics, hiddenText)
			if success and width then
				markerPos.x = math.max(-90, width.width * (self.comboboxData[node].mag or 1) - 90)
			else
				markerPos.x = -90
			end
			gui.set_position(markerNode, markerPos)

			scheduleListUpdate(self, node, effectiveList, newText, use_mag)
		end

		-- Backspace: always deletes the character before the cursor
		if action_id == hash("backspace") and (action.pressed or action.repeated) then
			local hiddenTextContent = gui.get_text(hiddenText) or ""
			local selectedTextContent = gui.get_text(selected_text) or ""

			local isPlaceholder = selectedTextContent == "" or
				selectedTextContent == D.select_a_value or
				selectedTextContent == D.no_entries

			if not isPlaceholder then
				local cursorPos = utf8.len(hiddenTextContent)
				if cursorPos > 0 then
					-- Remove the character before the cursor
					local before = utf8.sub(hiddenTextContent, 1, cursorPos - 1)
					local after  = utf8.sub(selectedTextContent, cursorPos + 1, -1)
					local newHiddenText = before
					local newText = before .. after

					gui.set_text(hiddenText, newHiddenText)
					gui.set_text(selected_text, newText)
					self.comboboxData[node].value = newText

					local markerPos = gui.get_position(markerNode)
					local success, width = pcall(D.getTextMetrics, hiddenText)
					if success and width then
						markerPos.x = math.max(-90, width.width * (self.comboboxData[node].mag or 1) - 90)
					else
						markerPos.x = -90
					end
					gui.set_position(markerNode, markerPos)

					scheduleListUpdate(self, node, effectiveList, newText, use_mag)
				end
				-- cursorPos == 0: nothing to delete, fall through
			end
		end

		-- Delete: removes the character after the cursor
		if action_id == hash("delete") and (action.pressed or action.repeated) then
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

				local success, width = pcall(D.getTextMetrics, hiddenText)
				if success and width then
					markerPos.x = math.max(-90, width.width * self.comboboxData[node].mag - 90)
				end
				gui.set_position(markerNode, markerPos)

				scheduleListUpdate(self, node, effectiveList, text, use_mag)
			end
		end

		local listOfButton, listOfText, listOfSelect = buildButtonLists(self, node)
		if #listOfButton > 0 then
			-- Scroll: enabled when dropdown has more than 6 items
			if self.comboboxData[node].count < 6 then
				gui.set_enabled(dragpos, false)
			else
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
					currentPos.y = D.valuelimit(currentPos.y - self.comboboxData[node].scroll.delta.y, 0, self.comboboxData[node].size - 170)
					gui.set_position(dd_obj, currentPos)
				elseif self.comboboxData[node].open and action_id == hash("wheelup") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
					local currentPos = gui.get_position(dd_obj)
					currentPos.y = D.valuelimit(currentPos.y - D.scrollSpeed, 0, self.comboboxData[node].size - 170)
					gui.set_position(dd_obj, currentPos)
				elseif self.comboboxData[node].open and action_id == hash("wheeldown") and gui.pick_node(dd_obj, D.currentMousePos.x, D.currentMousePos.y) then
					local currentPos = gui.get_position(dd_obj)
					currentPos.y = D.valuelimit(currentPos.y + D.scrollSpeed, 0, self.comboboxData[node].size - 170)
					gui.set_position(dd_obj, currentPos)
				end
				-- Sync scroll indicator
				local currentPos = gui.get_position(dd_obj)
				local amountcomplete = currentPos.y / (self.comboboxData[node].size - 170)
				local dragposCurrent = gui.get_position(dragpos)
				dragposCurrent.y = D.valuelimit(-170 * amountcomplete, -gui.get_size(dd_obj).y, -10)
				gui.set_position(dragpos, dragposCurrent)
			end

			-- Track hovered/selected row
			self.comboboxData[node].previous = nil
			for k in pairs(listOfButton) do
				local ok, color = pcall(function() return gui.get_color(gui.get_node(node .. listOfButton[k])) end)
				if ok and color == D.colors.hover then
					self.comboboxData[node].previous = k
					break
				end
			end
			if self.comboboxData[node].previous == nil then
				for k in pairs(listOfButton) do
					local ok, color = pcall(function() return gui.get_color(gui.get_node(node .. listOfButton[k])) end)
					if ok and color == D.colors.select then
						self.comboboxData[node].previous = k
						break
					end
				end
				if self.comboboxData[node].previous == nil then
					self.comboboxData[node].previous = 1
					pcall(function() gui.set_color(gui.get_node(node .. listOfButton[1]), D.colors.hover) end)
				end
			end

			-- Keyboard navigation
			local prev = self.comboboxData[node].previous
			if action_id == hash("up") and action.pressed and prev and prev > 1 and self.comboboxData[node].open then
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev - 1]), D.colors.hover) end)
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev]),     D.colors.active) end)
				if self.comboboxData[node].count > 6 then
					gui.set_position(dd_obj, vmath.vector3(0, (prev - 1) * 30 - 30, 0))
				end
			elseif action_id == hash("down") and action.pressed and prev and prev < #listOfButton and self.comboboxData[node].open then
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev + 1]), D.colors.hover) end)
				pcall(function() gui.set_color(gui.get_node(node .. listOfButton[prev]),     D.colors.active) end)
				if self.comboboxData[node].count > 6 then
					gui.set_position(dd_obj, vmath.vector3(0, (prev + 1) * 30 - 30, 0))
				end
			end

			-- Confirm selection with Enter
			if action_id == hash("enter") and action.pressed then
				for k in pairs(listOfButton) do
					local ok, color = pcall(function() return gui.get_color(gui.get_node(node .. listOfButton[k])) end)
					if ok and color == D.colors.hover then
						local ok_t, txtNode = pcall(gui.get_node, node .. listOfText[k])
						if ok_t then self.comboboxData[node].value = gui.get_text(txtNode) end
						closeDropdown(self, node)
						D.stop_pulsate(markerNode)
						gui.set_enabled(markerNode, false)
						break
					end
				end
				if D.isMobileDevice then
					gui.reset_keyboard()
					gui.hide_keyboard()
				end
			end

			-- Confirm selection with touch / update hover highlight
			if gui.pick_node(mask, D.currentMousePos.x, D.currentMousePos.y) then
				for k in pairs(listOfButton) do
					local ok_b, btn = pcall(gui.get_node, node .. listOfButton[k])
					local ok_t, txt = pcall(gui.get_node, node .. listOfText[k])
					local ok_s, sel = pcall(gui.get_node, node .. listOfSelect[k])
					if not (ok_b and ok_t and ok_s) then break end
					local hovered  = gui.pick_node(btn, D.currentMousePos.x, D.currentMousePos.y)
					local itemText = gui.get_text(txt)
					if action_id == hash("touch") and action.released and self.comboboxData[node].open and hovered then
						if itemText ~= D.no_entries then
							self.comboboxData[node].value = itemText
							closeDropdown(self, node)
							D.stop_pulsate(markerNode)
							gui.set_enabled(markerNode, false)
							if D.isMobileDevice then
								gui.reset_keyboard()
								gui.hide_keyboard()
							end
							break
						end
					elseif self.comboboxData[node].open and hovered then
						if self.comboboxData[node].value == itemText then
							gui.set_color(btn, D.colors.select)
							gui.set_scale(sel, vmath.vector3(1, 0.75, 1))
						else
							gui.set_color(btn, D.colors.hover)
						end
					elseif self.comboboxData[node].open and not hovered then
						if self.comboboxData[node].value == itemText then
							gui.set_color(btn, D.colors.hover)
							gui.set_scale(sel, vmath.vector3(1, 1, 1))
						else
							gui.set_color(btn, D.colors.active)
						end
					end
				end
			end
		end -- if #listOfButton > 0
	end -- if D.nodes["active"] == node

	local value = self.comboboxData[node].value
	local prev = self.comboboxData[node].lastValue
	if prev == nil then prev = value end -- no spurious change on first frame
	local changed = (value ~= prev)
	self.comboboxData[node].lastValue = value
	return value, changed
end

-- Reset a standard combobox to its unselected placeholder state.
-- Closes the dropdown if it is open and clears the stored value.
function M.clearCombobox(self, node)
	self.comboboxData       = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	local data              = self.comboboxData[node]

	local textbox       = gui.get_node(node .. "/textbox")
	local selected_text = gui.get_node(node .. "/selecttext")
	local mask          = gui.get_node(node .. "/bg")
	local arrow         = gui.get_node(node .. "/arrow")

	-- Close dropdown if currently open
	if data.open then
		M.deleteCombobox(self, node)
		gui.set_enabled(mask, false)
		data.open = false
		data.init = false
	end

	-- Cancel any pending list-update timer
	if data.updateTimer then
		timer.cancel(data.updateTimer)
		data.updateTimer = nil
	end

	-- Reset value to placeholder
	data.value     = D.select_a_value
	data.lastValue = D.select_a_value  -- prevent spurious changed on next frame
	gui.set_text(selected_text, D.select_a_value)
	gui.set_color(textbox, D.colors.active)
	gui.set_color(arrow,   D.colors.accent)

	-- Release focus if this node was active
	if D.nodes["active"] == node then
		D.nodes["active"]   = nil
		self.selectedNode   = nil
	end
end

-- Reset an auto-suggest box to its unselected placeholder state.
-- Closes the dropdown, clears typed text and the stored value.
function M.clearAutobox(self, node)
	self.comboboxData       = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	local data              = self.comboboxData[node]

	local textbox       = gui.get_node(node .. "/textbox")
	local selected_text = gui.get_node(node .. "/selecttext")
	local hiddenText    = gui.get_node(node .. "/hiddentext")
	local markerNode    = gui.get_node(node .. "/marker")
	local mask          = gui.get_node(node .. "/bg")
	local arrow         = gui.get_node(node .. "/arrow")

	-- Close dropdown if currently open
	if data.open then
		M.deleteCombobox(self, node)
		gui.set_enabled(mask, false)
		data.open = false
		data.init = false
	end

	-- Cancel any pending list-update timer
	if data.updateTimer then
		timer.cancel(data.updateTimer)
		data.updateTimer = nil
	end

	-- Reset text fields to placeholder
	gui.set_text(selected_text, D.select_a_value)
	gui.set_text(hiddenText, D.select_a_value)
	data.value     = D.select_a_value
	data.lastValue = D.select_a_value  -- prevent spurious changed on next frame

	-- Reset marker
	D.stop_pulsate(markerNode)
	gui.set_enabled(markerNode, false)
	local markerPos = gui.get_position(markerNode)
	markerPos.x = -90
	gui.set_position(markerNode, markerPos)

	gui.set_color(textbox, D.colors.active)
	gui.set_color(arrow,   D.colors.inactive)

	-- Release focus if this node was active
	if D.nodes["active"] == node then
		D.nodes["active"] = nil
		self.selectedNode = nil
	end
end

-- Override the source list for a standard combobox at runtime.
-- On the next open the new list is used instead of the one passed to combobox().
-- Call clearCombobox() afterwards to reset the displayed value if desired.
function M.setListCombobox(self, node, list)
	self.comboboxData       = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	self.comboboxData[node].customList = list
	-- Force dropdown to be rebuilt on next open
	self.comboboxData[node].init = false
end

-- Override the source list for an auto-suggest box at runtime.
-- Filtering will be applied to the new list on the next keystroke.
function M.setListAutobox(self, node, list)
	self.comboboxData       = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	self.comboboxData[node].customList = list
	-- Force dropdown to be rebuilt on next open
	self.comboboxData[node].init = false
end

-- Programmatically set the value of an auto-suggest box and prevent a spurious
-- 'changed' event on the next frame.  Mirrors setValueAutobox but also syncs lastValue.
function M.initializeAutobox(self, node, value, active)
	M.setValueAutobox(self, node, value, active)
	self.comboboxData       = self.comboboxData or {}
	self.comboboxData[node] = self.comboboxData[node] or {}
	-- Prevent spurious 'changed' on the next frame
	self.comboboxData[node].lastValue = self.comboboxData[node].value
end

return M