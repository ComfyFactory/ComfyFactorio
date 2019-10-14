require "modules.wave_defense.biter_rolls"
require "modules.wave_defense.threat_events"
local gui = require "modules.wave_defense.gui"
local threat_values = require "modules.wave_defense.threat_values"
local math_random = math.random
local side_target_types = {"accumulator", "assembling-machine", "beacon", "boiler", "container", "electric-pole", "furnace", "lamp", "lab",
 "logistic-container", "mining-drill", "container", "pump", "radar", "reactor", "roboport", "rocket-silo", "solar-panel", "storage-tank",}

local function debug_print(msg)
	if not global.wave_defense.debug then return end 
	print("WaveDefense: " .. msg) 
end

function is_unit_valid(biter)
	if not biter.entity then debug_print("is_unit_valid - unit destroyed - does no longer exist") return false end
	if not biter.entity.valid then debug_print("is_unit_valid - unit destroyed - invalid") return false end
	if not biter.entity.unit_group then debug_print("is_unit_valid - unit destroyed - no unitgroup") return false end
	if biter.spawn_tick + global.wave_defense.max_biter_age < game.tick then debug_print("is_unit_valid - unit destroyed - timed out") return false end
	return true
end

local function time_out_biters()
	debug_print("time_out_biters")
	for k, biter in pairs(global.wave_defense.active_units) do
		if not is_unit_valid(biter) then
			global.wave_defense.active_biter_count = global.wave_defense.active_biter_count - 1
			if biter.entity then
				if biter.entity.valid then
					global.wave_defense.threat = global.wave_defense.threat + threat_values[biter.entity.name]
					if biter.entity.force.index == 2 then
						biter.entity.destroy()
					end
				end
			end
			global.wave_defense.active_units[k] = nil
		end
	end
end

local function is_random_unit_valid(unit)
	if not unit then return false end
	if not unit.valid then return false end
	if unit.force.index ~= 2 then return false end
	return true
end

