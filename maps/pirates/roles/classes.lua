-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Balance = require 'maps.pirates.balance'
local _inspect = require 'utils.inspect'.inspect
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local CoreData = require 'maps.pirates.coredata'
local SurfacesCommon = require 'maps.pirates.surfaces.common'
-- local Server = require 'utils.server'

local Public = {}
local enum = {
	DECKHAND = 'deckhand',
	FISHERMAN = 'fisherman',
	SCOUT = 'scout',
	SAMURAI = 'samurai',
	MERCHANT = 'merchant',
	SHORESMAN = 'shoresman',
	BOATSWAIN = 'boatswain',
	PROSPECTOR = 'prospector',
	LUMBERJACK = 'lumberjack',
	MASTER_ANGLER = 'master_angler',
	WOOD_LORD = 'wood_lord',
	CHIEF_EXCAVATOR = 'chief_excavator',
	HATAMOTO = 'hatamoto',
	IRON_LEG = 'iron_leg',
	QUARTERMASTER = 'quartermaster',
	DREDGER = 'dredger',
	SMOLDERING = 'smoldering',
	GOURMET = 'gourmet',
	CHEF = 'chef',
	ROCK_EATER = 'rock_eater',
	SOLDIER = 'soldier',
	VETERAN = 'veteran',
}
Public.enum = enum

