-- simply use /where ::LuaPlayerName to locate them

local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'

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

local function get_player_data(player, remove)
    local player_data = this.players[player.index]
    if player_data then
        if not remove then
            return player_data
        else
            this.players[player.index] = nil
        end
    end

    this.players[player.index] = {}
    return this.players[player.index]
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.index] then
        return false
    end
    return true
end

local function create_mini_camera_gui(player, caption, position, surface, refresh)
    local target_player = game.players[caption]

    if validate_player(target_player) then
        local player_data = get_player_data(player)
        player_data.target_player = target_player
    else
        get_player_data(player, true)
        player.print('Please type a name of a player who is connected.', Color.warning)
        return
    end

    if player.gui.center['where_camera'] and not refresh then
        player.gui.center['where_camera'].destroy()
    end

    local frame = player.gui.center.where_camera
    if not frame then
        frame = player.gui.center.add({type = 'frame', name = 'where_camera', caption = caption})
    end

    surface = tonumber(surface)

    if frame.where_camera then
        frame.where_camera.destroy()
    end

    local camera =
        frame.add(
        {
            type = 'camera',
            name = 'where_camera',
            position = position,
            zoom = 0.4,
            surface_index = surface
        }
    )
    camera.style.minimal_width = 740
    camera.style.minimal_height = 580
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
            local target_player = game.players[cmd.parameter]

            if validate_player(target_player) then
                local player_data = get_player_data(player)
                player_data.target_player = target_player
                create_mini_camera_gui(player, target_player.name, target_player.position, target_player.surface.index)
            else
                get_player_data(player, true)
                player.print('Please type a name of a player who is connected.', Color.warning)
            end
        else
            return
        end
    end
)

local function on_gui_click(event)
    local player = game.players[event.player_index]

    if not (event.element and event.element.valid) then
        return
    end

    local name = event.element.name

    if name == 'where_camera' then
        player.gui.center['where_camera'].destroy()
        get_player_data(player, true)
        return
    end
end

local function on_nth_tick()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]

        local player_data = get_player_data(player)
        if player_data and player_data.target_player then
            local target_player = player_data.target_player

            if not validate_player(target_player) then
                get_player_data(player, true)
                goto continue
            end

            create_mini_camera_gui(player, target_player.name, target_player.position, target_player.surface.index, true)

            ::continue::
        end
    end
end

Public.create_mini_camera_gui = create_mini_camera_gui

Event.add(defines.events.on_gui_click, on_gui_click)
Event.on_nth_tick(2, on_nth_tick)

return Public
