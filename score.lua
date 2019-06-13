--scoreboard by mewmew

local event = require 'utils.event'
local sorting_symbol = {ascending = "▲", descending = "▼"}

local function create_score_button(player)
	if not player.gui.top.score then
		local button = player.gui.top.add({ type = "sprite-button", name = "score", sprite = "item/rocket-silo", tooltip = "Scoreboard" })
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function get_score_list(force)
	local score = global.score[force]
	local score_list = {}
	for _, p in pairs(game.connected_players) do
		if score.players[p.name] then
			local score = score.players[p.name]
			table.insert(score_list, {
				name = p.name,
				killscore = score.killscore or 0,
				deaths = score.deaths or 0,
				built_entities = score.built_entities or 0,
				mined_entities = score.mined_entities or 0,
			})
		end
	end
	return score_list
end

local function get_sorted_list(method, column_name, score_list)
	local comparators = {
		["ascending"]  = function(a,b) return a[column_name] < b[column_name] end,
		["descending"] = function(a,b) return a[column_name] > b[column_name] end
	}
	table.sort(score_list, comparators[method])
	return score_list
end

local biters = {"small-biter", "medium-biter", "big-biter", "behemoth-biter", "small-spitter", "medium-spitter", "big-spitter", "behemoth-spitter"}
local function get_total_biter_killcount(force)
	local count = 0
	for _, biter in pairs(biters) do
		count = count + force.kill_count_statistics.get_input_count(biter)
	end
	return count
end

local function add_global_stats(frame, player)
	local score = global.score[player.force.name]
	local t = frame.add { type = "table", column_count = 5}

	local l = t.add { type = "label", caption = "Rockets launched: "}
	l.style.font = "default-game"
	l.style.font_color = {r = 175, g = 75, b = 255}
	l.style.minimal_width = 140

	local str = "0"
	if score.rocket_launches then str = tostring(score.rocket_launches) end
	local l = t.add { type = "label", caption = str}
	l.style.font = "default-listbox"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 123

	local l = t.add { type = "label", caption = "Dead biters: "}
	l.style.font = "default-game"
	l.style.font_color = { r=0.90, g=0.3, b=0.3}
	l.style.minimal_width = 100

	local l = t.add { type = "label", caption = tostring(get_total_biter_killcount(player.force))}
	l.style.font = "default-listbox"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 145

	local l = t.add { type = "checkbox", caption = "Show floating numbers", state = global.show_floating_killscore[player.name], name = "show_floating_killscore_texts"	}
	l.style.font_color = { r=0.8, g=0.8, b=0.8}
end

