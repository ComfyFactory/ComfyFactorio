
local Session = require 'utils.datastore.session_data'
local Antigrief = require 'utils.antigrief'
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

	if Common.validate_player(player) and (not (captain.index == player.index)) then
		memory.officers_table[player.index] = true
	end

	local message = (captain.name .. ' made ' .. player.name .. ' an officer.')
	Common.notify_force(force, message)
    Public.update_privileges(player)
end

function Public.unmake_officer(captain, player)
	local memory = Memory.get_crew_memory()
	local force = memory.force

	if Common.validate_player(player) and (not (captain.index == player.index)) then
		memory.officers_table[player.index] = nil
	end

	local message = (captain.name .. ' unmade ' .. player.name .. ' an officer.')
	Common.notify_force(force, message)
    Public.update_privileges(player)
end

function Public.tag_text(player)
	local memory = Memory.get_crew_memory()


	local str = ''
	local tags = {}

	if memory.id ~= 0 and Common.is_captain(player) then
		tags[#tags + 1] = 'Cap\'n'
	elseif player.controller_type == defines.controllers.spectator then
		tags[#tags + 1] = 'Spectating'
	elseif memory.officers_table and memory.officers_table[player.index] then
		tags[#tags + 1] = 'Officer'
	end

	if memory.classes_table and memory.classes_table[player.index] then
		tags[#tags + 1] = Classes.display_form[memory.classes_table[player.index]]
	end

	for i, t in ipairs(tags) do
		if i>1 then str = str .. ', ' end
		str = str .. t
	end

	if (not (str == '')) then str = '[' .. str .. ']' end

	return str
end


function Public.get_classes_print_string()
	local str = 'Current class Descriptions:'

	for i, class in ipairs(Classes.Class_List) do
		str = str .. '\n' .. Classes.display_form[class] .. ': ' .. Classes.explanation[class] .. ''
	end

	return str
end

function Public.get_class_print_string(class)

	for _, class2 in ipairs(Classes.Class_List) do
		if Classes.display_form[class2]:lower() == class:lower() then
			return Classes.display_form[class2] .. ': ' .. Classes.explanation[class2] .. ''
		end
	end

	if class:lower() == 'officer' then
		return 'Officer: Assigned by the captain, officers can use the Captain\'s shop and access privileged chests.'
	end

	if class:lower() == 'captain' then
		return 'Captain: Has executive power to undock the ship, purchase items, and various other special actions. When the game assigns a captain, it gives priority to those who have been playing the longest as a non-captain.'
	end

	return nil
end

function Public.update_tags(player)
	
	local str = Public.tag_text(player)
	player.tag = str

	if game.tick % 300 == 0 and Common.validate_player_and_character(player) then
		local memory = Memory.get_crew_memory()
		if memory.classes_table and memory.classes_table[player.index] and memory.classes_table[player.index] == Classes.enum.IRON_LEG then
			local inv = player.get_inventory(defines.inventory.character_main)
			if not (inv and inv.valid) then return end
			local count = inv.get_item_count('iron-ore')
			if count and count < 2500 then
				local rgb = CoreData.colors.notify_player_error
				Common.flying_text_small(player.surface, player.position, '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']missing iron ore[/color]')
			end
		end
	end
end

function Public.player_privilege_level(player)
	local memory = Memory.get_crew_memory()

	if memory.id ~= 0 and Common.is_captain(player) then
		return Public.privilege_levels.CAPTAIN
	elseif memory.officers_table and memory.officers_table[player.index] then
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
end

function Public.player_confirm_captainhood(player)
	local memory = Memory.get_crew_memory()
	local captain_index = memory.playerindex_captain

	if not (player.index == captain_index) then
		Common.notify_player_error(player, 'You\'re not the captain.')
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
			Common.notify_player_expected(player, 'You\'re not temporary, so you don\'t need to accept.')
		end
	end
end

function Public.player_left_so_redestribute_roles(player)
	local memory = Memory.get_crew_memory()

	if player and player.index then
		if Common.is_captain(player) then
			Public.assign_captain_based_on_priorities()
		end
		
		-- no need to do this, as long as officers get reset when the captainhood changes hands
		-- if memory.officers_table and memory.officers_table[player.index] then
		-- 	memory.officers_table[player.index] = nil
		-- end
	end
	
	Classes.try_renounce_class(player, "A %s class is now spare.")
end


function Public.renounce_captainhood(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if #Common.crew_get_crew_members() == 1 then
		Common.notify_player_error(player, 'But you\'re the only crew member...')
	else

		local force = memory.force
		global_memory.playerindex_to_captainhood_priority[player.index] = nil
		if force and force.valid then
			local message = (player.name .. ' renounces their title of captain.')
			Common.notify_force(force, message)
			Server.to_discord_embed_raw(CoreData.comfy_emojis.ree1 .. '[' .. memory.name .. '] ' .. message)
		end
		
		Public.assign_captain_based_on_priorities(player.index)
	end
end

function Public.resign_as_officer(player)
	local memory = Memory.get_crew_memory()
	local force = memory.force

	if memory.officers_table and memory.officers_table[player.index] then
		memory.officers_table[player.index] = nil

		local message = (player.name .. ' resigns as an officer.')
		Common.notify_force(force, message)
		Server.to_discord_embed_raw(CoreData.comfy_emojis.ree1 .. '[' .. memory.name .. '] ' .. message)
	else
		log('Error: player tried to resign as officer despite not being one.')
	end
end



function Public.confirm_captain_exists(player_to_make_captain_otherwise)
	local memory = Memory.get_crew_memory()
	-- Currently this catches an issue where someone starts a crew and leaves it, and more players join later.

	if (memory.id and memory.id > 0 and memory.crewstatus and memory.crewstatus == 'adventuring') and (not (memory.playerindex_captain and game.players[memory.playerindex_captain] and Common.validate_player(game.players[memory.playerindex_captain]))) then --fixme: enum hacked
		if player_to_make_captain_otherwise then
			Public.make_captain(player_to_make_captain_otherwise)
			game.print('Reassigning captain.')
		else
			log('Error: Couldn\'t make a captain.')
		end
	end
end

function Public.pass_captainhood(player, player_to_pass_to)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	local force = memory.force
	if not (force and force.valid) then return end
	local message = string.format("%s has passed their captainhood to %s.", player.name, player_to_pass_to.name)
	Common.notify_force(force, message)
	Server.to_discord_embed_raw(CoreData.comfy_emojis.spurdo .. '[' .. memory.name .. '] ' .. message)

	Public.make_captain(player_to_pass_to)
end

function Public.afk_player_tick(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()
	
	if Common.is_captain(player) and #Common.crew_get_nonafk_crew_members() > 0 then

		local force = memory.force
		if force and force.valid then
			local message = string.format(player.name .. ' was afk.')
			Common.notify_force(force, message)
			Server.to_discord_embed_raw(CoreData.comfy_emojis.loops .. '[' .. memory.name .. '] ' .. message)
		end

		if #Common.crew_get_nonafk_crew_members() == 1 then --don't need to bounce it around
			Public.make_captain(Common.crew_get_nonafk_crew_members()[1])
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
	
				local player_priority = global_memory.playerindex_to_captainhood_priority[player_index]
				if player_priority and player_priority > best_priority_so_far then
					best_priority_so_far = player_priority
					captain_index = player_index
					captain_name = player.name
				end
			end
		end
	end

	local force = memory.force
	if not (force and force.valid) then return end

	if not captain_index then
		captain_index = crew_members[1]
		captain_name = game.players[captain_index].name
		Common.notify_force(force,'Looking for a suitable captain...')
	end

	if captain_index then
		local player = game.players[captain_index]
		if player and Common.validate_player(player) then
			Public.make_captain(player)
			-- this sets memory.captain_acceptance_timer = nil so now we must reset that after this function
		end
	end

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
	else
		memory.captain_acceptance_timer = nil
	end
end


function Public.captain_requisition_coins(captain_index)
	local memory = Memory.get_crew_memory()
	local total = 0

	local crew_members = memory.crewplayerindices
	local captain = game.players[captain_index]
	if not (captain and crew_members and #crew_members > 1) then return end
	
	local captain_inv = captain.get_inventory(defines.inventory.character_main)
	if captain_inv and captain_inv.valid then
		for _, player_index in pairs(crew_members) do
			if player_index ~= captain_index then
				local player = game.players[player_index]
				if player and not (memory.officers_table and memory.officers_table[player.index]) then
					local inv = player.get_inventory(defines.inventory.character_main)
					if inv and inv.valid then
						local coin_amount = inv.get_item_count('coin')
						if coin_amount and coin_amount > 0 then
							inv.remove{name='coin', count=coin_amount}
							captain_inv.insert{name='coin', count=coin_amount}
							total = total + coin_amount
						end
					end

					local cursor_stack = player.cursor_stack
					if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == 'coin' then
						local cursor_stack_count = cursor_stack.count
						if cursor_stack_count > 0 then
							cursor_stack.count = 0
							captain_inv.insert{name='coin', count = cursor_stack_count}
							total = total + cursor_stack_count
						end
					end
				end
			end
		end
	
		if total > 0 then 
			Common.notify_force(memory.force, 'The captain requisitioned ' .. Utils.bignumber_abbrevform2(total) .. ' coins.')
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

        group.set_allows_action(defines.input_action.open_gui, false)
        group.set_allows_action(defines.input_action.fast_entity_transfer, false)
        group.set_allows_action(defines.input_action.fast_entity_split, false)
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

		group.set_allows_action(defines.input_action.grab_blueprint_record, false)
		if not CoreData.blueprint_library_allowed then
			group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
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

			plebs_group.set_allows_action(defines.input_action.grab_blueprint_record, false)
			if not CoreData.blueprint_library_allowed then
				plebs_group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
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
    if not Common.validate_player_and_character(player) then
        return
    end

    if string.sub(player.surface.name, 9, 17) == 'Crowsnest' or string.sub(player.surface.name, 9, 13) == 'Cabin' then
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