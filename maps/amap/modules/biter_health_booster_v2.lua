-- Biters, Spawners and Worms gain additional health / resistance -- mewmew
-- modified by Gerkiz
-- Use this.biter_health_boost or this.biter_health_boost_forces to modify their health.
-- 1 = vanilla health, 2 = 200% vanilla health
-- do not use values below 1

local Event = require 'utils.event'
local Global = require 'utils.global'
local Token = require 'utils.token'

local floor = math.floor
local round = math.round
local Public = {}

local this = {
    biter_health_boost = 1,
    car_health_boost=1,
    player_biter_health_boost=1,
    player_biter_resist=1,
    player_build_health_boost=1,
    car_resist=1,
    player_build_resist=1,
    biter_health_boost_forced = false,
    biter_health_boost_forces = {},
    biter_health_boost_units = {},
    biter_health_boost_count = 0,
    make_normal_unit_mini_bosses = true,
    active_surface = 'nauvis',
    active_surfaces = {},
    acid_lines_delay = {},
    acid_nova = false,
    boss_spawns_projectiles = false,
    enable_boss_loot = false
}




Global.register(
    this,
    function(t)
        this = t
    end
)


local biter_types={
    ['unit'] = true,
    ['unit-spawner'] = true,
    ['combat-robot']=true
}

local enemy_build_types = {
    ['roboport']=true,
    ['wall'] = true,
    ['ammo-turret'] = true,
    ['turret'] = true,
    ['fluid-turret'] = true,
    ['artillery-turret'] = true,
    ['electric-turret'] = true
}

local player_build_types = {
  ['wall'] = true,
  ['ammo-turret'] = true,
    ['fluid-turret'] = true,
        ['electric-turret'] = true
}

local car_types = {
  ['car'] = true,
  ['tank'] = true,
  ['spidertron'] = true,
  ['spider-vehicle'] = true
  --['unit-spawner'] = true
}


local function clear_unit_from_tbl(unit_number)
    if this.biter_health_boost_units[unit_number] then
        this.biter_health_boost_units[unit_number] = nil
    end
end


local function clean_table()

        this.biter_health_boost_units={}
end

local function check_clear_table()
    this.biter_health_boost_count = this.biter_health_boost_count + 1
    if this.biter_health_boost_count >= 1000 then
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


local function on_entity_damaged(event)
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    local health_boost = 1
    local resist=1
    local biter = false
    local biter_build = false
  --  game.print(entity.type)
    if enemy_build_types[entity.type] and entity.force ~=game.forces.player then
    health_boost=this.biter_health_boost
        biter_build=true
    if health_boost==1 then
      return
    else
      goto workflow
    end

    end

    if biter_types[entity.type] and entity.force ==game.forces.enemy then
       health_boost=this.biter_health_boost
        biter=true
       if health_boost==1 then
         return
       else
         goto workflow
       end

    end

    if biter_types[entity.type] and entity.force ==game.forces.player then
       health_boost=this.player_biter_health_boost
          biter=true
       if health_boost==1 then
         return
       else
         goto workflow
       end
       resist=this.player_biter_resist

    end

    if car_types[entity.type] and entity.force ==game.forces.player then
       health_boost=this.car_health_boost
         resist=this.car_resist
       if health_boost==1 then
         return
       else
         goto workflow
       end

    end

    if player_build_types[entity.type] and entity.force ==game.forces.player then
       health_boost=this.player_build_health_boost
         resist=this.player_build_resist
       if health_boost==1 then
         return
       else
         goto workflow
       end

    end


    if health_boost==1 then return end
