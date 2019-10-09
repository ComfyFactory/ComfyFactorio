require "modules.wave_defense.biter_rolls"
require "modules.wave_defense.threat_events"
local threat_values = require "modules.wave_defense.threat_values"
local math_random = math.random

local function debug_print(msg)
	if global.wave_defense.debug then 
		print("WaveDefense>> " .. msg) 
	end
end

local function is_unit_valid(biter)
	if not biter.entity then debug_print("is_unit_valid - unit destroyed - does no longer exist") return false end
	if not biter.entity.valid then debug_print("is_unit_valid - unit destroyed - invalid") return false end
	if not biter.entity.unit_group then debug_print("is_unit_valid - unit destroyed - no unitgroup") return false end
	if biter.spawn_tick + global.wave_defense.max_biter_age < game.tick then debug_print("is_unit_valid - unit destroyed - timed out") return false end
	return true
end

local function time_out_biters()	
	for k, biter in pairs(global.wave_defense.active_biters) do
		if not is_unit_valid(biter) then
			global.wave_defense.active_biter_count = global.wave_defense.active_biter_count - 1
			if biter.entity then
				if biter.entity.valid then
					global.wave_defense.threat = global.wave_defense.threat + threat_values[biter.entity.name]
					biter.entity.destroy()
				end
			end
			global.wave_defense.active_biters[k] = nil
		end
	end
end

local function get_random_close_spawner()
	local spawners = global.wave_defense.surface.find_entities_filtered({type = "unit-spawner"})	
	if not spawners[1] then return false end
	local center = global.wave_defense.target.position
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, global.wave_defense.get_random_close_spawner_attempts, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then spawner = spawner_2 end	
	end	
	return spawner
end

