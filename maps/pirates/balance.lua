-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Public = {}
local Math = require 'maps.pirates.math'
-- local Raffle = require 'maps.pirates.raffle'
-- local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
-- local _inspect = require 'utils.inspect'.inspect

-- this file is an API to all the balance tuning knobs


-- Kraken related parameters
Public.biter_swim_speed = 1.5
Public.kraken_biter_spawn_radius = 6 -- only used during non automatic forced spawning during kraken's "special ability"
Public.kraken_spit_targeting_player_chance = 0

Public.base_extra_character_speed = 1.44
Public.respawn_speed_boost = 1.85

-- maximum rate at which alert sound can be played when important buildings are damaged (like silo or cannons)
-- NOTE: frequency can sometimes be faster by 1 second than denoted, but accuracy doesn't really matter here
Public.alert_sound_max_frequency_in_seconds = 3

Public.cannon_extra_hp_for_upgrade = 1000
Public.cannon_starting_hp = 2000
Public.cannon_resistance_factor = 2
Public.technology_price_multiplier = 1

Public.rocket_launch_coin_reward = 5000

Public.base_caught_fish_amount = 3
Public.class_reward_tick_rate_in_seconds = 7
Public.poison_damage_multiplier = 1.85
Public.every_nth_tree_gives_coins = 6

Public.samurai_damage_taken_multiplier = 0.32
Public.samurai_damage_dealt_when_not_melee_multiplier = 0.75
Public.samurai_damage_dealt_with_melee = 25
Public.hatamoto_damage_taken_multiplier = 0.21
Public.hatamoto_damage_dealt_when_not_melee_multiplier = 0.75
Public.hatamoto_damage_dealt_with_melee = 45
Public.iron_leg_damage_taken_multiplier = 0.24
Public.iron_leg_iron_ore_required = 3000
Public.deckhand_extra_speed = 1.25
Public.deckhand_ore_grant_multiplier = 5
Public.deckhand_ore_scaling_enabled = false
Public.boatswain_extra_speed = 1.25
Public.boatswain_ore_grant_multiplier = 8
Public.boatswain_ore_scaling_enabled = false
Public.shoresman_extra_speed = 1.1
Public.shoresman_ore_grant_multiplier = 5
Public.shoresman_ore_scaling_enabled = false
Public.quartermaster_range = 19
Public.quartermaster_bonus_physical_damage = 1.3
Public.quartermaster_ore_scaling_enabled = false
Public.scout_extra_speed = 1.3
Public.scout_damage_taken_multiplier = 1.25
Public.scout_damage_dealt_multiplier = 0.6
Public.fisherman_fish_bonus = 2
Public.fisherman_reach_bonus = 10
Public.lumberjack_coins_from_tree = 12
Public.lumberjack_ore_base_amount = 4
Public.master_angler_reach_bonus = 16
Public.master_angler_fish_bonus = 4
Public.master_angler_coin_bonus = 20
Public.dredger_reach_bonus = 16
Public.dredger_fish_bonus = 6
Public.gourmet_ore_scaling_enabled = false
Public.chef_fish_received_for_biter_kill = 1
Public.chef_fish_received_for_worm_kill = 3
Public.rock_eater_damage_taken_multiplier = 0.8
Public.rock_eater_required_stone_furnace_to_heal_count = 1
Public.soldier_defender_summon_chance = 0.2
Public.veteran_destroyer_summon_chance = 0.2
Public.veteran_on_hit_slow_chance = 0.1

Public.maximum_fish_allowed_to_catch_at_sea = 30

