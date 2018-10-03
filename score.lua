--scoreboard by mewmew

local event = require 'utils.event'
local sorting_symbol = {ascending = "▲", descending = "▼"}

local function create_score_button(player)
	if not player.gui.top.score then
		local button = player.gui.top.add({ type = "sprite-button", name = "score", sprite = "item/rocket-silo" })		
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function get_sorted_list(method, column_name, score_list)
	if method == "ascending" then 
		for x = 1, #score_list, 1 do
			for y = 1, #score_list, 1 do			
				if not score_list[y + 1] then break end
				if score_list[y][column_name] > score_list[y + 1][column_name] then
					local key = score_list[y]
					score_list[y] = score_list[y + 1]
					score_list[y + 1] = key
				end
			end		
		end
	end
	if method == "descending" then 
		for x = 1, #score_list, 1 do
			for y = 1, #score_list, 1 do			
				if not score_list[y + 1] then break end
				if score_list[y][column_name] < score_list[y + 1][column_name] then
					local key = score_list[y]
					score_list[y] = score_list[y + 1]
					score_list[y + 1] = key
				end
			end		
		end
	end
	return score_list
end

local function show_score(player)
	if player.gui.left["score_panel"] then player.gui.left["score_panel"].destroy() end
	local score = global.score[player.force.name]
		
	local frame = player.gui.left.add { type = "frame", name = "score_panel", direction = "vertical" }
		
	local t = frame.add { type = "table", column_count = 4}
	
	local l = t.add { type = "label", caption = "Rockets launched: "}	
	l.style.font = "default-game"			
	l.style.font_color = {r = 175, g = 75, b = 255}
	l.style.minimal_width = 140
	
	local str = "0"
	if score.rocket_launches then str = tostring(score.rocket_launches) end
	local l = t.add { type = "label", caption = str}
	l.style.font = "default-frame"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 123

	local l = t.add { type = "label", caption = "Dead biters: "}	
	l.style.font = "default-game"			
	l.style.font_color = { r=0.90, g=0.3, b=0.3}
	l.style.minimal_width = 100
	
	local str = "0"
	if score.kills then str = tostring(score.kills) end
	local l = t.add { type = "label", caption = str}
	l.style.font = "default-frame"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 30
	
	local l = frame.add { type = "label", caption = "---------------------------------------------------------------------------------------------------------------"}
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	
	local t = frame.add { type = "table", column_count = 5}
	
	local l = t.add { type = "label", caption = "Player"}	
	l.style.font = "default-listbox"			
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	l.style.minimal_width = 140
	
	local str = ""
	if global.score_sort_by[player.name].column == "killscore" then str = sorting_symbol[global.score_sort_by[player.name].method] .. " " end
	local l = t.add { type = "label", caption = str .. "Killscore", name = "score_killscore"}	
	l.style.font = "default-listbox"			
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	l.style.minimal_width = 140
	str = ""
	if global.score_sort_by[player.name].column == "deaths" then str = sorting_symbol[global.score_sort_by[player.name].method] .. " " end
	local l = t.add { type = "label", caption = str .. "Deaths", name = "score_deaths"}	
	l.style.font = "default-listbox"			
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	l.style.minimal_width = 140
	str = ""
	if global.score_sort_by[player.name].column == "built_entities" then str = sorting_symbol[global.score_sort_by[player.name].method] .. " " end
	local l = t.add { type = "label", caption = str .. "Built structures", name = "score_built_entities"}	
	l.style.font = "default-listbox"			
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	l.style.minimal_width = 140
	str = ""
	if global.score_sort_by[player.name].column == "mined_entities" then str = sorting_symbol[global.score_sort_by[player.name].method] .. " " end
	local l = t.add { type = "label", caption = str .. "Mined entities", name = "score_mined_entities"}	
	l.style.font = "default-listbox"			
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	l.style.minimal_width = 140
		
	local score_list = {}
	for _, p in pairs(game.connected_players) do
		local killscore = 0
		if score.players[p.name].killscore then killscore = score.players[p.name].killscore end
		local deaths = 0
		if score.players[p.name].deaths then deaths = score.players[p.name].deaths end
		local built_entities = 0
		if score.players[p.name].built_entities then built_entities = score.players[p.name].built_entities end
		local mined_entities = 0
		if score.players[p.name].mined_entities then mined_entities = score.players[p.name].mined_entities end
		table.insert(score_list, {name = p.name, killscore = killscore, deaths = deaths, built_entities = built_entities, mined_entities = mined_entities})		
	end
	
	if #game.connected_players > 1 then
		score_list = get_sorted_list(global.score_sort_by[player.name].method, global.score_sort_by[player.name].column, score_list)
	end
	
	for _, entry in pairs(score_list) do		
		local l = t.add { type = "label", caption = entry.name}	
		l.style.font = "default"
		local p = game.players[entry.name]
		local color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
		l.style.font_color = color
		l.style.minimal_width = 140
		l.style.maximal_width = 140

		local l = t.add { type = "label", caption = tostring(entry.killscore)}	
		l.style.font = "default"			
		l.style.font_color = { r=0.9, g=0.9, b=0.9}
		l.style.minimal_width = 140
		
		local l = t.add { type = "label", caption = tostring(entry.deaths)}	
		l.style.font = "default"			
		l.style.font_color = { r=0.9, g=0.9, b=0.9}
		l.style.minimal_width = 140
		
		local l = t.add { type = "label", caption = tostring(entry.built_entities)}	
		l.style.font = "default"			
		l.style.font_color = { r=0.9, g=0.9, b=0.9}
		l.style.minimal_width = 140

		local l = t.add { type = "label", caption = tostring(entry.mined_entities)}	
		l.style.font = "default"			
		l.style.font_color = { r=0.9, g=0.9, b=0.9}
		l.style.minimal_width = 140
		
	end	
