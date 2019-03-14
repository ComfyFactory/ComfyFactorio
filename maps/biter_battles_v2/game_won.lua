local event = require 'utils.event' 

local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
local function create_fireworks_rocket(surface, position)
	local particle = particles[math_random(1, #particles)]
	local m = math_random(16, 36)
	local m2 = m * 0.005
				
	for i = 1, 80, 1 do 
		surface.create_entity({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
	
	if math_random(1,16) ~= 1 then return end
	surface.create_entity({name = "explosion", position = position})
end

local function fireworks(surface)
	local radius = 96
	for t = 1, 18000, 1 do
		if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
		for x = 1, 3, 1 do
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = create_fireworks_rocket,
				args = {surface, {x = radius - math_random(0, radius * 2),y = radius - math_random(0, radius * 2)}}
			}								
		end
		t = t + 1
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
			insert(result, 'NORTH: \\n')
			insert(result, 'MVP Defender: \\n')
			insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Builder: \\n')
			insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Deaths: \\n')
			insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
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
			insert(result, 'SOUTH: \\n')
			insert(result, 'MVP Defender: \\n')
			insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Builder: \\n')
			insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Deaths: \\n')
			insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
			local message = table.concat(result)
			server_commands.to_discord_embed(message)
			global.results_sent_south = true
		end
	end
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	if event.entity.name ~= "rocket-silo" then return end	
	if event.entity == global.rocket_silo.south or event.entity == global.rocket_silo.north then 					
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_won", volume_modifier=1}
		end
		show_mvps(player)
		fireworks(surface)
	end		
end

event.add(defines.events.on_entity_died, on_entity_died)
