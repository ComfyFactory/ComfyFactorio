local math_ceil = math.ceil
local height = 600
local width = 400
local column_count = 8
local line_count = 12
local items_per_page = column_count * line_count
local Public = {}

local function get_total_page_count(player)
	return math_ceil(global.fjei.player_data[player.index].size_of_filtered_list / items_per_page)
end

local function set_page_count_caption(player)
	if not player.gui.left.fjei_main_window then return end
	local active_page = global.fjei.player_data[player.index].active_page
	local element = player.gui.left.fjei_main_window.fjei_main_window_control_table.fjei_main_window_page_counter
	element.caption = "Page " .. active_page .. " of " .. get_total_page_count(player)
end

local function display_item_list(player)
	if not player.gui.left.fjei_main_window then return end
	if not player.gui.left.fjei_main_window.fjei_main_window_item_list_table then return end
	local item_list_table = player.gui.left.fjei_main_window.fjei_main_window_item_list_table
	item_list_table.clear()
	
	local active_page = global.fjei.player_data[player.index].active_page
	local starting_index = 1 + (active_page - 1) * items_per_page
	local item_list = global.fjei.item_list
	local filtered_list = global.fjei.player_data[player.index].filtered_list	
	
	for i = starting_index, starting_index + items_per_page - 1, 1 do
		if not filtered_list[i] then return end
		local item_key = filtered_list[i]
		if not item_list[item_key] then return end		
		local sprite = item_list_table.add({type = "sprite", sprite = "recipe/" .. item_list[item_key].name, tooltip = item_list[item_key].name})
		sprite.style.maximal_width = 32
		sprite.style.maximal_height = 32
		sprite.style.margin = 4		
	end
end

function Public.refresh_main_window(player)
	set_page_count_caption(player)
	display_item_list(player)
end

local function draw_main_window(player)
	if player.gui.left["fjei_main_window"] then player.gui.left["fjei_main_window"].destroy() end
	local frame = player.gui.left.add({type = "frame", name = "fjei_main_window", direction = "vertical"})
	frame.style.minimal_height = height
	frame.style.minimal_width = width
	frame.style.padding = 2
	
	local t = frame.add({type = "table", name = "fjei_main_window_control_table",  column_count = 4})
	local element = t.add({type = "label", name = "fjei_main_window_page_counter",  caption = " "})
	element.style.font = "heading-1"
	element.style.margin = 4
	
	local element = t.add({type = "sprite-button", name = "fjei_main_window_previous_page", caption = "←"})
	element.style.font = "heading-1"
	element.style.maximal_height = 38
	element.style.maximal_width = 38
	local element = t.add({type = "sprite-button", name = "fjei_main_window_next_page", caption = "→"})
	element.style.font = "heading-1"
	element.style.maximal_height = 38
	element.style.maximal_width = 38
	local textfield = t.add({ type = "textfield", name = "fjei_main_window_search_textfield", text = "" })
	textfield.style.minimal_width = 160	
	
	frame.add({type = "line"})
		
	local t = frame.add({type = "table", name = "fjei_main_window_item_list_table", column_count = column_count})
	
	Public.refresh_main_window(player)
end

local function toggle_main_window(element, player)
	if player.gui.left.fjei_main_window then
		player.gui.left.fjei_main_window.destroy()		
	else
		draw_main_window(player)	
	end
	return true
end

local function main_window_next_page(element, player)
	if global.fjei.player_data[player.index].active_page == get_total_page_count(player) then return end
	global.fjei.player_data[player.index].active_page = global.fjei.player_data[player.index].active_page + 1
	Public.refresh_main_window(player)
end

local function main_window_previous_page(element, player)
	if global.fjei.player_data[player.index].active_page == 1 then return end
	global.fjei.player_data[player.index].active_page = global.fjei.player_data[player.index].active_page - 1
	Public.refresh_main_window(player)
end

local gui_actions = {
	["fjei_toggle_button"] = toggle_main_window,
	["fjei_main_window_next_page"] = main_window_next_page,
	["fjei_main_window_previous_page"] = main_window_previous_page,
}

function Public.gui_click_actions(element, player)
	if not gui_actions[element.name] then return end
	gui_actions[element.name](element, player)
end

function Public.draw_top_toggle_button(player)
	if player.gui.top["fjei_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "fjei_toggle_button", sprite = "virtual-signal/signal-J"})
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.padding = -2
end

return Public