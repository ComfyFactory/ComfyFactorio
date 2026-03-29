--luacheck: ignore 113
local Public = {}
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Modifiers = require 'utils.player_modifiers'
local Roles = require 'utils.role.main'
local Token = require 'utils.token'
local Task = require 'utils.task'

local main_view_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()

local force_settings =
{
    { type = 'slider', object = 'force', key = 'manual_mining_speed_modifier', name = 'mining-speed', min = 0, max = 1000 },
    {
        type = 'slider',
        object = 'force',
        key = 'manual_crafting_speed_modifier',
        name = 'craft-speed',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'force',
        key = 'character_running_speed_modifier',
        name = 'running-speed',
        min = 0,
        max = 10
    },
    {
        type = 'slider',
        object = 'force',
        key = 'character_build_distance_bonus',
        name = 'build-distance',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'force',
        key = 'character_reach_distance_bonus',
        name = 'reach-distance',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'force',
        key = 'worker_robots_speed_modifier',
        name = 'bot-speed',
        min = -1,
        max = 100
    },
    {
        type = 'slider',
        object = 'force',
        key = 'worker_robots_battery_modifier',
        name = 'bot-battery',
        min = -1,
        max = 100
    },
    {
        type = 'slider',
        object = 'force',
        key = 'worker_robots_storage_bonus',
        name = 'bot-storage',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'force',
        key = 'laboratory_speed_modifier',
        name = 'lab-speed',
        min = 0,
        max = 500
    },
    {
        type = 'slider',
        object = 'force',
        key = 'bulk_inserter_capacity_bonus',
        name = 'stack-bonus',
        min = 1,
        max = 1000
    },
    {
        type = 'slider',
        object = 'force',
        key = 'mining_drill_productivity_bonus',
        name = 'mining-prod',
        min = 0,
        max = 100
    }
}

local personal_settings =
{
    {
        type = 'slider',
        object = 'player',
        key = 'character_maximum_following_robot_count_bonus',
        name = 'robot-bonus',
        min = 0,
        max = 100
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_resource_reach_distance_bonus',
        name = 'reach-bonus',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_mining_speed_modifier',
        name = 'mining-speed',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_crafting_speed_modifier',
        name = 'craft-speed',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_running_speed_modifier',
        name = 'running-speed',
        min = 0,
        max = 10
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_build_distance_bonus',
        name = 'build-distance',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_reach_distance_bonus',
        name = 'reach-distance',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_inventory_slots_bonus',
        name = 'inventory-size',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_item_drop_distance_bonus',
        name = 'item-drop-distance',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_item_pickup_distance_bonus',
        name = 'item-pickup-distance',
        min = 0,
        max = 1000
    },
    {
        type = 'slider',
        object = 'player',
        key = 'character_loot_pickup_distance_bonus',
        name = 'loot-pickup-distance',
        min = 0,
        max = 320
    },
    { type = 'slider', object = 'player', key = 'character_health_bonus', name = 'health', min = 0, max = 5000 }
}

local advanced_settings =
{
    {
        type = 'slider',
        object = 'force',
        key = 'character_inventory_slots_bonus',
        name = 'inventory-size',
        min = 0,
        max = 1000
    },
    { type = 'slider', object = 'game', key = 'speed', name = 'game-speed', min = 0.5, max = 5 },
    { type = 'function', object = 'game', key = 'server_save', name = 'save' },
    { type = 'function', object = 'force', key = 'reset_technology_effects', name = 'reload-effects' },
    { type = 'function', object = 'enemy', key = 'kill_all_units', name = 'kill-biters' },
    { type = 'function', object = 'force', key = 'rechart', name = 'reload-map' },
    { type = 'function', object = 'game', key = 'force_crc', name = 'crc' },
    { type = 'function', object = 'force', key = 'reset', name = 'reset-force' }
}

local function object_type(player)
    return { game = game, player = player, force = player.force, enemy = game.forces.enemy }
end

local function get_load_player_and_force(player)
    local str = 'local player = game.get_player(' .. player.index .. ');'
    str = str .. 'local force = player.force;'
    str = str .. 'local enemy = game.forces.enemy;'
    return str
end

local close_element =
    Token.register(
        function (data)
            local element = data.element
            if element and element.valid then
                element.state = false
            end
        end
    )

local combined_list =
{
    personal_settings = personal_settings,
    force_settings = force_settings,
    advanced_settings = advanced_settings
}

local function get_value_of_player_or_force(player, setting)
    local data = object_type(player)
    local object = data[setting.object]
    return object[setting.key] or 1
end

local function get_element_data(frame)
    local object = frame.name
    local key = frame.setting_name.caption
    for _, setting in pairs(combined_list[object]) do
        if key == setting.key then
            return setting
        end
    end
end

