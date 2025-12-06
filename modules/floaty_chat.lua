local Event = require 'utils.event'
local Global = require 'utils.global'

local this =
{
    player_floaty_chat = {}
}

Global.register(this,
    function (tbl)
        this = tbl
    end)

---@param event table
local function on_console_chat(event)
    local msg = event.message
    local player_index = event.player_index
    if not msg or not player_index then
        return
    end

    local player = game.get_player(player_index)
    if not (player and player.valid and player.character) then
        return
    end

    if player.character.surface.index ~= player.physical_surface.index then
        return
    end

    local prev_text = this.player_floaty_chat[player_index]
    if prev_text and prev_text.valid then
        prev_text.destroy()
    end

    local players = {}
    for _, p in pairs(game.connected_players) do
        if p.force == player.force then
            players[#players + 1] = p
        end
    end

    if #players == 0 then
        return
    end

    -- Draw new floaty chat text
    local color = player.color
    local text_chat = rendering.draw_text
        {
            text = msg,
            surface = player.physical_surface,
            target = { entity = player.character, offset = { -0.05, -4 } },
            color =
            {
                r = color.r * 0.6 + 0.25,
                g = color.g * 0.6 + 0.25,
                b = color.b * 0.6 + 0.25,
                a = 1
            },
            players = players,
            time_to_live = 600,
            scale = 1.5,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }

    this.player_floaty_chat[player_index] = text_chat
end

Event.add(defines.events.on_console_chat, on_console_chat)
