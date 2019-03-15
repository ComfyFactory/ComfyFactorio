local event = require 'utils.event'

local food_values = {
	["automation-science-pack"] =	{value = 100, name = "automation science"},
	["logistic-science-pack"] =			{value = 292, name = "logistic science"},
	["military-science-pack"] =			{value = 1225, name = "military science"},
	["chemical-science-pack"] = 		{value = 2392, name = "chemical science"},
	["production-science-pack"] =	{value = 8000, name = "production science"},
	["utility-science-pack"] =			{value = 13875, name = "utility science"},
	["space-science-pack"] = 			{value = 42000, name = "space science"},
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

local function set_evolution(team)
	
end

local function feed_biters(player, food)	
	local enemy_team = enemy_team_of[player.force.name]
	
	local i = player.get_main_inventory()
	local flask_amount = i.get_item_count(food)
	if flask_amount == 0 then
		player.print("You have no " .. food_values[food].name .. " flask in your inventory.", {r = 0.98, g = 0.66, b = 0.22})
		return
	end
	
	i.remove({name = food, count = flask_amount})
								
	if flask_amount >= 20 then
		game.print(player.name .. " fed " .. flask_amount .. " flasks of " .. food_values[food].name .. " juice to team " .. enemy_team .. "'s biters!", {r = 0.98, g = 0.66, b = 0.22})
	else
		if flask_amount > 1 then
			player.print("You fed one flask of " .. food_values[food].name .. " juice to the enemy team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		else
			player.print("You fed " .. flask_amount .. " flasks of " .. food_values[food].name .. " juice to the enemy team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		end				
	end								
	
	--ADD TOTAL FOOD FED
	global.bb_total_food[enemy_team] = global.bb_total_food[enemy_team] + (food_values[food].value * flask_amount)	
	
	---SET EVOLUTION
	for a = 1, flask_amount, 1 do
		local evo_modifier = (1 / ((((game.forces[enemy_team .. "_biters"].evolution_factor + 0.00001)^2.9)+8000)/500))	
		global.bb_evolution[enemy_team] = global.bb_evolution[enemy_team] + (food_values[food].value * evo_modifier)
	end
	
	if global.bb_evolution[enemy_team] < 1 then
		game.forces[enemy_team .. "_biters"].evolution_factor = global.bb_evolution[enemy_team]
	else
		game.forces[enemy_team .. "_biters"].evolution_factor = 1
	end
	
	--ADD INSTANT THREAT
	local evo_modifier = (1 / ((((game.forces[enemy_team .. "_biters"].evolution_factor + 0.00001)^2.9)+8000)/500))
	global.bb_threat[enemy_team] = global.bb_threat[enemy_team] + (food_values[food].value * evo_modifier * flask_amount)
	
	--SET THREAT INCOME
	
	
	
	--global.bb_total_food = {}
	--global.bb_evolution = {}
	--global.bb_evasion = {}
	--global.bb_threat_income = {}
	--global.bb_threat = {}
end

--Biter Evasion
local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if math.random(1,2) == 1 then return end
	if event.entity.type ~= "unit" then return end	
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