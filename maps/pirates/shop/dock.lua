
-- local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
local CoreData = require 'maps.pirates.coredata'
local Classes = require 'maps.pirates.roles.classes'
-- local Crew = require 'maps.pirates.crew'
-- local Boats = require 'maps.pirates.structures.boats.boats'
-- local Dock = require 'maps.pirates.surfaces.dock'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
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
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'coal', count = 500}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'iron-plate', count = 750}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'copper-plate', count = 750}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'steel-plate', count = 125}},

	{price = {{'wood', 200}}, offer = {type = 'give-item', item = 'coin', count = 250}},
	--TODO: add more complex trades
}

Public.market_permanent_offers = {
	{price = {{'coin', 2400}}, offer = {type = 'give-item', item = 'iron-ore', count = 800}},
	{price = {{'coin', 2400}}, offer = {type = 'give-item', item = 'copper-ore', count = 800}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 100}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
	{price = {{'coin', 5000}}, offer = {type = 'give-item', item = 'beacon', count = 2}},
	{price = {{'coin', 2800}}, offer = {type = 'give-item', item = 'speed-module-2', count = 2}},
}

-- cheap but one-off
Public.market_sales = {
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'coal', count = 900}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 75}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine', count = 30}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell', count = 50}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'raw-fish', count = 300}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'laser-turret', count = 1}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'vehicle-machine-gun', count = 3}},
	{price = {{'coin', 3000}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'distractor-capsule', count = 20}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'poison-capsule', count = 20}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'slowdown-capsule', count = 20}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'coin', count = 4000}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'roboport', count = 1}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'construction-robot', count = 10}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'logistic-chest-passive-provider', count = 2}},
	{price = {{'coin', 2000}}, offer = {type = 'give-item', item = 'logistic-robot', count = 2}},
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

	if not (surface and p) then return end

	local e

	e = surface.create_entity{name = 'market', position = {x = p.x - 7, y = p.y}}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		for _, offer in pairs(Public.market_permanent_offers) do
			e.add_market_item(offer)
		end
	end

	e = surface.create_entity{name = 'market', position = {x = p.x, y = p.y - 1}}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		local toaddcount

		local salescopy = Utils.deepcopy(Public.market_sales)
		toaddcount = 3
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
		local destination = Common.current_destination()
		if destination.static_params.class_for_sale then
			e.add_market_item{price={{'coin', Balance.class_cost()}}, offer={type="nothing"}}

			destination.dynamic_data.market_class_offer_rendering = rendering.draw_text{
				text = 'Class available: ' .. Classes.display_form[destination.static_params.class_for_sale],
				surface = surface,
				target = Utils.psum{e.position, {x = 0, y = -4}},
				color = CoreData.colors.renderingtext_green,
				scale = 2.5,
				font = 'default-game',
				alignment = 'center'
			}
		end
	end

	e = surface.create_entity{name = 'market', position = {x = p.x + 7, y = p.y}}
	if e and e.valid then
		e.minable = false
		e.rotatable = false
		e.destructible = false

		local toaddcount

		local barterscopy = Utils.deepcopy(Public.market_barters)
		toaddcount = 2
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