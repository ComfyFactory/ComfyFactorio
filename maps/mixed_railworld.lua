local event = require 'utils.event'

require "modules.spawners_contain_acid"
require "modules.dynamic_landfill"
require "modules.satellite_score"
require "modules.dangerous_nights"
require "on_tick_schedule"
require "modules.splice_double"
require "modules.mineable_wreckage_yields_scrap"

local function init_surface()
	if game.surfaces["mixed_railworld"] then return game.surfaces["mixed_railworld"] end

	local map_gen_settings = {}
	map_gen_settings.water = "0.3"
	map_gen_settings.starting_area = "2"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 40, cliff_elevation_0 = 40}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "7", size = "0.5", richness = "0.5"},
		["stone"] = {frequency = "0.3", size = "2.0", richness = "0.5"},
		["iron-ore"] = {frequency = "0.3", size = "2.0", richness = "0.5"},
		["copper-ore"] = {frequency = "0.3", size = "2.0", richness = "0.5"},
		["uranium-ore"] = {frequency = "0.5", size = "1", richness = "0.5"},		
		["crude-oil"] = {frequency = "0.5", size = "1", richness = "1"},
		["trees"] = {frequency = "0.5", size = "0.75", richness = "0.75"},
		["enemy-base"] = {frequency = "1", size = "1", richness = "1"}
	}
	
	game.map_settings.enemy_expansion.enabled = false
	game.difficulty_settings.technology_price_multiplier = 2
		
	local surface = game.create_surface("mixed_railworld", map_gen_settings)				
	surface.request_to_generate_chunks({x = 0, y = 0}, 1)
	surface.force_generate_chunk_requests()
	
	game.forces["player"].set_spawn_position({0,0},game.surfaces["mixed_railworld"])
	
	return surface
end

local function on_player_joined_game(event)	
	local surface = init_surface()
	
	local player = game.players[event.player_index]
	local surface = game.surfaces["mixed_railworld"]
	if player.online_time == 0 then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "mixed_railworld")
		player.insert({name = 'car', count = 1})
		player.insert({name = 'small-lamp', count = 1})
	end	
end

local function on_chunk_generated(event)	
	for _, coal in pairs(event.surface.find_entities_filtered({area = event.area, name = {"coal"}})) do
		local pos = coal.position
		if math.random(1,2) ~= 1 then
			event.surface.create_entity({name = "mineable-wreckage", position = coal.position, force = "neutral"})
		end
		coal.destroy()
	end	
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "modules.ores_are_mixed"