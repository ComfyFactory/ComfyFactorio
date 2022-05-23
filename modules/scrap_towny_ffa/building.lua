local Public = {}

local math_floor = math.floor
local table_insert = table.insert
local table_size = table.size
local Table = require 'modules.scrap_towny_ffa.table'

local town_radius = 27
local connection_radius = 7

local blacklist_entity_types = {
    ['car'] = true,
    ['character'] = true,
    ['combat-robot'] = true,
    ['construction-robot'] = true,
    ['logistic-robot'] = true,
    ['entity-ghost'] = true,
    ['character-corpse'] = true,
    ['corpse'] = true
}
-- these should be allowed to place inside any base by outlanders as neutral
local neutral_whitelist = {
    ['burner-inserter'] = true,
    ['car'] = true,
    ['coin'] = true,
    ['express-loader'] = true,
    ['fast-inserter'] = true,
    ['fast-loader'] = true,
    ['filter-inserter'] = true,
    ['inserter'] = true,
    ['iron-chest'] = true,
    ['loader'] = true,
    ['long-handed-inserter'] = true,
    ['raw-fish'] = true,
    ['stack-filter-inserter'] = true,
    ['stack-inserter'] = true,
    ['steel-chest'] = true,
    ['tank'] = true,
    ['wooden-chest'] = true
}

-- these should be allowed to place outside any base by town players
local team_whitelist = {
    ['burner-inserter'] = true,
    ['car'] = true,
    ['cargo-wagon'] = true,
    ['coin'] = true,
    ['curved-rail'] = true,
    ['electric-pole'] = true,
    ['express-loader'] = true,
    ['fast-inserter'] = true,
    ['fast-loader'] = true,
    ['filter-inserter'] = true,
    ['inserter'] = true,
    ['fluid-wagon'] = true,
    ['iron-chest'] = true,
    ['loader'] = true,
    ['long-handed-inserter'] = true,
    ['locomotive'] = true,
    ['rail'] = true,
    ['rail-chain-signal'] = true,
    ['rail-signal'] = true,
    ['raw-fish'] = true,
    ['stack-filter-inserter'] = true,
    ['stack-inserter'] = true,
    ['steel-chest'] = true,
    ['straight-rail'] = true,
    ['tank'] = true,
    ['train-stop'] = true,
    ['wooden-chest'] = true
}

-- these need to be prototypes
local team_entities = {
    ['accumulator'] = true,
    ['ammo-turret'] = true,
    ['arithmetic-combinator'] = true,
    ['artillery-turret'] = true,
    ['assembling-machine'] = true,
    ['beacon'] = true,
    ['boiler'] = true,
    ['burner-generator'] = true,
    ['constant-combinator'] = true,
    ['container'] = true,
    ['decider-combinator'] = true,
    ['electric-energy-interface'] = true,
    ['electric-pole'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true,
    ['furnace'] = true,
    ['gate'] = true,
    ['generator'] = true,
    ['heat-interface'] = true,
    ['heat-pipe'] = true,
    ['infinity-container'] = true,
    ['infinity-pipe'] = true,
    ['inserter'] = true,
    ['lab'] = true,
    ['lamp'] = true,
    ['land-mine'] = true,
    ['linked-belt'] = true,
    ['linked-container'] = true,
    ['loader'] = true,
    ['loader-1x1'] = true,
    ['logistic-container'] = true,
    ['market'] = true,
    ['mining-drill'] = true,
    ['offshore-pump'] = true,
    ['pipe'] = true,
    ['pipe-to-ground'] = true,
    ['player-port'] = true,
    ['power-switch'] = true,
    ['programmable-speaker'] = true,
    ['pump'] = true,
    ['radar'] = true,
    ['reactor'] = true,
    ['roboport'] = true,
    ['rocket-silo'] = true,
    ['solar-panel'] = true,
    ['splitter'] = true,
    ['storage-tank'] = true,
    ['transport-belt'] = true,
    ['underground-belt'] = true,
    ['wall'] = true
}

local function isolated(surface, force, position)
    local position_x = position.x
    local position_y = position.y
    local area = {{position_x - connection_radius, position_y - connection_radius}, {position_x + connection_radius, position_y + connection_radius}}
    local count = 0

    for _, e in pairs(surface.find_entities_filtered({area = area, force = force.name})) do
        if team_entities[e.type] then
            count = count + 1
            if count > 1 then
                return false
            end -- are there more than one team entities in the area?
        end
    end

    return true
end

local function refund_item(event, item_name)
    if item_name == 'blueprint' then
        return
    end
    if event.player_index ~= nil then
        game.players[event.player_index].insert({name = item_name, count = 1})
        return
    end

    -- return item to robot, but don't replace ghost (otherwise might loop)
    if event.robot ~= nil then
        local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
        inventory.insert({name = item_name, count = 1})
        return
    end
end

local function error_floaty(surface, position, msg)
    surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = msg,
            color = {r = 0.77, g = 0.0, b = 0.0}
        }
    )
end

function Public.in_range(pos1, pos2, radius)
    if pos1 == nil then
        return false
    end
    if pos2 == nil then
        return false
    end
    if radius < 1 then
        return true
    end
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    if dx ^ 2 + dy ^ 2 < radius ^ 2 then
        return true
    end
    return false
