local event = require 'utils.event'
local function compute_fullness(player)
    local inv = player.get_inventory(defines.inventory.character_main)
    local max_stacks = #inv
    local num_stacks = 0

    local contents = inv.get_contents()
    for item, count in pairs(contents) do
        local stack_size = 1
        if game.item_prototypes[item].stackable then
            stack_size = game.item_prototypes[item].stack_size
        end

        num_stacks = num_stacks + count / stack_size
    end

    return num_stacks / max_stacks
end

local function check_burden(event)
    local player = game.players[event.player_index]
    local fullness = compute_fullness(player)
    player.character_running_speed_modifier = 0.5 - fullness
end


local function on_init(event)
    script.on_event(defines.events.on_player_main_inventory_changed, check_burden)
end

local function on_load(event)
    script.on_event(defines.events.on_player_main_inventory_changed, check_burden)
end

event.on_init(on_init)
event.on_load(on_load)
