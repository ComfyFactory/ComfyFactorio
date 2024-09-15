-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local GuiEvo = require 'maps.pirates.gui.evo'
local GuiProgress = require 'maps.pirates.gui.progress'
local GuiRuns = require 'maps.pirates.gui.runs'
local GuiCrew = require 'maps.pirates.gui.crew'
local GuiClasses = require 'maps.pirates.gui.classes'
local GuiMinimap = require 'maps.pirates.gui.minimap'
local GuiInfo = require 'maps.pirates.gui.info'
local Quest = require 'maps.pirates.quest'
local Balance = require 'maps.pirates.balance'
local _inspect = require 'utils.inspect'.inspect
local GuiCommon = require 'maps.pirates.gui.common'
local Boats = require 'maps.pirates.structures.boats.boats'
local Hold = require 'maps.pirates.surfaces.hold'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Progression = require 'maps.pirates.progression'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Roles = require 'maps.pirates.roles.roles'
local Event = require 'utils.event'

local IslandEnum = require 'maps.pirates.surfaces.islands.island_enum'
local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local GuiWelcome = require 'maps.pirates.gui.welcome'

local ComfyGui = require 'utils.gui'
ComfyGui.set_disabled_tab('Scoreboard', true)
ComfyGui.set_disabled_tab('Groups', true)

local Public = {}

Public.progress = require 'maps.pirates.gui.progress'
Public.runs = require 'maps.pirates.gui.runs'
Public.crew = require 'maps.pirates.gui.crew'
Public.classes = require 'maps.pirates.gui.classes'
Public.minimap = require 'maps.pirates.gui.minimap'
Public.info = require 'maps.pirates.gui.info'
Public.color = require 'maps.pirates.gui.color'

