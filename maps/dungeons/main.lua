-- Deep dark dungeons by mewmew --

require "modules.mineable_wreckage_yields_scrap"

local Room_generator = require "functions.room_generator"

local Biomes = {}
Biomes.dirtlands = require "maps.dungeons.biome_dirtlands"
Biomes.grasslands = require "maps.dungeons.biome_grasslands"
Biomes.glitch = require "maps.dungeons.biome_glitch"

local Get_noise = require "utils.get_noise"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs

local tile_sets = {
	
	{"red-desert-1", "red-desert-3", "red-desert-2"},
	{"sand-2", "sand-1", "sand-3"},
	{"concrete", "refined-concrete", "stone-path"},
}

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local function get_biome(position)
	local seed = game.surfaces[1].map_gen_settings.seed
	local seed_addition = 100000
	
	if Get_noise("cave_ponds", position, seed + seed_addition) > 0.25 then return "grasslands" end
	if Get_noise("cave_ponds", position, seed + seed_addition * 2) > 0.5 then return "glitch" end
	
	return "dirtlands"
end

local function expand(surface, position)
	local room = Room_generator.get_room(surface, position)
	if not room then return end
	local name = get_biome(position)
	Biomes[name](surface, room)
	
	if not room.room_tiles[1] then return end
	global.dungeons.depth = global.dungeons.depth + 1
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	
	local tiles = {}
	local i = 1
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if math_abs(position.x) > 2 or math_abs(position.y) > 2 then
				tiles[i] = {name = "out-of-map", position = position}
				i = i + 1
			else
				if math_abs(position.x) > 1 or math_abs(position.y) > 1 then
					tiles[i] = {name = "black-refined-concrete", position = position}
					i = i + 1
				else
					tiles[i] = {name = "purple-refined-concrete", position = position}
					i = i + 1
				end
			end
		end
	end
	surface.set_tiles(tiles, true)
	
	if left_top.x == 32 and left_top.y == 32 then	
		surface.create_entity({name = "rock-big", position = {0, -2}})
		surface.create_entity({name = "rock-big", position = {0, 2}})
		surface.create_entity({name = "rock-big", position = {-2, 0}})
		surface.create_entity({name = "rock-big", position = {2, 0}})
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces["dungeons"]
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
		player.insert({name = "raw-fish", count = 10})
	end	
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end	
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_init()
	local map_gen_settings = {
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = false,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
	}
	local surface = game.create_surface("dungeons", map_gen_settings)
	
	surface.request_to_generate_chunks({0,0}, 2)
	surface.force_generate_chunk_requests()
	
	local surface = game.surfaces[1]
	local map_gen_settings = surface.map_gen_settings
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	surface.map_gen_settings = map_gen_settings
	for chunk in surface.get_chunks() do		
		surface.delete_chunk({chunk.x, chunk.y})		
	end
	
	game.forces.player.manual_mining_speed_modifier = 20
	
	global.dungeons = {}
	global.dungeons.depth = 0
end

local Event = require 'utils.event' 
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)