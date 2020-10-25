local Public = {}

local Constants = require 'maps.cave_miner_v2.constants'
local Functions = require 'maps.cave_miner_v2.functions'
local LootRaffle = require "functions.loot_raffle"

local loot_blacklist = {
	["discharge-defense-remote"] = true,
	["express-loader"] = true,
	["fast-loader"] = true,
	["landfill"] = true,	
	["loader"] = true,
	["railgun"] = true,
	["railgun-dart"] = true,
	["raw-fish"] = true,
	["wood"] = true,
}

local special_slots = {
	[1] = function(market, cave_miner)
		local pickaxe_tiers = Constants.pickaxe_tiers
		local tier = cave_miner.pickaxe_tier + 1
		if pickaxe_tiers[tier] then
			local item_stacks = LootRaffle.roll(math.floor(tier ^ 3.65) + 8, 100, loot_blacklist)
			local price = {}
			for _, item_stack in pairs(item_stacks) do table.insert(price, {name = item_stack.name, amount = item_stack.count}) end	
			market.add_market_item({price = price, offer = {type = 'nothing', effect_description = 'Upgrade pickaxe tier to: ' .. pickaxe_tiers[tier]}})		
		else
			market.add_market_item({price = price, offer = {type = 'nothing', effect_description = 'Maximum pickaxe upgrade reached!'}})		
		end
	end,
	[2] = function(market, cave_miner)
		local tier = (market.force.character_inventory_slots_bonus + 2) * 0.5
		local item_stacks = LootRaffle.roll(math.floor(tier ^ 3.50) + 8, 100, loot_blacklist)
		local price = {}
		for _, item_stack in pairs(item_stacks) do table.insert(price, {name = item_stack.name, amount = item_stack.count}) end	
		market.add_market_item({price = price, offer = {type = 'nothing', effect_description = 'Upgrade backpack to tier ' .. tier}})
		return tier
	end,
	[3] = function(market, cave_miner)
		local tier_pickaxe = cave_miner.pickaxe_tier + 1
		local tier_backpack = (market.force.character_inventory_slots_bonus + 2) * 0.5
		market.add_market_item({price = {{name = "raw-fish", amount = (tier_pickaxe + tier_backpack)}}, offer = {type = 'nothing', effect_description = 'Reroll offers'}})
	end,
}

function Public.refresh_offer(market, cave_miner, slot)
	local offers = market.get_market_items()
	market.clear_market_items()	
	for k, offer in pairs(offers) do
		if k == slot then
			special_slots[k](market, cave_miner)
		else
			market.add_market_item(offer)
		end
	end	
end

function Public.spawn(cave_miner)
	local surface = game.surfaces.nauvis
	local market = surface.create_entity({name = "market", position = {0,0}, force = "player"})
	rendering.draw_light({
		sprite = "utility/light_medium", scale = 7, intensity = 0.8, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = market,
		surface = surface, visible = true, only_in_alt_mode = false,
	})
	market.destructible = false
	market.minable = false

	for i = 1, 3, 1 do
		special_slots[i](market, cave_miner)
	end

	for _, item in pairs(Constants.spawn_market_items) do
		market.add_market_item(item)
	end
end

function Public.offer_bought(event, cave_miner)
	local player = game.players[event.player_index]	
	local market = event.market
	local offer_index = event.offer_index
	local count = event.count
	local offers = market.get_market_items()	
	local bought_offer = offers[offer_index].offer
	if bought_offer.type ~= "nothing" then return end
	if offer_index == 1 then
		market.force.play_sound({path = 'utility/new_objective', volume_modifier = 0.75})
		cave_miner.pickaxe_tier = cave_miner.pickaxe_tier + 1
		local speed = Functions.set_mining_speed(cave_miner, player.force)
		game.print("Pickaxe has been upgraded to: " .. Constants.pickaxe_tiers[cave_miner.pickaxe_tier] .. "!")
		Public.refresh_offer(market, cave_miner, 1)
		Public.refresh_offer(market, cave_miner, 3)
		Functions.update_top_gui(cave_miner)
		return
	end
	if offer_index == 2 then
		market.force.character_inventory_slots_bonus = market.force.character_inventory_slots_bonus + 2
		market.force.play_sound({path = 'utility/new_objective', volume_modifier = 0.75})
		game.print("Backpack has been upgraded to tier " .. (market.force.character_inventory_slots_bonus + 2) * 0.5 .. "!")
		Public.refresh_offer(market, cave_miner, 2)
		Public.refresh_offer(market, cave_miner, 3)
		Functions.update_top_gui(cave_miner, 2)	
		return
	end	
	if offer_index == 3 then
		if cave_miner.last_reroll_player_name ~= player.name then
			game.print(player.name .. " is rerolling market offers.")
			cave_miner.last_reroll_player_name = player.name
		end
		Public.refresh_offer(market, cave_miner, 1)
		Public.refresh_offer(market, cave_miner, 2)
		Public.refresh_offer(market, cave_miner, 3)
	end
end

return Public