local Public = {}

local BiterRaffle = require "functions.biter_raffle"
local LootRaffle = require "functions.loot_raffle"

local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor

function Public.roll_spawner_name()
	if math_random(1, 3) == 1 then
		return "spitter-spawner"
	end
	return "biter-spawner"
end

function Public.roll_worm_name()
	return BiterRaffle.roll("worm", global.dungeons.depth * 0.002)
end

function Public.get_crude_oil_amount()
	return math_random(200000, 400000) + global.dungeons.depth * 500
end

function Public.common_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 2 + 8, 16)
	local container = surface.create_entity({name = "wooden-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

return Public