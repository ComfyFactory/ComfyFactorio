-- fish defender -- by mewmew --

local event = require 'utils.event'
require "maps.fish_defender_map_intro"
require "maps.fish_defender_kaboomsticks"
local map_functions = require "maps.tools.map_functions"
local math_random = math.random
local insert = table.insert
local wave_interval = 3600		--interval between waves in ticks
local biter_count_limit = 2400	--maximum biters on the east side of the map, next wave will be delayed if the maximum has been reached
local boss_waves = {
	[50] = {{name = "big-biter", count = 3}},
	[100] = {{name = "behemoth-biter", count = 1}},
	[150] = {{name = "behemoth-spitter", count = 4}, {name = "big-spitter", count = 16}},
	[200] = {{name = "behemoth-biter", count = 4}, {name = "behemoth-spitter", count = 2}},
	[250] = {{name = "behemoth-biter", count = 8}, {name = "behemoth-spitter", count = 4}},
	[300] = {{name = "behemoth-biter", count = 12}, {name = "behemoth-spitter", count = 6}},
	[350] = {{name = "behemoth-biter", count = 16}, {name = "behemoth-spitter", count = 8}},
	[400] = {{name = "behemoth-biter", count = 20}, {name = "behemoth-spitter", count = 10}},
	[450] = {{name = "behemoth-biter", count = 24}, {name = "behemoth-spitter", count = 12}}
}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_wave_gui(player)
	if player.gui.top["fish_defense_waves"] then player.gui.top["fish_defense_waves"].destroy() end
	local frame = player.gui.top.add({ type = "frame", name = "fish_defense_waves"})
	frame.style.maximal_height = 38

	local wave_count = 0
	if global.wave_count then wave_count = global.wave_count end
	
	if not global.wave_grace_period then
		local label = frame.add({ type = "label", caption = "Wave: " .. wave_count })
		label.style.font_color = {r=0.88, g=0.88, b=0.88}
		label.style.font = "default-listbox"
		label.style.left_padding = 4
		label.style.right_padding = 4
		label.style.minimal_width = 68
		label.style.font_color = {r=0.33, g=0.66, b=0.9}

		local next_level_progress = game.tick % wave_interval / wave_interval

		local progressbar = frame.add({ type = "progressbar", value = next_level_progress})
		progressbar.style.minimal_width = 120
		progressbar.style.maximal_width = 120
		progressbar.style.top_padding = 10
	else
	
		local time_remaining = math.floor(((global.wave_grace_period - (game.tick % global.wave_grace_period)) / 60) / 60)		
		if time_remaining <= 0 then
			global.wave_grace_period = nil
			return
		end
			
		local label = frame.add({ type = "label", caption = "Waves will start in " .. time_remaining .. " minutes."})
		label.style.font_color = {r=0.88, g=0.88, b=0.88}
		label.style.font = "default-listbox"
		label.style.left_padding = 4
		label.style.right_padding = 4
		label.style.font_color = {r=0.33, g=0.66, b=0.9}				
	end
end

local threat_values = {
	["small_biter"] = 1,
	["medium_biter"] = 3,
	["big_biter"] = 5,
	["behemoth_biter"] = 10,
	["small_spitter"] = 1,
	["medium_spitter"] = 3,
	["big_spitter"] = 5,
	["behemoth_spitter"] = 10
}

