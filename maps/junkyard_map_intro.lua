local event = require 'utils.event'

--local main_caption = " --Junkyard-- "
--local sub_caption = "Some may call this junk. Me, I call them treasures."
local info = [[
	Citizen Log #468-2A-3287, Freelancer Cole
	
	To whoever is reading this message,
	i have most likely already left this doomed place,	or... well..
	
	I am stranded on this foreign world since months and i have given up on fixing my ships transceiver.
	Yes, things are not looking too good, i must admit.	
	The rust and devastation tells a story of an advanced civilization,
	which seems to have evacuated their home long time ago.
	
	Any natural resources are rare and the ones worth while are too hard for me to reach.
	Luckily, the wrecks yield all kinds of useful scraps, but also various dangers.
	Almost lost half a leg just some days ago while digging out a crate.
	
	The wildlife is extremely aggressive, especially at the time of night.	
	Most of these insect appearing like creatures seem to live underground.
	Stay near your light sources!!
	
	###Log End###
]]

local function create_map_intro(player)
	if player.gui.left["map_intro_frame"] then player.gui.left["map_intro_frame"].destroy() end
	local frame = player.gui.left.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	
	local t = frame.add {type = "table", column_count = 1}	
	--[[
	local tt = t.add {type = "table", column_count = 3}
	local l = tt.add {type = "label", caption = main_caption}
	l.style.font = "heading-1"
	l.style.font_color = {r=0.8, g=0.6, b=0.6}
	l.style.top_padding = 6	
	l.style.bottom_padding = 6
	
	local l = tt.add {type = "label", caption = sub_caption}
	l.style.font = "heading-2"
	l.style.font_color = {r=0.5, g=0.8, b=0.1}
	l.style.minimal_width = 280	
	]]
	local b = frame.add {type = "button", caption = "Close", name = "close_map_intro_frame", align = "right"}	
	b.style.font = "default"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	
	--local tt = t.add {type = "table", column_count = 1}
	local frame = t.add {type = "frame"}
	local l = frame.add {type = "label", caption = info}
	l.style.single_line = false
	l.style.font = "heading-3"
	l.style.font_color = {r=0.95, g=0.95, b=0.95}	
	
	
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if player.online_time < 18000 then
		create_map_intro(player)
	end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
	local player = game.players[event.element.player_index]
	if event.element.name == "close_map_intro_frame" then player.gui.left["map_intro_frame"].destroy() end	
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)