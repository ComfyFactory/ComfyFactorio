
local Math = require 'maps.pirates.math'
local Memory = require 'maps.pirates.memory'
local Balance = require 'maps.pirates.balance'
local CoreData = require 'maps.pirates.coredata'
local Common = require 'maps.pirates.common'
local inspect = require 'utils.inspect'.inspect

local Public = {}

Public.buried_treasure_loot_data_raw = {
	{100, 0, 999, false, 'coin', 10, 20},
	{100, 0, 999, false, 'steel-plate', 140, 180},
	{50, 0, 999, false, 'defender-capsule', 5, 18},
	{25, 0, 999, false, 'distractor-capsule', 5, 18},
	{10, 0, 999, false, 'destroyer-capsule', 5, 18},
	{20, 0, 999, false, 'flying-robot-frame', 20, 35},
	{40, 0, 999, false, 'construction-robot', 15, 25},
	{100, 0, 999, false, 'electronic-circuit', 150, 250},
	{70, 0, 999, false, 'advanced-circuit', 20, 40},
	{150, 0, 999, false, 'crude-oil-barrel', 25, 45},
	{70, 0, 999, false, 'effectivity-module-3', 3, 4},
	{70, 0, 999, false, 'speed-module-3', 3, 4},
	{10, 0, 999, false, 'productivity-module-3', 3, 4},
	{70, 0, 999, false, 'plastic-bar', 40, 70},
	{60, 0, 999, false, 'chemical-science-pack', 12, 24},
	{70, 0, 999, false, 'assembling-machine-3', 2, 2},
	{65, 0, 999, false, 'solar-panel', 7, 8},
	{20, 0, 999, false, 'radar', 10, 20},
	{10, 0, 999, false, 'production-science-pack', 12, 24},
	{5, 0, 999, false, 'modular-armor', 1, 1},
	{5, 0, 999, false, 'laser-turret', 1, 1},
	{5, 0, 999, false, 'cannon-shell', 5, 10},
	{50, 0, 999, false, 'artillery-shell', 4, 8},
	{50, 0, 999, false, 'express-transport-belt', 8, 20},
	{35, 0, 999, false, 'express-underground-belt', 4, 4},
	{35, 0, 999, false, 'express-splitter', 4, 11},
	{50, 0, 999, false, 'stack-inserter', 4, 12},
}

