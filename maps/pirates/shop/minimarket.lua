
local Memory = require 'maps.pirates.memory'
local Roles = require 'maps.pirates.roles.roles'
local Classes = require 'maps.pirates.roles.classes'
local Crew = require 'maps.pirates.crew'
local Boats = require 'maps.pirates.structures.boats.boats'
local Dock = require 'maps.pirates.surfaces.dock'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local inspect = require 'utils.inspect'.inspect

local Upgrades = require 'maps.pirates.boat_upgrades'

local Public = {}




Public.market_barters = {
	{price = {{'iron-plate', 300}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'copper-plate', 300}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},
	--repeating these:
	{price = {{'iron-plate', 300}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'copper-plate', 300}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},
	{price = {{'steel-plate', 50}}, offer = {type = 'give-item', item = 'copper-plate', count = 500}},
	{price = {{'steel-plate', 50}}, offer = {type = 'give-item', item = 'iron-plate', count = 500}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'coal', count = 500}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'iron-plate', count = 750}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'copper-plate', count = 750}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'steel-plate', count = 125}},

	{price = {{'wood', 200}}, offer = {type = 'give-item', item = 'coin', count = 250}},
	--TODO: add more complex trades
}

Public.market_permanent_offers = {
	{price = {{'coin', 4000}}, offer = {type = 'give-item', item = 'iron-ore', count = 800}},
	{price = {{'coin', 4000}}, offer = {type = 'give-item', item = 'copper-ore', count = 800}},
	{price = {{'coin', 4000}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 120}},
	{price = {{'coin', 5000}}, offer = {type = 'give-item', item = 'beacon', count = 2}},
	{price = {{'coin', 2800}}, offer = {type = 'give-item', item = 'speed-module', count = 2}},
}

-- cheap but one-off
Public.market_sales = {
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'coal', count = 900}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 500}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 75}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine', count = 30}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell', count = 60}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'raw-fish', count = 300}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'laser-turret', count = 1}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'vehicle-machine-gun', count = 2}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'substation', count = 6}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'distractor-capsule', count = 10}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'destroyer-capsule', count = 5}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'coin', count = 4000}},
}



function Public.minimarket_generate_offers(how_many_barters, how_many_sales)
	local ret = {}

	for _, offer in pairs(Public.market_permanent_offers) do
		ret[#ret + 1] = offer
	end

	local toaddcount

	local salescopy = Utils.deepcopy(Public.market_sales)
	toaddcount = how_many_sales
	while toaddcount>0 and #salescopy > 0 do
		local index = Math.random(#salescopy)
		local toadd = salescopy[index]
		ret[#ret + 1] = toadd
		for i = index, #salescopy - 1 do
			salescopy[i] = salescopy[i+1]
		end
		salescopy[#salescopy] = nil
		toaddcount = toaddcount - 1
	end

	local barterscopy = Utils.deepcopy(Public.market_barters)
	toaddcount = how_many_barters
	while toaddcount>0 and #barterscopy > 0 do
		local index = Math.random(#barterscopy)
		local toadd = barterscopy[index]
		ret[#ret + 1] = toadd
		for i = index, #barterscopy - 1 do
			barterscopy[i] = barterscopy[i+1]
		end
		barterscopy[#barterscopy] = nil
		toaddcount = toaddcount - 1
	end
	

    return ret
end


function Public.create_minimarket(surface, p)
	local memory = Memory.get_crew_memory()

	if not (surface and p) then return end

	local entity = {name = 'market', position = p}
	if surface.can_place_entity(entity) then
		local e = surface.create_entity(entity)
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.destructible = false
	
			local offers = Public.minimarket_generate_offers(2,2)

			for _, offer in pairs(offers) do
				e.add_market_item(offer)
			end
		end
	end
end


return Public