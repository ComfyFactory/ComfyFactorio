local Public = {}
local bb_config = require "maps.biter_battles_v2.config"
local math_random = math.random

local vector_radius = 360
local attack_vectors = {}
attack_vectors.north = {}
attack_vectors.south = {}
for x = vector_radius * -1, vector_radius, 1 do
	for y = 0, vector_radius, 1 do
		local r = math.sqrt(x ^ 2 + y ^ 2)
		if r < vector_radius and r > vector_radius - 1 then
			attack_vectors.north[#attack_vectors.north + 1] = {x, y * -1}
			attack_vectors.south[#attack_vectors.south + 1] = {x, y}
		end
	end
end
local size_of_vectors = #attack_vectors.north

local threat_values = {
	["small-spitter"] = 1.5,
	["small-biter"] = 1.5,
	["medium-spitter"] = 4,
	["medium-biter"] = 4,
	["big-spitter"] = 12,
	["big-biter"] = 12,
	["behemoth-spitter"] = 32,
	["behemoth-biter"] = 32,
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

local function set_biter_raffle_table(surface, biter_force_name)
	local biters = surface.find_entities_filtered({type = "unit", force = biter_force_name})
	if not biters[1] then return end
	global.biter_raffle[biter_force_name] = {}
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
	if not biter.entity.unit_group then return true end	
	if not biter.entity.unit_group.valid then return true end	
	if game.tick - biter.active_since < bb_config.biter_timeout then return false end	
	if biter.entity.surface.count_entities_filtered({area = {{biter.entity.position.x - 16, biter.entity.position.y - 16},{biter.entity.position.x + 16, biter.entity.position.y + 16}}, force = {"north", "south"}}) ~= 0 then
		global.active_biters[biter_force_name][unit_number].active_since = game.tick
		return false 
	end		
	if global.bb_debug then game.print(biter_force_name .. " unit " .. unit_number .. " timed out at tick age " .. game.tick - biter.active_since) end	
	biter.entity.destroy()
	return true
end

Public.destroy_inactive_biters = function()	
	for _, biter_force_name in pairs({"north_biters", "south_biters"}) do
		for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
			if is_biter_inactive(biter, unit_number, biter_force_name) then
				global.active_biters[biter_force_name][unit_number] = nil
			end
		end
	end
end

Public.send_near_biters_to_silo = function()
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
	
	local commands = {}
	
	local vector = attack_vectors[force_name][math_random(1, size_of_vectors)]
	local position = {target.x + vector[1], target.y + vector[2]}
	position = unit_group.surface.find_non_colliding_position("stone-furnace", position, 96, 1)
	if position then
		if math.abs(position.y) < math.abs(unit_group.position.y) then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = position,
				radius = 24,
				distraction = defines.distraction.by_enemy
			}
		end
	end
	
	commands[#commands + 1] = {
		type = defines.command.attack_area,
		destination = target,
		radius = 32,
		distraction = defines.distraction.by_enemy
	}
	
	commands[#commands + 1] = {
		type = defines.command.attack,
		target = global.rocket_silo[force_name],
		distraction = defines.distraction.by_enemy
	}
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = commands
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

local function get_active_threat(biter_force_name)
	local active_threat = 0
	for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
		if biter.entity then 
			if biter.entity.valid then 
				active_threat = active_threat + threat_values[biter.entity.name]
			end
		end
	end
	return active_threat
end

local function create_attack_group(surface, force_name, biter_force_name)
	local threat = global.bb_threat[biter_force_name]	
	if get_active_threat(biter_force_name) > threat * 1.20 then return end
	if threat <= 0 then return false end
	
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

Public.main_attack = function()
	local surface = game.surfaces["biter_battles"]
	local force_name = global.next_attack
	
	if not global.training_mode or (global.training_mode and #game.forces[force_name].connected_players > 0) then
		local biter_force_name = force_name .. "_biters"
		local wave_amount = math.ceil(get_threat_ratio(biter_force_name) * 7)
		
		set_biter_raffle_table(surface, biter_force_name)
		
		for c = 1, wave_amount, 1 do		
			create_attack_group(surface, force_name, biter_force_name)
		end
		if global.bb_debug then game.print(wave_amount .. " unit groups designated for " .. force_name .. " biters.") end
	end
	
	if global.next_attack == "north" then
		global.next_attack = "south"
	else
		global.next_attack = "north"
	end	
end

Public.wake_up_sleepy_groups = function()
	local force_name = global.next_attack
	local biter_force_name = force_name .. "_biters"
	local entity
	local unit_group	
	for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
		entity = biter.entity
		if entity then 
			if entity.valid then
				unit_group = entity.unit_group
				if unit_group then
					if unit_group.valid then
						if unit_group.state == defines.group_state.finished then
							local nearest_player_unit = entity.surface.find_nearest_enemy({position = entity.position, max_distance = 2048, force = biter_force_name})
							if not nearest_player_unit then nearest_player_unit = global.rocket_silo[force_name] end
							send_group(unit_group, force_name, nearest_player_unit)
							print("BiterBattles: Woke up Unit Group at x" .. unit_group.position.x .. " y" .. unit_group.position.y .. ".")
						end
					end
				end
			end
		end
	end
end

Public.raise_evo = function()
	if global.freeze_players then return end
	if not global.training_mode and (#game.forces.north.connected_players == 0 or #game.forces.south.connected_players == 0) then return end
	local amount = math.ceil(global.difficulty_vote_value * global.evo_raise_counter)
	local biter_teams = {["north_biters"] = "north", ["south_biters"] = "south"}
	local a_team_has_players = false
	for bf, pf in pairs(biter_teams) do
		if #game.forces[pf].connected_players > 0 then
			set_evo_and_threat(amount, "automation-science-pack", bf)
			a_team_has_players = true
		end
	end
	if not a_team_has_players then return end
	global.evo_raise_counter = global.evo_raise_counter + (1 * 0.50)
end

--Biter Threat Value Substraction
function Public.subtract_threat(entity)
	if not threat_values[entity.name] then return end
	if entity.type == "unit" then
		global.active_biters[entity.force.name][entity.unit_number] = nil
	end
	global.bb_threat[entity.force.name] = global.bb_threat[entity.force.name] - threat_values[entity.name]
	return true
end

return Public