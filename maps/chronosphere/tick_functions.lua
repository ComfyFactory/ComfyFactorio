local Public_tick = {}

local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil
local math_min = math.min

function Public_tick.check_chronoprogress()
	local objective = global.objective
	--game.print(objective.chronotimer)
  if objective.planet[1].name.id == 19 then
    if objective.passivetimer == 10 then
      game.print("Comfylatron: We have a problem! We got disrupted in mid-jump, only part of energy got used, and here we landed. It might have been a trap!", {r=0.98, g=0.66, b=0.22})
      game.print("Comfylatron: My analysis says that charging needs full energy reset to work again, so we are stuck there until next full jump.", {r=0.98, g=0.66, b=0.22})
    elseif objective.passivetimer == 25 then
      game.print("Robot voice: INTRUDER ALERT! Lifeforms detected! Must eliminate!", {r=0.98, g=0, b=0})
    elseif objective.passivetimer == 30 then
      game.print("Robot voice: Nuclear missiles armed, launch countdown enabled.", {r=0.98, g=0, b=0})
    end
  end
	if objective.chronotimer == objective.chrononeeds - 180  then
		game.print("Comfylatron: Acumulator charging disabled, 180 seconds countdown to jump!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 60  then
		game.print("Comfylatron: ChronoTrain nearly charged! Grab what you can, we leaving in 60 seconds!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 30 then
		game.print("Comfylatron: You better hurry up! 30 seconds remaining!", {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer >= objective.chrononeeds - 10 and objective.chrononeeds - objective.chronotimer > 0 then
		game.print("Comfylatron: Jump in " .. objective.chrononeeds - objective.chronotimer .. " seconds!", {r=0.98, g=0.66, b=0.22})
	end
	if objective.chronotimer >= objective.chrononeeds then
		return true
	end
  return false
end

function Public_tick.charge_chronosphere()
	if not global.acumulators then return end
	local objective = global.objective
	if not objective.chronotimer then return end
	if objective.chronotimer < 20 then return end
	if objective.planet[1].name.id == 17 or objective.planet[1].name.id == 19 then return end
	local acus = global.acumulators
	if #acus < 1 then return end
	for i = 1, #acus, 1 do
		if not acus[i].valid then return end
		local energy = acus[i].energy
		if energy > 3000000 and objective.chronotimer < objective.chrononeeds - 182 and objective.chronotimer > 130 then
			acus[i].energy = acus[i].energy - 3000000
			objective.chronotimer = objective.chronotimer + 1
			game.surfaces[global.active_surface_index].pollute(global.locomotive.position, (10 + 2 * objective.chronojumps) * (4 / (objective.filterupgradetier / 2 + 1)) * global.difficulty_vote_value)
			--log("energy charged from acu")
		end
	end
end

function Public_tick.transfer_pollution()
	local surface = game.surfaces["cargo_wagon"]
	if not surface then return end
	local pollution = surface.get_total_pollution() * (3 / (global.objective.filterupgradetier / 3 + 1)) * global.difficulty_vote_value
	game.surfaces[global.active_surface_index].pollute(global.locomotive.position, pollution)
	surface.clear_pollution()
end

function Public_tick.boost_evolution()
	local objective = global.objective
	if objective.passivetimer > objective.chrononeeds * 0.50 and objective.chronojumps > 5 then
		local evolution = game.forces.enemy.evolution_factor
		evolution = evolution + (evolution / 500) * global.difficulty_vote_value
		if evolution > 1 then evolution = 1 end
		game.forces.enemy.evolution_factor = evolution
	end
end

function Public_tick.move_items()
	if not global.comfychests then return end
	if not global.comfychests2 then return end
	if global.objective.game_lost == true then return end
  local input = global.comfychests
  local output = global.comfychests2
	for i = 1, 24, 1 do
		if not input[i].valid then return end
		if not output[i].valid then  return end

		local input_inventory = input[i].get_inventory(defines.inventory.chest)
		local output_inventory = output[i].get_inventory(defines.inventory.chest)
		input_inventory.sort_and_merge()
		local items = input_inventory.get_contents()

		for item, count in pairs(items) do
			local inserted = output_inventory.insert({name = item, count = count})
			if inserted > 0 then
				local removed = input_inventory.remove({name = item, count = inserted})
			end
		end
	end
end

function Public_tick.output_items()
	if global.objective.game_lost == true then return end
	if not global.outchests then return end
	if not global.locomotive_cargo[2] then return end
	if not global.locomotive_cargo[3] then return end
	if global.objective.outupgradetier ~= 1 then return end
	for i = 1, 4, 1 do
		if not global.outchests[i].valid then return end
		local inv = global.outchests[i].get_inventory(defines.inventory.chest)
		inv.sort_and_merge()
		local items = inv.get_contents()
		for item, count in pairs(items) do
			local inserted = nil
			if i <= 2 then
				inserted = global.locomotive_cargo[2].get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
			else
				inserted = global.locomotive_cargo[3].get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
			end
			if inserted > 0 then
				local removed = inv.remove({name = item, count = inserted})
			end
		end
	end
end

function Public_tick.repair_train()
	local objective = global.objective
	if not game.surfaces["cargo_wagon"] then return 0 end
	if objective.game_lost == true then return 0 end
	local count = 0
	if objective.health < objective.max_health then
		count = global.upgradechest[1].get_inventory(defines.inventory.chest).get_item_count("repair-pack")
		count = math_min(count, objective.toolsupgradetier + 1, math_ceil((objective.max_health - objective.health) / 150))
		if count > 0 then inv.remove({name = "repair-pack", count = count}) end
	end
  return count * -150
end

function Public_tick.spawn_poison()
  local surface = game.surfaces[global.active_surface_index]
  local random_x = math_random(-460,460)
  local random_y = math_random(-460,460)
  local tile = surface.get_tile(random_x, random_y)
  if not tile.valid then return end
  if tile.name == "water-shallow" or tile.name == "water-mud" then
    surface.create_entity({name = "poison-cloud", position = {x = random_x, y = random_y}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x + 2, y = random_y + 2}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x - 2, y = random_y - 2}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x + 2, y = random_y - 2}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x - 2, y = random_y + 2}})
  end
