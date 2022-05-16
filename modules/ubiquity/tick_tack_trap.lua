-- timer traps -- by mewmew
local table_insert = table.insert
local math_random = math.random

local Table = require 'modules.ubiquity.table'

local tick_tacks = {'*tick*', '*tick*', '*tack*', '*tak*', '*tik*', '*tok*'}

local kaboom_weights = {
	{name = 'grenade', chance = 7},
	{name = 'cluster-grenade', chance = 1},
	{name = 'destroyer-capsule', chance = 1},
	{name = 'defender-capsule', chance = 4},
	{name = 'distractor-capsule', chance = 3},
	{name = 'poison-capsule', chance = 4},
	{name = 'explosive-uranium-cannon-projectile', chance = 3},
	{name = 'explosive-cannon-projectile', chance = 5}
}

local kabooms = {}
for _, t in pairs(kaboom_weights) do
	for _ = 1, t.chance, 1 do
		table_insert(kabooms, t.name)
	end
end

local function create_flying_text(surface_name, position, text)
	local surface = game.surfaces[surface_name]
	if not surface.valid then
		return
	end
	surface.create_entity(
			{
				name = 'flying-text',
				position = position,
				text = text,
				color = {r = 0.75, g = 0.75, b = 0.75}
			}
	)
	if text == '...' then
		return
	end
	surface.play_sound({path = 'utility/armor_insert', position = position, volume_modifier = 0.75})
end

local function create_kaboom(surface_name, position, name)
	local surface = game.surfaces[surface_name]
	if not surface.valid then
		return
	end
	local target = position
	local speed = 0.5
	if name == 'defender-capsule' or name == 'destroyer-capsule' or name == 'distractor-capsule' then
		surface.create_entity(
				{
					name = 'flying-text',
					position = position,
					text = '(((Sentries Engaging Target)))',
					color = {r = 0.8, g = 0.0, b = 0.0}
				}
		)
		local nearest_player_unit = surface.find_nearest_enemy({position = position, max_distance = 128, force = 'enemy'})
		if nearest_player_unit then
			target = nearest_player_unit.position
		end
		speed = 0.001
	end
	surface.create_entity(
			{
				name = name,
				position = position,
				force = 'enemy',
				target = target,
				speed = speed
			}
	)
end

local function tick_tack_trap(surface, position)
	local ubitable = Table.get_table()
	if not ubitable.on_tick_schedule then
		ubitable.on_tick_schedule = {}
	end

	local tick_tack_count = math_random(5, 9)
	for t = 60, tick_tack_count * 60, 60 do
		if not ubitable.on_tick_schedule[game.tick + t] then
			ubitable.on_tick_schedule[game.tick + t] = {}
		end

		if t < tick_tack_count * 60 then
			ubitable.on_tick_schedule[game.tick + t][#ubitable.on_tick_schedule[game.tick + t] + 1] = {
				func = create_flying_text,
				args = {surface.name, {x = position.x, y = position.y}, tick_tacks[math_random(1, #tick_tacks)]}
			}
		else
			if math_random(1, 10) == 1 then
				ubitable.on_tick_schedule[game.tick + t][#ubitable.on_tick_schedule[game.tick + t] + 1] = {
					func = create_flying_text,
					args = {surface.name, {x = position.x, y = position.y}, '...'}
				}
			else
				ubitable.on_tick_schedule[game.tick + t][#ubitable.on_tick_schedule[game.tick + t] + 1] = {
					func = create_kaboom,
					args = {surface.name, {x = position.x, y = position.y}, kabooms[math_random(1, #kabooms)]}
				}
			end
		end
	end
end

return tick_tack_trap
