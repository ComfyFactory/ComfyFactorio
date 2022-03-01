
local Public = {}
local Math = require 'maps.pirates.math'
local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect


Public.base_extra_character_speed = 0.20

Public.technology_price_multiplier = 1


function Public.starting_boatEEIpower_production_MW()
	-- return 3 * Math.sloped(Common.capacity_scale(), 1/2) / 2 --/2 as we have 2
	return 3/2
end
function Public.starting_boatEEIelectric_buffer_size_MJ() --maybe needs to be at least the power_production
	-- return 3 * Math.sloped(Common.capacity_scale(), 1/2) / 2 --/2 as we have 2
	return 3/2
end
Public.EEI_stages = { --multipliers
	1,2,5,8,12
}


function Public.scripted_biters_pollution_cost_multiplier()
	return 1.33 --tuned
end

function Public.cost_to_leave_multiplier()
	return Common.difficulty()
end

Public.rocket_launch_coin_reward = 5000

function Public.crew_scale()
	return Common.activecrewcount()/10
end

function Public.silo_base_est_time()
	local T = Public.expected_time_on_island() * Public.crew_scale()^(2/10) --to undo some of the time scaling
	local est_secs
	if T > 0 then
		est_secs = T/6
	else
		est_secs = 60 * 6
	end
	if Common.overworldx() == 0 then est_secs = 60 * 2 end
	return est_secs
end

function Public.time_quest_seconds()
	return 2.8 * Public.silo_base_est_time()
end

function Public.silo_energy_needed_MJ()
	local est_secs = Public.silo_base_est_time()

	local est_base_power = 2*Public.starting_boatEEIpower_production_MW() * (1 + 0.05 * (Common.overworldx()/40)^(5/3))

	return est_secs * est_base_power
	-- return est_secs * est_base_power * Math.sloped(Common.difficulty(), 1/3)
end

function Public.silo_count()
	local E = Public.silo_energy_needed_MJ()
	return Math.ceil(E/(16.8*150)) --no more than 2.5 minutes to charge it
end


function Public.max_time_on_island_formula() --always >0  --tuned
	return 60 * (
			(32 + 2 * (Common.overworldx()/40)^(1/3))
	) / Public.crew_scale()^(65/100) / Math.sloped(Common.difficulty(), 1/4) --changed crew_scale factor significantly to help smaller crews
end


function Public.max_time_on_island()
	if Common.overworldx() == 0 or ((Common.overworldx()/40) > 20 and (Common.overworldx()/40) < 25) then
		return -1
	else
		return Math.ceil(Public.max_time_on_island_formula())
	end
end

function Public.expected_time_on_island() --always >0
	return 3/5 * Public.max_time_on_island_formula()
end

function Public.fuel_depletion_rate_static()
	if (not Common.overworldx()) then return 0 end

	local T = Public.expected_time_on_island()

	local rate
	if Common.overworldx() > 0 then
		rate = 380 * (0 + (Common.overworldx()/40)^(10/10)) * Public.crew_scale()^(1/6) * Math.sloped(Common.difficulty(), 3/5) / T --the extra player dependency accounts for the fact that even in compressed time, more players get more resources...
	else
		rate = 0
	end

	return -rate
end

function Public.fuel_depletion_rate_sailing()
	if (not Common.overworldx()) then return 0 end

	return - 8 * (1 + 0.13 * (Common.overworldx()/40)^(10/10))
end

function Public.silo_total_pollution()
	return (
		400 * (Common.difficulty()^(1.2)) * Public.crew_scale()^(2/5) * (3.2 + 0.7 * (Common.overworldx()/40)^(1.6)) --shape of the curve with x is tuned
)
end

function Public.boat_passive_pollution_per_minute(time)
	local boost = 1
	local T = Public.max_time_on_island_formula()
	if time then
		if time >= 90/100 * T then
			boost = 15
		elseif time >= 85/100 * T then
			boost = 8
		elseif time >= 80/100 * T then
			boost = 6
		elseif time >= 70/100 * T then
			boost = 4
		elseif time >= 55/100 * T then
			boost = 3
		elseif time >= 40/100 * T then
			boost = 2
		elseif time >= 25/100 * T then
			boost = 1.5
		end
	end

	return boost * (
			6 * Common.difficulty() * (Common.overworldx()/40)^(1.6) * (Public.crew_scale())^(60/100)
	 ) -- No T dependence! Is that the right idea? I wrote it this way earlier, and it can make sense, but I'm not 100% sure.
end


function Public.base_evolution()
	local evo = (0.0201 * (Common.overworldx()/40)) * Math.sloped(Common.difficulty(), 1/5)
	if Common.overworldx()/40 == 0 then evo = 0 end
	return evo
