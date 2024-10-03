-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require('maps.pirates.memory')
local Math = require('maps.pirates.math')
local Balance = require('maps.pirates.balance')
local Common = require('maps.pirates.common')
-- local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require('utils.inspect').inspect
--
-- local SurfacesCommon = require 'maps.pirates.surfaces.common'
local Raffle = require 'utils.math.raffle'
local ShopCovered = require 'maps.pirates.shop.covered'
local Classes = require 'maps.pirates.roles.classes'
local Loot = require 'maps.pirates.loot'


local Public = {}
Public.Data = require('maps.pirates.structures.quest_structures.furnace1.data')

function Public.create_step1_entities()
	local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	local quest_structure_data = destination.dynamic_data.quest_structure_data
	if not quest_structure_data then
		return
	end

	local position = quest_structure_data.position
	local hardcoded_data = Public.Data.step1

	quest_structure_data.blue_chests = {}
	for _, chest_position in pairs(hardcoded_data.blue_chests) do
		local e = surface.create_entity({
			name = 'blue-chest',
			position = Math.vector_sum(position, chest_position),
			force = 'environment',
		})
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.operable = false
			e.destructible = false
			quest_structure_data.blue_chests[#quest_structure_data.blue_chests + 1] = e
		end
	end
	quest_structure_data.red_chests = {}
	for _, chest_position in pairs(hardcoded_data.red_chests) do
		local e = surface.create_entity({
			name = 'red-chest',
			position = Math.vector_sum(position, chest_position),
			force = 'environment',
		})
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.operable = false
			e.destructible = false
			quest_structure_data.red_chests[#quest_structure_data.red_chests + 1] = e
		end
	end
	quest_structure_data.door_walls = {}
	for _, p in pairs(hardcoded_data.walls) do
		local e = surface.create_entity({
			name = 'stone-wall',
			position = Math.vector_sum(position, p),
			force = 'environment',
		})
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
	if not quest_structure_data then
		return
	end

	local position = quest_structure_data.position
	local hardcoded_data = Public.Data.step2

	quest_structure_data.market = surface.create_entity({
		name = 'market',
		position = Math.vector_sum(position, hardcoded_data.market),
		force = memory.ancient_friendly_force_name,
	})
	if quest_structure_data.market and quest_structure_data.market.valid then
		quest_structure_data.market.minable = false
		quest_structure_data.market.rotatable = false
		quest_structure_data.market.destructible = false

		quest_structure_data.market.add_market_item({
			price = Balance.weapon_damage_upgrade_price(),
			offer = {
				type = 'nothing',
				effect_description = {
					'pirates.market_description_purchase_attack_upgrade',
					Balance.weapon_damage_upgrade_percentage(),
				},
			},
		})

		-- quest_structure_data.market.add_market_item{price={{'pistol', 1}}, offer={type = 'give-item', item = 'coin', count = Balance.coin_sell_amount}}
		-- quest_structure_data.market.add_market_item{price={{'burner-mining-drill', 1}}, offer={type = 'give-item', item = 'iron-plate', count = 9}}

		local how_many_coin_offers = 5
		if Balance.crew_scale() >= 1 then
			how_many_coin_offers = 6
		end

		-- Thinking of not having these offers available always (if it's bad design decision can always change it back)
		if Math.random(4) == 1 then
			quest_structure_data.market.add_market_item({
				price = { { name = 'pistol', count = 1 } },
				offer = { type = 'give-item', item = 'coin', count = Balance.coin_sell_amount },
			})
			how_many_coin_offers = how_many_coin_offers - 1
		end

		if Math.random(4) == 1 then
			quest_structure_data.market.add_market_item({
				price = { { name = 'burner-mining-drill', count = 1 } },
				offer = { type = 'give-item', item = 'iron-plate', count = 9 },
			})
			how_many_coin_offers = how_many_coin_offers - 1
		end

		local coin_offers = ShopCovered.market_generate_coin_offers(how_many_coin_offers)
		for _, o in pairs(coin_offers) do
			quest_structure_data.market.add_market_item(o)
		end

		if destination.static_params.class_for_sale then
			quest_structure_data.market.add_market_item({
				price = { { name = 'coin', count = Balance.class_cost(false) } },
				offer = {
					type = 'nothing',
					effect_description = {
						'pirates.market_description_purchase_class',
						Classes.display_form(destination.static_params.class_for_sale),
					},
				},
			})

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
		local e = surface.create_entity({
			name = 'wooden-chest',
			position = Math.vector_sum(position, p),
			force = memory.ancient_friendly_force_name,
		})
		if e and e.valid then
			e.minable = false
			e.rotatable = false
			e.destructible = false

			local inv = e.get_inventory(defines.inventory.chest)
			if k == 1 then
				inv.insert({ name = 'coin', count = Loot.quest_structure_coin_loot() })
			elseif k == 4 then
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

Public.entry_price_data_raw = { -- choose things which make interesting minifactories
	['electric-mining-drill'] = {
		overall_weight = 1,
		min_param = -0.1,
		max_param = 0.6,
		shape = 'bump',
		enabled = true,
		base_amount = 600,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 46, ['copper-plate'] = 9 },
	},
	['fast-splitter'] = {
		overall_weight = 1,
		min_param = 0.1,
		max_param = 0.6,
		shape = 'bump',
		enabled = true,
		base_amount = 300,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 92, ['copper-plate'] = 45 },
	},
	['assembling-machine-1'] = {
		overall_weight = 1,
		min_param = -0.2,
		max_param = 0.6,
		shape = 'bump',
		enabled = true,
		base_amount = 600,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 44, ['copper-plate'] = 9 },
	},
	['programmable-speaker'] = {
		overall_weight = 1.67,
		min_param = 0.1,
		max_param = 0.7,
		enabled = true,
		base_amount = 450,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 18, ['copper-plate'] = 17 },
	},
	['pump'] = {
		overall_weight = 1.25,
		min_param = 0.2,
		max_param = 0.9,
		enabled = true,
		base_amount = 250,
		itemBatchSize = 1,
		batchRawMaterials = { ['iron-plate'] = 15 },
	},
	['grenade'] = {
		overall_weight = 1.1,
		min_param = 0.1,
		max_param = 0.7,
		enabled = true,
		base_amount = 500,
		itemBatchSize = 1,
		batchRawMaterials = { ['iron-plate'] = 5, ['coal'] = 10 },
	},
	['assembling-machine-2'] = {
		overall_weight = 1,
		min_param = 0.3,
		max_param = 1.5,
		shape = 'bump',
		enabled = true,
		base_amount = 200,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 160, ['copper-plate'] = 18 },
	},
	['pumpjack'] = {
		overall_weight = 1.7,
		min_param = 0.4,
		max_param = 1.5,
		enabled = true,
		base_amount = 120,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 120, ['copper-plate'] = 15 },
	},
	['oil-refinery'] = {
		overall_weight = 1.7,
		min_param = 0.4,
		max_param = 2,
		enabled = true,
		base_amount = 70,
		itemBatchSize = 1,
		batchRawMaterials = { ['iron-plate'] = 115, ['copper-plate'] = 15, ['stone-brick'] = 10 },
	},
	['chemical-plant'] = {
		overall_weight = 1.7,
		min_param = 0.4,
		max_param = 1.5,
		enabled = true,
		base_amount = 150,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 90, ['copper-plate'] = 15 },
	},
	['solar-panel'] = {
		overall_weight = 1.43,
		min_param = 0.3,
		max_param = 1.2,
		enabled = true,
		base_amount = 150,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 80, ['copper-plate'] = 55 },
	},
	['cluster-grenade'] = {
		overall_weight = 2.5,
		min_param = 0.6,
		max_param = 2,
		enabled = true,
		base_amount = 120,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 120, ['coal'] = 145, ['sulfur'] = 5 },
	},
	['car'] = {
		overall_weight = 1.67,
		min_param = 0.4,
		max_param = 1.5,
		enabled = true,
		base_amount = 90,
		itemBatchSize = 1,
		batchRawMaterials = { ['iron-plate'] = 117 },
	},
	['defender-capsule'] = {
		overall_weight = 1.67,
		min_param = 0.4,
		max_param = 1.5,
		enabled = true,
		base_amount = 150,
		itemBatchSize = 2,
		batchRawMaterials = { ['iron-plate'] = 72, ['copper-plate'] = 39 },
	},
	['express-transport-belt'] = {
		overall_weight = 2.5,
		min_param = 0.6,
		max_param = 1.5,
		enabled = true,
		base_amount = 150,
		itemBatchSize = 10,
		batchRawMaterials = { ['iron-plate'] = 315, ['lubricant-barrel'] = 2 },
	},
}

function Public.entry_price()
	local lambda = Math.clamp(0, 1, Math.sloped(Common.difficulty_scale(), 0.4) * Common.game_completion_progress())

	local item = Raffle.raffle_with_parameter(lambda, Public.entry_price_data_raw)

	if not item then
		item = Common.get_random_dictionary_entry(Public.entry_price_data_raw, true)
	end

	local batchSize = Public.entry_price_data_raw[item].itemBatchSize

	return {
		name = item,
		count = Math.ceil(
			(0.9 + 0.2 * Math.random())
				* Public.entry_price_data_raw[item].base_amount
				* Balance.quest_furnace_entry_price_scale()
				/ batchSize
		) * batchSize,
		batchSize = batchSize,
		batchRawMaterials = Public.entry_price_data_raw[item].batchRawMaterials,
	}
end

return Public
