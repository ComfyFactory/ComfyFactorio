local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Utils = require 'utils.core'
local SpamProtection = require 'utils.spam_protection'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Task = require 'utils.task_token'

local module_name = Gui.uid_name()

local Public = {}

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
    scenario_registry = {}
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
    this.scenario_registry[data.id] = data
end

local function handle_registered_event(event, player)
    for _, mod in pairs(this.scenario_registry) do
        if mod.handlers and mod.handlers[event.element.name] then
            local handler = Task.get(mod.handlers[event.element.name])
            if handler then
                handler(player, event)
                return
            end
        end
    end
end

local function get_actor(event, prefix, msg, admins_only)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    if admins_only then
        Utils.print_admins(msg, player.name)
    else
        Utils.action_warning(prefix, player.name .. ' ' .. msg)
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

    event.entity.surface.create_entity(
        {
            name = 'flying-text',
            position = entity.position,
            text = 'Spaghett Mode Active!',
            color = { r = 0.98, g = 0.66, b = 0.22 }
        }
    )

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
        if event.element.switch_state == 'left' then
            game.get_player(event.player_index).spectator = true
        else
            game.get_player(event.player_index).spectator = false
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
    local t = element.add({ type = 'table', column_count = 5 })
    local on_label = t.add({ type = 'label', caption = 'ON' })
    on_label.style.padding = 0
    on_label.style.left_padding = 10
    on_label.style.font_color = { 0.77, 0.77, 0.77 }
    local switch = t.add({ type = 'switch', name = name })
    switch.switch_state = switch_state
    switch.style.padding = 0
    switch.style.margin = 0
    local off_label = t.add({ type = 'label', caption = 'OFF' })
    off_label.style.padding = 0
    off_label.style.font_color = { 0.70, 0.70, 0.70 }

    local desc_main_label = t.add({ type = 'label', caption = description_main })
    desc_main_label.style.padding = 2
    desc_main_label.style.left_padding = 10
    desc_main_label.style.minimal_width = 120
    desc_main_label.style.font = 'heading-2'
    desc_main_label.style.font_color = { 0.88, 0.88, 0.99 }

    local desc_label = t.add({ type = 'label', caption = description })
    desc_label.style.padding = 2
    desc_label.style.left_padding = 10
    desc_label.style.single_line = false
    desc_label.style.font = 'default-semibold'
    desc_label.style.font_color = { 0.85, 0.85, 0.85 }

    return switch
end

local function build_config_gui(data)
    local player = data.player
    if not player then return end
    local frame = data.frame

    local switch_state
    local label

    local admin = player.admin
    frame.clear()

    local scroll_pane =
        frame.add
        {
            type = 'scroll-pane',
            horizontal_scroll_policy = 'never'
        }
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.minimal_height = 350
    scroll_style.bottom_padding = 2
    scroll_style.left_padding = 2
    scroll_style.right_padding = 2
    scroll_style.top_padding = 2

    label = scroll_pane.add({ type = 'label', caption = 'Player Settings' })
    label.style.font = 'default-bold'
    label.style.padding = 0
    label.style.left_padding = 10
    label.style.horizontal_align = 'left'
    label.style.vertical_align = 'bottom'
    label.style.font_color = { 0.55, 0.55, 0.99 }

    scroll_pane.add({ type = 'line' })

    switch_state = 'right'
    if player.spectator then
        switch_state = 'left'
    end
    add_switch(scroll_pane, switch_state, 'spectator_switch', { 'gui.spectator_mode' }, { 'gui-description.spectator_mode' })

    scroll_pane.add({ type = 'line' })

    if storage.auto_hotbar_enabled then
        switch_state = 'right'
        if storage.auto_hotbar_enabled[player.index] then
            switch_state = 'left'
        end
        add_switch(scroll_pane, switch_state, 'auto_hotbar_switch', 'AutoHotbar', 'Automatically fills your hotbar with placeable items.')
        scroll_pane.add({ type = 'line' })
    end

    for _, mod in pairs(this.scenario_registry) do
        if mod.gui_rows and not mod.admin_only then
            local handler = Task.get(mod.gui_rows)
            if handler then
                handler(player, scroll_pane)
            end
        end
    end

    if admin then
        label = scroll_pane.add({ type = 'label', caption = 'Admin Settings' })
        label.style.font = 'default-bold'
        label.style.padding = 0
        label.style.left_padding = 10
        label.style.top_padding = 10
        label.style.horizontal_align = 'left'
        label.style.vertical_align = 'bottom'
        label.style.font_color = { 0.77, 0.11, 0.11 }

        scroll_pane.add({ type = 'line' })

        for _, mod in pairs(this.scenario_registry) do
            if mod.gui_rows and mod.admin_only then
                local handler = Task.get(mod.gui_rows)
                if handler then
                    handler(player, scroll_pane)
                end
            end
        end

        switch_state = 'right'
        if game.permissions.get_group('Default').allows_action(defines.input_action.open_blueprint_library_gui) then
            switch_state = 'left'
        end
        add_switch(scroll_pane, switch_state, 'blueprint_toggle', 'Blueprint Library', 'Toggles the usage of blueprint strings and the library.')

        scroll_pane.add({ type = 'line' })

        switch_state = 'right'
        if this.gui_config.spaghett.enabled then
            switch_state = 'left'
        end
        add_switch(scroll_pane, switch_state, 'spaghett_toggle', { 'gui.spaghett_mode' }, { 'gui-description.spaghett_mode' })

        scroll_pane.add({ type = 'line' })

        if storage.tokens.maps_pirates_memory then
            label = scroll_pane.add({ type = 'label', caption = 'Pirates Settings' })
            label.style.font = 'default-bold'
            label.style.padding = 0
            label.style.left_padding = 10
            label.style.top_padding = 10
            label.style.horizontal_align = 'left'
            label.style.vertical_align = 'bottom'
            label.style.font_color = Color.green

            local Memory = storage.tokens.maps_pirates_memory
            switch_state = 'right'
            if Memory.disband_crews then
                switch_state = 'left'
            end
            add_switch(scroll_pane, switch_state, 'toggle_disband', 'Disband Crews', 'On = Enables crew disband.\nOff = Disables crew disband.')
        end
    end
    for _, e in pairs(scroll_pane.children) do
        if e.type == 'line' then
            e.style.padding = 0
            e.style.margin = 0
        end
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
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Config Functions Elem')
        if is_spamming then
            return
        end
        functions[event.element.name](event)
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
