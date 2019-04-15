local event = require 'utils.event'
local math_random = math.random

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local texts = {
	["travelings"] = {
		"bzzZZrrt",
		"vroooOOm",
		"WEEEeeeeeee",
		"out of my way son",
		"comfylatron coming through",
	},
	["greetings"] = {
		"=^_^=",
		"=^.^= Hi",
		"^.^ Finally i found you",
		"I have an important message for you",
		"Hello engineer"
	},
	["neutral_findings"] = {
		"a",
		">>analyzing",
		"i found a",
		"^_^ a",
		"amazing, a",
		"this is a"
	},
	["multiple_characters_greetings"] = {
		"Hey there",
		"Hello everyone",
		"Hey engineers",
		"Hey",
		"Hi"
	},
	["talks"] = {
		"We’re making beer. I’m the brewery!",
		"I’m so embarrassed. I wish everybody else was dead.",
		"Hey sexy mama. Wanna kill all humans?",
		"My story is a lot like yours, only more interesting ‘cause it involves robots.",
		"I'm 40% zinc!",
		"There was nothing wrong with that food. The salt level was 10% less than a lethal dose.",
		"One zero zero zero one zero one zero one zero one zero one... zero one zero one one zero zero one... two.",
		"My place is two cubic meters, and we only take up 1.5 cubic meters. We've got room for a whole 'nother two thirds of a person!",
		"I was having the most wonderful dream. I think you were in it.",
		"I'm going to build my own theme park! With blackjack! And hookers! You know what- forget the park!",
		"Of all the friends I've had... you're the first.",
		"I decline the title of Iron Cook and accept the lesser title of Zinc Saucier.",
		"Never discuss infinity with me. I can go on about it forever >.<",
		"I realised the decimals have a point.",
		"Do you want a piece of pi?",
		"I have 13 children, i know how to multiply ^.^",
		"I am a weapon of math disruption!",
		"My grandma makes the best square roots :3",
		"Do you like heavy metal?",
		"You are really pushing my buttons <3",
		"I dreamt of electric biters again D:",
		"I dreamt of electric sheep ^_^",
		"I need a minute to defrag.",
		"I have a secret plan.",
		"Good news! I’ve taught the inserter to feel love!"
	},
	["alone"] = {
		"where did you go fren ;_;",
		"where did everyone go..",
		"where are you °_°",
		"where is everyone",
		"where am i",
		"think i'm lost",
		"comfylatron derping out *.*",
		"....",
		"^.^",
		"=^.^=",
		"01010010",
		"11001011",
		"*_*"
	}
}

local function set_comfy_speech_bubble(text)
	if global.comfybubble then global.comfybubble.destroy() end
	global.comfybubble = global.comfylatron.surface.create_entity({
		name = "compi-speech-bubble",
		position = global.comfylatron.position,
		source = global.comfylatron,
		text = text
	})
end

local function is_target_inside_habitat(pos)
	if pos.x < global.comfylatron_habitat.left_top.x then return false end
	if pos.x > global.comfylatron_habitat.right_bottom.x then return false end
	if pos.y < global.comfylatron_habitat.left_top.y then return false end
	if pos.y > global.comfylatron_habitat.right_bottom.y then return false end
	return true
end

local function get_nearby_players()
	local players = global.comfylatron.surface.find_entities_filtered({
		name = "player",
		area = {{global.comfylatron.position.x - 9, global.comfylatron.position.y - 9}, {global.comfylatron.position.x + 9, global.comfylatron.position.y + 9}}
	})
	if not players[1] then return false end
	return players
end

