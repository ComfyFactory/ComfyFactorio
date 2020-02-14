require "maps.chronosphere.comfylatron"
local Public = {}
local math_floor = math.floor
local math_random = math.random


function Public.locomotive_spawn(surface, position)
	for y = -10, 18, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	global.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -6}, force = "player"})
	global.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	global.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 0}, force = "player"})
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 1})

	global.locomotive_cargo2 = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 6}, force = "player"})
	global.locomotive_cargo2.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 1})

	global.locomotive_cargo3 = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 13}, force = "player"})
	global.locomotive_cargo3.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 1})

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
	global.locomotive_cargo2.operable = false
	global.locomotive_cargo3.minable = false
	global.locomotive_cargo3.operable = false
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
--[[
local function accelerate()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	if global.locomotive.get_driver() then return end
	global.locomotive_driver = global.locomotive.surface.create_entity({name = "character", position = global.locomotive.position, force = "player"})
	global.locomotive_driver.driving = true
	global.locomotive_driver.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
end

local function remove_acceleration()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	if global.locomotive_driver then global.locomotive_driver.destroy() end
	global.locomotive_driver = nil
end
]]
local function spawn_acumulators()
	local x = -28
	local y = -252
	local yy = global.objective.acuupgradetier * 2
	local surface = game.surfaces["cargo_wagon"]
	if yy > 8 then yy = yy + 2 end
	if yy > 26 then yy = yy + 2 end
	if yy > 44 then yy = yy + 2 end
	for i = 1, 27, 1 do
		local acumulator = surface.create_entity({name = "accumulator", position = {x + 2 * i, y + yy}, force="player", create_build_effect_smoke = false})
		acumulator.minable = false
		acumulator.destructible = false
		table.insert(global.acumulators, acumulator)
	end
end

