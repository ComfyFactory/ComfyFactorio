-- forest circle --  MewMew

require 'utils.table'
require "functions.soft_reset"

local event = require 'utils.event'

global.map_gen_settings = {}
global.map_gen_settings.seed = 1024
global.map_gen_settings.water = "0.01"
global.map_gen_settings.starting_area = "2.5"
global.map_gen_settings.cliff_settings = {cliff_elevation_interval = 38, cliff_elevation_0 = 38}	
global.map_gen_settings.autoplace_controls = {
	["coal"] = {frequency = "2", size = "1", richness = "1"},
	["stone"] = {frequency = "2", size = "1", richness = "1"},
	["copper-ore"] = {frequency = "2", size = "1", richness = "1"},
	["iron-ore"] = {frequency = "2.5", size = "1.1", richness = "1"},
	["uranium-ore"] = {frequency = "2", size = "1", richness = "1"},
	["crude-oil"] = {frequency = "2.5", size = "1", richness = "1.5"},
	["trees"] = {frequency = "1.25", size = "0.6", richness = "0.5"},
	["enemy-base"] = {frequency = "256", size = "0.61", richness = "1"}	
}

local function init_surface()	
	
	game.create_surface("forest_circle", global.map_gen_settings)
			
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false
	
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.settler_group_min_size = 8
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.min_expansion_cooldown = 54000
	game.map_settings.enemy_expansion.max_expansion_cooldown = 108000
end

local function on_player_joined_game(event)	
	local surface = game.surfaces["forest_circle"]
	local player = game.players[event.player_index]	
	
	if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
	
	if player.online_time == 0 then
		if surface.is_chunk_generated({0,0}) then
			player.teleport(surface.find_non_colliding_position("character", {0,0}, 3, 0.5), surface)
		else
			player.teleport({0,0}, surface)
		end
		player.character.destructible = false
		game.permissions.get_group("spectator").add_player(player)
	end
end

local circles = {
	[1] = "tree-01",
	[2] = "small-worm-turret",
	[3] = "biter-spawner",
	[4] = "tree-04",
	[5] = "tree-05",
	[6] = "tree-06",
}

local function process_position(surface, pos)
	surface.set_tiles({{name = "grass-1", position = pos}}, true)
	
	local m = 0.035
	
	if pos.y <= math.floor(40 * math.sin(pos.x * m)) + 9 and pos.y >= math.floor(40 * math.sin(pos.x * m)) - 9 then
		surface.create_entity({name = circles[1], position = pos})
		return
	else
		
		return 
	end
	
	local current_radius = pos.x ^ 2 + pos.y ^ 2
	local index = math.floor(current_radius / 2048)
	if index == 0 then return end
	if index > #circles then return end
	if not surface.can_place_entity({name = circles[index], position = pos}) then return end
	if math.random(1,3) ~= 1 then
		surface.create_entity({name = circles[index], position = pos})
	end
end

local function on_chunk_generated(event)
	local pos
	local left_top = event.area.left_top
	local surface = event.surface
	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "neutral"})) do
		e.destroy()
	end
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			pos = {x = left_top.x + x, y = left_top.y + y}
			process_position(surface, pos)
		end
	end
end

local function on_init(surface)
	if game.surfaces["forest_circle"] then return end
	init_surface()
end

event.on_init(on_init)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)