end

function refresh_score()
	for _, p in pairs(game.connected_players) do
		if p.gui.left["score_panel"] then
			show_score(p)
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.score then global.score = {} end
	if not global.score[player.force.name] then global.score[player.force.name] = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players = {} end	
	if not global.score[player.force.name].players[player.name] then global.score[player.force.name].players[player.name] = {} end	
	if not global.score_sort_by then global.score_sort_by = {} end
	if not global.score_sort_by[player.name] then
		global.score_sort_by[player.name] = {method = "descending", column = "killscore"}
	end	
	create_score_button(player)
	
end

local function on_player_left_game(event)
	refresh_score()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	
	local player = game.players[event.element.player_index]
	local name = event.element.name		
	
	if name == "score" then			
		if player.gui.left["score_panel"] then
			player.gui.left["score_panel"].destroy()
		else
			global.score_sort_by[player.name].get_sorted_list = true
			show_score(player)
		end
	end
	
	local int_sort_columns = {"score_killscore", "killscore", "score_deaths", "deaths", "score_built_entities", "built_entities", "score_mined_entities", "mined_entities"}
	for x = 1, #int_sort_columns, 2 do
		if name == int_sort_columns[x] then		
			if global.score_sort_by[player.name].column == int_sort_columns[x + 1] then
				if global.score_sort_by[player.name].method == "ascending" then
					global.score_sort_by[player.name].method = "descending"
				else
					global.score_sort_by[player.name].method = "ascending"
				end
			else
				global.score_sort_by[player.name] = {method = "descending", column = int_sort_columns[x + 1]}
			end
			show_score(player)		
		end	
	end
end

local function on_rocket_launched(event)
	local force_name = event.rocket_silo.force.name
	if not global.score[force_name] then global.score[force_name] = {} end
	if not global.score[force_name].rocket_launches then
		global.score[force_name].rocket_launches = 1
	else
		global.score[force_name].rocket_launches = global.score[force_name].rocket_launches + 1
	end	
	game.print ("A rocket has been launched!", {r=0.98, g=0.66, b=0.22})	
	
	refresh_score()
end

