
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local GuiEvo = require 'maps.pirates.gui.evo'
local GuiProgress = require 'maps.pirates.gui.progress'
local GuiRuns = require 'maps.pirates.gui.runs'
local GuiCrew = require 'maps.pirates.gui.crew'
local GuiShop = require 'maps.pirates.gui.shop'
local GuiMinimap = require 'maps.pirates.gui.minimap'
local GuiInfo = require 'maps.pirates.gui.info'
local Quest = require 'maps.pirates.quest'
local Balance = require 'maps.pirates.balance'
local inspect = require 'utils.inspect'.inspect
local GuiCommon = require 'maps.pirates.gui.common'
local Boats = require 'maps.pirates.structures.boats.boats'
local Hold = require 'maps.pirates.surfaces.hold'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Progression = require 'maps.pirates.progression'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Roles = require 'maps.pirates.roles.roles'

local ComfyPanel = require 'comfy_panel.main'


local Public = {}
Public.progress = require 'maps.pirates.gui.progress'
Public.runs = require 'maps.pirates.gui.runs'
Public.crew = require 'maps.pirates.gui.crew'
Public.fuel = require 'maps.pirates.gui.shop'
Public.minimap = require 'maps.pirates.gui.minimap'
Public.info = require 'maps.pirates.gui.info'
Public.color = require 'maps.pirates.gui.color'





local function create_gui(player)
	local flowleft, flow1, flow2, flow3, flow4, tooltip

	flow1 = player.gui.top

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'info_piratebutton')
	flow2.caption = '?'
	flow2.style.font = 'debug'
	flow2.tooltip = 'Notes and updates on Pirate Ship'
	flow2.style.font_color = {r=1, g=1, b=1}
	flow2.style.hovered_font_color = {r=1, g=1, b=1}
	flow2.style.clicked_font_color = {r=1, g=1, b=1}
	flow2.parent.style.left_padding = -6

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'runs_piratebutton', 80)
	flow2.caption = 'Play'
	flow2.tooltip = 'Play\n\nView the ongoing runs, and make proposals.'
	flow2.style.font = 'debug'
	flow2.style.font_color = {r=1, g=1, b=1}
	flow2.style.hovered_font_color = {r=1, g=1, b=1}
	flow2.style.clicked_font_color = {r=1, g=1, b=1}
	flow2.parent.style.width = 73
	flow2.parent.style.left_padding = -6

	-- optional use of left gui:
	-- flowleft = player.gui.left
	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flowleft, 'crew_piratebutton')
	-- flow2.sprite = 'utility/spawn_flag'
	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'crew_piratebutton')
	flow2.sprite = 'utility/spawn_flag'

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
	flow2.tooltip = 'Progress\n\nTravel ' .. CoreData.victory_x .. ' leagues = victory.'
	flow2.sprite = 'item/rail'

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'evo_piratebutton')
	flow2.sprite = 'entity/small-biter'
	flow2.mouse_button_filter = {'middle'} --hack to avoid press visual
	flow2.show_percent_for_small_numbers = true

	flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'minimap_piratebutton')
	flow2.tooltip = 'View the outside world.'
	flow2.sprite = 'utility/map'

	-- flow2 = GuiCommon.flow_add_floating_sprite_button(flow1, 'shop_piratebutton')
	-- flow2.tooltip = "Coal/Officer's Shop\n\nThe captain and their officers are authorised to spend coal in the shop."
	-- flow2.sprite = 'item/coal'



	flow2 = GuiCommon.flow_add_floating_button(flow1, 'fuel_piratebutton')
	-- flow2.style.right_padding = -100

	flow3 = flow2.add({
		name = 'fuel_label_1',
		type = 'label',
		caption = ''
	})
	flow3.style.font = 'default-large-semibold'
	flow3.style.font_color = GuiCommon.bold_font_color
	-- flow3.style.font_color = GuiCommon.bold_font_color
	-- flow4.style.top_margin = -36
	-- flow4.style.left_margin = -100
	-- flow3.style.horizontal_align = 'center'
	-- flow4.style.left_padding = -5
	flow3.style.left_margin = -1

	flow3 = flow2.add({
		name = 'fuel_label_2',
		type = 'label',
		caption = ''
	})
	flow3.style.font = 'default-large'
	
	flow3.style.left_margin = 6





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

	flow3 = flow2.add({type = 'table', name = 'cost_table', column_count = 5})
	for i = 1, 5 do
		flow4 = flow3.add({type = 'sprite-button', name = 'cost_' .. i, number = 0})
		-- flow4.mouse_button_filter = {'middle'}
		flow4.enabled = false
		flow4.style.top_margin = -6
		flow4.style.right_margin = -6
		flow4.style.maximal_height = 38
		flow4.visible = false
	end
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
	flow3.style.font_color = GuiCommon.bold_font_color
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
			position = {x=0,y=0},
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




