-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require('maps.pirates.memory')
local Math = require('maps.pirates.math')
-- local Balance = require 'maps.pirates.balance'
local Boats = require('maps.pirates.structures.boats.boats')
local Common = require('maps.pirates.common')
local CoreData = require('maps.pirates.coredata')
local Utils = require('maps.pirates.utils_local')
local _inspect = require('utils.inspect').inspect

local Public = {}

Public.StartingBoats = {
	{
		type = Boats.enum.SLOOP,
		position = { x = Boats[Boats.enum.SLOOP].Data.width - 65, y = -1 },
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-001',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 + (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-002',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 - (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-003',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 + 2 * (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-004',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 - 2 * (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-005',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 + 3 * (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-006',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 - 3 * (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-007',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 + 4 * (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-008',
	},
	{
		type = Boats.enum.SLOOP,
		position = {
			x = Boats[Boats.enum.SLOOP].Data.width - 65,
			y = -1 - 4 * (23 + Boats[Boats.enum.SLOOP].Data.height / 2),
		},
		surface_name = CoreData.lobby_surface_name,
		force_name = 'crew-009',
	},
	-- {
	-- 	type = Boats.enum.CUTTER,
	-- 	position = {x = Boats[Boats.enum.CUTTER].Data.width - 56, y = (70.5 + Boats[Boats.enum.CUTTER].Data.height/2)},
	-- 	surface_name = CoreData.lobby_surface_name,
	-- 	force_name = 'environment',
	-- 	speedticker1 = 0,
	-- 	speedticker2 = 1/3 * Common.boat_steps_at_a_time,
	-- 	speedticker3 = 2/3 * Common.boat_steps_at_a_time,
	-- },
}

Public.Data = {}
Public.Data.display_name = { 'pirates.location_displayname_lobby_1' }
Public.Data.width = 224
Public.Data.height = 384
-- Public.Data.noiseparams = {
-- 	land = {
-- 		type = 'simplex_2d',
-- 		normalised = false,
-- 		params = {
-- 			{wavelength = 128, amplitude = 10/100},
-- 			{wavelength = 64, amplitude = 10/100},
-- 			{wavelength = 32, amplitude = 5/100},
-- 			{wavelength = 12, amplitude = 5/100},
-- 		},
-- 	}
-- }

Public.Data.iconized_map_width = 4
Public.Data.iconized_map_height = 20

function Public.terrain(args)
	local x, y = args.p.x, args.p.y

	if Math.distance(args.p, { x = -316, y = 0 }) < 230 then
		args.tiles[#args.tiles + 1] = { name = 'dirt-3', position = args.p }
		if x <= -80 and (y >= 10 or y <= -10) and math.random() < 0.1 then
			local tree_name = 'tree-05'
			if math.random() < 0.2 then
				tree_name = 'tree-07'
			end
			args.entities[#args.entities + 1] = { name = tree_name, position = args.p }
		elseif x <= -80 and y < 3 and y > -5 then
			args.tiles[#args.tiles + 1] = { name = 'stone-path', position = args.p }
		end
	elseif Math.distance(args.p, { x = -264, y = 0 }) < 180 then
		args.tiles[#args.tiles + 1] = { name = 'water-shallow', position = args.p }
	elseif Math.abs(Common.lobby_spawnpoint.x - x) < 3 and Math.abs(Common.lobby_spawnpoint.y - y) < 3 then
		args.tiles[#args.tiles + 1] = { name = CoreData.walkway_tile, position = args.p }
	else
		args.tiles[#args.tiles + 1] = { name = 'water', position = args.p }
		if math.random(1, 300) == 1 then
			args.entities[#args.entities + 1] = { name = 'fish', position = args.p }
		end
	end
end

function Public.chunk_structures()
	return nil
end

function Public.create_starting_dock_surface()
	-- local memory = Memory.get_crew_memory()

	local starting_dock_name = CoreData.lobby_surface_name

	local width = Public.Data.width
	local height = Public.Data.height
	local map_gen_settings = Common.default_map_gen_settings(width, height)

	local surface = game.create_surface(starting_dock_name, map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0
end

function Public.place_starting_dock_showboat(id)
	local global_memory = Memory.get_global_memory()

	Memory.set_working_id(id)

	local boat = Utils.deepcopy(Public.StartingBoats[id])

	global_memory.lobby_boats[id] = boat

	Boats.place_boat(boat, CoreData.static_boat_floor, true, true, false)
	-- Boats.place_boat(boat, CoreData.static_boat_floor, true, true, false, true) --this final argument is to enable the comfy graphic to be placed on the boat, but that argument is disabled for now, so luacheck forbids this line
end

function Public.place_lobby_jetty_and_boats()
	local surface = game.surfaces[CoreData.lobby_surface_name]

	for id, _ in pairs(Public.StartingBoats) do
		Public.place_starting_dock_showboat(id)
	end

	local offset = { x = 38, y = 127 }

	local tiles = {}
	for _, p in pairs(Common.tile_positions_from_blueprint(Public.Data.jetty_bp, offset)) do
		tiles[#tiles + 1] = { name = CoreData.walkway_tile, position = p, force = 'environment' }
	end

	surface.set_tiles(tiles, true)

	-- for y = -3.5, 3.5 do
	-- 	local e = surface.create_entity{name = 'stone-wall', position = {x = -68.5, y = y}, force = 'environment'}
	-- 	e.destructible = false
	-- 	e.minable_flag = false
	-- 	e.rotatable = false
	-- 	e.operable = false
	-- end

	local entities =
		Common.build_from_blueprint(Public.Data.jetty_objects_bp, surface, { x = -61, y = -1 }, 'environment')
	for _, e in pairs(entities) do
		if e and e.valid then
			e.destructible = false
			e.minable_flag = false
			e.rotatable = false
		end
	end
end

Public.Data.jetty_bp =
	[[0eNqd3cvORcmVXed3YbsEnHWLHaFXMdyQJcImILMEVckXCHp3l+3KdMeA/a0WARKRDY44+HPOvWKN//qX/+E//pe//qf//Le///Nf/u1//cvf/v0//v2f/vJv/7v/+pd/+tv/+Pd/9x//z//u7//uf/7rX/7tX/7Xf/zH//DXv/+bf/8//fWf/vkv/+0f/vK3v/+Hv/5vf/m38d/++3/4yz//7T/+9f8+9p/+8Z/+9s9/+8e//58H/+V//Tff9w9/+d//5T8j77+c+dd/1D/98z/+/a//5j/9u3/+n/7lH/T/cuYszsziTC/O1OJMLs7E4szPz5y3OHMXZxb34CzuwVncg7O4B2dxD87iHpzFPTiLezCLezCLezCLezCLezCLezCLezCLezCLezCLezCLe9CLe9CLe9CLe9CLe9CLe9CLe9CLe9CLe9CLe9CLe1CLe1CLe1CLe1CLe1CLe1CLe1CLe1CLe1CLe1CLe5CLe5CLe5CLe5CLe5CLe5CLe5CLe5CLe5CLe5CLexCLexCLexCLexCLexCLexCLexCLexCLexCLexCLe/D/5Llvkee+RZ77FnnuW+S5b5HnvkWe+xZ57lvkuW+R575FnvsWee5b5Llvkee+RZ77FnnuW+S5b5HnvkWe+xZ57lvkuW+R575FnvsWee5b5Llvkee+RZ77FnnuW+S5b5HnvkWe+xZ57lvkuW+R575FnvsWee5b5Llvkee+RZ77FnnuW+S5b5HnvkWe+xZ57lvkuW+R575FnvsWee5b5Llvkee+RZ77FnnuW+S5b5HnvkWe+xZ57lvkuW+R575FnvsWee5b5Llvkee+RZ77FnnuW+S5b5HnvkWe+xZ57lvkubPIc2eR584iz51FnjuLPHcWee4s8txZ5LmzyHNnkefOIs+dRZ47izx3FnnuLPLcWeS5s8hzZ5HnziLPnUWeO4s8dxZ57izy3FnkubPIc2eR584iz51FnjuLPHcWee4s8txZ5LmzyHNnkefOIs+dRZ47izx3FnnuLPLcWeS5s8hzZ5HnziLPnUWeO4s8dxZ57izy3FnkubPIc2eR584iz51FnjuLPHcWee4s8txZ5LmzyHNnkefOIs+dRZ47izx3FnnuLPLcWeS5s8hzZ5HnziLPnUWem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0Wem0We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60We60Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Weq0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wey0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0Wei0W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f6wWf2wWfywWfuwWfqwWfmwWfiwWfewWfawWfWwWfSwWfOwWfKwWfGwWfCwWf+wSf6wSf2wSfywSfuwSfqwSfvwJ8/gjw+RvA508An78AfP4A8Pn7v+fP/56//nv++O/527/n+sDn9sDn8sDn7sDn6sDn5sDn4sDn3sDn2sDn1sDn0sDnzsDnysDnxsDnwsDnvsDnusDntsDnssDnrsDnqsDnpsDnosDnnsDnmsDnlsDnksDnjsDnisDnhsDngsDnfsDnesDndsDncsDnbsDnasDnZsDnYsDnXsDnWsDnVsDnUsDnTsDnSsDnRsDnQsDnPsDnOsDnNsDnMsDnLsDnKsDnJsDnIsDnHsDnGsDnWzWub9W4vlXj+laN61s1rm/VuL5V4/pWjetbNa5v1bi+VUOOOP3j9I/TP07/OP3j9I/TH6c/Tn+c/jj9cfrj9Mfpj9Mfpz9Ov51+O/12+u302+m302+n306/nX47/XL65fTL6ZfTL6dfTr+cfjn9cvrl9NPpp9NPp59OP51+Ov10+un00+mn0w+nH04/nH44/XD64fTD6YfTD6cfTv/PLOYL664vrLu+sO76wrrrC+uuL6y7vrDu+sK66wvrri+skyNO/zj94/SP0z9O/zj94/TH6Y/TH6c/Tn+c/jj9cfrj9Mfpj9Nvp99Ov51+O/12+u302+m302+n306/nH45/XL65fTL6ZfTL6dfTr+cfjn9dPrp9NPpp9NPp59OP51+Ov10+un0w+mH0w+nH04/nH44/XD64fTD6YfT/zOL+S7o67ugr++Cvr4L+vou6Ou7oK/vgr6+C/r6Lujru6DliNM/Tv84/eP0j9M/Tv84/XH64/TH6Y/TH6c/Tn+c/jj9cfrj9Nvpt9Nvp99Ov51+O/12+u302+m30y+nX06/nH45/XL65fTL6ZfTL6dfTj+dfjr9dPrp9NPpp9NPp59OP51+Ov1w+uH0w+mH0w+nH04/nH44/XD64fT/zGKuWbmuWbmuWbmuWbmuWbmuWbmuWbmuWbmuWbmuWZEjTv84/eP0j9M/Tv84/eP0x+mP0x+nP05/nP44/XH64/TH6Y/Tb6ffTr+dfjv9dvrt9Nvpt9Nvp99Ov5x+Of1y+uX0y+mX0y+nX06/nH45/XT66fTT6afTT6efTj+dfjr9dPrp9MPph9MPpx9OP5x+OP1w+uH0w+mH0/8zi7nB8LrB8LrB8LrB8LrB8LrB8LrB8LrB8LrB8LrBUI44/eP0j9M/Tv84/eP0j9Mfpz9Of5z+OP1x+uP0x+mP0x+nP06/nX47/Xb67fTb6bfTb6ffTr+dfjv9cvrl9Mvpl9Mvp19Ov5x+Of1y+uX00+mn00+nn04/nX46/XT66fTT6afTD6cfTj+cfjj9cPrh9MPph9MPpx9O/88s5nLw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw63Lw6wbD6wbD6wbD6wbD6wbD6wbD6wbD6wbD6wbD6wbD6wbD65qV65qV65qV65qV65qV65qV65qV65qV65qV65qV65qV67ugr++Cvr4L+vou6Ou7oK/vgr6+C/r6Lujru6Cv74K+vgv6+sK6zxfWfb6w7vOFdZ8vrPt8Yd3nC+s+X1j3+cK6zxfWfb6w7vOtGp9v1fh8q8bnWzU+36rx+VaNz7dqfL5V4/OtGp9v1fh8q8bnT/8+f/r3+dO/z5/+ff707/Onf58//fv86d/nT/8+f/r3+dO/z+eTP59P/nw++fP55M/nkz+fT/58Pvnz+eTP55M/n0/+fD758yGKz4coPh+i+HyI4vMhis+HKD4fovh8iOLzIYrPhyg+H6L4vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOn9vOk93vQeb3qPN73Hm97jTe/xpvd403u86T3e9B5veo83vceb3uNN7/Gm93jTe7zpPd70Hm96jze9x5ve403v8ab3eNN7vOk93vQeb3qPN73Hm97jTe/xpvd403u86T3e9B5veo83vceb3uNN7/Gm93jTe7zpPd70Hm96jze9x5ve403v8ab3eNN7vOk93vQeb3qPN73Hm97jTe/xpvd403u86T3e9B5veo83vceb3uNN7/Gm93jTe7zpPd70Hm96jze9x5ve403v8ab3eNN7vOk93vQeb3qPN73Hm97jTe/xpvd403u86T3e9B5veo83vceb3uNN7/Gm93jTe7zpPd70Hm96jze9x5ve403v8ab3eNN7vOk93vQeb3qPN73Hm97jTe/xpvd403u86T3e9B5veo83vceb3uNN7/Gmd7zpHW96x5ve8aZ3vOkdb3rHm97xpne86R1veseb3vGmd7zpHW96x5ve8aZ3vOkdb3rHm97xpne86R035Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljQ9RjA9RjA9RjA9RjA9RjA9RjA9RjA9RjA9RjA9RjA9RjJvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LG55PH55PH55PH55PH55PH55PH55PH55PH55PH55PH55PHTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeNP/8af/o0//Rt/+jf+9G/86d/407/xp3/jT//Gn/6NP/0bN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y2b8sZNeeOmvHFT3rgpb9yUN27KGzfljZvyxk1546a8cVPeuClv3JQ3bsobN+WNm/LGTXnjprxxU964KW/clDduyhs35Y1v1RjfqjG+VWN8q8b4Vo3xrRrjWzXGt2qMb9UY36oxvlVDjjj94/SP0z9O/zj94/SP0x+nP05/nP44/XH64/TH6Y/TH6c/Tr+dfjv9dvrt9Nvpt9Nvp99Ov51+O/1y+uX0y+mX0y+nX06/nH45/XL65fTT6afTT6efTj+dfjr9dPrp9NPpp9MPpx9OP5x+OP1w+uH0w+mH0w+nH07/zyzmC+vGF9aNL6wbX1g3vrBufGHd+MK68YV14wvrxhfWyRGnf5z+cfrH6R+nf5z+cfrj9Mfpj9Mfpz9Of5z+OP1x+uP0x+m302+n306/nX47/Xb67fTb6bfTb6dfTr+cfjn9cvrl9Mvpl9Mvp19Ov5x+Ov10+un00+mn00+nn04/nX46/XT64fTD6YfTD6cfTj+cfjj9cPrh9MPp/5nFfBf0+C7o8V3Q47ugx3dBj++CHt8FPb4LenwX9PguaDni9I/TP07/OP3j9I/TP05/nP44/XH64/TH6Y/TH6c/Tn+c/jj9dvrt9Nvpt9Nvp99Ov51+O/12+u30y+mX0y+nX06/nH45/XL65fTL6ZfTT6efTj+dfjr9dPrp9NPpp9NPp59OP5x+OP1w+uH0w+mH0w+nH04/nH44/T+zmGtWxjUr45qVcc3KuGZlXLMyrlkZ16yMa1bGNStyxOkfp3+c/nH6x+kfp3+c/jj9cfrj9Mfpj9Mfpz9Of5z+OP1x+u302+m302+n306/nX47/Xb67fTb6ZfTL6dfTr+cfjn9cvrl9Mvpl9Mvp59OP51+Ov10+un00+mn00+nn04/nX44/XD64fTD6YfTD6cfTj+cfjj9cPp/ZjE3GI4bDMcNhuMGw3GD4bjBcNxgOG4wHDcYjhsM5YjTP07/OP3j9I/TP07/OP1x+uP0x+mP0x+nP05/nP44/XH64/Tb6bfTb6ffTr+dfjv9dvrt9Nvpt9Mvp19Ov5x+Of1y+uX0y+mX0y+nX04/nX46/XT66fTT6afTT6efTj+dfjr9cPrh9MPph9MPpx9OP5x+OP1w+uH0/8hi7XLwdjl4uxy8XQ7eLgdvl4O3y8Hb5eDtcvB2OXi7HLxdDt4uB2+Xg7fLwdvl4O1y8HY5eLscvF0O3i4HbzcYthsM2w2G7QbDdoNhu8Gw3WDYbjBsNxi2GwzbDYbtmpV2zUq7ZqVds9KuWWnXrLRrVto1K+2alXbNSrtmpX0XdPsu6PZd0O27oNt3Qbfvgm7fBd2+C7p9F3T7Luj2XdDtC+vaF9a1L6xrX1jXvrCufWFd+8K69oV17Qvr2hfWtS+sa9+q0b5Vo32rRvtWjfatGu1bNdq3arRv1WjfqtG+VaN9q0b707/2p3/tT//an/61P/1rf/rX/vSv/elf+9O/9qd/7U//2ueT2+eT2+eT2+eT2+eT2+eT2+eT2+eT2+eT2+eT2+eT24co2oco2oco2oco2oco2oco2oco2oco2oco2oco2oco2pve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOktb3rLm97ypre86S1vesub3vKmt7zpLW96y5ve8qa3vOlNb3rTm970pje96U1vetOb3vSmN73pTW9605ve9KY3velNb3rTm970pje96U1vetOb3vSmN73pTW9605ve9KY3velNb3rTm970pje96U1vetOb3vSmN73pTW9605ve9KY3velNb3rTm970pje96U1vetOb3vSmN73pTW9605ve9KY3velNb3rTm970pje96U1vetOb3vSmN73pTW9605ve9KY3velNb3rTm970pje96U1vetOb3vSmN73pTW9605ve9KY3velNb3rTm970pje96U035aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpQ9RpA9RpA9RpA9RpA9RpA9RpA9RpA9RpA9RpA9RpA9RpJvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LS55PT55PT55PT55PT55PT55PT55PT55PT55PT55PT55PTTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeelP/9Kf/qU//Ut/+pf+9C/96V/607/0p3/pT//Sn/6lP/1LN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aWb8tJNeemmvHRTXropL92Ul27KSzflpZvy0k156aa8dFNeuikv3ZSXbspLN+Wlm/LSTXnpprx0U166KS/dlJduyks35aVv1QjfqhG+VSN8q0b4Vo3wrRrhWzXCt2qEb9UI36oRvlVDjjj94/SP0z9O/zj94/SP0x+nP05/nP44/XH64/TH6Y/TH6c/Tr+dfjv9dvrt9Nvpt9Nvp99Ov51+O/1y+uX0y+mX0y+nX06/nH45/XL65fTT6afTT6efTj+dfjr9dPrp9NPpp9MPpx9OP5x+OP1w+uH0w+mH0w+nH07/zyzmC+vCF9aFL6wLX1gXvrAufGFd+MK68IV14QvrwhfWyRGnf5z+cfrH6R+nf5z+cfrj9Mfpj9Mfpz9Of5z+OP1x+uP0x+m302+n306/nX47/Xb67fTb6bfTb6dfTr+cfjn9cvrl9Mvpl9Mvp19Ov5x+Ov10+un00+mn00+nn04/nX46/XT64fTD6YfTD6cfTj+cfjj9cPrh9MPp/5nFfBd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v3A6/cDv8wu3wC7fDL9wOv3A7/MLt8Au3wy/cDr9wO/zC7fD87uH53cPzu4fndw/P7x6e3z08v3t4fvfw/O7h+d3D87uHpxMOTyccnk44PJ1weDrh8HTC4emEw9MJh6cTDk8nHJ5OONy9Hu5eD3evh7vXw93r4e71cPd6uHs93L0e7l4Pd6+Hu9fD3evh7vVw93q4ez3cvR7uXg93r4e718Pd6+Hu9XD3erh7Pdy9Hu5eD3evh7vXw93r4e71cPd6uHs93L0e7l4Pd6+Hu9fD3evh7vVw93q4ez3cvR7uXg93r4e718Pd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd68fd6+Xu9XL3erl7vdy9Xu5eL3evl7vXy93r5e71cvd6uXu93L1e7l4vd6+Xu9fL3evl7vVy93q5e73cvV7uXi93r5e718vd6+Xu9XL3erl7vdy9Xu5eL3evl7vXy93rZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZZffZ5emEy9MJl6cTLk8nXJ5OuDydcHk64fJ0wuXphMvTCZenEy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy67zy7P716e3708v3t5fvfy/O7l+d3L87uX53cvz+9ent+9PL972X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X122X12+YXb5Rdul1+4XX7hdvmF2+UXbpdfuF1+4Xb5hdvlF26XX7hddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9ddp9d3gFxeQfE5R0Ql3dAXN4BcXkHxOUdEJd3QFzeAXF5B8TlHRBygpkfZn6Y+WHmh5kfZn6Y+TDzYebDzIeZDzMfZj7MfJj5MPNh5s3Mm5k3M29m3sy8mXkz82bmzcybmRczL2ZezLyYeTHzYubFzIuZFzMvZp7MPJl5MvNk5snMk5knM09mnsw8mXkw82DmwcyDmQczD2YezDyYeTDzYOZ/5CjeknZ5S9rlLWmXt6Rd3pJ2eUva5S1pl7ekXd6SdnlLmpxg5oeZH2Z+mPlh5oeZH2Y+zHyY+TDzYebDzIeZDzMfZj7MfJh5M/Nm5s3Mm5k3M29m3sy8mXkz82bmxcyLmRczL2ZezLyYeTHzYubFzIuZJzNPZp7MPJl5MvNk5snMk5knM09mHsw8mHkw82DmwcyDmQczD2Ye/u/t//r/Lm8FvrwV+PJW4MtbgS9vBb68FfjyVuDLW4EvbwW+vBVYTjDzw8w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]]

Public.Data.jetty_objects_bp =
	[[0eNqlnPlu2zgQh99FfzML8SbzKkUQKKm2NeoLttNuUeTdVzx8LNY/UzNCgAxpSx9J8ZjhDOU/3dv6Y9wfVttT9/ynW73vtsfu+cuf7rj6th3W6bPtsBm75+7Xbvd13D69fx+Pp+5TdKvt1/Gf7ll+vohu3J5Wp9VY7syZ36/bj83beJguEHcJotvvjtNNu20qYwI9efeXFd3vKSXVlPz8FP9jKQ7L3mfpC2szfl19bJ7G9fh+Oqzen/a79XiPqa5Mc59pOPXT91mWWj9nmkx3YR43w3r9tB42+3sk3SR5au2sbTIDlWnaTzHOa7Fp10721Opp34ZKKlSFNlTNa7SaUT/yLJGxDTVkaN+G2nmNnlE9x5jFqdl3YZ4DA0uWDLNhtg2LCxZABFX9vF7wso3iKA4J+lQpxpPrA4BpRs16D2AcndEj/WgX9CmEOs6zQx3BmQ+9BLDAb25E/RGpIxiRdE9vauwBizEZInhqWvGfWgBTQmu+tQKZhmqtQJLlWyuQ6fjWCmR6qrUCSYFvrEBm5NsqiGl6qqkCSZJvqUCm4hsqkKmJdgoEmQXTGCxZZoH+8KiejrqgQhJDd3jUUoYp5YCNZxZYUohpGcrDAUvKMpSHA8rDLlAeDig3y7CnLGoreVa4KxPs6u3MrYWzTRJja2EVYDFmg0W+BrK6sKHJnLv1bpIceedtYpNJVhembzJn7rt1m0Q2p7RsMskzQ6kmc+bMkG0S2ZySuslkzBADdI+7zpDVYTdHWxiwsrsF2gLVzt+YUR9vx9OQb79DMue63aVIqqaG9WE4ag1Y5zxDOxjktTQze/FKAnrQL7CUNBgZnqEdNLBvvKe2VAOd5QOjVkA7+0i3ulC9AsNC0mCMBYaFpJEXm+FqgqwFQQoNrK3AcDgp9Nwsg4XaynAzwXp5BgvVa/74V03WgrVfgZUokl2ukCQXhJyAJoiKHHJCJL0g5ISYZkHICTEtOeSESG5BxAkx/YKAE2IGcrwJkeKCcFNAcbt+QbgJQiU13ARJnNCEQrBFUW0E5YQoJIIxVAZ8dNcJsj/svh2GzWZ4W49Px/04/JiuuMO8DMFkVUzfD9NN42k8HNMV+/Xw+214//H6c7f+SNipky+fbabKTgWtd+/DeiJPfb779To91N/777vtRPx7WB/Hz/TFeDi9/hd8/D5dm7+o14ny0W77uhn23fPp8DGe79yMx+PwLRXV3W80eQbf7P/Rg5w5g68jEJLoM1ieFRMaf/TIu7zMYMiku4v7Zj1n6rqoWiDyLI66hSRrumBaSMseiPA0hCOOQwiib/1RAF/S9z9ovboJuc9zIqA6KfreR/aIJcn6B7P43mGoMBjRdnjkgRFslwax6IpMesSi7/ylQ6yZQcSL7Y5JZK/wxQOOmWT9YJst1jN3QKZNonuFfZNJnhM6NJkzg4iqTaJ7hWOTSVYMqm8yZ2oG2SZ5ujXRZNJ1hEJrqOb7CNDGXhqqjwCTJLt2yCElDd1bjBx50tC1BXKhSmPImhGz+P5i5C6W5Mg6JtHNJQNHCH0uGDgy6P5iyGJE1A2a74yIOgqVyAURdczURO+/Rb1p6XPAwh7gH2nH9aMeacck/pF2zOQfacdM6pF2SHL8E+2YyT/QjpnU8+yYxD/Ojpn80+yYSTzMjkGOuhAgxeo8ce+KSXQFgU77SEdXEJB1E0R/263W9/2HF4q5z+CbRxaZDl4R1Twm0Y0jC99roG+lHVKnC4LpmOnYTA9HiCf2BCbR5wA6FSkJQfWLgwq+YNKzn1pAjpLADysG1LuBGlbEJH5YETP5YUXMpIYVMYkfVsRMflgRM6lhRUzihxUhM/KjiphJDCpiEH1HHdBCH+lKAx1Zl5G+m8AsS2fBNtL9r+hNHRnpZ08wi/+CU0ShkUh9wQmRVE/fUUf0Sl0vGRENhWALwhAYyohDwFfqGCF1iSIkqqfPBIlCOKp3C0I4sIZUw+kBKjAaC/s0MmBoOkhGUA6dClGSv5GQyLWspGJbYhJ5hJXURFPsAcqwbbEHUMs2xh5AHdEae4DybHPsATSw7bEH0Eg0yDBK9WyL7AFUsk2yB1BFs8kekBgKRMH32RkKBJ2WVZxQNvpZFcWJZaPfU1GKbkzVmr2I7tfqkH+S5osWNv29iJyahnFKpo98Tk3/RcipkL7uczIJMa3COS1TWpd0RpiSnkhCFXISQhVMEkKrUuIkhCnX63Svttf0+fN0r3Yl7VK6cHTmlOomIUypTxLCFH5CCFOYSQhTrk9C2HJNEsKWspIQNlzTrj6OVJYrbU9CuFJWEsKVtichXOG4fG+pc0II39+kS32SEKHcm4QIpawkRJTXdDq3mDLpMxFrOt0QS2FJiFgKS0LE0nNJiFigsYDOvZe7qfc153Nn2prLV577uXb0uadzV5/7unT2ubeTvFKSFOnES84lKWTt/yxFOutwk9PnXC5d1/J0GVqVkgdLismXXC6vjpcsRYpel1ym1PGQpZB1FGQpZO37LEWKvdzkfL3Plisr0+anVMdGlkLWEZGlkHVMZClkHRVZClnHRWYLWUdAliI540ou9V1yMuVcyMwgb3Oxlh4ypY6dLEVyq5Rcfi6hMkNh1jaE3IY6zmQZXLGWl9gibQ7yHE1SJHO35BJF1VGQpUjmUsnlK+soyFKoOgqyFEmHl5zPuboKyFyeKqVnKZKOsi/T2rQ6jZvkaL78+Jbofo6HY17QrFPRxGi1kz4q9fn5LxlvqY8=]]

return Public
