
local Math = require 'maps.pirates.math'
local Memory = require 'maps.pirates.memory'
local Balance = require 'maps.pirates.balance'
local CoreData = require 'maps.pirates.coredata'
local Common = require 'maps.pirates.common'
local inspect = require 'utils.inspect'.inspect

local Public = {}

-- @TODO: rewrite in terms of more sensible raffle
function Public.buried_treasure_loot()
	local ret
	
	local rng = Math.random(1000)
	if rng <= 150 then
		ret = {name = 'steel-plate', count = 150}
	elseif rng <= 200 then
		ret = {name = 'construction-robot', count = 15}
	elseif rng <= 330 then
		ret = {name = 'electronic-circuit', count = 150}
	elseif rng <= 400 then
		ret = {name = 'advanced-circuit', count = 40}
	elseif rng <= 530 then
		ret = {name = 'crude-oil-barrel', count = 10}
	elseif rng <= 600 then
		ret = {name = 'effectivity-module-3', count = 3}
	elseif rng <= 730 then
		ret = {name = 'effectivity-module-2', count = 6}
	elseif rng <= 800 then
		ret = {name = 'plastic-bar', count = 60}
	elseif rng <= 860 then
		ret = {name = 'chemical-science-pack', count = 15}
	elseif rng <= 930 then
		ret = {name = 'assembling-machine-3', count = 2}
	elseif rng <= 995 then
		ret = {name = 'solar-panel', count = 7}
	else
		ret = {name = 'modular-armor', count = 1}
	end
	return ret
end

