--module by Hanakocz
local Event = require 'utils.event'
local Global = require 'utils.global'
local Public = {}

local this = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local function on_gui_closed(event)
    local player_index = event.player_index
    if this[player_index] and this[player_index].disabled then return end -- player disabled usage of this module in config tab for his actions
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name == 'logistic-chest-requester' or entity.name == 'logistic-chest-buffer' then
        if not this[player_index] or not this[player_index].notified then
            local player = game.get_player(player_index)
            player.print({'modules.blueprint_requesting_notify'}, {r= 0.88, g = 0.66, b = 0.02})
            this[player_index] = this[player_index] or {}
            this[player_index].notified = true
        end
        local inventory = entity.get_inventory(defines.inventory.chest)
        if not inventory or not inventory.valid then return end
        if inventory.get_item_count('blueprint') > 0 then
            local items = {}
            for i = 1, #inventory, 1 do
                if inventory[i].valid_for_read and inventory[i].is_blueprint then
                    local cost = inventory[i].cost_to_build
                    for name, amount in pairs(cost) do
                        items[name] = (items[name] or 0) + amount
                    end
                end
            end
            if entity.request_slot_count > 0 then
                for slot = 1, entity.request_slot_count, 1 do
                    entity.clear_request_slot(slot)
                end
            end
            local slot_index = 1
            for item, amount in pairs(items) do
                entity.set_request_slot({name = item, count = amount}, slot_index)
                slot_index = slot_index + 1
            end
        end
    end
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

Event.add(defines.events.on_gui_closed, on_gui_closed)

return Public
