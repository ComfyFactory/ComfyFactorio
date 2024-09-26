-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
local Classes = require 'maps.pirates.roles.classes'
local Crew = require 'maps.pirates.crew'
-- local Boats = require 'maps.pirates.structures.boats.boats'
-- local Dock = require 'maps.pirates.surfaces.dock'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Roles = require 'maps.pirates.roles.roles'
local Math = require 'maps.pirates.math'
local _inspect = require 'utils.inspect'.inspect
local SurfacesCommon = require 'maps.pirates.surfaces.common'
local Upgrades = require 'maps.pirates.shop.boat_upgrades'
local Cabin = require 'maps.pirates.surfaces.cabin'
-- local Upgrades = require 'maps.pirates.shop.boat_upgrades'
local Permissions = require 'maps.pirates.permissions'
local Public = {}
Public.Covered = require 'maps.pirates.shop.covered'
Public.Merchants = require 'maps.pirates.shop.merchants'
Public.Minimarket = require 'maps.pirates.shop.dock'



function Public.print_transaction(player, multiplier, offer_itemname, offer_itemcount, price)
	local type = 'traded away'

	---@type (string|table)[]
	local s2 = { '' }
	local s3 = offer_itemcount * multiplier .. ' ' .. offer_itemname
	if offer_itemname == 'coin' then type = 'sold' end
	for i, p in pairs(price) do
		local p2 = { name = p.name, amount = p.count }
		if p2.name == 'raw-fish' then p2.name = 'fish' end
		if p2.name == 'coin' then
			type = 'bought'
			p2.name = 'doubloons'
		end
		if i > 1 then
			if i == #price then
				s2[#s2 + 1] = { 'pirates.separator_2' }
			else
				s2[#s2 + 1] = { 'pirates.separator_1' }
			end
		end
		s2[#s2 + 1] = p2.count * multiplier
		s2[#s2 + 1] = ' '
		s2[#s2 + 1] = p2.name
	end
	if type == 'sold' then
		Common.notify_force_light(player.force, { 'pirates.market_event_sell', player.name, s2, s3 })
	elseif type == 'traded away' then
		Common.notify_force_light(player.force, { 'pirates.market_event_trade', player.name, s2, s3 })
	elseif type == 'bought' then
		Common.notify_force_light(player.force, { 'pirates.market_event_buy', player.name, s3, s2 })
	end
end

local function purchaseData(market, player, offer_index)
	--a proper rewriting of this function would directly check market entities against saved references to them in memory, but we haven't had time to rewrite it yet

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

	-- check for BARTER vs STATIC vs ONE-OFF
	-- One-off becomes unavailable after purchase, such as class purchase
	-- Static doesn't decay
	-- Barter decays
	local decay_type
	local dock_bool = destination.type == SurfacesCommon.enum.DOCK
	local island_bool = destination.type == SurfacesCommon.enum.ISLAND
	local purchase_bool = (price and price[1] and price[1].name and (price[1].name == 'coin'))
	local simple_efficiency_trade_bool = (price and price[1] and price[1].name and (price[1].name == 'pistol' or price[1].name == 'burner-mining-drill'))
	local special_purchase_bool = (offer_giveitem_name == 'rocket-launcher')
	-- local special_purchase_bool = (offer_giveitem_name and (offer_giveitem_name == 'loader' or offer_giveitem_name == 'fast-loader' or offer_giveitem_name == 'express-loader' or offer_giveitem_name == 'rocket-launcher'))

	local surface_name_decoded = SurfacesCommon.decode_surface_name(player.surface.name)
	local type = surface_name_decoded.type
	local in_captains_cabin = type and type == SurfacesCommon.enum.CABIN
	local dock_upgrades_market = destination.dynamic_data.dock_captains_market and (destination.dynamic_data.dock_captains_market == market)

	local permission_level_fail = (in_captains_cabin and Permissions.player_privilege_level(player) < Permissions.privilege_levels.OFFICER) or (dock_upgrades_market and Permissions.player_privilege_level(player) < Permissions.privilege_levels.OFFICER)

	if in_captains_cabin then
		decay_type = 'static'
	elseif offer_type == 'nothing' or dock_upgrades_market then
		decay_type = 'one-off'
	elseif simple_efficiency_trade_bool or special_purchase_bool then
		decay_type = 'static'
	elseif dock_bool and purchase_bool and (offer_giveitem_name) and (offer_giveitem_name == 'stone' or offer_giveitem_name == 'iron-ore' or offer_giveitem_name == 'copper-ore' or offer_giveitem_name == 'crude-oil-barrel') then
		decay_type = 'fast_decay'
	elseif dock_bool and purchase_bool and (offer_giveitem_name) then
		decay_type = 'one-off'
	elseif island_bool and (not (offer_giveitem_name and offer_giveitem_name == 'rocket')) then
		decay_type = 'one-off'
	else
		decay_type = 'decay'
	end

	return {
		alloffers = alloffers,
		decay_type = decay_type,
		price = price,
		offer_type = offer_type,
		offer_giveitem_name = offer_giveitem_name,
		offer_giveitem_count = offer_giveitem_count,
		dock_bool = dock_bool,
		island_bool = island_bool,
		purchase_bool = purchase_bool,
		simple_efficiency_trade_bool = simple_efficiency_trade_bool,
		special_purchase_bool = special_purchase_bool,
		in_captains_cabin = in_captains_cabin,
		dock_upgrades_market = dock_upgrades_market,
		permission_level_fail = permission_level_fail,
	}
end


function Public.refund_items(player, price, price_multiplier, item_purchased_name, item_purchased_count)
	local inv = player.get_inventory(defines.inventory.character_main)
	if not inv then return end

	for _, p in pairs(price) do
		local inserted = inv.insert { name = p.name, count = p.count * price_multiplier }
		if inserted < p.count * price_multiplier then
			-- Inventory is full, drop the remaining items on the ground
			player.surface.spill_item_stack(player.position, { name = p.name, count = p.count * price_multiplier - inserted }, true, player.force, false)
		end
	end

	if item_purchased_name and item_purchased_count then
		local removed = inv.remove { name = item_purchased_name, count = item_purchased_count }
		if removed < item_purchased_count then
			local nearby_floor_items = player.surface.find_entities_filtered { area = { { player.position.x - 20, player.position.y - 20 }, { player.position.x + 20, player.position.y + 20 } }, name = 'item-on-ground' }
			local whilesafety = 2000
			local i = 1
			while removed < item_purchased_count and i <= #nearby_floor_items and i < whilesafety do
				if nearby_floor_items[i].stack and nearby_floor_items[i].stack.name and nearby_floor_items[i].stack.count and nearby_floor_items[i].stack.name == item_purchased_name then
					nearby_floor_items[i].destroy()
					removed = removed + 1
					-- local removed_count = nearby_floor_items[i].stack.count
					-- if removed_count > item_purchased_count - removed then
					-- 	removed_count = item_purchased_count - removed
					-- end
					-- if removed_count == nearby_floor_items[i].stack.count then
					-- 	nearby_floor_items[i].destroy()
					-- else
					-- 	nearby_floor_items[i].stack.count = nearby_floor_items[i].stack.count - removed_count
					-- end
					-- removed = removed + removed_count
				end
				i = i + 1
			end
			if i == whilesafety then log('ERROR: whilesafety reached') end
		end
	end
end

function Public.event_on_market_item_purchased(event)
	local player_index, market, offer_index, trade_count = event.player_index, event.market, event.offer_index, event.count
	local player = game.players[player_index]
	if not (market and market.valid and offer_index and Common.validate_player(player)) then return end

	local crew_id = Common.get_id_from_force_name(player.force.name)
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local inv = player.get_inventory(defines.inventory.character_main)

	local thisPurchaseData = purchaseData(market, player, offer_index)

	local refunds = 0

	-- Normally we want to disallow multi-purchases in this game (with the exception of static trades for items), so refund any additional purchases:
	if (thisPurchaseData.decay_type ~= 'static' or thisPurchaseData.offer_type == 'nothing') and player and trade_count and trade_count > 1 then
		if thisPurchaseData.offer_type == 'give-item' then
			Public.refund_items(player, thisPurchaseData.price, (trade_count - 1), thisPurchaseData.offer_giveitem_name, thisPurchaseData.offer_giveitem_count * (trade_count - 1))
		else
			Public.refund_items(player, thisPurchaseData.price, (trade_count - 1))
		end
		refunds = refunds + (trade_count - 1)
	end

	if thisPurchaseData.decay_type == 'one-off' then
		local force = player.force

		if thisPurchaseData.dock_upgrades_market then
			if thisPurchaseData.permission_level_fail then
				refunds = trade_count
				Common.notify_player_error(player, { 'pirates.market_error_not_captain' })
				-- refund:
				Public.refund_items(player, thisPurchaseData.price, 1)
				refunds = refunds + 1
			else
				local upgrade_type = Common.current_destination().static_params.upgrade_for_sale
				if upgrade_type then
					Upgrades.execute_upgade(upgrade_type, player)
				else
					log('Error purchasing upgrade at dock')
				end
				market.remove_market_item(offer_index)
			end
		else
			if thisPurchaseData.offer_type == 'nothing' then
				local isDamageUpgrade = thisPurchaseData.price[1].count == Balance.weapon_damage_upgrade_price()[1].count and thisPurchaseData.price[1].name == Balance.weapon_damage_upgrade_price()[1].name

				if isDamageUpgrade then
					Common.notify_force_light(player.force, { 'pirates.market_event_attack_upgrade_purchased', player.name, Balance.weapon_damage_upgrade_percentage() })
					market.remove_market_item(offer_index)

					Crew.buff_all_damage(Balance.weapon_damage_upgrade_percentage() / 100)
				elseif destination.static_params.class_for_sale then
					local class_for_sale = destination.static_params.class_for_sale
					-- if not class_for_sale then return end
					local required_class = Classes.class_purchase_requirement[class_for_sale]

					local ok = Classes.try_unlock_class(class_for_sale, player, false)

					if ok then
						market.remove_market_item(offer_index)
					else -- if this happens, I believe there is something wrong with code
						if force and force.valid then
							Common.notify_force_error(force, { 'pirates.class_purchase_error_prerequisite_class', Classes.display_form(required_class) })
						end

						--refund
						refunds = refunds + 1
						Public.refund_items(player, thisPurchaseData.price, 1)
						log('Error purchasing class: ' .. class_for_sale)
					end
				end
			else
				Common.notify_force_light(player.force, { 'pirates.market_event_buy', player.name, thisPurchaseData.offer_giveitem_count .. ' ' .. thisPurchaseData.offer_giveitem_name, thisPurchaseData.price[1].count .. ' ' .. thisPurchaseData.price[1].name })

				market.remove_market_item(offer_index)
			end
		end
	else
		if thisPurchaseData.in_captains_cabin and thisPurchaseData.permission_level_fail then
			Common.notify_player_error(player, { 'pirates.market_error_not_captain_or_officer' })
			-- refund:
			if thisPurchaseData.decay_type == 'static' then
				if thisPurchaseData.offer_type == 'give-item' then
					Public.refund_items(player, thisPurchaseData.price, trade_count, thisPurchaseData.offer_giveitem_name, thisPurchaseData.offer_giveitem_count * trade_count)
				else
					Public.refund_items(player, thisPurchaseData.price, trade_count)
				end
				refunds = refunds + trade_count
			else
				if thisPurchaseData.offer_type == 'give-item' then
					Public.refund_items(player, thisPurchaseData.price, 1, thisPurchaseData.offer_giveitem_name, thisPurchaseData.offer_giveitem_count)
				else
					Public.refund_items(player, thisPurchaseData.price, 1)
				end
				refunds = refunds + 1
			end
		else
			-- print:
			-- if (thisPurchaseData.price and thisPurchaseData.price[1]) then
			-- 	if not (thisPurchaseData.price[1].name and thisPurchaseData.price[1].name == 'burner-mining-drill') then --this one is too boring to announce
			-- 		if thisPurchaseData.in_captains_cabin and thisPurchaseData.offer_type == 'nothing' then
			-- 			Common.notify_force_light(player.force, {'pirates.market_event_buy', player.name, {'pirates.extra_time_at_sea'}, thisPurchaseData.price[1].count .. ' ' .. thisPurchaseData.price[1].name})
			-- 		else
			-- 			Public.print_transaction(player, trade_count - refunds, thisPurchaseData.offer_giveitem_name, thisPurchaseData.offer_giveitem_count, thisPurchaseData.price)
			-- 		end
			-- 	end
			-- end

			if thisPurchaseData.in_captains_cabin and thisPurchaseData.offer_type == 'nothing' then
				if offer_index == Cabin.enum.SLOT_EXTRA_HOLD then
					Upgrades.execute_upgade(Upgrades.enum.EXTRA_HOLD, player)
				elseif offer_index == Cabin.enum.SLOT_MORE_POWER then
					Upgrades.execute_upgade(Upgrades.enum.MORE_POWER, player)
				elseif offer_index == Cabin.enum.SLOT_RANDOM_CLASS then
					local class = Classes.generate_class_for_sale()
					local ok = Classes.try_unlock_class(class, player, false)
					if ok then
						memory.boat.random_class_purchase_count = memory.boat.random_class_purchase_count + 1
					else
						if player.force and player.force.valid then
							Common.notify_force_error(player.force, 'Oops, something went wrong trying to purchase a class!')
						end
					end
				end

				Cabin.handle_purchase(market, offer_index)

				-- local success = Crew.try_add_extra_time_at_sea(60 * 60)
				-- if not success then
				-- 	Common.notify_player_error(player, {'pirates.market_error_maximum_loading_time'})
				-- 	-- refund:
				-- 	Public.refund_items(player, thisPurchaseData.price, 1)
				-- 	refunds = refunds + 1
				-- end
			else
				if thisPurchaseData.price and thisPurchaseData.price[1] then
					Public.print_transaction(player, trade_count - refunds, thisPurchaseData.offer_giveitem_name, thisPurchaseData.offer_giveitem_count, thisPurchaseData.price)
				end

				if thisPurchaseData.decay_type == 'static' then
					if not inv then return end
					local flying_text_color = { r = 255, g = 255, b = 255 }
					local text1 = '[color=1,1,1]+' .. thisPurchaseData.offer_giveitem_count .. '[/color] [item=' .. thisPurchaseData.offer_giveitem_name .. ']'
					local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(thisPurchaseData.offer_giveitem_name) .. ')[/color]'

					Common.flying_text(player, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')
				else
					local decay_param = Balance.barter_decay_parameter()
					if thisPurchaseData.decay_type == 'fast_decay' then decay_param = Balance.barter_decay_parameter() ^ 3 end

					if not inv then return end
					local flying_text_color = { r = 255, g = 255, b = 255 }
					local text1 = '[color=1,1,1]+' .. thisPurchaseData.offer_giveitem_count .. '[/color] [item=' .. thisPurchaseData.offer_giveitem_name .. ']'
					local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(thisPurchaseData.offer_giveitem_name) .. ')[/color]'

					Common.flying_text(player, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')

					--update market trades:
					thisPurchaseData.alloffers[offer_index].offer.count = Math.max(Math.floor(thisPurchaseData.alloffers[offer_index].offer.count * decay_param), 1)

					market.clear_market_items()
					for _, offer in pairs(thisPurchaseData.alloffers) do
						market.add_market_item(offer)
					end
				end
			end
		end
	end

	if thisPurchaseData.offer_giveitem_name and thisPurchaseData.offer_giveitem_name == 'coin' and refunds < trade_count then
		memory.playtesting_stats.coins_gained_by_markets = memory.playtesting_stats.coins_gained_by_markets + thisPurchaseData.offer_giveitem_count
	end

	if (not memory.cliff_explosives_acquired_once) and thisPurchaseData.offer_type == 'give-item' and thisPurchaseData.offer_giveitem_name == 'cliff-explosives' and refunds < trade_count then
		memory.cliff_explosives_acquired_once = true
		Common.parrot_speak(memory.force, { 'pirates.parrot_cliff_explosive_tip' })
	end
end

return Public
