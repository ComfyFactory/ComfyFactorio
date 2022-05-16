-- Biters, Spawners and Worms gain additional health / resistance -- mewmew
-- modified by Gerkiz
-- Use this.biter_health_boost or this.biter_health_boost_forces to modify their health.
-- 1 = vanilla health, 2 = 200% vanilla health
-- do not use values below 1

local Event = require 'utils.event'
local LootDrop = require 'modules.mobs_drop_loot'
local WD = require 'modules.wave_defense.table'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'

local floor = math.floor
local insert = table.insert
local random = math.random
local sqrt = math.sqrt
local round = math.round
local Public = {}

local this = {
    biter_health_boost = 1,
    biter_health_boost_forced = false,
    biter_health_boost_forces = {},
    biter_health_boost_units = {},
    biter_health_boost_count = 0,
    make_normal_unit_mini_bosses = false,
    active_surface = 'nauvis',
    active_surfaces = {},
    acid_lines_delay = {},
    acid_nova = false,
    boss_spawns_projectiles = false,
    enable_boss_loot = false,
    randomize_stun_and_slowdown_sticker = false
}

local radius = 6
local targets = {}
local acid_splashes = {
    ['big-biter'] = 'acid-stream-worm-medium',
    ['behemoth-biter'] = 'acid-stream-worm-big'
}
local acid_lines = {
    ['small-spitter'] = 'acid-stream-spitter-small',
    ['medium-spitter'] = 'acid-stream-spitter-medium',
    ['big-spitter'] = 'acid-stream-spitter-big',
    ['behemoth-spitter'] = 'acid-stream-spitter-big'
}
for x = radius * -1, radius, 1 do
    for y = radius * -1, radius, 1 do
        if sqrt(x ^ 2 + y ^ 2) <= radius then
            targets[#targets + 1] = {x = x, y = y}
        end
    end
end

local projectiles = {
    'slowdown-capsule',
    'defender-capsule',
    'destroyer-capsule',
    'laser',
    'distractor-capsule',
    'rocket',
    'explosive-rocket',
    'grenade',
    'rocket',
    'grenade'
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local filters = {
    {filter = 'name', name = 'unit'},
    {filter = 'name', name = 'turret'},
    {filter = 'name', name = 'ammo-turret'},
    {filter = 'name', name = 'electric-turret'},
    {filter = 'name', name = 'unit-spawner'}
}

local entity_types = {
    ['unit'] = true,
    ['turret'] = true,
    ['ammo-turret'] = true,
    ['electric-turret'] = true,
    ['unit-spawner'] = true
}

local function clear_unit_from_tbl(unit_number)
    if this.biter_health_boost_units[unit_number] then
        this.biter_health_boost_units[unit_number] = nil
    end
end

local removeUnit =
    Token.register(
    function(data)
        local unit_number = data.unit_number
        clear_unit_from_tbl(unit_number)
    end
)

local function loaded_biters(event)
    local cause = event.cause
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local position = false
    if cause then
        if cause.valid then
            position = cause.position
        end
    end
    if not position then
        position = {entity.position.x + (-20 + random(0, 40)), entity.position.y + (-20 + random(0, 40))}
    end

    entity.surface.create_entity(
        {
            name = projectiles[random(1, 10)],
            position = entity.position,
            force = 'enemy',
            source = entity.position,
            target = position,
            max_range = 16,
            speed = 0.01
        }
    )
end

local function acid_nova(event)
    for _ = 1, random(20, 40) do
        local i = random(1, #targets)
        event.entity.surface.create_entity(
            {
                name = acid_splashes[event.entity.name],
                position = event.entity.position,
                force = event.entity.force.name,
                source = event.entity.position,
                target = {x = event.entity.position.x + targets[i].x, y = event.entity.position.y + targets[i].y},
                max_range = radius,
                speed = 0.001
            }
        )
    end
end

local function create_entity_radius(surface, name, source, target)
    local distance = sqrt((source.x - target.x) ^ 2 + (source.y - target.y) ^ 2)
    local modifier = {(target.x - source.x) / distance, (target.y - source.y) / distance}

    local position = {source.x, source.y}

    for _ = 1, distance * 1.5, 1 do
        if random(1, 2) ~= 1 then
            surface.create_entity(
                {
                    name = name,
                    position = source,
                    force = 'enemy',
                    source = source,
                    target = position,
                    max_range = 25,
                    speed = 1
                }
            )
        end
        position = {position[1] + modifier[1], position[2] + modifier[2]}
    end
end

local function clean_table()
    local units_to_delete = {}

    --Mark all health boost entries for deletion
    for key, _ in pairs(this.biter_health_boost_units) do
        units_to_delete[key] = true
    end

    --Remove valid health boost entries from deletion
    local validTypes = {}
    for k, v in pairs(entity_types) do
        if v then
            insert(validTypes, k)
        end
    end

    for name, enabled in pairs(this.active_surfaces) do
        local surface = game.surfaces[name]
        if surface and surface.valid and enabled then
            for _, unit in pairs(surface.find_entities_filtered({type = validTypes})) do
                units_to_delete[unit.unit_number] = nil
            end
        end
    end

    local surface = game.surfaces[this.active_surface]
    if not (surface and surface.valid) then
        return
    end

    for _, unit in pairs(surface.find_entities_filtered({type = validTypes})) do
        units_to_delete[unit.unit_number] = nil
    end

    --Remove abandoned health boost entries
    for key, _ in pairs(units_to_delete) do
        this.biter_health_boost_units[key] = nil
    end
end

local function check_clear_table()
    this.biter_health_boost_count = this.biter_health_boost_count + 1
    if this.biter_health_boost_count >= 500 then
        clean_table()
        this.biter_health_boost_count = 0
    end
end

local function create_boss_healthbar(entity, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = {0, 200, 0},
            x_scale = size * 15,
            y_scale = size,
            render_layer = 'light-effect',
            target = entity,
            target_offset = {0, -2.5},
            surface = entity.surface
        }
    )
end

local function set_boss_healthbar(health, max_health, healthbar_id)
    local m = health / max_health
    local x_scale = rendering.get_y_scale(healthbar_id) * 15
    rendering.set_x_scale(healthbar_id, x_scale * m)
    rendering.set_color(healthbar_id, {floor(255 - 255 * m), floor(200 * m), 0})
end

local function extra_projectiles(cause, target)
    if not cause or not cause.valid then
        return
    end
    local biter_health_boost_units = this.biter_health_boost_units
    local cause_unit_number = cause.unit_number
    local cause_health_pool = biter_health_boost_units[cause_unit_number]
    if cause_health_pool and cause_health_pool[3] and cause_health_pool[3].healthbar_id and entity_types[cause.type] then
        if this.acid_nova then
            if acid_lines[cause.name] then
                if not this.acid_lines_delay[cause_unit_number] then
                    this.acid_lines_delay[cause_unit_number] = 0
                end
                if this.acid_lines_delay[cause_unit_number] < game.tick then
                    create_entity_radius(cause.surface, acid_lines[cause.name], cause.position, target.position)
                    this.acid_lines_delay[cause_unit_number] = game.tick + 180
                end
            end
        end
    end
end

local function on_entity_damaged(event)
    local biter = event.entity
    if not (biter and biter.valid) then
        return
    end
    local surface = biter.surface
    local cause = event.cause

    local biter_health_boost_units = this.biter_health_boost_units

    local unit_number = biter.unit_number

    local damage = event.final_damage_amount

    --Create new health pool
    local health_pool = biter_health_boost_units[unit_number]
    extra_projectiles(cause, biter)

    if not entity_types[biter.type] then
        return
    end

    if this.randomize_stun_and_slowdown_sticker then
        local damage_type = event.damage_type
        if damage_type and damage_type.name == 'electric' then
            local stickers = biter.stickers
            if stickers and #stickers > 0 then
                for i = 1, #stickers, 1 do
                    if random(1, 4) == 1 then -- there's a % that biters can recover from stun and get slowed instead.
                        if stickers[i].sticked_to == biter then
                            if stickers[i].name == 'stun-sticker' then
                                stickers[i].destroy()
                                if random(1, 2) == 1 then
                                    local slow = surface.create_entity {name = 'slowdown-sticker', position = biter.position, target = biter}
                                    slow.time_to_live = 200
                                end
                                break
                            elseif stickers[i].name == 'slowdown-sticker' then
                                stickers[i].destroy()
                            end
                        end
                    end
                end
            end
        end
    end

    if not health_pool and this.make_normal_unit_mini_bosses then
        if this.biter_health_boost_forces[biter.force.index] then
            Public.add_unit(biter, this.biter_health_boost_forces[biter.force.index])
        else
            Public.add_unit(biter, this.biter_health_boost)
        end
        health_pool = this.biter_health_boost_units[unit_number]
    end

    if not health_pool then
        return
    end

    --Process boss unit health bars
    local boss = health_pool[3]
    if boss and boss.healthbar_id then
        set_boss_healthbar(health_pool[1], boss.max_health, boss.healthbar_id)
    end

    --Reduce health pool
    health_pool[1] = round(health_pool[1] - damage)

    --Set entity health relative to health pool
    local max_health = health_pool[3].max_health
    local m = health_pool[1] / max_health
    local final_health = round(biter.prototype.max_health * m)
    biter.health = final_health

    --Proceed to kill entity if health is 0
    if biter.health > 0 and health_pool[1] > 0 then
        return
    end

    if cause then
        if cause.valid then
            event.entity.die(cause.force, cause)
            return
        end
    end
    biter.die(biter.force)
end

local function on_entity_died(event)
    if not this.check_on_entity_died then
        return
    end

    local biter = event.entity
    if not (biter and biter.valid) then
        return
    end
    if not entity_types[biter.type] then
        return
    end

    local biter_health_boost_units = this.biter_health_boost_units

    local unit_number = biter.unit_number
    local health_pool = biter_health_boost_units[unit_number]
    local wave_count = WD.get_wave()

    if health_pool then
        Task.set_timeout_in_ticks(30, removeUnit, {unit_number = unit_number})
        if health_pool[3] and health_pool[3].healthbar_id then
            if this.enable_boss_loot then
                if random(1, 128) == 1 then
                    LootDrop.drop_loot(biter, wave_count)
                end
            end
            if this.boss_spawns_projectiles then
                if random(1, 32) == 1 then
                    loaded_biters(event)
                end
            end
            if this.acid_nova then
                if acid_splashes[biter.name] then
                    acid_nova(event)
                end
                if this.acid_lines_delay[biter.unit_number] then
                    this.acid_lines_delay[biter.unit_number] = nil
                end
            end
        end
    end
end

--- Use this function to retrieve a key from the global table.
---@param key string
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Using this function can set a new value to an exist key or create a new key with value
---@param key string
---@param value any
function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

--- Use this function to reset the global table to it's init values.
function Public.reset_table()
    this.biter_health_boost = 1
    this.biter_health_boost_forces = false
    this.biter_health_boost_forces = {}
    this.biter_health_boost_units = {}
    this.biter_health_boost_count = 0
    this.make_normal_unit_mini_bosses = false
    this.active_surface = 'nauvis'
    this.active_surfaces = {}
    this.check_on_entity_died = false
    this.acid_lines_delay = {}
    this.acid_nova = false
    this.boss_spawns_projectiles = false
    this.enable_boss_loot = false
end

--- Use this function to add a new unit that has extra health
---@param unit userdata
---@param health_multiplier number
function Public.add_unit(unit, health_multiplier)
    if not health_multiplier then
        health_multiplier = this.biter_health_boost
    end
    local health = floor(unit.prototype.max_health * health_multiplier)
    local xp_modifier = round(1 / health_multiplier, 5)
    this.biter_health_boost_units[unit.unit_number] = {
        health,
        xp_modifier,
        {max_health = health}
    }

    check_clear_table()
end

--- Use this function to add a new boss unit (with healthbar)
---@param unit userdata
---@param health_multiplier number
---@param health_bar_size number
function Public.add_boss_unit(unit, health_multiplier, health_bar_size)
    if not health_multiplier then
        health_multiplier = this.biter_health_boost
    end
    if not health_bar_size then
        health_bar_size = 0.5
    end
    local xp_modifier = round(1 / health_multiplier, 5)
    local health = floor(unit.prototype.max_health * health_multiplier)
    this.biter_health_boost_units[unit.unit_number] = {
        health,
        xp_modifier,
        {max_health = health, healthbar_id = create_boss_healthbar(unit, health_bar_size)}
    }

    check_clear_table()
end

--- This sets the active surface that we check and have the script active.
--- This deletes the list of surfaces if we use multiple, so use it only before setting more of them.
---@param str string
function Public.set_active_surface(str)
    if str and type(str) == 'string' then
        this.active_surfaces = {}
        this.active_surface = str or 'nauvis'
    end
    return this.active_surface
end

--- This sets if this surface is active, when we using multiple surfaces. The default active surface does not need to be added again
---@param name string
---@param value boolean
function Public.set_surface_activity(name, value)
    if name and type(name) == 'string' and type(value) == 'boolean' then
        this.active_surfaces[name] = value
    end
    return this.active_surfaces
end

--- Enables that biter bosses (units with health bars) spawns acid on death.
---@param boolean
function Public.acid_nova(boolean)
    this.acid_nova = boolean or false
    return this.acid_nova
end

--- Enables that we clear units from the global table when a unit dies.
---@param boolean
function Public.check_on_entity_died(boolean)
    this.check_on_entity_died = boolean or false
    return this.check_on_entity_died
end

--- Enables that biter bosses (units with health bars) spawns projectiles on death.
---@param boolean
function Public.boss_spawns_projectiles(boolean)
    this.boss_spawns_projectiles = boolean or false

    return this.boss_spawns_projectiles
end

--- Enables that biter bosses (units with health bars) drops loot.
---@param boolean
function Public.enable_boss_loot(boolean)
    this.enable_boss_loot = boolean or false

    return this.enable_boss_loot
end

--- Forces a value of biter_health_boost
---@param boolean
function Public.enable_biter_health_boost_forced(boolean)
    this.biter_health_boost_forced = boolean or false

    return this.biter_health_boost_forced
end

--- Enables that normal units have boosted health.
---@param boolean
function Public.enable_make_normal_unit_mini_bosses(boolean)
    this.make_normal_unit_mini_bosses = boolean or false

    return this.make_normal_unit_mini_bosses
end

--- Enables that enemies can recover from stun randomly.
---@param boolean
function Public.enable_randomize_stun_and_slowdown_sticker(boolean)
    this.randomize_stun_and_slowdown_sticker = boolean or false

    return this.randomize_stun_and_slowdown_sticker
end

Event.on_init(
    function()
        Public.reset_table()
    end
)

Event.add(defines.events.on_entity_damaged, on_entity_damaged, filters)
Event.on_nth_tick(7200, check_clear_table)
Event.add(defines.events.on_entity_died, on_entity_died, filters)

return Public
