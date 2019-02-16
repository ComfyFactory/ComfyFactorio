-- enemy biters have double damage -- by mewmew

local event = require 'utils.event'

local function on_player_joined_game(event)
	game.forces.enemy.set_ammo_damage_modifier("melee", 1)
	game.forces.enemy.set_ammo_damage_modifier("biological", 1)
	game.forces.enemy.set_ammo_damage_modifier("artillery-shell", 1)
	game.forces.enemy.set_ammo_damage_modifier("flamethrower", 1)
	game.forces.enemy.set_ammo_damage_modifier("laser-turret", 1)
end
	
event.add(defines.events.on_player_joined_game, on_player_joined_game)