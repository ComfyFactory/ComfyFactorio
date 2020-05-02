local Event = require 'utils.event'
local Power = require "maps.scrapyard.power"
local ICW = require "maps.scrapyard.icw.main"
local WD = require "modules.wave_defense.table"
local Scrap_table = require "maps.scrapyard.table"
local RPG = require 'maps.scrapyard.rpg'

local Public = {}

local desc = {
	["clear_threat_level"] = "[Wave Defense]:\nClears the current threat to 0\nUsable if threat level is too high.\nCan be purchased multiple times.",
	["energy_upgrade"] = "[Linked Power]:\nUpgrades the buffer size of the energy interface\nUsable if the power dies easily.\nCan be purchased multiple times.",
	["locomotive_max_health"] = "[Locomotive Health]:\nUpgrades the train health.\nCan be purchased multiple times."
}

local energy_upgrade = 50000000

local function rebuild_energy_overworld(data)
	local this = data.this
	local surface = data.surface
	if this.ow_energy then
		if this.ow_energy.valid then
			local position = this.ow_energy.position
			local area = {
	            left_top = {x = position.x - 2, y = position.y - 2},
	            right_bottom = {x = position.x + 2, y = position.y + 2}
	            }
			if Public.contains_positions(this.locomotive.position, area) then return end
			this.old_ow_energy = this.ow_energy.energy
			this.ow_energy.destroy()
			this.energy["scrapyard"] = nil
		end
	end
	this.ow_energy = surface.create_entity{
		name = "electric-energy-interface",
		position = {
			x=this.locomotive.position.x,
			y=this.locomotive.position.y+2
		},
		create_build_effect_smoke = false,
		force = game.forces.neutral
	}

	rendering.draw_text{
	  text = "Power to locomotive",
	  surface = surface,
	  target = this.ow_energy,
	  target_offset = {0, -1.5},
	  color = { r = 0, g = 1, b = 0},
	  alignment = "center"
	}

	this.ow_energy.minable = false
	this.ow_energy.destructible = false
	this.ow_energy.operable = false
	this.ow_energy.power_production = 0
	if this.energy_purchased then
		this.ow_energy.electric_buffer_size = energy_upgrade
	else
		this.ow_energy.electric_buffer_size = 10000000
	end
	if this.old_ow_energy then
		this.ow_energy.energy = this.old_ow_energy
	end
end

local function rebuild_energy_loco(data, rebuild)
	local this = data.this
	local surface = data.surface
	local pos = {x=-19, y=3}

	if rebuild then
		local radius = 1024
		local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
		for _, entity in pairs(surface.find_entities_filtered{area = area, name = "electric-energy-interface"}) do
			entity.destroy()
		end
		this.energy.loco = nil
		this.lo_energy = nil
	end

	this.lo_energy = surface.create_entity{
		name = "electric-energy-interface",
		position = pos,
		create_build_effect_smoke = false,
		force = game.forces.neutral
	}

	rendering.draw_text{
	  text = "Power to overworld",
	  surface = surface,
	  target = this.lo_energy,
	  target_offset = {0, -1.5},
	  color = { r = 0, g = 1, b = 0},
	  alignment = "center"
	}

	this.lo_energy.minable = false
	this.lo_energy.destructible = false
	this.lo_energy.operable = false
	this.lo_energy.power_production = 0
	if this.energy_purchased then
		this.lo_energy.electric_buffer_size = energy_upgrade
	else
		this.lo_energy.electric_buffer_size = 10000000
	end
end

local function refresh_market(data)
    local this = data.this

	if this.market then
	    for i = 1, 100, 1 do
			local a = this.market.remove_market_item(1)
			if a == false then break end
	    end
	end

    local items = {
    {price = {{"coin", 5000 * (1 + this.train_upgrades)}, {"chemical-science-pack", 200 * (1 + this.train_upgrades)}, {"advanced-circuit", 150 * (1 + this.train_upgrades)}},
    offer = {type = 'nothing', effect_description = desc["clear_threat_level"]}},

    {price = {{"coin", 5000 * (1 + this.train_upgrades)}, {"solar-panel", 500 * (1 + this.train_upgrades)}, {"accumulator", 100 * (1 + this.train_upgrades)}},
    offer = {type = 'nothing', effect_description = desc["energy_upgrade"]}},

    {price = {{"coin", 5000 * (1 + this.train_upgrades)}, {"copper-plate", 1500 * (1 + this.train_upgrades)}, {"iron-plate", 500 * (1 + this.train_upgrades)}},
    offer = {type = 'nothing', effect_description = desc["locomotive_max_health"]}},

    {price = {{"coin", 5}}, offer = {type = 'give-item', item = 'small-lamp'}},
	{price = {{"coin", 5}}, offer = {type = 'give-item', item = 'firearm-magazine'}},
	{price = {{'wood', 25}}, offer = {type = 'give-item', item = "raw-fish", count = 2}}
	}

    for _, item in pairs(items) do
        this.market.add_market_item(item)
    end
    return items
