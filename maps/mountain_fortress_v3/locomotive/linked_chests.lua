local Event = require 'utils.event'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WPT = require 'maps.mountain_fortress_v3.table'

local Public = {}

local function contains_positions(area)
    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    local wagons = ICW.get_table('wagons')
    for _, wagon in pairs(wagons) do
        if wagon.entity and wagon.entity.valid then
            if wagon.entity.name == 'cargo-wagon' then
                if inside(wagon.entity.position, area) then
                    return true, wagon.entity
                end
            end
        end
    end
    return false, nil
end

local function on_built_entity(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    if entity.name ~= 'steel-chest' then
        return
    end

    local map_name = 'mtn_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local area = {
        left_top = {x = entity.position.x - 3, y = entity.position.y - 3},
        right_bottom = {x = entity.position.x + 3, y = entity.position.y + 3}
    }

    local success, train = contains_positions(area)

    if not success then
        return
    end

    local outside_chests = WPT.get('outside_chests')
    local chests_linked_to = WPT.get('chests_linked_to')
    local chest_limit_outside_upgrades = WPT.get('chest_limit_outside_upgrades')
    local chest_created
    local increased = false

    for k, data in pairs(outside_chests) do
        if data and data.chest and data.chest.valid then
            if chests_linked_to[train.unit_number] then
                local linked_to = chests_linked_to[train.unit_number].count
                if linked_to == chest_limit_outside_upgrades then
                    return
                end
                outside_chests[entity.unit_number] = {chest = entity, position = entity.position, linked = train.unit_number}

                if not increased then
                    chests_linked_to[train.unit_number].count = linked_to + 1
                    chests_linked_to[train.unit_number][entity.unit_number] = true
                    increased = true

                    goto continue
                end
            else
                outside_chests[entity.unit_number] = {chest = entity, position = entity.position, linked = train.unit_number}
                chests_linked_to[train.unit_number] = {count = 1}
            end

            ::continue::
            rendering.draw_text {
                text = '♠',
                surface = entity.surface,
                target = entity,
                target_offset = {0, -0.6},
                scale = 2,
                color = {r = 0, g = 0.6, b = 1},
                alignment = 'center'
            }
            chest_created = true
        end
    end

    if chest_created then
        return
    end

    if next(outside_chests) == nil then
        outside_chests[entity.unit_number] = {chest = entity, position = entity.position, linked = train.unit_number}
        chests_linked_to[train.unit_number] = {count = 1}
        chests_linked_to[train.unit_number][entity.unit_number] = true

        rendering.draw_text {
            text = '♠',
            surface = entity.surface,
            target = entity,
            target_offset = {0, -0.6},
            scale = 2,
            color = {r = 0, g = 0.6, b = 1},
            alignment = 'center'
        }
        return
    end
end

local function on_player_and_robot_mined_entity(event)
    local entity = event.entity

    if not entity.valid then
        return
    end

    local outside_chests = WPT.get('outside_chests')
    local chests_linked_to = WPT.get('chests_linked_to')

    if outside_chests[entity.unit_number] then
        for k, data in pairs(chests_linked_to) do
            if data[entity.unit_number] then
                data.count = data.count - 1
                if data.count <= 0 then
                    chests_linked_to[k] = nil
                end
            end
            if chests_linked_to[k] and chests_linked_to[k][entity.unit_number] then
                chests_linked_to[k][entity.unit_number] = nil
            end
        end
        outside_chests[entity.unit_number] = nil
    end
end

local function divide_contents()
    local outside_chests = WPT.get('outside_chests')
    local chests_linked_to = WPT.get('chests_linked_to')
    local target_chest

    if not next(outside_chests) then
        goto final
    end

    for key, data in pairs(outside_chests) do
        local chest = data.chest
        local area = {
            left_top = {x = data.position.x - 4, y = data.position.y - 4},
            right_bottom = {x = data.position.x + 4, y = data.position.y + 4}
        }
        if not (chest and chest.valid) then
            if chests_linked_to[data.linked] then
                if chests_linked_to[data.linked][key] then
                    chests_linked_to[data.linked][key] = nil
                    chests_linked_to[data.linked].count = chests_linked_to[data.linked].count - 1
                    if chests_linked_to[data.linked].count <= 0 then
                        chests_linked_to[data.linked] = nil
                    end
                end
            end
            outside_chests[key] = nil
            goto continue
        end

        local success, entity = contains_positions(area)
        if success then
            target_chest = entity
        else
            if chests_linked_to[data.linked] then
                if chests_linked_to[data.linked][key] then
                    chests_linked_to[data.linked][key] = nil
                    chests_linked_to[data.linked].count = chests_linked_to[data.linked].count - 1
                    if chests_linked_to[data.linked].count <= 0 then
                        chests_linked_to[data.linked] = nil
                    end
                end
            end
            goto continue
        end

        local chest1 = chest.get_inventory(defines.inventory.chest)
        local chest2 = target_chest.get_inventory(defines.inventory.cargo_wagon)

        for item, count in pairs(chest1.get_contents()) do
            local t = {name = item, count = count}
            local c = chest2.insert(t)
            if (c > 0) then
                chest1.remove({name = item, count = c})
            end
        end
        ::continue::
    end
    ::final::
end

local function tick()
    local ticker = game.tick

    if ticker % 30 == 0 then
        divide_contents()
    end
end

Event.on_nth_tick(5, tick)

Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_player_and_robot_mined_entity)
Event.add(defines.events.on_pre_player_mined_item, on_player_and_robot_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_player_and_robot_mined_entity)

return Public
