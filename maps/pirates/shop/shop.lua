
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
	elseif offer_type == 'nothing' then
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

	local refunds = 0

	-- Normally we want to disallow multi-purchases in this game (with the exception of static trades for items), so refund any additional purchases:
	if (decay_type ~= 'static' or offer_type == 'nothing') and player and trade_count and trade_count > 1 then
		inv = player.get_inventory(defines.inventory.character_main)
		if not inv then return end
		for _, p in pairs(price) do
			inv.insert{name = p.name, count = p.amount * (trade_count - 1)}
		end
		if offer_type == 'give-item' then
			inv.remove{name = offer_giveitem_name, count = offer_giveitem_count * (trade_count - 1)}
		end
		refunds = refunds + (trade_count - 1)
	end

	if decay_type == 'one-off' then
		local force = player.force

		if dock_upgrades_market then
			if offer_type == 'give-item' then
				-- this is the dummy artillery purchase
				inv.remove{name = offer_giveitem_name, count = offer_giveitem_count}
			end

			if permission_level_fail then
				Common.notify_player_error(player, string.format('Purchase error: You need to be a captain or officer to buy this.', player.name))
				-- refund:
				inv = player.get_inventory(defines.inventory.character_main)
				if not inv then return end
				for _, p in pairs(price) do
					inv.insert{name = p.name, count = p.amount}
				end
				refunds = refunds + 1
			else
				if offer_type == 'give-item' then
					-- heal all cannons:
					local cannons = game.surfaces[destination.surface_name].find_entities_filtered({type = 'artillery-turret'})
					for _, c in pairs(cannons) do
						local unit_number = c.unit_number
					
						local healthbar = memory.healthbars[unit_number]
						if healthbar then
							healthbar.health = healthbar.max_health
							Common.update_healthbar_rendering(healthbar, healthbar.max_health)
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

			if offer_type == 'nothing' and destination.static_params.class_for_sale then
	
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
					for _, p in pairs(price) do
						inv.insert{name = p.name, count = p.amount}
					end
					refunds = refunds + 1
				end
			else
				Common.notify_force_light(player.force, player.name .. ' bought ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. ' for ' .. price[1].amount .. ' ' .. price[1].name .. '.')
	
				market.remove_market_item(offer_index)
			end
		end

	else
		if in_captains_cabin and permission_level_fail then
			Common.notify_player_error(player, string.format('Purchase error: You need to be a captain or officer to buy this.', player.name))
			-- refund:
			inv = player.get_inventory(defines.inventory.character_main)
			if not inv then return end
			for _, p in pairs(price) do
				inv.insert{name = p.name, count = p.amount}
			end
			if offer_type == 'give-item' then
				inv.remove{name = offer_giveitem_name, count = offer_giveitem_count}
			end
			refunds = refunds + 1
		else
			-- print:
			if (price and price[1]) then
				if not (price[1].name and price[1].name == 'burner-mining-drill') then --this one is too boring to announce
					if in_captains_cabin and offer_type == 'nothing' then
						local price_name = price[1].name
						Common.notify_force_light(player.force, player.name .. ' bought extra time at sea for ' .. price[1].amount .. ' ' .. price_name .. '.')
					else
						if price[2] then
							local price_name = price[2].name
							if price_name == 'raw-fish' then price_name = 'fish' end
							Common.notify_force_light(player.force, player.name .. ' traded away ' .. price[1].amount .. ' ' .. price[1].name .. ' and ' .. price_name .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '.')
						else
							local price_name = price[1].name
							if price_name == 'raw-fish' then price_name = 'fish' end
							if price_name == 'coin' then
								Common.notify_force_light(player.force, player.name .. ' bought ' ..this_offer.offer.count .. ' ' .. this_offer.offer.item  .. ' for ' .. price[1].amount .. ' ' .. price_name .. '.')
							elseif this_offer.offer.item == 'coin' then
								local sold_amount = price[1].amount
								if sold_amount == 1 then sold_amount = 'a' end
								Common.notify_force_light(player.force, player.name .. ' sold ' .. sold_amount .. ' ' .. price_name .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '.')
							else
								Common.notify_force_light(player.force, player.name .. ' traded away ' .. price[1].amount .. ' ' .. price_name .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '.')
							end
						end
					end
				end
			end
	
			if in_captains_cabin and offer_type == 'nothing' then
				local success = Crew.try_add_extra_time_at_sea(60 * 60)
				if not success then
					Common.notify_player_error(player, string.format('Purchase error: Reached the maximum allowed loading time.', player.name))
					-- refund:
					inv = player.get_inventory(defines.inventory.character_main)
					if not inv then return end
					for _, p in pairs(price) do
						inv.insert{name = p.name, count = p.amount}
					end
					refunds = refunds + 1
				end
			else
	
				if decay_type == 'static' then
					if not inv then return end
					local flying_text_color = {r = 255, g = 255, b = 255}
					local text1 = '[color=1,1,1]+' .. this_offer.offer.count .. '[/color] [item=' .. alloffers[offer_index].offer.item .. ']'
					local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(alloffers[offer_index].offer.item) .. ')[/color]'
	
					Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')
				else
					local decay_param =  Balance.barter_decay_parameter()
					if decay_type == 'fast_decay' then decay_param =  Balance.barter_decay_parameter()^3 end
	
					if not inv then return end
					local flying_text_color = {r = 255, g = 255, b = 255}
					local text1 = '[color=1,1,1]+' .. this_offer.offer.count .. '[/color] [item=' .. alloffers[offer_index].offer.item .. ']'
					local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(this_offer.offer.item) .. ')[/color]'
	
					Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')
	
					--update market trades:
					alloffers[offer_index].offer.count = Math.max(Math.floor(alloffers[offer_index].offer.count * decay_param),1)
	
					market.clear_market_items()
					for _, offer in pairs(alloffers) do
						market.add_market_item(offer)
					end
				end
			end
		end
	end

	if this_offer.offer.item == 'coin' then
		memory.playtesting_stats.coins_gained_by_markets = memory.playtesting_stats.coins_gained_by_markets + this_offer.offer.count
	end
end


return Public