::workflow::

    local biter_health_boost_units = this.biter_health_boost_units

    local unit_number = entity.unit_number

    --Create new health pool
    local health_pool = biter_health_boost_units[unit_number]
    if not health_pool then
        Public.add_unit(entity, health_boost)
        health_pool = this.biter_health_boost_units[unit_number]
    end

    if not health_pool then
        return
    end

    --Process boss unit health bars
    local boss = health_pool[3]
    if boss then
        if boss.last_update + 10 < game.tick then
            set_boss_healthbar(health_pool[1], boss.max_health, boss.healthbar_id)
            boss.last_update = game.tick
        end
    end
    if biter_build then
     resist= health_pool[2]
    end

    if biter then
    health_pool[1] = health_pool[1] - event.final_damage_amount
    entity.health = health_pool[1] * health_pool[2]
  else
      if  entity.health>event.final_damage_amount then
      entity.health=entity.health+event.final_damage_amount
      health_pool[1] =floor(entity.health/resist)-- -event.final_damage_amount*health_pool[2]-health_pool[2]
      health_pool[1] = health_pool[1] - event.final_damage_amount
      entity.health = health_pool[1] * resist
    end
  end
    --Set entity health relative to health pool

    --Proceed to kill entity if health is 0
    if entity.health > 0 then
        return
    end
   local cause = event.cause
    if cause then
        if cause.valid then
            event.entity.die(cause.force, cause)
            return
        end
    end
    entity.die(entity.force)
end

--- Use this function to retrieve a key from the global table.
---@param key <string>
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Using this function can set a new value to an exist key or create a new key with value
---@param key <string>
---@param value <string/boolean>
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
  this.car_health_boost=1
  this.player_biter_health_boost=1
  this.player_biter_resist=1
  this.player_build_health_boost=1
  this.car_resist=1
  this.player_build_resist=1
  this.biter_health_boost_forced = false
  this.biter_health_boost_forces = {}
  this.biter_health_boost_units = {}
  this.biter_health_boost_count = 0
  this.make_normal_unit_mini_bosses = true
  this.active_surface = 'nauvis'
  this.active_surfaces = {}
  this.acid_lines_delay = {}
  this.acid_nova = false
  this.boss_spawns_projectiles = false
  this.enable_boss_loot = false
end

--- Use this function to add a new unit that has extra health
---@param unit <LuaEntity>
---@param health_multiplier <number>
function Public.add_unit(unit, health_multiplier)
    if not health_multiplier then
        health_multiplier = this.biter_health_boost
    end
    local xp_modifier = round(1 / health_multiplier, 5)
    this.biter_health_boost_units[unit.unit_number] = {
        floor(unit.prototype.max_health * health_multiplier),
        xp_modifier
    }

    check_clear_table()
end

--- Use this function to add a new boss unit (with healthbar)
---@param unit <LuaEntity>
---@param health_multiplier <number>
---@param health_bar_size <number>
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
        {max_health = health, healthbar_id = create_boss_healthbar(unit, health_bar_size), last_update = game.tick}
    }

    check_clear_table()
end

--- This sets the active surface that we check and have the script active.
--- This deletes the list of surfaces if we use multiple, so use it only before setting more of them.
---@param string
function Public.set_active_surface(str)
    if str and type(str) == 'string' then
        this.active_surfaces = {}
        this.active_surface = str
    end
    return this.active_surface
end

--- This sets if this surface is active, when we using multiple surfaces. The default active surface does not need to be added again
---@param string, boolean
function Public.set_surface_activity(name, value)
    if name and type(name) == 'string' and type(value) == 'boolean' then
        this.active_surfaces[name] = value
    end
    return this.active_surfaces
end


--- Enables that we clear units from the global table when a unit dies.
---@param boolean
function Public.check_on_entity_died(boolean)
    this.check_on_entity_died = boolean or false
    return this.check_on_entity_died
end

--- Enables that biter bosses (units with health bars) spawns projectiles on death.
---@param boolean
--- Forces a value of biter_health_boost

--- Enables that normal units have boosted health.
---@param boolean

Event.on_init(
    function()
        Public.reset_table()
    end
)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.on_nth_tick(7200, check_clear_table)
--Event.add(defines.events.on_entity_died, on_entity_died)

return Public
