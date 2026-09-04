-- textbox.lua
-- Textinput component for DD-GUI

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

-- TEXTBOX
-- Local functions for textbox
local function editLine(self, action, node, type, equal_length)
	local textNode = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext") -- Hidden text for comparision
	local markerNode = gui.get_node(node .. "/marker")

	if not equal_length then
		local hiddenlength = utf8.len(gui.get_text(hiddenText))
		self.textboxData[node].makerpos = gui.get_position(markerNode)
		local text = gui.get_text(hiddenText)
		if type == "text" then
			text = text .. action.text
			gui.set_text(hiddenText, text)
			text = text .. utf8.sub(gui.get_text(textNode), hiddenlength+1, -1)
		elseif type == "backspace" then
			text = utf8.sub(text, 1, -2)
			gui.set_text(hiddenText, text)
			text = text .. utf8.sub(gui.get_text(textNode), hiddenlength+1, -1)
		elseif type == "del" then
			text = text .. utf8.sub(gui.get_text(textNode), hiddenlength+2, -1)
		end
		gui.set_text(textNode, text)
		self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width
		gui.set_position(markerNode, self.textboxData[node].makerpos)
	else
		self.textboxData[node].makerpos = gui.get_position(markerNode)
		local text = gui.get_text(hiddenText)
		if type == "text" then
			text = text .. action.text
		elseif type == "backspace" then
			text = utf8.sub(text, 1, -2)
		elseif type == "del" then
			-- cursor already at end; nothing to delete
		end
		gui.set_text(hiddenText, text)
		gui.set_text(textNode, text)
		self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width
		gui.set_position(markerNode, self.textboxData[node].makerpos)
	end
end

-- Main function for textbox
-- placeholder : string shown when field is empty and inactive (optional)
-- maxlength   : maximum number of UTF-8 characters allowed (optional, nil = unlimited)
-- readonly    : when true the field cannot be focused or edited (optional)
function M.textbox(self, action_id, action, node, enabled, tab_to, placeholder, maxlength, readonly)
	if action ~= nil and action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Load nodes
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext") -- Hidden text for comparision
	local markerNode = gui.get_node(node .. "/marker")

	-- Check current value
	self.textboxData = self.textboxData or {}
	self.textboxData[node] = self.textboxData[node] or {}
	self.textboxData[node].text = self.textboxData[node].text or ""
	self.textboxData[node].enabled = enabled

	D.nodes["active"] = D.nodes["active"] or nil
	D.nodes["tab"] = D.nodes["tab"] or false

	-- Display placeholder when field is empty and not focused
	if placeholder and self.textboxData[node].text == "" and D.nodes["active"] ~= node then
		gui.set_text(textNode, placeholder)
		gui.set_color(textNode, D.colors.inactive)
	else
		gui.set_text(textNode, self.textboxData[node].text)
		if placeholder then
			gui.set_color(textNode, D.colors.black)
		end
	end

	if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.textboxData[node].enabled then
		gui.set_color(bgNode, D.colors.hover)
		if action_id == hash("touch") and action.pressed and gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and D.nodes["active"] == nil and not readonly then
			D.nodes["active"] = node
			D.nodes["tab"] = false
			if D.isMobileDevice then
				gui.show_keyboard(gui.KEYBOARD_TYPE_DEFAULT, true)
			end
			D.pulsate(markerNode)
		end
	elseif not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.textboxData[node].enabled and D.nodes["active"] == node then
		gui.set_color(bgNode, D.colors.hover)
		if action_id == hash("touch") and action.pressed then
			D.nodes["active"] = nil
			D.nodes["tab"] = false
			gui.set_color(bgNode, D.colors.active)
			gui.set_enabled(markerNode, false)
			D.stop_pulsate(markerNode)
			if D.isMobileDevice then
				gui.hide_keyboard()
			end
		end
	elseif not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.textboxData[node].enabled and D.nodes["active"] ~= node then
		gui.set_color(bgNode, D.colors.active)
	elseif not self.textboxData[node].enabled then
		gui.set_color(bgNode, D.colors.inactive)
		if D.nodes["active"] == node then
			D.nodes["active"] = nil
			D.stop_pulsate(markerNode)
		end
	end

	-- If tab to
	if action_id == hash("tab") and action.pressed and tab_to ~= nil and D.nodes["tab"] == false and D.nodes["active"] == node then
		D.nodes["active"] = tab_to
		gui.set_color(bgNode, D.colors.active)
		gui.set_enabled(markerNode, false)
		D.stop_pulsate(markerNode)
		D.nodes["tab"] = true
	end

	if D.nodes["active"] == node and not readonly then
		local widthmod = window.get_size() / sys.get_config_int("display.width")
		if action_id == hash("touch") and action.released and gui.pick_node(bgNode, action.x, action.y) then
			gui.set_text(hiddenText, gui.get_text(textNode))
			gui.set_screen_position(markerNode, vmath.vector3(action.x*widthmod,action.y,0)) -- Set marker at click position
			self.textboxData[node].makerpos = gui.get_position(markerNode) -- Convert to local pos
			self.textboxData[node].makerpos.y = 0 -- Set y position to 0 to keep in middle of box
			gui.set_position(markerNode, self.textboxData[node].makerpos)
			if get_text_metrics_from_node(hiddenText).width > self.textboxData[node].makerpos.x and utf8.len(gui.get_text(hiddenText)) > 1 then
				while get_text_metrics_from_node(hiddenText).width > self.textboxData[node].makerpos.x do -- Adjust hidden string to fit hiddenstring
					local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
					gui.set_text(hiddenText, shortenstring)
					if utf8.len(shortenstring) <= 2 then
						break
					end
				end
				self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width -- Update marker to be at the end the hiddenstring
				gui.set_position(markerNode, self.textboxData[node].makerpos)
			else
				self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width -- Update marker to be at the end the hiddenstring
				gui.set_position(markerNode, self.textboxData[node].makerpos)
			end
			gui.set_enabled(markerNode, true) -- Enable marker
		elseif D.nodes["tab"] then	
			gui.set_text(hiddenText, gui.get_text(textNode))
			self.textboxData[node].makerpos = gui.get_position(markerNode) -- Convert to local pos
			self.textboxData[node].makerpos.y = 0 -- Set y position to 0 to keep in middle of box
			self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width -- Update marker to be at the end the hiddenstring
			gui.set_position(markerNode, self.textboxData[node].makerpos)
			D.nodes["tab"] = false -- Reset the tab flag after processing
			gui.set_enabled(markerNode, true) -- Enable marker
			D.pulsate(markerNode)
			-- Input text
		elseif action_id == hash("text") and get_text_metrics_from_node(textNode).width < (gui.get_size(bgNode).x-25)
				and (maxlength == nil or utf8.len(gui.get_text(textNode)) < maxlength) then
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then -- Hidden is shorter add text for that point
				editLine(self, action, node, "text", false)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(textNode)) then -- If equal add text at the end
				editLine(self, action, node, "text", true)
			end
		-- Erase using backspace
		elseif action_id == hash("backspace") and (action.pressed or action.repeated) then -- Remove letters
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then -- If hidden is shorter remove text from that point
				editLine(self, action, node, "backspace", false)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(textNode)) then -- If equal remove from the end
				editLine(self, action, node, "backspace", true)
			end
		elseif action_id == hash("delete") and (action.pressed or action.repeated) then -- Same as above but delete
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then
				editLine(self, action, node, "del", false)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(textNode)) then -- If marker at end there is nothing to delete
				editLine(self, action, node, "del", true)
			end
		elseif action_id == hash("left") and action.pressed and utf8.len(gui.get_text(hiddenText)) > 0 then
			local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
			gui.set_text(hiddenText, shortenstring)
			self.textboxData[node].makerpos = gui.get_position(markerNode)
			self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width
			gui.set_position(markerNode, self.textboxData[node].makerpos)
		elseif action_id == hash("right") and action.pressed and utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then
			local lengthNew = utf8.len(gui.get_text(hiddenText))
			local lenDiff = utf8.len(gui.get_text(textNode)) - lengthNew
			local shortenstring = utf8.sub(gui.get_text(textNode), 1, -lenDiff)
			gui.set_text(hiddenText, shortenstring)
			self.textboxData[node].makerpos = gui.get_position(markerNode)
			self.textboxData[node].makerpos.x = get_text_metrics_from_node(hiddenText).width
			gui.set_position(markerNode, self.textboxData[node].makerpos)
		end
		self.textboxData[node].text = gui.get_text(textNode)
	end
	local text = self.textboxData[node].text
	local prev = self.textboxData[node].lastText
	if prev == nil then prev = text end -- no spurious change on first frame
	local changed = (text ~= prev)
	self.textboxData[node].lastText = text
	return text, changed
