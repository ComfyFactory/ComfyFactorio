local unit_raffle = require "maps.biter_hatchery.raffle_tables"
local math_random = math.random

local function spawn_units(belt, food_item, removed_item_count)
	local count = unit_raffle[food_item][2]
	local raffle = unit_raffle[food_item][1]
	for _ = 1, count, 1 do
		belt.surface.create_entity({name = raffle[math_random(1, #raffle)], position = belt.position, force = belt.force})
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
	local surface = game.surfaces[1]
	for key, force in pairs(global.map_forces) do
		local belts = get_belts(force.hatchery)
		for _, belt in pairs(belts) do
			eat_food_from_belt(belt)
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	player.force = game.forces.east
end

local tick_tasks = {
	[0] = nom,
}

local function tick()
	local t = game.tick % 60
	if tick_tasks[t] then tick_tasks[t]() end
end

local function on_init()
	global.map_forces = {
		["west"] = {},
		["east"] = {},
	}

	for key, _ in pairs(global.map_forces) do game.create_force(key) end
	
	local surface = game.surfaces[1]
	game.forces.west.set_spawn_position({-64, 0}, game.surfaces[1])
	game.forces.east.set_spawn_position({64, 0}, game.surfaces[1])
		
	unit_spawners = {}
	
	local e = game.surfaces[1].create_entity({name = "biter-spawner", position = {-64, 0}, force = "west"})
	e.active = false
	global.map_forces.west.hatchery = e
	global.map_forces.east.target = e
	
	local e = game.surfaces[1].create_entity({name = "biter-spawner", position = {64, 0}, force = "east"})
	e.active = false
	global.map_forces.east.hatchery = e
	global.map_forces.west.target = e	
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(60, tick)
event.add(defines.events.on_player_joined_game, on_player_joined_game)