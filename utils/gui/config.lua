local FlyingText = require 'utils.functions.flying_texts'
local Event = require 'utils.event'
local Utils = require 'utils.core'
local SpamProtection = require 'utils.spam_protection'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local PlayerSettings = require 'utils.gui.player_settings'
local Style = require 'utils.gui_style'
local Task = require 'utils.task_token'

local module_name = Gui.uid_name()

local Public = {}
local module_order = {}
local refresh_local_settings

local this =
{
    gui_config =
    {
        spaghett =
        {
            undo = {}
        },
        poll_trusted = false
    },
    scenario_registry = {},
    spectators = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local spaghett_entity_blacklist =
{
    ['requester-chest'] = true,
    ['buffer-chest'] = true,
    ['active-provider-chest'] = true
}

function Public.register_scenario_module(data)
    assert(data.id, "Scenario module requires id")
    if not this.scenario_registry[data.id] then
        module_order[#module_order + 1] = data.id
    end
    this.scenario_registry[data.id] = data
end

local function handle_registered_event(event, player)
    for _, mod in pairs(this.scenario_registry) do
        if mod.handlers and mod.handlers[event.element.name] then
            local handler = Task.get(mod.handlers[event.element.name])
            if handler then
                handler(player, event)
                if not mod.admin_only then
                    refresh_local_settings(player)
                end
                return
            end
        end
    end
end

local function get_actor(event, prefix, msg, admins_only, locale_key)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    if admins_only then
        Utils.print_admins(msg, player.name, locale_key and { locale_key })
    else
        Utils.action_warning(prefix, player.name .. ' ' .. msg, locale_key and { locale_key, player.name })
    end
end

local function spaghett_deny_building(event)
    local spaghett = this.gui_config.spaghett
    if not spaghett.enabled then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not spaghett_entity_blacklist[event.entity.name] then
        return
    end

    if event.player_index then
        game.get_player(event.player_index).insert({ name = entity.name, count = 1 })
    else
        local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
        inventory.insert({ name = entity.name, count = 1 })
    end

    FlyingText.flying_text(event.player_index and game.get_player(event.player_index) or nil, event.entity.surface, entity.position, 'Spaghett Mode Active!', { r = 0.98, g = 0.66, b = 0.22 })

    entity.destroy()
end

local function spaghett()
    local spaghetti = this.gui_config.spaghett
    if spaghetti.noop then
        return
    end
    if spaghetti.enabled then
        for _, f in pairs(game.forces) do
            if f.technologies['logistic-system'].researched then
                spaghetti.undo[f.index] = true
            end
            f.technologies['logistic-system'].enabled = false
            f.technologies['logistic-system'].researched = false
        end
    else
        for _, f in pairs(game.forces) do
            f.technologies['logistic-system'].enabled = true
            if spaghetti.undo[f.index] then
                f.technologies['logistic-system'].researched = true
                spaghetti.undo[f.index] = nil
            end
        end
    end
end

local functions =
{
    ['spectator_switch'] = function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        if event.element.switch_state == 'left' then
            if player.controller_type ~= defines.controllers.spectator and player.character then
                this.spectators[player.index] = player.character
                player.set_controller({ type = defines.controllers.spectator })
            end
        else
            if player.controller_type == defines.controllers.spectator then
                local character = this.spectators[player.index]
                if character and character.valid then
                    player.set_controller({ type = defines.controllers.character, character = character })
                else
                    player.set_controller({ type = defines.controllers.god })
                    player.create_character()
                end
                this.spectators[player.index] = nil
            end
        end
    end,
    ['auto_hotbar_switch'] = function (event)
        if event.element.switch_state == 'left' then
            storage.auto_hotbar_enabled[event.player_index] = true
        else
            storage.auto_hotbar_enabled[event.player_index] = false
        end
    end,
    ['blueprint_toggle'] = function (event)
        if event.element.switch_state == 'left' then
            game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui, true)
            game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, true)
            get_actor(event, '[Blueprints]', 'has enabled blueprints!')
        else
            game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui, false)
            game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, false)
            get_actor(event, '[Blueprints]', 'has disabled blueprints!')
        end
    end,
    ['spaghett_toggle'] = function (event)
        if event.element.switch_state == 'left' then
            this.gui_config.spaghett.enabled = true
            get_actor(event, '[Spaghett]', 'has enabled spaghett mode!')
        else
            this.gui_config.spaghett.enabled = nil
            get_actor(event, '[Spaghett]', 'has disabled spaghett mode!')
        end
        spaghett()
    end
}

local pirates_functions =
{
    ['toggle_disband'] = function (event)
        local players = game.players
        local Memory = storage.tokens.maps_pirates_memory
        if event.element.switch_state == 'left' then
            Memory.disband_crews = true
            for _, player in pairs(players) do
                local gui = player.gui.screen['crew_piratewindow']
                if gui and gui.valid then
                    gui.destroy()
                end
            end
            get_actor(event, '[Pirates]', 'has enabled the ability to disband crews.')
        else
            Memory.disband_crews = false
            for _, player in pairs(players) do
                local gui = player.gui.screen['crew_piratewindow']
                if gui and gui.valid then
                    gui.destroy()
                end
            end
            get_actor(event, '[Pirates]', 'has disabled the ability to disband crews.')
        end
    end
}