Public.chest_loot_data_raw = {
	-- pirate-ship specific loot, which dominates:
	{20, -1, 0.5, true, 'splitter', 4, 12},
	-- {20, -1, 0.5, true, 'underground-belt', 4, 12},
	{40, -0.5, 0.5, true, 'firearm-magazine', 10, 48},
	{60, -1, 1, true, 'piercing-rounds-magazine', 4, 16},
	{20, 0, 1, false, 'assembling-machine-2', 1, 3},
	{20, 0, 1, false, 'solar-panel', 2, 5},
	{40, -1, 1, true, 'speed-module', 1, 3},
	{40, 0, 1, true, 'speed-module-2', 1, 3},
	{40, 0, 2, true, 'speed-module-3', 1, 3},
	{4, -1, 1, true, 'effectivity-module', 1, 3},
	{4, 0, 1, true, 'effectivity-module-2', 1, 3},
	{4, 0, 2, true, 'effectivity-module-3', 1, 3},
	{10, 0, 1, false, 'uranium-rounds-magazine', 3, 6},
	{10, 0, 1, false, 'fast-transport-belt', 6, 24},
	-- {10, 0, 1, false, 'fast-underground-belt', 2, 5},
	{10, 0, 1, false, 'fast-splitter', 2, 5},
	{12, 0, 1, false, 'artillery-shell', 1, 1},
	{40, 0, 1, false, 'rail-signal', 10, 30},
	{40, 0, 1, false, 'medium-electric-pole', 2, 5},
	{2, 0.2, 1, false, 'electric-engine-unit', 1, 1},

	{4, 0, 2, true, 'rocket-launcher', 1, 1},
	{8, 0, 2, true, 'rocket', 16, 32},

	-- copying over most of those i made for chronotrain:
	--always there (or normally always there):
	{4, 0, 1, false, 'pistol', 1, 2},
	{1, 0, 1, false, 'gun-turret', 2, 4},
	{6, 0, 1, false, 'grenade', 2, 12},
	{4, 0, 1, false, 'stone-wall', 12, 50},
	-- {4, 0, 1, false, 'gate', 14, 32}, --can beat biters with them
	{1, 0, 1, false, 'radar', 1, 2},
	{3, 0, 1, false, 'small-lamp', 8, 32},
	{2, 0, 1, false, 'electric-mining-drill', 2, 4},
	{3, 0, 1, false, 'long-handed-inserter', 4, 16},
	{0.5, 0, 1, false, 'filter-inserter', 2, 12},
	{0.2, 0, 1, false, 'stack-filter-inserter', 2, 6},
	{0.2, 0, 1, false, 'slowdown-capsule', 2, 4},
	{0.2, 0, 1, false, 'destroyer-capsule', 2, 4},
	{0.2, 0, 1, false, 'defender-capsule', 2, 4},
	{0.2, 0, 1, false, 'distractor-capsule', 2, 4},
	-- {0.25, 0, 1, false, 'rail', 50, 100},
	-- {0.25, 0, 1, false, 'uranium-rounds-magazine', 1, 4},
	{1, 0.15, 1, false, 'pump', 1, 2},
	{2, 0.15, 1, false, 'pumpjack', 1, 3},
	{0.02, 0.15, 1, false, 'oil-refinery', 1, 2},
	{3, 0, 1, false, 'effectivity-module', 1, 4},
	{3, 0, 1, false, 'speed-module', 1, 4},
	{3, 0, 1, false, 'productivity-module', 1, 4},
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
	{0.25, 0.6, 1, false, 'express-loader', 1, 2},
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
	{3, 0.2, 1.8, true, 'stack-inserter', 4, 8},
	{3, 0.2, 1.4, true, 'big-electric-pole', 4, 8},
	{2, 0.3, 1, true, 'rocket-fuel', 4, 10},
	{5, 0.4, 0.7, true, 'cannon-shell', 16, 32},
	{5, 0.4, 0.8, true, 'explosive-cannon-shell', 16, 32},
	{5, 0.2, 1.8, true, 'cluster-grenade', 8, 16},
	-- {5, 0.2, 1.4, true, 'construction-robot', 5, 25},
	-- {2, 0.25, 1.75, true, 'logistic-robot', 5, 25},
	{2, 0.25, 1.75, true, 'substation', 2, 4},
	{3, 0.25, 1.75, true, 'assembling-machine-3', 2, 4},
	{3, 0.25, 1.75, true, 'express-transport-belt', 10, 60},
	-- {3, 0.25, 1.75, true, 'express-underground-belt', 2, 6},
	{3, 0.25, 1.75, true, 'express-splitter', 1, 3},
	{3, 0.25, 1.75, true, 'electric-furnace', 2, 4},
	{3, 0.25, 1.75, true, 'laser-turret', 1, 4},
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

function Public.chest_loot_data()
	local ret = {}
	local loot_data = Public.chest_loot_data_raw
	for i = 1, #loot_data do
		local loot_data_item = loot_data[i]
		ret[#ret + 1] = {
            weight = loot_data_item[1],
            game_completion_progress_min = loot_data_item[2],
            game_completion_progress_max = loot_data_item[3],
            scaling = loot_data_item[4],
            name = loot_data_item[5],
            min_count = loot_data_item[6],
            max_count = loot_data_item[7],
            map_subtype = loot_data_item[8]
        }
	end
	return ret
end

function Public.wooden_chest_loot()
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0
	local num = Math.random(1,3)

	return Public.chest_loot(num, 40/100 * Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress())
end

function Public.iron_chest_loot()
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0
	local num = Math.random(3,4)

	local loot = Public.chest_loot(num, 5/100 + 40/100 * Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress())
	loot[#loot + 1] = {name = 'coin', count = Math.random(1,1500)}

    return loot
end

function Public.covered_wooden_chest_loot()
	local memory = Memory.get_crew_memory()
	local overworldx = memory.overworldx or 0
	local num = 2

	local loot = Public.chest_loot(num, 20/100 + 40/100 * Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress())

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
	local ret = {}
	local rng = Math.random()
	local memory = Memory.get_crew_memory()

	-- if rng < 20/100 then
	-- 	ret = {
	-- 		{name = 'iron-plate', count = 50},
	-- 	}
	-- elseif rng < 40/100 then
	-- 	ret = {
	-- 		{name = 'copper-plate', count = 50},
	-- 	}
	-- else
	-- 	ret = {
	-- 		{name = 'coal', count = 50},
	-- 	}
	-- end

	local loot_data = Public.chest_loot_data()
    local loot_types, loot_weights = {}, {}
    for i = 1, #loot_data, 1 do
        table.insert(loot_types, {['name'] = loot_data[i].name, ['min_count'] = loot_data[i].min_count, ['max_count'] = loot_data[i].max_count})

		local destination = Common.current_destination()
		if not (destination and destination.subtype and loot_data[i].map_subtype and loot_data[i].map_subtype == destination.subtype) then
			if loot_data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
				local midpoint = (loot_data[i].game_completion_progress_max + loot_data[i].game_completion_progress_min) / 2
				local difference = (loot_data[i].game_completion_progress_max - loot_data[i].game_completion_progress_min)
				table.insert(loot_weights, loot_data[i].weight * Math.max(0, 1 - (Math.abs(game_completion_progress - midpoint) / (difference / 2))))
			else -- no scaling
				if loot_data[i].game_completion_progress_min <= game_completion_progress and loot_data[i].game_completion_progress_max >= game_completion_progress then
					table.insert(loot_weights, loot_data[i].weight)
				else
					table.insert(loot_weights, 0)
				end
			end
		end
    end

	for _ = 1, number_of_items do
        local loot = Math.raffle(loot_types, loot_weights)
        local low = Math.max(1, Math.ceil(loot.min_count))
        local high = Math.max(1, Math.ceil(loot.max_count))
        local _count = Math.random(low, high)
        local lucky = Math.random(1, 180)
        if lucky == 1 then --lucky
            _count = _count * 3
        elseif lucky <= 10 then
            _count = _count * 2
        end
        ret[#ret + 1] = {name = loot.name, count = _count}
    end

	return ret
end

return Public