end

function Public.in_area(position, area_center, area_radius)
    if position == nil then
        return false
    end
    if area_center == nil then
        return false
    end
    if area_radius < 1 then
        return true
    end
    if position.x >= area_center.x - area_radius and position.x <= area_center.x + area_radius then
        if position.y >= area_center.y - area_radius and position.y <= area_center.y + area_radius then
            return true
        end
    end
    return false
end

-- is the position near another town?
function Public.near_another_town(force_name, position, surface, radius)
    -- check for nearby town centers
    if force_name == nil then
        return false
    end
    local ffatable = Table.get_table()
    local forces = {}
    -- check for nearby town centers
    local fail = false
    if table_size(ffatable.town_centers) > 0 then
        for _, town_center in pairs(ffatable.town_centers) do
            if town_center ~= nil then
                local market = town_center.market
                if market ~= nil and market.valid then
                    local market_force = market.force
                    if market_force ~= nil then
                        if market_force.name ~= nil then
                            table_insert(forces, market_force.name)
                            if force_name ~= market_force.name then
                                if Public.in_range(position, market.position, radius) == true then
                                    fail = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        if fail == true then
            return true
        end
    end
    -- check for nearby town entities
    if table.size(forces) > 0 then
        local entities = surface.find_entities_filtered({position = position, radius = radius, force = forces})
        for _, e in pairs(entities) do
            if e.valid and e.force ~= nil then
                local entity_force_name = e.force.name
                --if force_name ~= force.name and force_name ~= 'enemy' and force_name ~= 'neutral' and force_name ~= 'player' and force_name ~= 'rogue' then
                if entity_force_name ~= nil then
                    if entity_force_name ~= force_name then
                        if blacklist_entity_types[e.type] ~= true then
                            fail = true
                            break
                        end
                    end
                end
            end
        end
        if fail == true then
            return true
        end
    end
    return false
end

local function in_own_town(force, position)
    local ffatable = Table.get_table()
    local town_center = ffatable.town_centers[force.name]
    if town_center ~= nil then
        local market = town_center.market
        if market ~= nil then
            local center = market.position
            if position.x >= center.x - town_radius and position.x <= center.x + town_radius then
                if position.y >= center.y - town_radius and position.y <= center.y + town_radius then
                    return true
                end
            end
        end
    end
    return false
end

function Public.in_restricted_zone(surface, position)
    if surface.name ~= 'nauvis' then
        return false
    end
    local chunk_position = {}
    chunk_position.x = math_floor(position.x / 32)
    chunk_position.y = math_floor(position.y / 32)
    if chunk_position.x <= -33 or chunk_position.x >= 32 or chunk_position.y <= -33 or chunk_position.y >= 32 then
        return true
    end
    return false
end

local function prevent_entity_in_restricted_zone(event)
    local player_index = event.player_index or nil
    local entity = event.created_entity
    if entity == nil or not entity.valid then
        return
    end
    local item = event.item
    local name = entity.name
    local surface = entity.surface
    local position = entity.position
    local error = false
    if Public.in_restricted_zone(surface, position) then
        error = true
        entity.destroy()
        if name ~= 'entity-ghost' and name ~= 'tile-ghost' and item ~= nil then
            if item ~= nil then
                refund_item(event, item.name)
            end
        end
    end
    if error == true then
        if player_index ~= nil then
            local player = game.players[player_index]
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, 'Can not build in restricted zone!')
    end
end

local function prevent_unconnected_town_entities(event)
    local player_index = event.player_index or nil
    local entity = event.created_entity
    if entity == nil or not entity.valid then
        return
    end
    local item = event.item
    local name = entity.name
    local surface = entity.surface
    local position = entity.position
    local force = entity.force
    if force.index == game.forces.player.index or force.index == game.forces['rogue'].index then
        -- no town restrictions if outlander or rogue
        return
    end
    local error = false
    if name ~= 'entity-ghost' then
        if not in_own_town(force, position) and isolated(surface, force, position) and not team_whitelist[name] then
            error = true
            entity.destroy()
            if item ~= nil then
                refund_item(event, item.name)
            end
        end
    end
    if error == true then
        if player_index ~= nil then
            local player = game.players[player_index]
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, 'Building is not connected to your town!')
    end
end

local function prevent_landfill_in_restricted_zone(event)
    local player_index = event.player_index or nil
    local tile = event.tile
    if tile == nil or not tile.valid then
        return
    end
    local item = event.item
    local surface = game.surfaces[event.surface_index]
    local fail = false
    local position
    for _, t in pairs(event.tiles) do
        local old_tile = t.old_tile
        position = t.position
        if Public.in_restricted_zone(surface, position) then
            fail = true
            surface.set_tiles({{name = old_tile.name, position = position}}, true)
            if item ~= nil then
                refund_item(event, item.name)
            end
        end
    end
    if fail == true then
        if player_index ~= nil then
            local player = game.players[player_index]
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, 'Can not build in restricted zone!')
    end
    return fail
end

