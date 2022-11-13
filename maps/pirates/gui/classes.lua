-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local Classes = require 'maps.pirates.roles.classes'
local GuiCommon = require 'maps.pirates.gui.common'
local Public = {}


local window_name = 'classes'

local widths = {}
widths['available_classes'] = 150
widths['taken_by'] = 150
widths['action_buttons'] = 100

-- used to track whether new class entries should be added during "full_update"
local entry_count = 0

local function add_class_entry(player, class, taken_by_player_index, index)
	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow
	flow = player.gui.screen[window_name .. '_piratewindow']

	local class_list_panel_table = flow.scroll_pane.class_list_panel_table


	-- Class label
	local explanation = Classes.explanation(class, false)
	local full_explanation

	if Classes.class_purchase_requirement[class] then
		full_explanation = {'pirates.class_explanation_upgraded_class', Classes.display_form(class), Classes.display_form(Classes.class_purchase_requirement[class]), explanation}
	else
		full_explanation = {'pirates.class_explanation', Classes.display_form(class), explanation}
	end

	local available_class_label = class_list_panel_table.add({
		type = 'label',
		caption = Classes.display_form(class),
		tooltip = full_explanation,
	})
	available_class_label.style.minimal_width = widths['available_classes']
    available_class_label.style.maximal_width = widths['available_classes']


	-- Player label
	local taken_by_player_name = taken_by_player_index and game.players[taken_by_player_index].name or ''
	local taken_by_label = class_list_panel_table.add({
		name = 'player_label' .. index,
		type = 'label',
		caption = taken_by_player_name,
	})
	taken_by_label.style.minimal_width = widths['taken_by']
    taken_by_label.style.maximal_width = widths['taken_by']

	-- Button
	local button

	if not taken_by_player_index then
		button = class_list_panel_table.add({
			name = 'button' .. index,
			type = 'button',
			caption = {'pirates.gui_classes_take'},
			tooltip = {'pirates.gui_classes_take_enabled_tooltip'},
		})
	elseif taken_by_player_index == player.index then
		button = class_list_panel_table.add({
			name = 'button' .. index,
			type = 'button',
			caption = {'pirates.gui_classes_drop'},
			tooltip = {'pirates.gui_classes_drop_tooltip'},
		})
		button.style.font_color = {r=1, g=0, b=0}
		button.style.hovered_font_color = {r=1, g=0, b=0}
		button.style.clicked_font_color = {r=1, g=0, b=0}
	else
		button = class_list_panel_table.add({
			name = 'button' .. index,
			type = 'button',
			enabled = false, -- wanted to make "visble = false" instead, but table doesn't like that
			caption = {'pirates.gui_classes_take'},
			tooltip = {'pirates.gui_classes_take_disabled_tooltip'},
		})
	end
	button.tags = {type = 'pirates_' .. window_name, index = index}

	button.style.minimal_width = widths['action_buttons']
	button.style.maximal_width = widths['action_buttons']
end

function Public.toggle_window(player)
	local memory = Memory.get_crew_memory()
	local flow, flow2, flow3

	--*** OVERALL FLOW ***--
	if player.gui.screen[window_name .. '_piratewindow'] then player.gui.screen[window_name .. '_piratewindow'].destroy() return end

    if not Common.is_id_valid(memory.id) then return end

	flow = GuiCommon.new_window(player, window_name)
	flow.caption = {'pirates.gui_classes'}
	flow.auto_center = true
	flow.style.maximal_width = 500

	flow2 = flow.add({
		name = 'headers',
		type = 'flow',
		direction = 'horizontal',
	})

	flow3 = flow2.add({
		name = 'available_classes',
		type = 'label',
		caption = {'pirates.gui_classes_available_classes'},
	})
	flow3.style.minimal_width = widths['available_classes']
    flow3.style.maximal_width = widths['available_classes']
	flow3.style.font = 'heading-2'
	flow3.style.font_color = GuiCommon.section_header_font_color

	flow3 = flow2.add({
		name = 'taken_by',
		type = 'label',
		caption = {'pirates.gui_classes_taken_by'},
	})
	flow3.style.minimal_width = widths['taken_by']
    flow3.style.maximal_width = widths['taken_by']
	flow3.style.font = 'heading-2'
	flow3.style.font_color = GuiCommon.section_header_font_color

	flow3 = flow2.add({
		name = 'action_buttons',
		type = 'label',
		caption = {'pirates.gui_classes_actions'},
	})
	flow3.style.minimal_width = widths['action_buttons']
    flow3.style.maximal_width = widths['action_buttons']
	flow3.style.font = 'heading-2'
	flow3.style.font_color = GuiCommon.section_header_font_color

	-- List management
    local scroll_pane = flow.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    scroll_pane.style.maximal_height = 500
	scroll_pane.style.bottom_padding = 20

	scroll_pane.add{
		type = 'table',
		name = 'class_list_panel_table',
		column_count = 3
	}

	for i, class_entry in ipairs(memory.unlocked_classes) do
		add_class_entry(player, class_entry.class, class_entry.taken_by, i)
	end

	entry_count = #memory.unlocked_classes

	GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
