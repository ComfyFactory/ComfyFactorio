local Color = require 'utils.color_presets'
local Alert = require 'utils.alert'
local Task = require 'utils.task_token'
local Core = require 'utils.core'
local JailData = require 'utils.datastore.jail_data'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local WPT = require 'maps.mountain_fortress_v3.table'
local RPG = require 'modules.rpg.main'
local OfflinePlayers = require 'modules.clear_vacant_players'
local Event = require 'utils.event'
local Server = require 'utils.server'

local Public = {}
local main_tile_name = 'black-refined-concrete'
local round = math.round
local floor = math.floor
local module_tag = '[color=blue]Comfylatron:[/color] '

local is_modded = script.active_mods['MtnFortressAddons'] or false

local out_of_map_tile = 'out-of-map'
if is_modded then
    out_of_map_tile = 'void-tile'
end

local messages = {
    ' vehicle was nibbled to death.',
    ' vehicle should not have played with the biters.',
    ' vehicle is biter scrap.',
    ' vehicle learned the hard way not to mess with biters.',
    ' vehicle lost the battle to a hungry biter.',
    ' vehicle was a tasty biter treat.',
    ' vehicle lost their flux capacitator.',
    ' vehicle met a squishy end.'
}

local function validate_entity(entity)
    if not entity or not entity.valid then
        return false
    end

    return true
end

---Returns the car from the unit_number.
---@param unit_number any
---@return table|boolean
local function get_car_by_unit_number(unit_number)
    local cars = IC.get('cars')
    return cars[unit_number]
end

---Returns the car from the matching surface.
---@param surface_index any
---@return boolean
local function get_car_by_surface(surface_index)
    local cars = IC.get('cars')
    for _, car in pairs(cars) do
        if car.surface == surface_index then
            return true
        end
    end
    return false
end

local function log_err(err)
    local debug_mode = IC.get('debug_mode')
    if debug_mode then
        if type(err) == 'string' then
            log('IC: ' .. err)
        end
    end
end

local enable_car_to_be_mined =
    Task.register(
        function (event)
            local entity = event.entity
            local owner_name = event.owner_name
            if entity and entity.valid then
                entity.minable_flag = true
                local msg = owner_name .. "'s vehicle is now minable!"
                local p = {
                    position = entity.position
                }
                Alert.alert_all_players_location(p, msg, nil, 30)
            end
        end
    )

local function get_trusted_system(player)
    local trust_system = IC.get('trust_system')
    if not trust_system[player.name] then
        trust_system[player.name] = {
            players = {
                [player.name] = { trusted = true, drive = true }
            },
            allow_anyone = 'left',
            auto_upgrade = 'left',
            notify_on_driver_change = 'left'
        }
    end

    return trust_system[player.name]
end

local function does_player_table_exist(player)
    local trust_system = IC.get('trust_system')
    if not trust_system[player.name] then
        return false
    else
        return true
    end
end

local function upperCase(str)
    return (str:gsub('^%l', string.upper))
end

local function render_owner_text(renders, player, entity, new_owner)
    local color = {
        r = player.color.r * 0.6 + 0.25,
        g = player.color.g * 0.6 + 0.25,
        b = player.color.b * 0.6 + 0.25,
        a = 1
    }
    if renders[player.name] and renders[player.name].valid then
        renders[player.name].destroy()
    end

    local ce_name = entity.name

    if ce_name == 'kr-advanced-tank' then
        ce_name = 'Tank'
    end

    if new_owner then
        renders[new_owner.name] =
            rendering.draw_text {
                text = '## - ' .. new_owner.name .. "'s " .. ce_name .. ' - ##',
                surface = entity.surface,
                target = { entity = entity, offset = { 0, -2.6 } },
                color = color,
                scale = 1.05,
                font = 'default-large-semibold',
                alignment = 'center',
                scale_with_zoom = false
            }
    else
        renders[player.name] =
            rendering.draw_text {
                text = '## - ' .. player.name .. "'s " .. ce_name .. ' - ##',
                surface = entity.surface,
                target = { entity = entity, offset = { 0, -2.6 } },
                color = color,
                scale = 1.05,
                font = 'default-large-semibold',
                alignment = 'center',
                scale_with_zoom = false
            }
    end
    entity.color = color
end

local function kill_doors(car)
    if not validate_entity(car.entity) then
        return
    end
    local doors = IC.get('doors')
    for k, e in pairs(car.doors) do
        if validate_entity(e) then
            doors[e.unit_number] = nil
            e.destroy()
            car.doors[k] = nil
        end
    end
end


---Returns the car object of the player.
---@param player any
---@return table|boolean
local function get_owner_car_object(player)
    local cars = IC.get('cars')
    for _, car in pairs(cars) do
        if car.owner == player.name then
            return car
        end
    end
    return false
end

local function get_entity_from_player_surface(cars, player)
    for _, car in pairs(cars) do
        if validate_entity(car.entity) then
            local surface_index = car.surface
            local surface = game.surfaces[surface_index]
            if validate_entity(surface) then
                if car.surface == player.physical_surface.index then
                    return car.entity
                end
            end
        end
    end
    return false
end

local function get_owner_car_surface(cars, player, target)
    for _, car in pairs(cars) do
        if car.owner == player.name then
            local surface_index = car.surface
            local surface = game.surfaces[surface_index]
            if validate_entity(surface) then
                if car.surface == target.surface.index then
                    return true
                else
                    return false
                end
            else
                return false
            end
        end
    end
    return false
end

