local Public = {}

local function is_recipe_valid(force_name, name)
	local force_recipes = game.forces[force_name].recipes
	if not force_recipes[name] then return end
	if not force_recipes[name].enabled then return end
	if force_recipes[name].hidden then return end 
	return true
end

function Public.get_crafting_machines_for_recipe(force_name, recipe)
	local crafting_machine_list = global.fjei[force_name].crafting_machines
	local recipe_category = recipe.category
	local machine_names = {}
	local i = 1
	for _, name in pairs(crafting_machine_list) do
		if is_recipe_valid(force_name, name) or name == "character" then
			local crafting_categories = game.entity_prototypes[name].crafting_categories
			for category, _ in pairs(crafting_categories) do
				if recipe_category == category then
					machine_names[i] = name
					i = i + 1
					break
				end
			end
		end
	end
	return machine_names
end

function Public.set_crafting_machines(force_name)
	if not global.fjei[force_name] then global.fjei[force_name] = {} end	
	global.fjei[force_name].crafting_machines = {}
	
	local list = global.fjei[force_name].crafting_machines
	local i = 1
	for _, prototype in pairs(game.entity_prototypes) do
		if prototype.crafting_categories then
			list[i] = prototype.name
			i = i + 1
		end
	end
end

function Public.set_base_item_list(force_name)
	if not global.fjei[force_name] then global.fjei[force_name] = {} end	
	global.fjei[force_name].item_list = {}
	
	local list = global.fjei[force_name].item_list
	local i = 1
	for name, prototype in pairs(game.recipe_prototypes) do
		if is_recipe_valid(force_name, name) then
			--local machines = Public.get_crafting_machines_for_recipe(force_name, prototype)
			--if #machines > 0 then
				list[i] = name
				i = i + 1
			--end
		end
	end
	table.sort(list, function (a, b) return a < b end)
	global.fjei.size_of_item_list = #list
end

function Public.set_filtered_list(player)
	local player_data = global.fjei.player_data[player.index]
	local active_filter = player_data.active_filter
	local base_list = global.fjei[player.force.name].item_list
	player_data.active_page = 1
	player_data.filtered_list = {}
	local filtered_list = player_data.filtered_list
	local i = 1
	for key, name in pairs(base_list) do
		if active_filter then
			local a, b = string.find(name, active_filter)
			if a then
				filtered_list[i] = key
				i = i + 1
			end
		else
			filtered_list[i] = key
			i = i + 1
		end
	end
	player_data.size_of_filtered_list = #player_data.filtered_list
end

return Public