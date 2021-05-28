local Event = require 'utils.event'

local function set_pause()
    game.tick_paused = true
end

local function resume_game()
    local player_count = #game.connected_players

    if player_count <= 1 then
        game.tick_paused = false
    end
end

local function player_left()
    local player_count = #game.connected_players

    if player_count == 0 then
        set_pause()
    end
end

local function player_joined()
    resume_game()
end

Event.add(
    defines.events.on_player_joined_game,
    function()
        if _DEBUG then -- we're debugging, don't do anything.
            return
        end
        player_joined()
    end
)

Event.add(
    defines.events.on_player_left_game,
    function()
        if _DEBUG then -- we're debugging, don't do anything.
            return
        end
        player_left()
    end
)