end

local function create_market(data, rebuild)
    local surface = data.surface
    local this = data.this
    local pos = {x=18,y=3}

    if rebuild then
		local radius = 1024
		local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
		for _, entity in pairs(surface.find_entities_filtered{area = area, name = "market"}) do
			entity.destroy()
		end
		this.market = nil
	end
	if this.market then
	    for i = 1, 100, 1 do
			local a = this.market.remove_market_item(1)
			if a == false then break end
	    end
	end

    this.market = surface.create_entity {name = "market", position = pos, force = "player"}

    rendering.draw_text{
      text = "Market",
      surface = surface,
      target = this.market,
      target_offset = {0, 2},
      color = { r=0.98, g=0.66, b=0.22},
      alignment = "center"
    }

    this.market.destructible = false

    local items = refresh_market(data)

    for _, item in pairs(items) do
        this.market.add_market_item(item)
    end
end

local function on_market_item_purchased(event)
	local player = game.players[event.player_index]
	local market = event.market
	local offer_index = event.offer_index
	local offers = market.get_market_items()
	local bought_offer = offers[offer_index].offer
	if bought_offer.type ~= "nothing" then return end
	local this = Scrap_table.get_table()
	local wdt = WD.get_table()
	local icw_table = ICW.get_table()
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	local unit_surface = this.locomotive.unit_number
	local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

	local data = {
		this = this,
		surface = surface,
		wave = wdt
	}

	if bought_offer.effect_description == desc["clear_threat_level"] then
		game.print("[color=blue]Grandmaster:[/color] " .. player.name .. " has bought the group some extra time. Threat level is no more!", {r = 0.22, g = 0.77, b = 0.44})
		this.train_upgrades = this.train_upgrades + 1
		wdt.threat = 0

		refresh_market(data)
		return
	end
	if bought_offer.effect_description == desc["energy_upgrade"] then
		game.print("[color=blue]Grandmaster:[/color] " .. player.name .. " has bought the group a power upgrade The energy interface is now buffed!", {r = 0.22, g = 0.77, b = 0.44})
		this.train_upgrades = this.train_upgrades + 1
		this.energy_purchased = true
		this.lo_energy.electric_buffer_size =  this.lo_energy.electric_buffer_size + energy_upgrade
		this.ow_energy.electric_buffer_size =  this.ow_energy.electric_buffer_size + energy_upgrade

		refresh_market(data)
		return
	end
	if bought_offer.effect_description == desc["locomotive_max_health"] then
		game.print("[color=blue]Grandmaster:[/color] " .. player.name .. " has bought the group a train health modifier! The train health is now buffed!", {r = 0.22, g = 0.77, b = 0.44})
		this.locomotive_max_health = this.locomotive_max_health + 2500
		this.train_upgrades = this.train_upgrades + 1
		rendering.set_text(this.health_text, "HP: " .. this.locomotive_health .. " / " .. this.locomotive_max_health)

		refresh_market(data)
		return
	end
end

local function on_gui_opened(event)
	if not event.entity then return end
	if not event.entity.valid then return end
	local this = Scrap_table.get_table()
	local icw_table = ICW.get_table()
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	local unit_surface = this.locomotive.unit_number
	local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

	local data = {
		this = this,
		surface = surface
	}
	if event.entity.name == "market" then refresh_market(data) return end
end

--local function distance(data)
--	local sqrt = math.sqrt
--	local floor = math.floor
--	local player = data.player
--	local rpg = data.rpg
--	local distance_to_center = floor(sqrt(player.position.x ^ 2 + player.position.y ^ 2))
--	local location = distance_to_center
--	if location < 950 then return end
--	local min = 960 * rpg[player.index].bonus
--	local max = 965 * rpg[player.index].bonus
--	local min_times = location >= min
--	local max_times = location <= max
--	if min_times and max_times then
--		rpg[player.index].bonus = rpg[player.index].bonus + 1
--		player.print("[color=blue]Grandmaster:[/color] Survivor! Well done.")
--		Public.gain_xp(player, 300 * rpg[player.index].bonus)
--		return
--	end
--end

