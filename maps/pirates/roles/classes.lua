
local Balance = require 'maps.pirates.balance'
local inspect = require 'utils.inspect'.inspect
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'

local Public = {}
local enum = {
	DECKHAND = 1,
	FISHERMAN = 2,
	SCOUT = 3,
	SAMURAI = 4,
	MERCHANT = 5,
	SHORESMAN = 6,
	BOATSWAIN = 7,
	PROSPECTOR = 8,
	LUMBERJACK = 9,
	MASTER_ANGLER = 10,
	WOOD_LORD = 11,
	CHIEF_EXCAVATOR = 12,
	HATAMOTO = 13,
	IRON_LEG = 14,
	QUARTERMASTER = 15,
	DREDGER = 16,
	SMOLDERING = 17,
	GOURMET = 18,
}
Public.enum = enum

Public.Class_List = {
	enum.DECKHAND,
	enum.FISHERMAN,
	enum.SCOUT,
	enum.SAMURAI,
	enum.MERCHANT,
	enum.SHORESMAN,
	enum.BOATSWAIN,
	enum.PROSPECTOR,
	enum.LUMBERJACK,
	enum.MASTER_ANGLER,
	enum.WOOD_LORD,
	enum.CHIEF_EXCAVATOR,
	enum.HATAMOTO,
	enum.IRON_LEG,
	enum.QUARTERMASTER,
	enum.DREDGER,
	enum.SMOLDERING,
	enum.GOURMET,
}

Public.display_form = {
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
	[enum.WOOD_LORD] = 'Lord of the Woods',
	[enum.CHIEF_EXCAVATOR] = 'Chief Excavator',
	[enum.HATAMOTO] = 'Hatamoto',
	[enum.IRON_LEG] = 'Iron Leg',
	[enum.QUARTERMASTER] = 'Quartermaster',
	[enum.DREDGER] = 'Dredger',
	[enum.SMOLDERING] = 'Smoldering',
	[enum.GOURMET] = 'Gourmet',
}
Public.explanation = {
	[enum.DECKHAND] = 'They move faster and generate ore for the captain\'s cabin whilst onboard above deck, but move slower offboard.',
	[enum.FISHERMAN] = 'They fish at greater distance.',
	[enum.SCOUT] = 'They are faster, but frail and deal less damage.',
	[enum.SAMURAI] = 'They are tough, and *with no weapon equipped* fight well by melee, but poorly otherwise.',
	[enum.MERCHANT] = 'They generate 40 doubloons per league, but are frail.',
	[enum.SHORESMAN] = 'They move slightly faster and generate ore for the captain\'s cabin whilst offboard, but move slower onboard.',
	[enum.BOATSWAIN] = 'They move faster and generate ore for the captain\'s cabin whilst below deck, but move slower offboard.',
	[enum.PROSPECTOR] = 'They find more resources when handmining ore.',
	[enum.LUMBERJACK] = 'They find more resources when chopping trees.',
	[enum.MASTER_ANGLER] = 'They fish at much greater distance, and catch more.',
	[enum.WOOD_LORD] = 'They find many more resources when chopping trees.',
	[enum.CHIEF_EXCAVATOR] = 'They find many more resources when handmining ore.',
	[enum.HATAMOTO] = 'They are very tough, and *with no weapon equipped* fight well by melee, but poorly otherwise.',
	[enum.IRON_LEG] = 'They are very resistant to damage when carrying 2500 iron ore.',
	[enum.QUARTERMASTER] = 'They give nearby crewmates extra physical attack, and generate ore for the captain\'s cabin for each one.',
	[enum.DREDGER] = 'They find surprising items when they fish.',
	[enum.SMOLDERING] = 'They periodically convert wood into coal, if they have less than 25 coal.',
	[enum.GOURMET] = 'They generate ore for the captain\'s cabin by eating fish in fancy locations.',
}

Public.class_unlocks = {
	[enum.FISHERMAN] = {enum.MASTER_ANGLER},
	[enum.LUMBERJACK] = {enum.WOOD_LORD},
	-- [enum.PROSPECTOR] = {enum.CHIEF_EXCAVATOR}, --breaks the resource pressure in the game too strongly I think
	[enum.SAMURAI] = {enum.HATAMOTO},
	[enum.MASTER_ANGLER] = {enum.DREDGER},
}

Public.class_purchase_requirement = {
	[enum.MASTER_ANGLER] = enum.FISHERMAN,
	[enum.WOOD_LORD] = enum.LUMBERJACK,
	-- [enum.CHIEF_EXCAVATOR] = enum.PROSPECTOR,
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
		enum.PROSPECTOR,
		enum.LUMBERJACK,
		enum.IRON_LEG,
		enum.SMOLDERING,
		enum.GOURMET,
	}