end

-- TEXTBOX MULTILINE
-- Local functions for textboxMultiline
local function deleteLine (node, id)
	local text = gui.get_node(node .. "/text" .. id)
	local hidden = gui.get_node(node .. "/hiddentext" .. id)
	local marker = gui.get_node(node .. "/marker" .. id)
	local innerbox = gui.get_node(node .. "/innerbox" .. id)

	gui.delete_node(text)
	gui.delete_node(hidden)
	gui.delete_node(marker)
	gui.delete_node(innerbox)
end

local function addLine (node, currentline)
	local text = gui.get_node(node .. "/text")
	local hidden = gui.get_node(node .. "/hiddentext")
	local marker = gui.get_node(node .. "/marker")
	local innerbox = gui.get_node(node .. "/innerbox")
	local carrier = gui.get_node(node .. "/carrier")

	local newtext = gui.clone(text)
	local newhidden = gui.clone(hidden)
	local newmarker = gui.clone(marker)
	local newinnerbox = gui.clone(innerbox)

	gui.set_text(newtext, "")
	gui.set_text(newhidden, "")

	gui.set_id(newtext, node .. "/text" .. currentline)
	gui.set_id(newhidden, node .. "/hiddentext" .. currentline)
	gui.set_id(newmarker, node .. "/marker" .. currentline)
	gui.set_id(newinnerbox, node .. "/innerbox" .. currentline)

	gui.set_parent(newtext, newinnerbox, false)
	gui.set_parent(newhidden, newtext, true)
	gui.set_parent(newmarker, newtext, true)
	gui.set_parent(newinnerbox, carrier, true)

	local newPos = vmath.vector3(0, -20*(currentline-1), 0)
	gui.set_position(newinnerbox, newPos)
	local newline = {text = newtext, hidden = newhidden, marker = newmarker, innerbox = newinnerbox, id = currentline} 
	return newline
