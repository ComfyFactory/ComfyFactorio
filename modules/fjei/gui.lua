local Functions = require "modules.fjei.functions"
local math_ceil = math.ceil
local string_find = string.find
local table_remove = table.remove
local height = 492
local width = 360
local recipe_window_width = 480
local column_count = 8
local line_count = 4
local items_per_page = column_count * line_count
local Public = {}

local function get_total_page_count(player)
	if not global.fjei.player_data[player.index].filtered_list then Functions.set_filtered_list(player) end
	local count = math_ceil(global.fjei.player_data[player.index].size_of_filtered_list / items_per_page)
	if count < 1 then count = 1 end
	return count
end

local function set_page_count_caption(player)
	if not player.gui.left.fjei_main_window then return end
	if not global.fjei.player_data[player.index].filtered_list then Functions.set_filtered_list(player) end
	local active_page = global.fjei.player_data[player.index].active_page
	local element = player.gui.left.fjei_main_window.fjei_main_window_control_table.fjei_main_window_page_counter
	element.caption = "Page " .. active_page .. " of " .. get_total_page_count(player)
end

local function get_localised_name(name)
	local item = game.item_prototypes[name]
	if item then return item.localised_name end
	local fluid = game.fluid_prototypes[name]
	if fluid then return fluid.localised_name end
	local recipe = game.recipe_prototypes[name]
	if recipe then return recipe.localised_name end
	return name
end

local function get_sprite_type(name)
	if game.item_prototypes[name] then return "item" end
	if game.fluid_prototypes[name] then return "fluid" end
	if game.entity_prototypes[name] then return "entity" end
	if game.recipe_prototypes[name] then return "recipe" end
	return false
end

local function add_sprite_icon(element, name, is_recipe)
	local sprite_type = false
	if is_recipe then
		sprite_type = "recipe"
	else
		sprite_type = get_sprite_type(name)
	end

	if not sprite_type then return end
	local sprite = element.add({type = "sprite", name = name, sprite = sprite_type .. "/" .. name, tooltip = name})
	sprite.style.minimal_width = 32
	sprite.style.minimal_height = 32
	sprite.style.maximal_width = 32
	sprite.style.maximal_height = 32
	sprite.style.margin = 4	
end

local function display_item_list(player)
	if not player.gui.left.fjei_main_window then return end
	if not global.fjei.player_data[player.index].filtered_list then Functions.set_filtered_list(player) end
	
	local active_page = global.fjei.player_data[player.index].active_page
	local starting_index = 1 + (active_page - 1) * items_per_page
	local sorted_item_list = global.fjei.sorted_item_list
	local filtered_list = global.fjei.player_data[player.index].filtered_list	
	local item_list_table = player.gui.left.fjei_main_window.fjei_main_window_item_list_table
	item_list_table.clear()	
	
	for i = starting_index, starting_index + items_per_page - 1, 1 do
		if not filtered_list[i] then return end
		add_sprite_icon(item_list_table, sorted_item_list[filtered_list[i]], false)	
	end
end

local function display_history(player)
	if not player.gui.left.fjei_main_window then return end
	local player_data = global.fjei.player_data[player.index]
	local history = player_data.history	
	if not history then return end
	local history_table = player.gui.left.fjei_main_window.fjei_main_window_history_table
	history_table.clear()	
	
	for i = player_data.size_of_history - 8, player_data.size_of_history, 1 do
		local name = history[i]
		if name then
			add_sprite_icon(history_table, name, false)
		end
	end
end

function Public.refresh_main_window(player)
	set_page_count_caption(player)
	display_item_list(player)
	display_history(player)
end

local function draw_main_window(player)
	if player.gui.left["fjei_main_window"] then player.gui.left["fjei_main_window"].destroy() end
	local frame = player.gui.left.add({type = "frame", name = "fjei_main_window", direction = "vertical"})
	frame.style.minimal_width = width
	frame.style.maximal_height = height
	frame.style.maximal_width = width
	frame.style.padding = 4
	frame.style.margin = 2
	
	local t = frame.add({type = "table", name = "fjei_main_window_control_table",  column_count = 4})
	local element = t.add({type = "label", name = "fjei_main_window_page_counter",  caption = " "})
	element.style.font = "heading-2"
	element.style.font_color = {222, 222, 222}
	element.style.right_margin = 4
	
	local element = t.add({type = "sprite-button", name = "fjei_main_window_previous_page", caption = "←"})
	element.style.font = "heading-1"
	element.style.maximal_height = 32
	element.style.maximal_width = 32
	local element = t.add({type = "sprite-button", name = "fjei_main_window_next_page", caption = "→"})
	element.style.font = "heading-1"
	element.style.maximal_height = 32
	element.style.maximal_width = 32
	local text = global.fjei.player_data[player.index].active_filter
	if not text then text = "" end
	local textfield = t.add({ type = "textfield", name = "fjei_main_window_search_textfield", text = text})
	textfield.style.left_margin = 4
	textfield.style.minimal_width = 186	
	textfield.style.maximal_width = 186
	
	frame.add({type = "line"})
		
	local t = frame.add({type = "table", name = "fjei_main_window_item_list_table", column_count = column_count})
	
	frame.add({type = "line"})
	
	local element = frame.add({type = "label", caption = "Recently looked at:"})
	element.style.font = "heading-2"
	
	local t = frame.add({type = "table", name = "fjei_main_window_history_table", column_count = column_count})
	
	Public.refresh_main_window(player)
