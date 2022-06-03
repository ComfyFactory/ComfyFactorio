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
}

function Public.display_form(class)
	return {'pirates.class_' .. class}
end

function Public.explanation(class)
	return {'pirates.class_' .. class .. '_explanation'}
end

function Public.explanation_advanced(class)
	local explanation = 'pirates.class_' .. class .. '_explanation_advanced'
	local full_explanation = {}

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
		full_explanation = {'', {explanation, extra_range}}
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
		local melee_damage = Balance.samurai_damage_dealt_with_melee_multiplier
		local non_melee_damage = Public.percentage_points_difference_from_100_percent(Balance.samurai_damage_dealt_when_not_melee_multiplier)
		full_explanation = {'', {explanation, received_damage, melee_damage, non_melee_damage}}
	elseif class == enum.HATAMOTO then
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.hatamoto_damage_taken_multiplier)
		local melee_damage = Balance.hatamoto_damage_dealt_with_melee_multiplier
		local non_melee_damage = Public.percentage_points_difference_from_100_percent(Balance.hatamoto_damage_dealt_when_not_melee_multiplier)
		full_explanation = {'', {explanation, received_damage, melee_damage, non_melee_damage}}
	elseif class == enum.IRON_LEG then
		local received_damage = Public.percentage_points_difference_from_100_percent(Balance.iron_leg_damage_taken_multiplier)
		local iron_ore_required = Balance.iron_leg_iron_ore_required
		full_explanation = {'', {explanation, received_damage, iron_ore_required}}
	else
		full_explanation = {'', {explanation}}
	end

	full_explanation[#full_explanation + 1] = Public.class_is_obtainable(class) and {'', ' ', {'pirates.class_obtainable'}} or {'', ' ', {'pirates.class_unobtainable'}} 

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
}

Public.class_purchase_requirement = {
	[enum.MASTER_ANGLER] = enum.FISHERMAN,
	[enum.WOOD_LORD] = enum.LUMBERJACK,
	[enum.CHIEF_EXCAVATOR] = enum.PROSPECTOR,
	[enum.HATAMOTO] = enum.SAMURAI,
	[enum.DREDGER] = enum.MASTER_ANGLER,
}

function Public.initial_class_pool()
	return {
		enum.DECKHAND,
		enum.DECKHAND, --good for afk players
		enum.SHORESMAN,
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
	}
end

function Public.class_is_obtainable(class)
	local obtainable_class_pool = Public.initial_class_pool()
	
	for _, unlocked_class_list in pairs(Public.class_unlocks) do
		for __, unlocked_class in ipairs(unlocked_class_list) do
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


function Public.assign_class(player_index, class, self_assigned)
	local memory = Memory.get_crew_memory()
	local player = game.players[player_index]

	if not memory.classes_table then memory.classes_table = {} end

	if memory.classes_table[player_index] == class then
		Common.notify_player_error(player, {'pirates.error_class_assign_redundant', Public.display_form(class)})
		return false
	end

	if Utils.contains(memory.spare_classes, class) then -- verify that one is spare

		Public.try_renounce_class(player, false)

		memory.classes_table[player_index] = class

		local force = memory.force
		if force and force.valid then
			if self_assigned then
				Common.notify_force_light(force,{'pirates.class_take_spare', player.name, Public.display_form(memory.classes_table[player_index]), Public.explanation(memory.classes_table[player_index])})
			else
				Common.notify_force_light(force,{'pirates.class_give_spare', Public.display_form(memory.classes_table[player_index]), player.name, Public.explanation(memory.classes_table[player_index])})
			end
		end

		memory.spare_classes = Utils.ordered_table_with_single_value_removed(memory.spare_classes, class)
		return true
	else
		Common.notify_player_error(player, {'pirates.error_class_assign_unavailable_class'})
		return false
	end
end

function Public.try_renounce_class(player, whisper_failure_message, impersonal_bool)
	local memory = Memory.get_crew_memory()

	local force = memory.force
	if force and force.valid and player and player.index then
		if memory.classes_table and memory.classes_table[player.index] then
			if force and force.valid then
				if impersonal_bool then
					Common.notify_force_light(force,{'pirates.class_becomes_spare', Public.display_form(memory.classes_table[player.index])})
				else
					Common.notify_force_light(force,{'pirates.class_give_up', player.name, Public.display_form(memory.classes_table[player.index])})
				end
			end

			memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player.index]
			memory.classes_table[player.index] = nil
		elseif whisper_failure_message then
			Common.notify_player_error(player, {'pirates.class_give_up_error_no_class'})
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
	local count = ore_grant_amount(how_much, enable_scaling)
	
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

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
	local player_index = player.index

	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

    if not (player.character and player.character.valid) then
        return
    end

    local item = event.item
    if not (item and item.name and item.name == 'raw-fish') then return end

	local global_memory = Memory.get_global_memory()
	global_memory.last_players_health[event.player_index] = player.character.health

	if memory.classes_table and memory.classes_table[player_index] then
		local class = memory.classes_table[player_index]
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
				local timescale = 60*30 * Math.max((Balance.game_slowness_scale())^(2/3),0.8)
				if memory.gourmet_recency_tick then
					multiplier = multiplier *Math.clamp(0.2, 5, (1/5)^((memory.gourmet_recency_tick - game.tick)/(60*300)))
					memory.gourmet_recency_tick = Math.max(memory.gourmet_recency_tick, game.tick - timescale*10) + timescale
				else
					multiplier = multiplier * 5
					memory.gourmet_recency_tick = game.tick - timescale*10 + timescale
				end
				Public.class_ore_grant(player, 10 * multiplier, Balance.gourmet_ore_scaling_enabled)
			end
		end
	end
end


function Public.lumberjack_bonus_items(give_table)
	local memory = Memory.get_crew_memory()

	if Math.random(Balance.every_nth_tree_gives_coins) == 1 then
		local a = 12
		give_table[#give_table + 1] = {name = 'coin', count = a}
		memory.playtesting_stats.coins_gained_by_trees_and_rocks = memory.playtesting_stats.coins_gained_by_trees_and_rocks + a
	elseif Math.random(2) == 1 then
		if Math.random(5) == 1 then
			give_table[#give_table + 1] = {name = 'copper-ore', count = 1}
		else
			give_table[#give_table + 1] = {name = 'iron-ore', count = 1}
		end
	end
end


local event = require 'utils.event'
event.add(defines.events.on_player_used_capsule, class_on_player_used_capsule)

return Public