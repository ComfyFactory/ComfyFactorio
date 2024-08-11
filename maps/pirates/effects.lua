-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio.


local Math = require 'maps.pirates.math'
-- local Memory = require 'maps.pirates.memory'
local _inspect = require 'utils.inspect'.inspect
local Token = require 'utils.token'
local Task = require 'utils.task'

local Public = {}


function Public.worm_movement_effect(surface, position, solid_ground, big_bool)
	if not (surface and surface.valid) then return end

	if solid_ground then big_bool = false end

	local number, rmax, particles, sound
	if big_bool then
		number = 80
		rmax = 4
		particles = {'huge-rock-stone-particle-big', 'huge-rock-stone-particle-medium', 'red-desert-1-stone-particle-medium'}
		-- sound = 'utility/build_blueprint_large'
		sound = 'utility/build_blueprint_large'
	else
		number = 40
		rmax = 2.5
		particles = {'huge-rock-stone-particle-medium', 'red-desert-1-stone-particle-medium', 'red-desert-1-stone-particle-small'}
		sound = 'utility/build_blueprint_medium'
	end

	if solid_ground then
		particles = {'refined-concrete-stone-particle-medium', 'refined-concrete-stone-particle-small'}
		sound = 'utility/build_blueprint_small'
	end


	local function p(r, theta) return {x = position.x + r*Math.sin(theta), y = position.y + r*Math.cos(theta)} end

	for i=1,number do
		local r = rmax * Math.sqrt(Math.random())
		local theta = Math.random()*6.283
		local name = particles[Math.random(#particles)]
		local _p = p(r,theta)

		surface.create_particle{name = name, position = _p, movement = {0/10, 0/10}, height = 0, vertical_speed = 0.02 + Math.sqrt(rmax - r)*rmax/50, frame_speed = 1}

		if i<=5 then
			surface.play_sound{path = sound, position = _p, override_sound_type = 'walking', volume_modifier=0.75}
		end
	end
end


function Public.worm_emerge_effect(surface, position)
	if not (surface and surface.valid) then return end
	if position then
		local function p(r, theta) return {x = position.x + r*Math.sin(theta), y = position.y + r*Math.cos(theta)} end

		for theta=0,6,0.5 do
			local r = 3
			surface.create_entity{name = 'blood-explosion-huge', position = p(r,theta), color={1,1,1}}
		end
	end
end

function Public.biters_emerge(surface, position)
	if not (surface and surface.valid) then return end
	surface.create_entity{name = 'spitter-spawner-die', position = position}
end

function Public.kraken_effect_1(surface, position, angle)
	if not (surface and surface.valid) then return end
	local r = 9
	local p = {position.x + r*Math.sin(angle), position.y + r*Math.cos(angle)}
	surface.create_entity{name = 'blood-explosion-huge', position = p, color={1,1,1}}
end

function Public.kraken_effect_2(surface, position)
	if not (surface and surface.valid) then return end
	surface.create_entity{name = 'blood-explosion-big', position = position, color={1,1,1}}
end

local kraken_effect_3_token =
    Token.register(
    function(data)
		Public.kraken_effect_3(data.surface, data.position, data.r)
	end
)
function Public.kraken_effect_3(surface, position, r)
	r = r or 3
	if not (surface and surface.valid) then return end

	for theta=0,6.283,6.283/32 do
		local p = {position.x + r*Math.sin(theta), position.y + r*Math.cos(theta)}
		surface.create_entity{name = 'water-splash', position = p, color={1,1,1}}
	end

	local rmax = 100
	if r < rmax then
		Task.set_timeout_in_ticks(4, kraken_effect_3_token, {surface = surface, position = position, r = r + 2})
	end
end

function Public.kraken_effect_4(surface, position)
	if not (surface and surface.valid) then return end
	local r = 6
	for theta=0,6.283,6.283/32 do
		local p = {position.x + r*Math.sin(theta), position.y + r*Math.cos(theta)}
		surface.create_entity{name = 'blood-explosion-big', position = p, color={1,1,1}}
	end
end

function Public.kraken_effect_5(surface, position)
	if not (surface and surface.valid) then return end
	local r = 6
	for theta=0,6.283,6.283/32 do
		local p = {position.x + r*Math.sin(theta), position.y + r*Math.cos(theta)}
		surface.create_entity{name = 'blood-explosion-huge', position = p, color={1,1,1}}
	end
end


return Public