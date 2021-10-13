
local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Roles = require 'maps.pirates.roles.roles'
local Crew = require 'maps.pirates.crew'
local Progression = require 'maps.pirates.progression'
local Structures = require 'maps.pirates.structures.structures'
local inspect = require 'utils.inspect'.inspect
local Boats = require 'maps.pirates.structures.boats.boats'
local GuiCommon = require 'maps.pirates.gui.common'
local Server = require 'utils.server'
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


local function flow_add_proposal_switch(flow, name, displayname, starting_position, tooltip)
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
		name = 'switch',
		type = 'switch',
		switch_state = starting_position,
	})
	-- flow4.style.width = 80
	-- flow4.style.height = 40
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


function Public.toggle_window(player)
	local flow, flow2, flow3, flow4, flow5, flow6, flow7

	--*** OVERALL FLOW ***--
	if player.gui.screen[window_name .. '_piratewindow'] then player.gui.screen[window_name .. '_piratewindow'].destroy() return end
	
	flow = GuiCommon.new_window(player, window_name)
	flow.caption = 'Play'

	--*** ONGOING RUNS ***--

	flow2 = GuiCommon.flow_add_section(flow, 'ongoing_runs', 'Ongoing Runs')

	flow3 = flow2.add({
		name = 'helpful_tip',
		type = 'label',
		caption = 'To join a run, first select it in the table below.',
	})
	flow3.style.font_color = {r=0.90, g=0.90, b=0.90}
	flow3.style.single_line = false
	flow3.style.maximal_width = 160

	flow3 = flow2.add({
		name = 'ongoing_runs_listbox',
		type = 'list-box',
	})
	flow3.style.margin = 2
	flow3.style.horizontally_stretchable = true

	flow3 = flow2.add({
		name = 'flow_buttons',
		type = 'flow',
		direction = 'horizontal',
	})

	flow4 = flow3.add({
		name = 'join_spectators',
		type = 'button',
		caption = 'Spectate',
	})
	flow4.style.minimal_width = 95
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow4 = flow3.add({
		name = 'join_crew',
		type = 'button',
		caption = 'Join Crew',
	})
	flow4.style.minimal_width = 95
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}

	flow4 = flow3.add({
		name = 'leave_spectators',
		type = 'button',
		caption = 'Return to Lobby',
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
		caption = 'Hop on board.',
	})
	flow3.style.left_margin = 5


	-- PROPOSALS --

	flow2 = GuiCommon.flow_add_section(flow, 'proposals', 'Proposals')

	flow3 = flow2.add({
		name = 'proposals_listbox',
		type = 'list-box',
	})
	flow3.style.margin = 2

	flow3 = flow2.add({
		name = 'flow_buttons',
		type = 'flow',
		direction = 'horizontal',
	})

	flow4 = flow3.add({
		name = 'endorse_proposal',
		type = 'button',
		caption = 'Endorse Proposal',
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow4.style.bottom_margin = 9

	flow4 = flow3.add({
		name = 'retract_endorsement',
		type = 'button',
		caption = 'Retract Endorsement',
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}
	flow4.style.bottom_margin = 9

	flow4 = flow3.add({
		name = 'abandon_proposal',
		type = 'button',
		caption = 'Abandon Proposal',
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
		caption = 'Run name',
	})
	flow5.style.font = 'heading-3'

	flow5 = flow4.add({
		name = 'namefield',
		type = 'textfield',
		caption = 'Name',
		text = '',
	})
	flow5.style.width = 150
	flow5.style.height = 24
	flow5.style.top_margin = -3
	flow5.style.bottom_margin = 3

	flow5 = flow4.add({
		name = 'options',
		type = 'table',
		column_count = 2,
	})
	flow5.style.width = 200
	flow5.style.margin = 0

	flow_add_proposal_slider(flow5, 'capacity', 'Capacity', #CoreData.capacity_options, 3, {'pirates.capacity_tooltip'})
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
		caption = 'This capacity setting isn\'t available at the moment.',
	})
	flow5.style.single_line = false
	flow5.style.maximal_width = 200

	flow5 = flow4.add({
		name = 'propose_crew',
		type = 'button',
		caption = 'Propose',
	})
	flow4.style.minimal_width = 75
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}


	-- LAUNCH YOUR PROPOSAL --

	flow3 = flow2.add({
		name = 'flow_proposal_launch',
		type = 'flow',
		direction = 'vertical',
	})

	flow4 = flow3.add({
		name = 'proposal_insufficient_endorsers',
		type = 'label',
		caption = 'Gather support from more pirates.',
	})

	flow4 = flow3.add({
		name = 'proposal_insufficient_player_capacity',
		type = 'label',
		caption = "Can't launch; at least one run needs high player capacity.",
	})

	flow4 = flow3.add({
		name = 'proposal_insufficient_sloops',
		type = 'label',
		caption = 'No sloops available. Join an existing run instead.',
	})

	flow4 = flow3.add({
		name = 'launch_crew',
		type = 'button',
		caption = 'Launch run',
	})
	flow4.style.minimal_width = 150
	flow4.style.font = 'default-bold'
	flow4.style.font_color = {r=0.10, g=0.10, b=0.10}


	GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
end





function Public.update(player)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if not player.gui.screen['runs_piratewindow'] then return end
	local flow = player.gui.screen['runs_piratewindow']
	local playercrew_status = GuiCommon.playercrew_status_table(player.index)
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
			flow.ongoing_runs.body.wait_to_join.caption = 'Wait to join... ' .. Math.ceil(((global_memory.crew_memories[crewid].tempbanned_from_joining_data[player.index] - (game.tick - Common.ban_from_rejoining_crew_ticks)))/60)
		end

		if not selected_joinable_bool then flow.ongoing_runs.body.ongoing_runs_listbox.selected_index = 0 end

		flow.ongoing_runs.body.leaving_prompt.visible = playercrew_status.leaving
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

		flow.proposals.body.flow_proposal_launch.proposal_insufficient_endorsers.visible = playercrew_status.needs_more_endorsers

		-- flow.proposals.body.proposal_maker.body.proposal_cant_do_infinity_mode.visible = (flow.proposals.body.proposal_maker.body.options.mode.mode.switch.switch_state == 'right')

		-- flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible = false
		flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible = (flow.proposals.body.proposal_maker.body.options.capacity.capacity.slider.slider_value < global_memory.minimum_capacity_slider_value)

		flow.proposals.body.proposal_maker.body.propose_crew.visible = (flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible == false)
		-- flow.proposals.body.proposal_maker.body.propose_crew.visible = (flow.proposals.body.proposal_maker.body.proposal_cant_do_infinity_mode.visible == false) and (flow.proposals.body.proposal_maker.body.proposal_disabled_low_crew_caps.visible == false)

		flow.proposals.body.flow_proposal_launch.launch_crew.visible = (playercrew_status.proposing and not (playercrew_status.sloops_full or playercrew_status.needs_more_capacity or playercrew_status.needs_more_endorsers))

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
			wrappedmemories[#wrappedmemories + 1] = {'pirates.run_displayform', mem.id, mem.name .. ', ' .. CoreData.difficulty_options[mem.difficulty_option].text .. ', [item=light-armor]' ..  count .. CoreData.capacity_options[mem.capacity_option].text2 .. ',  [item=rail] ' .. (mem.overworldx or 0)}
			-- wrappedmemories[#wrappedmemories + 1] = {'pirates.run_displayform', mem.id, mem.name, Utils.spritepath_to_richtext(CoreData.difficulty_options[mem.difficulty_option].icon), count, CoreData.capacity_options[mem.capacity_option].text2, '      [item=rail] ', mem.overworldx or 0}
		end
		GuiCommon.update_listbox(flow.ongoing_runs.body.ongoing_runs_listbox, wrappedmemories)
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
		if flow.proposals.body.proposal_maker.body.options.capacity.capacity.readoff_text.caption == '∞' then flow.proposals.body.proposal_maker.body.options.capacity.capacity.readoff_text.caption = 'No limit' end

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

	local player = game.players[event.element.player_index]

	local eventname = event.element.name
	
	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow = player.gui.screen[window_name .. '_piratewindow']
	
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()


	if eventname == 'join_spectators' then
		local listbox = flow.ongoing_runs.body.ongoing_runs_listbox

		Crew.join_spectators(player, tonumber(listbox.get_item(listbox.selected_index)[2]))
		return
	end

	if eventname == 'leave_spectators' then
		Crew.leave_spectators(player)
		return
	end

	if eventname == 'join_crew' then
		local listbox = flow.ongoing_runs.body.ongoing_runs_listbox

		Crew.join_crew(player, tonumber(listbox.get_item(listbox.selected_index)[2]))
		return
	end

	if eventname == 'propose_crew' then
		local proposal_name = flow.proposals.body.proposal_maker.body.namefield.text
		-- local proposal_name = string.sub(flow.proposals.body.proposal_maker.body.namefield.text, 1, 30)

		local capacity_option = flow.proposals.body.proposal_maker.body.options.capacity.capacity.slider.slider_value
		local difficulty_option = 2
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
		}

		global_memory.crewproposals[#global_memory.crewproposals + 1] = proposal

		local message = player.name .. ' proposed the run ' .. proposal_name .. ' (capacity ' .. CoreData.capacity_options[capacity_option].text3 .. ').'
		-- local message = player.name .. ' proposed the run ' .. proposal_name .. ' (difficulty ' .. CoreData.difficulty_options[difficulty_option].text .. ', capacity ' .. CoreData.capacity_options[capacity_option].text3 .. ').'
		Common.notify_lobby(message)
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
		for k, proposal in pairs(global_memory.crewproposals) do
			if #global_memory.crew_active_ids < global_memory.active_crews_cap then
				if #proposal.endorserindices > 0 and proposal.endorserindices[1] == player.index then
					Crew.initialise_crew(proposal)
					global_memory.crewproposals[k] = nil
					Progression.set_off_from_starting_dock()

					return
				end
			else
				Common.notify_player(player, 'The number of concurrent runs on the server is currently capped at ' .. global_memory.active_crews_cap .. '.')
			end
		end
	end

end

return Public