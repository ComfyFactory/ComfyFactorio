-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
-- local CustomEvents = require 'maps.pirates.custom_events'
local IslandEnum = require 'maps.pirates.surfaces.islands.island_enum'
-- local Raffle = require 'maps.pirates.raffle'
-- local ShopCovered = require 'maps.pirates.shop.covered'
-- local Classes = require 'maps.pirates.roles.classes'
-- local Loot = require 'maps.pirates.loot'

local Public = {}

local enum = {
	MARKET1 = 'market1',
	FURNACE1 = 'furnace1',
}
Public.enum = enum
Public[enum.MARKET1] = require 'maps.pirates.structures.quest_structures.market1.market1'
Public[enum.FURNACE1] = require 'maps.pirates.structures.quest_structures.furnace1.furnace1'



function Public.choose_quest_structure_type()
    local destination = Common.current_destination()
	local subtype = destination.subtype

	local rng = Math.random(3)

	if rng == 1 or subtype and subtype == IslandEnum.enum.WALKWAYS then
		return enum.MARKET1
	else

		return enum.FURNACE1
	end
end



function Public.initialise_cached_quest_structure(position, quest_structure_type)
    local destination = Common.current_destination()
	local surface = game.surfaces[destination.surface_name]

	if quest_structure_type == enum.MARKET1 then

		local structurePath = Public[enum.MARKET1]
		local structureData = structurePath.Data.step1

		local entry_price = structurePath.entry_price()

		local special = Utils.deepcopy(structureData)
		special.position = position

		if not destination.dynamic_data.structures_waiting_to_be_placed then
			destination.dynamic_data.structures_waiting_to_be_placed = {}
		end
		destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}

		local rendering1 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 2.65, y = position.y - 1.3},
			color = CoreData.colors.renderingtext_green,
			scale = 1.5,
			font = 'default-game',
			alignment = 'right',
		}
		local rendering2 = rendering.draw_sprite{
			sprite = 'item/' .. entry_price.name,
			surface = surface,
			target = {x = position.x + 3.5, y = position.y - 0.65},
			x_scale = 1.5,
			y_scale = 1.5
		}
		local rendering3 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 0.5, y = position.y + 1.05},
			color = CoreData.colors.renderingtext_green,
			scale = 1,
			font = 'default-game',
			alignment = 'center',
			text = {'pirates.quest_structure_market_2'},
		}
		local rendering4 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 0.5, y = position.y + 1.7},
			color = CoreData.colors.renderingtext_green,
			scale = 1,
			font = 'default-game',
			alignment = 'center',
			text = {'pirates.quest_structure_market_3'},
		}

		destination.dynamic_data.quest_structure_data = {
			quest_structure_type = quest_structure_type,
			position = position,
			state = 'covered',
			entry_price = entry_price,
			rendering1 = rendering1,
			rendering2 = rendering2,
			rendering3 = rendering3,
			rendering4 = rendering4,
			completion_counter = 0,
		}

	elseif quest_structure_type == enum.FURNACE1 then

		local structurePath = Public[enum.FURNACE1]
		local structureData = structurePath.Data.step1

		local entry_price = structurePath.entry_price()

		local special = Utils.deepcopy(structureData)
		special.position = position

		if not destination.dynamic_data.structures_waiting_to_be_placed then
			destination.dynamic_data.structures_waiting_to_be_placed = {}
		end
		destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}

		local rendering0 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 2.15, y = position.y - 2.35},
			color = CoreData.colors.renderingtext_green,
			scale = 1.5,
			font = 'default-game',
			alignment = 'center',
			text = {'pirates.quest_structure_furnace_1'},
		}
		local rendering1 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 2.3, y = position.y - 1.15},
			color = CoreData.colors.renderingtext_green,
			scale = 1.5,
			font = 'default-game',
			alignment = 'right',
		}
		local rendering2 = rendering.draw_sprite{
			sprite = 'item/' .. entry_price.name,
			surface = surface,
			target = {x = position.x + 3.15, y = position.y - 0.5},
			x_scale = 1.5,
			y_scale = 1.5
		}
		local rendering3 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 2.15, y = position.y + 1.7},
			color = CoreData.colors.renderingtext_green,
			scale = 1,
			font = 'default-game',
			alignment = 'center',
			text = {'pirates.quest_structure_furnace_2'},
		}
		local rendering4 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 2.15, y = position.y + 2.35},
			color = CoreData.colors.renderingtext_green,
			scale = 1,
			font = 'default-game',
			alignment = 'center',
			text = {'pirates.quest_structure_furnace_3'},
		}
		local rendering5 = rendering.draw_text{
			surface = surface,
			target = {x = position.x + 2.15, y = position.y + 3.0},
			color = CoreData.colors.renderingtext_green,
			scale = 1,
			font = 'default-game',
			alignment = 'center',
			text = {'pirates.quest_structure_furnace_4'},
		}

		destination.dynamic_data.quest_structure_data = {
			quest_structure_type = quest_structure_type,
			position = position,
			state = 'covered',
			rendering0 = rendering0,
			rendering1 = rendering1,
			rendering2 = rendering2,
			rendering3 = rendering3,
			rendering4 = rendering4,
			rendering5 = rendering5,
			entry_price = entry_price,
			completion_counter = 0,
		}
	end

	log('quest structure position: ' .. position.x .. ', ' .. position.y)