local function show_score(player)
	if player.gui.left["score_panel"] then
		player.gui.left["score_panel"].destroy()
	end

	local frame = player.gui.left.add { type = "frame", name = "score_panel", direction = "vertical" }

	-- Global stats : rockets, biters kills
	add_global_stats(frame, player)

	-- Separator
	local l = frame.add { type = "label", caption = "---------------------------------------------------------------------------------------------------------------"}
	l.style.font_color = { r=0.9, g=0.9, b=0.9 }

	-- Score per player
	local t = frame.add { type = "table", column_count = 5 }

	-- Score headers
	local headers = {
		{ name = "score_player", caption = "Player" },
		{ column = "killscore", name = "score_killscore", caption = "Killscore" },
		{ column = "deaths", name = "score_deaths", caption = "Deaths" },
		{ column = "built_entities", name = "score_built_entities", caption = "Built structures" },
		{ column = "mined_entities", name = "score_mined_entities", caption = "Mined entities" }
	}

	local sorting_pref = global.score_sort_by[player.name]
	for _, header in ipairs(headers) do
		local cap = header.caption

		-- Add sorting symbol if any
		if header.column and sorting_pref.column == header.column then
			local symbol = sorting_symbol[sorting_pref.method]
			cap = symbol .. cap
		end

		-- Header
		local label = t.add {
			type = "label",
			caption = cap,
			name = header.name
		}
		label.style.font = "default-listbox"
		label.style.font_color = { r=0.98, g=0.66, b=0.22 } -- yellow
		label.style.minimal_width = 140
	end

	-- Score list
	local score_list = get_score_list(player.force.name)

	if #game.connected_players > 1 then
		score_list = get_sorted_list(sorting_pref.method, sorting_pref.column, score_list)
	end

	-- New pane for scores (while keeping headers at same position)
	local scroll_pane = frame.add({ type = "scroll-pane", name = "score_scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	scroll_pane.style.maximal_height = 400
	local t = scroll_pane.add { type = "table", column_count = 5}

	-- Score entries
	for _, entry in pairs(score_list) do
		local p = game.players[entry.name]
		local special_color = {
			r = p.color.r * 0.6 + 0.4,
			g = p.color.g * 0.6 + 0.4,
			b = p.color.b * 0.6 + 0.4,
			a = 1
		}
		local line = {
			{ caption = entry.name, color = special_color },
			{ caption = tostring(entry.killscore) },
			{ caption = tostring(entry.deaths) },
			{ caption = tostring(entry.built_entities) },
			{ caption = tostring(entry.mined_entities) }
		}
		local default_color = { r=0.9, g=0.9, b=0.9 }

		for _, column in ipairs(line) do
			local label = t.add {
				type = "label",
				caption = column.caption,
				color = column.color or default_color
			}
			label.style.font = "default"
			label.style.minimal_width = 140
			label.style.maximal_width = 140
		end -- foreach column
	end -- foreach entry
end -- show_score

local function refresh_score_full()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["score_panel"] then
			show_score(player)
		end
	end
end

--[[
local function refresh_score()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["score_panel"] then
			if global.score[player.force.name].rocket_launches then player.gui.left["score_panel"].children[1].children[2].caption = global.score[player.force.name].rocket_launches end
			player.gui.left["score_panel"].children[1].children[4].caption = get_total_biter_killcount(player.force)
			local score = global.score[player.force.name]
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
			local index = 1
			for _, entry in pairs(score_list) do
				player.gui.left["score_panel"].children[4].children[1].children[index].caption = entry.name
				local p = game.players[entry.name]
				local color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
				player.gui.left["score_panel"].children[4].children[1].children[index].style.font_color = color
				index = index + 1
				player.gui.left["score_panel"].children[4].children[1].children[index].caption = tostring(entry.killscore)
				index = index + 1
				player.gui.left["score_panel"].children[4].children[1].children[index].caption = tostring(entry.deaths)
				index = index + 1
				player.gui.left["score_panel"].children[4].children[1].children[index].caption = tostring(entry.built_entities)
				index = index + 1
				player.gui.left["score_panel"].children[4].children[1].children[index].caption = tostring(entry.mined_entities)
				index = index + 1
			end
		end
	end
end
]]

local function init_player_table(player)
	if not player then return end
	if not global.score[player.force.name] then global.score[player.force.name] = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players = {} end
	if not global.score[player.force.name].players[player.name] then global.score[player.force.name].players[player.name] = {} end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.score then global.score = {} end
	init_player_table(player)
	if not global.score_sort_by then global.score_sort_by = {} end
	if not global.score_sort_by[player.name] then
		global.score_sort_by[player.name] = {method = "descending", column = "killscore"}
	end
	if not global.show_floating_killscore then global.show_floating_killscore = {} end
	if not global.show_floating_killscore[player.name] then global.show_floating_killscore[player.name] = false end

	create_score_button(player)
	refresh_score_full()
end

local function on_player_left_game(event)
	refresh_score_full()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end

	local player = game.players[event.element.player_index]
	local name = event.element.name

	-- Handles click on the score button
	if name == "score" then
		if player.gui.left["score_panel"] then
			player.gui.left["score_panel"].destroy()
		else
			global.score_sort_by[player.name].get_sorted_list = true
			show_score(player)
		end
		return
	end

	-- Handles click on the checkbox, for floating score
	if name == "show_floating_killscore_texts" then
		global.show_floating_killscore[player.name] = event.element.state
		return
	end

	-- Handles click on a score header
	local element_to_column = {
		["score_killscore"] = "killscore",
		["score_deaths"] = "deaths",
		["score_built_entities"] = "built_entities",
		["score_mined_entities"] = "mined_entities"
	}
	local column = element_to_column[name]
	if column then
		local sorting_pref = global.score_sort_by[player.name]
		if sorting_pref.column == column and sorting_pref.method == "descending" then
			sorting_pref.method = "ascending"
		else
			sorting_pref.method = "descending"
			sorting_pref.column = column
		end
		show_score(player)
		return
	end

	-- No more to handle
end

local function on_rocket_launched(event)
	local force_name = event.rocket_silo.force.name
	if not global.score[force_name]
		then global.score[force_name] = {}
	end

	local force_score = global.score[force_name]
	force_score.rocket_launches = 1 + (force_score.rocket_launches or 0)
	--game.print ("A rocket has been launched!", {r=0.98, g=0.66, b=0.22})
	refresh_score_full()
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
	local player = false
	local passenger = false
	local train_passengers = false
	local proximity_list = {}

	-- Handles worm kills with no cause
	if event.entity.type == "turret" then
		local radius = 24
		local position = event.entity.position
		local insert = table.insert
		--Since we cannot reliably get the player who killed the worm, get all players in a radius and award them xp
		for _, p in pairs(game.connected_players) do
			if p.position.x < position.x + radius and p.position.x > position.x - radius and p.position.y < position.y + radius and p.position.y > position.y - radius then
				insert(proximity_list, {player = p})
			end
		end
	end

	-- Unit/Spawner Kills
	if event.entity.type == "unit" or  event.entity.type == "unit-spawner" then
		if event.cause then

			if event.cause.name == "character" then player = event.cause.player end

			--Check for passengers
			if event.cause.type == "car" then
				player = event.cause.get_driver()
				passenger = event.cause.get_passenger()
				if player then player = player.player end
				if passenger then passenger = passenger.player end
			end
			if event.cause.type == "locomotive" then
				player = event.cause.get_driver()
				train_passengers = event.cause.train.passengers
			end

			if not train_passengers and not passenger and not player then return end
			if event.cause.force.name == event.entity.force.name then return end
			init_player_table(player)
			if not global.score[event.force.name] then global.score[event.force.name] = {} end
			if not global.score[event.force.name].players then global.score[event.force.name].players = {} end
			if not global.score[event.force.name].players then global.score[event.force.name].players[player.name] = {} end
		end
	end

	if score_table[event.entity.name] then

		local show_floating_text = false
		local color = {r=0.98, g=0.66, b=0.22}
		-- Color based on main player color
		if #proximity_list <= 0 and player then
			color = player.color
			color.r = color.r * 0.6 + 0.4
			color.g = color.g * 0.6 + 0.4
			color.b = color.b * 0.6 + 0.4
		end

		local rewarded_players = {}
		if player then
			table.insert(rewarded_players, player)
		end
		for _,p in pairs(proximity_list) do
			table.insert(rewarded_players, p.player)
		end
		if passenger then
			table.insert(rewarded_players, passenger)
		end
		if train_passengers then
			for _,p in pairs(train_passengers) do
				table.insert(rewarded_players, p)
			end
		end

		-- Add killscore
		local points = score_table[event.entity.name]
		for _, p in pairs(rewarded_players) do
			-- Handles floating text
			if global.show_floating_killscore[player.name] == true then
				show_floating_text = true
			end
			-- Add
			local score = global.score[event.force.name].players[player.name]
			score.killscore = points + (score.killscore or 0)
		end

		if show_floating_text == true then
			event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = tostring(points), color = color})
		end
	end
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	init_player_table(player)
	local score = global.score[player.force.name].players[player.name]
	score.deaths = 1 + (score.deaths or 0)
end

local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	init_player_table(player)
	local score = global.score[player.force.name].players[player.name]
	score.mined_entities = 1 + (score.mined_entities or 0)
end

local function on_built_entity(event)
	if not event.created_entity.valid then return end
	if event.created_entity.type == "entity-ghost" then return end
	local player = game.players[event.player_index]
	init_player_table(player)
	local score = global.score[player.force.name].players[player.name]
	score.built_entities = 1 + (score.built_entities or 0)
end

local function on_tick(event)
	if game.tick % 300 == 0 then
		refresh_score_full()
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_player_died, on_player_died)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_rocket_launched, on_rocket_launched)