Public.chest_loot_data_raw = {
	-- pirate-ship specific loot, which dominates:
	{20, -1, 0.5, true, 'splitter', 4, 12},
	-- {20, -1, 0.5, true, 'underground-belt', 4, 12},
	{40, -0.5, 0.5, true, 'firearm-magazine', 10, 48},
	{60, -1, 1, true, 'piercing-rounds-magazine', 8, 18},
	{20, 0, 999, false, 'assembling-machine-2', 1, 3},
	{20, 0, 999, false, 'solar-panel', 2, 5},
	{40, -1, 999, true, 'speed-module', 1, 3},
	{40, 0, 999, true, 'speed-module-2', 1, 3},
	{40, 0, 2, true, 'speed-module-3', 1, 3},
	{4, -1, 1, true, 'effectivity-module', 1, 3},
	{4, 0, 1, true, 'effectivity-module-2', 1, 3},
	{4, 0, 2, true, 'effectivity-module-3', 1, 3},
	{10, 0, 999, false, 'uranium-rounds-magazine', 3, 6},
	{10, 0, 999, false, 'fast-transport-belt', 6, 24},
	-- {10, 0, 999, false, 'fast-underground-belt', 2, 5},
	{10, 0, 999, false, 'fast-splitter', 2, 5},
	{12, 0, 999, false, 'artillery-shell', 1, 1},
	{40, 0, 999, false, 'rail-signal', 10, 30},
	{40, 0, 999, false, 'medium-electric-pole', 2, 5},
	{2, 0.2, 999, false, 'electric-engine-unit', 1, 1},

	{4, 0, 2, true, 'rocket-launcher', 1, 1},
	{8, 0, 2, true, 'rocket', 16, 32},

	{3, 0, 0.5, false, 'stack-inserter', 1, 3},
	{1, 0, 0.5, false, 'stack-filter-inserter', 1, 3},
	{3, 0.5, 999, false, 'stack-inserter', 5, 16},
	{1, 0.5, 999, false, 'stack-filter-inserter', 5, 16},

	-- copying over most of those i made for chronotrain:
	--always there (or normally always there):
	{4, 0, 999, false, 'pistol', 1, 2},
	{1, 0, 999, false, 'gun-turret', 2, 4},
	{6, 0, 999, false, 'grenade', 2, 12},
	{4, 0, 999, false, 'stone-wall', 12, 50},
	-- {4, 0, 999, false, 'gate', 14, 32}, --can beat biters with them
	{1, 0, 999, false, 'radar', 1, 2},
	{3, 0, 999, false, 'small-lamp', 8, 32},
	{2, 0, 999, false, 'electric-mining-drill', 2, 4},
	{3, 0, 999, false, 'long-handed-inserter', 4, 16},
	{0.5, 0, 999, false, 'filter-inserter', 2, 12},
	{0.2, 0, 999, false, 'slowdown-capsule', 2, 4},
	{0.2, 0, 999, false, 'destroyer-capsule', 2, 4},
	{0.2, 0, 999, false, 'defender-capsule', 2, 4},
	{0.2, 0, 999, false, 'distractor-capsule', 2, 4},
	-- {0.25, 0, 999, false, 'rail', 50, 100},
	-- {0.25, 0, 999, false, 'uranium-rounds-magazine', 1, 4},
	{1, 0.15, 999, false, 'pump', 1, 2},
	{2, 0.15, 999, false, 'pumpjack', 1, 3},
	{0.02, 0.15, 999, false, 'oil-refinery', 1, 2},
	{3, 0, 999, false, 'effectivity-module', 1, 4},
	{3, 0, 999, false, 'speed-module', 1, 4},
	{3, 0, 999, false, 'productivity-module', 1, 4},
	--shotgun meta:
	{10, -0.2, 0.4, true, 'shotgun-shell', 12, 24},
	{5, 0, 0.4, true, 'shotgun', 1, 1},
	{3, 0.4, 1.2, true, 'piercing-shotgun-shell', 4, 9},
	{2, 0.4, 1.2, true, 'combat-shotgun', 1, 1},
	--modular armor meta:
	{0.7, 0.25, 1, true, 'modular-armor', 1, 1},
	-- {0.4, 0.5, 1, true, 'power-armor', 1, 1},
	-- {0.5, -1,3, true, "power-armor-mk2", 1, 1},
	{3, 0.1, 1, true, 'solar-panel-equipment', 1, 2},
	{2, 0.1, 1, true, 'battery-equipment', 1, 1},
	{1.6, 0.2, 1, true, 'energy-shield-equipment', 1, 2},
	{0.8, 0.1, 1, true, 'night-vision-equipment', 1, 1},
	{0.4, 0.5, 1.5, true, 'personal-laser-defense-equipment', 1, 1},
	--loader meta:
	{0.25, 0, 0.2, false, 'loader', 1, 2},
	{0.25, 0.2, 0.6, false, 'fast-loader', 1, 2},
	{0.25, 0.6, 999, false, 'express-loader', 1, 2},
	--science meta:
	{8, -0.5, 0.5, true, 'automation-science-pack', 4, 32},
	{8, -0.6, 0.6, true, 'logistic-science-pack', 4, 32},
	{6, -0.1, 1, true, 'military-science-pack', 8, 32},
	{6, 0.2, 1.4, true, 'chemical-science-pack', 16, 32},
	-- {6, 0.3, 1.5, true, 'production-science-pack', 16, 32},
	{4, 0.4, 1.5, true, 'utility-science-pack', 16, 32},
	-- {10, 0.5, 1.5, true, 'space-science-pack', 16, 32},

	--early-game:
	--{3, -0.1, 0.2, false, "railgun-dart", 2, 4},
	-- {3, -0.1, 0.1, true, 'wooden-chest', 8, 40},
	{5, -0.1, 0.1, true, 'burner-inserter', 8, 20},
	{1, -0.2, 0.2, true, 'offshore-pump', 1, 3},
	{3, -0.2, 0.2, true, 'boiler', 3, 6},
	{3, 0, 0.1, true, 'lab', 1, 3},
	{3, -0.2, 0.2, true, 'steam-engine', 2, 4},
	-- {3, -0.2, 0.2, true, 'burner-mining-drill', 2, 4},
	{2, 0, 0.1, false, 'submachine-gun', 1, 1},
	{3, 0, 0.3, true, 'iron-chest', 8, 40},
	{4, 0, 0.1, false, 'light-armor', 1, 1},
	{4, -0.3, 0.3, true, 'inserter', 8, 16},
	{8, -0.3, 0.3, true, 'small-electric-pole', 16, 32},
	{6, -0.4, 0.4, true, 'stone-furnace', 8, 16},
	-- {1, -0.3, 0.3, true, 'underground-belt', 3, 10},
	{1, -0.3, 0.3, true, 'splitter', 1, 5},
	{1, -0.3, 0.3, true, 'assembling-machine-1', 2, 4},
	{5, -0.8, 0.8, true, 'transport-belt', 15, 100},
	--mid-game:
	--{6, 0.2, 0.5, false, "railgun-dart", 4, 8},
	{5, -0.2, 0.7, true, 'pipe', 30, 50},
	{1, -0.2, 0.7, true, 'pipe-to-ground', 4, 8},
	{5, -0.2, 0.7, true, 'iron-gear-wheel', 20, 80},
	{5, -0.2, 0.7, true, 'copper-cable', 30, 100},
	{5, -0.2, 0.7, true, 'electronic-circuit', 15, 100},
	{4, -0.1, 0.8, true, 'fast-transport-belt', 10, 60},
	-- {4, -0.1, 0.8, true, 'fast-underground-belt', 3, 10},
	{4, -0.1, 0.8, true, 'fast-splitter', 1, 5},
	{2, 0, 0.6, true, 'storage-tank', 2, 6},
	{2, 0, 0.5, true, 'heavy-armor', 1, 1},
	{3, 0, 0.7, true, 'steel-plate', 15, 100},
	-- {8, 0, 0.9, true, 'piercing-rounds-magazine', 10, 64},
	-- {4, 0.2, 0.6, true, 'engine-unit', 8, 16},
	{4, 0, 1, true, 'fast-inserter', 2, 12},
	{5, 0, 1, true, 'steel-furnace', 4, 8},
	{5, 0, 1, true, 'assembling-machine-2', 2, 4},
	{5, 0, 1, true, 'medium-electric-pole', 6, 20},
	{5, 0, 1, true, 'accumulator', 4, 8},
	{5, 0, 1, true, 'solar-panel', 3, 6},
	{8, 0, 1, true, 'steel-chest', 8, 16},
	{3, 0.2, 1, true, 'chemical-plant', 1, 3},
	--late-game:
	--{9, 0.5, 0.8, false, "railgun-dart", 8, 16},
	-- {5, 0, 1.2, true, 'land-mine', 16, 32},
	{4, 0.2, 1.2, true, 'lubricant-barrel', 4, 10},
	{1, 0.2, 1.2, true, 'battery', 10, 50},
	{5, 0.2, 1.8, true, 'explosive-rocket', 16, 32},
	{4, 0.2, 1.4, true, 'advanced-circuit', 15, 100},
	{3, 0.2, 1.4, true, 'big-electric-pole', 4, 8},
	{2, 0.3, 1, true, 'rocket-fuel', 4, 10},
	{5, 0.4, 0.7, true, 'cannon-shell', 16, 32},
	{5, 0.4, 0.8, true, 'explosive-cannon-shell', 16, 32},
	{5, 0.2, 1.8, true, 'cluster-grenade', 8, 16},
	-- {5, 0.2, 1.4, true, 'construction-robot', 5, 25},
	-- {2, 0.25, 1.75, true, 'logistic-robot', 5, 25},
	{2, 0.25, 1.75, true, 'substation', 2, 4},
	{3, 0.25, 1.75, true, 'assembling-machine-3', 2, 4},
	{3, 0.25, 1.75, true, 'express-transport-belt', 2, 20},
	-- {3, 0.25, 1.75, true, 'express-underground-belt', 2, 6},
	{3, 0.25, 1.75, true, 'express-splitter', 1, 3},
	{3, 0.25, 1.75, true, 'electric-furnace', 2, 4},
	-- {1, 0.25, 1.75, true, 'laser-turret', 1, 1},
	-- {4, 0.4, 1.6, true, 'processing-unit', 30, 200},
	{2, 0.6, 1.4, true, 'roboport', 1, 1},
	-- super late-game:
	--{9, 0.8, 1.2, false, "railgun-dart", 12, 20},
	-- {1, 0.9, 1.1, true, 'power-armor-mk2', 1, 1},
	-- {1, 0.8, 1.2, true, 'fusion-reactor-equipment', 1, 1}

	--{2, 0, 1, , "computer", 1, 1},
	--{1, 0.2, 1, , "railgun", 1, 1},
	--{1, 0.9, 1, , "personal-roboport-mk2-equipment", 1, 1},
}

