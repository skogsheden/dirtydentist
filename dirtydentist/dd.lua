-- Dirty Dentist GUI
-- GUI basepack developed for use in educational software
-- Includs buttons, dropdowns, comboboxes, toggles, radiobuttons and textfields/boxes with editing
-- The GUI-package aims to provide basic functionalty for PCs, MACs and Web. Mobile is currently not supported.

-- Package requires defold-utf8, https://github.com/d954mas/defold-utf8, to be included in the project. 
-- If used with only english all utf8 can be repalced with string and not require any other package. 

local dd = {} -- list for storeing data
local scrollspeeed = 18 -- scrollspeed in dropddowns and comboboxes
local cb_textmag = 0.75 -- textmagninfication

-- Color data, adjusted to suit preferences
local colors = {}
colors.active = vmath.vector4(0.95,0.95,0.95,1)
colors.hover = vmath.vector4(0.85,0.85,0.85,1)
colors.select = vmath.vector4(0.75,0.75,0.75,1)
colors.inactive = vmath.vector4(0.3,0.3,0.3,0.3)
colors.green = vmath.vector4(0.1,1,0.1,1)
colors.red = vmath.vector4(1,0.1,0.1,1)

-- Strings for feedback and easy localisation
local noentries = "No entries found"
local selectavalue = "Select a value"

function localisationofstrings(nonfound, select)
	noentries = nonfound
	selectavalue = select
end

-- Check if node is the active Node
local function isActive(node)
	if dd.activeNode == node then
		return true
	else
		return false
	end
end

-- Function that limits input values
local function valuelimit(v, min, max)
	if v < min then
		return min
	elseif v > max then
		return max
	end
	return v
end

-- Radiobuttons takes action, which groups the current button belongs to, current node and if it should be enabled
function radio(self, action_id, action, group, nodes, enabled)
	-- if more then one radiobutton
	if enabled and dd.activeNode == nil then
		local radios = {}
		if #nodes > 1 then
			for k in pairs(nodes) do
				radios[k] = gui.get_node(nodes[k] .. "/bg")
			end
			for k in pairs(radios) do
				if gui.pick_node(radios[k], action.x, action.y) then
					gui.set_color(radios[k], colors.hover)
					if action_id == hash("touch") and action.pressed and dd["radio" .. group] ~= k then
						if dd["radio" .. group] ~= nil then
							gui.play_flipbook(radios[dd["radio" .. group]], "radio")
							dd["radio" .. group] = nil
						end
						dd["radio" .. group] = k
						gui.play_flipbook(radios[k], "radio_selected")
					elseif action_id == hash("touch") and action.pressed and dd["radio" .. group] == k then
						gui.play_flipbook(radios[k], "radio")
						dd["radio" .. group] = nil
					end
				else
					gui.set_color(radios[k], colors.active)
				end
			end
			return dd["radio" .. group]
		else
			print("not enough radios")
			return nil
		end
	elseif enabled == false then
		local radios = {}
		if #nodes > 1 then
			for k in pairs(nodes) do
				radios[k] = gui.get_node(nodes[k] .. "/bg")
				gui.set_color(radios[k], colors.inactive)
			end
			return nil
		else
			print("not enough radios")
		end
		return nil
	end
end

-- Checkboxes takes action, current node and if it should be enabled
function checkbox(self, action_id, action, node, enabled)
	-- Check if can be activated
	local bgNode = gui.get_node(node .. "/bg")

	local selected  = node .. "selected"
	if dd[selected] == nil then
		dd[selected] = false
	end
	
	if dd.activeNode == nil and gui.pick_node(bgNode, action.x, action.y) and enabled then
		dd.activeNode = node
	elseif enabled == false then
		gui.set_color(bgNode, colors.inactive)
	end
	
	if dd.activeNode == node then 
		if gui.pick_node(bgNode, action.x, action.y) then
			gui.set_color(bgNode, colors.hover)
			if action_id == hash("touch") and action.pressed and dd[selected] then
				dd[selected] = false
				gui.play_flipbook(bgNode, "bg_checkbox")
			elseif action_id == hash("touch") and action.pressed and dd[selected] == false then
				dd[selected] = true
				gui.play_flipbook(bgNode, "check")
			end
		else
			dd.activeNode = nil
			gui.set_color(bgNode, colors.active)
		end
		dd.activeNode = nil
	end
	--return value
	return dd[selected]
end

function button_enabled(self, node, enabled)
	local bgNode = gui.get_node(node .. "/bg")
	if enabled and dd.activeNode == nil then
		gui.set_color(bgNode, colors.active)
	end
	if not enabled then
		gui.set_color(bgNode, colors.inactive)
	end
end

-- Normal buttons takes action, current node and if it should be enabled
function button_touch(self, action_id, action, node, enabled)
	-- Check if can be activated
	local bgNode = gui.get_node(node .. "/bg")
	if dd.activeNode == nil and gui.pick_node(bgNode, action.x, action.y) and enabled then
		dd.activeNode = node
	end
	
	-- if node active
	if dd.activeNode == node then 
		gui.set_color(bgNode, colors.hover)
		local textNode = gui.get_node(node .. "/text")
		if gui.pick_node(bgNode, action.x, action.y) then
			if action_id == hash("touch") and action.pressed then
				-- return true if pressed
				returnvalue = true
				gui.set_color(bgNode, colors.active)
			else
				-- else return false
				returnvalue = false
			end
		end
		dd.activeNode = nil
		return returnvalue
	elseif enabled then
		gui.set_color(bgNode, colors.active)
	else
		gui.set_color(bgNode, colors.inactive)
	end