end

function Public.expected_time_evo()
	return 0.14
end

function Public.evolution_per_second()
	local destination = Common.current_destination()

	local T = Public.expected_time_on_island() --always greater than 0
	local rate = Public.expected_time_evo() / T
	if Common.overworldx() == 0 then rate = 0 end

	-- scale by biter nests remaining:
	if destination and destination.dynamic_data then
		local initial_spawner_count = destination.dynamic_data.initial_spawner_count
		if initial_spawner_count and initial_spawner_count > 0 then
			local surface = game.surfaces[destination.surface_name]
			if surface and surface.valid then
				rate = rate * Common.spawner_count(surface) / destination.dynamic_data.initial_spawner_count
			end
		end
	end

	return rate
end

function Public.evolution_per_biter_base_kill() --it's important to have evo go up with biter base kills, to provide resistance if you try to plow through all the bases
	local destination = Common.current_destination()
	if Common.overworldx() == 0 then return 0 end

	if destination and destination.dynamic_data and destination.dynamic_data.timer and destination.dynamic_data.timer > 0 and destination.dynamic_data.initial_spawner_count and destination.dynamic_data.initial_spawner_count > 0 then

		local initial_spawner_count = destination.dynamic_data.initial_spawner_count
		local time = destination.dynamic_data.timer
		local expected_time = Public.expected_time_on_island()
		if time > expected_time then return 0
		else
			-- evo it 'would have' contributed:
			return 1/initial_spawner_count * Public.expected_time_evo() * (expected_time - time)/expected_time
		end
	else
		return 0
	end

	-- return 0.003 * Common.difficulty()
end

function Public.evolution_per_full_silo_charge()
	return 0.06 --too low and you always charge immediately, too high and you always charge late
end

function Public.bonus_damage_to_humans()
	local ret = 0.125
	local diff = Common.difficulty()
	if diff <= 0.7 then ret = 0.1 end
	if diff >= 1.3 then ret = 0.15 end
	return ret
end


function Public.periodic_free_resources_per_x(x)
	return {
	}
	-- return {
	-- 	{name = 'iron-plate', count = Math.ceil(5 * (Common.overworldx()/40)^(2/3))},
	-- 	{name = 'copper-plate', count = Math.ceil(1 * (Common.overworldx()/40)^(2/3))},
	-- }
end

function Public.periodic_free_resources_per_destination_5_seconds(x)
	return {
	}
	-- return {
	-- 	{name = 'iron-ore', count = Math.ceil(7 * (Common.overworldx()/40)^(0.6))},
	-- 	{name = 'copper-ore', count = Math.ceil(3 * (Common.overworldx()/40)^(0.6))},
	-- }
end

function Public.class_resource_scale()
	return 1 / (Public.crew_scale()^(3/5))
end

function Public.biter_base_density_scale()
	local p = Common.activecrewcount()
	if p >= 10 then
		return (Common.activecrewcount()/10)^(1/2)
	else
		return Math.max((Common.activecrewcount()/6)^(1/2), 0.6)
	end
end


function Public.launch_fuel_reward()
	return Math.ceil(1000 * (1 + 0.1 * (Common.overworldx()/40)^(8/10)) / Math.sloped(Common.difficulty(), 1/4))
end

function Public.quest_reward_multiplier()
	return (0.4 + 0.08 * (Common.overworldx()/40)^(8/10)) * Math.sloped(Common.difficulty(), 1/3) * (Public.crew_scale())^(1/8)
end

function Public.island_richness_avg_multiplier()
	return 0.7 + 0.1 * (Common.overworldx()/40)^(7/10)
end

function Public.resource_quest_multiplier()
	return (1.0 + 0.075 * (Common.overworldx()/40)^(8/10)) * Math.sloped(Common.difficulty(), 1/3) * (Public.crew_scale())^(1/8)
end


function Public.apply_crew_buffs_per_x(force)
	force.laboratory_productivity_bonus = force.laboratory_productivity_bonus + 10/100 * 1/40
end

function Public.class_cost()
	return 9000
	-- return Math.ceil(10000 / (Common.activecrewcount()/4)^(1/6))
end


Public.covered_first_appears_at = 40

Public.silo_max_hp = 8000

function Public.pistol_damage_multiplier() return 1.95 end

Public.kraken_spawns_base_extra_evo = 0.2

function Public.kraken_evo_increase_per_shot()
	return 1/100 * 0.04 --started off low, currently slowly upping to see
end

function Public.kraken_kill_reward()
	return {{name = 'sulfuric-acid-barrel', count = 5}}
end

function Public.kraken_health()
	return Math.ceil(2500 * Math.max(1, 1 + 0.1 * ((Common.overworldx()/40)^(13/10)-6)) * (Public.crew_scale()^(5/8)) * Math.sloped(Common.difficulty(), 1/2))
