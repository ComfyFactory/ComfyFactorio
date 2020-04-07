-- Deep dark dungeons by mewmew --

local spawn_size = 46

require "modules.mineable_wreckage_yields_scrap"

local MapInfo = require "modules.map_info"
local Room_generator = require "functions.room_generator"
local RPG = require "modules.rpg"
local BiterHealthBooster = require "modules.biter_health_booster"
local BiterRaffle = require "functions.biter_raffle"
local Functions = require "maps.dungeons.functions"
local Get_noise = require "utils.get_noise"

local Biomes = {}
Biomes.dirtlands = require "maps.dungeons.biome_dirtlands"
Biomes.desert = require "maps.dungeons.biome_desert"
Biomes.red_desert = require "maps.dungeons.biome_red_desert"
Biomes.grasslands = require "maps.dungeons.biome_grasslands"
Biomes.concrete = require "maps.dungeons.biome_concrete"
Biomes.doom = require "maps.dungeons.biome_doom"
Biomes.glitch = require "maps.dungeons.biome_glitch"
Biomes.acid_zone = require "maps.dungeons.biome_acid_zone"

local Get_noise = require "utils.get_noise"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_round = math.round

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local function get_biome(position)
	if position.x ^ 2 + position.y ^ 2 < 6400 then return "dirtlands" end

	local seed = game.surfaces[1].map_gen_settings.seed
	local seed_addition = 100000	
	
	if Get_noise("dungeons", position, seed + seed_addition * 1) > 0.62 then return "glitch" end
	if Get_noise("dungeons", position, seed + seed_addition * 2) > 0.52 then return "doom" end
	if Get_noise("dungeons", position, seed + seed_addition * 3) > 0.62 then return "acid_zone" end
	if Get_noise("dungeons", position, seed + seed_addition * 4) > 0.60 then return "concrete" end
	if Get_noise("dungeons", position, seed + seed_addition * 5) > 0.26 then return "grasslands" end
	if Get_noise("dungeons", position, seed + seed_addition * 6) > 0.30 then return "red_desert" end
	if Get_noise("dungeons", position, seed + seed_addition * 7) > 0.25 then return "desert" end
		
	return "dirtlands"
end

local function draw_depth_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top.dungeon_depth then player.gui.top.dungeon_depth.destroy() end
		local element = player.gui.top.add({type = "sprite-button", name = "dungeon_depth", caption = "~ Depth " .. global.dungeons.depth .. " ~"})
		
		element.tooltip = "Evolution: " .. game.forces.enemy.evolution_factor * 100 .. "%\nEnemy Health: " .. global.biter_health_boost * 100 .. "%"

		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 146
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 0, g = 0, b = 0}
		style.font = "default-large-bold"
	end
end

local function expand(surface, position)
	local room = Room_generator.get_room(surface, position)
	if not room then return end
	local name = get_biome(position)
	Biomes[name](surface, room)
	
	if not room.room_tiles[1] then return end
	
	local a = 2000
	local m = 1 / a
	
	global.dungeons.depth = global.dungeons.depth + 1
	game.forces.enemy.evolution_factor = global.dungeons.depth * m
	
	global.biter_health_boost = 1 + global.dungeons.depth * m
	
	if game.forces.enemy.evolution_factor == 1 then
		global.biter_health_boost = 2 + (global.dungeons.depth - a) * 0.001
		global.biter_health_boost = math_round(global.biter_health_boost, 2)
	end
	
	draw_depth_gui()
end

local function draw_spawn_decoratives(surface)	
	local decoratives = {"brown-hairy-grass", "brown-asterisk", "brown-fluff", "brown-fluff-dry", "brown-asterisk", "brown-fluff", "brown-fluff-dry"}
	local a = spawn_size * -1 + 1
	local b = spawn_size - 1
	for _, decorative_name in pairs(decoratives) do
		local seed = game.surfaces[1].map_gen_settings.seed + math_random(1, 1000000)
		for x = a, b, 1 do
			for y = a, b, 1 do
				local position = {x = x + 0.5, y = y + 0.5}
				if surface.get_tile(position).name == "dirt-7" or math_random(1, 5) == 1 then 
					local noise = Get_noise("decoratives", position, seed)
					if math_abs(noise) > 0.37 then
						surface.create_decoratives{check_collision = false, decoratives = {{name = decorative_name, position = position, amount = math.floor(math.abs(noise * 3)) + 1}}}
					end	
				end
			end
		end
	end
