-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
-- local CoreData = require 'maps.pirates.coredata'
local Classes = require 'maps.pirates.roles.classes'
-- local Crew = require 'maps.pirates.crew'
-- local Boats = require 'maps.pirates.structures.boats.boats'
-- local Dock = require 'maps.pirates.surfaces.dock'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local Upgrades = require 'maps.pirates.boat_upgrades'
local _inspect = require 'utils.inspect'.inspect

-- local Upgrades = require 'maps.pirates.boat_upgrades'

local Public = {}




Public.market_barters = {
	{price = {{'iron-plate', 300}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'copper-plate', 300}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},
	--repeating these:
	{price = {{'iron-plate', 300}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'copper-plate', 300}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},

	{price = {{'steel-plate', 40}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'steel-plate', 40}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},
	{price = {{'raw-fish', 80}}, offer = {type = 'give-item', item = 'coal', count = 500}},
	{price = {{'raw-fish', 80}}, offer = {type = 'give-item', item = 'iron-plate', count = 750}},
	{price = {{'raw-fish', 80}}, offer = {type = 'give-item', item = 'copper-plate', count = 750}},
	{price = {{'raw-fish', 80}}, offer = {type = 'give-item', item = 'steel-plate', count = 150}},
	{price = {{'wood', 200}}, offer = {type = 'give-item', item = 'coin', count = 360}},
	{price = {{'wood', 150}}, offer = {type = 'give-item', item = 'coal', count = 150}},
	{price = {{'stone-brick', 200}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},
	{price = {{'stone-brick', 200}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'stone-brick', 200}}, offer = {type = 'give-item', item = 'steel-plate', count = 160}},
}

