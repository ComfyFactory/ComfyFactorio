local simplex_noise = require 'utils.simplex_noise'.d2
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt
local ores = {"copper-ore", "iron-ore", "stone", "coal"}

local function pos_to_key(position)
    return tostring(position.x .. "_" .. position.y)
end

local function draw_noise_ore_patch(position, name, surface, radius, richness, mixed)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
  local ore_raffle = {
	"iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "coal", "stone"
  }
	local seed = surface.map_gen_settings.seed
	local noise_seed_add = 25000
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x + 0.5, y = y + position.y + 0.5}
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed + 25000)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then
        pos = surface.find_non_colliding_position(name, pos, 64, 1)
        if not pos then return end
        if mixed then
          local noise = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed) + simplex_noise(pos.x * 0.01, pos.y * 0.01, seed) * 0.3 + simplex_noise(pos.x * 0.05, pos.y * 0.05, seed) * 0.2
      		local i = (math_floor(noise * 100) % 7) + 1
          name = ore_raffle[i]
        end
        local entity = {name = name, position = pos, amount = a}
				if surface.can_place_entity(entity) then
          surface.create_entity(entity)
        end
          --if not global.ores_queue[pos.x] then global.ores_queue[pos.x] = {} end

          --global.ores_queue[pos_to_key(pos)] = {name = name, position = pos, amount = a}
				--end
			end
		end
	end
end

-- function ores_are_mixed(surface)
--   local ore_raffle = {
-- 	"iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "coal", "stone"
--   }
--   local r = 480
-- 	local area = {{r * -1, r * -1}, {r, r}}
--   local ores = surface.find_entities_filtered({area = area, name = {"iron-ore", "copper-ore", "coal", "stone"}})
--   	if #ores == 0 then return end
--   	local seed = surface.map_gen_settings.seed
--
--   	for _, ore in pairs(ores) do
--   		local pos = ore.position
--   		local noise = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed) + simplex_noise(pos.x * 0.01, pos.y * 0.01, seed) * 0.3 + simplex_noise(pos.x * 0.05, pos.y * 0.05, seed) * 0.2
--
--   		local i = (math.floor(noise * 100) % 7) + 1
--       --if not global.ores_queue[pos.x] then global.ores_queue[pos.x] = {} end
--       --global.ores_queue[pos_to_key(pos)] = {name = ore_raffle[i], position = ore.position, amount = ore.amount}
--   		ore.destroy()
--   	end
--   end

local function get_size_of_ore(ore, planet)
  local base_size = math_random(5, 10) + math_floor(planet[1].ore_richness.factor * 3)
  local final_size = 1
  if planet[1].name.name == "iron planet" and ore == "iron-ore" then
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].name.name == "copper planet" and ore == "copper-ore" then
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].name.name == "stone planet" and ore == "stone" then
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].name.name == "coal planet" and ore == "coal" then
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].name.name == "uranium planet" and ore == "uranium-ore" then
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].name.name == "mixed planet" then
    final_size = base_size
  else
    final_size = math_floor(base_size / 2)
  end
  return final_size
end

local function get_oil_amount(pos, oil_w)
  local hundred_percent = 300000
	return (hundred_percent / 20) * (1+global.objective.chronojumps) * oil_w
end

function spawn_ore_vein(surface, pos, planet)
  local mixed = false
  if planet[1].name.name == "mixed planet" then mixed = true end
  local richness = math_random(50 + 30 * global.objective.chronojumps, 100 + 30 * global.objective.chronojumps) * planet[1].ore_richness.factor
  local iron = {w = planet[1].name.iron, t = planet[1].name.iron}
  local copper = {w = planet[1].name.copper, t = iron.t + planet[1].name.copper}
  local stone = {w = planet[1].name.stone, t = copper.t + planet[1].name.stone}
  local coal = {w = planet[1].name.coal, t = stone.t + planet[1].name.coal}
  local uranium = {w = planet[1].name.uranium, t = coal.t + planet[1].name.uranium}
  local oil = {w = planet[1].name.oil, t = uranium.t + planet[1].name.oil}

  local total = iron.w + copper.w + stone.w + coal.w + uranium.w + oil.w
  local roll = math_random (0, oil.t)
  if roll == 0 then return end
  local choice = nil
  if roll <= iron.t then
    choice = "iron-ore"
  elseif roll <= copper.t then
    choice = "copper-ore"
  elseif roll <= stone.t then
    choice = "stone"
  elseif roll <= coal.t then
    choice = "coal"
  elseif roll <= uranium.t then
    choice = "uranium-ore"
  elseif roll <= oil.t then
    choice = "crude-oil"
  end

  --if surface.can_place_entity({name = choice, position = pos, amount = 1}) then
    if choice == "crude-oil" then
      surface.create_entity({name = "crude-oil", position = pos, amount = get_oil_amount(pos, oil.w) })
    else
      draw_noise_ore_patch(pos, choice, surface, get_size_of_ore(choice, planet), richness, mixed)
    end
  --end
end

function prospect_ores(entity)
  local planet = global.objective.planet
  local chance = 10
  if entity.name == "rock-huge" then chance = 40 end
  if math_random(chance + math_floor(10 * planet[1].ore_richness.factor) ,100 + chance) >= 100 then
    spawn_ore_vein(entity.surface, entity.position, planet)
    --if planet[1].name.name == "mixed planet" then
  end
end
