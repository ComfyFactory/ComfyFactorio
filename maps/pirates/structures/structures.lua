-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
-- local Common = require 'maps.pirates.common'
local Loot = require 'maps.pirates.loot'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect

--@add stuff from new quest structures to this file?
local Public = {}
local enum = {
	BOATS = 'Boats',
	ISLANDSTRUCTURES = 'IslandStructures',
}
Public.enum = enum
Public[enum.BOATS] = require 'maps.pirates.structures.boats.boats'
Public[enum.ISLANDSTRUCTURES] = require 'maps.pirates.structures.island_structures.island_structures'


function Public.configure_structure_entities(special_name, components)
	local memory = Memory.get_crew_memory()

	for _, c in pairs(components) do
		local type = c.type
		local force_name = c.force_name
		-- local force
		-- if force_name then force = game.forces[force_name] end

		if type == 'static' then
			for _, e in pairs(c.built_entities) do
				if e and e.valid then
					e.destructible = false
					e.minable = false
					e.rotatable = false
				end
			end
		elseif type == 'static_destructible' then
			for _, e in pairs(c.built_entities) do
				if e and e.valid then
					e.minable = false
					e.rotatable = false
				end
			end
			-- elseif type == 'plain' then
			-- 	for _, e in pairs(c.built_entities) do
			-- 		--
			-- 	end
		elseif type == 'static_inoperable' then
			for _, e in pairs(c.built_entities) do
				if e and e.valid then
					e.destructible = false
					e.minable = false
					e.rotatable = false
					e.operable = false
				end
			end
		elseif type == 'entities' or type == 'entities_grid' then
			for _, e in pairs(c.built_entities) do
				if e and e.valid then
					e.minable = false
					-- e.rotatable = false -- don't see why it shouldn't be rotatable
					e.destructible = false
				end
			end
		elseif type == 'entities_randomlyplaced' or type == 'entities_randomlyplaced_border' then
			for _, e in pairs(c.built_entities) do
				if e and e.valid then
					e.minable = false
					e.rotatable = false
				end
			end
			-- elseif type == 'entities_minable' then
			-- 	for _, e in pairs(c.built_entities) do
			-- 		--
			-- 	end
		end


		for _, e in pairs(c.built_entities) do
			if e and e.valid then
				e.update_connections()

				if e.name == 'iron-chest' then
					local inv = e.get_inventory(defines.inventory.chest)
					local loot = Loot.iron_chest_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				elseif e.name == 'stone-furnace' then
					local inv = e.get_inventory(defines.inventory.fuel)
					local loot = Loot.stone_furnace_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				elseif e.name == 'roboport' then
					local inv = e.get_inventory(defines.inventory.roboport_robot)
					local loot = Loot.roboport_bots_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				elseif e.name == 'centrifuge' then
					local inv = e.get_inventory(defines.inventory.assembling_machine_input)
					e.set_recipe('kovarex-enrichment-process')
					inv.insert { name = 'uranium-235', count = 20 }
				elseif e.name == 'gun-turret' and special_name == 'small_radioactive_centrifuge' then
					e.force = memory.force
				elseif e.name == 'fast-splitter' and special_name == 'small_radioactive_centrifuge' then
					e.splitter_output_priority = 'left'
					e.splitter_filter = 'uranium-235'
				elseif e.name == 'storage-tank' and special_name == 'swamp_lonely_storage_tank' then
					e.insert_fluid(Loot.swamp_storage_tank_fluid_loot())
				elseif e.name == 'storage-tank' and special_name == 'small_oilrig_base' then
					e.insert_fluid(Loot.storage_tank_fluid_loot('crude-oil'))
				elseif e.name == 'storage-tank' and special_name == 'small_abandoned_refinery' then
					e.insert_fluid(Loot.storage_tank_fluid_loot('petroleum-gas'))
				elseif e.name == 'storage-tank' and special_name ~= 'small_radioactive_reactor' then
					e.insert_fluid(Loot.storage_tank_fluid_loot())
				elseif e.name == 'lab' and (special_name == 'maze_labs' or special_name == 'small_radioactive_lab') then
					local inv = e.get_inventory(defines.inventory.lab_input)
					local loot = Loot.lab_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				elseif e.name == 'steel-chest' and special_name == 'maze_treasure' then
					local inv = e.get_inventory(defines.inventory.chest)
					local loot = Loot.maze_treasure_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				elseif e.name == 'wooden-chest' and (special_name == 'maze_defended_camp' or special_name == 'maze_undefended_camp') then
					local inv = e.get_inventory(defines.inventory.chest)
					local loot = Loot.maze_camp_loot()
					for i = 1, #loot do
						local l = loot[i]
						inv.insert(l)
					end
				elseif special_name == 'small_cliff_base' then
					-- this is to make friendly gun turrets work
					e.force = memory.force

					if e.name == 'boiler' or e.name == 'burner-mining-drill' then
						local inv = e.get_inventory(defines.inventory.fuel)
						local loot = Loot.stone_furnace_loot()
						for i = 1, #loot do
							local l = loot[i]
							inv.insert(l)
						end
					elseif e.name == 'assembling-machine-2' then
						local inv = e.get_output_inventory()
						local loot = Loot.assembling_machine_loot()
						e.set_recipe(loot.name)
						inv.insert(loot)

						e.operable = false
					elseif e.type == 'resource' then
						e.minable = true
					end
				end

				if force_name and string.sub(force_name, 1, 15) == 'ancient-hostile' then
					if e.name == 'gun-turret' then
						if memory.overworldx < 800 then
							e.insert({ name = "piercing-rounds-magazine", count = 64 })
						else
							e.insert({ name = "uranium-rounds-magazine", count = 64 })
						end
					end
				elseif force_name and string.sub(force_name, 1, 16) == 'ancient-friendly' then
					if e.name == 'oil-refinery' then
						e.set_recipe('advanced-oil-processing')
					end
				end
			end
		end
	end
