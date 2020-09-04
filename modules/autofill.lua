local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'

local this = {
    refill_turrets = {},
    refill_chests = {index = 1, placed = 0},
    full_turrets = {},
    valid_chest = {
        ['iron-chest'] = {valid = true, limit = 4}
    },
    valid_turrets = {
        ['gun-turret'] = true,
        ['artillery-turret'] = true
    },
    valid_ammo = {
        ['firearm-magazine'] = {valid = true, priority = 1},
        ['piercing-rounds-magazine'] = {valid = true, priority = 2},
        ['uranium-rounds-magazine'] = {valid = true, priority = 3}
    },
    message_limit = {},
    player_settings = {},
    globally_enabled = false
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}
local insert = table.insert
local autofill_amount = 10
local valid_chest = this.valid_chest
local valid_turrets = this.valid_turrets
local valid_ammo = this.valid_ammo

local function validate_entity(entity)
    if not entity then
        return false
    end
    if not entity.valid then
        return false
    end
    return true
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local function get_player_data(player, remove_user_data)
    if this.globally_enabled then
        return
    end
    if remove_user_data then
        if this.player_settings[player.index] then
            this.player_settings[player.index] = nil
        end
    end
    if not this.player_settings[player.index] then
        this.player_settings[player.index] = {
            placed = 0,
            chests = {},
            turrets = {},
            enabled = true
        }
    end
    return this.player_settings[player.index]
end

local function contains(table, entity)
    if not table then
        return
    end
    for k, turret in pairs(table) do
        if not validate_entity(turret) then
            return false
        end
        if not validate_entity(entity) then
            return false
        end
        if turret.unit_number == entity.unit_number then
            return true
        end
    end
end

local function get_highest(table)
    local highest = -math.huge
    local item
    local count

    for k, v in pairs(table) do
        if (k and valid_ammo[k] and valid_ammo[k].priority > highest) then
            item = k
            count = v
        end
    end

    if not item or not count then
        return false
    end

    return item, count
end