end



function Public.full_update(player, force_refresh)
	force_refresh = force_refresh or nil
	-- close and open the window to reconstruct the window (not really necessary when window is closed, but doesn't really matter as it should be ran once and only when necessary)
	if force_refresh then
		Public.toggle_window(player)
		Public.toggle_window(player)
	end

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow = player.gui.screen[window_name .. '_piratewindow']

	local memory = Memory.get_crew_memory()

	--*** Overwrite contents ***--

	local class_list_panel_table = flow.scroll_pane.class_list_panel_table

	-- Currently assuming class list size never decreases

	-- Update current content table
	for i = 1, entry_count do
		local label = class_list_panel_table['player_label' .. i]
		local class_entry = memory.unlocked_classes[i]
		label.caption = class_entry.taken_by and game.players[class_entry.taken_by].name or ''

		local black = {r=0, g=0, b=0}
		local red = {r=1, g=0, b=0}

		local button = class_list_panel_table['button' .. i]
		if not class_entry.taken_by then
			button.caption = {'pirates.gui_classes_take'}
			button.tooltip = {'pirates.gui_classes_take_enabled_tooltip'}
			button.style.font_color = black
			button.style.hovered_font_color = black
			button.style.clicked_font_color = black
			button.enabled = true
		elseif class_entry.taken_by == player.index then
			button.caption = {'pirates.gui_classes_drop'}
			button.tooltip = {'pirates.gui_classes_drop_tooltip'}
			button.style.font_color = red
			button.style.hovered_font_color = red
			button.style.clicked_font_color = red
			button.enabled = true
		else
			button.caption = {'pirates.gui_classes_take'}
			button.tooltip = {'pirates.gui_classes_take_disabled_tooltip'}
			button.style.font_color = black
			button.style.hovered_font_color = black
			button.style.clicked_font_color = black
			button.enabled = false
		end
	end


	-- If new entries were added since last update, add them to GUI
	if entry_count ~= #memory.unlocked_classes then
		for i = entry_count + 1, #memory.unlocked_classes do
			local class_entry = memory.unlocked_classes[i]
			add_class_entry(player, class_entry.class, class_entry.taken_by, i)
		end

		entry_count = #memory.unlocked_classes
	end
end


function Public.click(event)
	if not event.element then return end
	if not event.element.valid then return end

	local player = game.players[event.element.player_index]
	if not player.gui.screen[window_name .. '_piratewindow'] then return end

	local tags = event.element.tags
	if not tags then return end
	if tags.type ~= 'pirates_' .. window_name then return end

	local memory = Memory.get_crew_memory()

	if tags.index then
		local button_is_take_class = (not memory.unlocked_classes[tags.index].taken_by) and true or false

		if button_is_take_class then
			local class_to_assign = memory.unlocked_classes[tags.index].class
			Classes.assign_class(player.index, class_to_assign, tags.index)
			return
		else -- button is drop class
			Classes.assign_class(player.index, nil, tags.index)
			return
		end
	end
end

return Public