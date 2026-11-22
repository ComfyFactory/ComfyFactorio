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
local PlayerSettings = require 'utils.gui.player_settings'

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

local MAX_SPELL_SLOTS = 8
local dataset = this.settings.dataset

local rpg_settings_keys =
{
    'dropdown_select_name',
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

local setting_labels =
{
    dropdown_select_name = 'Active spell',
    spell_slot_count = 'Spell slots',
    enable_entity_spawn = 'Spell casting',
    show_bars = 'Health and mana bars',
    stone_path = 'Stone path',
    show_lvl_txt = 'Level text',
    crafting_chance = 'Crafting bonuses',
    quality_crafting_chance = 'Quality crafting bonuses',
    show_notification = 'Notifications'
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function copy_setting_value(out, k, v)
    if v == nil then
        return
    end
    if type(v) == 'table' then
        out[k] = {}
        for k2, v2 in pairs(v) do
            out[k][k2] = v2
        end
    else
        out[k] = v
    end
end

local function spell_slot_name_key(slot)
    return 'dropdown_select_name_' .. slot
end

local function get_spell_slot_from_name_key(k)
    local slot = tonumber(string.match(k, '^dropdown_select_name_(%d+)$'))
    if slot and slot >= 1 and slot <= MAX_SPELL_SLOTS then
        return slot
    end
    return nil
end

local function build_settings_from_player(player)
    local rpg_t = RPG.get_value_from_player(player.index)
    if not rpg_t or type(rpg_t) ~= 'table' then
        return nil
    end
    local out = {}
    for _, k in ipairs(rpg_settings_keys) do
        copy_setting_value(out, k, rpg_t[k])
    end
    for slot = 1, MAX_SPELL_SLOTS do
        copy_setting_value(out, spell_slot_name_key(slot), rpg_t[spell_slot_name_key(slot)])
    end
    if next(out) then
        return out
    end
    return nil
end

local function apply_settings_to_player(player, saved)
    if not saved or type(saved) ~= 'table' then
        return false
    end
    local rpg_t = RPG.get_value_from_player(player.index)
    if not rpg_t or type(rpg_t) ~= 'table' then
        return false
    end
    for k, v in pairs(saved) do
        local slot = get_spell_slot_from_name_key(k)
        if slot then
            local spell, spell_index = Spells.has_enough_level_to_access_spell(rpg_t, v)
            if spell and spell_index then
                RPG.set_value_to_player(player.index, k, v)
                RPG.set_value_to_player(player.index, 'dropdown_select_index_' .. slot, spell_index)
            end
        else
            if k == 'spell_slot_count' then
                v = RPG.get_spell_slot_count({ spell_slot_count = v })
            end
            RPG.set_value_to_player(player.index, k, v)
        end
    end
    RPG.clamp_active_spell_to_visible_slots(rpg_t)
    if saved.show_lvl_txt ~= nil then
        RPG.draw_level_text(player)
    end
    return true
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
    return value
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

local function save_player_preset(player)
    local rpg_t = RPG.get_value_from_player(player.index)
    if not rpg_t or type(rpg_t) ~= 'table' then
        return
    end
    if rpg_t.level < 100 then
        return nil, { 'gui.player_settings_rpg_level' }
    end
    return Public.save_rpg_settings(player)
end

local function setting_text(value)
    if type(value) == 'table' then
        return table.concat(value, ' ')
    end
    if type(value) == 'boolean' then
        return value and 'On' or 'Off'
    end
    return tostring(value)
end

PlayerSettings.register('rpg', dataset, {
    available = function () return this.settings.enabled end,
    save = save_player_preset,
    remove = Public.remove_rpg_settings,
    apply = apply_settings_to_player,
    describe = function (value)
        local lines = {}
        for _, key in ipairs(rpg_settings_keys) do
            if value[key] ~= nil then
                lines[#lines + 1] = setting_labels[key] .. '  ' .. setting_text(value[key])
            end
        end
        for slot = 1, MAX_SPELL_SLOTS do
            local spell = value[spell_slot_name_key(slot)]
            if spell then
                lines[#lines + 1] = 'Spell ' .. slot .. '  ' .. setting_text(spell)
            end
        end
        return table.concat(lines, '\n')
    end
})

Commands.new('save-rpg-settings', 'Save your RPG settings to the datastore.')
    :require_backend()
    :callback(
        function (player)
            local value, err = save_player_preset(player)
            if value then
                RPG.display_notification(player, 'RPG settings saved.', Color.success)
            elseif err then
                RPG.display_notification(player, 'You need to be at least level 100 to save your RPG settings.', Color.error)
            end
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