end




function Public.create_quest_structure_entities(name)

	if name == enum.MARKET1 .. '_step1' then
		local structurePath = Public[enum.MARKET1]
		structurePath.create_step1_entities()

	elseif name == enum.MARKET1 .. '_step2' then
		local structurePath = Public[enum.MARKET1]
		structurePath.create_step2_entities()

	elseif name == enum.FURNACE1 .. '_step1' then
		local structurePath = Public[enum.FURNACE1]
		structurePath.create_step1_entities()

	elseif name == enum.FURNACE1 .. '_step2' then
		local structurePath = Public[enum.FURNACE1]
		structurePath.create_step2_entities()

	end
end





function Public.tick_quest_structure_entry_price_check()
-- function Public.tick_quest_structure_entry_price_check(tickinterval)
	local memory = Memory.get_crew_memory()
	if memory.game_lost then return end
	local destination = Common.current_destination()
	if not (destination and destination.dynamic_data) then return end

	local quest_structure_data = destination.dynamic_data.quest_structure_data
	if not quest_structure_data then return end

	if quest_structure_data.quest_structure_type == enum.MARKET1 then

		local blue_chest = quest_structure_data.blue_chest
		local red_chest = quest_structure_data.red_chest
		if not (blue_chest and blue_chest.valid and red_chest and red_chest.valid) then return end
		local blue_inv = quest_structure_data.blue_chest.get_inventory(defines.inventory.chest)
		local red_inv = quest_structure_data.red_chest.get_inventory(defines.inventory.chest)

		local blue_contents = blue_inv.get_contents()

		local entry_price = quest_structure_data.entry_price

		for k, v in pairs(blue_contents) do
			if quest_structure_data.state == 'covered' and k == entry_price.name then
				quest_structure_data.completion_counter = quest_structure_data.completion_counter + v
			else
				-- @FIX: power armor loses components, items lose health!
				-- @Piratux: ^ bro what?

				red_inv.insert({name = k, count = v});
			end

			blue_inv.remove({name = k, count = v});
		end

		if quest_structure_data.state == 'covered' then
			if quest_structure_data.completion_counter >= entry_price.count then
				quest_structure_data.state = 'uncovered'
				rendering.destroy(quest_structure_data.rendering1)
				rendering.destroy(quest_structure_data.rendering2)
				rendering.destroy(quest_structure_data.rendering3)
				rendering.destroy(quest_structure_data.rendering4)

				local special = Utils.deepcopy(Public[enum.MARKET1].Data.step2)
				special.position = quest_structure_data.position

				destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}
			else
				if quest_structure_data.rendering1 then
					rendering.set_text(quest_structure_data.rendering1, {'pirates.quest_structure_market_1', entry_price.count - quest_structure_data.completion_counter})
				end
			end
		end

	elseif quest_structure_data.quest_structure_type == enum.FURNACE1 then

		local blue_chests = quest_structure_data.blue_chests
		local red_chests = quest_structure_data.red_chests
		if not (blue_chests and blue_chests[1] and blue_chests[1].valid and blue_chests[2] and blue_chests[2].valid and blue_chests[3] and blue_chests[3].valid and red_chests and red_chests[1] and red_chests[1].valid and red_chests[2] and red_chests[2].valid and red_chests[3] and red_chests[3].valid) then return end

		local blue_invs = {}
		blue_invs[1] = quest_structure_data.blue_chests[1].get_inventory(defines.inventory.chest)
		blue_invs[2] = quest_structure_data.blue_chests[2].get_inventory(defines.inventory.chest)
		blue_invs[3] = quest_structure_data.blue_chests[3].get_inventory(defines.inventory.chest)

		local red_invs = {}
		red_invs[1] = quest_structure_data.red_chests[1].get_inventory(defines.inventory.chest)
		red_invs[2] = quest_structure_data.red_chests[2].get_inventory(defines.inventory.chest)
		red_invs[3] = quest_structure_data.red_chests[3].get_inventory(defines.inventory.chest)

		local blue_contents = {}
		blue_contents[1] = blue_invs[1].get_contents()
		blue_contents[2] = blue_invs[2].get_contents()
		blue_contents[3] = blue_invs[3].get_contents()

		local entry_price = quest_structure_data.entry_price --fields {name, count, batchSize, batchRawMaterials}

		if quest_structure_data.state == 'covered' then

			local removed = 0
			local available = {0, 0, 0}

			for i = 1, 3 do
				local contents = blue_contents[i]
				for k, v in pairs(contents) do
					if k == entry_price.name then
						available[i] = available[i] + v
					else
						blue_invs[i].remove({name = k, count = v});
						red_invs[i].insert({name = k, count = v});
					end
				end
			end

			for i = 1, 3 do
				local to_remove_1 = Math.min(available[i] - (available[i] % entry_price.batchSize), entry_price.count - quest_structure_data.completion_counter)
				if to_remove_1 > 0 then
					blue_invs[i].remove({name = entry_price.name, count = to_remove_1});
					available[i] = available[i] - to_remove_1
					removed = removed + to_remove_1
				end

				if (available[i] + (available[i-1] or 0) + (available[i-2] or 0)) >= entry_price.batchSize then --remove one more batch
					local counter = entry_price.batchSize
					if available[i-1] and available[i-1] > 0 then
						blue_invs[i-1].remove({name = entry_price.name, count = available[i-1]});
						available[i-1] = 0
						counter = counter - available[i-1]
					end
					if available[i-2] and available[i-2] > 0 then
						blue_invs[i-2].remove({name = entry_price.name, count = available[i-2]});
						available[i-2] = 0
						counter = counter - available[i-2]
					end
					blue_invs[i].remove({name = entry_price.name, count = counter});

					removed = removed + entry_price.batchSize
				end
			end

			if removed > 0 then
				quest_structure_data.completion_counter = quest_structure_data.completion_counter + removed
				local count = 1
				for k, v in pairs(entry_price.batchRawMaterials) do
					red_invs[count].insert({name = k, count = v * removed / entry_price.batchSize});
					count = count + 1
				end
			end

			if quest_structure_data.completion_counter >= entry_price.count then
				quest_structure_data.state = 'uncovered'
				rendering.destroy(quest_structure_data.rendering0)
				rendering.destroy(quest_structure_data.rendering1)
				rendering.destroy(quest_structure_data.rendering2)
				rendering.destroy(quest_structure_data.rendering3)
				rendering.destroy(quest_structure_data.rendering4)
				rendering.destroy(quest_structure_data.rendering5)

				local special = Utils.deepcopy(Public[enum.FURNACE1].Data.step2)
				special.position = quest_structure_data.position

				destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] = {data = special, tick = game.tick}
			else
				if quest_structure_data.rendering1 then
					rendering.set_text(quest_structure_data.rendering1, entry_price.count - quest_structure_data.completion_counter .. ' x')
				end
			end
		else
			local removed = 0

			for i = 1, 3 do
				local contents = blue_contents[i]
				for k, v in pairs(contents) do
					if k == entry_price.name then
						blue_invs[i].remove({name = k, count = v});
						removed = removed + v
					else
						blue_invs[i].remove({name = k, count = v});
						red_invs[i].insert({name = k, count = v});
					end
				end
			end

			if removed > 0 then
				local count = 1
				for k, v in pairs(entry_price.batchRawMaterials) do
					red_invs[count].insert({name = k, count = v * removed / entry_price.batchSize});
					count = count + 1
				end
			end
		end
	end
end






return Public