-- function Public.Class_List()
-- 	local ret = {}
-- 	for _,v in pairs(enum) do
-- 		ret[#ret + 1] = v
-- 	end
-- end

Public.eng_form = {
	[enum.DECKHAND] = 'Deckhand',
	[enum.FISHERMAN] = 'Fisherman',
	[enum.SCOUT] = 'Scout',
	[enum.SAMURAI] = 'Samurai',
	[enum.MERCHANT] = 'Merchant',
	[enum.SHORESMAN] = 'Shoresman',
	[enum.BOATSWAIN] = 'Boatswain',
	[enum.PROSPECTOR] = 'Prospector',
	[enum.LUMBERJACK] = 'Lumberjack',
	[enum.MASTER_ANGLER] = 'Master Angler',
	[enum.WOOD_LORD] = 'Wood Lord',
	[enum.CHIEF_EXCAVATOR] = 'Chief Excavator',
	[enum.HATAMOTO] = 'Hatamoto',
	[enum.IRON_LEG] = 'Iron Leg',
	[enum.QUARTERMASTER] = 'Quartermaster',
	[enum.DREDGER] = 'Dredger',
	[enum.SMOLDERING] = 'Smoldering',
	[enum.GOURMET] = 'Gourmet',
	[enum.CHEF] = 'Chef',
	[enum.ROCK_EATER] = 'Rock Eater',
	[enum.SOLDIER] = 'Soldier',
	[enum.VETERAN] = 'Veteran',
}

function Public.display_form(class)
	return {'pirates.class_' .. class}
end

-- function Public.explanation(class)
-- 	return {'pirates.class_' .. class .. '_explanation'}
-- end

function Public.explanation(class, add_is_class_obtainable)
	local explanation = 'pirates.class_' .. class .. '_explanation_advanced'
	local full_explanation

	if class == enum.DECKHAND then
		local extra_speed = Public.percentage_points_difference_from_100_percent(Balance.deckhand_extra_speed)
		local ore_amount = Public.ore_grant_amount(Balance.deckhand_ore_grant_multiplier, Balance.deckhand_ore_scaling_enabled)
		local tick_rate = Balance.class_reward_tick_rate_in_seconds
		full_explanation = {'', {explanation, extra_speed, ore_amount, tick_rate}}
	elseif class == enum.BOATSWAIN then
		local extra_speed = Public.percentage_points_difference_from_100_percent(Balance.boatswain_extra_speed)
		local ore_amount = Public.ore_grant_amount(Balance.boatswain_ore_grant_multiplier, Balance.boatswain_ore_scaling_enabled)
		local tick_rate = Balance.class_reward_tick_rate_in_seconds
		full_explanation = {'', {explanation, extra_speed, ore_amount, tick_rate}}
	elseif class == enum.SHORESMAN then
		local extra_speed = Public.percentage_points_difference_from_100_percent(Balance.shoresman_extra_speed)
		local ore_amount = Public.ore_grant_amount(Balance.shoresman_ore_grant_multiplier, Balance.shoresman_ore_scaling_enabled)
		local tick_rate = Balance.class_reward_tick_rate_in_seconds
		full_explanation = {'', {explanation, extra_speed, ore_amount, tick_rate}}
	elseif class == enum.QUARTERMASTER then
		local range = Balance.quartermaster_range
		local extra_physical = Public.percentage_points_difference_from_100_percent(Balance.quartermaster_bonus_physical_damage)
		full_explanation = {'', {explanation, range, extra_physical}}
	elseif class == enum.FISHERMAN then
		local extra_range = Balance.fisherman_reach_bonus
		local extra_fish = Balance.fisherman_fish_bonus
		full_explanation = {'', {explanation, extra_range, extra_fish}}
	elseif class == enum.MASTER_ANGLER then
		local extra_range = Balance.master_angler_reach_bonus
		local extra_fish = Balance.master_angler_fish_bonus
		local extra_coins = Balance.master_angler_coin_bonus
		full_explanation = {'', {explanation, extra_range, extra_fish, extra_coins}}
	elseif class == enum.SCOUT then
		local extra_speed = Public.percentage_points_difference_from_100_percent(Balance.scout_extra_speed)
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.scout_damage_taken_multiplier)
		local dealt_damage = Public.percentage_points_difference_from_100_percent(Balance.scout_damage_dealt_multiplier)
		full_explanation = {'', {explanation, extra_speed, received_damage, dealt_damage}}
	elseif class == enum.SAMURAI then
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.samurai_damage_taken_multiplier)
		local melee_damage = Balance.samurai_damage_dealt_with_melee
		local non_melee_damage = Public.percentage_points_difference_from_100_percent(Balance.samurai_damage_dealt_when_not_melee_multiplier)
		full_explanation = {'', {explanation, received_damage, melee_damage, non_melee_damage}}
	elseif class == enum.HATAMOTO then
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.hatamoto_damage_taken_multiplier)
		local melee_damage = Balance.hatamoto_damage_dealt_with_melee
		local non_melee_damage = Public.percentage_points_difference_from_100_percent(Balance.hatamoto_damage_dealt_when_not_melee_multiplier)
		full_explanation = {'', {explanation, received_damage, melee_damage, non_melee_damage}}
	elseif class == enum.IRON_LEG then
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.iron_leg_damage_taken_multiplier)
		local iron_ore_required = Balance.iron_leg_iron_ore_required
		full_explanation = {'', {explanation, received_damage, iron_ore_required}}
	elseif class == enum.ROCK_EATER then
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.rock_eater_damage_taken_multiplier)
		full_explanation = {'', {explanation, received_damage}}
	elseif class == enum.SOLDIER then
		local chance = Balance.soldier_defender_summon_chance * 100
		full_explanation = {'', {explanation, chance}}
	elseif class == enum.VETERAN then
		local chance = Balance.veteran_destroyer_summon_chance * 100
		local chance2 = Balance.veteran_on_hit_slow_chance * 100
		full_explanation = {'', {explanation, chance, chance2}}
	else
		full_explanation = {'', {explanation}}
	end

	if add_is_class_obtainable then
		full_explanation[#full_explanation + 1] = Public.class_is_obtainable(class) and {'', ' ', {'pirates.class_obtainable'}} or {'', ' ', {'pirates.class_unobtainable'}}
	end

	return full_explanation
end

-- Public.display_form = {
-- 	[enum.DECKHAND] = {'pirates.class_deckhand'},
-- }
-- Public.explanation = {
-- 	[enum.DECKHAND] = {'pirates.class_deckhand_explanation'},
-- }


-- returns by how much % result changes when you multiply it by multiplier
-- for example consider these multiplier cases {0.6, 1.2}:
-- number * 0.6 -> result decreased by 40%
-- number * 1.2 -> result increased by 20%
function Public.percentage_points_difference_from_100_percent(multiplier)
	if(multiplier < 1) then
		return (1 - multiplier) * 100
	else
		return (multiplier - 1) * 100
	end
end


Public.class_unlocks = {
	[enum.FISHERMAN] = {enum.MASTER_ANGLER},
	-- [enum.LUMBERJACK] = {enum.WOOD_LORD}, --not that interesting
	-- [enum.PROSPECTOR] = {enum.CHIEF_EXCAVATOR}, --breaks the resource pressure in the game too strongly I think
	[enum.SAMURAI] = {enum.HATAMOTO},
	[enum.MASTER_ANGLER] = {enum.DREDGER},
	[enum.SOLDIER] = {enum.VETERAN},
}

Public.class_purchase_requirement = {
	[enum.MASTER_ANGLER] = enum.FISHERMAN,
	[enum.WOOD_LORD] = enum.LUMBERJACK,
	[enum.CHIEF_EXCAVATOR] = enum.PROSPECTOR,
	[enum.HATAMOTO] = enum.SAMURAI,
	[enum.DREDGER] = enum.MASTER_ANGLER,
	[enum.VETERAN] = enum.SOLDIER,
}

function Public.initial_class_pool()
	return {
		enum.DECKHAND, --good for afk players
		enum.SHORESMAN,
		enum.QUARTERMASTER,
		enum.FISHERMAN,
		enum.SCOUT,
		enum.SAMURAI,
		-- enum.MERCHANT, --not interesting, breaks coin economy
		enum.BOATSWAIN,
		-- enum.PROSPECTOR, --lumberjack is just more fun
		enum.LUMBERJACK,
		enum.IRON_LEG,
		-- enum.SMOLDERING, --tedious
		enum.GOURMET,
		enum.CHEF,
		enum.ROCK_EATER,
		enum.SOLDIER,
	}
end

-- Returns true if it's possible to obtain the class, or false if it has been disabled
function Public.class_is_obtainable(class)
	local obtainable_class_pool = Public.initial_class_pool()

	for _, unlocked_class_list in pairs(Public.class_unlocks) do
		for _, unlocked_class in ipairs(unlocked_class_list) do
			obtainable_class_pool[#obtainable_class_pool + 1] = unlocked_class
		end
	end

	for _, unlockable_class in ipairs(obtainable_class_pool) do
		if unlockable_class == class then
			return true
		end
	end

	return false
end

-- When "class" is nil, player drops equipped class
-- "class_entry_index" only relevant for GUI order consistency
function Public.assign_class(player_index, class, class_entry_index)
	local memory = Memory.get_crew_memory()
	local player = game.players[player_index]

	if not memory.classes_table then memory.classes_table = {} end


	if class then
		if Utils.contains(memory.spare_classes, class) then
			-- drop class
			if memory.classes_table[player_index] then
				memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player_index]
				memory.classes_table[player_index] = nil

				for _, class_entry in ipairs(memory.unlocked_classes) do
					if class_entry.taken_by == player.index then
						class_entry.taken_by = nil
						break
					end
				end
			end

			-- assign class
			memory.classes_table[player_index] = class
			memory.spare_classes = Utils.ordered_table_with_single_value_removed(memory.spare_classes, class)

			if class_entry_index then
				memory.unlocked_classes[class_entry_index].taken_by = player.index
			else
				for _, class_entry in ipairs(memory.unlocked_classes) do
					if class_entry.class == class and (not class_entry.taken_by) then
						class_entry.taken_by = player.index
						break
					end
				end
			end
		end
	else
		-- drop class
		if memory.classes_table[player_index] then
			memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player_index]
			memory.classes_table[player_index] = nil

			if class_entry_index then
				memory.unlocked_classes[class_entry_index].taken_by = nil
			else
				for _, class_entry in ipairs(memory.unlocked_classes) do
					if class_entry.taken_by == player.index then
						class_entry.taken_by = nil
						break
					end
				end
			end
		end
	end
