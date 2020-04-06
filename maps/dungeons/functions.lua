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
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 2 + math_random(8, 16), 16)
	local container = surface.create_entity({name = "wooden-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.uncommon_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 4 + math_random(32, 64), 16)
	local container = surface.create_entity({name = "wooden-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.rare_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 8 + math_random(128, 256), 32)
	local container = surface.create_entity({name = "iron-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.epic_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 16 + math_random(512, 1024), 48)
	local container = surface.create_entity({name = "steel-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.crash_site_chest(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 6 + math_random(160, 320), 48)
	local container = surface.create_entity({name = "crash-site-chest-" .. math_random(1, 2), position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.spawn_random_biter(surface, position)
	local name = BiterRaffle.roll("mixed", global.dungeons.depth * 0.001)
	local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
	if non_colliding_position then
		local unit = surface.create_entity({name = name, position = non_colliding_position, force = "enemy"})
	else
		local unit = surface.create_entity({name = name, position = position, force = "enemy"})
	end	
end

return Public