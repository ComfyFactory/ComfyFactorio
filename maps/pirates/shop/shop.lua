
local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
local Classes = require 'maps.pirates.roles.classes'
local Crew = require 'maps.pirates.crew'
-- local Boats = require 'maps.pirates.structures.boats.boats'
-- local Dock = require 'maps.pirates.surfaces.dock'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Roles = require 'maps.pirates.roles.roles'
local Math = require 'maps.pirates.math'
local _inspect = require 'utils.inspect'.inspect
local SurfacesCommon = require 'maps.pirates.surfaces.common'
local Upgrades = require 'maps.pirates.boat_upgrades'
-- local Upgrades = require 'maps.pirates.boat_upgrades'

local Public = {}
Public.Captains = require 'maps.pirates.shop.captains'
Public.Covered = require 'maps.pirates.shop.covered'
Public.Merchants = require 'maps.pirates.shop.merchants'
Public.Minimarket = require 'maps.pirates.shop.dock'



function Public.print_transaction(player, offer_itename, offer_itemcount, price)
	local s1 = ' traded away '
	local s2 = ''
	local s3 = offer_itemcount .. ' ' .. offer_itename
	if offer_itename == 'coin' then s1 = ' sold ' end
	for i, p in pairs(price) do
		local p2 = {name = p.name, amount = p.amount}
		if p2.name == 'raw-fish' then p2.name = 'fish' end
		if p2.name == 'coin' then
			s1 = ' bought '
			p2.name = 'doubloons'
		end
		if i > 1 then
			if i == #price then
				s2 = s2 .. ' and '
			else
				s2 = s2 .. ', '
			end
		end
		s2 = s2 .. p2.amount .. ' ' .. p2.name
	end
	if s1 == ' sold ' or s1 == ' traded away ' then
		Common.notify_force_light(player.force, player.name .. s1 .. s2 .. ' for ' .. s3 .. '.')
	else
		Common.notify_force_light(player.force, player.name .. s1 .. s3 .. ' for ' .. s2 .. '.')
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

	local permission_level_fail = (in_captains_cabin and Roles.player_privilege_level(player) < Roles.privilege_levels.OFFICER) or (dock_upgrades_market and Roles.player_privilege_level(player) < Roles.privilege_levels.OFFICER)

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