end


function Public.assign_class(player_index, class, self_assigned)
	local memory = Memory.get_crew_memory()

	if not memory.classes_table then memory.classes_table = {} end

	if Utils.contains(memory.spare_classes, class) then -- verify that one is spare
	
		memory.classes_table[player_index] = class
	
		local force = memory.force
		if force and force.valid then
			local message
			if self_assigned then
				message = '%s took the spare class %s. ([font=scenario-message-dialog]%s[/font])'
				Common.notify_force_light(force,string.format(message, game.players[player_index].name, Public.display_form[memory.classes_table[player_index]], Public.explanation[memory.classes_table[player_index]]))
			else
				message = 'A spare %s class was given to %s. [font=scenario-message-dialog](%s)[/font]'
				Common.notify_force_light(force,string.format(message, Public.display_form[memory.classes_table[player_index]], game.players[player_index].name, Public.explanation[memory.classes_table[player_index]]))
			end
		end
	
		memory.spare_classes = Utils.ordered_table_with_single_value_removed(memory.spare_classes, class)
	end
end

function Public.try_renounce_class(player, override_message)
	local memory = Memory.get_crew_memory()

	local force = memory.force
	if force and force.valid then
		if player and player.index and memory.classes_table and memory.classes_table[player.index] then
			if force and force.valid then
				if override_message then
					Common.notify_force_light(force,string.format(override_message, Public.display_form[memory.classes_table[player.index]]))
				else
					Common.notify_force_light(force,string.format('%s gave up %s.', player.name, Public.display_form[memory.classes_table[player.index]])) --shorter for less spam
					-- Common.notify_force_light(force,string.format('%s gave up the class %s.', player.name, Public.display_form[memory.classes_table[player.index]]))
				end
			end

			memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player.index]
			memory.classes_table[player.index] = nil
		end
	end
end

function Public.generate_class_for_sale()
	local memory = Memory.get_crew_memory()

	if #memory.available_classes_pool == 0 then
		-- memory.available_classes_pool = Public.initial_class_pool() --reset to initial state
		-- turned off as this makes too many classes
	end

	local class
	if #memory.available_classes_pool > 0 then
		class = memory.available_classes_pool[Math.random(#memory.available_classes_pool)]
	end

	return class
end



function Public.class_ore_grant(player, how_much, disable_scaling)
	local count
	if disable_scaling then
		count = Math.ceil(how_much)
	else
		count = Math.ceil(how_much * Balance.class_resource_scale())
	end
	if Math.random(3) == 1 then
		Common.flying_text_small(player.surface, player.position, '[color=0.85,0.58,0.37]+' .. count .. '[/color]')
		Common.give_items_to_crew{{name = 'copper-ore', count = count}}
	else
		Common.flying_text_small(player.surface, player.position, '[color=0.7,0.8,0.8]+' .. count .. '[/color]')
		Common.give_items_to_crew{{name = 'iron-ore', count = count}}
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

	if memory.classes_table and memory.classes_table[player_index] then
		local class = memory.classes_table[player_index]
		if class == Public.enum.SAMURAI then
			-- vanilla heal is 80HP
			player.character.health = player.character.health + 175
		elseif class == Public.enum.HATAMOTO then
			player.character.health = player.character.health + 250
		elseif class == Public.enum.GOURMET then
			local tile = player.surface.get_tile(player.position)
			if tile.valid then
				local multiplier = 0
				if tile.name == CoreData.world_concrete_tile then
					multiplier = 1.5
				elseif tile.name == 'cyan-refined-concrete' then
					multiplier = 1.6
				elseif tile.name == CoreData.walkway_tile then
					multiplier = 1
				elseif tile.name == 'orange-refined-concrete' then
					multiplier = 0.8
				elseif tile.name == CoreData.enemy_landing_tile then
					multiplier = 0.33
				elseif tile.name == CoreData.static_boat_floor then
					multiplier = 0.1
				end
				if multiplier > 0 then
					local timescale = 60*30 * Math.max((Balance.game_slowness_scale())^(2/3),0.8)
					if memory.gourmet_recency_tick then
						multiplier = multiplier * Math.max(0.2, Math.min(5, (1/5)^((memory.gourmet_recency_tick - game.tick)/(60*300))))
						memory.gourmet_recency_tick = Math.max(memory.gourmet_recency_tick, game.tick - timescale*10) + timescale
					else
						multiplier = multiplier * 5
						memory.gourmet_recency_tick = game.tick - timescale*10 + timescale
					end
					Public.class_ore_grant(player, 10 * multiplier, true)
				end
			end
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_player_used_capsule, class_on_player_used_capsule)

return Public