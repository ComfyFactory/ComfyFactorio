local Public = {}
local math_floor = math.floor
local math_random = math.random


function Public.locomotive_spawn(surface, position, wagons)
	if global.objective.planet[1].name.id == 17 then
		position.x = position.x - 960
		position.y = position.y - 64
	end
	for y = -10, 18, 2 do
		local rail = {name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0}
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	global.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -6}, force = "player"})
	global.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	global.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 0}, force = "player"})
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 100})

	global.locomotive_cargo2 = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 6}, force = "player"})
	for item, count in pairs(wagons[1].inventory) do
		global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
	end

	global.locomotive_cargo3 = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 13}, force = "player"})
	for item, count in pairs(wagons[2].inventory) do
		global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon).insert({name = item, count = count})
	end
	if wagons[1].bar > 0 then global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).set_bar(wagons[1].bar) end
	if wagons[2].bar > 0 then global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon).set_bar(wagons[2].bar) end
	for i = 1, 40, 1 do
		global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).set_filter(i, wagons[1].filters[i])
		global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon).set_filter(i, wagons[2].filters[i])
	end

	if not global.comfychests then global.comfychests = {} end
	if not global.acumulators then global.acumulators = {} end

	for i = 1, 24, 1 do
		local yi = 0
		local xi = 5
		if i > 20 then
		 	yi = 6 - 12
			xi = 5
		elseif i > 16 then
		 	yi = 6 - 15
			xi = 5
		elseif i > 12 then
		 	xi = 5
		  yi = 6 - 18
		elseif i > 8 then
		 	yi = 6
		 	xi = 0
		elseif i > 4 then
		 	yi = 3
		 	xi = 0
		else
		 	yi = 0
		 	xi = 0
		end

		local comfychest = surface.create_entity({name = "compilatron-chest", position = {position.x - 2 + xi, position.y - 2 + yi + i}, force = "player"})
		comfychest.minable = false
		--comfychest.destructible = false
		if not global.comfychests[i] then
			table.insert(global.comfychests, comfychest)
		else
			global.comfychests[i] = comfychest
		end
	end
	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = global.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = global.locomotive_cargo,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	global.locomotive.color = {0, 255, 0}
	global.locomotive.minable = false
	global.locomotive_cargo.minable = false
	global.locomotive_cargo.operable = false
	global.locomotive_cargo2.minable = false
	--global.locomotive_cargo2.operable = false
	global.locomotive_cargo3.minable = false
	--global.locomotive_cargo3.operable = false
end


function Public.fish_tag()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	if not global.locomotive_cargo.surface then return end
	if not global.locomotive_cargo.surface.valid then return end
	if global.locomotive_tag then
		if global.locomotive_tag.valid then
			if global.locomotive_tag.position.x == global.locomotive_cargo.position.x and global.locomotive_tag.position.y == global.locomotive_cargo.position.y then return end
			global.locomotive_tag.destroy()
		end
	end
	global.locomotive_tag = global.locomotive_cargo.force.add_chart_tag(
		global.locomotive_cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = global.locomotive_cargo.position,
		text = " "
	})
end

