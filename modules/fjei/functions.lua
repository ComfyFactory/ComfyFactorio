local Public = {}

function Public.set_base_item_list()
	global.fjei.item_list = {}
	local list = global.fjei.item_list
	local i = 1
	for name, prototype in pairs(game.recipe_prototypes) do	
		list[i] = {name = name}
		i = i + 1
	end
	table.sort(list, function (a, b) return a.name < b.name end)
	global.fjei.size_of_item_list = #list
end

function Public.set_filtered_list(player)
	local player_data = global.fjei.player_data[player.index]
	local active_filter = player_data.active_filter
	local base_list = global.fjei.item_list
	player_data.active_page = 1
	player_data.filtered_list = {}
	local filtered_list = player_data.filtered_list
	local i = 1
	for key, entry in pairs(base_list) do
		if active_filter then
			local a, b = string.find(entry.name, active_filter)
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