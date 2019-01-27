require "maps.modules.satellite_score"
require "maps.modules.dynamic_landfill"
require "maps.modules.splice"
require "maps.modules.spawners_contain_biters"

local event = require 'utils.event'

local function init()
	if global.railworld_init_done then return end
	
	game.map_settings.enemy_expansion.enabled = false
	
	global.railworld_init_done = true
end

local function on_player_joined_game(event)
	init()
	
	local player = game.players[event.player_index]
	if not global.player_equipped then global.player_equipped = {} end
	
	if not global.player_equipped[player.name] then
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "iron-plate", count = 64})
		player.insert({name = "iron-gear-wheel", count = 32})
		player.insert({name = "shotgun", count = 1})
		player.insert({name = "shotgun-shell", count = 16})
		player.insert({name = "light-armor", count = 1})
		global.player_equipped[player.name] = true
		
		local radius = 320
		game.forces.player.chart(game.surfaces[1], {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})	
	end
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)