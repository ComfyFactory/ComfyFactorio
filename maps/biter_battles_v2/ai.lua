local event = require 'utils.event' 
local math_random = math.random
local ai = {}

local threat_values = {
	["small-spitter"] = 2,
	["small-biter"] = 2,
	["medium-spitter"] = 4,
	["medium-biter"] = 4,
	["big-spitter"] = 8,
	["big-biter"] = 8,
	["behemoth-spitter"] = 24,
	["behemoth-biter"] = 24,
	["small-worm-turret"] = 8,
	["medium-worm-turret"] = 12,
	["big-worm-turret"] = 16,
	["behemoth-worm-turret"] = 16,
	["biter-spawner"] = 16,
	["spitter-spawner"] = 16
}

local function get_active_biter_count(biter_force_name)
	local count = 0
	for _, biter in pairs(global.active_biters[biter_force_name]) do
		count = count + 1
	end
	return count
end

ai.destroy_inactive_biters = function()	
	for _, biter_force_name in pairs({"north_biters", "south_biters"}) do
		for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
			if game.tick - biter.active_since > bb_config.biter_timeout then
				--game.print(biter_force_name .. " unit " .. unit_number .. " timed out at tick age " .. game.tick - biter.active_since)			
				biter.entity.destroy()
				global.active_biters[biter_force_name][unit_number] = nil
			end
		end
	end
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
	
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, 4, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if spawner_2.position.x ^ 2 + spawner_2.position.y ^ 2 < spawner.position.x ^ 2 + spawner.position.y ^ 2 then spawner = spawner_2 end	
	end	
	
	return spawner
end

local function select_units_around_spawner(spawner, force_name, biter_force_name)
	local biters = spawner.surface.find_enemy_units(spawner.position, 320, force_name)
	if not biters[1] then return false end
	local valid_biters = {}
	local size = math_random(3, 6) * 0.1
	local threat = global.bb_threat[biter_force_name] * size
	local active_biter_count = get_active_biter_count(biter_force_name)
		
	for _, biter in pairs(biters) do
		if active_biter_count >= bb_config.max_active_biters then break end
		if biter.force.name == biter_force_name then
			valid_biters[#valid_biters + 1] = biter
			global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
			active_biter_count = active_biter_count + 1
			threat = threat - threat_values[biter.name]
		end	
		if threat < 0 then break end
	end
	
	--game.print(active_biter_count .. " active units for " .. biter_force_name)
	
	return valid_biters
end

local function send_group(unit_group, force_name, nearest_player_unit)
	local target = nearest_player_unit.position
	if math_random(1,2) == 1 then target = global.rocket_silo[force_name].position end
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = target,
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
	if not spawner then return false end
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
	for c = 1, math_random(1, 2), 1 do
		for _, force_name in pairs({"north", "south"}) do
			create_attack_group(surface, force_name, force_name .. "_biters")
		end
	end
end

--Prevent Players from damaging Rocket Silos
local function protect_silo(event)	
	if event.cause then
		if event.cause.type == "unit" then return end		 
	end
	if event.entity.name ~= "rocket-silo" then return end		
	event.entity.health = event.entity.health + event.final_damage_amount
end

--Prevent Players from doing direct pvp combat
local function ignore_pvp(event)	
	if not event.cause then return end
	if event.cause.force.name == "north" then
		if event.entity.force.name == "south" then
			if not event.entity.valid then return end
			event.entity.health = event.entity.health + event.final_damage_amount
			return
		end
	end
	if event.cause.force.name == "south" then
		if event.entity.force.name == "north" then
			if not event.entity.valid then return end
			event.entity.health = event.entity.health + event.final_damage_amount
			return
		end
	end
end

--Biter Evasion
local random_max = 10000

local function get_evade_chance(force_name)	
	return random_max - (random_max / global.bb_evasion[force_name])
end

local function evade(event)
	if not event.entity.valid then return end
	if not global.bb_evasion[event.entity.force.name] then return end	
	if event.final_damage_amount > event.entity.prototype.max_health * global.bb_evasion[event.entity.force.name] then return end
	if math_random(1, random_max) > get_evade_chance(event.entity.force.name) then return end
	event.entity.health = event.entity.health + event.final_damage_amount
end

local function on_entity_damaged(event)
	evade(event)
	protect_silo(event)
	--ignore_pvp(event)
end

--Biter Threat Value Substraction
local function on_entity_died(event)
	if not event.entity.valid then return end
	if not threat_values[event.entity.name] then return end
	if event.entity.type == "unit" then
		global.active_biters[event.entity.force.name][event.entity.unit_number] = nil
	end
	global.bb_threat[event.entity.force.name] = global.bb_threat[event.entity.force.name] - threat_values[event.entity.name]		
end

--Flamethrower Turret Nerf
local function on_research_finished(event)
	local research = event.research
	local force_name = research.force.name
	if research.name == "flamethrower" then
		if not global.flamethrower_damage then global.flamethrower_damage = {} end
		global.flamethrower_damage[force_name] = -0.6
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])						
	end
	
	if string.sub(research.name, 0, 18) == "refined-flammables" then
		global.flamethrower_damage[force_name] = global.flamethrower_damage[force_name] + 0.05
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])								
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])
	end	
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_research_finished, on_research_finished)

return ai