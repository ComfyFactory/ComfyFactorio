return function (center, surface)
    local ce = surface.create_entity

    local fN = game.forces.enemy
    ce { name = "gun-turret", position = { center.x + (4.0), center.y + (-2.0) }, force = fN }.insert { name = "piercing-rounds-magazine", count = math.random(64, 100), quality = 'normal' }
end
