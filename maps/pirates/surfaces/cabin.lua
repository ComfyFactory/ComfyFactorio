
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local Utils = require 'maps.pirates.utils_local'
local inspect = require 'utils.inspect'.inspect
local SurfacesCommon = require 'maps.pirates.surfaces.common'

local Public = {}
local enum = {
	DEFAULT = 'Default',
}
Public.enum = enum

Public.Data = {}

Public.Data.width = 16
Public.Data.height = 24

Public.Data.cabin_whitebelts_lrtp_order = {
	{x = -5.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -4.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -3.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -5.5, y = 10.5, direction = defines.direction.south, type = 'output'},
	{x = -4.5, y = 10.5, direction = defines.direction.south, type = 'output'},
	{x = -3.5, y = 10.5, direction = defines.direction.south, type = 'output'},
}

Public.Data.car_pos = {x = 7, y = 0}

Public.Data.static_entities_bp = [[0eNqlmt1u4jAQhd/F16HKOP4Lr1JVK1qsbiSaoCTstqp49yWwW9EtJ/FxLyPIx9g+4zP28K4ed4e475t2VOt3NbSb/WrsVs99s52eX9VaXKHe1FqbY6Gap64d1Pr+9MXmud3spq+Mb/uo1qoZ44sqVLt5mZ5+d902tqunn3EY1fRiu40T61gsvhpf930chtXYb9ph3/Xj6jHuriH6+FCo2I7N2MRLMOeHtx/t4eUx9qdfuR1GofbdcHqpa/+N7M6eh1be2eMU2H8YnYgp5zFVIqaax5hEjJ7H2ESMnce4RIyZx/hEjJ/HhESMm8fUiZh6HiNlIicscJJ1vCBkSVWyLEhZUrUsC2KWVDXLgpwlVc+yoERxZLYL4HiSowEnLG2IMNcQsWanCoB0yYLAXGkh56oCHHanNoBT0XOuF4gmm4jGamlitRCj+0LcdZvt6aMb+8MHqFDbpo9Plw9PhL9W3h3G/WEy668/41nVoHgDC0JTWZOyscDgS5LjAEeyxYKIOpuIxlplyw8R+RSxV6P+pEN9i2+zN1IUscuOGBF9cgp6MPKPDGxakIAV7yj+KuzPCX+LX9N8x/BNye5TNmefMsJuLyD5jGZBQB2mIvcXDziG5ATAsdm7CiLmZ1RI2QMMm18hI78M7UtoNuhCDSy4ZY2pBhy2ThN0+Mz3I4issqVzRi5qxxpSOzewy+KxyecYuzQhjq7OEYmu2JB+AqsfcGCwbMUm4AjjynwhIqTkC1GnCNFpVog6Q4iONRsB1bVj3UZAve/y7QYi8/1GTNJasYZzA5uwVoHeNNBi0ZaDptbzlwMgJk+7DqifPHs9IKCi8/n3AxCZf/qRpOOPt6wSc84WnjcdNCG06cBlp10HlFGedh1Q2IVvuA5CfsN1kkrnQLtOTu0cKnrV0YQYmgSWPVh22UH5E9irZY3aHD5bPxBJH1ogibcQMF81e2zRoFysWQfRoLardf5lPIqNVjwMjlY8jMmSjVMNrLumFY9AnmyeQlAg26cQVJMNVASSsiR7qJgkZBsVkzTZScWkimymYpIh26mYZNmGKkY5tqWKUZ5tqmJUYNuqGMV3C8+oh+Lyd4711f9KCvUr9sOlFghifK29FSuVK4/HPzs+Pbo=]]