end

-- Textinput takes actions, node and if it is enabled
function text_input(self, action_id, action, node, enabled)	
	-- Check if can be activated
	local bgNode = gui.get_node(node .. "/bg")
	local textNode = gui.get_node(node .. "/text")
	
	if dd.activeNode == nil and gui.pick_node(bgNode, action.x, action.y) and enabled then
		dd.activeNode = node -- Active node if touched and no other is active
	elseif not enabled then
		gui.set_color(bgNode, colors.inactive) -- Set color to inactive
	end
	-- Recieve input
	if dd.activeNode == node then
		-- Get the other subnodes
		local hiddenText = gui.get_node(node .. "/hiddentext") -- Hidden text for comparision
		local markerNode = gui.get_node(node .. "/marker")

		-- If button pressed on textbox
		if action_id == hash("touch") and action.pressed and gui.pick_node(bgNode, action.x, action.y) then
			dd[node .. "isActive"] = true -- Activate text input
			gui.set_enabled(markerNode, true) -- Enable marker
			gui.set_color(bgNode, colors.hover) -- Set color to hover
			gui.set_screen_position(markerNode, vmath.vector3(action.x,action.y,0)) -- Set marker at click position
			markpos = gui.get_position(markerNode) -- Convert to local pos
			markpos.y=0 -- Set y position to 0 to keep in middle of box
			gui.set_position(markerNode, markpos) -- Update
			gui.set_text(hiddenText, gui.get_text(textNode))
			if utf8.len(gui.get_text(hiddenText)) >= 2 then -- If two or more letters allow editing
				while gui.get_text_metrics_from_node(hiddenText).width > markpos.x do -- Adjust hidden string to fit hiddenstring
					local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
					gui.set_text(hiddenText, shortenstring)
					if utf8.len(shortenstring) <= 2 then
						break
					end
				end
			end
			markpos.x = gui.get_text_metrics_from_node(hiddenText).width -- Update marker to be at the end the hiddenstring
			gui.set_position(markerNode, markpos)
		elseif action_id == hash("touch") and action.pressed and not gui.pick_node(bgNode, action.x, action.y) then -- If pressed outside of text box deactivate
			dd[node .. "isActive"] = false
			gui.set_enabled(markerNode, false)
			gui.set_color(bgNode, colors.active)
			dd.activeNode = nil
		end
		
		if action_id == hash("text") and dd[node .. "isActive"] and gui.get_text_metrics_from_node(textNode).width < (gui.get_size(bgNode).x-25) then
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then -- Hidden is shorter add text for that point
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = text .. action.text
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(textNode), hiddenlength+1, -1)
				gui.set_text(textNode, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(textNode)) then -- If equal add text at the end
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = text .. action.text
				gui.set_text(hiddenText, text)
				gui.set_text(textNode, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width
				gui.set_position(markerNode, markerPos)
			end
		end
		if action_id == hash("backspace") and action.repeated and dd[node .. "isActive"] then -- Remove letters
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then -- If hidden is shorter remove text from that point
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = utf8.sub(text, 1, -2)
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(textNode), hiddenlength+1, -1)
				gui.set_text(textNode, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(textNode)) then -- If equal remove from the end
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = utf8.sub(text, 1, -2)
				gui.set_text(hiddenText, text)
				gui.set_text(textNode, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width
				gui.set_position(markerNode, markerPos)
			end
		end
		if action_id == hash("delete") and action.repeated and dd[node .. "isActive"] then -- Same as above but delete
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(textNode)) then
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(textNode), hiddenlength+2, -1)
				gui.set_text(textNode, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(textNode)) then -- If marker at end there is nothing to delete
				print("nothing to delete")
			end
		end
	end
	return gui.get_text(textNode)
end

-- Dropdown and combobox initiater
function dropdown_init(self, node, list, openUpwards, set_value, enabled, id)
	-- get nodes
	local textbox = gui.get_node(node .. "/textbox")
	local mask = gui.get_node(node .. "/mask")
	local dd_obj = gui.get_node(node .. "/dddrag")
	local id_obj = gui.get_node(node .. "/ID")
	-- and variables
	local selectedValue = node .. "selectedValue"
	local isOpen = node .. "isOpen"
	local scrolling = node .. "scrolling"
	local mask = gui.get_node(node .. "/mask")
	local selected_text = gui.get_node(node .. "/selecttext")

	-- If no input for standard value is given set to default string 
	if set_value == nil or set_value == "" then
		dd[selectedValue] = selectavalue
	else
		dd[selectedValue] = set_value
	end
	gui.set_text(selected_text, dd[selectedValue])
	dd[isOpen] = false -- start as closed
	dd[scrolling] = false -- Not scrolling

	-- choose side to which way to isOpen
	if openUpwards then
		local pos = gui.get_position(mask)
		pos.y = pos.y + 230
		gui.set_position(mask, pos)
	end

	-- If enabled set color of the dropbox
	if enabled then
		gui.set_color(textbox, colors.active)
	else
		gui.set_color(textbox, colors.inactive)
	end
	gui.set_enabled(mask, false)

	-- If id avilable set id_obj
	if gui.get_text(id_obj) ~= nil then
		gui.set_text(id_obj, id)
	end
