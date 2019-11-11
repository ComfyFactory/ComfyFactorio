local height = 600
local width = 400
local column_count = 8
local line_count = 12
local items_per_page = column_count * line_count
local Public = {}

local function draw_main_window(player)
	local item_list = global.fjei.item_list

	if player.gui.left["fjei_main_window"] then player.gui.left["fjei_main_window"].destroy() end
	local frame = player.gui.left.add({type = "frame", name = "fjei_main_window", caption = "search"})
	frame.style.minimal_height = height
	frame.style.minimal_width = width
	frame.style.padding = 2
	
	local t = frame.add({type = "table", name = "fjei_main_window_table", column_count = column_count})
	for i = 1, items_per_page, 1 do
		local sprite = t.add({type = "sprite", sprite = item_list[i].sprite, tooltip = item_list[i].name})
		sprite.style.maximal_width = 28
		sprite.style.maximal_height = 28
		sprite.style.margin = 4
	end
end

function Public.draw_top_toggle_button(player)
	if player.gui.top["fjei_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "fjei_toggle_button", sprite = "virtual-signal/signal-J"})
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.padding = -2
end

function Public.toggle_main_window(element, player)	
	if element.name ~= "fjei_toggle_button" then return end
	if player.gui.left.fjei_main_window then
		player.gui.left.fjei_main_window.destroy()		
	else
		draw_main_window(player)	
	end
	return true
end

return Public