end

local function draw_spawn(surface)
	local tiles = {}
	local i = 1
	for x = spawn_size * -1, spawn_size, 1 do
		for y = spawn_size * -1, spawn_size, 1 do
			local position = {x = x, y = y}
			if math_abs(position.x) < 2 or math_abs(position.y) < 2 then
				tiles[i] = {name = "stone-path", position = position}
				i = i + 1
			end		
		end
	end
	surface.set_tiles(tiles, true)

	local tiles = {}
	local i = 1
	for x = -2, 2, 1 do
		for y = -2, 2, 1 do
			local position = {x = x, y = y}
			if math_abs(position.x) > 1 or math_abs(position.y) > 1 then
				tiles[i] = {name = "black-refined-concrete", position = position}
				i = i + 1
			else
				tiles[i] = {name = "purple-refined-concrete", position = position}
				i = i + 1
			end		
		end
	end
	surface.set_tiles(tiles, true)
	
	local tiles = {}
	local i = 1
	for x = spawn_size * -1, spawn_size, 1 do
		for y = spawn_size * -1, spawn_size, 1 do
			local position = {x = x, y = y}
			local r = math.sqrt(position.x ^ 2 + position.y ^ 2)	
			if r < 2 then
				tiles[i] = {name = "purple-refined-concrete", position = position}
				i = i + 1
			else
				if r < 2.5 then
					tiles[i] = {name = "black-refined-concrete", position = position}
					i = i + 1
				else
					if r < 4.5 then
						tiles[i] = {name = "concrete", position = position}
						i = i + 1
					end
				end
			end		
		end
	end
	surface.set_tiles(tiles, true)
	
	draw_spawn_decoratives(surface)
	
	local entities = {}
	local i = 1
	for x = spawn_size * -1 - 16, spawn_size + 16, 1 do
		for y = spawn_size * -1 - 16, spawn_size + 16, 1 do
			local position = {x = x, y = y}
			if position.x <= spawn_size and position.y <= spawn_size and position.x >= spawn_size * -1 and position.y >= spawn_size * -1 then
				if position.x == spawn_size then
					entities[i] = {name = "rock-big", position = {position.x + 0.95, position.y}}
					i = i + 1
				end
				if position.y == spawn_size then
					entities[i] = {name = "rock-big", position = {position.x, position.y + 0.95}}
					i = i + 1
				end
				if position.x == spawn_size * -1 or position.y == spawn_size * -1 then
					entities[i] = {name = "rock-big", position = position}
					i = i + 1
				end
			end
		end
	end
	
	for k, e in pairs(entities) do
		if k % 3 > 0 then surface.create_entity(e) end
	end
	
	local trees = { "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree", "tree-04"}
	local size_of_trees = #trees
	local r = 4
	for x = spawn_size * -1, spawn_size, 1 do
		for y = spawn_size * -1, spawn_size, 1 do
			local position = {x = x + 0.5, y = y + 0.5}
			if position.x > 5 and position.y > 5 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end
			if position.x <= -4 and position.y <= -4 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end	
			if position.x > 5 and position.y <= -4 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end	
			if position.x <= -4 and position.y > 5 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end				
		end
	end
	surface.set_tiles(tiles, true)
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	
	if math_abs(left_top.x) > 256 or math_abs(left_top.y) > 256 then
		local tiles = {}
		local i = 1
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local position = {x = left_top.x + x, y = left_top.y + y}			
				tiles[i] = {name = "out-of-map", position = position}
				i = i + 1			
			end
		end
		surface.set_tiles(tiles, true)
		return
	end
	
	local tiles = {}
	local i = 1
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if position.x > spawn_size or position.y > spawn_size or position.x < spawn_size * -1 or position.y < spawn_size * -1 then
				tiles[i] = {name = "out-of-map", position = position}
				i = i + 1
			else	
				tiles[i] = {name = "dirt-7", position = position}
				i = i + 1
			end
		end
	end
	surface.set_tiles(tiles, true)
	
	if left_top.x == 160 and left_top.y == 160 then		
		draw_spawn(surface)
	end
