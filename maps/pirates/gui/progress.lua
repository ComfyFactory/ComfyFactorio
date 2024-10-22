-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require('maps.pirates.memory')
local Common = require('maps.pirates.common')
local CoreData = require('maps.pirates.coredata')
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
local Surfaces = require('maps.pirates.surfaces.surfaces')
local Lobby = require('maps.pirates.surfaces.lobby')
local _inspect = require('utils.inspect').inspect
-- local Boats = require 'maps.pirates.structures.boats.boats'
local GuiCommon = require('maps.pirates.gui.common')
local Public = {}

local window_name = 'progress'

function Public.toggle_window(player)
	if player.gui.screen[window_name .. '_piratewindow'] then
		player.gui.screen[window_name .. '_piratewindow'].destroy()
		return
	end

	local flow, flow2, flow3
	flow = GuiCommon.new_window(player, window_name)
	flow.caption = { 'pirates.gui_progress' }

	flow2 = GuiCommon.flow_add_section(flow, 'distance_travelled', { 'pirates.gui_progress_distance_travelled' })

	flow3 = flow2.add({
		name = 'leagues',
		type = 'label',
	})
	flow3.style.left_margin = 5
	flow3.style.top_margin = -3
	flow3.style.bottom_margin = -3
	flow3.style.single_line = false
	flow3.style.maximal_width = 160
	flow3.style.font = 'default-dropdown'

	flow2 = GuiCommon.flow_add_section(flow, 'current_location', { 'pirates.gui_progress_current_location', '' })

	-- flow3 = flow2.add({
	-- 	name = 'location_name',
	-- 	type = 'label',
	-- })
	-- flow3.style.left_margin = 5
	-- flow3.style.top_margin = -3
	-- flow3.style.bottom_margin = -3
	-- flow3.style.single_line = false
	-- flow3.style.maximal_width = 160
	-- flow3.style.font = 'default-dropdown'

	-- flow3 = flow2.add({type = 'label', name = 'hidden_ores_yes', caption = 'Ores detected:'})

	-- flow3 = flow2.add({type = 'table', name = 'hidden_ores_yes_table', column_count = 3})
	-- flow3.style.left_margin = 5
	-- flow3.style.bottom_margin = 4

	-- for _, ore in ipairs(CoreData.ore_types) do
	-- 	flow3.add({type = 'sprite-button', name = ore.name, sprite = ore.sprite_name, enabled = false, number = 0})
	-- end

	-- flow3 = flow2.add({type = 'label', name = 'hidden_ores_no', caption = 'Ores detected: None'})

	-- -- flow3 = flow2.add({type = 'label', name = 'daynight', caption = ''})

	-- flow3 = flow2.add({type = 'label', name = 'patch_size', caption = ''})
	-- flow3.style.top_margin = -3

	flow3 = flow2.add({ type = 'label', name = 'daynight', caption = '' })
	flow3.style.top_margin = -3

	-- flow2 = GuiCommon.flow_add_section(flow, 'departure_items', 'Resources needed for departure:')

	-- flow3.style.bottom_margin = -2
	-- flow3 = flow2.add({type = 'table', name = 'needed', column_count = 4})
	-- flow3.style.left_margin = 5
	-- for _, item in ipairs(CoreData.departure_items) do
	-- 	flow3.add({type = 'sprite-button', name = item.name, sprite = item.sprite_name, enabled = false, number = 0})
	-- end

	GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
	return nil
end

-- function Public.regular_update(player)

-- end

function Public.full_update(player)
	if Public.regular_update then
		Public.regular_update(player)
	end
	if not player.gui.screen[window_name .. '_piratewindow'] then
		return
	end
	local flow = player.gui.screen[window_name .. '_piratewindow']

	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	-- local type = destination.type
	-- local subtype = destination.subtype

	local scope = Surfaces.get_scope(destination)

	local name
	if scope then
		name = (destination and destination.static_params and destination.static_params.name)
				and destination.static_params.name
			or scope.Data.display_name
	else
		name = Lobby.Data.display_name
	end

	flow.current_location.header.caption = { 'pirates.gui_progress_current_location', name }
	flow.distance_travelled.body.leagues.caption = { 'pirates.gui_progress_leagues', tostring(memory.overworldx or 0) }

	-- local daynighttype
	-- if destination.static_params and destination.static_params.daynightcycletype then
	-- 	daynighttype = destination.static_params.daynightcycletype
	-- else
	-- 	daynighttype = 1
	-- end
	-- flow.current_location.body.daynight.caption = string.format('Day/night cycle: %s', CoreData.daynightcycle_types[daynighttype].displayname)

	-- if destination.static_params and destination.static_params.radius_squared_modifier then
	-- 	local radius_squared_modifier = destination.static_params.radius_squared_modifier
	-- 	flow.current_location.body.patch_size.visible = true
	-- 	if radius_squared_modifier <= 0.65 then
	-- 		flow.current_location.body.patch_size.caption = 'Patch sizing: ' .. 'Nano'
	-- 	elseif radius_squared_modifier <= 0.85 then
	-- 		flow.current_location.body.patch_size.caption = 'Patch sizing: ' .. 'Small'
	-- 	elseif radius_squared_modifier <= 1.5 then
	-- 		flow.current_location.body.patch_size.caption = 'Patch sizing: ' .. 'Normal'
	-- 	else
	-- 		flow.current_location.body.patch_size.caption = 'Patch sizing: ' .. 'Large'
	-- 	end
	-- else
	-- 	flow.current_location.body.patch_size.visible = false
	-- end

	-- if destination.static_params and destination.static_params.daynightcycletype then
	-- 	flow.current_location.body.daynight.visible = true
	-- 	local daynightcycletype = destination.static_params.daynightcycletype
	-- 	flow.current_location.body.daynight.caption = 'Daynight cycle: ' .. CoreData.daynightcycle_types[daynightcycletype].displayname

	-- else
	-- 	flow.current_location.body.daynight.visible = false
	-- end
	local daynightcycletype = destination.static_params.daynightcycletype or 1
	flow.current_location.body.daynight.caption =
		{ 'pirates.gui_progress_time_of_day', CoreData.daynightcycle_types[daynightcycletype].displayname }

	-- local ores
	-- -- if destination.static_params and destination.static_params.abstract_ore_amounts then ores = destination.static_params.abstract_ore_amounts end
	-- if destination.dynamic_data and destination.dynamic_data.hidden_ore_remaining_abstract then ores = destination.dynamic_data.hidden_ore_remaining_abstract end

	-- if ores then
	-- 	flow.current_location.body.hidden_ores_yes.visible = true
	-- 	flow.current_location.body.hidden_ores_yes_table.visible = true
	-- 	flow.current_location.body.patch_size.visible = true
	-- 	flow.current_location.body.hidden_ores_no.visible = false

	-- 	for _, ore in ipairs(CoreData.ore_types) do
	-- 		if ores[ore.name] then
	-- 			flow.current_location.body.hidden_ores_yes_table[ore.name].number = Math.ceil(ores[ore.name])
	-- 		else
	-- 			flow.current_location.body.hidden_ores_yes_table[ore.name].number = 0
	-- 		end
	-- 	end
	-- else
	-- 	flow.current_location.body.hidden_ores_yes.visible = false
	-- 	flow.current_location.body.hidden_ores_yes_table.visible = false
	-- 	flow.current_location.body.patch_size.visible = false
	-- 	flow.current_location.body.hidden_ores_no.visible = true
	-- end
end

return Public
