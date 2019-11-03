local unit_raffle = require "maps.biter_hatchery.raffle_tables"
local Terrain = require "maps.biter_hatchery.terrain"
local Reset = require "functions.soft_reset"
local math_random = math.random
local Public = {}
local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16}

function Public.reset_map()
	local map_gen_settings = {}
	map_gen_settings.seed = math_random(1, 10000000)
	map_gen_settings.height = 160
	map_gen_settings.water = math.random(30, 40) * 0.01
	map_gen_settings.starting_area = 2.5
	map_gen_settings.terrain_segmentation = math.random(30, 40) * 0.1	
	map_gen_settings.cliff_settings = {cliff_elevation_interval = math.random(16, 48), cliff_elevation_0 = math.random(16, 48)}	
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = math.random(20, 40) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(5, 15) * 0.1},
		["stone"] = {frequency = math.random(20, 40) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(5, 15) * 0.1},
		["copper-ore"] = {frequency = math.random(20, 40) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(5, 15) * 0.1},
		["iron-ore"] = {frequency = math.random(20, 40) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(5, 15) * 0.1},
		["uranium-ore"] = {frequency = math.random(20, 40) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(5, 15) * 0.1},
		["crude-oil"] = {frequency = math.random(25, 50) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(10, 20) * 0.1},
		["trees"] = {frequency = math.random(5, 25) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(3, 10) * 0.1},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}	
	}
	
	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("biter_hatchery", map_gen_settings).index
		game.forces.west.set_spawn_position({-64, 0}, game.surfaces[global.active_surface_index])
		game.forces.east.set_spawn_position({64, 0}, game.surfaces[global.active_surface_index])
	else
		game.forces.west.set_spawn_position({-64, 0}, game.surfaces[global.active_surface_index])
		game.forces.east.set_spawn_position({64, 0}, game.surfaces[global.active_surface_index])	
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], map_gen_settings, starting_items).index
	end
	
	game.surfaces[global.active_surface_index].request_to_generate_chunks({0,0}, 8)
	game.surfaces[global.active_surface_index].force_generate_chunk_requests()
	
	local e = game.surfaces[global.active_surface_index].create_entity({name = "biter-spawner", position = {-64, 0}, force = "west"})
	e.active = false
	global.map_forces.west.hatchery = e
	global.map_forces.east.target = e
	
	local e = game.surfaces[global.active_surface_index].create_entity({name = "biter-spawner", position = {64, 0}, force = "east"})
	e.active = false
	global.map_forces.east.hatchery = e
	global.map_forces.west.target = e
end

local function spawn_units(belt, food_item, removed_item_count)
	local count = unit_raffle[food_item][2]
	local raffle = unit_raffle[food_item][1]
	for _ = 1, count, 1 do
		local unit = belt.surface.create_entity({name = raffle[math_random(1, #raffle)], position = belt.position, force = belt.force})
		unit.ai_settings.allow_destroy_when_commands_fail = false
		unit.ai_settings.allow_try_return_to_spawner = false
	end
end

local function get_belts(spawner)
	local belts = spawner.surface.find_entities_filtered({
			type = "transport-belt",
			area = {{spawner.position.x - 5, spawner.position.y - 3},{spawner.position.x + 4, spawner.position.y + 3}},
			force = spawner.force,
		})
	return belts
end

local function eat_food_from_belt(belt)
	for i = 1, 2, 1 do
		local line = belt.get_transport_line(i)
		for food_item, raffle in pairs(unit_raffle) do
			local removed_item_count = line.remove_item({name = food_item, count = 8})
			if removed_item_count > 0 then
				spawn_units(belt, food_item, removed_item_count)
			end
		end
	end	
end

local function nom()
	local surface = game.surfaces[global.active_surface_index]
	for key, force in pairs(global.map_forces) do
		local belts = get_belts(force.hatchery)
		for _, belt in pairs(belts) do
			eat_food_from_belt(belt)
		end
	end
end

local function send_unit_groups()
	local surface = game.surfaces[global.active_surface_index]
	for key, force in pairs(global.map_forces) do
		local units = {}
		for _, unit in pairs(surface.find_entities_filtered({type = "unit", force = key})) do
			if not unit.unit_group then
				units[#units + 1] = unit
			end
		end
		if #units > 0 then
			local unit_group = surface.create_unit_group({position = force.hatchery.position, force = key})
			for _, unit in pairs(units) do unit_group.add_member(unit) end
			unit_group.set_command({
				type = defines.command.compound,
				structure_type = defines.compound_command.return_last,
				commands = {
					{
						type = defines.command.attack_area,
						destination = {x = force.target.position.x, y = force.target.position.y},
						radius = 8,
						distraction = defines.distraction.by_enemy
					},
					{
						type = defines.command.attack,
						target = force.target,
						distraction = defines.distraction.by_enemy,
					},			
				}
			})
		end
	end
end

local function on_entity_died(event)
	if not event.entity.valid then	return end
	if event.entity.type ~= "unit-spawner" then return end

	if event.entity.force.name == "east" then
		game.print("East lost their Hatchery.", {100, 100, 100})
		game.print(">>>> West team has won the game!!! <<<<", {255, 110, 22})
	else
		game.print("West lost their Hatchery.", {100, 100, 100})
		game.print(">>>> East team has won the game!!! <<<<", {255, 110, 22})
	end

	global.game_reset_tick = game.tick + 1800
	
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/game_won", volume_modifier=0.85}
	end		
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces[global.active_surface_index]
	
	if player.surface.index ~= global.active_surface_index then
		local force
		if math_random(1, 2) == 1 then
			force = game.forces.east 
		else
			force = game.forces.west 
		end
		player.force = force
		if player.character then
			if player.character.valid then
				player.character.destroy()
			end
		end		
		player.character = nil
		player.set_controller({type=defines.controllers.god})
		player.create_character()
		player.teleport(surface.find_non_colliding_position("character", force.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end
end

local function tick()	
	local t2 = game.tick % 900
	if t2 == 0 then send_unit_groups() end
	
	if global.game_reset_tick then
		if global.game_reset_tick < game.tick then
			global.game_reset_tick = nil
			Public.reset_map()
		end
		return
	end
	
	nom()
end

local function on_init()
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0	
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = false
	game.map_settings.pollution.enabled = false
	global.map_forces = {
		["west"] = {},
		["east"] = {},
	}
	for key, _ in pairs(global.map_forces) do game.create_force(key) end
	Public.reset_map()
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(60, tick)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)