local event = require 'utils.event'

local function on_console_chat(event)
	if not event.message then return end	
	if not event.player_index then return end	
	local player = game.players[event.player_index]
	if not player.character then return end
	
	if global.player_floaty_chat[player.index] then
		rendering.destroy(global.player_floaty_chat[player.index])
		global.player_floaty_chat[player.index] = nil
	end
	
	global.player_floaty_chat[player.index] = rendering.draw_text{
		text = event.message,
		surface = player.surface,
		target = player.character,
		target_offset = {-0.1, -3},
		color = {
			r = player.color.r * 0.6 + 0.25,
			g = player.color.g * 0.6 + 0.25,
			b = player.color.b * 0.6 + 0.25,
			a = 1
		},
		time_to_live = 600,
		scale = 0.9,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = true
	}
end

local function on_init(event)
	global.player_floaty_chat = {}
end

event.on_init(on_init)
event.add(defines.events.on_console_chat, on_console_chat)