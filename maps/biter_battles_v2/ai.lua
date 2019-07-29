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

function set_biter_raffle_table(surface, biter_force_name)
	
	local biters = surface.find_entities_filtered({type = "unit", force = biter_force_name})
	if not biters[1] then return end	
	for _, e in pairs(biters) do
		if math_random(1,3) == 1 then
			global.biter_raffle[biter_force_name][#global.biter_raffle[biter_force_name] + 1] = e.name
		end
	end				
end

local function get_threat_ratio(biter_force_name)
	if global.bb_threat[biter_force_name] <= 0 then return 0 end
	local t1 = global.bb_threat["north_biters"]
	local t2 = global.bb_threat["south_biters"]
	if t1 == 0 and t2 == 0 then return 0.5 end
	if t1 < 0 then t1 = 0 end
	if t2 < 0 then t2 = 0 end
	local total_threat = t1 + t2
	local ratio = global.bb_threat[biter_force_name] / total_threat
	return ratio
end

local function is_biter_inactive(biter, unit_number, biter_force_name)
	if not biter.entity.valid then return true end	
	if game.tick - biter.active_since < bb_config.biter_timeout then return false end	
	if biter.entity.surface.count_entities_filtered({area = {{biter.entity.position.x - 16, biter.entity.position.y - 16},{biter.entity.position.x + 16, biter.entity.position.y + 16}}, force = {"north", "south"}}) ~= 0 then
		global.active_biters[biter_force_name][unit_number].active_since = game.tick
		return false 
	end		
	if global.bb_debug then game.print(biter_force_name .. " unit " .. unit_number .. " timed out at tick age " .. game.tick - biter.active_since) end	
	biter.entity.destroy()
	return true
end

ai.destroy_old_age_biters = function()
	local surface = game.surfaces["biter_battles"]
	for _, e in pairs(surface.find_entities_filtered({type = "unit"})) do
		if not e.unit_group then
			if math_random(1,8) == 1 then e.destroy() end
		end
	end
end

ai.destroy_inactive_biters = function()	
	for _, biter_force_name in pairs({"north_biters", "south_biters"}) do
		for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
			if is_biter_inactive(biter, unit_number, biter_force_name) then
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
		unit_count = 16,
		force = "north_biters",
		unit_search_distance=128
		})
		
	game.surfaces["biter_battles"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["south"],
			distraction=defines.distraction.none
			},
		unit_count = 16,
		force = "south_biters",
		unit_search_distance=128
		})
end

local function get_random_close_spawner(surface, biter_force_name)
	local spawners = surface.find_entities_filtered({type = "unit-spawner", force = biter_force_name})	
	if not spawners[1] then return false end
	
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, 5, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if spawner_2.position.x ^ 2 + spawner_2.position.y ^ 2 < spawner.position.x ^ 2 + spawner.position.y ^ 2 then spawner = spawner_2 end	
	end	
	
	return spawner
end

