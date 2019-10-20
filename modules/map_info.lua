map_info = {}
map_info.main_caption = "Insert Main Caption"
map_info.main_caption_color = {r=0.6, g=0.3, b=0.99}
map_info.sub_caption = "Insert Sub Caption"
map_info.sub_caption_color = {r=0.2, g=0.9, b=0.2}
map_info.text = [[
Add info text to map_info.
]]

local function create_map_intro(player, frame)
	frame.clear()
	frame.style.padding = 4
	frame.style.margin = 0
	
	local t = frame.add {type = "table", column_count = 1}
	
	local line = t.add { type = "line"}
	line.style.top_margin = 4
	line.style.bottom_margin = 4
	
	local l = t.add {type = "label", caption = map_info.main_caption}
	l.style.font = "heading-1"
	l.style.font_color = map_info.main_caption_color
	l.style.minimal_width = 780	
	l.style.horizontal_align = "center"	
	l.style.vertical_align = "center"
	
	local l = t.add {type = "label", caption = map_info.sub_caption}
	l.style.font = "heading-2"
	l.style.font_color = map_info.sub_caption_color
	l.style.minimal_width = 780
	l.style.horizontal_align = "center"	
	l.style.vertical_align = "center"
	
	local line = t.add { type = "line"}
	line.style.top_margin = 4
	line.style.bottom_margin = 4
	
	local scroll_pane = frame.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	scroll_pane.style.maximal_height = 320
	scroll_pane.style.minimal_height = 320
	
	local l = scroll_pane.add {type = "label", caption = map_info.text}
	l.style.font = "heading-2"
	l.style.single_line = false
	l.style.font_color = {r=0.85, g=0.85, b=0.88}
	l.style.minimal_width = 780	
	l.style.horizontal_align = "center"	
	l.style.vertical_align = "center"
	
	local b = frame.add {type = "button", caption = "CLOSE", name = "close_map_intro"}
	b.style.font = "heading-2"
	b.style.padding = 2
	b.style.top_margin = 3
	b.style.left_margin = 333
	b.style.horizontal_align = "center"	
	b.style.vertical_align = "center"
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if player.online_time == 0 then	comfy_panel_call_tab(player, "Map Info") end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
	if event.element.name == "close_map_intro" then game.players[event.player_index].gui.left.comfy_panel.destroy() return end
end

comfy_panel_tabs["Map Info"] = create_map_intro

local event = require 'utils.event'
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)