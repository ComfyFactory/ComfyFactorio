local event = require 'utils.event' 

local gui_values = {
		["north"] = {c1 = "Team North", color1 = {r = 0.55, g = 0.55, b = 0.99}},
		["south"] = {c1 = "Team South", color1 = {r = 0.99, g = 0.33, b = 0.33}}
	}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end
	
local function create_victory_gui(player)	
	local values = gui_values[global.bb_game_won_by_team]
	local frame = player.gui.left.add {type = "frame", name = "bb_victory_gui", direction = "vertical", caption = values.c1 .. " team has won!" }
	frame.style.font = "heading-1"
	frame.style.font_color = values.color1
end

local function destroy_entity(e)
	if not e.valid then return end
	local names = {"big-artillery-explosion", "big-explosion", "big-explosion", "big-explosion", "fire-flame", "massive-explosion"}
	e.surface.create_entity({name = names[math.random(1,#names)], position = e.position})
	e.die()
end

local function annihilate_base(center_pos, surface, force_name)	
	local entities = {}
	for _, e in pairs(surface.find_entities_filtered({force = force_name, area = {{center_pos.x - 64, center_pos.y - 64},{center_pos.x + 64, center_pos.y + 64}}})) do
		if e.name ~= "player" then
			if e.valid then
				local distance_to_center = math.ceil(math.sqrt((e.position.x - center_pos.x)^2 + (e.position.y - center_pos.y)^2))
				if not entities[distance_to_center] then entities[distance_to_center] = {} end
				entities[distance_to_center][#entities[distance_to_center] + 1] = e
			end
		end
	end
	
	if #entities == 0 then return end
	
	local t = 1
	for i1, entity_list in pairs(entities) do
		for i2, e in pairs(entity_list) do
			if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end			
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = destroy_entity,
				args = {e}
			}
			t = t + 3
		end
	end
end

local function create_fireworks_rocket(surface, position)
	local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
	local particle = particles[math.random(1, #particles)]
	local m = math.random(16, 36)
	local m2 = m * 0.005
				
	for i = 1, 60, 1 do 
		surface.create_entity({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
		})
	end
	
	if math.random(1,12) ~= 1 then return end
	surface.create_entity({name = "explosion", position = position})
end

local function fireworks(surface)
	local radius = 52
	local pos = global.rocket_silo[global.bb_game_won_by_team].position
	for t = 1, 10800, 1 do
		if t % 3 == 0 then
			if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = create_fireworks_rocket,
				args = {
					surface,
					{x = (pos.x - radius) + math.random(0, radius * 2),y = (pos.y - radius) + math.random(0, radius * 2)}
				}
			}
		end
	end
end

local function get_sorted_list(column_name, score_list)		
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
	return score_list
end

local function get_mvps(force)
	if not global.score[force] then return false end
	local score = global.score[force]
	local score_list = {}
	for _, p in pairs(game.players) do
		if score.players[p.name] then
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
	end
	local mvp = {}
	score_list = get_sorted_list("killscore", score_list)
	mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
	score_list = get_sorted_list("deaths", score_list)
	mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
	score_list = get_sorted_list("built_entities", score_list)
	mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
	return mvp
end

local function show_mvps(player)
	if not global.score then return end
	if player.gui.left["mvps"] then return end
	local frame = player.gui.left.add({type = "frame", name = "mvps", direction = "vertical"})
	local l = frame.add({type = "label", caption = "MVPs - North:"})
	l.style.font = "default-listbox"
	l.style.font_color = {r = 0.55, g = 0.55, b = 0.99}
		
	local t = frame.add({type = "table", column_count = 2})
	local mvp = get_mvps("north")		
	if mvp then
		
		local l = t.add({type = "label", caption = "Defender >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.killscore.name .. " with a score of " .. mvp.killscore.score})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Builder >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things"})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Deaths >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.deaths.name .. " died " .. mvp.deaths.score .. " times"})						
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		if not global.results_sent_north then
			local result = {}
			table.insert(result, 'NORTH: \\n')
			table.insert(result, 'MVP Defender: \\n')
			table.insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Builder: \\n')
			table.insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Deaths: \\n')
			table.insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
			local message = table.concat(result)
			server_commands.to_discord_embed(message)
			global.results_sent_north = true
		end
	end
	
	local l = frame.add({type = "label", caption = "MVPs - South:"})
	l.style.font = "default-listbox"
	l.style.font_color = {r = 0.99, g = 0.33, b = 0.33}
	
	local t = frame.add({type = "table", column_count = 2})
	local mvp = get_mvps("south")		
	if mvp then			
		local l = t.add({type = "label", caption = "Defender >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.killscore.name .. " with a score of " .. mvp.killscore.score})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Builder >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things"})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Deaths >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.deaths.name .. " died " .. mvp.deaths.score .. " times"})						
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		if not global.results_sent_south then
			local result = {}
			table.insert(result, 'SOUTH: \\n')
			table.insert(result, 'MVP Defender: \\n')
			table.insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Builder: \\n')
			table.insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Deaths: \\n')
			table.insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
			local message = table.concat(result)
			server_commands.to_discord_embed(message)
			global.results_sent_south = true
		end
	end
end

local enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

local function server_restart()
	if not global.server_restart_timer then return end
	global.server_restart_timer = global.server_restart_timer - 5
	if global.server_restart_timer == 180 then return end
	if global.server_restart_timer == 0 then
		game.print("Map is restarting!", {r=0.22, g=0.88, b=0.22})
		local message = 'Map is restarting! '
		server_commands.to_discord_bold(table.concat{'*** ', message, ' ***'})
		server_commands.start_scenario('Biter_Battles')
		global.server_restart_timer = nil
		return
	end
	if global.server_restart_timer % 30 == 0 then
		game.print("Map will restart in " .. global.server_restart_timer .. " seconds!", {r=0.22, g=0.88, b=0.22})		
	end
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	if event.entity.name ~= "rocket-silo" then return end
	if global.bb_game_won_by_team then return end
	if event.entity == global.rocket_silo.south or event.entity == global.rocket_silo.north then
		global.bb_game_won_by_team = enemy_team_of[event.entity.force.name]
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_won", volume_modifier=1}
			if player.gui.left["bb_main_gui"] then player.gui.left["bb_main_gui"].destroy() end
			create_victory_gui(player)
			show_mvps(player)
		end
		
		game.forces["north_biters"].set_friend("north", true)
		game.forces["north"].set_friend("north_biters", true)
		game.forces["south_biters"].set_friend("south", true)
		game.forces["south"].set_friend("south_biters", true)
		global.spy_fish_timeout["north"] = game.tick + 999999
		global.spy_fish_timeout["south"] = game.tick + 999999
		global.server_restart_timer = 180
		
		fireworks(event.entity.surface)
		annihilate_base(event.entity.position, event.entity.surface, event.entity.force.name)			
	end
end

event.add(defines.events.on_entity_died, on_entity_died)

return server_restart