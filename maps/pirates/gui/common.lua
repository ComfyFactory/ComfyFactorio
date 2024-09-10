---@diagnostic disable: inject-field
-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local _inspect = require 'utils.inspect'.inspect
local Crew = require 'maps.pirates.crew'
-- local Progression = require 'maps.pirates.progression'
-- local Structures = require 'maps.pirates.structures.structures'
local Shop = require 'maps.pirates.shop.shop'
local Boats = require 'maps.pirates.structures.boats.boats'
local Surfaces = require 'maps.pirates.surfaces.surfaces'


local Public = {}


Public.bold_font_color = {255, 230, 192}
Public.default_font_color = {1, 1, 1}
Public.section_header_font_color = {r=0.40, g=0.80, b=0.60}
Public.subsection_header_font_color = {229, 255, 242}
Public.friendly_font_color = {246, 230, 255}
Public.sufficient_font_color = {66, 220, 124}
Public.insufficient_font_color = {1, 0.62, 0.19}
Public.achieved_font_color = {227, 250, 192}

Public.fuel_color_1 = {r=255, g=255, b=255}
Public.fuel_color_2 = {r=255, g=0, b=60}

Public.rage_font_color_1 = {r=1, g=1, b=1}
Public.rage_font_color_2 = {r=1, g=0.5, b=0.1}
Public.rage_font_color_3 = {r=1, g=0.1, b=0.05}



Public.default_window_positions = {
	runs = {x = 10, y = 48},
	crew = {x = 40, y = 48},
	progress = {x = 250, y = 48},
	fuel = {x = 468, y = 48},
	minimap = {x = 10, y = 48},
	color = {x = 160, y = 96},
}

function Public.new_window(player, name)

	local global_memory = Memory.get_global_memory()
	local gui_memory = global_memory.player_gui_memories[player.index]
	local flow

	flow = player.gui.screen.add{
        type = 'frame',
        name = name .. '_piratewindow',
        direction = 'vertical'
    }

	if gui_memory and gui_memory[name] and gui_memory[name].position then
		flow.location = gui_memory[name].position
	else
		flow.location = Public.default_window_positions[name]
	end

	flow.style = 'map_details_frame'
	flow.style.minimal_width = 210
	flow.style.natural_width = 210
	flow.style.maximal_width = 270
	flow.style.minimal_height = 80
	flow.style.natural_height = 80
	flow.style.maximal_height = 760
	flow.style.padding = 10

	return flow
end


function Public.update_gui_memory(player, namespace, key, value)
	local global_memory = Memory.get_global_memory()
	if not global_memory.player_gui_memories[player.index] then
		global_memory.player_gui_memories[player.index] = {}
	end
	local gui_memory = global_memory.player_gui_memories[player.index]
	if not gui_memory[namespace] then
		gui_memory[namespace] = {}
	end
	gui_memory[namespace][key] = value
end


function Public.flow_add_floating_sprite_button(flow1, button_name, width)
	width = width or 40
	local flow2, flow3

    flow2 = flow1.add({
		name = button_name .. '_frame',
		type = 'frame',
	})
	flow2.style.height = 40
	flow2.style.margin = 0
	flow2.style.left_padding = -4
	flow2.style.top_padding = -4
	flow2.style.right_margin = -2
	flow2.style.width = width

	flow3 = flow2.add({
		name = button_name,
		type = 'sprite-button',
	})
	flow3.style.height = 40
	flow3.style.width = width
	-- flow3.style.padding = -4

    return flow3
end




function Public.flow_add_floating_button(flow1, button_name)
	local flow2, flow3

    flow2 = flow1.add({
		name = button_name .. '_flow_1',
		type = 'flow',
		direction = 'vertical',
	})
	flow2.style.height = 40
	-- flow2.style.left_padding = 4
	-- flow2.style.top_padding = 0
	-- flow2.style.right_margin = -2
	flow2.style.natural_width = 40

	flow3 = flow2.add({
		name = button_name,
		type = 'button',
	})
	flow3.style = 'dark_rounded_button'
	-- flow3.style.minimal_width = 60
	-- flow3.style.natural_width = 60
	flow3.style.minimal_height = 40
	flow3.style.maximal_height = 40
	flow3.style.left_padding = 10
	flow3.style.right_padding = 4
	flow3.style.top_padding = 3
	-- flow3.style.padding = -4
	flow3.style.natural_width = 40
	flow3.style.horizontally_stretchable = true

	flow3 = flow2.add({
		name = button_name .. '_flow_2',
		type = 'flow',
	})
	flow3.style.natural_width = 20
	flow3.style.top_margin = -37
	flow3.style.left_margin = 10
	flow3.style.right_margin = 9
	flow3.ignored_by_interaction=true

    return flow3
