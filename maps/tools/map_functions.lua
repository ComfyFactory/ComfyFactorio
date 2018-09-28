local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local f = {}

f.draw_oil_circle = function(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random		
	local count = 0
	local max_count = 0
	while count < radius and max_count < 100000 do
		for y = radius * -1, radius, 1 do
			for x = radius * -1, radius, 1 do					
				if math_random(1, 200) == 1 then
					local pos = {x = x + position.x, y = y + position.y}
					local a = math_random(richness * 0.5, richness * 1.5)
					local distance_to_center = math.sqrt(x^2 + y^2)						
					if distance_to_center < radius then			
						if surface.can_place_entity({name = name, position = pos, amount = a}) then
							surface.create_entity{name = name, position = pos, amount = a}
							count = count + 1
						end
					end
				end
			end
		end
		max_count = max_count + 1
	end					
end

f.draw_smoothed_out_ore_circle = function(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000	
	local richness_part = richness / radius
	for y = radius*-1, radius, 1 do
		for x = radius*-1, radius, 1 do
			local pos = {x = x + position.x, y = y + position.y}
			local noise_1 = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
			seed = seed + noise_seed_add
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
			local noise = noise_1 + noise_2 * 0.2
			local distance_to_center = math.sqrt(x^2 + y^2)						
			local a = richness - richness_part * distance_to_center
			if distance_to_center + ((1 + noise) * 3) < radius then			
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}									
				end
			end			
		end
	end
end

f.create_cluster = function(name, pos, size, surface, spread, resource_amount)		
	local p = {x = pos.x, y = pos.y}
	local math_random = math.random
	local original_pos = {x = pos.x, y = pos.y}
	local entity_has_been_placed = false
	for z = 1, size, 1 do
		entity_has_been_placed = false
		local y = 1
		if spread then y = math_random(1, spread) end	
		local modifier_raffle = {{0,y*-1},{y*-1,0},{y,0},{0,y},{y*-1,y*-1},{y,y},{y,y*-1},{y*-1,y}}
		modifier_raffle = shuffle(modifier_raffle)
		for x = 1, 8, 1 do					
			local m = modifier_raffle[x]
			local pos = {x = p.x + m[1], y = p.y + m[2]}
			if resource_amount then
				if surface.can_place_entity({name=name, position=pos, amount=resource_amount}) then
					surface.create_entity {name=name, position=pos, amount=resource_amount}				
					p = {x = pos.x, y = pos.y}
					entity_has_been_placed = true
					break
				end
			else
				if surface.can_place_entity({name=name, position=pos}) then
					surface.create_entity {name=name, position=pos}
					p = {x = pos.x, y = pos.y}	
					entity_has_been_placed = true
					break
				end
			end
		end
		if entity_has_been_placed == false then
			p = {x = original_pos.x, y = original_pos.y}
		end
	end
end

return f