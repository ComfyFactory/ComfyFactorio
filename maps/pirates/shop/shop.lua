
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
local SurfacesCommon = require 'maps.pirates.surfaces.common'

local Upgrades = require 'maps.pirates.boat_upgrades'

local Public = {}


Public.main_shop_data_1 = {
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
		base_cost = {coins = 5000, fuel = 700},
	},
	[Upgrades.enum.EXTRA_HOLD] = {
		tooltip = 'Upgrade the ship\'s hold.',
		what_you_get_sprite_buttons = {['item/steel-chest'] = false},
		base_cost = {coins = 10000, fuel = 2500},
	},
	[Upgrades.enum.ROCKETS_FOR_SALE] = {
		tooltip = 'Unlock rockets for sale at covered-up markets.',
		what_you_get_sprite_buttons = {['item/rocket-launcher'] = false},
		base_cost = {coins = 10000, fuel = 3000},
	},
	[Upgrades.enum.UNLOCK_MERCHANTS] = {
		tooltip = 'Unlock merchant ships.',
		what_you_get_sprite_buttons = {['entity/market'] = false},
		base_cost = {coins = 10000, fuel = 4000},
	},
}

Public.main_shop_data_2 = {
	rail_signal = {
		tooltip = "100 signals, used to steer the boat one space in the Crow's Nest View.",
		what_you_get_sprite_buttons = {['item/rail-signal'] = 100},
		base_cost = {coins = 600},
	},
	artillery_shell = {
		tooltip = '10 cannon shells.',
		what_you_get_sprite_buttons = {['item/artillery-shell'] = 10},
		base_cost = {coins = 2000, fuel = 300},
	},
	artillery_remote = {
		tooltip = 'An artillery targeting remote.',
		what_you_get_sprite_buttons = {['item/artillery-targeting-remote'] = 1},
		base_cost = {coins = 12000, fuel = 2500},
	},
	-- extra_time = {
	-- 	tooltip = 'Relax at sea for an extra minute for 50 stored fuel. (Increases the next destination\'s loading time.)',
	-- 	what_you_get_sprite_buttons = {['utility/time_editor_icon'] = 60},
	-- 	base_cost = {fuel = 50},
	-- },
	-- buy_fast_loader = {
	-- 	tooltip = 'A fast loader for 500 stored fuel.',
	-- 	what_you_get_sprite_buttons = {['item/fast-loader'] = 1},
	-- 	base_cost = {fuel = 500},
	-- },
	uranium_ore = {
		tooltip = '10 green rocks of unknown origin.',
		what_you_get_sprite_buttons = {['item/uranium-238'] = 10},
		base_cost = {coins = 1000, fuel = 800},
	},
}



function Public.initialise_main_shop()
	local memory = Memory.get_crew_memory()

	memory.mainshop_availability_bools = {
		uranium_ore = true,
		rail_signal = true,
		artillery_shell = true,
		artillery_remote = true,
		-- extra_time = true,
		new_boat_sloop_with_hold = false,
		new_boat_cutter_with_hold = false,
		new_boat_cutter = false,
		buy_iron = false,
		-- sell_iron = false,
		-- buy_fast_loader = true,
		-- sell_copper = false,
	}
end

