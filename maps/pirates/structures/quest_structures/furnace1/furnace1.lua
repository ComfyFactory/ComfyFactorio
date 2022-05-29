
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
local CustomEvents = require 'maps.pirates.custom_events'
local SurfacesCommon = require 'maps.pirates.surfaces.common'
local Raffle = require 'maps.pirates.raffle'
local ShopCovered = require 'maps.pirates.shop.covered'
local Classes = require 'maps.pirates.roles.classes'
local Loot = require 'maps.pirates.loot'


local Public = {}
Public.Data = require 'maps.pirates.structures.quest_structures.furnace1.data'



function Public.create_step1_entities()
	local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local quest_structure_data = destination.dynamic_data.quest_structure_data
	if not quest_structure_data then return end

	local position = quest_structure_data.position
	local hardcoded_data = Public.Data.step1

	quest_structure_data.blue_chests = {}
	for _, chest_position in pairs(hardcoded_data.blue_chests) do
		local e = surface.create_entity{name = 'blue-chest', position = Math.vector_sum(position, chest_position), force = 'environment'}
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.operable = false
			e.destructible = false
			quest_structure_data.blue_chests[#quest_structure_data.blue_chests+1] = e
		end
	end
	quest_structure_data.red_chests = {}
	for _, chest_position in pairs(hardcoded_data.red_chests) do
		local e = surface.create_entity{name = 'red-chest', position = Math.vector_sum(position, chest_position), force = 'environment'}
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.operable = false
			e.destructible = false
			quest_structure_data.red_chests[#quest_structure_data.red_chests+1] = e
		end
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

	quest_structure_data.market = surface.create_entity{name = 'market', position = Math.vector_sum(position, hardcoded_data.market), force = string.format('ancient-friendly-%03d', memory.id)}
	if quest_structure_data.market and quest_structure_data.market.valid then
		quest_structure_data.market.minable = false
		quest_structure_data.market.rotatable = false
		quest_structure_data.market.destructible = false

		quest_structure_data.market.add_market_item{price={{'pistol', 1}}, offer={type = 'give-item', item = 'coin', count = Balance.coin_sell_amount}}
		quest_structure_data.market.add_market_item{price={{'burner-mining-drill', 1}}, offer={type = 'give-item', item = 'iron-plate', count = 9}}

		local how_many_coin_offers = 4
		if Balance.crew_scale() >= 1.2 then how_many_coin_offers = 5 end
		local coin_offers = ShopCovered.market_generate_coin_offers(how_many_coin_offers)
		for _, o in pairs(coin_offers) do
			quest_structure_data.market.add_market_item(o)
		end

		if destination.static_params.class_for_sale then
			quest_structure_data.market.add_market_item{price={{'coin', Balance.class_cost()}}, offer={type="nothing", effect_description = {'pirates.market_description_purchase_class', Classes.display_form(destination.static_params.class_for_sale)}}}

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

	for _, w in pairs(quest_structure_data.door_walls) do
		if w and w.valid then
			w.destructible = true
			w.destroy()
		end
	end

	quest_structure_data.wooden_chests = {}
	for k, p in ipairs(hardcoded_data.wooden_chests) do
		local e = surface.create_entity{name = 'wooden-chest', position = Math.vector_sum(position, p), force = string.format('ancient-friendly-%03d', memory.id)}
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.destructible = false

			local inv = e.get_inventory(defines.inventory.chest)
			if k==1 then
				inv.insert({name = 'coin', count = 2000})
			elseif k==4 then
				local loot = Loot.covered_wooden_chest_loot_1()
				for j = 1, #loot do
					local l = loot[j]
					inv.insert(l)
				end
			else
				local loot = Loot.covered_wooden_chest_loot_2()
				for j = 1, #loot do
					local l = loot[j]
					inv.insert(l)
				end
			end
		end
		quest_structure_data.wooden_chests[#quest_structure_data.wooden_chests + 1] = e
	end
end



Public.entry_price_data_raw = {-- choose things which make interesting minifactories
	['electric-mining-drill'] = {
		overallWeight = 1,
		minLambda = -0.75,
		maxLambda = 0.75,
		shape = 'bump',
		enabled = true,
		base_amount = 600,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 46, ['copper-plate'] = 9},
	},
	['fast-splitter'] = {
		overallWeight = 1,
		minLambda = -1,
		maxLambda = 1,
		shape = 'bump',
		enabled = true,
		base_amount = 300,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 92, ['copper-plate'] = 45},
	},
	['assembling-machine-1'] = {
		overallWeight = 1,
		minLambda = -1,
		maxLambda = 1,
		shape = 'bump',
		enabled = true,
		base_amount = 600,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 44, ['copper-plate'] = 9},
	},
	['filter-inserter'] = {
		overallWeight = 1,
		minLambda = 0,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 500,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 32, ['copper-plate'] = 24},
	},
	['programmable-speaker'] = {
		overallWeight = 1,
		minLambda = 0,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 500,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 18, ['copper-plate'] = 17},
	},
	['pump'] = {
		overallWeight = 1,
		minLambda = 0.05,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 350,
		itemBatchSize = 1,
		batchRawMaterials = {['iron-plate'] = 15},
	},
	['grenade'] = {
		overallWeight = 1,
		minLambda = 0.05,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 500,
		itemBatchSize = 1,
		batchRawMaterials = {['iron-plate'] = 5, ['coal'] = 10},
	},
	['assembling-machine-2'] = {
		overallWeight = 1,
		minLambda = 0.2,
		maxLambda = 1.2,
		shape = 'bump',
		enabled = true,
		base_amount = 300,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 160, ['copper-plate'] = 18},
	},
	['pumpjack'] = {
		overallWeight = 1,
		minLambda = 0.35,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 250,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 120, ['copper-plate'] = 15},
	},
	['oil-refinery'] = {
		overallWeight = 1,
		minLambda = 0.35,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 100,
		itemBatchSize = 1,
		batchRawMaterials = {['iron-plate'] = 115, ['copper-plate'] = 15, ['stone-brick'] = 10},
	},
	['chemical-plant'] = {
		overallWeight = 1,
		minLambda = 0.35,
		maxLambda = 1,
		shape = 'density',
		enabled = true,
		base_amount = 150,
		itemBatchSize = 2,
		batchRawMaterials = {['iron-plate'] = 90, ['copper-plate'] = 15},
	},
}

function Public.entry_price()
	local lambda = Math.max(Math.min(Math.sloped(Common.difficulty_scale(),1/2) * Common.game_completion_progress(), 1), 0)

	local item = Raffle.LambdaRaffle(Public.entry_price_data_raw, lambda)

	local batchSize = Public.entry_price_data_raw[item].itemBatchSize

	return {
		name = item,
		count = Math.ceil(
			(0.9 + 0.2 * Math.random()) * Public.entry_price_data_raw[item].base_amount * Balance.quest_structure_entry_price_scale() / batchSize
		) * batchSize,
		batchSize = batchSize,
		batchRawMaterials = Public.entry_price_data_raw[item].batchRawMaterials,
	}
end


return Public