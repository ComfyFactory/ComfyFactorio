-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
-- local Balance = require 'maps.pirates.balance'
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
-- local Loot = require 'maps.pirates.loot'
local _inspect = require 'utils.inspect'.inspect
local Upgrades = require 'maps.pirates.boat_upgrades'
-- local Hold = require 'maps.pirates.surfaces.hold'
-- local Crew = require 'maps.pirates.crew'
-- local Boats = require 'maps.pirates.structures.boats.boats'
-- local Dock = require 'maps.pirates.surfaces.dock'
local CustomEvents = require 'maps.pirates.custom_events'

local Public = {}



-- Note! This file is deprecated. It is replaced with a dedicated market at the dock and inside the captain's cabin. The exception is main_shop_data_1 as noted below, which is consulted for the Crowsnest caption. (Haven't had time to unify this yet.)



--== Warning: If something only costs fuel, then we need to check the player can't buy it whilst they're dead

-- WARNING: The Crowsnest caption pulls data from this data. But the actual dock market pulls from boat_upgrades.lua.
Public.main_shop_data_1 = {
	upgrade_cannons = {
		tooltip = 'Increase cannons max health. This will also repair them.',
		what_you_get_sprite_buttons = {['item/artillery-turret'] = false},
		base_cost = {coins = 1000},
	},
	new_boat_cutter = {
		tooltip = 'Purchase a cutter.',
		what_you_get_sprite_buttons = {['utility/spawn_flag'] = false},
		base_cost = {fuel = 3000},
	},
	new_boat_sloop_with_hold = {
		tooltip = 'Purchase a sloop (with hold).',
		what_you_get_sprite_buttons = {['utility/spawn_flag'] = false},
		base_cost = {fuel = 3500},
	},
	new_boat_cutter_with_hold = {
		tooltip = 'Purchase a cutter (with hold).',
		what_you_get_sprite_buttons = {['utility/spawn_flag'] = false},
		base_cost = {fuel = 5000},
	},
	-- buy_iron = {
	-- 	tooltip = 'Purchase 250 iron plates for 300 stored fuel.',
	-- 	what_you_get_sprite_buttons = {['item/iron-plate'] = 250},
	-- 	base_cost = {fuel = 300},
	-- },
	-- buy_copper = {
	-- 	tooltip = 'Purchase 250 copper plates for 300 stored fuel.',
	-- 	what_you_get_sprite_buttons = {['item/copper-plate'] = 250},
	-- 	base_cost = {fuel = 300},
	-- },
	-- sell_iron = {
	-- 	tooltip = 'Purchase 200 stored fuel for 2000 iron plates.',
	-- 	what_you_get_sprite_buttons = {['item/sulfur'] = 200},
	-- 	base_cost = {iron_plates = 2000},
	-- },
	-- sell_copper = {
	-- 	tooltip = 'Purchase 100 stored fuel for 2500 copper plates',
	-- 	what_you_get_sprite_buttons = {['item/sulfur'] = 100},
	-- 	base_cost = {copper_plates = 2500},
	-- },
	-- as as initial pass let's try making the fuel values half of the old gold values...
	[Upgrades.enum.MORE_POWER] = {
		tooltip = 'Upgrade the ship\'s power.',
		what_you_get_sprite_buttons = {['utility/status_working'] = false},
		base_cost = {coins = 7000, fuel = 500},
	},
	[Upgrades.enum.EXTRA_HOLD] = {
		tooltip = 'Upgrade the ship\'s hold.',
		what_you_get_sprite_buttons = {['item/steel-chest'] = false},
		base_cost = {coins = 7000, fuel = 500},
	},
	[Upgrades.enum.UNLOCK_MERCHANTS] = {
		tooltip = 'Unlock merchant ships.',
		what_you_get_sprite_buttons = {['entity/market'] = false},
		base_cost = {coins = 14000, fuel = 1000},
	},
	[Upgrades.enum.ROCKETS_FOR_SALE] = {
		tooltip = 'Unlock rockets for sale at covered-up markets.',
		what_you_get_sprite_buttons = {['item/rocket-launcher'] = false},
		base_cost = {coins = 21000, fuel = 1000},
	},
}