function Public.main_shop_try_purchase(name)
	local memory = Memory.get_crew_memory()
	local shop_data_1 = Public.main_shop_data_1
	local shop_data_2 = Public.main_shop_data_2
	local trade_data = shop_data_1[name] or shop_data_2[name]
	if not trade_data then return end

	local stored_fuel = memory.stored_fuel
	local captain_index = memory.playerindex_captain
	if not (stored_fuel and captain_index) then return end
	local captain = game.players[captain_index]
	if not Common.validate_player_and_character(captain) then return end
	local captain_inv = captain.get_inventory(defines.inventory.character_main)
	if not captain_inv then return end

	local multiplier = Balance.main_shop_cost_multiplier()

	local can_buy = true
	-- local rate_limit_ok = not (memory.mainshop_rate_limit_ticker and memory.mainshop_rate_limit_ticker > 0)
	local rate_limit_ok = true
	local enough_fuel = true
	local enough_iron_plates = true
	local enough_coins = true
	local enough_copper_plates = true
	local coins_got = nil
	local iron_plates_got = nil
	local copper_plates_got = nil
	-- local able_to_buy_boats = memory.boat.state == Boats.enum_state.DOCKED --disabled for now
	local able_to_buy_boats = false
	-- local able_to_buy_boats = (memory.boat.state == Boats.enum_state.DOCKED or memory.boat.state == Boats.enum_state.APPROACHING) --problem with this if you buy whilst approaching, the original one no longer moves
	
	for k, v in pairs(trade_data.base_cost) do
		if k == 'fuel' then
			enough_fuel = (stored_fuel >= v * multiplier)
		elseif k == 'coins' then
			coins_got = captain_inv.get_item_count('coin')
			enough_coins = coins_got >= v * multiplier
		elseif k == 'iron_plates' then
			iron_plates_got = captain_inv.get_item_count('iron-plate')
			enough_iron_plates = iron_plates_got >= v * multiplier
		elseif k == 'copper_plates' then
			copper_plates_got = captain_inv.get_item_count('copper-plate')
			enough_copper_plates = copper_plates_got >= v * multiplier
		end
	end

	can_buy = rate_limit_ok and enough_coins and enough_fuel and enough_iron_plates and enough_copper_plates

	if name == 'new_boat_sloop_with_hold' or name == 'new_boat_cutter_with_hold' or name == 'new_boat_cutter' then can_buy = can_buy and able_to_buy_boats end

	-- potential TODO: prevent the captain from buying things whilst marooned?


	if can_buy then
		for k, v in pairs(trade_data.base_cost) do
			if k == 'fuel' then
				memory.stored_fuel = memory.stored_fuel - v * multiplier
			elseif k == 'coins' then
				captain_inv.remove{name="coin", count=v * multiplier}
			elseif k == 'iron_plates' then
				captain_inv.remove{name="iron-plate", count=v * multiplier}
			elseif k == 'copper_plates' then
				captain_inv.remove{name="copper-plate", count=v * multiplier}
			end
		end

		local force = game.forces[memory.force_name]
		if not (force and force.valid) then return end

		local gotamount
		if name == 'uranium_ore' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/uranium-238']
			Common.give(captain, {{name = 'uranium-238', count = gotamount}})
			Common.notify_force_light(force,string.format('%s is buying green rocks...', captain.name))

		elseif name == 'extra_time' then
			local success = Crew.try_add_extra_time_at_sea(60 * 60)
			if success then
				Common.notify_force_light(force,string.format('%s is buying extra time at sea...', captain.name))
			else
				Common.notify_player(captain, string.format('Can\'t buy more time than this.', captain.name))
				-- refund:
				memory.stored_fuel = memory.stored_fuel + trade_data.base_cost.fuel * multiplier
			end

		elseif name == 'rail_signal' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/rail-signal']
			Common.give(captain, {{name = 'rail-signal', count = gotamount}})
			Common.notify_force_light(force,string.format('%s is buying signals...', captain.name))

		elseif name == 'artillery_shell' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/artillery-shell']
			Common.give(captain, {{name = 'artillery-shell', count = gotamount}})
			Common.notify_force_light(force,string.format('%s is buying cannon shells...', captain.name))

		elseif name == 'artillery_remote' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/artillery-targeting-remote']
			Common.give(captain, {{name = 'artillery-targeting-remote', count = gotamount}})
			Common.notify_force_light(force,string.format('%s is buying an artillery targeting remote...', captain.name))

		elseif name == 'new_boat_cutter' or name == 'new_boat_cutter_with_hold' or name == 'new_boat_sloop_with_hold' then
			Dock.execute_boat_purchase()
			Common.notify_force_light(force,string.format('[font=heading-1]%s bought a %s.[/font]', captain.name, Boats[Common.current_destination().static_params.boat_for_sale_type].Data.display_name))

		elseif name == Upgrades.enum.MORE_POWER then
			Upgrades.execute_upgade(Upgrades.enum.MORE_POWER)
			Common.notify_force_light(force,string.format('[font=heading-1]%s upgraded the ship\'s power.[/font]', captain.name))
			memory.mainshop_availability_bools[name] = false

		elseif name == Upgrades.enum.EXTRA_HOLD then
			Upgrades.execute_upgade(Upgrades.enum.EXTRA_HOLD)
			Common.notify_force_light(force,string.format('[font=heading-1]%s upgraded the ship\'s hold.[/font]', captain.name))
			memory.mainshop_availability_bools[name] = false

		elseif name == Upgrades.enum.UNLOCK_MERCHANTS then
			Upgrades.execute_upgade(Upgrades.enum.UNLOCK_MERCHANTS)
			Common.notify_force_light(force,string.format('[font=heading-1]%s unlocked merchant ships.[/font]', captain.name))
			memory.mainshop_availability_bools[name] = false

		elseif name == Upgrades.enum.ROCKETS_FOR_SALE then
			Upgrades.execute_upgade(Upgrades.enum.ROCKETS_FOR_SALE)
			Common.notify_force_light(force,string.format('[font=heading-1]%s unlocked the sale of rockets at covered-up markets.[/font]', captain.name))
			memory.mainshop_availability_bools[name] = false

		elseif name == 'sell_iron' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/coal']
			Common.give(captain, {{name = 'fuel', count = gotamount}})
			Common.notify_force_light(force,string.format('%s is selling iron...', captain.name))

		elseif name == 'buy_iron' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/iron-plate']
			Common.give_reward_items{{name = 'iron-plate', count = gotamount}}
			Common.notify_force_light(force,string.format('%s is buying iron...', captain.name))

		elseif name == 'buy_copper' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/copper-plate']
			Common.give_reward_items{{name = 'copper-plate', count = gotamount}}
			Common.notify_force_light(force,string.format('%s is buying copper...', captain.name))

		-- elseif name == 'buy_fast_loader' then
		-- 	gotamount = trade_data.what_you_get_sprite_buttons['item/fast-loader']
		-- 	Common.give(captain, {{name = 'fast-loader', count = gotamount}})
		-- 	Common.notify_force_light(force,string.format('%s bought a fast loader...', captain.name))

		elseif name == 'sell_copper' then
			gotamount = trade_data.what_you_get_sprite_buttons['item/coal']
			Common.give(captain, {{name = 'fuel', count = gotamount}})
			Common.notify_force_light(force,string.format('%s is selling copper...', captain.name))

		end


		-- memory.mainshop_rate_limit_ticker = Common.mainshop_rate_limit_ticks
	else
		-- play sound?
		if rate_limit_ok == false then
			Common.notify_player(captain, 'Shop rate limit exceeded.')
		end
		if enough_fuel == false then
			Common.notify_player(captain, 'Not enough stored fuel.')
		end
		if enough_coins == false then
			Common.notify_player(captain, 'Not enough coins.')
		end
		if enough_iron_plates == false then
			Common.notify_player(captain, 'Not enough iron plates.')
		end
		if enough_copper_plates == false then
			Common.notify_player(captain, 'Not enough copper plates.')
		end

		if (name == 'new_boat_cutter' or name == 'new_boat_sloop_with_hold' or name == 'new_boat_cutter_with_hold') and (not able_to_buy_boats) then
			Common.notify_player(captain, 'Not able to purchase ships right now.')
		end
	end
