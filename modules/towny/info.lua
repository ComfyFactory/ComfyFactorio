local Public = {}
local Table = require "modules.towny.table"

function Public.toggle_button(player)
	if player.gui.top["towny_map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = {"modules_towny.towny"}, name = "towny_map_intro_button", tooltip = {"modules_towny.show_info"}})
	b.style.font_color = {r=0.5, g=0.3, b=0.99}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.maximal_height = 38
	b.style.minimal_width = 100
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

function Public.show(player)
	local townytable = Table.get_table()
	if player.gui.center["towny_map_intro_frame"] then player.gui.center["towny_map_intro_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "towny_map_intro_frame"}
	local frame = frame.add {type = "frame", direction = "vertical"}

	local t = frame.add {type = "table", column_count = 2}

	local label = t.add {type = "label", caption = {"modules_towny.active_factions"}}
	label.style.font = "heading-1"
	label.style.font_color = {r=0.85, g=0.85, b=0.85}
	label.style.right_padding = 8

	local t = t.add {type = "table", column_count = 4}

	local label = t.add {type = "label", caption = {"modules_towny.outlander", #game.forces.player.connected_players}}
	label.style.font_color = {170, 170, 170}
	label.style.font = "heading-3"
	label.style.minimal_width = 80

	for _, town_center in pairs(townytable.town_centers) do
		local force = town_center.market.force
		local label = t.add {type = "label", caption = {"modules_towny.force", force.name, #force.connected_players}}
		label.style.font = "heading-3"
		label.style.minimal_width = 80
		label.style.font_color = town_center.color
	end

	frame.add {type = "line"}

	local l = frame.add {type = "label", caption = {"modules_towny.map_info_header"}}
	l.style.font = "heading-1"
	l.style.font_color = {r=0.85, g=0.85, b=0.85}
	local caption = {"modules_towny.map_info", {"modules_towny.map_info1"}, {"modules_towny.map_info2"},{"modules_towny.map_info3"},{"modules_towny.map_info4"},{"modules_towny.map_info5"}}

	local l = frame.add {type = "label", caption = caption}
	l.style.single_line = false
	l.style.font = "heading-2"
	l.style.font_color = {r=0.8, g=0.7, b=0.99}
end

function Public.new_town_button(player)
	if player.gui.top["towny_new_town_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "New Town", name = "towny_new_town_button", tooltip = {"modules_towny.new_town_caption", {"modules_towny.new_town_off"}}})
	b.style.font_color = {r = 0.88, g = 0.02, b = 0.02}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.maximal_height = 38
	b.style.minimal_width = 100
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

function Public.update_new_town_button(player)
	local townytable = Table.get_table()
	local button = player.gui.top["towny_new_town_button"]
	if not button or not button.valid then return end
	if player.force == game.forces.player then
		button.visible = true
		if townytable.town_buttons[player.index] == true then
			button.tooltip = {"modules_towny.new_town_caption", {"modules_towny.new_town_on"}}
			button.style.font_color = {r = 0.02, g = 0.88, b = 0.02}
		else
			button.tooltip = {"modules_towny.new_town_caption", {"modules_towny.new_town_off"}}
			button.style.font_color = {r = 0.88, g = 0.02, b = 0.02}
		end
	else
		button.visible = false
	end
end

function Public.close(event)
	if not event.element then return end
	if not event.element.valid then return end
	local parent = event.element.parent
	for _ = 1, 4, 1 do
		if not parent then return end
		if parent.name == "towny_map_intro_frame" then parent.destroy() return end
		parent = parent.parent
	end
end

function Public.toggle(event)
	if not event.element then return end
	if not event.element.valid then return end
	if event.element.name == "towny_map_intro_button" then
		local player = game.players[event.player_index]
		if player.gui.center["towny_map_intro_frame"] then
			player.gui.center["towny_map_intro_frame"].destroy()
		else
			Public.show(player)
		end
	end
end

function Public.toggle_town(event)
	local townytable = Table.get_table()
	if not event.element then return end
	if not event.element.valid then return end
	if event.element.name == "towny_new_town_button" then
		local player = game.players[event.player_index]
		if townytable.town_buttons[player.index] then
			townytable.town_buttons[player.index] = false
		else
			townytable.town_buttons[player.index] = true
		end
		Public.update_new_town_button(player)
	end
end


return Public
