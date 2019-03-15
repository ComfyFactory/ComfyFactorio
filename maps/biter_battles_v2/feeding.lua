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

local function feed_biters(player, food)
	game.print(food_values[food].name)
	local enemy_team = enemy_team_of[player.force.name]
	global.bb_threat[enemy_team] = global.bb_threat[enemy_team] + food_values[food].value
	global.bb_total_food[enemy_team] = global.bb_total_food[enemy_team] + food_values[food].value
	
	global.bb_evolution[enemy_team] = math.ceil(global.bb_total_food[enemy_team] * 0.001)
	
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