local function get_player_surface(player)
    local surfaces = IC.get('surfaces')
    for _, index in pairs(surfaces) do
        local surface = game.surfaces[index]
        if validate_entity(surface) then
            if surface.index == player.physical_surface.index then
                return true
            end
        end
    end
    return false
end

local function get_player_entity(player)
    local cars = IC.get('cars')
    for _, car in pairs(cars) do
        if car.owner == player.name and car.saved then
            return car, true
        elseif car.owner == player.name then
            return car, false
        end
    end
    return false, false
end

local function get_owner_car_name(player)
    local cars = IC.get('cars')
    local saved_surfaces = IC.get('saved_surfaces')
    local index = saved_surfaces[player.name]
    for _, car in pairs(cars) do
        if not index then
            return false
        end
        if car.owner == player.name then
            return car.name
        end
    end
    return false
end

local function get_saved_entity(entity, index)
    if index and index.name ~= entity.name then
        local msg =
            table.concat(
                {
                    'The built entity is not the same as the saved one. ',
                    'Saved entity is: ' .. upperCase(index.name) .. ' - Built entity is: ' .. upperCase(entity.name) .. '. '
                }
            )
        return false, msg
    end
    return true
end

local function replace_entity(cars, entity, index)
    local upgrades = WPT.get('upgrades')
    local unit_number = entity.unit_number
    local health = floor(2000 * entity.health * 0.002)
    for k, car in pairs(cars) do
        if car.saved_entity == index.saved_entity then
            local c = car
            cars[unit_number] = c
            cars[unit_number].entity = entity
            cars[unit_number].saved_entity = nil
            cars[unit_number].saved = false
            cars[unit_number].transfer_entities = car.transfer_entities
            cars[unit_number].health_pool = {
                enabled = upgrades.has_upgraded_health_pool or false,
                health = health,
                max = health
            }
            cars[k] = nil
        end
    end
end

local function replace_doors(doors, entity, index)
    if not validate_entity(entity) then
        return
    end
    for k, door in pairs(doors) do
        local unit_number = entity.unit_number
        if index.saved_entity == door then
            doors[k] = unit_number
        end
    end
end

local function replace_surface(surfaces, entity, index)
    if not validate_entity(entity) then
        return
    end
    for car_to_surface_index, surface_index in pairs(surfaces) do
        local surface = game.surfaces[surface_index]
        local unit_number = entity.unit_number
        if validate_entity(surface) then
            if tostring(index.saved_entity) == surface.name then
                local car = get_car_by_unit_number(unit_number)
                surface.name = car.surface_name
                surfaces[unit_number] = surface.index
                surfaces[car_to_surface_index] = nil
            end
        end
    end
end

local function replace_surface_entity(cars, entity, index)
    if not validate_entity(entity) then
        return
    end
    for _, car in pairs(cars) do
        if index and index.saved_entity == car.saved_entity then
            local surface_index = car.surface
            local surface = game.surfaces[surface_index]
            if validate_entity(surface) then
                surface.name = car.surface_name
            end
        end
    end
end

local function remove_logistics(car)
    local chests = car.transfer_entities
    for k, chest in pairs(chests) do
        car.transfer_entities[k] = nil
        chest.destroy()
    end
end

local function set_new_area(car)
    local car_areas = IC.get('car_areas')
    local new_area = car_areas
    local name = car.name
    local apply_area = new_area[name]
    car.area = apply_area
end

local function upgrade_surface(player, entity)
    local ce = entity
    local saved_surfaces = IC.get('saved_surfaces')
    local cars = IC.get('cars')
    local doors = IC.get('doors')
    local surfaces = IC.get('surfaces')
    local index = saved_surfaces[player.name]
    if not index then
        return
    end

    if saved_surfaces[player.name] then
        local car = get_owner_car_object(player)
        if ce.name == 'spidertron' then
            car.name = 'spidertron'
        elseif ce.name == 'tank' then
            car.name = 'tank'
        end
        set_new_area(car)
        remove_logistics(car)
        replace_entity(cars, ce, index)
        replace_doors(doors, ce, index)
        replace_surface(surfaces, ce, index)
        replace_surface_entity(cars, ce, index)
        kill_doors(car)
        Public.create_car_room(car)
        saved_surfaces[player.name] = nil
        return true
    end
    return false
end

local function save_surface(entity, player)
    local cars = IC.get('cars')
    local saved_surfaces = IC.get('saved_surfaces')
    local car = cars[entity.unit_number]

    car.entity = nil
    car.saved = true
    car.saved_entity = entity.unit_number

    saved_surfaces[player.name] = { saved_entity = entity.unit_number, name = entity.name }
end

local function kick_players_out_of_vehicles(car)
    for _, player in pairs(game.connected_players) do
        local character = player.character
        if validate_entity(character) and character.driving then
            if car.surface == player.physical_surface.index then
                character.driving = false
            end
        end
    end
end

local function exclude_surface(surface)
    for _, force in pairs(game.forces) do
        force.set_surface_hidden(surface, true)
    end
end

---Kicks players out of the car surface.
---@param car any
---@return nil
local function kick_players_from_surface(car)
    local surface_index = car.surface
    local surface = game.surfaces[surface_index]
    local allowed_surface = IC.get('allowed_surface')
    if not validate_entity(surface) then
        return log_err('Car surface was not valid.')
    end
    if not car.entity or not car.entity.valid then
        local main_surface = game.surfaces[allowed_surface]
        if validate_entity(main_surface) then
            for _, e in pairs(surface.find_entities_filtered({ area = car.area })) do
                if validate_entity(e) and e.name == 'character' and e.player then
                    local p = main_surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(main_surface), 3, 0)
                    if p then
                        e.player.teleport(p, main_surface)
                    end
                end
            end
            return log_err('Car entity was not valid.')
        end
    end

    for _, e in pairs(surface.find_entities_filtered({ name = 'character' })) do
        if validate_entity(e) and e.name == 'character' and e.player then
            local p = car.entity.surface.find_non_colliding_position('character', car.entity.position, 128, 0.5)
            if p then
                e.player.teleport(p, car.entity.surface)
            else
                e.player.teleport(car.entity.position, car.entity.surface)
            end
        end
    end
