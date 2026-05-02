-- created by Gerkiz for ComfyFactorio
-- Handles player RPG settings.
local Global = require 'utils.global'
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local RPG = require 'modules.rpg.table'
local Spells = require 'modules.rpg.spells'
local Color = require 'utils.color_presets'
local Commands = require 'utils.commands'

local Public = {}

local this =
{
    settings =
    {
        enabled = true,
        dataset = 'rpg_settings_dataset',
    },
    data = {}
}

local set_data = Server.set_data
local try_get_data = Server.try_get_data

local rpg_settings_keys =
{
    'dropdown_select_name',
    'dropdown_select_name_1',
    'dropdown_select_name_2',
    'dropdown_select_name_3',
    'spell_slot_count',
    -- 'allocate_index',
    'enable_entity_spawn',
    'show_bars',
    'stone_path',
    'show_lvl_txt',
    'crafting_chance',
    'quality_crafting_chance',
    'show_notification',
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function build_settings_from_player(player)
    local rpg_t = RPG.get_value_from_player(player.index)
    if not rpg_t or type(rpg_t) ~= 'table' then
        return nil
    end
    local out = {}
    for _, k in ipairs(rpg_settings_keys) do
        local v = rpg_t[k]
        if v ~= nil then
            if type(v) == 'table' then
                out[k] = {}
                for k2, v2 in pairs(v) do
                    out[k][k2] = v2
                end
            else
                out[k] = v
            end
        end
    end
    if next(out) then
        return out
    end
    return nil
end

local function apply_settings_to_player(player, saved)
    if not saved or type(saved) ~= 'table' then
        return
    end
    local rpg_t = RPG.get_value_from_player(player.index)
    if not rpg_t or type(rpg_t) ~= 'table' then
        return
    end
    for k, v in pairs(saved) do
        if k == 'show_lvl_txt' then
            RPG.draw_level_text(player)
        end

        if string.sub(k, 1, 21) == 'dropdown_select_name_' then
            local spell, spell_index = Spells.has_enough_level_to_access_spell(rpg_t, v)
            if spell and spell_index then
                RPG.set_value_to_player(player.index, k, v)
                local index_key = 'dropdown_select_index_' .. string.sub(k, 22)
                RPG.set_value_to_player(player.index, index_key, spell_index)
            end
        else
            if k == 'spell_slot_count' then
                v = RPG.get_spell_slot_count({ spell_slot_count = v })
            end
            RPG.set_value_to_player(player.index, k, v)
        end
    end
    RPG.clamp_active_spell_to_visible_slots(rpg_t)
end

local fetch_rpg_settings_token =
    Token.register(
        function (data)
            local key = data.key
            local value = data.value
            local player = game.get_player(key)
            if not player or not player.valid then
                return
            end
            if value and type(value) == 'table' then
                apply_settings_to_player(player, value)
                this.data[player.name] = value
            end
        end
    )

function Public.save_rpg_settings(player)
    if not this.settings.enabled then
        return
    end
    if not player or not player.valid then
        return
    end
    local secs = Server.get_current_time()
    if secs == nil or secs == false then
        return
    end
    local value = build_settings_from_player(player)
    if not value then
        return
    end
    set_data(this.settings.dataset, player.name, value)
    this.data[player.name] = value
end

function Public.remove_rpg_settings(player)
    if not player or not player.valid then
        return
    end
    set_data(this.settings.dataset, player.name, nil)
    this.data[player.name] = nil
end

function Public.fetch_rpg_settings(player)
    if not this.settings.enabled then
        return
    end
    local secs = Server.get_current_time()
    if secs == nil or secs == false then
        return
    end
    try_get_data(this.settings.dataset, player.name, fetch_rpg_settings_token)
end

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        if not this.settings.enabled then
            return
        end
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end
        Public.fetch_rpg_settings(player)
    end
)

Commands.new('save-rpg-settings', 'Save your RPG settings to the datastore.')
    :require_backend()
    :callback(
        function (player)
            local rpg_t = RPG.get_value_from_player(player.index)
            if not rpg_t or type(rpg_t) ~= 'table' then
                return
            end
            if rpg_t.level < 100 then
                RPG.display_notification(player, 'You need to be at least level 100 to save your RPG settings.', Color.error)
                return
            end

            Public.save_rpg_settings(player)
            RPG.display_notification(player, 'RPG settings saved.', Color.success)
        end
    )

Commands.new('remove-rpg-settings', 'Removes your RPG settings from the datastore.')
    :require_backend()
    :callback(
        function (player)
            Public.remove_rpg_settings(player)
            RPG.display_notification(player, 'RPG settings removed.', Color.success)
        end
    )

Commands.new('restore-rpg-settings', 'Restores your RPG settings from the datastore.')
    :require_backend()
    :callback(
        function (player)
            Public.fetch_rpg_settings(player)
            RPG.display_notification(player, 'RPG settings restored.', Color.success)
        end
    )

function Public.set_module_state(state)
    this.settings.enabled = state or false
end

function Public.get_module_state()
    return this.settings.enabled
end

return Public