local function create_gui(player)
	local flow1, flow2, flow3, flow4

	flow1 = player.gui.top

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'info_piratebutton')
	flow2.caption = '?'
	flow2.style.font = 'debug'
	flow2.tooltip = { 'pirates.gui_info_main_tooltip' }
	flow2.style.font_color = { r = 1, g = 1, b = 1 }
	flow2.style.hovered_font_color = { r = 1, g = 1, b = 1 }
	flow2.style.clicked_font_color = { r = 1, g = 1, b = 1 }
	flow2.parent.style.left_padding = -6

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'runs_piratebutton', 70)
	flow2.caption = { 'pirates.gui_crews' }
	flow2.tooltip = { 'pirates.gui_crews_main_tooltip' }
	flow2.style.font = 'debug'
	flow2.style.font_color = { r = 1, g = 1, b = 1 }
	flow2.style.hovered_font_color = { r = 1, g = 1, b = 1 }
	flow2.style.clicked_font_color = { r = 1, g = 1, b = 1 }
	flow2.parent.style.width = 67
	flow2.parent.style.left_padding = -6

	-- optional use of left gui:
	-- flowleft = player.gui.left
	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flowleft, 'crew_piratebutton')
	-- flow2.sprite = 'utility/spawn_flag'
	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'crew_piratebutton')
	flow2.sprite = 'utility/spawn_flag'

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'classes_piratebutton')
	flow2.sprite = 'item/light-armor'

	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'lives_piratebutton')
	-- flow2.tooltip = 'Lives\n\nWhen a silo is destroyed before its rocket is launched, you lose a life.\n\nLosing all your lives is one way to lose the game.'
	-- flow2.mouse_button_filter = {'middle'}

	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'distance_travelled_piratebutton')
	-- flow2.tooltip = 'Leagues travelled in the overworld\n\nCrews progress through the game by travelling in the overworld. Travel ' .. CoreData.victory_x/40 .. ' leagues = victory.'
	-- flow2.sprite = 'item/rail'
	-- flow2.mouse_button_filter = {'middle'}

	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'destination_piratebutton')
	-- flow2.tooltip = 'Location window\n\nWhere am I?'
	-- flow2.sprite = 'item/landfill'

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'progress_piratebutton')
	flow2.sprite = 'item/rail'

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'evo_piratebutton')
	flow2.sprite = 'entity/small-biter'
	flow2.mouse_button_filter = { 'middle' } --hack to avoid press visual
	flow2.show_percent_for_small_numbers = true --as of factorio v1.1.59, there is a bug in which 1.002 displays as like 1e-2% or something. but after 1.01 it's ok

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'minimap_piratebutton')
	flow2.tooltip = { 'pirates.gui_minimap_main_tooltip' }
	flow2.sprite = 'utility/map'

	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'shop_piratebutton')
	-- flow2.tooltip = "Coal/Officer's Shop\n\nThe captain and their officers are authorised to spend coal in the shop."
	-- flow2.sprite = 'item/coal'




	flow2 = flow1.add({
		name = 'fuel_flow',
		type = 'frame',
	})
	flow2.style.minimal_width = 80
	flow2.style.natural_width = 80
	flow2.style.minimal_height = 40
	flow2.style.maximal_height = 40
	flow2.style.left_padding = 4
	flow2.style.right_padding = 4
	flow2.style.top_padding = 3

	-- interactive version:
	-- flow2 = GuiCommon.flow_add_floating_button(flow1, 'fuel_piratebutton')

	flow3 = flow2.add({
		name = 'fuel_label_0',
		type = 'label',
		caption = ''
	})
	flow3.style.font = 'default-large-semibold'
	flow3.style.font_color = GuiCommon.bold_font_color
	flow3.caption = { 'pirates.gui_fuel_1' }

	flow3 = flow2.add({
		name = 'fuel_label_1',
		type = 'label',
		caption = ''
	})
	flow3.style.font = 'default-large'
	flow3.style.font_color = GuiCommon.default_font_color
	-- flow3.style.font_color = GuiCommon.bold_font_color
	-- flow4.style.top_margin = -36
	-- flow4.style.left_margin = -100
	-- flow3.style.horizontal_align = 'center'
	-- flow4.style.left_padding = -5
	flow3.style.left_margin = -2

	flow3 = flow2.add({
		name = 'fuel_label_2',
		type = 'label',
		caption = ''
	})
	flow3.style.font = 'default-large'
	flow3.style.left_margin = 3





	flow2 = GuiCommon.flow_add_floating_button(flow1, 'etaframe_piratebutton')
	-- flow2.style.right_padding = -100
	-- flow2.enabled = false

	flow3 = flow2.add({
		name = 'etaframe_label_1',
		type = 'label',
	})
	flow3.style.font = 'default-large-semibold'
	flow3.style.font_color = GuiCommon.bold_font_color

	flow3 = flow2.add({
		name = 'etaframe_label_2',
		type = 'label',
	})
	flow3.style.left_margin = 1
	flow3.style.font = 'default-large'
	flow3.style.font_color = GuiCommon.default_font_color

	flow3 = flow2.add({
		name = 'etaframe_label_3',
		type = 'label',
	})
	flow3.style.left_margin = 3
	flow3.style.font = 'default-large-semibold'
	flow3.style.font_color = GuiCommon.bold_font_color

	flow3 = flow2.add({ type = 'table', name = 'cost_table', column_count = #CoreData.cost_items })
	for i = 1, #CoreData.cost_items do
		flow4 = flow3.add({ type = 'sprite-button', name = 'cost_' .. i, number = 0 })
		-- flow4.mouse_button_filter = {'middle'}
		flow4.sprite = CoreData.cost_items[i].sprite_name
		flow4.enabled = false
		flow4.style.top_margin = -6
		flow4.style.right_margin = -6
		flow4.style.maximal_height = 38
		flow4.visible = false
	end
	-- and
	flow4 = flow3.add({ type = 'sprite-button', name = 'cost_launch_rocket' })
	-- flow4.mouse_button_filter = {'middle'}
	flow4.sprite = 'item/rocket-silo'
	flow4.enabled = false
	flow4.style.top_margin = -6
	flow4.style.right_margin = -6
	flow4.style.maximal_height = 38
	flow4.visible = false

	flow3.style.left_margin = -1
	flow3.style.right_margin = -2 --to get to the end of the button frame


	-- flow2 = flow1.add({
	-- 	name = 'time_remaining_frame',
	-- 	type = 'frame',
	-- })
	-- flow2.style.minimal_width = 100
	-- flow2.style.natural_width = 100
	-- flow2.style.minimal_height = 40
	-- flow2.style.maximal_height = 40
	-- flow2.style.left_padding = 4
	-- flow2.style.right_padding = 4
	-- flow2.style.top_padding = 3
	-- flow2.tooltip = tooltip

	-- flow3 = flow2.add({
	-- 	name = 'time_remaining_label_1',
	-- 	type = 'label',
	-- 	caption = 'Max Time:'
	-- })
	-- flow3.style.font = 'default-large-semibold'
	-- flow3.style.font_color = GuiCommon.bold_font_color
	-- flow3.tooltip = tooltip

	-- flow3 = flow2.add({
	-- 	name = 'time_remaining_label_2',
	-- 	type = 'label',
	-- })
	-- flow3.style.left_margin = 2
	-- flow3.style.font = 'default-large'
	-- flow3.style.font_color = GuiCommon.default_font_color
	-- flow3.tooltip = tooltip





	-- flow3 = flow2.add({
	-- 	name = 'rage_table',
	-- 	type = 'table',
	-- 	column_count = 5,
	-- })
	-- flow3.style.top_margin = 6
	-- flow3.style.left_margin = 4
	-- for i = 1, 6 do
	-- 	flow4 = flow3.add({type = 'progressbar', name = 'bar_' .. i, value = 0.5})
	-- 	flow4.style.width = 18
	-- 	flow4.style.height = 5
	-- end








	-- flow2 = flow1.add({
	-- 	name = 'cost_frame',
	-- 	type = 'frame',
	-- })
	-- flow2.style.minimal_width = 100
	-- flow2.style.natural_width = 100
	-- flow2.style.minimal_height = 40
	-- flow2.style.maximal_height = 40
	-- flow2.style.left_padding = 4
	-- flow2.style.right_padding = 4
	-- flow2.style.top_padding = 3

	-- -- flow3 = flow2.add({
	-- -- 	name = 'cost_label_1',
	-- -- 	type = 'label',
	-- -- })
	-- -- flow3.style.font = 'default-large-semibold'
	-- -- flow3.style.font_color = GuiCommon.bold_font_color

	-- -- flow3 = flow2.add({
	-- -- 	name = 'cost_label_2',
	-- -- 	type = 'label',
	-- -- })
	-- -- flow3.style.font = 'default-large'
	-- -- flow3.style.font_color = GuiCommon.default_font_color

	-- flow3 = flow2.add({type = 'table', name = 'cost_table', column_count = 5})
	-- for i = 1, 5 do
	-- 	flow4 = flow3.add({type = 'sprite-button', name = 'cost_' .. i, number = 0})
	-- 	-- flow4.mouse_button_filter = {'middle'}
	-- 	flow4.enabled = false
	-- 	flow4.style.top_margin = -6
	-- 	flow4.style.right_margin = -6
	-- 	flow4.style.maximal_height = 38
	-- 	flow4.visible = false
	-- end
	-- flow3.style.right_margin = -3








	flow2 = flow1.add({
		name = 'silo_frame',
		type = 'frame',
	})
	flow2.style.minimal_width = 80
	flow2.style.natural_width = 80
	flow2.style.minimal_height = 40
	flow2.style.maximal_height = 40
	flow2.style.left_padding = 4
	flow2.style.right_padding = 4
	flow2.style.top_padding = 3

	flow3 = flow2.add({
		name = 'silo_label_1',
		type = 'label',
	})
	flow3.style.font = 'default-large-semibold'
	flow3.style.font_color = GuiCommon.bold_font_color
	flow3.style.right_margin = 2

	flow3 = flow2.add({
		type = 'progressbar',
		name = 'silo_progressbar',
		value = 0,
	})
	flow3.style.top_margin = 9
	flow3.style.right_margin = 2
	flow3.style.width = 72
	flow3.style.height = 11

	flow3 = flow2.add({
		name = 'silo_label_2',
		type = 'label',
	})
	flow3.style.font = 'default-large-semibold'
	flow3.style.right_margin = 2

	flow3 = flow2.add({
		name = 'silo_label_3',
		type = 'label',
	})
	flow3.style.font = 'default-large'
	flow3.style.font_color = GuiCommon.default_font_color
	flow3.style.right_margin = 2

	-- flow3 = flow2.add({
	-- 	type = 'sprite',
	-- 	name = 'silo_charging_indicator',
	-- })
	-- flow3.tooltip = tooltip

	-- old font color: {r=0.33, g=0.66, b=0.9}










	flow2 = flow1.add({
		name = 'quest_frame',
		type = 'frame',
	})
	flow2.style.minimal_width = 80
	flow2.style.natural_width = 80
	flow2.style.minimal_height = 40
	flow2.style.maximal_height = 40
	flow2.style.left_padding = 4
	flow2.style.right_padding = 4
	flow2.style.top_padding = 3

	flow3 = flow2.add({
		name = 'quest_label_1',
		type = 'label',
	})
	flow3.style.font = 'default-large-semibold'
	flow3.style.right_margin = 2

	flow3 = flow2.add({
		name = 'quest_label_2',
		type = 'label',
	})
	flow3.style.font = 'default-large'
	flow3.style.font_color = Common.default_font_color

	flow3 = flow2.add({
		name = 'quest_label_3',
		type = 'label',
	})
	-- flow3.style.font = 'default-large'
	flow3.style.font = 'default-large-semibold'
	flow3.style.left_margin = -4
	flow3.style.right_margin = -4
	flow3.style.font_color = Common.default_font_color

	flow3 = flow2.add({
		name = 'quest_label_4',
		type = 'label',
	})
	flow3.style.font = 'default-large'
	flow3.style.font_color = Common.default_font_color






	flow2 = flow1.add({
		name = 'covering_line_frame',
		type = 'frame',
	})
	flow2.style.minimal_width = 40
	flow2.style.natural_width = 40
	flow2.style.minimal_height = 40
	flow2.style.maximal_height = 40
	flow2.style.left_padding = 3
	flow2.style.right_padding = 3

	flow3 = flow2.add({
		name = 'covering_line',
		type = 'line',
		direction = 'horizontal',
	})
	flow3.style.top_margin = 9
	flow3.style.minimal_width = 320
	flow3.style.maximal_width = 320





	--== SCREEN STUFF

	-- spontaneous inside view of the hold:
	flow1 =
		player.gui.screen.add(
			{
				type = 'camera',
				name = 'pirates_spontaneous_camera',
				position = { x = 0, y = 0 },
			}
		)
	flow1.visible = false
	flow1.style.margin = 8
	-- flow2.style.minimal_height = 64
	-- flow2.style.minimal_width = 64
	-- flow2.style.maximal_height = 640
	-- flow2.style.maximal_width = 640


	-- flow2 = player.gui.screen.add({
	-- 	name = 'pirates_undock_shortcut_button',
	-- 	type = 'sprite-button',
	-- 	enabled = false,
	-- })
	-- flow2.style.minimal_width = 80
	-- flow2.style.natural_width = 80
	-- flow2.style.maximal_width = 150
	-- flow2.style.minimal_height = 40
	-- flow2.style.maximal_height = 40
	-- flow2.style.left_margin = 1
	-- flow2.style.top_margin = 1
	-- flow2.style.left_padding = 4
	-- flow2.style.right_padding = 4
	-- flow2.style.top_padding = 3
	-- flow2.style.font = 'default-large-semibold'
	-- flow2.style.font_color = GuiCommon.default_font_color
end


function Public.process_etaframe_update(player, flow1, bools)
	if not flow1 then return end

	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local dynamic_data = destination.dynamic_data --assumes this always exists

	local flow2

	if bools.cost_bool or bools.atsea_loading_bool or bools.atsea_waiting_bool or bools.atsea_victorious_bool or bools.eta_bool or bools.retreating_bool or bools.leave_anytime_bool then
		flow1.visible = true

		---@type string|table
		local tooltip = ''

		flow2 = flow1.etaframe_piratebutton_flow_2

		flow2.etaframe_label_1.visible = false --start off
		flow2.etaframe_label_2.visible = false --start off
		flow2.etaframe_label_3.visible = false --start off
		flow2.cost_table.visible = false --start off

		if bools.retreating_bool then
			flow2.etaframe_label_1.visible = true
			flow2.etaframe_label_2.visible = false

			tooltip = { 'pirates.gui_etaframe_board_warning_tooltip' }

			flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_board_warning' }
		elseif bools.eta_bool then
			flow2.etaframe_label_1.visible = true
			flow2.etaframe_label_2.visible = true

			tooltip = { 'pirates.auto_undock_tooltip' }

			local passive_eta = dynamic_data.time_remaining

			flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_autoundock' }
			flow2.etaframe_label_2.caption = Utils.standard_string_form_of_time_in_seconds(passive_eta)
		elseif bools.atsea_loading_bool then
			if Kraken.get_active_kraken_count(memory.id) > 0 then
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_2.visible = false

				tooltip = { 'pirates.defeat_krakens_tooltip' }

				flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_defeat_krakens' }
			else
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_2.visible = true

				tooltip = { 'pirates.atsea_loading_tooltip' }

				local total = Common.map_loading_ticks_atsea
				if destination.type == Surfaces.enum.DOCK then
					total = Common.map_loading_ticks_atsea_dock
				elseif destination.type == Surfaces.enum.ISLAND and destination.subtype == IslandEnum.enum.MAZE then
					total = Common.map_loading_ticks_atsea_maze
				end

				local eta_ticks = total + (memory.extra_time_at_sea or 0) - memory.loadingticks

				flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_loading_for' }
				flow2.etaframe_label_2.caption = Utils.standard_string_form_of_time_in_seconds(eta_ticks / 60)
			end
		elseif bools.atsea_waiting_bool then
			flow2.etaframe_label_1.visible = true
			flow2.etaframe_label_2.visible = false

			tooltip = { 'pirates.atsea_waiting_tooltip' }

			flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_atsea_waiting' }
		elseif bools.atsea_victorious_bool then
			flow2.etaframe_label_1.visible = true
			flow2.etaframe_label_2.visible = false

			tooltip = { 'pirates.atsea_victorious_tooltip' }

			flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_atsea_victorious' }
		elseif bools.leave_anytime_bool then
			flow2.etaframe_label_1.visible = true
			flow2.etaframe_label_2.visible = true

			tooltip = { 'pirates.leave_anytime_tooltip' }

			flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_undock' }
			flow2.etaframe_label_2.caption = { 'pirates.gui_etaframe_anytime' }
		end

		if bools.cost_bool and Kraken.get_active_kraken_count(memory.id) == 0 then
			local costs = destination.static_params.base_cost_to_undock
			local adjusted_costs = Common.time_adjusted_departure_cost(costs)

			local cost_table = flow2.cost_table

			flow2.etaframe_label_3.visible = true
			cost_table.visible = true

			if flow2.etaframe_label_2.visible then
				flow2.etaframe_label_2.caption = flow2.etaframe_label_2.caption .. '.'
			end

			-- local caption
			if bools.atsea_loading_bool then
				flow2.etaframe_label_3.caption = { 'pirates.gui_etaframe_next_escape_cost' }
				if Boats.need_resources_to_undock(Common.overworldx(), destination.subtype) then
					if bools.cost_includes_rocket_launch_bool then
						tooltip = { 'pirates.resources_needed_tooltip_4_rocketvariant' }
					else
						tooltip = { 'pirates.resources_needed_tooltip_4' }
					end
				elseif destination.static_params.undock_cost_decreases == true then
					if bools.cost_includes_rocket_launch_bool then
						tooltip = { 'pirates.resources_needed_tooltip_1_rocketvariant' }
					else
						tooltip = { 'pirates.resources_needed_tooltip_1' }
					end
				else
					if bools.cost_includes_rocket_launch_bool then
						tooltip = { 'pirates.resources_needed_tooltip_0a_rocketvariant' }
					else
						tooltip = { 'pirates.resources_needed_tooltip_0a' }
					end
				end
			elseif (not bools.eta_bool) then -- Shown when ship doesn't have auto undock timer
				flow2.etaframe_label_3.visible = false
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_to_escape_store' }

				if bools.cost_includes_rocket_launch_bool then
					tooltip = { 'pirates.resources_needed_tooltip_3_rocketvariant' }
				else
					tooltip = { 'pirates.resources_needed_tooltip_3' }
				end
			else -- Shown when at island
				if Boats.need_resources_to_undock(Common.overworldx(), destination.subtype) then
					flow2.etaframe_label_3.visible = false

					if bools.cost_includes_rocket_launch_bool then
						tooltip = { 'pirates.resources_needed_tooltip_5_rocketvariant' }
					else
						tooltip = { 'pirates.resources_needed_tooltip_5' }
					end
				elseif destination.static_params.undock_cost_decreases == true then
					flow2.etaframe_label_3.caption = { 'pirates.gui_etaframe_or_store' }

					local adjusted_costs_resources_strings = Common.time_adjusted_departure_cost_resources_strings(memory)
					if bools.cost_includes_rocket_launch_bool then
						tooltip = { 'pirates.resources_needed_tooltip_2_rocketvariant', adjusted_costs_resources_strings[1], adjusted_costs_resources_strings[2] }
					else
						--@Future reference: localisation handling
						tooltip = { 'pirates.resources_needed_tooltip_2', adjusted_costs_resources_strings[1], adjusted_costs_resources_strings[2] }
					end
				else
					if bools.cost_includes_rocket_launch_bool then
						tooltip = { 'pirates.resources_needed_tooltip_3_rocketvariant' }
					else
						tooltip = { 'pirates.resources_needed_tooltip_3' }
					end
				end
			end

			for i = 1, #CoreData.cost_items do
				local item_name = CoreData.cost_items[i].name

				if adjusted_costs[item_name] and cost_table['cost_' .. i] then
					local stored = (memory.boat.stored_resources and memory.boat.stored_resources[item_name]) or 0
					if bools.atsea_loading_bool then
						cost_table['cost_' .. i].number = adjusted_costs[item_name]
					else --subtract off the amount we've stored
						cost_table['cost_' .. i].number = Math.max(adjusted_costs[item_name] - stored, 0)
					end
					cost_table['cost_' .. i].tooltip = CoreData.cost_items[i].display_name
					cost_table['cost_' .. i].visible = true
				else
					cost_table['cost_' .. i].visible = false
				end
			end

			if adjusted_costs['launch_rocket'] and cost_table['cost_launch_rocket'] then
				if bools.atsea_loading_bool or (not dynamic_data.rocketlaunched) then
					cost_table['cost_launch_rocket'].number = 1
				else
					cost_table['cost_launch_rocket'].number = 0
				end
				cost_table['cost_launch_rocket'].tooltip = { 'pirates.gui_etaframe_rocket_requirement_tooltip' }
				cost_table['cost_launch_rocket'].visible = true
			else
				cost_table['cost_launch_rocket'].visible = false
			end
		end

		flow1.etaframe_piratebutton.tooltip = tooltip
		flow2.tooltip = tooltip

		if bools.captain_bool and (not bools.retreating_bool) and (bools.leave_anytime_bool or bools.atsea_waiting_bool or bools.eta_bool or (bools.cost_bool and (not bools.atsea_loading_bool))) then
			flow1.etaframe_piratebutton.mouse_button_filter = { 'left' }
			if memory.undock_shortcut_are_you_sure_data and memory.undock_shortcut_are_you_sure_data[player.index] and memory.undock_shortcut_are_you_sure_data[player.index] > game.tick - 60 * 4 then
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_1.caption = { 'pirates.gui_etaframe_undock_are_you_sure' }
				flow2.etaframe_label_2.visible = false
				flow2.etaframe_label_3.visible = false
			end
		else
			flow1.etaframe_piratebutton.mouse_button_filter = { 'middle' } --hack to avoid press visual
		end
	else
		flow1.visible = false
	end
end

function Public.process_siloframe_and_questframe_updates(flowsilo, flowquest, bools)
	local destination = Common.current_destination()
	local dynamic_data = destination.dynamic_data --assumes this always exists

	local active_eta
	local flow1

	flow1 = flowsilo
	if flow1 then
		if bools.silo_bool then
			flow1.visible = true

			if bools.charged_bool then
				if bools.launched_bool then
					flow1.silo_progressbar.visible = false

					flow1.silo_label_2.visible = false
					flow1.silo_label_3.visible = true

					-- flow1.silo_label_1.caption = string.format('[achievement=there-is-no-spoon]: +%.0f[item=sulfur]', dynamic_data.rocketcoalreward)
					flow1.silo_label_1.caption = { 'pirates.gui_etaframe_launched' }
					-- flow1.silo_label_1.caption = string.format('Launched for %.0f[item=coal] , ' .. Balance.rocket_launch_coin_reward .. '[item=coin]', dynamic_data.rocketcoalreward)
					flow1.silo_label_1.style.font_color = GuiCommon.achieved_font_color

					local rocket_launch_coal_reward = Balance.rocket_launch_fuel_reward()
					local rocket_launch_coin_reward = Balance.rocket_launch_coin_reward()

					flow1.silo_label_3.caption = Math.floor(rocket_launch_coal_reward / 100) / 10 .. 'k[item=coal], ' .. Math.floor(rocket_launch_coin_reward / 100) / 10 .. 'k[item=coin]'

					local tooltip = { 'pirates.gui_etaframe_launched_tooltip' }
					flow1.tooltip = tooltip
					flow1.silo_label_1.tooltip = tooltip
					flow1.silo_label_3.tooltip = tooltip
				else
					local tooltip = { 'pirates.gui_etaframe_launching' }
					flow1.tooltip = tooltip
					flow1.silo_label_1.tooltip = tooltip
					flow1.silo_progressbar.tooltip = tooltip

					flow1.silo_label_1.caption = { 'pirates.gui_etaframe_charge' }
					flow1.silo_label_1.style.font_color = GuiCommon.bold_font_color
					flow1.silo_label_2.visible = false
					flow1.silo_label_3.visible = false
					flow1.silo_progressbar.visible = true

					flow1.silo_progressbar.value = 1
				end
			else
				flow1.silo_label_1.caption = { 'pirates.gui_etaframe_charge' }
				flow1.silo_label_1.style.font_color = GuiCommon.bold_font_color
				flow1.silo_label_2.visible = true
				flow1.silo_progressbar.visible = true
				flow1.silo_label_3.visible = false

				local consumed = dynamic_data.rocketsiloenergyconsumed
				local needed = dynamic_data.rocketsiloenergyneeded
				local recent = (dynamic_data.rocketsiloenergyconsumedwithinlasthalfsecond * 2)

				flow1.silo_progressbar.value = consumed / needed

				local tooltip = { 'pirates.gui_etaframe_charge_tooltip', string.format('%.1f', Math.floor(consumed / 100000000) / 10), string.format('%.1f', Math.floor(needed / 100000000) / 10) }
				flow1.tooltip = tooltip
				flow1.silo_label_1.tooltip = tooltip
				flow1.silo_label_2.tooltip = tooltip
				flow1.silo_progressbar.tooltip = tooltip

				if recent ~= 0 then
					active_eta = (needed - consumed) / recent
					flow1.silo_label_2.caption = Utils.standard_string_form_of_time_in_seconds(active_eta)
					if active_eta < dynamic_data.time_remaining or (not bools.eta_bool) then
						flow1.silo_label_2.style.font_color = GuiCommon.sufficient_font_color
					else
						flow1.silo_label_2.style.font_color = GuiCommon.insufficient_font_color
					end
				else
					flow1.silo_label_2.caption = '∞'
					flow1.silo_label_2.style.font_color = GuiCommon.insufficient_font_color
				end
			end
		else
			flow1.visible = false
		end
	end

	flow1 = flowquest
	if flow1 then
		if bools.quest_bool then
			flow1.visible = true

			local quest_type = dynamic_data.quest_type or nil
			local quest_params = dynamic_data.quest_params or {}
			local quest_reward = dynamic_data.quest_reward or nil
			local quest_progress = dynamic_data.quest_progress or 0
			local quest_progressneeded = dynamic_data.quest_progressneeded or 0
			local quest_complete = dynamic_data.quest_complete or false

			if quest_type then
				---@type string|table
				local tooltip = ''

				if quest_complete and quest_reward then
					tooltip = { 'pirates.gui_questframe_complete_tooltip', quest_type }
					flow1.quest_label_1.caption = { 'pirates.gui_questframe' }
					flow1.quest_label_1.style.font_color = GuiCommon.achieved_font_color
					flow1.quest_label_2.visible = true
					flow1.quest_label_3.visible = false
					flow1.quest_label_4.visible = false
					flow1.quest_label_2.caption = quest_reward.display_amount .. ' ' .. quest_reward.display_sprite
				elseif quest_reward then
					if quest_progress < quest_progressneeded then
						flow1.quest_label_1.caption = { 'pirates.gui_questframe' }
						flow1.quest_label_1.style.font_color = GuiCommon.bold_font_color
						flow1.quest_label_2.visible = true
						flow1.quest_label_3.visible = true
						flow1.quest_label_4.visible = true
						-- defaults, to be overwritten:
						flow1.quest_label_2.caption = string.format('%s ', Quest.quest_icons[quest_type])
						flow1.quest_label_3.caption = string.format('%.0f/%.0f', quest_progress, quest_progressneeded)
						flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
						flow1.quest_label_4.caption = string.format(' for %s', quest_reward.display_sprite)
						flow1.quest_label_4.style.font_color = Common.default_font_color
					end

					if quest_type == Quest.enum.TIME then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_time' } end

						if quest_progress >= 0 then
							flow1.quest_label_3.caption = string.format('%.0fm%.0fs', Math.floor(quest_progress / 60), quest_progress % 60)
							if active_eta then
								if active_eta < quest_progress - 35 then --35 is roughly the number of seconds between charge and launch
									flow1.quest_label_3.style.font_color = GuiCommon.sufficient_font_color
								else
									flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
								end
							else
								if bools.charged_bool and quest_progress > 35 then
									flow1.quest_label_3.style.font_color = GuiCommon.sufficient_font_color
								else
									flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
								end
							end
						else
							flow1.quest_label_3.caption = { 'pirates.gui_questframe_fail' }
							flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
						end
					elseif quest_type == Quest.enum.WORMS then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_worms' } end
					elseif quest_type == Quest.enum.FIND then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_find' } end
					elseif quest_type == Quest.enum.RESOURCEFLOW then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_resourceflow' } end

						-- out of date:
						if quest_progressneeded / 60 % 1 == 0 then
							flow1.quest_label_2.caption = string.format('%s %.1f/%.0f /s', '[item=' .. quest_params.item .. ']', quest_progress / 60, quest_progressneeded / 60)
							flow1.quest_label_3.caption = string.format(' for %s', quest_reward.display_sprite)
						else
							flow1.quest_label_2.caption = string.format('%s %.1f/%.1f /s', '[item=' .. quest_params.item .. ']', quest_progress / 60, quest_progressneeded / 60)
							flow1.quest_label_3.caption = string.format(' for %s', quest_reward.display_sprite)
						end
					elseif quest_type == Quest.enum.RESOURCECOUNT then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_resourcecount' } end

						flow1.quest_label_2.caption = string.format('%s ', '[item=' .. quest_params.item .. ']')
					elseif quest_type == Quest.enum.NODAMAGE then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_nodamage' } end

						if bools.approaching_bool or (dynamic_data.rocketsilos and dynamic_data.rocketsilos[1] and dynamic_data.rocketsilos[1].valid and dynamic_data.rocketsilohp == dynamic_data.rocketsilomaxhp) then
							flow1.quest_label_3.caption = { 'pirates.gui_questframe_ok' }
							flow1.quest_label_3.style.font_color = GuiCommon.sufficient_font_color
						else
							flow1.quest_label_3.caption = { 'pirates.gui_questframe_fail' }
							flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
						end
					elseif quest_type == Quest.enum.FISH then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_fish' } end
					elseif quest_type == Quest.enum.COMPILATRON then
						if tooltip == '' then tooltip = { 'pirates.gui_questframe_compilatron' } end
					end
				end

				flow1.tooltip = tooltip
				flow1.quest_label_1.tooltip = tooltip
				flow1.quest_label_2.tooltip = tooltip
				flow1.quest_label_3.tooltip = tooltip
				flow1.quest_label_4.tooltip = tooltip
			end
		else
			flow1.visible = false
		end
	end
end

-- local function create_gui_2()

-- end

-- Event.add(defines.events.on_player_joined_game, create_gui_2)


function Public.update_gui(player)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local flow1, flow2

	local pirates_flow = player.gui.top

	if not pirates_flow.info_piratebutton_frame then create_gui(player) end


	flow1 = pirates_flow.crew_piratebutton_frame.crew_piratebutton

	if Common.is_id_valid(memory.id) then
		flow1.tooltip = { 'pirates.gui_crew_tooltip_1' }
		flow1.mouse_button_filter = { 'left', 'right' }
	else
		flow1.tooltip = { 'pirates.gui_crew_tooltip_2' }
		flow1.mouse_button_filter = { 'middle' } --hack to avoid press visual
		if player.gui.screen['crew_piratewindow'] then
			player.gui.screen['crew_piratewindow'].destroy()
		end
	end

	flow1 = pirates_flow.classes_piratebutton_frame.classes_piratebutton

	if Common.is_id_valid(memory.id) then
		flow1.tooltip = { 'pirates.gui_classes_tooltip_1' }
		flow1.mouse_button_filter = { 'left', 'right' }
	else
		flow1.tooltip = { 'pirates.gui_classes_tooltip_2' }
		flow1.mouse_button_filter = { 'middle' } --hack to avoid press visual
		if player.gui.screen['classes_piratewindow'] then
			player.gui.screen['classes_piratewindow'].destroy()
		end
	end

	if GuiEvo.full_update then GuiEvo.full_update(player) end
	if GuiProgress.regular_update then GuiProgress.regular_update(player) end --moved to event
	if GuiRuns.full_update then GuiRuns.full_update(player) end
	if GuiCrew.full_update then GuiCrew.full_update(player) end
	if GuiClasses.full_update then GuiClasses.full_update(player) end
	if GuiMinimap.full_update then GuiMinimap.full_update(player) end
	if GuiInfo.full_update then GuiInfo.full_update(player) end

	-- local lives = memory.lives or 1
	-- local button = pirates_flow.lives_piratebutton_frame.lives_piratebutton
	-- if lives == 1 then
	-- 	button.sprite = 'item/effectivity-module'
	-- 	button.number = 1
	-- elseif lives == 2 then
	-- 	button.sprite = 'item/effectivity-module-2'
	-- 	button.number = 2
	-- elseif lives == 3 then
	-- 	button.sprite = 'item/effectivity-module-3'
	-- 	button.number = 3
	-- end

	flow1 = pirates_flow.fuel_flow
	-- flow1 = pirates_flow.fuel_piratebutton_flow_1

	local tooltip = { 'pirates.fuel_tooltip', Math.floor(memory.stored_fuel or 0) }
	flow1.tooltip = tooltip
	-- flow1.fuel_piratebutton.tooltip = {'pirates.fuel_tooltip', Math.floor(memory.stored_fuel or 0)}


	flow2 = flow1
	-- flow2 = flow1.fuel_piratebutton_flow_2

	flow2.fuel_label_1.caption = Utils.bignumber_abbrevform(memory.stored_fuel or 0) .. '[item=coal]'
	flow2.fuel_label_2.caption = Utils.negative_rate_abbrevform(memory.fuel_depletion_rate_memoized or 0)
	local color_scale = Math.clamp(0, 1, (-(memory.fuel_depletion_rate_memoized or 0)) / 30)
	flow2.fuel_label_2.style.font_color = {
		r = GuiCommon.fuel_color_1.r * (1 - color_scale) + GuiCommon.fuel_color_2.r * color_scale,
		g = GuiCommon.fuel_color_1.g * (1 - color_scale) + GuiCommon.fuel_color_2.g * color_scale,
		b = GuiCommon.fuel_color_1.b * (1 - color_scale) + GuiCommon.fuel_color_2.b * color_scale,
	}
	flow2.fuel_label_0.tooltip = tooltip
	flow2.fuel_label_1.tooltip = tooltip
	flow2.fuel_label_2.tooltip = tooltip


	flow1 = pirates_flow.progress_piratebutton_frame.progress_piratebutton

	flow1.number = (memory.overworldx or 0)
	flow1.tooltip = { 'pirates.gui_progress_tooltip', memory.overworldx or 0, CoreData.victory_x }
	-- pirates_flow.destination_piratebutton_frame.destination_piratebutton.number = memory.destinationsvisited_indices and #memory.destinationsvisited_indices or 0


	--== State-checking bools ==--

	-- this is nonsense to temporarily avoid function complexity for luacheck:
	local bools = GuiCommon.player_and_crew_state_bools(player)



	--== Update Gui ==--


	flow1 = pirates_flow.fuel_flow
	-- flow1 = pirates_flow.fuel_piratebutton_flow_1

	if memory.crewstatus == nil then
		flow1.visible = false
	else
		flow1.visible = true
	end


	flow1 = pirates_flow.etaframe_piratebutton_flow_1
	Public.process_etaframe_update(player, flow1, bools)



	-- flow1 = pirates_flow.cost_frame
	-- if flow1 then
	-- 	if bools.cost_bool then
	-- 		flow1.visible = true

	-- 		-- local costs = destination.static_params.base_cost_to_undock

	-- 		-- for i = 1, #CoreData.cost_items do
	-- 		-- 	local item_name = CoreData.cost_items[i].name

	-- 		-- 	if costs[item_name] then
	-- 		-- 		local stored = (memory.boat.stored_resources and memory.boat.stored_resources[item_name]) or 0
	-- 		-- 		flow1.cost_table['cost_' .. i].sprite = CoreData.cost_items[i].sprite_name
	-- 		-- 		flow1.cost_table['cost_' .. i].number = Math.max(costs[item_name] - stored, 0)
	-- 		-- 		flow1.cost_table['cost_' .. i].tooltip = CoreData.cost_items[i].display_name
	-- 		-- 		flow1.cost_table['cost_' .. i].visible = true
	-- 		-- 	else
	-- 		-- 		flow1.cost_table['cost_' .. i].visible = false
	-- 		-- 	end
	-- 		-- end

	-- 		-- local total_rage = time_rage + silo_rage

	-- 		-- flow1.rage_label_2.caption = total_rage .. '/10'
	-- 		-- if total_rage <= 4 then
	-- 		-- 	flow1.rage_label_2.style.font_color = GuiCommon.rage_font_color_1
	-- 		-- 	flow1.rage_label_2.style.font = 'default-large'
	-- 		-- elseif total_rage <= 7 then
	-- 		-- 	flow1.rage_label_2.style.font_color = GuiCommon.rage_font_color_2
	-- 		-- 	flow1.rage_label_2.style.font = 'default-large-semibold'
	-- 		-- else
	-- 		-- 	flow1.rage_label_2.style.font_color = GuiCommon.rage_font_color_3
	-- 		-- 	flow1.rage_label_2.style.font = 'default-dialog-button'
	-- 		-- end

	-- 		-- -- flow1.rage_table.bar_1.value = time_rage >= 1 and 1 or 0
	-- 		-- -- flow1.rage_table.bar_2.value = time_rage >= 2 and 1 or 0
	-- 		-- -- flow1.rage_table.bar_3.value = time_rage >= 3 and 1 or 0
	-- 		-- -- flow1.rage_table.bar_4.value = time_rage >= 4 and 1 or 0
	-- 		-- -- flow1.rage_table.bar_5.value = silo_rage >= 1 and 1 or 0
	-- 		-- -- flow1.rage_table.bar_6.value = silo_rage >= 2 and 1 or 0
	-- 	else
	-- 		flow1.visible = false
	-- 	end
	-- end


	-- flow1 = player.gui.screen.pirates_undock_shortcut_button

	-- if flow1 then
	-- 	flow1.location = GuiCommon.default_window_positions.undock_shortcut_button
	-- 	if bools.captain_bool and bools.landed_bool and (not memory.captain_acceptance_timer) then
	-- 		flow1.visible = true
	-- 		local enabled = Common.query_can_pay_cost_to_leave()
	-- 		flow1.enabled = enabled
	-- 		if enabled then
	-- 			flow1.tooltip = ''
	-- 		else
	-- 			flow1.tooltip = 'Store more resources in the captain\'s cabin before leaving.'
	-- 		end
	-- 	elseif bools.captain_bool and destination and destination.type and destination.type == Surfaces.enum.DOCK and (not (memory.boat.state and memory.boat.state == Boats.enum_state.LEAVING_DOCK)) then
	-- 		flow1.visible = true
	-- 		flow1.enabled = memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.DOCKED
	-- 		flow1.tooltip = ''
	-- 	else
	-- 		flow1.visible = false
	-- 	end

	-- 	if flow1.visible then
	-- 		if (not memory.undock_shortcut_are_you_sure_data) then memory.undock_shortcut_are_you_sure_data = {} end
	-- 		if memory.undock_shortcut_are_you_sure_data[player.index] and memory.undock_shortcut_are_you_sure_data[player.index] > game.tick - 60 * 4 then
	-- 			flow1.caption = 'Are you sure?'
	-- 		else
	-- 			flow1.caption = 'Undock'
	-- 		end
	-- 	end
	-- end



	local flowsilo = pirates_flow.silo_frame
	local flowquest = pirates_flow.quest_frame
	Public.process_siloframe_and_questframe_updates(flowsilo, flowquest, bools)


	flow1 = pirates_flow.covering_line_frame

	if flow1 then
		-- if not bools.eta_bool and not bools.retreating_bool and not bools.quest_bool and not bools.silo_bool and not bools.atsea_loading_bool and not bools.leave_anytime_bool and not bools.cost_bool and not bools.approaching_dock_bool and not bools.leaving_dock_bool then
		if not (bools.eta_bool or bools.retreating_bool or bools.quest_bool or bools.silo_bool or bools.atsea_loading_bool or bools.leave_anytime_bool or bools.cost_bool or bools.approaching_dock_bool or bools.leaving_dock_bool or bools.atsea_sailing_bool or bools.atsea_waiting_bool) then
			flow1.visible = true
		else
			flow1.visible = false
		end
	end


	flow1 = pirates_flow.minimap_piratebutton_frame

	if flow1 then
		if bools.in_hold_bool or bools.in_cabin_bool then
			flow1.visible = true
		else
			flow1.visible = false
		end
	end


	flow1 = player.gui.screen.pirates_spontaneous_camera

	if not flow1 then --comfy panel might possibly destroy this, so this puts it back
		flow1 =
			player.gui.screen.add(
				{
					type = 'camera',
					name = 'pirates_spontaneous_camera',
					position = { x = 0, y = 0 },
				}
			)
		flow1.visible = false
		flow1.style.margin = 8
	end

	if flow1 then
		flow1.visible = false
		flow1.location = { x = 8, y = 48 }
		if bools.on_deck_standing_near_loco_bool then
			flow1.visible = true
			flow1.surface_index = Hold.get_hold_surface(1).index
			flow1.zoom = 0.182
			flow1.style.minimal_height = 292
			flow1.style.minimal_width = 540
			flow1.position = { x = 0, y = -2 }
		elseif bools.on_deck_standing_near_cabin_bool then
			flow1.visible = true
			flow1.surface_index = Cabin.get_cabin_surface().index
			flow1.zoom = 0.468
			flow1.style.minimal_height = 400
			flow1.style.minimal_width = 280
			flow1.position = { x = 0, y = -1 }
		elseif bools.on_deck_standing_near_crowsnest_bool then
			flow1.visible = true
			flow1.surface_index = Crowsnest.get_crowsnest_surface().index
			flow1.zoom = 0.21
			flow1.style.minimal_height = 384
			flow1.style.minimal_width = 384
			flow1.position = { x = memory.overworldx, y = memory.overworldy }
		elseif bools.in_crowsnest_bool then
			flow1.visible = true
			flow1.surface_index = game.surfaces[memory.boat.surface_name].index
			flow1.zoom = 0.09
			flow1.style.minimal_height = 312
			flow1.style.minimal_width = 312

			local position = memory.boat.position
			if (destination and destination.type and destination.type == Surfaces.enum.ISLAND and memory.boat.surface_name and memory.boat.surface_name == destination.surface_name and destination.static_params and destination.static_params.boat_starting_xposition) then
				-- nicer viewing position:
				position = { x = destination.static_params.boat_starting_xposition + 50, y = destination.static_params.boat_starting_yposition or 0 }
			end
			flow1.position = position
		end
	end
end

-- ATTENTION: Giving same names to GUI elements can cause issues, because click events are dispatched to all GUI windows!
local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end

	local player = game.players[event.element.player_index]

	local crew_id = Common.get_id_from_force_name(player.force.name)
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

	if event.element.name and event.element.name == 'etaframe_piratebutton' then
		if (memory.boat.state == Boats.enum_state.DOCKED or memory.boat.state == Boats.enum_state.LANDED) then
			if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
				if (not memory.undock_shortcut_are_you_sure_data) then memory.undock_shortcut_are_you_sure_data = {} end
				if memory.undock_shortcut_are_you_sure_data[player.index] and memory.undock_shortcut_are_you_sure_data[player.index] > game.tick - 60 * 4 then
					if memory.boat.state == Boats.enum_state.DOCKED then
						Progression.undock_from_dock(true)
					elseif memory.boat.state == Boats.enum_state.LANDED then
						Progression.try_retreat_from_island(player, true)
					end
				else
					memory.undock_shortcut_are_you_sure_data[player.index] = game.tick
				end
			end
		elseif memory.boat.state == Boats.enum_state.ATSEA_WAITING_TO_SAIL then
			if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
				local destination_index = memory.mapbeingloadeddestination_index

				Progression.progress_to_destination(destination_index)
				memory.loadingticks = 0
			end
		elseif memory.boat.state == Boats.enum_state.ATSEA_VICTORIOUS then
			if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
				memory.boat.state = Boats.enum_state.ATSEA_SAILING

				local force = memory.force
				if not (force and force.valid) then return end
				if memory.victory_continue_message then
					memory.victory_continue_message = false
					Common.notify_force(force, { 'pirates.crew_continue_on_freeplay' }, CoreData.colors.notify_victory)
				end
			end
		end
	elseif string.sub(event.element.name, -13, -1) and string.sub(event.element.name, -13, -1) == '_piratebutton' then
		local name = string.sub(event.element.name, 1, -14)
		if Public[name] then
			Public[name].toggle_window(player)
			Public[name].full_update(player)
		end
		-- elseif event.element.name == 'fuel_label_1' or event.element.name == 'fuel_label_2' then
		-- 	Public.fuel.toggle_window(player)
		-- 	Public.fuel.full_update(player)
	else
		if GuiWelcome.handle_click then GuiWelcome.handle_click(event) end
		if GuiRuns.click then GuiRuns.click(event) end
		if GuiCrew.click then GuiCrew.click(event) end
		if GuiClasses.click then GuiClasses.click(event) end
		if GuiMinimap.click then GuiMinimap.click(event) end
		if GuiInfo.click then GuiInfo.click(event) end
	end
end

local function on_gui_location_changed(event)
	if (not event and event.element and event.element.valid) then return end

	if string.sub(event.element.name, -13, -1) and string.sub(event.element.name, -13, -1) == '_piratewindow' then
		local name = string.sub(event.element.name, 1, -14)
		local player = game.players[event.element.player_index]

		GuiCommon.update_gui_memory(player, name, 'position', event.element.location)
	end
end


local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_gui_location_changed, on_gui_location_changed)

return Public
