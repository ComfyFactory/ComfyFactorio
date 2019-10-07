local math_random = math.random
local threat_values = {
	["behemoth-biter"] = 10,
	["behemoth-spitter"] = 10,
	["big-biter"] = 5,
	["big-spitter"] = 5,
	["medium-biter"] = 3,
	["medium-spitter"] = 3,
	["small-biter"] = 1,
	["small-spitter"] = 1,
}

local function roll_biter_name()
	local max_chance = 0
	for k, v in pairs(global.wave_defense.biter_raffle) do
		max_chance = max_chance + v
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for k, v in pairs(global.wave_defense.biter_raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

local function set_biter_raffle(level)
	global.wave_defense.biter_raffle = {
		["small-biter"] = 1000 - level * 2,
		["small-spitter"] = 1000 - level * 2,
		["medium-biter"] = level,
		["medium-spitter"] = level,
		["big-biter"] = 0,
		["big-spitter"] = 0,
		["behemoth-biter"] = 0,
		["behemoth-spitter"] = 0,
	}
	if level > 500 then
		global.wave_defense.biter_raffle["big-biter"] = (level - 500) * 5
		global.wave_defense.biter_raffle["big-spitter"] = (level - 500) * 5
	end
	if level > 800 then
		global.wave_defense.biter_raffle["behemoth-biter"] = (level - 800) * 10
		global.wave_defense.biter_raffle["behemoth-spitter"] = (level - 800) * 10
	end
	for k, v in pairs(global.wave_defense.biter_raffle) do
		if global.wave_defense.biter_raffle[k] < 0 then global.wave_defense.biter_raffle[k] = 0 end
	end
end

local function time_out_biters()	
	for k, biter in pairs(global.wave_defense.active_biters) do
		if biter.spawn_tick + global.wave_defense.max_biter_age < game.tick then
			global.wave_defense.threat = global.wave_defense.threat + threat_values[biter.entity.name]
			biter.entity.destroy()
			global.wave_defense.active_biters[k] = nil
		end
	end
end

local function get_random_close_spawner()
	local spawners = global.wave_defense.surface.find_entities_filtered({type = "unit-spawner"})	
	if not spawners[1] then return false end
	local center = global.wave_defense.target.position
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, 5, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then spawner = spawner_2 end	
	end	
	return spawner
end

local function set_target()
	if global.wave_defense.target then
		if global.wave_defense.target.valid then return end
	end
	local characters = {}
	for i = 1, #game.connected_players, 1 do
		if game.connected_players[i].character then
			if game.connected_players[i].character.valid then
				characters[#characters + 1] = game.connected_players[i].character
			end
		end
	end
	global.wave_defense.target = characters[math_random(1, #characters)]
end

local function set_group_spawn_position()
	local spawner = get_random_close_spawner()
	if not spawner then return end
	local position = global.wave_defense.surface.find_non_colliding_position("rocket-silo", spawner.position, 48, 1)
	if not position then return end	
	global.wave_defense.spawn_position = position
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
	local name = roll_biter_name()
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

local function spawn_wave()
	if global.wave_defense.active_biter_count >= global.wave_defense.max_active_biters then return false end
	global.wave_defense.wave_number = global.wave_defense.wave_number + 1
	global.wave_defense.group_size = global.wave_defense.wave_number * 2
	if global.wave_defense.group_size > global.wave_defense.max_group_size then global.wave_defense.group_size = global.wave_defense.max_group_size end
	global.wave_defense.threat = global.wave_defense.threat + global.wave_defense.wave_number * 3
	set_enemy_evolution()
	set_biter_raffle(global.wave_defense.wave_number)
	for a = 1, 16, 1 do
		if not spawn_unit_group() then break end
	end
end

local function give_commands_to_unit_groups()
	if #global.wave_defense.unit_groups == 0 then return end
	if not global.wave_defense.target then return end
	if not global.wave_defense.target.valid then return end
	for k, group in pairs(global.wave_defense.unit_groups) do
		if group.valid then
			group.set_command({
				type = defines.command.compound,
				structure_type = defines.compound_command.return_last,
				commands = {
					{
						type = defines.command.attack_area,
						destination = global.wave_defense.target.position,
						radius = 16,
						distraction = defines.distraction.by_enemy
					},									
					{
						type = defines.command.attack,
						target = global.wave_defense.target,
						distraction = defines.distraction.by_enemy
					}
				}
			})
		else
			global.wave_defense.unit_groups[k] = nil 
		end
	end	
end

local function create_gui(player)
	local frame = player.gui.top.add({ type = "frame", name = "wave_defense", tooltip = "Click to show map info"})
	frame.style.maximal_height = 38

	local label = frame.add({ type = "label", caption = " ", name = "label"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-listbox"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 68
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 128
	progressbar.style.maximal_width = 128
	progressbar.style.top_padding = 10
end

local function update_gui(player)
	if not player.gui.top.wave_defense then create_gui(player) end
	player.gui.top.wave_defense.label.caption = "Wave: " .. global.wave_defense.wave_number
	if global.wave_defense.wave_number == 0 then player.gui.top.wave_defense.label.caption = "First wave in " .. math.floor((global.wave_defense.next_wave - game.tick) / 60) + 1 end
	local interval = global.wave_defense.next_wave - global.wave_defense.last_wave
	player.gui.top.wave_defense.progressbar.value = 1 - (global.wave_defense.next_wave - game.tick) / interval
end

local function on_entity_died(event)
	if not event.entity.valid then	return end
	if event.entity.type ~= "unit" then return end
	if not global.wave_defense.active_biters[event.entity.unit_number] then return end
	global.wave_defense.active_biters[event.entity.unit_number] = nil
	global.wave_defense.active_biter_count = global.wave_defense.active_biter_count - 1
end

local function on_tick()
	if global.wave_defense.game_lost then return end
	
	for _, player in pairs(game.connected_players) do update_gui(player) end
	
	if game.tick < global.wave_defense.next_wave then return end
	
	if global.wave_defense.active_biter_count < global.wave_defense.max_active_biters then
		global.wave_defense.last_wave = global.wave_defense.next_wave
		global.wave_defense.next_wave = game.tick + global.wave_defense.wave_interval
		time_out_biters()
		set_target()
		spawn_wave()
		give_commands_to_unit_groups()
		return
	end
	
	if game.tick % 3600 == 0 then
		time_out_biters() 
		set_target()
		give_commands_to_unit_groups()
	end		
end

function reset_wave_defense()
	global.wave_defense = {
		surface = game.surfaces["nauvis"],
		active_biters = {},
		unit_groups = {},
		max_active_biters = 1024,
		max_group_size = 256,
		max_biter_age = 3600 * 30,
		active_biter_count = 0,
		spawn_position = {x = 0, y = 48},
		last_wave = game.tick,
		next_wave = game.tick + 36 * 10,
		wave_interval = 1800,
		wave_number = 0,
		game_lost = false,
		threat = 0,
	}
end

local function on_init()
	reset_wave_defense()
end

local event = require 'utils.event'
event.on_nth_tick(30, on_tick)
event.on_init(on_init)
event.add(defines.events.on_entity_died, on_entity_died)