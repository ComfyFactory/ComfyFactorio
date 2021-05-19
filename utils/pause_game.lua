local Event = require 'utils.event'

local function halt_game()
    game.tick_paused = true
end

local function resume_game()
    game.tick_paused = false
end

local function player_left()
    local player_count = #game.connected_players

    if player_count == 0 then
        halt_game()
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
