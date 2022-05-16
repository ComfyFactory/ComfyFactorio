local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local tick_tack_trap = require 'modules.ubiquity.tick_tack_trap'

local containers = {
	-- containers
	{name = 'crash-site-chest-1', size = 8},
	{name = 'crash-site-chest-2', size = 8}
}
local containers_index = table.size(containers)

local container_loot_chance = {
	{name = 'advanced-circuit', chance = 5},
	{name = 'artillery-shell', chance = 1},
	{name = 'cannon-shell', chance = 2},
	{name = 'cliff-explosives', chance = 5},
	{name = "cluster-grenade", chance = 2},
	{name = 'coin', chance = 1},
	{name = 'construction-robot', chance = 1},
	{name = 'copper-cable', chance = 250},
	{name = 'copper-plate', chance = 500},
	{name = 'crude-oil-barrel', chance = 30},
	{name = 'defender-capsule', chance = 5},
	{name = 'destroyer-capsule', chance = 1},
	{name = 'distractor-capsule', chance = 2},
	{name = 'electric-engine-unit', chance = 2},
	{name = 'electronic-circuit', chance = 200},
	{name = 'empty-barrel', chance = 10},
	{name = 'engine-unit', chance = 7},
	{name = 'explosive-cannon-shell', chance = 2},
	{name = "explosive-rocket", chance = 3},
	{name = 'explosive-uranium-cannon-shell', chance = 1},
	{name = 'explosives', chance = 5},
	{name = 'green-wire', chance = 10},
	{name = 'grenade', chance = 10},
	{name = 'heat-pipe', chance = 1},
	{name = 'heavy-oil-barrel', chance = 15},
	{name = 'iron-gear-wheel', chance = 500},
	{name = 'iron-plate', chance = 750},
	{name = 'iron-stick', chance = 50},
	{name = 'land-mine', chance = 3},
	{name = 'light-oil-barrel', chance = 15},
	{name = 'logistic-robot', chance = 1},
	{name = 'low-density-structure', chance = 1},
	{name = 'lubricant-barrel', chance = 20},
	{name = 'nuclear-fuel', chance = 1},
	{name = 'petroleum-gas-barrel', chance = 15},
	{name = 'pipe', chance = 100},
	{name = 'pipe-to-ground', chance = 10},
	{name = 'plastic-bar', chance = 5},
	{name = 'processing-unit', chance = 2},
	{name = 'red-wire', chance = 10},
	{name = "rocket", chance = 3},
	{name = "battery", chance = 20},
	{name = 'rocket-control-unit', chance = 1},
	{name = 'rocket-fuel', chance = 3},
	{name = 'solid-fuel', chance = 100},
	{name = 'steel-plate', chance = 150},
	{name = 'sulfuric-acid-barrel', chance = 15},
	{name = 'uranium-cannon-shell', chance = 1},
	{name = 'uranium-fuel-cell', chance = 1},
	{name = 'used-up-uranium-fuel-cell', chance = 1},
	{name = 'water-barrel', chance = 10}
}

local container_loot_amounts = {
	['advanced-circuit'] = 2,
	['artillery-shell'] = 0.3,
	['battery'] = 2,
	['cannon-shell'] = 2,
	['cliff-explosives'] = 2,
	["cluster-grenade"] = 0.3,
	['coin'] = 2,
	['construction-robot'] = 0.3,
	['copper-cable'] = 24,
	['copper-plate'] = 16,
	['crude-oil-barrel'] = 3,
	['defender-capsule'] = 2,
	['destroyer-capsule'] = 0.3,
	['distractor-capsule'] = 0.3,
	['electric-engine-unit'] = 2,
	['electronic-circuit'] = 8,
	['empty-barrel'] = 3,
	['engine-unit'] = 2,
	['explosive-cannon-shell'] = 2,
	["explosive-rocket"] = 2,
	['explosive-uranium-cannon-shell'] = 2,
	['explosives'] = 4,
	['green-wire'] = 8,
	['grenade'] = 2,
	['heat-pipe'] = 1,
	['heavy-oil-barrel'] = 3,
	['iron-gear-wheel'] = 8,
	['iron-plate'] = 16,
	['iron-stick'] = 16,
	['land-mine'] = 1,
	['light-oil-barrel'] = 3,
	['logistic-robot'] = 0.3,
	['low-density-structure'] = 0.3,
	['lubricant-barrel'] = 3,
	['nuclear-fuel'] = 0.1,
	['petroleum-gas-barrel'] = 3,
	['pipe'] = 8,
	['pipe-to-ground'] = 1,
	['plastic-bar'] = 4,
	['processing-unit'] = 1,
	['red-wire'] = 8,
	["rocket"] = 2,
	['rocket-control-unit'] = 0.3,
	['rocket-fuel'] = 0.3,
	['solid-fuel'] = 4,
	['steel-plate'] = 4,
	['sulfuric-acid-barrel'] = 3,
	['uranium-cannon-shell'] = 2,
	['uranium-fuel-cell'] = 0.3,
	['used-up-uranium-fuel-cell'] = 1,
	['water-barrel'] = 3
}

local scrap_raffle = {}
for _, t in pairs(container_loot_chance) do
	for _ = 1, t.chance, 1 do
		table_insert(scrap_raffle, t.name)
	end
end

local size_of_scrap_raffle = #scrap_raffle

local function treasure_chest(surface, position)
	local chest = containers[math_random(1, containers_index)]
	local e = surface.create_entity({name = chest.name, position = position, force = 'neutral'})
	e.minable = true
	local i = e.get_inventory(defines.inventory.chest)
	if i then
		local size = math_random(1, chest.size)
		for _ = 1, size, 1 do
			local loot = scrap_raffle[math_random(1, size_of_scrap_raffle)]
			local amount = container_loot_amounts[loot]
			local count = math_floor(amount * math_random(5, 35) * 0.1) + 1
			i.insert({name = loot, count = count})
		end
	end
	return
end

local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	if player.surface.name == 'nauvis' then
		return
	end
	local entity = event.entity
	if entity.name ~= "crash-site-chest-1" and entity.name ~= "crash-site-chest-2" then
		return
	end
	if math_random(1,4) == 1 then
		event.buffer = nil
		tick_tack_trap(entity.surface, entity.position)
	end
end

local function on_gui_opened(event)
	local player = game.players[event.player_index]
	if player.surface.name == 'nauvis' then
		return
	end
	local gui_type = event.gui_type
	if gui_type ~= defines.gui_type.entity then
		return
	end
	local entity = event.entity
	if entity.name ~= "crash-site-chest-1" and entity.name ~= "crash-site-chest-2" then
		return
	end
	if math_random(1,8) == 1 then
		tick_tack_trap(entity.surface, entity.position)
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_gui_opened, on_gui_opened)

return treasure_chest