local score_table = {
	["small-biter"] = 5,
	["medium-biter"] = 15,
	["big-biter"] = 30,
	["behemoth-biter"] = 100,
	["small-spitter"] = 5,
	["medium-spitter"] = 15,
	["big-spitter"] = 30,
	["behemoth-spitter"] = 100,
	["biter-spawner"] = 200,
	["spitter-spawner"] = 200,
	["small-worm-turret"] = 50,
	["medium-worm-turret"] = 150,
	["big-worm-turret"] = 300,
	["player"] = 1000
}

local function on_entity_died(event)	
	if not event.cause then return end
	local player = false
	local passenger = false
	local train_passengers = false
	if event.cause.name == "player" then player = event.cause.player end	
	if event.cause.type == "car" then
		player = event.cause.get_driver()
		passenger = event.cause.get_passenger()
		if player then player = player.player end
		if passenger then passenger = passenger.player end
	end
	if event.cause.type == "locomotive" then
		train_passengers = event.cause.train.passengers
	end
	if not train_passengers and not passenger and not player then return end
	if event.cause.force.name == event.entity.force.name then return end
	if not global.score[event.force.name] then global.score[event.force.name] = {} end
	if not global.score[event.force.name].players then global.score[event.force.name].players = {} end
	if not global.score[event.force.name].players then global.score[event.force.name].players[player.name] = {} end
	
	if score_table[event.entity.name] then
	
		if not global.score[event.force.name].kills then
			global.score[event.force.name].kills = 1
		else
			global.score[event.force.name].kills = global.score[event.force.name].kills + 1
		end
		
		if player then
			if not global.score[event.force.name].players[player.name].killscore then
				global.score[event.force.name].players[player.name].killscore = score_table[event.entity.name]
			else
				global.score[event.force.name].players[player.name].killscore = global.score[event.force.name].players[player.name].killscore + score_table[event.entity.name]
			end
		end
		
		if passenger then
			if not global.score[event.force.name].players[passenger.name].killscore then
				global.score[event.force.name].players[passenger.name].killscore = score_table[event.entity.name]
			else
				global.score[event.force.name].players[passenger.name].killscore = global.score[event.force.name].players[passenger.name].killscore + score_table[event.entity.name]
			end
		end
		
		if train_passengers then
			for _, player in pairs(train_passengers) do
				if not global.score[event.force.name].players[player.name].killscore then
					global.score[event.force.name].players[player.name].killscore = score_table[event.entity.name]
				else
					global.score[event.force.name].players[player.name].killscore = global.score[event.force.name].players[player.name].killscore + score_table[event.entity.name]
				end
			end
		end
		
		event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = tostring(score_table[event.entity.name]), color = {r=0.98, g=0.66, b=0.22}})
	end
	refresh_score()
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	if not global.score[player.force.name] then global.score[player.force.name] = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players[player.name] = {} end
	if not global.score[player.force.name].players[player.name].deaths then
		global.score[player.force.name].players[player.name].deaths = 1
	else
		global.score[player.force.name].players[player.name].deaths = global.score[player.force.name].players[player.name].deaths + 1
	end
	refresh_score()
end

local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	if not global.score[player.force.name] then global.score[player.force.name] = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players[player.name] = {} end
	if not global.score[player.force.name].players[player.name].mined_entities then
		global.score[player.force.name].players[player.name].mined_entities = 1
	else
		global.score[player.force.name].players[player.name].mined_entities = global.score[player.force.name].players[player.name].mined_entities + 1
	end
	refresh_score()
end

local function on_built_entity(event)	
	local player = game.players[event.player_index]
	if not global.score[player.force.name] then global.score[player.force.name] = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players[player.name] = {} end
	if not global.score[player.force.name].players[player.name].built_entities then
		global.score[player.force.name].players[player.name].built_entities = 1
	else
		global.score[player.force.name].players[player.name].built_entities = global.score[player.force.name].players[player.name].built_entities + 1
	end	
	refresh_score()
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_player_died, on_player_died)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_rocket_launched, on_rocket_launched)