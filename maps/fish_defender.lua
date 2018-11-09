-- fish defense -- by mewmew --

local event = require 'utils.event'
require "maps.fish_defender_map_intro"
require "maps.fish_defender_kaboomsticks"
--require "maps.tools.teleporters"
local market_items = require "maps.fish_defender_market_items"
local map_functions = require "maps.tools.map_functions"
local math_random = math.random
local insert = table.insert
local wave_interval = 5400

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
	local frame = player.gui.top.add({ type = "frame", name = "fish_defense_waves"})
	frame.style.maximal_height = 38

	local wave_count = 0
	if global.wave_count then wave_count = global.wave_count / 2 end

	local label = frame.add({ type = "label", caption = "Wave: " .. wave_count })
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-listbox"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local next_level_progress = game.tick % wave_interval / wave_interval

	local progressbar = frame.add({ type = "progressbar", value = next_level_progress})
	progressbar.style.minimal_width = 120
	progressbar.style.maximal_width = 120
	progressbar.style.top_padding = 10

end

local function get_biters()
	local surface = game.surfaces[1]
	local biters_found = {}
	for x = 256, 8000, 32 do
		if not surface.is_chunk_generated({math.ceil(x / 32, 0), 0}) then return biters_found end
		local area = {
					left_top = {x = x, y = -1024},
					right_bottom = {x = x + 32, y = 1024}
				}
		local entities = surface.find_entities_filtered({area = area, type = "unit", limit = global.wave_count})
		for _, entity in pairs(entities) do
			if #biters_found > global.wave_count then break end
			insert(biters_found, entity)
		end
		if #biters_found >= global.wave_count then return biters_found end
	end
end

local function biter_attack_wave()
	if not global.market then return end		
	
	local surface = game.surfaces[1]
	if not global.wave_count then
		global.wave_count = 2
	else
		global.wave_count = global.wave_count + 2
	end

	if game.forces.enemy.evolution_factor > 0.9 then
		if not global.endgame_modifier then
			global.endgame_modifier = 0.01
			game.print("Endgame enemy evolution reached. Biter damage is rising...", {r = 0.7, g = 0.1, b = 0.1})
		else
			global.endgame_modifier = global.endgame_modifier + 0.01
		end
	end

	--game.print("Wave " .. tostring(global.wave_count / 2) .. " incoming!", {r = 0.9, g = 0.05, b = 0.4})

	local group_coords = {
		{spawn = {x = 256, y = 0}, target = {x = 0, y = 0}}
		}
	local number_of_groups = 1

	if global.wave_count > 50 then
		group_coords = {
			{spawn = {x = 256, y = -160}, target = {x = -32, y = -64}},
			{spawn = {x = 256, y = -128}, target = {x = -32, y = -64}},
			{spawn = {x = 256, y = -96}, target = {x = -32, y = -48}},
			{spawn = {x = 256, y = -64}, target = {x = -32, y = -32}},
			{spawn = {x = 256, y = -32}, target = {x = -32, y = -16}},
			{spawn = {x = 256, y = 0}, target = {x = -32, y = 0}},
			{spawn = {x = 256, y = 32}, target = {x = -32, y = 16}},
			{spawn = {x = 256, y = 64}, target = {x = -32, y = 32}},
			{spawn = {x = 256, y = 96}, target = {x = -32, y = 48}},
			{spawn = {x = 256, y = 128}, target = {x = -32, y = 64}},
			{spawn = {x = 256, y = 160}, target = {x = -32, y = 64}}
		}
		number_of_groups = math.ceil(global.wave_count / 100, 0)
    if number_of_groups > #group_coords then number_of_groups = #group_coords end
	end

	group_coords = shuffle(group_coords)

	local biters = get_biters()

	local max_group_size = math.ceil(global.wave_count / number_of_groups, 0)
	if max_group_size > 200 then max_group_size = 200 end

	local biter_counter = 0
	local biter_attack_groups = {}
	for i = 1, number_of_groups, 1 do
		if biter_counter > global.wave_count then break end
		biter_attack_groups[i] = surface.create_unit_group({position=group_coords[i].spawn})
		for x = 1, max_group_size, 1 do
			biter_counter = biter_counter + 1
			if biter_counter > global.wave_count then break end
			if not biters[biter_counter] then break end
			biter_attack_groups[i].add_member(biters[biter_counter])
		end
		
		if number_of_groups == 1 then
			biter_attack_groups[i].set_command({type=defines.command.attack , target=global.market, distraction=defines.distraction.by_enemy})
		else
			if math_random(1,6) == 1 then
				biter_attack_groups[i].set_command({type=defines.command.attack , target=global.market, distraction=defines.distraction.by_enemy})
			else
				biter_attack_groups[i].set_command({type=defines.command.attack_area, destination=group_coords[i].target, radius=12, distraction=defines.distraction.by_anything})
			end
		end
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