end

function Public.generate_class_for_sale()
	local memory = Memory.get_crew_memory()

	-- if #memory.available_classes_pool == 0 then
	-- 	-- memory.available_classes_pool = Public.initial_class_pool() --reset to initial state
	-- 	-- turned off as this makes too many classes
	-- end

	local class
	if #memory.available_classes_pool > 0 then
		class = memory.available_classes_pool[Math.random(#memory.available_classes_pool)]
	end

	return class
end



function Public.class_ore_grant(player, how_much, enable_scaling)
	local count = Public.ore_grant_amount(how_much, enable_scaling)

	if Math.random(4) == 1 then
		Common.flying_text_small(player.surface, player.position, '[color=0.85,0.58,0.37]+' .. count .. '[/color]')
		Common.give_items_to_crew{{name = 'copper-ore', count = count}}
	else
		Common.flying_text_small(player.surface, player.position, '[color=0.7,0.8,0.8]+' .. count .. '[/color]')
		Common.give_items_to_crew{{name = 'iron-ore', count = count}}
	end
end

function Public.ore_grant_amount(how_much, enable_scaling)
	if enable_scaling then
		return Math.ceil(how_much * Balance.class_resource_scale())
	else
		return Math.ceil(how_much)
	end
end

local function class_on_player_used_capsule(event)

	if not event.player_index then return end

	local player = game.players[event.player_index]
	if not player then return end
	if not player.valid then return end
	if not player.character then return end
	if not player.character.valid then return end

	if not event.item then return end
	if event.item.name ~= 'raw-fish' then return end

	local class = Public.get_class(player.index)
	if not class then return end

	local crew_id = Common.get_id_from_force_name(player.force.name)
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

	local global_memory = Memory.get_global_memory()
	global_memory.last_players_health[event.player_index] = player.character.health

	if class == Public.enum.GOURMET then
		local multiplier = 0
		local surfacedata = SurfacesCommon.decode_surface_name(player.surface.name)
		if surfacedata.type == SurfacesCommon.enum.CABIN then
			multiplier = 0.25
		elseif surfacedata.type == SurfacesCommon.enum.CROWSNEST then
			multiplier = 0.15
		else
			local tile = player.surface.get_tile(player.position)
			if tile.valid then
				if tile.name == CoreData.world_concrete_tile then
					multiplier = 1.5
				elseif tile.name == 'cyan-refined-concrete' then
					multiplier = 1.6
				elseif tile.name == CoreData.walkway_tile then
					multiplier = 1
				elseif tile.name == 'orange-refined-concrete' then
					multiplier = 0.5
				elseif tile.name == CoreData.enemy_landing_tile then
					multiplier = 0.3
				elseif tile.name == CoreData.static_boat_floor then
					multiplier = 0.1
				end
			end
		end
		if multiplier > 0 then
			-- Idea behind this: A diminishing return for ore granted every time fish is eaten. But slowly "reset" the diminishing return overtime
			local timescale = 60*30 * Math.max((Balance.game_slowness_scale())^(2/3),0.8)
			if memory.gourmet_recency_tick then
				multiplier = multiplier * Math.clamp(0.2, 5, (1/5)^((memory.gourmet_recency_tick - game.tick)/(60*300)))
				memory.gourmet_recency_tick = Math.max(memory.gourmet_recency_tick, game.tick - timescale*10) + timescale
			else
				multiplier = multiplier * 5
				memory.gourmet_recency_tick = game.tick - timescale*10 + timescale
			end
			Public.class_ore_grant(player, 15 * multiplier, Balance.gourmet_ore_scaling_enabled)
		end
	elseif class == Public.enum.ROCK_EATER then
		local required_count = Balance.rock_eater_required_stone_furnace_to_heal_count
		if player.get_item_count('stone-furnace') >= required_count then
			player.remove_item({name='stone-furnace', count=required_count})
			player.insert({name='raw-fish', count=1})
		end
	elseif class == Public.enum.SOLDIER then
		local chance = Balance.soldier_defender_summon_chance
		if Math.random() < chance then
			local random_vec = Math.random_vec(3)
			local e = player.surface.create_entity{
				name = 'defender',
				position = Utils.psum{player.character.position, random_vec},
				speed = 1.5,
				force = player.force
			}
			if e and e.valid then
				e.combat_robot_owner = player.character
			end
		end
	elseif class == Public.enum.VETERAN then
		local chance = Balance.veteran_destroyer_summon_chance
		if Math.random() < chance then
			local random_vec = Math.random_vec(3)
			local e = player.surface.create_entity{
				name = 'destroyer',
				position = Utils.psum{player.character.position, random_vec},
				speed = 1.5,
				force = player.force
			}
			if e and e.valid then
				e.combat_robot_owner = player.character
			end
		end
	end
end


function Public.lumberjack_bonus_items(give_table)
	local memory = Memory.get_crew_memory()

	if Math.random(Balance.every_nth_tree_gives_coins) == 1 then
		local a = Balance.lumberjack_coins_from_tree
		give_table[#give_table + 1] = {name = 'coin', count = a}
		memory.playtesting_stats.coins_gained_by_trees_and_rocks = memory.playtesting_stats.coins_gained_by_trees_and_rocks + a
	elseif Math.random(2) == 1 then
		local multiplier = Balance.island_richness_avg_multiplier() * Math.random_float_in_range(1, 1.5)
		local amount = Math.ceil(Balance.lumberjack_ore_base_amount * multiplier)
		if Math.random(4) == 1 then
			give_table[#give_table + 1] = {name = 'copper-ore', count = amount}
		else
			give_table[#give_table + 1] = {name = 'iron-ore', count = amount}
		end
	end
end

function Public.try_unlock_class(class_for_sale, player, force_unlock)
	force_unlock = force_unlock or nil
	local memory = Memory.get_crew_memory()

	if not class_for_sale then return false end
	if not player then return false end

	local required_class = Public.class_purchase_requirement[class_for_sale]

	if not (memory.classes_table and memory.spare_classes) then
		return false
	end

	if not Public.class_is_obtainable(class_for_sale) then return false end

	if required_class then
		-- check if pre-requisite class is taken by someone
		for p_index, chosen_class in pairs(memory.classes_table) do
			if chosen_class == required_class then
				memory.classes_table[p_index] = class_for_sale

				-- update GUI data
				for _, class_entry in ipairs(memory.unlocked_classes) do
					if class_entry.taken_by == p_index then
						class_entry.class = class_for_sale
						break
					end
				end
				return true
			end
		end

		-- check if pre-requisite class is in spare classes
		for i, spare_class in pairs(memory.spare_classes) do
			if spare_class == required_class then
				memory.spare_classes[i] = class_for_sale

				-- update GUI data
				for _, class_entry in ipairs(memory.unlocked_classes) do
					if required_class == class_entry.class and (not class_entry.taken_by) then
						class_entry.class = class_for_sale
						break
					end
				end
				return true
			end
		end

		-- allows to unlock class even if pre-requisite is missing
		if force_unlock then
			memory.spare_classes[#memory.spare_classes + 1] = class_for_sale

			-- if player who unlocked class doesn't have one equipped, equip it for him
			if not memory.classes_table[player.index] then
				memory.classes_table[player.index] = class_for_sale

				-- update GUI data
				memory.unlocked_classes[#memory.unlocked_classes + 1] = {class = class_for_sale, taken_by = player.index}
			else
				-- update GUI data
				memory.unlocked_classes[#memory.unlocked_classes + 1] = {class = class_for_sale}
			end

			return true
		end
	else -- there is no required class
		-- if player who unlocked class doesn't have one equipped, equip it for him
		if not memory.classes_table[player.index] then
			memory.classes_table[player.index] = class_for_sale

			-- update GUI data
			memory.unlocked_classes[#memory.unlocked_classes + 1] = {class = class_for_sale, taken_by = player.index}
		else
			memory.spare_classes[#memory.spare_classes + 1] = class_for_sale

			-- update GUI data
			memory.unlocked_classes[#memory.unlocked_classes + 1] = {class = class_for_sale}
		end
		return true
	end

	return false
end

function Public.has_class(player_index)
	local memory = Memory.get_crew_memory()

	if memory.classes_table and memory.classes_table[player_index] then
		return true
	else
		return false
	end
end

function Public.get_class(player_index)
	local memory = Memory.get_crew_memory()

	if Public.has_class(player_index) then
		return memory.classes_table[player_index]
	else
		return nil
	end
end


local event = require 'utils.event'
event.add(defines.events.on_player_used_capsule, class_on_player_used_capsule)

return Public