-- permanent means you can buy more than once (but only some items???)
Public.market_permanent_offers = {
	{price = {{'pistol', 1}}, offer = {type = 'give-item', item = 'coin', count = Balance.coin_sell_amount}},
	{price = {{'coin', 3600}}, offer = {type = 'give-item', item = 'iron-ore', count = 800}},
	{price = {{'coin', 3600}}, offer = {type = 'give-item', item = 'copper-ore', count = 800}},
	{price = {{'coin', 4200}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 100}},
	{price = {{'coin', 3600}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
	{price = {{'coin', 6200}}, offer = {type = 'give-item', item = 'beacon', count = 2}},
	{price = {{'coin', 4200}}, offer = {type = 'give-item', item = 'speed-module-2', count = 2}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'explosives', count = 50}},
	{price = {{'coin', 6500}, {'steel-plate', 25}, {'explosives', 50}}, offer = {type = 'give-item', item = 'land-mine', count = 100}},
	-- {price = {{'coin', 30000}}, offer = {type = 'give-item', item = 'artillery-targeting-remote', count = 1}},
}

-- cheap but one-off
Public.market_sales = {
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'coal', count = 900}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 75}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine', count = 20}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell', count = 50}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'raw-fish', count = 300}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'laser-turret', count = 1}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'vehicle-machine-gun', count = 2}},
	{price = {{'coin', 6000}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'distractor-capsule', count = 20}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'poison-capsule', count = 20}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'slowdown-capsule', count = 20}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'coin', count = 6000}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'roboport', count = 1}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'construction-robot', count = 10}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'logistic-chest-passive-provider', count = 2}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'logistic-robot', count = 2}},
	{price = {{'transport-belt', 100}, {'coin', 800}}, offer = {type = 'give-item', item = 'fast-transport-belt', count = 100}},
	{price = {{'fast-transport-belt', 100}, {'coin', 2500}}, offer = {type = 'give-item', item = 'express-transport-belt', count = 100}},
	{price = {{'underground-belt', 10}, {'coin', 800}}, offer = {type = 'give-item', item = 'fast-underground-belt', count = 10}},
	{price = {{'fast-underground-belt', 10}, {'coin', 2500}}, offer = {type = 'give-item', item = 'express-underground-belt', count = 10}},
	{price = {{'splitter', 10}, {'coin', 800}}, offer = {type = 'give-item', item = 'fast-splitter', count = 10}},
	{price = {{'fast-splitter', 10}, {'coin', 2500}}, offer = {type = 'give-item', item = 'express-splitter', count = 10}},
	{price = {{'pistol', 1}, {'coin', 300}}, offer = {type = 'give-item', item = 'submachine-gun', count = 1}},
	{price = {{'submachine-gun', 1}, {'coin', 1000}}, offer = {type = 'give-item', item = 'vehicle-machine-gun', count = 1}},
	{price = {{'shotgun', 1}, {'coin', 3500}}, offer = {type = 'give-item', item = 'combat-shotgun', count = 1}},
	{price = {{'shotgun-shell', 100}, {'coin', 2000}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell', count = 100}},
	{price = {{'piercing-rounds-magazine', 100}, {'coin', 3500}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine', count = 100}},
}



-- function Public.dock_generate_offers(how_many_barters, how_many_sales)
-- 	local ret = {}

-- 	local toaddcount

-- 	local barterscopy = Utils.deepcopy(Public.market_barters)
-- 	toaddcount = how_many_barters
-- 	while toaddcount>0 and #barterscopy > 0 do
-- 		local index = Math.random(#barterscopy)
-- 		local toadd = barterscopy[index]
-- 		ret[#ret + 1] = toadd
-- 		for i = index, #barterscopy - 1 do
-- 			barterscopy[i] = barterscopy[i+1]
-- 		end
-- 		barterscopy[#barterscopy] = nil
-- 		toaddcount = toaddcount - 1
-- 	end

-- 	for _, offer in pairs(Public.market_permanent_offers) do
-- 		ret[#ret + 1] = offer
-- 	end

-- 	local salescopy = Utils.deepcopy(Public.market_sales)
-- 	toaddcount = how_many_sales
-- 	while toaddcount>0 and #salescopy > 0 do
-- 		local index = Math.random(#salescopy)
-- 		local toadd = salescopy[index]
-- 		ret[#ret + 1] = toadd
-- 		for i = index, #salescopy - 1 do
-- 			salescopy[i] = salescopy[i+1]
-- 		end
-- 		salescopy[#salescopy] = nil
-- 		toaddcount = toaddcount - 1
-- 	end


--     return ret
-- end


function Public.create_dock_markets(surface, p)
	-- local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()

	if not (surface and p) then return end

	local e

	e = surface.create_entity{name = 'market', position = {x = p.x - 22, y = p.y - 1}, force = 'environment'}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		-- -- check if cannons need healing:
		-- local need_healing
		-- local cannons = game.surfaces[destination.surface_name].find_entities_filtered({type = 'artillery-turret'})
		-- for _, c in pairs(cannons) do
		-- 	local unit_number = c.unit_number

		-- 	local healthbar = memory.boat.healthbars[unit_number]
		-- 	if healthbar and healthbar.health < healthbar.max_health then
		-- 		need_healing = true
		-- 		break
		-- 	end
		-- end

		-- if need_healing then
		-- 	e.add_market_item{price = {{'repair-pack', 20}, {'coin', 1000}}, offer = {type = 'give-item', item = 'artillery-turret', count = 1}}
		-- end

		local upgrade_for_sale = Common.current_destination().static_params.upgrade_for_sale
		if upgrade_for_sale then
			e.add_market_item(Upgrades.market_offer_form[upgrade_for_sale])
		end

		destination.dynamic_data.dock_captains_market = e
	end

	e = surface.create_entity{name = 'market', position = {x = p.x - 7, y = p.y}, force = 'environment'}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		-- for _, offer in pairs(Public.market_permanent_offers) do
		-- 	e.add_market_item(offer)
		-- end

		local to_add_count

		local permanent_offers_copy = Utils.deepcopy(Public.market_permanent_offers)

		to_add_count = 3 + Math.random(0, 2)
		while to_add_count>0 and #permanent_offers_copy > 0 do
			local index = Math.random(#permanent_offers_copy)
			local offer = permanent_offers_copy[index]
			e.add_market_item(offer)
			for i = index, #permanent_offers_copy - 1 do
				permanent_offers_copy[i] = permanent_offers_copy[i+1]
			end
			permanent_offers_copy[#permanent_offers_copy] = nil
			to_add_count = to_add_count - 1
		end
	end

	e = surface.create_entity{name = 'market', position = {x = p.x, y = p.y - 1}, force = 'environment'}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		-- for _, offer in pairs(Public.market_sales) do
		-- 	e.add_market_item(offer)
		-- end

		local toaddcount

		local salescopy = Utils.deepcopy(Public.market_sales)
		toaddcount = 3 + Math.random(0, 2)
		while toaddcount>0 and #salescopy > 0 do
			local index = Math.random(#salescopy)
			local offer = salescopy[index]
			e.add_market_item(offer)
			for i = index, #salescopy - 1 do
				salescopy[i] = salescopy[i+1]
			end
			salescopy[#salescopy] = nil
			toaddcount = toaddcount - 1
		end

		-- new class offerings:
		if destination.static_params.class_for_sale then
			e.add_market_item{price={{'coin', Balance.class_cost(true)}}, offer={type="nothing", effect_description = {'pirates.market_description_purchase_class', Classes.display_form(destination.static_params.class_for_sale)}}}

			-- destination.dynamic_data.market_class_offer_rendering = rendering.draw_text{
			-- 	text = 'Class available: ' .. Classes.display_form(destination.static_params.class_for_sale),
			-- 	surface = surface,
			-- 	target = Utils.psum{e.position, {x = 0, y = -4}},
			-- 	color = CoreData.colors.renderingtext_green,
			-- 	scale = 2.5,
			-- 	font = 'default-game',
			-- 	alignment = 'center'
			-- }
		end
	end

	e = surface.create_entity{name = 'market', position = {x = p.x + 7, y = p.y}, force = 'environment'}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		-- for _, offer in pairs(Public.market_barters) do
		-- 	e.add_market_item(offer)
		-- end

		local toaddcount

		local barterscopy = Utils.deepcopy(Public.market_barters)
		toaddcount = 2 + Math.random(0, 2)
		while toaddcount>0 and #barterscopy>0 do
			local index = Math.random(#barterscopy)
			local offer = barterscopy[index]
			e.add_market_item(offer)
			for i = index, #barterscopy - 1 do
				barterscopy[i] = barterscopy[i+1]
			end
			barterscopy[#barterscopy] = nil
			toaddcount = toaddcount - 1
		end
	end
end


return Public