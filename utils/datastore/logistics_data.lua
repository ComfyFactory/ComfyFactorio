local Token = require 'utils.token'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Event = require 'utils.event'

local logistics_dataset = 'logistics'
local logistics_dataset_modded = 'logistics_modded'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}

local function is_game_modded()
    local i = 0
    for k, _ in pairs(game.active_mods) do
        i = i + 1
        if i > 1 then
            return true
        end
    end
    return false
end

local fetch =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = game.players[key]
        if not player or not player.valid then
            return
        end
        if value then
            for i, item_name in pairs(value) do
                if item_name ~= nil and item_name ~= '' then
                    player.set_personal_logistic_slot(i, item_name)
                end
            end
        end
    end
)

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    local secs = Server.get_current_time()
    local dataset = logistics_dataset
    if not secs then
        local player = game.players[key]
        if not player or not player.valid then
            return
        end
        return
    else
        local game_has_mods = is_game_modded()
        if game_has_mods then
            dataset = logistics_dataset_modded
        end

        try_get_data(dataset, key, fetch)
    end
end

commands.add_command(
    'save-logistics',
    'Save your personal logistics preset so it´s always the same.',
    function()
        local player = game.player
        if not player or not player.valid then
            return
        end

        local secs = Server.get_current_time()
        if not secs then
            return
        end

        local dataset = logistics_dataset

        local game_has_mods = is_game_modded()
        if game_has_mods then
            dataset = logistics_dataset_modded
        end

        local slots = {}

        for i = 1, 100 do
            local slot = player.get_personal_logistic_slot(i)
            if slot ~= nil then
                slots[i] = slot.name
            end
        end
        if next(slots) then
            set_data(dataset, player.name, slots)
            player.print('Your personal logistics has been saved.', Color.success)
        end
    end
)

commands.add_command(
    'remove-logistics',
    'Removes your personal logistics preset from the datastore.',
    function()
        local player = game.player
        if not player or not player.valid then
            return
        end

        local dataset = logistics_dataset

        local game_has_mods = is_game_modded()
        if game_has_mods then
            dataset = logistics_dataset_modded
        end

        set_data(dataset, player.name, nil)
        player.print('Your personal logistics has been removed.', Color.success)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.fetch(player.name)
    end
)

return Public