Public.Data.operable_entities_bp = [[0eNqV1NtqxCAQBuB3mWtTVnP2VUopyWbYCskY1G0bFt+9MUthKW4a7xzw/xyN5gb9eMXZKHIgb2CpmzOns4tRQ6i/QfKKwQJSFJ6BOmuyIF/XiepC3RimuGVGkKAcTsCAuilUX1oPSNn5A62DEKQBg+XZv1FnOrKzNi7rcXwMC//GAMkpp/DexFYs73SdejSrHl+ewaztGtL0u6PTS7ntKQx8aOkPJFKhNu7kRx2+7xRHHbHvlEedfN+pkg+ax6E6GRJxqEmGijjUJkN5HOKn1I/2rCXOU6/RU0mkXoC7tL677Y3Kh58Fg080douIhhd1K+pC5HlTVt7/AARAZgM=]]

Public.Data.cabin_splitters = {
	{x = -5, y = 9.5, direction = defines.direction.north, type = 0},
	{x = -4, y = 8.5, direction = defines.direction.north, type = 0},
	{x = -3, y = 7.5, direction = defines.direction.north, type = 0},
	{x = -5, y = 7.5, direction = defines.direction.north, type = 1},
	{x = -4, y = 6.5, direction = defines.direction.north, type = 1},
	{x = -3, y = 5.5, direction = defines.direction.north, type = 1},
	{x = -5, y = 5.5, direction = defines.direction.north, type = 2},
	{x = -4, y = 4.5, direction = defines.direction.north, type = 2},
	{x = -3, y = 3.5, direction = defines.direction.north, type = 2},
	{x = -5, y = 3.5, direction = defines.direction.north, type = 3},
	{x = -4, y = 2.5, direction = defines.direction.north, type = 3},
	{x = -3, y = 1.5, direction = defines.direction.north, type = 3},
	{x = -5, y = 1.5, direction = defines.direction.north, type = 4},
	{x = -4, y = 0.5, direction = defines.direction.north, type = 4},
	{x = -3, y = -0.5, direction = defines.direction.north, type = 4},
	{x = -5, y = -0.5, direction = defines.direction.north, type = 5},
	{x = -4, y = -1.5, direction = defines.direction.north, type = 5},
	{x = -3, y = -2.5, direction = defines.direction.north, type = 5},
	{x = -5, y = -2.5, direction = defines.direction.north, type = 6},
	{x = -4, y = -3.5, direction = defines.direction.north, type = 6},
	{x = -3, y = -4.5, direction = defines.direction.north, type = 6},
	{x = -5, y = -4.5, direction = defines.direction.north, type = 7},
	{x = -4, y = -5.5, direction = defines.direction.north, type = 7},
	{x = -4, y = -8.5, direction = defines.direction.north, type = 7},
	{x = -5, y = -9.5, direction = defines.direction.north, type = 7},
	{x = -3, y = -7.5, direction = defines.direction.north, type = 8},
	{x = 0.5, y = -7, direction = defines.direction.west, type = 8},
}

Public.Data.output_chest = {x = 3.5, y = -6.5}
Public.Data.backup_output_chest = {x = 3.5, y = -7.5}

Public.Data.input_chests = {
	{x = 0.5, y = 6.5},
	{x = 0.5, y = 4.5},
	{x = 0.5, y = 2.5},
	{x = 0.5, y = 0.5},
	{x = 0.5, y = -1.5},
	{x = 0.5, y = -3.5},
	{x = 0.5, y = -5.5},
}

Public.Data.surfacename_rendering_pos = {x = -0.5, y = -15}

function Public.get_cabin_surface_name()
	local memory = Memory.get_crew_memory()
	return SurfacesCommon.encode_surface_name(memory.id, 1, SurfacesCommon.enum.CABIN, enum.DEFAULT)
end

function Public.get_cabin_surface()
	local name = Public.get_cabin_surface_name()
	if name and game.surfaces[name] and game.surfaces[name].valid then return game.surfaces[Public.get_cabin_surface_name()] end
end

function Public.create_cabin_surface()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if not Public.get_cabin_surface() then

		local width = Public.Data.width
		local height = Public.Data.height
		local map_gen_settings = Common.default_map_gen_settings(width, height)

		map_gen_settings.autoplace_settings.decorative.treat_missing_as_default = false

		local cabinname = Public.get_cabin_surface_name()

		local surface = game.create_surface(cabinname, map_gen_settings)
		surface.freeze_daytime = true
		surface.daytime = 0
		surface.show_clouds = false

        -- more here

		Common.ensure_chunks_at(surface, {x = 0, y = 0}, 3)

		boat.cabin_whitebelts = {}
		for _, b in ipairs(Public.Data.cabin_whitebelts_lrtp_order) do
			local p = {x = b.x, y = b.y}
			local e = surface.create_entity({name = 'linked-belt', position = p, force = boat.force_name, create_build_effect_smoke = false, direction = b.direction})
			if e and e.valid then
				e.destructible = false
				e.minable = false
				e.rotatable = false
				e.operable = false
				e.linked_belt_type = b.type
				boat.cabin_whitebelts[#boat.cabin_whitebelts + 1] = e
			end
		end

		boat.cabin_splitters = {}
		for i, splitter in ipairs(Public.Data.cabin_splitters) do
			local name = 'express-splitter'
			local p = {x = splitter.x, y = splitter.y}
			local priority, filter
			if splitter.type == 0 then
				priority = 'right'
				filter = 'coal'
			elseif splitter.type <= 6 then
				priority = 'right'
				filter = game.item_prototypes[CoreData.cost_items[splitter.type].name]
			elseif splitter.type == 7 then
				priority = 'left'
			elseif splitter.type == 8 then
				priority = 'right'
				filter = 'landfill'
			end
			local e = surface.create_entity({name = name, position = p, force = boat.force_name, create_build_effect_smoke = false, direction = splitter.direction})
			if e and e.valid then
				e.destructible = false
				e.minable = false
				e.rotatable = false
				e.operable = false
				if filter then e.splitter_filter = filter end
				if priority then e.splitter_output_priority = priority end
				boat.cabin_splitters[#boat.cabin_splitters + 1] = e
			end
		end

		boat.input_chests = {}
		for i, b in ipairs(Public.Data.input_chests) do
			local p = {x = b.x, y = b.y}
			local e = surface.create_entity({name = 'blue-chest', position = p, force = boat.force_name, create_build_effect_smoke = false})
			if e and e.valid then
				e.destructible = false
				e.minable = false
				e.rotatable = false
				e.operable = false
				boat.input_chests[#boat.input_chests + 1] = e
			end
		end

		local p = {x = Public.Data.output_chest.x, y = Public.Data.output_chest.y}
		local e = surface.create_entity({name = 'red-chest', position = p, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			e.operable = false
			boat.output_chest = e
		end

		p = {x = Public.Data.backup_output_chest.x, y = Public.Data.backup_output_chest.y}
		e = surface.create_entity({name = 'red-chest', position = p, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			e.operable = false
			boat.backup_output_chest = e
		end

		local es = Common.build_from_blueprint(Public.Data.static_entities_bp, surface, {x=0, y=0}, boat.force_name)
		for _, e2 in pairs(es) do
			if e2 and e2.valid then
				e2.destructible = false
				e2.minable = false
				e2.rotatable = false
				e2.operable = false
			end
		end
		local es2 = Common.build_from_blueprint(Public.Data.operable_entities_bp, surface, {x=4, y=0}, boat.force_name)
		for _, e2 in pairs(es2) do
			if e2 and e2.valid then
				e2.destructible = false
				e2.minable = false
				e2.rotatable = false
			end
		end
		e = surface.create_entity({name = 'car', position = Public.Data.car_pos, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 16})
			e.color = {148, 106, 52}
			e.destructible = false
			e.minable = false
			e.rotatable = false
			e.operable = false
		end

		rendering.draw_text{
			text = 'Captain\'s Cabin',
			surface = surface,
			target = Public.Data.surfacename_rendering_pos,
			color = CoreData.colors.renderingtext_yellow,
			scale = 3.5,
			font = 'default-game',
			alignment = 'center'
		}
	end
end

function Public.connect_up_linked_belts_to_deck() --assumes both are in standard lrtd order
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	if boat and boat.deck_whitebelts and #boat.deck_whitebelts > 0 and boat.cabin_whitebelts and #boat.cabin_whitebelts > 0 then

		local connections = {
			{1,7},
			{2,8},
			{3,9},
			{4,10},
			{5,11},
			{6,12},
		}

		for _, c in pairs(connections) do
			local b1 = boat.cabin_whitebelts[c[1]]
			local b2 = boat.deck_whitebelts[c[2]]
			b1.connect_linked_belts(b2)
		end
	end
end


function Public.terrain(args)
	if args.p.x > Public.Data.width/2-1 and (args.p.y > 2 or args.p.y < -2) then
		args.tiles[#args.tiles + 1] = {name = 'out-of-map', position = args.p}
	else
		args.tiles[#args.tiles + 1] = {name = CoreData.static_boat_floor, position = args.p}
	end
	return nil
end

function Public.chunk_structures(args)
	return nil
end

return Public