function wave_defense_get_random_unit()
	if #global.wave_defense.unit_raffle == 0 then return false end
	local unit = global.wave_defense.unit_raffle[math_random(1, #global.wave_defense.unit_raffle)]
	if is_random_unit_valid(unit) then return unit end

	for key, unit in pairs(global.wave_defense.unit_raffle) do
		if not is_random_unit_valid(unit) then
			global.wave_defense.unit_raffle[key] = global.wave_defense.unit_raffle[#global.wave_defense.unit_raffle]
			global.wave_defense.unit_raffle[#global.wave_defense.unit_raffle] = nil
		end
	end

	local unit = global.wave_defense.unit_raffle[math_random(1, #global.wave_defense.unit_raffle)]
	if is_random_unit_valid(unit) then return unit end
	
	return false
end

local function get_random_close_spawner(surface)
	debug_print("get_random_close_spawner")
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})	
	if not spawners[1] then return false end
	local center = global.wave_defense.target.position
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, global.wave_defense.get_random_close_spawner_attempts, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then spawner = spawner_2 end	
	end	
	return spawner
end

local function set_main_target()
	if global.wave_defense.target then	
		if global.wave_defense.target.valid then return true end
	end
	local characters = {}
	for i = 1, #game.connected_players, 1 do
		if game.connected_players[i].character then
			if game.connected_players[i].character.valid then
				if game.connected_players[i].surface.index == global.wave_defense.surface_index then
					characters[#characters + 1] = game.connected_players[i].character
				end
			end
		end
	end
	if #characters == 0 then return false end 
	global.wave_defense.target = characters[math_random(1, #characters)]
	return true
end

local function set_side_target_list()
	debug_print("set_side_target_list")
	if not global.wave_defense.target then return false end
	if not global.wave_defense.target.valid then return false end
	global.wave_defense.side_targets = global.wave_defense.target.surface.find_entities_filtered({
		area = {
			{global.wave_defense.target.position.x - global.wave_defense.side_target_search_radius, global.wave_defense.target.position.y - global.wave_defense.side_target_search_radius},
			{global.wave_defense.target.position.x + global.wave_defense.side_target_search_radius, global.wave_defense.target.position.y + global.wave_defense.side_target_search_radius}
		},
		force = global.wave_defense.target.force,
		type = side_target_types
	})
end

local function get_side_target()
	debug_print("get_side_target")
	if not global.wave_defense.side_targets then return false end
	if #global.wave_defense.side_targets < 2 then return false end
	local side_target = global.wave_defense.side_targets[math_random(1,#global.wave_defense.side_targets)]
	if not side_target then return false end
	if not side_target.valid then return false end
	for _ = 1, 4, 1 do
		local new_target = global.wave_defense.side_targets[math_random(1,#global.wave_defense.side_targets)]
		if new_target then
			if new_target.valid then
				local side_target_distance = (global.wave_defense.target.position.x - side_target.position.x) ^ 2 + (global.wave_defense.target.position.y - side_target.position.y) ^ 2
				local new_target_distance = (global.wave_defense.target.position.x - new_target.position.x) ^ 2 + (global.wave_defense.target.position.y - new_target.position.y) ^ 2
				if new_target_distance > side_target_distance then side_target = new_target end		
			end	
		end		
	end	
	return side_target
end

local function set_group_spawn_position(surface)
	local spawner = get_random_close_spawner(surface)
	if not spawner then return end
	local position = surface.find_non_colliding_position("rocket-silo", spawner.position, 48, 1)
	if not position then return end	
	global.wave_defense.spawn_position = {x = math.floor(position.x), y = math.floor(position.y)}
end

local function set_enemy_evolution()
	local evolution_factor = global.wave_defense.wave_number * 0.001
	local evasion_factor = 1
	local damage_increase = 0
	
	if evolution_factor > 1 then
		evasion_factor = evasion_factor + (evolution_factor - 1) * 3
		evolution_factor = 1
	end
	
	if global.wave_defense.threat > 0 then
		local m = math.round(global.wave_defense.threat / 50000, 3)
		evasion_factor = evasion_factor + m
		damage_increase = damage_increase + m
	end

	global.biter_evasion_health_increase_factor = evasion_factor
	game.forces.enemy.set_ammo_damage_modifier("melee", damage_increase)
	game.forces.enemy.set_ammo_damage_modifier("biological", damage_increase)
	game.forces.enemy.evolution_factor = evolution_factor
	
	debug_print("evolution_factor: " .. evolution_factor)
	debug_print("evasion_factor: " .. global.biter_evasion_health_increase_factor)
	debug_print("damage_increase: " .. game.forces.enemy.get_ammo_damage_modifier("melee"))	
end

local function spawn_biter(surface)
	if global.wave_defense.threat <= 0 then return false end
	if global.wave_defense.active_biter_count >= global.wave_defense.max_active_biters then return false end
	local name
	if math.random(1,100) > 73 then
		name = wave_defense_roll_spitter_name()
	else
		name = wave_defense_roll_biter_name()
	end
	local position = surface.find_non_colliding_position(name, global.wave_defense.spawn_position, 48, 2)
	if not position then return false end
	local biter = surface.create_entity({name = name, position = position, force = "enemy"})
	biter.ai_settings.allow_destroy_when_commands_fail = false
	biter.ai_settings.allow_try_return_to_spawner = false
	
	global.wave_defense.active_units[biter.unit_number] = {entity = biter, spawn_tick = game.tick}
	global.wave_defense.unit_raffle[#global.wave_defense.unit_raffle + 1] = biter
	global.wave_defense.active_biter_count = global.wave_defense.active_biter_count + 1
	global.wave_defense.threat = global.wave_defense.threat - threat_values[name]
	
	return biter
end

local function set_next_wave()
	global.wave_defense.wave_number = global.wave_defense.wave_number + 1
	global.wave_defense.group_size = global.wave_defense.wave_number * 2
	if global.wave_defense.group_size > global.wave_defense.max_group_size then global.wave_defense.group_size = global.wave_defense.max_group_size end
	global.wave_defense.threat = global.wave_defense.threat + global.wave_defense.wave_number * 2
	global.wave_defense.last_wave = global.wave_defense.next_wave
	global.wave_defense.next_wave = game.tick + global.wave_defense.wave_interval
end

local function get_commmands(group)
	debug_print("get_commmands")
	local commands = {}
	local group_position = {x = group.position.x, y = group.position.y}
	local step_length = global.wave_defense.unit_group_command_step_length
	
	if math_random(1,3) ~= 1 then
		local side_target = false
		for _ = 1, 3, 1 do
			side_target = get_side_target()
			if side_target then break end
		end
		if side_target then
			local target_position = side_target.position	
			local distance_to_target = math.floor(math.sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
			local steps = math.floor(distance_to_target / step_length) + 1
			local vector = {math.round((target_position.x - group_position.x) / steps, 3), math.round((target_position.y - group_position.y) / steps, 3)}
			
			
			debug_print("Side Target X:" .. side_target.position.x .. " Y:" .. side_target.position.y)
			debug_print("Distance to target " .. distance_to_target)
			debug_print("Steps " .. steps)
			debug_print("Vector " .. vector[1] .. "  " .. vector[2])
			
			
			for i = 1, steps, 1 do
				group_position.x = group_position.x + vector[1]
				group_position.y = group_position.y + vector[2]	
				local position = group.surface.find_non_colliding_position("small-biter", group_position, 64, 2)
				if position then
					commands[#commands + 1] = {
						type = defines.command.attack_area,
						destination = {x = position.x, y = position.y},
						radius = 16,
						distraction = defines.distraction.by_anything
					}
					--if global.wave_defense.debug then print(position) end
				end		
			end
			
			commands[#commands + 1] = {
				type = defines.command.attack,
				target = side_target,
				distraction = defines.distraction.by_enemy,
			}	
		end
	end
	
	local target_position = global.wave_defense.target.position	
	local distance_to_target = math.floor(math.sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
	local steps = math.floor(distance_to_target / step_length) + 1
	local vector = {math.round((target_position.x - group_position.x) / steps, 3), math.round((target_position.y - group_position.y) / steps, 3)}
	
	debug_print("Main Target X:" .. target_position.x .. " Y:" .. target_position.y)
	debug_print("Distance to target " .. distance_to_target)
	debug_print("Steps " .. steps)
	debug_print("Vector " .. vector[1] .. "  " .. vector[2])
	
	for i = 1, steps, 1 do
		group_position.x = group_position.x + vector[1]
		group_position.y = group_position.y + vector[2]	
		local position = group.surface.find_non_colliding_position("small-biter", group_position, 64, 1)
		if position then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = {x = position.x, y = position.y},
				radius = 16,
				distraction = defines.distraction.by_anything
			}
			--if global.wave_defense.debug then print(position) end
		end		
	end
	
	commands[#commands + 1] = {
		type = defines.command.attack_area,
		destination = {x = target_position.x, y = target_position.y},
		radius = 8,
		distraction = defines.distraction.by_enemy
	}
	
	commands[#commands + 1] = {
		type = defines.command.attack,
		target = global.wave_defense.target,
		distraction = defines.distraction.by_enemy,
	}
	
	return commands
end

local function command_unit_group(group)
	group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = get_commmands(group)
	})
end

local function spawn_and_command_unit_group()
	if global.wave_defense.active_biter_count >= global.wave_defense.max_active_biters then return false end
	if global.wave_defense.threat < global.wave_defense.group_size then return false end
	wave_defense_set_unit_raffle(global.wave_defense.wave_number)
	local surface = game.surfaces[global.wave_defense.surface_index]
	set_group_spawn_position(surface)
	debug_print("Spawning unit group at position:" .. global.wave_defense.spawn_position.x .." " .. global.wave_defense.spawn_position.y)
	local unit_group = surface.create_unit_group({position = global.wave_defense.spawn_position, force = "enemy"})
	for a = 1, global.wave_defense.group_size, 1 do
		local biter = spawn_biter(surface)
		if not biter then break end
		unit_group.add_member(biter)
	end
	command_unit_group(unit_group)
end

local function on_tick()
	if global.wave_defense.game_lost then return end	
	for _, player in pairs(game.connected_players) do gui(player) end	
	
	if game.tick > global.wave_defense.next_wave then	set_next_wave() end
	
	if game.tick % 300 == 0 then
		if not set_main_target() then return end
		if game.tick % 1800 == 0 then time_out_biters() end
		if game.tick % 7200 == 0 then set_side_target_list() end
		set_enemy_evolution()
		spawn_and_command_unit_group()
		build_nest()
		build_worm()
	end	
end

function reset_wave_defense()
	global.wave_defense = {
		debug = false,
		surface_index = 1,
		active_units = {},
		unit_raffle = {},
		unit_group_command_step_length = 64,
		group_size = 2,
		max_group_size = 200,
		max_active_biters = 1024,
		max_biter_age = 3600 * 60,
		active_biter_count = 0,
		get_random_close_spawner_attempts = 5,
		side_target_search_radius = 512,
		spawn_position = {x = 0, y = 64},
		last_wave = game.tick,
		next_wave = game.tick + 3600 * 5,
		wave_interval = 1800,
		wave_number = 0,
		game_lost = false,
		threat = 0,
		simple_entity_shredding_count_modifier = 0.0003,
		simple_entity_shredding_cost_modifier = 0.007,		--threat cost for one health
		nest_building_density = 64,										--lower values = more dense building
		nest_building_chance = 4,											--high value = less chance
		worm_building_density = 8,										--lower values = more dense building
		worm_building_chance = 2,										--high value = less chance
	}
end

local function on_init()
	reset_wave_defense()
end

local event = require 'utils.event'
event.on_nth_tick(30, on_tick)
event.on_init(on_init)