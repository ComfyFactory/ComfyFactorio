local event = require 'utils.event' 
local math_random = math.random
local ai = {}

local threat_values = {
	["small-spitter"] = 1,
	["small-biter"] = 1,
	["medium-spitter"] = 4,
	["medium-biter"] = 4,
	["big-spitter"] = 8,
	["big-biter"] = 8,
	["behemoth-spitter"] = 16,
	["behemoth-biter"] = 16
}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

ai.send_near_biters_to_silo = function()
	if game.tick < 108000 then return end
	if not global.rocket_silo["north"] then return end
	if not global.rocket_silo["south"] then return end
	
	game.surfaces["biter_battles"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["north"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "north_biters",
		unit_search_distance=128
		})
		
	game.surfaces["biter_battles"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["south"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "south_biters",
		unit_search_distance=128
		})
end

local function get_random_close_spawner(surface, biter_force_name)
	local spawners = surface.find_entities_filtered({type = "unit-spawner", force = biter_force_name})	
	if not spawners[1] then return false end	
	spawners = shuffle(spawners)
	local spawner = spawners[1]	
	for i = 2, 4, 1 do
		if not spawners[i] then return spawner end
		if spawners[i].position.x ^ 2 + spawners[i].position.y ^ 2 < spawner.position.x ^ 2 + spawner.position.y ^ 2 then spawner = spawners[i] end
	end	
	return spawner
end

local function select_units_around_spawner(spawner, force_name, biter_force_name)
	local biters = spawner.surface.find_enemy_units(spawner.position, 128, force_name)
	if not biters[1] then return false end
	local valid_biters = {}
	local size = math_random(2, 6) * 0.1
	local threat = global.bb_threat[biter_force_name] * size
	for _, biter in pairs(biters) do
		if biter.force.name == biter_force_name then
			valid_biters[#valid_biters + 1] = biter 
			threat = threat - threat_values[biter.name]
		end
		if threat < 0 then break end
	end
	return valid_biters
end

local function send_group(unit_group, force_name, nearest_player_unit)
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = nearest_player_unit.position,
				radius = 32,
				distraction=defines.distraction.by_enemy
			},									
			{
				type = defines.command.attack,
				target = global.rocket_silo[force_name],
				distraction = defines.distraction.by_enemy
			}
		}
	})
	return true
end

local function create_attack_group(surface, force_name, biter_force_name)
	if global.bb_threat[biter_force_name] <= 0 then return false end
	local spawner = get_random_close_spawner(surface, biter_force_name)
	if not spawner then return false end --game.print("no unit-spawner for " .. biter_force_name)
	local nearest_player_unit = surface.find_nearest_enemy({position = spawner.position, max_distance = 2048, force = biter_force_name})
	if not nearest_player_unit then nearest_player_unit = global.rocket_silo[force_name] end
	local unit_group_position = {x = (spawner.position.x + nearest_player_unit.position.x) * 0.5, y = (spawner.position.y + nearest_player_unit.position.y) * 0.5}
	local pos = surface.find_non_colliding_position("rocket-silo", unit_group_position, 128, 1)
	if pos then unit_group_position = pos end
	local units = select_units_around_spawner(spawner, force_name, biter_force_name)
	if not units then return false end
	local unit_group = surface.create_unit_group({position = unit_group_position, force = biter_force_name})
	for _, unit in pairs(units) do unit_group.add_member(unit) end
	send_group(unit_group, force_name, nearest_player_unit)
end

ai.main_attack = function()	
	local surface = game.surfaces["biter_battles"]
	for _, force_name in pairs({"north", "south"}) do
		create_attack_group(surface, force_name, force_name .. "_biters")
	end
end

--Biter Evasion
local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if event.entity.type ~= "unit" then return end
	if global.bb_evasion[event.entity.force.name] < math_random(1,1000) then return end
	event.entity.health = event.entity.health + event.final_damage_amount	
end

--Biter Threat Value Substraction
local function on_entity_died(event)
	if not event.entity.valid then return end
	if threat_values[event.entity.name] then
		global.bb_threat[event.entity.force.name] = global.bb_threat[event.entity.force.name] - threat_values[event.entity.name]
		return
	end	
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)

return ai