end

---Kicks players out of the car surface.
---@param car any
---@return nil
local function kick_non_trusted_players_from_surface(car)
    local surface_index = car.surface
    local trust_system = IC.get('trust_system')
    local allowed_surface = IC.get('allowed_surface') --[[@as string]]
    local main_surface = game.get_surface(allowed_surface) --[[@as LuaSurface]]

    local position = car.entity and car.entity.valid and car.entity.position or game.forces.player.get_spawn_position(main_surface)
    local owner = game.get_player(car.owner) and game.get_player(car.owner).name or false
    Core.iter_connected_players(
        function (player)
            local is_trusted = trust_system and trust_system.players and trust_system.players[player.name] and trust_system.players[player.name].trusted
            if player.physical_surface.index == surface_index and player.name ~= car.owner and not is_trusted then
                if position then
                    local new_position = main_surface.find_non_colliding_position('character', position, 3, 0)
                    if new_position then
                        player.teleport(new_position, main_surface)
                    else
                        player.teleport(game.forces.player.get_spawn_position(main_surface), main_surface)
                    end
                    player.print('[IC] You were kicked out of ' .. owner .. "'s " .. car.entity.name .. ' because you were not in the trusted list.', { color = Color.warning })
                end
            end
        end
    )
end

local function kick_player_from_surface(player, target)
    local cars = IC.get('cars')
    local allowed_surface = IC.get('allowed_surface')

    local main_surface = game.surfaces[allowed_surface]
    if not validate_entity(main_surface) then
        return
    end

    local car = get_owner_car_object(player)

    if not validate_entity(car.entity) then
        return
    end

    if validate_entity(player) then
        if validate_entity(target) then
            local locate = get_owner_car_surface(cars, player, target)
            if locate then
                local p = car.entity.surface.find_non_colliding_position('character', car.entity.position, 128, 0.5)
                if p then
                    target.teleport(p, car.entity.surface)
                else
                    target.teleport(main_surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(main_surface), 3, 0), main_surface)
                end
                target.print('You were kicked out of ' .. player.name .. ' vehicle.', Color.warning)
            end
        end
    end
end

local function restore_surface(player, entity)
    local ce = entity
    local saved_surfaces = IC.get('saved_surfaces')
    local cars = IC.get('cars')
    local doors = IC.get('doors')
    local renders = IC.get('renders')
    local surfaces = IC.get('surfaces')
    local index = saved_surfaces[player.name]
    if not index then
        return
    end

    if saved_surfaces[player.name] then
        local success, msg = get_saved_entity(ce, index)
        if not success then
            player.print(module_tag .. msg, { color = Color.warning })
            return true
        end
        replace_entity(cars, ce, index)
        replace_doors(doors, ce, index)
        replace_surface(surfaces, ce, index)
        replace_surface_entity(cars, ce, index)
        saved_surfaces[player.name] = nil
        render_owner_text(renders, player, ce)
        return true
    end
    return false
end

local function input_filtered(car_inv, chest, chest_inv, free_slots)
    local request_stacks = {}

    local prototypes = prototypes.item
    local logistics = chest.get_logistic_point(defines.logistic_member_index.logistic_container)
    local filters = Core.get_filters(logistics)
    for _, filter in pairs(filters) do
        if filter.value.name then
            request_stacks[filter.value.name] = 10 * prototypes[filter.value.name].stack_size
        end
    end
    for i = 1, #car_inv - 1, 1 do
        if free_slots <= 0 then
            return
        end
        local stack = car_inv[i]
        if stack.valid_for_read then
            local request_stack = request_stacks[stack.name]
            if request_stack and request_stack > chest_inv.get_item_count(stack.name) then
                chest_inv.insert(stack)
                stack.clear()
                free_slots = free_slots - 1
            end
        end
    end
end

local function input_cargo(car, chest)
    if not chest.request_from_buffers then
        goto continue
    end

    local car_entity = car.entity
    if not validate_entity(car_entity) then
        car.transfer_entities = nil
        goto continue
    end

    local car_inventory = car_entity.get_inventory(defines.inventory.car_trunk)
    if car_inventory.is_empty() then
        goto continue
    end

    local chest_inventory = chest.get_inventory(defines.inventory.chest)
    local free_slots = 0
    for i = 1, chest_inventory.get_bar() - 1, 1 do
        if not chest_inventory[i].valid_for_read then
            free_slots = free_slots + 1
        end
    end

    local has_request_slot = false
    local logistics = chest.get_logistic_point(defines.logistic_member_index.logistic_container)
    if logistics then
        local filters = Core.get_filters(logistics)
        for _, filter in pairs(filters) do
            if filter.value.name then
                has_request_slot = true
            end
        end
    end

    if has_request_slot then
        input_filtered(car_inventory, chest, chest_inventory, free_slots)
        goto continue
    end

    for i = 1, #car_inventory - 1, 1 do
        if free_slots <= 0 then
            goto continue
        end
        if car_inventory[i].valid_for_read then
            chest_inventory.insert(car_inventory[i])
            car_inventory[i].clear()
            free_slots = free_slots - 1
        end
    end

    ::continue::
