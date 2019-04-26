local event = require 'utils.event'

local gui = require "maps.biter_battles_v2.gui"
local ai = require "maps.biter_battles_v2.ai"
local chunk_pregen = require "maps.biter_battles_v2.pregenerate_chunks"
local mirror_map = require "maps.biter_battles_v2.mirror_terrain"
local server_restart = require "maps.biter_battles_v2.game_won"

local spy_forces = {{"north", "south"},{"south", "north"}}
local function spy_fish()
	for _, f in pairs(spy_forces) do		
		if global.spy_fish_timeout[f[1]] - game.tick > 0 then
			local r = 96
			local surface = game.surfaces["biter_battles"]
			for _, player in pairs(game.forces[f[2]].connected_players) do
				game.forces[f[1]].chart(surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})
			end			
		else
			global.spy_fish_timeout[f[1]] = 0
		end
	end		
end

local function clear_corpses()
	for _, e in pairs(game.surfaces["biter_battles"].find_entities_filtered({type = "corpse"})) do		
		if math.random(1, 3) == 1 then
			e.destroy()
		end
	end
end

local function restart_idle_map()
	if game.tick < 432000 then return end
	if #game.connected_players ~= 0 then global.restart_idle_map_countdown = 2 return end
	if not global.restart_idle_map_countdown then global.restart_idle_map_countdown = 2 end
	global.restart_idle_map_countdown = global.restart_idle_map_countdown - 1
	if global.restart_idle_map_countdown ~= 0 then return end
	server_commands.start_scenario('Biter_Battles')
end

local function on_tick(event)
	if game.tick % 30 ~= 0 then return end
	chunk_pregen()
	mirror_map()
	
	if game.tick % 60 ~= 0 then return end
	global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
	global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]
	
	if game.tick % 120 == 0 then gui() end	
	
	if game.tick % 300 ~= 0 then return end
	spy_fish()
	if global.bb_game_won_by_team then server_restart() return end
	
	if game.tick % 1800 ~= 0 then return end
		
	ai.main_attack()
	ai.send_near_biters_to_silo()
	
	if game.tick % 3600 ~= 0 then return end
	clear_corpses()
	restart_idle_map()
end

event.add(defines.events.on_tick, on_tick)
