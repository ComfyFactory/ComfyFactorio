
local Memory = require 'maps.pirates.memory'
-- local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require 'utils.inspect'.inspect
local SurfacesCommon = require 'maps.pirates.surfaces.common'

local Public = {}
local enum = {
	DEFAULT = 'Default',
}
Public.enum = enum

Public.Data = {}

Public.Data.width = 18
Public.Data.height = 24

Public.Data.cabin_whitebelts_lrtp_order = {
	{x = -7.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -6.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -5.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -4.5, y = -10.5, direction = defines.direction.north, type = 'input'},
	{x = -7.5, y = 10.5, direction = defines.direction.south, type = 'output'},
	{x = -6.5, y = 10.5, direction = defines.direction.south, type = 'output'},
	{x = -5.5, y = 10.5, direction = defines.direction.south, type = 'output'},
	{x = -4.5, y = 10.5, direction = defines.direction.south, type = 'output'},
}

Public.Data.car_pos = {x = 9, y = 0}

Public.Data.market_position = {x = 4.5, y = 3.5}

Public.Data.static_entities_bp = [[0eNqlmu9u2jAUxd8ln2HK9X/zKlM10RJ1kWiCkrAVVX33hVJtXcuJfcwnhEh+XF+fY8e596W63x+bw9B2U7V5qcZue1hP/fpxaHfn78/VRsKqOlUbZV5XVfvQd2O1+T5f2D522/35kul0aKpN1U7NU7Wquu3T+dvvvt813frhZzNO1fnGbtecWa+r5K3N82FoxnE9HvbtNDXDh9vV692qarqpndrmEsbbl9OP7vh0P1+5kesBrKpDP8439d37mOpv9m1Q8+frOaRPGJWJkWWMzsSoZYzJxOhljM3EmGWMy8TYZYzPxLhlTMjE+GVMzMSEZYzUmZyY4OTqWBJClmwlJ6QsuVqWhJglV82SkLPk6lkSgpZcRUtC0pKraUmIWgK5jCnAiSRHwHJYf1mcp2HbjYd+mNb3zX5hLQKRKaGJJkFUpPUQR5MclLN/Ot8OU7vfN8NpPR2HoVmS6Jy2ebfbtUPzcPnZXUNbVmcoRseCUNI8KTQDOKzwNeBEWl6yTNR1MRGMVfMWUAmiKjYVGrX+Qtz32938E9ynzf/6nV3w/pDXH6fD8fws+PVfTPa/+Bv+xZLGRll2JAfllt4tECiwIDQydrtw4Hm1JjkWcKTYc4ioiolorLrYxYhoiolo1LZ4+0YxumIiitEXr10oxkATbYLI7yruAzG5r1v29ADitEJywJxYxS4sCKRZEBqZIVeWADiW5HjAccXrCSL6YiIaayheT1CMsdhZ/rMP1LU3DHX+8wCg/n0eaDvwOOBYk4D0OvbcAZLqaI8gkGFBaGSsSQS9MXIkKAJOuTdgaOWbRMySciSlHAuk7Nl9A2XDs54AE+XpjQOBsk3hU0OjXQFJtC3AodmzthBwjPc3+ALFVu6LtyiTxvCsMa5g084ItDNAPgLrDDRXQbGTDg5rQbMgcHwMplw9KDZbrh6do57gWPXoEvV4dtJRPgILQnMV6VUMhBRremUFMUWhY0Ik2hvgmBBpb4CDS7zBGyi2G7xhc7wRaW/YAm9E2hsoH7Q30Fzx3rCoilfTKIdQbEVaAiLR7vCIpMtVDaMz5bLOOhRKbVldlxwLpWZf7+KU0BaBE0a/4cUo3iVofMK+5lWw2k2bJCJS+QteHJ0ur1VCpmGrlZDEljVw7lxJxfItsOSrTeFr4zhO2g04eWzFQ6FKu6LNIIgk5cV2yCyvDGImWyjHuaPNAGOiK+MYxdfG4fjY6rjSiBTIxjRMimRvGiTpmmxPwyQhO9QwSZFNapikyT41TDJkqxomsUs+Jjmy7w2TPNtohlGBbX7DqMg2m0FUdlFbko4xwjacYZRim+Awii5AXFB3q0v/7uZDI/Gq+tUM4+WZO4jxUXlrZt3W8/V/ACz9dUA=]]

Public.Data.operable_entities_bp = [[0eNqVkeFqwzAMhN9Fv51Ru8nS+lVKGWkjOkMiG0vZGkrefbZXRhljbX+Jg7vPJ/kCh2HCEB0J2AswdaESX52i67M+gzUrBXMa9aLAHT0x2F0yuhN1Q7bIHBAsOMERFFA3ZvXpfY9UHd+RBXKQekwsvai7UTyHiMwVh8GJYLyJm2WvAEmcOPyuUcT8RtN4SE6rfygsiMP1fQXBc8p4uq6kX1+aslSaS670C2MexLT/Y9ZPtmn/xtRPtimYdKhyVnvzvwo+MHJJmI2u261pm1qvm1XyfwG7QKjd]]

