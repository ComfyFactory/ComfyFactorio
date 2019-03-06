local event = require 'utils.event'

local function spin(player)
	local d = player.character.direction
	d = d + 1
	if d > 7 then d = 0 end
	player.character.direction = d
end

local function on_player_joined_game(event)
	commands.add_command("spin", "spins you", 
		function(args)
			local player = game.players[args.player_index]
			
			--if not args.parameter then player.print("Please add a player name.") return end
			local c = 25			
			for t = 0, 600, 1 do				
				if t % math.ceil(c) == 0 then
					local trigger_tick = game.tick + t				
					if not global.on_tick_schedule[trigger_tick] then global.on_tick_schedule[trigger_tick] = {} end
					table.insert(global.on_tick_schedule[trigger_tick], {func = spin, args = {player}})
									
					c = c - c * 0.05
					if c < 1 then c = 1 end
				end
			end
			
			local c = 1
			for t = 600, 1200, 1 do				
				if t % math.ceil(c) == 0 then
					local trigger_tick = game.tick + t				
					if not global.on_tick_schedule[trigger_tick] then global.on_tick_schedule[trigger_tick] = {} end
					table.insert(global.on_tick_schedule[trigger_tick], {func = spin, args = {player}})
									
					c = c + c * 0.05
					if c > 25 then c = 25 end
				end
			end						
		end
	)	
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)