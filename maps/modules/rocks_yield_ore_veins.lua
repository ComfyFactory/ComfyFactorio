local event = require 'utils.event'
local math_random = math.random

local valid_entities = {
	["rock-big"] = true,
	["rock-huge"] = true,
	["sand-rock-big"] = true	
}

local rock_mining_chance_weights = {
	{"iron-ore", 25},
	{"copper-ore",18},
	{"coal",14},
	{"stone",10},
	{"uranium-ore",3}
}

local ore_raffle = {}				
for _, t in pairs (rock_mining_chance_weights) do
	for x = 1, t[2], 1 do
		table.insert(ore_raffle, t[1])
	end			
end

local size_raffle = {
		{"huge", 33, 42},
		{"big", 17, 32},
		{"", 8, 16},
		{"tiny", 3, 7}
	}

local ore_prints = {
		["coal"] = {"dark", "Coal"},
		["iron-ore"] = {"shiny", "Iron"},
		["copper-ore"] = {"glimmering", "Copper"},
		["uranium-ore"] = {"glowing", "Uranium"},
		["stone"] = {"solid", "Stone"}
	}

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if valid_entities[entity.name] then
		if math_random(1,64) == 1 then
			local player = game.players[event.player_index]
			local p = {x = entity.position.x, y = entity.position.y}
			local tile_distance_to_center = p.x^2 + p.y^2			
			local radius = 32
			if entity.surface.count_entities_filtered{area={{p.x - radius,p.y - radius},{p.x + radius,p.y + radius}}, type="resource", limit=1} == 0 then				
				local size = size_raffle[math_random(1, #size_raffle)]
				local ore = ore_raffle[math_random(1, #ore_raffle)]								
				player.print("You notice something " .. ore_prints[ore][1] .. " underneath the rubble covered floor. It's a " .. size[1] .. " vein of " ..  ore_prints[ore][2] .. "!!", { r=0.98, g=0.66, b=0.22})
				tile_distance_to_center = math.sqrt(tile_distance_to_center)
				local ore_entities_placed = 0
				local modifier_raffle = {{0,-1},{-1,0},{1,0},{0,1}}
				while ore_entities_placed < math_random(size[2],size[3]) do						
					local a = math.ceil((math_random(tile_distance_to_center*4, tile_distance_to_center*5)) / 1 + ore_entities_placed * 0.5, 0)						
					for x = 1, 150, 1 do
						local m = modifier_raffle[math_random(1,#modifier_raffle)]
						local pos = {x = p.x + m[1], y = p.y + m[2]}
						if entity.surface.can_place_entity({name=ore, position=pos, amount=a}) then
							entity.surface.create_entity {name=ore, position=pos, amount=a}
							p = pos
							break
						end
					end
					ore_entities_placed = ore_entities_placed + 1
				end
			end			
		end	
	end
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)