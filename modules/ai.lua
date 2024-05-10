--- created by Gerkiz
local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Utils = require 'utils.common'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Task = require 'utils.task'

local this = {
    timers = {},
    characters = {},
    characters_unit_numbers = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {events = {on_entity_mined = Event.generate_event_name('on_entity_mined')}}

local max_keepalive = 54000 -- 15 minutes
local remove = table.remove
local round = math.round
local default_radius = 5

local armor_names = {
    'power-armor-mk2',
    'power-armor',
    'modular-armor',
    'heavy-armor',
    'light-armor'
}

local weapon_names = {
    ['rocket-launcher'] = 'rocket',
    ['submachine-gun'] = {'uranium-rounds-magazine', 'piercing-rounds-magazine', 'firearm-magazine'},
    ['shotgun'] = {'piercing-shotgun-shell', 'shotgun-shell'},
    ['pistol'] = {'uranium-rounds-magazine', 'piercing-rounds-magazine', 'firearm-magazine'}
}
local remove_character

Public.command = {
    noop = 0,
    seek_and_destroy_cmd = 1,
    seek_and_mine_cmd = 2
}

local clear_corpse_token =
    Token.register(
    function(event)
        local position = event.position
        local surface = game.get_surface(event.surface_index)
        local search_info = {
            type = 'character-corpse',
            position = position,
            radius = 1
        }

        local corpses = surface.find_entities_filtered(search_info)
        if corpses and #corpses > 0 then
            for _, corpse in pairs(corpses) do
                if corpse and corpse.valid then
                    if corpse.character_corpse_player_index == 65536 then
                        corpse.destroy()
                    end
                end
            end
        end
    end
)

local function char_callback(callback)
    local entities = this.characters

    for i = 1, #entities do
        local data = entities[i]
        if data and data.entity and data.entity.valid then
            callback(data)
        elseif data and data.unit_number then
            remove_character(data.unit_number)
        end
    end
end

local function get_near_position(entity)
    return {x = round(entity.position.x, 0), y = round(entity.position.y, 0)}
end

local function is_mining_target_taken(selected)
    if not selected then
        return false
    end

    char_callback(
        function(data)
            local entity = data.entity
            if entity.selected == selected then
                return true
            end
        end
    )

    return false
end

local function count_active_characters(player_index)
    if not next(this.characters) then
        return
    end

    local count = 0

    for _, data in pairs(this.characters) do
        if data and data.player_index == player_index then
            count = count + 1
        end
    end
    return count
end

local function add_character(player_index, entity, render_id, data)
    local index = #this.characters + 1
    if not this.characters[index] then
        this.characters[index] = {
            player_index = player_index,
            index = index,
            unit_number = entity.unit_number,
            entity = entity,
            ttl = game.tick + (data.ttl or max_keepalive),
            command = data.command,
            radius = default_radius,
            max_radius_mine = 20,
            max_radius_destroy = 150,
            render_id = render_id,
            search_local = data.search_local or false,
            walking_position = {count = 1, position = get_near_position(entity)}
        }
    end
    if not this.characters_unit_numbers[entity.unit_number] then
        this.characters_unit_numbers[entity.unit_number] = true
    end
end

local function exists_character(unit_number)
    if not next(this.characters_unit_numbers) then
        return
    end

    if this.characters_unit_numbers[unit_number] then
        return true
    end

    return false
end

remove_character = function(unit_number)
    if not next(this.characters) then
        return
    end

    for index, data in pairs(this.characters) do
        if data and data.unit_number == unit_number then
            if data.entity and data.entity.valid then
                data.entity.destroy()
            end
            if rendering.is_valid(data.render_id) then
                rendering.destroy(data.render_id)
            end
            remove(this.characters, index)
        end
    end

    if this.characters_unit_numbers[unit_number] then
        this.characters_unit_numbers[unit_number] = nil
    end
end

local function get_dir(src, dest)
    local src_x = Utils.get_axis(src, 'x')
    local src_y = Utils.get_axis(src, 'y')
    local dest_x = Utils.get_axis(dest, 'x')
    local dest_y = Utils.get_axis(dest, 'y')

    local step = {
        x = nil,
        y = nil
    }

    local precision = Utils.rand_range(1, 10)
    if dest_x - precision > src_x then
        step.x = 1
    elseif dest_x < src_x - precision then
        step.x = -1
    else
        step.x = 0
    end

    if dest_y - precision > src_y then
        step.y = 1
    elseif dest_y < src_y - precision then
        step.y = -1
    else
        step.y = 0
    end

    return Utils.direction_lookup[step.x][step.y]
end

local function move_to(entity, target, min_distance)
    local state = {
        walking = false
    }

    local distance = Utils.get_distance(target.position, entity.position)
    if min_distance < distance then
        local dir = get_dir(entity.position, target.position)
        if dir then
            state = {
                walking = true,
                direction = dir
            }
        end
    end

    entity.walking_state = state
    return state.walking
end

local function refill_ammo(player, entity)
    if not entity or not entity.valid then
        return
    end
    local inventory = player.get_main_inventory()

    local weapon = entity.get_inventory(defines.inventory.character_guns)[entity.selected_gun_index]
    if weapon and weapon.valid_for_read then
        local selected_ammo = entity.get_inventory(defines.inventory.character_ammo)[entity.selected_gun_index]
        if selected_ammo then
            if not selected_ammo.valid_for_read then
                if weapon.name == 'rocket-launcher' then
                    local player_has_ammo = inventory.get_item_count('rocket')
                    if player_has_ammo > 0 then
                        entity.insert({name = 'rocket', count = 1})
                        player.remove_item({name = 'rocket', count = 1})
                    end
                end
                if weapon.name == 'shotgun' then
                    local player_has_ammo = inventory.get_item_count('shotgun-shell')
                    if player_has_ammo > 4 then
                        entity.insert({name = 'shotgun-shell', count = 5})
                        player.remove_item({name = 'shotgun-shell', count = 5})
                    end
                end
                if weapon.name == 'pistol' then
                    local player_has_ammo = inventory.get_item_count('firearm-magazine')
                    if player_has_ammo > 4 then
                        entity.insert({name = 'firearm-magazine', count = 5})
                        player.remove_item({name = 'firearm-magazine', count = 5})
                    end
                end
            end
        end
    end
end

local function shoot_at(entity, target)
    entity.selected = target
    entity.shooting_state = {
        state = defines.shooting.shooting_enemies,
        position = target.position
    }
end

local function check_progress_and_raise_event(data)
    if data.entity.selected and data.entity.character_mining_progress >= 0.95 then
        if not data.raised_event then
            data.raised_event = true
            Event.raise(
                Public.events.on_entity_mined,
                {
                    player_index = data.player_index,
                    entity = data.entity.selected,
                    surface = data.entity.surface,
                    script_character = data.entity
                }
            )
        end
    end
end

local function mine_entity(data, target)
    data.entity.selected = target
    data.entity.mining_state = {mining = true, position = target.position}
end

local function shoot_stop(entity)
    entity.shooting_state = {
        state = defines.shooting.not_shooting,
        position = {0, 0}
    }
end

local function has_armor_equipped(entity)
    local armor = entity.get_inventory(defines.inventory.character_armor)[1]
    if armor.valid_for_read then
        return true
    end
    return false
end

local function insert_weapons_and_armor(player, entity, armor_only)
    if not entity or not entity.valid then
        return
    end
    local weapon = entity.get_inventory(defines.inventory.character_guns)[entity.selected_gun_index]
    if weapon and weapon.valid_for_read then
        return
    end

    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end

    for _, armor_name in pairs(armor_names) do
        if not has_armor_equipped(entity) and inventory.get_item_count(armor_name) > 0 then
            entity.insert({name = armor_name, count = 1})
            player.remove_item({name = armor_name, count = 1})
            break
        end
    end

    if armor_only then
        return
    end

    for weapon_name, ammo in pairs(weapon_names) do
        if inventory.get_item_count(weapon_name) > 0 then
            entity.insert({name = weapon_name, count = 1})
            player.remove_item({name = weapon_name, count = 1})

            if type(ammo) ~= 'table' then
                if inventory.get_item_count(ammo) > 0 then
                    entity.insert({name = ammo, count = 1})
                    player.remove_item({name = ammo, count = 1})
                end
            else
                for _, ammo_name in pairs(ammo) do
                    if inventory.get_item_count(ammo_name) > 0 then
                        entity.insert({name = ammo_name, count = 1})
                        player.remove_item({name = ammo_name, count = 1})
                        break
                    end
                end
            end
            break
        end
    end
end

local function seek_and_mine(data)
    if data.radius >= data.max_radius_mine then
        if data.overriden_command then
            data.command = data.overriden_command
            data.overriden_command = nil
            return
        else
            data.radius = 1
        end
    end

    local entity = data.entity
    if not entity or not entity.valid then
        remove_character(data.unit_number)
        return
    end

    local surface = entity.surface
    local player_index = data.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid or not player.connected then
        remove_character(data.unit_number)
        return
    end

    local position

    if data.search_local then
        position = entity.position
    else
        position = player.position
    end

    local search_info = {
        position = position,
        radius = data.radius,
        type = {
            'simple-entity-with-owner',
            'simple-entity',
            'tree'
        },
        force = {
            'neutral'
        }
    }

    local closest = surface.find_entities_filtered(search_info)

    if #closest ~= 0 then
        local target = Utils.get_closest_neighbour_non_player(entity.position, closest)
        if not target then
            data.radius = data.radius + 1
            return
        end

        data.radius = 1

        insert_weapons_and_armor(player, entity, true)

        if not move_to(entity, target, 1) then
            if not is_mining_target_taken(target) then
                if data.raised_event then
                    data.raised_event = nil
                end

                if entity.can_reach_entity(target) then
                    mine_entity(data, target)
                else
                    move_to(entity, target, 1)
                end
            end
            if data.overriden_command then
                data.command = data.overriden_command
                data.overriden_command = nil
            end
        end
    else
        data.radius = data.radius + 1
    end
end

local function seek_enemy_and_destroy(data)
    if data.radius >= data.max_radius_destroy then
        remove_character(data.unit_number)
        return
    end

    local entity = data.entity
    if not entity or not entity.valid then
        remove_character(data.unit_number)
        return
    end

    local surface = entity.surface
    local player_index = data.player_index
    local player = game.get_player(player_index)
    if not player or not player.valid or not player.connected then
        remove_character(data.unit_number)
        return
    end

    local search_info = {
        type = {'unit', 'unit-spawner', 'turret'},
        position = entity.position,
        radius = data.radius,
        force = 'enemy'
    }

    local closest = surface.find_entities_filtered(search_info)

    if #closest ~= 0 then
        local target = Utils.get_closest_neighbour_non_player(entity.position, closest)
        if not target then
            data.radius = data.radius + 5
            return
        end
        data.radius = default_radius
        insert_weapons_and_armor(player, entity)
        refill_ammo(player, entity)

        local inside = ((entity.position.x - data.walking_position.position.x) ^ 2 + (entity.position.y - data.walking_position.position.y) ^ 2) < 1 ^ 2
        data.walking_position.position = get_near_position(entity)

        if inside then
            data.walking_position.count = data.walking_position.count + 1
        end

        if data.walking_position.count == 3 then
            data.radius = 1
            data.walking_position.count = 1
            data.overriden_command = data.command
            data.command = Public.command.seek_and_mine_cmd
            seek_and_mine(data)
        else
            if not move_to(entity, target, Utils.rand_range(10, 20)) then
                shoot_at(entity, target)
            else
                shoot_stop(entity)
            end
        end
    else
        data.radius = data.radius + 5
    end
end

--- Creates a new character that seeks and does stuff.
---@param data table
----- @usage local Ai = require 'modules.ai' Ai.create_char({player_index = game.player.index, command = 1})
function Public.create_char(data)
    if not data or not type(data) == 'table' then
        return error('No data was provided or the provided data was not a table.', 2)
    end

    if not data.player_index or not data.command then
        return error('No correct data was provided.', 2)
    end

    if data.command ~= Public.command.seek_and_destroy_cmd and data.command ~= Public.command.attack_objects_cmd and data.command ~= Public.command.seek_and_mine_cmd then
        return error('No correct command was provided.', 2)
    end

    local player = game.get_player(data.player_index)
    if not player or not player.valid or not player.connected then
        return error('Provided player was not valid or not connected.', 2)
    end

    local count = count_active_characters(data.player_index)
    if count and count >= 5 then
        return false
    end

    local surface = player.surface
    local valid_position = surface.find_non_colliding_position('character', {x = player.position.x, y = player.position.y + 2}, 3, 0.5)
    if not valid_position then
        return
    end
    local entity = surface.create_entity {name = 'character', position = valid_position, force = player.force}
    if not entity or not entity.valid then
        return
    end

    entity.associated_player = player
    if player.character_health_bonus >= 200 then
        entity.character_health_bonus = player.character_health_bonus / 2
    end

    entity.color = player.color
    local index = #this.characters + 1

    local render_id =
        rendering.draw_text {
        text = player.name .. "'s drone #" .. index,
        surface = player.surface,
        target = entity,
        target_offset = {0, -2.25},
        color = Color.orange,
        scale = 1.00,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }

    add_character(player.index, entity, render_id, data)
end

Event.on_nth_tick(
    2,
    function()
        char_callback(
            function(data)
                check_progress_and_raise_event(data)
            end
        )
    end
)

Event.on_nth_tick(
    10,
    function()
        local tick = game.tick
        char_callback(
            function(data)
                if data.ttl <= tick then
                    remove_character(data.unit_number)
                    return
                end

                local command = data.command

                if command == Public.command.seek_and_destroy_cmd then
                    seek_enemy_and_destroy(data)
                elseif command == Public.command.seek_and_mine_cmd then
                    seek_and_mine(data)
                end
            end
        )
    end
)

Event.add(
    defines.events.on_entity_died,
    function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end
        if entity.type ~= 'character' then
            return
        end

        local unit_number = entity.unit_number
        if not exists_character(unit_number) then
            return
        end

        Task.set_timeout_in_ticks(1, clear_corpse_token, {position = entity.position, surface_index = entity.surface.index})

        remove_character(unit_number)
    end
)

return Public