end

local function on_entity_spawned(event)
	local spawner = event.spawner
	local unit = event.entity
	local surface = spawner.surface

	local spawner_tier = global.dungeons.spawner_tier
	if not spawner_tier[spawner.unit_number] then
		Functions.set_spawner_tier(spawner)
	end

	local e = global.dungeons.depth * 0.0005
	for _ = 1, spawner_tier[spawner.unit_number], 1 do
		local name = BiterRaffle.roll("mixed", e)
		local non_colliding_position = surface.find_non_colliding_position(name, unit.position, 16, 1)
		local bonus_unit
		if non_colliding_position then
			bonus_unit = surface.create_entity({name = name, position = non_colliding_position, force = "enemy"})
		else
			bonus_unit = surface.create_entity({name = name, position = unit.position, force = "enemy"})
		end	
		bonus_unit.ai_settings.allow_try_return_to_spawner = true
		bonus_unit.ai_settings.allow_destroy_when_commands_fail = true
		
		if math_random(1, 256) == 1 then
			BiterHealthBooster.add_boss_unit(bonus_unit, global.biter_health_boost * 8, 0.25)
		end
	end
	
	if math_random(1, 256) == 1 then
		BiterHealthBooster.add_boss_unit(unit, global.biter_health_boost * 8, 0.25)
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces["dungeons"]
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
		player.insert({name = "raw-fish", count = 8})
		
		player.set_quick_bar_slot(1, "raw-fish")
		
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 16})
	end
	draw_depth_gui()
end

local function spawner_death(entity)
	local tier = global.dungeons.spawner_tier[entity.unit_number]
	
	if not tier then
		Functions.set_spawner_tier(entity)
		tier = global.dungeons.spawner_tier[entity.unit_number]
	end
	
	for _ = 1, tier * 2, 1 do
		Functions.spawn_random_biter(entity.surface, entity.position)
	end
	
	global.dungeons.spawner_tier[entity.unit_number] = nil
end

local function mining_events(entity)
	if math_random(1, 8) == 1 then Functions.spawn_random_biter(entity.surface, entity.position) return end
	if math_random(1, 32) == 1 then Functions.common_loot_crate(entity.surface, entity.position) return end
	if math_random(1, 128) == 1 then Functions.uncommon_loot_crate(entity.surface, entity.position) return end
	if math_random(1, 512) == 1 then Functions.rare_loot_crate(entity.surface, entity.position) return end
	if math_random(1, 1024) == 1 then Functions.epic_loot_crate(entity.surface, entity.position) return end
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "simple-entity" then
		mining_events(entity)
	end
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end	
	if entity.type == "unit-spawner" then
		spawner_death(entity)
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
	local force = game.create_force("dungeon")
	force.set_friend("enemy", false)
	force.set_friend("player", false)

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
	
	surface.request_to_generate_chunks({0,0}, 8)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.30
	
	local surface = game.surfaces[1]
	local map_gen_settings = surface.map_gen_settings
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	surface.map_gen_settings = map_gen_settings
	for chunk in surface.get_chunks() do		
		surface.delete_chunk({chunk.x, chunk.y})		
	end
	
	game.forces.player.manual_mining_speed_modifier = 0.5
	
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 0
	
	global.dungeons = {}
	global.dungeons.depth = 0
	global.dungeons.spawner_tier = {}
	
	global.rocks_yield_ore_base_amount = 100
	global.rocks_yield_ore_distance_modifier = 0.001
	
	local T = MapInfo.Pop_info()
	T.localised_category = "dungeons"
	T.main_caption_color = {r = 0, g = 0, b = 0}
	T.sub_caption_color = {r = 150, g = 0, b = 20}
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