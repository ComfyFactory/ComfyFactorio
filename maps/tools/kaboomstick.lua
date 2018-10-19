local event = require 'utils.event'

local damage_per_explosive = 100
local empty_tile_damage_absorption = 50
local out_of_map_tile_health = 500
local replacement_tile = "dirt-5"
local math_random = math.random
local math_sqrt = math.sqrt
local kabooms = {"big-artillery-explosion", "big-explosion", "explosion"}

local function on_entity_damaged(event)	
	if event.entity.type == "container" then
		if math_random(1,1) == 1 then kaboom(event.entity) end
	end
end

local function on_tick(event)
	if global.kaboom_schedule then		
		if #global.kaboom_schedule == 0 then global.kaboom_schedule = nil return end
		local tick = game.tick
		for explosion_index = 1, #global.kaboom_schedule, 1 do	
			if global.kaboom_schedule[explosion_index] then
				local surface = global.kaboom_schedule[explosion_index].surface			
				for radius = 1, #global.kaboom_schedule[explosion_index], 1 do
					if global.kaboom_schedule[explosion_index][radius] then
						if global.kaboom_schedule[explosion_index][radius].trigger_tick < tick then				
							for tile_index = 1, #global.kaboom_schedule[explosion_index][radius], 1 do							
								surface.create_entity({name = global.kaboom_schedule[explosion_index][radius][tile_index].animation.name, position = global.kaboom_schedule[explosion_index][radius][tile_index].animation.position})
							end
							global.kaboom_schedule[explosion_index][radius] = nil
						end
					end					
				end
				if #global.kaboom_schedule[explosion_index] == 0 then global.kaboom_schedule[explosion_index] = nil end
			end			
		end		
	end
end

function kaboom(entity)		
	local i = entity.get_inventory(defines.inventory.chest)
	local explosives_amount = i.get_item_count("explosives")
	if explosives_amount < 1 then return end	
	local current_radius = 0
	local center_position = entity.position
	local surface = entity.surface
	
	if not global.kaboom_schedule then global.kaboom_schedule = {} end
	global.kaboom_schedule[#global.kaboom_schedule + 1] = {}
	global.kaboom_schedule[#global.kaboom_schedule].surface = surface
	
	local tiles_count = 0
	
	while explosives_amount > 0 do		
		current_radius = current_radius + 1
		global.kaboom_schedule[#global.kaboom_schedule][current_radius] = {}
		global.kaboom_schedule[#global.kaboom_schedule][current_radius].trigger_tick = game.tick + (current_radius * 5)
		local i = 1
		for x = current_radius * -1, current_radius, 1 do
			for y = current_radius * -1, current_radius, 1 do
				local pos = {x = center_position.x + x, y = center_position.y + y}				
				local distance_to_center = math_sqrt(x^2 + y^2)
				
				--check if position is already in the table
				local entry_already_exists = false
				--[[
				if current_radius > 1 then
					for index = 1, #global.kaboom_schedule[#global.kaboom_schedule][current_radius - 1], 1 do
						local position = global.kaboom_schedule[#global.kaboom_schedule][current_radius - 1][index].animation.position	
						if position.x == pos.x and position.y == pos.y then
							entry_already_exists = true
							game.print("OK")
						end												
					end
				end			
				]]--
				
				if entry_already_exists == false then
					if distance_to_center >= current_radius - 1 and distance_to_center < current_radius then					
						global.kaboom_schedule[#global.kaboom_schedule][current_radius][i] = {}					
						global.kaboom_schedule[#global.kaboom_schedule][current_radius][i].animation = {position = {x = pos.x, y = pos.y}, name = "big-artillery-explosion"}
						tiles_count = tiles_count + 1
						
						local target_entity = surface.find_entities_filtered({position = pos, limit = 1})    ---- some might not have health
						if target_entity[1] and target_entity[1].health then							
							local damage_dealt = 0
							local explosives_needed = math.floor(target_entity[1].health / damage_per_explosive, 0)
							for z = 1, explosives_needed, 1 do
								explosives_amount = explosives_amount - 1
								damage_dealt = damage_dealt + damage_per_explosive
								if explosives_amount < 1 then break end
							end
							global.kaboom_schedule[#global.kaboom_schedule][current_radius][i].entity_to_damage = {target_entity[1], damage_dealt}							
						else
							local tile = surface.get_tile(pos)	
							if tile.name == "out-of-map" then
								local explosives_needed = math.floor(out_of_map_tile_health / damage_per_explosive, 0)
								if explosives_amount >= explosives_needed then
									explosives_amount = explosives_amount - explosives_needed
								end
								if explosives_amount >= 0 then global.kaboom_schedule[#global.kaboom_schedule][current_radius][i].tile_to_convert = {tile, replacement_tile} end						
							else
								local explosives_needed = math.floor(empty_tile_damage_absorption / damage_per_explosive, 0)						
								explosives_amount = explosives_amount - explosives_needed							
							end						
							if explosives_amount < 1 then return end
						end
						i = i + 1
						
						game.print(tiles_count)
					end
				end
			end
		end
	end	
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_tick, on_tick)