Public.Data.cabin_splitters = {
	{x = -7, y = 9.5, direction = defines.direction.north, type = 0},
	{x = -6, y = 8.5, direction = defines.direction.north, type = 0},
	{x = -5, y = 7.5, direction = defines.direction.north, type = 0},
	{x = -4, y = 6.5, direction = defines.direction.north, type = 0},
	{x = -7, y = 7.5, direction = defines.direction.north, type = 1},
	{x = -6, y = 6.5, direction = defines.direction.north, type = 1},
	{x = -5, y = 5.5, direction = defines.direction.north, type = 1},
	{x = -4, y = 4.5, direction = defines.direction.north, type = 1},
	{x = -7, y = 5.5, direction = defines.direction.north, type = 2},
	{x = -6, y = 4.5, direction = defines.direction.north, type = 2},
	{x = -5, y = 3.5, direction = defines.direction.north, type = 2},
	{x = -4, y = 2.5, direction = defines.direction.north, type = 2},
	{x = -7, y = 3.5, direction = defines.direction.north, type = 3},
	{x = -6, y = 2.5, direction = defines.direction.north, type = 3},
	{x = -5, y = 1.5, direction = defines.direction.north, type = 3},
	{x = -4, y = 0.5, direction = defines.direction.north, type = 3},
	{x = -7, y = 1.5, direction = defines.direction.north, type = 4},
	{x = -6, y = 0.5, direction = defines.direction.north, type = 4},
	{x = -5, y = -0.5, direction = defines.direction.north, type = 4},
	{x = -4, y = -1.5, direction = defines.direction.north, type = 4},
	{x = -7, y = -0.5, direction = defines.direction.north, type = 5},
	{x = -6, y = -1.5, direction = defines.direction.north, type = 5},
	{x = -5, y = -2.5, direction = defines.direction.north, type = 5},
	{x = -4, y = -3.5, direction = defines.direction.north, type = 5},
	-- {x = -7, y = -2.5, direction = defines.direction.north, type = 6},
	-- {x = -6, y = -3.5, direction = defines.direction.north, type = 6},
	-- {x = -5, y = -4.5, direction = defines.direction.north, type = 6},
	-- {x = -4, y = -5.5, direction = defines.direction.north, type = 6},
	{x = -7, y = -2.5, direction = defines.direction.north, type = 7},
	{x = -6, y = -3.5, direction = defines.direction.north, type = 7},
	{x = -5, y = -4.5, direction = defines.direction.north, type = 7},

	{x = -5, y = -7.5, direction = defines.direction.north, type = 7},
	{x = -6, y = -8.5, direction = defines.direction.north, type = 7},
	{x = -7, y = -9.5, direction = defines.direction.north, type = 7},
	{x = -4, y = -6.5, direction = defines.direction.north, type = 8},
	{x = -2, y = -6.5, direction = defines.direction.south, type = 9},
}

Public.Data.output_chest = {x = -2.5, y = -9.5}
Public.Data.backup_output_chest = {x = -1.5, y = -9.5}

Public.Data.input_chests = {
	{x = -0.5, y = 5.5},
	{x = -0.5, y = 3.5},
	{x = -0.5, y = 1.5},
	{x = -0.5, y = -0.5},
	{x = -0.5, y = -2.5},
	{x = -0.5, y = -4.5},
	-- {x = 0.5, y = -6.5},
}

Public.Data.surfacename_rendering_pos = {x = -0.5, y = -15}



Public.cabin_shop_data = {
	{
		price = {{'coin', 300}, {'coal', 25}},
		offer = {type='give-item', item = 'artillery-shell', count = 5},
	},
	{
		price = {{'coin', 1000}, {'electronic-circuit', 30}},
		offer = {type='give-item', item = 'rail-signal', count = 100},
	},
	{
		price = {{'coin', 2000}, {'stone-brick', 30}},
		offer = {type='give-item', item = 'uranium-238', count = 10},
	},
	{
		price = {{'coin', 25}},
		offer = {type='nothing', effect_description='Relax at sea for an extra minute: Increase the next destination\'s loading time by 60 seconds.'},
	},
}

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
			elseif splitter.type == 9 then
				priority = 'left'
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
				-- e.operable = false
				boat.input_chests[#boat.input_chests + 1] = e
			end
		end

		local p = {x = Public.Data.output_chest.x, y = Public.Data.output_chest.y}
		local e = surface.create_entity({name = 'red-chest', position = p, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			-- e.operable = false
			boat.output_chest = e
		end

		p = {x = Public.Data.backup_output_chest.x, y = Public.Data.backup_output_chest.y}
		e = surface.create_entity({name = 'red-chest', position = p, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			-- e.operable = false
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
		local es2 = Common.build_from_blueprint(Public.Data.operable_entities_bp, surface, {x=5, y=-4}, boat.force_name)
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

		e = surface.create_entity({name = 'market', position = Public.Data.market_position, force = boat.force_name, create_build_effect_smoke = false})
		if e and e.valid then
			e.destructible = false
			e.minable = false
			e.rotatable = false
			for _, offer in pairs(Public.cabin_shop_data) do
				e.add_market_item(offer)
			end
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
			{1,9},
			{2,10},
			{3,11},
			{4,12},
			{5,13},
			{6,14},
			{7,15},
			{8,16},
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

function Public.chunk_structures()
	return nil
end

return Public