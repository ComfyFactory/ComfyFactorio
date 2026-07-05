local Compat = require 'utils.functions.factorio_compat'

local Public = {}

function Public.flying_text(player, surface, position, text, color)
    Compat.flying_text(player, surface, position, text, color)
end

function Public.player_flying_text(player, opts)
    Compat.player_flying_text(player, opts)
end

return Public