function Public.update_gui(player)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local flow1, flow1b, flow2, flow3

	local pirates_flow = player.gui.top

	if not pirates_flow.info_piratebutton_frame then create_gui(player) end
	
	if memory.id and memory.id ~= 0 then
		pirates_flow.crew_piratebutton_frame.crew_piratebutton.tooltip = 'Crew\n\nPerform crew actions.'
		pirates_flow.crew_piratebutton_frame.crew_piratebutton.mouse_button_filter = {'left','right'}
	else
		pirates_flow.crew_piratebutton_frame.crew_piratebutton.tooltip = 'Crew\n\nYou\'re a free agent, so there\'s nothing to do here.'
		pirates_flow.crew_piratebutton_frame.crew_piratebutton.mouse_button_filter = {'middle'} --hack to avoid press visual
		if player.gui.screen['crew_piratewindow'] then
			player.gui.screen['crew_piratewindow'].destroy()
		end
	end
	
	GuiEvo.update(player)
	GuiProgress.update(player)
	GuiRuns.update(player)
	GuiCrew.update(player)
	GuiShop.update(player)
	GuiMinimap.update(player)
	GuiInfo.update(player)

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

	pirates_flow.fuel_piratebutton_flow_1.fuel_piratebutton_flow_2.fuel_label_1.caption = '[item=coal] ' .. Utils.bignumber_abbrevform(memory.stored_fuel or 0)
	pirates_flow.fuel_piratebutton_flow_1.fuel_piratebutton_flow_2.fuel_label_2.caption = Utils.negative_rate_abbrevform(Progression.fuel_depletion_rate() or 0)
	local color_scale = Math.max(Math.min((- (Progression.fuel_depletion_rate() or 0))/35, 1),0)
	pirates_flow.fuel_piratebutton_flow_1.fuel_piratebutton_flow_2.fuel_label_2.style.font_color = {
		r = GuiCommon.fuel_color_1.r * (1-color_scale) + GuiCommon.fuel_color_2.r * color_scale,
		g = GuiCommon.fuel_color_1.g * (1-color_scale) + GuiCommon.fuel_color_2.g * color_scale,
		b = GuiCommon.fuel_color_1.b * (1-color_scale) + GuiCommon.fuel_color_2.b * color_scale,
	}



	pirates_flow.fuel_piratebutton_flow_1.fuel_piratebutton.tooltip = {'pirates.fuel_tooltip', Math.floor(memory.stored_fuel or 0)}

	pirates_flow.progress_piratebutton_frame.progress_piratebutton.number = (memory.overworldx or 0)
	-- pirates_flow.destination_piratebutton_frame.destination_piratebutton.number = memory.destinationsvisited_indices and #memory.destinationsvisited_indices or 0


	--== State-checking bools ==--

	local in_crowsnest_bool = string.sub(player.surface.name, 9, 17) == 'Crowsnest'
	local in_hold_bool = string.sub(player.surface.name, 9, 12) == 'Hold'
	local in_cabin_bool = string.sub(player.surface.name, 9, 13) == 'Cabin'

	local onmap_bool = destination.surface_name and (player.surface.name == destination.surface_name or (memory.boat and memory.boat.surface_name and
	memory.boat.surface_name == destination.surface_name and (in_crowsnest_bool or in_hold_bool or in_cabin_bool)
	))

	local eta_bool = destination.dynamic_data.time_remaining and destination.dynamic_data.time_remaining > 0 and onmap_bool
	local retreating_bool = memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.RETREATING and onmap_bool
	local approaching_bool = memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.APPROACHING
	local atsea_sailing_bool = memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.ATSEA_SAILING
	local landed_bool = memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.LANDED
	local quest_bool = (destination.dynamic_data.quest_type ~= nil) and onmap_bool
	local silo_bool = destination.dynamic_data.rocketsilos and destination.dynamic_data.rocketsilos[1] and destination.dynamic_data.rocketsilos[1].valid and onmap_bool
	local charged_bool = destination.dynamic_data.silocharged
	local launched_bool = destination.dynamic_data.rocketlaunched

	local captain_bool = (memory.playerindex_captain and player.index == memory.playerindex_captain)

	local atsea_loading_bool = memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP and memory.loadingticks

	local character_on_deck_bool = player.character and player.character.position and memory.boat and memory.boat.position and memory.boat.surface_name and player.surface.name and player.surface.name == memory.boat.surface_name

	local on_deck_standing_near_loco_bool = character_on_deck_bool and Boats.get_scope(memory.boat) and Math.distance(player.character.position, Math.vector_sum(memory.boat.position, Boats.get_scope(memory.boat).Data.loco_pos)) < 3
	local on_deck_standing_near_cabin_bool = character_on_deck_bool and Boats.get_scope(memory.boat) and Math.distance(player.character.position, Math.vector_sum(memory.boat.position, Boats.get_scope(memory.boat).Data.cabin_car)) < 2.5
	local on_deck_standing_near_crowsnest_bool = character_on_deck_bool and Boats.get_scope(memory.boat) and Math.distance(player.character.position, Math.vector_sum(memory.boat.position, Boats.get_scope(memory.boat).Data.crowsnest_center)) < 2.7

	local cost_bool = destination.static_params.cost_to_leave and (not atsea_sailing_bool) and (not retreating_bool)

	local approaching_dock_bool = destination.type == Surfaces.enum.DOCK and memory.boat.state == Boats.enum_state.APPROACHING
	local leaving_dock_bool = destination.type == Surfaces.enum.DOCK and memory.boat.state == Boats.enum_state.LEAVING_DOCK

	local leave_anytime_bool = (landed_bool and not (eta_bool or cost_bool)) 

	--== Update Gui ==--

	flow1 = pirates_flow.fuel_piratebutton_flow_1
	if memory.crewstatus == nil then
		flow1.visible = false
	else
		flow1.visible = true
	end


	flow1 = pirates_flow.etaframe_piratebutton_flow_1

	if flow1 then
		if cost_bool or atsea_loading_bool or eta_bool or retreating_bool or leave_anytime_bool then
			flow1.visible = true
			local tooltip = ''

			flow2 = flow1.etaframe_piratebutton_flow_2

			flow2.etaframe_label_1.visible = false --start off
			flow2.etaframe_label_2.visible = false --start off
			flow2.etaframe_label_3.visible = false --start off
			flow2.cost_table.visible = false --start off

			if retreating_bool then
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_2.visible = false
		
				tooltip = 'Probably time to board...'
	
				flow2.etaframe_label_1.caption = 'RETURN TO SHIP'
	
			elseif eta_bool then
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_2.visible = true
		
				tooltip = {'pirates.auto_undock_tooltip'}
		
				local passive_eta = destination.dynamic_data.time_remaining
		
				flow2.etaframe_label_1.caption = 'Auto-undock:'
				flow2.etaframe_label_2.caption = Utils.standard_string_form_of_time_in_seconds(passive_eta)
	
			elseif atsea_loading_bool then
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_2.visible = true
		
				tooltip = {'pirates.atsea_loading_tooltip'}

				local total = Common.map_loading_ticks_atsea
				if destination.type == Surfaces.enum.DOCK then
					total = Common.map_loading_ticks_atsea_dock
				end
		
				local eta_ticks = total + (memory.extra_time_at_sea or 0) - memory.loadingticks
		
				flow2.etaframe_label_1.caption = 'Arriving in'
				flow2.etaframe_label_2.caption = Utils.standard_string_form_of_time_in_seconds(eta_ticks / 60)
			elseif leave_anytime_bool then
				flow2.etaframe_label_1.visible = true
				flow2.etaframe_label_2.visible = true
		
				tooltip = {'pirates.leave_anytime_tooltip'}
		
				flow2.etaframe_label_1.caption = 'Undock:'
				flow2.etaframe_label_2.caption = 'Anytime'
			end

			if cost_bool then
				flow2.etaframe_label_3.visible = true
				flow2.cost_table.visible = true

				if flow2.etaframe_label_2.visible then
				flow2.etaframe_label_2.caption = flow2.etaframe_label_2.caption .. '.'
				end
				
				local caption
				if atsea_loading_bool then
					flow2.etaframe_label_3.caption = 'Next escape cost:'
					tooltip = {'pirates.resources_needed_tooltip_1'}
				elseif (not eta_bool) then
					flow2.etaframe_label_3.visible = false
					flow2.etaframe_label_1.visible = true
					flow2.etaframe_label_1.caption = 'To escape, store'
					tooltip = {'pirates.resources_needed_tooltip_3'}
				else
					flow2.etaframe_label_3.caption = 'Or store'
					tooltip = {'pirates.resources_needed_tooltip_2'}
				end

				flow2.cost_table.visible = true
				local costs = destination.static_params.cost_to_leave
	
				for i = 1, #CoreData.cost_items do
					local item_name = CoreData.cost_items[i].name
		
					if costs[item_name] then
						local stored = (memory.boat.stored_resources and memory.boat.stored_resources[item_name]) or 0
						flow2.cost_table['cost_' .. i].sprite = CoreData.cost_items[i].sprite_name
						if atsea_loading_bool then
							flow2.cost_table['cost_' .. i].number = costs[item_name]
						else --subtract off the amount we've stored
							flow2.cost_table['cost_' .. i].number = Math.max(costs[item_name] - stored, 0)
						end
						flow2.cost_table['cost_' .. i].tooltip = CoreData.cost_items[i].display_name
						flow2.cost_table['cost_' .. i].visible = true
					else
						flow2.cost_table['cost_' .. i].visible = false
					end
				end
			end

			flow1.etaframe_piratebutton.tooltip = tooltip
			flow2.tooltip = tooltip

			if captain_bool and (not retreating_bool) and (leave_anytime_bool or eta_bool or (cost_bool and (not atsea_loading_bool))) then
				flow1.etaframe_piratebutton.mouse_button_filter = {'left'}
				if memory.undock_shortcut_are_you_sure_data and memory.undock_shortcut_are_you_sure_data[player.index] and memory.undock_shortcut_are_you_sure_data[player.index] > game.tick - 60 * 4 then
					flow2.etaframe_label_1.visible = true
					flow2.etaframe_label_1.caption = 'Undock — Are you sure?'
					flow2.etaframe_label_2.visible = false
					flow2.etaframe_label_3.visible = false
				end
			else
				flow1.etaframe_piratebutton.mouse_button_filter = {'middle'} --hack to avoid press visual
			end
		else
			flow1.visible = false
		end
	end




	-- flow1 = pirates_flow.cost_frame
	-- if flow1 then
	-- 	if cost_bool then
	-- 		flow1.visible = true
	
	-- 		-- local costs = destination.static_params.cost_to_leave
	
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
	-- 	if captain_bool and landed_bool and (not memory.captain_acceptance_timer) then
	-- 		flow1.visible = true
	-- 		local enabled = Common.query_sufficient_resources_to_leave()
	-- 		flow1.enabled = enabled
	-- 		if enabled then
	-- 			flow1.tooltip = ''
	-- 		else
	-- 			flow1.tooltip = 'Store more resources in the captain\'s cabin before leaving.'
	-- 		end
	-- 	elseif captain_bool and destination and destination.type and destination.type == Surfaces.enum.DOCK and (not (memory.boat.state and memory.boat.state == Boats.enum_state.LEAVING_DOCK)) then
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



	flow1 = pirates_flow.silo_frame

	local active_eta
	if flow1 then
	
		if silo_bool then
			flow1.visible = true
	
			if charged_bool then
	
				if launched_bool then
					local tooltip = 'The rocket has launched, and this is the reward.'
					flow1.tooltip = tooltip
					flow1.silo_label_1.tooltip = tooltip
	
					flow1.silo_label_2.visible = false
					flow1.silo_progressbar.visible = false
	
					-- flow1.silo_label_1.caption = string.format('[achievement=there-is-no-spoon]: +%.0f[item=sulfur]', destination.dynamic_data.rocketcoalreward)
					flow1.silo_label_1.caption = string.format('Launch: %.0f[item=coal] , ' .. Balance.rocket_launch_coin_reward .. '[item=coin]', destination.dynamic_data.rocketcoalreward)
					flow1.silo_label_1.style.font_color = GuiCommon.achieved_font_color
				else
					local tooltip = 'The rocket is launching...'
					flow1.tooltip = tooltip
					flow1.silo_label_1.tooltip = tooltip
					flow1.silo_progressbar.tooltip = tooltip
	
					flow1.silo_label_1.caption = 'Charge:'
					flow1.silo_label_1.style.font_color = GuiCommon.bold_font_color
					flow1.silo_label_2.visible = false
					flow1.silo_progressbar.visible = true
		
					flow1.silo_progressbar.value = 1
				end
	
			else
				flow1.silo_label_1.caption = 'Charge:'
				flow1.silo_label_1.style.font_color = GuiCommon.bold_font_color
				flow1.silo_label_2.visible = true
				flow1.silo_progressbar.visible = true
	
				local consumed = destination.dynamic_data.rocketsiloenergyconsumed
				local needed = destination.dynamic_data.rocketsiloenergyneeded
				local recent = (destination.dynamic_data.rocketsiloenergyconsumedwithinlasthalfsecond * 2)
		
				flow1.silo_progressbar.value = consumed/needed
		
				local tooltip = string.format('Rocket silo charge\n\nCharge the silo to launch a rocket, gaining both coins and fuel.\n\nCurrent charge: %.1f', consumed / 1000000000) .. '/' .. Math.floor(needed / 100000000)/10 .. ' GJ'
				flow1.tooltip = tooltip
				flow1.silo_label_1.tooltip = tooltip
				flow1.silo_label_2.tooltip = tooltip
				flow1.silo_progressbar.tooltip = tooltip
		
				if recent ~= 0 then
					active_eta = (needed - consumed) / recent
					flow1.silo_label_2.caption = Utils.standard_string_form_of_time_in_seconds(active_eta)
					if active_eta >= destination.dynamic_data.time_remaining then
						flow1.silo_label_2.style.font_color = GuiCommon.insufficient_font_color
					else
						flow1.silo_label_2.style.font_color = GuiCommon.sufficient_font_color
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


	flow1 = pirates_flow.quest_frame

	if flow1 then
		if quest_bool then
			flow1.visible = true
	
			local quest_type = destination.dynamic_data.quest_type or nil
			local quest_params = destination.dynamic_data.quest_params or {}
			local quest_reward = destination.dynamic_data.quest_reward or nil
			local quest_progress = destination.dynamic_data.quest_progress or 0
			local quest_progressneeded = destination.dynamic_data.quest_progressneeded or 0
			local quest_complete =  destination.dynamic_data.quest_complete or false
	
			if quest_type then
	
				local tooltip = ''
	
				if quest_complete then
					tooltip = 'The quest is complete, and this is the reward.'
					flow1.quest_label_1.caption = 'Quest: ' .. quest_reward.display_amount .. ' ' .. quest_reward.display_sprite
					flow1.quest_label_2.visible = false
					flow1.quest_label_3.visible = false
					flow1.quest_label_4.visible = false
				elseif quest_progress < quest_progressneeded then
					flow1.quest_label_1.caption = 'Quest:'
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
					if tooltip == '' then tooltip = 'Quest: Time\n\nLaunch a rocket before the countdown completes for a bonus.' end
	
					if quest_progress >= 0 then
						flow1.quest_label_3.caption = string.format('%.0fm%.0fs', Math.floor(quest_progress / 60), quest_progress % 60)
						if active_eta then
							if active_eta < quest_progress - 35 then --35 is roughly the number of seconds between charge and launch
								flow1.quest_label_3.style.font_color = GuiCommon.sufficient_font_color
							else
								flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
							end
						else
							if charged_bool and quest_progress > 35 then
								flow1.quest_label_3.style.font_color = GuiCommon.sufficient_font_color
							else
								flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
							end
						end
					else
						flow1.quest_label_3.caption = string.format('Fail')
						flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
					end
	
				elseif quest_type == Quest.enum.WORMS then
					if tooltip == '' then tooltip = 'Quest: Worms\n\nKill enough worms for a bonus.' end
	
				elseif quest_type == Quest.enum.FIND then
					if tooltip == '' then tooltip = 'Quest: Find\n\nFind the ghosts for a bonus.' end
	
				elseif quest_type == Quest.enum.RESOURCEFLOW then
					if tooltip == '' then tooltip = 'Quest: Resource Flow\n\nAchieve a production rate of a particular item for a bonus.' end
	
					-- out of date:
					if quest_progressneeded/60 % 1 == 0 then
						flow1.quest_label_2.caption = string.format('%s %.1f/%.0f /s', '[item=' .. quest_params.item .. ']', quest_progress/60, quest_progressneeded/60)
						flow1.quest_label_3.caption = string.format(' for %s', quest_reward.display_sprite)
					else
						flow1.quest_label_2.caption = string.format('%s %.1f/%.1f /s', '[item=' .. quest_params.item .. ']', quest_progress/60, quest_progressneeded/60)
						flow1.quest_label_3.caption = string.format(' for %s', quest_reward.display_sprite)
					end
	
				elseif quest_type == Quest.enum.RESOURCECOUNT then
					if tooltip == '' then tooltip = 'Quest: Item Production\n\nProduce a particular number of items for a bonus.' end
					
					flow1.quest_label_2.caption = string.format('%s ', '[item=' .. quest_params.item .. ']')
	
				elseif quest_type == Quest.enum.NODAMAGE then
					if tooltip == '' then tooltip = 'Quest: No Damage\n\nLaunch a rocket without the silo taking damage.' end
					
					if (memory.boat and memory.boat.state == Boats.enum_state.APPROACHING) or (destination.dynamic_data.rocketsilos and destination.dynamic_data.rocketsilos[1] and destination.dynamic_data.rocketsilos[1].valid and destination.dynamic_data.rocketsilohp == destination.dynamic_data.rocketsilomaxhp) then
						flow1.quest_label_3.caption = string.format('OK')
						flow1.quest_label_3.style.font_color = GuiCommon.sufficient_font_color
					else
						flow1.quest_label_3.caption = string.format('Fail')
						flow1.quest_label_3.style.font_color = GuiCommon.insufficient_font_color
					end
				end
	
				flow1.tooltip = tooltip
				flow1.quest_label_1.tooltip = tooltip
				flow1.quest_label_2.tooltip = tooltip
				flow1.quest_label_3.tooltip = tooltip
			end
		else
			flow1.visible = false
		end
	end


	flow1 = pirates_flow.covering_line_frame

	if flow1 then
		if not eta_bool and not retreating_bool and not quest_bool and not silo_bool and not atsea_loading_bool and not cost_bool and not leave_anytime_bool and not approaching_dock_bool and not leaving_dock_bool then
			flow1.visible = true
		else
			flow1.visible = false
		end
	end

	flow1 = pirates_flow.minimap_piratebutton_frame

	if flow1 then
		if in_hold_bool then
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
				position = {x=0,y=0},
			}
		)
		flow1.visible = false
		flow1.style.margin = 8
	end

	if flow1 then
		flow1.visible = false
		flow1.location = {x = 8, y = 48}
		if on_deck_standing_near_loco_bool then
			flow1.visible = true
			flow1.surface_index = Hold.get_hold_surface(1).index
			flow1.zoom = 0.18
			flow1.style.minimal_height = 268
			flow1.style.minimal_width = 532
			flow1.position = {x=0,y=0}
		elseif on_deck_standing_near_cabin_bool then
			flow1.visible = true
			flow1.surface_index = Cabin.get_cabin_surface().index
			flow1.zoom = 0.468
			flow1.style.minimal_height = 416
			flow1.style.minimal_width = 260
			flow1.position = {x=0,y=-1.3}
		elseif on_deck_standing_near_crowsnest_bool then
			flow1.visible = true
			flow1.surface_index = Crowsnest.get_crowsnest_surface().index
			flow1.zoom = 0.21
			flow1.style.minimal_height = 384
			flow1.style.minimal_width = 384
			flow1.position = {x=memory.overworldx,y=memory.overworldy}
		elseif in_cabin_bool or in_crowsnest_bool then
			flow1.visible = true
			flow1.surface_index = game.surfaces[memory.boat.surface_name].index
			flow1.zoom = 0.09
			flow1.style.minimal_height = 312
			flow1.style.minimal_width = 312
	
			local position = memory.boat.position
			if (destination and destination.type and destination.type == Surfaces.enum.ISLAND and memory.boat.surface_name and memory.boat.surface_name == destination.surface_name and destination.static_params and destination.static_params.boat_starting_xposition) then
				-- nicer viewing position:
				position = {x = destination.static_params.boat_starting_xposition + 50, y = destination.static_params.boat_starting_yposition or 0}
			end
			flow1.position = position
		end
	end