local market_offers = {
	{price = {{'coin', 10}}, offer = {type = 'give-item', item = "raw-fish"}},
	{price = {{"coin", 20}}, offer = {type = 'give-item', item = 'wood', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'stone', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'coal', count = 50}},
	{price = {{"coin", 200}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
	{price = {{"coin", 25}, {"empty-barrel", 1}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
	{price = {{"coin", 200}, {"steel-plate", 20}, {"electronic-circuit", 20}}, offer = {type = 'give-item', item = 'loader', count = 1}},
	{price = {{"coin", 400}, {"steel-plate", 40}, {"advanced-circuit", 10}, {"loader", 1}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
	{price = {{"coin", 600}, {"express-transport-belt", 10}, {"fast-loader", 1}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
	--{price = {{"coin", 5}, {"stone", 100}}, offer = {type = 'give-item', item = 'landfill', count = 1}},
	{price = {{"coin", 1}, {"steel-plate", 1}, {"explosives", 10}}, offer = {type = 'give-item', item = 'land-mine', count = 1}}
}

local function create_wagon_room()
	local width = 64
	local height = 384
	global.comfychests2 = {}
	if not global.acumulators then global.acumulators = {} end
	local map_gen_settings = {
		["width"] = width,
		["height"] = height + 128,
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = false},
		},
	}
	local surface = 	game.create_surface("cargo_wagon", map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0.1
	surface.request_to_generate_chunks({0,0}, 12)
	surface.force_generate_chunk_requests()
	local carfpos = {
		[1]={x=-33,y=-127},[2]={x=-33,y=-128},[3]={x=-33,y=-129},[4]={x=-33,y=-130},[5]={x=32,y=-127},[6]={x=32,y=-128},[7]={x=32,y=-129},[8]={x=32,y=-130},
		[9]={x=-33,y=-2},[10]={x=-33,y=-1},[11]={x=-33,y=0},[12]={x=-33,y=1},[13]={x=32,y=-2},[14]={x=32,y=-1},[15]={x=32,y=0},[16]={x=32,y=1},
		[17]={x=-33,y=126},[18]={x=-33,y=127},[19]={x=-33,y=128},[20]={x=-33,y=129},[21]={x=32,y=126},[22]={x=32,y=127},[23]={x=32,y=128},[24]={x=32,y=129}
	}
	for i = 1, 24, 1 do
		surface.set_tiles({{name = "tutorial-grid", position = {carfpos[i].x,carfpos[i].y}}})
	end

	for x = width * -0.5, width * 0.5 - 1, 1 do
		for y = height * 0.5, height * 0.7, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * -0.7, height * -0.5, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * -0.5 + 3, height * 0.5 - 4, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
		for y = height * -0.16 - 5, height * -0.16 + 0, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * 0.16 - 0, height * 0.16 + 5, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * -0.5, height * -0.5 + 2, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * 0.5 - 3, height * 0.5, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
	end
	for x = width * -0.2 + 1, width * 0.2 - 1, 1 do
		for y = height * -0.16 - 5, height * -0.16 + 0, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
		for y = height * 0.16 -0, height * 0.16 + 5, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
		--for y = height * -0.5 -5, height * -0.5 + 3, 1 do
		--	surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		--end
	end

	for x = width * -0.5 + 5, width * 0.5 - 6, 1 do
		for y = height * -0.7 + 18, height * -0.5 - 5, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
	end

	for x = width * -0.5 - 6, width * -0.5 + 3, 1 do -- combinators
		for y = -251, -241, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
	end

	for x = width * -0.4 + 6, width * 0.4 - 6, 1 do
		for y = height * -0.5 + 7, height * -0.5 + 10, 1 do
			local p = {x,y}
			surface.set_tiles({{name = "water", position = p}})
			if math.random(1, 3) == 1 then surface.create_entity({name = "fish", position = p}) end
		end
	end

	local combinators = {}
	for x = width * -0.5 - 6, width * -0.5 + 3, 1 do
		for y = -250, -244, 2 do
			combinators[#combinators + 1] = {name = "arithmetic-combinator", position = {x, y}, force = "player", create_build_effect_smoke = false}
		end
	end
	local combimade = {}
	for i = 1, #combinators, 1 do
		combimade[i] = surface.create_entity(combinators[i])
		combimade[i].minable = false
		combimade[i].destructible = false
		combimade[i].operable = false

		if i > 1 then
			combimade[i].connect_neighbour({wire = defines.wire_type.green, target_entity = combimade[i - 1], source_circuit_id =  2, target_circuit_id = 1})
			local rule = combimade[i].get_or_create_control_behavior()
			rule.parameters = {parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, operation = "+", output_signal = {type = "virtual", name = "signal-A"}}}
		else
			local rule2 = combimade[i].get_or_create_control_behavior()
			rule2.parameters =  {parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, operation = "+", output_signal = {type = "virtual", name = "signal-B"}}}
		end
	end
	local checker = surface.create_entity({name = "decider-combinator", position = {x = width * -0.5 - 6, y = -242}, force = "player", create_build_effect_smoke = false })
		local rules3 = checker.get_or_create_control_behavior()
		rules3.parameters = {parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_signal = {type = "virtual", name = "signal-B"}, comparator = ">",
		output_signal = {type = "virtual", name = "signal-C"}, copy_count_from_input = false }}
	local combipower = surface.create_entity({name = "substation", position = {x = width * -0.5 - 4, y = -242}, force="player", create_build_effect_smoke = false})
	combipower.connect_neighbour({wire = defines.wire_type.green, target_entity = checker, target_circuit_id = 1})
	combipower.connect_neighbour({wire = defines.wire_type.green, target_entity = combimade[#combimade], target_circuit_id = 1})
	combimade[1].connect_neighbour({wire = defines.wire_type.green, target_entity = checker, source_circuit_id =  2, target_circuit_id = 1})
	local speaker = surface.create_entity({name = "programmable-speaker", position = {x = width * -0.5 - 6, y = -241}, force = "player", create_build_effect_smoke = false,
		parameters = {playback_volume = 0.6, playback_globally = true, allow_polyphony = false},
		alert_parameters = {show_alert = true, show_on_map = true, icon_signal_id = {type = "item", name = "accumulator"}, alert_message = "Train Is Charging!" }})
	speaker.connect_neighbour({wire = defines.wire_type.green, target_entity = checker, target_circuit_id = 2})
	local rules4 = speaker.get_or_create_control_behavior()
	rules4.circuit_condition = {condition = {first_signal = {type = "virtual", name = "signal-C"}, second_constant = 0, comparator = ">"}}
	local solar1 = surface.create_entity({name = "solar-panel", position = {x = width * -0.5 - 2, y = -242}, force="player", create_build_effect_smoke = false})
	local solar2 = surface.create_entity({name = "solar-panel", position = {x = width * -0.5 + 1, y = -242}, force="player", create_build_effect_smoke = false})
	solar1.destructible = false
	solar1.minable = false
	solar2.destructible = false
	solar2.minable = false
	combipower.destructible = false
	combipower.minable = false
	combipower.operable = false
	speaker.destructible = false
	speaker.minable = false
	speaker.operable = false
	checker.destructible = false
	checker.minable = false
	checker.operable = false



	for _, x in pairs({-1, 0}) do
		for i = 1, 12, 1 do
			local step = math_floor((i-1)/4)
			y = -131 + i + step * 128 - step * 4
			local e = surface.create_entity({name = "compilatron-chest", position = {x,y}, force = "player", create_build_effect_smoke = false})
			e.destructible = false
			e.minable = false
			table.insert(global.comfychests2, e)
		end

	end

	for i = 1, 9, 1 do
		local y = -0.7 * height + 18 + 9 + 18 * ( math_floor((i - 1) / 3))
		local x = -0.5 * width + 5 + 9 + 18 * ( i%3 )
		local substation = surface.create_entity({name = "substation", position = {x,y}, force="player", create_build_effect_smoke = false})
		if i == 3 then
			substation.disconnect_neighbour(combipower)
			substation.connect_neighbour({wire = defines.wire_type.green, target_entity = combipower})
		end
		substation.minable = false
		substation.destructible = false
		for j = 1, 4, 1 do
			local xx = x - 2 * j
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
			if i == 3 and j == 1 then
				acumulator.connect_neighbour({wire = defines.wire_type.green, target_entity = substation})
			end
			acumulator.minable = false
			acumulator.destructible = false
			table.insert(global.acumulators, acumulator)
		end
		for k = 1, 4, 1 do
			local xx = x + 2 * k
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
			acumulator.minable = false
			acumulator.destructible = false
			table.insert(global.acumulators, acumulator)
		end

	end

	local powerpole = surface.create_entity({name = "big-electric-pole", position = {0, height * -0.5 }, force="player", create_build_effect_smoke = false})
	powerpole.minable = false
	powerpole.destructible = false

	local market = surface.create_entity({name = "market", position = {-5, height * -0.5 + 13}, force="neutral", create_build_effect_smoke = false})
	market.minable = false
	market.destructible = false

	local upgradechests = {
		[1] = {name = "repairchest", entity = {name = "compilatron-chest", position = {0, height * -0.5 + 13}, force = "player"}, signal = nil},
		[2] = {name = "hpchest", entity = {name = "compilatron-chest", position = {3, height * -0.5 + 12}, force = "player"}, signal = "virtual-signal/signal-1"},
		[3] = {name = "filterchest", entity = {name = "compilatron-chest", position = {4, height * -0.5 + 12}, force = "player"}, signal = "virtual-signal/signal-2"},
		[4] = {name = "acuchest", entity = {name = "compilatron-chest", position = {5, height * -0.5 + 12}, force = "player"}, signal = "virtual-signal/signal-3"},
		[5] = {name = "reachchest", entity = {name = "compilatron-chest", position = {3, height * -0.5 + 13}, force = "player"}, signal = "virtual-signal/signal-4"},
		[6] = {name = "invchest", entity = {name = "compilatron-chest", position = {4, height * -0.5 + 13}, force = "player"}, signal = "virtual-signal/signal-5"},
		[7] = {name = "toolschest", entity = {name = "compilatron-chest", position = {5, height * -0.5 + 13}, force = "player"}, signal = "virtual-signal/signal-6"},
		[8] = {name = "waterchest", entity = {name = "compilatron-chest", position = {3, height * -0.5 + 14}, force = "player"}, signal = "virtual-signal/signal-7"},
		[9] = {name = "outchest", entity = {name = "compilatron-chest", position = {4, height * -0.5 + 14}, force = "player"}, signal = "virtual-signal/signal-8"},
		[10] = {name = "boxchest", entity = {name = "compilatron-chest", position = {5, height * -0.5 + 14}, force = "player"}, signal = "virtual-signal/signal-9"},
		[11] = {name = "poisonchest", entity = {name = "compilatron-chest", position = {6, height * -0.5 + 12}, force = "player"}, signal = "virtual-signal/signal-P"},
		[12] = {name = "computerchest", entity = {name = "compilatron-chest", position = {6, height * -0.5 + 13}, force = "player"}, signal = "virtual-signal/signal-C"}
	}

	for i = 1, #upgradechests, 1 do
		local e = surface.create_entity(upgradechests[i].entity)
		e.minable = false
		e.destructible = false
		global.upgradechest[i] = e
		if i == 1 then
			local repair_text = rendering.draw_text{
				text = "Repair chest",
				surface = surface,
				target = e,
				target_offset = {0, -2.5},
				color = global.locomotive.color,
				scale = 1.00,
				font = "default-game",
				alignment = "center",
				scale_with_zoom = false
			}
		else
			local upgrade_text = rendering.draw_sprite{
				sprite = upgradechests[i].signal,
				surface = surface,
				target = e,
				target_offset = {0, -0.1},
				font = "default-game",
				visible = true
			}
		end
	end

	local market1_text = rendering.draw_text{
		text = "Resources",
		surface = surface,
		target = market,
		target_offset = {0, -3.5},
		color = global.locomotive.color,
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	local upgrade_text = rendering.draw_text{
		text = "Upgrades",
		surface = surface,
		target = global.upgradechest[3],
		target_offset = {0, -3.5},
		color = global.locomotive.color,
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	local upgrade_sub_text = rendering.draw_text{
		text = "Click [Upgrades] on top of screen",
		surface = surface,
		target = global.upgradechest[3],
		target_offset = {0, -2.5},
		color = global.locomotive.color,
		scale = 0.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}


	for _, offer in pairs(market_offers) do market.add_market_item(offer) end

	--generate cars--
	for _, x in pairs({width * -0.5 -1.4, width * 0.5 + 1.4}) do
		local e = surface.create_entity({name = "car", position = {x, 0}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end
	for _, x in pairs({width * -0.5 - 1.4, width * 0.5 + 1.4}) do
		local e = surface.create_entity({name = "car", position = {x, -128}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end
	for _, x in pairs({width * -0.5 - 1.4, width * 0.5 + 1.4}) do
		local e = surface.create_entity({name = "car", position = {x, 128}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end

	--generate chests inside south wagon--
	local positions = {}
	for x = width * -0.5 + 2, width * 0.5 - 1, 1 do
		if x == -1 then x = x - 1 end
		if x == 0 then x = x + 1 end
		for y = 68, height * 0.5 - 4, 1 do
			positions[#positions + 1] = {x = x, y = y}
		end
	end
	table.shuffle_table(positions)

	local cargo_boxes = {
		{name = "grenade", count = math_random(2, 5)},
		{name = "grenade", count = math_random(2, 5)},
		{name = "grenade", count = math_random(2, 5)},
		{name = "submachine-gun", count = 1},
		{name = "submachine-gun", count = 1},
		{name = "submachine-gun", count = 1},
		{name = "land-mine", count = math_random(8, 12)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "shotgun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun-shell", count = math_random(5, 7)},
		{name = "shotgun-shell", count = math_random(5, 7)},
		{name = "shotgun-shell", count = math_random(5, 7)},
		{name = "firearm-magazine", count = math_random(7, 15)},
		{name = "firearm-magazine", count = math_random(7, 15)},
		{name = "firearm-magazine", count = math_random(7, 15)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)},
	}

	local i = 1
	for _ = 1, 16, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		local inventory = e.get_inventory(defines.inventory.chest)
		inventory.insert({name = "raw-fish", count = math_random(2, 5)})
		i = i + 1
	end

	for _ = 1, 24, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		i = i + 1
	end

	for loot_i = 1, #cargo_boxes, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		local inventory = e.get_inventory(defines.inventory.chest)
		inventory.insert(cargo_boxes[loot_i])
		i = i + 1
	end
end

function Public.set_player_spawn_and_refill_fish()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	global.locomotive_cargo.health = global.locomotive_cargo.health + 6
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math_random(1, 2)})
	local position = global.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", global.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, global.locomotive_cargo.surface)
end

function Public.enter_cargo_wagon(player, vehicle)
	if not vehicle then log("no vehicle") return end
	if not vehicle.valid then log("vehicle invalid") return end
	if not global.locomotive_cargo then log("no cargo") return end
	if not global.locomotive_cargo.valid then log("cargo invalid") return end
	if vehicle == global.locomotive_cargo then
		if not game.surfaces["cargo_wagon"] then create_wagon_room() end
		local surface = game.surfaces["cargo_wagon"]
		local x_vector = vehicle.position.x - player.position.x
		local position
		if x_vector > 0 then
			position = {surface.map_gen_settings.width * -0.5, -128}
		else
			position = {surface.map_gen_settings.width * 0.5, -128}
		end
		player.teleport(surface.find_non_colliding_position("character", position, 128, 0.5), surface)
	end
	if not global.locomotive_cargo2 then return end
	if not global.locomotive_cargo2.valid then return end
	if vehicle == global.locomotive_cargo2 then
		if not game.surfaces["cargo_wagon"] then create_wagon_room() end
		local surface = game.surfaces["cargo_wagon"]
		local x_vector = vehicle.position.x - player.position.x
		local position
		if x_vector > 0 then
			position = {surface.map_gen_settings.width * -0.5, 0}
		else
			position = {surface.map_gen_settings.width * 0.5, 0}
		end
		player.teleport(surface.find_non_colliding_position("character", position, 128, 0.5), surface)
	end
	if not global.locomotive_cargo3 then return end
	if not global.locomotive_cargo3.valid then return end
	if vehicle == global.locomotive_cargo3 then
		if not game.surfaces["cargo_wagon"] then create_wagon_room() end
		local surface = game.surfaces["cargo_wagon"]
		local x_vector = vehicle.position.x - player.position.x
		local position
		if x_vector > 0 then
			position = {surface.map_gen_settings.width * -0.5, 128}
		else
			position = {surface.map_gen_settings.width * 0.5, 128}
		end
		player.teleport(surface.find_non_colliding_position("character", position, 128, 0.5), surface)
	end
	if player.surface.name == "cargo_wagon" and vehicle.type == "car" then
		if global.flame_boots then
			global.flame_boots[player.index] = {fuel = 1, steps = {}}
		end
		local surface = global.locomotive_cargo.surface
		local x_vector = (vehicle.position.x / math.abs(vehicle.position.x)) * 2
		local y_vector = vehicle.position.y / 16
		local position = {global.locomotive_cargo2.position.x + x_vector, global.locomotive_cargo2.position.y + y_vector}
 		local position2 = surface.find_non_colliding_position("character", position, 128, 0.5)
		if not position2 then return end
		player.teleport(position2, surface)
	end
end

return Public
