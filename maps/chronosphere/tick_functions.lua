local Public = {}

function Public.check_chronoprogress()
	local objective = global.objective
	--game.print(objective.chronotimer)
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

function Public.charge_chronosphere()
	if not global.acumulators then return end
	local objective = global.objective
	if not objective.chronotimer then return end
	if objective.chronotimer < 20 then return end
	if objective.planet[1].name.id == 17 then return end
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

function Public.transfer_pollution()
	local surface = game.surfaces["cargo_wagon"]
	if not surface then return end
	local pollution = surface.get_total_pollution() * (3 / (global.objective.filterupgradetier / 3 + 1)) * global.difficulty_vote_value
	game.surfaces[global.active_surface_index].pollute(global.locomotive.position, pollution)
	surface.clear_pollution()
end

function Public.boost_evolution()
	local objective = global.objective
	if objective.passivetimer > objective.chrononeeds * 0.50 and objective.chronojumps > 5 then
		local evolution = game.forces.enemy.evolution_factor
		evolution = evolution + (evolution / 2000) * global.difficulty_vote_value
		if evolution > 1 then evolution = 1 end
		game.forces.enemy.evolution_factor = evolution
	end
end

function Public.move_items()
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

function Public.output_items()
	if global.objective.game_lost == true then return end
	if not global.outchests then return end
	if not global.locomotive_cargo2 then return end
	if not global.locomotive_cargo3 then return end
	if global.objective.outupgradetier ~= 1 then return end
	for i = 1, 4, 1 do
		if not global.outchests[i].valid then return end
		local inv = global.outchests[i].get_inventory(defines.inventory.chest)
		inv.sort_and_merge()
		local items = inv.get_contents()
		for item, count in pairs(items) do
			local inserted = nil
			if i <= 2 then
				inserted = global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
			else
				inserted = global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
			end
			if inserted > 0 then
				local removed = inv.remove({name = item, count = inserted})
			end
		end
	end
end

function Public.repair_train()
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

return Public