local function prevent_unconnected_town_tiles(event)
    local player_index = event.player_index or nil
    local tile = event.tile
    if tile == nil or not tile.valid then
        return
    end
    local item = event.item
    local surface = game.surfaces[event.surface_index]
    local tiles = event.tiles
    local force
    if player_index ~= nil then
        force = game.players[player_index].force
    else
        force = event.robot.force
    end
    local fail = false
    local position
    for _, t in pairs(tiles) do
        local old_tile = t.old_tile
        position = t.position
        local name = tile.name
        if name ~= 'tile-ghost' then
            if not in_own_town(force, position) and isolated(surface, force, position) then
                fail = true
                surface.set_tiles({{name = old_tile.name, position = position}}, true)
                if item ~= nil then
                    refund_item(event, item.name)
                end
            end
        end
    end
    if fail == true then
        if player_index ~= nil then
            local player = game.players[player_index]
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, 'Tile is not connected to town!')
    end
end

local function prevent_entities_near_towns(event)
    local player_index = event.player_index or nil
    local entity = event.created_entity
    if entity == nil or not entity.valid then
        return
    end
    local item = event.item
    local name = entity.name
    local surface = entity.surface
    local position = entity.position
    local force_name
    if player_index ~= nil then
        local player = game.players[player_index]
        if player ~= nil then
            local force = player.force
            if force ~= nil then
                force_name = force.name
            end
        end
    else
        local robot = event.robot
        if robot ~= nil then
            local force = robot.force
            if force ~= nil then
                force_name = force.name
            end
        end
    end
    if Public.near_another_town(force_name, position, surface, 32) == true then
        if neutral_whitelist[name] then
            entity.force = game.forces['neutral']
        else
            entity.destroy()
            if player_index ~= nil then
                local player = game.players[player_index]
                player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
            end
            error_floaty(surface, position, "Can't build near town!")
            if name ~= 'entity-ghost' then
                if item ~= nil then
                    refund_item(event, item.name)
                end
            end
            return
        end
    end
end

local function prevent_tiles_near_towns(event)
    local player_index = event.player_index or nil
    local tile = event.tile
    if tile == nil or not tile.valid then
        return
    end
    local item = event.item
    local surface = game.surfaces[event.surface_index]
    local force_name
    if player_index ~= nil then
        local player = game.players[player_index]
        if player ~= nil then
            local force = player.force
            if force ~= nil then
                force_name = force.name
            end
        end
    else
        local robot = event.robot
        if robot ~= nil then
            local force = robot.force
            if force ~= nil then
                force_name = force.name
            end
        end
    end
    local fail = false
    local position
    for _, t in pairs(event.tiles) do
        local old_tile = t.old_tile
        position = t.position
        if Public.near_another_town(force_name, position, surface, 32) == true then
            fail = true
            surface.set_tiles({{name = old_tile.name, position = position}}, true)
            if item ~= nil then
                refund_item(event, item.name)
            end
        end
    end
    if fail == true then
        if player_index ~= nil then
            local player = game.players[player_index]
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, "Can't build near town!")
    end
    return fail
end

local function prevent_neutral_deconstruct(event)
    local index = event.player_index
    local player
    if index then
        player = game.players[index]
    end
    local entity = event.entity
    if entity and entity.valid and entity.to_be_deconstructed() and entity.force.name == 'neutral' then
        for _, f in pairs(game.forces) do
            if f ~= nil and entity.is_registered_for_deconstruction(f) then
                entity.cancel_deconstruction(f, player)
            end
        end
    end
end

-- called when a player places an item, or a ghost
local function on_built_entity(event)
    local player = game.players[event.player_index]
    if prevent_entity_in_restricted_zone(event) then
        return
    end
    if prevent_entities_near_towns(event) then
        return
    end
    if player.force.index ~= game.forces['player'].index and player.force.index ~= game.forces['rogue'].index then
        prevent_unconnected_town_entities(event)
    end
end

local function on_robot_built_entity(event)
    local robot = event.robot
    if prevent_entity_in_restricted_zone(event) then
        return
    end
    if prevent_entities_near_towns(event) then
        return
    end
    if robot.force.index ~= game.forces['player'].index and robot.force.index ~= game.forces['rogue'].index then
        prevent_unconnected_town_entities(event)
    end
end

-- called when a player places landfill
local function on_player_built_tile(event)
    local player = game.players[event.player_index]
    if prevent_landfill_in_restricted_zone(event) then
        return
    end
    if prevent_tiles_near_towns(event) then
        return
    end
    if player.force.index ~= game.forces['player'].index and player.force.index ~= game.forces['rogue'].index then
        prevent_unconnected_town_tiles(event)
    end
end

local function on_robot_built_tile(event)
    local robot = event.robot
    if prevent_landfill_in_restricted_zone(event) then
        return
    end
    if prevent_tiles_near_towns(event) then
        return
    end
    if robot.force.index ~= game.forces['player'].index and robot.force.index ~= game.forces['rogue'].index then
        prevent_unconnected_town_tiles(event)
    end
end

local function on_marked_for_deconstruction(event)
    prevent_neutral_deconstruct(event)
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)

return Public
