
-- local Memory = require 'maps.pirates.memory'
-- local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
-- local Surfaces = require 'maps.pirates.surfaces.surfaces'
-- local Lobby = require 'maps.pirates.surfaces.lobby'
local _inspect = require 'utils.inspect'.inspect
-- local Boats = require 'maps.pirates.structures.boats.boats'
local GuiCommon = require 'maps.pirates.gui.common'
local Public = {}


local window_name = 'info'


local width = 430



function Public.toggle_window(player)
	local flow, flow2, flow3, flow4

	if player.gui.screen[window_name .. '_piratewindow'] then player.gui.screen[window_name .. '_piratewindow'].destroy() return end

	flow = player.gui.screen.add{
        type = 'tabbed-pane',
        name = window_name .. '_piratewindow',
        direction = 'vertical'
    }
	flow.location = {x = 90, y = 90}
	flow.selected_tab_index = 1

	flow.style = 'frame_tabbed_pane'
	flow.style.width = width
	flow.style.height = 420

	flow2 = Public.flow_add_info_tab(flow, {'pirates.gui_info_info'})

	flow3 = flow2.parent.last_info_flow_1.last_info_flow_2
	flow4 = flow3.add{type = "label", caption = {"pirates.softmod_info_body_1"}}
	flow4.style.font_color = GuiCommon.friendly_font_color
	flow4.style.single_line = false
	flow4.style.font = 'debug'
	flow4.style.top_margin = -2
	flow4.style.bottom_margin = 0
	-- flow4.style.bottom_margin = 16

	Public.flow_add_info_sections(flow2, {'game_description'})

	flow2 = Public.flow_add_info_tab(flow, {'pirates.gui_info_updates'})

	Public.flow_add_info_sections(flow2, {'updates'})
	-- Public.flow_add_info_sections(flow2, {'updates', 'bugs'})

	flow2 = Public.flow_add_info_tab(flow, {'pirates.gui_info_tips'})

	Public.flow_add_info_sections(flow2, {'new_players', 'tips'})

	flow2 = Public.flow_add_info_tab(flow, {'pirates.gui_info_credits'})

	Public.flow_add_info_sections(flow2, {'credits'})
end


function Public.flow_add_info_sections(flow, sections_list)
	local flow2

	for j = 1, #sections_list do
		local i = sections_list[j]

		flow2 = flow.add{type = "label", caption = {"pirates.softmod_info_" .. i .. "_1"}}
		flow2.style.font_color = GuiCommon.friendly_font_color
		flow2.style.single_line = false
		flow2.style.font = 'heading-3'
		flow2.style.bottom_margin = -4

		flow2 = flow.add{type = "label", caption = {"pirates.softmod_info_" .. i .. "_2"}}
		flow2.style.font_color = GuiCommon.friendly_font_color
		flow2.style.single_line = false
		flow2.style.font = 'default'
		flow2.style.bottom_margin = 12
		flow2.style.left_margin = 8
	end
end


