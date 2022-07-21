-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
-- local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local CustomEvents = require 'maps.pirates.custom_events'
-- local SurfacesCommon = require 'maps.pirates.surfaces.common'
local Raffle = require 'maps.pirates.raffle'
local ShopCovered = require 'maps.pirates.shop.covered'
local Classes = require 'maps.pirates.roles.classes'
local Loot = require 'maps.pirates.loot'

local Public = {}
Public.Data = require 'maps.pirates.structures.quest_structures.market1.data'


function Public.create_step1_entities()
    local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local quest_structure_data = destination.dynamic_data.quest_structure_data
	if not quest_structure_data then return end

	local position = quest_structure_data.position
	local hardcoded_data = Public.Data.step1

	quest_structure_data.blue_chest = surface.create_entity{name = 'blue-chest', position = Math.vector_sum(position, hardcoded_data.blue_chest), force = 'environment'}
	if quest_structure_data.blue_chest and quest_structure_data.blue_chest.valid then
		quest_structure_data.blue_chest.minable = false
		quest_structure_data.blue_chest.rotatable = false
		quest_structure_data.blue_chest.operable = false
		quest_structure_data.blue_chest.destructible = false
	end
	quest_structure_data.red_chest = surface.create_entity{name = 'red-chest', position = Math.vector_sum(position, hardcoded_data.red_chest), force = 'environment'}
	if quest_structure_data.red_chest and quest_structure_data.red_chest.valid then
		quest_structure_data.red_chest.minable = false
		quest_structure_data.red_chest.rotatable = false
		quest_structure_data.red_chest.operable = false
		quest_structure_data.red_chest.destructible = false
	end
	quest_structure_data.door_walls = {}
	for _, p in pairs(hardcoded_data.walls) do
		local e = surface.create_entity{name = 'stone-wall', position = Math.vector_sum(position, p), force = 'environment'}
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.operable = false
			e.destructible = false
		end
		quest_structure_data.door_walls[#quest_structure_data.door_walls + 1] = e
	end
end


function Public.create_step2_entities()
	local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local quest_structure_data = destination.dynamic_data.quest_structure_data
	if not quest_structure_data then return end

	local position = quest_structure_data.position
	local hardcoded_data = Public.Data.step2

	quest_structure_data.market = surface.create_entity{name = 'market', position = Math.vector_sum(position, hardcoded_data.market), force = memory.ancient_friendly_force_name}
	if quest_structure_data.market and quest_structure_data.market.valid then
		quest_structure_data.market.minable = false
		quest_structure_data.market.rotatable = false
		quest_structure_data.market.destructible = false

		-- quest_structure_data.market.add_market_item{price={{'pistol', 1}}, offer={type = 'give-item', item = 'coin', count = Balance.coin_sell_amount}}
		-- quest_structure_data.market.add_market_item{price={{'burner-mining-drill', 1}}, offer={type = 'give-item', item = 'iron-plate', count = 9}}

		local how_many_coin_offers = 5
		if Balance.crew_scale() >= 1.2 then how_many_coin_offers = 6 end

		-- Thinking of not having these offers available always (if it's bad design decision can always change it back)
		if Math.random(4) == 1 then
			quest_structure_data.market.add_market_item{price={{'pistol', 1}}, offer={type = 'give-item', item = 'coin', count = Balance.coin_sell_amount}}
			how_many_coin_offers = how_many_coin_offers - 1
		end

		if Math.random(4) == 1 then
			quest_structure_data.market.add_market_item{price={{'burner-mining-drill', 1}}, offer={type = 'give-item', item = 'iron-plate', count = 9}}
			how_many_coin_offers = how_many_coin_offers - 1
		end

		local coin_offers = ShopCovered.market_generate_coin_offers(how_many_coin_offers)
		for _, o in pairs(coin_offers) do
			quest_structure_data.market.add_market_item(o)
		end

		if destination.static_params.class_for_sale then
			quest_structure_data.market.add_market_item{price={{'coin', Balance.class_cost(false)}}, offer={type="nothing", effect_description = {'pirates.market_description_purchase_class', Classes.display_form(destination.static_params.class_for_sale)}}}

			-- destination.dynamic_data.market_class_offer_rendering = rendering.draw_text{
			-- 	text = 'Class available: ' .. Classes.display_form(destination.static_params.class_for_sale),
			-- 	surface = surface,
			-- 	target = Utils.psum{special.position, hardcoded_data.market, {x = 1, y = -3.9}},
			-- 	color = CoreData.colors.renderingtext_green,
			-- 	scale = 2.5,
			-- 	font = 'default-game',
			-- 	alignment = 'center'
			-- }
		end
	end

	quest_structure_data.steel_chest = surface.create_entity{name = 'steel-chest', position = Math.vector_sum(position, hardcoded_data.steel_chest), force = memory.ancient_friendly_force_name}
	if quest_structure_data.steel_chest and quest_structure_data.steel_chest.valid then
		quest_structure_data.steel_chest.minable = false
		quest_structure_data.steel_chest.rotatable = false
		quest_structure_data.steel_chest.destructible = false

		local inv = quest_structure_data.steel_chest.get_inventory(defines.inventory.chest)
		local loot = destination.dynamic_data.quest_structure_data.entry_price.raw_materials
		for j = 1, #loot do
			local l = loot[j]
			if l.count > 0 then
				inv.insert(l)
			end
		end
	end

	for _, w in pairs(quest_structure_data.door_walls) do
		w.destructible = true
		w.destroy()
	end

	quest_structure_data.wooden_chests = {}
	for k, p in ipairs(hardcoded_data.wooden_chests) do
		local e = surface.create_entity{name = 'wooden-chest', position = Math.vector_sum(position, p), force = memory.ancient_friendly_force_name}
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.destructible = false

			local inv = e.get_inventory(defines.inventory.chest)
			local loot = Loot.covered_wooden_chest_loot()
			if k==1 then loot[1] = {name = 'coin', count = 2000} end
			--@TODO: log this in coin stats
			for j = 1, #loot do
				local l = loot[j]
				inv.insert(l)
			end
		end
		quest_structure_data.wooden_chests[#quest_structure_data.wooden_chests + 1] = e
	end
end

Public.entry_price_data_raw = {
	--watch out that the raw_materials chest can only hold e.g. 4.8 iron-plates
	-- choose things that are easy to make at outposts
	-- if the prices are too high, players will accidentally throw too much in when they can't do it
	['iron-stick'] = {
		overallWeight = 1,
		minLambda = 0,
		maxLambda = 1,
		shape = false,
		base_amount = 1500,
		raw_materials = {{name = 'iron-plate', count = 750}}
	},
	['copper-cable'] = {
		overallWeight = 0.85,
		minLambda = 0,
		maxLambda = 1,
		shape = false,
		base_amount = 1500,
		raw_materials = {{name = 'copper-plate', count = 750}}
	},
	['small-electric-pole'] = {
		overallWeight = 1,
		minLambda = 0,
		maxLambda = 0.3,
		shape = false,
		base_amount = 450,
		raw_materials = {{name = 'copper-plate', count = 900}}
	},
	['assembling-machine-1'] = {
		overallWeight = 1,
		minLambda = 0.1,
		maxLambda = 1,
		shape = false,
		base_amount = 80,
		raw_materials = {{name = 'iron-plate', count = 1760}, {name = 'copper-plate', count = 360}}
	},
	['burner-mining-drill'] = {
		overallWeight = 0.25,
		minLambda = 0,
		maxLambda = 0.15,
		shape = false,
		base_amount = 150,
		raw_materials = {{name = 'iron-plate', count = 1350}}
	},
	['burner-inserter'] = {
		overallWeight = 0.75,
		minLambda = 0,
		maxLambda = 0.6,
		shape = false,
		base_amount = 300,
		raw_materials = {{name = 'iron-plate', count = 900}}
	},
	['small-lamp'] = {
		overallWeight = 1,
		minLambda = 0.05,
		maxLambda = 0.7,
		shape = false,
		base_amount = 300,
		raw_materials = {{name = 'iron-plate', count = 600}, {name = 'copper-plate', count = 900}}
	},
	['firearm-magazine'] = {
		overallWeight = 1,
		minLambda = 0,
		maxLambda = 1,
		shape = false,
		base_amount = 700,
		raw_materials = {{name = 'iron-plate', count = 2800}}
	},
	['constant-combinator'] = {
		overallWeight = 0.6,
		minLambda = 0,
		maxLambda = 1,
		shape = false,
		base_amount = 276,
		raw_materials = {{name = 'iron-plate', count = 552}, {name = 'copper-plate', count = 1518}}
	},
	['stone-furnace'] = {
		overallWeight = 1,
		minLambda = 0.05,
		maxLambda = 1,
		shape = false,
		base_amount = 250,
		raw_materials = {{name = 'stone', count = 1250}}
	},
	['advanced-circuit'] = {
		overallWeight = 1,
		minLambda = 0.4,
		maxLambda = 1.6,
		shape = true,
		base_amount = 180,
		raw_materials = {{name = 'iron-plate', count = 360}, {name = 'copper-plate', count = 900}, {name = 'plastic-bar', count = 360}}
	},
	['wooden-chest'] = {
		overallWeight = 0.5,
		minLambda = -0.5,
		maxLambda = 0.5,
		shape = true,
		base_amount = 400,
		raw_materials = {}
	},
	['iron-chest'] = {
		overallWeight = 0.5,
		minLambda = 0,
		maxLambda = 1,
		shape = true,
		base_amount = 250,
		raw_materials = {{name = 'iron-plate', count = 2000}}
	},
	['steel-chest'] = {
		overallWeight = 0.5,
		minLambda = 0.25,
		maxLambda = 1.75,
		shape = true,
		base_amount = 125,
		raw_materials = {{name = 'steel-plate', count = 1000}}
	},
}

function Public.entry_price()
	local lambda = Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(),1/2) * Common.game_completion_progress())

	local item = Raffle.LambdaRaffle(Public.entry_price_data_raw, lambda)

	local raw_materials = Public.entry_price_data_raw[item].raw_materials

	return {
		name = item,
		count = Math.ceil(
			(0.9 + 0.2 * Math.random()) * Public.entry_price_data_raw[item].base_amount * Balance.quest_structure_entry_price_scale()
		),
		raw_materials = raw_materials,
	}
end


return Public