end



function Public.flow_add_shop_item(flow, name)
	local flow2, flow3

	local shop_data_1 = Shop.Captains.main_shop_data_1
	local shop_data_2 = Shop.Captains.main_shop_data_2
	local trade_data = shop_data_1[name] or shop_data_2[name]
	if not trade_data then return end

	flow2 = flow.add({
		name = name,
		type = 'flow',
		direction = 'horizontal',
	})
    flow2.style.top_margin = 3
    flow2.style.horizontal_align = 'center'
    flow2.style.vertical_align = 'center'
	flow2.tooltip = trade_data.tooltip


	for k, v in pairs(trade_data.what_you_get_sprite_buttons) do
		flow3 = flow2.add({
			type = 'sprite-button',
			name = k,
			sprite = k,
			enabled = false,
		})
		flow3.style.minimal_height = 40
		flow3.style.maximal_height = 40
		if v == false then
			flow3.number = nil
		else
			flow3.number = v
		end
		flow3.tooltip = trade_data.tooltip
	end

	flow3 = flow2.add({
		type = 'label',
		name = 'for',
		caption = 'for'
	})
	flow3.style.font = 'default-large'
	flow3.style.font_color = Public.default_font_color
	flow3.tooltip = trade_data.tooltip

	for k, _ in pairs(trade_data.base_cost) do
		flow3 = flow2.add({
			name = 'cost_' .. k,
			type = 'sprite-button',
			enabled = false,
		})
		flow3.style.minimal_height = 40
		flow3.style.maximal_height = 40
		flow3.tooltip = trade_data.tooltip
		if k == 'fuel' then
			flow3.sprite = 'item/coal'
		elseif k == 'coins' then
			flow3.sprite = 'item/coin'
		elseif k == 'iron_plates' then
			flow3.sprite = 'item/iron-plate'
		elseif k == 'copper_plates' then
			flow3.sprite = 'item/copper-plate'
		end
	end


	flow3 = flow2.add({
		name = 'spacing',
		type = 'flow',
		direction = 'horizontal',
	})
    flow3.style.horizontally_stretchable = true

	flow3 = flow2.add({
		type = 'sprite-button',
		name = 'buy_button',
		caption = 'Buy'
	})
	flow3.style.font = 'default-large'
	flow3.style.font_color = Public.default_font_color
    flow3.style.height = 32
    flow3.style.width = 50
    flow3.style.padding = 0
    flow3.style.margin = 0

	return flow2
end


function Public.flow_add_section(flow, name, caption)
	local flow2, flow3

	flow2 = flow.add({
		name = name,
		type = 'flow',
		direction = 'vertical',
	})
	flow2.style.bottom_margin = 5

	flow3 = flow2.add({
		type = 'label',
		name = 'header',
		caption = caption
	})
	flow3.style.font = 'heading-2'
	flow3.style.font_color = Public.section_header_font_color
	flow3.style.maximal_width = 300
	-- flow3.style.maximal_width = 220
	-- flow3.style.single_line = false

	flow3 = flow2.add({
		name = 'body',
		type = 'flow',
		direction = 'vertical',
	})
	flow3.style.left_margin = 5
	flow3.style.right_margin = 5

	return flow3
end


function Public.flow_add_subpanel(flow, name)
	local flow2

	flow2 = flow.add({
		name = name,
		type = 'frame',
		direction = 'vertical',
	})
	flow2.style = 'subpanel_frame'
	flow2.style.natural_width = 100
	flow2.style.top_padding = -2
	flow2.style.top_margin = -8

	return flow2
end



function Public.flow_add_close_button(flow, close_button_name)
	local flow2, flow3, flow4

	flow2 = flow.add({
		name = 'close_button_flow',
		type = 'flow',
		direction = 'vertical',
	})

	flow3 = flow2.add{type="flow", name='hflow', direction="horizontal"}
    flow3.style.vertical_align = 'center'

	flow4 = flow3.add{type="flow", name='spacing', direction="horizontal"}
	flow4.style.horizontally_stretchable = true

	flow4 = flow3.add({
		type = 'button',
		name = close_button_name,
		caption = {'pirates.gui_close_button'},
	})
	flow4.style = 'back_button'
	flow4.style.minimal_width = 90
	flow4.style.font = 'default-bold'
	flow4.style.height = 28
	flow4.style.horizontal_align = 'center'

	return flow3
