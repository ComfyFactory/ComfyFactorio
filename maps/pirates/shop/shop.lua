
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
	local special_purchase_bool = (offer_giveitem_name and (offer_giveitem_name == 'loader' or offer_giveitem_name == 'fast-loader' or offer_giveitem_name == 'express-loader' or offer_giveitem_name == 'rocket-launcher'))

	if offer_type == 'nothing' then
		decay_type = 'one-off'
	elseif dock_bool and purchase_bool and (offer_giveitem_name) and (offer_giveitem_name == 'stone' or offer_giveitem_name == 'iron-ore' or offer_giveitem_name == 'copper-ore' or offer_giveitem_name == 'crude-oil-barrel') then
		decay_type = 'double_decay'
	elseif dock_bool and purchase_bool and (offer_giveitem_name) then
		decay_type = 'one-off'
	elseif simple_efficiency_trade_bool or special_purchase_bool then
		decay_type = 'static'
	elseif island_bool and (not (offer_giveitem_name and offer_giveitem_name == 'rocket')) then
		decay_type = 'one-off'
	else
		decay_type = 'decay'
	end

	-- For everything but static, we want to disallow multi-purchases in this game, so refund any additional purchases:
	if decay_type ~= 'static' and player and trade_count and trade_count > 1 then
		inv = player.get_inventory(defines.inventory.character_main)
		if not inv then return end
		for _, p in pairs(price) do
			inv.insert{name = p.name, count = p.amount * (trade_count - 1)}
		end
		if offer_type == 'give-item' then
			inv.remove{name = offer_giveitem_name, count = offer_giveitem_count * (trade_count - 1)}
		end
	end

	if decay_type == 'one-off' then
		local force = player.force

		if offer_type == 'nothing' and destination.static_params.class_for_sale then

			local class_for_sale = destination.static_params.class_for_sale
			-- if not class_for_sale then return end
			local required_class = Classes.class_purchase_requirement[class_for_sale]

			local ok = true
			-- check if they have the required class to buy it
			if required_class then
				if not (memory.classes_table and memory.classes_table[player.index] and memory.classes_table[player.index] == required_class) then
					ok = false
					Common.notify_error(force,string.format('Class purchase error: you need to be a %s to buy this.', Classes.display_form[required_class]))
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
						Classes.try_renounce_class(player)
					end

					if force and force.valid then
						Common.notify_force_light(force,string.format('%s bought the class %s. ([font=scenario-message-dialog]%s[/font])', player.name, Classes.display_form[class_for_sale], Classes.explanation[class_for_sale]))
					end
				end

				memory.classes_table[player.index] = class_for_sale

				memory.available_classes_pool = Utils.ordered_table_with_single_value_removed(memory.available_classes_pool, class_for_sale)
			
				if destination.dynamic_data and destination.dynamic_data.market_class_offer_rendering then
					rendering.destroy(destination.dynamic_data.market_class_offer_rendering)
				end

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
			end
		else
			Common.notify_force_light(player.force, player.name .. ' bought ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. ' for ' .. price[1].amount .. ' ' .. price[1].name .. '.')

			market.remove_market_item(offer_index)
		end


	else
		-- print:
		if (price and price[1]) then
			if not (price[1].name and price[1].name == 'burner-mining-drill') then --this one is too boring to announce
				if price[2] then
					local fish = price[2].name
					if fish == 'raw-fish' then fish = 'fish' end
					Common.notify_force_light(player.force, player.name .. ' is trading away ' .. price[1].amount .. ' ' .. price[1].name .. ' and ' .. fish .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '...')
				else
					if price[1].name == 'coin' then
						Common.notify_force_light(player.force, player.name .. ' bought ' ..this_offer.offer.count .. ' ' .. this_offer.offer.item  .. ' for ' .. price[1].amount .. ' ' .. price[1].name .. '...')
					elseif this_offer.offer.item == 'coin' then
						local sold_amount = price[1].amount
						if sold_amount == 1 then sold_amount = 'a' end
						Common.notify_force_light(player.force, player.name .. ' sold ' .. sold_amount .. ' ' .. price[1].name .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '...')
					else
						Common.notify_force_light(player.force, player.name .. ' is trading away ' .. price[1].amount .. ' ' .. price[1].name .. ' for ' .. this_offer.offer.count .. ' ' .. this_offer.offer.item .. '...')
					end
				end
			end
		end

		if decay_type == 'static' then
			if not inv then return end
			local flying_text_color = {r = 255, g = 255, b = 255}
			local text1 = '[color=1,1,1]+' .. this_offer.offer.count .. '[/color] [item=' .. alloffers[offer_index].offer.item .. ']'
			local text2 = '[color=' .. flying_text_color.r .. ',' .. flying_text_color.g .. ',' .. flying_text_color.b .. '](' .. inv.get_item_count(alloffers[offer_index].offer.item) .. ')[/color]'
		
			Common.flying_text(player.surface, player.position, text1 .. '  [font=count-font]' .. text2 .. '[/font]')
		else
			local decay_param =  Balance.barter_decay_parameter()
			if decay_type == 'double_decay' then decay_param =  Balance.barter_decay_parameter()^2 end

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


return Public