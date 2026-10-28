--luacheck: ignore
local event = require 'utils.event'

local function quickbar_page_and_slot(player, index)
    local width = player.quick_bar_width
    if not width or width < 1 then width = 10 end
    local page = math.floor((index - 1) / width) + 1
    local slot = (index - 1) % width + 1
    return page, slot
end

local function get_quick_bar_slot(player, index)
    local page, slot = quickbar_page_and_slot(player, index)
    local value = player.get_quick_bar_slot(page, slot)
    if value and value.type == 'filter' and value.filter and value.filter.name then
        return value
    end
end

local function set_quick_bar_slot(player, index, filter)
    local page, slot = quickbar_page_and_slot(player, index)
    player.set_quick_bar_slot(page, slot, filter)
end

local function get_empty_hotbar_slot(player)
    for i = 1, 20, 1 do
        local slot = get_quick_bar_slot(player, i)
        if slot then
            return i
        end
    end
    return false
end

local function is_item_already_present_in_hotbar(player, item)
    for i = 1, 20, 1 do
        local slot = get_quick_bar_slot(player, i)
        if slot then
            if item == slot.filter.name then
                return true
            end
        end
    end
    return false
end

local function set_hotbar(player, item)
    if not prototypes.entity[item] then
        return
    end
    if not prototypes.recipe[item] then
        return
    end
    local slot_index = get_empty_hotbar_slot(player)
    if not slot_index then
        return
    end
    if is_item_already_present_in_hotbar(player, item) then
        return
    end
    set_quick_bar_slot(player, slot_index, item)
end

local function on_player_fast_transferred(event)
    if not storage.auto_hotbar_enabled[event.player_index] then
        return
    end
    local player = game.players[event.player_index]
    for name, count in pairs(player.get_main_inventory().get_contents()) do
        set_hotbar(player, name)
    end
end

local function on_player_crafted_item(event)
    if not storage.auto_hotbar_enabled[event.player_index] then
        return
    end
    set_hotbar(game.players[event.player_index], event.item_stack.name)
end

local function on_picked_up_item(event)
    if not storage.auto_hotbar_enabled[event.player_index] then
        return
    end
    set_hotbar(game.players[event.player_index], event.item_stack.name)
end

local function on_player_mined_entity(event)
    if not storage.auto_hotbar_enabled[event.player_index] then
        return
    end
    set_hotbar(game.players[event.player_index], event.entity.name)
end

local function on_init()
    storage.auto_hotbar_enabled = {}
end

event.on_init(on_init)
event.add(defines.events.on_player_fast_transferred, on_player_fast_transferred)
event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
event.add(defines.events.on_picked_up_item, on_picked_up_item)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