Public.prevent_waves_from_spawning_in_cave_timer_length = 10 -- in seconds


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

	return 1.25 / Math.sloped(Common.difficulty_scale(), 1/2) * (1 + 1.2 / ((1 + (Common.overworldx()/40))^(1.5+Common.difficulty_scale()))) -- the complicated factor just makes the early-game easier; in particular the first island, but on easier difficulties the next few islands as well
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
	-- return 1 / (Public.crew_scale()^(50/100) / Math.sloped(Common.difficulty_scale(), 1/4)) --changed crew_scale factor significantly to help smaller crews

	return Math.sloped(Common.difficulty_scale(), 1/4) / Public.crew_scale()^(50/100)
end


function Public.max_time_on_island_formula() --always >0  --tuned
	return 60 * (
			-- (32 + 2.2 * (Common.overworldx()/40)^(1/3))
			(33 + 0.2 * (Common.overworldx()/40)^(1/3)) --based on observing x=2000, lets try killing the extra time
	) * Public.game_slowness_scale()
end


Public.rockets_needed_x = 40*20

-- Returns true if resources are mandatory to escape from island. Returns false, when resources are needed to just undock early.
function Public.need_resources_to_undock()
	local x = Common.overworldx()
	if x >= Public.rockets_needed_x and x ~= 40*21 then
		return true
	else
		return false
	end
end

function Public.max_time_on_island()
	local x = Common.overworldx()
	if x == 0 or Public.need_resources_to_undock() then
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

	if Common.overworldx() > 0 then
		-- With this formula coal consumption becomes 1x, 2x, 3x and 4x with 1, 3, 6, 9 crew members respectively
		-- most of the crewsize dependence is through T, i.e. the coal cost per island stays the same... but the extra player dependency accounts for the fact that even in compressed time, more players seem to get more resources per island
		-- rate = 570 * ((Common.overworldx()/40)^(9/10)) * Public.crew_scale()^(1/8) * Math.sloped(Common.difficulty_scale(), 65/100) / T

		-- With this formula coal consumption becomes 1x, 1.24x, 1.44x and 1.57x with 1, 3, 6, 9 crew members respectively.
		-- Coal consumption should scale slowly because:
		-- - More people doesn't necessarily mean faster progression: people just focus on other things (and on some islands it's hard to "employ" every crew member to be productive, due to lack of activities).
		-- - Although more players can setup miners faster, miners don't dig ore faster.
		-- - It's not fun being punished when noobs(or just your casual friends) join game and don't contribute "enough" to make up for increased coal consumption (among other things).
		return -0.2 * ((Common.overworldx()/40)^(9/10)) * Public.crew_scale()^(1/5) * Math.sloped(Common.difficulty_scale(), 40/100)
	else
		return 0
	end
end

function Public.fuel_depletion_rate_sailing()
	if (not Common.overworldx()) then return 0 end

	return - 7.75 * (1 + 0.135 * (Common.overworldx()/40)^(100/100)) * Math.sloped(Common.difficulty_scale(), 1/20) --shouldn't depend on difficulty much if at all, as available resources don't depend much on difficulty
end

function Public.silo_total_pollution()
	return (
		347 * (Common.difficulty_scale()^(1.0)) * Public.crew_scale()^(3/10) * (3.2 + 0.7 * (Common.overworldx()/40)^(1.6)) --shape of the curve with x is tuned.
)
end

function Public.boat_passive_pollution_per_minute(time)
	local T = Public.max_time_on_island_formula()
	if (Common.overworldx()/40) > 25 then T = T * 0.9 end

	local boost
	if time then --sharp rise approaching T, steady increase thereafter
		if time > T then
			boost = 20 + 10 * (time - T) / (30/100 * T)
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
		else
			boost = 1
		end
	else
		boost = 1
	end

	return boost * (
			2.60 * (Common.difficulty_scale()^(0.8)) * (Common.overworldx()/40)^(1.8) * (Public.crew_scale())^(52/100)-- There is no _explicit_ T dependence, but it depends almost the same way on the crew_scale as T does.
	 )
end


