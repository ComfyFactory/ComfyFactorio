-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require('maps.pirates.memory')
-- local Roles = require 'maps.pirates.roles.roles'
-- local Balance = require 'maps.pirates.balance'
local Common = require('maps.pirates.common')
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
-- local Loot = require 'maps.pirates.loot'
local _inspect = require('utils.inspect').inspect

-- local Structures = require 'maps.pirates.structures.structures'
-- local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Boats = require('maps.pirates.structures.boats.boats')
local Hold = require('maps.pirates.surfaces.hold')

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
	UPGRADE_CANNONS = 'upgrade_cannons', -- heal and upgrade all ship's artilerry turrets max health
}
Public.enum = enum
Public.List = {
	enum.EXTRA_HOLD,
	enum.MORE_POWER,
	enum.UNLOCK_MERCHANTS,
	enum.ROCKETS_FOR_SALE,
	enum.UPGRADE_CANNONS,
}

Public.crowsnest_display_form = {
	[enum.EXTRA_HOLD] = { 'pirates.upgrade_hold_crowsnest_form' },
	[enum.MORE_POWER] = { 'pirates.upgrade_power_crowsnest_form' },
	[enum.UNLOCK_MERCHANTS] = { 'pirates.upgrade_merchants_crowsnest_form' },
	[enum.ROCKETS_FOR_SALE] = { 'pirates.upgrade_rockets_crowsnest_form' },
	[enum.UPGRADE_CANNONS] = { 'pirates.upgrade_cannons_crowsnest_form' },
}

Public.upgrades_data = {
	[enum.MORE_POWER] = {
		market_item = {
			price = {
				{ name = 'coin', count = 7000 },
				{ name = 'coal', count = 500 },
			},
			offer = {
				type = 'nothing',
				effect_description = { 'pirates.market_description_upgrade_power' },
			},
		},
		tooltip = { 'pirates.market_description_upgrade_power' },
		what_you_get_sprite_buttons = { ['utility/status_working'] = false },
	},
	[enum.EXTRA_HOLD] = {
		market_item = {
			price = {
				{ name = 'coin', count = 7000 },
				{ name = 'coal', count = 500 },
			},
			offer = {
				type = 'nothing',
				effect_description = { 'pirates.market_description_upgrade_hold' },
			},
		},
		tooltip = { 'pirates.market_description_upgrade_hold' },
		what_you_get_sprite_buttons = { ['item/steel-chest'] = false },
	},
	[enum.UNLOCK_MERCHANTS] = {
		market_item = {
			price = {
				{ name = 'coin', count = 14000 },
				{ name = 'coal', count = 1000 },
			},
			offer = {
				type = 'nothing',
				effect_description = { 'pirates.market_description_upgrade_merchants' },
			},
		},
		tooltip = { 'pirates.market_description_upgrade_merchants' },
		what_you_get_sprite_buttons = { ['entity/market'] = false },
	},
	[enum.ROCKETS_FOR_SALE] = {
		market_item = {
			price = {
				{ name = 'coin', count = 21000 },
				{ name = 'coal', count = 1000 },
			},
			offer = {
				type = 'nothing',
				effect_description = { 'pirates.market_description_upgrade_rockets' },
			},
		},
		tooltip = { 'pirates.market_description_upgrade_rockets' },
		what_you_get_sprite_buttons = { ['item/rocket-launcher'] = false },
	},
	[enum.UPGRADE_CANNONS] = {
		market_item = {
			price = {
				{ name = 'repair-pack', count = 20 },
				{ name = 'coin', count = 5000 },
				{ name = 'coal', count = 800 },
			},
			offer = {
				type = 'nothing',
				effect_description = { 'pirates.market_description_upgrade_turrets' },
			},
		},
		tooltip = { 'pirates.market_description_upgrade_turrets' },
		what_you_get_sprite_buttons = { ['item/artillery-turret'] = false },
	},
}

function Public.execute_upgade(upgrade_type, player)
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if upgrade_type == enum.EXTRA_HOLD then
		if player then
			Common.notify_force(player.force, { 'pirates.upgrade_hold', player.name })
		end
		Hold.add_another_hold_surface()
	elseif upgrade_type == enum.MORE_POWER then
		if player then
			Common.notify_force(player.force, { 'pirates.upgrade_power', player.name })
		end
		boat.EEI_stage = boat.EEI_stage + 1
		Boats.update_EEIs(boat)
	elseif upgrade_type == enum.UNLOCK_MERCHANTS then
		if player then
			Common.notify_force(player.force, { 'pirates.upgrade_merchants', player.name })
		end
		memory.merchant_ships_unlocked = true
	elseif upgrade_type == enum.ROCKETS_FOR_SALE then
		if player then
			Common.notify_force(player.force, { 'pirates.upgrade_rockets', player.name })
		end
		memory.rockets_for_sale = true
	elseif upgrade_type == enum.UPGRADE_CANNONS then
		if player then
			Common.notify_force(player.force, { 'pirates.upgraded_cannons', player.name })
		end
		Boats.upgrade_cannons()
	end
end

return Public
