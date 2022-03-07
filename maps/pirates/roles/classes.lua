
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
}
Public.explanation = {
	[enum.DECKHAND] = 'They move faster and generate ore for the captain\'s cabin whilst onboard above deck, but move slower offboard.',
	[enum.FISHERMAN] = 'They fish at greater distance.',
	[enum.SCOUT] = 'They are faster, but frail and deal less damage.',
	[enum.SAMURAI] = 'They are tough, and *with no weapon equipped* fight well by melee, but poorly otherwise.',
	[enum.MERCHANT] = 'They generate 40 coins per league, but are frail.',
	[enum.SHORESMAN] = 'They move slightly faster and generate ore for the captain\'s cabin whilst offboard, but move slower onboard.',
	[enum.BOATSWAIN] = 'They move faster and generate lots of ore for the captain\'s cabin whilst below deck, but move slower offboard.',
	[enum.PROSPECTOR] = 'They find more resources when handmining ore.',
	[enum.LUMBERJACK] = 'They find more resources when chopping trees.',
	[enum.MASTER_ANGLER] = 'They fish at much greater distance, and catch more.',
	[enum.WOOD_LORD] = 'They find many more resources when chopping trees.',
	[enum.CHIEF_EXCAVATOR] = 'They find many more resources when handmining ore.',
	[enum.HATAMOTO] = 'They are very tough, and *with no weapon equipped* fight well by melee.',
	[enum.IRON_LEG] = 'They are very resistant to damage when carrying 2500 iron ore.',
	[enum.QUARTERMASTER] = 'Nearby crew generate a little ore for the captain\'s cabin, and have extra physical attack.',
	[enum.DREDGER] = 'They find surprising items when they fish.',
}

Public.class_unlocks = {
	[enum.FISHERMAN] = {enum.MASTER_ANGLER},
	[enum.LUMBERJACK] = {enum.WOOD_LORD},
	[enum.PROSPECTOR] = {enum.CHIEF_EXCAVATOR},
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
	-- if _DEBUG then
	-- 	return {
	-- 		enum.QUARTERMASTER,
	-- 	}
	-- end
	return {
		enum.DECKHAND,
		enum.FISHERMAN,
		enum.SCOUT,
		enum.SAMURAI,
		enum.MERCHANT,
		enum.SHORESMAN,
		enum.SHORESMAN,
		enum.BOATSWAIN,
		enum.PROSPECTOR,
		enum.LUMBERJACK,
		enum.IRON_LEG,
		enum.QUARTERMASTER,
		enum.QUARTERMASTER,
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
					Common.notify_force_light(force,string.format('%s gave up the class %s.', player.name, Public.display_form[memory.classes_table[player.index]]))
				end
			end

			memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player.index]
			memory.classes_table[player.index] = nil
		end
	end
end

function Public.generate_class_for_sale()
	local memory = Memory.get_crew_memory()

	if #memory.available_classes_pool > 0 then

		local class = memory.available_classes_pool[Math.random(#memory.available_classes_pool)]
	
		return class
	else
		return nil
	end
end

return Public