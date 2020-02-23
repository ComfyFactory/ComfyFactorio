
local Public = {}
local math_floor = math.floor
local Server = require 'utils.server'

local function spawn_acumulators()
	local x = -28
	local y = -252
	local yy = global.objective.acuupgradetier * 2
	local surface = game.surfaces["cargo_wagon"]
	if yy > 8 then yy = yy + 2 end
	if yy > 26 then yy = yy + 2 end
	if yy > 44 then yy = yy + 2 end
	for i = 1, 27, 1 do
		local acumulator = surface.create_entity({name = "accumulator", position = {x + 2 * i, y + yy}, force="player", create_build_effect_smoke = false})
		acumulator.minable = false
		acumulator.destructible = false
		table.insert(global.acumulators, acumulator)
	end
end

local function check_upgrade_hp()
  local objective = global.objective
	if not game.surfaces["cargo_wagon"] then return end
	if objective.game_lost == true then return end
	if global.upgradechest[2] and global.upgradechest[2].valid then
		local inv = global.upgradechest[2].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("copper-plate")
		local coincost = math_floor(500 * (1 + objective.hpupgradetier /2))
		if countcoins >= coincost and count2 >= 1500 and objective.hpupgradetier < 36 then
			inv.remove({name = "coin", count = coincost})
			inv.remove({name = "copper-plate", count = 3000})
			game.print("Comfylatron: Train's max HP was upgraded.", {r=0.98, g=0.66, b=0.22})
			objective.hpupgradetier = objective.hpupgradetier + 1
			objective.max_health = 10000 + 2500 * objective.hpupgradetier
			rendering.set_text(global.objective.health_text, "HP: " .. global.objective.health .. " / " .. global.objective.max_health)
		end
	end
end

local function check_upgrade_filter()
  local objective = global.objective
  if global.upgradechest[3] and global.upgradechest[3].valid then
    local inv = global.upgradechest[3].get_inventory(defines.inventory.chest)
    local countcoins = inv.get_item_count("coin")
    local count2 = inv.get_item_count("electronic-circuit")
    if countcoins >= 5000 and count2 >= 2000 and objective.filterupgradetier < 9 and objective.chronojumps >= (objective.filterupgradetier + 1) * 3 then
      inv.remove({name = "coin", count = 5000})
      inv.remove({name = "electronic-circuit", count = 2000})
      game.print("Comfylatron: Train's pollution filter was upgraded.", {r=0.98, g=0.66, b=0.22})
      objective.filterupgradetier = objective.filterupgradetier + 1
    end
  end
end

local function check_upgrade_acu()
  local objective = global.objective
  if global.upgradechest[4] and global.upgradechest[4].valid then
		local inv = global.upgradechest[4].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("battery")
    local coincost = math_floor(2000 * (1 + objective.acuupgradetier /4))
		if countcoins >= coincost and count2 >= 200 and objective.acuupgradetier < 24 then
			inv.remove({name = "coin", count = coincost})
			inv.remove({name = "battery", count = 200})
			game.print("Comfylatron: Train's acumulator capacity was upgraded.", {r=0.98, g=0.66, b=0.22})
			objective.acuupgradetier = objective.acuupgradetier + 1
			spawn_acumulators()
		end
	end
end

local function check_upgrade_pickup()
  local objective = global.objective
  if global.upgradechest[5] and global.upgradechest[5].valid then
		local inv = global.upgradechest[5].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("long-handed-inserter")
		local coincost = 1000 * (1 + objective.pickupupgradetier)
		if countcoins >= coincost and count2 >= 400 and objective.pickupupgradetier < 4 then
			inv.remove({name = "coin", count = coincost})
			inv.remove({name = "long-handed-inserter", count = 400})
			game.print("Comfylatron: Players now have additional red inserter installed on shoulders, increasing their item pickup range.", {r=0.98, g=0.66, b=0.22})
			objective.pickupupgradetier = objective.pickupupgradetier + 1
			game.forces.player.character_loot_pickup_distance_bonus = game.forces.player.character_loot_pickup_distance_bonus + 1
		end
	end
