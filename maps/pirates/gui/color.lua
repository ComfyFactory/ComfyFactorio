-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Memory = require 'maps.pirates.memory'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
local GuiCommon = require 'maps.pirates.gui.common'
local PlayerColors = require 'maps.pirates.player_colors'
local Public = {}

local window_name = 'color'

function Public.toggle_window(player)
	local flow, flow2

	if player.gui.screen[window_name .. '_piratewindow'] then player.gui.screen[window_name .. '_piratewindow'].destroy() return end

	flow = GuiCommon.new_window(player, window_name)
	flow.caption = 'Colors!'
	flow.style.width = 500
	flow.style.height = 500

	-- local label = ''
	-- for i, v in ipairs(PlayerColors.names) do
	-- 	if i>1 then label = label .. ', ' end
	-- 	local c = PlayerColors.colors[v]
	-- 	label = label .. ', [color=' .. c.r .. ',' .. c.g .. ',' .. c.b .. ']' .. v .. '[/color]'
	-- 	-- label = label .. v
	-- end
	-- log(label)


	flow2 = flow.add({
		name = 'colors',
		type = 'text-box',
		text = PlayerColors.printable,
	})
	flow2.word_wrap = true
	flow2.read_only = true
	flow2.selectable = true
	flow2.style.width = 450
	flow2.style.height = 400

	GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
end



-- function Public.regular_update(player)

-- end

function Public.full_update(player)
	if Public.regular_update then Public.regular_update(player) end
end


-- function Public.click(event)
-- end

return Public