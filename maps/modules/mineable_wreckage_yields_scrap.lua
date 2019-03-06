--destroying and mining rocks yields ore -- load as last module

local event = require 'utils.event'

local mining_chance_weights = {
	{name = "iron-plate", chance = 100},
	{name = "iron-gear-wheel", chance = 75},	
	{name = "copper-plate", chance = 75},
	{name = "copper-cable", chance = 50},	
	{name = "electronic-circuit", chance = 30},
	{name = "steel-plate", chance = 20},
	{name = "solid-fuel", chance = 15},
	{name = "pipe", chance = 10},
	{name = "iron-stick", chance = 10},	
	{name = "empty-barrel", chance = 10},	
	{name = "battery", chance = 1},
	{name = "land-mine", chance = 1}			
}

local scrap_yield_amounts = {
	["iron-plate"] = 16,
	["iron-gear-wheel"] = 8,
	["iron-stick"] = 16,
	["copper-plate"] = 16,
	["copper-cable"] = 24,
	["electronic-circuit"] = 8,
	["steel-plate"] = 4,
	["pipe"] = 8,
	["solid-fuel"] = 4,
	["empty-barrel"] = 2,
	["battery"] = 2,
	["land-mine"] = 1,
}
		
local scrap_raffle = {}				
for _, t in pairs (mining_chance_weights) do
	for x = 1, t.chance, 1 do
		table.insert(scrap_raffle, t.name)
	end			
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name ~= "mineable-wreckage" then return end
			
	event.buffer.clear()
	
	local scrap = scrap_raffle[math.random(1, #scrap_raffle)]
	
	local amount = math.random(math.ceil(scrap_yield_amounts[scrap] * 0.3), math.ceil(scrap_yield_amounts[scrap] * 1.7))
	
	local player = game.players[event.player_index]	
	local inserted_count = player.insert({name = scrap, count = amount})
	
	if inserted_count ~= amount then
		local amount_to_spill = amount - inserted_count			
		entity.surface.spill_item_stack(entity.position,{name = scrap, count = amount_to_spill}, true)
	end
	
	entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "+" .. amount .. " [img=item/" .. scrap .. "]",
		color = {r=0.98, g=0.66, b=0.22}
	})	
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)