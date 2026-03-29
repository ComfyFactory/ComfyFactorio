return function (center, surface) --encampment
    local ce = surface.create_entity --save typing
    local fN = game.forces.neutral
    local direct = defines.direction

    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (-5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-4.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-5.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-2.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-3.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (-5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-1.0), center.y + (-6.0) }, force = fN }
    ce { name = "land-mine", position = { center.x + (1.26953125), center.y + (-4.28515625) }, force = game.forces.enemy }
    ce { name = "gate", position = { center.x + (1.0), center.y + (-6.0) }, direction = direct.east, force = fN }
    ce { name = "stone-wall", position = { center.x + (2.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (3.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (4.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (5.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (-6.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (-5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (-4.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (-3.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (-4.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (-4.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (-3.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (-1.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (-1.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (1.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (2.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (4.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (3.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (-2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (-1.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-7.0), center.y + (1.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-7.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-3.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-2.0), center.y + (0.0) }, force = fN }
    ce { name = "wooden-chest", position = { center.x + (-1.0), center.y + (1.0) }, force = fN }.insert { name = "raw-fish", count = 30, quality = 'normal' }
    ce { name = "stone-wall", position = { center.x + (-1.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (1.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (2.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (4.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (3.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (1.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (5.0), center.y + (0.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-7.0), center.y + (3.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-7.0), center.y + (2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (3.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (2.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (3.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-6.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-7.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-7.0), center.y + (4.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-5.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-4.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-3.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-2.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (-1.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (0.0), center.y + (4.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (2.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (1.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (4.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (3.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (4.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (6.0), center.y + (5.0) }, force = fN }
    ce { name = "stone-wall", position = { center.x + (5.0), center.y + (5.0) }, force = fN }
end
