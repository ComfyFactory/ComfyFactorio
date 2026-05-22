return function (center, surface)
    local ce = surface.create_entity --save typing
    ce { name = 'stone-wall', position = { center.x + (-6.0), center.y + (-6.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-5.0), center.y + (-6.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-4.0), center.y + (-6.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (1.0), center.y + (-6.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (4.0), center.y + (-6.0) }, force = game.forces.enemy }
    ce { name = 'medium-electric-pole', position = { center.x + (-4.0), center.y + (-4.0) }, force = game.forces.enemy }
    ce { name = 'gun-turret', position = { center.x + (2.5), center.y + (-2.5) }, force = game.forces.enemy }.insert
    {
        name = 'piercing-rounds-magazine',
        count = 128
        , quality = 'normal'
    }
    ce { name = 'gun-turret', position = { center.x + (2.5), center.y + (2.5) }, force = game.forces.enemy }.insert { name = 'piercing-rounds-magazine', count = 128, quality = 'normal' }
    ce { name = 'stone-wall', position = { center.x + (-6.0), center.y + (-1.0) }, force = game.forces.enemy }
    ce { name = 'radar', position = { center.x + (-1.0), center.y + (-1.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (6.0), center.y + (-2.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-6.0), center.y + (1.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-6.0), center.y + (0.0) }, force = game.forces.enemy }
    ce { name = 'radar', position = { center.x + (-1.0), center.y + (2.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (6.0), center.y + (1.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-6.0), center.y + (2.0) }, force = game.forces.enemy }
    ce { name = 'medium-electric-pole', position = { center.x + (1.0), center.y + (2.0) }, force = game.forces.enemy }
    ce { name = 'gun-turret', position = { center.x + (-2.5), center.y + (4.5) }, force = game.forces.enemy }.insert
    {
        name = 'piercing-rounds-magazine',
        count = 128, quality = 'normal'
    }
    ce { name = 'gun-turret', position = { center.x + (-2.5), center.y + (-4.5) }, force = game.forces.enemy }.insert
    {
        name = 'piercing-rounds-magazine',
        count = 128, quality = 'normal'
    }
    ce { name = 'land-mine', position = { center.x + (4.86328125), center.y + (4.16796875) }, force = game.forces.enemy }
    ce { name = 'gate', position = { center.x + (6.0), center.y + (5.0) }, force = game.forces.enemy }
    ce { name = 'gate', position = { center.x + (6.0), center.y + (4.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-5.0), center.y + (7.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-6.0), center.y + (7.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-3.0), center.y + (7.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (-4.0), center.y + (7.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (0.0), center.y + (7.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (3.0), center.y + (7.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (6.0), center.y + (6.0) }, force = game.forces.enemy }
    ce { name = 'stone-wall', position = { center.x + (6.0), center.y + (7.0) }, force = game.forces.enemy }
end
