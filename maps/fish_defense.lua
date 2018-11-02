-- fish defense -- by mewmew -- 

local event = require 'utils.event'
require "maps.fish_defense_map_intro"
require "maps.fish_defense_kaboomsticks"
local math_random = math.random
local insert = table.insert

local function increase_difficulty()
	if game.map_settings.enemy_expansion.max_expansion_cooldown < 7200 then return end
	game.map_settings.enemy_expansion.max_expansion_cooldown = game.map_settings.enemy_expansion.max_expansion_cooldown - 3600	 
end

function biter_attack_wave()
	if not global.market then return end
	
	local surface = game.surfaces[1]
	if not global.wave_count then
		global.wave_count = 1
	else
		global.wave_count = global.wave_count + 1
	end
	
	surface.set_multi_command{command = {type=defines.command.attack_area, destination=global.market.position, radius=2, distraction=defines.distraction.by_anything}, unit_count = global.wave_count, force = "enemy", unit_search_distance = 5000}
	
end

local function is_game_lost()
	if global.market then return end
	
	for _, player in pairs(game.connected_players) do
		if player.gui.left["fish_defense_game_lost"] then player.gui.left["fish_defense_game_lost"].destroy() end
		local f = player.gui.left.add({ type = "frame", name = "fish_defense_game_lost", caption = "The fish market was destroyed! :(" })
		f.style.font_color = {r=0.99, g=0.15, b=0.15}
		f.add({type = "label", caption = "It survived for " .. math.ceil(((global.market_age / 60) / 60), 0) .. " minutes."})
	end
end

local function on_entity_died(event)
	if event.entity == global.market then
		global.market = nil
		global.market_age = game.tick
		is_game_lost()
	end
end

local function on_entity_damaged(event)
	if event.entity.name == "market" then
		if event.cause.force.name == "enemy" then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end


local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if not global.fish_defense_init_done then
		local surface = game.surfaces[1]
		
		game.map_settings.enemy_expansion.enabled = true
		game.map_settings.enemy_expansion.max_expansion_distance = 10
		game.map_settings.enemy_expansion.settler_group_min_size = 10
		game.map_settings.enemy_expansion.settler_group_max_size = 20
		game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
		game.map_settings.enemy_expansion.max_expansion_cooldown = 216000
				
		game.map_settings.enemy_evolution.destroy_factor = 0.002
		game.map_settings.enemy_evolution.time_factor = 0.000008 
		game.map_settings.enemy_evolution.pollution_factor = 0.000015
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false			
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false
		game.forces.player.recipes["laser-turret"].enabled = false
		game.forces.player.recipes["flamethrower-turret"].enabled = false
		
		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 0.5)
		
		local pos = surface.find_non_colliding_position("market",{0, 0}, 50, 1)
		global.market = surface.create_entity({name = "market", position = pos, force = "player"})
		global.market.minable = false
		global.market.add_market_item({price = {{"coal", 3}}, offer = {type = 'give-item', item = "raw-fish", count = 1}})
		
		global.fish_defense_init_done = true
	end
	
	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 16})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = true end
	end
	
	is_game_lost()
end

local map_height = 96
local function on_chunk_generated(event)
	local surface = game.surfaces[1]
	local area = event.area
	local left_top = area.left_top
		
	local entities = surface.find_entities_filtered({area = area, force = "enemy"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	
	local tiles = {}
	
	if left_top.y > map_height or left_top.y < map_height * -1 then
		for x = 0, 31, 1 do	
			for y = 0, 31, 1 do		
				local pos = {x = left_top.x + x, y = left_top.y + y}
				insert(tiles, {name = "out-of-map", position = pos})
			end
		end
	end
	surface.set_tiles(tiles, false)
	if left_top.x < 160 then return end
	
	local entities = {}	
	
	for x = 0, 31, 1 do	
		for y = 0, 31, 1 do		
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1,10) == 1 then
				if surface.can_place_entity({name = "biter-spawner", force = "enemy", position = pos}) then
					if math_random(1,4) == 1 then
						surface.create_entity({name = "spitter-spawner", force = "enemy", position = pos})
					else
						surface.create_entity({name = "biter-spawner", force = "enemy", position = pos})
					end
				end
			end
		end
	end
end

local function on_research_finished(event)
	game.forces.player.recipes["laser-turret"].enabled = false
	game.forces.player.recipes["flamethrower-turret"].enabled = false
end

local function on_built_entity(event)
	if "gun-turret" == event.created_entity.name then
		event.created_entity.die()
	end
end

local function on_robot_built_entity(event)
	on_built_entity(event)
end

local function on_tick()
	if game.tick % 21600 == 10800 then
		increase_difficulty()		
	end
	
	if game.tick % 3600 == 1800 then
		biter_attack_wave()
	end	
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)