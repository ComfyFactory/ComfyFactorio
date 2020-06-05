local Token = require 'utils.token'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WPT = require 'maps.mountain_fortress_v3.table'
local Event = require 'utils.event'

local Public = {}

local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8
local floor = math.floor

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local function do_refill_turrets()
    local refill_turrets = WPT.get('refill_turrets')
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local turret_data = refill_turrets[index]
    local turret = turret_data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)
        return
    end

    refill_turrets.index = index + 1

    local data = turret_data.data
    if data.liquid then
        turret.fluidbox[1] = data
    elseif data then
        turret.insert(data)
    end
end

local function turret_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local number = entity.unit_number
    if not number then
        return
    end
    local power_sources = WPT.get('power_sources')

    local ps_data = power_sources[number]
    if ps_data then
        power_sources[number] = nil

        local ps_entity = ps_data.entity
        local ps_pole = ps_data.pole

        if ps_entity and ps_entity.valid then
            ps_entity.destroy()
        end

        if ps_pole and ps_pole.valid then
            ps_pole.destroy()
        end
    end
end

local function do_magic_crafters()
    local magic_crafters = WPT.get('magic_crafters')
    local limit = #magic_crafters
    if limit == 0 then
        return
    end

    local index = magic_crafters.index

    for i = 1, magic_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                entity.get_output_inventory().insert {name = data.item, count = fcount}
                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local magic_fluid_crafters = WPT.get('magic_fluid_crafters')
    local limit = #magic_fluid_crafters

    if limit == 0 then
        return
    end

    local index = magic_fluid_crafters.index

    for i = 1, magic_fluid_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_fluid_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_fluid_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                local fluidbox_index = data.fluidbox_index
                local fb = entity.fluidbox

                local fb_data = fb[fluidbox_index] or {name = data.item, amount = 0}
                fb_data.amount = fb_data.amount + fcount
                fb[fluidbox_index] = fb_data

                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_fluid_crafters.index = index
end

local function tick()
    do_refill_turrets()
    do_magic_crafters()
    do_magic_fluid_crafters()
end

Public.deactivate_callback =
    Token.register(
    function(entity)
        entity.active = false
        entity.operable = false
        entity.destructible = false
    end
)

Public.neutral_force =
    Token.register(
    function(entity)
        entity.force = 'neutral'
    end
)

Public.enemy_force =
    Token.register(
    function(entity)
        entity.force = 'enemy'
    end
)

Public.active_not_destructible_callback =
    Token.register(
    function(entity)
        entity.active = true
        entity.operable = false
        entity.destructible = false
    end
)

Public.disable_minable_callback =
    Token.register(
    function(entity)
        entity.minable = false
    end
)

Public.disable_minable_and_ICW_callback =
    Token.register(
    function(entity)
        entity.minable = false
        local wagon = ICW.register_wagon(entity, true)
        wagon.entity_count = 999
    end
)

Public.disable_destructible_callback =
    Token.register(
    function(entity)
        entity.destructible = false
    end
)
Public.disable_active_callback =
    Token.register(
    function(entity)
        entity.active = false
    end
)

Public.refill_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = WPT.get('refill_turrets')
        local callback_data = data.callback_data
        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.refill_liquid_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = WPT.get('refill_turrets')
        local callback_data = data.callback_data
        callback_data.liquid = true

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.power_source_callback =
    Token.register(
    function(turret, data)
        local power_sources = WPT.get('power_sources')
        local callback_data = data.callback_data

        local power_source =
            turret.surface.create_entity {name = 'hidden-electric-energy-interface', position = turret.position}
        power_source.electric_buffer_size = callback_data.buffer_size
        power_source.power_production = callback_data.power_production
        power_source.destructible = false
        local power_pole =
            turret.surface.create_entity {
            name = 'crash-site-electric-pole',
            position = {x = turret.position.x, y = turret.position.y}
        }
        power_pole.destructible = false
        power_pole.disconnect_neighbour()

        power_sources[turret.unit_number] = {entity = power_source, pole = power_pole}
    end
)

Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
Public.light_oil_ammo = {name = 'light-oil', amount = 100}
Public.artillery_shell_ammo = {name = 'artillery-shell', count = 15}
Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}

Event.on_nth_tick(20, tick)
--Event.add(defines.events.on_tick, tick)
Event.add(defines.events.on_entity_died, turret_died)

return Public
