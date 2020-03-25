local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local math_sqrt = math.sqrt
local math_round = math.round
local math_abs = math.abs

local drop_values = {
	["small-spitter"] = 8,
	["small-biter"] = 8,
	["medium-spitter"] = 16,
	["medium-biter"] = 16,
	["big-spitter"] = 32,
	["big-biter"] = 32,
	["behemoth-spitter"] = 96,
	["behemoth-biter"] = 96,
	["small-worm-turret"] = 128,
	["medium-worm-turret"] = 160,
	["big-worm-turret"] = 196,
	["behemoth-worm-turret"] = 256,
	["biter-spawner"] = 640,
	["spitter-spawner"] = 640
}
local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32}

local drop_raffle = {}
for _ = 1, 32, 1 do table_insert(drop_raffle, "iron-ore") end
for _ = 1, 24, 1 do table_insert(drop_raffle, "copper-ore") end
for _ = 1, 16, 1 do table_insert(drop_raffle, "stone") end
for _ = 1, 16, 1 do table_insert(drop_raffle, "coal") end
for _ = 1, 1, 1 do table_insert(drop_raffle, "uranium-ore") end
for _ = 1, 4, 1 do table_insert(drop_raffle, "wood") end
local size_of_drop_raffle = #drop_raffle

local drop_vectors = {}
for x = -2, 2, 0.1 do
	for y = -2, 2, 0.1 do
		table_insert(drop_vectors, {x, y})
	end
end
local size_of_drop_vectors = #drop_vectors

local function on_player_joined_game(event)
	local surface = game.surfaces["railway_troopers"]
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.type == "unit" and entity.spawner then
		entity.spawner.damage(20, game.forces[1])
	end	
	
	if not drop_values[entity.name] then return end	
	table_insert(global.drop_schedule, {{entity.position.x, entity.position.y}, drop_values[entity.name]})
end

local function draw_west_side(surface, left_top)	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {left_top.x + x, left_top.y + y}
			surface.set_tiles({{name = "deepwater-green", position = position}}, true)
			if math_random(1, 256) == 1 then surface.create_entity({name = "fish", position = position}) end
		end
	end
	
	if math_random(1, 8) == 1 then
		surface.create_entity({name = "crude-oil", position = {left_top.x + math_random(0, 31), left_top.y + math_random(0, 31)}, amount = 100000 + math_abs(left_top.x * 250)})
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	
	if left_top.x < -32 then
		draw_west_side(surface, left_top)
		return
	end
	
	if left_top.y == 0 then
		for x = 0, 30, 2 do
			surface.create_entity({name = "straight-rail", position = {left_top.x + x, 0}, direction = 2, force = "player"})
		end
	end
end

local type_whitelist = {
	["artillery-wagon"] = true,
	["car"] = true,
	["cargo-wagon"] = true,
	["construction-robot"] = true,
	["entity-ghost"] = true,
	["fluid-wagon"] = true,
	["heat-pipe"] = true,
	["locomotive"] = true,
	["logistic-robot"] = true,
	["rail-chain-signal"] = true,
	["rail-signal"] = true,
	["straight-rail"] = true,
	["train-stop"] = true,	
	["transport-belt"] = true,
	["splitter"] = true,
	["container"] = true,
	["inserter"] = true,
	["underground-belt"] = true,
}

local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	
	if type_whitelist[event.created_entity.type] then return end

	if entity.position.x < -32 then return end

	if event.player_index then
		game.players[event.player_index].insert({name = entity.name, count = 1})		
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})													
	end
	
	event.created_entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Can only be built west!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	entity.destroy()
end

local function on_built_entity(event)
	deny_building(event)
end

local function on_robot_built_entity(event)
	deny_building(event)
end

local function drop_loot()
end

local function drop_schedule()
	local surface = game.surfaces["railway_troopers"]
	for key, entry in pairs(global.drop_schedule) do
		for _ = 1, 3, 1 do
			local vector = drop_vectors[math_random(1, size_of_drop_vectors)]
			surface.spill_item_stack({entry[1][1] + vector[1], entry[1][2] + vector[2]}, {name = drop_raffle[math_random(1, size_of_drop_raffle)], count = 1}, true)		
			global.drop_schedule[key][2] = global.drop_schedule[key][2] - 1
			if global.drop_schedule[key][2] <= 0 then
				table_remove(global.drop_schedule, key)
				break
			end
		end
	end
end

local function on_tick()
	drop_schedule()
end

local function on_init()
	global.drop_schedule = {}

	game.map_settings.enemy_evolution.destroy_factor = 0.001
	game.map_settings.enemy_evolution.pollution_factor = 0	
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 1800
	game.map_settings.enemy_expansion.min_expansion_cooldown = 1800
	game.map_settings.enemy_expansion.settler_group_max_size = 32
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	
	local map_gen_settings = {
		["height"] = 196,
		["water"] = 0.1,
		["starting_area"] = 0.60,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["autoplace_controls"] = {
			["coal"] = {frequency = 0, size = 0.65, richness = 0.5},
			["stone"] = {frequency = 0, size = 0.65, richness = 0.5},
			["copper-ore"] = {frequency = 0, size = 0.65, richness = 0.5},
			["iron-ore"] = {frequency = 0, size = 0.65, richness = 0.5},
			["uranium-ore"] = {frequency = 0, size = 1, richness = 1},
			["crude-oil"] = {frequency = 0, size = 1, richness = 0.75},
			["trees"] = {frequency = 4, size = 0.5, richness = 1},
			["enemy-base"] = {frequency = 256, size = 2, richness = 1},
		},
	}
	
	local surface = game.create_surface("railway_troopers", map_gen_settings)
	surface.request_to_generate_chunks({0,0}, 2)
	surface.force_generate_chunk_requests()
	
	game.forces.player.set_spawn_position({0, 0}, surface)	
	
	game.forces["player"].technologies["landfill"].researched = true
	game.forces["player"].technologies["railway"].researched = true
	game.forces["player"].technologies["engine"].researched = true
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)