end

function Public.try_place(structureScope, specialsTable, left_top, areawidth, areaheight, placeability_function_strict, placeability_function_optional)
	local structureData = structureScope.Data

	local attempts = 3
	local succeeded = false

	while attempts > 0 and (not succeeded) do
		attempts = attempts - 1

		local structure_topleft = {
			x = left_top.x + Math.random(areawidth + 1 - structureData.width) - 1,
			y = left_top.y + Math.random(areaheight + 1 - structureData.height) - 1,
		}
		local structure_center = {
			x = structure_topleft.x + structureData.width / 2,
			y = structure_topleft.y + structureData.height / 2,
		}
		local structure_topright = {
			x = structure_topleft.x + structureData.width,
			y = structure_topleft.y,
		}
		local structure_bottomleft = {
			x = structure_topleft.x,
			y = structure_topleft.y + structureData.height,
		}
		local structure_bottomright = {
			x = structure_topleft.x + structureData.width,
			y = structure_topleft.y + structureData.height,
		}

		--game.print('trying: structure_yes: ' .. structureData.name .. ' at ' .. structure_center.x .. ', ' .. structure_center.y)

		local positions_to_check = { structure_topleft, structure_topright, structure_bottomleft, structure_bottomright, structure_center }

		local placable_strict_count = 0
		for _, pos in pairs(positions_to_check) do
			if placeability_function_strict(pos) then
				placable_strict_count = placable_strict_count + 1
			end
		end

		-- check if positions aren't in water
		if placable_strict_count == #positions_to_check then
			local placable_optional_count = 0
			for _, pos in pairs(positions_to_check) do
				if placeability_function_optional(pos) then
					placable_optional_count = placable_optional_count + 1
				end
			end

			-- check if at least single position is not in forest, to lower the chance of structure being completely surrounded by forest
			if placable_optional_count >= 1 then
				specialsTable[#specialsTable + 1] = {
					position = structure_center,
					components = structureData.components,
					width = structureData.width,
					height = structureData.height,
					name = structureData.name,
				}
				succeeded = true


				if _DEBUG then
					--game.print('success: structure_yes: ' .. structureData.name .. ' at ' .. structure_center.x .. ', ' .. structure_center.y)
					log('structure_yes: ' .. structureData.name .. ' at ' .. structure_center.x .. ', ' .. structure_center.y)
				end
			end

			-- else
			-- 	-- if _DEBUG then
			-- 	-- 	log('structure_no: ' .. structureData.name .. ' at ' .. structure_center.x .. ', ' .. structure_center.y)
			-- 	-- end
		end
	end
end

function Public.tryAddStructureByName(specialsTable, name, p)
	local structureScope = Public[enum.ISLANDSTRUCTURES][Public[enum.ISLANDSTRUCTURES].enum.ROC][name] or Public[enum.ISLANDSTRUCTURES][Public[enum.ISLANDSTRUCTURES].enum.MATTISSO][name]

	if not structureScope then
		log('Couldn\'t find structure data for ' .. name)
		return {}
	else
		local structureData = structureScope.Data

		specialsTable[#specialsTable + 1] = {
			position = p,
			components = structureData.components,
			width = structureData.width,
			height = structureData.height,
			name = structureData.name,
		}
	end
end

return Public