Public.main_shop_data_2 = {
	rail_signal = {
		tooltip = "100 signals, used to steer the boat one space in the Crow's Nest View.",
		what_you_get_sprite_buttons = {['item/rail-signal'] = 100},
		base_cost = {coins = 600, fuel = 50},
	},
	artillery_shell = {
		tooltip = '8 cannon shells.',
		what_you_get_sprite_buttons = {['item/artillery-shell'] = 8},
		base_cost = {coins = 800, fuel = 30},
	},
	artillery_remote = {
		tooltip = 'An artillery targeting remote.',
		what_you_get_sprite_buttons = {['item/artillery-targeting-remote'] = 1},
		base_cost = {coins = 12000, fuel = 2500},
	},
	-- buy_fast_loader = {
	-- 	tooltip = 'A fast loader for 500 stored fuel.',
	-- 	what_you_get_sprite_buttons = {['item/fast-loader'] = 1},
	-- 	base_cost = {fuel = 500},
	-- },
	uranium_ore = {
		tooltip = '10 green rocks of unknown origin.',
		what_you_get_sprite_buttons = {['item/uranium-238'] = 10},
		base_cost = {coins = 1000, fuel = 100},
	},
	extra_time = {
		tooltip = 'Relax at sea for an extra minute. (Increases the next destination\'s loading time.)',
		what_you_get_sprite_buttons = {['utility/time_editor_icon'] = 60},
		base_cost = {coins = 10, fuel = 1},
	},
}



function Public.initialise_captains_shop()
	local memory = Memory.get_crew_memory()

	memory.mainshop_availability_bools = {
		uranium_ore = true,
		rail_signal = true,
		artillery_shell = true,
		artillery_remote = false, --good way to get trolled by crew and remove skill
		extra_time = true,
		new_boat_sloop_with_hold = false,
		new_boat_cutter_with_hold = false,
		new_boat_cutter = false,
		buy_iron = false,
		upgrade_cannons = false,
		-- sell_iron = false,
		-- buy_fast_loader = true,
		-- sell_copper = false,
	}

	script.raise_event(CustomEvents.enum['update_crew_fuel_gui'], {})
end

-- function Public.main_shop_try_purchase(player, purchase_name)
-- 	local memory = Memory.get_crew_memory()
-- 	local destination = Common.current_destination()
-- 	local shop_data_1 = Public.main_shop_data_1
-- 	local shop_data_2 = Public.main_shop_data_2
-- 	local trade_data = shop_data_1[purchase_name] or shop_data_2[purchase_name]
-- 	if not trade_data then return end

-- 	local stored_fuel = memory.stored_fuel
-- 	if not stored_fuel then return end
-- 	-- local captain_index = memory.playerindex_captain
-- 	-- if not (stored_fuel and captain_index) then return end
-- 	-- local captain = game.players[captain_index]
-- 	if not Common.validate_player_and_character(player) then return end

-- 	local inv = player.get_inventory(defines.inventory.character_main)
-- 	if not (inv and inv.valid) then return end

-- 	local multiplier = Balance.main_shop_cost_multiplier()

-- 	-- local rate_limit_ok = not (memory.mainshop_rate_limit_ticker and memory.mainshop_rate_limit_ticker > 0)
-- 	local rate_limit_ok = true
-- 	local enough_fuel = true
-- 	local enough_iron_plates = true
-- 	local enough_coins = true
-- 	local enough_copper_plates = true
-- 	local coins_got
-- 	local iron_plates_got
-- 	local copper_plates_got
-- 	-- local able_to_buy_boats = memory.boat.state == Boats.enum_state.DOCKED --disabled for now
-- 	local able_to_buy_boats = false
-- 	-- local able_to_buy_boats = (memory.boat.state == Boats.enum_state.DOCKED or memory.boat.state == Boats.enum_state.APPROACHING) --problem with this if you buy whilst approaching, the original one no longer moves