local function set_target()
	if global.wave_defense.target then	
		if global.wave_defense.target.valid then
			if global.wave_defense.target.name ~= "character" then return end
		end	
	end
	local characters = {}
	for i = 1, #game.connected_players, 1 do
		if game.connected_players[i].character then
			if game.connected_players[i].character.valid then
				characters[#characters + 1] = game.connected_players[i].character
			end
		end
	end
	if #characters == 0 then return end 
	global.wave_defense.target = characters[math_random(1, #characters)]
end

local function set_group_spawn_position()
	local spawner = get_random_close_spawner()
	if not spawner then return end
	local position = global.wave_defense.surface.find_non_colliding_position("rocket-silo", spawner.position, 48, 1)
	if not position then return end	
	global.wave_defense.spawn_position = {x = position.x, y = position.y}
end

local function set_enemy_evolution()
	local evolution = global.wave_defense.wave_number * 0.001
	if evolution > 1 then
		global.biter_evasion_health_increase_factor = (evolution - 1) * 4
		evolution = 1
	else
		global.biter_evasion_health_increase_factor = 1
	end
	game.forces.enemy.evolution_factor = evolution
end

local function spawn_biter()
	if global.wave_defense.threat <= 0 then return false end
	if global.wave_defense.active_biter_count >= global.wave_defense.max_active_biters then return false end
	local name = wave_defense_roll_biter_name()	
	local position = global.wave_defense.surface.find_non_colliding_position(name, global.wave_defense.spawn_position, 32, 1)
	if not position then return false end
	local biter = global.wave_defense.surface.create_entity({name = name, position = position, force = "enemy"})
	biter.ai_settings.allow_destroy_when_commands_fail = false
	biter.ai_settings.allow_try_return_to_spawner = false
	global.wave_defense.active_biters[biter.unit_number] = {entity = biter, spawn_tick = game.tick}
	global.wave_defense.active_biter_count = global.wave_defense.active_biter_count + 1
	global.wave_defense.threat = global.wave_defense.threat - threat_values[name]
	return biter
end

local function spawn_unit_group()
	if global.wave_defense.threat <= 0 then return false end
	if global.wave_defense.active_biter_count >= global.wave_defense.max_active_biters then return false end
	set_group_spawn_position()
	local unit_group = global.wave_defense.surface.create_unit_group({position = global.wave_defense.spawn_position, force = "enemy"})
	for a = 1, global.wave_defense.group_size, 1 do
		local biter = spawn_biter()
		if not biter then break end
		unit_group.add_member(biter)
	end
	global.wave_defense.unit_groups[#global.wave_defense.unit_groups + 1] = unit_group
	return true
end

local function set_unit_group_count()
	c = 0
	for k, group in pairs(global.wave_defense.unit_groups) do
		if group.valid then
			if #group.members > 0 then
				c = c + 1
			else
				group.destroy()
				global.wave_defense.unit_groups[k] = nil
			end
		else
			global.wave_defense.unit_groups[k] = nil
		end
	end
	global.wave_defense.active_unit_group_count = c
end

local function spawn_attack_groups()
	if global.wave_defense.active_biter_count >= global.wave_defense.max_active_biters then return false end
	if global.wave_defense.threat <= 0 then return false end
	wave_defense_set_biter_raffle(global.wave_defense.wave_number)
	for a = 1, global.wave_defense.max_active_unit_groups - global.wave_defense.active_unit_group_count, 1 do
		if not spawn_unit_group() then break end
	end
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
	local commands = {}
	local target_position = global.wave_defense.target.position
	local group_position = {x = group.position.x, y = group.position.y}
	local step_length = global.wave_defense.unit_group_command_step_length
	local distance_to_target = math.floor(math.sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
	local steps = math.floor(distance_to_target / step_length) + 1
	local vector = {math.round((target_position.x - group_position.x) / steps, 3), math.round((target_position.y - group_position.y) / steps, 3)}
	
	if global.wave_defense.debug then
		print("get_commmands")
		print("distance_to_target " .. distance_to_target)
		print("steps " .. steps)
		print("vector " .. vector[1] .. "_" .. vector[2])
	end
	
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
			if global.wave_defense.debug then print(position) end
		end
		
	end
	
	commands[#commands + 1] = {
		type = defines.command.attack_area,
		destination = {x = global.wave_defense.target.position.x, y = global.wave_defense.target.position.y},
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
	if not global.wave_defense.unit_group_last_command[group.group_number] then global.wave_defense.unit_group_last_command[group.group_number] = game.tick - (global.wave_defense.unit_group_command_delay + 1) end
	if global.wave_defense.unit_group_last_command[group.group_number] + global.wave_defense.unit_group_command_delay > game.tick then return end	
	global.wave_defense.unit_group_last_command[group.group_number] = game.tick
	
	group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = get_commmands(group)
	})
end

local function give_commands_to_unit_groups()
	if #global.wave_defense.unit_groups == 0 then return end
	if not global.wave_defense.target then return end
	if not global.wave_defense.target.valid then return end
	for k, group in pairs(global.wave_defense.unit_groups) do
		if group.valid then
			command_unit_group(group)
		else
			global.wave_defense.unit_groups[k] = nil 
		end
	end	
end

local function create_gui(player)
	local frame = player.gui.top.add({ type = "frame", name = "wave_defense"})
	frame.style.maximal_height = 38

	local label = frame.add({ type = "label", caption = " ", name = "label"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 68
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 128
	progressbar.style.maximal_width = 128
	progressbar.style.top_padding = 10
	
	local line = frame.add({type = "line", direction = "vertical"})
	line.style.left_padding = 4
	line.style.right_padding = 4
	
	local label = frame.add({ type = "label", caption = " ", name = "threat", tooltip = "high threat may empower biters"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 10
	label.style.font_color = {r=0.99, g=0.0, b=0.5}
end

local function update_gui(player)
	if not player.gui.top.wave_defense then create_gui(player) end
	player.gui.top.wave_defense.label.caption = "Wave: " .. global.wave_defense.wave_number
	if global.wave_defense.wave_number == 0 then player.gui.top.wave_defense.label.caption = "First wave in " .. math.floor((global.wave_defense.next_wave - game.tick) / 60) + 1 end
	local interval = global.wave_defense.next_wave - global.wave_defense.last_wave
	player.gui.top.wave_defense.progressbar.value = 1 - (global.wave_defense.next_wave - game.tick) / interval
	local value = global.wave_defense.threat
	if value < 0 then value = 0 end
	player.gui.top.wave_defense.threat.caption = "Threat: " .. value
end

local function on_tick()
	if global.wave_defense.game_lost then return end
	
	for _, player in pairs(game.connected_players) do update_gui(player) end
	
	if game.tick > global.wave_defense.next_wave then	set_next_wave() end
	
	if game.tick % 180 == 0 then
		if game.tick % 1800 == 0 then
			time_out_biters()
		end
		set_target()
		set_enemy_evolution()
		spawn_attack_groups()
		set_unit_group_count()
		give_commands_to_unit_groups()
	end	
end

function reset_wave_defense()
	global.wave_defense = {
		debug = false,
		surface = game.surfaces["nauvis"],
		active_biters = {},
		unit_groups = {},
		unit_group_last_command = {},
		unit_group_command_delay = 3600 * 5,
		unit_group_command_step_length = 96,
		max_group_size = 256,
		max_active_unit_groups = 6,
		max_active_biters = 256 * 6,
		max_biter_age = 3600 * 60,
		active_unit_group_count = 0,
		active_biter_count = 0,
		get_random_close_spawner_attempts = 2,
		spawn_position = {x = 0, y = 64},
		last_wave = game.tick,
		next_wave = game.tick + 3600 * 5,
		wave_interval = 1800,
		wave_number = 0,
		game_lost = false,
		threat = 0,
		simple_entity_shredding_count_modifier = 0.0003,
		simple_entity_shredding_cost_modifier = 0.005,		--threat cost for one health
	}
end

local function on_init()
	reset_wave_defense()
end

local event = require 'utils.event'
event.on_nth_tick(30, on_tick)
event.on_init(on_init)