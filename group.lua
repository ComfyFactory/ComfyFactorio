-- this script adds a group button to create groups for your players -- 

local Event = require 'utils.event' 

local function build_group_gui(player)
	local group_name_width = 160
	local description_width = 220
	local members_width = 90
	local member_columns = 3
	local actions_width = 60
	local total_height = 350
	
	if not player.gui.top["group_button"] then
		local b = player.gui.top.add({type = "button", name = "group_button", caption = global.player_group[player.name], tooltip = "Join / Create a group"})
		b.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
		b.style.font = "default-bold"
		b.style.minimal_height = 38
		b.style.minimal_width = 38
		b.style.top_padding = 2
		b.style.left_padding = 4
		b.style.right_padding = 4
		b.style.bottom_padding = 2
	end
	
	if player.online_time < 1 then return end
	
	if player.gui.left["group_frame"] then player.gui.left["group_frame"].destroy() end
	local frame = player.gui.left.add({type = "frame", name = "group_frame", direction = "vertical"})
	frame.style.minimal_height = total_height
	
	local t = frame.add({type = "table", column_count = 5})
	local headings = {{"Title", group_name_width}, {"Description", description_width}, {"Members", members_width * member_columns}, {"", actions_width*2 - 30}}
	for _, h in pairs (headings) do			
		local l = t.add({ type = "label", caption = h[1]})
		l.style.font_color = { r=0.98, g=0.66, b=0.22}
		l.style.font = "default-listbox"
		l.style.top_padding = 6
		l.style.minimal_height = 40
		l.style.minimal_width = h[2]
		l.style.maximal_width = h[2]
	end
	local b = t.add {type = "button", caption = "X", name = "close_group_frame", align = "right"}	
	b.style.font = "default"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	
	local scroll_pane = frame.add({ type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	scroll_pane.style.maximal_height = total_height - 50
	scroll_pane.style.minimal_height = total_height - 50
	
	local t = scroll_pane.add({type = "table", name = "groups_table", column_count = 4})
	for _, h in pairs (headings) do	
		local l = t.add({ type = "label", caption = ""})
		l.style.minimal_width = h[2]
		l.style.maximal_width = h[2]
	end	

	for _, group in pairs (global.tag_groups) do
		
		local l = t.add({ type = "label", caption = group.name})
		l.style.font = "default-bold"
		l.style.top_padding = 16
		l.style.bottom_padding = 16
		l.style.minimal_width = group_name_width
		l.style.maximal_width = group_name_width
		local color = game.players[group.founder].color
		color = {r = color.r * 0.6 + 0.4, g = color.g * 0.6 + 0.4, b = color.b * 0.6 + 0.4, a = 1}
		l.style.font_color = color
		l.style.single_line = false
		
		local l = t.add({ type = "label", caption = group.description})
		l.style.top_padding = 16
		l.style.bottom_padding = 16
		l.style.minimal_width = description_width
		l.style.maximal_width = description_width
		l.style.font_color = {r = 0.90, g = 0.90, b = 0.90}		
		l.style.single_line = false
		
		local tt = t.add({ type = "table", column_count = member_columns})
		for _, p in pairs (game.connected_players) do
			if group.name == global.player_group[p.name] then
				local l = tt.add({ type = "label", caption = p.name})
				local color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1} 			
				l.style.font_color = color
				--l.style.minimal_width = members_width
				l.style.maximal_width = members_width * 2
			end
		end
		
		local tt = t.add({ type = "table", name = group.name, column_count = 2})		
		if player.admin == true or group.founder == player.name then				
			local b = tt.add({ type = "button", caption = "Delete"})
			b.style.font = "default-bold"
			b.style.minimal_width = actions_width
			b.style.maximal_width = actions_width
		else
			local l = tt.add({ type = "label", caption = ""})			
			l.style.minimal_width = actions_width
			l.style.maximal_width = actions_width
		end	
		if group.name ~= global.player_group[player.name] then
			local b = tt.add({ type = "button", caption = "Join"})
			b.style.font = "default-bold"
			b.style.minimal_width = actions_width
			b.style.maximal_width = actions_width
		else			
			local b = tt.add({ type = "button", caption = "Leave"})
			b.style.font = "default-bold"
			b.style.minimal_width = actions_width
			b.style.maximal_width = actions_width
		end
	end		
	
	local frame2 = frame.add({type = "frame", name = "frame2"})
	local t = frame2.add({type = "table", name = "group_table", column_count = 3})
	local textfield = t.add({ type = "textfield", name = "new_group_name", text = "Name" })
	textfield.style.minimal_width = group_name_width
	local textfield = t.add({ type = "textfield", name = "new_group_description", text = "Description" })
	textfield.style.minimal_width = description_width + members_width * member_columns
	local b = t.add({type = "button", name = "create_new_group", caption = "Create"})
	b.style.minimal_width = actions_width*2 - 12
	b.style.font = "default-bold"
		
end

local function refresh_gui()
	for _, p in pairs(game.connected_players) do
		if p.gui.left["group_frame"] then
		
			local frame = p.gui.left["group_frame"]
			local new_group_name = frame.frame2.group_table.new_group_name.text
			local new_group_description = frame.frame2.group_table.new_group_description.text
			
			build_group_gui(p)
			
			local frame = p.gui.left["group_frame"]
			frame.frame2.group_table.new_group_name.text = new_group_name
			frame.frame2.group_table.new_group_description.text = new_group_description
			
		end
	end
end

local function on_player_joined_game(event)

	local player = game.players[event.player_index]
	
	if not global.player_group then global.player_group = {} end
	if not global.player_group[player.name] then global.player_group[player.name] = "[Group]" end
	
	if not global.join_spam_protection then global.join_spam_protection = {} end	
	if not global.join_spam_protection[player.name] then global.join_spam_protection[player.name] = game.tick end
	
	
	if not global.tag_groups then global.tag_groups = {} end
	
	if player.online_time < 10 then  
		build_group_gui(player)
	end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	

	local player = game.players[event.element.player_index]
	local name = event.element.name
	local frame = player.gui.left["group_frame"]
	
	if name == "create_new_group" then			
		local new_group_name = frame.frame2.group_table.new_group_name.text
		local new_group_description = frame.frame2.group_table.new_group_description.text
		if new_group_name ~= "" and new_group_name ~= "Name" and new_group_description ~= "Description" then
			
			if string.len(new_group_name) > 32 then
				player.print("Group name is too long. 32 characters maximum.", { r=0.90, g=0.0, b=0.0})
				return
			end
			
			if string.len(new_group_description) > 128 then
				player.print("Description is too long. 128 characters maximum.", { r=0.90, g=0.0, b=0.0})				
				return
			end
			
			global.tag_groups[new_group_name] = {name = new_group_name, description = new_group_description, founder = player.name}
			local color = {r = player.color.r * 0.7 + 0.3, g = player.color.g * 0.7 + 0.3, b = player.color.b * 0.7 + 0.3, a = 1}
			game.print(player.name .. " has founded a new group!", color)
			game.print('>> ' .. new_group_name, { r=0.98, g=0.66, b=0.22})
			game.print(new_group_description, { r=0.85, g=0.85, b=0.85})
			
			frame.frame2.group_table.new_group_name.text = "Name"
			frame.frame2.group_table.new_group_description.text = "Description"
			refresh_gui()
			return
		end		
	end
	
	local p = event.element.parent
	if p then p = p.parent end
	if p then
		if p.name == "groups_table" then			
			if event.element.type == "button" and event.element.caption == "Join" then		
				global.player_group[player.name] = event.element.parent.name
				local str = "[" .. event.element.parent.name
				str = str .. "]"
				player.gui.top["group_button"].caption = str
				player.tag = str
				if game.tick - global.join_spam_protection[player.name] > 600 then
					local color = {r = player.color.r * 0.7 + 0.3, g = player.color.g * 0.7 + 0.3, b = player.color.b * 0.7 + 0.3, a = 1}
					game.print(player.name .. ' has joined group "' .. event.element.parent.name .. '"', color)
					global.join_spam_protection[player.name] = game.tick
				end				
				refresh_gui()
				return
			end

			if event.element.type == "button" and event.element.caption == "Delete" then
				for _, p in pairs(game.players) do
					if global.player_group[p.name] then
						if global.player_group[p.name] == event.element.parent.name then
							global.player_group[p.name] = "[Group]"
							p.gui.top["group_button"].caption = "[Group]"
							p.tag = ""
						end
					end
				end
				game.print(player.name .. ' deleted group "' .. event.element.parent.name .. '"')
				global.tag_groups[event.element.parent.name] = nil
				refresh_gui()	
				return
			end

			if event.element.type == "button" and event.element.caption == "Leave" then		
				global.player_group[player.name] = "[Group]"
				player.gui.top["group_button"].caption = "[Group]"
				player.tag = ""				
				refresh_gui()	
				return
			end			
		end
	end
	
	if name == "group_button" then
		if frame then
			frame.destroy()
		else
			build_group_gui(player)
		end
	end
	
	if name == "close_group_frame" then
		frame.destroy()
	end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)