local function property_boost(data)
	local surface = data.surface
	local rng = math.random
	local xp_floating_text_color = {r = rng(0,128), g = 128, b = 0}
	local visuals_delay = 1800
	local this = data.this
	local rpg = data.rpg
	local loco = this.locomotive.position
	local area = {
        left_top = {x = loco.x - 40, y = loco.y - 40},
        right_bottom = {x = loco.x + 40, y = loco.y + 40}
        }
	for _, player in pairs(game.connected_players) do
		if player.surface ~= surface then return end
		if Public.contains_positions(player.position, area) then
			local pos = player.position
			RPG.gain_xp(player, 0.2 * rpg[player.index].bonus)
			player.create_local_flying_text{text="+" .. "", position={x=pos.x, y=pos.y-2}, color=xp_floating_text_color, time_to_live=120, speed=2}
			rpg[player.index].xp_since_last_floaty_text = 0
			rpg[player.index].last_floaty_text = game.tick + visuals_delay
		end
	end
end

function Public.boost_players_around_train()
	local rpg = RPG.get_table()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	if not this.locomotive then return end
	if not this.locomotive.valid then return end

	local data = {
		this = this,
		surface = surface,
		rpg = rpg
	}
	property_boost(data)
end

function Public.render_train_hp()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	this.health_text = rendering.draw_text{
		text = "HP: " .. this.locomotive_health .. " / " .. this.locomotive_max_health,
		surface = surface,
		target = this.locomotive,
		target_offset = {0, -2.5},
		color = this.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	this.caption = rendering.draw_text{
		text = "Grandmasters Train",
		surface = surface,
		target = this.locomotive,
		target_offset = {0, -4.25},
		color = this.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end

function Public.locomotive_spawn(surface, position)
	local this = Scrap_table.get_table()
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	this.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	this.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	this.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 3}, force = "player"})
	this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 8})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = this.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	this.locomotive.color = {0, 255, 0}
	this.locomotive.minable = false
	this.locomotive_cargo.minable = false
	this.locomotive_cargo.operable = true

	ICW.register_wagon(this.locomotive)
	ICW.register_wagon(this.locomotive_cargo)
end

function Public.inside(pos, area)
    local lt = area.left_top
    local rb = area.right_bottom

    return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
end
function Public.contains_positions(pos, area)
    if Public.inside(pos, area) then
        return true
    end
    return false
end

function Public.place_market()
	local this = Scrap_table.get_table()
	local icw_table = ICW.get_table()
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	local unit_surface = this.locomotive.unit_number
	local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

	local data = {
		this = this,
		surface = surface
	}
	if not this.market then
		create_market(data)
	elseif not this.market.valid then
		create_market(data, true)
	end

end

function Public.power_source_overworld()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	if not this.locomotive then return end
	if not this.locomotive.valid then return end

	local data = {
		this = this,
		surface = surface
	}

	rebuild_energy_overworld(data)
end

function Public.power_source_locomotive()
	local this = Scrap_table.get_table()
	local icw_table = ICW.get_table()
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	local unit_surface = this.locomotive.unit_number
	local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

	local data = {
		this = this,
		icw_table = icw_table,
		surface = surface
	}

	if not this.lo_energy then
		rebuild_energy_loco(data)

	elseif not this.lo_energy.valid then
		rebuild_energy_loco(data, true)
	end
end

local function fish_tag()
	local this = Scrap_table.get_table()
	if not this.locomotive_cargo then return end
	if not this.locomotive_cargo.valid then return end
	if not this.locomotive_cargo.surface then return end
	if not this.locomotive_cargo.surface.valid then return end
	if this.locomotive_tag then
		if this.locomotive_tag.valid then
			if this.locomotive_tag.position.x == this.locomotive_cargo.position.x and this.locomotive_tag.position.y == this.locomotive_cargo.position.y then return end
			this.locomotive_tag.destroy()
		end
	end
	this.locomotive_tag = this.locomotive_cargo.force.add_chart_tag(
		this.locomotive_cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = this.locomotive_cargo.position,
		text = " "
	})
end

local function set_player_spawn_and_refill_fish()
	local this = Scrap_table.get_table()
	if not this.locomotive_cargo then return end
	if not this.locomotive_cargo.valid then return end
	this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math.random(2, 5)})
	local position = this.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", this.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, this.locomotive_cargo.surface)
end

local function tick()
	Public.power_source_overworld()
	Public.power_source_locomotive()
	Public.place_market()
	if game.tick % 120 == 0 then
		Public.boost_players_around_train()
	end
	if game.tick % 30 == 0 then
		if game.tick % 1800 == 0 then
			set_player_spawn_and_refill_fish()
		end
		fish_tag()
	end
end

Event.on_nth_tick(5, tick)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_gui_opened, on_gui_opened)

return Public