end


function Public.crew_overall_state_bools(player_index)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	--*** PLAYER STATUS ***--

	local ret = {
		adventuring = false,
		spectating = false,
		created_crew = false,
		proposing = false,
		sloops_full = false,
		needs_more_capacity = false,
		crew_count_capped = false,
		leaving = false,
		proposal_can_launch = false,
	}
	if memory.crewstatus == Crew.enum.ADVENTURING then
		for _, playerindex in pairs(memory.crewplayerindices) do
			if player_index == playerindex then ret.adventuring = true end
		end
		for _, playerindex in pairs(memory.spectatorplayerindices) do
			if player_index == playerindex then ret.spectating = true end
		end
	end
	if memory.crewstatus == nil then
		for _, crewid in pairs(global_memory.crew_active_ids) do
			if global_memory.crew_memories[crewid].crewstatus == Crew.enum.LEAVING_INITIAL_DOCK then
				if global_memory.crew_memories[crewid].original_proposal.created_by_player == player_index then ret.leaving = true end
			end
		end
		for _, proposal in pairs(global_memory.crewproposals) do
			if proposal.created_by_player == player_index then
				ret.proposing = true
				if #global_memory.crew_active_ids >= Common.starting_ships_count then
					ret.sloops_full = true
				elseif #global_memory.crew_active_ids >= global_memory.active_crews_cap_memory then
					ret.crew_count_capped = true
				elseif global_memory.active_crews_cap_memory > 1 and #global_memory.crew_active_ids == (global_memory.active_crews_cap_memory - 1) and not ((global_memory.crew_memories[1] and global_memory.crew_memories[1].capacity >= Common.minimum_run_capacity_to_enforce_space_for) or (global_memory.crew_memories[2] and global_memory.crew_memories[2].capacity >= Common.minimum_run_capacity_to_enforce_space_for) or (global_memory.crew_memories[3] and global_memory.crew_memories[3].capacity >= Common.minimum_run_capacity_to_enforce_space_for)) and not (CoreData.capacity_options[proposal.capacity_option].value >= Common.minimum_run_capacity_to_enforce_space_for) then
					ret.needs_more_capacity = true
				end
				if not (ret.sloops_full or ret.needs_more_capacity or ret.crew_count_capped) then
					ret.proposal_can_launch = true
				end
			end
			
			if player_index == proposal.created_by_player then ret.created_crew = true end
		end
	end

	return ret
end





