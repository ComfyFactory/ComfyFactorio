local Public_chrono = {}

local Server = require 'utils.server'

function Public_chrono.objective_died()
  local objective = global.objective
  if objective.game_lost == true then return end
  objective.health = 0
  local surface = objective.surface
  game.print("The chronotrain was destroyed!")
  game.print("Comfylatron is going to kill you for that...he has time machine after all!")
  surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo.position})
  global.locomotive_cargo.destroy()
  surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo2.position})
  global.locomotive_cargo2.destroy()
  surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo3.position})
  global.locomotive_cargo3.destroy()
  for i = 1, #global.comfychests,1 do
    --surface.create_entity({name = "big-artillery-explosion", position = global.comfychests[i].position})
    global.comfychests[i].destroy()

    if global.comfychests2 then global.comfychests2[i].destroy() end

    --global.comfychests = {}
  end
  global.acumulators = {}
  objective.game_lost = true
  global.game_reset_tick = game.tick + 1800
  for _, player in pairs(game.connected_players) do
    player.play_sound{path="utility/game_lost", volume_modifier=0.75}
  end
end

local function overstayed()
  local objective = global.objective
	if objective.passivetimer > objective.chrononeeds * 0.75 and objective.chronojumps > 5 then
		objective.passivejumps = objective.passivejumps + 1
    return true
	end
  return false
end

function Public_chrono.process_jump(choice)
	local objective = global.objective
	local overstayed = overstayed()
	objective.chronojumps = objective.chronojumps + 1
	objective.chrononeeds = 2000 + 500 * objective.chronojumps
	objective.passivetimer = 0
	objective.chronotimer = 0
	local message = "Comfylatron: Wheeee! Time Jump Active! This is Jump number " .. global.objective.chronojumps
	game.print(message, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed(message)

	if objective.chronojumps == 6 then
		game.print("Comfylatron: Biters start to evolve faster! We need to charge forward or they will be stronger! (hover over timer to see evolve timer)", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronojumps >= 15 and objective.computermessage == 0 then
		game.print("Comfylatron: You know...I have big quest. Deliver fish to fish market. But this train is broken. Please help me fix the train computer!", {r=0.98, g=0.66, b=0.22})
    objective.computermessage = 1
	elseif objective.chronojumps >= 20 and objective.computermessage == 2 then
		game.print("Comfylatron: Ah, we need to give this machine more power and better navigation chipset. Please bring me some additional things.", {r=0.98, g=0.66, b=0.22})
    objective.computermessage = 3
	elseif objective.chronojumps >= 25 and objective.computermessage == 4 then
		game.print("Comfylatron: Finally found the main issue. We will need to rebuild whole processor. Exactly what I feared of. Just a few more things...", {r=0.98, g=0.66, b=0.22})
    objective.computermessage = 5
	end
	if overstayed then
    game.print("Comfylatron: Looks like you stayed on previous planet for so long that enemies on other planets had additional time to evolve!", {r=0.98, g=0.66, b=0.22})
  end
end

function Public_chrono.get_wagons()
  local inventories = {one = global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon), two = global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon)}
	inventories.one.sort_and_merge()
	inventories.two.sort_and_merge()
	local wagons = {}
	wagons[1] = {inventory = inventories.one.get_contents(), bar = inventories.one.get_bar(), filters = {}}
	wagons[2] = {inventory = inventories.two.get_contents(), bar = inventories.two.get_bar(), filters = {}}
	for i = 1, 40, 1 do
		wagons[1].filters[i] = inventories.one.get_filter(i)
		wagons[2].filters[i] = inventories.two.get_filter(i)
	end
  return wagons
end

function Public_chrono.post_jump()
  local objective = global.objective
  game.forces.enemy.reset_evolution()
	if objective.chronojumps + objective.passivejumps <= 40 and objective.planet[1].name.id ~= 17 then
		game.forces.enemy.evolution_factor = 0 + 0.025 * (objective.chronojumps + objective.passivejumps)
	else
		game.forces.enemy.evolution_factor = 1
	end
	if objective.planet[1].name.id == 17 then
		global.comfychests[1].insert({name = "space-science-pack", count = 1000})
		objective.chrononeeds = 200000000
	end
	for _, player in pairs(game.connected_players) do
		global.flame_boots[player.index] = {fuel = 1, steps = {}}
	end
	game.map_settings.enemy_evolution.time_factor = 7e-05 + 3e-06 * (objective.chronojumps + objective.passivejumps)
	game.forces.scrapyard.set_ammo_damage_modifier("bullet", 0.01 * objective.chronojumps)
	game.forces.scrapyard.set_turret_attack_modifier("gun-turret", 0.01 * objective.chronojumps)
	game.forces.enemy.set_ammo_damage_modifier("melee", 0.1 * objective.passivejumps)
	game.forces.enemy.set_ammo_damage_modifier("biological", 0.1 * objective.passivejumps)
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.8
end

return Public_chrono
