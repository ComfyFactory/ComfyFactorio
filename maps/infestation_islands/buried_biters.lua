local Event = require 'utils.event'
local Public = require 'maps.infestation_islands.table'
local Global = require 'utils.global'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Server = require 'utils.server'

local this = {}

Global.register(
	this,
	function (t)
		this = t
	end
)

local scale_units_by_health =
{
	['small-biter'] = 1,
	['medium-biter'] = 0.75,
	['big-biter'] = 0.5,
	['behemoth-biter'] = 0.25,
	['small-spitter'] = 1,
	['medium-spitter'] = 0.75,
	['big-spitter'] = 0.5,
	['behemoth-spitter'] = 0.25
}

local scale_worms_by_health =
{
	['land-mine'] = 0.5, -- not active as of now
	['gun-turret'] = 0.5, -- not active as of now
	['flamethrower-turret'] = 0.4, -- not active as of now
	['artillery-turret'] = 0.25, -- not active as of now
	['small-worm-turret'] = 0.8,
	['medium-worm-turret'] = 0.6,
	['big-worm-turret'] = 0.3,
	['behemoth-worm-turret'] = 0.3
}

local round = math.round
local floor = math.floor
local random = math.random

local spawn_amount_rolls = {}
for a = 48, 1, -1 do
	spawn_amount_rolls[#spawn_amount_rolls + 1] = floor(a ^ 5)
end

local random_particles =
{
	'dirt-2-stone-particle-medium',
	'dirt-4-dust-particle',
	'coal-particle'
}

local s_random_particles = #random_particles

local function create_particles(data)
	local surface = data.surface
	local position = data.position
	local amount = data.amount

	if not surface or not surface.valid then
		return
	end
	for _ = 1, amount, 1 do
		local m = random(6, 12)
		local m2 = m * 0.005

		surface.create_particle(
			{
				name = random_particles[random(1, s_random_particles)],
				position = position,
				frame_speed = 0.1,
				vertical_speed = 0.1,
				height = 0.1,
				movement = { m2 - (random(0, m) * 0.01), m2 - (random(0, m) * 0.01) }
			}
		)
	end
end

local function roll_biter(level)
	if not level or level <= 3 then
		return 'small-biter'
	elseif level <= 6 then
		local choices = { 'small-biter', 'medium-biter' }
		return choices[random(1, #choices)]
	elseif level <= 10 then
		local choices = { 'small-biter', 'medium-biter', 'big-biter' }
		return choices[random(1, #choices)]
	else
		local choices = { 'medium-biter', 'big-biter', 'behemoth-biter' }
		return choices[random(1, #choices)]
	end
end

local function roll_worm(level)
	if not level or level <= 3 then
		return 'small-worm-turret'
	elseif level <= 6 then
		local choices = { 'small-worm-turret', 'medium-worm-turret' }
		return choices[random(1, #choices)]
	elseif level <= 10 then
		local choices = { 'small-worm-turret', 'medium-worm-turret', 'big-worm-turret' }
		return choices[random(1, #choices)]
	else
		local choices = { 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret' }
		return choices[random(1, #choices)]
	end
end

local function roll_health_boost(level)
	if not level or level <= 3 then
		return 1
	elseif level <= 6 then
		return 1.5
	elseif level <= 10 then
		return 2
	elseif level > 10 then
		return 3
	end
end

local function spawn_biters(data)
	local alive_enemies = Public.get('alive_enemies')
	local max_biters_per_island = Public.get('max_biters_per_island')
	if alive_enemies >= max_biters_per_island then
		return false
	end

	local surface = data.surface
	if not (surface and surface.valid) then
		return false
	end
	local current_level = Public.get('current_level')

	local position = surface.find_non_colliding_position('small-biter', data.position, 10, 1)
	if not position then
		position = data.position
	end

	local unit_to_create = roll_biter(current_level)

	if not unit_to_create then
		Server.output_script_data('buried_enemies - unit_to_create was nil?')
		return
	end


	local unit = surface.create_entity({ name = unit_to_create, position = position, force = data.force or 'enemy' })
	if not unit or not unit.valid then
		return
	end

	alive_enemies = Public.get('alive_enemies')

	Public.set('alive_enemies', alive_enemies + 1)

	local health_boost = roll_health_boost(current_level) or 1

	if random(1, 30) == 1 then
		BiterHealthBooster.add_boss_unit(unit, health_boost, 0.38)
	else
		local final_health = round(health_boost * scale_units_by_health[unit.name], 3)
		if final_health < 1 then
			final_health = 1
		end
		BiterHealthBooster.add_unit(unit, final_health)
	end
	return true
end

local function spawn_tech(data)
	local alive_enemies = Public.get('alive_enemies')
	local max_biters_per_island = Public.get('max_biters_per_island')
	if alive_enemies >= max_biters_per_island then
		return false
	end

	local surface = data.surface
	if not (surface and surface.valid) then
		return false
	end
	local position = surface.find_non_colliding_position('small-biter', data.position, 10, 1)
	if not position then
		position = data.position
	end

	local current_level = Public.get('current_level')

	local rand_tech =
	{
		'defender',
		'destroyer',
		'distractor'
	}

	local unit_to_create

	if random(1, 3) == 1 then
		unit_to_create = rand_tech[random(1, #rand_tech)]
	else
		unit_to_create = rand_tech[random(1, #rand_tech)]
	end

	if not unit_to_create then
		Server.output_script_data('spawn_tech - unit_to_create was nil?')
		return
	end

	local health_boost = roll_health_boost(current_level) or 1


	local unit = surface.create_entity({ name = unit_to_create, position = position, force = data.force or 'enemy' })
	if not unit or not unit.valid then
		return
	end

	if random(1, 30) == 1 then
		BiterHealthBooster.add_boss_unit(unit, health_boost, 0.38)
	else
		local final_health = round(health_boost * 0.5, 3)
		if final_health < 1 then
			final_health = 1
		end
		BiterHealthBooster.add_unit(unit, final_health)
	end
	return true
end

local function spawn_worms(data)
	local alive_enemies = Public.get('alive_enemies')
	local max_biters_per_island = Public.get('max_biters_per_island')
	if alive_enemies >= max_biters_per_island then
		return false
	end

	local current_level = Public.get('current_level')
	local unit_to_create = roll_worm(current_level)

	if not unit_to_create then
		return false
	end

	local surface = data.surface
	if not (surface and surface.valid) then
		return false
	end
	local position = surface.find_non_colliding_position('small-worm-turret', data.position, 10, 1)
	if not position then
		position = data.position
	end

	local unit = surface.create_entity({ name = unit_to_create, position = position })
	if not unit or not unit.valid then
		return
	end
	alive_enemies = Public.get('alive_enemies')
	Public.set('alive_enemies', alive_enemies + 1)

	local health_boost = roll_health_boost(current_level) or 1

	if random(1, 30) == 1 then
		BiterHealthBooster.add_boss_unit(unit, health_boost, 0.38)
	else
		local final_health = round(health_boost * scale_worms_by_health[unit.name], 3)
		if final_health < 1 then
			final_health = 1
		end

		BiterHealthBooster.add_unit(unit, final_health)
	end
end

function Public.buried_biter(surface, position, count, force)
	if not (surface and surface.valid) then
		return
	end
	if not position then
		return
	end
	if not position.x then
		return
	end
	if not position.y then
		return
	end

	if not count then
		count = 1
	end

	for t = 1, 60, 1 do
		if not this[game.tick + t] then
			this[game.tick + t] = {}
		end

		this[game.tick + t][#this[game.tick + t] + 1] =
		{
			callback = 'create_particles',
			data = { surface = surface, position = { x = position.x, y = position.y }, amount = math.ceil(t * 0.05) }
		}

		if t == 60 then
			if count == 1 then
				this[game.tick + t][#this[game.tick + t] + 1] =
				{
					callback = 'spawn_biters',
					data = { surface = surface, position = { x = position.x, y = position.y }, count = count or 1, force = force or 'enemy' }
				}
			else
				local tick = 2
				for _ = 1, count do
					this[game.tick + t][#this[game.tick + t] + 1 + tick] =
					{
						callback = 'spawn_biters',
						data = { surface = surface, position = { x = position.x, y = position.y }, count = count or 1, force = force or 'enemy' }
					}
					tick = tick + 2
				end
			end
		end
	end
end

function Public.buried_tech(surface, position, count, force)
	if not (surface and surface.valid) then
		return
	end
	if not position then
		return
	end
	if not position.x then
		return
	end
	if not position.y then
		return
	end

	if not count then
		count = 1
	end

	for t = 1, 60, 1 do
		if not this[game.tick + t] then
			this[game.tick + t] = {}
		end

		this[game.tick + t][#this[game.tick + t] + 1] =
		{
			callback = 'create_particles',
			data = { surface = surface, position = { x = position.x, y = position.y }, amount = math.ceil(t * 0.05) }
		}

		if t == 60 then
			if count == 1 then
				this[game.tick + t][#this[game.tick + t] + 1] =
				{
					callback = 'spawn_tech',
					data = { surface = surface, position = { x = position.x, y = position.y }, count = count or 1, force = force or 'enemy' }
				}
			else
				local tick = 2
				for _ = 1, count do
					this[game.tick + t][#this[game.tick + t] + 1 + tick] =
					{
						callback = 'spawn_tech',
						data = { surface = surface, position = { x = position.x, y = position.y }, count = count or 1, force = force or 'enemy' }
					}
					tick = tick + 2
				end
			end
		end
	end
end

function Public.buried_worm(surface, position)
	if not (surface and surface.valid) then
		return
	end
	if not position then
		return
	end
	if not position.x then
		return
	end
	if not position.y then
		return
	end

	for t = 1, 60, 1 do
		if not this[game.tick + t] then
			this[game.tick + t] = {}
		end

		this[game.tick + t][#this[game.tick + t] + 1] =
		{
			callback = 'create_particles',
			data = { surface = surface, position = { x = position.x, y = position.y }, amount = math.ceil(t * 0.05) }
		}

		if t == 60 then
			this[game.tick + t][#this[game.tick + t] + 1] =
			{
				callback = 'spawn_worms',
				data = { surface = surface, position = { x = position.x, y = position.y } }
			}
		end
	end
end

local callbacks =
{
	['create_particles'] = create_particles,
	['spawn_biters'] = spawn_biters,
	['spawn_worms'] = spawn_worms,
	['spawn_tech'] = spawn_tech
}

local function on_tick()
	local t = game.tick
	if not this[t] then
		return
	end
	for _, token in pairs(this[t]) do
		local callback = token.callback
		local data = token.data
		local cbl = callbacks[callback]
		if callbacks[callback] then
			cbl(data)
		end
	end
	this[t] = nil
end

function Public.reset_buried_biters()
	for k, _ in pairs(this) do
		this[k] = nil
	end
end

Event.add(defines.events.on_tick, on_tick)

return Public