end

local function create_recipe_window(item_name, player, button, selected_recipe)
	local mode
	if button == defines.mouse_button_type.left then mode = "product" else mode = "ingredient" end
	
	if selected_recipe then
		local recipe_window = player.gui.center["fjei_recipe_window"]
		item_name = recipe_window.t1.children[1].name
		local a, b = string_find(recipe_window.t1.children[2].caption, "product")
		if a then mode = "product" else mode = "ingredient" end
	end
	
	local category_string
	local recipes
	if global.fjei.item_list[item_name] then
		if mode == "product" then
			recipes = global.fjei.item_list[item_name][1]
			category_string = "is product of: "		
		else
			recipes = global.fjei.item_list[item_name][2]
			category_string = "is ingredient in: "
		end
	end
	if #recipes == 0 then return end
	
	if selected_recipe then Functions.shift_recipe_forward(recipes, selected_recipe) end

	local recipe = recipes[1]
	
	recipe = game.recipe_prototypes[recipe]
	local machines = Functions.get_crafting_machines_for_recipe(player.force.name, recipe)
	--if #machines == 0 then return end
	local products = recipe.products
	local ingredients = recipe.ingredients
	
	if player.gui.center["fjei_recipe_window"] then player.gui.center["fjei_recipe_window"].destroy() end
	local frame = player.gui.center.add({type = "frame", name = "fjei_recipe_window", direction = "vertical"})
	frame.style.minimal_width = recipe_window_width
	frame.style.maximal_width = recipe_window_width
	frame.style.padding = 4
	
	local t = frame.add({type = "table", name = "t1", column_count = 4})
	add_sprite_icon(t, item_name, false)
	local element = t.add({type = "label", caption = category_string})
	--element.style.single_line = false
	element.style.font = "heading-2"
	element.style.font_color = {222, 222, 222}
	element.style.minimal_width = 110
	element.style.maximal_width = 110
	
	local scroll_pane = t.add({ type = "scroll-pane", name = "scroll_pane", horizontal_scroll_policy = "always", vertical_scroll_policy = "never"})	
	scroll_pane.style.minimal_width = recipe_window_width - 210
	scroll_pane.style.maximal_width = recipe_window_width - 210
	scroll_pane.style.minimal_height = 56
	scroll_pane.style.maximal_height = 56
	local tt = scroll_pane.add({type = "table", name = "fjei_recipe_window_select_table", column_count = 256}) 
	for _, recipe_name in pairs(recipes) do
		--local machines = Functions.get_crafting_machines_for_recipe(player.force.name, game.recipe_prototypes[recipe_name])
		--if #machines > 0 then
		add_sprite_icon(tt, recipe_name, true) 
		--end		
	end
	
	local element = t.add {type = "sprite-button", caption = "X", name = "fjei_close_recipe_window"}
	element.style.font = "heading-1"
	element.style.margin = 4
	element.style.minimal_width = 32
	element.style.maximal_width = 32
	element.style.minimal_height = 32
	element.style.maximal_height = 32
	
	frame.add({type = "line"})
	
	local t = frame.add({type = "table", column_count = 2})	
	add_sprite_icon(t, recipe.name, true)
	
	local tt = t.add({type = "table", column_count = 1})
	local ttt = tt.add({type = "table", column_count = 2})	
	local element = ttt.add({type = "label", caption = recipe.localised_name})
	element.style.font = "heading-1"
	local element = ttt.add({type = "label", caption = " (" .. recipe.name .. ")"})
	element.style.font = "heading-2"
	local element = tt.add({type = "label", caption = recipe.energy .. " seconds crafting time"})
	element.style.font = "default"

	frame.add({type = "line"})
		
	local element = frame.add({type = "label", caption = "Products:"})
	element.style.font = "heading-2"		
	local t = frame.add({type = "table", column_count = 2})
	
	for _, product in pairs(products) do
		local tt = t.add({type = "table", column_count = 3})
		local element = tt.add({type = "label", caption = product.amount * product.probability .. " x "})
		element.style.minimal_width = 32
		element.style.horizontal_align = "right"
		add_sprite_icon(tt, product.name)
		local element = tt.add({type = "label", caption = get_localised_name(product.name)})
		element.style.minimal_width = recipe_window_width * 0.5 - 82
		element.style.maximal_width = recipe_window_width * 0.5 - 82
		element.style.single_line = false
		element.style.font = "default"
	end
	
	local element = frame.add({type = "label", caption = "Ingredients:"})
	element.style.font = "heading-2"		
	local t = frame.add({type = "table", column_count = 2})
	
	for key, ingredient in pairs(ingredients) do
		local tt = t.add({type = "table", column_count = 3})
		local element = tt.add({type = "label", caption = ingredient.amount .. " x "})
		element.style.minimal_width = 32
		element.style.horizontal_align = "right"
		
		add_sprite_icon(tt, ingredient.name)
		local element = tt.add({type = "label", caption = get_localised_name(ingredient.name)})
		element.style.minimal_width = recipe_window_width * 0.5 - 82
		element.style.maximal_width = recipe_window_width * 0.5 - 82
		element.style.single_line = false
		element.style.font = "default"
	end
	
	frame.add({type = "line"})
	
	local element = frame.add({type = "label", caption = "Made by:"})
	element.style.font = "heading-2"		
	local t = frame.add({type = "table", column_count = 2})
	
	for key, machine in pairs(machines) do
		local prototype = game.entity_prototypes[machine]
		if prototype then
			local tt = t.add({type = "table", column_count = 2})
			add_sprite_icon(tt, machine)
			local element = tt.add({type = "label", caption = prototype.localised_name})
			element.style.minimal_width = recipe_window_width * 0.5 - 85
			element.style.maximal_width = recipe_window_width * 0.5 - 85
			element.style.single_line = false
			element.style.font = "default"
		end
	end
	
	return true
