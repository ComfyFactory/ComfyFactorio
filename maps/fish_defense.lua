-- fish defense -- by mewmew -- 

local event = require 'utils.event'
require "maps.fish_defense_map_intro"
require "maps.fish_defense_kaboomsticks"
require "maps.tools.teleporters"
local math_random = math.random
local insert = table.insert

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function spill_loot(position)
	local chest_raffle = {}
	local chest_loot = {					
		{{name = "slowdown-capsule", count = math_random(4,8)}, weight = 1, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "poison-capsule", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "uranium-cannon-shell", count = math_random(8,16)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "cannon-shell", count = math_random(8,16)}, weight = 5, evolution_min = 0.4, evolution_max = 0.7},
		{{name = "explosive-uranium-cannon-shell", count = math_random(8,16)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "explosive-cannon-shell", count = math_random(8,16)}, weight = 5, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "shotgun", count = 1}, weight = 2, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "shotgun-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "combat-shotgun", count = 1}, weight = 3, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "piercing-shotgun-shell", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "flamethrower", count = 1}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "flamethrower-ammo", count = math_random(8,16)}, weight = 5, evolution_min = 0.3, evolution_max = 1},
		{{name = "rocket-launcher", count = 1}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "rocket", count = math_random(8,16)}, weight = 5, evolution_min = 0.2, evolution_max = 0.7},		
		{{name = "explosive-rocket", count = math_random(8,16)}, weight = 5, evolution_min = 0.3, evolution_max = 1},
		{{name = "land-mine", count = math_random(8,16)}, weight = 5, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "grenade", count = math_random(8,16)}, weight = 5, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "cluster-grenade", count = math_random(8,16)}, weight = 5, evolution_min = 0.4, evolution_max = 1},
		{{name = "firearm-magazine", count = math_random(16,48)}, weight = 5, evolution_min = 0, evolution_max = 0.3},
		{{name = "piercing-rounds-magazine", count = math_random(16,48)}, weight = 5, evolution_min = 0.1, evolution_max = 0.8},
		{{name = "uranium-rounds-magazine", count = math_random(16,48)}, weight = 5, evolution_min = 0.5, evolution_max = 1},
		{{name = "railgun", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "railgun-dart", count = math_random(16,32)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "defender-capsule", count = math_random(8,16)}, weight = 2, evolution_min = 0.0, evolution_max = 0.7},
		{{name = "distractor-capsule", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 1},
		{{name = "destroyer-capsule", count = math_random(8,16)}, weight = 2, evolution_min = 0.3, evolution_max = 1},
		--{{name = "atomic-bomb", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},		
		{{name = "light-armor", count = 1}, weight = 3, evolution_min = 0, evolution_max = 0.1},		
		{{name = "heavy-armor", count = 1}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "modular-armor", count = 1}, weight = 2, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "power-armor", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		--{{name = "power-armor-mk2", count = 1}, weight = 1, evolution_min = 0.9, evolution_max = 1},
		{{name = "battery-equipment", count = 1}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "battery-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		{{name = "belt-immunity-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "solar-panel-equipment", count = math_random(1,4)}, weight = 5, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "discharge-defense-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 0.8},
		{{name = "energy-shield-equipment", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "energy-shield-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "fusion-reactor-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "night-vision-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "personal-laser-defense-equipment", count = 1}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
								
		{{name = "iron-gear-wheel", count = math_random(25,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "copper-cable", count = math_random(50,100)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "engine-unit", count = math_random(8,16)}, weight = 2, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(8,16)}, weight = 2, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "battery", count = math_random(25,50)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "advanced-circuit", count = math_random(25,50)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "electronic-circuit", count = math_random(25,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "processing-unit", count = math_random(25,50)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "explosives", count = math_random(40,50)}, weight = 5, evolution_min = 0.0, evolution_max = 1},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, evolution_min = 0.3, evolution_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "computer", count = 2}, weight = 1, evolution_min = 0, evolution_max = 1},
		{{name = "steel-plate", count = math_random(25,75)}, weight = 2, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
				
		{{name = "burner-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},		
		{{name = "fast-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 1},
		{{name = "filter-inserter", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(4,8)}, weight = 1, evolution_min = 0.4, evolution_max = 1},
		{{name = "stack-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},				
		{{name = "small-electric-pole", count = math_random(16,24)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.2, evolution_max = 1},
		{{name = "big-electric-pole", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "substation", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "wooden-chest", count = math_random(16,24)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "iron-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 0.4},
		{{name = "steel-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "small-lamp", count = math_random(16,32)}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail", count = math_random(25,50)}, weight = 3, evolution_min = 0.1, evolution_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "assembling-machine-3", count = math_random(1,2)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "accumulator", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "offshore-pump", count = math_random(1,3)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "beacon", count = math_random(1,2)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "boiler", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "steam-engine", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "steam-turbine", count = math_random(1,2)}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		--{{name = "nuclear-reactor", count = 1}, weight = 1, evolution_min = 0.6, evolution_max = 1},
		{{name = "centrifuge", count = math_random(1,2)}, weight = 1, evolution_min = 0.6, evolution_max = 1},
		{{name = "heat-pipe", count = math_random(4,8)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-exchanger", count = math_random(2,4)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "arithmetic-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "constant-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "decider-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "power-switch", count = math_random(1,2)}, weight = 1, evolution_min = 0.1, evolution_max = 1},		
		{{name = "programmable-speaker", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "green-wire", count = math_random(25,55)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "red-wire", count = math_random(25,55)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "chemical-plant", count = math_random(1,3)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "burner-mining-drill", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		{{name = "express-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0, evolution_max = 0.3},		
		--{{name = "oil-refinery", count = math_random(2,4)}, weight = 2, evolution_min = 0.3, evolution_max = 1},
		{{name = "pipe", count = math_random(30,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(4,8)}, weight = 1, evolution_min = 0.2, evolution_max = 0.5},
		{{name = "pumpjack", count = math_random(1,3)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "pump", count = math_random(1,2)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "solar-panel", count = math_random(2,4)}, weight = 3, evolution_min = 0.4, evolution_max = 0.9},
		{{name = "electric-furnace", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "steel-furnace", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "stone-furnace", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "radar", count = math_random(1,2)}, weight = 1, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},		
		{{name = "stone-wall", count = math_random(25,75)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "gate", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "storage-tank", count = math_random(1,4)}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		--{{name = "express-loader", count = math_random(1,3)}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		--{{name = "fast-loader", count = math_random(1,3)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		--{{name = "loader", count = math_random(1,3)}, weight = 1, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "lab", count = math_random(1,2)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1}	
	}
	
	for _, t in pairs (chest_loot) do
		for x = 1, t.weight, 1 do
			if t.evolution_min <= game.forces.enemy.evolution_factor and t.evolution_max >= game.forces.enemy.evolution_factor then
				table.insert(chest_raffle, t[1])
			end
		end			
	end
	
	local loot = chest_raffle[math.random(1,#chest_raffle)]
	game.surfaces[1].spill_item_stack(position, loot, true)
			
end

local function create_wave_gui(player)
	if player.gui.top["fish_defense_waves"] then player.gui.top["fish_defense_waves"].destroy() end
	local b = player.gui.top.add({ type = "button", name = "fish_defense_waves", caption = "Wave: " .. (global.wave_count / 2) })
	b.style.font_color = {r=0.88, g=0.88, b=0.88}
	b.style.font = "default-listbox"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function increase_difficulty()
	if game.map_settings.enemy_expansion.max_expansion_cooldown < 7200 then return end
	game.map_settings.enemy_expansion.max_expansion_cooldown = game.map_settings.enemy_expansion.max_expansion_cooldown - 3600	 
end

local function get_biters()
	local surface = game.surfaces[1]
	local biters_found = {}					
	for x = 0, 8000, 32 do
		if not surface.is_chunk_generated({math.ceil(x / 32, 0), 0}) then return biters_found end
		local area = {
					left_top = {x = x, y = -96},
					right_bottom = {x = x + 32, y = 128}
				}
		local entities = surface.find_entities_filtered({area = area, type = "unit", limit = global.wave_count})
		for _, entity in pairs(entities) do
			if #biters_found > global.wave_count then break end
			insert(biters_found, entity)
		end
		if #biters_found >= global.wave_count then return biters_found end
	end		
end

local function get_group_coords()

end

local function biter_attack_wave()
	if not global.market then return end
	
	local surface = game.surfaces[1]
	if not global.wave_count then
		global.wave_count = 2
	else
		global.wave_count = global.wave_count + 2
	end
	
	for _, player in pairs(game.connected_players) do
		create_wave_gui(player)
	end
	
	game.print("Wave " .. tostring(global.wave_count / 2) .. " incoming!", {r = 0.9, g = 0.05, b = 0.4})
	
	if global.wave_count > 100 then				
		local biters = get_biters()		
		local group_coords = {
			{x = 175, y = -64},
			{x = 175, y = -32},
			{x = 175, y = 0},
			{x = 175, y = 32},
			{x = 175, y = 64},
			{x = 175, y = 96}
		}
		group_coords = shuffle(group_coords)
		
		local max_group_size = math.ceil(global.wave_count / #group_coords, 0)
		
		local biter_counter = 0
		local biter_attack_groups = {}
		for i = 1, #group_coords, 1 do
			if biter_counter > global.wave_count then break end 
			biter_attack_groups[i] = surface.create_unit_group({position=group_coords[i]})
			for x = 1, max_group_size, 1 do	
				biter_counter = biter_counter + 1
				if biter_counter > global.wave_count then break end				
				if not biters[biter_counter] then break end
				biter_attack_groups[i].add_member(biters[biter_counter])				
			end				
		end
				
		for _, group in pairs(biter_attack_groups) do	
			if math_random(1,6) == 1 then
				group.set_command({type=defines.command.attack , target=global.market, distraction=defines.distraction.by_enemy})
			else
				group.set_command({type=defines.command.attack_area, destination={x = group.position.x - 180, y = group.position.y}, radius=12, distraction=defines.distraction.by_anything})
			end
		end
		return
	end
	
	surface.set_multi_command{command = {type=defines.command.attack_area, destination=global.market.position, radius=2, distraction=defines.distraction.by_anything}, unit_count = global.wave_count, force = "enemy", unit_search_distance = 2000}
end

local function is_game_lost()
	if global.market then return end
	
	for _, player in pairs(game.connected_players) do
		if player.gui.left["fish_defense_game_lost"] then player.gui.left["fish_defense_game_lost"].destroy() end
		local f = player.gui.left.add({ type = "frame", name = "fish_defense_game_lost", caption = "The fish market was destroyed! ;_;" })
		f.style.font_color = {r = 0.6, g = 0.05, b = 0.9}
		f.add({type = "label", caption = "It survived for " .. math.ceil(((global.market_age / 60) / 60), 0) .. " minutes."})
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_won", volume_modifier=1}
		end
	end
end

local biter_building_inhabitants = {}
biter_building_inhabitants[1] = {{"small-biter",8,16}}
biter_building_inhabitants[2] = {{"small-biter",12,24}}
biter_building_inhabitants[3] = {{"small-biter",8,16},{"medium-biter",1,2}}
biter_building_inhabitants[4] = {{"small-biter",4,8},{"medium-biter",4,8}}
biter_building_inhabitants[5] = {{"small-biter",3,5},{"medium-biter",8,12}}
biter_building_inhabitants[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}}
biter_building_inhabitants[7] = {{"medium-biter",6,8},{"big-biter",3,5}}
biter_building_inhabitants[8] = {{"medium-biter",2,4},{"big-biter",6,8}}
biter_building_inhabitants[9] = {{"medium-biter",2,3},{"big-biter",7,9}}
biter_building_inhabitants[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}

local function on_entity_died(event)
	if event.entity.force.name == "enemy" then
		if math_random(1, 150) == 1 then
			spill_loot(event.entity.position)
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
			local entities_to_damage = event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 1, event.entity.position.y - 1},{event.entity.position.x + 1, event.entity.position.y + 1}}})
			for _, entity in pairs(entities_to_damage) do
				if entity.health then
					if entity.force.name ~= "enemy" then
						entity.health = entity.health - 25
						if entity.health <= 0 then entity.die("enemy") end
					end
				end
			end
		end
		
		if event.entity.name == "big-biter" then
			for x = 1, math_random(3, 5), 1 do
				local p = event.entity.surface.find_non_colliding_position("small-biter", event.entity.position, 5, 1)
				event.entity.surface.create_entity({name = "small-biter", position = p})
			end
			event.entity.surface.create_entity({name = "uranium-cannon-shell-explosion", position = event.entity.position})
			local entities_to_damage = event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 2, event.entity.position.y - 2},{event.entity.position.x + 2, event.entity.position.y + 2}}})
			for _, entity in pairs(entities_to_damage) do
				if entity.health then
					if entity.force.name ~= "enemy" then
						entity.health = entity.health - 50
						if entity.health <= 0 then entity.die("enemy") end
					end
				end
			end
		end
		
		--if event.entity.name == "behemoth-biter" then
			
		--end		
		
		return
	end
	
	if event.entity == global.market then
		global.market = nil
		global.market_age = game.tick
		is_game_lost()
	end
end

local function on_entity_damaged(event)
	if event.entity.name == "market" then
		if event.cause.force.name == "enemy" then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end


local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if not global.fish_defense_init_done then
		local surface = game.surfaces[1]
		
		game.map_settings.enemy_expansion.enabled = true
		game.map_settings.enemy_expansion.max_expansion_distance = 15
		game.map_settings.enemy_expansion.settler_group_min_size = 12
		game.map_settings.enemy_expansion.settler_group_max_size = 20
		game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
		game.map_settings.enemy_expansion.max_expansion_cooldown = 216000
				
		game.map_settings.enemy_evolution.destroy_factor = 0.008
		game.map_settings.enemy_evolution.time_factor = 0.000012 
		game.map_settings.enemy_evolution.pollution_factor = 0.000015
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false			
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false
		
		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 0.5)
		
		local pos = surface.find_non_colliding_position("market",{0, 0}, 50, 1)
		global.market = surface.create_entity({name = "market", position = pos, force = "player"})
		global.market.minable = false
		global.market.add_market_item({price = {{"coal", 3}}, offer = {type = 'give-item', item = "raw-fish", count = 1}})
		
		local radius = 512
		game.forces.player.chart(game.players[1].surface,{{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
		
		global.fish_defense_init_done = true
	end
	
	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 32})
		player.insert({name = "grenade", count = 3})
		player.insert({name = "iron-plate", count = 32})
		player.insert({name = "light-armor", count = 1})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = true end
	end
	
	if global.wave_count then create_wave_gui(player) end
	
	is_game_lost()
end

local map_height = 96
local function on_chunk_generated(event)
	local surface = game.surfaces[1]
	local area = event.area
	local left_top = area.left_top
		
	local entities = surface.find_entities_filtered({area = area, force = "enemy"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	
	local tiles = {}
	
	if left_top.y > map_height or left_top.y < map_height * -1 then
		for x = 0, 31, 1 do	
			for y = 0, 31, 1 do		
				local pos = {x = left_top.x + x, y = left_top.y + y}
				insert(tiles, {name = "out-of-map", position = pos})
			end
		end
	end
	surface.set_tiles(tiles, false)
	
	if left_top.x < 196 then return end
	
	local entities = surface.find_entities_filtered({area = area, type = "tree"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	
	local entities = surface.find_entities_filtered({area = area, type = "cliff"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	
	for x = 0, 31, 1 do	
		for y = 0, 31, 1 do		
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1,32) == 1 then
				if surface.can_place_entity({name = "biter-spawner", force = "enemy", position = pos}) then
					if math_random(1,4) == 1 then
						surface.create_entity({name = "spitter-spawner", force = "enemy", position = pos})
					else
						surface.create_entity({name = "biter-spawner", force = "enemy", position = pos})
					end
				end
			end
		end
	end
	
	for x = 0, 31, 1 do	
		for y = 0, 31, 1 do		
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, 16) == 1 then
				if surface.can_place_entity({name = "big-worm-turret", force = "enemy", position = pos}) then
					if math_random(1,2) == 1 then
						surface.create_entity({name = "big-worm-turret", force = "enemy", position = pos})
					else
						surface.create_entity({name = "big-worm-turret", force = "enemy", position = pos})
					end
				end
			end
		end
	end
end

local function on_built_entity(event)
	if "gun-turret" == event.created_entity.name or "flamethrower-turret" == event.created_entity.name or "laser-turret" == event.created_entity.name then
		event.created_entity.die()
	end
end

local function on_robot_built_entity(event)
	on_built_entity(event)
end

local function on_tick()
	if game.tick % 21600 == 10800 then
		increase_difficulty()		
	end
	
	if game.tick % 7200 == 3600 then
		biter_attack_wave()
	end	
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)