local Public_tick = {}

local math_random = math.random
local math_floor = math.floor

function Public_tick.check_chronoprogress()
	local objective = global.objective
  local map_gen_settings = Public_tick.get_map_gen_settings()
	--game.print(objective.chronotimer)
  if objective.planet[1].name.id == 19 then
    if objective.passivetimer == 10 then
      game.print({"chronosphere.message_danger1"}, {r=0.98, g=0.66, b=0.22})
      game.print({"chronosphere.message_danger2"}, {r=0.98, g=0.66, b=0.22})
    elseif objective.passivetimer == 25 then
      game.print({"chronosphere.message_danger3"}, {r=0.98, g=0, b=0})
    elseif objective.passivetimer == 30 then
      game.print({"chronosphere.message_danger4"}, {r=0.98, g=0, b=0})
    end
  end
	if objective.chronotimer == objective.chrononeeds - 180  then
		game.print({"chronosphere.message_jump180"}, {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 60  then
		game.print({"chronosphere.message_jump60"}, {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 30 then
		game.print({"chronosphere.message_jump30"}, {r=0.98, g=0.66, b=0.22})
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
      if item == "modular-armor" or item == "power-armor" or item == "power-armor-mk2" then
        --log("can't move armors")
      else
    		local inserted = output_inventory.insert({name = item, count = count})
    		if inserted > 0 then
    			local removed = input_inventory.remove({name = item, count = inserted})
    		end
      end
		end
    -- local items = {}
    -- for ii = 1, #input_inventory, 1 do
    --   items[#items + 1] = input_inventory[ii]
    -- end
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
      if item == "modular-armor" or item == "power-armor" or item == "power-armor-mk2" then
        --log("can't move armors")
      else
  			local inserted = nil
  			if i <= 2 then
  				inserted = global.locomotive_cargo[2].get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count, grid = item.grid})
  			else
  				inserted = global.locomotive_cargo[3].get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count, grid = item.grid})
  			end
  			if inserted > 0 then
  				local removed = inv.remove({name = item, count = inserted})
  			end
      end
		end
	end
end

function Public_tick.repair_train()
	local objective = global.objective
	if not game.surfaces["cargo_wagon"] then return 0 end
	if objective.game_lost == true then return 0 end
	if objective.health < objective.max_health then
		local inv = global.upgradechest[1].get_inventory(defines.inventory.chest)
		local count = inv.get_item_count("repair-pack")
		if count >= 5 and objective.toolsupgradetier == 4 and objective.health + 750 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 5})
			return -750
		elseif count >= 4 and objective.toolsupgradetier == 3 and objective.health + 600 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 4})
			return -600
		elseif count >= 3 and objective.toolsupgradetier == 2 and objective.health + 450 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 3})
			return -450
		elseif count >= 2 and objective.toolsupgradetier == 1 and objective.health + 300 <= objective.max_health then
			inv.remove({name = "repair-pack", count = 2})
			return -300
		elseif count >= 1 then
			inv.remove({name = "repair-pack", count = 1})
			return -150
		end
	end
  return 0
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
        game.print({"chronosphere.message_nuke"}, {r=0.98, g=0, b=0})
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
  if objective.chronotimer > objective.chrononeeds - 182 or objective.passivetimer < 30 then return end
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
        if players[i] and players[i].tick < game.tick - 540 then
          --log("spawning corpse")
          local player_inv = {}
          local items = {}
          player_inv[1] = game.players[players[i].index].get_inventory(defines.inventory.character_main)
          player_inv[2] = game.players[players[i].index].get_inventory(defines.inventory.character_armor)
          player_inv[3] = game.players[players[i].index].get_inventory(defines.inventory.character_guns)
          player_inv[4] = game.players[players[i].index].get_inventory(defines.inventory.character_ammo)
          player_inv[5] = game.players[players[i].index].get_inventory(defines.inventory.character_trash)
          game.print({"chronosphere.message_accident"}, {r=0.98, g=0.66, b=0.22})
          local e = surface.create_entity({name = "character", position = game.forces.player.get_spawn_position(surface), force = "neutral"})
          local inv = e.get_inventory(defines.inventory.character_main)
          for ii = 1, 5, 1 do
            if player_inv[ii].valid then
              for iii = 1, #player_inv[ii], 1 do
                if player_inv[ii][iii].valid then
                  items[#items + 1] = player_inv[ii][iii]
                end
              end
            end
          end
          if #items > 0 then
            for item = 1, #items, 1 do
              if items[item].valid then
      			     inv.insert(items[item])
              end
            end
          end
          e.die("neutral")
          for ii = 1, 5, 1 do
            if player_inv[ii].valid then
              player_inv[ii].clear()
            end
          end
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
