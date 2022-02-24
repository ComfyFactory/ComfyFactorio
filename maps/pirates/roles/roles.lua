
local Balance = require 'maps.pirates.balance'
local inspect = require 'utils.inspect'.inspect
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'
local Classes = require 'maps.pirates.roles.classes'
local Public = {}



--== Roles — General ==--

function Public.tag_text(player)
	local memory = Memory.get_crew_memory()


	local tags = {}

	if memory.id ~= 0 and memory.playerindex_captain and player.index == memory.playerindex_captain then
		tags[#tags + 1] = "Cap'n"
	elseif player.controller_type == defines.controllers.spectator then
		tags[#tags + 1] = 'Spectating'
	elseif memory.officers_table and memory.classes_table[player.index] then
		tags[#tags + 1] = "Officer"
	end


	if memory.classes_table and memory.classes_table[player.index] then

		if not str == '' then str = str .. ' ' end
		tags[#tags + 1] = Classes.display_form[memory.classes_table[player.index]]
	end

	local str = ''
	for i, t in ipairs(tags) do
		if i>1 then str = str .. ', ' end
		str = str .. t
	end

	if (not (str == '')) then str = '[' .. str .. ']' end

	return str
end

function Public.update_tags(player)
	local str = Public.tag_text(player)

	player.tag = str
end

function Public.try_accept_captainhood(player)
	local memory = Memory.get_crew_memory()
	local captain_index = memory.playerindex_captain

	if not (player.index == captain_index) then
		Common.notify_player(player, 'You\'re not the captain.')
	else
		if memory.captain_acceptance_timer then
			memory.captain_acceptance_timer = nil

			local force = player.force
			if force and force.valid then
				local message = (player.name .. ' accepted the role of captain.')
				Common.notify_force(force, message)
				Server.to_discord_embed_raw(CoreData.comfy_emojis.derp .. '[' .. memory.name .. '] ' .. message)
			end
		else
			Common.notify_player(player, 'You\'re not temporary, so you don\'t need to accept.')
		end
	end
end

function Public.player_left_so_redestribute_roles(player)
	local memory = Memory.get_crew_memory()
	-- we can assume #Common.crew_get_crew_members() > 0
	
	if player and player.index and player.index == memory.playerindex_captain then
		Public.assign_captain_based_on_priorities()
	end
	
	Public.try_renounce_class(player, "A %s class is now spare.")
end


function Public.renounce_captainhood(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if #Common.crew_get_crew_members() == 1 then
		Common.notify_player(player, 'But you\'re the only crew member...')
	else

		local force = game.forces[memory.force_name]
		global_memory.playerindex_to_priority[player.index] = nil
		if force and force.valid then
			local message = (player.name .. ' renounces their title of captain.')
			Common.notify_force(force, message)
			Server.to_discord_embed_raw(CoreData.comfy_emojis.ree1 .. '[' .. memory.name .. '] ' .. message)
		end
		
		Public.assign_captain_based_on_priorities(player.index)
	end
end


function Public.assign_class(player_index, class, self_assigned)
	local memory = Memory.get_crew_memory()

	if not memory.classes_table then memory.classes_table = {} end

	if Utils.contains(memory.spare_classes, class) then -- verify that one is spare
	
		memory.classes_table[player_index] = class
	
		local force = game.forces[memory.force_name]
		if force and force.valid then
			local message
			if self_assigned then
				message = '%s took the spare class %s. ([font=scenario-message-dialog]%s[/font])'
				Common.notify_force_light(force,string.format(message, game.players[player_index].name, Classes.display_form[memory.classes_table[player_index]], Classes.explanation[memory.classes_table[player_index]]))
			else
				message = 'A spare %s class was given to %s. [font=scenario-message-dialog](%s)[/font]'
				Common.notify_force_light(force,string.format(message, Classes.display_form[memory.classes_table[player_index]], game.players[player_index].name, Classes.explanation[memory.classes_table[player_index]]))
			end
		end
	
		memory.spare_classes = Utils.ordered_table_with_single_value_removed(memory.spare_classes, class)
	end
end

function Public.try_renounce_class(player, override_message)
	local memory = Memory.get_crew_memory()

	local force = game.forces[memory.force_name]
	if force and force.valid then
		if player and player.index and memory.classes_table and memory.classes_table[player.index] then
			if force and force.valid then
				if override_message then
					Common.notify_force_light(force,string.format(override_message, Classes.display_form[memory.classes_table[player.index]]))
				else
					Common.notify_force_light(force,string.format('%s gave up the class %s.', player.name, Classes.display_form[memory.classes_table[player.index]]))
				end
			end

			memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player.index]
			memory.classes_table[player.index] = nil
		end
	end
end

function Public.pass_captainhood(player, player_to_pass_to)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	memory.playerindex_captain = player_to_pass_to.index
	global_memory.playerindex_to_priority[player_to_pass_to.index] = nil
	memory.captain_acceptance_timer = nil

	local force = game.forces[memory.force_name]
	if not (force and force.valid) then return end
	local message = string.format("%s has passed their captainhood to %s.", player.name, player_to_pass_to.name)
	Common.notify_force(force, message)
	Server.to_discord_embed_raw(CoreData.comfy_emojis.spurdo .. '[' .. memory.name .. '] ' .. message)
end

function Public.afk_player_tick(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()
	
	if player.index == memory.playerindex_captain and #Common.crew_get_nonafk_crew_members() > 0 then

		local force = game.forces[memory.force_name]
		if force and force.valid then
			local message = string.format(player.name .. ' was afk.')
			Common.notify_force(force, message)
			Server.to_discord_embed_raw(CoreData.comfy_emojis.loops .. '[' .. memory.name .. '] ' .. message)
		end

		if #Common.crew_get_nonafk_crew_members() == 1 then --don't need to bounce it around
			local new_cap_index = Common.crew_get_nonafk_crew_members()[1].index
			global_memory.playerindex_to_priority[new_cap_index] = nil
			memory.playerindex_captain = new_cap_index
		else
			Public.assign_captain_based_on_priorities()
		end
	end
end


function Public.assign_captain_based_on_priorities(excluded_player_index)
	excluded_player_index = excluded_player_index or nil

	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	local crew_members = memory.crewplayerindices

	if not (crew_members and #crew_members > 0) then return end

	local only_found_afk_players = true
	local best_priority_so_far = -1
	local captain_index = nil
	local captain_name = nil

	for _, player_index in pairs(crew_members) do
		local player = game.players[player_index]

		if Common.validate_player(player) and not (player.index == excluded_player_index) then

			local player_active = Utils.contains(Common.crew_get_nonafk_crew_members(), player)

			-- prefer non-afk players:
			if only_found_afk_players or player_active then
				only_found_afk_players = player_active
	
				local player_priority = global_memory.playerindex_to_priority[player_index]
				if player_priority and player_priority > best_priority_so_far then
					best_priority_so_far = player_priority
					captain_index = player_index
					captain_name = player.name
				end
			end
		end
	end

	local force = game.forces[memory.force_name]
	if not (force and force.valid) then return end

	if not captain_index then
		captain_index = crew_members[1]
		captain_name = game.players[captain_index].name
		Common.notify_force(force,'Looking for a suitable captain...')
	end

	global_memory.playerindex_to_priority[captain_index] = nil
	memory.playerindex_captain = captain_index



	if #Common.crew_get_crew_members() > 1 then
		local messages = {
			"would you like to be captain?",
			"would you like to be captain?",
			"captain?",
			"is it your turn to be captain?",
		}
		local message = captain_name .. ', ' .. messages[Math.random(#messages)]
		Common.notify_force_light(force, message .. ' If yes say /ok')
		-- Server.to_discord_embed_raw('[' .. memory.name .. ']' .. CoreData.comfy_emojis.spurdo .. ' ' .. message)
		memory.captain_acceptance_timer = 72 --tuned
	end
end


function Public.captain_requisition_coins(captain_index)
	local memory = Memory.get_crew_memory()
	local print = true
	if print then 
		Common.notify_force(game.forces[memory.force_name], 'Coins requisitioned by captain.')
	end

	local crew_members = memory.crewplayerindices
	local captain = game.players[captain_index]
	if not (captain and crew_members and #crew_members > 2) then return end
	
	local captain_inv = captain.get_inventory(defines.inventory.character_main)

	for _, player_index in pairs(crew_members) do
		if player_index == captain_index then return end

		local player = game.players[player_index]
		if player then
			local inv = player.get_inventory(defines.inventory.character_main)
			if not inv then return end
			local coin_amount = inv.get_item_count('coin')
			if coin_amount and coin_amount > 0 then
				inv.remove{name='coin', count=coin_amount}
				captain_inv.insert{name='coin', count=coin_amount}
			end
		end
	end
end





return Public