
local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
-- local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
-- local Loot = require 'maps.pirates.loot'
local _inspect = require 'utils.inspect'.inspect

-- local Structures = require 'maps.pirates.structures.structures'
-- local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Boats = require 'maps.pirates.structures.boats.boats'
local Hold = require 'maps.pirates.surfaces.hold'

local Public = {}

-- September 2021: Reworking the game so that you start on a 'sloop with hold', but can customize the ship with upgrades.

-- I'm thinking these can start by simply being shop icons.

-- In the hold, we can extend the hold size by placing tiles. Perhaps the space that is extended could be random, as usual to dissuade repetitive builds.

-- For the deck, we don't really want to do that. It's probably safest to stick to things like upgrading the accumulator.

local enum = {
	EXTRA_HOLD = 'extra_hold',
	MORE_POWER = 'upgrade_power',
	UNLOCK_MERCHANTS = 'unlock_merchants',
	ROCKETS_FOR_SALE = 'rockets_for_sale',
}
Public.enum = enum
Public.List = {
	enum.EXTRA_HOLD,
	enum.MORE_POWER,
	enum.UNLOCK_MERCHANTS,
	enum.ROCKETS_FOR_SALE,
}

Public.crowsnest_display_form = {
	[enum.EXTRA_HOLD] = 'Extra Hold',
	[enum.MORE_POWER] = 'Power',
	[enum.UNLOCK_MERCHANTS] = 'Unlock Merchants',
	[enum.ROCKETS_FOR_SALE] = 'Unlock Rockets',
}

-- WARNING: The dock market pulls from these values, but the Crowsnest caption pulls data from main_shop_data_1. So don't change one without the other
Public.market_offer_form = {
	[enum.EXTRA_HOLD] = {price = {{'coin', 6000}, {'coal', 500}}, offer = {type='nothing', effect_description='Purchase an extra hold.'}},
	[enum.MORE_POWER] = {price = {{'coin', 12000}, {'coal', 2000}}, offer = {type='nothing', effect_description='Upgrade the ship\'s passive power generators.'}},
	[enum.UNLOCK_MERCHANTS] = {price = {{'coin', 12000}, {'coal', 2000}}, offer = {type='nothing', effect_description='Unlock merchant ships on future islands.'}},
	[enum.ROCKETS_FOR_SALE] = {price = {{'coin', 18000}, {'coal', 2000}}, offer = {type='nothing', effect_description='Unlock the sale of rockets at covered markets.'}},
}

function Public.execute_upgade(upgrade_type, player)

	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if upgrade_type == enum.EXTRA_HOLD then
		if player then
			Common.notify_force(player.force,string.format('[font=heading-1]%s upgraded the ship\'s hold.[/font]', player.name))
		end
		Hold.add_another_hold_surface()
	elseif upgrade_type == enum.MORE_POWER then
		if player then
			Common.notify_force(player.force, string.format('[font=heading-1]%s upgraded the ship\'s power.[/font]', player.name))
		end
		boat.EEI_stage = boat.EEI_stage + 1
		Boats.update_EEIs(boat)
	elseif upgrade_type == enum.UNLOCK_MERCHANTS then
		if player then
			Common.notify_force(player.force,string.format('[font=heading-1]%s unlocked merchant ships.[/font]', player.name))
		end
		memory.merchant_ships_unlocked = true
	elseif upgrade_type == enum.ROCKETS_FOR_SALE then
		if player then
			Common.notify_force(player.force,string.format('[font=heading-1]%s unlocked the sale of rockets at covered-up markets.[/font]', player.name))
		end
		memory.rockets_for_sale = true
	end

end


return Public