
local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
-- local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
-- local Roles = require 'maps.pirates.roles.roles'
-- local Crew = require 'maps.pirates.crew'
-- local Progression = require 'maps.pirates.progression'
-- local Structures = require 'maps.pirates.structures.structures'
local _inspect = require 'utils.inspect'.inspect
-- local Boats = require 'maps.pirates.structures.boats.boats'
local GuiCommon = require 'maps.pirates.gui.common'
local Public = {}

local window_name = 'minimap'

local default_zoom = 0.1
local default_size = 320

function Public.toggle_window(player)
	local flow, flow2

	local window = player.gui.screen[window_name .. '_piratewindow']
	if window then
		local switch_state = window.close_button_flow.hflow.switch_auto_map.switch_state
		local auto_map = true
		if switch_state == 'right' then
			auto_map = false
		end
		GuiCommon.update_gui_memory(player, window_name, 'auto_map', auto_map)

		window.destroy()
		return
	end -- else:

	flow = GuiCommon.new_window(player, window_name)
	flow.caption = {'pirates.gui_minimap_outside_view'}
	flow.style.maximal_width = 800

	local memory = Memory.get_crew_memory()
	local global_memory = Memory.get_global_memory()
	local gui_memory = global_memory.player_gui_memories[player.index]

	local auto_map
	if gui_memory and gui_memory[window_name] then
		auto_map = gui_memory[window_name].auto_map
	else
		auto_map = true
	end
	local switch_state = 'right'
	if auto_map then
		switch_state = 'left'
	end

	if not (memory.boat and memory.boat.position and memory.boat.surface_name) then return end

    local position = memory.boat.position
	local destination = Common.current_destination()
	if (destination and destination.type and destination.type == Surfaces.enum.ISLAND and destination.static_params and destination.static_params.boat_starting_xposition) then
		-- nicer viewing position:
		position = {x = destination.static_params.boat_starting_xposition + 50, y = destination.static_params.boat_starting_yposition or 0}
	end
	local zoom
	if gui_memory and gui_memory[window_name] and gui_memory[window_name].zoom then
		zoom = gui_memory[window_name].zoom
	else
		zoom = default_zoom
	end
	local size
	if gui_memory and gui_memory[window_name] and gui_memory[window_name].size then
		size = gui_memory[window_name].size
	else
		size = default_size
	end

    local element = flow['camera']
    if not element then
        element =
		flow.add(
            {
                type = 'camera',
                name = 'camera',
                position = position,
                surface_index = game.surfaces[memory.boat.surface_name].index,
                zoom = zoom,
                tooltip = {'pirates.gui_minimap_tooltip'}
            }
        )
        element.style.margin = 1
        element.style.minimal_height = size
        element.style.minimal_width = size
        element.style.maximal_height = size
        element.style.maximal_width = size
    end

	flow2 = GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
	flow2.add(
		{
			type = 'switch',
			name = 'switch_auto_map',
			index = 1,
			allow_none_state = false,
			switch_state = switch_state,
			left_label_caption = {'pirates.gui_minimap_switch_left'},
			right_label_caption = {'pirates.gui_minimap_switch_right'},
		}
	)
end





-- function Public.regular_update(player)

-- end

function Public.full_update(player)
	if Public.regular_update then Public.regular_update(player) end
	local flow

	local memory = Memory.get_crew_memory()

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	flow = player.gui.screen[window_name .. '_piratewindow']

    local element = flow['camera']
	if element then
		local position = memory.boat.position
		local destination = Common.current_destination()
		if (destination and destination.type and destination.type == Surfaces.enum.ISLAND and memory.boat.surface_name and memory.boat.surface_name == destination.surface_name and destination.static_params and destination.static_params.boat_starting_xposition) then
			-- nicer viewing position:
			position = {x = destination.static_params.boat_starting_xposition + 50, y = destination.static_params.boat_starting_yposition or 0}
		end

		if position then
			element.position = position
		end
		if memory.boat.surface_name and game.surfaces[memory.boat.surface_name] and game.surfaces[memory.boat.surface_name].valid then
			element.surface_index = game.surfaces[memory.boat.surface_name].index
		end
	end
end


function Public.click(event)

	local player = game.players[event.element.player_index]

	local eventname = event.element.name

	if not player.gui.screen[window_name .. '_piratewindow'] then return end
	-- local flow = player.gui.screen[window_name .. '_piratewindow']

	-- local memory = Memory.get_crew_memory()
	-- local shop_data = Shop.main_shop_data

	-- if eventname == 'buy_button' then
	-- 	Shop.Captains.main_shop_try_purchase(event.element.parent.name)
	-- end

    if eventname ~= 'camera' then return end

	local zoom = default_zoom
	local size = default_size

	local global_memory = Memory.get_global_memory()
	local gui_memory = global_memory.player_gui_memories[player.index]

	if gui_memory and gui_memory[window_name] then
		zoom = gui_memory[window_name].zoom or default_zoom
		size = gui_memory[window_name].size or default_size
	end

    if event.button == defines.mouse_button_type.right then
		if zoom == 0.15 then
			zoom = 0.11
		elseif zoom == 0.11 then
			zoom = 0.07
		else
			zoom = 0.04
		end
        event.element.zoom = zoom
    end
    if event.button == defines.mouse_button_type.left then
		if zoom == 0.04 then
			zoom = 0.07
		elseif zoom == 0.07 then
			zoom = 0.11
		else
			zoom = 0.15
		end
        event.element.zoom = zoom
    end
    if event.button == defines.mouse_button_type.middle then
		if size == 340 then
			size = 440
		elseif size == 440 then
			size = 560
		elseif size == 560 then
			size = 700
		elseif size == 700 then
			size = 280
		else
			size = 340
		end
        event.element.style.minimal_height = size
        event.element.style.minimal_width = size
        event.element.style.maximal_height = size
        event.element.style.maximal_width = size
    end

	GuiCommon.update_gui_memory(player, window_name, 'zoom', zoom)
	GuiCommon.update_gui_memory(player, window_name, 'size', size)
end



local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not Common.validate_player_and_character(player) then
        return
    end

	local window = player.gui.screen[window_name .. '_piratewindow']

	local from_hold_bool = string.sub(game.surfaces[event.surface_index].name, 9, 12) == 'Hold'
	local to_hold_bool = string.sub(player.surface.name, 9, 12) == 'Hold'

    if from_hold_bool and (not to_hold_bool) then
        if window then
			Public.toggle_window(player)
		end
	elseif to_hold_bool and (not from_hold_bool) then
		local global_memory = Memory.get_global_memory()
		local gui_memory = global_memory.player_gui_memories[player.index]

		if (gui_memory and gui_memory[window_name] and gui_memory[window_name].auto_map) or (not gui_memory) or (gui_memory and (not gui_memory[window_name])) then --if no gui memory exists for this, default to opening the minimap
			Public.toggle_window(player)
		end
    end

end

local event = require 'utils.event'
event.add(defines.events.on_player_changed_surface, on_player_changed_surface)

return Public