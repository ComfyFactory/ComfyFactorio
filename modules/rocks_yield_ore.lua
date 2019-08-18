--destroying and mining rocks yields ore -- load as last module

local event = require 'utils.event'

local rock_yield = {
	["rock-big"] = 1,
	["rock-huge"] = 2,
	["sand-rock-big"] = 1	
}

local rock_mining_chance_weights = {
	{"iron-ore", 25},
	{"copper-ore",18},
	{"coal",14},
	{"stone",10},
	{"uranium-ore",3}
}

local texts = {
	["iron-ore"] = {"Iron ore", {r = 200, g = 200, b = 180}},
	["copper-ore"] = {"Copper ore", {r = 221, g = 133, b = 6}},
	["uranium-ore"] = {"Uranium ore", {r= 50, g= 250, b= 50}},
	["coal"] = {"Coal", {r = 0, g = 0, b = 0}},
	["stone"] = {"Stone", {r = 200, g = 160, b = 30}},
}

local particles = {
	["iron-ore"] = "iron-ore-particle",
	["copper-ore"] = "copper-ore-particle",
	["uranium-ore"] = "coal-particle",
	["coal"] = "coal-particle",
	["stone"] = "stone-particle"
}
		
local ore_raffle = {}				
for _, t in pairs (rock_mining_chance_weights) do
	for x = 1, t[2], 1 do
		table.insert(ore_raffle, t[1])
	end			
end

local function create_particles(surface, name, position, amount, cause_position)
	local math_random = math.random
	
	local direction_mod = (-100 + math_random(0,200)) * 0.0004
	local direction_mod_2 = (-100 + math_random(0,200)) * 0.0004
	
	if cause_position then
		direction_mod = (cause_position.x - position.x) * 0.025
		direction_mod_2 = (cause_position.y - position.y) * 0.025
	end
	
	for i = 1, amount, 1 do 
		local m = math_random(4, 10)
		local m2 = m * 0.005
		
		surface.create_entity({
			name = name,
			position = position,
			frame_speed = 1,
			vertical_speed = 0.130,
			height = 0,
			movement = {
				(m2 - (math_random(0, m) * 0.01)) + direction_mod,
				(m2 - (math_random(0, m) * 0.01)) + direction_mod_2
			}
		})
	end	
end

local function get_amount(entity)
	local distance_to_center = math.sqrt(entity.position.x^2 + entity.position.y^2)
	local amount = 50 + (distance_to_center * 0.33)
	if amount > 150 then amount = 150 end
	amount = rock_yield[entity.name] * amount
	
	if not global.rock_yield_amount_modifier then global.rock_yield_amount_modifier = 1 end
	amount = amount * global.rock_yield_amount_modifier
	
	amount = math.random(math.ceil(amount * 0.5), math.ceil(amount * 1.5))		
	
	return amount
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if rock_yield[entity.name] then
		event.buffer.clear()
		
		local ore = ore_raffle[math.random(1, #ore_raffle)]
		
		local amount = get_amount(entity)
		
		local amount_to_spill = math.ceil(amount * 0.5)
		local amount_to_insert = math.floor(amount * 0.5)
		
		local player = game.players[event.player_index]
		local inserted_count = player.insert({name = ore, count = amount_to_insert})
		local amount_to_spill = amount_to_spill + (amount_to_insert - inserted_count)
				
		entity.surface.spill_item_stack(entity.position,{name = ore, count = amount_to_spill}, true)
		
		--entity.surface.create_entity({name = "flying-text", position = entity.position, text = amount .. " " .. texts[ore][1], color = texts[ore][2]})
		entity.surface.create_entity({name = "flying-text", position = entity.position, text = "+" .. amount .. " [img=item/" .. ore .. "]", color = {r = 200, g = 160, b = 30}})
		
		create_particles(entity.surface, particles[ore], entity.position, 64, game.players[event.player_index].position)
		
	end
end

local function on_entity_died(event)	
	local entity = event.entity
	if not entity.valid then return end
	if rock_yield[entity.name] then
		local surface = entity.surface
		local amount = get_amount(entity)
		amount = math.ceil(amount * 0.1)
		local ore = ore_raffle[math.random(1, #ore_raffle)]
		local pos = {entity.position.x, entity.position.y}
		entity.destroy()
		surface.spill_item_stack(pos,{name = ore, count = amount}, true)
		create_particles(surface, particles[ore], pos, 16)
	end
end

event.add(defines.events.on_entity_died, on_entity_died)	
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)