end




function Public.event_on_market_item_purchased(event)
    local player_index, market, offer_index, trade_count = event.player_index, event.market, event.offer_index, event.count
	local player = game.players[player_index]
	if not (market and market.valid and offer_index and Common.validate_player(player)) then return end

	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local alloffers = market.get_market_items()
	local this_offer = alloffers[offer_index]

	local price = this_offer.price

	local offer_type = this_offer.offer.type
	local offer_giveitem_name, offer_giveitem_count
	if offer_type == 'give-item' then
		offer_giveitem_name = this_offer.offer.item
		offer_giveitem_count = this_offer.offer.count
	end

	local inv = player.get_inventory(defines.inventory.character_main)

	-- We want to disallow multi-purchases in this game, so we need to refund any additional purchases:
	if player and trade_count and trade_count > 1 then
		inv = player.get_inventory(defines.inventory.character_main)
		if not inv then return end
		for _, p in pairs(price) do
			inv.insert{name = p.name, count = p.amount * (trade_count - 1)}
		end
		if offer_type == 'give-item' then
			inv.remove{name = offer_giveitem_name, count = offer_giveitem_count * (trade_count - 1)}
		end
	end


	-- Here - check for BARTER vs STATIC vs ONE-oFF
	-- One-off becomes unavailable after purchase, such as class purchase
	-- Static doesn't decay
	-- Barter decays
	local decay_type
	if offer_type == 'nothing' then
		decay_type = 'one-off'
	elseif destination.type == SurfacesCommon.enum.DOCK and (price and price[1] and price[1].name and (price[1].name == 'coin')) and (offer_giveitem_name and not (offer_giveitem_name == 'stone' or offer_giveitem_name == 'iron-ore' or offer_giveitem_name == 'crude-oil-barrel' or offer_giveitem_name == 'copper-ore')) then
		decay_type = 'one-off'
	elseif (price and price[1] and price[1].name and (price[1].name == 'pistol' or price[1].name == 'burner-mining-drill')) or (offer_giveitem_name and (offer_giveitem_name == 'defender-capsule' or offer_giveitem_name == 'gun-turret')) then
		decay_type = 'static'
	else
		decay_type = 'decay'
	end

	if decay_type == 'one-off' then
		local force = player.force
		local destination = Common.current_destination()

		if offer_type == 'nothing' then
			-- check if they have a role already - renounce it if so
			if memory.classes_table and memory.classes_table[player.index] then
				Roles.try_renounce_class(player)
			end
			
			memory.classes_table[player.index] = destination.static_params.class_for_sale
	
			if force and force.valid then
				Common.notify_force_light(force,string.format('%s is now a %s. ([font=scenario-message-dialog]%s[/font])', player.name, Classes.display_form[memory.classes_table[player.index]], Classes.explanation[memory.classes_table[player.index]]))
			end
		
			if destination.dynamic_data and destination.dynamic_data.market_class_offer_rendering then
				rendering.destroy(destination.dynamic_data.market_class_offer_rendering)
			end
		else
			Common.notify_force_light(player.force, player.name .. ' bought ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. ' for ' .. price[1].amount .. ' ' .. price[1].name .. '.')
		end

		market.remove_market_item(offer_index)

	else
		-- print:
		if (price and price[1]) then
		-- if (price and price[1] and price[1].name and ((price[1].name ~= 'coin' and price[1].name ~= 'pistol') or price[2])) then
			if price[2] then
				local fish = price[2].name
				if fish == 'raw-fish' then fish = 'fish' end
				Common.notify_force_light(player.force, player.name .. ' is trading away ' .. price[1].amount .. ' ' .. price[1].name .. ' and ' .. fish .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '...')
			else
				Common.notify_force_light(player.force, player.name .. ' is trading away ' .. price[1].amount .. ' ' .. price[1].name .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '...')
			end
		end

		if decay_type == 'static' then
			if not inv then return end
			local flying_text_color = {r = 255, g = 255, b = 255}
			local text1 = '[color=1,1,1]+' .. this_offer.offer.count .. '[/color] [item=' .. alloffers[offer_index].offer.item .. ']'
			local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(alloffers[offer_index].offer.item) .. ')[/color]'
		
			Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')
		else
			if not inv then return end
			local flying_text_color = {r = 255, g = 255, b = 255}
			local text1 = '[color=1,1,1]+' .. this_offer.offer.count .. '[/color] [item=' .. alloffers[offer_index].offer.item .. ']'
			local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(this_offer.offer.item) .. ')[/color]'
		
			Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')

			--update market trades:
			alloffers[offer_index].offer.count = Math.max(Math.floor(alloffers[offer_index].offer.count * Balance.barter_decay_parameter()),1)
		
			market.clear_market_items()
			for _, offer in pairs(alloffers) do
				market.add_market_item(offer)
			end
		end
	end
end


return Public