local create_checkbox_element =
    Gui.new_frame(
        function (event_trigger, parent, value)
            return parent.add({ type = 'radiobutton', name = event_trigger, state = value })
        end
    ):on_click(
        function (player, element)
            local data = get_element_data(element.parent)
            if data.button == 'checkbox' then
                local str = data.object .. '.' .. data.key .. ' = '
                if element.state then
                    str = str .. ' true'
                else
                    str = str .. ' false'
                end
                load(str)()
            else
                local str = get_load_player_and_force(player) .. data.object .. '.' .. data.key .. '()'
                pcall(load(str))
                Task.set_timeout_in_ticks(20, close_element, { element = element })
            end
        end
    )

local create_slider_element =
    Gui.new_frame(
        function (event_trigger, parent, value, min, max)
            return parent.add(
                {
                    type = 'slider',
                    name = event_trigger,
                    value = value,
                    minimum_value = min,
                    maximum_value =
                        max,
                    value_step = 0.10
                })
        end
    ):on_value_changed(
        function (player, element)
            local data = get_element_data(element.parent)

            local objects = object_type(player)
            local object = objects[data.object]
            local _caption = string.format('%.2f', element.slider_value)
            if element.slider_value > 2 then
                _caption = string.format('%.2f', math.floor(element.slider_value))
            end
            object[data.key] = tonumber(_caption)
            Modifiers.update_single_modifier(player, data.key, 'gs', tonumber(_caption))
            element.parent.counter.caption = _caption
        end
    )

local function draw_slider_element(frame, setting)
    local player = game.get_player(frame.player_index)
    return create_slider_element(frame, get_value_of_player_or_force(player, setting), setting.min, setting.max)
end

local function create_input_elements(frame, setting, setting_name)
    frame = frame.add { type = 'flow' }
    frame =
        frame.add
        {
            type = 'flow',
            name = setting_name
        }
    frame.add
    {
        type = 'label',
        caption = { 'game-settings.effect-' .. setting.name },
        style = 'caption_label'
    }
    frame.add
    {
        type = 'label',
        caption = setting.key,
        name = 'setting_name'
    }.visible = false
    if setting.type == 'slider' then
        local slider = draw_slider_element(frame, setting)
        slider.style.width = 300
        local caption = string.format('%.2f', slider.slider_value)
        if slider.slider_value > 2 then
            caption = tostring(math.floor(slider.slider_value))
        end
        frame.add
        {
            type = 'label',
            name = 'counter',
            caption = caption
        }
    elseif setting.type == 'function' then
        if not setting.params then
            setting.params = {}
        end
        create_checkbox_element(frame, false, setting.button)
    end
end

local function draw_settings(frame, name)
    if frame and frame.valid then
        frame.clear()
    end

    if name == 'force' then
        frame.add
        {
            type = 'label',
            caption = { 'game-settings.basic-message' }
        }.style.single_line = false
        for _, setting in pairs(force_settings) do
            create_input_elements(frame, setting, 'force_settings')
        end
    elseif name == 'personal' then
        frame.add
        {
            type = 'label',
            caption = { 'game-settings.personal-message' }
        }.style.single_line = false
        for _, setting in pairs(personal_settings) do
            create_input_elements(frame, setting, 'personal_settings')
        end
    elseif name == 'advanced' then
        frame.add
        {
            type = 'label',
            caption = { 'game-settings.advanced-message' }
        }.style.single_line = false
        for _, setting in pairs(advanced_settings) do
            create_input_elements(frame, setting, 'advanced_settings')
        end
    end
end

local force_settings_name =
    Gui.new_frame(
        function (event_trigger, parent)
            local force_button =
                parent.add
                {
                    type = 'sprite-button',
                    name = event_trigger,
                    caption = 'Force settings',
                    tooltip = 'Force Settings',
                    style = 'mod_gui_button'
                }
            force_button.style.horizontal_align = 'center'
            force_button.style.font_color = Color.white
            return parent
        end
    ):on_click(
        function (_, element, _)
            for _, elem in pairs(element.parent.children) do
                elem.style.font_color = Color.white
            end
            element.style.font_color = Color.red

            draw_settings(element.parent.parent.parent.parent.tab.tab_scroll, 'force')
        end
    )

local personal_settings_name =
    Gui.new_frame(
        function (event_trigger, parent, triggered)
            local personal_button =
                parent.add
                {
                    type = 'sprite-button',
                    name = event_trigger,
                    caption = 'Personal settings',
                    tooltip = 'Personal Settings',
                    style = 'mod_gui_button'
                }
            personal_button.style.horizontal_align = 'center'
            if triggered then
                personal_button.style.font_color = Color.red
            else
                personal_button.style.font_color = Color.white
            end
            return parent
        end
    ):on_click(
        function (_, element, _)
            for _, elem in pairs(element.parent.children) do
                elem.style.font_color = Color.white
            end
            element.style.font_color = Color.red
            draw_settings(element.parent.parent.parent.parent.tab.tab_scroll, 'personal')
        end
    )

