-- enemy units yield coins -- by mewmew

local event = require 'utils.event'
local insert = table.insert

local coin_yield = {
	["small-biter"] = 1,
	["medium-biter"] = 2,
	["big-biter"] = 3,
	["behemoth-biter"] = 5,
	["small-spitter"] = 1,
	["medium-spitter"] = 2,
	["big-spitter"] = 3,
	["behemoth-spitter"] = 5,
	["spitter-spawner"] = 32,
	["biter-spawner"] = 32,	
	["small-worm-turret"] = 8,
	["medium-worm-turret"] = 16,
	["big-worm-turret"] = 24
}

local entities_that_earn_coins = {
		["artillery-turret"] = true,
		["gun-turret"] = true,
		["laser-turret"] = true,
		["flamethrower-turret"] = true
	}

local function on_entity_died(event)	
	if not event.entity.valid then return end
	if event.entity.force.name ~= "enemy" then return end	
	if not coin_yield[event.entity.name] then return end
		
	local players_to_reward = {}
	local reward_has_been_given = false
	
	if event.cause then
		if event.cause.valid then
			if event.cause.name == "player" then
				insert(players_to_reward, event.cause)
				reward_has_been_given = true
			end			
			if event.cause.type == "car" then
				player = event.cause.get_driver()
				passenger = event.cause.get_passenger()
				if player then insert(players_to_reward, player.player)	end
				if passenger then insert(players_to_reward, passenger.player) end
				reward_has_been_given = true
			end
			if event.cause.type == "locomotive" then
				train_passengers = event.cause.train.passengers			
				if train_passengers then
					for _, passenger in pairs(train_passengers) do
						insert(players_to_reward, passenger)
					end
					reward_has_been_given = true
				end
			end
			for _, player in pairs(players_to_reward) do
				player.insert({name = "coin", count = coin_yield[event.entity.name]})
			end
		end
		if entities_that_earn_coins[event.cause.name] then
			event.entity.surface.spill_item_stack(event.cause.position,{name = "coin", count = coin_yield[event.entity.name]}, true)
			reward_has_been_given = true
		end
	end	
																	
	if reward_has_been_given == false then
		event.entity.surface.spill_item_stack(event.entity.position,{name = "coin", count = coin_yield[event.entity.name]}, true) 
	end
end
	
event.add(defines.events.on_entity_died, on_entity_died)