
--require "maps.chronosphere.ores"

local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local math_sqrt = math.sqrt
local level_depth = 960
local Treasure = require 'maps.chronosphere.treasure'
local simplex_noise = require "utils.simplex_noise".d2
local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local size_of_rock_raffle = #rock_raffle
local dead_tree_raffle = {"dead-dry-hairy-tree", "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree"}
local tree_raffle = {"tree-01", "tree-02", "tree-02-red", "tree-03", "tree-04", "tree-05", "tree-06", "tree-06-brown", "tree-07",
      "tree-08", "tree-08-brown", "tree-08-red", "tree-09", "tree-09-brown", "tree-09-red"}
local s_tree_raffle = #tree_raffle
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
local worm_raffle = {
  "small-worm-turret", "small-worm-turret", "medium-worm-turret", "small-worm-turret",
  "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "medium-worm-turret",
  "big-worm-turret","big-worm-turret","behemoth-worm-turret", "big-worm-turret",
  "behemoth-worm-turret","behemoth-worm-turret","behemoth-worm-turret","big-worm-turret","behemoth-worm-turret"
}
local scrap_entities = {"crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-lab-broken",
 "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck",
 "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2"}
local scrap_entities_index = #scrap_entities
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
  ["ores"] = {{modifier = 0.05, weight = 1}, {modifier = 0.02, weight = 0.55}, {modifier = 0.05, weight = 0.05}}
}

local function pos_to_key(position)
    return tostring(position.x .. "_" .. position.y)
end

local function get_noise(name, pos, seed)
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

local function get_size_of_ore(ore, planet)
  local base_size = 0.04 + 0.04 * planet[1].ore_richness.factor
  local final_size = 1
  if planet[1].name.name == "iron planet" and ore == "iron-ore" then
    final_size = base_size * 5
  elseif planet[1].name.name == "copper planet" and ore == "copper-ore" then
    final_size = base_size * 5
  elseif planet[1].name.name == "stone planet" and ore == "stone" then
    final_size = base_size * 5
  elseif planet[1].name.name == "coal planet" and ore == "coal" then
    final_size = base_size * 5
  elseif planet[1].name.name == "uranium planet" and ore == "uranium-ore" then
    final_size = base_size * 5
  elseif planet[1].name.name == "mixed planet" then
    final_size = base_size * 2
  else
    final_size = base_size / 2
  end
  return final_size
end