end

-- Local function to delete all objects in the dropdown objects
local function dropdown_del(self, node)
	local count = node .. "count"
	local dd_obj = gui.get_node(node .. "/dddrag")

	if dd[count] >= 1 then 
		for i=1, dd[count] do
			gui.delete_node(gui.get_node(node .. "/button" .. i))
			gui.delete_node(gui.get_node(node .. "/text" .. i))
		end
		gui.set_position(dd_obj, vmath.vector3(0,0,0))
	end
end

-- Local function to create all objects in the dropdown objects
local function dropdown_crt(self, node, list)
	-- setup nodes 	
	local orginalnode = gui.get_node(node .. "/button")
	local orginaltext = gui.get_node(node .. "/text")
	local mask = gui.get_node(node .. "/mask")
	local dd_obj = gui.get_node(node .. "/dddrag")
	-- and variables
	local size = node .. "size"
	local count = node .. "count"
	local selectedValue = node .. "selectedValue"

	--Reset color of node
	gui.set_color(orginalnode, colors.active)
	
	-- assign templet button first value or error message
	if #list == 0 then 
		gui.set_text(gui.get_node(node .. "/text"), noentries)
	else
		-- Get values from list
		dd[size] = #list * 30
		dd[count] = #list - 1 -- onenode is allready created

		-- Set size of dragbox
		local currentsize = gui.get_size(dd_obj)
		currentsize.y = dd[size]
		gui.set_size(dd_obj, currentsize)
		gui.set_position(dd_obj, vmath.vector3(0,0,0))
		
		if list[1] == dd[selectedValue] then
			gui.set_text(gui.get_node(node .. "/text"), list[1])
			gui.set_color(orginalnode, colors.select)
			gui.set_position(dd_obj, vmath.vector3(0,0,0))
		else
			gui.set_text(gui.get_node(node .. "/text"), list[1])
			gui.set_color(orginalnode, colors.active)
		end
		
		-- fill up list
		if #list > 1 then
			for k in pairs (list) do
				-- create new node
				if k+1 <= #list then
					local newnode = gui.clone(orginalnode)
					local newtext = gui.clone(orginaltext)

					-- assagin to correct template
					gui.set_parent(newtext, newnode)
					gui.set_parent(newnode, dd_obj)		
					gui.set_id(newnode, node .. "/button" .. k)
					gui.set_id(newtext, node .. "/text" .. k)

					--set text value, position and check if selected 
					if list[k+1] == dd[selectedValue] then
						gui.set_text(newtext, list[k+1])
						gui.set_color(newnode, colors.select)
						if #list > 7 then
							gui.set_position(dd_obj, vmath.vector3(0,valuelimit((k*30),0,(dd[size]-200)),0))
						end
					else
						gui.set_text(newtext, list[k+1])
						gui.set_color(newnode, colors.active)
					end
					gui.set_position(newnode, vmath.vector3(0,-30*k,0))
				end
			end
		end	
	end
end