function Public.wooden_chest_loot()
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0
	local num = 1

	return Public.chest_loot(num, Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress())
end

function Public.iron_chest_loot()
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0
	local num = Math.random(2,3)

	local loot = Public.chest_loot(num, 5/100 + Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress()) --reward higher difficulties with better loot
	loot[#loot + 1] = {name = 'coin', count = Math.random(1,1500)}

    return loot
end

function Public.covered_wooden_chest_loot()
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0
	local num = 2

	local loot = Public.chest_loot(num, 10/100 + Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress()) --reward higher difficulties with better loot

    return loot
end

function Public.stone_furnace_loot()
    return {
		{name = 'coal', count = 50},
	}
end
function Public.storage_tank_fluid_loot(force_crude_oil)
	local ret
	local rng = Math.random(10)
	if force_crude_oil then
		ret = {name = 'crude-oil', amount = Math.random(3000, 15000)}
	elseif rng < 6 then
		ret = {name = 'crude-oil', amount = Math.random(1000, 5000)}
	elseif rng == 7 then
		ret = {name = 'heavy-oil', amount = Math.random(1000, 4000)}
	elseif rng == 8 then
		ret = {name = 'lubricant', amount = Math.random(1000, 2000)}
	else
		ret = {name = 'petroleum-gas', amount = Math.random(1000, 4000)}
	end
    return ret
end

function Public.swamp_storage_tank_fluid_loot()
	local ret
	ret = {name = 'sulfuric-acid', amount = Math.random(500, 1500)}
    return ret
end

function Public.roboport_bots_loot()
    return {
		{name = 'logistic-robot', count = 5},
	}
    -- construction robots
end

function Public.chest_loot(number_of_items, game_completion_progress)
	local ret = Common.raffle_from_processed_loot_data(Common.processed_loot_data(Public.chest_loot_data_raw), number_of_items, game_completion_progress)

	local platesrng = Math.random(5)
	if platesrng <= 2 then
		ret[#ret + 1] = {name = 'iron-plate', count = 120}
	elseif platesrng <= 4 then
		ret[#ret + 1] = {name = 'copper-plate', count = 120}
	else
		ret[#ret + 1] = {name = 'steel-plate', count = 20}
	end

	return ret
end

function Public.buried_treasure_loot()
	local ret = Common.raffle_from_processed_loot_data(Common.processed_loot_data(Public.buried_treasure_loot_data_raw), 1, Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress())

	if ret and ret[1] then return ret[1] end
end

return Public