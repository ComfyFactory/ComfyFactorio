local forces = {
	{name = "north", color = {r = 0, g = 0, b = 200}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "south",	color = {r = 200, g = 0, b = 0}},
}

local function get_player_array(force_name)
	local a = {}
	for i = 1, math.random(3, 111), 1 do
		a[#a + 1] = math.random(100, 10000)
	end
	
	for _, p in pairs(game.forces[force_name].players) do a[#a + 1] = p.name end
	return a
end

local function draw_manager_button(player)
	if player.gui.top["bb_team_lock_button"] then player.gui.top["bb_team_lock_button"].destroy() end
	
	if not player.admin then return end
	
	local button = player.gui.top.add({type = "sprite-button", name = "team_manager_toggle_button", caption = "Team Manager", tooltip = tooltip})
	button.style.font = "heading-2"
	button.style.font_color = {r = 0.33, g = 0.77, b = 0.33}
	button.style.minimal_height = 38
	button.style.minimal_width = 120
	button.style.top_padding = 2
	button.style.left_padding = 0
	button.style.right_padding = 0
	button.style.bottom_padding = 2
end

local function draw_manager_gui(player)
	if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
	
	local frame = player.gui.center.add({type = "frame", name = "team_manager_gui", caption = "Manage Teams"})
	
	local t = frame.add({type = "table", name = "team_manager_root_table", column_count = 5})
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local l = t.add({type = "label", caption = string.upper(forces[i2].name)})
			l.style.font_color = forces[i2].color
			l.style.font = "heading-1"
			i2 = i2 + 1
		else
			local tt = t.add({type = "label", caption = " "})
		end		
	end
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local list_box = t.add({type = "list-box", name = "team_manager_list_box_" .. i, items = get_player_array(forces[i2].name)})
			list_box.style.minimal_height = 360
			list_box.style.minimal_width = 160
			list_box.style.maximal_height = 480
			i2 = i2 + 1
		else
			local tt = t.add({type = "table", column_count = 1})
			local b = tt.add({type = "sprite-button", caption = "→"})
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
			local b = tt.add({type = "sprite-button", caption = "←"})
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
		end		
	end
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]	
	draw_manager_button(player)
	draw_manager_gui(player)
end

local event = require 'utils.event'
event.add(defines.events.on_player_joined_game, on_player_joined_game)