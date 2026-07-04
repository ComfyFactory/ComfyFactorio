local Public = {}

local scrapable = {
    ['mineable-wreckage'] = true,
    ['crash-site-chest-1'] = true,
    ['crash-site-chest-2'] = true
}

function Public.is_scrap(entity)
    if not entity.valid then
        return false
    end
    return scrapable[entity.name] or false
end

return Public
