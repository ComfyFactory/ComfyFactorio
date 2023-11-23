-- simply use /where ::LuaPlayerName to locate them

local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'

local this = {
    players = {},
    module_disabled = false
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

local locate_player_frame_name = Gui.uid_name()
local player_frame_name = Gui.uid_name()

local function create_player_data(player)
    local player_data = this.players[player.index]
    if player_data then
        return this.players[player.index]
    else
        this.players[player.index] = {}
        return this.players[player.index]
    end
end

local function remove_player_data(player)
    if not player then
        return
    end
    if not player.index then
        return
    end
    local player_data = this.players[player.index]
    if player_data then
        if player_data.render_object then
            rendering.destroy(player_data.render_object)
        end

        this.players[player.index] = nil
    end
end

local function remove_camera_frame(player)
    if player.gui.screen[locate_player_frame_name] then
        player.gui.screen[locate_player_frame_name].destroy()
        remove_player_data(player)
        return
    end
end

local function validate_frame(frame)
    if not frame then
        return false
    end
    if not frame.valid then
        return false
    end

    return true
end

local function create_mini_camera_gui(player, target, zoom, render, tooltip)
    if not player or not player.valid then
        return
    end

    if player.gui.screen[locate_player_frame_name] then
        player.gui.screen[locate_player_frame_name].destroy()
        remove_player_data(player)
        return
    end
    local player_data

    if target and target.valid and player.admin or target and target.valid then
        player_data = create_player_data(player)
        player_data.target = target
    else
        remove_player_data(player)
        return
    end

    local frame = player.gui.screen[locate_player_frame_name]
    if not validate_frame(frame) then
        frame = player.gui.screen.add({type = 'frame', name = locate_player_frame_name, caption = target.name})
    end

    frame.force_auto_center()

    local surface = tonumber(target.surface.index)

    if frame[player_frame_name] and frame[player_frame_name].valid then
        frame[player_frame_name].destroy()
    end

    if render then
        local render_object =
            rendering.draw_text {
            text = '▼',
            surface = target.surface,
            target = {target.position.x, target.position.y - 3},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            players = {player.index},
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }

        if player_data then
            player_data.render_object = render_object
        end
    end

    local camera =
        frame.add(
        {
            type = 'camera',
            name = player_frame_name,
            position = target.position,
            zoom = zoom or 0.4,
            surface_index = surface,
            tooltip = tooltip or ''
        }
    )
    camera.style.minimal_width = 740
    camera.style.minimal_height = 580
    player_data = create_player_data(player)
    player_data.camera_frame = camera
    return frame
end

commands.add_command(
    'where',
    'Locates a player',
    function(cmd)
        local player = game.player

        if player and player.valid then
            if not cmd.parameter then
                return
            end

            if this.module_disabled then
                return
            end

            local target = game.get_player(cmd.parameter)

            if target and target.valid then
                local player_data = create_player_data(player)
                player_data.target = target
                create_mini_camera_gui(player, target)
            else
                remove_player_data(player)
                player.print('[Where] Please type a name of a player who is connected.', Color.warning)
            end
        else
            return
        end
    end
)

local function on_nth_tick()
    for p, data in pairs(this.players) do
        if data and data.target and data.target.valid then
            local target = data.target
            local camera_frame = data.camera_frame
            local player = game.get_player(p)

            if not (player and player.valid or target and target.valid) then
                remove_player_data(player)
                goto continue
            end

            if not validate_frame(camera_frame) then
                remove_player_data(player)
                goto continue
            end

            camera_frame.position = target.position
            camera_frame.surface_index = target.surface.index

            ::continue::
        end
    end
end

Gui.on_click(
    locate_player_frame_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Where Locate Player')
        if is_spamming then
            return
        end
        remove_camera_frame(event.player)
    end
)

Gui.on_custom_close(
    locate_player_frame_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Where Locate Player')
        if is_spamming then
            return
        end
        remove_camera_frame(event.player)
    end
)

Gui.on_click(
    player_frame_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Where Player Frame')
        if is_spamming then
            return
        end
        remove_camera_frame(event.player)
    end
)

--- Disables the module.
---@param state boolean
function Public.module_disabled(state)
    this.module_disabled = state or false
end

Public.create_mini_camera_gui = create_mini_camera_gui
Public.remove_camera_frame = remove_camera_frame
Public.locate_player_frame_name = locate_player_frame_name
Public.player_frame_name = player_frame_name

Event.on_nth_tick(2, on_nth_tick)

return Public