end

local function check_upgrade_inv()
  local objective = global.objective
  if global.upgradechest[6] and global.upgradechest[6].valid then
		local inv = global.upgradechest[6].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local item = "computer"
		if objective.invupgradetier == 0 then
			item = "wooden-chest"
		elseif objective.invupgradetier == 1 then
			item = "iron-chest"
		elseif objective.invupgradetier == 2 then
			item = "steel-chest"
		elseif objective.invupgradetier == 3 then
			item = "logistic-chest-storage"
		end
		local count2 = inv.get_item_count(item)
		local coincost = 2000 * (1 + objective.invupgradetier)
		if countcoins >= coincost and count2 >= 250 and objective.invupgradetier < 4 and objective.chronojumps >= (objective.invupgradetier + 1) * 5 then
			inv.remove({name = "coin", count = coincost})
			inv.remove({name = item, count = 250})
			game.print("Comfylatron: Players now can carry more trash in their unsorted inventories.", {r=0.98, g=0.66, b=0.22})
			objective.invupgradetier = objective.invupgradetier + 1
			game.forces.player.character_inventory_slots_bonus = game.forces.player.character_inventory_slots_bonus + 10
		end
	end
end

local function check_upgrade_tools()
  local objective = global.objective
  if global.upgradechest[7] and global.upgradechest[7].valid then
		local inv = global.upgradechest[7].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("repair-pack")
		local coincost = 1000 * (1 + objective.toolsupgradetier)
		local toolscost = 200 * (1 + objective.toolsupgradetier)
		if countcoins >= coincost and count2 >= toolscost and objective.toolsupgradetier < 4 then
			inv.remove({name = "coin", count = coincost})
			inv.remove({name = "repair-pack", count = toolscost})
			game.print("Comfylatron: Train now gets repaired with additional repair kit at once.", {r=0.98, g=0.66, b=0.22})
			objective.toolsupgradetier = objective.toolsupgradetier + 1
		end
	end
end

local function check_upgrade_water()
  local objective = global.objective
  if global.upgradechest[8] and global.upgradechest[8].valid and game.surfaces["cargo_wagon"].valid then
		local inv = global.upgradechest[8].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("pipe")
		if countcoins >= 2000 and count2 >= 500 and objective.waterupgradetier < 1 then
			inv.remove({name = "coin", count = 2000})
			inv.remove({name = "pipe", count = 500})
			game.print("Comfylatron: Train now has piping system for additional water sources.", {r=0.98, g=0.66, b=0.22})
			objective.waterupgradetier = objective.waterupgradetier + 1
      local positions = {{28,66},{28,-62},{-29,66},{-29,-62}}
      for i = 1, 4, 1 do
        local e = game.surfaces["cargo_wagon"].create_entity({name = "offshore-pump", position = positions[i], force="player"})
        e.destructible = false
        e.minable = false
      end
		end
	end
end

local function check_upgrade_out()
  local objective = global.objective
  if global.upgradechest[9] and global.upgradechest[9].valid and game.surfaces["cargo_wagon"].valid then
		local inv = global.upgradechest[9].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("fast-inserter")
		if countcoins >= 2000 and count2 >= 100 and objective.outupgradetier < 1 then
			inv.remove({name = "coin", count = 2000})
			inv.remove({name = "fast-inserter", count = 100})
			game.print("Comfylatron: Train now has output chests.", {r=0.98, g=0.66, b=0.22})
			objective.outupgradetier = objective.outupgradetier + 1
      local positions = {{-16,-62},{15,-62},{-16,66},{15,66}}
			local out = {}
			for i = 1, 4, 1 do
        local e = game.surfaces["cargo_wagon"].create_entity({name = "compilatron-chest", position = positions[i], force = "player"})
				e.destructible = false
				e.minable = false
				global.outchests[i] = e
				out[i] = rendering.draw_text{
					text = "Output",
					surface = e.surface,
					target = e,
					target_offset = {0, -1.5},
					color = global.locomotive.color,
					scale = 0.80,
					font = "default-game",
					alignment = "center",
					scale_with_zoom = false
				}
			end
		end
	end