local function add_switch(element, switch_state, name, description_main, description)
    local row = Style.toolbar(element)
    row.style.minimal_height = Style.dimensions.row_height
    row.style.horizontally_stretchable = true

    local details = row.add({ type = 'flow', direction = 'vertical' })
    local row_width = element.tags.row_width
    local text_width
    if row_width then
        row.style.width = row_width
        text_width = row_width - 104
        details.style.width = text_width
    else
        details.style.horizontally_stretchable = true
        text_width = math.max(120, element.style.minimal_width - 2 * Style.spacing.md - 110)
    end
    local title = Style.text(details, description_main, text_width)
    title.style.font = 'default-semibold'
    Style.text(details, description, text_width, Style.colors.muted)

    local switch = row.add({
        type = 'switch',
        name = name,
        left_label_caption = 'ON',
        right_label_caption = 'OFF',
        switch_state = switch_state
    })

    return switch
end

local function draw_modules(player, rows, admin_only)
    for _, id in ipairs(module_order) do
        local mod = this.scenario_registry[id]
        if mod and mod.gui_rows and (mod.admin_only or false) == admin_only then
            local render = Task.get(mod.gui_rows)
            if render then
                render(player, rows)
            end
        end
    end
end

local function draw_local_settings(player, rows)
    local switch_state = player.controller_type == defines.controllers.spectator and 'left' or 'right'
    add_switch(rows, switch_state, 'spectator_switch', { 'gui.spectator_mode' }, { 'gui-description.spectator_mode' })

    if storage.auto_hotbar_enabled then
        switch_state = storage.auto_hotbar_enabled[player.index] and 'left' or 'right'
        add_switch(rows, switch_state, 'auto_hotbar_switch', 'AutoHotbar', 'Automatically fills your hotbar with placeable items.')
    end
    draw_modules(player, rows, false)
end

refresh_local_settings = function (player)
    local frame = Gui.get_player_active_frame(player)
    local section = frame and frame.comfy_config_local
    if section then
        Gui.clear(section.settings_rows)
        draw_local_settings(player, section.settings_rows)
    end
end

local function add_section(frame, name, caption, width)
    local section = frame.add({ type = 'flow', name = name, direction = 'vertical', tags = { width = width } })
    section.style.vertical_spacing = Style.spacing.xs
    section.style.bottom_margin = Style.spacing.md
    Style.heading(section, caption)
    return section
end

local function build_config_gui(data)
    local player = data.player
    if not player then return end
    local frame = data.frame

    Gui.clear(frame)

    local width = Style.content_width(player, frame)
    local section = add_section(frame, 'comfy_config_local', { 'gui.config_local_settings' }, width)
    draw_local_settings(player, Style.settings_table(section, 'settings_rows', width))

    section = add_section(frame, 'comfy_config_server', { 'gui.config_server_settings' }, width)
    PlayerSettings.refresh(player, section)

    if not player.admin then
        return
    end
    section = add_section(frame, 'comfy_config_admin', { 'gui.config_admin_settings' }, width)
    local rows = Style.settings_table(section, 'settings_rows', width)
    local allowed = game.permissions.get_group('Default').allows_action(defines.input_action.open_blueprint_library_gui)
    add_switch(rows, allowed and 'left' or 'right', 'blueprint_toggle', 'Blueprint Library', 'Toggles the usage of blueprint strings and the library.')
    add_switch(rows, this.gui_config.spaghett.enabled and 'left' or 'right', 'spaghett_toggle', { 'gui.spaghett_mode' }, { 'gui-description.spaghett_mode' })
    draw_modules(player, rows, true)

    local memory = storage.tokens.maps_pirates_memory
    if memory then
        add_switch(rows, memory.disband_crews and 'left' or 'right', 'toggle_disband', 'Disband Crews', 'Allows crews to disband.')
    end
end

local build_config_gui_token = Token.register(build_config_gui)

local function on_gui_switch_state_changed(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end



    if functions[event.element.name] then
        local name = event.element.name
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Config Functions Elem')
        if not is_spamming then
            functions[name](event)
        end
        if name == 'spectator_switch' then
            refresh_local_settings(player)
        end
        return
    elseif pirates_functions[event.element.name] then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Config Pirates Elem')
        if is_spamming then
            return
        end
        pirates_functions[event.element.name](event)
        return
    end

    handle_registered_event(event, player)
end

local function on_force_created()
    spaghett()
end

local function on_built_entity(event)
    spaghett_deny_building(event)
end

local function on_robot_built_entity(event)
    spaghett_deny_building(event)
end

Gui.add_tab_to_gui({ name = module_name, caption = 'Config', id = build_config_gui_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Config')
    end
)

Event.add(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)
Event.add(defines.events.on_force_created, on_force_created)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Public.add_switch = add_switch
Public.get_actor = get_actor
Public.register_token = Task.register
return Public