end

local function sortLines (node, list)
	for i = 1, #list do
		gui.set_position(list[i].innerbox, vmath.vector3(10,-20 * i,0)) 
	end
	local carrier = gui.get_node(node .. "/carrier")
	local carries_size = gui.get_size(carrier)
	carries_size.y = #list*20
	gui.set_size(carrier, carries_size)
end

local function sizeFix(self, node)
	if not self.textboxData[node].sizeFix then
		local bgNode = gui.get_node(node .. "/bg")
		local textNode = gui.get_node(node .. "/text")
		local hiddenText = gui.get_node(node .. "/hiddentext") -- Hidden text for comparision
		local carrier = gui.get_node(node .. "/carrier")
		local innerbox = gui.get_node(node .. "/innerbox")
		local dragpos = gui.get_node(node .. "/dragpos")
	
		local bgSize = gui.get_size(bgNode)
		local textboxSize = gui.get_size(innerbox)
		textboxSize.x = bgSize.x -18 
		gui.set_size(carrier, bgSize)
		gui.set_size(innerbox, textboxSize)
		gui.set_size(hiddenText, textboxSize)
		gui.set_size(textNode, textboxSize)
		bgSize.x = bgSize.x - 7
		gui.set_position(dragpos, bgSize)
		self.textboxData[node].sizeFix = true
	end
end

local function scrollMulti(self, node, speed)
	local bgNode = gui.get_node(node .. "/bg")
	local carrier = gui.get_node(node .. "/carrier")
	local dragpos = gui.get_node(node .. "/dragpos")
	
	for i = 1, #self.textboxData[node].lines do
		local currentPos = gui.get_position(carrier)
		currentPos.y =  D.valuelimit(currentPos.y + speed/5, 0, gui.get_size(carrier).y-gui.get_size(bgNode).y+10)
		gui.set_position(carrier, currentPos)
	end
	local dragPos = gui.get_position(dragpos)
	local posDelta = -gui.get_position(carrier).y / (gui.get_size(carrier).y - gui.get_size(bgNode).y)
	dragPos.y = D.valuelimit(gui.get_size(bgNode).y * posDelta, -gui.get_size(bgNode).y+15, -15)
	gui.set_position(dragpos, dragPos)
end

local function moveLineMulti(self, node, direction)
	local bgNode = gui.get_node(node .. "/bg")
	local carrier = gui.get_node(node .. "/carrier")
	local dragpos = gui.get_node(node .. "/dragpos")

	local currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
	local lengthstring = utf8.len(gui.get_text(currentline.hidden))

	D.stop_pulsate(currentline.marker)
	gui.set_enabled(currentline.marker, false)
	
	if direction == "up" then 
		self.textboxData[node].activeline = self.textboxData[node].activeline - 1
		currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
	elseif direction == "down" then
		self.textboxData[node].activeline = self.textboxData[node].activeline + 1
		currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
	end
	
	gui.set_enabled(currentline.marker, true)
	local lenDiff = utf8.len(gui.get_text(currentline.text)) + 1 - lengthstring
	if lenDiff > 0 then
		local shortenstring = utf8.sub(gui.get_text(currentline.text), 1, -lenDiff)
		gui.set_text(currentline.hidden, shortenstring)
	else
		gui.set_text(currentline.hidden, gui.get_text(currentline.text))
	end
	
	local markerPos = gui.get_position(currentline.marker)
	markerPos.x = get_text_metrics_from_node(currentline.hidden).width
	gui.set_position(currentline.marker, markerPos)

	if gui.get_screen_position(currentline.innerbox).y >= gui.get_screen_position(bgNode).y and direction == "up" then
		local carrierpos = gui.get_position(carrier)
		carrierpos.y = carrierpos.y - 20
		gui.set_position(carrier, carrierpos)
	elseif gui.get_position(currentline.innerbox).y < -60 and direction == "down" then
		local carrierpos = gui.get_position(carrier)
		carrierpos.y = carrierpos.y + 20
		gui.set_position(carrier, carrierpos)
	end
	
	local dragPos = gui.get_position(dragpos)
	local posDelta = -gui.get_position(carrier).y / (gui.get_size(carrier).y - gui.get_size(bgNode).y)
	dragPos.y = D.valuelimit(gui.get_size(bgNode).y * posDelta, -gui.get_size(bgNode).y+15, -15)
	gui.set_position(dragpos, dragPos)
	D.pulsate(currentline.marker)
end

