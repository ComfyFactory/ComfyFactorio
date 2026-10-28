
local Public = {}

function Public.flying_text(player, surface, position, text, color)
    if not player then
        for _, p in pairs(game.connected_players) do
            if p.surface == surface then
                p.create_local_flying_text({ text = text, position = position, color = color })
            end
        end
    else
        player.create_local_flying_text({ text = text, position = position, color = color })
    end
end

function Public.player_flying_text(player, opts)
    player.create_local_flying_text(opts)
end

return Public
