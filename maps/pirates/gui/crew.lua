
local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Roles = require 'maps.pirates.roles.roles'
local Classes = require 'maps.pirates.roles.classes'
local Crew = require 'maps.pirates.crew'
local Progression = require 'maps.pirates.progression'
local Structures = require 'maps.pirates.structures.structures'
local inspect = require 'utils.inspect'.inspect
local Boats = require 'maps.pirates.structures.boats.boats'
local GuiCommon = require 'maps.pirates.gui.common'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'
local Public = {}


local window_name = 'crew'


function Public.toggle_window(player)
	local memory = Memory.get_crew_memory()
	local flow, flow2, flow3, flow4, flow5, flow6

	--*** OVERALL FLOW ***--
	if player.gui.screen[window_name .. '_piratewindow'] then player.gui.screen[window_name .. '_piratewindow'].destroy() return end

	if not memory.id then return end
	
	flow = GuiCommon.new_window(player, window_name)
	flow.caption = 'Crew'

	--*** RUN AGE ***--
	
	flow2 = flow.add({
		name = 'crew_age',
		type = 'label',
	})
	flow2.style.left_margin = 5
	flow2.style.top_margin = 0
	flow2.style.bottom_margin = -3
	flow2.style.single_line = true
	flow2.style.maximal_width = 200
	flow2.style.font = 'default'

	--*** RUN DIFFICULTY ***--
	
	flow2 = flow.add({
		name = 'crew_difficulty',
		type = 'label',
	})
	flow2.style.left_margin = 5
	flow2.style.top_margin = -3
	flow2.style.bottom_margin = 0
	flow2.style.single_line = false
	flow2.style.maximal_width = 190
	flow2.style.font = 'default'


	--*** MEMBERSHIP BUTTONS ***--

	flow2 = flow.add({
		name = 'membership_buttons',
		type = 'flow',
		direction = 'horizontal',
	})

	flow3 = flow2.add({
		name = 'leave_crew',
		type = 'button',
		caption = 'Quit Crew',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Return to the lobby.'

	flow3 = flow2.add({
		name = 'leave_spectators',
		type = 'button',
		caption = 'Return to Lobby',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow3 = flow2.add({
		name = 'spectator_join_crew',
		type = 'button',
		caption = 'Join Crew',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow3 = flow2.add({
		name = 'crewmember_join_spectators',
		type = 'button',
		caption = 'Spectate',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'You won\t be able to rejoin the crew for a short while after you do this.'

	--*** MEMBERS AND SPECTATORS ***--

	flow2 = GuiCommon.flow_add_section(flow, 'members', 'Crew Members')

	flow3 = flow2.add({
		name = 'members_listbox',
		type = 'list-box',
	})
	flow3.style.margin = 2
	flow3.style.maximal_height = 350

	flow3 = flow2.add({
		name = 'class_renounce',
		type = 'button',
		caption = 'Give Up Class',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'The class will become available for other crewmembers to take.'

	flow3 = flow2.add({
		name = 'officer_resign',
		type = 'button',
		caption = 'Resign as Officer',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Give up the officer role.'

	flow2 = GuiCommon.flow_add_section(flow, 'spectators', 'Spectators')

	flow3 = flow2.add({
		name = 'spectators_listbox',
		type = 'list-box',
	})
	flow3.style.margin = 2
	flow3.style.maximal_height = 150

	--*** DIFFICULTY VOTE ***--

	flow2 = GuiCommon.flow_add_section(flow, 'difficulty_vote', 'Vote for Difficulty')

	for i, o in ipairs(CoreData.difficulty_options) do
		flow3 = flow2.add({
			name = 'difficulty_option_' .. i,
			type = 'button',
			caption = o.text,
		})
		flow3.style.minimal_width = 95
		flow3.style.font = 'default-bold'
		flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	end

	--*** SPARE CLASSES ***--

	flow2 = GuiCommon.flow_add_section(flow, 'spare_classes', 'Spare Classes')
	
	flow3 = flow2.add({
		name = 'list',
		type = 'label',
	})
	flow3.style.left_margin = 5
	flow3.style.top_margin = -3
	flow3.style.bottom_margin = -3
	flow3.style.single_line = false
	flow3.style.maximal_width = 160
	flow3.style.font = 'default-dropdown'

	flow3 = flow2.add({
		name = 'assign_flow',
		type = 'flow',
		direction = 'vertical',
	})
	flow3.style.top_margin = 3

	for _, c in ipairs(Classes.Class_List) do
		flow4 = flow3.add({
			name = 'assign_class_' .. c,
			type = 'button',
			caption = 'Give class: ' .. Classes.display_form[c],
		})
		flow4.style.minimal_width = 95
		flow4.style.font = 'default-bold'
		flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
		flow4.tooltip = 'Give this class to the selected player.'
	end

	for _, c in ipairs(Classes.Class_List) do
		flow4 = flow3.add({
			name = 'selfassign_class_' .. c,
			type = 'button',
			caption = 'Take class: ' .. Classes.display_form[c],
		})
		flow4.style.minimal_width = 95
		flow4.style.font = 'default-bold'
		flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
		flow4.tooltip = 'Take the spare class for yourself.'
	end

	--*** CAPTAIN's ACTIONS ***--

	flow2 = GuiCommon.flow_add_section(flow, 'captain', 'Captain\'s Actions')

	flow3 = flow2.add({
		name = 'capn_disband_crew',
		type = 'button',
		caption = 'Disband Crew',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'End the run. You will be prompted again after clicking.'

	flow3 = flow2.add({
		name = 'capn_disband_are_you_sure',
		type = 'button',
		caption = 'ARE YOU SURE?',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Click to disband the crew.'

	flow3 = flow2.add({
		name = 'capn_renounce',
		type = 'button',
		caption = 'Renounce Captainhood',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'You will no longer be captain, and the role will be passed around until a crewmember takes it.'

	flow3 = flow2.add({
		name = 'capn_pass',
		type = 'button',
		caption = 'Pass Captain To',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Make the selected crewmember into the Captain.'

	flow3 = flow2.add({
		name = 'capn_plank',
		type = 'button',
		caption = 'Plank (Make Spectator)',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'The player will be returned to the lobby and can\'t join your crew for a while.'

	flow3 = flow2.add({
		name = 'line',
		type = 'line',
	})
    flow3.style.width = 50
    flow3.style.left_margin = 20
    flow3.style.top_margin = 4
    flow3.style.bottom_margin = 4

	-- flow3 = flow2.add({
	-- 	name = 'capn_undock_normal',
	-- 	type = 'button',
	-- 	caption = 'Undock Boat',
	-- })
	-- flow3.style.minimal_width = 95
	-- flow3.style.font = 'default-bold'
	-- flow3.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow3 = flow2.add({
		name = 'make_officer',
		type = 'button',
		caption = 'Make Officer',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Make this player an Officer.'

	flow3 = flow2.add({
		name = 'unmake_officer',
		type = 'button',
		caption = 'Unamake Officer',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Remove this player as an Officer.'

	flow3 = flow2.add({
		name = 'capn_summon_crew',
		type = 'button',
		caption = 'Summon Crew to Ship',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Teleport crewmembers to the ship.'

	flow3 = flow2.add({
		name = 'capn_take_coins',
		type = 'button',
		caption = 'Requisition Coins',
	})
	flow3.style.minimal_width = 95
	flow3.style.font = 'default-bold'
	flow3.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow3.tooltip = 'Take all the coins from each non-officer.'


	flow2 = flow.add({
		name = 'undock_tip',
		type = 'label',
	})
	flow2.style.left_margin = 5
	flow2.style.top_margin = -8
	flow2.style.bottom_margin = 7
	flow2.style.single_line = false
	flow2.style.maximal_width = 190
	flow2.style.font = 'default'
	flow2.caption = 'To undock, use the top toolbar.'

	--

	GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
end





function Public.update(player)

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow = player.gui.screen[window_name .. '_piratewindow']

	local memory = Memory.get_crew_memory()
	local playercrew_status = GuiCommon.playercrew_status_table(player.index)
	local destination = Common.current_destination()


	--*** WHAT TO SHOW ***--

	flow.difficulty_vote.visible = memory.overworldx and memory.overworldx == 0

	flow.members.body.class_renounce.visible = memory.classes_table and memory.classes_table[player.index]

	flow.members.body.officer_resign.visible = memory.officers_table and memory.officers_table[player.index]

	flow.spare_classes.visible = memory.spare_classes and #memory.spare_classes > 0

	local other_player_selected = flow.members.body.members_listbox.selected_index ~= 0 and tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2]) ~= player.index

	local any_class_button = false
	for _, c in pairs(Classes.Class_List) do
		if memory.spare_classes and Utils.contains(memory.spare_classes, c) and (not (player.controller_type == defines.controllers.spectator)) then
			if (memory.playerindex_captain and player.index == memory.playerindex_captain) and memory.crewplayerindices and #memory.crewplayerindices > 1 then
				if other_player_selected and (not (memory.classes_table[tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])])) then
					flow.spare_classes.body.assign_flow['selfassign_class_' .. c].visible = false
					flow.spare_classes.body.assign_flow['assign_class_' .. c].visible = true
					any_class_button = true
				else
					flow.spare_classes.body.assign_flow['assign_class_' .. c].visible = false
					if (not memory.classes_table[player.index]) then
						flow.spare_classes.body.assign_flow['selfassign_class_' .. c].visible = true
						any_class_button = true
					else
						flow.spare_classes.body.assign_flow['selfassign_class_' .. c].visible = false
					end
				end
			else
				flow.spare_classes.body.assign_flow['assign_class_' .. c].visible = false
				if (not memory.classes_table[player.index]) then
					flow.spare_classes.body.assign_flow['selfassign_class_' .. c].visible = true
					any_class_button = true
				else
					flow.spare_classes.body.assign_flow['selfassign_class_' .. c].visible = false
				end
			end
		else
			flow.spare_classes.body.assign_flow['assign_class_' .. c].visible = false
			flow.spare_classes.body.assign_flow['selfassign_class_' .. c].visible = false
		end
	end
	flow.spare_classes.body.assign_flow.visible = any_class_button

	flow.captain.visible = (memory.playerindex_captain and player.index == memory.playerindex_captain)
	flow.undock_tip.visible = (memory.playerindex_captain and player.index == memory.playerindex_captain)

	flow.captain.body.capn_pass.visible = other_player_selected
	flow.captain.body.capn_plank.visible = flow.captain.body.capn_pass.visible

	flow.captain.body.make_officer.visible = other_player_selected and (not (memory.officers_table and memory.officers_table[tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])]))
	flow.captain.body.unmake_officer.visible = other_player_selected and ((memory.officers_table and memory.officers_table[tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])]))

	-- flow.captain.body.capn_undock_normal.visible = memory.boat and memory.boat.state and ((memory.boat.state == Boats.enum_state.LANDED) or (memory.boat.state == Boats.enum_state.APPROACHING) or (memory.boat.state == Boats.enum_state.DOCKED))

	flow.captain.body.capn_summon_crew.visible = false
	flow.captain.body.capn_take_coins.visible = true
	-- flow.captain.body.capn_summon_crew.visible = memory.boat and memory.boat.state and (memory.boat.state == Boats.enum_state.RETREATING or memory.boat.state == Boats.enum_state.LEAVING_DOCK)

	flow.captain.body.capn_disband_are_you_sure.visible = memory.disband_are_you_sure_ticks and memory.disband_are_you_sure_ticks[player.index] and memory.disband_are_you_sure_ticks[player.index] > game.tick - 60*2
	flow.captain.body.capn_disband_crew.visible = not flow.captain.body.capn_disband_are_you_sure.visible

	flow.members.visible = true
	flow.spectators.visible = (#memory.spectatorplayerindices > 0)
	-- flow.crew_age.visible = true
	-- -- flow.crew_age.visible = memory.mode and memory.mode == 'speedrun'
	-- flow.crew_difficulty.visible = true
	
	local count = 0
	if playercrew_status.spectating then
		for _, v in pairs(memory.crewplayerindices) do
			if Common.validate_player(game.players[v]) then count = count + 1 end
		end
	end
	flow.membership_buttons.spectator_join_crew.visible = playercrew_status.spectating and (not (count >= memory.capacity))

	flow.membership_buttons.leave_crew.visible = playercrew_status.adventuring
	flow.membership_buttons.crewmember_join_spectators.visible = playercrew_status.adventuring
	flow.membership_buttons.leave_spectators.visible = playercrew_status.spectating

	flow.membership_buttons.spectator_join_crew.visible = flow.membership_buttons.spectator_join_crew.visible and (not (memory.tempbanned_from_joining_data[player.index] and game.tick < memory.tempbanned_from_joining_data[player.index] + Common.ban_from_rejoining_crew_ticks))



	--== UPDATE CONTENT ==--
	
	if memory.id then
		flow.caption = memory.name

		flow.crew_age.caption = 'Age: ' .. Utils.time_mediumform((memory.age or 0)/60)
		flow.crew_difficulty.caption = 'Difficulty: ' .. CoreData.difficulty_options[memory.difficulty_option].text

		if flow.spare_classes.visible then
			local str = ''

			for i, c in ipairs(memory.spare_classes) do
				if i>1 then str = str .. ', ' end
				str = str .. Classes.display_form[c]
			end
			str = str .. '.'

			flow.spare_classes.body.list.caption = str
		end
	end


	if flow.members.visible then
		local wrappedcrew = {}
		for _, index in pairs(memory.crewplayerindices) do
			local player2 = game.players[index]
			local tag_text = Roles.tag_text(player2)

			wrappedcrew[#wrappedcrew + 1] = {'pirates.crewmember_displayform', index, player2.color.r, player2.color.g, player2.color.b, player2.name, tag_text}
		end
		GuiCommon.update_listbox(flow.members.body.members_listbox, wrappedcrew)

		flow.members.header.caption = 'Crew Members (' .. (#memory.crewplayerindices or 0) .. ')'
	end

	if flow.spectators.visible then
		local wrappedspectators = {}
		for _, index in pairs(memory.spectatorplayerindices) do
			local player2 = game.players[index]

			wrappedspectators[#wrappedspectators + 1] = {'pirates.crewmember_displayform', index, player2.color.r, player2.color.g, player2.color.b, player2.name, ''}
		end
		GuiCommon.update_listbox(flow.spectators.body.spectators_listbox, wrappedspectators)
	end

	-- if flow.captain.body.capn_undock_normal.visible then
	-- 	flow.captain.body.capn_undock_normal.enabled = ((memory.boat.state == Boats.enum_state.LANDED) and Common.query_sufficient_resources_to_leave()) or (memory.boat.state == Boats.enum_state.DOCKED)
	-- end
end


function Public.click(event)

	local player = game.players[event.element.player_index]

	local eventname = event.element.name

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow = player.gui.screen[window_name .. '_piratewindow']

	local memory = Memory.get_crew_memory()


	if eventname == 'crewmember_join_spectators' then
		Crew.join_spectators(player, memory.id)
		return
	end

	if eventname == 'leave_spectators' then
		Crew.leave_spectators(player)
		return
	end

	if eventname == 'spectator_join_crew' then
		Crew.join_crew(player, memory.id)
		return
	end

	if eventname == 'leave_crew' then
		Crew.leave_crew(player)
		return
	end


	-- if eventname == 'promote_officer' then
	-- 	Roles.promote_to_officer(player)
	-- 	return
	-- end

	-- if eventname == 'demote_officer' then
	-- 	Roles.demote_to_officer(player)
	-- 	return
	-- end


	if string.sub(eventname, 1, 13) and string.sub(eventname, 1, 13) == 'assign_class_' then
		local other_id = tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])
		Roles.assign_class(other_id, tonumber(string.sub(eventname, 14, -1)))
		return
	end

	if string.sub(eventname, 1, 17) and string.sub(eventname, 1, 17) == 'selfassign_class_' then
		Roles.assign_class(player.index, tonumber(string.sub(eventname, 18, -1)), true)
		return
	end

	if string.sub(eventname, 1, 18) and string.sub(eventname, 1, 18) == 'difficulty_option_' then
		Crew.difficulty_vote(player.index, tonumber(string.sub(eventname, 19, -1)))
		return
	end


	-- if eventname == 'capn_undock_normal' then
	-- 	--double check:
	-- 	if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
	-- 		if memory.boat.state == Boats.enum_state.DOCKED then
	-- 			Progression.undock_from_dock()
	-- 		else
	-- 			Progression.try_retreat_from_island()
	-- 		end
	-- 	end
	-- 	return
	-- end

	if eventname == 'capn_summon_crew' then
		--double check:
		if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
			Crew.summon_crew()
		end
		return
	end

	if eventname == 'capn_take_coins' then
		--double check:
		if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
			Roles.captain_requisition_coins(memory.playerindex_captain)
		end
		return
	end

	if eventname == 'class_renounce' then
		Roles.try_renounce_class(player)
		return
	end

	if eventname == 'capn_renounce' then
		Roles.renounce_captainhood(player)
		return
	end

	if eventname == 'officer_resign' then
		Roles.resign_as_officer(player)
		return
	end

	if eventname == 'capn_disband_crew' then
		--double check:
		if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
			if not memory.disband_are_you_sure_ticks then memory.disband_are_you_sure_ticks = {} end
			memory.disband_are_you_sure_ticks[player.index] = game.tick
		end
		return
	end

	if eventname == 'capn_disband_are_you_sure' then
		--double check:
		if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
			local force = game.forces[memory.force_name]
			if force and force.valid then
				local message = player.name .. ' disbanded ' .. memory.name .. ', after ' .. Utils.time_longform((memory.real_age or 0)/60) .. '.'
				Common.notify_game(message)
				Server.to_discord_embed_raw(CoreData.comfy_emojis.trashbin .. '[' .. memory.name .. '] ' .. message)
			end
			Crew.disband_crew(true)
		end
		return
	end

	if eventname == 'capn_pass' then
		local other_id = tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])
		Roles.pass_captainhood(player, game.players[other_id])
		return
	end

	if eventname == 'make_officer' then
		local other_id = tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])
		Roles.make_officer(player, game.players[other_id])
		return
	end

	if eventname == 'unmake_officer' then
		local other_id = tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])
		Roles.unmake_officer(player, game.players[other_id])
		return
	end

	if eventname == 'capn_plank' then
		local other_id = tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])

		local message = "%s planked %s!"
		Server.to_discord_embed_raw(CoreData.comfy_emojis.monkas .. message)

		Common.notify_force(player.force, string.format(message, player.name, game.players[other_id].name))

		Crew.join_spectators(game.players[other_id], memory.id)
		memory.tempbanned_from_joining_data[other_id] = game.tick + 60 * 120
		return
	end

end

return Public