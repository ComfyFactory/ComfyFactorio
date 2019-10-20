--vanilla with wave_defense

require "modules.wave_defense.main"
require "modules.map_info"
map_info = {}
map_info.main_caption = "Wave Defense"
map_info.sub_caption =  "~~~~~~"
map_info.text = table.concat({
	"Survive\n",
	"as\n",
	"long\n",
	"as\n",
	"possible.\n",
})
map_info.main_caption_color = {r = 150, g = 0, b = 150}
map_info.sub_caption_color = {r = 100, g = 150, b = 0}

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['iron-plate'] = 16, ['iron-gear-wheel'] = 8, ['raw-fish'] = 3,}

local function set_difficulty()
	--20 Players for maximum difficulty
	global.wave_defense.wave_interval = 7200 - #game.connected_players * 270
	if global.wave_defense.wave_interval < 1800 then global.wave_defense.wave_interval = 1800 end	
end

local function on_player_joined_game(event)	
	set_difficulty()
	
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end	
end

local function on_player_left_game(event)
	set_difficulty()
end

local function on_init()	
	game.surfaces[1].request_to_generate_chunks({0,0}, 16)
	game.surfaces[1].force_generate_chunk_requests()
	
	global.wave_defense.next_wave = 3600 * 15
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_player_joined_game, on_player_joined_game)