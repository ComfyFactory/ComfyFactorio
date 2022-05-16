--wreckage yields scrap
local math_random = math.random

local wreckage = {
	-- simple entity
	['small-ship-wreck'] = true,
	['medium-ship-wreck'] = true,
	['crash-site-spaceship-wreck-small-1'] = true,
	['crash-site-spaceship-wreck-small-2'] = true,
	['crash-site-spaceship-wreck-small-3'] = true,
	['crash-site-spaceship-wreck-small-4'] = true,
	['crash-site-spaceship-wreck-small-5'] = true,
	['crash-site-spaceship-wreck-small-6'] = true,
	['kr-mineable-wreckage'] = true
}

-- loot chances and amounts for scrap entities
local loot = {}
loot[1] = { name = "iron-plate", amount_min = 1, amount_max = 2, probability = 0.70 }
loot[2] = { name = "copper-cable", amount_min = 0, amount_max = 2, probability = 0.40 }
loot[3] = { name = "iron-gear-wheel", amount_min = 0, amount_max = 2, probability = 0.40 }
loot[4] = { name = "electronic-circuit", amount_min = 0, amount_max = 2, probability = 0.20 }
loot[5] = { name = "kr-sentinel", amount_min = 0, amount_max = 2, probability = 0.10 }

local function on_player_mined_entity(event)
	local player = game.get_player(event.player_index)
	local entity = event.entity
	if not entity.valid then
		return
	end
	if player.surface.name == 'nauvis' then
		return
	end
	local position = entity.position

	if not wreckage[entity.name] then
		return
	end

	-- scrap entities drop loot
	event.buffer.clear()

	for _, item in pairs(loot) do
		if math_random(0, 100) > item.probability * 100 then
			local amount = math_random(item.amount_min, item.amount_max)
			if amount > 0 then
			local inserted_count = player.insert({name = item.name, count = amount})
			if inserted_count ~= amount then
				local amount_to_spill = amount - inserted_count
				entity.surface.spill_item_stack(position, {name = item.name, count = amount_to_spill}, true)
			end
			entity.surface.create_entity({
				name = 'flying-text',
				position = position,
				text = '+' .. amount .. ' [img=item/' .. item.name .. ']',
				color = {r = 0.98, g = 0.66, b = 0.22}
			})
			end
		end
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
