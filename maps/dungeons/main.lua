-- Deep dark dungeons by mewmew --

require "modules.mineable_wreckage_yields_scrap"
require "modules.biters_yield_ore"
require "modules.rpg"
require "modules.explosives"

local MapInfo = require "modules.map_info"
local Room_generator = require "functions.room_generator"
local BiterHealthBooster = require "modules.biter_health_booster"
local BiterRaffle = require "functions.biter_raffle"

local Biomes = {}
Biomes.dirtlands = require "maps.dungeons.biome_dirtlands"
Biomes.desert = require "maps.dungeons.biome_desert"
Biomes.red_desert = require "maps.dungeons.biome_red_desert"
Biomes.grasslands = require "maps.dungeons.biome_grasslands"
Biomes.concrete = require "maps.dungeons.biome_concrete"
Biomes.doom = require "maps.dungeons.biome_doom"
Biomes.glitch = require "maps.dungeons.biome_glitch"

local Get_noise = require "utils.get_noise"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor

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
	
	if Get_noise("dungeons", position, seed + seed_addition * 1) > 0.59 then return "glitch" end
	if Get_noise("dungeons", position, seed + seed_addition * 2) > 0.48 then return "doom" end
	if Get_noise("dungeons", position, seed + seed_addition * 3) > 0.21 then return "grasslands" end
	if Get_noise("dungeons", position, seed + seed_addition * 4) > 0.35 then return "red_desert" end
	if Get_noise("dungeons", position, seed + seed_addition * 5) > 0.25 then return "desert" end
	if Get_noise("dungeons", position, seed + seed_addition * 6) > 0.75 then return "concrete" end	
	
	return "dirtlands"
end

local function draw_depth_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top.dungeon_depth then player.gui.top.dungeon_depth.destroy() end
		local element = player.gui.top.add({type = "sprite-button", name = "dungeon_depth", caption = "Depth: " .. global.dungeons.depth, tooltip = "Delve deep and face increased dangers.\nIncreases whenever a new room is discovered."})
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 146
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 125, g = 75, b = 25}
		style.font = "default-large-bold"
	end
end

local function expand(surface, position)
	local room = Room_generator.get_room(surface, position)
	if not room then return end
	local name = get_biome(position)
	Biomes[name](surface, room)
	
	if not room.room_tiles[1] then return end
	global.dungeons.depth = global.dungeons.depth + 1
	draw_depth_gui()
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

local function on_entity_spawned(event)
	local spawner = event.spawner
	local unit = event.entity
	local unit_2 = spawner.surface.create_entity({name = unit.name, position = unit.position, force = "enemy"})
	unit_2.ai_settings.allow_try_return_to_spawner = true
	unit_2.ai_settings.allow_destroy_when_commands_fail = false
	
	local spawner_tier = global.dungeons.spawner_tier
	if not spawner_tier[spawner.unit_number] then
		local tier = math_floor(global.dungeons.depth * 0.05 - math_random(1, 4))
		if tier < 1 then tier = 1 end		
		spawner_tier[spawner.unit_number] = tier
		
		rendering.draw_text{
			text = "-Tier " .. tier .. "-",
			surface = spawner.surface,
			target = spawner,
			target_offset = {0, -3.25},
			color = {25, 0, 100, 255},
			scale = 1.50,
			font = "default-game",
			alignment = "center",
			scale_with_zoom = false
		}
	end
	
	local health_multiplier = (spawner_tier[spawner.unit_number] + 4) * 0.25
	
	if math_random(1, 32) == 1 then
		BiterHealthBooster.add_boss_unit(unit, health_multiplier * 8, 0.25)
	else
		BiterHealthBooster.add_unit(unit, health_multiplier)
	end
	BiterHealthBooster.add_unit(unit_2, health_multiplier)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces["dungeons"]
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
		player.insert({name = "raw-fish", count = 10})
	end
	draw_depth_gui()
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end	
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.type == "unit" and entity.spawner then
		entity.spawner.damage(20, game.forces[1])
	end
	
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
	
	--game.forces.player.manual_mining_speed_modifier = 0
	
	global.dungeons = {}
	global.dungeons.depth = 0
	global.dungeons.spawner_tier = {}
	
	global.rocks_yield_ore_base_amount = 50
	global.rocks_yield_ore_distance_modifier = 0.001
	
	global.explosion_cells_destructible_tiles = {
		["out-of-map"] = 2500,	
	}
	
	local T = MapInfo.Pop_info()
	T.localised_category = "dungeons"
	T.main_caption_color = {r = 0, g = 0, b = 0}
	T.sub_caption_color = {r = 75, g = 0, b = 0}
end

local Event = require 'utils.event' 
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_entity_died, on_entity_died)

require "modules.rocks_yield_ore"