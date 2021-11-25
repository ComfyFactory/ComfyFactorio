local Global = require 'utils.global'

local Public = {}
local simplex_noise = require 'utils.simplex_noise'.d2

local get_noise = require "utils.get_noise"
local random = math.random

local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local size_of_rock_raffle = #rock_raffle

local colors = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}}
local function add_light(e)
	local color = colors[math.random(1, 3)]
	local light_nr = rendering.draw_light({sprite="utility/light_small", orientation=1, scale=1, intensity=1, minimum_darkness=0, oriented=false, color=color, target=e, target_offset={0, -0.5}, surface=e.surface})
end
local ore_raffle = {
	"iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "coal", "stone"
}

local function is_scrap_area(noise)
	if noise > 0.63 then return end
	if noise < -0.63 then return end
	if noise > 0.33 then return true end
	if noise < -0.33 then return true end
end

local function place_entity(surface, position)
	if math.random(1, 4) == 1 then
		surface.create_entity({name = rock_raffle[math.random(1, size_of_rock_raffle)], position = position, force = "neutral"})
	end
end


local function move_away_things(surface, area)
	for _, e in pairs(surface.find_entities_filtered({type = {"unit-spawner",  "unit", "tree"}, area = area})) do
		local position = surface.find_non_colliding_position(e.name, e.position, 128, 4)
		if position then
			local entity = surface.create_entity({name = e.name, position = position, force = "enemy"})
			e.destroy()
		end
	end
end

function Public.world_cave(surface,position,seed,get_tile,set_tiles,event)
	if math.random(1, 2)==2 then
		if not get_tile(position).collides_with("resource-layer") then
			noise = get_noise("scrapyard", position, seed)
			if is_scrap_area(noise) then
				--set_tiles({{name = "dirt-" .. math.floor(math.abs(noise) * 12) % 4 + 3, position = position}}, true)
				place_entity(surface, position)
			end
		--	move_away_things(surface, event.area)
		end
	end
end

local spawn_size = 96
local wall_thickness = 3

local function is_spawn_wall(p)
	--if p.y < -32 and p.x < -32 then return false end
	--if p.y > 32 and p.x > 32 then return false end
	if p.x >= spawn_size - wall_thickness then return true end
	if p.x < spawn_size * -1 + wall_thickness then return true end
	if p.y >= spawn_size - wall_thickness then return true end
	if p.y < spawn_size * -1 + wall_thickness then return true end
	return false
end

function Public.quarter(event,x,y)
	local left_top = event.area.left_top
	if left_top.x < spawn_size and left_top.y < spawn_size and left_top.x >= spawn_size * -1 and left_top.y >= spawn_size * -1 then
		--摧毁水
		for _, entity in pairs(event.surface.find_entities_filtered({area = event.area, name = "water"})) do
			entity.destroy()
		end
		--建设墙
		local p = {x = left_top.x + x, y = left_top.y + y}
		event.surface.set_tiles({{name = "stone-path", position = p}})
		if is_spawn_wall(p) then
			event.surface.create_entity({name = "stone-wall", position = p, force = "player"})
		end
		--生成矿物
		local ore = false
		if left_top.x == -64 and left_top.y == -64 then ore = "coal" end
		if left_top.x == 32 and left_top.y == 32 then ore = "stone" end
		if left_top.x == 32 and left_top.y == -64 then ore = "iron-ore" end
		if left_top.x == -64 and left_top.y == 32 then ore = "copper-ore" end


		if not ore then return end
		local p = {x = left_top.x + x, y = left_top.y + y}
		event.surface.create_entity({name = ore, position = p, amount = 1000})
	end

	--切割水域
	local p = {left_top.x + x, left_top.y + y}
	local area=event.area
	local surface=event.surface
	if left_top.x == 0 or left_top.x == -32 then
		surface.set_tiles({{name = "deepwater", position = p}})
		surface.destroy_decoratives({area = area})

	end
	if left_top.y == 0 or left_top.y == -32 then
		surface.set_tiles({{name = "deepwater", position = p}})
		surface.destroy_decoratives({area = area})
	end
end


function Public.crossing(surface,maxs,position,area,left_top)

local noise_1 =1
if left_top.x < 64 and left_top.x > -64 then
	if position.x > -80 + (noise_1 * 8) and position.x < 80 + (noise_1 * 8) then
		local tile = surface.get_tile(position)
		if tile.name == "water" or tile.name == "deepwater" then
			surface.set_tiles({{name = "grass-2", position = position}})
		end

		if position.x > -26  and position.x < 28  then
			if position.y > 0 then
				surface.create_entity({name = "stone", position = position, amount = 1 + position.y * 0.5})
			else
				surface.create_entity({name = "coal", position = position, amount = 1 + position.y * -1 * 0.5})
			end
		end
	end
