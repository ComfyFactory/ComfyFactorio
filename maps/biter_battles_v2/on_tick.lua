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

--[[
local function reveal_team(f)
	local m = 32
	if f == "north" then
		game.forces["south"].chart(
			game.surfaces["biter_battles"],
			{{x = global.force_area[f].x_top - m, y = global.force_area[f].y_top - m}, {x = global.force_area[f].x_bot + m, y = global.force_area[f].y_bot + m}}
		)
	else
		game.forces["north"].chart(
			game.surfaces["biter_battles"],
			{{x = global.force_area[f].x_top - m, y = global.force_area[f].y_top - m}, {x = global.force_area[f].x_bot + m, y = global.force_area[f].y_bot + m}}
		)
	end	
end
]]

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
end

event.add(defines.events.on_tick, on_tick)
