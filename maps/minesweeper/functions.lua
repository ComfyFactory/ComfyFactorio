--luacheck: ignore

local Public = {}
local LootRaffle = require "utils.functions.loot_raffle"
local Get_noise = require "utils.get_noise"

local safe_zone_radius = 16

local ores = {}
ores[1] = {}
ores[2] = {}
for _ = 1, 15, 1 do table.insert(ores[1], "iron-ore") end
for _ = 1, 9, 1 do table.insert(ores[1], "coal") end
for _ = 1, 1, 1 do table.insert(ores[1], "crude-oil") end
for _ = 1, 6, 1 do table.insert(ores[2], "copper-ore") end
for _ = 1, 4, 1 do table.insert(ores[2], "stone") end
for _ = 1, 1, 1 do table.insert(ores[2], "uranium-ore") end

local function unstuck_players_around_position(surface, position)
	local area = {{position.x - 2, position.y - 2}, {position.x + 2, position.y + 2}}
	local characters = surface.find_entities_filtered({name = "character", area = area})
	for _, character in pairs(characters) do
		if character.player then
			local player = character.player
			local p = surface.find_non_colliding_position('character', player.position, 32, 0.5)
			if not p then
				return
			end
			player.teleport(p, surface)
		end
	end
end

function Public.kaboom(position)
	local surface = game.surfaces[1]
	local count = surface.count_entities_filtered({name = {"atomic-bomb-ground-zero-projectile", "atomic-bomb-wave", "atomic-bomb-wave-spawns-cluster-nuke-explosion", "atomic-bomb-wave-spawns-fire-smoke-explosion","atomic-bomb-wave-spawns-nuclear-smoke", "atomic-bomb-wave-spawns-nuke-shockwave-explosion", "atomic-rocket"}, area = {{position.x - 4, position.y - 4}, {position.x + 4, position.y + 4}}, limit = 1})
	if count > 0 then return end
	surface.create_entity({name = "atomic-rocket", position = {position.x + 1, position.y + 1}, target = {position.x + 1, position.y + 1}, speed = 1, force = "minesweeper"})
end

function Public.is_minefield_tile(position, search_cell)
	local surface = game.surfaces.nauvis
	if search_cell then
		for x = 0, 1, 1 do
			for y = 0, 1, 1 do
				local p = {x = position.x + x, y = position.y + y}
				local tile = surface.get_tile(p)
				if tile.name == "nuclear-ground" then return true end
				if tile.hidden_tile == "nuclear-ground" then return true end
			end
		end
		return
	end

	local tile = surface.get_tile(position)
	if tile.name == "nuclear-ground" then return true end
	if tile.hidden_tile == "nuclear-ground" then return true end
end

function Public.is_spawn(position)
	if math.abs(position.x) > safe_zone_radius then return false end
	if math.abs(position.y) > safe_zone_radius then return false end
	local p = {x = position.x, y = position.y}
	if p.x > 0 then p.x = p.x + 1 end
	if p.y > 0 then p.y = p.y + 1 end
	local d = math.sqrt(p.x ^ 2 + p.y ^ 2)
	if d < safe_zone_radius then
		return true
	end
end

function Public.position_to_string(p)
	return p.x .. "_" .. p.y
end

function Public.position_to_cell_position(p)
	local cell_position = {}
	cell_position.x = math.floor(p.x * 0.5) * 2
	cell_position.y = math.floor(p.y * 0.5) * 2
	return cell_position
end

function Public.get_terrain_tile(surface, position)
	if Public.is_spawn(position) then	return 'black-refined-concrete' end

	local seed = surface.map_gen_settings.seed

	local noise_1 = Get_noise("smol_areas", position, seed)
	local noise_2 = Get_noise("cave_rivers", position, seed)

	local a = 0.08
	if math.floor((noise_1 * 8) % 5) ~= 0 then
		if math.abs(noise_2) < a then
			return "water-shallow"
		end
	end

	if noise_2 > 0 then return "sand-" .. math.floor((noise_2 * 10) % 3 + 1) end
	return "grass-" .. math.floor((noise_2 * 10) % 3 + 1)
end

function Public.disarm_reward(position)
	local surface = game.surfaces[1]
	local distance_to_center = math.sqrt(position.x ^ 2 + position.y ^ 2)

	surface.create_entity({
		name = "flying-text",
		position = {position.x + 1, position.y + 1},
		text = "Mine disarmed!",
		color = {r=0.98, g=0.66, b=0.22}
	})

	local tile_name = Public.get_terrain_tile(surface, position)

	if math.random(1, 3) ~= 1 or tile_name == "water-shallow" then return end

	if math.random(1, 8) == 1 then
		local blacklist = LootRaffle.get_tech_blacklist(0.05 + distance_to_center * 0.00025)	--max loot tier at ~4000 tiles
		local item_stacks = LootRaffle.roll(math.random(16, 48) + math.floor(distance_to_center * 0.2), 16, blacklist)
		local p = {x = position.x + math.random(0, 1), y = position.y + math.random(0, 1)}
		local container = surface.create_entity({name = "crash-site-chest-" .. math.random(1, 2), position = p, force = "neutral"})
		for _, item_stack in pairs(item_stacks) do container.insert(item_stack) end
		container.minable = false
		unstuck_players_around_position(surface, p)
		return
	end

	local a, b = string.find(tile_name, "grass", 1, true)
	local ore
	if a then
		ore = ores[1][math.random(1, #ores[1])]
	else
		ore = ores[2][math.random(1, #ores[2])]
	end

	if ore == "crude-oil" then
		surface.create_entity({name = "crude-oil", position = {position.x + 1, position.y + 1}, amount = 301000 + distance_to_center * 600})
		return
	end

	for x = 0, 1, 1 do
		for y = 0, 1, 1 do
			local p = {x = position.x + x, y = position.y + y}
			local tile_name = Public.get_terrain_tile(surface, p)
			if tile_name ~= "water-shallow" then
				surface.create_entity({name = ore, position = p, amount = 1000 + distance_to_center * 3})
			end
		end
	end
end

function Public.uncover_terrain(position)
	local surface = game.surfaces[1]
	for x = 0, 1, 1 do
		for y = 0, 1, 1 do
			local p = {x = position.x + x, y = position.y + y}
			local tile_name = Public.get_terrain_tile(surface, p)
			local tile = surface.get_tile(p)
			local mineable_tile_name = false
			if tile.prototype.mineable_properties.minable then	mineable_tile_name = tile.name end

			surface.set_hidden_tile(p, nil)
			surface.set_tiles({{name = tile_name, position = p}}, true)
			if math.random(1, 16) == 1 and tile_name == "water-shallow" then
				surface.create_entity({name = "fish", position = p})
			end

			if mineable_tile_name and tile_name ~= "water-shallow" then surface.set_tiles({{name = mineable_tile_name, position = p}}, true) end
		end
	end
end

return Public