local function get_biter_initial_pool()
	local biter_pool = {}
	if global.wave_count > 2000 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 1},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 1},			
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if global.wave_count > 1000 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 3},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},			
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.1 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 3},			
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 1}		
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.2 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 10},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 2},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 5},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.3 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 18},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 6},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 8},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 3},
			{name = "big-biter", threat = threat_values.big_biter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.4 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 8},
			{name = "big-biter", threat = threat_values.big_biter, weight = 2},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 4},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.5 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 4},
			{name = "big-biter", threat = threat_values.big_biter, weight = 8},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 4}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.6 then
		biter_pool = {			
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 4},
			{name = "big-biter", threat = threat_values.big_biter, weight = 8},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 4}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.7 then
		biter_pool = {
			{name = "behemoth-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 12},
			{name = "big-biter", threat = threat_values.big_biter, weight = 20},
			{name = "behemoth-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 6},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 10}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.8 then
		biter_pool = {
			{name = "behemoth-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 4},
			{name = "big-biter", threat = threat_values.big_biter, weight = 10},
			{name = "behemoth-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 5}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor <= 0.9 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 12},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 6},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end	
	if game.forces.enemy.evolution_factor <= 1 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 4},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 2},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end	
end

local function get_biter_pool()
	local surface = game.surfaces["fish_defender"]
	local biter_pool = get_biter_initial_pool()
	local biter_raffle = {}
	for _, biter_type in pairs(biter_pool) do
		for x = 1, biter_type.weight, 1 do
			insert(biter_raffle, {name = biter_type.name, threat = biter_type.threat})
		end
	end
	return biter_raffle
end

local function spawn_biter(pos, biter_pool)
	if global.attack_wave_threat < 1 then return false end
	local surface = game.surfaces["fish_defender"]	
	biter_pool = shuffle(biter_pool)
	global.attack_wave_threat = global.attack_wave_threat - biter_pool[1].threat
	local valid_pos = surface.find_non_colliding_position(biter_pool[1].name, pos, 100, 2)
	local biter = surface.create_entity({name = biter_pool[1].name, position = valid_pos})	
	return biter
end

local attack_group_count_thresholds = {
			{0, 1},
			{50, 2},
			{100, 3},
			{150, 4},
			{200, 5},
			{1000, 6},
			{2000, 7},
			{3000, 8}
		}
		
local function get_number_of_attack_groups()	
	local n = 1
	for _, entry in pairs(attack_group_count_thresholds) do
		if global.wave_count >= entry[1] then
			n = entry[2]
		end
	end
	return n
end

local function clear_corpses(surface)
	local area = {{x = -256, y = -256}, {x = 256, y = 256}}
	for _, entity in pairs(surface.find_entities_filtered{area = area, type = "corpse"}) do
		if math_random(1,2) == 1 then
			entity.destroy()
		end
	end
end

local function spawn_boss_units(surface)
	if not boss_waves[global.wave_count] then return end
	if global.wave_count == 50 then game.print("The Big Biter Gang", {r = 0.7, g = 0.1, b = 0.1}) end
	if global.wave_count == 100 then game.print("Biterzilla", {r = 0.7, g = 0.1, b = 0.1}) end
	if global.wave_count == 150 then game.print("The Spitter Squad", {r = 0.7, g = 0.1, b = 0.1}) end
	local position = {x = 216, y = 0}
	local biter_group = surface.create_unit_group({position = position})
	for _, entry in pairs(boss_waves[global.wave_count]) do
		for x = 1, entry.count, 1 do
			local pos = surface.find_non_colliding_position(entry.name, position, 64, 3)
			if pos then
				local biter = surface.create_entity({name = entry.name, position = pos})
				biter_group.add_member(biter)
			end
		end
	end	
	biter_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
				{
					type=defines.command.attack_area,
					destination={x = -32, y = 0},
					radius=16,
					distraction=defines.distraction.by_anything
				},
				{
					type=defines.command.attack,
					target=global.market,
					distraction=defines.distraction.by_enemy
				}
			}
		})
end

local function wake_up_idle_biters(surface)
	surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.by_enemy
			},
		unit_count = 500,
		force = "enemy",
		unit_search_distance=64
		})
	
	surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.none
			},
		unit_count = 100,
		force = "enemy",
		unit_search_distance=16
		})
	
	local units = surface.find_entities_filtered({type = "unit", area = {{192, -256},{360, 256}}})
	for _, unit in pairs(units) do		
		unit.set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
					{
						type=defines.command.attack_area,
						destination={x = -160, y = 0},
						radius=16,
						distraction=defines.distraction.by_anything
					},					
					{
						type=defines.command.attack_area,
						destination={x = -80, y = 0},
						radius=16,
						distraction=defines.distraction.by_anything
					},					
					{
						type=defines.command.attack,
						target=global.market,
						distraction=defines.distraction.by_enemy
					}
				}
			})
	end
end

local function biter_attack_wave()
	if not global.market then return end		
	if global.wave_grace_period then return end
	local surface = game.surfaces["fish_defender"]
	
	clear_corpses(surface)
	wake_up_idle_biters(surface)
	
	if surface.count_entities_filtered({type = "unit", area = {{-128,-256},{360, 256}}}) > biter_count_limit then
		game.print("Biter limit reached, wave stalled.", {r = 0.7, g = 0.1, b = 0.1})
		return 
	end
	
	if not global.wave_count then
		global.wave_count = 1
	else
		global.wave_count = global.wave_count + 1
	end
				
	if global.wave_count % 50 == 0 then
		game.print("Boss Wave " .. global.wave_count, {r = 0.7, g = 0.1, b = 0.1})
		global.attack_wave_threat = global.wave_count * 10
		spawn_boss_units(surface)
	else
		global.attack_wave_threat = global.wave_count * 5
	end
	
	if global.attack_wave_threat > 35000 then global.attack_wave_threat = 35000 end
	
	local evolution = global.wave_count * 0.00125
	if evolution > 1 then evolution = 1 end
	game.forces.enemy.evolution_factor = evolution
	
	if game.forces.enemy.evolution_factor == 1 then
		if not global.endgame_modifier then
			global.endgame_modifier = 1
			game.print("Endgame enemy evolution reached. Biter damage is rising...", {r = 0.7, g = 0.1, b = 0.1})
		else
			global.endgame_modifier = global.endgame_modifier + 1
		end
	end			
	
	local units = surface.find_entities_filtered({force = "player", area = {{160, -256},{360, 256}}})
	for _, unit in pairs(units) do
		if unit.health then
			unit.health = unit.health - math_random(75, 125)
			surface.create_entity({name = "water-splash", position = unit.position})
			if unit.health <= 0 then unit.die("enemy") end
		else
			if unit.type == "entity-ghost" then
				unit.destroy()
			end
		end		
	end
		
	local spawn_x = 242
	local target_x = -32
	local group_coords = {}
	for a = -80, 80, 16 do
		insert(group_coords, {spawn = {x = spawn_x, y = a * 2}, target = {x = target_x, y = a}})
	end						
	group_coords = shuffle(group_coords)
	
	local unit_groups = {}
	if global.wave_count > 100 and math_random(1,3) == 1 then		
		for i = 1, #group_coords, 1 do
			unit_groups[i] = surface.create_unit_group({position = group_coords[i].spawn})
		end
	else	
		for i = 1, get_number_of_attack_groups(), 1 do
			unit_groups[i] = surface.create_unit_group({position = group_coords[i].spawn})
		end
	end

	local biter_pool = get_biter_pool()
	while global.attack_wave_threat > 0 do
		for i = 1, #unit_groups, 1 do
			local biter = spawn_biter(unit_groups[i].position, biter_pool)
			if biter then
				unit_groups[i].add_member(biter)
			else
				break
			end			
		end
	end
	
	for i = 1, #unit_groups, 1 do								
		unit_groups[i].set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
					{
						type=defines.command.attack_area,
						destination={group_coords[i].target.x + 180, group_coords[i].target.y},
						radius=32,
						distraction=defines.distraction.by_anything
					},
					{
						type=defines.command.attack_area,
						destination={group_coords[i].target.x + 120, group_coords[i].target.y},
						radius=32,
						distraction=defines.distraction.by_anything
					},
					{
						type=defines.command.attack_area,
						destination={group_coords[i].target.x + 60, group_coords[i].target.y},
						radius=32,
						distraction=defines.distraction.by_anything
					},
					{
						type=defines.command.attack_area,
						destination=group_coords[i].target,
						radius=32,
						distraction=defines.distraction.by_anything
					},
					{
						type=defines.command.attack,
						target=global.market,
						distraction=defines.distraction.by_enemy
					}
				}
		})			
	end
