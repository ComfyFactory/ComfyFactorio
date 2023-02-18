-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Session = require 'utils.datastore.session_data'
local Antigrief = require 'utils.antigrief'
-- local Balance = require 'maps.pirates.balance'
local _inspect = require 'utils.inspect'.inspect
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'
local Classes = require 'maps.pirates.roles.classes'

local Public = {}
local privilege_levels = {
	NORMAL = 1,
	OFFICER = 2,
	CAPTAIN = 3
}
Public.privilege_levels = privilege_levels


--== Roles — General ==--

function Public.reset_officers()
	local memory = Memory.get_crew_memory()
	memory.officers_table = {}
end

function Public.make_officer(captain, player)
	local memory = Memory.get_crew_memory()
	local force = memory.force

	if Utils.contains(Common.crew_get_crew_members(), player) then
		if captain.index ~= player.index then
			if Common.validate_player(player) then
				memory.officers_table[player.index] = true

				Common.notify_force_light(force,{'pirates.roles_make_officer', captain.name, player.name})
				Public.update_privileges(player)
			else
				Common.notify_player_error(captain,{'pirates.roles_make_officer_error_1'})
				return false
			end
		else
			Common.notify_player_error(captain,{'pirates.roles_make_officer_error_2'})
			return false
		end
	else
		Common.notify_player_error(captain,{'pirates.roles_make_officer_error_3'})
		return false
	end
end

function Public.unmake_officer(captain, player)
	local memory = Memory.get_crew_memory()
	local force = memory.force

	if Utils.contains(Common.crew_get_crew_members(), player) then
		if Common.is_officer(player.index) then
			memory.officers_table[player.index] = nil

			Common.notify_force_light(force,{'pirates.roles_unmake_officer', captain.name, player.name})
			Public.update_privileges(player)
			return true
		else
			Common.notify_player_error(captain,{'pirates.roles_unmake_officer_error_1'})
			return false
		end
	else
		Common.notify_player_error(captain,{'pirates.roles_unmake_officer_error_2'})
		return false
	end
end

-- function Public.revoke_class(captain, player)
-- 	local memory = Memory.get_crew_memory()
-- 	local force = memory.force