end

local function output_cargo(car, passive_chest)
    if not validate_entity(car.entity) then
        goto continue
    end

    if not passive_chest.valid then
        goto continue
    end
    local chest1 = passive_chest.get_inventory(defines.inventory.chest)
    local chest2 = car.entity.get_inventory(defines.inventory.car_trunk)
    for i = 1, #chest1 do
        local t = chest1[i]
        if t and t.valid then
            local c = chest2.insert(t)
            if (c > 0) then
                chest1[i].count = chest1[i].count - c
            end
        end
    end
    ::continue::
end

local transfer_functions = {
    ['requester-chest'] = input_cargo,
    ['passive-provider-chest'] = output_cargo
}

local function construct_doors(car)
    local area = car.area
    local surface_index = car.surface
    local surface = game.surfaces[surface_index]
    if not surface or not surface.valid then
        return
    end

    local doors = IC.get('doors')

    for _, x in pairs({ area.left_top.x - 1.5, area.right_bottom.x + 1.5 }) do
        local p = { x = x, y = area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
        if p.x < 0 then
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x + 0.5, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x + 0.5, y = p.y - 0.5 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x + 0.5, y = p.y - 1 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x - 0.5, y = p.y - 1 } } }, true)
        else
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x - 0.5, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x - 1, y = p.y } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x, y = p.y - 0.5 } } }, true)
            surface.set_tiles({ { name = main_tile_name, position = { x = p.x - 1, y = p.y - 0.5 } } }, true)
        end
        local e =
            surface.create_entity(
                {
                    name = 'car',
                    position = { x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) },
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
        e.destructible = false
        e.minable_flag = false
        e.operable = false
        e.get_inventory(defines.inventory.fuel).insert({ name = 'coal', count = 1 })
        if car.saved then
            return
        end
        doors[e.unit_number] = car.entity.unit_number
        car.doors[#car.doors + 1] = e
    end
end

local function get_player_data(player)
    local players = IC.get('players')
    local player_data = players[player.name]
    if players[player.name] then
        return player_data
    end
    local fallback = WPT.get('active_surface_index') --[[@as string|integer]]
    if not fallback then
        fallback = 1
    end

    players[player.name] = {
        surface = 1,
        fallback_surface = tonumber(fallback),
        notified = false
    }
    return players[player.name]
end

local function get_persistent_player_data(player)
    local players = IC.get('players_persistent')
    local player_data = players[player.name]
    if players[player.name] then
        return player_data
    end

    players[player.name] = {}
    return players[player.name]
end

local remove_car =
    Task.register(
        function (data)
            local player = data.player
            local car = data.car
            player.remove_item({ name = car.name, count = 1 })
        end
    )

local find_remove_car =
    Task.register(
        function (data)
            local index = data.index
            local types = data.types
            local position = data.position

            local surface = game.get_surface(index)
            if not surface or not surface.valid then
                return
            end

            for _, dropped_ent in pairs(surface.find_entities_filtered { type = 'item-entity', area = { { position.x - 10, position.y - 10 }, { position.x + 10, position.y + 10 } } }) do
                if dropped_ent and dropped_ent.valid and dropped_ent.stack then
                    if types[dropped_ent.stack.name] then
                        dropped_ent.destroy()
                    end
                end
            end
        end
    )

function Public.save_car(event)
    local entity = event.entity
    local player = game.players[event.player_index]

    local cars = IC.get('cars')
    local car = cars[entity.unit_number]
    local restore_on_theft = IC.get('restore_on_theft')
    local entity_type = IC.get('entity_type')
    local types = entity_type
    local players = IC.get('players')

    if not car then
        log_err('Car was not valid.')
        return
    end

    local position = entity.position
    local health = entity.health

    kick_players_out_of_vehicles(car)
    kick_players_from_surface(car)
    get_player_data(player)

    if car.owner == player.name then
        save_surface(entity, player)
        if not players[player.name].notified then
            player.print(module_tag .. player.name .. ', the ' .. car.name .. ' surface has been saved.', { color = Color.success })
            players[player.name].notified = true
        end
    else
        local p = game.get_player(car.owner)
        if not p or not p.valid then
            return
        end

        local find_remove_car_args = {
            index = p.surface.index,
            types = types,
            position = p.physical_position
        }

        Task.set_timeout_in_ticks(1, find_remove_car, find_remove_car_args)
        Task.set_timeout_in_ticks(2, find_remove_car, find_remove_car_args)
        Task.set_timeout_in_ticks(3, find_remove_car, find_remove_car_args)

        log_err('Owner of this vehicle is: ' .. p.name)
        save_surface(entity, p)
        game.print(module_tag .. player.name .. ' has looted ' .. p.name .. '´s car.')
        player.print(module_tag .. 'This car was not yours to keep.', { color = Color.warning })
        local params = {
            player = player,
            car = car
        }
        Task.set_timeout_in_ticks(10, remove_car, params)
        if restore_on_theft then
            local e = player.physical_surface.create_entity({ name = car.name, position = position, force = player.force, create_build_effect_smoke = false })
            e.health = health
            restore_surface(p, e)
        elseif p.can_insert({ name = car.name, count = 1 }) then
            p.insert({ name = car.name, count = 1, health = health })
            p.print(module_tag .. 'Your car was stolen from you - the gods foresaw this and granted you a new one.', { color = Color.info })
        end
    end
end

function Public.remove_surface(player)
    local surfaces = IC.get('surfaces')
    local cars = IC.get('cars')
    local car = get_owner_car_object(player)
    if not car then
        return
    end

    if car.saved_entity then
        return
    end

    kick_players_out_of_vehicles(car)
    kick_players_from_surface(car)

    local trust_system = IC.get('trust_system')
    if trust_system[player.name] then
        trust_system[player.name] = nil
    end

    local renders = IC.get('renders')

    if renders[player.name] then
        renders[player.name].destroy()
        renders[player.name] = nil
    end

    local player_gui_data = IC.get('player_gui_data')
    if player_gui_data[player.name] then
        player_gui_data[player.name] = nil
    end

    local players = IC.get('players')
    if players[player.name] then
        players[player.name] = nil
    end

    local misc_settings = IC.get('misc_settings')
    if misc_settings[player.name] then
        misc_settings[player.name] = nil
    end

    kill_doors(car)

    surfaces[car.saved_entity] = nil
    cars[car.saved_entity] = nil

    local surface_index = car.surface
    local surface = game.surfaces[surface_index]
    if not surface or not surface.valid then
        return
    end

    for _, tile in pairs(surface.find_tiles_filtered({ area = car.area })) do
        surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end
    for _, x in pairs({ car.area.left_top.x - 1.5, car.area.right_bottom.x + 1.5 }) do
        local p = { x = x, y = car.area.left_top.y + ((car.area.right_bottom.y - car.area.left_top.y) * 0.5) }
        surface.set_tiles({ { name = out_of_map_tile, position = { x = p.x + 0.5, y = p.y } } }, true)
        surface.set_tiles({ { name = out_of_map_tile, position = { x = p.x - 1, y = p.y } } }, true)
    end
    game.delete_surface(surface)
end

function Public.kill_car(entity)
    if not validate_entity(entity) then
        return
    end

    local entity_type = IC.get('entity_type')

    if not entity_type[entity.type] then
        return
    end

    local entity_position = entity.position
    local entity_surface = entity.surface

    local surfaces = IC.get('surfaces')
    local cars = IC.get('cars')
    local car = cars[entity.unit_number]
    if not car then
        return
    end

    kick_players_out_of_vehicles(car)
    kick_players_from_surface(car)

    local trust_system = IC.get('trust_system')
    local owner = car.owner

    if owner then
        owner = game.get_player(owner)
        if owner and owner.valid then
            if trust_system[owner.name] then
                trust_system[owner.name] = nil
            end
        end
    end

    local renders = IC.get('renders')

    if not owner then
        return
    end

    if renders[owner.name] and renders[owner.name].valid then
        renders[owner.name].destroy()
        renders[owner.name] = nil
    end

    local gps_tag = '[gps=' .. entity_position.x .. ',' .. entity_position.y .. ',' .. entity_surface.name .. ']'

    game.print(module_tag .. owner.name .. messages[math.random(1, #messages)] .. ' ' .. gps_tag)

    Server.to_discord_bold(table.concat { '*** ', '[Personal Vehicle] ***', owner.name .. messages[math.random(1, #messages)] .. ' ', gps_tag })

    local player_gui_data = IC.get('player_gui_data')
    if player_gui_data[owner.name] then
        player_gui_data[owner.name] = nil
    end

    local players = IC.get('players')
    if players[owner.name] then
        players[owner.name] = nil
    end

    local misc_settings = IC.get('misc_settings')
    if misc_settings[owner.name] then
        misc_settings[owner.name] = nil
    end

    local surface_index = car.surface
    local surface = game.surfaces[surface_index]
    if not surface or not surface.valid then
        log('[IC] Car surface was not valid upon trying to delete.')
        return
    end
    kill_doors(car)
    for _, tile in pairs(surface.find_tiles_filtered({ area = car.area })) do
        surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end
    for _, x in pairs({ car.area.left_top.x - 1.5, car.area.right_bottom.x + 1.5 }) do
        local p = { x = x, y = car.area.left_top.y + ((car.area.right_bottom.y - car.area.left_top.y) * 0.5) }
        surface.set_tiles({ { name = out_of_map_tile, position = { x = p.x + 0.5, y = p.y } } }, true)
        surface.set_tiles({ { name = out_of_map_tile, position = { x = p.x - 1, y = p.y } } }, true)
    end
    car.entity.force.chart(surface, car.area)
    game.delete_surface(surface)
    surfaces[entity.unit_number] = nil
    cars[entity.unit_number] = nil
end

function Public.kill_car_but_save_surface(entity)
    if not validate_entity(entity) then
        return nil
    end

    local entity_type = IC.get('entity_type')

    if not entity_type[entity.type] then
        return nil
    end

    local cars = IC.get('cars')
    local car = cars[entity.unit_number]
    if not car then
        return nil
    end

    local surface_index = car.surface
    local surface = game.get_surface(surface_index)
    if not surface then
        return nil
    end

    local c = 0
    local entities = surface.find_entities_filtered({ area = car.area, force = 'player' })
    if entities and #entities > 0 then
        for _, e in pairs(entities) do
            if e and e.valid and e.name ~= 'character' then
                c = c + 1
            end
        end
        if c > 0 then
            return false, c
        end
    end

    local surfaces = IC.get('surfaces')
    local surfaces_deleted_by_button = IC.get('surfaces_deleted_by_button')

    kick_players_out_of_vehicles(car)
    kick_players_from_surface(car)

    car.entity.minable_flag = true

    local trust_system = IC.get('trust_system')
    local owner = car.owner

    if owner then
        owner = game.get_player(owner)
        if owner and owner.valid then
            if trust_system[owner.name] then
                trust_system[owner.name] = nil
            end
        end
    end

    if not owner then
        return nil
    end

    local renders = IC.get('renders')

    if renders[owner.name] and renders[owner.name].valid then
        renders[owner.name].destroy()
        renders[owner.name] = nil
    end

    local player_gui_data = IC.get('player_gui_data')
    if player_gui_data[owner.name] then
        player_gui_data[owner.name] = nil
    end

    local players = IC.get('players')
    if players[owner.name] then
        players[owner.name] = nil
    end

    local misc_settings = IC.get('misc_settings')
    if misc_settings[owner.name] then
        misc_settings[owner.name] = nil
    end

    if not surfaces_deleted_by_button[owner.name] then
        surfaces_deleted_by_button[owner.name] = {}
    end

    surfaces_deleted_by_button[owner.name][#surfaces_deleted_by_button[owner.name] + 1] = surface.name

    kill_doors(car)
    car.entity.force.chart(surface, car.area)
    surfaces[entity.unit_number] = nil
    cars[entity.unit_number] = nil
    return true
end

function Public.validate_owner(player, entity)
    if validate_entity(entity) then
        local cars = IC.get('cars')
        local unit_number = entity.unit_number
        local car = cars[unit_number]
        if not car then
            return
        end
        if validate_entity(car.entity) then
            local p = game.players[car.owner]
            local list = get_trusted_system(p)
            if p and p.valid and p.connected then
                if list.players[player.name] and list.players[player.name].drive then
                    return
                end
            end
            if p then
                if car.owner ~= player.name and player.driving then
                    player.driving = false
                    if not player.admin then
                        if list.notify_on_driver_change == 'left' then
                            p.print(player.name .. ' tried to drive your car.', { color = Color.warning })
                        end
                        return
                    end
                end
            end
        end
        return false
    end
    return false
end

function Public.create_room_surface(car)
    local unit_number = car.entity.unit_number

    if game.surfaces[car.surface_name] then
        return game.surfaces[car.surface_name].index
    end

    local map_gen_settings = {
        ['width'] = 2,
        ['height'] = 2,
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] = {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = { treat_missing_as_default = true },
            ['decorative'] = { treat_missing_as_default = false }
        }
    }
    local surface = game.create_surface(car.surface_name, map_gen_settings)
    surface.no_enemies_mode = true
    surface.freeze_daytime = true
    surface.daytime = 0.1
    surface.request_to_generate_chunks({ 16, 16 }, 1)
    surface.force_generate_chunk_requests()
    exclude_surface(surface)
    for _, tile in pairs(surface.find_tiles_filtered({ area = { { -2, -2 }, { 2, 2 } } })) do
        surface.set_tiles({ { name = out_of_map_tile, position = tile.position } }, true)
    end
    local surfaces = IC.get('surfaces')
    surfaces[unit_number] = surface.index
    return surface.index
end

function Public.create_car_room(car)
    local surface_index = car.surface
    local surface = game.surfaces[surface_index]
    local car_areas = IC.get('car_areas')
    local entity_name = car.name
    local entity_type = car.type
    local area = car_areas[entity_name]
    local tiles = {}

    if not area then
        area = car_areas[entity_type]
    end


    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
    end
    for x = -3, 2, 1 do
        for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
            tiles[#tiles + 1] = { name = main_tile_name, position = { x, y } }
        end
    end

    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = -0, 1, 1 do
            tiles[#tiles + 1] = { name = 'water', position = { x, y } }
        end
    end

    surface.set_tiles(tiles, true)

    local p = game.get_player(car.owner)
    if p and p.valid then
        local player_data = get_persistent_player_data(p)
        if not player_data.placed_fish then
            local fishes = {}
            for x = area.left_top.x, area.right_bottom.x - 1, 1 do
                for y = -0, 1, 1 do
                    fishes[#fishes + 1] = { name = 'fish', position = { x, y } }
                end
            end

            for _, fish in pairs(fishes) do
                surface.create_entity(fish)
            end
            player_data.placed_fish = true
        end
    end

    construct_doors(car)
    local mgs = surface.map_gen_settings
    mgs.width = area.right_bottom.x * 2
    mgs.height = area.right_bottom.y * 2
    surface.map_gen_settings = mgs

    local lx, ly, rx, ry = 4, 1, 5, 1

    local position1 = { area.left_top.x + lx, area.left_top.y + ly }
    local position2 = { area.right_bottom.x - rx, area.left_top.y + ry }

    local e1 =
        surface.create_entity(
            {
                name = 'requester-chest',
                position = position1,
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
    e1.destructible = false
    e1.minable_flag = false

    local e2 =
        surface.create_entity(
            {
                name = 'passive-provider-chest',
                position = position2,
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
    e2.destructible = false
    e2.minable_flag = false
    car.transfer_entities = { e1, e2 }
end

function Public.create_car(event)
    local ce = event.entity

    local player = game.get_player(event.player_index)

    local allowed_surface = IC.get('allowed_surface')
    local map_name = allowed_surface

    local entity_type = IC.get('entity_type')
    local un = ce.unit_number

    if not un then
        return
    end

    if not entity_type[ce.type] then
        return
    end

    local renders = IC.get('renders')
    local upgrades = WPT.get('upgrades')

    local car, mined = get_player_entity(player)

    if car then
        if entity_type[car.name] and not mined then
            return player.print(module_tag .. 'Multiple vehicles are not supported at the moment.', { color = Color.warning })
        end
    end

    if string.sub(ce.surface.name, 0, #map_name) ~= map_name then
        return player.print(module_tag .. 'Multi-surface is not supported at the moment.', { color = Color.warning })
    end

    local storage = get_trusted_system(player)

    if get_owner_car_name(player) == 'car' and ce.name == 'tank' or get_owner_car_name(player) == 'car' and ce.name == 'spidertron' or get_owner_car_name(player) == 'tank' and ce.name == 'spidertron' then
        if storage.auto_upgrade and storage.auto_upgrade == 'right' then
            return
        end
        upgrade_surface(player, ce)
        render_owner_text(renders, player, ce)
        player.print(module_tag .. 'Your car-surface has been upgraded!', { color = Color.success })
        return
    end

    local saved_surface = restore_surface(player, ce)
    if saved_surface then
        return
    end

    local car_areas = IC.get('car_areas')
    local cars = IC.get('cars')
    local car_area = car_areas[ce.name]
    if not car_area then
        car_area = car_areas[ce.type]
    end

    local health = floor(2000 * ce.health * 0.002)

    cars[un] = {
        entity = ce,
        area = {
            left_top = { x = car_area.left_top.x, y = car_area.left_top.y },
            right_bottom = { x = car_area.right_bottom.x, y = car_area.right_bottom.y }
        },
        doors = {},
        health_pool = {
            enabled = upgrades.has_upgraded_health_pool or false,
            health = health,
            max = health
        },
        owner = player.name,
        owner_name = player.name,
        name = ce.name,
        type = ce.type,
        unit_number = ce.unit_number,
        surface_name = player.name .. '_' .. ce.type .. '_' .. un
    }

    car = cars[un]

    car.surface = Public.create_room_surface(car)
    Public.create_car_room(car)
    render_owner_text(renders, player, ce)

    return car
end

function Public.remove_invalid_cars()
    local cars = IC.get('cars')
    local doors = IC.get('doors')
    local surfaces = IC.get('surfaces')
    for car_index, car in pairs(cars) do
        if car and not car.saved then
            if not validate_entity(car.entity) then
                cars[car_index] = nil
                for key, door_to_car_index in pairs(doors) do
                    if car_index == door_to_car_index then
                        doors[key] = nil
                    end
                end
                kick_players_from_surface(car)
                log('IC::remove_invalid_cars -> car.entity was not valid for car_index: ' .. car_index)
            else
                local owner = game.get_player(car.owner)
                if owner and owner.valid then
                    if JailData.get_is_jailed(owner.name) and not car.schedule_enable_mining then
                        car.schedule_enable_mining = true
                        Task.set_timeout_in_ticks(30, enable_car_to_be_mined, { entity = car.entity, owner_name = owner.name })
                    end

                    if not owner.connected and not car.schedule_enable_mining then
                        car.schedule_enable_mining = true
                        Task.set_timeout_in_ticks(30, enable_car_to_be_mined, { entity = car.entity, owner_name = owner.name })
                    end

                    if owner.connected and car.schedule_enable_mining then
                        car.schedule_enable_mining = nil
                    end
                else
                    if not car.schedule_enable_mining then
                        Task.set_timeout_in_ticks(30, enable_car_to_be_mined, { entity = car.entity, owner_name = owner.name })
                        cars[car_index] = nil
                        if cars[car_index] then
                            log('IC::remove_invalid_cars -> car will be deleted since no valid owner was found for car index: ' .. car_index)
                            cars[car_index] = nil
                        end
                    end
                end
            end
        end
    end

    for car_to_surface_index, surface_index in pairs(surfaces) do
        local surface = game.surfaces[surface_index]
        if surface and surface.valid then
            local valid_surface = get_car_by_surface(surface.index)
            if not valid_surface then
                game.delete_surface(surface)
                surfaces[car_to_surface_index] = nil
                log('IC::remove_invalid_cars -> surface was valid and will be deleted since no car entry for car_to_surface_index: ' .. car_to_surface_index)
            end
        else
            if cars[car_to_surface_index] then
                log('IC::remove_invalid_cars -> car will be deleted since no valid surface was found for car_to_surface_index: ' .. car_to_surface_index)
                cars[car_to_surface_index] = nil
            end

            log('IC::remove_invalid_cars -> surface was not valid upon trying to delete for car_to_surface_index: ' .. car_to_surface_index)
            surfaces[car_to_surface_index] = nil
        end
    end
end

function Public.use_door_with_entity(player, door)
    local player_data = get_player_data(player)
    if player_data.state then
        player_data.state = player_data.state - 1
        if player_data.state == 0 then
            player_data.state = nil
        end
        return
    end

    if not validate_entity(door) then
        return
    end
    local doors = IC.get('doors')
    local cars = IC.get('cars')

    local car = false
    if doors[door.unit_number] then
        car = cars[doors[door.unit_number]]
    end
    if cars[door.unit_number] then
        car = cars[door.unit_number]
    end
    if not car then
        return
    end

    if not validate_entity(car.entity) then
        return
    end

    local owner = game.players[car.owner]
    local list = get_trusted_system(owner)
    if owner and owner.valid and owner.name ~= player.name and player.connected then
        if list.allow_anyone == 'right' then
            if ((not list.players[player.name]) or (list.players[player.name] and not list.players[player.name].trusted)) and not player.admin then
                if list.players[player.name] and list.players[player.name].drive then
                    return
                else
                    player.driving = false
                    return player.print(module_tag .. 'You have not been approved by ' .. owner.name .. ' to enter their vehicle.', { color = Color.warning })
                end
            end
        else
            if (list.players[player.name] and not list.players[player.name].trusted) and not player.admin then
                if list.players[player.name].drive then
                    return
                else
                    player.driving = false
                    return player.print(module_tag .. 'You have not been approved by ' .. owner.name .. ' to enter their vehicle.', { color = Color.warning })
                end
            end
        end
    end

    if validate_entity(car.entity) then
        player_data.fallback_surface = car.entity.surface
        player_data.fallback_position = { car.entity.position.x, car.entity.position.y }
    end

    if validate_entity(car.entity) and car.entity.surface.name == player.physical_surface.name then
        local surface_index = car.surface
        local surface = game.surfaces[surface_index]
        if validate_entity(car.entity) and car.owner == player.name then
            Event.raise(
                IC.events.used_car_door,
                {
                    player = player,
                    state = 'add'
                }
            )
            car.entity.minable_flag = false
        end

        if not validate_entity(surface) then
            return
        end

        local area = car.area
        local x_vector = door.position.x - player.physical_position.x
        local position
        if x_vector > 0 then
            position = { area.left_top.x + 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
        else
            position = { area.right_bottom.x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5) }
        end
        local p = surface.find_non_colliding_position('character', position, 128, 0.5)
        if p then
            player.teleport(p, surface)
        else
            player.teleport(position, surface)
        end
        player_data.surface = surface.index
    else
        if validate_entity(car.entity) and car.owner == player.name then
            Event.raise(
                IC.events.used_car_door,
                {
                    player = player,
                    state = 'remove'
                }
            )
            car.entity.minable_flag = true
        end
        local surface = car.entity.surface
        local x_vector = (door.position.x / math.abs(door.position.x)) * 2
        local position = { car.entity.position.x + x_vector, car.entity.position.y }
        local surface_position = surface.find_non_colliding_position('character', position, 128, 0.5)
        if car.entity.type == 'car' or car.entity.name == 'spidertron' then
            player.teleport(surface_position, surface)
            player_data.state = 2
            player.driving = true
        else
            player.teleport(surface_position, surface)
        end
        player_data.surface = surface.index
    end
end

function Public.item_transfer()
    local cars = IC.get('cars')
    for _, car in pairs(cars) do
        if validate_entity(car.entity) then
            if car.transfer_entities then
                for _, e in pairs(car.transfer_entities) do
                    if validate_entity(e) then
                        transfer_functions[e.name](car, e)
                    end
                end
            end
        end
    end
end

function Public.on_player_died(player)
    local cars = IC.get('cars')
    for _, car in pairs(cars) do
        if car.owner == player.name then
            local entity = car.entity
            if entity and entity.valid then
                entity.minable_flag = false
            end
        end
    end
end

function Public.on_player_respawned(player)
    local cars = IC.get('cars')
    for _, car in pairs(cars) do
        if car.owner == player.name then
            local entity = car.entity
            if entity and entity.valid then
                entity.minable_flag = true
            end
        end
    end
end

function Public.check_entity_healths()
    local cars = IC.get('cars')
    if not next(cars) then
        return
    end

    local health_types = {
        ['car'] = 450,
        ['tank'] = 2000,
        ['spidertron'] = 3000
    }

    for _, car in pairs(cars) do
        local m = car.health_pool.health / car.health_pool.max

        if car.health_pool.health > car.health_pool.max then
            car.health_pool.health = car.health_pool.max
        end

        if (car.entity and car.entity.valid) then
            car.entity.health = health_types[car.entity.name] * m
        end
    end
end

function Public.get_car(unit_number)
    local cars = IC.get('cars')
    if not next(cars) then
        return
    end

    return cars[unit_number] or nil
end

function Public.set_damage_health(data)
    local entity = data.entity
    local final_damage_amount = data.final_damage_amount
    local car = data.car

    if final_damage_amount == 0 then
        return
    end

    local health_types = {
        ['car'] = 450,
        ['tank'] = 2000,
        ['spidertron'] = 3000
    }

    car.health_pool.health = round(car.health_pool.health - final_damage_amount)

    if car.health_pool.health <= 0 then
        entity.die()
        return
    end

    local m = car.health_pool.health / car.health_pool.max

    entity.health = health_types[entity.name] * m
end

function Public.set_repair_health(data)
    local entity = data.entity
    local car = data.car
    local player = data.player

    local repair_speed = RPG.get_magicka(player)
    if repair_speed <= 0 then
        repair_speed = 5
    end

    local health_types = {
        ['car'] = 450,
        ['tank'] = 2000,
        ['spidertron'] = 3000
    }

    car.health_pool.health = round(car.health_pool.health + repair_speed)

    local m = car.health_pool.health / car.health_pool.max

    if car.health_pool.health > car.health_pool.max then
        car.health_pool.health = car.health_pool.max
    end

    entity.health = health_types[entity.name] * m
end

Public.get_trusted_system = get_trusted_system
Public.does_player_table_exist = does_player_table_exist
Public.kick_player_from_surface = kick_player_from_surface
Public.get_player_surface = get_player_surface
Public.get_entity_from_player_surface = get_entity_from_player_surface
Public.get_owner_car_object = get_owner_car_object
Public.get_player_entity = get_player_entity
Public.render_owner_text = render_owner_text
Public.kick_players_from_surface = kick_players_from_surface
Public.kick_non_trusted_players_from_surface = kick_non_trusted_players_from_surface

Event.add(
    OfflinePlayers.events.remove_surface,
    function (event)
        local target = event.target
        if not target then
            return
        end

        Public.remove_surface(target)
    end
)

return Public