-- 	for k, v in pairs(trade_data.base_cost) do
-- 		if k == 'fuel' then
-- 			enough_fuel = (stored_fuel >= v * multiplier)
-- 		elseif k == 'coins' then
-- 			coins_got = inv.get_item_count('coin')
-- 			enough_coins = coins_got >= v * multiplier
-- 		elseif k == 'iron_plates' then
-- 			iron_plates_got = inv.get_item_count('iron-plate')
-- 			enough_iron_plates = iron_plates_got >= v * multiplier
-- 		elseif k == 'copper_plates' then
-- 			copper_plates_got = inv.get_item_count('copper-plate')
-- 			enough_copper_plates = copper_plates_got >= v * multiplier
-- 		end
-- 	end

-- 	local can_buy = rate_limit_ok and enough_coins and enough_fuel and enough_iron_plates and enough_copper_plates

-- 	if purchase_name == 'new_boat_sloop_with_hold' or purchase_name == 'new_boat_cutter_with_hold' or purchase_name == 'new_boat_cutter' then can_buy = can_buy and able_to_buy_boats end

-- 	-- @TODO: prevent people from buying things whilst marooned

-- 	if can_buy then
-- 		for k, v in pairs(trade_data.base_cost) do
-- 			if k == 'fuel' then
-- 				memory.stored_fuel = memory.stored_fuel - v * multiplier
-- 			elseif k == 'coins' then
-- 				inv.remove{name="coin", count=v * multiplier}
-- 			elseif k == 'iron_plates' then
-- 				inv.remove{name="iron-plate", count=v * multiplier}
-- 			elseif k == 'copper_plates' then
-- 				inv.remove{name="copper-plate", count=v * multiplier}
-- 			end
-- 		end

-- 		local force = memory.force
-- 		if not (force and force.valid) then return end

-- 		local gotamount
-- 		if purchase_name == 'uranium_ore' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/uranium-238']
-- 			Common.give(player, {{name = 'uranium-238', count = gotamount}})
-- 			Common.notify_force_light(force,string.format('%s is buying green rocks...', player.name))

-- 		elseif purchase_name == 'extra_time' then
-- 			local success = Crew.try_add_extra_time_at_sea(60 * 60)
-- 			if success then
-- 				Common.notify_force_light(force,string.format('%s is buying extra time at sea...', player.name))
-- 			else
-- 				Common.notify_player_error(player, string.format('Purchase error: Can\'t buy more time than this.', player.name))
-- 				-- refund:
-- 				memory.stored_fuel = memory.stored_fuel + trade_data.base_cost.fuel * multiplier
-- 			end

-- 		elseif purchase_name == 'rail_signal' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/rail-signal']
-- 			Common.give(player, {{name = 'rail-signal', count = gotamount}})
-- 			Common.notify_force_light(force,string.format('%s is buying signals...', player.name))

-- 		elseif purchase_name == 'artillery_shell' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/artillery-shell']
-- 			Common.give(player, {{name = 'artillery-shell', count = gotamount}})
-- 			Common.notify_force_light(force,string.format('%s is buying cannon shells...', player.name))

-- 		elseif purchase_name == 'artillery_remote' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/artillery-targeting-remote']
-- 			Common.give(player, {{name = 'artillery-targeting-remote', count = gotamount}})
-- 			Common.notify_force_light(force,string.format('%s is buying an artillery targeting remote...', player.name))

-- 		elseif purchase_name == 'new_boat_cutter' or purchase_name == 'new_boat_cutter_with_hold' or purchase_name == 'new_boat_sloop_with_hold' then
-- 			Dock.execute_boat_purchase()
-- 			Common.notify_force(force,string.format('[font=heading-1]%s bought a %s.[/font]', player.name, Boats[Common.current_destination().static_params.boat_for_sale_type].Data.display_name))

-- 		elseif purchase_name == 'repair_cannons' then
-- 			-- heal all cannons:
-- 			local cannons = game.surfaces[destination.surface_name].find_entities_filtered({type = 'artillery-turret'})
-- 			for _, c in pairs(cannons) do
-- 				local unit_number = c.unit_number

