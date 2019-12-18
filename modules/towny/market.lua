local Town_center = require "modules.towny.town_center"
local Public = {}

local upgrade_functions = {
	--Upgrade Town Center Health
	[1] = function(town_center)
		town_center.health = town_center.health + town_center.max_health
		town_center.max_health = town_center.max_health * 2
		Town_center.set_market_health(town_center.market, 0)
	end,
}

local function clear_offers(market)
	for i = 1, 256, 1 do
		local a = market.remove_market_item(1)
		if a == false then return end
	end
end

local function set_offers(town_center)
	local market = town_center.market
	local market_items = {
		{price = {{"coin", town_center.max_health * 0.1}}, offer = {type = 'nothing', effect_description = "Upgrade Town Center Health"}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'wood', count = 50}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'stone', count = 50}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'coal', count = 50}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
		{price = {{'wood', 12}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'iron-ore', 12}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'copper-ore', 12}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'stone', 12}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'coal', 12}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'uranium-ore', 10}}, offer = {type = 'give-item', item = "coin"}},
	}
	for _, item in pairs(market_items) do
		market.add_market_item(item)
	end
end

function Public.refresh_offers(event)
	local market = event.entity or event.market
	if not market then return end
	if not market.valid then return end
	if market.name ~= "market" then return end
	local town_center = global.towny.town_centers[market.force.name]
	if not town_center then return end
	clear_offers(market)
	set_offers(town_center)
end

function Public.offer_purchased(event)
	local offer_index = event.offer_index		
	if not upgrade_functions[offer_index] then return end
	
	local market = event.market

	local town_center = global.towny.town_centers[market.force.name]
	if not town_center then return end
	
	upgrade_functions[offer_index](town_center)
end

return Public

