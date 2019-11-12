local table_insert = table.insert
local string_find = string.find

local Public = {}

local function is_recipe_valid(force_name, name)
	local force_recipes = game.forces[force_name].recipes
	if not force_recipes[name] then return end
	return true
end

function Public.shift_recipe_forward(recipes, selected_recipe)
	local t = {}
	table_insert(t, selected_recipe)
	for k, v in pairs(recipes) do
		if v ~= selected_recipe then table_insert(t, v) end
	end
	for k, v in pairs(recipes) do
		recipes[k] = t[k]
	end
end

function Public.get_crafting_machines_for_recipe(force_name, recipe)
	local item_whitelist = global.fjei.item_whitelist[force_name]
	local crafting_machines = global.fjei.crafting_machines
	local recipe_category = recipe.category
	local result = {}
	local i = 1
	for _, name in pairs(crafting_machines) do
		if item_whitelist[name] or name == "character" then
			local crafting_categories = game.entity_prototypes[name].crafting_categories
			for category, _ in pairs(crafting_categories) do
				if recipe_category == category then
					result[i] = name
					i = i + 1
					break
				end
			end
		end
	end
	return result
end

local function set_crafting_machines()
	global.fjei.crafting_machines = {}
	local list = global.fjei.crafting_machines
	local i = 1
	for _, prototype in pairs(game.entity_prototypes) do
		if prototype.crafting_categories then
			list[i] = prototype.name
			i = i + 1
		end
	end
end

local function add_item_list_product(item_list, product_name, recipe_name)
	if not item_list[product_name] then item_list[product_name] = {{}, {}} end
	table_insert(item_list[product_name][1], recipe_name)
end

local function add_item_list_ingredient(item_list, ingredient_name, recipe_name)
	if not item_list[ingredient_name] then item_list[ingredient_name] = {{}, {}} end
	table_insert(item_list[ingredient_name][2], recipe_name)
end

local function set_item_list()	
	global.fjei.item_list = {}		
	local item_list = global.fjei.item_list	
	for recipe_name, recipe in pairs(game.recipe_prototypes) do	
		for key, product in pairs(recipe.products) do
			add_item_list_product(item_list, product.name, recipe_name)
		end
		for key, ingredient in pairs(recipe.ingredients) do
			add_item_list_ingredient(item_list, ingredient.name, recipe_name)
		end	
	end	
end

local function set_sorted_item_list()
	global.fjei.sorted_item_list = {}
	local sorted_item_list = global.fjei.sorted_item_list
	local item_list = global.fjei.item_list	
	local i = 1
	for key, value in pairs(item_list) do
		sorted_item_list[i] = key
		i = i + 1
	end	
	table.sort(sorted_item_list, function (a, b) return a < b end)
end

local function add_recipe_to_whitelist(item_whitelist, recipe)
	for key, product in pairs(recipe.products) do
		item_whitelist[product.name] = true
	end
	for key, ingredient in pairs(recipe.ingredients) do
		item_whitelist[ingredient.name] = true
	end
end

function Public.add_research_to_whitelist(force, effects)
	if not effects then return end
	local item_whitelist = global.fjei.item_whitelist[force.name]
	local items_have_been_added = false
	for _, effect in pairs(effects) do
		if effect.recipe then
			add_recipe_to_whitelist(item_whitelist, game.recipe_prototypes[effect.recipe])
			items_have_been_added = true
		end
	end
	return items_have_been_added
end

local function set_item_whitelist(force)
	global.fjei.item_whitelist[force.name] = {}
	local item_whitelist = global.fjei.item_whitelist[force.name]
	
	for key, recipe in pairs(force.recipes) do
		if recipe.enabled and not recipe.hidden then
			add_recipe_to_whitelist(item_whitelist, recipe)
		end
	end
	
	for key, technology in pairs(force.technologies) do
		if technology.researched then
			Public.add_research_to_whitelist(force, technology.effects)
		end
	end
end

local function set_item_whitelists_for_all_forces()
	global.fjei.item_whitelist = {}
	for _, force in pairs(game.forces) do
		if force.index ~= 2 and force.index ~= 3 then
			set_item_whitelist(force)
		end
	end
end

function Public.set_filtered_list(player)
	local player_data = global.fjei.player_data[player.index]
	player_data.filtered_list = {}
	player_data.active_page = 1
	local filtered_list = player_data.filtered_list
	local active_filter = player_data.active_filter
	local sorted_item_list = global.fjei.sorted_item_list
	local item_whitelist = global.fjei.item_whitelist[player.force.name]
		
	local i = 1
	for key, name in pairs(sorted_item_list) do
		if item_whitelist[name] then
			if active_filter then
				local a, b = string_find(name, active_filter)
				if a then
					filtered_list[i] = key
					i = i + 1
				end
			else
				filtered_list[i] = key
				i = i + 1
			end
		end
	end
	player_data.size_of_filtered_list = #player_data.filtered_list
end

function Public.build_tables()
	set_item_list()										--creates list of all items as key and two tables for each key containing [1] product recipes and [2] ingredient recipes
	set_sorted_item_list()							--creates sorted list of all items in the game for faster searching
	set_crafting_machines()						--creates list of available crafting entities
	set_item_whitelists_for_all_forces()		--whitelist to only display researched items in the browser for the force
end

return Public