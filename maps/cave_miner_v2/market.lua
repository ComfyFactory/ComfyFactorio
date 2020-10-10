local Public = {}

local Functions = require 'maps.cave_miner_v2.functions'
local LootRaffle = require "functions.loot_raffle"

local pickaxe_tiers = {
	"wood",
	"plastic",
	"bone",
	"alabaster",
	"lead",
	"zinc",	
	"tin",
	"salt",	
	"bauxite",
	"borax",
	"bismuth",
	"amber",
	"galena",	
	"calcite",
	"aluminium",
	"silver",
	"gold",
	"copper",
	"marble",
	"brass",
	"flourite",
	"platinum",
	"nickel",	
	"iron",	
	"manganese",
	"apatite",
	"uraninite",
	"turquoise",
	"hematite",
	"glass",
	"magnetite",
	"concrete",
	"pyrite",
	"steel",
	"zircon",
	"titanium",
	"silicon",
	"quartz",
	"garnet",
	"flint",
	"tourmaline",
	"beryl",
	"topaz",
	"chrysoberyl",
	"chromium",
	"tungsten",
	"corundum",
	"tungsten",
	"diamond",	
	"penumbrite",
	"meteorite",
	"crimtane",
	"obsidian",
	"demonite",
	"mythril",
	"adamantite",
	"chlorophyte",
	"densinium",
	"luminite",
}

function Public.refresh_offers(market, cave_miner)
    for i = 1, 100, 1 do
        local a = market.remove_market_item(1)
        if a == false then
            break
        end
    end	
	local tier = cave_miner.pickaxe_tier + 1
	local item_stacks = LootRaffle.roll(tier ^ 4 + 8, 8)
	local price = {}
	for _, item_stack in pairs(item_stacks) do
		table.insert(price, {name = item_stack.name, amount = item_stack.count})
	end	
	market.add_market_item({price = price, offer = {type = 'nothing', effect_description = 'Upgrade pickaxe tier to ' .. pickaxe_tiers[tier]}})
	market.add_market_item({price = {{name = "raw-fish", amount = tier * 2}}, offer = {type = 'nothing', effect_description = 'reroll offers'}})
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
		game.print("Pickaxe material has been upgraded to " .. pickaxe_tiers[cave_miner.pickaxe_tier] .. "!")
		Public.refresh_offers(market, cave_miner)
		return
	end
	if offer_index == 2 then
		game.print(player.name .. " has rerolled market offers!")
		Public.refresh_offers(market, cave_miner)
	end
end

return Public