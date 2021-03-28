local Public = {}

--[[
on_inactive_players - Performs operation on inactive players from the game
if they exceed time.
@param time - Maximum time a player can be inactive.
--]]
Public.on_inactive_players = function(time)
    if not time then
        time = 5
    end

    for _, p in pairs(game.connected_players) do
        local afk = p.afk_time
        time = time * 60 * 60
        if afk >= time then
            game.kick_player(p, 'Kicked by script')
        end
    end
end

return Public
