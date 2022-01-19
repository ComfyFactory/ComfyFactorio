local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Server = require 'utils.server'

local main_frame_name = Gui.uid_name()
local main_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()
local instance_id_name = Gui.uid_name()
local insert = table.insert
local sort = table.sort

local function get_instance()
    local server_instances = Server.get_instances()
    local id = Server.get_server_id()
    if server_instances and server_instances[id] then
        return server_instances[id]
    else
        return {name = 'Offline', id = id, status = 'offline', version = game.active_mods.base}
    end
end

local function apply_button_style(button)
    local button_style = button.style
    button_style.font = 'default-semibold'
    button_style.height = 26
    button_style.minimal_width = 26
    button_style.top_padding = 0
    button_style.bottom_padding = 0
    button_style.left_padding = 2
    button_style.right_padding = 2
end

local function draw_main_frame(player)
    local instance = get_instance()
    local left = player.gui.left

    local frame = left.add {type = 'frame', name = main_frame_name, caption = 'Comfy Servers', direction = 'vertical'}

    local inside_frame =
        frame.add {
        type = 'frame',
        style = 'deep_frame_in_shallow_frame'
    }
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    inside_frame_style.maximal_height = 800

    player.opened = frame

    local instances = {}
    local server_instances = Server.get_instances()
    for _, i in pairs(server_instances) do
        insert(instances, i)
    end

    local viewer_table = inside_frame.add {type = 'table', column_count = 3}
    viewer_table.style.cell_padding = 4

    sort(
        instances,
        function(a, b)
            return a.id < b.id
        end
    )

    if #instances <= 1 then
        viewer_table.add {
            type = 'label',
            caption = 'No other instances online'
        }
    else
        for _, i in ipairs(instances) do
            viewer_table.add {
                type = 'label',
                caption = 'Name: ' .. i.name,
                tooltip = i.connected .. '\nVersion: ' .. i.version,
                style = 'caption_label'
            }
            local flow = viewer_table.add {type = 'flow'}
            flow.style.horizontal_align = 'right'
            flow.style.horizontally_stretchable = true
            local empty_flow = viewer_table.add {type = 'flow'}
            local button =
                empty_flow.add {
                type = 'button',
                caption = 'Connect',
                tooltip = 'Click to connect to this server.\n' .. i.connected .. '\nVersion: ' .. i.version,
                name = instance_id_name
            }
            Gui.set_data(button, i.id)
            apply_button_style(button)

            if i.id == instance.id then
                button.enabled = false
                button.tooltip = 'You are here'
            elseif i.status == 'unknown' then
                button.enabled = i.game_port ~= nil
                button.style.font_color = {r = 0.65}
                button.style.hovered_font_color = {r = 0.65}
                button.style.clicked_font_color = {r = 0.65}
                button.style.disabled_font_color = {r = 0.75, g = 0.1, b = 0.1}
                button.tooltip = 'Unknown status for this server'
            elseif i.status ~= 'running' then
                button.enabled = false
                button.tooltip = 'This server is offline'
            elseif i.version ~= instance.version then
                button.enabled = false
                button.tooltip = "We're on version: " .. instance.version .. '\nDestination server is on version: ' .. i.version
            end
        end
    end

    local bottom_flow = frame.add {type = 'flow', direction = 'horizontal'}

    local left_flow = bottom_flow.add {type = 'flow'}
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add {type = 'button', name = discard_button_name, caption = 'Close'}
    apply_button_style(close_button)

    local right_flow = bottom_flow.add {type = 'flow'}
    right_flow.style.horizontal_align = 'right'
end

local function toggle(player)
    local left = player.gui.left
    local frame = left[main_frame_name]
    if not player or not player.valid or not player.character then
        return
    end
    if frame and frame.valid then
        Gui.remove_data_recursively(frame)
        frame.destroy()
    else
        draw_main_frame(player)
    end
end

local function create_main_button(event)
    local player = game.get_player(event.player_index)
    local main_button = player.gui.top[main_button_name]
    if not main_button or not main_button.valid then
        main_button =
            player.gui.top.add(
            {
                type = 'sprite-button',
                sprite = 'utility/surface_editor_icon',
                tooltip = 'Connect to another Comfy server!',
                name = main_button_name
            }
        )
        main_button.style.font_color = {r = 0.11, g = 0.8, b = 0.44}
        main_button.style.font = 'heading-1'
        main_button.style.minimal_height = 40
        main_button.style.maximal_width = 40
        main_button.style.minimal_width = 38
        main_button.style.maximal_height = 38
        main_button.style.padding = 1
        main_button.style.margin = 0
    end
end

Gui.on_click(
    main_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end
        toggle(player)
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end
        toggle(player)
    end
)

Gui.on_click(
    instance_id_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end
        local id = Gui.get_data(event.element)
        local instance_id = tostring(id)
        local server_instances = Server.get_instances()
        local instance = server_instances[instance_id]

        if instance and instance.game_port and instance.public_address then
            player.connect_to_server {
                address = instance.public_address .. ':' .. instance.game_port,
                name = instance.name
            }
            toggle(player)
        end
    end
)

Event.add(defines.events.on_player_joined_game, create_main_button)