end

Public.kraken_regen_scale = 0.1 --starting off low

function Public.krakens_per_slot(overworldx)
	local rng = Math.random()
	if rng < 0.03 then
		return 2
	elseif rng < 0.25 then
		return 1
	else
		return 0
	end
end

function Public.krakens_per_free_slot(overworldx)
	local rng = Math.random()
	local multiplier = 1
	if overworldx and overworldx > 600 then
		multiplier = 1 + (overworldx-600)/600
	end
	if rng < 0.075 * multiplier then
		return 2
	elseif rng < 0.5 * multiplier then
		return 1
	else
		return 0
	end
end


function Public.main_shop_cost_multiplier()
	return 1
end

function Public.covered_entry_price_scale()
	return (1 + 0.025 * (Common.overworldx()/40 - 1))
end

function Public.barter_decay_parameter()
	return 0.95
end

-- function Public.island_otherresources_prospect_decay_parameter()
-- 	return 0.95
-- end

Public.research_buffs = {
	-- these already give .1 productivity so we're adding .1 to get to 20%
	['mining-productivity-1'] = {['mining-drill-productivity-bonus'] = .1},
	['mining-productivity-2'] = {['mining-drill-productivity-bonus'] = .1},
	['mining-productivity-3'] = {['mining-drill-productivity-bonus'] = .1},
	['mining-productivity-4'] = {['mining-drill-productivity-bonus'] = .1},
	-- -- these already give .1 productivity so we're adding .1 to get to 20%
	-- ['mining-productivity-1'] = {['mining-drill-productivity-bonus'] = .1, ['character-inventory-slots-bonus'] = 5},
	-- ['mining-productivity-2'] = {['mining-drill-productivity-bonus'] = .1, ['character-inventory-slots-bonus'] = 5},
	-- ['mining-productivity-3'] = {['mining-drill-productivity-bonus'] = .1, ['character-inventory-slots-bonus'] = 5},
	-- ['mining-productivity-4'] = {['mining-drill-productivity-bonus'] = .1, ['character-inventory-slots-bonus'] = 5},
}


-- function Public.flamers_nerfs_size(jumps) return 0.02 * jumps * difficulty_sloped(1/2) end




function Public.player_ammo_damage_modifiers() -- modifiers are fractional. bullet affects gun turrets, but flamethrower does not affect flamer turrets
	local data = {
		['artillery-shell'] = 0,
		['biological'] = 0,
		['bullet'] = 0.1,
		['cannon-shell'] = 0,
		['capsule'] = 0,
		['electric'] = 0,
		['flamethrower'] = 0, --these nerfs are elsewhere for finer control
		['grenade'] = -0.05,
		['landmine'] = 0,
		['melee'] = 0, -- doesn't do anything apparently
		['rocket'] = 0,
		['shotgun-shell'] = 0
	}
	return data
end
function Public.player_turret_attack_modifiers()
	local data = {
		['gun-turret'] = 0,
		['artillery-turret'] = 0,
		['laser-turret'] = 0,
	}
	return data
end
function Public.player_gun_speed_modifiers()
	local data = {
		['artillery-shell'] = 0,
		['biological'] = 0,
		['bullet'] = 0,
		['cannon-shell'] = 0,
		['capsule'] = 0,
		['electric'] = 0,
		['flamethrower'] = 0, --these nerfs are elsewhere for finer control
		['grenade'] = -0.25,
		['landmine'] = 0,
		['melee'] = 0, -- doesn't do anything
		['rocket'] = 0,
		['shotgun-shell'] = 0.1
	}
	return data
end


Public.starting_items_player = {['pistol'] = 1, ['firearm-magazine'] = 12, ['raw-fish'] = 1, ['iron-plate'] = 12, ['medium-electric-pole'] = 4}

Public.starting_items_player_late = {['pistol'] = 1, ['firearm-magazine'] = 5}

function Public.starting_items_crew_upstairs()
	return {
		{['steel-plate'] = 38},
		{['stone-brick'] = 60},
		{['grenade'] = 3},
		{['shotgun'] = 2, ['shotgun-shell'] = 36},
		{['raw-fish'] = 5},
		{['coin'] = 1000},
	}
end

function Public.starting_items_crew_downstairs()
	return {
		{['transport-belt'] = Math.random(600,650)},
		{['underground-belt'] = 80},
		{['splitter'] = Math.random(50,56)},
		{['inserter'] = Math.random(120,140)},
		{['storage-tank'] = 4},
		{['medium-electric-pole'] = Math.random(15,21)},
		{['coin'] = 2000},
		{['solar-panel'] = 4},
	}
