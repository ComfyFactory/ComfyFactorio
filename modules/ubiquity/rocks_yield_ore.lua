--destroying and mining rocks yields ore -- load as last module
local max_spill = 60
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt

local Table = require 'modules.ubiquity.table'

local rock = {
	['rock-big'] = true,
	['rock-huge'] = true,
	['underground-rock-rock-big'] = true,
	['underground-rock-rock-huge'] = true,
	['underground-attack-rock'] = true
}

local sand = {
	['sand-rock-big'] = true,
	['underground-rock-sand-rock-big'] = true,
}

local yield = {
	['rock-big'] = 1,
	['rock-huge'] = 2,
	['sand-rock-big'] = 1,
	['underground-rock-rock-big'] = 1,
	['underground-rock-rock-huge'] = 2,
	['underground-rock-sand-rock-big'] = 1,
	['underground-attack-rock'] = 1
}

local particles = {
	['iron-ore'] = 'iron-ore-particle',
	['copper-ore'] = 'copper-ore-particle',
	['coal'] = 'coal-particle',
	['stone'] = 'stone-particle',
	['raw-rare-metals'] = 'stone-particle',
	['raw-imersite'] = 'stone-particle',
	['sand'] = 'stone-particle',
	['quartz'] = 'stone-particle',
	['silicon'] = 'stone-particle'
}

local function get_chances_rock()
	local chances = {}
	table.insert(chances, {'iron-ore', 50})
	table.insert(chances, {'copper-ore', 35})
	table.insert(chances, {'coal', 20})
	table.insert(chances, {'raw-rare-metals', 8})
	table.insert(chances, {'raw-imersite', 1})
	return chances
end

local function get_chances_sand()
	local chances = {}
	table.insert(chances, {'sand', 50})
	table.insert(chances, {'iron-ore', 10})
	table.insert(chances, {'copper-ore', 10})
	table.insert(chances, {'coal', 10})
	table.insert(chances, {'quartz', 8})
	table.insert(chances, {'silicon', 1})
	return chances
end

local function set_raffle_rock()
	local ubitable = Table.get_table()
	ubitable.rocks_yield_ore['raffle_rock'] = {}
	for _, t in pairs(get_chances_rock()) do
		for _ = 1, t[2], 1 do
			table.insert(ubitable.rocks_yield_ore['raffle_rock'], t[1])
		end
	end
	ubitable.rocks_yield_ore['size_of_rock_raffle'] = #ubitable.rocks_yield_ore['raffle_rock']
end

local function set_raffle_sand()
	local ubitable = Table.get_table()
	ubitable.rocks_yield_ore['raffle_sand'] = {}
	for _, t in pairs(get_chances_sand()) do
		for _ = 1, t[2], 1 do
			table.insert(ubitable.rocks_yield_ore['raffle_sand'], t[1])
		end
	end
	ubitable.rocks_yield_ore['size_of_sand_raffle'] = #ubitable.rocks_yield_ore['raffle_sand']
end

local function create_particles(surface, name, position, amount, cause_position)
	local direction_mod = (-100 + math_random(0, 200)) * 0.0004
	local direction_mod_2 = (-100 + math_random(0, 200)) * 0.0004

	if cause_position then
		direction_mod = (cause_position.x - position.x) * 0.025
		direction_mod_2 = (cause_position.y - position.y) * 0.025
	end

	for _ = 1, amount, 1 do
		local m = math_random(4, 10)
		local m2 = m * 0.005

		surface.create_particle(
				{
					name = name,
					position = position,
					frame_speed = 1,
					vertical_speed = 0.130,
					height = 0,
					movement = {
						(m2 - (math_random(0, m) * 0.01)) + direction_mod,
						(m2 - (math_random(0, m) * 0.01)) + direction_mod_2
					}
				}
		)
	end
end

local function get_amount(entity)
	local ubitable = Table.get_table()
	local distance_to_center = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))

	local amount = ubitable.rocks_yield_ore_base_amount + (distance_to_center * ubitable.rocks_yield_ore_distance_modifier)
	if amount > ubitable.rocks_yield_ore_maximum_amount then
		amount = ubitable.rocks_yield_ore_maximum_amount
	end

	local m = (70 + math_random(0, 60)) * 0.01

	amount = math_floor(amount * yield[entity.name] * m)
	if amount < 1 then
		amount = 1
	end

	return amount
end

local function on_player_mined_entity(event)
	local ubitable = Table.get_table()
	local entity = event.entity
	if not entity.valid then
		return
	end
	if not rock[entity.name] and not sand[entity.name] then
		return
	end

	event.buffer.clear()

	local ore
	if rock[entity.name] then
		ore = ubitable.rocks_yield_ore['raffle_rock'][math_random(1, ubitable.rocks_yield_ore['size_of_rock_raffle'])]
	else
		ore = ubitable.rocks_yield_ore['raffle_sand'][math_random(1, ubitable.rocks_yield_ore['size_of_sand_raffle'])]
	end
	local player = game.players[event.player_index]

	local count = get_amount(entity)
	count = math_floor(count * (1 + player.force.mining_drill_productivity_bonus))

	ubitable.rocks_yield_ore['ores_mined'] = ubitable.rocks_yield_ore['ores_mined'] + count
	ubitable.rocks_yield_ore['rocks_broken'] = ubitable.rocks_yield_ore['rocks_broken'] + 1

	local position = {x = entity.position.x, y = entity.position.y}

	local ore_amount = math_floor(count * 0.85) + 1
	local stone_amount = math_floor(count * 0.15) + 1

	player.surface.create_entity({name = 'flying-text', position = position, text = '+' .. ore_amount .. ' [img=item/' .. ore .. ']', color = {r = 200, g = 160, b = 30}})
	create_particles(player.surface, particles[ore], position, 64, {x = player.position.x, y = player.position.y})

	if ore_amount > max_spill then
		player.surface.spill_item_stack(position, {name = ore, count = max_spill}, true)
		ore_amount = ore_amount - max_spill
		local inserted_count = player.insert({name = ore, count = ore_amount})
		ore_amount = ore_amount - inserted_count
		if ore_amount > 0 then
			player.surface.spill_item_stack(position, {name = ore, count = ore_amount}, true)
		end
	else
		player.surface.spill_item_stack(position, {name = ore, count = ore_amount}, true)
	end

	if stone_amount > max_spill then
		player.surface.spill_item_stack(position, {name = 'stone', count = max_spill}, true)
		stone_amount = stone_amount - max_spill
		local inserted_count = player.insert({name = 'stone', count = stone_amount})
		stone_amount = stone_amount - inserted_count
		if stone_amount > 0 then
			player.surface.spill_item_stack(position, {name = 'stone', count = stone_amount}, true)
		end
	else
		player.surface.spill_item_stack(position, {name = 'stone', count = stone_amount}, true)
	end
end

local function on_init()
	local ubitable = Table.get_table()
	ubitable.rocks_yield_ore = {}
	ubitable.rocks_yield_ore['rocks_broken'] = 0
	ubitable.rocks_yield_ore['ores_mined'] = 0
	set_raffle_rock()
	set_raffle_sand()

	if not ubitable.rocks_yield_ore_distance_modifier then
		ubitable.rocks_yield_ore_distance_modifier = 0.25
	end
	if not ubitable.rocks_yield_ore_base_amount then
		ubitable.rocks_yield_ore_base_amount = 4
	end
	if not ubitable.rocks_yield_ore_maximum_amount then
		ubitable.rocks_yield_ore_maximum_amount = 16
	end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