function Public.player_and_crew_state_bools(player)
	local memory = Memory.get_crew_memory()

	-- if memory.player_and_crew_state_bools_memoized and memory.player_and_crew_state_bools_memoized.tick > game.tick - 30 then -- auto-memoize and only update every half-second
	-- 	return memory.player_and_crew_state_bools_memoized.ret
	-- else
		local destination = Common.current_destination()
		local dynamic_data = destination.dynamic_data --assumes this always exists

		local in_crowsnest_bool, in_hold_bool, in_cabin_bool, onmap_bool, eta_bool, approaching_bool, retreating_bool, atsea_sailing_bool, landed_bool, quest_bool, silo_bool, charged_bool, launched_bool, captain_bool, atsea_loading_bool, atsea_waiting_bool, character_on_deck_bool, on_deck_standing_near_loco_bool, on_deck_standing_near_cabin_bool, on_deck_standing_near_crowsnest_bool, cost_bool, cost_includes_rocket_launch_bool, approaching_dock_bool, leaving_dock_bool, leave_anytime_bool

		captain_bool = Common.is_captain(player)

		in_crowsnest_bool = string.sub(player.surface.name, 9, 17) == 'Crowsnest'
		in_hold_bool = string.sub(player.surface.name, 9, 12) == 'Hold'
		in_cabin_bool = string.sub(player.surface.name, 9, 13) == 'Cabin'

		onmap_bool = destination.surface_name and (player.surface.name == destination.surface_name or (
			memory.boat and memory.boat.surface_name == destination.surface_name and (in_crowsnest_bool or in_hold_bool or in_cabin_bool)
		))

		if destination then
			eta_bool = dynamic_data.time_remaining and dynamic_data.time_remaining > 0 and onmap_bool
			approaching_bool = memory.boat and memory.boat.state == Boats.enum_state.APPROACHING and onmap_bool
			retreating_bool = memory.boat and memory.boat.state == Boats.enum_state.RETREATING and onmap_bool
			-- approaching_bool = memory.boat and memory.boat.state == Boats.enum_state.APPROACHING
			atsea_sailing_bool = memory.boat and memory.boat.state == Boats.enum_state.ATSEA_SAILING
			atsea_waiting_bool = memory.boat and memory.boat.state == Boats.enum_state.ATSEA_WAITING_TO_SAIL
			landed_bool = memory.boat and memory.boat.state == Boats.enum_state.LANDED
			quest_bool = (dynamic_data.quest_type ~= nil) and onmap_bool
			charged_bool = dynamic_data.silocharged
			silo_bool = dynamic_data.rocketsilos and onmap_bool and ((dynamic_data.rocketsilos[1] and dynamic_data.rocketsilos[1].valid) or charged_bool)
			launched_bool = dynamic_data.rocketlaunched

			cost_bool = destination.static_params.base_cost_to_undock and (not atsea_sailing_bool) and (not atsea_waiting_bool) and (not retreating_bool)
			cost_includes_rocket_launch_bool = cost_bool and destination.static_params.base_cost_to_undock['launch_rocket']

			leave_anytime_bool = (landed_bool and not (eta_bool or cost_bool))
		end

		if memory.boat then
			atsea_loading_bool = memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP and memory.loadingticks

			character_on_deck_bool = player.character and player.character.position and player.surface.name and player.surface.name == memory.boat.surface_name

			if character_on_deck_bool then
				local BoatData = Boats.get_scope(memory.boat).Data

				on_deck_standing_near_loco_bool = Math.distance(player.character.position, Math.vector_sum(memory.boat.position, BoatData.loco_pos)) < 2.5

				on_deck_standing_near_cabin_bool = Math.distance(player.character.position, Math.vector_sum(memory.boat.position, BoatData.cabin_car)) < 2.0

				on_deck_standing_near_crowsnest_bool = Math.distance(player.character.position, Math.vector_sum(memory.boat.position, BoatData.crowsnest_center)) < 2.5
			end

			approaching_dock_bool = destination.type == Surfaces.enum.DOCK and memory.boat.state == Boats.enum_state.APPROACHING
			leaving_dock_bool = destination.type == Surfaces.enum.DOCK and memory.boat.state == Boats.enum_state.LEAVING_DOCK
		end

		local ret = {
			in_crowsnest_bool = in_crowsnest_bool,
			in_hold_bool = in_hold_bool,
			in_cabin_bool = in_cabin_bool,
			-- onmap_bool = onmap_bool,
			eta_bool = eta_bool,
			approaching_bool = approaching_bool,
			retreating_bool = retreating_bool,
			atsea_sailing_bool = atsea_sailing_bool,
			atsea_waiting_bool = atsea_waiting_bool,
			-- landed_bool = landed_bool,
			quest_bool = quest_bool,
			silo_bool = silo_bool,
			charged_bool = charged_bool,
			launched_bool = launched_bool,
			captain_bool = captain_bool,
			atsea_loading_bool = atsea_loading_bool,
			-- character_on_deck_bool = character_on_deck_bool,
			on_deck_standing_near_loco_bool = on_deck_standing_near_loco_bool,
			on_deck_standing_near_cabin_bool = on_deck_standing_near_cabin_bool,
			on_deck_standing_near_crowsnest_bool = on_deck_standing_near_crowsnest_bool,
			cost_bool = cost_bool,
			cost_includes_rocket_launch_bool = cost_includes_rocket_launch_bool,
			approaching_dock_bool = approaching_dock_bool,
			leaving_dock_bool = leaving_dock_bool,
			leave_anytime_bool = leave_anytime_bool
		}

		-- memory.player_and_crew_state_bools_memoized = {ret = ret, tick = game.tick}

		return ret
	-- end
end



function Public.update_listbox(listbox, table)
	-- pass a table of strings of the form {'locale', unique_id, ...}

	-- remove any that shouldn't be there
	local marked_for_removal = {}
	for index, item in pairs(listbox.items) do
		local exists = false
		for _, i in pairs(table) do
			if tostring(i[2]) == item[2] then
				exists = true
			end
		end
		if exists == false then
			marked_for_removal[#marked_for_removal + 1] = index
		end
	end
	for i = #marked_for_removal, 1, -1 do
		listbox.remove_item(marked_for_removal[i])
	end

	local indexalreadyat
	for _, i in pairs(table) do
		local contained = false
		for index, item in pairs(listbox.items) do
			if tostring(i[2]) == item[2] then
				contained = true
				indexalreadyat = index
			end
		end

		if contained then
			listbox.set_item(indexalreadyat, i)
		else
			listbox.add_item(i)
		end
	end
end


return Public