function Public.base_evolution_leagues(leagues)
	local evo
	local overworldx = leagues

	if overworldx == 0 then
		evo = 0
	else
		evo = (0.0201 * (overworldx/40)) * Math.sloped(Common.difficulty_scale(), 1/5)

		local difficulty_name = CoreData.get_difficulty_option_informal_name_from_value(Common.difficulty_scale())
		if difficulty_name == 'normal' then
			evo = evo + 0.01
		elseif difficulty_name == 'hard' then
			evo = evo + 0.02
		elseif difficulty_name == 'nightmare' then
			evo = evo + 0.04
		end

		if overworldx > 600 and overworldx < 1000 then
			evo = evo + (0.0025 * (overworldx - 600)/40)
		elseif overworldx >= 1000 then
			evo = evo + 0.0025 * 10
		end --extra slope from 600 to 1000 adds 2.5% evo
	end

	return evo
end

function Public.expected_time_evo()
	return 0.125 --tuned
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
		local base_evo_jump = 0.04 * (1/initial_spawner_count) --extra friction to make them hard to mow through, even at late times

		local time = destination.dynamic_data.timer
		-- local time_to_jump_to = Public.expected_time_on_island() * ((1/Public.expected_time_fraction)^(2/3))
		local time_to_jump_to = Public.max_time_on_island_formula()
		if time > time_to_jump_to then return base_evo_jump
		else
			-- evo it 'would have' contributed:
			return (1/initial_spawner_count) * Public.expected_time_evo() * (time_to_jump_to - time)/time_to_jump_to + base_evo_jump
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
	return 0.06 + 0.025 * Common.overworldx()/1000
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
	local base = 0.73
	local additional = 0.120 * Math.clamp(0, 7, (Common.overworldx()/40)^(65/100) * Math.sloped(Public.crew_scale(), 1/40)) --tuned tbh

	-- now clamped, because it takes way too long to mine that many more resources

	--we don't really have resources scaling by player count in this resource-constrained scenario, but we scale a little, to accommodate each player filling their inventory with useful tools. also, I would do higher than 1/40, but we go even slightly lower because we're applying this somewhat sooner than players actually get there.

	return base + additional
end

function Public.resource_quest_multiplier()
	return (0.9 + 0.075 * (Common.overworldx()/40)^(8/10)) * Math.sloped(Common.difficulty_scale(), 1/5) * (Public.crew_scale())^(1/10)
end

function Public.quest_market_entry_price_scale()
	-- Whilst the scenario philosophy says that resource scales tend to be independent of crew size, we account slightly for the fact that more players tend to handcraft more
	-- Idea behind formula: small scale for early islands, but scale linearly ~3-4 times every 25 islands (scaling and starting scale is more aggressive for higher difficulties)

	-- Returned value examples
	-- Assuming parameters:
	-- crew_size = 3
	-- difficulty = easy (0.5)
	-- @NOTE: assuming starting island is 0th island
	-- x = 40   (1st island): 0.419
	-- x = 200  (5th island): 0.582
	-- x = 600  (15th island): 0.992
	-- x = 1000 (25th island): 1.401
	return (1 + 0.05 * (Common.overworldx()/40 - 1)) * ((1 + Public.crew_scale())^(1/3)) * Math.sloped(Common.difficulty_scale(), 1/2) - 0.4
end

function Public.quest_furnace_entry_price_scale()
	-- Slower increase with time, because this is more time-constrained than resource-constrained
	-- Idea behind formula: small scale for early islands, but scale linearly ~2-3 times every 25 islands (scaling and starting scale is more aggressive for higher difficulties)

	-- Returned value examples
	-- Assuming parameters:
	-- crew_size = 3
	-- difficulty = easy (0.5)
	-- @NOTE: assuming starting island is 0th island
	-- x = 40   (1st island): 0.419
	-- x = 200  (5th island): 0.517
	-- x = 600  (15th island): 0.762
	-- x = 1000 (25th island): 1.008
	return (1 + 0.03 * (Common.overworldx()/40 - 1)) * ((1 + Public.crew_scale())^(1/3)) * Math.sloped(Common.difficulty_scale(), 1/2) - 0.4