-- Main function for textbox multiline
function M.textboxMultiline(self, action_id, action, node, enabled, tab_to)
	if action ~= nil and action.x ~= nil then
		D.currentMousePos.x = action.x
		D.currentMousePos.y = action.y
	end
	
	-- Load nodes
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext") -- Hidden text for comparision
	local markerNode = gui.get_node(node .. "/marker")
	local carrier = gui.get_node(node .. "/carrier")
	local innerbox = gui.get_node(node .. "/innerbox")
	local dragpos = gui.get_node(node .. "/dragpos")

	self.textboxData = self.textboxData or {}
	self.textboxData[node] = self.textboxData[node] or {}
	self.textboxData[node].text = self.textboxData[node].text or ""
	self.textboxData[node].linecount = self.textboxData[node].linecount or 0
	self.textboxData[node].activeline = self.textboxData[node].activeline or 0
	self.textboxData[node].lines = self.textboxData[node].lines or {}
	self.textboxData[node].sizeFix = self.textboxData[node].sizeFix or false
	self.textboxData[node].scroll = self.textboxData[node].scroll or {}	
	self.textboxData[node].enabled = enabled

	sizeFix(self, node)

	if gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and enabled then
		gui.set_color(bgNode, D.colors.hover)
		if action_id == hash("touch") and action.pressed and gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and (D.nodes["active"] == nil or D.nodes["active"] == node) then
			D.nodes["active"], self.selectedNode = node, node
			D.nodes["tab"] = false
			if D.isMobileDevice then
				gui.show_keyboard(gui.KEYBOARD_TYPE_DEFAULT, true)
			end
		end
	elseif not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.textboxData[node].enabled and D.nodes["active"] == node then
		gui.set_color(bgNode, D.colors.hover)
		if action_id == hash("touch") and action.pressed then
			D.nodes["active"], self.selectedNode = nil, nil
			gui.set_color(bgNode, D.colors.active)
			gui.set_enabled(markerNode, false)
			gui.set_enabled(self.textboxData[node].lines[self.textboxData[node].activeline].marker, false)
			if D.isMobileDevice then
				gui.hide_keyboard()
			end
		end
		-- if not active an not hoverd
	elseif not gui.pick_node(bgNode, D.currentMousePos.x, D.currentMousePos.y) and self.textboxData[node].enabled then
		gui.set_color(bgNode, D.colors.active)
		-- disabled
	elseif not self.textboxData[node].enabled then
		gui.set_color(bgNode, D.colors.inactive)
		if self.selectedNode == node then
			D.nodes["active"], self.selectedNode = nil, nil
		end
	end

	-- If tab to
	if action_id == hash("tab") and action.pressed and tab_to ~= nil and D.nodes["tab"] == false and D.nodes["active"] == node then
		D.nodes["active"] = tab_to
		gui.set_color(bgNode, D.colors.active)
		gui.set_enabled(self.textboxData[node].lines[self.textboxData[node].activeline].marker, false)
		D.nodes["tab"] = true
	end

	if D.nodes["active"] == node then
		-- Create first line if not created
		if self.textboxData[node].linecount == 0 then
			self.textboxData[node].lines[1] = {text = textNode, hidden = hiddenText, marker = markerNode, innerbox = innerbox, id = 1}
			self.textboxData[node].activeline = 1
			self.textboxData[node].linecount = 1
		end

		local widthmod = window.get_size()/sys.get_config_int("display.width")

		-- if tabbed to
		if D.nodes["tab"] then
			self.textboxData[node].activeline = #self.textboxData[node].lines
			gui.set_text(self.textboxData[node].lines[self.textboxData[node].activeline].hidden, gui.get_text(self.textboxData[node].lines[self.textboxData[node].activeline].text))
			gui.set_enabled(self.textboxData[node].lines[self.textboxData[node].activeline].marker, true) -- Enable marker
			local markerpos = gui.get_position(self.textboxData[node].lines[self.textboxData[node].activeline].marker)
			markerpos.x = get_text_metrics_from_node(self.textboxData[node].lines[self.textboxData[node].activeline].hidden).width -- Update marker to be at the end the hiddenstring
			gui.set_position(self.textboxData[node].lines[self.textboxData[node].activeline].marker, markerpos)
			gui.set_enabled(self.textboxData[node].lines[self.textboxData[node].activeline].marker, true)
			D.pulsate(self.textboxData[node].lines[self.textboxData[node].activeline].marker)
			D.nodes["tab"] = false -- Reset the tab flag after processing
		end

		--Scrolling
		if  (gui.get_size(carrier).y - gui.get_size(bgNode).y) > 0 then 
			-- Input from mouse
			if action_id == hash("touch") and action.pressed then
				self.textboxData[node].scroll.active = true
				self.textboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
			elseif action_id == hash("touch") and action.released then
				self.textboxData[node].scroll.active = false
				self.textboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
				-- Reset if outside node
				if not gui.pick_node(bgNode, action.x, action.y) then
					gui.set_color(bgNode, D.colors.active)
					for i = 1, #self.textboxData[node].lines do 
						gui.set_enabled(self.textboxData[node].lines[i].marker, false)
					end
					D.nodes["active"] = nil
				end
			end
			-- Move
			gui.set_visible(dragpos, true)
			if self.textboxData[node].scroll.active then
				local currentPos = gui.get_position(carrier)
				self.textboxData[node].scroll.delta = self.textboxData[node].scroll.pos - vmath.vector3(action.x, action.y, 0)
				self.textboxData[node].scroll.pos = vmath.vector3(action.x, action.y, 0)
				currentPos.y =  D.valuelimit(currentPos.y - self.textboxData[node].scroll.delta.y, 0, gui.get_size(carrier).y-gui.get_size(bgNode).y+20)
				gui.set_position(carrier, currentPos)
				local dragPos = gui.get_position(dragpos)
				local posDelta = -gui.get_position(carrier).y / (gui.get_size(carrier).y - gui.get_size(bgNode).y)
				dragPos.y = D.valuelimit(gui.get_size(bgNode).y * posDelta, -gui.get_size(bgNode).y+15, -15)
				gui.set_position(dragpos, dragPos)
			elseif action_id == hash("wheelup") and gui.pick_node(bgNode, action.x, action.y) then
				scrollMulti(self, node, -D.scrollSpeed)
			elseif action_id == hash("wheeldown") and gui.pick_node(bgNode, action.x, action.y) then
				scrollMulti(self, node, D.scrollSpeed)
			end
		else
			gui.set_visible(dragpos, false)
		end

		--Key movment
		if action_id == hash("up") and action.pressed and self.textboxData[node].activeline > 1 then
			moveLineMulti(self, node, "up")
		elseif action_id == hash("down") and action.pressed and self.textboxData[node].activeline < #self.textboxData[node].lines then
			moveLineMulti(self, node, "down")
		end

		local currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
		if action_id == hash("left") and action.pressed and utf8.len(gui.get_text(currentline.hidden)) > 0 then
			local shortenstring = utf8.sub(gui.get_text(currentline.hidden), 1, -2)
			gui.set_text(currentline.hidden, shortenstring)
			local markerPos = gui.get_position(currentline.marker)
			markerPos.x = get_text_metrics_from_node(currentline.hidden).width
			gui.set_position(currentline.marker, markerPos)
		elseif action_id == hash("right") and action.pressed and utf8.len(gui.get_text(currentline.hidden)) < utf8.len(gui.get_text(currentline.text)) then
			local lengthNew = utf8.len(gui.get_text(currentline.hidden))
			local lenDiff = utf8.len(gui.get_text(currentline.text)) - lengthNew
			local shortenstring = utf8.sub(gui.get_text(currentline.text), 1, -lenDiff)
			gui.set_text(currentline.hidden, shortenstring)
			local markerPos = gui.get_position(currentline.marker)
			markerPos.x = get_text_metrics_from_node(currentline.hidden).width
			gui.set_position(currentline.marker, markerPos)
		end

		-- Touch
		for i = 1, #self.textboxData[node].lines do 
			if action_id == hash("touch") and action.released and gui.pick_node(self.textboxData[node].lines[i].innerbox, action.x, action.y) then
				gui.set_text(self.textboxData[node].lines[i].hidden, gui.get_text(self.textboxData[node].lines[i].text))
				self.textboxData[node].activeline = i -- Set active to current
				gui.set_enabled(self.textboxData[node].lines[i].marker, true) -- Enable marker
				gui.set_screen_position(self.textboxData[node].lines[i].marker, vmath.vector3(action.x*widthmod,action.y,0)) -- Set marker at click position
				self.textboxData[node].makerpos = gui.get_position(self.textboxData[node].lines[i].marker) -- Convert to local pos
				self.textboxData[node].makerpos.y = 0
				if utf8.len(gui.get_text(self.textboxData[node].lines[i].hidden)) >= 1 then -- If two or more letters allow editing
					while get_text_metrics_from_node(self.textboxData[node].lines[i].hidden).width > self.textboxData[node].makerpos.x do -- Adjust hidden string to fit hiddenstring
						local shortenstring = utf8.sub(gui.get_text(self.textboxData[node].lines[i].hidden), 1, -2)
						gui.set_text(self.textboxData[node].lines[i].hidden, shortenstring)
						if utf8.len(shortenstring) <= 1 then
							break
						end
					end
				end
				self.textboxData[node].makerpos.x = get_text_metrics_from_node(self.textboxData[node].lines[i].hidden).width -- Update marker to be at the end the hiddenstring
				gui.set_position(self.textboxData[node].lines[i].marker, self.textboxData[node].makerpos)
				D.pulsate(self.textboxData[node].lines[i].marker)
			elseif action_id == hash("touch") and action.released and not gui.pick_node(self.textboxData[node].lines[i].innerbox, action.x, action.y) then
				gui.set_enabled(self.textboxData[node].lines[i].marker, false)
				D.stop_pulsate(self.textboxData[node].lines[i].marker)
			end
		end

		-- Delete
		if action_id == hash("backspace") and (action.pressed or action.repeated) then -- Remove one letter
			currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
			if utf8.len(gui.get_text(currentline.hidden)) == 0 and self.textboxData[node].activeline > 1 then -- If higher then first line
				local text = gui.get_text(currentline.text)
				local rowabove = gui.get_text(self.textboxData[node].lines[self.textboxData[node].activeline-1].text)
				text = rowabove .. text
				gui.set_text(self.textboxData[node].lines[self.textboxData[node].activeline - 1].text, text)
				deleteLine(node, currentline.id)
				table.remove(self.textboxData[node].lines, self.textboxData[node].activeline)
				self.textboxData[node].activeline = self.textboxData[node].activeline - 1
				sortLines(node, self.textboxData[node].lines)
				currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
				gui.set_text(currentline.hidden, rowabove)
				local markerPos = gui.get_position(currentline.marker)
				markerPos.x = get_text_metrics_from_node(currentline.hidden).width
				gui.set_position(currentline.marker, markerPos)
				gui.set_enabled(currentline.marker, true)
				D.pulsate(currentline.marker)
				if gui.get_screen_position(currentline.innerbox).y >= gui.get_screen_position(bgNode).y then
					local carrierpos = gui.get_position(carrier)
					carrierpos.y = carrierpos.y - 20
					gui.set_position(carrier, carrierpos)
					local dragPos = gui.get_position(dragpos)
					local posDelta = -gui.get_position(carrier).y / (gui.get_size(carrier).y - gui.get_size(bgNode).y)
					dragPos.y = D.valuelimit(gui.get_size(bgNode).y * posDelta, -gui.get_size(bgNode).y+15, -5)
					gui.set_position(dragpos, dragPos)
				end
			elseif utf8.len(gui.get_text(currentline.hidden)) < utf8.len(gui.get_text(currentline.text)) then -- If hidden is shorter remove text from that point
				local hiddenlength = utf8.len(gui.get_text(currentline.hidden))
				local markerPos = gui.get_position(currentline.marker)
				local text = gui.get_text(currentline.hidden)
				text = utf8.sub(text, 1, -2)
				gui.set_text(currentline.hidden, text)
				text = text .. utf8.sub(gui.get_text(currentline.text), hiddenlength+1, -1)
				gui.set_text(currentline.text, text)
				markerPos.x = get_text_metrics_from_node(currentline.hidden).width
				gui.set_position(currentline.marker, markerPos)
			elseif utf8.len(gui.get_text(currentline.hidden)) == utf8.len(gui.get_text(currentline.text)) then -- If equal remove from the end
				local markerPos = gui.get_position(currentline.marker)
				local text = gui.get_text(currentline.hidden)
				text = utf8.sub(text, 1, -2)
				gui.set_text(currentline.hidden, text)
				gui.set_text(currentline.text, text)
				markerPos.x = get_text_metrics_from_node(currentline.hidden).width
				gui.set_position(currentline.marker, markerPos)
			end
		end
		if action_id == hash("delete") and (action.pressed or action.repeated) then -- Same as above but delete
			currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
			if utf8.len(gui.get_text(currentline.hidden)) < utf8.len(gui.get_text(currentline.text)) then
				local hiddenlength = utf8.len(gui.get_text(currentline.hidden))
				local markerPos = gui.get_position(currentline.marker)
				local text = gui.get_text(currentline.hidden)
				gui.set_text(currentline.hidden, text)
				text = text .. utf8.sub(gui.get_text(currentline.text), hiddenlength+2, -1)
				gui.set_text(currentline.text, text)
				markerPos.x = get_text_metrics_from_node(currentline.hidden).width
				gui.set_position(currentline.marker, markerPos)
			end
		end

		-- New line
		if action_id == hash("enter") and action.pressed then -- add new line
			currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
			if utf8.len(gui.get_text(currentline.hidden)) < utf8.len(gui.get_text(currentline.text)) then
				local hiddenlength = utf8.len(gui.get_text(currentline.hidden))
				local text = gui.get_text(currentline.hidden)
				local textfornextline = utf8.sub(gui.get_text(currentline.text), hiddenlength+1, -1)
				gui.set_text(currentline.text, text)
				gui.set_enabled(currentline.marker, false)
				D.stop_pulsate(currentline.marker)
				self.textboxData[node].linecount = self.textboxData[node].linecount + 1
				self.textboxData[node].activeline = self.textboxData[node].activeline + 1
				table.insert(self.textboxData[node].lines, self.textboxData[node].activeline, addLine(node, self.textboxData[node].linecount))
				currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
				gui.set_text(currentline.text, textfornextline)
				gui.set_text(currentline.hidden, "")
				sortLines(node, self.textboxData[node].lines)
				local markerPos = gui.get_position(currentline.marker)
				markerPos.x = 0
				gui.set_position(currentline.marker, markerPos)
				gui.set_enabled(currentline.marker, true)
				D.pulsate(currentline.marker)
				if gui.get_position(currentline.innerbox).y < -(gui.get_size(bgNode).y-20) then
					local carrierpos = gui.get_position(carrier)
					carrierpos.y = carrierpos.y + 20
					gui.set_position(carrier, carrierpos)
				end
				local dragPos = gui.get_position(dragpos)
				local posDelta = -gui.get_position(carrier).y / (gui.get_size(carrier).y - gui.get_size(bgNode).y)
				dragPos.y = D.valuelimit(gui.get_size(bgNode).y * posDelta, -gui.get_size(bgNode).y+15, -5)
				gui.set_position(dragpos, dragPos)
			elseif utf8.len(gui.get_text(currentline.hidden)) == utf8.len(gui.get_text(currentline.text)) and self.textboxData[node].activeline <= #self.textboxData[node].lines then -- If marker at end there is nothing to delete
				gui.set_enabled(currentline.marker, false)
				D.stop_pulsate(currentline.marker)
				self.textboxData[node].linecount = self.textboxData[node].linecount + 1
				self.textboxData[node].activeline = self.textboxData[node].activeline + 1
				table.insert(self.textboxData[node].lines, self.textboxData[node].activeline, addLine(node, self.textboxData[node].linecount))
				currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
				gui.set_text(currentline.hidden, "")
				gui.set_text(currentline.text, "")
				sortLines(node, self.textboxData[node].lines)
				local markerPos = gui.get_position(currentline.marker)
				markerPos.x = 0
				gui.set_enabled(currentline.marker, true)
				gui.set_position(currentline.marker, markerPos)
				D.pulsate(currentline.marker)

				if gui.get_position(currentline.innerbox).y < -(gui.get_size(bgNode).y-20)  then
					local carrierpos = gui.get_position(carrier)
					carrierpos.y = carrierpos.y + 20
					gui.set_position(carrier, carrierpos)
				end
				local dragPos = gui.get_position(dragpos)
				local posDelta = -gui.get_position(carrier).y / (gui.get_size(carrier).y - gui.get_size(bgNode).y)
				dragPos.y = D.valuelimit(gui.get_size(bgNode).y * posDelta, -gui.get_size(bgNode).y+15, -5)
				gui.set_position(dragpos, dragPos)
			end
		end

		local currentline = self.textboxData[node].lines[self.textboxData[node].activeline]
		if action_id == hash("text") and get_text_metrics_from_node(currentline.text).width < (gui.get_size(bgNode).x-25) then
			if utf8.len(gui.get_text(currentline.hidden)) < utf8.len(gui.get_text(currentline.text)) then -- Hidden is shorter add text for that point
				local hiddenlength = utf8.len(gui.get_text(currentline.hidden))
				self.textboxData[node].makerpos = gui.get_position(currentline.marker)
				local text = gui.get_text(currentline.hidden)
				text = text .. action.text
				gui.set_text(currentline.hidden, text)
				text = text .. utf8.sub(gui.get_text(currentline.text), hiddenlength+1, -1)
				gui.set_text(currentline.text, text)
				self.textboxData[node].makerpos.x = get_text_metrics_from_node(currentline.hidden).width
				gui.set_position(currentline.marker, self.textboxData[node].makerpos)
			elseif utf8.len(gui.get_text(currentline.hidden)) == utf8.len(gui.get_text(currentline.text)) then -- If equal add text at the end
				self.textboxData[node].makerpos = gui.get_position(currentline.marker)
				local text = gui.get_text(currentline.text)
				text = text .. action.text
				gui.set_text(currentline.hidden, text)
				gui.set_text(currentline.text, text)
				self.textboxData[node].makerpos.x = get_text_metrics_from_node(currentline.text).width
				gui.set_position(currentline.marker, self.textboxData[node].makerpos)
			end
		elseif action_id == hash("text") and get_text_metrics_from_node(currentline.text).width >= (gui.get_size(bgNode).x-25) then
			gui.set_enabled(currentline.marker, false)
			self.textboxData[node].linecount = self.textboxData[node].linecount + 1
			self.textboxData[node].activeline = self.textboxData[node].activeline + 1
			table.insert(self.textboxData[node].lines, self.textboxData[node].activeline, addLine(node, self.textboxData[node].activeline))
			gui.set_text(currentline.hidden, "")
			currentline = self.textboxData[node].lines[self.textboxData[node].activeline]

			gui.set_text(currentline.text, "")
			sortLines(node, self.textboxData[node].lines)
			self.textboxData[node].makerpos = gui.get_position(currentline.marker)
			self.textboxData[node].makerpos.x = 0
			gui.set_enabled(currentline.marker, true)
			gui.set_position(currentline.marker, self.textboxData[node].makerpos)
		end				
	end
	-- Gather return string
	local returnstring = ""
	if self.textboxData[node].lines ~= nil then
		for i = 1, #self.textboxData[node].lines do
			returnstring = returnstring .. gui.get_text(self.textboxData[node].lines[i].text) .. "\n"
		end
	end
	local prev = self.textboxData[node].lastText
	if prev == nil then prev = returnstring end -- no spurious change on first frame
	local changed = (returnstring ~= prev)
	self.textboxData[node].lastText = returnstring
	return returnstring, changed
