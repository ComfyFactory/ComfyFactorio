local Public = {}

local scrapable = {
    ['crash-site-spaceship-wreck-small-1'] = true,
    ['crash-site-spaceship-wreck-small-2'] = true,
    ['crash-site-spaceship-wreck-small-3'] = true,
    ['crash-site-spaceship-wreck-small-4'] = true,
    ['crash-site-spaceship-wreck-small-5'] = true,
    ['crash-site-spaceship-wreck-small-6'] = true,
    ['big-ship-wreck-1'] = true,
    ['big-ship-wreck-2'] = true,
    ['big-ship-wreck-3'] = true,
    ['crash-site-chest-1'] = true,
    ['crash-site-chest-2'] = true,
    ['crash-site-spaceship-wreck-medium-1'] = true,
    ['crash-site-spaceship-wreck-medium-2'] = true,
    ['crash-site-spaceship-wreck-medium-3'] = true,
    ['crash-site-spaceship-wreck-big-1'] = true,
    ['crash-site-spaceship-wreck-big-2'] = true,
    ['crash-site-spaceship'] = true
}

function Public.is_scrap(entity)
    if not entity.valid then
        return false
    end
    return scrapable[entity.name] or false
end

return Public
