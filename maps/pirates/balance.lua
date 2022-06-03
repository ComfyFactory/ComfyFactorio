-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Public = {}
local Math = require 'maps.pirates.math'
-- local Raffle = require 'maps.pirates.raffle'
-- local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect

-- this file is an API to all the balance tuning knobs

-- damage_taken_multiplier:
-- if multiplier > 1: entity takes more damage
-- if multiplier < 1: entity takes less damage (has damage reduction)

-- damage_dealt_multiplier:
-- if multiplier > 1: entity deals more damage
-- if multiplier < 1: entity deals less damage

-- extra_speed:
-- if multiplier > 1: entity moves faster
-- if multiplier < 1: entity moves slower
-- NOTE: when some extra speed modifiers stack, they stack multiplicatively

Public.base_extra_character_speed = 1.44
Public.respawn_speed_boost = 1.75

Public.technology_price_multiplier = 1
Public.rocket_launch_coin_reward = 5000

Public.base_caught_fish_amount = 3
Public.class_reward_tick_rate_in_seconds = 7
Public.poison_damage_multiplier = 1.85
Public.every_nth_tree_gives_coins = 6

Public.samurai_damage_taken_multiplier = 0.26
Public.samurai_damage_dealt_when_not_melee_multiplier = 0.75
Public.samurai_damage_dealt_with_melee_multiplier = 25
Public.hatamoto_damage_taken_multiplier = 0.16
Public.hatamoto_damage_dealt_when_not_melee_multiplier = 0.75
Public.hatamoto_damage_dealt_with_melee_multiplier = 45
Public.iron_leg_damage_taken_multiplier = 0.18
Public.iron_leg_iron_ore_required = 3000
Public.deckhand_extra_speed = 1.25
Public.deckhand_ore_grant_multiplier = 2
Public.deckhand_ore_scaling_enabled = true
Public.boatswain_extra_speed = 1.25
Public.boatswain_ore_grant_multiplier = 4
Public.boatswain_ore_scaling_enabled = true
Public.shoresman_extra_speed = 1.1
Public.shoresman_ore_grant_multiplier = 2
Public.shoresman_ore_scaling_enabled = true
Public.quartermaster_range = 19
Public.quartermaster_bonus_physical_damage = 0.1
Public.quartermaster_ore_scaling_enabled = false
Public.scout_extra_speed = 1.3
Public.scout_damage_taken_multiplier = 1.25
Public.scout_damage_dealt_multiplier = 0.6
Public.fisherman_reach_bonus = 10
Public.master_angler_reach_bonus = 16
Public.master_angler_fish_bonus = 1
Public.master_angler_coin_bonus = 10
Public.dredger_reach_bonus = 16
Public.dredger_fish_bonus = 1
Public.gourmet_ore_scaling_enabled = false

function Public.starting_boatEEIpower_production_MW()
	-- return 3 * Math.sloped(Common.capacity_scale(), 1/2) / 2 --/2 as we have 2
	return 3/2
end
function Public.starting_boatEEIelectric_buffer_size_MJ() --maybe needs to be at least the power_production
	-- return 3 * Math.sloped(Common.capacity_scale(), 1/2) / 2 --/2 as we have 2
	return 3/2
end
Public.EEI_stages = { --multipliers
	1,2,4,7,11
}


function Public.scripted_biters_pollution_cost_multiplier()

	return 1.45 / Math.sloped(Common.difficulty_scale(), 1/5) * (1 + 1.2 / ((1 + (Common.overworldx()/40))^(1.5+Common.difficulty_scale()))) -- the complicated factor just makes the early-game easier; in particular the first island, but on easier difficulties the next few islands as well
end

function Public.cost_to_leave_multiplier()
	-- return Math.sloped(Common.difficulty_scale(), 7/10) --should scale with difficulty similar to, but slightly slower than, passive fuel depletion rate --Edit: not sure about this?
	-- return Math.sloped(Common.difficulty_scale(), 9/10)

	-- extra factor now that the cost scales with time:
	return Math.sloped(Common.difficulty_scale(), 8/10)
end

function Public.crew_scale()
	local ret = Common.activecrewcount()/10
	if ret == 0 then ret = 1/10 end --if all players are afk
	if ret > 2.1 then ret = 2.1 end --An upper cap on this is important, for two reasons:
	-- large crews become disorganised
	-- Higher values of this scale lower the amount of time you get on each island. But the amount of time certain island tasks take is fixed; e.g. the amount of ore is mostly invariant, and you need time to mine it.
	return ret
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
	-- return est_secs * est_base_power * Math.sloped(Common.difficulty_scale(), 1/3)
