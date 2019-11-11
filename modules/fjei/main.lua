--[[
FJEI - Factorio "Just enough items"
An item recipe browser - MewMew
]]

local Gui = require "modules.fjei.gui"

local function set_base_item_list()
	global.fjei.item_list = {}
	local list = global.fjei.item_list
	local i = 1
	for name, prototype in pairs(game.recipe_prototypes) do	
		list[i] = {name = name}
		i = i + 1
	end
	table.sort(list, function (a, b) return a.name < b.name end)
	global.fjei.size_of_item_list = #list
end

local function set_filtered_list(player)
	local player_data = global.fjei.player_data[player.index]
	local active_filter = player_data.active_filter
	local base_list = global.fjei.item_list
	player_data.active_page = 1
	player_data.filtered_list = {}
	local filtered_list = player_data.filtered_list
	local i = 1
	for key, entry in pairs(base_list) do
		if active_filter then
			local a, b = string.find(entry.name, active_filter)
			if a then
				filtered_list[i] = key
				i = i + 1
			end
		else
			filtered_list[i] = key
			i = i + 1
		end
	end
	player_data.size_of_filtered_list = #player_data.filtered_list
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	global.fjei.player_data[player.index] = {}
	set_base_item_list()
	set_filtered_list(player)
	Gui.draw_top_toggle_button(player)
end

local function on_player_left_game(event)
	local player = game.players[event.player_index]
	global.fjei.player_data[player.index].filtered_list = nil
	global.fjei.player_data[player.index] = nil
end

local function on_gui_click(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	local player = game.players[event.player_index]	
	Gui.gui_click_actions(element, player)
end

local function on_gui_text_changed(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	if element.name ~= "fjei_main_window_search_textfield" then return end
	local player = game.players[event.player_index]
	if element.text == "" then
		global.fjei.player_data[player.index].active_filter = false
	else
		global.fjei.player_data[player.index].active_filter = element.text
	end
	set_filtered_list(player)
	Gui.refresh_main_window(player)
end

local function on_init()
	global.fjei = {}
	global.fjei.player_data = {}
end

local event = require "utils.event"
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_gui_text_changed, on_gui_text_changed)
event.on_init(on_init)