end

local function toggle_main_window(element, player, button)
	if player.gui.left.fjei_main_window then
		player.gui.left.fjei_main_window.destroy()
		if player.gui.center.fjei_recipe_window then player.gui.center.fjei_recipe_window.destroy() end
	else
		draw_main_window(player)	
	end
	return true
end

local function main_window_next_page(element, player, button)
	local player_data = global.fjei.player_data[player.index]
	if button == defines.mouse_button_type.right then
		for _ = 1, 5, 1 do
			if player_data.active_page == get_total_page_count(player) then
				player_data.active_page = 1
			else
				player_data.active_page = player_data.active_page + 1
			end	
		end
	else
		if player_data.active_page == get_total_page_count(player) then
			player_data.active_page = 1
		else
			player_data.active_page = player_data.active_page + 1
		end	
	end
	Public.refresh_main_window(player)
end

local function main_window_previous_page(element, player, button)
	local player_data = global.fjei.player_data[player.index]
	if button == defines.mouse_button_type.right then
		for _ = 1, 5, 1 do
			if player_data.active_page == 1 then
				player_data.active_page = get_total_page_count(player)
			else
				player_data.active_page = player_data.active_page - 1
			end
		end
	else
		if player_data.active_page == 1 then
			player_data.active_page = get_total_page_count(player)
		else
			player_data.active_page = player_data.active_page - 1
		end
	end		
	Public.refresh_main_window(player)
end

local function clear_search_textfield(element, player, button)
	if button ~= defines.mouse_button_type.right then return end
	global.fjei.player_data[player.index].active_filter = false
	element.text = ""
	Functions.set_filtered_list(player)
	Public.refresh_main_window(player)
end

local function close_recipe_window(element, player, button)
	element.parent.parent.destroy()
end

local gui_actions = {
	["fjei_toggle_button"] = toggle_main_window,
	["fjei_main_window_next_page"] = main_window_next_page,
	["fjei_main_window_previous_page"] = main_window_previous_page,
	["fjei_main_window_search_textfield"] = clear_search_textfield,
	["fjei_close_recipe_window"] = close_recipe_window,
}

function Public.gui_click_actions(element, player, button)
	if not gui_actions[element.name] then return end
	gui_actions[element.name](element, player, button)
	return true
end

function Public.draw_top_toggle_button(player)
	if player.gui.top["fjei_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "fjei_toggle_button", caption = "FJEI"})
	button.style.font = "heading-1"
	button.style.font_color = {222, 222, 222}
	button.style.minimal_height = 38
	button.style.minimal_width = 50
	button.style.padding = -2
end

local function add_to_history(item_name, player)
	--if not game.recipe_prototypes[recipe_name] then return end

	local player_data = global.fjei.player_data[player.index]
	if not player_data.history then
		player_data.history = {item_name}
		player_data.size_of_history = 1
		return
	end
	
	--avoid double elements
	for _, v in pairs(player_data.history) do
		if v == item_name then return end
	end
	
	player_data.size_of_history = player_data.size_of_history + 1
	player_data.history[player_data.size_of_history] = item_name	
	if player_data.size_of_history > column_count then player_data.history[player_data.size_of_history - column_count] = nil end
end

function Public.open_recipe(element, player, button)
	local item_name = element.name
	local selected_recipe = false
	if element.parent then
		if element.parent.name == "fjei_recipe_window_select_table" then selected_recipe = item_name end
	end
	add_to_history(item_name, player)
	if not create_recipe_window(item_name, player, button, selected_recipe) then return end
	display_history(player)	
end

return Public