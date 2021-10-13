
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
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'coal', count = 600}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'iron-plate', count = 600}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'copper-plate', count = 600}},
	{price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'steel-plate', count = 100}},

	{price = {{'wood', 200}}, offer = {type = 'give-item', item = 'coin', count = 25}},
	--TODO: add more complex trades
}



function Public.minimarket_generate_barters(how_many)
	local ret = {}
	local barterscopy = Utils.deepcopy(Public.market_barters)

	local toaddcount = how_many
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
	
			local barters = Public.minimarket_generate_barters(4)

			for _, barter in pairs(barters) do
				local offer = barter
				e.add_market_item(offer)
			end
		end
	end
end


return Public