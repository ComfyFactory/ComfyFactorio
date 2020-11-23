local Token = require 'utils.token'
local Task = require 'utils.task'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Event = require 'utils.event'
local Global = require 'utils.global'

local this = {
    power_sources = {index = 1},
    refill_turrets = {index = 1},
    magic_crafters = {index = 1},
    magic_fluid_crafters = {index = 1},
    art_table = {index = 1},
    surface_cleared = false
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}
local random = math.random
local floor = math.floor
local sqrt = math.sqrt
local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8

local artillery_target_entities = {
    'character',
    'tank',
    'car',
    'furnace',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon'
}

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
    local refill_turrets = this.refill_turrets
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
    local power_sources = this.power_sources

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
    local magic_crafters = this.magic_crafters
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

            if fcount > 1 then
                fcount = 1
            end

            if fcount > 0 then
                entity.get_output_inventory().insert {name = data.item, count = fcount}
                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local magic_fluid_crafters = this.magic_fluid_crafters
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

local artillery_target_callback =
    Token.register(
    function(data)
        local position = data.position
        local entity = data.entity

        if not entity.valid then
            return
        end

        local tx, ty = position.x, position.y

        local pos = entity.position
        local x, y = pos.x, pos.y
        local dx, dy = tx - x, ty - y
        local d = dx * dx + dy * dy
        if d >= 1024 and d <= 441398 then -- 704 in depth~
            entity.surface.create_entity {
                name = 'artillery-projectile',
                position = position,
                target = entity,
                force = 'enemy',
                speed = 1.5
            }
        end
    end
)

local function do_artillery_turrets_targets()
    local art_table = this.art_table
    local index = art_table.index

    if index > #art_table then
        art_table.index = 1
        return
    end

    art_table.index = index + 1

    local outpost = art_table[index]

    local now = game.tick
    if now - outpost.last_fire_tick < 480 then
        return
    end

    local turrets = outpost.artillery_turrets
    for i = #turrets, 1, -1 do
        local turret = turrets[i]
        if not turret.valid then
            fast_remove(turrets, i)
        end
    end

    local count = #turrets
    if count == 0 then
        fast_remove(art_table, index)
        return
    end

    outpost.last_fire_tick = now

    local turret = turrets[1]
    local area = outpost.artillery_area
    local surface = turret.surface

    local entities = surface.find_entities_filtered {area = area, name = artillery_target_entities}

    if #entities == 0 then
        return
    end

    local position = turret.position

    for i = 1, count do
        local entity = entities[random(#entities)]
        if entity and entity.valid then
            local data = {position = position, entity = entity}
            Task.set_timeout_in_ticks(i * 60, artillery_target_callback, data)
        end
    end
end

local function add_magic_crafter_output(entity, output, distance)
    local magic_fluid_crafters = this.magic_fluid_crafters
    local magic_crafters = this.magic_crafters
    local rate = output.min_rate + output.distance_factor * distance

    local fluidbox_index = output.fluidbox_index
    local data = {
        entity = entity,
        last_tick = game.tick,
        base_rate = rate,
        rate = rate,
        item = output.item,
        fluidbox_index = fluidbox_index
    }

    if fluidbox_index then
        magic_fluid_crafters[#magic_fluid_crafters + 1] = data
    else
        magic_crafters[#magic_crafters + 1] = data
    end
end

local function tick()
    do_refill_turrets()
    do_magic_crafters()
    do_magic_fluid_crafters()
    do_artillery_turrets_targets()
end

Public.deactivate_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.neutral_force =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'neutral'
        end
    end
)

Public.enemy_force =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'enemy'
        end
    end
)

Public.active_not_destructible_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = true
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.disable_minable_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
        end
    end
)

Public.disable_minable_and_ICW_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
            ICW.register_wagon(entity, true)
        end
    end
)

Public.disable_destructible_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.destructible = false
            entity.minable = false
        end
    end
)
Public.disable_active_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
        end
    end
)

local disable_active_callback = Public.disable_active_callback

Public.refill_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local callback_data = data.callback_data
        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.refill_artillery_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local art_table = this.art_table
        local index = art_table.index

        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = data.callback_data}

        local artillery_data = art_table[index]
        if not artillery_data then
            artillery_data = {}
        end

        local artillery_turrets = artillery_data.artillery_turrets
        if not artillery_turrets then
            artillery_turrets = {}
            artillery_data.artillery_turrets = artillery_turrets

            local pos = turret.position
            local x, y = pos.x, pos.y
            artillery_data.artillery_area = {{x - 112, y}, {x + 112, y + 212}}
            artillery_data.last_fire_tick = 0

            art_table[#art_table + 1] = artillery_data
        end

        artillery_turrets[#artillery_turrets + 1] = turret
    end
)

Public.refill_liquid_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local callback_data = data.callback_data
        callback_data.liquid = true

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.power_source_callback =
    Token.register(
    function(turret, data)
        local power_sources = this.power_sources
        local callback_data = data.callback_data

        local power_source = turret.surface.create_entity {name = 'hidden-electric-energy-interface', position = turret.position}
        power_source.electric_buffer_size = callback_data.buffer_size
        power_source.power_production = callback_data.power_production
        power_source.destructible = false
        local power_pole =
            turret.surface.create_entity {
            name = 'small-electric-pole',
            position = {x = turret.position.x, y = turret.position.y}
        }
        power_pole.destructible = false
        power_pole.disconnect_neighbour()

        power_sources[turret.unit_number] = {entity = power_source, pole = power_pole}
    end
)

Public.magic_item_crafting_callback =
    Token.register(
    function(entity, data)
        local callback_data = data.callback_data

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local recipe = callback_data.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = callback_data.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = callback_data.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for i = 1, #output do
                local o = output[i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

Public.magic_item_crafting_callback_weighted =
    Token.register(
    function(entity, data)
        local callback_data = data.callback_data

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local weights = callback_data.weights
        local loot = callback_data.loot

        local p = entity.position

        local i = random() * weights.total

        local index = table.binary_search(weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local stack = loot[index].stack
        if not stack then
            return
        end

        local recipe = stack.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = stack.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = stack.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for o_i = 1, #output do
                local o = output[o_i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

function Public.prepare_weighted_loot(loot)
    local total = 0
    local weights = {}

    for i = 1, #loot do
        local v = loot[i]
        total = total + v.weight
        weights[#weights + 1] = total
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    --entity.destructible = false

    local i = random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.insert {name = stack.name, count = count}
end

Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
Public.light_oil_ammo = {name = 'light-oil', amount = 100}
Public.artillery_shell_ammo = {name = 'artillery-shell', count = 15}
Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}

function Public.reset_table()
    this.power_sources = {index = 1}
    this.refill_turrets = {index = 1}
    this.magic_crafters = {index = 1}
    this.magic_fluid_crafters = {index = 1}
end

Event.on_nth_tick(10, tick)
--Event.add(defines.events.on_tick, tick)
Event.add(defines.events.on_entity_died, turret_died)

return Public
