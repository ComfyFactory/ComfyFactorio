--Players will have to carry water barrels or stand next to a water tile, to keep themselves hydrated!

local Event = require 'utils.event'
local Player_modifiers = require 'utils.player_modifiers'
local random = math.random
local tooltip = 'How thirsty your character is.\nStand next to water,\nor keep water-barrels in your inventory to take a sip.'

local function update_player_modifiers(player)
    if storage.hydration[player.index] <= 0 then
        storage.hydration[player.index] = 100
        player.character.die()
        game.print(player.name .. ' forgot to take a sip.')
        return
    end

    local m = ((storage.hydration[player.index] - 100) * 0.01) + 0.2
    Player_modifiers.update_single_modifier(player, 'character_mining_speed_modifier', 'thirst', m)
    Player_modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'thirst', m)
    Player_modifiers.update_single_modifier(player, 'character_crafting_speed_modifier', 'thirst', m)
    Player_modifiers.update_player_modifiers(player)
end

local function update_hydration_meter(player)
    local hydration_meter = player.gui.top.hydration_meter

    if not hydration_meter then
        storage.hydration[player.index] = 100

        hydration_meter = player.gui.top.add({ type = 'frame', name = 'hydration_meter' })
        hydration_meter.style.padding = 3
        hydration_meter.tooltip = tooltip

        local label = hydration_meter.add({ type = 'label', caption = 'Hydration:' })
        label.style.font = 'heading-2'
        label.style.font_color = { 125, 125, 255 }
        label.tooltip = tooltip
        local label2 = hydration_meter.add({ type = 'label', caption = 100 })
        label2.style.font = 'heading-2'
        label2.style.font_color = { 175, 175, 175 }
        label2.tooltip = tooltip
        local label3 = hydration_meter.add({ type = 'label', caption = '%' })
        label3.style.font = 'heading-2'
        label3.style.font_color = { 175, 175, 175 }
        label3.tooltip = tooltip
        return
    end

    hydration_meter.children[2].caption = storage.hydration[player.index]
end

local function sip(player)
    if not storage.hydration[player.index] then
        return
    end
    if random(1, 4) == 1 then
        storage.hydration[player.index] = storage.hydration[player.index] - 1
    end
    if storage.hydration[player.index] == 100 then
        return
    end

    if
        player.surface.count_tiles_filtered(
            { name = { 'water', 'deepwater' }, area = { { player.position.x - 1, player.position.y - 1 }, { player.position.x + 1, player.position.y + 1 } } }
        ) > 0
    then
        storage.hydration[player.index] = storage.hydration[player.index] + 20
        if storage.hydration[player.index] > 100 then
            storage.hydration[player.index] = 100
        end
        return
    end

    if storage.hydration[player.index] > 90 then
        return
    end

    local inventory = player.get_main_inventory()
    local removed_count = inventory.remove({ name = 'water-barrel', count = 1 })
    if removed_count == 0 then
        return
    end

    storage.hydration[player.index] = storage.hydration[player.index] + 10
    player.play_sound { path = 'utility/armor_insert', volume_modifier = 0.9 }

    local inserted_count = inventory.insert({ name = 'barrel', count = 1 })
    if inserted_count > 0 then
        return
    end

    player.surface.spill_item_stack(player.position, { name = 'barrel', count = 1 }, true)
end

local function on_player_changed_position(event)
    if random(1, 320) ~= 1 then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    if player.vehicle then
        return
    end
    storage.hydration[player.index] = storage.hydration[player.index] - 1
end

local function on_player_died(event)
    if not storage.hydration[event.player_index] then
        return
    end
    storage.hydration[event.player_index] = 100
end

local function tick()
    for _, player in pairs(game.connected_players) do
        if player.character then
            if player.character.valid then
                sip(player)
                update_hydration_meter(player)
                update_player_modifiers(player)
            end
        end
    end
end

local function on_init()
    storage.hydration = {}
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_died, on_player_died)
Event.on_nth_tick(120, tick)
Event.on_init(on_init)