end

	if left_top.y < 64 and left_top.y > -64 then
		if position.y > -80 + (noise_1 * 8) and position.y < 80 + (noise_1 * 8) then
			local tile = surface.get_tile(position)
			if tile.name == "water" or tile.name == "deepwater" then
				surface.set_tiles({{name = "grass-2", position = position}})
			end
		end

		if position.y > -26  and position.y < 28  then
			if position.x > 0 then
				surface.create_entity({name = "copper-ore", position = position, amount = 1 + position.x * 0.5})
			else
				surface.create_entity({name = "iron-ore", position = position, amount = 1 + position.x * -1 * 0.5})
			end
		end
	end
end
local spawn_size = 160
local spawn_check = spawn_size + 96

local waters = {"water-shallow","water"}

local function is_water(position, noise, seed)
	if math.abs(position.y) <= spawn_check or math.abs(position.x) <= spawn_check then
		local border_noise = get_noise("cave_ponds", position, seed)
		if math.abs(position.x) + border_noise * 10 < spawn_size and math.abs(position.y) + border_noise * 10 < spawn_size then return false end
		if math.abs(position.x) + border_noise * 10 < spawn_size + 32 and math.abs(position.y) + border_noise * 10 < spawn_size + 32 then return true end
	end
	if noise > 0.50 then return end
	if noise < -0.50 then return end
	if noise > 0.50 then return true end
	if noise < -0.50 then return true end
	return true
end

function Public.water(surface,position,seed)

	if not surface.get_tile(position).collides_with("resource-layer") then
	local	noise = get_noise("watery_world", position, seed)
		if is_water(position, noise, seed) then
			surface.set_tiles({{name = waters[math.floor(noise * 10 % 2 + 1)], position = position}}, true)
			if math.random(1, 1024) == 1 then
				surface.create_entity({name = global.watery_world_fishes[math.random(1, #global.watery_world_fishes)], position = position})
			end
		end
	end

end


local noises = {
	["no_rocks"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["no_rocks_2"] = {{modifier = 0.013, weight = 1}, {modifier = 0.1, weight = 0.1}},
	["large_caves"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},
	["small_caves_2"] = {{modifier = 0.009, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.25, weight = 0.05}},
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_rivers"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_2"] = {{modifier = 0.003, weight = 1}, {modifier = 0.01, weight = 0.21}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_3"] = {{modifier = 0.002, weight = 1}, {modifier = 0.01, weight = 0.15}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_4"] = {{modifier = 0.001, weight = 1}, {modifier = 0.01, weight = 0.11}, {modifier = 0.05, weight = 0.01}},
	["scrapyard"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.35}, {modifier = 0.05, weight = 0.23}, {modifier = 0.1, weight = 0.11}},
  ["forest_location"] = {{modifier = 0.006, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.15}, {modifier = 0.1, weight = 0.05}},
	["forest_density"] = {{modifier = 0.01, weight = 1}, {modifier = 0.05, weight = 0.5}, {modifier = 0.1, weight = 0.025}},
  ["ores"] = {{modifier = 0.05, weight = 1}, {modifier = 0.02, weight = 0.55}, {modifier = 0.05, weight = 0.05}},
  ["hedgemaze"] = {{modifier = 0.001, weight = 1}}
}

local function get_noise_2(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise
end

function Public.water_dungle(surface,position,seed)

	if not surface.get_tile(position).collides_with("resource-layer") then
		local noise1 = get_noise_2("large_caves", position, seed)
		local noise2 = get_noise_2("cave_rivers", position, seed)
		local	noise = get_noise("watery_world", position, seed)
	if noise1 > -0.05 and noise1 < 0.05 and noise2 < 0.25 then
			surface.set_tiles({{name = waters[math.floor(noise * 10 % 2 + 1)], position = position}}, true)
			if math.random(1, 128) == 1 then
				surface.create_entity({name = global.watery_world_fishes[math.random(1, #global.watery_world_fishes)], position = position})
			end
		end
	end

end

function Public.winter(surface,area,event,seed)

	local ores = surface.find_entities_filtered({area = event.area, name = {"iron-ore", "copper-ore", "coal", "stone"}})
	for _, ore in pairs(ores) do
		local pos = ore.position
		local noise = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed) + simplex_noise(pos.x * 0.01, pos.y * 0.01, seed) * 0.3 + simplex_noise(pos.x * 0.05, pos.y * 0.05, seed) * 0.2

		local i = (math.floor(noise * 100) % 7) + 1
		surface.create_entity({name = ore_raffle[i], position = ore.position, amount = ore.amount})
		ore.destroy()
	end

end
return Public