-- Function to interact with dropdown
function dropdown_interact(self, action_id, action, node, list, enabled)
	-- check if dropdown is interatcted with
	local textbox = gui.get_node(node .. "/textbox")

	if gui.pick_node(textbox, action.x, action.y) and dd.activeNode == nil and action_id == hash("touch") and action.pressed and enabled then
		dd.activeNode = node
	elseif enabled and gui.get_color(textbox) ~= colors.active then
		gui.set_color(textbox, colors.active)
	elseif enabled == false then
		gui.set_color(textbox, colors.inactive)
	end
	
	-- get selected value for return
	local selectedValue = node .. "selectedValue"	
	
	-- if dropdown is active handle interactions
	if isActive(node) then
		-- Get variables in table
		local isOpen = node .. "isOpen"
		local size = node .. "size"
		local count = node .. "count"
		local init = node .. "init"
		local prevPos = node .. "prevPos"
		

		-- get nodes to use
		local selected_text = gui.get_node(node .. "/selecttext")
		local dd_obj = gui.get_node(node .. "/dddrag")
		local mask = gui.get_node(node .. "/mask")
		local dragpos = gui.get_node(node .. "/dragpos")
		local safearea = gui.get_node(node .. "/safearea")
		
		-- if boxes not created
		if dd[init] ~= true then
			dropdown_crt(self, node, list)
			dd[init] = true
		end

		-- Add buttons to list
		local listOfButton = {"/button"}
		local listOfText = {"/text"}
		for i = 1 , dd[count], 1 do 
			listOfButton[i+1] = "/button" .. i
			listOfText[i+1] = "/text" .. i
		end	

		-- If left active area close dropdown
		if gui.pick_node(gui.get_node(dd.activeNode .. "/safearea"), action.x, action.y) == false and gui.pick_node(gui.get_node(dd.activeNode .. "/dddrag"), action.x, action.y) == false and gui.pick_node(gui.get_node(dd.activeNode .. "/textbox"), action.x, action.y) == false then
			gui.set_enabled(mask, false) 
			gui.set_text(selected_text, dd[selectedValue])
			dd[isOpen] = false
			dropdown_del(self, node)
			dd[init] = false
			dd.activeNode = nil
		end
		
		-- Open and close
		if action_id == hash("touch") and action.pressed then
			if gui.pick_node(textbox, action.x, action.y) and not dd[isOpen] then
				gui.set_enabled(mask, true)
				gui.set_text(selected_text, selectavalue)
				dd[isOpen] = true
			elseif gui.pick_node(textbox, action.x, action.y) and dd[isOpen] then
				gui.set_enabled(mask, false)
				gui.set_text(selected_text, dd[selectedValue])
				dropdown_del(self, node)
				dd[init] = false
				dd[isOpen] = false
				dd.activeNode = nil
			end
		end

		-- Scrolling is enabeled when more than 7 items in dropdown
		if dd[count] < 7 then
			gui.set_enabled(dragpos, false)
		elseif dd[count] > 7 then
			gui.set_enabled(dragpos, true)
			-- Scrollwheel
			if dd[isOpen] and action_id == hash("wheelup") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = valuelimit((currentPos.y - scrollspeeed),0,dd[size]-200)
				gui.set_position(dd_obj, currentPos)
			elseif dd[isOpen] and action_id == hash("wheeldown") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = valuelimit((currentPos.y + scrollspeeed),0,dd[size]-200)
				gui.set_position(dd_obj, currentPos)
			end

			-- move indicator
			local currentPos = gui.get_position(dd_obj)
			local amountcomplete = currentPos.y / (dd[size]-200)
			local dragposCurrent = gui.get_position(dragpos)
			dragposCurrent.y = -190 * amountcomplete
			gui.set_position(dragpos, dragposCurrent)
		end
		
		-- Check if value pressed
		if gui.pick_node(mask, action.x, action.y) then
			for k in pairs (listOfButton) do
				if action_id == hash("touch") and action.pressed and dd[isOpen] and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) then
					if gui.get_text(gui.get_node(node .. listOfText[k])) ~= noentries then
						dd[selectedValue] = gui.get_text(gui.get_node(node .. listOfText[k]))
						gui.set_text(selected_text, dd[selectedValue])
						gui.set_color(gui.get_node(node .. listOfButton[k]), colors.select)
					end
				elseif dd[isOpen] and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) and dd[selectedValue] ~= gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), colors.hover)
				elseif dd[selectedValue] ~= gui.get_text(gui.get_node(node .. listOfText[k])) and dd[isOpen] then
					gui.set_color(gui.get_node(node .. listOfButton[k]), colors.active)
				end
			end	
		end
	end
	return dd[selectedValue]
end

