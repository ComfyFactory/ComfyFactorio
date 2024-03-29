local Event = require 'utils.event'

local function on_player_joined_game()
    game.forces.enemy.set_ammo_damage_modifier('melee', 1)
    game.forces.enemy.set_ammo_damage_modifier('biological', 1)
    game.forces.enemy.set_ammo_damage_modifier('artillery-shell', 0.5)
    game.forces.enemy.set_ammo_damage_modifier('flamethrower', 0.5)
    game.forces.enemy.set_ammo_damage_modifier('laser', 0.5)
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
