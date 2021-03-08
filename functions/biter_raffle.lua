--[[
Use roll(entity_type, evolution_factor), to get a fitting enemy for the current or custom evolution factor.

entity_type 		- can be "spitter", "biter", "mixed", "worm"
evolution_factor 	- custom evolution factor (optional)
]]

local Public = {}
local math_random = math.random
local math_floor = math.floor

local function get_raffle_table(level, name)
	local raffle = {
		["small-" .. name] = 1000 - level * 1.75,		
		["medium-" .. name] = -250 + level * 1.5,
		["big-" .. name] = 0,		
		["behemoth-" .. name] = 0,
	}
	
	if level > 500 then
		raffle["medium-" .. name] = 500 - (level - 500)
		raffle["big-" .. name] = (level - 500) * 2
	end
	if level > 900 then
		raffle["behemoth-" .. name] = (level - 900) * 3
	end
	for k, v in pairs(raffle) do
		if raffle[k] < 0 then raffle[k] = 0 end
	end
	return raffle
end

local function roll(evolution_factor, name)
	local raffle = get_raffle_table(math_floor(evolution_factor * 1000), name)
	local max_chance = 0
	for k, v in pairs(raffle) do
		max_chance = max_chance + v
	end
	local r = math_random(0, math_floor(max_chance))	
	local current_chance = 0
	for k, v in pairs(raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

local function get_biter_name(evolution_factor)
	return roll(evolution_factor, "biter")
end

local function get_spitter_name(evolution_factor)	
	return roll(evolution_factor, "spitter")	
end

local function get_worm_raffle_table(level)
	local raffle = {
		["small-worm-turret"] = 1000 - level * 1.75,		
		["medium-worm-turret"] = level,		
		["big-worm-turret"] = 0,		
		["behemoth-worm-turret"] = 0,
	}
	
	if level > 500 then
		raffle["medium-worm-turret"] = 500 - (level - 500)
		raffle["big-worm-turret"] = (level - 500) * 2
	end
	if level > 900 then
		raffle["behemoth-worm-turret"] = (level - 900) * 3
	end
	for k, v in pairs(raffle) do
		if raffle[k] < 0 then raffle[k] = 0 end
	end
	return raffle
end

local function get_worm_name(evolution_factor)
	local raffle = get_worm_raffle_table(math_floor(evolution_factor * 1000))
	local max_chance = 0
	for k, v in pairs(raffle) do
		max_chance = max_chance + v
	end
	local r = math_random(0, math_floor(max_chance))	
	local current_chance = 0
	for k, v in pairs(raffle) do
		current_chance = current_chance + v
		if r <= current_chance then return k end
	end
end

local function get_unit_name(evolution_factor)
	if math_random(1, 3) == 1 then
		return get_spitter_name(evolution_factor)
	else
		return get_biter_name(evolution_factor)
	end
end

local type_functions = {
	["spitter"] = get_spitter_name,
	["biter"] = get_biter_name,
	["mixed"] = get_unit_name,
	["worm"] = get_worm_name,
}

function Public.roll(entity_type, evolution_factor)
	if not entity_type then return end
	if not type_functions[entity_type] then return end
	local evo = evolution_factor
	if not evo then evo = game.forces.enemy.evolution_factor end
	return type_functions[entity_type](evo)
end

return Public