end

-- OTHER
function M.clearTextbox(self, node)
	-- Clear textbox
	local textNode = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext")
	local markerNode = gui.get_node(node .. "/marker")
	self.textboxData = self.textboxData or {}
	self.textboxData[node] = self.textboxData[node] or {}
	self.textboxData[node].text     = ""
	self.textboxData[node].lastText = ""  -- prevent spurious changed on next frame
	gui.set_text(textNode, "")
	gui.set_text(hiddenText, "")
	-- Reset marker to the start position
	local markerPos = gui.get_position(markerNode)
	markerPos.x = 0
	gui.set_position(markerNode, markerPos)
end

function M.setTextbox(self, node, text)
	local textNode = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext") -- Hidden text for comparision
	local markerNode = gui.get_node(node .. "/marker")

	-- Check current value
	self.textboxData = self.textboxData or {}
	self.textboxData[node] = self.textboxData[node] or {}
	self.textboxData[node].text     = text
	self.textboxData[node].lastText = text  -- prevent spurious changed on next frame
	gui.set_text(textNode, text)
	gui.set_text(hiddenText, text)
	gui.set_enabled(markerNode, false)
end


function M.clearTextboxMultiline(self, node)
	local textNode   = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext")
	local markerNode = gui.get_node(node .. "/marker")
	local carrier    = gui.get_node(node .. "/carrier")
	local dragpos    = gui.get_node(node .. "/dragpos")

	self.textboxData       = self.textboxData or {}
	self.textboxData[node] = self.textboxData[node] or {}
	local data             = self.textboxData[node]

	-- Stop pulsate and delete all dynamic lines (index 2+)
	if data.lines then
		for i = #data.lines, 2, -1 do
			D.stop_pulsate(data.lines[i].marker)
			gui.set_enabled(data.lines[i].marker, false)
			deleteLine(node, data.lines[i].id)
		end
	end

	-- Reset template nodes
	gui.set_text(textNode, "")
	gui.set_text(hiddenText, "")
	D.stop_pulsate(markerNode)
	gui.set_enabled(markerNode, false)
	local markerPos = gui.get_position(markerNode)
	markerPos.x = 0
	gui.set_position(markerNode, markerPos)

	-- Reset carrier scroll position and hide scroll indicator
	gui.set_position(carrier, vmath.vector3(0, 0, 0))
	gui.set_visible(dragpos, false)

	-- Reset state (preserve sizeFix so sizes are not re-applied unnecessarily)
	data.lines      = {}
	data.linecount  = 0
	data.activeline = 0
	data.text       = ""
	data.lastText   = ""
	data.scroll     = {}

	-- Release focus if this node was active
	if D.nodes["active"] == node then
		D.nodes["active"] = nil
	end
