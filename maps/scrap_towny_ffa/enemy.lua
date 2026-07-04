local Public = {}

function Public.clear_enemies(position, surface, radius)
    for _, e in pairs(surface.find_entities_filtered({ force = 'enemy', type = { 'unit-spawner', 'unit', 'turret' }, position = position, radius = radius })) do
        e.destroy()
    end
    for _, e in pairs(surface.find_entities_filtered({ force = 'enemy', name = { 'gun-turret' }, position = position, radius = radius })) do
        e.destroy()
    end
end

function Public.clear_worms(position, surface, radius)
    for _, e in pairs(surface.find_entities_filtered({ force = 'enemy', type = { 'turret' }, position = position, radius = radius })) do
        e.destroy()
    end
end

return Public
