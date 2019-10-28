require "modules.biter_health_booster"
local BiterRolls = require "modules.wave_defense.biter_rolls"
local ThreatEvent = require "modules.wave_defense.threat_events"
local update_gui = require "modules.wave_defense.gui"
local threat_values = require "modules.wave_defense.threat_values"
local WD = require "modules.wave_defense.table"
local event = require 'utils.event'
local side_target_types = {"accumulator", "assembling-machine", "beacon", "boiler", "container", "furnace", "lamp", "lab", "logistic-container", "mining-drill", "container", "pump", "radar", "reactor", "roboport", "rocket-silo", "solar-panel", "storage-tank",}
--local side_target_types = {"assembling-machine", "electric-pole", "furnace", "mining-drill", "pump", "radar", "reactor", "roboport"}

local Public = {}

local function debug_print(msg)
	local wave_defense_table = WD.get_table()
	if not wave_defense_table.debug then return end
	print("WaveDefense: " .. msg)
end

local function is_unit_valid(biter)
	local wave_defense_table = WD.get_table()
	if not biter.entity then debug_print("is_unit_valid - unit destroyed - does no longer exist") return false end
	if not biter.entity.valid then debug_print("is_unit_valid - unit destroyed - invalid") return false end
	if not biter.entity.unit_group then debug_print("is_unit_valid - unit destroyed - no unitgroup") return false end
	if biter.spawn_tick + wave_defense_table.max_biter_age < game.tick then debug_print("is_unit_valid - unit destroyed - timed out") return false end
	return true
end

local function refresh_active_unit_threat()
	local wave_defense_table = WD.get_table()
	debug_print("refresh_active_unit_threat - current value " .. wave_defense_table.active_biter_threat)
	local active_biter_threat = 0
	for k, biter in pairs(wave_defense_table.active_biters) do
		if biter.entity then
			if biter.entity.valid then
				active_biter_threat = active_biter_threat + threat_values[biter.entity.name]
			end
		end
	end
	wave_defense_table.active_biter_threat = math.round(active_biter_threat * global.biter_health_boost, 2)
	debug_print("refresh_active_unit_threat - new value " .. wave_defense_table.active_biter_threat)
end

local function time_out_biters()
	local wave_defense_table = WD.get_table()
	for k, biter in pairs(wave_defense_table.active_biters) do
		if not is_unit_valid(biter) then
			wave_defense_table.active_biter_count = wave_defense_table.active_biter_count - 1
			if biter.entity then
				if biter.entity.valid then
					wave_defense_table.active_biter_threat = wave_defense_table.active_biter_threat - math.round(threat_values[biter.entity.name] * global.biter_health_boost, 2)
					if biter.entity.force.index == 2 then
						biter.entity.destroy()
					end
				end
			end
			wave_defense_table.active_biters[k] = nil
		end
	end
end

