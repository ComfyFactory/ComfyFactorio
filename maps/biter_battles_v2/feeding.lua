local food_values = {
	["automation-science-pack"] =	{value = 0.001, name = "automation science"},
	["logistic-science-pack"] =			{value = 0.0025, name = "logistic science"},
	["military-science-pack"] =			{value = 0.0096, name = "military science"},
	["chemical-science-pack"] = 		{value = 0.0264, name = "chemical science"},
	["production-science-pack"] =	{value = 0.08874, name = "production science"},
	["utility-science-pack"] =			{value = 0.09943, name = "utility science"},
	["space-science-pack"] = 			{value = 0.28957, name = "space science"},
}

local force_translation = {
	["south_biters"] = "south",
	["north_biters"] = "north"
}

local enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

local minimum_modifier = 125
local maximum_modifier = 250
local player_amount_for_maximum_threat_gain = 20

function get_instant_threat_player_count_modifier()
	local current_player_count = #game.forces.north.connected_players + #game.forces.south.connected_players
	local gain_per_player = (maximum_modifier - minimum_modifier) / player_amount_for_maximum_threat_gain
	local m = minimum_modifier + gain_per_player * current_player_count
	if m > maximum_modifier then m = maximum_modifier end
	return m
end

local function set_biter_endgame_modifiers(force)
	if force.evolution_factor ~= 1 then return end
	local damage_mod = (global.bb_evolution[force.name] - 1) * 2
	local evasion_mod = ((global.bb_evolution[force.name] - 1) * 2) + 1
	
	force.set_ammo_damage_modifier("melee", damage_mod)
	force.set_ammo_damage_modifier("biological", damage_mod)
	force.set_ammo_damage_modifier("artillery-shell", damage_mod)
	force.set_ammo_damage_modifier("flamethrower", damage_mod)
	force.set_ammo_damage_modifier("laser-turret", damage_mod)
	
	global.bb_evasion[force.name] = evasion_mod
end

local function feed_biters(player, food)	
	local enemy_force_name = enemy_team_of[player.force.name]  ---------------
	--enemy_force_name = player.force.name
	
	local biter_force_name = enemy_force_name .. "_biters"
	
	local i = player.get_main_inventory()
	local flask_amount = i.get_item_count(food)
	if flask_amount == 0 then
		player.print("You have no " .. food_values[food].name .. " flask in your inventory.", {r = 0.98, g = 0.66, b = 0.22})
		return
	end
	
	i.remove({name = food, count = flask_amount})
								
	if flask_amount >= 20 then
		game.print(player.name .. " fed " .. flask_amount .. " flasks of " .. food_values[food].name .. " juice to team " .. enemy_force_name .. "'s biters!", {r = 0.98, g = 0.66, b = 0.22})
	else
		if flask_amount == 1 then
			player.print("You fed one flask of " .. food_values[food].name .. " juice to the enemy team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		else
			player.print("You fed " .. flask_amount .. " flasks of " .. food_values[food].name .. " juice to the enemy team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		end				
	end								
	
	local decimals = 12
	local math_round = math.round
	
	local instant_threat_player_count_modifier = get_instant_threat_player_count_modifier()
	
	for a = 1, flask_amount, 1 do				
		--SET THREAT INCOME
		local e = (global.bb_evolution[biter_force_name] * 100) + 1
		local diminishing_modifier = (1 / (10 ^ (e * 0.014))) / (e * 0.5)
		global.bb_threat_income[biter_force_name] = global.bb_threat_income[biter_force_name] + (food_values[food].value * diminishing_modifier * 12)		
		global.bb_threat_income[biter_force_name] = math_round(global.bb_threat_income[biter_force_name], decimals)
		
		---SET EVOLUTION
		local e2 = (game.forces[biter_force_name].evolution_factor * 100) + 1
		local diminishing_modifier = (1 / (10 ^ (e2 * 0.017))) / (e2 * 0.5)
		local evo_gain = (food_values[food].value * diminishing_modifier)
		global.bb_evolution[biter_force_name] = global.bb_evolution[biter_force_name] + evo_gain
		global.bb_evolution[biter_force_name] = math_round(global.bb_evolution[biter_force_name], decimals)
		if global.bb_evolution[biter_force_name] <= 1 then
			game.forces[biter_force_name].evolution_factor = global.bb_evolution[biter_force_name]
		else
			game.forces[biter_force_name].evolution_factor = 1
		end
						
		--ADD INSTANT THREAT
		local diminishing_modifier = 1 / (0.2 + (e2 * 0.018))
		global.bb_threat[biter_force_name] = global.bb_threat[biter_force_name] + (food_values[food].value * instant_threat_player_count_modifier * diminishing_modifier)
		global.bb_threat[biter_force_name] = math_round(global.bb_threat[biter_force_name], decimals)
	end
	
	set_biter_endgame_modifiers(game.forces[biter_force_name])
end

return feed_biters