local advanced_settings_name =
    Gui.new_frame(
        function (event_trigger, parent)
            local advanced_button =
                parent.add
                {
                    type = 'sprite-button',
                    name = event_trigger,
                    caption = 'Advanced settings',
                    tooltip = 'Advanced Settings',
                    style = 'mod_gui_button'
                }
            advanced_button.style.horizontal_align = 'center'
            advanced_button.style.font_color = Color.white
            return parent
        end
    ):on_click(
        function (_, element, _)
            for _, elem in pairs(element.parent.children) do
                elem.style.font_color = Color.white
            end
            element.style.font_color = Color.red
            draw_settings(element.parent.parent.parent.parent.tab.tab_scroll, 'advanced')
        end
    )

local function draw_main_frame(player)
    local frame =
        player.gui.screen.add(
            {
                type = 'frame',
                name = main_view_frame_name,
                caption = 'Game settings',
                direction = 'vertical'
            }
        )

    frame.auto_center = true
    player.opened = frame

    Gui.bar(frame, 510)
    if not frame or not frame.valid then
        return
    end
    local tab_bar =
        frame.add
        {
            type = 'frame',
            name = 'tab_bar',
            style = 'deep_frame_in_shallow_frame',
            direction = 'vertical'
        }
    tab_bar.style.width = 510
    tab_bar.style.height = 65
    local tab_bar_scroll =
        tab_bar.add
        {
            type = 'scroll-pane',
            name = 'tab_bar_scroll',
            horizontal_scroll_policy = 'auto-and-reserve-space',
            vertical_scroll_policy = 'never'
        }
    tab_bar_scroll.style.vertically_squashable = false
    tab_bar_scroll.style.vertically_stretchable = true
    tab_bar_scroll.style.width = 500
    local tab_bar_scroll_flow =
        tab_bar_scroll.add
        {
            type = 'flow',
            name = 'tab_bar_scroll_flow',
            direction = 'horizontal'
        }
    Gui.bar(frame, 510)
    local tab =
        frame.add
        {
            type = 'frame',
            name = 'tab',
            direction = 'vertical',
            style = 'deep_frame_in_shallow_frame'
        }
    tab.style.width = 510
    tab.style.height = 305
    local tab_scroll =
        tab.add
        {
            type = 'scroll-pane',
            name = 'tab_scroll',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    tab_scroll.style.vertically_squashable = false
    tab_scroll.style.vertically_stretchable = true
    tab_scroll.style.width = 500
    local tab_scroll_flow =
        tab_scroll.add
        {
            type = 'flow',
            name = 'tab_scroll_flow',
            direction = 'vertical'
        }
    tab_scroll_flow.style.width = 480
    Gui.bar(frame, 510)

    draw_settings(tab_scroll_flow, 'personal')

    personal_settings_name(tab_bar_scroll_flow, true)

    force_settings_name(tab_bar_scroll_flow)

    advanced_settings_name(tab_bar_scroll_flow)
end

local function remove_main_frame(main_frame)
    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()
end

local function toggle(player)
    local screen = player.gui.screen
    local main_frame = screen[main_view_frame_name]

    if main_frame then
        remove_main_frame(main_frame)
    else
        draw_main_frame(player)
    end
end

local function gui_closed(event)
    local player = game.get_player(event.player_index)
    local type = event.gui_type

    if not player or not player.valid then
        return
    end


    if type == defines.gui_type.custom then
        local screen = player.gui.screen
        local main_frame = screen[main_view_frame_name]

        if main_frame then
            remove_main_frame(main_frame)
        end
    end
end

function Public.draw_button(player)
    if not Roles.allowed(player, 'game-settings') then
        if Gui.get_button_flow(player)[main_button_name] then
            Gui.get_button_flow(player)[main_button_name].destroy()
        end
        return
    end

    if Gui.get_button_flow(player)[main_button_name] then
        return
    end

    local button = Gui.get_button_flow(player).add
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'utility/no_building_material_icon',
            tooltip = 'Game settings',
            style = Gui.button_style
        }
    button.style.minimal_height = 36
    button.style.maximal_height = 36
    button.style.minimal_width = 40
    button.style.padding = -2
end

Event.add(
    defines.events.on_player_created,
    function (event)
        local player = game.get_player(event.player_index)

        Public.draw_button(player)
    end
)

Gui.on_click(
    main_button_name,
    function (event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        toggle(player)
    end
)

local reassign_settings_button =
    Token.register(
        function (data)
            local player_index = data.player_index
            local player = game.get_player(player_index)
            if player and player.valid then
                Public.draw_button(player)
            end
        end
    )

Event.add(
    Roles.events.on_role_change,
    function (event)
        Task.set_timeout_in_ticks(10, reassign_settings_button, { player_index = event.player_index })
    end
)

Event.add(defines.events.on_gui_closed, gui_closed)

return Public