local function get_valid_chest()
    local chests = {}
    if this.globally_enabled then
        local refill_chests = this.refill_chests

        if not next(refill_chests) then
            return
        end

        local chest

        for i = 1, #refill_chests do
            chest = refill_chests[i]
            if chest then
                chests[#chests + 1] = chest
            end

            if not chest.valid then
                fast_remove(refill_chests, i)
                refill_chests.placed = refill_chests.placed - 1
                if refill_chests.placed <= 0 then
                    refill_chests.placed = 0
                end
                return false
            end
        end
        return chests
    end

    local player_data = this.player_settings

    if not next(player_data) then
        return
    end

    local chest

    for i = 1, #player_data do
        local player = game.get_player(i)
        if player and player.valid then
            local p_data = get_player_data(player)
            local p_chests = p_data.chests
            if not next(p_chests) then
                return
            end
            for t = 1, #p_chests do
                chest = p_chests[t]
                if chest then
                    chests[#chests + 1] = chest
                end
                if not chest.valid then
                    fast_remove(p_data.chests, i)
                    p_data.placed = p_data.placed - 1
                    if p_data.placed <= 0 then
                        p_data.placed = 0
                    end
                    return
                end
            end
        end
    end
    return chests
end

local function get_ammo(entity_turret)
    local turret = entity_turret.get_inventory(defines.inventory.turret_ammo)

    local contents = turret.get_contents()

    local c = 0

    for item, count in pairs(contents) do
        if valid_ammo[item] and valid_ammo[item].valid and count >= 1 then
            c = count
            return item, c
        end
    end

    return false, c
end

local function get_items(chest)
    local contents = chest.get_contents()
    local item, count = get_highest(contents)

    if valid_ammo[item] and valid_ammo[item].valid and count >= 1 then
        return item, count
    end
end

local function remove_ammo(chest, entity_turret)
    local turret = entity_turret.get_inventory(defines.inventory.turret_ammo)
    local current_ammo

    if not chest or not chest.valid then
        return
    end

    local contents = turret.get_contents()

    for item, count in pairs(contents) do
        if count >= 1 then
            local t = {name = item, count = count}
            if chest.can_insert(t) then
                local c = chest.insert(t)
                current_ammo = item
                turret.remove({name = item, count = c})
                return current_ammo
            end
        end
    end
end

local function refill(entity_turret, entity_chest)
    local turret = entity_turret

    for _, chests in next, entity_chest do
        local chest = chests.get_inventory(defines.inventory.chest)

        local item, count = get_items(chest)

        local turret_inv = turret.get_inventory(defines.inventory.turret_ammo)
        if valid_ammo[item] and valid_ammo[item].valid and count >= 1 then
            local ammo_name, ammo_count = get_ammo(turret)

            if ammo_name and valid_ammo[ammo_name].priority < valid_ammo[item].priority then
                remove_ammo(chest, turret)
            end
            if ammo_count and ammo_count >= 10 then
                goto continue
            end
            local t = {name = item, count = 1}
            local c = turret_inv.insert(t)
            if (c > 0) then
                chest.remove({name = item, count = c})
            end

            ::continue::
        end
    end
end

local function do_refill_turrets()
    local chest = get_valid_chest()

    if not chest then
        return
    end

    if this.globally_enabled then
        local turrets = this.refill_turrets

        if not next(turrets) then
            return
        end

        for i = 1, #turrets do
            local turret = turrets[i]
            if not turret then
                return
            end

            if not turret.valid then
                fast_remove(turrets, i)
            else
                refill(turret, chest)
            end
        end
        return
    end

    local player_data = this.player_settings

    if not next(player_data) then
        return
    end

    for p, _ in next, player_data do
        local player = game.get_player(p)
        if player and player.valid then
            local p_data = get_player_data(player)
            if not p_data then
                return
            end
            local turrets = p_data.turrets
            if not next(turrets) then
                return
            end
            for key, turret in next, turrets do
                if not turret then
                    return
                end

                if not turret.valid then
                    fast_remove(turrets, key)
                else
                    refill(turret, chest)
                end
            end
        end
    end
end

local function show_text(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({name = 'flying-text', position = pos, text = msg})
    else
        surface.create_entity({name = 'flying-text', position = pos, text = msg, color = color})
    end
end

local function move_items(source, destination, stack)
    if (source.get_item_count(stack.name) == 0) then
        return -1
    end

    if (not destination.can_insert(stack)) then
        return -2
    end

    local itemsRemoved = source.remove(stack)
    stack.count = itemsRemoved
    return destination.insert(stack)
end

local function move_multiple(source, destination, stack, amount)
    local ret = 0
    for _, itemName in pairs(stack) do
        ret = move_items(source, destination, {name = itemName, count = amount})
        if (ret > 0) then
            return ret
        end
    end
    return ret
end

local function auto_insert_into_turret(player, turret)
    local inventory = player.get_main_inventory()
    if (inventory == nil) then
        return
    end

    local ret =
        move_multiple(
        inventory,
        turret,
        {'artillery-shell', 'uranium-rounds-magazine', 'piercing-rounds-magazine', 'firearm-magazine'},
        autofill_amount
    )

    if (ret > 1) then
        show_text('[Autofill] Inserted ' .. ret .. '!', turret.position, Color.info, player.surface)
    elseif (ret == -1) then
        show_text('[Autofill] Out of ammo!', turret.position, Color.red, player.surface)
    elseif (ret == -2) then
        show_text('[Autofill] Autofill ERROR! - Report this bug!', turret.position, Color.red, player.surface)
    end
end

local function auto_insert_into_vehicle(player, vehicle)
    local inventory = player.get_main_inventory()
    if (inventory == nil) then
        return
    end

    if ((vehicle.name == 'car') or (vehicle.name == 'tank') or (vehicle.name == 'locomotive')) then
        move_multiple(inventory, vehicle, {'nuclear-fuel', 'rocket-fuel', 'solid-fuel', 'coal', 'wood'}, 50)
    end

    if ((vehicle.name == 'car') or (vehicle.name == 'tank')) then
        move_multiple(
            inventory,
            vehicle,
            {'uranium-rounds-magazine', 'piercing-rounds-magazine', 'firearm-magazine'},
            autofill_amount
        )
    end

    if (vehicle.name == 'tank') then
        move_multiple(
            inventory,
            vehicle,
            {'explosive-uranium-cannon-shell', 'uranium-cannon-shell', 'explosive-cannon-shell', 'cannon-shell'},
            autofill_amount
        )
    end
end

local function on_entity_built(event)
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    local ce = event.created_entity
    if not (ce and ce.valid) then
        return
    end

    if (valid_chest[ce.name] and valid_chest[ce.name].valid) then
        if this.globally_enabled then
            if (this.refill_chests.placed < valid_chest[ce.name].limit) then
                if this.message_limit[player.index] then
                    this.message_limit[player.index] = nil
                end
                Public.add_chest_to_refill_callback(nil, ce)
            else
                if not this.message_limit[player.index] then
                    this.message_limit[player.index] = true
                    player.print('[Autofill] Chest limit reached.', Color.warning)
                end
            end
        else
            local player_data = get_player_data(player)
            if (player_data.placed < valid_chest[ce.name].limit) then
                if this.message_limit[player.index] then
                    this.message_limit[player.index] = nil
                end
                Public.add_chest_to_refill_callback(player, ce)
            else
                if not this.message_limit[player.index] then
                    this.message_limit[player.index] = true
                    player.print('[Autofill] Chest limit reached.', Color.warning)
                end
            end
        end
    end

    if (valid_turrets[ce.name]) then
        if this.globally_enabled then
            Public.refill_turret_callback(nil, ce)
        else
            Public.refill_turret_callback(player, ce)
        end
        auto_insert_into_turret(player, ce)
    end

    if ((ce.name == 'car') or (ce.name == 'tank') or (ce.name == 'locomotive')) then
        auto_insert_into_vehicle(player, ce)
    end
end

local function on_pre_player_mined_item(event)
    local player = game.get_player(event.player_index)

    if not validate_entity(player) then
        return
    end

    local entity = event.entity
    if not validate_entity(entity) then
        return
    end

    if not valid_turrets[entity.name] then
        return
    end

    if this.globally_enabled then
        local chest = get_valid_chest()

        if not chest then
            return
        end

        local refill_turrets = this.refill_turrets
        local full_turrets = this.full_turrets

        if contains(refill_turrets, entity) or contains(full_turrets, entity) then
            remove_ammo(chest, entity)
        end
        return
    end

    local chest = get_valid_chest(player)

    if not chest then
        return
    end

    local refill_turrets = this.refill_turrets
    local full_turrets = this.full_turrets

    if contains(refill_turrets, entity) or contains(full_turrets, entity) then
        remove_ammo(chest, entity)
    end
end

local function on_tick()
    do_refill_turrets()
end

Public.refill_turret_callback = function(player, turret)
    if this.globally_enabled then
        local refill_turrets = this.refill_turrets
        if turret and turret.valid then
            refill_turrets[#refill_turrets + 1] = turret
        end
        return
    end
    if turret and turret.valid then
        local player_data = get_player_data(player)
        local turrets = player_data.turrets
        insert(turrets, turret)
    end
end

Public.add_chest_to_refill_callback = function(player, entity)
    if entity and entity.valid then
        if this.globally_enabled then
            local refill_chests = this.refill_chests
            refill_chests[#refill_chests + 1] = entity
            refill_chests.placed = refill_chests.placed + 1
        else
            local player_data = get_player_data(player)
            local chest_placed = player_data.placed
            local chests = player_data.chests

            insert(chests, entity)

            player_data.placed = chest_placed + 1
        end

        rendering.draw_text {
            text = '⚙',
            surface = entity.surface,
            target = entity,
            target_offset = {0, -0.5},
            scale = 1.5,
            color = {r = 0, g = 0.6, b = 1},
            alignment = 'center'
        }
    end
end

Event.add(defines.events.on_built_entity, on_entity_built)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.on_nth_tick(50, on_tick)

return Public