local function damage_entities_in_radius(position, radius, damage)
	local entities_to_damage = game.surfaces[1].find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})
	for _, entity in pairs(entities_to_damage) do
		if entity.health then
			if entity.force.name ~= "enemy" then
				if entity.name == "player" then
					entity.damage(damage, "enemy")
				else
					entity.health = entity.health - damage
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
	["behemoth-spitter"] = 5	
}

local function on_entity_died(event)
	if event.entity.force.name == "enemy" then
		if event.cause then
			if event.cause.name == "player" and event.entity.type == "unit" then
				event.cause.insert({name = "coin", count = coin_earnings[event.entity.name]})
			end
		end
		--if math_random(1, 150) == 1 then
			--spill_loot(event.entity.position)
		--end

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
			if global.endgame_modifier then damage = 25 + math.ceil((global.endgame_modifier * 25), 0) end
			damage_entities_in_radius(event.entity.position, 1, damage)
		end

		if event.entity.name == "big-biter" then
			event.entity.surface.create_entity({name = "uranium-cannon-shell-explosion", position = event.entity.position})
			local damage = 35
			if global.endgame_modifier then damage = 50 + math.ceil((global.endgame_modifier * 50), 0) end
			damage_entities_in_radius(event.entity.position, 2, damage)
		end

		return
	end

	if event.entity == global.market then
		global.market = nil
		global.market_age = game.tick
		is_game_lost()
	end
end

local function on_entity_damaged(event)
	if event.cause then
		if event.cause.name == "big-spitter" then
			local surface = event.cause.surface
			local area = {{event.entity.position.x - 3, event.entity.position.y - 3}, {event.entity.position.x + 3, event.entity.position.y + 3}}
			if surface.count_entities_filtered({area = area, name = "small-biter", limit = 3}) < 3 then
				local pos = surface.find_non_colliding_position("small-biter", event.entity.position, 3, 1)
				surface.create_entity({name = "small-biter", position = pos})
			end
		end

		if event.cause.name == "behemoth-spitter" then
			local surface = event.cause.surface
			local area = {{event.entity.position.x - 3, event.entity.position.y - 3}, {event.entity.position.x + 3, event.entity.position.y + 3}}
			if surface.count_entities_filtered({area = area, name = "medium-biter", limit = 3}) < 3 then
				local pos = surface.find_non_colliding_position("medium-biter", event.entity.position, 3, 1)
				surface.create_entity({name = "medium-biter", position = pos})
			end
		end

		if event.cause.force.name == "enemy" then
			if global.endgame_modifier then
				event.entity.health = event.entity.health - (event.final_damage_amount * global.endgame_modifier)
			end
		end
	end

	if event.entity.name == "market" then
		if event.cause.force.name == "enemy" then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end


end


local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.fish_defense_init_done then
		local surface = game.surfaces[1]

		game.map_settings.enemy_expansion.enabled = false

		game.map_settings.enemy_evolution.destroy_factor = 0.008
		game.map_settings.enemy_evolution.time_factor = 0.00005
		game.map_settings.enemy_evolution.pollution_factor = 0.000015
		
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false

		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 0.5)
		
		local pos = surface.find_non_colliding_position("player",{4, 0}, 50, 1)
		game.players[1].teleport(pos, surface)
		
		local pos = surface.find_non_colliding_position("market",{0, 0}, 50, 1)
					
			
			--[[
			map_functions.draw_noise_tile_circle({x = 10, y = 0}, replacement_tile, surface, 16)			
			local decorative_names = {}
			for k,v in pairs(game.decorative_prototypes) do
				if v.autoplace_specification then
				  decorative_names[#decorative_names+1] = k
				end
			 end
			local regen_coords = {}
			surface.regenerate_decorative(decorative_names, {{x=0,y=0}})
			surface.regenerate_decorative(decorative_names, {{x=0,y=-1}})
			surface.regenerate_decorative(decorative_names, {{x=-1,y=0}})
			surface.regenerate_decorative(decorative_names, {{x=-1,y=-1}})	
			]]
			
			global.market = surface.create_entity({name = "market", position = pos, force = "player"})
			global.market.minable = false
			for _, item in pairs(market_items) do
				global.market.add_market_item(item)
			end
		

		local radius = 512
		game.forces.player.chart(game.players[1].surface,{{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})

		surface.create_entity({name = "electric-beam", position = {160, -95}, source = {160, -95}, target = {160,96}})		
		
		game.players[1].insert({name = "gun-turret", count = 1})
		
		
		
		global.fish_defense_init_done = true
	end

	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 32})
		player.insert({name = "iron-plate", count = 64})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
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
	
	if left_top.x >= -160 and left_top.x < 160 then
		local entities = surface.find_entities_filtered({area = area, type = "resource"})
		for _, entity in pairs(entities) do
			entity.destroy()
		end
		
		local tiles = {}
		if global.market.position then
			local replacement_tile = surface.get_tile(global.market.position)
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local pos = {x = left_top.x + x, y = left_top.y + y}
					local tile = surface.get_tile(pos)
					if tile.name == "deepwater" or tile.name == "water" then
						insert(tiles, {name = replacement_tile.name, position = pos})
					end
				end
			end
			surface.set_tiles(tiles, true)
		end		
	end
	
	if left_top.x >= 256 then
		if not global.spawn_ores_generated then
			map_functions.draw_smoothed_out_ore_circle({x = -64, y = -64}, "copper-ore", surface, 15, 2500)
			map_functions.draw_smoothed_out_ore_circle({x = -64, y = -32}, "iron-ore", surface, 15, 2500)
			map_functions.draw_smoothed_out_ore_circle({x = -64, y = 32}, "coal", surface, 15, 1500)
			map_functions.draw_smoothed_out_ore_circle({x = -64, y = 64}, "stone", surface, 15, 1500)	
			map_functions.draw_noise_tile_circle({x = -32, y = 0}, "water", surface, 16)			
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
				insert(tiles, {name = "dirt-6", position = pos})
			end

			if left_top.x > 256 and math_random(1,32) == 1 then
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
	surface.set_tiles(tiles, true)

	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	surface.regenerate_decorative(decorative_names, {{x=math.floor(event.area.left_top.x/32),y=math.floor(event.area.left_top.y/32)}})

