local Color = require 'utils.color_presets'
local Event = require 'utils.event'

local autofill_amount = 10

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
        {'uranium-rounds-magazine', 'piercing-rounds-magazine', 'firearm-magazine'},
        autofill_amount
    )

    if (ret > 1) then
        show_text('Inserted ' .. ret .. '!', turret.position, Color.info, player.surface)
    elseif (ret == -1) then
        show_text('Out of ammo!', turret.position, Color.red, player.surface)
    elseif (ret == -2) then
        show_text('Autofill ERROR! - Report this bug!', turret.position, Color.red, player.surface)
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
    local eventEntity = event.created_entity
    if not (eventEntity and eventEntity.valid) then
        return
    end

    if (player.character == nil) then
        return
    end

    if (eventEntity.name == 'gun-turret') then
        auto_insert_into_turret(player, eventEntity)
    end

    if ((eventEntity.name == 'car') or (eventEntity.name == 'tank') or (eventEntity.name == 'locomotive')) then
        auto_insert_into_vehicle(player, eventEntity)
    end
end

Event.add(defines.events.on_built_entity, on_entity_built)
