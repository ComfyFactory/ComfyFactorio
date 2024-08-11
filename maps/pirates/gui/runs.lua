-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio.

local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
-- local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Roles = require 'maps.pirates.roles.roles'
local Crew = require 'maps.pirates.crew'
local Progression = require 'maps.pirates.progression'
-- local Structures = require 'maps.pirates.structures.structures'
local _inspect = require 'utils.inspect'.inspect
local Boats = require 'maps.pirates.structures.boats.boats'
local GuiCommon = require 'maps.pirates.gui.common'
-- local Server = require 'utils.server'
local Public = {}


local window_name = 'runs'


local function flow_add_proposal_slider(flow, name, displayname, indices_count, starting_index, tooltip)
	local flow2, flow3, flow4


	flow2 = flow.add({
		name = name,
		type = 'flow',
		direction = 'vertical',
	})
    flow2.style.horizontal_align = 'left'
    flow2.style.width = 130

	flow3 = flow2.add({
		type = 'label',
		caption = displayname,
	})
	flow3.style.font = 'heading-3'
	flow3.style.height = 20
    flow3.style.margin = 0
    flow3.style.padding = 0
    flow3.style.top_padding = -4
    flow3.style.bottom_margin = 0
	flow3.style.font_color = GuiCommon.subsection_header_font_color
	flow3.tooltip = tooltip

	flow3 = flow2.add({
		name = name,
		type = 'flow',
		direction = 'vertical',
	})
    flow3.style.horizontal_align = 'center'
    flow3.style.width = 130

	flow4 = flow3.add({
		name = 'slider',
		type = 'slider',
		value_step = 1,
		minimum_value = 1,
		maximum_value = indices_count,
		value = starting_index,
		discrete_values = true,
		discrete_slider = true,
	})
	flow4.style.width = 100
    flow4.style.margin = 0
	flow4.tooltip = tooltip

	flow4 = flow3.add({
		name = 'readoff_text',
		type = 'label',
		caption = '',
	})
	flow4.style.font = 'default-listbox'
	flow4.style.height = 20
    flow4.style.margin = 0
    flow4.style.padding = 0
    flow4.style.top_padding = 0
    flow4.style.bottom_margin = 16
	flow4.tooltip = tooltip

	flow2 = flow.add({
		name = name .. '_readoff_icon',
		type = 'sprite-button',
		enabled = false,
	})
	flow2.style.width = 48
	flow2.style.height = 48
	flow2.tooltip = tooltip

	return flow2
end


-- commented out for luacheck:
-- local function flow_add_proposal_switch(flow, name, displayname, starting_position, tooltip)
-- 	local flow2, flow3, flow4

-- 	flow2 = flow.add({
-- 		name = name,
-- 		type = 'flow',
-- 		direction = 'vertical',
-- 	})
--     flow2.style.horizontal_align = 'left'
--     flow2.style.width = 130

-- 	flow3 = flow2.add({
-- 		type = 'label',
-- 		caption = displayname,
-- 	})
-- 	flow3.style.font = 'heading-3'
-- 	flow3.style.height = 20
--     flow3.style.margin = 0
--     flow3.style.padding = 0
--     flow3.style.top_padding = -4
--     flow3.style.bottom_margin = 0
-- 	flow3.style.font_color = GuiCommon.subsection_header_font_color
-- 	flow3.tooltip = tooltip

-- 	flow3 = flow2.add({
-- 		name = name,
-- 		type = 'flow',
-- 		direction = 'vertical',
-- 	})
--     flow3.style.horizontal_align = 'center'
--     flow3.style.width = 130

-- 	flow4 = flow3.add({
-- 		name = 'switch',
-- 		type = 'switch',
-- 		switch_state = starting_position,
-- 	})
-- 	-- flow4.style.width = 80
-- 	-- flow4.style.height = 40
--     flow4.style.margin = 0
-- 	flow4.tooltip = tooltip

-- 	flow4 = flow3.add({
-- 		name = 'readoff_text',
-- 		type = 'label',
-- 		caption = '',
-- 	})
-- 	flow4.style.font = 'default-listbox'
-- 	flow4.style.height = 20
--     flow4.style.margin = 0
--     flow4.style.padding = 0
--     flow4.style.top_padding = 0
--     flow4.style.bottom_margin = 16
-- 	flow4.tooltip = tooltip

-- 	flow2 = flow.add({
-- 		name = name .. '_readoff_icon',
-- 		type = 'sprite-button',
-- 		enabled = false,
-- 	})
-- 	flow2.style.width = 48
-- 	flow2.style.height = 48
-- 	flow2.tooltip = tooltip