-- 				local healthbar = memory.healthbars[unit_number]
-- 				if _DEBUG then game.print(unit_number) end
-- 				if healthbar then
-- 					healthbar.health = healthbar.max_health
-- 					Public.update_healthbar_rendering(healthbar, healthbar.max_health)
-- 				end
-- 			end
-- 			Common.notify_force(force,string.format('[font=heading-1]%s repaired the cannons.[/font]', player.name))
-- 			memory.mainshop_availability_bools[purchase_name] = false

-- 		elseif purchase_name == Upgrades.enum.MORE_POWER then
-- 			Upgrades.execute_upgade(Upgrades.enum.MORE_POWER)
-- 			memory.mainshop_availability_bools[purchase_name] = false

-- 		elseif purchase_name == Upgrades.enum.EXTRA_HOLD then
-- 			Upgrades.execute_upgade(Upgrades.enum.EXTRA_HOLD)
-- 			memory.mainshop_availability_bools[purchase_name] = false

-- 		elseif purchase_name == Upgrades.enum.UNLOCK_MERCHANTS then
-- 			Upgrades.execute_upgade(Upgrades.enum.UNLOCK_MERCHANTS)
-- 			memory.mainshop_availability_bools[purchase_name] = false

-- 		elseif purchase_name == Upgrades.enum.ROCKETS_FOR_SALE then
-- 			Upgrades.execute_upgade(Upgrades.enum.ROCKETS_FOR_SALE)
-- 			memory.mainshop_availability_bools[purchase_name] = false

-- 		elseif purchase_name == 'sell_iron' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/coal']
-- 			Common.give(player, {{name = 'fuel', count = gotamount}})
-- 			Common.notify_force_light(force,string.format('%s is selling iron...', player.name))

-- 		elseif purchase_name == 'buy_iron' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/iron-plate']
-- 			Common.give_items_to_crew{{name = 'iron-plate', count = gotamount}}
-- 			Common.notify_force_light(force,string.format('%s is buying iron...', player.name))

-- 		elseif purchase_name == 'buy_copper' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/copper-plate']
-- 			Common.give_items_to_crew{{name = 'copper-plate', count = gotamount}}
-- 			Common.notify_force_light(force,string.format('%s is buying copper...', player.name))

-- 		-- elseif name == 'buy_fast_loader' then
-- 		-- 	gotamount = trade_data.what_you_get_sprite_buttons['item/fast-loader']
-- 		-- 	Common.give(player, {{name = 'fast-loader', count = gotamount}})
-- 		-- 	Common.notify_force_light(force,string.format('%s bought a fast loader...', player.name))

-- 		elseif purchase_name == 'sell_copper' then
-- 			gotamount = trade_data.what_you_get_sprite_buttons['item/coal']
-- 			Common.give(player, {{name = 'fuel', count = gotamount}})
-- 			Common.notify_force_light(force,string.format('%s is selling copper...', player.name))

-- 		end

-- 		script.raise_event(CustomEvents.enum['update_crew_fuel_gui'], {})

-- 		-- memory.mainshop_rate_limit_ticker = Common.mainshop_rate_limit_ticks
-- 	else
-- 		-- play sound?
-- 		if rate_limit_ok == false then
-- 			Common.notify_player_error(player, 'Purchase error: Shop rate limit exceeded.')
-- 		end
-- 		if enough_fuel == false then
-- 			Common.notify_player_error(player, 'Purchase error: Not enough stored fuel.')
-- 		end
-- 		if enough_coins == false then
-- 			Common.notify_player_error(player, 'Purchase error: Not enough doubloons.')
-- 		end
-- 		if enough_iron_plates == false then
-- 			Common.notify_player_error(player, 'Purchase error: Not enough iron plates.')
-- 		end
-- 		if enough_copper_plates == false then
-- 			Common.notify_player_error(player, 'Purchase error: Not enough copper plates.')
-- 		end

-- 		if (purchase_name == 'new_boat_cutter' or purchase_name == 'new_boat_sloop_with_hold' or purchase_name == 'new_boat_cutter_with_hold') and (not able_to_buy_boats) then
-- 			Common.notify_player_error(player, 'Purchase error: Not able to purchase ships right now.')
-- 		end
-- 	end
-- end

return Public