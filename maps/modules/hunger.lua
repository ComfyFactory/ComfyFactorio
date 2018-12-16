-- hunger module by mewmew --

local event = require 'utils.event'
local math_random = math.random

local respawn_fish = true

local player_hunger_fish_food_value = 10
local player_hunger_spawn_value = 80				
local player_hunger_stages = {}
for x = 1, 200, 1 do
	if x <= 200 then player_hunger_stages[x] = "Obese" end						
	if x <= 179 then player_hunger_stages[x] = "Stuffed" end
	if x <= 150 then player_hunger_stages[x] = "Bloated" end
	if x <= 130 then player_hunger_stages[x] = "Sated" end
	if x <= 110 then player_hunger_stages[x] = "Well Fed" end
	if x <= 89 then player_hunger_stages[x] = "Nourished" end			
	if x <= 70 then player_hunger_stages[x] = "Hungry" end
	if x <= 35 then player_hunger_stages[x] = "Starving" end			
end	

local player_hunger_color_list = {}
for x = 1, 50, 1 do
	player_hunger_color_list[x] = 		{r = 0.5 + x*0.01, g = x*0.01, b = x*0.005}
	player_hunger_color_list[50+x] = {r = 1 - x*0.02, g = 0.5 + x*0.01, b = 0.25}
	player_hunger_color_list[100+x] = {r = 0 + x*0.02, g = 1 - x*0.01, b = 0.25}
	player_hunger_color_list[150+x] = {r = 1 - x*0.01, g = 0.5 - x*0.01, b = 0.25 - x*0.005}
end

local player_hunger_buff = {}
local buff_top_value = 0.70		
for x = 1, 200, 1 do
	player_hunger_buff[x] = buff_top_value
end
local y = 1
for x = 89, 1, -1 do			
	player_hunger_buff[x] = buff_top_value - y * 0.015
	y = y + 1
end
local y = 1		
for x = 111, 200, 1 do			
	player_hunger_buff[x] = buff_top_value - y * 0.015
	y = y + 1
end

local function create_hunger_gui(player)
	if player.gui.top["hunger_frame"] then player.gui.top["hunger_frame"].destroy() end
	
	local frame = player.gui.top.add { type = "frame", name = "hunger_frame"}
	
	local str = tostring(global.player_hunger[player.name])
	str = str .. "% "
	str = str .. player_hunger_stages[global.player_hunger[player.name]]
	local caption_hunger = frame.add { type = "label", caption = str  }
	caption_hunger.style.font = "default-bold"
	caption_hunger.style.font_color = player_hunger_color_list[global.player_hunger[player.name]]
	caption_hunger.style.top_padding = 2	
end

local function hunger_update(player, food_value)	
	if food_value == -1 and player.character.driving == true then return end
	
	local past_hunger = global.player_hunger[player.name]	
	global.player_hunger[player.name] = global.player_hunger[player.name] + food_value
	if global.player_hunger[player.name] > 200 then global.player_hunger[player.name] = 200 end
			
	if past_hunger == 200 and global.player_hunger[player.name] + food_value > 200 then
		global.player_hunger[player.name] = player_hunger_spawn_value
		player.surface.create_entity({name = "big-artillery-explosion", position = player.character.position})
		player.character.die("player")
		local t = {" ate too much and exploded.", " needs to work on their bad eating habbits.", " should have skipped dinner today."}
		game.print(player.name .. t[math.random(1,#t)], { r=0.75, g=0.0, b=0.0})				
	end	
	
	if global.player_hunger[player.name] < 1 then
		global.player_hunger[player.name] = player_hunger_spawn_value		
		player.character.die("player")
		local t = {" ran out of foodstamps.", " starved.", " should not have skipped breakfast today."}
		game.print(player.name .. t[math.random(1,#t)], { r=0.75, g=0.0, b=0.0})	
	end
	
	if player.character then
		if player_hunger_stages[global.player_hunger[player.name]] ~= player_hunger_stages[past_hunger] then
			local print_message = "You are " .. player_hunger_stages[global.player_hunger[player.name]] .. "."
			if player_hunger_stages[global.player_hunger[player.name]] == "Obese" then
				print_message = "You have become " .. player_hunger_stages[global.player_hunger[player.name]]  .. "."					
			end
			if player_hunger_stages[global.player_hunger[player.name]] == "Starving" then
				print_message = "You are starving!"
			end
			player.print(print_message, player_hunger_color_list[global.player_hunger[player.name]])
		end
	end
	
	player.character.character_running_speed_modifier = player_hunger_buff[global.player_hunger[player.name]] * 0.5
	player.character.character_mining_speed_modifier  = player_hunger_buff[global.player_hunger[player.name]]
	
	create_hunger_gui(player)
end

local function respawn_fishes()				
	local surface = game.players[1].surface
	for chunk in surface.get_chunks() do
		if math_random(1, 32) == 1 then
			local area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}
			local water_tiles = surface.find_tiles_filtered({name = {"water", "deepwater", "water-green"}, area = area})
			for _, tile in pairs(water_tiles) do
				if math_random(1, 32) == 1 then
					local area_entities = {{tile.position.x - 2, tile.position.y - 2},{tile.position.x + 2, tile.position.y + 2}}
					local area_tiles = {{tile.position.x - 1, tile.position.y - 1},{tile.position.x + 1, tile.position.y + 1}}			
					if surface.count_entities_filtered({area = area_entities, name = "fish"}) == 0 and surface.count_tiles_filtered({area = area_tiles, name = {"water", "deepwater", "water-green"}}) > 3 then
						surface.create_entity({name = "water-splash", position = tile.position})
						surface.create_entity({name = "fish", position = tile.position})				
					end
				end
			end
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.player_hunger then global.player_hunger = {} end
	if player.online_time < 2 then		
		global.player_hunger[player.name] = player_hunger_spawn_value
		hunger_update(player, 0)
	end
	create_hunger_gui(player)
end

local function on_player_used_capsule(event)
	if event.item.name == "raw-fish" then		
		local player = game.players[event.player_index]
		if player.character.health < 250 then return end		
		hunger_update(player, player_hunger_fish_food_value)		
		player.play_sound{path="utility/armor_insert", volume_modifier=0.65}				
	end
end

local function on_tick()	
	if game.tick % 360 == 0 then
		if game.tick % 3600 == 0 then
			for _, player in pairs(game.connected_players) do
				if player.afk_time < 18000 then	hunger_update(player, -1) end		
			end			
		end
		if respawn_fish then
			respawn_fishes()
		end
	end
end

event.add(defines.events.on_tick, on_tick)	
event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
event.add(defines.events.on_player_joined_game, on_player_joined_game)