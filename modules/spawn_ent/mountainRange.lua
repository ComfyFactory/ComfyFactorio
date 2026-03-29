return function (center, surface) -- mountain range
    local ce = surface.create_entity --save typing
    local fN = game.forces.neutral

    ce { name = "big-rock", position = { center.x + (-7.5), center.y + (-0.5) }, force = fN }
    ce { name = "big-rock", position = { center.x + (-3.5), center.y + (-0.5) }, force = fN }
    ce { name = "big-rock", position = { center.x + (0.5), center.y + (-0.5) }, force = fN }
    ce { name = "big-rock", position = { center.x + (4.5), center.y + (-0.5) }, force = fN }
    ce { name = "big-rock", position = { center.x + (-5.5), center.y + (1.5) }, force = fN }
    ce { name = "big-rock", position = { center.x + (-1.5), center.y + (1.5) }, force = fN }
    ce { name = "big-rock", position = { center.x + (2.5), center.y + (1.5) }, force = fN }
end