end

function Public.apply_crew_buffs_per_league(force, leagues_travelled)
	force.laboratory_productivity_bonus = force.laboratory_productivity_bonus + Math.max(0, 7/100 * leagues_travelled/40)
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

Public.kraken_static_evo = 0.35

function Public.kraken_evo_increase_per_shot()
	-- return 1/100 * 0.08
	return 0
end

function Public.kraken_evo_increase_per_second()
	return (1/100) / 20
end

function Public.sandworm_evo_increase_per_spawn()
	if _DEBUG then
		return 1/100
	else
		return (1/100) * (1/7) * Math.sloped(Common.difficulty_scale(), 3/5)
	end
end

function Public.kraken_kill_reward_items()
	return {{name = 'coin', count = 800}, {name = 'utility-science-pack', count = 8}}
end
function Public.kraken_kill_reward_fuel()
	return 150
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
	['mining-productivity-1'] = {['mining_drill_productivity_bonus'] = .1},
	['mining-productivity-2'] = {['mining_drill_productivity_bonus'] = .1},
	['mining-productivity-3'] = {['mining_drill_productivity_bonus'] = .1},
	['mining-productivity-4'] = {['mining_drill_productivity_bonus'] = .1},
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


Public.starting_items_player = {
	['pistol'] = 1,
	['firearm-magazine'] = 20,
	['raw-fish'] = 4,
	['medium-electric-pole'] = 20,
	['iron-plate'] = 50,
	['copper-plate'] = 20,
	['iron-gear-wheel'] = 6,
	['copper-cable'] = 20,
	['burner-inserter'] = 2,
	['gun-turret'] = 1
}

Public.starting_items_player_late = {
	['pistol'] = 1,
	['firearm-magazine'] = 10,
	['raw-fish'] = 4,
	['small-electric-pole'] = 20,
	['iron-plate'] = 50,
	['copper-plate'] = 20,
	['iron-gear-wheel'] = 6,
	['copper-cable'] = 20,
	['burner-inserter'] = 2,
	['gun-turret'] = 1
}

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

function Public.pick_random_drilling_ore()
	local number = Math.random(10)
	if number <= 4 then -- 40%
		return 'iron-ore'
	elseif number <= 7 then -- 30%
		return 'copper-ore'
	elseif number <= 9 then -- 20%
		return 'coal'
	else -- 10%
		return 'stone'
	end
end


-- Current formula returns [50 - 200] + random(1, [10 - 40]) depending on completion progress
-- Formula is "a(100x)^(1/2) + random(1, 0.2a(100x)^(1/2))" where
-- x: progress in range [0-1] (when leagues are in 0-1000)
-- a: scaling
-- When the formula needs adjustments, I suggest changing scaling variable
function Public.pick_drilling_ore_amount()
	local scaling = 20
	local amount = scaling * Math.sqrt(100 * Common.game_completion_progress())
	local extra_random_amount = Math.random(Math.ceil(0.2 * amount))
	return amount + extra_random_amount
end


-- Current formula returns [15000 - 50000] + random(1, [3000 - 10000]) depending on completion progress
-- Formula is "a(1000000x)^(1/2) + random(1, 0.2a(1000000x)^(1/2))" where
-- x: progress in range [0-1] (when leagues are in 0-1000)
-- a: scaling
-- When the formula needs adjustments, I suggest changing scaling variable
-- Note: 3333 crude oil amount ~= 1% = 0.1/sec
function Public.pick_default_oil_amount()
	local scaling = 50
	local amount = scaling * Math.sqrt(1000000 * Common.game_completion_progress())
	local extra_random_amount = Math.random(Math.max(1, Math.ceil(0.2 * amount)))
	return amount + extra_random_amount
end

return Public