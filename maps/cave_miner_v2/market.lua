local Public = {}

local Constants = require 'maps.cave_miner_v2.constants'
local Functions = require 'maps.cave_miner_v2.functions'
local LootRaffle = require "functions.loot_raffle"

local loot_blacklist = {
	["landfill"] = true,	
	["loader"] = true,
	["fast-loader"] = true,
	["express-loader"] = true,
	["wood"] = true,
	["raw-fish"] = true,
	["discharge-defense-remote"] = true,
	["railgun-dart"] = true,
}

function Public.refresh_offers(market, cave_miner)
    for i = 1, 100, 1 do
        local a = market.remove_market_item(1)
        if a == false then
            break
        end
    end
	local pickaxe_tiers = Constants.pickaxe_tiers
	local tier = cave_miner.pickaxe_tier + 1
	if pickaxe_tiers[tier] then
		local item_stacks = LootRaffle.roll(math.floor(tier ^ 3.75) + 8, 80, loot_blacklist)
		local price = {}
		for _, item_stack in pairs(item_stacks) do
			table.insert(price, {name = item_stack.name, amount = item_stack.count})
		end	
		market.add_market_item({price = price, offer = {type = 'nothing', effect_description = 'Upgrade pickaxe tier to: ' .. pickaxe_tiers[tier]}})
		market.add_market_item({price = {{name = "raw-fish", amount = tier * 2}}, offer = {type = 'nothing', effect_description = 'Reroll offer'}})
	end	
	for _, item in pairs(Constants.spawn_market_items) do
		market.add_market_item(item)
	end	
end

function Public.spawn(cave_miner)
	local surface = game.surfaces.nauvis
	local market = surface.create_entity({name = "market", position = {0,0}})
	market.destructible = false
	Public.refresh_offers(market, cave_miner)
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
		cave_miner.pickaxe_tier = cave_miner.pickaxe_tier + 1
		local speed = Functions.set_mining_speed(cave_miner, player.force)
		game.print("Pickaxe has been upgraded to: " .. Constants.pickaxe_tiers[cave_miner.pickaxe_tier] .. "!")
		Public.refresh_offers(market, cave_miner)
		Functions.update_top_gui(cave_miner)
		return
	end
	if offer_index == 2 then
		game.print(player.name .. " has rerolled market offers!")
		Public.refresh_offers(market, cave_miner)
	end
end

return Public