end




local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end

	local player = game.players[event.element.player_index]

	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()

	if event.element.name and event.element.name == 'etaframe_piratebutton' and (memory.boat.state == Boats.enum_state.DOCKED or memory.boat.state == Boats.enum_state.LANDED) then
		if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
			if (not memory.undock_shortcut_are_you_sure_data) then memory.undock_shortcut_are_you_sure_data = {} end
			if memory.undock_shortcut_are_you_sure_data[player.index] and memory.undock_shortcut_are_you_sure_data[player.index] > game.tick - 60 * 4 then
				if memory.boat.state == Boats.enum_state.DOCKED then
					Progression.undock_from_dock()
				elseif memory.boat.state == Boats.enum_state.LANDED then
					if Common.query_sufficient_resources_to_leave() then
						Progression.try_retreat_from_island()
					else
						Common.notify_player_error(player, 'Not enough stored resources.')
					end
				end
			else
				memory.undock_shortcut_are_you_sure_data[player.index] = game.tick
			end
		end
	elseif string.sub(event.element.name, -13, -1) and string.sub(event.element.name, -13, -1) == '_piratebutton' then
			local name = string.sub(event.element.name, 1, -14)
			if Public[name] then
				Public[name].toggle_window(player)
				Public[name].update(player)
			end
		-- elseif event.element.name == 'fuel_label_1' or event.element.name == 'fuel_label_2' then
		-- 	Public.fuel.toggle_window(player)
		-- 	Public.fuel.update(player)
	else
		GuiRuns.click(event)
		GuiCrew.click(event)
		GuiShop.click(event)
		GuiMinimap.click(event)
		GuiInfo.click(event)
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