local market_offers = {
	{price = {{'coin', 10}}, offer = {type = 'give-item', item = "raw-fish"}},
	{price = {{"coin", 20}}, offer = {type = 'give-item', item = 'wood', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'stone', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'coal', count = 50}},
	{price = {{"coin", 200}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
	{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
}
local market_offers2 = {
	[1] = function ()
		if global.objective.hpupgradetier >= 18 then return end
		global.objective.max_health = global.objective.max_health + 5000
		global.objective.hpupgradetier = global.objective.hpupgradetier + 1
		rendering.set_text(global.objective.health_text, "HP: " .. global.objective.health .. " / " .. global.objective.max_health)
	end,
	[2] = function ()
		if global.objective.acuupgradetier >= 24 then return end
		global.objective.acuupgradetier = global.objective.acuupgradetier + 1
		spawn_acumulators()
	end,
	[3] = function ()
		if global.objective.filterupgradetier >= 14 then return end
		global.objective.filterupgradetier = global.objective.filterupgradetier + 1
	end,

}
local function setup_upgrade_shop(market2)
	local special_offers = {}
	if global.objective.hpupgradetier < 18 then
		special_offers[1] = {{{"coin", 2500}}, "Upgrade Train's Health. Current max health: " .. global.objective.max_health }
	else
		special_offers[1] = {{{"computer", 1}}, "Maximum Health upgrades reached!"}
	end
	if global.objective.acuupgradetier < 24 then
		special_offers[2] = {{{"coin", 2500}}, "Upgrade Acumulator capacity"}
	else
		special_offers[2] = {{{"computer", 1}}, "Maximum Acumulators reached!"}
	end
	if global.objective.filterupgradetier < 14 then
		special_offers[3] = {{{"coin", 2500}}, "Upgrade Pollution filter. Actual pollution from train: " .. math_floor(400/(global.objective.filterupgradetier/2+1)) .. "%"}
	else
		special_offers[3] = {{{"computer", 1}}, "Best filter reached! Actual pollution from train: " .. math_floor(400/(global.objective.filterupgradetier/2+1)) .. "%"}
	end

	local market_items = {}
	for _, offer in pairs(special_offers) do
		table.insert(market_items, {price = offer[1], offer = {type = 'nothing', effect_description = offer[2]}})
	end
	for _, offer in pairs(market_items) do market2.add_market_item(offer) end
end


local function create_wagon_room()
	local width = 64
	local height = 384
	global.comfychests2 = {}
	if not global.acumulators then global.acumulators = {} end
	local map_gen_settings = {
		["width"] = width,
		["height"] = height,
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

	for x = width * -0.5, width * 0.5 - 1, 1 do
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

	for x = width * -0.4 + 6, width * 0.4 - 6, 1 do
		for y = height * -0.5 + 7, height * -0.5 + 10, 1 do
			local p = {x,y}
			surface.set_tiles({{name = "water", position = p}})
			if math.random(1, 3) == 1 then surface.create_entity({name = "fish", position = p}) end
		end
	end

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
		substation.minable = false
		substation.destructible = false
		for j = 1, 4, 1 do
			local xx = x - 2 * j
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
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
	local market2 = surface.create_entity({name = "market", position = {4, height * -0.5 + 13}, force="neutral", create_build_effect_smoke = false})
	local repairchest = surface.create_entity({name = "compilatron-chest", position = {0, height * -0.5 + 13}, force = "player"})
	repairchest.minable = false
	repairchest.destructible = false
	market.minable = false
	market.destructible = false
	market2.minable = false
	market2.destructible = false
	global.upgrademarket = market2
	global.repairchest = repairchest

	local repair_text = rendering.draw_text{
		text = "Insert repair tools to repair train",
		surface = surface,
		target = global.repairchest,
		target_offset = {0, -2.5},
		color = global.locomotive.color,
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
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
	local market2_text = rendering.draw_text{
		text = "Upgrades",
		surface = surface,
		target = market2,
		target_offset = {0, -3.5},
		color = global.locomotive.color,
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}

	-- for x = -6, 5, 1 do
	-- 	for y = height * -0.5 + 11, height * -0.5 + 15, 4 do
	-- 		local wall = surface.create_entity({name = "stone-wall", position = {x,y}, force="neutral", create_build_effect_smoke = false})
	-- 		wall.minable = false
	-- 		wall.destructible = false
	-- 	end
	-- end
	-- for y = height * -0.5 + 11, height * -0.5 + 15, 1 do
	-- 	for x = -7, 6, 13 do
	-- 		local wall = surface.create_entity({name = "stone-wall", position = {x,y}, force="neutral", create_build_effect_smoke = false})
	-- 		wall.minable = false
	-- 		wall.destructible = false
	-- 	end
	-- end
	for _, offer in pairs(market_offers) do market.add_market_item(offer) end
	setup_upgrade_shop(market2)

	--generate cars--
	for _, x in pairs({width * -0.5 -0.5, width * 0.5 + 0.5}) do
		local e = surface.create_entity({name = "car", position = {x, 0}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end
	for _, x in pairs({width * -0.5 - 0.5, width * 0.5 + 0.5}) do
		local e = surface.create_entity({name = "car", position = {x, -128}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end
	for _, x in pairs({width * -0.5 - 0.5, width * 0.5 + 0.5}) do
		local e = surface.create_entity({name = "car", position = {x, 128}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end

	--local e = Public.spawn_comfylatron(surface.index, 0, height * -0.5 + 13)
	--local e = surface.create_entity({name = "compilatron", position = {0, height * -0.5 + 13}, force = "player", create_build_effect_smoke = false})
	--e.ai_settings.allow_destroy_when_commands_fail = false


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
	if not vehicle then return end
	if not vehicle.valid then return end
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
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
		local surface = global.locomotive_cargo.surface
		local x_vector = (vehicle.position.x / math.abs(vehicle.position.x)) * 2
		local y_vector = vehicle.position.y / 16
		local position = {global.locomotive_cargo2.position.x + x_vector, global.locomotive_cargo2.position.y + y_vector}
		local position = surface.find_non_colliding_position("character", position, 128, 0.5)
		if not position then return end
		player.teleport(position, surface)
	end
end

local function clear_offers(market)
	for i = 1, 256, 1 do
		local a = market.remove_market_item(1)
		if a == false then return end
	end
end

function Public.refresh_offers(event)

	local market = event.entity or event.market
	if not market then return end
	if not market.valid then return end
	if market.name ~= "market" then return end
	if market ~= global.upgrademarket then return end
	clear_offers(market)
	setup_upgrade_shop(market)
end

function Public.offer_purchased(event)
	local offer_index = event.offer_index
	if not market_offers2[offer_index] then return end
	local market = event.market
	if not market.name == "market" then return end

	market_offers2[offer_index]()

	count = event.count
	if count > 1 then
		local offers = market.get_market_items()
		local price = offers[offer_index].price[1].amount
		game.players[event.player_index].insert({name = "coin", count = price * (count - 1)})
	end
	Public.refresh_offers(event)
end



return Public