local function select_units_around_spawner(spawner, force_name, biter_force_name)
	local biters = spawner.surface.find_enemy_units(spawner.position, 160, force_name)
	if not biters[1] then return false end
	local valid_biters = {}
	
	local threat = global.bb_threat[biter_force_name] * math_random(11,22) * 0.01
	
	local unit_count = 0
	local max_unit_count = math.ceil(global.bb_threat[biter_force_name] * 0.25) + math_random(6,12)
	if max_unit_count > bb_config.max_group_size then max_unit_count = bb_config.max_group_size end
	
	for _, biter in pairs(biters) do
		if unit_count >= max_unit_count then break end
		if biter.force.name == biter_force_name and global.active_biters[biter.force.name][biter.unit_number] == nil then
			valid_biters[#valid_biters + 1] = biter
			global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
			unit_count = unit_count + 1
			threat = threat - threat_values[biter.name]
		end	
		if threat < 0 then break end
	end
	
	--Manual spawning of additional units
	for c = 1, max_unit_count - unit_count, 1 do
		if threat < 0 then break end
		local biter_name = global.biter_raffle[biter_force_name][math_random(1, #global.biter_raffle[biter_force_name])]
		local position = spawner.surface.find_non_colliding_position(biter_name, spawner.position, 128, 2)
		if not position then break end
		
		local biter = spawner.surface.create_entity({name = biter_name, force = biter_force_name, position = position})
		threat = threat - threat_values[biter.name]
		
		valid_biters[#valid_biters + 1] = biter
		global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
	end
	
	if global.bb_debug then game.print(get_active_biter_count(biter_force_name) .. " active units for " .. biter_force_name) end
	
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

local function is_chunk_empty(surface, area)
	if surface.count_entities_filtered({type = {"unit-spawner", "unit"}, area = area}) ~= 0 then return false end
	if surface.count_entities_filtered({force = {"north", "south"}, area = area}) ~= 0 then return false end
	if surface.count_tiles_filtered({name = {"water", "deepwater"}, area = area}) ~= 0 then return false end
	return true
end

local function get_unit_group_position(surface, nearest_player_unit, spawner)
	
	if math_random(1,3) ~= 1 then
		local spawner_chunk_position = {x = math.floor(spawner.position.x / 32), y = math.floor(spawner.position.y / 32)}
		local valid_chunks = {}
		for x = -2, 2, 1 do
			for y = -2, 2, 1 do
				local chunk = {x = spawner_chunk_position.x + x, y = spawner_chunk_position.y + y}
				local area = {{chunk.x * 32, chunk.y * 32},{chunk.x * 32 + 32, chunk.y * 32 + 32}}
				if is_chunk_empty(surface, area) then
					valid_chunks[#valid_chunks + 1] = chunk
				end
			end
		end
		
		if #valid_chunks > 0 then
			local chunk = valid_chunks[math_random(1, #valid_chunks)]
			return {x = chunk.x * 32 + 16, y = chunk.y * 32 + 16}
		end
	end
	
	local unit_group_position = {x = (spawner.position.x + nearest_player_unit.position.x) * 0.5, y = (spawner.position.y + nearest_player_unit.position.y) * 0.5}
	local pos = surface.find_non_colliding_position("rocket-silo", unit_group_position, 256, 1)
	if pos then unit_group_position = pos end
	
	if not unit_group_position then
		if global.bb_debug then game.print("No unit_group_position found for team " .. force_name) end
		return false 
	end
	
	return unit_group_position
end

local function create_attack_group(surface, force_name, biter_force_name)
	if global.bb_threat[biter_force_name] <= 0 then return false end
	
	if bb_config.max_active_biters - get_active_biter_count(biter_force_name) < bb_config.max_group_size then
		if global.bb_debug then game.print("Not enough slots for biters for team " .. force_name .. ". Available slots: " .. bb_config.max_active_biters - get_active_biter_count(biter_force_name)) end
		return false 
	end	
	
	local spawner = get_random_close_spawner(surface, biter_force_name)
	if not spawner then
		if global.bb_debug then game.print("No spawner found for team " .. force_name) end
		return false 
	end
	
	local nearest_player_unit = surface.find_nearest_enemy({position = spawner.position, max_distance = 2048, force = biter_force_name})
	if not nearest_player_unit then nearest_player_unit = global.rocket_silo[force_name] end
	
	local unit_group_position = get_unit_group_position(surface, nearest_player_unit, spawner)
	
	local units = select_units_around_spawner(spawner, force_name, biter_force_name)
	if not units then return false end
	local unit_group = surface.create_unit_group({position = unit_group_position, force = biter_force_name})
	for _, unit in pairs(units) do unit_group.add_member(unit) end
	send_group(unit_group, force_name, nearest_player_unit)
end

ai.main_attack = function()
	local surface = game.surfaces["biter_battles"]
	local force_name = global.next_attack
	local biter_force_name = force_name .. "_biters"
	local wave_amount = math.ceil(get_threat_ratio(biter_force_name) * 7)
	
	set_biter_raffle_table(surface, biter_force_name)
	
	for c = 1, wave_amount, 1 do		
		create_attack_group(surface, force_name, biter_force_name)
	end
	if global.bb_debug then game.print(wave_amount .. " unit groups designated for " .. force_name .. " biters.") end
	
	if global.next_attack == "north" then
		global.next_attack = "south"
	else
		global.next_attack = "north"
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