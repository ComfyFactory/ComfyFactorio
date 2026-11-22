local FlyingText = require 'utils.functions.flying_texts'

local Public = {}
local LootRaffle = require "utils.functions.loot_raffle"
local Get_noise = require "utils.math.get_noise"

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
    local area = { { position.x - 2, position.y - 2 }, { position.x + 2, position.y + 2 } }
    local characters = surface.find_entities_filtered({ name = "character", area = area })
    for _, character in pairs(characters) do
        if character.player then
            local player = character.player
            local p = surface.find_non_colliding_position('character', player.position, 32, 0.5)
            if p then
                player.teleport(p, surface)
            end
        end
    end
end

function Public.kaboom(position)
    local surface = game.surfaces[1]
    local count = surface.count_entities_filtered({ name = { "atomic-bomb-ground-zero-projectile", "atomic-bomb-wave", "atomic-bomb-wave-spawns-cluster-nuke-explosion", "atomic-bomb-wave-spawns-fire-smoke-explosion", "atomic-bomb-wave-spawns-nuclear-smoke", "atomic-bomb-wave-spawns-nuke-shockwave-explosion", "atomic-rocket" }, area = { { position.x - 4, position.y - 4 }, { position.x + 4, position.y + 4 } }, limit = 1 })
    if count > 0 then return end

    local center = { x = position.x + 1, y = position.y + 1 }
    local area = { { center.x - 13, center.y - 13 }, { center.x + 13, center.y + 13 } }
    local terrain = {}
    for _, tile in pairs(surface.find_tiles_filtered({ area = area })) do
        if tile.name ~= 'nuclear-ground' and tile.name ~= 'out-of-map' then
            terrain[#terrain + 1] = { name = tile.name, position = tile.position, hidden = tile.hidden_tile, double_hidden = tile.double_hidden_tile }
        end
    end
    local projectile = surface.create_entity({ name = 'atomic-rocket', position = center, target = center, speed = 1, force = 'minesweeper' })
    if projectile then
        return { projectile = projectile, terrain = terrain }
    end
end

function Public.restore_blast_terrain(terrain)
    local surface = game.surfaces[1]
    local tiles = {}
    for _, tile in ipairs(terrain) do
        if surface.get_tile(tile.position).name == 'nuclear-ground' then
            tiles[#tiles + 1] = tile
        end
    end
    if #tiles > 0 then
        surface.set_tiles(tiles, true, false, false)
        for _, tile in ipairs(tiles) do
            surface.set_hidden_tile(tile.position, tile.hidden)
            surface.set_double_hidden_tile(tile.position, tile.double_hidden)
        end
    end
end

local function has_minefield_tile(position, extent, paved_only)
    local surface = game.surfaces[1]
    for x = 0, extent do
        for y = 0, extent do
            local tile = surface.get_tile(position.x + x, position.y + y)
            if tile.hidden_tile == 'nuclear-ground' or (not paved_only and tile.name == 'nuclear-ground') then
                return true
            end
        end
    end
    return false
end

function Public.is_minefield_tile(position, search_cell)
    return has_minefield_tile(position, search_cell and 1 or 0, false)
end

function Public.has_paved_minefield_tile(position)
    return has_minefield_tile(position, 1, true)
end

function Public.is_spawn(position)
    if math.abs(position.x) > safe_zone_radius then return false end
    if math.abs(position.y) > safe_zone_radius then return false end
    local p = { x = position.x, y = position.y }
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
    if Public.is_spawn(position) then return 'black-refined-concrete' end

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

    FlyingText.flying_text(nil, surface, { x = position.x + 1, y = position.y + 1 }, 'Mine disarmed!', { r = 0.98, g = 0.66, b = 0.22 })

    local tile_name = Public.get_terrain_tile(surface, position)

    if math.random(1, 3) ~= 1 or tile_name == "water-shallow" then return end

    if math.random(1, 8) == 1 then
        local blacklist = LootRaffle.get_tech_blacklist(0.05 + distance_to_center * 0.00025)
        local item_stacks = LootRaffle.roll(math.random(16, 48) + math.floor(distance_to_center * 0.2), 16, blacklist)
        local p = { x = position.x + math.random(0, 1), y = position.y + math.random(0, 1) }
        local container = surface.create_entity({ name = "crash-site-chest-" .. math.random(1, 2), position = p, force = "neutral" })
        if container then
            for _, item_stack in pairs(item_stacks or {}) do
                if prototypes.item[item_stack.name] then
                    container.insert(item_stack)
                end
            end
            container.minable_flag = false
            unstuck_players_around_position(surface, p)
            return
        end
    end

    local ore
    if string.find(tile_name, "grass", 1, true) then
        ore = ores[1][math.random(1, #ores[1])]
    else
        ore = ores[2][math.random(1, #ores[2])]
    end

    if ore == "crude-oil" then
        surface.create_entity({ name = "crude-oil", position = { position.x + 1, position.y + 1 }, amount = 301000 + distance_to_center * 600 })
        return
    end

    for x = 0, 1, 1 do
        for y = 0, 1, 1 do
            local p = { x = position.x + x, y = position.y + y }
            if Public.get_terrain_tile(surface, p) ~= "water-shallow" then
                surface.create_entity({ name = ore, position = p, amount = 1000 + distance_to_center * 3 })
            end
        end
    end
end

function Public.uncover_terrain(position)
    local surface = game.surfaces[1]
    local uncovered_water = false
    for x = 0, 1, 1 do
        for y = 0, 1, 1 do
            local p = { x = position.x + x, y = position.y + y }
            local tile = surface.get_tile(p)
            if tile.name == 'nuclear-ground' or tile.hidden_tile == 'nuclear-ground' then
                local tile_name = Public.get_terrain_tile(surface, p)
                if tile.hidden_tile == 'nuclear-ground' and tile_name ~= 'water-shallow' then
                    surface.set_hidden_tile(p, tile_name)
                else
                    surface.set_hidden_tile(p, nil)
                    surface.set_tiles({ { name = tile_name, position = p } }, true)
                end
                if tile_name == 'water-shallow' then
                    uncovered_water = true
                    if math.random(1, 16) == 1 then
                        surface.create_entity({ name = 'fish', position = p })
                    end
                end
            end
        end
    end
    if uncovered_water then
        unstuck_players_around_position(surface, { x = position.x + 1, y = position.y + 1 })
    end
end

return Public