function Public.event_on_market_item_purchased(event)
    local player_index, market, offer_index, trade_count = event.player_index, event.market, event.offer_index, event.count
	local player = game.players[player_index]
	if not (market and market.valid and offer_index and Common.validate_player(player)) then return end

	local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()

	local inv = player.get_inventory(defines.inventory.character_main)

	local thisPurchaseData = purchaseData(market, player, offer_index)

	local refunds = 0

	-- Normally we want to disallow multi-purchases in this game (with the exception of static trades for items), so refund any additional purchases:
	if (thisPurchaseData.decay_type ~= 'static' or thisPurchaseData.offer_type == 'nothing') and player and trade_count and trade_count > 1 then
		inv = player.get_inventory(defines.inventory.character_main)
		if not inv then return end
		for _, p in pairs(thisPurchaseData.price) do
			inv.insert{name = p.name, count = p.amount * (trade_count - 1)}
		end
		if thisPurchaseData.offer_type == 'give-item' then
			inv.remove{name = thisPurchaseData.offer_giveitem_name, count = thisPurchaseData.offer_giveitem_count * (trade_count - 1)}
		end
		refunds = refunds + (trade_count - 1)
	end

	if thisPurchaseData.decay_type == 'one-off' then
		local force = player.force

		if thisPurchaseData.dock_upgrades_market then
			if thisPurchaseData.offer_type == 'give-item' then
				-- this is the dummy artillery purchase
				inv.remove{name = thisPurchaseData.offer_giveitem_name, count = thisPurchaseData.offer_giveitem_count}
			end

			if thisPurchaseData.permission_level_fail then
				Common.notify_player_error(player, string.format('Purchase error: You need to be a captain or officer to buy this.', player.name))
				-- refund:
				inv = player.get_inventory(defines.inventory.character_main)
				if not inv then return end
				for _, p in pairs(thisPurchaseData.price) do
					inv.insert{name = p.name, count = p.amount}
				end
				refunds = refunds + 1
			else
				if thisPurchaseData.offer_type == 'give-item' then
					-- heal all cannons:
					local cannons = game.surfaces[destination.surface_name].find_entities_filtered({type = 'artillery-turret'})
					for _, c in pairs(cannons) do
						local unit_number = c.unit_number

						local healthbar = memory.boat.healthbars[unit_number]
						if healthbar then
							healthbar.health = healthbar.max_health
							Common.update_healthbar_rendering(healthbar, healthbar.max_health)
						else
							log('error: healthbar ' .. unit_number .. ' not found')
						end
					end
					Common.notify_force(force,string.format('[font=heading-1]%s repaired the ship\'s cannons.[/font]', player.name))
					market.remove_market_item(offer_index)
				else
					local upgrade_type = Common.current_destination().static_params.upgrade_for_sale
					if upgrade_type then
						Upgrades.execute_upgade(upgrade_type, player)
					end
					market.remove_market_item(offer_index)
				end
			end

		else

			if thisPurchaseData.offer_type == 'nothing' and destination.static_params.class_for_sale then

				local class_for_sale = destination.static_params.class_for_sale
				-- if not class_for_sale then return end
				local required_class = Classes.class_purchase_requirement[class_for_sale]

				local ok = true
				-- check if they have the required class to buy it
				if required_class then
					if not (memory.classes_table and memory.classes_table[player.index] and memory.classes_table[player.index] == required_class) then
						ok = false
						Common.notify_force_error(force, string.format('Class purchase error: You need to be a %s to buy this.', Classes.display_form[required_class]))
					end
				end

				if ok then
					if required_class then
						if force and force.valid then
							Common.notify_force_light(force,string.format('%s upgraded their class from %s to %s. ([font=scenario-message-dialog]%s[/font])', player.name, Classes.display_form[required_class], Classes.display_form[class_for_sale], Classes.explanation[class_for_sale]))
						end
					else
						-- check if they have a role already - renounce it if so
						if memory.classes_table and memory.classes_table[player.index] then
							Classes.try_renounce_class(player, false)
						end

						if force and force.valid then
							Common.notify_force_light(force,string.format('%s bought the class %s. ([font=scenario-message-dialog]%s[/font])', player.name, Classes.display_form[class_for_sale], Classes.explanation[class_for_sale]))
						end
					end

					memory.classes_table[player.index] = class_for_sale

					memory.available_classes_pool = Utils.ordered_table_with_single_value_removed(memory.available_classes_pool, class_for_sale)

					-- if destination.dynamic_data and destination.dynamic_data.market_class_offer_rendering then
					-- 	rendering.destroy(destination.dynamic_data.market_class_offer_rendering)
					-- end

					market.remove_market_item(offer_index)

					if Classes.class_unlocks[class_for_sale] then
						for _, upgrade in pairs(Classes.class_unlocks[class_for_sale]) do
							memory.available_classes_pool[#memory.available_classes_pool + 1] = upgrade
						end
					end
				else
					--refund
					inv = player.get_inventory(defines.inventory.character_main)
					if not inv then return end
					for _, p in pairs(thisPurchaseData.price) do
						inv.insert{name = p.name, count = p.amount}
					end
					refunds = refunds + 1
				end
			else
				Common.notify_force_light(player.force, player.name .. ' bought ' .. thisPurchaseData.offer_giveitem_count .. ' ' .. thisPurchaseData.offer_giveitem_name .. ' for ' .. thisPurchaseData.price[1].amount .. ' ' .. thisPurchaseData.price[1].name .. '.')

				market.remove_market_item(offer_index)
			end
		end

	else
		if thisPurchaseData.in_captains_cabin and thisPurchaseData.permission_level_fail then
			Common.notify_player_error(player, string.format('Purchase error: You need to be a captain or officer to buy this.', player.name))
			-- refund:
			inv = player.get_inventory(defines.inventory.character_main)
			if not inv then return end
			for _, p in pairs(thisPurchaseData.price) do
				inv.insert{name = p.name, count = p.amount}
			end
			if thisPurchaseData.offer_type == 'give-item' then
				inv.remove{name = thisPurchaseData.offer_giveitem_name, count = thisPurchaseData.offer_giveitem_count}
			end
			refunds = refunds + 1
		else
			-- print:
			if (thisPurchaseData.price and thisPurchaseData.price[1]) then
				if not (thisPurchaseData.price[1].name and thisPurchaseData.price[1].name == 'burner-mining-drill') then --this one is too boring to announce
					if thisPurchaseData.in_captains_cabin and thisPurchaseData.offer_type == 'nothing' then
						local price_name = thisPurchaseData.price[1].name
						Common.notify_force_light(player.force, player.name .. ' bought extra time at sea for ' .. thisPurchaseData.price[1].amount .. ' ' .. price_name .. '.')
					else
						Public.print_transaction(player, thisPurchaseData.offer_giveitem_name, thisPurchaseData.offer_giveitem_count, thisPurchaseData.price)
					end
				end
			end

			if thisPurchaseData.in_captains_cabin and thisPurchaseData.offer_type == 'nothing' then
				local success = Crew.try_add_extra_time_at_sea(60 * 60)
				if not success then
					Common.notify_player_error(player, string.format('Purchase error: Reached the maximum allowed loading time.', player.name))
					-- refund:
					inv = player.get_inventory(defines.inventory.character_main)
					if not inv then return end
					for _, p in pairs(thisPurchaseData.price) do
						inv.insert{name = p.name, count = p.amount}
					end
					refunds = refunds + 1
				end
			else

				if thisPurchaseData.decay_type == 'static' then
					if not inv then return end
					local flying_text_color = {r = 255, g = 255, b = 255}
					local text1 = '[color=1,1,1]+' .. thisPurchaseData.offer_giveitem_count .. '[/color] [item=' .. thisPurchaseData.alloffers[offer_index].offer.item .. ']'
					local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(thisPurchaseData.alloffers[offer_index].offer.item) .. ')[/color]'

					Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')
				else
					local decay_param =  Balance.barter_decay_parameter()
					if thisPurchaseData.decay_type == 'fast_decay' then decay_param =  Balance.barter_decay_parameter()^3 end

					if not inv then return end
					local flying_text_color = {r = 255, g = 255, b = 255}
					local text1 = '[color=1,1,1]+' .. thisPurchaseData.offer_giveitem_count .. '[/color] [item=' .. thisPurchaseData.alloffers[offer_index].offer.item .. ']'
					local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(thisPurchaseData.offer_giveitem_name) .. ')[/color]'

					Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')

					--update market trades:
					thisPurchaseData.alloffers[offer_index].offer.count = Math.max(Math.floor(thisPurchaseData.alloffers[offer_index].offer.count * decay_param),1)

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
end


return Public