local function get_random_close_spawner(surface)
	local wave_defense_table = WD.get_table()
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})
	if not spawners[1] then return false end
	local center = wave_defense_table.target.position
	local spawner = spawners[math.random(1,#spawners)]
	for i = 1, wave_defense_table.get_random_close_spawner_attempts, 1 do
		local spawner_2 = spawners[math.random(1,#spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then spawner = spawner_2 end
	end
	debug_print("get_random_close_spawner - Found at x" .. spawner.position.x .. " y" .. spawner.position.y)
	return spawner
end

local function set_side_target_list()
	local wave_defense_table = WD.get_table()
	local surface = game.surfaces[wave_defense_table.surface_index]
	local position = false
	local force = false

	if wave_defense_table.target then
		if wave_defense_table.target.valid then
			position = wave_defense_table.target.position
			force = wave_defense_table.target.force
		end
	end

	if not position then
		local r = math.random(1, #game.connected_players)
		position = {x = game.connected_players[r].position.x, y = game.connected_players[r].position.y}
		force = game.connected_players[r].force
	end

	wave_defense_table.side_targets = surface.find_entities_filtered({
		area = {
			{position.x - wave_defense_table.side_target_search_radius, position.y - wave_defense_table.side_target_search_radius},
			{position.x + wave_defense_table.side_target_search_radius, position.y + wave_defense_table.side_target_search_radius}
		},
		force = force,
		type = side_target_types,
	})

	debug_print("set_side_target_list -- " .. #wave_defense_table.side_targets .. " targets around position x" .. position.x .. " y" .. position.y .. " saved.")
end

local function get_side_target()
	local wave_defense_table = WD.get_table()
	if math.random(1, 2) == 1 then
		local surface = game.surfaces[wave_defense_table.surface_index]
		local characters = surface.find_entities_filtered({name = "character"})
		if not characters[1] then return false end
		local character = characters[math.random(1, #characters)]
		if not character.valid then return false end
		return character
	end

	if not wave_defense_table.side_targets then return false end
	if #wave_defense_table.side_targets < 2 then return false end
	local side_target = wave_defense_table.side_targets[math_random(1,#wave_defense_table.side_targets)]
	if not side_target then return false end
	if not side_target.valid then return false end
	for _ = 1, 4, 1 do
		local new_target = wave_defense_table.side_targets[math.random(1,#wave_defense_table.side_targets)]
		if new_target then
			if new_target.valid then
				local side_target_distance = (wave_defense_table.target.position.x - side_target.position.x) ^ 2 + (wave_defense_table.target.position.y - side_target.position.y) ^ 2
				local new_target_distance = (wave_defense_table.target.position.x - new_target.position.x) ^ 2 + (wave_defense_table.target.position.y - new_target.position.y) ^ 2
				if new_target_distance > side_target_distance then side_target = new_target end
			end
		end
	end
	debug_print("get_side_target -- " .. side_target.name .. " at position x" .. side_target.position.x .. " y" .. side_target.position.y .. " selected.")
	return side_target
end

--[[
local function set_main_target()
	if wave_defense_table.target then
		if wave_defense_table.target.valid then return end
	end
	local characters = {}
	for i = 1, #game.connected_players, 1 do
		if game.connected_players[i].character then
			if game.connected_players[i].character.valid then
				if game.connected_players[i].surface.index == wave_defense_table.surface_index then
					characters[#characters + 1] = game.connected_players[i].character
				end
			end
		end
	end
	if #characters == 0 then return end
	wave_defense_table.target = characters[math.random(1, #characters)]
end
]]

local function set_main_target()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.target then
		if wave_defense_table.target.valid then return end
	end
	if not wave_defense_table.side_targets then return end
	if #wave_defense_table.side_targets == 0 then return end
	local target = wave_defense_table.side_targets[math.random(1, #wave_defense_table.side_targets)]
	if not target then return end
	if not target.valid then return end
	wave_defense_table.target = target
	debug_print("set_main_target -- New main target " .. target.name .. " at position x" .. target.position.x .. " y" .. target.position.y .. " selected.")
end

local function set_group_spawn_position(surface)
	local wave_defense_table = WD.get_table()
	local spawner = get_random_close_spawner(surface)
	if not spawner then return end
	local position = surface.find_non_colliding_position("rocket-silo", spawner.position, 48, 1)
	if not position then return end
	wave_defense_table.spawn_position = {x = math.floor(position.x), y = math.floor(position.y)}
	debug_print("set_group_spawn_position -- Changed position to x" .. wave_defense_table.spawn_position.x .. " y" .. wave_defense_table.spawn_position.y .. ".")
end

local function set_enemy_evolution()
	local wave_defense_table = WD.get_table()
	local evolution_factor = wave_defense_table.wave_number * 0.001
	local biter_health_boost = 1
	--local damage_increase = 0

	if evolution_factor > 1 then
		--damage_increase = damage_increase + (evolution_factor - 1)
		--biter_health_boost = biter_health_boost + (evolution_factor - 1) * 2
		evolution_factor = 1
	end

	if wave_defense_table.threat > 0 then
		biter_health_boost = math.round(biter_health_boost + wave_defense_table.threat * 0.00005, 3)
		--damage_increase = math.round(damage_increase + wave_defense_table.threat * 0.0000025, 3)
	end

	global.biter_health_boost = biter_health_boost
	--game.forces.enemy.set_ammo_damage_modifier("melee", damage_increase)
	--game.forces.enemy.set_ammo_damage_modifier("biological", damage_increase)
	game.forces.enemy.evolution_factor = evolution_factor

	if global.biter_health_boost then
		for _, player in pairs(game.connected_players) do
			--player.gui.top.wave_defense.threat.tooltip = "High threat may empower biters.\nBiter health " .. biter_health_boost * 100 .. "% | damage " .. (damage_increase + 1) * 100 .. "%"
			if player.gui.top.wave_defense then
				player.gui.top.wave_defense.threat.tooltip = "High threat may empower biters.\nBiter health " .. biter_health_boost * 100 .. "%"
			end
		end
	end
end

local function can_units_spawn()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.threat <= 0 then
		debug_print("can_units_spawn - threat too low")
		return false
	end
	if wave_defense_table.active_biter_count >= wave_defense_table.max_active_biters then
		debug_print("can_units_spawn - active biter count too high")
		return false
	end
	if wave_defense_table.active_biter_threat >= wave_defense_table.threat then
		debug_print("can_units_spawn - active biter threat too high (" .. wave_defense_table.active_biter_threat .. ")")
		return false
	end
	return true
end

local function get_active_unit_groups_count()
	local wave_defense_table = WD.get_table()
	local count = 0
	for _, g in pairs(wave_defense_table.unit_groups) do
		if g.valid then
			if #g.members > 0 then
				count = count + 1
			else
				g.destroy()
			end
		end
	end
	debug_print("Active unit group count: " .. count)
	return count
end

local function spawn_biter(surface)
	local wave_defense_table = WD.get_table()
	if not can_units_spawn() then return end

	local name
	if math.random(1,100) > 73 then
		name = BiterRolls.wave_defense_roll_spitter_name()
	else
		name = BiterRolls.wave_defense_roll_biter_name()
	end
	local position = surface.find_non_colliding_position(name, wave_defense_table.spawn_position, 48, 2)
	if not position then return false end
	local biter = surface.create_entity({name = name, position = position, force = "enemy"})
	biter.ai_settings.allow_destroy_when_commands_fail = false
	biter.ai_settings.allow_try_return_to_spawner = false
	wave_defense_table.active_biters[biter.unit_number] = {entity = biter, spawn_tick = game.tick}
	wave_defense_table.active_biter_count = wave_defense_table.active_biter_count + 1
	wave_defense_table.active_biter_threat = wave_defense_table.active_biter_threat + math.round(threat_values[name] * global.biter_health_boost, 2)
	return biter
end

local function set_next_wave()
	local wave_defense_table = WD.get_table()
	wave_defense_table.wave_number = wave_defense_table.wave_number + 1
	wave_defense_table.group_size = wave_defense_table.wave_number * 2
	if wave_defense_table.group_size > wave_defense_table.max_group_size then wave_defense_table.group_size = wave_defense_table.max_group_size end
	wave_defense_table.threat = wave_defense_table.threat + math.floor(wave_defense_table.wave_number * wave_defense_table.threat_gain_multiplier)
	wave_defense_table.last_wave = wave_defense_table.next_wave
	wave_defense_table.next_wave = game.tick + wave_defense_table.wave_interval
end

local function get_commmands(group)
	local wave_defense_table = WD.get_table()
	local commands = {}
	local group_position = {x = group.position.x, y = group.position.y}
	local step_length = wave_defense_table.unit_group_command_step_length

	if math.random(1,3) ~= 1 then
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

			if wave_defense_table.debug then
				debug_print("get_commmands - to side_target x" .. side_target.position.x .. " y" .. side_target.position.y)
				debug_print("get_commmands - distance_to_target:" .. distance_to_target .. " steps:" .. steps)
				debug_print("get_commmands - vector " .. vector[1] .. "_" .. vector[2])
			end

			for i = 1, steps, 1 do
				group_position.x = group_position.x + vector[1]
				group_position.y = group_position.y + vector[2]	
				local position = group.surface.find_non_colliding_position("small-biter", group_position, step_length, 2)
				if position then
					commands[#commands + 1] = {
						type = defines.command.attack_area,
						destination = {x = position.x, y = position.y},
						radius = 16,
						distraction = defines.distraction.by_anything
					}
				end
			end

			commands[#commands + 1] = {
				type = defines.command.attack,
				target = side_target,
				distraction = defines.distraction.by_enemy,
			}
		end
	end

	local target_position = wave_defense_table.target.position
	local distance_to_target = math.floor(math.sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
	local steps = math.floor(distance_to_target / step_length) + 1
	local vector = {math.round((target_position.x - group_position.x) / steps, 3), math.round((target_position.y - group_position.y) / steps, 3)}

	if wave_defense_table.debug then
		debug_print("get_commmands - to main target x" .. target_position.x .. " y" .. target_position.y)
		debug_print("get_commmands - distance_to_target:" .. distance_to_target .. " steps:" .. steps)
		debug_print("get_commmands - vector " .. vector[1] .. "_" .. vector[2])
	end

	for i = 1, steps, 1 do
		group_position.x = group_position.x + vector[1]
		group_position.y = group_position.y + vector[2]
		local position = group.surface.find_non_colliding_position("small-biter", group_position, step_length, 1)
		if position then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = {x = position.x, y = position.y},
				radius = 16,
				distraction = defines.distraction.by_anything
			}
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
		target = wave_defense_table.target,
		distraction = defines.distraction.by_enemy,
	}

	return commands
end

local function command_unit_group(group)
	local wave_defense_table = WD.get_table()
	if not wave_defense_table.unit_group_last_command[group.group_number] then
		wave_defense_table.unit_group_last_command[group.group_number] = game.tick - (wave_defense_table.unit_group_command_delay + 1)
	end
	if wave_defense_table.unit_group_last_command[group.group_number] then
		if wave_defense_table.unit_group_last_command[group.group_number] + wave_defense_table.unit_group_command_delay > game.tick then return end		
	end
	
	group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = get_commmands(group)
	})
	
	wave_defense_table.unit_group_last_command[group.group_number] = game.tick
end

local function give_commands_to_unit_groups()
	local wave_defense_table = WD.get_table()
	if #wave_defense_table.unit_groups == 0 then return end
	if not wave_defense_table.target then return end
	if not wave_defense_table.target.valid then return end
	for k, group in pairs(wave_defense_table.unit_groups) do
		if group.valid then
			command_unit_group(group)
		else
			table.remove(wave_defense_table.unit_groups, k)
			--wave_defense_table.unit_groups[k] = nil 
		end
	end
end

local function spawn_unit_group()
	local wave_defense_table = WD.get_table()
	if not can_units_spawn() then return end
	if not wave_defense_table.target then return end
	if not wave_defense_table.target.valid then return end
	if get_active_unit_groups_count() >= wave_defense_table.max_active_unit_groups then return end
	
	BiterRolls.wave_defense_set_unit_raffle(wave_defense_table.wave_number)
	
	local surface = game.surfaces[wave_defense_table.surface_index]
	set_group_spawn_position(surface)
	debug_print("Spawning unit group at x" .. wave_defense_table.spawn_position.x .." y" .. wave_defense_table.spawn_position.y)
	local unit_group = surface.create_unit_group({position = wave_defense_table.spawn_position, force = "enemy"})
	for a = 1, wave_defense_table.group_size, 1 do
		local biter = spawn_biter(surface)
		if not biter then break end
		unit_group.add_member(biter)
	end
	--command_unit_group(unit_group)
	
	table.insert(wave_defense_table.unit_groups, unit_group)
	--[[
	for i = 1, #wave_defense_table.unit_groups, 1 do
		if not wave_defense_table.unit_groups[i] then
			wave_defense_table.unit_groups[i] = unit_group
			return true
		end
	end
	wave_defense_table.unit_groups[#wave_defense_table.unit_groups + 1] = unit_group
	]]
	return true
end

local function log_threat()
	local wave_defense_table = WD.get_table()
	wave_defense_table.threat_log_index = wave_defense_table.threat_log_index + 1
	wave_defense_table.threat_log[wave_defense_table.threat_log_index] = wave_defense_table.threat
	if wave_defense_table.threat_log_index > 900 then wave_defense_table.threat_log[wave_defense_table.threat_log_index - 901] = nil end	
end

local tick_tasks = {
	[30] = set_main_target,
	[60] = set_enemy_evolution,
	[90] = spawn_unit_group,
	[120] = give_commands_to_unit_groups,
	[150] = ThreatEvent.build_nest,
	[180] = ThreatEvent.build_worm,
	[1800] = set_side_target_list,
	[3600] = time_out_biters,
	[7200] = refresh_active_unit_threat,
}

local function on_tick()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.game_lost then return end
			
	if game.tick > wave_defense_table.next_wave then	set_next_wave() end

	local t = game.tick % 300
	local t2 = game.tick % 18000
	
	if tick_tasks[t] then tick_tasks[t]() end
	if tick_tasks[t2] then tick_tasks[t2]() end
	
	if game.tick % 60 == 0 then log_threat() end
	for _, player in pairs(game.connected_players) do update_gui(player) end
end

local function on_init()
	local wave_defense_table = WD.get_table()
	wave_defense_table.reset_wave_defense()
end

event.on_nth_tick(30, on_tick)
return Public