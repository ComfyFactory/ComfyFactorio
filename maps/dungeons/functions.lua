local Public = {}

local BiterRaffle = require "functions.biter_raffle"
local LootRaffle = require "functions.loot_raffle"

local table_shuffle_table = table.shuffle_table
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
	return BiterRaffle.roll("worm", global.dungeons.depth * 0.001)
end

function Public.get_crude_oil_amount()
	return math_random(200000, 400000) + global.dungeons.depth * 500
end

function Public.get_common_resource_amount()
	return math_random(350, 650) + global.dungeons.depth * 10
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
	local container = surface.create_entity({name = "iron-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.rare_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 8 + math_random(128, 256), 32)
	local container = surface.create_entity({name = "steel-chest", position = position, force = "neutral"})
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

function Public.set_spawner_tier(spawner)
	local tier = math_floor(global.dungeons.depth * 0.005 - math_random(0, 5)) + 1
	if tier < 1 then tier = 1 end		
	global.dungeons.spawner_tier[spawner.unit_number] = tier
	--[[
	rendering.draw_text{
		text = "-Tier " .. tier .. "-",
		surface = spawner.surface,
		target = spawner,
		target_offset = {0, -2.65},
		color = {25, 0, 100, 255},
		scale = 1.25,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	]]
end

function Public.spawn_random_biter(surface, position)
	local name = BiterRaffle.roll("mixed", global.dungeons.depth * 0.0005)
	local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
	local unit
	if non_colliding_position then
		unit = surface.create_entity({name = name, position = non_colliding_position, force = "enemy"})
	else
		unit = surface.create_entity({name = name, position = position, force = "enemy"})
	end	
	unit.ai_settings.allow_try_return_to_spawner = false
	unit.ai_settings.allow_destroy_when_commands_fail = false
end

function Public.place_border_rock(surface, position)
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)
	
	local key = false
	for k, v in pairs(vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if tile.name == "out-of-map" then
			key = k
			break
		end
	end	
	if not key then return end
	
	local pos = {x = position.x + 0.5, y = position.y + 0.5}
	pos = {pos.x + vectors[key][1] * 0.45, pos.y + vectors[key][2] * 0.45}
	surface.create_entity({name = "rock-big", position = pos})
end

return Public