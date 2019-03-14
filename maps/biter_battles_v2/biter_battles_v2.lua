-- Biter Battles v2 -- by MewMew

require "maps.biter_battles_v2.terrain"
require "maps.biter_battles_v2.mirror_terrain"

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "tools.map_functions"

local function init_surface(event)
	if game.surfaces["biter_battles"] then return end
	local map_gen_settings = {}
	map_gen_settings.water = "none"
	map_gen_settings.starting_area = "5"	
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0.8", size = "1", richness = "0.3"},
		["stone"] = {frequency = "0.8", size = "1", richness = "0.3"},
		["copper-ore"] = {frequency = "0.8", size = "2", richness = "0.3"},
		["iron-ore"] = {frequency = "0.8", size = "2", richness = "0.3"},
		["crude-oil"] = {frequency = "0.8", size = "2", richness = "0.4"},
		["trees"] = {frequency = "0.8", size = "0.5", richness = "0.3"},
		["enemy-base"] = {frequency = "0.8", size = "1", richness = "0.4"}			
	}
	--game.create_surface("biter_battles", map_gen_settings)
	
end

local function on_player_joined_game(event)
	--init_surface(event)
	local player = game.players[event.player_index]
	player.character.destructible = false
	--player.character.destroy()
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