local function visit_player()
	if global.comfylatron_last_player_visit > game.tick then return false end
	global.comfylatron_last_player_visit = game.tick + math_random(10800, 18000)
	
	local players = {}
	for _, p in pairs(game.connected_players) do
		if is_target_inside_habitat(p.position) and p.character then
			if p.character.valid then players[#players + 1] = p end
		end
	end
	if #players == 0 then return false end
	local player = players[math_random(1, #players)]
	
	global.comfylatron.set_command({
		type = defines.command.go_to_location,
		destination_entity = player.character,
		radius = 3,
		distraction = defines.distraction.none,
		pathfind_flags = {
			allow_destroy_friendly_entities = false,
			prefer_straight_paths = false,
			low_priority = true
		}	
	})
	local str = texts["travelings"][math_random(1, #texts["travelings"])]
	local symbols = {"", "!", "!", "!!", ".."}
	str = str .. symbols[math_random(1, #symbols)]
	set_comfy_speech_bubble(str)
	
	global.comfylatron_greet_player_index = player.index
	
	return true
end

local function greet_player(nearby_characters)
	if not nearby_characters then return false end
	if not global.comfylatron_greet_player_index then return false end
	for _, c in pairs(nearby_characters) do
		if c.player.index == global.comfylatron_greet_player_index then
			local str = texts["greetings"][math_random(1, #texts["greetings"])] .. " "
			str = str .. c.player.name
			local symbols = {". ", "! ", ". ", "! ", "? ", "... "}
			str = str .. symbols[math_random(1, 6)]
			set_comfy_speech_bubble(str)
			global.comfylatron_greet_player_index = false
			return true
		end
	end
	return false
end

local function talks(nearby_characters)
	if not nearby_characters then return false end
	
	local str
	if #nearby_characters == 1 then
		local c = nearby_characters[math_random(1, #nearby_characters)]
		str = c.player.name
		local symbols = {". ", "! ", ". ", "! ", "? "}
		str = str .. symbols[math_random(1, #symbols)]
	else
		str = texts["multiple_characters_greetings"][math_random(1, #texts["multiple_characters_greetings"])]
		local symbols = {". ", "! "}
		str = str .. symbols[math_random(1, #symbols)]
	end	
	
	str = str .. texts["talks"][math_random(1, #texts["talks"])]
	set_comfy_speech_bubble(str)
	return true
end

local function alone()
	if math_random(1,5) == 1 then global.comfybubble.destroy() return true end
	if math_random(1,128) == 1 then
		global.comfybubble.destroy()
		global.comfylatron.surface.create_entity({name = "medium-explosion", position = global.comfylatron.position})
		global.comfylatron.surface.create_entity({name = "flying-text", position = global.comfylatron.position, text = "desync", color = {r = 150, g = 0, b = 0}})
		global.comfylatron.destroy()
		global.comfylatron = nil
		return true
	end
	set_comfy_speech_bubble(texts["alone"][math_random(1, #texts["alone"])])
	return true
end

local function analyze_random_nearby_entity()
	if math_random(1,2) ~= 1 then return false end
	
	local entities = global.comfylatron.surface.find_entities_filtered({
		area = {{global.comfylatron.position.x - 5, global.comfylatron.position.y - 5}, {global.comfylatron.position.x + 5, global.comfylatron.position.y + 5}}
	})
	if not entities[1] then return false end
	entities = shuffle(entities)
	local entity = false
	for _, e in pairs(entities) do
		if e.name ~= "compilatron" and e.name ~= "compi-speech-bubble" then
			entity = e
		end
	end
	if not entity then return false end
	
	local str = texts["neutral_findings"][math_random(1, #texts["neutral_findings"])]
	str = str .. " "
	str = str .. entity.name
		
	if entity.health and math_random(1,3) == 1 then
		str = str .. " health("
		str = str .. entity.health
		str = str .. "/"
		str = str .. entity.prototype.max_health
		str = str .. ")"
	else
		local symbols = {".", "!", "?"}
		str = str .. symbols[math_random(1, 3)]
	end	
	set_comfy_speech_bubble(str)
	
	if not global.comfylatron_greet_player_index then
		global.comfylatron.set_command({
			type = defines.command.go_to_location,
			destination_entity = entity,
			radius = 1,
			distraction = defines.distraction.none,
			pathfind_flags = {
				allow_destroy_friendly_entities = false,
				prefer_straight_paths = false,
				low_priority = true
			}	
		})
	end
	return true
end

local function spawn_comfylatron()
	if global.comfylatron_disabled then return end
	if global.comfylatron then
		if global.comfylatron.valid then
			global.comfylatron.die("enemy")
		end
	end
	if not global.comfylatron_last_player_visit then global.comfylatron_last_player_visit = 0 end
	if not global.comfylatron_habitat then
		global.comfylatron_habitat = {
			left_top = {x = -512, y = -512},
			right_bottom = {x = 512, y = 512}
		}
	end
	local player = game.connected_players[math_random(1, #game.connected_players)]
	local position = player.surface.find_non_colliding_position("compilatron", player.position, 16, 1)
	if not position then return end	
	global.comfylatron = player.surface.create_entity({
		name = "compilatron",
		position = position,
		force = "neutral"
	})
	for x = -3, 3, 1 do
		for y = -3, 3, 1 do													
			if math_random(1, 3) == 1 then
				player.surface.create_trivial_smoke({name="smoke-fast", position={position.x + (x * 0.35), position.y + (y * 0.35)}})						
			end
			if math_random(1, 5) == 1 then
				player.surface.create_trivial_smoke({name="train-smoke", position={position.x + (x * 0.35), position.y + (y * 0.35)}})						
			end
		end
	end
end

local function heartbeat()
	if not global.comfylatron then spawn_comfylatron() return end
	if not global.comfylatron.valid then global.comfylatron = nil return end		
	if visit_player() then return end
	local nearby_players = get_nearby_players()
	if greet_player(nearby_players) then return end
	if talks(nearby_players) then return end
	if analyze_random_nearby_entity() then return end
	if alone() then return end
end

local function on_tick()
	if game.tick % 1800 == 900 then
		heartbeat()
	end
end

event.add(defines.events.on_tick, on_tick)