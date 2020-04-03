--lost-- mewmew made this --

local Rooms = require "functions.random_room"
require "modules.mineable_wreckage_yields_scrap"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs

local ores = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore","coal", "coal","stone", "stone","uranium-ore"}
local trees = {"dead-dry-hairy-tree", "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree"}
local size_of_trees = #trees

local tile_sets = {
	{"dirt-3", "dirt-7", "dirt-5"},
	{"dirt-3", "dirt-7", "dirt-5"},
	{"dirt-3", "dirt-7", "dirt-5"},
	{"dirt-3", "dirt-7", "dirt-5"},
	{"dirt-3", "dirt-7", "dirt-5"},
	{"dirt-3", "dirt-7", "dirt-5"},
	{"dirt-3", "dirt-7", "dirt-5"},
	{"lab-white", "lab-dark-2", "lab-dark-1"},
	{"red-desert-1", "red-desert-3", "red-desert-2"},
	{"grass-1", "grass-3", "grass-2"},
	{"sand-2", "sand-1", "sand-3"},
	{"concrete", "refined-concrete", "stone-path"},
}
local size_of_tile_sets = #tile_sets

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local function expand(surface, room)
	local tile_set = tile_sets[math_random(1, size_of_tile_sets)]
	
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = tile_set[1], position = tile.position}}, true)
	end
	
	if #room.room_border_tiles > 1 then table_shuffle_table(room.room_border_tiles) end
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = tile_set[2], position = tile.position}}, true)
		if key < 5 then
			surface.create_entity({name = "rock-big", position = tile.position})
		end
	end
	
	if #room.room_tiles > 1 then table_shuffle_table(room.room_tiles) end
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = tile_set[3], position = tile.position}}, true)
		if math_random(1, 64) == 1 then
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = math_random(100, 20000)})
		else
			if math_random(1, 128) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = tile.position})
			end
		end
		if key % 128 == 1 and math_random(1, 2) == 1 then
			surface.create_entity({name = "biter-spawner", position = tile.position})
		end
		if key % 128 == 1 and math_random(1, 3) == 1 then
			surface.create_entity({name = "small-worm-turret", position = tile.position})
		end
		if math_random(1, 64) == 1 then
			surface.create_entity({name = "mineable-wreckage", position = tile.position})
		end
		if math_random(1, 256) == 1 then
			surface.create_entity({name = "rock-huge", position = tile.position})
		end
	end
	
	if room.center then
		if math_random(1, 16) == 1 then
			for x = -1, 1, 1 do
				for y = -1, 1, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "water", position = p}})
					surface.create_entity({name = "fish", position = p})
				end
			end
		else
			if math_random(1, 16) == 1 then
				surface.create_entity({name = "crude-oil", position = room.center, amount = math_random(200000, 400000)})
			end
		end
	end
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
	
	local surface = entity.surface
	
	local room = Rooms.get_room(surface, entity.position)
	if room then 
		expand(surface, room)
	end
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
	
	--game.forces.player.manual_mining_speed_modifier = 10
	
	global.terrain_work = {}
end

local Event = require 'utils.event' 
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)