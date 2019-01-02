local event = require 'utils.event'

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.new_player_equipped then global.new_player_equipped = {} end
	
	if not global.new_player_equipped[player.name] then
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "iron-plate", count = 128})
		player.insert({name = "iron-gear-wheel", count = 64})
		player.insert({name = "copper-plate", count = 128})
		player.insert({name = "copper-cable", count = 64})
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 128})
		player.insert({name = "shotgun", count = 1})
		player.insert({name = "shotgun-shell", count = 32})
		player.insert({name = "light-armor", count = 1})
		global.new_player_equipped[player.name] = true
	end
end

local function on_player_created(event)	
	local player = game.players[event.player_index]			
	
end

local function on_research_finished(event)
	
end

event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_created, on_player_created)