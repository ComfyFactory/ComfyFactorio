local math_random = math.random
local math_ceil = math.ceil

local Table = require 'modules.ubiquity.table'

local function create_particles(surface_name, position, amount)
	local surface = game.surfaces[surface_name]
	if not surface.valid then
		return
	end
	for _ = 1, amount, 1 do
		local m = math_random(8, 24)
		local m2 = m * 0.005

		surface.create_particle(
				{
					name = 'stone-particle',
					position = position,
					frame_speed = 0.1,
					vertical_speed = 0.1,
					height = 0.1,
					movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
				}
		)
	end
end

local function spawn_worm(surface_name, position, evolution_index)
	local surface = game.surfaces[surface_name]
	if not surface.valid then
		return
	end
	local worm_raffle_table = {
		[1] = {'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret'},
		[2] = {'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret'},
		[3] = {'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret'},
		[4] = {'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret'},
		[5] = {'small-worm-turret', 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret'},
		[6] = {'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret'},
		[7] = {'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret'},
		[8] = {'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret'},
		[9] = {'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret', 'big-worm-turret'},
		[10] = {'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret', 'big-worm-turret'}
	}
	local raffle = worm_raffle_table[evolution_index]
	local worm_name = raffle[math_random(1, #raffle)]
	surface.create_entity({name = worm_name, position = position, force = 'enemy'})
end

local function unearthing_worm(surface, position, evolution_factor)
	local ubitable = Table.get_table()
	if not ubitable.on_tick_schedule then
		ubitable.on_tick_schedule = {}
	end

	local evolution_index = math_ceil(evolution_factor * 10)
	if evolution_index < 1 then
		evolution_index = 1
	end

	for t = 1, 330, 1 do
		if not ubitable.on_tick_schedule[game.tick + t] then
			ubitable.on_tick_schedule[game.tick + t] = {}
		end

		ubitable.on_tick_schedule[game.tick + t][#ubitable.on_tick_schedule[game.tick + t] + 1] = {
			func = create_particles,
			args = {surface.name, {x = position.x, y = position.y}, math_ceil(t * 0.05)}
		}

		if t == 330 then
			ubitable.on_tick_schedule[game.tick + t][#ubitable.on_tick_schedule[game.tick + t] + 1] = {
				func = spawn_worm,
				args = {surface.name, {x = position.x, y = position.y}, evolution_index}
			}
		end
	end
end

return unearthing_worm
