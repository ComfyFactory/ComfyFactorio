--[[
FJEI - Factorio "Just enough items"
An item recipe browser
]]

local Gui = require "modules.fjei.gui"

local function set_item_list()
	global.fjei.item_list = {}
	local list = global.fjei.item_list
	local i = 1
	for name, prototype in pairs(game.recipe_prototypes) do	
		list[i] = {name = name, sprite = "recipe/" .. name}
		i = i + 1
	end
	table.sort(list, function (a, b) return a.name < b.name end)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	set_item_list()
	Gui.draw_top_toggle_button(player)
end

local function on_gui_click(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	local player = game.players[event.player_index]
	
	if Gui.toggle_main_window(element, player) then return end

end

local function on_init()
	global.fjei = {}
end

local event = require "utils.event"
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)
event.on_init(on_init)