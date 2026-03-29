return function (center, surface) --biter defense setup
    local ce = surface.create_entity --save typing
    local fN = game.forces.neutral

    ce { name = 'big-rock', position = { center.x + (-6.5), center.y + (-5.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-4.5), center.y + (-6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-2.5), center.y + (-6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-0.5), center.y + (-6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (1.5), center.y + (-6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (3.5), center.y + (-6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (5.5), center.y + (-6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-6.5), center.y + (-3.5) }, force = fN }
    ce { name = 'biter-spawner', position = { center.x + (2.0), center.y + (-3.0) }, force = game.forces.enemy }
    ce { name = 'big-rock', position = { center.x + (6.5), center.y + (-4.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-6.5), center.y + (-1.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (6.5), center.y + (-2.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-6.5), center.y + (0.5) }, force = fN }
    ce { name = 'biter-spawner', position = { center.x + (2.0), center.y + (1.0) }, force = game.forces.enemy }
    ce { name = 'big-rock', position = { center.x + (6.5), center.y + (-0.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-6.5), center.y + (2.5) }, force = fN }
    ce { name = 'biter-spawner', position = { center.x + (-2.0), center.y + (2.0) }, force = game.forces.enemy }
    ce { name = 'big-rock', position = { center.x + (6.5), center.y + (1.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-6.5), center.y + (4.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (6.5), center.y + (3.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-5.5), center.y + (6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-3.5), center.y + (6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (-1.5), center.y + (6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (0.5), center.y + (6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (2.5), center.y + (6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (4.5), center.y + (6.5) }, force = fN }
    ce { name = 'big-rock', position = { center.x + (6.5), center.y + (6.5) }, force = fN }
end