end

function Public.silo_count()
	local E = Public.silo_energy_needed_MJ()
	return Math.min(Math.ceil(E/(16.8 * 300)),6)
	-- return Math.ceil(E/(16.8 * 300)) --no more than this many seconds to charge it. Players can in fact go even faster using beacons
end


function Public.game_slowness_scale()
	-- return 1 / Public.crew_scale()^(55/100) / Math.sloped(Common.difficulty_scale(), 1/4) --changed crew_scale factor significantly to help smaller crews
	return 1 / Public.crew_scale()^(50/100) / Math.sloped(Common.difficulty_scale(), 1/4) --changed crew_scale factor significantly to help smaller crews
end


function Public.max_time_on_island_formula() --always >0  --tuned
	return 60 * (
			-- (32 + 2.2 * (Common.overworldx()/40)^(1/3))
			(33 + 0.2 * (Common.overworldx()/40)^(1/3)) --based on observing x=2000, lets try killing the extra time
	) * Public.game_slowness_scale()
end


Public.rockets_needed_x = 40*21


function Public.max_time_on_island()
	local x = Common.overworldx()
	if x == 0 or (x >= Public.rockets_needed_x) then
	-- if Common.overworldx() == 0 or ((Common.overworldx()/40) > 20 and (Common.overworldx()/40) < 25) then
		return -1
	else
		if x == 40 then
			return 1.1 * Math.ceil(Public.max_time_on_island_formula()) --it's important for this island to be somewhat chill, so that it's not such a shock to go here from the first lobby chill island
		else
			return Math.ceil(Public.max_time_on_island_formula())
		end
	end
end

Public.expected_time_fraction = 3/5

function Public.expected_time_on_island() --always >0
	return Public.expected_time_fraction * Public.max_time_on_island_formula()
end

function Public.fuel_depletion_rate_static()
	if (not Common.overworldx()) then return 0 end

	local T = Public.expected_time_on_island()

	local rate
	if Common.overworldx() > 0 then
		rate = 575 * (0 + (Common.overworldx()/40)^(9/10)) * Public.crew_scale()^(1/8) * Math.sloped(Common.difficulty_scale(), 65/100) / T --most of the crewsize dependence is through T, i.e. the coal cost per island stays the same... but the extra player dependency accounts for the fact that even in compressed time, more players seem to get more resources per island
	else
		rate = 0
	end

	return -rate
end

function Public.fuel_depletion_rate_sailing()
	if (not Common.overworldx()) then return 0 end

	return - 7.65 * (1 + 0.135 * (Common.overworldx()/40)^(100/100)) * Math.sloped(Common.difficulty_scale(), 1/20) --shouldn't depend on difficulty much if at all, as available resources don't depend much on difficulty
end

function Public.silo_total_pollution()
	return (
		365 * (Common.difficulty_scale()^(1.2)) * Public.crew_scale()^(3/10) * (3.2 + 0.7 * (Common.overworldx()/40)^(1.6)) / Math.sloped(Common.difficulty_scale(), 1/5) --shape of the curve with x is tuned. Final factor of difficulty is to offset a change made to scripted_biters_pollution_cost_multiplier
)
end

function Public.boat_passive_pollution_per_minute(time)
	local boost = 1
	local T = Public.max_time_on_island_formula()
	if (Common.overworldx()/40) > 25 then T = T * 0.9 end

	if time then
		if time >= 160/100 * T then
		boost = 40
		elseif time >= 130/100 * T then
			boost = 30
		elseif time >= 100/100 * T then --will still happen regularly, on islands without an auto-undock timer
			boost = 20
		elseif time >= 95/100 * T then
			boost = 16
		elseif time >= 90/100 * T then
			boost = 12
		elseif time >= 85/100 * T then
			boost = 8
		elseif time >= 80/100 * T then
			boost = 5
		elseif time >= 70/100 * T then
			boost = 3
		elseif time >= 60/100 * T then
			boost = 2
		elseif time >= 50/100 * T then
			boost = 1.5
		end
	end

	return boost * (
			2.73 * (Common.difficulty_scale()^(1.1)) * (Common.overworldx()/40)^(1.8) * (Public.crew_scale())^(52/100)-- There is no _explicit_ T dependence, but it depends almost the same way on the crew_scale as T does.
	 ) / Math.sloped(Common.difficulty_scale(), 1/5) --Final factor of difficulty is to offset a change made to scripted_biters_pollution_cost_multiplier