end

local function launch_nukes()
  local surface = game.surfaces[global.active_surface_index]
  local objective = global.objective
  if objective.dangers and #objective.dangers > 1 then
    for i = 1, #objective.dangers, 1 do
      if objective.dangers[i].destroyed == false then
        local fake_shooter = surface.create_entity({name = "character", position = objective.dangers[i].silo.position, force = "enemy"})
        surface.create_entity({name = "atomic-rocket", position = objective.dangers[i].silo.position, force = "enemy", speed = 1, max_range = 800, target = global.locomotive, source = fake_shooter})
        game.print("Warning: Nuclear missile launched.", {r=0.98, g=0, b=0})
      end
    end
  end
end

function Public_tick.dangertimer()
  local objective = global.objective
  local timer = objective.dangertimer
  if timer == 0 then return end
  if objective.planet[1].name.id == 19 then
    timer = timer - 1
    if objective.dangers and #objective.dangers > 0 then
      for i = 1, #objective.dangers, 1 do
        if objective.dangers[i].destroyed == false then
          if timer == 15 then
            objective.dangers[i].silo.launch_rocket()
            objective.dangers[i].silo.rocket_parts = 100
          end
          rendering.set_text(objective.dangers[i].timer, math_floor(timer / 60) .. " min, " .. timer % 60 .. " s")
        end
      end
    end
  else
    timer = 1200
  end
  if timer < 0 then timer = 0 end
  if timer == 0 then
    launch_nukes()
    timer = 90
  end

  objective.dangertimer = timer
end

function Public_tick.offline_players()
  local objective = global.objective
  if objective.chronotimer > objective.chrononeeds - 182 then return end
  local current_tick = game.tick
  local players = objective.offline_players
  local surface = game.surfaces[global.active_surface_index]
  if #players > 0 then
    --log("nonzero offline players")
    local later = {}
    for i = 1, #players, 1 do
      if players[i] and game.players[players[i].index] and game.players[players[i].index].connected then
        --game.print("deleting already online character from list")
        players[i] = nil
      else
        if players[i] and players[i].tick < game.tick - 54000 then
          --log("spawning corpse")
          local player_inv = {}
          player_inv[1] = game.players[players[i].index].get_inventory(defines.inventory.character_main)
          player_inv[2] = game.players[players[i].index].get_inventory(defines.inventory.character_armor)
          player_inv[3] = game.players[players[i].index].get_inventory(defines.inventory.character_guns)
          player_inv[4] = game.players[players[i].index].get_inventory(defines.inventory.character_ammo)
          player_inv[5] = game.players[players[i].index].get_inventory(defines.inventory.character_trash)
          game.print("Comfylatron: Offline player had an accident, and dropped his items on ground around locomotive.")
          local e = surface.create_entity({name = "character", position = game.forces.player.get_spawn_position(surface), force = "player"})
          local inv = e.get_inventory(defines.inventory.character_main)
          for i = 1, 5, 1 do
            if player_inv[i].valid then
              local items = player_inv[i].get_contents()
              for item, count in pairs(items) do
          			inv.insert({name = item, count = count})
                player_inv[i].remove({name = item, count = count})
              end
            else
              --log("invalid")
              --game.print("invalid")
            end
          end
          e.die("neutral")
          players[i] = nil
        else
          --game.print("keeping player in list")
          later[#later + 1] = players[i]
        end
      end
    end
    players = {}
    if #later > 0 then
      for i = 1, #later, 1 do
        players[#players + 1] = later[i]
      end
    end
  end
end


return Public_tick
