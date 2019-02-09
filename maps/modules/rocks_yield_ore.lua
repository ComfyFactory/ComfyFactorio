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
		
local ore_raffle = {}				
for _, t in pairs (rock_mining_chance_weights) do
	for x = 1, t[2], 1 do
		table.insert(ore_raffle, t[1])
	end			
end

local function get_amount(entity)
	local distance_to_center = math.sqrt(entity.position.x^2 + entity.position.y^2)
	local amount = 25 + (distance_to_center * 0.2)
	if amount > 200 then amount = 200 end
	amount = rock_yield[entity.name] * amount
	amount = math.random(math.ceil(amount * 0.5), math.ceil(amount * 1.5))	
	return amount
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if rock_yield[entity.name] then
		event.buffer.clear()
		local amount = get_amount(entity)
		local ore = ore_raffle[math.random(1, #ore_raffle)]
		entity.surface.spill_item_stack(entity.position,{name = ore, count = amount}, true)
		entity.surface.create_entity({name = "flying-text", position = entity.position, text = amount .. " " .. texts[ore][1], color = texts[ore][2]})	
	end
end
	
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)