end


function Public.base_evolution_leagues(leagues)
	local evo
	local overworldx = leagues

	if overworldx == 0 then
		evo = 0
	else
		evo = (0.0201 * (overworldx/40)) * Math.sloped(Common.difficulty_scale(), 1/5)

		if overworldx > 600 and overworldx < 1000 then
			evo = evo + (0.0025 * (overworldx - 600)/40)
		elseif overworldx >= 1000 then
			evo = evo + 0.0025 * 10
		end --extra slope from 600 to 1000 adds 2.5% evo
	end

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

	-- if _DEBUG then
	-- 	local surface = game.surfaces[destination.surface_name]
	-- 	game.print(Common.spawner_count(surface) .. '  ' .. destination.dynamic_data.initial_spawner_count)
	-- end

	return rate
end

function Public.evolution_per_nest_kill() --it's important to have evo go up with biter base kills, to provide resistance if you try to plow through all the bases
	local destination = Common.current_destination()
	if Common.overworldx() == 0 then return 0 end

	if destination and destination.dynamic_data and destination.dynamic_data.timer and destination.dynamic_data.timer > 0 and destination.dynamic_data.initial_spawner_count and destination.dynamic_data.initial_spawner_count > 0 then

		local initial_spawner_count = destination.dynamic_data.initial_spawner_count
		local time = destination.dynamic_data.timer
		-- local time_to_jump_to = Public.expected_time_on_island() * ((1/Public.expected_time_fraction)^(2/3))
		local time_to_jump_to = Public.max_time_on_island_formula()
		if time > time_to_jump_to then return 0
		else
			-- evo it 'would have' contributed:
			return (1/initial_spawner_count) * Public.expected_time_evo() * (time_to_jump_to - time)/time_to_jump_to
		end
	else
		return 0
	end

	-- return 0.003 * Common.difficulty_scale()
end

function Public.evolution_per_full_silo_charge()
	 --too low and you always charge immediately, too high and you always charge late
	-- return 0.05
	-- observed x=2000 run, changed this to:
	-- return 0.05 + 0.03 * Common.overworldx()/1000
	return 0.05 + 0.02 * Common.overworldx()/1000
end

-- function Public.bonus_damage_to_humans()
-- 	local ret = 0.025
-- 	local diff = Common.difficulty_scale()
-- 	if diff <= 0.7 then ret = 0 end
-- 	if diff >= 1.3 then ret = 0.050 end
-- 	return ret
-- end


function Public.biter_timeofday_bonus_damage(darkness) -- a surface having min_brightness of 0.2 will cap darkness at 0.8
	return 0.1 * darkness
end


function Public.periodic_free_resources_per_x()
	return {
	}
	-- return {
	-- 	{name = 'iron-plate', count = Math.ceil(5 * (Common.overworldx()/40)^(2/3))},
	-- 	{name = 'copper-plate', count = Math.ceil(1 * (Common.overworldx()/40)^(2/3))},
	-- }
end

function Public.periodic_free_resources_per_destination_5_seconds()
	return {
	}
	-- return {
	-- 	{name = 'iron-ore', count = Math.ceil(7 * (Common.overworldx()/40)^(0.6))},
	-- 	{name = 'copper-ore', count = Math.ceil(3 * (Common.overworldx()/40)^(0.6))},
	-- }
end

function Public.class_resource_scale()
	return 1 / (Public.crew_scale()^(2/5)) --already helped by longer timescales
end

function Public.biter_base_density_scale()
	local p = Public.crew_scale()
	if p >= 1 then
		return p^(1/2)
	else
		return Math.max((p*10/6)^(1/2), 0.6)
	end
end


function Public.rocket_launch_fuel_reward()
	return Math.ceil(1250 * (1 + 0.13 * (Common.overworldx()/40)^(9/10)) * Math.sloped(Common.difficulty_scale(), 1/3))
	-- return Math.ceil(1000 * (1 + 0.1 * (Common.overworldx()/40)^(8/10)) / Math.sloped(Common.difficulty_scale(), 1/4))
end

function Public.quest_reward_multiplier()
	return (0.4 + 0.08 * (Common.overworldx()/40)^(8/10)) * Math.sloped(Common.difficulty_scale(), 1/3) * (Public.crew_scale())^(1/8)
end