local function process_rocky_position(p, seed, tiles, entities, treasure, planet)
  local biters = planet[1].name.biters
  local noise_large_caves = get_noise("large_caves", p, seed)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)

	if math_abs(noise_large_caves) > 0.7 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end
	if math_abs(noise_large_caves) > 0.6 then
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="tree-02", position=p} end
		--if math_random(1,32) == 1 then markets[#markets + 1] = p end
	end
	if math_abs(noise_large_caves) > 0.5 then
		tiles[#tiles + 1] = {name = "grass-2", position = p}
		--if math_random(1,620) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		-- if math_random(1,384) == 1 then
		-- 	Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
		-- 	entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		-- end
    if math_random(1,102 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end
	if math_abs(noise_large_caves) > 0.375 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,6) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end

	--Chasms
	if noise_cave_ponds < 0.25 and noise_cave_ponds > -0.25 then
		if small_caves > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if small_caves > -0.25 and small_caves < 0.25 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
    local roll = math_random(1,1000)
    if roll > 800 then
      entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
    elseif roll > 790 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then
      entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
    else

    end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if noise_large_caves > -0.28 and noise_large_caves < 0.28 then

		--Main Rock Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 40 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		return
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_forest_position(p, seed, tiles, entities, treasure, planet)
  local biters = planet[1].name.biters
	local noise_forest_location = get_noise("forest_location", p, seed)
	--local r = math.ceil(math.abs(get_noise("forest_density", pos, seed + 4096)) * 10)
	--local r = 5 - math.ceil(math.abs(noise_forest_location) * 3)
	--r = 2

	if noise_forest_location > 0.095 then
		if noise_forest_location > 0.6 then
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-08-brown", position = p} end
		else
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-01", position = p} end
		end
		--surface.create_decoratives({check_collision=false, decoratives={{name = decos_inside_forest[math_random(1, #decos_inside_forest)], position = pos, amount = math_random(1, 2)}}})
		return
  else
    if math_random(1,152 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 250 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
  end

	if noise_forest_location < -0.095 then
		if noise_forest_location < -0.6 then
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-04", position = p} end
		else
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-02-red", position = p} end
		end
		--surface.create_decoratives({check_collision=false, decoratives={{name = decos_inside_forest[math_random(1, #decos_inside_forest)], position = pos, amount = math_random(1, 2)}}})
		return
  else
    if math_random(1,152 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 250 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
  end


	--surface.create_decoratives({check_collision=false, decoratives={{name = decos[math_random(1, #decos)], position = pos, amount = math_random(1, 2)}}})
end

local function process_river_position(p, seed, tiles, entities, treasure, planet)
  local biters = planet[1].name.biters
  local richness = math_random(50 + 20 * global.objective.chronojumps, 100 + 20 * global.objective.chronojumps) * planet[1].ore_richness.factor
  local iron_size = get_size_of_ore("iron-ore", planet) * 3
  local copper_size = get_size_of_ore("copper-ore", planet) * 3
  local stone_size = get_size_of_ore("stone", planet) * 3
  local coal_size = get_size_of_ore("coal", planet) * 4
  if not biters then biters = 4 end
  local large_caves = get_noise("large_caves", p, seed)
	local cave_rivers = get_noise("cave_rivers", p, seed)
  local ores = get_noise("ores", p, seed)
  local noise_forest_location = get_noise("forest_location", p, seed)

	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
		if small_caves > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if large_caves > -0.05 and large_caves < 0.05 and cave_rivers < 0.25 then
		tiles[#tiles + 1] = {name = "water-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
  elseif large_caves > -0.20 and large_caves < 0.20 and math_abs(cave_rivers) < 0.95 then
    if ores > -coal_size and ores < coal_size then
      entities[#entities + 1] = {name = "coal", position = p, amount = richness}
    end
	end

	if cave_rivers > -0.70 and cave_rivers < 0.70 then
		if math_random(1,48) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
    if cave_rivers > -0.05 and cave_rivers < 0.05 then
      if ores > -iron_size and ores < iron_size then
        entities[#entities + 1] = {name = "iron-ore", position = p, amount = richness}
      end
    elseif cave_rivers > -0.10 and cave_rivers < 0.10 then
      if ores > -copper_size and ores < copper_size then
        entities[#entities + 1] = {name = "copper-ore", position = p, amount = richness}
      end
    end
	else
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
    if ores > -stone_size and ores < stone_size then
      entities[#entities + 1] = {name = "stone", position = p, amount = richness}
    end
		if math_random(1,52 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 200 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
	end
  if noise_forest_location > 0.9 then
    local tree = tree_raffle[math_random(1, s_tree_raffle)]
		if math_random(1,100) > 42 then entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p} end
		return
  end

	if noise_forest_location < -0.9 then
		if math_random(1,100) > 42 then entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p} end
		return
  end
end

local function process_biter_position(p, seed, tiles, entities, treasure, planet)
  local scrapyard = get_noise("scrapyard", p, seed)
  local noise_forest_location = get_noise("forest_location", p, seed)
  local large_caves = get_noise("large_caves", p, seed)
  local biters = planet[1].name.biters
  local ore_size = planet[1].ore_richness.factor
  local handicap = 0
  if global.objective.chronojumps < 5 then handicap = 150 end
  if scrapyard < -0.75 or scrapyard > 0.75 then

    if math_random(1,52 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 + handicap then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end

  end
  if scrapyard > -0.05 - 0.01 * ore_size and scrapyard < 0.05 + 0.01 * ore_size  then
    if math_random(1,20) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
  end
  if scrapyard + 0.5 > -0.1  - 0.1 * planet[1].name.moisture and scrapyard + 0.5 < 0.1 +  0.1 * planet[1].name.moisture  then
    local treetypes = tree_raffle[math_random(1, s_tree_raffle)]
    if planet[1].name.name == "lava planet" then treetypes = dead_tree_raffle[math_random(1, 5)] end
    if math_random(1,100) > 42 - handicap / 6 then entities[#entities + 1] = {name = treetypes , position = p} end
  end

	if scrapyard > -0.10 and scrapyard < 0.10 then
		if math_floor(large_caves * 10) % 4 < 3 then
      local jumps = global.objective.chronojumps * 5
      if global.objective.chronojumps > 20 then jumps = 100 end
      local roll = math_random(1,200 - jumps - biters)
      if math_sqrt(p.x * p.x + p.y * p.y) > 200 + handicap then
  			if roll == 1 then
          entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p}
        elseif roll == 2 then
          entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
        elseif roll == 3 then
          --if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
        end
			  return
      end
		end
	end
end

local function process_scrapyard_position(p, seed, tiles, entities, treasure, planet)
	local scrapyard = get_noise("scrapyard", p, seed)
  local biters = planet[1].name.biters
	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
  local noise_forest_location = get_noise("forest_location", p, seed)
	if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
		if small_caves > 0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if scrapyard < -0.25 or scrapyard > 0.25 then
		if math_random(1, 256) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 50 then
			entities[#entities + 1] = {name="gun-turret", position=p, force = "scrapyard"}
		end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		 if scrapyard < -0.55 or scrapyard > 0.55 then
		 	if math_random(1,40) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
		 	return
		 end
     if scrapyard + 0.5 > -0.05  - 0.1 * planet[1].name.moisture and scrapyard + 0.5 < 0.05 +  0.1 * planet[1].name.moisture  then
       if math_random(1,100) > 42 then entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p} end
     end
		if scrapyard < -0.28 or scrapyard > 0.28 then
			-- if math_random(1,128) == 1 then
			-- 	Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			-- 	entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
			-- end
			if math_random(1,96) == 1 then entities[#entities + 1] = {name = scrap_entities[math_random(1, scrap_entities_index)], position = p, force = "enemy"} end
			if math_random(1,5) > 1 then entities[#entities + 1] = {name="mineable-wreckage", position=p} end
			return
		end
		return
	end

	local cave_ponds = get_noise("cave_ponds", p, seed)
	if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	local large_caves = get_noise("large_caves", p, seed)
	if scrapyard > -0.15 and scrapyard < 0.15 then
		if math_floor(large_caves * 10) % 4 < 3 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
      local jumps = global.objective.chronojumps * 5
      if global.objective.chronojumps > 20 then jumps = 100 end
			if math_random(1,200 - jumps) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
			return
		end
	end


	--if math_random(1,64) == 1 and cave_ponds > 0.6 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end

	tiles[#tiles + 1] = {name = "stone-path", position = p}
end

local levels = {
	process_level_1_position,
	process_level_2_position,
	process_level_3_position,
	process_rocky_position,
	process_forest_position,
	process_river_position,
	process_biter_position,
	process_scrapyard_position,
	process_level_9_position,
	process_level_10_position,
}

local entity_functions = {
	["turret"] = function(surface, entity) surface.create_entity(entity) end,
	["simple-entity"] = function(surface, entity) surface.create_entity(entity) end,
	["ammo-turret"] = function(surface, entity)
    local e = surface.create_entity(entity)
		e.insert({name = "uranium-rounds-magazine", count = math_random(16, 64)})
	end,
	["container"] = function(surface, entity)
		Treasure(surface, entity.position, entity.name)
	end,
}

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "grass-1"
end

local function replace_water(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if surface.get_tile(p).collides_with("resource-layer") then
				surface.set_tiles({{name = get_replacement_tile(surface, p), position = p}}, true)
			end
		end
	end
end

local function forest_chunk(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
	--local markets = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]
  for y = 0.5, 31.5, 1 do
		for x = 0.5, 31.5, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
  surface.set_tiles(tiles, true)
  for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) then
			local e = surface.create_entity(entity)
      if e.name == "biter-spawner" or e.name == "spitter-spawner" or e.name == "small-worm-turret" or e.name == "medium-worm-turret" or e.name == "big-worm-turret" or e.name == "behemoth-worm-turret" then
        if math_abs(e.position.x) > 420 or math_abs(e.position.y) > 420 then e.destructible = false end
      end
		end
	end
end

local function biter_chunk(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
	--local markets = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]
  for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
  for _, p in pairs(treasure) do
		local name = "wooden-chest"
		if math_random(1, 6) == 1 then name = "iron-chest" end
		Treasure(surface, p, name)
	end
  surface.set_tiles(tiles, true)
  for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) then
			local e = surface.create_entity(entity)
      if e.name == "biter-spawner" or e.name == "spitter-spawner" or e.name == "small-worm-turret" or e.name == "medium-worm-turret" or e.name == "big-worm-turret" or e.name == "behemoth-worm-turret" then
        if math_abs(e.position.x) > 420 or math_abs(e.position.y) > 420 then e.destructible = false end
      end
		end

	end
end

local function empty_chunk(surface, left_top, level, planet)
	local tiles = {}
	local entities = {}
	--local markets = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
	surface.set_tiles(tiles, true)
  replace_water(surface, left_top)
end

local function normal_chunk(surface, left_top, level, planet)
	local tiles = {}
	local entities = {}
	--local markets = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed

	--local level_index = math_floor((math_abs(left_top.y / level_depth)) % 10) + 1
	local process_level = levels[level]

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
	surface.set_tiles(tiles, true)

	-- if #markets > 0 then
	-- 	local position = markets[math_random(1, #markets)]
	-- 	if surface.count_entities_filtered{area = {{position.x - 96, position.y - 96}, {position.x + 96, position.y + 96}}, name = "market", limit = 1} == 0 then
	-- 		local market = Market.mountain_market(surface, position, math_abs(position.y) * 0.004)
	-- 		market.destructible = false
	-- 	end
	-- end

	for _, p in pairs(treasure) do
		local name = "wooden-chest"
		if math_random(1, 6) == 1 then name = "iron-chest" end
		Treasure(surface, p, name)
	end

	for _, entity in pairs(entities) do
		if entity_functions[game.entity_prototypes[entity.name].type] then
			entity_functions[game.entity_prototypes[entity.name].type](surface, entity)
		else
			if surface.can_place_entity(entity) then
				local e = surface.create_entity(entity)
        if e.name == "biter-spawner" or e.name == "spitter-spawner" or e.name == "small-worm-turret" or e.name == "medium-worm-turret" or e.name == "big-worm-turret" or e.name == "behemoth-worm-turret" then
          if math_abs(e.position.x) > 420 or math_abs(e.position.y) > 420 then e.destructible = false end
        end
			end
		end
	end
end

local function process_chunk(surface, left_top)
	if not surface then return end
	if not surface.valid then return end
	if left_top.x >= level_depth * 0.5 or left_top.y >= level_depth * 0.5 then return end
	if left_top.x < level_depth * -0.5 or left_top.y < level_depth * -0.5 then return end


	--if left_top.y >= 0 then replace_water(surface, left_top) end
	--if left_top.y > 32 then game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}}) end
	-- if left_top.y == -128 and left_top.x == -128 then
	-- 	local p = global.locomotive.position
	-- 	for _, entity in pairs(surface.find_entities_filtered({area = {{p.x - 3, p.y - 4},{p.x + 3, p.y + 10}}, type = "simple-entity"})) do	entity.destroy() end
	-- end
  local planet = global.objective.planet
  if planet[1].name.name == "scrapyard" then
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 8, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 8, planet) return end
  elseif planet[1].name.name == "river planet" then
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 6, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 6, planet) return end
  elseif planet[1].name.name == "choppy planet" then
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 5, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then forest_chunk(surface, left_top, 5, planet) return end
  elseif planet[1].name.name == "rocky planet" then
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 4, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 4, planet) return end
  elseif planet[1].name.name == "lava planet" then
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 7, planet) end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then biter_chunk(surface, left_top, 7, planet) end
    replace_water(surface, left_top)
    return
  else
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 7, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then biter_chunk(surface, left_top, 7, planet) return end
  end
	--if left_top.y > 96 then out_of_map(surface, left_top) return end
	--if left_top.y > 64 then biter_chunk(surface, left_top) return end
	--if left_top.y >= 0 then border_chunk(surface, left_top) return end
  --rock_chunk(surface, left_top)
  --return
end

local function on_chunk_generated(event)
	if string.sub(event.surface.name, 0, 12) ~= "chronosphere" then return end
	process_chunk(event.surface, event.area.left_top)
	--global.chunk_queue[#global.chunk_queue + 1] = {left_top = {x = event.area.left_top.x, y = event.area.left_top.y}, surface_index = event.surface.index}
end

local event = require 'utils.event'
--event.on_nth_tick(4, process_chunk_queue)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