-- Interaction with combobox
function combobox_interact(self, action_id, action, node, list, enabled)
	-- check if combobox is interatcted with
	local textbox = gui.get_node(node .. "/textbox")
	if gui.pick_node(textbox, action.x, action.y) and dd.activeNode == nil and action_id == hash("touch") and action.pressed and enabled then
		dd.activeNode = node
	elseif gui.pick_node(textbox, action.x, action.y) and dd.activeNode == nil and enabled then
		gui.set_color(textbox, colors.hover)
	elseif enabled and (gui.get_color(textbox) ~= colors.active or gui.get_color(textbox) ~= colors.hover) then
		gui.set_color(textbox, colors.active)
	elseif enabled == false then
		gui.set_color(textbox, colors.inactive)
	end

	-- get selected value for return
	local selectedValue = node .. "selectedValue"	
	
	if isActive(node) then
		-- Values in table
		local isOpen = node .. "isOpen"
		local inputActive = node .. "inputActive"
		local scrolling = node .. "scrolling"
		local prevPos = node .. "prevPos"
		local size = node .. "size"
		local count = node .. "count"
		local init = node .. "init"
		
		-- get nodes to use
		local drop_button = gui.get_node(node .. "/drop_button")
		local selected_text = gui.get_node(node .. "/selecttext")
		local dd_obj = gui.get_node(node .. "/dddrag")
		local mask = gui.get_node(node .. "/mask")
		local dragpos = gui.get_node(node .. "/dragpos")
		local markerNode = gui.get_node(node .. "/marker")
		local hiddenText = gui.get_node(node .. "/hiddentext")
		local safearea = gui.get_node(node .. "/safearea")

		-- List to store matching values
		local foundInList = {}

		-- if boxes not created
		if dd[init] ~= true then
			dropdown_crt(self, node, list)
			dd[init] = true
		end
		
		-- If left active area close dropdown
		if gui.pick_node(gui.get_node(dd.activeNode .. "/safearea"), action.x, action.y) == false and gui.pick_node(gui.get_node(dd.activeNode .. "/dddrag"), action.x, action.y) == false and gui.pick_node(gui.get_node(dd.activeNode .. "/textbox"), action.x, action.y) == false then
			gui.set_enabled(mask, false) 
			gui.set_text(selected_text, dd[selectedValue])
			dd[isOpen] = false
			dropdown_del(self, node)
			dd[init] = false
			dd.activeNode = nil
			dd[inputActive] = false
			gui.set_enabled(markerNode, false)
			gui.set_color(textbox, colors.active)
		end

		-- active textinput
		if action_id == hash("touch") and action.pressed and gui.pick_node(selected_text, action.x, action.y) then
			dd[inputActive] = true
			gui.set_enabled(markerNode, true)
			gui.set_color(textbox, colors.hover)
			if gui.get_text(selected_text) == selectavalue then
				gui.set_text(selected_text, "")
				gui.set_text(hiddenText,"")
			end
			gui.set_text(hiddenText, gui.get_text(selected_text))
			
			-- Set marker
			gui.set_screen_position(markerNode, vmath.vector3(action.x,action.y,0)) 
			local markpos = gui.get_position(markerNode)
			markpos.y = 0 

			while gui.get_text_metrics_from_node(hiddenText).width * cb_textmag - 90 > markpos.x do -- Adjust hidden string to fit hiddenstring
				local shortenstring = utf8.sub(gui.get_text(hiddenText), 1, -2)
				gui.set_text(hiddenText, shortenstring)
				if utf8.len(shortenstring) <= 1 then
					break
				end
			end
			markpos.x = gui.get_text_metrics_from_node(hiddenText).width * cb_textmag - 90 -- Update marker to be at the end the hiddenstring
			gui.set_position(markerNode, markpos)
		-- if clicked outside of textbox --> stop input
		elseif action_id == hash("touch") and action.pressed then
			dd[inputActive] = false
			gui.set_color(textbox, colors.active)
			gui.set_enabled(markerNode, false)
		end

		-- handle input of text
		if action_id == hash("text") and dd[inputActive] then	
			dropdown_del(self, node)
			
			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(selected_text)) then -- Hidden is shorter add text for that point
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = text .. action.text
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(selected_text), hiddenlength + 1, -1)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*cb_textmag - 90
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(selected_text)) then -- If equal add text at the end
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(selected_text)
				text = text .. action.text
				gui.set_text(hiddenText, text)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(selected_text).width*cb_textmag - 90
				gui.set_position(markerNode, markerPos)
			end
			
			-- clear check if input is in list and store matching ids in foundInList
			for i = 0, #foundInList do foundInList[i] = nil end
			for k in pairs(list) do
				if utf8.find(utf8.lower(list[k]),utf8.lower(gui.get_text(selected_text))) ~= nil then
					foundInList[#foundInList+1] = list[k]
				end
			end	
			dd[selectedValue] = gui.get_text(selected_text)
			dd[count] = #foundInList
			dropdown_crt(self, node, foundInList)

			gui.set_position(dd_obj, vmath.vector3(0,0,0))
			gui.set_enabled(mask, true)
			dd[isOpen] = true
		end
	
		if action_id == hash("backspace") and action.repeated then
			dropdown_del(self, node)

			if utf8.len(gui.get_text(hiddenText)) < utf8.len(gui.get_text(selected_text)) then -- If hidden is shorter remove text from that point
				local hiddenlength = utf8.len(gui.get_text(hiddenText))
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = utf8.sub(text, 1, -2)
				gui.set_text(hiddenText, text)
				text = text .. utf8.sub(gui.get_text(selected_text), hiddenlength+1, -1)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*cb_textmag - 90
				gui.set_position(markerNode, markerPos)
			elseif utf8.len(gui.get_text(hiddenText)) == utf8.len(gui.get_text(selected_text)) then -- If equal remove from the end
				local markerPos = gui.get_position(markerNode)
				local text = gui.get_text(hiddenText)
				text = utf8.sub(text, 1, -2)
				gui.set_text(hiddenText, text)
				gui.set_text(selected_text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width*cb_textmag - 90
				gui.set_position(markerNode, markerPos)
			end

			for i=0, #foundInList do foundInList[i]=nil end
			for k in pairs(list) do
				if utf8.find(utf8.lower(list[k]),utf8.lower(gui.get_text(selected_text))) ~= nil then
					foundInList[#foundInList+1] = list[k]
				end
			end	
			
			dd[count] = #foundInList
			dropdown_crt(self, node, foundInList)
			gui.set_position(dd_obj, vmath.vector3(0,0,0))
			dd[selectedValue] = gui.get_text(selected_text)
			gui.set_enabled(mask, true)
			dd[isOpen] = true
		end

		if dd[count] < 7 then
			gui.set_enabled(dragpos, false)
		elseif dd[count] > 7 then
			gui.set_enabled(dragpos, true)
			-- Scrollwheel
			if dd[isOpen] and action_id == hash("wheelup") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = valuelimit((currentPos.y - scrollspeeed),0,dd[size]-200)
				gui.set_position(dd_obj, currentPos)
			elseif dd[isOpen] and action_id == hash("wheeldown") and gui.pick_node(dd_obj, action.x, action.y) then
				local currentPos = gui.get_position(dd_obj)
				currentPos.y = valuelimit((currentPos.y + scrollspeeed),0,dd[size]-200)
				gui.set_position(dd_obj, currentPos)
			end

			-- move indicator
			local currentPos = gui.get_position(dd_obj)
			local amountcomplete = currentPos.y / (dd[size]-200)
			local dragposCurrent = gui.get_position(dragpos)
			dragposCurrent.y = -190 * amountcomplete
			gui.set_position(dragpos, dragposCurrent)
		end

		-- Add buttons to list
		local listOfButton = {"/button"}
		local listOfText = {"/text"}
		for i = 1 , dd[count], 1 do 
			listOfButton[i+1] = "/button" .. i
			listOfText[i+1] = "/text" .. i
		end	
		
		-- Check if value pressed
		if gui.pick_node(mask, action.x, action.y) then
			for k in pairs (listOfButton) do
				if action_id == hash("touch") and action.pressed and dd[isOpen] and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) then
					if gui.get_text(gui.get_node(node .. listOfText[k])) ~= noentries then
						dd[selectedValue] = gui.get_text(gui.get_node(node .. listOfText[k]))
						gui.set_text(selected_text, dd[selectedValue])
						gui.set_color(gui.get_node(node .. listOfButton[k]), colors.select)
					end
				elseif dd[isOpen] and gui.pick_node(gui.get_node(node .. listOfButton[k]), action.x, action.y) and dd[selectedValue] ~= gui.get_text(gui.get_node(node .. listOfText[k])) then
					gui.set_color(gui.get_node(node .. listOfButton[k]), colors.hover)
				elseif dd[selectedValue] ~= gui.get_text(gui.get_node(node .. listOfText[k])) and dd[isOpen] then
					gui.set_color(gui.get_node(node .. listOfButton[k]), colors.active)
				end
			end	
		end

		--Dropdown
		if action_id == hash("touch") and action.pressed and gui.pick_node(drop_button, action.x, action.y)then
			-- Open and close
			if not dd[isOpen] then
				gui.set_enabled(mask, true)
				dd[isOpen] = true
			elseif dd[isOpen] then
				gui.set_enabled(mask, false)
				gui.set_text(selected_text, dd[selectedValue])
				dd[isOpen] = false
				dropdown_del(self, node)
				dd[init] = false
				dd.activeNode = nil
			end
		end
	end
	return dd[selectedValue]
end

-- Multiline inputbox
function textbox_input(self, action_id, action, node, enabled)	
	-- Check if can be activated
	local bgNode = gui.get_node(node .. "/bg")
	if dd.activeNode == nil and gui.pick_node(bgNode, action.x, action.y) and enabled then
		dd.activeNode = node
	elseif not enabled then
		gui.set_color(bgNode, colors.inactive)
	end
	local lines = node .. "lines"
	
	-- Recieve input
	if dd.activeNode == node then
		local textNode = gui.get_node(node .. "/text")
		local hiddenText = gui.get_node(node .. "/hiddentext")
		local markerNode = gui.get_node(node .. "/marker")
		local innerbox = gui.get_node(node .. "/innerbox")
		local carrier = gui.get_node(node .. "/carrier")
		local linescount = node .. "count"
		local active = node .. "activeline"
		local input = node .. "input"

		 -- Store all created lines
		
		if  dd[lines] == nil or #dd[lines] == 0 then
			dd[lines] = {}
			dd[lines][1] = {text = textNode, hidden = hiddenText, marker = markerNode, innerbox = innerbox, id = 1}
			dd[active] = 1
			dd[linescount] = 1
		end

		--Scrolling
		if action_id == hash("wheelup") and gui.pick_node(bgNode, action.x, action.y) then
			for i = 1, #dd[lines] do
				local currentPos = gui.get_position(carrier)
				currentPos.y =  valuelimit(currentPos.y - scrollspeeed/5, 0, gui.get_size(carrier).y-gui.get_size(bgNode).y)
				gui.set_position(carrier, currentPos)
			end
		elseif action_id == hash("wheeldown") and gui.pick_node(bgNode, action.x, action.y) then
			for i = 1, #dd[lines] do
				local currentPos = gui.get_position(carrier)
				
				currentPos.y = valuelimit(currentPos.y + scrollspeeed/5, 0, gui.get_size(carrier).y-gui.get_size(bgNode).y)
				gui.set_position(carrier, currentPos)
			end
		end

		for i = 1, #dd[lines] do -- Loop through all lines and check which one is active
			if action_id == hash("touch") and action.pressed and gui.pick_node(dd[lines][i].innerbox, action.x, action.y) then
				gui.set_enabled(dd[lines][dd[active]].marker, false)
				gui.set_color(bgNode, colors.hover) -- Set BG color to hover
				dd[active] = i -- Set active to current
				
				dd[input] = true -- Recive text input
				gui.set_enabled(dd[lines][i].marker, true) -- Enable marker
				gui.set_screen_position(dd[lines][i].marker, vmath.vector3(action.x,action.y,0)) -- Set marker at click position
				markpos = gui.get_position(dd[lines][i].marker) -- Convert to local pos
				markpos.y = -10 -- Set y position to 0 to keep in middle of box
				gui.set_position(dd[lines][i].marker, markpos) -- Update
				gui.set_text(dd[lines][i].hidden, gui.get_text(dd[lines][i].text))
				if utf8.len(gui.get_text(dd[lines][i].hidden)) >= 1 then -- If two or more letters allow editing
					while gui.get_text_metrics_from_node(dd[lines][i].hidden).width > markpos.x do -- Adjust hidden string to fit hiddenstring
						local shortenstring = utf8.sub(gui.get_text(dd[lines][i].hidden), 1, -2)
						gui.set_text(dd[lines][i].hidden, shortenstring)
						if utf8.len(shortenstring) <= 1 then
							break
						end
					end
				end
				markpos.x = gui.get_text_metrics_from_node(dd[lines][i].hidden).width -- Update marker to be at the end the hiddenstring
				gui.set_position(dd[lines][i].marker, markpos)
			elseif action_id == hash("touch") and action.pressed and not gui.pick_node(bgNode, action.x, action.y) then -- If pressed outside of text box deactivate
				gui.set_color(bgNode, colors.active)
				dd[input] = false
				gui.set_enabled(dd[lines][i].marker, false)
				dd.activeNode = nil
			end
		end
	
		if action_id == hash("text") and dd[input] and gui.get_text_metrics_from_node(dd[lines][dd[active]].text).width < (gui.get_size(bgNode).x-25) then
			if utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) < utf8.len(gui.get_text(dd[lines][dd[active]].text)) then -- Hidden is shorter add text for that point
				local hiddenlength = utf8.len(gui.get_text(dd[lines][dd[active]].hidden))
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				local text = gui.get_text(dd[lines][dd[active]].hidden)
				text = text .. action.text
				gui.set_text(dd[lines][dd[active]].hidden, text)
				text = text .. utf8.sub(gui.get_text(dd[lines][dd[active]].text), hiddenlength+1, -1)
				gui.set_text(dd[lines][dd[active]].text, text)
				markerPos.x = gui.get_text_metrics_from_node(dd[lines][dd[active]].hidden).width
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
			elseif utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) == utf8.len(gui.get_text(dd[lines][dd[active]].text)) then -- If equal add text at the end
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				local text = gui.get_text(dd[lines][dd[active]].text)
				text = text .. action.text
				gui.set_text(dd[lines][dd[active]].hidden, text)
				gui.set_text(dd[lines][dd[active]].text, text)
				markerPos.x = gui.get_text_metrics_from_node(dd[lines][dd[active]].text).width
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
			end
		elseif action_id == hash("text") and dd[input] and gui.get_text_metrics_from_node(dd[lines][dd[active]].text).width >= (gui.get_size(bgNode).x-25) then
			gui.set_enabled(dd[lines][dd[active]].marker, false)
			dd[linescount] = dd[linescount] + 1
			dd[active] = dd[active] + 1
			table.insert(dd[lines], dd[active], addline(node, dd[linescount]))
			gui.set_text(dd[lines][dd[active]].hidden, "")
			gui.set_text(dd[lines][dd[active]].text, "")
			sortlines(node, dd[lines])
			local markerPos = gui.get_position(dd[lines][dd[active]].marker)
			markerPos.x = 0
			gui.set_enabled(dd[lines][dd[active]].marker, true)
			gui.set_position(dd[lines][dd[active]].marker, markerPos)
		end
		if action_id == hash("backspace") and action.repeated and dd[input] then -- Remove one letter
			if utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) == 0 and dd[active] > 1 then -- If higher then first line
				local text = gui.get_text(dd[lines][dd[active]].text)
				local rowabove = gui.get_text(dd[lines][dd[active] - 1].text)
				text = rowabove .. text
				gui.set_text(dd[lines][dd[active] - 1].text, text)
				deleteLine(node, dd[lines][dd[active]].id)
				table.remove(dd[lines], dd[active])
				dd[active] = dd[active] - 1
				sortlines (node, dd[lines])
				gui.set_text(dd[lines][dd[active]].hidden, rowabove)
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				markerPos.x = gui.get_text_metrics_from_node(dd[lines][dd[active]].hidden).width
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
				gui.set_enabled(dd[lines][dd[active]].marker, true)

				if gui.get_screen_position(dd[lines][dd[active]].innerbox).y > gui.get_screen_position(bgNode).y then
					local carrierpos = gui.get_position(carrier)
					carrierpos.y = carrierpos.y - 20
					gui.set_position(carrier, carrierpos)
				end
				
			elseif utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) < utf8.len(gui.get_text(dd[lines][dd[active]].text)) then -- If hidden is shorter remove text from that point
				local hiddenlength = utf8.len(gui.get_text(dd[lines][dd[active]].hidden))
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				local text = gui.get_text(dd[lines][dd[active]].hidden)
				text = utf8.sub(text, 1, -2)
				gui.set_text(dd[lines][dd[active]].hidden, text)
				text = text .. utf8.sub(gui.get_text(dd[lines][dd[active]].text), hiddenlength+1, -1)
				gui.set_text(dd[lines][dd[active]].text, text)
				markerPos.x = gui.get_text_metrics_from_node(dd[lines][dd[active]].hidden).width
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
			elseif utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) == utf8.len(gui.get_text(dd[lines][dd[active]].text)) then -- If equal remove from the end
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				local text = gui.get_text(dd[lines][dd[active]].hidden)
				text = utf8.sub(text, 1, -2)
				gui.set_text(dd[lines][dd[active]].hidden, text)
				gui.set_text(dd[lines][dd[active]].text, text)
				markerPos.x = gui.get_text_metrics_from_node(dd[lines][dd[active]].hidden).width
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
			end
		end
		if action_id == hash("delete") and action.repeated  and dd[input] then -- Same as above but delete
			if utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) < utf8.len(gui.get_text(dd[lines][dd[active]].text)) then
				local hiddenlength = utf8.len(gui.get_text(dd[lines][dd[active]].hidden))
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				local text = gui.get_text(dd[lines][dd[active]].hidden)
				gui.set_text(dd[lines][dd[active]].hidden, text)
				text = text .. utf8.sub(gui.get_text(dd[lines][dd[active]].text), hiddenlength+2, -1)
				gui.set_text(dd[lines][dd[active]].text, text)
				markerPos.x = gui.get_text_metrics_from_node(hiddenText).width
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
			elseif utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) == utf8.len(gui.get_text(dd[lines][dd[active]].text)) and dd[active] <= #dd[lines] then -- If marker at end there is nothing to delete
				print("nothing to delete")
			end
		end
		if action_id == hash("enter") and action.pressed and dd[input] then -- add new line
			if utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) < utf8.len(gui.get_text(dd[lines][dd[active]].text)) then
				local hiddenlength = utf8.len(gui.get_text(dd[lines][dd[active]].hidden))
				local text = gui.get_text(dd[lines][dd[active]].hidden)
				local textfornextline = utf8.sub(gui.get_text(dd[lines][dd[active]].text), hiddenlength+1, -1)
				gui.set_text(dd[lines][dd[active]].text, text)
				gui.set_enabled(dd[lines][dd[active]].marker, false)
				dd[linescount] = dd[linescount] + 1
				dd[active] = dd[active] + 1
				table.insert(dd[lines], dd[active], addline(node, dd[linescount]))
				gui.set_text(dd[lines][dd[active]].text, textfornextline)
				gui.set_text(dd[lines][dd[active]].hidden, "")
				sortlines(node, dd[lines])
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				markerPos.x = 0
				gui.set_position(dd[lines][dd[active]].marker, markerPos)
				gui.set_enabled(dd[lines][dd[active]].marker, true)

				if gui.get_position(dd[lines][dd[active]].innerbox).y < -60 then
					local carrierpos = gui.get_position(carrier)
					carrierpos.y = carrierpos.y + 20
					gui.set_position(carrier, carrierpos)
				end
			elseif utf8.len(gui.get_text(dd[lines][dd[active]].hidden)) == utf8.len(gui.get_text(dd[lines][dd[active]].text)) and dd[active] <= #dd[lines] then -- If marker at end there is nothing to delete
				gui.set_enabled(dd[lines][dd[active]].marker, false)
				dd[linescount] = dd[linescount] + 1
				dd[active] = dd[active] + 1
				table.insert(dd[lines], dd[active], addline(node, dd[linescount]))
				gui.set_text(dd[lines][dd[active]].hidden, "")
				gui.set_text(dd[lines][dd[active]].text, "")
				sortlines(node, dd[lines])
				local markerPos = gui.get_position(dd[lines][dd[active]].marker)
				markerPos.x = 0
				gui.set_enabled(dd[lines][dd[active]].marker, true)
				gui.set_position(dd[lines][dd[active]].marker, markerPos)

				if gui.get_position(dd[lines][dd[active]].innerbox).y < -60 then
					local carrierpos = gui.get_position(carrier)
					carrierpos.y = carrierpos.y + 20
					gui.set_position(carrier, carrierpos)
				end
			end
		end
	end
	-- Gather return string
	if dd[lines] ~= nil then
		local returnstring = ""
		for i = 1, #dd[lines] do
			returnstring = returnstring .. gui.get_text(dd[lines][i].text) .. "\n"
		end
		return returnstring
	end
end

function deleteLine (node, id)
	local text = gui.get_node(node .. "/text" .. id)
	local hidden = gui.get_node(node .. "/hiddentext" .. id)
	local marker = gui.get_node(node .. "/marker" .. id)
	local innerbox = gui.get_node(node .. "/innerbox" .. id)

	gui.delete_node(text)
	gui.delete_node(hidden)
	gui.delete_node(marker)
	gui.delete_node(innerbox)
end

function addline (node, currentline)
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

	local newPos = vmath.vector3(0, -20*(currentline-1) - 5, 0)
	gui.set_position(newinnerbox, newPos)
	newline = {text = newtext, hidden = newhidden, marker = newmarker, innerbox = newinnerbox, id = currentline} 
	return newline
end

function sortlines (node, list)
	for i = 1, #list do
		gui.set_position(list[i].innerbox, vmath.vector3(5,-20 * (i-1) -5,0)) 
	end

	local carrier = gui.get_node(node .. "/carrier")
	carries_size = gui.get_size(carrier)
	carries_size.y = #list*30
	gui.set_size(carrier, carries_size)
end
	