-- 	return flow2
-- end


function Public.toggle_window(player)
	local window
	local flow, flow2, flow3, flow4, flow5

	--*** OVERALL FLOW ***--
	if player.gui.screen[window_name .. '_piratewindow'] then player.gui.screen[window_name .. '_piratewindow'].destroy() return end

	window = GuiCommon.new_window(player, window_name)
	window.caption = {'pirates.gui_runs_play'}

	flow = window.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
		vertical_scroll_policy = 'auto-and-reserve-space'
    }
    flow.style.maximal_height = 500
	flow.style.bottom_margin = 10

	--*** ONGOING RUNS ***--

	flow2 = GuiCommon.flow_add_section(flow, 'ongoing_runs', {'pirates.gui_runs_ongoing_runs'})

	flow3 = flow2.add({
		name = 'helpful_tip',
		type = 'label',
		caption = {'pirates.gui_runs_ongoing_runs_helpful_tip'},
	})
	flow3.style.font_color = {r=0.90, g=0.90, b=0.90}
	flow3.style.single_line = false
	flow3.style.maximal_width = 160

	flow3 = flow2.add({
		name = 'ongoing_runs_listbox',
		type = 'list-box',
	})
	flow3.style.margin = 2
	flow3.style.right_margin = 5
	flow3.style.horizontally_stretchable = true

	flow3 = flow2.add({
		name = 'join_protected_crew_info',
		type = 'label',
		caption = {'pirates.gui_join_protected_run_info', 0, 0, 0},
		visible = false,
	})
	flow3.style.single_line = false

	flow3 = flow2.add({
		name = 'join_private_crew_info',
		type = 'label',
		caption = {'pirates.gui_join_private_run_info', 0, 0, 0},
		visible = false,
	})
	flow3.style.single_line = false

	flow3 = flow2.add({
		name = 'password_namefield',
		type = 'textfield',
		text = '',
		visible = false,
	})
	flow3.style.width = 150
	flow3.style.height = 24
	flow3.style.top_margin = -3
	flow3.style.bottom_margin = 3

	flow3 = flow2.add({
		name = 'flow_buttons',
		type = 'flow',
		direction = 'horizontal',
	})

	flow4 = flow3.add({
		name = 'join_spectators',
		type = 'button',
		caption = {'pirates.gui_runs_ongoing_runs_spectate'},
	})
	flow4.style.minimal_width = 95
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow4 = flow3.add({
		name = 'join_crew',
		type = 'button',
		caption = {'pirates.gui_runs_ongoing_runs_join_crew'},
	})
	flow4.style.minimal_width = 95
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow4 = flow3.add({
		name = 'leave_spectators',
		type = 'button',
		caption = {'pirates.gui_runs_ongoing_runs_return_to_lobby'},
	})
	flow4.style.minimal_width = 95
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow3 = flow2.add({
		name = 'wait_to_join',
		type = 'label',
	})
	flow3.style.left_margin = 5

	flow3 = flow2.add({
		name = 'leaving_prompt',
		type = 'label',
		caption = {'pirates.gui_runs_ongoing_runs_hop_on_board'},
	})
	flow3.style.left_margin = 5


	-- PROPOSALS --

	flow2 = GuiCommon.flow_add_section(flow, 'proposals', {'pirates.gui_runs_proposals'})

	flow3 = flow2.add({
		name = 'proposals_listbox',
		type = 'list-box',
	})
	flow3.style.margin = 2
	flow3.style.right_margin = 5
	flow3.style.horizontally_stretchable = true

	flow3 = flow2.add({
		name = 'flow_buttons',
		type = 'flow',
		direction = 'horizontal',
	})

	flow4 = flow3.add({
		name = 'endorse_proposal',
		type = 'button',
		caption = {'pirates.gui_runs_proposals_endorse_proposal'},
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow4.style.bottom_margin = 9

	flow4 = flow3.add({
		name = 'retract_endorsement',
		type = 'button',
		caption = {'pirates.gui_runs_proposals_retract_endorsement'},
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow4.style.bottom_margin = 9

	flow4 = flow3.add({
		name = 'abandon_proposal',
		type = 'button',
		caption = {'pirates.gui_runs_proposals_abandon_proposal'},
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow4.style.bottom_margin = 9


	-- PROPOSAL MAKER --

	flow3 = GuiCommon.flow_add_subpanel(flow2, 'proposal_maker')

	flow4 = flow3.add({
		name = 'body',
		type = 'flow',
		direction = 'vertical',
	})
    flow4.style.horizontal_align = 'center'
    flow4.style.vertical_align = 'center'

	flow5 = flow4.add({
		type = 'label',
		caption = {'pirates.gui_runs_proposal_maker_run_name'},
	})
	flow5.style.font = 'heading-3'

	flow5 = flow4.add({
		name = 'namefield',
		type = 'textfield',
		caption = {'pirates.gui_runs_proposal_maker_run_name_2'},
		text = '',
	})
	flow5.style.width = 150
	flow5.style.height = 24
	flow5.style.top_margin = -3
	flow5.style.bottom_margin = 3

	-- PROTECTED RUN ELEMENTS --

	flow4.add({
		name = 'protected_checkbox',
		type = 'checkbox',
		caption = {'pirates.gui_runs_proposal_maker_protected'},
		state = false,
		tooltip = {'pirates.gui_runs_proposal_maker_protected_tooltip', CoreData.protected_run_lock_amount_hr}
	})

	-- PRIVATE RUN ELEMENTS --

	flow4.add({
		name = 'private_checkbox',
		type = 'checkbox',
		caption = {'pirates.gui_runs_proposal_maker_private'},
		state = false,
		tooltip = {'pirates.gui_runs_proposal_maker_private_tooltip', CoreData.private_run_lock_amount_hr}
	})

	flow5 = flow4.add({
		name = 'password_label',
		type = 'label',
		caption = {'pirates.gui_runs_proposal_maker_password'},
	})
	flow5.style.font = 'heading-3'

	flow5 = flow4.add({
		name = 'password_namefield',
		type = 'textfield',
		text = '',
	})
	flow5.style.width = 150
	flow5.style.height = 24
	flow5.style.top_margin = -3
	flow5.style.bottom_margin = 3

	flow5 = flow4.add({
		name = 'confirm_password_label',
		type = 'label',
		caption = {'pirates.gui_runs_proposal_maker_confirm_password'},
	})
	flow5.style.font = 'heading-3'

	flow5 = flow4.add({
		name = 'confirm_password_namefield',
		type = 'textfield',
		text = '',
	})
	flow5.style.width = 150
	flow5.style.height = 24
	flow5.style.top_margin = -3
	flow5.style.bottom_margin = 3

	-- CREW SIZE LIMIT SLIDER --

	flow5 = flow4.add({
		name = 'options',
		type = 'table',
		column_count = 2,
	})
	flow5.style.width = 200
	flow5.style.margin = 0

	flow_add_proposal_slider(flow5, 'capacity', {'pirates.gui_runs_proposal_maker_capacity'}, #CoreData.capacity_options, 5, {'pirates.capacity_tooltip'})
	-- flow_add_proposal_slider(flow5, 'difficulty', 'Difficulty', #CoreData.difficulty_options, 2, {'pirates.difficulty_tooltip'})
	-- flow_add_proposal_switch(flow5, 'mode', 'Mode', 'left', {'pirates.mode_tooltip'})

	-- flow5 = flow4.add({
	-- 	name = 'proposal_cant_do_infinity_mode',
	-- 	type = 'label',
	-- 	caption = 'Infinity mode isn\'t available at the moment.',
	-- })
	-- flow5.style.single_line = false
	-- flow5.style.maximal_width = 200

	flow5 = flow4.add({
		name = 'proposal_disabled_low_crew_caps',
		type = 'label',
		caption = {'pirates.gui_runs_proposal_maker_capacity_disabled'},
	})
	flow5.style.single_line = false
	flow5.style.maximal_width = 200

	flow5 = flow4.add({
		name = 'propose_crew',
		type = 'button',
		caption = {'pirates.gui_runs_proposal_maker_propose'},
	})
	flow5.style.minimal_width = 75
	flow5.style.font = 'default-bold'
	flow5.style.font_color = {r=0.10, g=0.10, b=0.10}


	-- LAUNCH YOUR PROPOSAL --

	flow3 = flow2.add({
		name = 'flow_proposal_launch',
		type = 'flow',
		direction = 'vertical',
	})

	flow4 = flow3.add({
		name = 'proposal_insufficient_endorsers',
		type = 'label',
		caption = {'pirates.gui_runs_launch_error_1'},
	})
	flow4.style.single_line = false

	flow4 = flow3.add({
		name = 'proposal_crew_count_capped',
		type = 'label',
		caption = {'pirates.gui_runs_launch_error_2'},
	})
	flow4.style.single_line = false

	flow4 = flow3.add({
		name = 'proposal_insufficient_player_capacity',
		type = 'label',
		caption = {'pirates.gui_runs_launch_error_3'},
	})
	flow4.style.single_line = false

	flow4 = flow3.add({
		name = 'proposal_insufficient_sloops',
		type = 'label',
		caption = {'pirates.gui_runs_launch_error_4'},
	})
	flow4.style.single_line = false

	flow4 = flow3.add({
		name = 'launch_crew',
		type = 'button',
		caption = {'pirates.gui_runs_launch'},
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}


	GuiCommon.flow_add_close_button(window, window_name .. '_piratebutton')
end




-- function Public.regular_update(player)

-- end


function Public.full_update(player)
	if Public.regular_update then Public.regular_update(player) end
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if not player.gui.screen['runs_piratewindow'] then return end
	local flow = player.gui.screen['runs_piratewindow'].scroll_pane
	local playercrew_status = GuiCommon.crew_overall_state_bools(player.index)
	if not playercrew_status then return end


	--*** WHAT TO SHOW ***--

	flow.ongoing_runs.visible = (#global_memory.crew_active_ids > 0)
	if flow.ongoing_runs.visible then
		local bool1 = (not playercrew_status.leaving) and (not playercrew_status.adventuring) and (not playercrew_status.spectating) and (flow.ongoing_runs.body.ongoing_runs_listbox.selected_index ~= 0)

		local selected_joinable_bool = false
		local crewid
		if bool1 then
			crewid = tonumber((flow.ongoing_runs.body.ongoing_runs_listbox.get_item(flow.ongoing_runs.body.ongoing_runs_listbox.selected_index))[2])
			selected_joinable_bool = bool1 and crewid and (global_memory.crew_memories[crewid].crewstatus == Crew.enum.ADVENTURING)
		end

		flow.ongoing_runs.body.helpful_tip.visible = not (playercrew_status.leaving or playercrew_status.adventuring or playercrew_status.spectating)

		flow.ongoing_runs.body.flow_buttons.visible = selected_joinable_bool or playercrew_status.spectating
		flow.ongoing_runs.body.flow_buttons.join_spectators.visible = selected_joinable_bool
		flow.ongoing_runs.body.flow_buttons.leave_spectators.visible = playercrew_status.spectating
		flow.ongoing_runs.body.flow_buttons.join_crew.visible = selected_joinable_bool and (not (crewid and global_memory.crew_memories[crewid] and (global_memory.crew_memories[crewid].crewstatus == Crew.enum.LEAVING_INITIAL_DOCK or #global_memory.crew_memories[crewid].crewplayerindices >= global_memory.crew_memories[crewid].capacity or (global_memory.crew_memories[crewid].tempbanned_from_joining_data and global_memory.crew_memories[crewid].tempbanned_from_joining_data[player.index] and game.tick < global_memory.crew_memories[crewid].tempbanned_from_joining_data[player.index] + Common.ban_from_rejoining_crew_ticks))))

		flow.ongoing_runs.body.wait_to_join.visible = selected_joinable_bool and crewid and global_memory.crew_memories[crewid] and (global_memory.crew_memories[crewid].tempbanned_from_joining_data and global_memory.crew_memories[crewid].tempbanned_from_joining_data[player.index] and game.tick < global_memory.crew_memories[crewid].tempbanned_from_joining_data[player.index] + Common.ban_from_rejoining_crew_ticks) and (not (global_memory.crew_memories[crewid].crewstatus == Crew.enum.LEAVING_INITIAL_DOCK or #global_memory.crew_memories[crewid].crewplayerindices >= global_memory.crew_memories[crewid].capacity))
		if flow.ongoing_runs.body.wait_to_join.visible then
			flow.ongoing_runs.body.wait_to_join.caption = {'pirates.gui_runs_wait_to_join', Math.ceil(((global_memory.crew_memories[crewid].tempbanned_from_joining_data[player.index] - (game.tick - Common.ban_from_rejoining_crew_ticks)))/60)}
		end

		if not selected_joinable_bool then flow.ongoing_runs.body.ongoing_runs_listbox.selected_index = 0 end

		flow.ongoing_runs.body.leaving_prompt.visible = playercrew_status.leaving

		local show_protected_info = crewid and global_memory.crew_memories[crewid].run_is_protected
		flow.ongoing_runs.body.join_protected_crew_info.visible = show_protected_info

		local show_private_info = crewid and global_memory.crew_memories[crewid].run_is_private
		flow.ongoing_runs.body.join_private_crew_info.visible = show_private_info
		flow.ongoing_runs.body.password_namefield.visible = show_private_info
	end

	flow.proposals.visible = (memory.crewstatus == nil and not playercrew_status.leaving)
	if flow.proposals.visible then
		if playercrew_status.proposing then
			flow.proposals.body.proposals_listbox.selected_index = 0
			flow.proposals.body.proposals_listbox.selected_index = 0
		end

		flow.proposals.body.proposals_listbox.visible = (not playercrew_status.leaving) and (#global_memory.crewproposals > 0)

		flow.proposals.body.flow_buttons.endorse_proposal.visible = (not playercrew_status.leaving) and (not playercrew_status.endorsing) and (#global_memory.crewproposals > 0) and flow.proposals.body.proposals_listbox.selected_index ~= 0

		flow.proposals.body.flow_buttons.abandon_proposal.visible = (not playercrew_status.leaving) and playercrew_status.endorsing and playercrew_status.endorsing and playercrew_status.proposing and (#global_memory.crewproposals > 0)

		flow.proposals.body.flow_buttons.retract_endorsement.visible = (not playercrew_status.leaving) and playercrew_status.endorsing and (not playercrew_status.proposing) and (#global_memory.crewproposals > 0)

		flow.proposals.body.proposal_maker.visible = (not playercrew_status.leaving) and (not playercrew_status.endorsing)

		flow.proposals.body.flow_proposal_launch.proposal_insufficient_sloops.visible = playercrew_status.sloops_full

		flow.proposals.body.flow_proposal_launch.proposal_insufficient_player_capacity.visible = playercrew_status.needs_more_capacity

		flow.proposals.body.flow_proposal_launch.proposal_crew_count_capped.visible = playercrew_status.crew_count_capped

		flow.proposals.body.flow_proposal_launch.proposal_insufficient_endorsers.visible = playercrew_status.needs_more_endorsers

		-- flow.proposals.body.proposal_maker.body.proposal_cant_do_infinity_mode.visible = (flow.proposals.body.proposal_maker.body.options.mode.mode.switch.switch_state == 'right')

		-- flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible = false
		flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible = (flow.proposals.body.proposal_maker.body.options.capacity.capacity.slider.slider_value < global_memory.minimumCapacitySliderValue)

		flow.proposals.body.proposal_maker.body.propose_crew.visible = (flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible == false)
		-- flow.proposals.body.proposal_maker.body.propose_crew.visible = (flow.proposals.body.proposal_maker.body.proposal_cant_do_infinity_mode.visible == false) and (flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible == false)

		flow.proposals.body.flow_proposal_launch.launch_crew.visible = playercrew_status.proposal_can_launch

		local checkbox_state = flow.proposals.body.proposal_maker.body.private_checkbox.state
		flow.proposals.body.proposal_maker.body.password_label.visible = checkbox_state
		flow.proposals.body.proposal_maker.body.password_namefield.visible = checkbox_state
		flow.proposals.body.proposal_maker.body.confirm_password_label.visible = checkbox_state
		flow.proposals.body.proposal_maker.body.confirm_password_namefield.visible = checkbox_state
	end



	--*** UPDATE CONTENT ***--

	if flow.ongoing_runs.visible then
		local wrappedmemories = {}
		for _, mem in pairs(global_memory.crew_memories) do
			local count = 0
			if mem.crewstatus and mem.crewstatus == Crew.enum.LEAVING_INITIAL_DOCK then
				count = Boats.players_on_boat_count(mem.boat)
			elseif mem.crewplayerindices then
				count = #mem.crewplayerindices
			end
			wrappedmemories[#wrappedmemories + 1] = {'pirates.run_displayform', mem.id, {'', mem.name .. ', ', CoreData.difficulty_options[mem.difficulty_option].text, ', [item=light-armor]' ..  count .. CoreData.capacity_options[mem.capacity_option].text2 .. ',  [item=rail] ' .. (mem.overworldx or 0)}}
			-- wrappedmemories[#wrappedmemories + 1] = {'pirates.run_displayform', mem.id, mem.name, Utils.spritepath_to_richtext(CoreData.difficulty_options[mem.difficulty_option].icon), count, CoreData.capacity_options[mem.capacity_option].text2, '      [item=rail] ', mem.overworldx or 0}
		end
		GuiCommon.update_listbox(flow.ongoing_runs.body.ongoing_runs_listbox, wrappedmemories)

		local crewid = nil
		local bool1 = (not playercrew_status.leaving) and (not playercrew_status.adventuring) and (not playercrew_status.spectating) and (flow.ongoing_runs.body.ongoing_runs_listbox.selected_index ~= 0)
		if bool1 then
			crewid = tonumber((flow.ongoing_runs.body.ongoing_runs_listbox.get_item(flow.ongoing_runs.body.ongoing_runs_listbox.selected_index))[2])
		end

		-- Update timer when captain protection expires
		if crewid and flow.ongoing_runs.body.join_protected_crew_info.visible then
			local lock_timer = global_memory.crew_memories[crewid].protected_run_lock_timer
			local sec = Math.floor((lock_timer / (60)) % 60)
			local min = Math.floor((lock_timer / (60 * 60)) % 60)
			local hrs = Math.floor((lock_timer / (60 * 60 * 60)) % 60)
			flow.ongoing_runs.body.join_protected_crew_info.caption = {'pirates.gui_join_protected_run_info', hrs, min, sec}
		end

		-- Update timer when run will become public
		if crewid and flow.ongoing_runs.body.join_private_crew_info.visible then
			local lock_timer = global_memory.crew_memories[crewid].private_run_lock_timer
			local sec = Math.floor((lock_timer / (60)) % 60)
			local min = Math.floor((lock_timer / (60 * 60)) % 60)
			local hrs = Math.floor((lock_timer / (60 * 60 * 60)) % 60)
			flow.ongoing_runs.body.join_private_crew_info.caption = {'pirates.gui_join_private_run_info', hrs, min, sec}
		end
	end

	if flow.proposals.visible then
		local wrappedproposals = {}
		for _, proposal in pairs(global_memory.crewproposals) do
			wrappedproposals[#wrappedproposals + 1] = {'pirates.proposal_displayform', proposal.name, Utils.spritepath_to_richtext(CoreData.capacity_options[proposal.capacity_option].icon)}
			-- wrappedproposals[#wrappedproposals + 1] = {'pirates.proposal_displayform', proposal.name, Utils.spritepath_to_richtext(CoreData.difficulty_options[proposal.difficulty_option].icon), Utils.spritepath_to_richtext(CoreData.capacity_options[proposal.capacity_option].icon)}
		end
		GuiCommon.update_listbox(flow.proposals.body.proposals_listbox, wrappedproposals)
	end

	-- update proposal maker
	if flow.proposals.body.proposal_maker.visible then
		local capacity_slider_value = flow.proposals.body.proposal_maker.body.options.capacity.capacity.slider.slider_value
		for i, opt in pairs(CoreData.capacity_options) do
			if capacity_slider_value == i then
				flow.proposals.body.proposal_maker.body.options.capacity.capacity.readoff_text.caption = opt.text
				flow.proposals.body.proposal_maker.body.options.capacity_readoff_icon.sprite = opt.icon
			end
		end
		if flow.proposals.body.proposal_maker.body.options.capacity.capacity.readoff_text.caption == '∞' then flow.proposals.body.proposal_maker.body.options.capacity.capacity.readoff_text.caption = {'pirates.gui_runs_proposal_maker_no_limit'} end

		-- local difficulty_slider_value = flow.proposals.body.proposal_maker.body.options.difficulty.difficulty.slider.slider_value
		-- for i, opt in pairs(CoreData.difficulty_options) do
		-- 	if difficulty_slider_value == i then
		-- 		flow.proposals.body.proposal_maker.body.options.difficulty.difficulty.readoff_text.caption = opt.text
		-- 		flow.proposals.body.proposal_maker.body.options.difficulty_readoff_icon.sprite = opt.icon
		-- 	end
		-- end

		-- local mode_switch_state = flow.proposals.body.proposal_maker.body.options.mode.mode.switch.switch_state
		-- for i, opt in pairs(CoreData.mode_options) do
		-- 	if mode_switch_state == i then
		-- 		flow.proposals.body.proposal_maker.body.options.mode.mode.readoff_text.caption = opt.text
		-- 		flow.proposals.body.proposal_maker.body.options.mode_readoff_icon.sprite = opt.icon
		-- 	end
		-- end
	end
end


function Public.click(event)
	if not event.element then return end
	if not event.element.valid then return end

	local player = game.players[event.element.player_index]

	local eventname = event.element.name

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow = player.gui.screen[window_name .. '_piratewindow'].scroll_pane

	local global_memory = Memory.get_global_memory()
	-- local memory = Memory.get_crew_memory()


	if eventname == 'join_spectators' then
		local listbox = flow.ongoing_runs.body.ongoing_runs_listbox

		-- It was observed that "listbox.get_item(listbox.selected_index)" can produce "Index out of range error"
		-- This is to prevent that error.
		if listbox.selected_index >= 1 and listbox.selected_index <= #listbox.items then
			Crew.join_spectators(player, tonumber(listbox.get_item(listbox.selected_index)[2]))
		end
		return
	end

	if eventname == 'leave_spectators' then
		Crew.leave_spectators(player)
		return
	end

	if eventname == 'join_crew' then
		local listbox = flow.ongoing_runs.body.ongoing_runs_listbox

		-- It was observed that "listbox.get_item(listbox.selected_index)" can produce "Index out of range error"
		-- This is to prevent that error.
		if listbox.selected_index >= 1 and listbox.selected_index <= #listbox.items then
			local crewid = tonumber(listbox.get_item(listbox.selected_index)[2])

			Memory.set_working_id(crewid)
			local memory = Memory.get_crew_memory()

			-- If run is private
			if memory.run_is_private then
				if memory.private_run_password == flow.ongoing_runs.body.password_namefield.text then
					Crew.join_crew(player)
					flow.ongoing_runs.body.join_private_crew_info.visible = false
					flow.ongoing_runs.body.password_namefield.visible = false

					if memory.run_is_protected and (not Roles.captain_exists()) then
						Common.notify_player_expected(player, {'pirates.player_joins_protected_run_with_no_captain'})
						Common.notify_player_expected(player, {'pirates.create_new_crew_tip'})
					end
				else
					Common.notify_player_error(player, {'pirates.gui_join_private_run_error_wrong_password'})
				end
			else
				Crew.join_crew(player)

				if memory.run_is_protected and (not Roles.captain_exists()) then
					Common.notify_player_expected(player, {'pirates.player_joins_protected_run_with_no_captain'})
					Common.notify_player_expected(player, {'pirates.create_new_crew_tip'})
				end
			end

			return
		end
	end

	if eventname == 'propose_crew' then
		if #global_memory.crew_active_ids >= global_memory.active_crews_cap then
			Common.notify_player_error(player, {'pirates.gui_runs_launch_error_5'})
			return
		end

		-- Count private runs
		local private_run_count = 0
		for _, id in pairs(global_memory.crew_active_ids) do
			if global_memory.crew_memories[id].run_is_private then
				private_run_count = private_run_count + 1
			end
		end

		-- Count protected but not private runs
		local protected_but_not_private_run_count = 0
		for _, id in pairs(global_memory.crew_active_ids) do
			if global_memory.crew_memories[id].run_is_protected and (not global_memory.crew_memories[id].run_is_private) then
				protected_but_not_private_run_count = protected_but_not_private_run_count + 1
			end
		end

		local run_is_protected = flow.proposals.body.proposal_maker.body.protected_checkbox.state
		local run_is_private = flow.proposals.body.proposal_maker.body.private_checkbox.state
		if run_is_private then
			-- Make sure private run can be created
			if private_run_count >= global_memory.private_run_cap then
				Common.notify_player_error(player, {'pirates.gui_runs_proposal_maker_error_private_run_limit'})
				return
			end

			-- Check if passwords match
			if flow.proposals.body.proposal_maker.body.password_namefield.text ~= flow.proposals.body.proposal_maker.body.confirm_password_namefield.text then
				Common.notify_player_error(player, {'pirates.gui_runs_proposal_maker_error_private_run_password_no_match'})
				return
			end

			-- Check if passwords aren't empty
			if flow.proposals.body.proposal_maker.body.password_namefield.text == '' then
				Common.notify_player_error(player, {'pirates.gui_runs_proposal_maker_error_private_run_password_empty'})
				return
			end
		elseif run_is_protected then
			-- Make sure protected run can be created
			if protected_but_not_private_run_count >= global_memory.protected_run_cap then
				Common.notify_player_error(player, {'pirates.gui_runs_proposal_maker_error_protected_run_limit'})
				return
			end
		end

		local private_run_password = flow.proposals.body.proposal_maker.body.password_namefield.text
		local proposal_name = flow.proposals.body.proposal_maker.body.namefield.text
		-- local proposal_name = string.sub(flow.proposals.body.proposal_maker.body.namefield.text, 1, 30)

		local capacity_option = flow.proposals.body.proposal_maker.body.options.capacity.capacity.slider.slider_value
		local difficulty_option = 1
		-- local difficulty_option = flow.proposals.body.proposal_maker.body.options.difficulty.difficulty.slider.slider_value
		-- local mode_option = flow.proposals.body.proposal_maker.body.options.mode.mode.switch.switch_state

		if (not proposal_name) or (proposal_name == '') then proposal_name = 'NoName' end

		-- make name unique
		-- local unique, changed = true, false
		-- local check_unique = function(name)
		-- 	unique = true
		-- 	for _, proposal in pairs(global_memory.crewproposals) do
		-- 		if name == proposal.name then
		-- 			unique = false
		-- 			changed = true
		-- 			break
		-- 		end
		-- 	end
		-- end
		-- local i = 0
		-- check_unique()
		-- while i < 10 and not unique do
		-- 	check_unique(proposal_name .. i)
		-- 	i = i + 1
		-- end
		-- if not unique then return end
		-- if changed then proposal_name = proposal_name .. i end

		local unique = true
		for _, proposal in pairs(global_memory.crewproposals) do
			if proposal_name == proposal.name then
				unique = false
				break
			end
		end

		if not unique then return end

		local proposal = {
			name = proposal_name,
			difficulty_option = difficulty_option,
			capacity_option = capacity_option,
			-- mode_option = mode_option,
			endorserindices = {player.index},
			run_is_protected = run_is_protected,
			run_is_private = run_is_private,
			private_run_password = private_run_password,
		}

		global_memory.crewproposals[#global_memory.crewproposals + 1] = proposal

		if run_is_private then
			Common.notify_lobby({'pirates.proposal_propose_private', player.name, proposal_name, CoreData.capacity_options[capacity_option].text3})
		else
			Common.notify_lobby({'pirates.proposal_propose', player.name, proposal_name, CoreData.capacity_options[capacity_option].text3})
		end

		-- local message = player.name .. ' proposed the run ' .. proposal_name .. ' (difficulty ' .. CoreData.difficulty_options[difficulty_option].text .. ', capacity ' .. CoreData.capacity_options[capacity_option].text3 .. ').'
		return
	end

	if eventname == 'endorse_proposal' then
		local lb = flow.proposals.body.proposals_listbox

		local index = lb.selected_index
		if index ~= 0 then
			local name2 = lb.get_item(lb.selected_index)[2]

			for _, proposal in pairs(global_memory.crewproposals) do

				if proposal.name == name2 and #proposal.endorserindices < CoreData.capacity_options[proposal.capacity_option].value then
					proposal.endorserindices[#proposal.endorserindices + 1] = player.index
				end
			end
		end
		return
	end

	if eventname == 'abandon_proposal' then
		Crew.player_abandon_proposal(player)
		Crew.player_abandon_endorsements(player)
		return
	end

	if eventname == 'retract_endorsement' then
		Crew.player_abandon_endorsements(player)
		return
	end

	if eventname == 'launch_crew' then
		if GuiCommon.crew_overall_state_bools(player.index).proposal_can_launch then --double check
			for k, proposal in pairs(global_memory.crewproposals) do
				if #proposal.endorserindices > 0 and proposal.endorserindices[1] == player.index then
					-- Make sure private run can be created
					if proposal.run_is_private then
						-- NOTE: I didn't want to add this check in "proposal_can_launch", because different error message would get displayed (I think?).
						local private_run_count = 0
						for _, id in pairs(global_memory.crew_active_ids) do
							if global_memory.crew_memories[id].run_is_private then
								private_run_count = private_run_count + 1
							end
						end

						if private_run_count >= global_memory.private_run_cap then
							Common.notify_player_error(player, {'pirates.gui_runs_proposal_maker_error_private_run_limit'})
							return
						end
					elseif proposal.run_is_protected then
						local protected_but_not_private_run_count = 0
						for _, id in pairs(global_memory.crew_active_ids) do
							if global_memory.crew_memories[id].run_is_protected and (not global_memory.crew_memories[id].run_is_private) then
								protected_but_not_private_run_count = protected_but_not_private_run_count + 1
							end
						end

						if protected_but_not_private_run_count >= global_memory.protected_run_cap then
							Common.notify_player_error(player, {'pirates.gui_runs_proposal_maker_error_protected_run_limit'})
							return
						end
					end

					Crew.initialise_crew(proposal)
					global_memory.crewproposals[k] = nil
					Progression.set_off_from_starting_dock()

					return
				end
			end
		end
	end
end

return Public