-- simply use /where ::LuaPlayerName to locate them

local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'

local this = {
    players = {}
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
    local player_data = this.players[player.index]
    if player_data then
        this.players[player.index] = nil
    end
end

local function remove_camera_frame(player)
    if player.gui.center[locate_player_frame_name] then
        player.gui.center[locate_player_frame_name].destroy()
        remove_player_data(player)
        return
    end
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if player.admin then
        return false
    end
    return true
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

local function create_mini_camera_gui(player, target)
    if not player or not player.valid then
        return
    end

    if player.gui.center[locate_player_frame_name] then
        player.gui.center[locate_player_frame_name].destroy()
        remove_player_data(player)
        return
    end

    if validate_player(target) then
        local player_data = create_player_data(player)
        player_data.target = target
    else
        remove_player_data(player)
        return
    end

    local frame = player.gui.center[locate_player_frame_name]
    if not validate_frame(frame) then
        frame = player.gui.center.add({type = 'frame', name = locate_player_frame_name, caption = target.name})
    end

    local surface = tonumber(target.surface.index)

    if frame[player_frame_name] and frame[player_frame_name].valid then
        frame[player_frame_name].destroy()
    end

    local camera =
        frame.add(
        {
            type = 'camera',
            name = player_frame_name,
            position = target.position,
            zoom = 0.4,
            surface_index = surface
        }
    )
    camera.style.minimal_width = 740
    camera.style.minimal_height = 580
    local player_data = create_player_data(player)
    player_data.camera_frame = camera
end

commands.add_command(
    'where',
    'Locates a player',
    function(cmd)
        local player = game.player

        if validate_player(player) then
            if not cmd.parameter then
                return
            end

            local target_player = game.get_player(cmd.parameter)

            if validate_player(target_player) then
                local player_data = create_player_data(player)
                player_data.target_player = target_player
                create_mini_camera_gui(player, target_player)
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
        if data and data.target_player and data.target_player.valid then
            local target_player = data.target_player
            local camera_frame = data.camera_frame
            local player = game.get_player(p)

            if not (validate_player(player) and validate_player(target_player)) then
                remove_player_data(player)
                goto continue
            end

            if not validate_frame(camera_frame) then
                remove_player_data(player)
                goto continue
            end

            camera_frame.position = target_player.position
            camera_frame.surface_index = target_player.surface.index

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

Public.create_mini_camera_gui = create_mini_camera_gui
Public.remove_camera_frame = remove_camera_frame

Event.on_nth_tick(2, on_nth_tick)

return Public
