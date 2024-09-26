--biters make comic like text sounds when they damage something -- mewmew

local Event = require 'utils.event'
local math_random = math.random

local strings = {
    'delicious!',
    'yum',
    'yum',
    'crunch',
    'crunch',
    'chomp',
    'chomp',
    'chow',
    'chow',
    'nibble',
    'nibble',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom',
    'nom'
}
local size_of_strings = #strings

local whitelist = {
    ['small-biter'] = true,
    ['medium-biter'] = true,
    ['big-biter'] = true,
    ['behemoth-biter'] = true
}

local function on_entity_damaged(event)
    if not event.cause then return end
    if not event.cause.valid then return end

    if not whitelist[event.cause.name] then return end

    local surface = event.cause.surface
    if not surface.valid then return end

    if math_random(1, 5) == 1 then
        for _, player in pairs(game.players) do
            if player.surface_index == event.cause.surface_index then
                player.create_local_flying_text(
                    {
                        position = event.cause.position,
                        text = strings[math_random(1, size_of_strings)],
                        color = { r = math_random(130, 170), g = math_random(130, 170), b = 130 }
                    }
                )
            end
        end
    end
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
