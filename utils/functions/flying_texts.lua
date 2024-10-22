local Public = {}


---Create Flying text for the player, or for all players on that surface if no player specified
---@param player LuaPlayer|nil
---@param surface LuaSurface
---@param position MapPosition
---@param text string|table
---@param color Color|table
function Public.flying_text(player, surface, position, text, color)
    if not player then
        for _, p in pairs(game.connected_players) do
            if p.surface == surface then
                p.create_local_flying_text({
                    text = text,
                    position = position,
                    color = color
                })
            end
        end
    else
        player.create_local_flying_text({
            text = text,
            position = position,
            color = color
        })
    end
end

return Public
