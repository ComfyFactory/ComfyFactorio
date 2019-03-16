local event = require 'utils.event'

local food_values = {
	["automation-science-pack"] =	{value = 0.001, name = "automation science"},
	["logistic-science-pack"] =			{value = 0.00292, name = "logistic science"},
	["military-science-pack"] =			{value = 0.01225, name = "military science"},
	["chemical-science-pack"] = 		{value = 0.02392, name = "chemical science"},
	["production-science-pack"] =	{value = 0.080, name = "production science"},
	["utility-science-pack"] =			{value = 0.13875, name = "utility science"},
	["space-science-pack"] = 			{value = 0.420, name = "space science"},
}

local threat_values = {
	["small_biter"] = 1,
	["medium_biter"] = 3,
	["big_biter"] = 5,
	["behemoth_biter"] = 10,
	["small_spitter"] = 1,
	["medium_spitter"] = 3,
	["big_spitter"] = 5,
	["behemoth_spitter"] = 10
}

local force_translation = {
	["south_biters"] = "south",
	["north_biters"] = "north"
}

local enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

local function set_biter_endgame_damage(force_name, biter_force)
	if biter_force.evolution_factor ~= 1 then return end
	local m = (math.ceil(global.bb_evolution[force_name] * 100) / 100) - 1
	m = m
	biter_force.set_ammo_damage_modifier("melee", m)
	biter_force.set_ammo_damage_modifier("biological", m)
	biter_force.set_ammo_damage_modifier("artillery-shell", m)
	biter_force.set_ammo_damage_modifier("flamethrower", m)
	biter_force.set_ammo_damage_modifier("laser-turret", m)
end

local function feed_biters(player, food)	
	--local enemy_force_name = enemy_team_of[player.force.name]  ---------------
	
	enemy_force_name = player.force.name
	
	local biter_force_name = enemy_force_name .. "_biters"
	
	local i = player.get_main_inventory()
	local flask_amount = i.get_item_count(food)
	if flask_amount == 0 then
		player.print("You have no " .. food_values[food].name .. " flask in your inventory.", {r = 0.98, g = 0.66, b = 0.22})
		return
	end
	
	--i.remove({name = food, count = flask_amount})
								
	if flask_amount >= 20 then
		game.print(player.name .. " fed " .. flask_amount .. " flasks of " .. food_values[food].name .. " juice to team " .. enemy_force_name .. "'s biters!", {r = 0.98, g = 0.66, b = 0.22})
	else
		if flask_amount > 1 then
			player.print("You fed one flask of " .. food_values[food].name .. " juice to the enemy team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		else
			player.print("You fed " .. flask_amount .. " flasks of " .. food_values[food].name .. " juice to the enemy team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		end				
	end								
	
	--ADD TOTAL FOOD FEED
	--global.bb_total_food[enemy_force_name] = global.bb_total_food[enemy_force_name] + (food_values[food].value * flask_amount)	
	
	for a = 1, flask_amount, 1 do				
		--SET THREAT INCOME
		local e = (global.bb_evolution[enemy_force_name] * 100) + 1
		local diminishing_modifier = 1 / (10 ^ (e * 0.03))
		global.bb_threat_income[enemy_force_name] = global.bb_threat_income[enemy_force_name] + (food_values[food].value * diminishing_modifier * 10)
		
		---SET EVOLUTION
		local e = (game.forces[biter_force_name].evolution_factor * 100) + 1
		local diminishing_modifier = 1 / (10 ^ (e * 0.03))
		global.bb_evolution[enemy_force_name] = global.bb_evolution[enemy_force_name] + (food_values[food].value * diminishing_modifier)
		if global.bb_evolution[enemy_force_name] < 1 then
			game.forces[biter_force_name].evolution_factor = global.bb_evolution[enemy_force_name]
		else
			game.forces[biter_force_name].evolution_factor = 1
		end
	end
	
	--ADD INSTANT THREAT
	global.bb_threat[enemy_force_name] = global.bb_threat[enemy_force_name] + (food_values[food].value * 100 * flask_amount)
	
	set_biter_endgame_damage(enemy_force_name, game.forces[biter_force_name])
	
	global.bb_evasion[biter_force_name] = (global.bb_evolution[enemy_force_name] - 1) * 333
	if global.bb_evasion[biter_force_name] > 900 then global.bb_evasion[biter_force_name] = 900 end
end

--Biter Evasion
local math_random = math.random
local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if event.entity.type ~= "unit" then return end
	if global.bb_evasion[event.entity.force.name] < math_random(1,1000) then return end
	event.entity.health = event.entity.health + event.final_damage_amount			
end

--Biter Threat Value Reduction
local function on_entity_died(event)
	if not event.entity.valid then return end
	if threat_values[event.entity.name] then
		global.bb_threat[event.entity.force.name] = global.bb_threat[event.entity.force.name] - threat_values[event.entity.name]
		return
	end	
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)

return feed_biters