end

function M.setTextboxMultiline(self, node, text)
	self.textboxData            = self.textboxData or {}
	self.textboxData[node]      = self.textboxData[node] or {}
	-- Bootstrap fields that sizeFix and addLine depend on
	self.textboxData[node].text      = self.textboxData[node].text or ""
	self.textboxData[node].linecount = self.textboxData[node].linecount or 0
	self.textboxData[node].activeline= self.textboxData[node].activeline or 0
	self.textboxData[node].lines     = self.textboxData[node].lines or {}
	self.textboxData[node].sizeFix   = self.textboxData[node].sizeFix or false
	self.textboxData[node].scroll    = self.textboxData[node].scroll or {}

	-- Clear any existing content first
	M.clearTextboxMultiline(self, node)

	-- Ensure node sizes are applied (no-op if already done)
	sizeFix(self, node)

	-- Grab template nodes (only the first line uses the bare template IDs)
	local textNode   = gui.get_node(node .. "/text")
	local hiddenText = gui.get_node(node .. "/hiddentext")
	local markerNode = gui.get_node(node .. "/marker")
	local innerbox   = gui.get_node(node .. "/innerbox")

	-- Split the text on newlines; always produce at least one entry
	local lineTexts = {}
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		table.insert(lineTexts, line)
	end
	if #lineTexts == 0 then lineTexts = {""} end

	local data = self.textboxData[node]

	-- Set up line 1 using the template nodes directly
	data.linecount  = 1
	data.activeline = 1
	gui.set_text(textNode, lineTexts[1])
	gui.set_text(hiddenText, lineTexts[1])
	data.lines[1] = {text = textNode, hidden = hiddenText, marker = markerNode, innerbox = innerbox, id = 1}

	-- Create additional lines via cloning
	for i = 2, #lineTexts do
		data.linecount = data.linecount + 1
		local newline = addLine(node, data.linecount)
		gui.set_text(newline.text, lineTexts[i])
		gui.set_text(newline.hidden, lineTexts[i])
		table.insert(data.lines, newline)
	end

	-- Reposition all lines and resize the carrier
	sortLines(node, data.lines)

	-- Persist the text value and prevent a spurious "changed" on the next frame
	local fullText    = table.concat(lineTexts, "\n")
	data.text         = fullText
	data.lastText     = fullText
