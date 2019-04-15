local event = require 'utils.event'
local math_random = math.random
global.comfylatron_habitat = {
		left_top = {x = -1000, y = -1000},
		right_bottom = {x = 0, y = 1000}
	}


local texts = {
	["travelings"] = {
		"bzzZZrrt",
		"vroooOOm",
		"WEEEeeeeeee",
		"out of my way son!",
		"comfylatron coming through!!",
	},
	["greetings"] = {
		"=^_^=",
		"Hi! =^.^=",
		"Hello engineer!"
	},
	["jokes"] = {
		"We’re making beer. I’m the brewery!",
		"I’m so embarrassed. I wish everybody else was dead.",
		"Hey sexy mama. Wanna kill all humans?",
		"My story is a lot like yours, only more interesting ‘cause it involves robots."
	},
	["bored"] = {
		"where did you go fren ;_;",
		"where is everyone...",
		"...."
	}
}

local function comfy_speech_bubbles(text_type)
	global.comfybubble = game.player.surface.create_entity({
		name = "compi-speech-bubble",
		position = global.comfylatron.position,
		source = global.comfylatron,
		text = texts[text_type][math_random(1, #texts[text_type])]
	})
end

local function is_target_inside_habitat()
	if pos.x < global.comfylatron_habitat.left_top.x then return false end
	if pos.x > global.comfylatron_habitat.right_bottom.x then return false end
	if pos.y < global.comfylatron_habitat.left_top.y then return false end
	if pos.y > global.comfylatron_habitat.right_bottom.y then return false end
	return true
end

local function visit_player()
	global.comfylatron_last_player_visit = game.tick + math_random(1800, 3600)
	local players = {}
	for _, p in pairs(game.connected_players) do
		if 
	end
	local player = game.connected_players[math_random(1, #game.connected_players)]
	comfy_speech_bubbles("travelings")
end

local function get_text_status()
	local surface = global.comfylatron.surface
end

local function heartbeat()
	if not global.comfylatron then return end
	if not global.comfylatron.valid then return end
	
	if global.comfylatron_last_player_visit < game.tick then
		visit_player()
		return
	end	
end

function spawn_comfylatron()
	if global.comfylatron then
		if global.comfylatron.valid then
			global.comfylatron.die("enemy")
		end
	end
	if not global.comfylatron_last_player_visit then global.comfylatron_last_player_visit = 0 end
	local player = game.connected_players[math_random(1, #game.connected_players)]
	local position = player.surface.find_non_colliding_position("compilatron", player.position, 16, 1)
	if not position then return end	
	global.comfylatron = player.surface.create_entity({
		name = "compilatron",
		position = game.player.selected.position,
		force = "neutral"
	})
end

return heartbeat