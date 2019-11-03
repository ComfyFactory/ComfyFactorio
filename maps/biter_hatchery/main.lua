require "modules.no_turrets"
local RPG = require "modules.rpg"
local unit_raffle = require "maps.biter_hatchery.raffle_tables"
local map_functions = require "tools.map_functions"
local Terrain = require "maps.biter_hatchery.terrain"
local Reset = require "functions.soft_reset"
local Map = require "modules.map_info"
local math_random = math.random
local Public = {}
local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16}

local function draw_spawn_ores(surface)
	local x = global.map_forces.west.hatchery.position.x - 64
	map_functions.draw_smoothed_out_ore_circle({x = x, y = 32}, "iron-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle({x = x, y = -32}, "copper-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle({x = x, y = 0}, "coal", surface, 15, 1500)
	
	local x = global.map_forces.east.hatchery.position.x + 64
	map_functions.draw_smoothed_out_ore_circle({x = x, y = 32}, "copper-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle({x = x, y = -32}, "iron-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle({x = x, y = 0}, "coal", surface, 15, 1500)
end

function Public.reset_map()
	local map_gen_settings = {}
	map_gen_settings.seed = math_random(1, 10000000)
	map_gen_settings.height = 192
	map_gen_settings.water = 0.2
	map_gen_settings.starting_area = 1
	map_gen_settings.terrain_segmentation = 10
	map_gen_settings.cliff_settings = {cliff_elevation_interval = math.random(16, 48), cliff_elevation_0 = math.random(16, 48)}	
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 100, size = 0.5, richness = 0.5,},
		["stone"] = {frequency = 100, size = 0.5, richness = 0.5,},
		["copper-ore"] = {frequency = 100, size = 0.5, richness = 0.5,},
		["iron-ore"] = {frequency = 100, size = 0.5, richness = 0.5,},
		["uranium-ore"] = {frequency = 50, size = 0.5, richness = 0.5,},
		["crude-oil"] = {frequency = 50, size = 0.5, richness = 0.5,},
		["trees"] = {frequency = math.random(5, 10) * 0.1, size = math.random(5, 10) * 0.1, richness = math.random(3, 10) * 0.1},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}	
	}
	
	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("biter_hatchery", map_gen_settings).index
		game.forces.west.set_spawn_position({-128, 0}, game.surfaces[global.active_surface_index])
		game.forces.east.set_spawn_position({128, 0}, game.surfaces[global.active_surface_index])
	else
		game.forces.west.set_spawn_position({-128, 0}, game.surfaces[global.active_surface_index])
		game.forces.east.set_spawn_position({128, 0}, game.surfaces[global.active_surface_index])	
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], map_gen_settings, starting_items).index
	end
	
	game.surfaces[global.active_surface_index].request_to_generate_chunks({0,0}, 10)
	game.surfaces[global.active_surface_index].force_generate_chunk_requests()
	
	for key, _ in pairs(global.map_forces) do
		game.forces[key].technologies["artillery"].enabled = false
		game.forces[key].technologies["artillery-shell-range-1"].enabled = false					
		game.forces[key].technologies["artillery-shell-speed-1"].enabled = false	
	end
		
	local e = game.surfaces[global.active_surface_index].create_entity({name = "biter-spawner", position = {-128, 0}, force = "west"})
	e.active = false
	global.map_forces.west.hatchery = e
	global.map_forces.east.target = e
	
	local e = game.surfaces[global.active_surface_index].create_entity({name = "biter-spawner", position = {128, 0}, force = "east"})
	e.active = false
	global.map_forces.east.hatchery = e
	global.map_forces.west.target = e
	
	draw_spawn_ores(game.surfaces[global.active_surface_index])
	
	RPG.rpg_reset_all_players()
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

local border_teleport = {
	["east"] = 2,
	["west"] = -2,
}

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if player.position.x >= -4 and player.position.x <= 4 then
		if player.character.driving then player.character.driving = false end
		player.teleport({player.position.x + border_teleport[player.force.name], player.position.y}, game.surfaces[global.active_surface_index])
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
	
	if game.tick % 240 == 0 then
		local area = {{-256, -96}, {255, 96}}
		game.forces.west.chart(game.surfaces[global.active_surface_index], area)
		game.forces.east.chart(game.surfaces[global.active_surface_index], area)
	end
end

--Construction Robot Restriction
local robot_build_restriction = {
	["east"] = function(x)
		if x < 0 then return true end
	end,
	["west"] = function(x)
		if x > 0 then return true end
	end
}

local function on_robot_built_entity(event)
	if not robot_build_restriction[event.robot.force.name] then return end
	if not robot_build_restriction[event.robot.force.name](event.created_entity.position.x) then return end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	game.print("Team " .. event.robot.force.name .. "'s construction drone had an accident.", {r = 200, g = 50, b = 100})
	event.created_entity.destroy()
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
	
	local T = Map.Pop_info()
	T.main_caption = "Biter Hatchery"
	T.sub_caption =  "..nibble nibble nom nom.."
	T.text = table.concat({
		"Defeat the enemy teams nest.\n",
		"Feed your hatchery science flasks to breed biters!\n",
		"They will soon after swarm to the opposing teams nest!,\n",
		"\n",
		"Lay transport belts to your hatchery and they will happily nom the juice off the conveyor.\n",
		"Higher tier flasks will breed stronger biters!\n",
		"\n",
		"Turrets are disabled.\n",
		"The center river may not be crossed.\n",
		"Construction robots may not build over the river.\n",
	})
	T.main_caption_color = {r = 150, g = 0, b = 255}
	T.sub_caption_color = {r = 0, g = 250, b = 150}
	
	for key, _ in pairs(global.map_forces) do game.create_force(key) end
	Public.reset_map()
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(60, tick)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_changed_position, on_player_changed_position)