end

local function refresh_market_offers()
	if not global.market then return end
	for i = 1, 100, 1 do
		local a = global.market.remove_market_item(1)
		if a == false then break end
	end
	
	local str1 = "Gun Turret Slot for " .. tostring(global.entity_limits["gun-turret"].limit * global.entity_limits["gun-turret"].slot_price)
	str1 = str1 .. " Coins."
	
	local str2 = "Laser Turret Slot for " .. tostring(global.entity_limits["laser-turret"].limit * global.entity_limits["laser-turret"].slot_price)
	str2 = str2 .. " Coins."
	
	local str3 = "Artillery Slot for " .. tostring(global.entity_limits["artillery-turret"].limit * global.entity_limits["artillery-turret"].slot_price)
	str3 = str3 .. " Coins."
	
	local current_limit = 1
	if global.entity_limits["flamethrower-turret"].limit ~= 0 then current_limit = current_limit + global.entity_limits["flamethrower-turret"].limit end
	local str4 = "Flamethrower Turret Slot for " .. tostring(current_limit * global.entity_limits["flamethrower-turret"].slot_price)
	str4 = str4 .. " Coins."
	
	local str5 = "Landmine Slot for " .. tostring(global.entity_limits["land-mine"].limit * global.entity_limits["land-mine"].slot_price)
	str5 = str5 .. " Coins."
	
	local market_items = {
		{price = {}, offer = {type = 'nothing', effect_description = str1}},
		{price = {}, offer = {type = 'nothing', effect_description = str2}},
		{price = {}, offer = {type = 'nothing', effect_description = str3}},
		{price = {}, offer = {type = 'nothing', effect_description = str4}},
		{price = {}, offer = {type = 'nothing', effect_description = str5}},
		{price = {{"coin", 3}}, offer = {type = 'give-item', item = "raw-fish", count = 1}},
		{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'raw-wood', count = 8}},		
		{price = {{"coin", 8}}, offer = {type = 'give-item', item = 'grenade', count = 1}},
		{price = {{"coin", 32}}, offer = {type = 'give-item', item = 'cluster-grenade', count = 1}},
		{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'land-mine', count = 1}},
		{price = {{"coin", 80}}, offer = {type = 'give-item', item = 'car', count = 1}},
		{price = {{"coin", 1200}}, offer = {type = 'give-item', item = 'tank', count = 1}},
		{price = {{"coin", 3}}, offer = {type = 'give-item', item = 'cannon-shell', count = 1}},
		{price = {{"coin", 7}}, offer = {type = 'give-item', item = 'explosive-cannon-shell', count = 1}},
		{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'gun-turret', count = 1}},
		{price = {{"coin", 300}}, offer = {type = 'give-item', item = 'laser-turret', count = 1}},
		{price = {{"coin", 450}}, offer = {type = 'give-item', item = 'artillery-turret', count = 1}},
		{price = {{"coin", 16}}, offer = {type = 'give-item', item = 'artillery-shell', count = 1}},
		{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'artillery-targeting-remote', count = 1}},
		{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 1}},
		{price = {{"coin", 4}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 1}},				
		{price = {{"coin", 2}}, offer = {type = 'give-item', item = 'shotgun-shell', count = 1}},	
		{price = {{"coin", 6}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell', count = 1}},
		{price = {{"coin", 30}}, offer = {type = 'give-item', item = "submachine-gun", count = 1}},
		{price = {{"coin", 250}}, offer = {type = 'give-item', item = 'combat-shotgun', count = 1}},	
		{price = {{"coin", 450}}, offer = {type = 'give-item', item = 'flamethrower', count = 1}},	
		{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'flamethrower-ammo', count = 1}},	
		{price = {{"coin", 125}}, offer = {type = 'give-item', item = 'rocket-launcher', count = 1}},
		{price = {{"coin", 2}}, offer = {type = 'give-item', item = 'rocket', count = 1}},	
		{price = {{"coin", 7}}, offer = {type = 'give-item', item = 'explosive-rocket', count = 1}},
		{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'atomic-bomb', count = 1}},		
		{price = {{"coin", 90}}, offer = {type = 'give-item', item = 'railgun', count = 1}},
		{price = {{"coin", 5}}, offer = {type = 'give-item', item = 'railgun-dart', count = 1}},	
		{price = {{"coin", 40}}, offer = {type = 'give-item', item = 'poison-capsule', count = 1}},
		{price = {{"coin", 4}}, offer = {type = 'give-item', item = 'defender-capsule', count = 1}},	
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'light-armor', count = 1}},		
		{price = {{"coin", 125}}, offer = {type = 'give-item', item = 'heavy-armor', count = 1}},	
		{price = {{"coin", 350}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}},	
		{price = {{"coin", 1500}}, offer = {type = 'give-item', item = 'power-armor', count = 1}},
		{price = {{"coin", 12000}}, offer = {type = 'give-item', item = 'power-armor-mk2', count = 1}},
		{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'solar-panel-equipment', count = 1}},
		{price = {{"coin", 2250}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment', count = 1}},
		{price = {{"coin", 100}}, offer = {type = 'give-item', item = 'battery-equipment', count = 1}},				
		{price = {{"coin", 200}}, offer = {type = 'give-item', item = 'energy-shield-equipment', count = 1}},
		{price = {{"coin", 750}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment', count = 1}},	
		{price = {{"coin", 175}}, offer = {type = 'give-item', item = 'exoskeleton-equipment', count = 1}},		
		{price = {{"coin", 125}}, offer = {type = 'give-item', item = 'night-vision-equipment', count = 1}},
		{price = {{"coin", 200}}, offer = {type = 'give-item', item = 'belt-immunity-equipment', count = 1}},	
		{price = {{"coin", 250}}, offer = {type = 'give-item', item = 'personal-roboport-equipment', count = 1}},
		{price = {{"coin", 20}}, offer = {type = 'give-item', item = 'construction-robot', count = 1}}
	}
	
	for _, item in pairs(market_items) do
		global.market.add_market_item(item)
	end
end

local function get_sorted_list(column_name, score_list)		
	for x = 1, #score_list, 1 do
		for y = 1, #score_list, 1 do			
			if not score_list[y + 1] then break end
			if score_list[y][column_name] < score_list[y + 1][column_name] then
				local key = score_list[y]
				score_list[y] = score_list[y + 1]
				score_list[y + 1] = key
			end
		end		
	end	
	return score_list
end

local function get_mvps()
	if not global.score["player"] then return false end
	local score = global.score["player"]
	local score_list = {}
	for _, p in pairs(game.players) do
		local killscore = 0
		if score.players[p.name].killscore then killscore = score.players[p.name].killscore end
		local deaths = 0
		if score.players[p.name].deaths then deaths = score.players[p.name].deaths end
		local built_entities = 0
		if score.players[p.name].built_entities then built_entities = score.players[p.name].built_entities end
		local mined_entities = 0
		if score.players[p.name].mined_entities then mined_entities = score.players[p.name].mined_entities end
		table.insert(score_list, {name = p.name, killscore = killscore, deaths = deaths, built_entities = built_entities, mined_entities = mined_entities})		
	end
	local mvp = {}
	score_list = get_sorted_list("killscore", score_list)
	mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
	score_list = get_sorted_list("deaths", score_list)
	mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
	score_list = get_sorted_list("built_entities", score_list)
	mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
	return mvp
end

local function is_game_lost()
	if global.market then return end

	for _, player in pairs(game.connected_players) do
		if player.gui.left["fish_defense_game_lost"] then return end
		local f = player.gui.left.add({ type = "frame", name = "fish_defense_game_lost", caption = "The fish market was overrun! The biters are having a feast :3", direction = "vertical"})
		f.style.font_color = {r = 0.65, g = 0.1, b = 0.99}
		
		local t = f.add({type = "table", column_count = 2})
		local l = t.add({type = "label", caption = "Survival Time >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		
		if global.market_age >= 216000 then
			local l = t.add({type = "label", caption = math.floor(((global.market_age / 60) / 60) / 60) .. " hours " .. math.ceil((global.market_age % 216000 / 60) / 60) .. " minutes"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
		else
			local l = t.add({type = "label", caption = math.ceil((global.market_age % 216000 / 60) / 60) .. " minutes"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
		end
		
		local mvp = get_mvps()		
		if mvp then
			
			local l = t.add({type = "label", caption = "MVP Defender >> "})
			l.style.font = "default-listbox"
			l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
			local l = t.add({type = "label", caption = mvp.killscore.name .. " with a score of " .. mvp.killscore.score})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
			
			local l = t.add({type = "label", caption = "MVP Builder >> "})
			l.style.font = "default-listbox"
			l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
			local l = t.add({type = "label", caption = mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
			
			local l = t.add({type = "label", caption = "MVP Deaths >> "})
			l.style.font = "default-listbox"
			l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
			local l = t.add({type = "label", caption = mvp.deaths.name .. " died " .. mvp.deaths.score .. " times"})						
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
		end
		
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_lost", volume_modifier=1}
		end
	end
	
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_distance = 15
	game.map_settings.enemy_expansion.settler_group_min_size = 15
	game.map_settings.enemy_expansion.settler_group_max_size = 30
	game.map_settings.enemy_expansion.min_expansion_cooldown = 600
	game.map_settings.enemy_expansion.max_expansion_cooldown = 600
end

local biter_building_inhabitants = {
	[1] = {{"small-biter",8,16}},
	[2] = {{"small-biter",12,24}},
	[3] = {{"small-biter",8,16},{"medium-biter",1,2}},
	[4] = {{"small-biter",4,8},{"medium-biter",4,8}},
	[5] = {{"small-biter",3,5},{"medium-biter",8,12}},
	[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}},
	[7] = {{"medium-biter",6,8},{"big-biter",3,5}},
	[8] = {{"medium-biter",2,4},{"big-biter",6,8}},
	[9] = {{"medium-biter",2,3},{"big-biter",7,9}},
	[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}
}

local function damage_entities_in_radius(position, radius, damage)
	if radius > 8 then radius = 8 end
	local entities_to_damage = game.surfaces["fish_defender"].find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})
	for _, entity in pairs(entities_to_damage) do
		if entity.health and entity.name ~= "land-mine" then
			if entity.force.name ~= "enemy" then
				if entity.name == "player" then
					entity.damage(damage, "enemy")
				else
					entity.health = entity.health - damage
					entity.surface.create_entity({name = "explosion", position = entity.position})
					if entity.health <= 0 then entity.die("enemy") end
				end
			end
		end
	end
end

local coin_earnings = {
	["small-biter"] = 1,
	["medium-biter"] = 2,
	["big-biter"] = 3,
	["behemoth-biter"] = 5,
	["small-spitter"] = 1,
	["medium-spitter"] = 2,
	["big-spitter"] = 3,
	["behemoth-spitter"] = 5,
	["spitter-spawner"] = 32,
	["biter-spawner"] = 32	
}

local entities_that_earn_coins = {
		["artillery-turret"] = true,
		["gun-turret"] = true,
		["laser-turret"] = true,
		["flamethrower-turret"] = true
	}	
	
local function on_entity_died(event)
	if event.entity.force.name == "enemy" then
		local players_to_reward = {}
		local reward_has_been_given = false
		if event.cause then
			if event.entity.type == "unit" or event.entity.type == "unit-spawner" then
				if event.cause.name == "player" then
					insert(players_to_reward, event.cause)
					reward_has_been_given = true
				end			
				if event.cause.type == "car" then
					player = event.cause.get_driver()
					passenger = event.cause.get_passenger()
					if player then insert(players_to_reward, player.player)	end
					if passenger then insert(players_to_reward, passenger.player) end
					reward_has_been_given = true
				end
				if event.cause.type == "locomotive" then
					train_passengers = event.cause.train.passengers			
					if train_passengers then
						for _, passenger in pairs(train_passengers) do
							insert(players_to_reward, passenger)
						end
						reward_has_been_given = true
					end
				end
				for _, player in pairs(players_to_reward) do
					player.insert({name = "coin", count = coin_earnings[event.entity.name]})
				end
				
				if entities_that_earn_coins[event.cause.name] then
					event.entity.surface.spill_item_stack(event.cause.position,{name = "coin", count = coin_earnings[event.entity.name]}, true)
					reward_has_been_given = true
				end								
			end
		end		
				
		if reward_has_been_given == false and coin_earnings[event.entity.name] then
			event.entity.surface.spill_item_stack(event.entity.position,{name = "coin", count = coin_earnings[event.entity.name]}, true) 
		end
		
		if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
			local e = math.ceil(game.forces.enemy.evolution_factor*10, 0)
			for _, t in pairs (biter_building_inhabitants[e]) do
				for x = 1, math.random(t[2],t[3]), 1 do
					local p = event.entity.surface.find_non_colliding_position(t[1] , event.entity.position, 6, 1)
					if p then event.entity.surface.create_entity {name=t[1], position=p} end
				end
			end
		end

		if event.entity.name == "medium-biter" then
			event.entity.surface.create_entity({name = "explosion", position = event.entity.position})
			local damage = 25
			if global.endgame_modifier then damage = 25 + math.ceil((global.endgame_modifier * 0.025), 0) end
			if damage > 75 then damage = 75 end
			damage_entities_in_radius(event.entity.position, 1 + math.floor(global.wave_count * 0.001), damage)
		end

		if event.entity.name == "big-biter" then
			event.entity.surface.create_entity({name = "uranium-cannon-shell-explosion", position = event.entity.position})
			local damage = 35
			if global.endgame_modifier then damage = 50 + math.ceil((global.endgame_modifier * 0.05), 0) end
			if damage > 150 then damage = 150 end
			damage_entities_in_radius(event.entity.position, 2 + math.floor(global.wave_count * 0.001), damage)
		end

		if event.entity.name == "behemoth-biter" then
			local spawn_entity = false
			if global.endgame_modifier then																				
				if global.endgame_modifier > 500 then
					spawn_entity = "big-worm-turret"
				else
					spawn_entity = "medium-worm-turret"
				end														
			end
						
			if spawn_entity then
				local surface = event.entity.surface
				if surface.count_entities_filtered({area = {{event.entity.position.x - 5, event.entity.position.y - 5},{event.entity.position.x + 5, event.entity.position.y + 5}}, name = spawn_entity}) == 0 then	
					surface.create_entity({name = "blood-explosion-huge", position = event.entity.position})
					surface.create_entity({name = spawn_entity, position = event.entity.position})
				end
			end
		end
		
		return
	end
	
	if event.entity == global.market then
		global.market = nil
		global.market_age = game.tick
		is_game_lost()
	end
	
	if global.entity_limits[event.entity.name] then
		global.entity_limits[event.entity.name].placed = global.entity_limits[event.entity.name].placed - 1
	end
end

local function on_entity_damaged(event)
	if event.cause then
		if event.cause.name == "big-spitter" then
			local surface = event.cause.surface
			local area = {{event.entity.position.x - 3, event.entity.position.y - 3}, {event.entity.position.x + 3, event.entity.position.y + 3}}
			if surface.count_entities_filtered({area = area, name = "small-biter", limit = 3}) < 3 then
				local pos = surface.find_non_colliding_position("small-biter", event.entity.position, 4, 0.5)
				if pos then surface.create_entity({name = "small-biter", position = pos}) end
			end
		end

		if event.cause.name == "behemoth-spitter" then
			local surface = event.cause.surface
			local area = {{event.entity.position.x - 3, event.entity.position.y - 3}, {event.entity.position.x + 3, event.entity.position.y + 3}}
			if surface.count_entities_filtered({area = area, name = "medium-biter", limit = 3}) < 3 then
				local pos = surface.find_non_colliding_position("medium-biter", event.entity.position, 4, 0.5)
				if pos then surface.create_entity({name = "medium-biter", position = pos}) end
			end
		end

		if event.cause.force.name == "enemy" then
			if global.endgame_modifier then
				event.entity.health = event.entity.health - (event.final_damage_amount * global.endgame_modifier * 0.002)
				if event.entity.health <= 0 then event.entity.die() end
			end
		end
	end
	if event.entity.valid then
		if event.entity.name == "market" then
			if event.cause then
				if event.cause.force.name == "enemy" then return end
			end
			event.entity.health = event.entity.health + event.final_damage_amount
		end
	end
end


local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.fish_defense_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["stone"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["copper-ore"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["iron-ore"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["crude-oil"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			["grass"] = {frequency = "normal", size = "normal", richness = "normal"},
			["sand"] = {frequency = "normal", size = "normal", richness = "normal"},
			["desert"] = {frequency = "normal", size = "normal", richness = "normal"},
			["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
		}		
		game.create_surface("fish_defender", map_gen_settings)							
		local surface = game.surfaces["fish_defender"]
		
		local radius = 256
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
		
		game.map_settings.enemy_expansion.enabled = false
		game.map_settings.enemy_evolution.destroy_factor = 0
		game.map_settings.enemy_evolution.time_factor = 0
		game.map_settings.enemy_evolution.pollution_factor = 0					
		
		--game.forces["player"].set_turret_attack_modifier("flamethrower-turret", -0.5)
		game.forces["player"].technologies["flamethrower-damage-1"].enabled = false	
		game.forces["player"].technologies["flamethrower-damage-2"].enabled = false
		game.forces["player"].technologies["flamethrower-damage-3"].enabled = false
		game.forces["player"].technologies["flamethrower-damage-4"].enabled = false
		game.forces["player"].technologies["flamethrower-damage-5"].enabled = false
		game.forces["player"].technologies["flamethrower-damage-6"].enabled = false
		game.forces["player"].technologies["flamethrower-damage-7"].enabled = false
		game.forces["player"].technologies["gun-turret-damage-1"].enabled = false	
		game.forces["player"].technologies["gun-turret-damage-2"].enabled = false
		game.forces["player"].technologies["gun-turret-damage-3"].enabled = false
		game.forces["player"].technologies["gun-turret-damage-4"].enabled = false
		game.forces["player"].technologies["gun-turret-damage-5"].enabled = false
		game.forces["player"].technologies["gun-turret-damage-6"].enabled = false
		game.forces["player"].technologies["gun-turret-damage-7"].enabled = false
		game.forces["player"].technologies["laser-turret-speed-6"].enabled = false
		game.forces["player"].technologies["laser-turret-speed-7"].enabled = false
		
		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 0.5)				
		
		global.entity_limits = {
			["gun-turret"] = {placed = 1, limit = 1, str = "gun turret", slot_price = 100},
			["laser-turret"] = {placed = 0, limit = 1, str = "laser turret", slot_price = 300},
			["artillery-turret"] = {placed = 0, limit = 1, str = "artillery turret", slot_price = 500},
			["flamethrower-turret"] =  {placed = 0, limit = 0, str = "flamethrower turret", slot_price = 35000},
			["land-mine"] =  {placed = 0, limit = 1, str = "mine", slot_price = 1}
		}
		
		global.wave_grace_period = wave_interval * 21
		
		global.fish_defense_init_done = true
	end

	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["fish_defender"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {-75, 4}, 50, 1), "fish_defender")
	else
		if player.online_time < 2 then
			player.teleport({-50, 0}, "fish_defender")
		end
	end
			
	create_wave_gui(player)
	
	if game.tick > 900 then
		is_game_lost()
	end
end

local function get_replacement_tile(surface)
	local tilename = "grass-1"
	for x = -160, 160, 1 do
		for y = -96, 90, 1 do
			local tile = surface.get_tile(x, y)
			if tile.name ~= "water" and tile.name ~= "deepwater" then
				tilename = tile.name
			end
		end
	end
	return tilename	
end

local map_height = 96

local function on_chunk_generated(event)
	local surface = game.surfaces["fish_defender"]
	
	if not surface then return end
	if surface.name ~= event.surface.name then return end
		
	local area = event.area
	local left_top = area.left_top

	local entities = surface.find_entities_filtered({area = area, force = "enemy"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end	
	
	if left_top.x >= 160 then
		if not global.spawn_ores_generated then
		
			local spawn_position_x = -76
								
			surface.create_entity({name = "electric-beam", position = {160, -95}, source = {160, -95}, target = {160,96}})
								
			local tiles = {}
			local replacement_tile = get_replacement_tile(surface)
			local water_tiles = surface.find_tiles_filtered({name = {"water", "deepwater"}})
			
			for _, tile in pairs(water_tiles) do
				insert(tiles, {name = replacement_tile, position = {tile.position.x, tile.position.y}})
			end				
			surface.set_tiles(tiles, true)
			
			local entities = surface.find_entities_filtered({type = "resource", area = {{-160, -96},{160, 96}}})
			for _, entity in pairs(entities) do
				entity.destroy()
			end											
			
			local decorative_names = {}
			for k,v in pairs(game.decorative_prototypes) do
				if v.autoplace_specification then
				  decorative_names[#decorative_names+1] = k
				end
			 end
			for x = -4, 4, 1 do
				for y = -3, 3, 1 do
					surface.regenerate_decorative(decorative_names, {{x,y}})
				end
			end
			
			map_functions.draw_smoothed_out_ore_circle({x = -128, y = -64}, "copper-ore", surface, 15, 2500)
			map_functions.draw_smoothed_out_ore_circle({x = -128, y = -32}, "iron-ore", surface, 15, 2500)
			map_functions.draw_smoothed_out_ore_circle({x = -128, y = 32}, "coal", surface, 15, 1500)
			map_functions.draw_smoothed_out_ore_circle({x = -128, y = 64}, "stone", surface, 15, 1500)			
			map_functions.draw_noise_tile_circle({x = -96, y = 0}, "water", surface, 16)		
			map_functions.draw_oil_circle({x = -128, y = 0}, "crude-oil", surface, 8, 200000)
			
			local pos = surface.find_non_colliding_position("market",{spawn_position_x, 0}, 50, 1)										
			global.market = surface.create_entity({name = "market", position = pos, force = "player"})
			global.market.minable = false
			refresh_market_offers()
			
			local pos = surface.find_non_colliding_position("gun-turret",{spawn_position_x + 5, 1}, 50, 1)
			local turret = surface.create_entity({name = "gun-turret", position = pos, force = "player"})
			turret.insert({name = "firearm-magazine", count = 32})
			
			for x = -20, 20, 1 do
				for y = -20, 20, 1 do
					local pos = {x = global.market.position.x + x, y = global.market.position.y + y}
					local distance_to_center = math.sqrt(x^2 + y^2)
					if distance_to_center > 8 and distance_to_center < 15 then
						if math_random(1,3) == 1 and surface.can_place_entity({name = "wooden-chest", position = pos, force = "player"}) then
							local chest = surface.create_entity({name = "wooden-chest", position = pos, force = "player"})
						end
					end
				end
			end
			
			local area = {{x = -160, y = -96}, {x = 160, y = 96}}
			for _, tile in pairs(surface.find_tiles_filtered({name = "water", area = area})) do
				if math_random(1,16) == 1 then
					surface.create_entity({name = "fish", position = tile.position})
				end
			end
			
			local pos = surface.find_non_colliding_position("player",{spawn_position_x + 1, 4}, 50, 1)
			game.forces["player"].set_spawn_position(pos, surface)
			for _, player in pairs(game.connected_players) do
				local pos = surface.find_non_colliding_position("player",{spawn_position_x + 1, 4}, 50, 1)
				player.teleport(pos, surface)
			end
					
			global.spawn_ores_generated = true
		end				
	end		
	
	local tiles = {}
	local hourglass_center_piece_length = 64
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if pos.y >= map_height then
				if pos.y > pos.x - hourglass_center_piece_length and pos.x > 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
				if pos.y > (pos.x + hourglass_center_piece_length) * -1 and pos.x <= 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
			end
			if pos.y < map_height * -1 then
				if pos.y < (pos.x - hourglass_center_piece_length) * -1 and pos.x > 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
				if pos.y < pos.x + hourglass_center_piece_length and pos.x <= 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
			end
		end
	end

	surface.set_tiles(tiles, false)


	if left_top.x < 160 then return end

	local entities = surface.find_entities_filtered({area = area, type = "tree"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end

	local entities = surface.find_entities_filtered({area = area, type = "cliff"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end

	local entities = surface.find_entities_filtered({area = area, type = "resource"})
	for _, entity in pairs(entities) do
		surface.create_entity({name = "uranium-ore", position = entity.position, amount = math_random(200, 8000)})
		entity.destroy()
	end

	local tiles = {}
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}

			local tile = surface.get_tile(pos)
			if tile.name ~= "out-of-map" then
				if pos.x > 312 then
					insert(tiles, {name = "out-of-map", position = pos})
				else
					--insert(tiles, {name = "dirt-7", position = pos})
				end
				
				if pos.x > 296 and pos.x < 312 and math_random(1, 128) == 1 then				
					if surface.can_place_entity({name = "biter-spawner", force = "enemy", position = pos}) then
						if math_random(1,4) == 1 then
							local entity = surface.create_entity({name = "spitter-spawner", force = "player", position = pos})						
							entity.active = false
							entity.destructible = false
						else						
							local entity = surface.create_entity({name = "biter-spawner", force = "player", position = pos})						
							entity.active = false
							entity.destructible = false
						end
					end
				end
			end		
		end
	end
	surface.set_tiles(tiles, true)

	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	surface.regenerate_decorative(decorative_names, {{x=math.floor(event.area.left_top.x/32),y=math.floor(event.area.left_top.y/32)}})
end

local function on_built_entity(event)
	local entity = event.created_entity
	if global.entity_limits[entity.name] then
		local surface = entity.surface
		
		if global.entity_limits[entity.name].placed < global.entity_limits[entity.name].limit then
			global.entity_limits[entity.name].placed = global.entity_limits[entity.name].placed + 1		
			surface.create_entity(
				{name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].placed .. " / " .. global.entity_limits[entity.name].limit .. " " .. global.entity_limits[entity.name].str .. "s", color = {r=0.98, g=0.66, b=0.22}}
				)
		else
			surface.create_entity({name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].str .. " limit reached.", color = {r=0.82, g=0.11, b=0.11}})			 
			local player = game.players[event.player_index]			
			player.insert({name = entity.name, count = 1})
			if global.score then
				if global.score[player.force.name] then
					if global.score[player.force.name].players[player.name] then
						global.score[player.force.name].players[player.name].built_entities = global.score[player.force.name].players[player.name].built_entities - 1
					end
				end
			end		
			entity.destroy()
		end
	end
end

local function on_robot_built_entity(event)
	local entity = event.created_entity
	if global.entity_limits[entity.name] then
		local surface = entity.surface		
		if global.entity_limits[entity.name].placed < global.entity_limits[entity.name].limit then
			global.entity_limits[entity.name].placed = global.entity_limits[entity.name].placed + 1		
			surface.create_entity(
				{name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].placed .. " / " .. global.entity_limits[entity.name].limit .. " " .. global.entity_limits[entity.name].str .. "s", color = {r=0.98, g=0.66, b=0.22}}
				)
		else
			surface.create_entity({name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].str .. " limit reached.", color = {r=0.82, g=0.11, b=0.11}})
			local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
			inventory.insert({name = entity.name, count = 1})
			entity.destroy()												
		end
	end
end

local function on_tick()
	if game.tick % 30 == 0 then		
		if global.market then
			for _, player in pairs(game.connected_players) do
				create_wave_gui(player)
			end					
		end
		if game.tick % 180 == 0 then
			if game.surfaces["fish_defender"] then
				game.forces.player.chart(game.surfaces["fish_defender"], {{x = -64, y = -256}, {x = 288, y = 256}})
			end
		end
		
		if global.market_age then
			if not global.game_restart_timer then
				global.game_restart_timer = 7200
			else
				if global.game_restart_timer < 0 then return end
				global.game_restart_timer = global.game_restart_timer - 30
			end
			if global.game_restart_timer % 900 == 0 then 
				if global.game_restart_timer > 0 then game.print("Map will restart in " .. global.game_restart_timer / 60 .. " seconds!", { r=0.22, g=0.88, b=0.22}) end
				if global.game_restart_timer == 0 then
					game.print("Map is restarting!", { r=0.22, g=0.88, b=0.22})
					game.write_file("commandPipe", ":loadscenario --force", false, 0)
				end							
			end
		end
	end

	if game.tick % wave_interval == wave_interval - 1 then
		biter_attack_wave()
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if player.position.x >= 160 then
		player.teleport({player.position.x - 1, player.position.y}, game.surfaces["fish_defender"])
		if player.position.y > map_height or player.position.y < map_height * -1 then
			player.teleport({player.position.x, 0}, game.surfaces["fish_defender"])
		end
		if player.character then
			player.character.health = player.character.health - 25
			player.character.surface.create_entity({name = "water-splash", position = player.position})
			if player.character.health <= 0 then player.character.die("enemy") end
		end
	end
end

local function on_player_mined_entity(event)
	if global.entity_limits[event.entity.name] then
		global.entity_limits[event.entity.name].placed = global.entity_limits[event.entity.name].placed - 1
	end
end

local function on_robot_mined_entity(event)
	if global.entity_limits[event.entity.name] then
		global.entity_limits[event.entity.name].placed = global.entity_limits[event.entity.name].placed - 1
	end
end

local function on_market_item_purchased(event)
	local player = game.players[event.player_index]	
	local market = event.market
	local offer_index = event.offer_index	
	local offers = market.get_market_items()	
	local bought_offer = offers[offer_index].offer	
	if bought_offer.type ~= "nothing" then return end
	local slot_upgrade_offers = {
		[1] = {"gun-turret", "gun turret"},
		[2] = {"laser-turret", "laser turret"},
		[3] = {"artillery-turret", "artillery turret"},
		[4] = {"flamethrower-turret", "flamethrower turret"},
		[5] = {"land-mine", "land mine"}
	}
	for x = 1, 5, 1 do
		if offer_index == x then
						
			local price = global.entity_limits[slot_upgrade_offers[x][1]].limit * global.entity_limits[slot_upgrade_offers[x][1]].slot_price
			
			if slot_upgrade_offers[x][1] == "flamethrower-turret" then
				price = (global.entity_limits[slot_upgrade_offers[x][1]].limit + 1) * global.entity_limits[slot_upgrade_offers[x][1]].slot_price
			end			
			
			local coins_removed = player.remove_item({name = "coin", count = price})		
			if coins_removed ~= price then
				if coins_removed > 0 then
					player.insert({name = "coin", count = coins_removed})
				end
				player.print("Not enough coins.", {r = 0.22, g = 0.77, b = 0.44})
				return
			end
			global.entity_limits[slot_upgrade_offers[x][1]].limit = global.entity_limits[slot_upgrade_offers[x][1]].limit + 1
			game.print(player.name .. " has bought a " .. slot_upgrade_offers[x][2] .. " slot for " .. price .. " coins!", {r = 0.22, g = 0.77, b = 0.44})
			refresh_market_offers()
		end
	end
end	

local function on_research_finished(event)
	local research = event.research.name
	if research ~= "tanks" then return end
	game.forces["player"].technologies["artillery"].researched=true
	game.forces.player.recipes["artillery-wagon"].enabled = false
end

event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_research_finished, on_research_finished)	
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
event.add(defines.events.on_tick, on_tick)