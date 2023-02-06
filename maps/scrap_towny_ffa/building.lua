local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local Public = {}

local math_floor = math.floor
local table_insert = table.insert
local table_size = table.size

local town_zoning_entity_types = {'wall', 'gate', 'electric-pole', 'ammo-turret', 'electric-turret', 'fluid-turret'}

-- these should be allowed to place inside any base by anyone as neutral
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
    ['wooden-chest'] = true,
    ['transport-belt'] = true,
    ['fast-transport-belt'] = true,
    ['express-transport-belt'] = true,
    ['underground-belt'] = true,
    ['fast-underground-belt'] = true,
    ['express-underground-belt'] = true,
    ['splitter'] = true,
    ['fast-splitter'] = true,
    ['express-splitter'] = true
}

local function refund_item(event, item_name)
    if item_name == 'blueprint' then
        return
    end

    if event.player_index then
        local player = game.get_player(event.player_index)
        if player and player.valid then
            player.insert({name = item_name, count = 1})
            return
        end
    end

    -- return item to robot, but don't replace ghost (otherwise might loop)
    local robot = event.robot
    if robot and robot.valid then
        local inventory = robot.get_inventory(defines.inventory.robot_cargo)
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

function Public.is_another_character_near(surface, position, force)
    if not surface then
        return
    end
    if not position then
        return
    end
    if not force then
        return
    end

    local ents = surface.find_entities_filtered {position = position, radius = 15, type = 'character'}
    if ents and #ents >= 1 then
        for _, ent in pairs(ents) do
            if ent and ent.valid then
                if ent.force.name ~= force.name and not ent.force.get_friend(force.name) and not force.get_friend(ent.force.name) then
                    return true
                end
            end
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
    local this = ScenarioTable.get_table()
    local forces = {}
    -- check for nearby town centers
    local fail = false
    if table_size(this.town_centers) > 0 then
        for _, town_center in pairs(this.town_centers) do
            if town_center ~= nil then
                local market = town_center.market
                if market ~= nil and market.valid then
                    local market_force = market.force
                    if market_force ~= nil then
                        if market_force.name ~= nil then
                            if force_name ~= market_force.name then
                                table_insert(forces, market_force.name)
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
        if
            surface.count_entities_filtered(
                {
                    position = position,
                    radius = radius,
                    force = forces,
                    type = town_zoning_entity_types,
                    limit = 1
                }
            ) > 0
         then
            return true
        end
    end
    return false
end

function Public.in_restricted_zone(surface, position)
    local this = ScenarioTable.get_table()
    local map_surface = game.get_surface(this.active_surface_index)
    if not map_surface or not map_surface.valid then
        return
    end

    if surface.name ~= map_surface.name then
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
    local name = entity.name
    local surface = entity.surface
    local position = entity.position
    local error = false
    if Public.in_restricted_zone(surface, position) then
        error = true
        entity.destroy()
        local item = event.item
        if name ~= 'entity-ghost' and name ~= 'tile-ghost' and item ~= nil then
            refund_item(event, item.name)
        end
    end
    if error == true then
        if player_index ~= nil then
            local player = game.get_player(player_index)
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, 'Can not build in restricted zone!')
    end
end

local function prevent_landfill_in_restricted_zone(event)
    local player_index = event.player_index or nil
    local tile = event.tile
    if tile == nil or not tile.valid then
        return
    end
    local this = ScenarioTable.get_table()
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    local fail = false
    local position
    for _, t in pairs(event.tiles) do
        local old_tile = t.old_tile
        position = t.position
        if Public.in_restricted_zone(surface, position) then
            fail = true
            surface.set_tiles({{name = old_tile.name, position = position}}, true)
        end
    end
    if fail == true then
        if player_index ~= nil then
            local player = game.get_player(player_index)
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, 'Can not build in restricted zone!')
    end
    return fail
end

local function process_built_entities(event)
    local player_index = event.player_index
    local entity = event.created_entity
    if entity == nil or not entity.valid then
        return
    end
    local name = entity.name
    local surface = entity.surface
    local position = entity.position
    local force
    local force_name
    if player_index ~= nil then
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        force = player.force
        force_name = force.name

        local is_another_character_near = Public.is_another_character_near(player.surface, player.position, force)
        if is_another_character_near then
            entity.destroy()

            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
            error_floaty(surface, position, "Can't build near other characters!")
            if name ~= 'entity-ghost' then
                if event.stack and event.stack.valid_for_read then
                    refund_item(event, event.stack.name)
                end
            end
            return
        end
    else
        local robot = event.robot
        force = robot.force
        force_name = force.name

        local is_another_character_near = Public.is_another_character_near(robot.surface, robot.position, robot.force)
        if is_another_character_near then
            entity.destroy()
            error_floaty(surface, position, "Can't build near other characters!")
            if name ~= 'entity-ghost' then
                if event.stack and event.stack.valid_for_read then
                    refund_item(event, event.stack.name)
                end
            end
            return
        end
    end

    if Public.near_another_town(force_name, position, surface, 32) == true then
        if neutral_whitelist[name] then
            entity.force = game.forces['neutral']
        else
            entity.destroy()
            if player_index then
                local player = game.get_player(player_index)
                if not player or not player.valid then
                    return
                end

                player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
            end
            error_floaty(surface, position, "Can't build near town!")
            if name ~= 'entity-ghost' then
                if event.stack and event.stack.valid_for_read then
                    refund_item(event, event.stack.name)
                end
            end
            return
        end
    end

    if force_name == 'player' or force_name == 'rogue' then
        entity.force = game.forces['neutral']
    end
end

local function prevent_tiles_near_towns(event)
    local player_index = event.player_index or nil
    local tile = event.tile
    if tile == nil or not tile.valid then
        return
    end
    local this = ScenarioTable.get_table()
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    local force_name
    if player_index ~= nil then
        local player = game.get_player(player_index)
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
        end
    end
    if fail == true then
        if player_index ~= nil then
            local player = game.get_player(player_index)
            player.play_sound({path = 'utility/cannot_build', position = player.position, volume_modifier = 0.75})
        end
        error_floaty(surface, position, "Can't build near town!")
    end
    return fail
end

-- called when a player places an item, or a ghost
local function on_built_entity(event)
    if prevent_entity_in_restricted_zone(event) then
        return
    end
    if process_built_entities(event) then
        return
    end
end

local function on_robot_built_entity(event)
    if prevent_entity_in_restricted_zone(event) then
        return
    end
    if process_built_entities(event) then
        return
    end
end

-- called when a player places landfill
local function on_player_built_tile(event)
    if prevent_landfill_in_restricted_zone(event) then
        return
    end
    if process_built_entities(event) then
        return
    end
    if prevent_tiles_near_towns(event) then
        return
    end
end

local function on_robot_built_tile(event)
    if prevent_landfill_in_restricted_zone(event) then
        return
    end
    if prevent_tiles_near_towns(event) then
        return
    end
end

Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)

return Public