end

-- Efficiently append a single line of text to a multiline textbox.
-- Unlike setTextboxMultiline, this does not clear existing content first.
-- The widget must have been used (or sizeFix called) at least once before calling this.
function M.appendLineTextboxMultiline(self, node, text)
	self.textboxData            = self.textboxData or {}
	self.textboxData[node]      = self.textboxData[node] or {}
	local data                  = self.textboxData[node]
	data.lines                  = data.lines or {}
	data.linecount              = data.linecount or 0
	data.sizeFix                = data.sizeFix or false
	data.scroll                 = data.scroll or {}

	-- Ensure sizes have been applied
	sizeFix(self, node)

	if #data.lines == 0 then
		-- No lines yet — set up line 1 from the template nodes
		local textNode   = gui.get_node(node .. "/text")
		local hiddenText = gui.get_node(node .. "/hiddentext")
		local markerNode = gui.get_node(node .. "/marker")
		local innerbox   = gui.get_node(node .. "/innerbox")
		data.linecount  = 1
		data.activeline = 1
		gui.set_text(textNode, text)
		gui.set_text(hiddenText, text)
		data.lines[1] = {text = textNode, hidden = hiddenText, marker = markerNode, innerbox = innerbox, id = 1}
	else
		-- Clone a new line after the last existing one
		data.linecount = data.linecount + 1
		local newline  = addLine(node, data.linecount)
		gui.set_text(newline.text,   text)
		gui.set_text(newline.hidden, text)
		table.insert(data.lines, newline)
	end

	sortLines(node, data.lines)

	-- Rebuild return string and prevent a spurious 'changed' on the next frame
	local parts = {}
	for i = 1, #data.lines do
		parts[i] = gui.get_text(data.lines[i].text)
	end
	local fullText  = table.concat(parts, "\n") .. "\n"
	data.lastText   = fullText
end

return M