function Public.island_richness_avg_multiplier()
	local ret
	-- local base = 0.7 + 0.1 * (Common.overworldx()/40)^(7/10) --tuned tbh
	local base = 0.73 + 0.120 * (Common.overworldx()/40)^(65/100) --tuned tbh

	ret = base * Math.sloped(Public.crew_scale(), 1/40) --we don't really have resources scaling by player count in this resource-constrained scenario, but we scale a little, to accommodate each player filling their inventory with useful tools. also, I would do higher than 1/40, but we go even slightly lower because we're applying this somewhat sooner than players actually get there.

	return ret
end

function Public.resource_quest_multiplier()
	return (1.0 + 0.075 * (Common.overworldx()/40)^(8/10)) * Math.sloped(Common.difficulty_scale(), 1/5) * (Public.crew_scale())^(1/10)
end

function Public.quest_structure_entry_price_scale()
	return 0.85 * (1 + 0.033 * (Common.overworldx()/40 - 1)) * ((1 + Public.crew_scale())^(1/3)) * Math.sloped(Common.difficulty_scale(), 1/2) --whilst the scenario philosophy says that resource scales tend to be independent of crew size, we account slightly for the fact that more players tend to handcraft more
end


function Public.apply_crew_buffs_per_league(force, leagues_travelled)
	force.laboratory_productivity_bonus = force.laboratory_productivity_bonus + Math.max(0, 6/100 * leagues_travelled/40)
end

function Public.class_cost(at_dock)
	if at_dock then
		return 10000
	else
		return 6000
	end
	-- return Math.ceil(10000 / (Public.crew_scale()*10/4)^(1/6))
end


Public.quest_structures_first_appear_at = 40

Public.coin_sell_amount = 500

Public.starting_fuel = 4000

Public.silo_max_hp = 5000
Public.silo_resistance_factor = 7

function Public.pistol_damage_multiplier() return 2.25 end --2.0 slightly too low, 2.5 causes players to yell at each other for not using pistol

Public.kraken_spawns_base_extra_evo = 0.35

function Public.kraken_evo_increase_per_shot()
	return 1/100 * 0.07
end

function Public.sandworm_evo_increase_per_spawn()
	if _DEBUG then
		return 1/100
	else
		return 1/100 * 1/7 * Math.sloped(Common.difficulty_scale(), 3/5)
	end
end

function Public.kraken_kill_reward_items()
	return {{name = 'sulfuric-acid-barrel', count = 5}, {name = 'coin', count = 800}}
end
function Public.kraken_kill_reward_fuel()
	return 200
end

function Public.kraken_health()
	return Math.ceil(3500 * Math.max(1, 1 + 0.075 * (Common.overworldx()/40)^(13/10)) * (Public.crew_scale()^(4/8)) * Math.sloped(Common.difficulty_scale(), 3/4))
	-- return Math.ceil(3500 * Math.max(1, 1 + 0.08 * ((Common.overworldx()/40)^(13/10)-6)) * (Public.crew_scale()^(5/8)) * Math.sloped(Common.difficulty_scale(), 3/4))
end

Public.kraken_regen_scale = 0.1 --starting off low

function Public.krakens_per_slot()
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
	if rng < 0.0025 * multiplier then
		return 3
	elseif rng < 0.075 * multiplier then
		return 1
	elseif rng < 0.5 * multiplier then
		return 1
	else
		return 0
	end
end


function Public.main_shop_cost_multiplier()
	return 1
end

function Public.barter_decay_parameter()
	return 0.95
end

function Public.sandworm_speed()
	return 6.4 * Math.sloped(Common.difficulty_scale(), 1/5)
end

-- function Public.island_otherresources_prospect_decay_parameter()
-- 	return 0.95
-- end

Public.research_buffs = { --currently disabled anyway
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


function Public.flamers_tech_multipliers()
	return 0.8
end

function Public.flamers_base_nerf()
	return -0.2
end




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
		['melee'] = 0, -- doesn't do anything apparently
		['rocket'] = 0,
		['shotgun-shell'] = 0
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
		-- {['raw-fish'] = 5},
		{['coin'] = 1000},
	}
end

function Public.starting_items_crew_downstairs()
	return {
		{['transport-belt'] = Math.random(600,650)},
		{['underground-belt'] = 80},
		{['splitter'] = Math.random(50,56)},
		{['inserter'] = Math.random(120,140)},
		{['storage-tank'] = 2},
		{['medium-electric-pole'] = Math.random(15,21)},
		{['coin'] = 1000},
		{['solar-panel'] = 3},
	}
end















return Public