-- 	if force and force.valid and player.index and memory.classes_table[player.index] then
-- 		memory.spare_classes[#memory.spare_classes + 1] = memory.classes_table[player.index]
-- 		memory.classes_table[player.index] = nil

-- 		Common.notify_force_light(captain,{'pirates.class_revoke', captain.name, Classes.display_form(memory.classes_table[player.index]), player.name})
-- 	end
-- end

function Public.tag_text(player)
	local memory = Memory.get_crew_memory()

	local str = ''
	local tags = {}

	if Common.is_id_valid(memory.id) and Common.is_captain(player) then
		tags[#tags + 1] = 'Cap\'n'
	elseif player.controller_type == defines.controllers.spectator then
		tags[#tags + 1] = 'Spectating'
	elseif Common.is_officer(player.index) then
		tags[#tags + 1] = 'Officer'
	end

	local class = Classes.get_class(player.index)
	if class then
		tags[#tags + 1] = Classes.eng_form[class]
	end

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

-- function Public.get_classes_print_string()
-- 	local str = 'Current class Descriptions:'

-- 	for i, class in pairs(Classes.enum) do
-- 		str = str .. '\n' .. Classes.display_form[class] .. ': ' .. Classes.explanation[class] .. ''
-- 	end

-- 	return str
-- end

function Public.get_class_print_string(class, add_is_class_obstainable)

	for _, class2 in pairs(Classes.enum) do
		if Classes.eng_form[class2]:lower() == class:lower() or class2 == class:lower() then
			local explanation = Classes.explanation(class2, add_is_class_obstainable)

			if Classes.class_purchase_requirement[class2] then
				return {'pirates.class_explanation_upgraded_class', Classes.display_form(class2), Classes.display_form(Classes.class_purchase_requirement[class2]), explanation}
			else
				return {'pirates.class_explanation', Classes.display_form(class2), explanation}
			end
		end
	end

	if class:lower() == 'officer' then
		return {'pirates.class_explanation', {'pirates.role_officer'}, {'pirates.role_officer_description'}}
	end

	if class:lower() == 'captain' then
		return {'pirates.class_explanation', {'pirates.role_captain'}, {'pirates.role_captain_description'}}
	end

	return nil
end

function Public.player_privilege_level(player)
	local memory = Memory.get_crew_memory()

	if Common.is_id_valid(memory.id) and Common.is_captain(player) then
		return Public.privilege_levels.CAPTAIN
	elseif Common.is_officer(player.index) then
		return Public.privilege_levels.OFFICER
	else
		return Public.privilege_levels.NORMAL
	end
end

function Public.make_captain(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if memory.playerindex_captain then
		Public.update_privileges(game.players[memory.playerindex_captain])
	end

	memory.playerindex_captain = player.index
	global_memory.playerindex_to_captainhood_priority[player.index] = nil
	memory.captain_acceptance_timer = nil

	Public.reset_officers()
    Public.update_privileges(player)

	local force = player.force
	if force and force.valid then
		local message = {'pirates.roles_new_captain', player.name}

		Common.notify_force(force, message)
		Server.to_discord_embed_raw({'', CoreData.comfy_emojis.derp .. '[' .. memory.name .. '] ', message}, true)
	end

	log('INFO: ' .. (player.name or 'noname') .. ' is now new captain.')
end

function Public.player_confirm_captainhood(player)
	local memory = Memory.get_crew_memory()
	local captain_index = memory.playerindex_captain

	if player.index ~= captain_index then
		Common.notify_player_error(player, {'pirates.roles_confirm_captain_error_1'})
	else
		if memory.captain_acceptance_timer then
			local force = player.force
			if force and force.valid then
				local message = {'pirates.roles_confirm_captain', player.name}

				Common.notify_force(force, message)
				Server.to_discord_embed_raw({'', CoreData.comfy_emojis.derp .. '[' .. memory.name .. '] ', message}, true)
			end

			Public.make_captain(player)
		else
			Common.notify_player_error(player, {'pirates.roles_confirm_captain_error_2'})
		end
	end
end

function Public.player_left_so_redestribute_roles(player)
	if not (player and player.index) then return end

	local memory = Memory.get_crew_memory()

	if Common.is_captain(player) then
		local officers = Common.crew_get_non_afk_officers()
		if memory.run_is_protected and #officers == 0 then
			if memory.crewplayerindices and #memory.crewplayerindices > 0 then
				Common.parrot_speak(memory.force, {'pirates.parrot_captain_left_protected_run'})
				Common.parrot_speak(memory.force, {'pirates.parrot_create_new_crew_tip'})
			end
		elseif memory.run_is_protected then
			Public.make_captain(officers[1])
		else
			Public.assign_captain_based_on_priorities()
		end
	end

	-- no need to do this, as long as officers get reset when the captainhood changes hands
	-- if Common.is_officer(player.index) then
	-- 	memory.officers_table[player.index] = nil
	-- end

	local class = Classes.get_class(player.index)

	-- free up the class
	if class then
		memory.spare_classes[#memory.spare_classes + 1] = class
		memory.classes_table[player.index] = nil

		for _, class_entry in ipairs(memory.unlocked_classes) do
			if class_entry.taken_by == player.index then
				class_entry.taken_by = nil
				break
			end
		end
	end
end


function Public.renounce_captainhood(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if #Common.crew_get_crew_members() == 1 then
		Common.notify_player_error(player, {'pirates.roles_renounce_captain_error_1'})
	else

		local force = memory.force
		global_memory.playerindex_to_captainhood_priority[player.index] = nil
		if force and force.valid then
			local message = {'pirates.roles_renounce_captain', player.name}

			Common.notify_force(force, message)
			Server.to_discord_embed_raw({'', CoreData.comfy_emojis.ree1 .. '[' .. memory.name .. '] ', message}, true)
		end

		Public.assign_captain_based_on_priorities(player.index)
	end
end

function Public.resign_as_officer(player)
	local memory = Memory.get_crew_memory()
	local force = memory.force

	if Common.is_officer(player.index) then
		memory.officers_table[player.index] = nil


		local message = {'pirates.roles_resign_officer', player.name}

		Common.notify_force(force, message)
		Server.to_discord_embed_raw({'', CoreData.comfy_emojis.ree1 .. '[' .. memory.name .. '] ', message}, true)
	else
		log('Error: player tried to resign as officer despite not being one.')
	end
end

function Public.captain_exists()
	local memory = Memory.get_crew_memory()

	if Common.is_id_valid(memory.id) and
		memory.crewstatus == 'adventuring' and --@fixme: enum hacked
		memory.playerindex_captain and
		game.players[memory.playerindex_captain] and
		Common.validate_player(game.players[memory.playerindex_captain])
	then
		local crew_members = Common.crew_get_crew_members()
		for _, player in pairs(crew_members) do
			if player.index == memory.playerindex_captain then
				return true
			end
		end
	end

	return false
end


function Public.confirm_captain_exists(player_to_make_captain_otherwise)
	-- Currently this catches an issue where a crew drops to zero players, and then someone else joins.
	if not Public.captain_exists() then
		if player_to_make_captain_otherwise then
			Public.make_captain(player_to_make_captain_otherwise)
			-- game.print('Auto-reassigning captain.')
		else
			log('Error: Couldn\'t make a captain.')
		end
	end
end

function Public.pass_captainhood(player, player_to_pass_to)
	-- local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	local force = memory.force
	if not (force and force.valid) then return end



	local message = {'pirates.roles_pass_captainhood', player.name, player_to_pass_to.name}

	Common.notify_force(force, message)
	Server.to_discord_embed_raw({'', CoreData.comfy_emojis.spurdo .. '[' .. memory.name .. '] ', message}, true)

	Public.make_captain(player_to_pass_to)
end

function Public.afk_player_tick(player)
	-- local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	local non_afk_members = Common.crew_get_nonafk_crew_members()
	local officers = Common.crew_get_non_afk_officers()

	if Common.is_captain(player) and #non_afk_members >= 1 and ((not memory.run_is_protected) or #officers > 0) then
		if #non_afk_members == 1 then --don't need to bounce it around
			Public.make_captain(non_afk_members[1])
		else
			local force = memory.force
			if force and force.valid then
				local message = {'pirates.roles_lose_captainhood_by_afk', player.name}

				Common.notify_force(force, message)
				Server.to_discord_embed_raw({'', CoreData.comfy_emojis.loops .. '[' .. memory.name .. '] ', message}, true)
			end

			if memory.run_is_protected then
				Public.make_captain(officers[1])
			else
				Public.assign_captain_based_on_priorities()
			end
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

	-- Prefer officers for a captain (if there are any)
	-- NOTE: this will try offering captain role to officer just once. It won't necessarily offer captain role to 2nd officer in the list if 1st officer rejects it.
	for player_index, _ in pairs(memory.officers_table) do
		local player = game.players[player_index]
		local player_active = Utils.contains(Common.crew_get_nonafk_crew_members(), player)

		if player_active then
			captain_index = player_index
			captain_name = player.name
			break
		end
	end

	-- No officers (or all officers afk), try pass captain to oldest crew member
	if not captain_index then
		for _, player_index in pairs(crew_members) do
			local player = game.players[player_index]

			if Common.validate_player(player) and not (player.index == excluded_player_index) then

				local player_active = Utils.contains(Common.crew_get_nonafk_crew_members(), player)

				-- prefer non-afk players:
				if only_found_afk_players or player_active then
					only_found_afk_players = player_active

					local player_priority = global_memory.playerindex_to_captainhood_priority[player_index]
					if player_priority and player_priority > best_priority_so_far then
						best_priority_so_far = player_priority
						captain_index = player_index
						captain_name = player.name
					end
				end
			end
		end
	end

	local force = memory.force
	if not (force and force.valid) then return end

	-- if all crew members afk (or if by some chance failed to pass captain), just give captain to first crew member
	if not captain_index then
		captain_index = crew_members[1]
		captain_name = game.players[captain_index].name
		Common.notify_force(force,{'pirates.roles_notify_looking_for_captain'})
	end

	if captain_index then
		local player = game.players[captain_index]
		if player and Common.validate_player(player) then
			Public.make_captain(player)
			-- this sets memory.captain_acceptance_timer = nil so now we must reset that after this function
		end
	end

	if #Common.crew_get_crew_members() > 1 then
		local rng = Math.random(4)
		local message
		if rng <= 2 then
			message = {'pirates.roles_ask_player_about_captainhood_variant_1', captain_name}
		elseif rng <= 3 then
			message = {'pirates.roles_ask_player_about_captainhood_variant_2', captain_name}
		else
			message = {'pirates.roles_ask_player_about_captainhood_variant_3', captain_name}
		end

		Common.notify_force_light(force, message)
		-- Server.to_discord_embed_raw('[' .. memory.name .. ']' .. CoreData.comfy_emojis.spurdo .. ' ' .. message)
		memory.captain_acceptance_timer = 72 --tuned
	else
		memory.captain_acceptance_timer = nil
	end
end


function Public.captain_tax(captain_index)
	if not captain_index then return end

	local memory = Memory.get_crew_memory()
	local any_taken = false

	local items_to_req = {'coin', 'rail-signal', 'uranium-235'}

	local item_count_table = {}
	for _, i in pairs(items_to_req) do
		item_count_table[i] = 0
	end

	local crew_members = memory.crewplayerindices
	local captain = game.players[captain_index]
	if not (captain and crew_members) then return end

	local captain_inv = captain.get_inventory(defines.inventory.character_main)
	if captain_inv and captain_inv.valid then
		for _, player_index in pairs(crew_members) do
			if player_index ~= captain_index then
				local player = game.players[player_index]
				if player and player.valid and not (Common.is_officer(player.index)) then
					local inv = player.get_inventory(defines.inventory.character_main)
					if inv and inv.valid then
						for _, i in pairs(items_to_req) do
							local amount = inv.get_item_count(i)
							if i == 'coin' then amount = Math.floor(amount/100*Common.coin_tax_percentage) end
							if amount and amount > 0 then
								inv.remove{name=i, count=amount}
								captain_inv.insert{name=i, count=amount}
								item_count_table[i] = item_count_table[i] + amount
								any_taken = true
							end
						end
					end

					local cursor_stack = player.cursor_stack
					if cursor_stack and cursor_stack.valid_for_read then
						for _, i in pairs(items_to_req) do
							if cursor_stack.name == i then
								local cursor_stack_count = cursor_stack.count
								if cursor_stack_count > 0 then
									cursor_stack.count = 0
									captain_inv.insert{name=i, count = cursor_stack_count}
									item_count_table[i] = item_count_table[i] + cursor_stack_count
									any_taken = true
								end
								break
							end
						end
					end
				end
			end
		end

		if any_taken then
			local str = {''}
			local j = 1
			for i = 1, #items_to_req do
				local item = items_to_req[i]
				local count = item_count_table[item]
				if count > 0 then
					if j > 1 then
						if i == #items_to_req then
							str[#str+1] = {'pirates.separator_2'}
						else
							str[#str+1] = {'pirates.separator_1'}
						end
					end
					local display_name = item
					if display_name == 'coin' then display_name = 'doubloons' end
					if count >= 1000 then
						str[#str+1] = Utils.bignumber_abbrevform2(count)
						str[#str+1] = ' '
						str[#str+1] = display_name
					else
						str[#str+1] = count
						str[#str+1] = ' '
						str[#str+1] = display_name
					end
					j = j + 1
				end
			end
			Common.notify_force(memory.force, {'pirates.tax', str})
		else
			Common.notify_player_error(captain, {'pirates.tax_error_nothing'})
		end
	end
end


function Public.try_create_permissions_groups()

    if not game.permissions.get_group('restricted_area') then
		local group = game.permissions.create_group('restricted_area')
        group.set_allows_action(defines.input_action.edit_permission_group, false)
        group.set_allows_action(defines.input_action.import_permissions_string, false)
        group.set_allows_action(defines.input_action.delete_permission_group, false)
        group.set_allows_action(defines.input_action.add_permission_group, false)
        group.set_allows_action(defines.input_action.admin_action, false)

        group.set_allows_action(defines.input_action.cancel_craft, false)
        group.set_allows_action(defines.input_action.drop_item, false)
        group.set_allows_action(defines.input_action.drop_blueprint_record, false)
        group.set_allows_action(defines.input_action.build, false)
        group.set_allows_action(defines.input_action.build_rail, false)
        group.set_allows_action(defines.input_action.build_terrain, false)
        group.set_allows_action(defines.input_action.begin_mining, false)
        group.set_allows_action(defines.input_action.begin_mining_terrain, false)
        -- group.set_allows_action(defines.input_action.deconstruct, false) --pick up dead players
        group.set_allows_action(defines.input_action.activate_copy, false)
        group.set_allows_action(defines.input_action.activate_cut, false)
        group.set_allows_action(defines.input_action.activate_paste, false)
        group.set_allows_action(defines.input_action.upgrade, false)

		group.set_allows_action(defines.input_action.grab_blueprint_record, false)
		if not CoreData.blueprint_library_allowed then
			group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
		end
		if not CoreData.blueprint_importing_allowed then
			group.set_allows_action(defines.input_action.import_blueprint_string, false)
			group.set_allows_action(defines.input_action.import_blueprint, false)
		end
        group.set_allows_action(defines.input_action.fast_entity_transfer, false)
        group.set_allows_action(defines.input_action.fast_entity_split, false)
    end

    if not game.permissions.get_group('super_restricted_area') then
		local group = game.permissions.create_group('super_restricted_area')
        group.set_allows_action(defines.input_action.edit_permission_group, false)
        group.set_allows_action(defines.input_action.import_permissions_string, false)
        group.set_allows_action(defines.input_action.delete_permission_group, false)
        group.set_allows_action(defines.input_action.add_permission_group, false)
        group.set_allows_action(defines.input_action.admin_action, false)

        group.set_allows_action(defines.input_action.cancel_craft, false)
        group.set_allows_action(defines.input_action.drop_item, false)
        group.set_allows_action(defines.input_action.drop_blueprint_record, false)
        group.set_allows_action(defines.input_action.build, false)
        group.set_allows_action(defines.input_action.build_rail, false)
        group.set_allows_action(defines.input_action.build_terrain, false)
        group.set_allows_action(defines.input_action.begin_mining, false)
        group.set_allows_action(defines.input_action.begin_mining_terrain, false)
        -- group.set_allows_action(defines.input_action.deconstruct, false) --pick up dead players
        group.set_allows_action(defines.input_action.activate_copy, false)
        group.set_allows_action(defines.input_action.activate_cut, false)
        group.set_allows_action(defines.input_action.activate_paste, false)
        group.set_allows_action(defines.input_action.upgrade, false)

		group.set_allows_action(defines.input_action.grab_blueprint_record, false)
		if not CoreData.blueprint_library_allowed then
			group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
		end
		if not CoreData.blueprint_importing_allowed then
			group.set_allows_action(defines.input_action.import_blueprint_string, false)
			group.set_allows_action(defines.input_action.import_blueprint, false)
		end

        group.set_allows_action(defines.input_action.fast_entity_transfer, false)
        group.set_allows_action(defines.input_action.fast_entity_split, false)

        group.set_allows_action(defines.input_action.open_gui, false)
    end

    if not game.permissions.get_group('restricted_area_privileged') then
		local group = game.permissions.create_group('restricted_area_privileged')
        group.set_allows_action(defines.input_action.edit_permission_group, false)
        group.set_allows_action(defines.input_action.import_permissions_string, false)
        group.set_allows_action(defines.input_action.delete_permission_group, false)
        group.set_allows_action(defines.input_action.add_permission_group, false)
        group.set_allows_action(defines.input_action.admin_action, false)

        group.set_allows_action(defines.input_action.cancel_craft, false)
        group.set_allows_action(defines.input_action.drop_item, false)
        group.set_allows_action(defines.input_action.drop_blueprint_record, false)
        group.set_allows_action(defines.input_action.build, false)
        group.set_allows_action(defines.input_action.build_rail, false)
        group.set_allows_action(defines.input_action.build_terrain, false)
        group.set_allows_action(defines.input_action.begin_mining, false)
        group.set_allows_action(defines.input_action.begin_mining_terrain, false)
        -- group.set_allows_action(defines.input_action.deconstruct, false) --pick up dead players
        group.set_allows_action(defines.input_action.activate_copy, false)
        group.set_allows_action(defines.input_action.activate_cut, false)
        group.set_allows_action(defines.input_action.activate_paste, false)
        group.set_allows_action(defines.input_action.upgrade, false)

		if not CoreData.blueprint_library_allowed then
			group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
			group.set_allows_action(defines.input_action.grab_blueprint_record, false)
		end
		if not CoreData.blueprint_importing_allowed then
			group.set_allows_action(defines.input_action.import_blueprint_string, false)
			group.set_allows_action(defines.input_action.import_blueprint, false)
		end
    end

    if not game.permissions.get_group('plebs') then
        local plebs_group = game.permissions.create_group('plebs')
		if not _DEBUG then
			plebs_group.set_allows_action(defines.input_action.edit_permission_group, false)
			plebs_group.set_allows_action(defines.input_action.import_permissions_string, false)
			plebs_group.set_allows_action(defines.input_action.delete_permission_group, false)
			plebs_group.set_allows_action(defines.input_action.add_permission_group, false)
			plebs_group.set_allows_action(defines.input_action.admin_action, false)

			if not CoreData.blueprint_library_allowed then
				plebs_group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
				plebs_group.set_allows_action(defines.input_action.grab_blueprint_record, false)
			end
			if not CoreData.blueprint_importing_allowed then
				plebs_group.set_allows_action(defines.input_action.import_blueprint_string, false)
				plebs_group.set_allows_action(defines.input_action.import_blueprint, false)
			end
		end
    end

    if not game.permissions.get_group('not_trusted') then
        local not_trusted = game.permissions.create_group('not_trusted')
        -- not_trusted.set_allows_action(defines.input_action.cancel_craft, false)
        not_trusted.set_allows_action(defines.input_action.edit_permission_group, false)
        not_trusted.set_allows_action(defines.input_action.import_permissions_string, false)
        not_trusted.set_allows_action(defines.input_action.delete_permission_group, false)
        not_trusted.set_allows_action(defines.input_action.add_permission_group, false)
        not_trusted.set_allows_action(defines.input_action.admin_action, false)
        -- not_trusted.set_allows_action(defines.input_action.drop_item, false)
        not_trusted.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        not_trusted.set_allows_action(defines.input_action.connect_rolling_stock, false)
        not_trusted.set_allows_action(defines.input_action.open_train_gui, false)
        not_trusted.set_allows_action(defines.input_action.open_train_station_gui, false)
        not_trusted.set_allows_action(defines.input_action.open_trains_gui, false)
        not_trusted.set_allows_action(defines.input_action.change_train_stop_station, false)
        not_trusted.set_allows_action(defines.input_action.change_train_wait_condition, false)
        not_trusted.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
        not_trusted.set_allows_action(defines.input_action.drag_train_schedule, false)
        not_trusted.set_allows_action(defines.input_action.drag_train_wait_condition, false)
        not_trusted.set_allows_action(defines.input_action.go_to_train_station, false)
        not_trusted.set_allows_action(defines.input_action.remove_train_station, false)
        not_trusted.set_allows_action(defines.input_action.set_trains_limit, false)
        not_trusted.set_allows_action(defines.input_action.set_train_stopped, false)

		not_trusted.set_allows_action(defines.input_action.grab_blueprint_record, false)
		if not CoreData.blueprint_library_allowed then
			not_trusted.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
		end
		if not CoreData.blueprint_importing_allowed then
			not_trusted.set_allows_action(defines.input_action.import_blueprint_string, false)
			not_trusted.set_allows_action(defines.input_action.import_blueprint, false)
		end
    end
end



function Public.add_player_to_permission_group(player, group_override)
    -- local jailed = Jailed.get_jailed_table()
    -- local enable_permission_group_disconnect = WPT.get('disconnect_wagon')
    local session = Session.get_session_table()
    local AG = Antigrief.get()

    local gulag = game.permissions.get_group('gulag')
    local tbl = gulag and gulag.players
    for i = 1, #tbl do
        if tbl[i].index == player.index then
            return
        end
    end

    -- if player.admin then
    --     return
    -- end

    local playtime = player.online_time
    if session and session[player.name] then
        playtime = player.online_time + session[player.name]
    end

    -- if jailed[player.name] then
    --     return
    -- end

	Public.try_create_permissions_groups()

	local group
	if group_override then
		group = game.permissions.get_group(group_override)
	else
		if AG.enabled and not player.admin and playtime < 5184000 then -- 24 hours
			group = game.permissions.get_group('not_trusted')
		else
			group = game.permissions.get_group('plebs')
		end
	end
	group.add_player(player)
end

function Public.update_privileges(player)
	Public.try_create_permissions_groups()

    if not Common.validate_player_and_character(player) then
        return
    end

	if string.sub(player.surface.name, 9, 17) == 'Crowsnest' then
		if Public.player_privilege_level(player) >= Public.privilege_levels.OFFICER then
			return Public.add_player_to_permission_group(player, 'restricted_area_privileged')
		else
			return Public.add_player_to_permission_group(player, 'super_restricted_area')
		end
	elseif string.sub(player.surface.name, 9, 13) == 'Cabin' then
		if Public.player_privilege_level(player) >= Public.privilege_levels.OFFICER then
			return Public.add_player_to_permission_group(player, 'restricted_area_privileged')
		else
			return Public.add_player_to_permission_group(player, 'restricted_area')
		end
    else
        return Public.add_player_to_permission_group(player)
	end
end


return Public