end

local build_limit_radius = 24
local function on_built_entity(event)
	if "flamethrower-turret" == event.created_entity.name then
		event.created_entity.die()
		return
	end

	if event.created_entity.name == "gun-turret" then
		local surface = event.created_entity.surface
		local area = {{event.created_entity.position.x - build_limit_radius, event.created_entity.position.y - build_limit_radius}, {event.created_entity.position.x + build_limit_radius, event.created_entity.position.y + build_limit_radius}}
		local turrets_count_in_area = surface.count_entities_filtered({area = area, name = "gun-turret", limit = 2})

		if turrets_count_in_area <= 1 then
			--surface.create_entity({name = "flying-text", position = event.created_entity.position, text = turrets_count_in_area .. " / 2 Turrets built in area", color = {r=0.98, g=0.66, b=0.22}})
		else
			surface.create_entity({name = "flying-text", position = event.created_entity.position, text = "Too many turrets in area", color = {r=0.82, g=0.11, b=0.11}})
			if event.player_index then
				local player = game.players[event.player_index]
				event.created_entity.destroy()
				player.insert({name = "gun-turret", count = 1})
				if global.score then
					if global.score[player.force.name] then
						if global.score[player.force.name].players[player.name] then
							global.score[player.force.name].players[player.name].built_entities = global.score[player.force.name].players[player.name].built_entities - 1
						end
					end
				end
				return
			else
				event.created_entity.die()
				return
			end
		end
	end

	if event.created_entity.name == "laser-turret" then
		local surface = event.created_entity.surface
		local area = {{event.created_entity.position.x - build_limit_radius, event.created_entity.position.y - build_limit_radius}, {event.created_entity.position.x + build_limit_radius, event.created_entity.position.y + build_limit_radius}}
		local turrets_count_in_area = surface.count_entities_filtered({area = area, name = "laser-turret", limit = 2})

		if turrets_count_in_area <= 1 then
			--surface.create_entity({name = "flying-text", position = event.created_entity.position, text = turrets_count_in_area .. " / 1 Turrets built in area", color = {r=0.98, g=0.66, b=0.22}})
		else
			surface.create_entity({name = "flying-text", position = event.created_entity.position, text = "Too many turrets in area", color = {r=0.82, g=0.11, b=0.11}})
			if event.player_index then
				local player = game.players[event.player_index]
				event.created_entity.destroy()
				player.insert({name = "laser-turret", count = 1})
				if global.score then
					if global.score[player.force.name] then
						if global.score[player.force.name].players[player.name] then
							global.score[player.force.name].players[player.name].built_entities = global.score[player.force.name].players[player.name].built_entities - 1
						end
					end
				end
				return
			else
				event.created_entity.die()
				return
			end
		end
	end
end

local function on_robot_built_entity(event)
	on_built_entity(event)
end

local function on_tick()
	if game.tick % 30 == 0 then
		if global.market then
			for _, player in pairs(game.connected_players) do
				create_wave_gui(player)
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
		player.teleport({player.position.x - 1, player.position.y}, game.surfaces[1])
		if player.position.y > map_height or player.position.y < map_height * -1 then
			player.teleport({player.position.x, 0}, game.surfaces[1])
		end
		if player.character then
			player.character.health = player.character.health - 25
			player.character.surface.create_entity({name = "water-splash", position = player.position})
			if player.character.health <= 0 then player.character.die("enemy") end
		end
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