function Public.flow_add_info_tab(flow, tab_name)

	local tab, contents, ret, flow3, flow4, flow5

	tab = flow.add{type='tab', caption=tab_name}
	tab.style = 'frame_tab'

	contents = flow.add({
		type = 'frame',
		direction = 'vertical',
	})
	contents.style.vertically_stretchable = true
	contents.style.width = width
	contents.style.natural_height = 2000
	contents.style.top_margin = -8
	contents.style.bottom_margin = -12
	contents.style.left_margin = -7
	contents.style.right_margin = -11

	flow3 = contents.add({
		type = 'flow',
		name = 'header_flow_1',
		direction = 'horizontal',
	})
	flow3.style.horizontally_stretchable = true
    flow3.style.horizontal_align = 'center'

	flow4 = flow3.add({
		type = 'flow',
		name = 'header_flow_2',
		direction = 'vertical',
	})
	flow4.style.horizontally_stretchable = true
    flow4.style.horizontal_align = 'center'

	flow5 = flow4.add{type = "label", caption = {"", {"pirates.softmod_info_header_before_version_number"}, CoreData.version_string, {"pirates.softmod_info_header_after_version_number"}}}
	flow5.style.font_color = GuiCommon.friendly_font_color
	flow5.style.font = 'heading-1'
	flow5.style.bottom_margin = 2

	flow5 = flow4.add{type = "label", caption = {"pirates.softmod_info_body_promote"}}
	flow5.style.font_color = GuiCommon.friendly_font_color
	flow5.style.single_line = false
	flow5.style.font = 'default-small'
	flow5.style.top_margin = -12
	flow5.style.bottom_margin = 8

	ret = contents.add({
		type = 'flow',
		name = 'main_flow_1',
		direction = 'vertical',
	})
	ret.style.horizontally_stretchable = true

	flow3 = contents.add({
		type = 'flow',
		name = 'last_info_flow_1',
		direction = 'horizontal',
	})
	flow3.style.horizontally_stretchable = true
    flow3.style.horizontal_align = 'center'

	flow4 = flow3.add({
		type = 'flow',
		name = 'last_info_flow_2',
		direction = 'vertical',
	})
	flow4.style.horizontally_stretchable = true
    flow4.style.horizontal_align = 'center'

	flow3 = contents.add({
		type = 'flow',
		direction = 'vertical',
	})
	flow3.style.vertically_stretchable = true
	flow3.style.horizontally_stretchable = true

	flow3 = contents.add({
		type = 'flow',
		direction = 'horizontal',
	})
	flow3.style.horizontally_stretchable = true
    flow3.style.horizontal_align = 'center'

	flow4 = flow3.add{type = "label", caption = {"pirates.softmod_info_body_clicky"}}
	flow4.style.font_color = GuiCommon.friendly_font_color
	flow4.style.single_line = false
	flow4.style.font = 'default'
	flow4.style.bottom_margin = 4
	flow4.style.top_margin = 3

	flow.add_tab(tab, contents)

	return ret
end


function Public.click(event)

	local player = game.players[event.element.player_index]
	-- local name = 'info'

	local element = event.element
	local eventtype = element.type

	if not player.gui.screen[window_name .. '_piratewindow'] then return end

	-- local memory = Memory.get_crew_memory()

	if eventtype ~= 'tab' and (
		element.name == (window_name .. '_piratewindow') or
		(element.parent and element.parent.name == (window_name .. '_piratewindow')) or
		(element.parent and element.parent.parent and element.parent.parent.name == (window_name .. '_piratewindow')) or
		(element.parent and element.parent.parent and element.parent.parent.parent and element.parent.parent.parent.name == (window_name .. '_piratewindow')) or
		(element.parent and element.parent.parent and element.parent.parent.parent and element.parent.parent.parent.parent and element.parent.parent.parent.parent.name == (window_name .. '_piratewindow')) or
		(element.parent and element.parent.parent and element.parent.parent.parent and element.parent.parent.parent.parent and element.parent.parent.parent.parent.parent and element.parent.parent.parent.parent.parent.name == (window_name .. '_piratewindow'))
	) then
		Public.toggle_window(player)
	end
end



-- function Public.regular_update(player)

-- end

function Public.full_update(player)
	if Public.regular_update then Public.regular_update(player) end

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	local flow = player.gui.screen[window_name .. '_piratewindow']

	local flow2 = flow
	-- warning, if you make these too small, it loses 'Click to dismiss.'
	if flow2.selected_tab_index == 1 then
		flow2.style.height = 400
	elseif flow2.selected_tab_index == 2 then
		flow2.style.height = 520
	elseif flow2.selected_tab_index == 3 then
		flow2.style.height = 620
	elseif flow2.selected_tab_index == 4 then
		flow2.style.height = 360
	end
end



return Public