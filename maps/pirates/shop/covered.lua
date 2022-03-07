
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

local enum = {
	TIME = 'Time',
} 
Public.enum = enum



Public.offers_loaders = {
	{price = {{'coin', 1500}}, offer = {type = 'give-item', item = 'loader', count = 1}},
	{price = {{'coin', 2500}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
	{price = {{'coin', 3500}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
}

Public.offers_rockets = {
	{price = {{'coin', 200}, {'electronic-circuit', 80}}, offer = {type = 'give-item', item = 'rocket-launcher', count = 1}},
	{price = {{'coin', 1000}, {'explosives', 20}, {'electronic-circuit', 20}}, offer = {type = 'give-item', item = 'rocket', count = 20}},
}

Public.offers_default = {
	{price = {{'coin', 750}}, offer = {type = 'give-item', item = 'copper-plate', count = 150}},
	{price = {{'coin', 750}}, offer = {type = 'give-item', item = 'iron-plate', count = 150}},
	{price = {{'coin', 800}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 20}},
	{price = {{'coin', 1000}}, offer = {type = 'give-item', item = 'heavy-armor', count = 1}},
	{price = {{'coin', 400}}, offer = {type = 'give-item', item = 'gun-turret', count = 2}},
	{price = {{'coin', 600}}, offer = {type = 'give-item', item = 'defender-capsule', count = 2}},
	{price = {{'coin', 750}}, offer = {type = 'give-item', item = 'gate', count = 20}},
	{price = {{'coin', 200}}, offer = {type = 'give-item', item = 'storage-tank', count = 4}},
	{price = {{'coin', 250}}, offer = {type = 'give-item', item = 'big-electric-pole', count = 8}},
}



function Public.market_generate_coin_offers(how_many)
	local memory = Memory.get_crew_memory()

	local ret = {}
	local offerscopy = Utils.deepcopy(Public.offers_default)
	local loaderoffers = Public.offers_loaders

	local game_completion_progress = Common.game_completion_progress()

	if game_completion_progress < 0.2 then
		ret[#ret + 1] = loaderoffers[1]
	elseif game_completion_progress < 0.6 then
		ret[#ret + 1] = loaderoffers[2]
	else
		ret[#ret + 1] = loaderoffers[3]
	end

	local toaddcount = how_many
	while toaddcount>0 and #offerscopy > 0 do
		local index = Math.random(#offerscopy)
		local toadd = offerscopy[index]
		ret[#ret + 1] = toadd
		for i = index, #offerscopy - 1 do
			offerscopy[i] = offerscopy[i+1]
		end
		offerscopy[#offerscopy] = nil
		toaddcount = toaddcount - 1
	end

	if memory.rockets_for_sale then
		for _, o in ipairs(Public.offers_rockets) do
			ret[#ret + 1] = o
		end
	end

    return ret
end



return Public