end





Public.covered1_entry_price_data_raw = { --watch out that the raw_materials chest can only hold e.g. 4.8 iron-plates
	-- choose things that are easy to make at outposts
	{1, 0, 1, false, {
		price = {name = 'iron-stick', count = 1500},
		raw_materials = {{name = 'iron-plate', count = 750}}}, {}},
	{0.8, 0, 1, false, {
		price = {name = 'copper-cable', count = 1500},
		raw_materials = {{name = 'copper-plate', count = 750}}}, {}},

	{1, 0, 0.3, true, {
		price = {name = 'small-electric-pole', count = 800},
		raw_materials = {{name = 'copper-plate', count = 400}}}, {}},
	{1, 0.1, 1, false, {
		price = {name = 'assembling-machine-1', count = 80},
		raw_materials = {{name = 'iron-plate', count = 1760}, {name = 'copper-plate', count = 360}}}, {}},
	{1, 0, 0.2, false, {
		price = {name = 'burner-mining-drill', count = 200},
		raw_materials = {{name = 'iron-plate', count = 1800}}}, {}},
	{0.5, 0, 0.6, false, {
		price = {name = 'burner-inserter', count = 300},
		raw_materials = {{name = 'iron-plate', count = 900}}}, {}},
	-- {1, 0, 1, false, {
	-- 	price = {name = 'electronic-circuit', count = 800},
	-- 	raw_materials = {{name = 'iron-plate', count = 800}, {name = 'copper-plate', count = 1200}}}, {}},
	-- {1, 0, 1, false, {
	-- 	price = {name = 'piercing-rounds-magazine', count = 100},
	-- 	raw_materials = {{name = 'iron-plate', count = 400}, {name = 'copper-plate', count = 500}, {name = 'steel-plate', count = 100}}}, {}},

	{1, 0.1, 1, false, {
		price = {name = 'stone-furnace', count = 400},
		raw_materials = {}}, {}},
	{1, 0.4, 1, false, {
		price = {name = 'advanced-circuit', count = 100},
		raw_materials = {{name = 'iron-plate', count = 200}, {name = 'copper-plate', count = 500}, {name = 'plastic-bar', count = 200}}}, {}},

	{1, -1, 1, true, {
		price = {name = 'wooden-chest', count = 400},
		raw_materials = {}}, {}},
	{1, 0, 1, true, {
		price = {name = 'iron-chest', count = 300},
		raw_materials = {{name = 'iron-plate', count = 2400}}}, {}},
	{1, 0, 2, true, {
		price = {name = 'steel-chest', count = 200},
		raw_materials = {{name = 'steel-plate', count = 1600}}}, {}},
}
function Public.covered1_entry_price_data()
	local ret = {}
	local data = Public.covered1_entry_price_data_raw
	for i = 1, #data do
		local data_item = data[i]
		ret[#ret + 1] = {
            weight = data_item[1],
            game_completion_progress_min = data_item[2],
            game_completion_progress_max = data_item[3],
            scaling = data_item[4],
            item = data_item[5],
            map_subtypes = data_item[6],
        }
	end
	return ret
end


function Public.covered1_entry_price()
	local rng = Math.random()
	local memory = Memory.get_crew_memory()

	local overworldx = memory.overworldx or 0

	local game_completion_progress = Math.sloped(Common.difficulty(),1/2) * Common.game_completion_progress()

	local data = Public.covered1_entry_price_data()
    local types, weights = {}, {}
    for i = 1, #data, 1 do
        table.insert(types, data[i].item)

		local destination = Common.current_destination()
		if not (data[i].map_subtypes and #data[i].map_subtypes > 0 and destination and destination.subtype and data[i].map_subtypes and (not Utils.contains(data[i].map_subtypes, destination.subtype))) then
			if data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
				local midpoint = (data[i].game_completion_progress_max + data[i].game_completion_progress_min) / 2
				local difference = (data[i].game_completion_progress_max - data[i].game_completion_progress_min)
				table.insert(weights, data[i].weight * Math.max(0, 1 - (Math.abs(game_completion_progress - midpoint) / (difference / 2))))
			else -- no scaling
				if data[i].game_completion_progress_min <= game_completion_progress and data[i].game_completion_progress_max >= game_completion_progress then
					table.insert(weights, data[i].weight)
				else
					table.insert(weights, 0)
				end
			end
		end
    end

	local res = Utils.deepcopy(Math.raffle(types, weights))

	res.price.count = Math.ceil(res.price.count * Public.covered_entry_price_scale())
	for i, _ in pairs(res.raw_materials) do
		res.raw_materials[i].count = Math.ceil(res.raw_materials[i].count * Public.covered_entry_price_scale())
	end

	return res
end

return Public