end

local function check_upgrade_box()
  local objective = global.objective
  if global.upgradechest[10] and global.upgradechest[10].valid and game.surfaces["cargo_wagon"].valid then
		local inv = global.upgradechest[10].get_inventory(defines.inventory.chest)
		local countcoins = inv.get_item_count("coin")
		local item = "computer"
		if objective.boxupgradetier == 0 then
			item = "wooden-chest"
		elseif objective.boxupgradetier == 1 then
			item = "iron-chest"
		elseif objective.boxupgradetier == 2 then
			item = "steel-chest"
		elseif objective.boxupgradetier == 3 then
			item = "logistic-chest-storage"
		end
		local count2 = inv.get_item_count(item)
		if countcoins >= 5000 and count2 >= 250 and objective.boxupgradetier < 4 and objective.chronojumps >= (objective.boxupgradetier + 1) * 5 then
			inv.remove({name = "coin", count = 5000})
			inv.remove({name = item, count = 250})
			game.print("Comfylatron: Cargo wagons now have enlargened storage.", {r=0.98, g=0.66, b=0.22})
			objective.boxupgradetier = objective.boxupgradetier + 1
			local chests = {}
      local positions = {
        [1] = {x = {-33, 32}, y = {-189, -127, -61, 1, 67, 129}}
      }
      for i = 1, 58, 1 do
        for ii = 1, 6, 1 do
          if objective.boxupgradetier == 1 then
            chests[#chests + 1] = {name = "wooden-chest", position = {x = positions[1].x[1] ,y = positions[1].y[ii] + i}, force = "player"}
            chests[#chests + 1] = {name = "wooden-chest", position = {x = positions[1].x[2] ,y = positions[1].y[ii] + i}, force = "player"}
          elseif objective.boxupgradetier == 2 then
            chests[#chests + 1] = {name = "iron-chest", position = {x = positions[1].x[1] ,y = positions[1].y[ii] + i}, force = "player"}
            chests[#chests + 1] = {name = "iron-chest", position = {x = positions[1].x[2] ,y = positions[1].y[ii] + i}, force = "player"}
          elseif objective.boxupgradetier == 3 then
            chests[#chests + 1] = {name = "steel-chest", position = {x = positions[1].x[1] ,y = positions[1].y[ii] + i}, force = "player"}
            chests[#chests + 1] = {name = "steel-chest", position = {x = positions[1].x[2] ,y = positions[1].y[ii] + i}, force = "player"}
          elseif objective.boxupgradetier == 4 then
            chests[#chests + 1] = {name = "logistic-chest-storage", position = {x = positions[1].x[1] ,y = positions[1].y[ii] + i}, force = "player"}
            chests[#chests + 1] = {name = "logistic-chest-storage", position = {x = positions[1].x[2] ,y = positions[1].y[ii] + i}, force = "player"}
          end
        end
      end
			local surface = game.surfaces["cargo_wagon"]
			for i = 1, #chests, 1 do
        if objective.boxupgradetier == 1 then
          surface.set_tiles({{name = "tutorial-grid", position = chests[i].position}})
        end
				local e = surface.create_entity(chests[i])
				local old = nil
				if e.name == "iron-chest" then old = surface.find_entity("wooden-chest", e.position)
				elseif e.name == "steel-chest" then old = surface.find_entity("iron-chest", e.position)
				elseif e.name == "logistic-chest-storage" then old = surface.find_entity("steel-chest", e.position)
				end
				if old then
					local items = old.get_inventory(defines.inventory.chest).get_contents()
					for item, count in pairs(items) do
						e.insert({name = item, count = count})
					end
					old.destroy()
				end
				e.destructible = false
				e.minable = false
			end
		end
	end
end

local function check_poisondefense()
  local objective = global.objective
  if global.upgradechest[11] and global.upgradechest[11].valid then
    local inv = global.upgradechest[11].get_inventory(defines.inventory.chest)
    local countcoins = inv.get_item_count("coin")
		local count2 = inv.get_item_count("poison-capsule")
    if countcoins >= 1000 and count2 >= 50 and objective.poisondefense < 4 then
			inv.remove({name = "coin", count = 1000})
			inv.remove({name = "poison-capsule", count = 50})
			game.print("Comfylatron: I don't believe in your defense skills. I equipped train with poison defense.", {r=0.98, g=0.66, b=0.22})
			objective.poisondefense = objective.poisondefense + 1
		end
  end
end

local function check_upgrade_computer()
  local objective = global.objective
  if global.upgradechest[12] and global.upgradechest[12].valid then
    local inv = global.upgradechest[12].get_inventory(defines.inventory.chest)
    local countcoins = inv.get_item_count("coin")
    local count2 = inv.get_item_count("advanced-circuit")
    local count3 = inv.get_item_count("processing-unit")
    local count4 = inv.get_item_count("low-density-structure")
    local count5 = inv.get_item_count("rocket-control-unit")
    local count6 = inv.get_item_count("uranium-fuel-cell")
    local count7 = inv.get_item_count("nuclear-reactor")
    local count8 = inv.get_item_count("copper-plate")
    local count9 = inv.get_item_count("rocket-silo")
    local count10 = inv.get_item_count("satellite")

    if countcoins >= 5000 and count2 >= 1000 and count8 >= 2000 and objective.computerupgrade == 0 and objective.chronojumps >= 15 then
      inv.remove({name = "coin", count = 5000})
      inv.remove({name = "advanced-circuit", count = 1000})
      inv.remove({name = "copper-plate", count = 2000})
      game.print("Comfylatron: Thanks for fixing train navigation. I can now get us rid of very poor worlds. It will still need more work though.", {r=0.98, g=0.66, b=0.22})
      objective.computerupgrade = objective.computerupgrade + 1
    elseif countcoins >= 10000 and count3 >= 1000 and count7 >= 1 and objective.computerupgrade == 1 and objective.chronojumps >= 20 then
      inv.remove({name = "coin", count = 10000})
      inv.remove({name = "processing-unit", count = 1000})
      inv.remove({name = "nuclear-reactor", count = 1})
      objective.computerupgrade = objective.computerupgrade + 1
      game.print("Comfylatron: Perfect! Now we have train reactor and even better destination precision. I will get to you later what still needs to be done.", {r=0.98, g=0.66, b=0.22})
    elseif objective.computerupgrade == 2 and objective.chronojumps >= 25 then
      if countcoins >= 2000 and count4 >= 100 and count5 >= 100 and count6 >= 50 and objective.computerparts < 10 then
        inv.remove({name = "coin", count = 2000})
        inv.remove({name = "low-density-structure", count = 100})
        inv.remove({name = "rocket-control-unit", count = 100})
        inv.remove({name = "uranium-fuel-cell", count = 50 })
        objective.computerparts = objective.computerparts + 1
        if objective.computerparts < 10 then
          game.print("Comfylatron: That's another processor part done! I still need " .. 10 - objective.computerparts .. " more of those parts.", {r=0.98, g=0.66, b=0.22})
        else
          game.print("Comfylatron: And this was last part of cpu brain done. Now we just need to synchronize our time correctly and we are done! Bring me satellite and rocket silo.", {r=0.98, g=0.66, b=0.22})
        end
      elseif objective.computerparts == 10 and count9 >= 1 and count10 >= 1 then
        inv.remove({name = "satellite", count = 1 })
        inv.remove({name = "rocket-silo", count = 1 })
        game.print("Comfylatron: Time synchronized. Calculating time and space destination. Success. Jump once more and let me deliver the fish finally. This trip is getting long.", {r=0.98, g=0.66, b=0.22})
        objective.computerupgrade = objective.computerupgrade + 1
      end
    end
  end
end

local function check_win()
  local objective = global.objective
  if global.fishchest then
    if global.fishchest.valid then
      local inv = global.fishchest.get_inventory(defines.inventory.chest)
      local countfish = inv.get_item_count("raw-fish")
      local enemies = game.surfaces[global.active_surface_index].count_entities_filtered{force = "enemy"}
      if countfish > 0 then
        inv.remove({name = "raw-fish", count = countfish})
        objective.mainscore = objective.mainscore + countfish
        if enemies > 0 then
          game.print("Comfylatron: You delivered fish, but there is still " .. enemies .. " enemies left. Kill them all so fish are safe!", {r=0.98, g=0.66, b=0.22})
        else
          if not global.game_reset_tick then
            global.game_reset_tick = game.tick + 18000
            objective.game_won = true
            objective.game_lost = true
            objective.chronotimer = 200000000 - 300
            for _, player in pairs(game.connected_players) do
        			player.play_sound{path="utility/game_won", volume_modifier=0.85}
        		end
            local message = "Comfylatron: Thank you with helping me on this delivery. It was tough one. I hope, that now, when all biters are dead, fish will be safe here forever...after all, we delivered " .. objective.mainscore .. " of them fishies."
            game.print(message, {r=0.98, g=0.66, b=0.22})
            Server.to_discord_embed(message)
          end
        end
      end
    end
  end
end



function Public.check_upgrades()
  local objective = global.objective
  if not global.upgradechest then return end
  if objective.hpupgradetier < 36 then
    check_upgrade_hp()
  end
  if objective.filterupgradetier < 9 then
    check_upgrade_filter()
  end
  if objective.acuupgradetier < 24 then
    check_upgrade_acu(Locomotive)
  end
  if objective.pickupupgradetier < 4 then
    check_upgrade_pickup()
  end
  if objective.invupgradetier < 4 then
    check_upgrade_inv()
  end
  if objective.toolsupgradetier < 4 then
    check_upgrade_tools()
  end
  if objective.waterupgradetier < 1 then
    check_upgrade_water()
  end
  if objective.outupgradetier < 1 then
    check_upgrade_out()
  end
  if objective.boxupgradetier < 4 and objective.chronojumps >= (objective.boxupgradetier + 1) * 5 then
    check_upgrade_box()
  end
  if objective.poisondefense < 4 then
    check_poisondefense()
  end
  if objective.computerupgrade < 3 and objective.chronojumps >= 15 then
    check_upgrade_computer()
  end
  if objective.planet[1].name.id == 17 then
    if global.fishchest then
      check_win()
    end
  end
end

function Public.trigger_poison()
  local objective = global.objective
  if objective.poisondefense > 0 and objective.poisontimeout == 0 then
    local objective = global.objective
    objective.poisondefense = objective.poisondefense - 1
    objective.poisontimeout = 120
    local objs = {global.locomotive, global.locomotive_cargo, global.locomotive_cargo2, global.locomotive_cargo3}
    local surface = objective.surface
    game.print("Comfylatron: Triggering poison defense. Let's kill everything!", {r=0.98, g=0.66, b=0.22})
    for i = 1, 4, 1 do
      surface.create_entity({name = "poison-capsule", position = objs[i].position, force = "player", target = objs[i], speed = 1 })
    end
    for i = 1 , #global.comfychests, 1 do
      surface.create_entity({name = "poison-capsule", position = global.comfychests[i].position, force = "player", target = global.comfychests[i], speed = 1 })
    end
  end
end

return Public
