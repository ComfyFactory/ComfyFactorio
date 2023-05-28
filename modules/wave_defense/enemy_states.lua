-- track state of units by Gerkiz
local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Public = require 'modules.wave_defense.table'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Beams = require 'modules.render_beam'

local de = defines.events
local ev = Public.events
local random = math.random
local abs = math.abs
local floor = math.floor
local set_timeout_in_ticks = Task.set_timeout_in_ticks
local deepcopy = table.deepcopy

local this = {
    states = {},
    state_count = 0,
    settings = {
        frenzy_length = 3600,
        frenzy_burst_length = 160,
        update_rate = 60,
        enabled = false
    },
    target_settings = {}
}

Public._esp = {}

Global.register(
    this,
    function(tbl)
        this = tbl
        for _, state in pairs(this.states) do
            setmetatable(state, {__index = Public._esp})
        end
    end
)

local projectiles = {
    'slowdown-capsule',
    'defender-capsule',
    'slowdown-capsule',
    'destroyer-capsule',
    'distractor-capsule',
    'slowdown-capsule',
    'rocket',
    'slowdown-capsule',
    'explosive-rocket',
    'grenade',
    'rocket',
    'grenade'
}

local tiers = {
    ['small-biter'] = 'medium-biter',
    ['medium-biter'] = 'big-biter',
    ['big-biter'] = 'behemoth-biter',
    ['behemoth-biter'] = 'behemoth-biter',
    ['small-spitter'] = 'medium-spitter',
    ['medium-spitter'] = 'big-spitter',
    ['big-spitter'] = 'behemoth-spitter',
    ['behemoth-spitter'] = 'behemoth-spitter'
}

local tier_damage = {
    ['small-biter'] = {min = 25, max = 50},
    ['medium-biter'] = {min = 50, max = 100},
    ['big-biter'] = {min = 75, max = 150},
    ['behemoth-biter'] = {min = 100, max = 200},
    ['small-spitter'] = {min = 25, max = 50},
    ['medium-spitter'] = {min = 50, max = 100},
    ['big-spitter'] = {min = 75, max = 150},
    ['behemoth-spitter'] = {min = 100, max = 200}
}

--- A token to register tasks that entities are given
local work_token
work_token =
    Token.register(
    function(event)
        if not event then
            return
        end

        local state = Public.get_unit(event.unit_number)
        local tick = game.tick
        if not state then
            return
        end

        if state:validate() then
            state:work(tick)

            set_timeout_in_ticks(this.settings.update_rate, work_token, event)
        else
            state:remove()
        end
    end
)

--- Restores a given entity to their original force
local restore_force_token =
    Token.register(
    function(event)
        if not event then
            return
        end
        local force_name = event.force_name
        if not force_name then
            return
        end

        local state = Public.get_unit(event.unit_number)
        if state then
            state:set_force()
            state.frenzied = false
        end
    end
)

local function is_closer(pos1, pos2, pos)
    return ((pos1.x - pos.x) ^ 2 + (pos1.y - pos.y) ^ 2) < ((pos2.x - pos.x) ^ 2 + (pos2.y - pos.y) ^ 2)
end

local function shuffle_distance(tbl, position)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        if is_closer(tbl[i].position, tbl[rand].position, position) and i > rand then
            tbl[i], tbl[rand] = tbl[rand], tbl[i]
        end
    end
    return tbl
end

local function aoe_punch(entity, target, damage)
    if not (target and target.valid) then
        return
    end

    local base_vector = {target.position.x - entity.position.x, target.position.y - entity.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 1000
    vector[2] = vector[2] * 1000

    if abs(vector[1]) > abs(vector[2]) then
        local d = abs(vector[1])
        if abs(vector[1]) > 0 then
            vector[1] = vector[1] / d
        end
        if abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
    else
        local d = abs(vector[2])
        if abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
        if abs(vector[1]) > 0 and d > 0 then
            vector[1] = vector[1] / d
        end
    end

    vector[1] = vector[1] * 1.5
    vector[2] = vector[2] * 1.5

    local a = 0.20

    local cs = entity.surface
    local cp = entity.position

    local valid_enemy_forces = Public.get('valid_enemy_forces')

    for i = 1, 16, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {cp.x + x + vector[1] * i, cp.y + y + vector[2] * i}
                cs.create_trivial_smoke({name = 'train-smoke', position = p})
                for _, e in pairs(cs.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable and not valid_enemy_forces[e.force.name] then
                                if e.force.index ~= entity.force.index then
                                    if e.valid then
                                        e.health = e.health - damage * 0.05
                                        if e.health <= 0 then
                                            e.die(e.force.name, entity)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function do_projectile(surface, name, _position, _force, target, max_range)
    surface.create_entity(
        {
            name = name,
            position = _position,
            force = _force,
            source = _position,
            target = target or nil,
            max_range = max_range or nil,
            speed = 0.4,
            fast_replace = true,
            create_build_effect_smoke = false
        }
    )
    return true
end

local function area_of_effect(entity, radius, callback, find_entities)
    if not radius then
        return
    end

    local function get_area(pos, dist)
        local area = {
            left_top = {
                x = pos.x - dist,
                y = pos.y - dist
            },
            right_bottom = {
                x = pos.x + dist,
                y = pos.y + dist
            }
        }
        return area
    end

    local cs = entity.surface
    local cp = entity.position

    if radius and radius > 256 then
        radius = 256
    end

    local area = get_area(cp, radius)

    for x = area.left_top.x, area.right_bottom.x, 1 do
        for y = area.left_top.y, area.right_bottom.y, 1 do
            local d = floor((cp.x - x) ^ 2 + (cp.y - y) ^ 2)
            if d < radius then
                local p = {x = x, y = y}
                if find_entities then
                    for _, e in pairs(cs.find_entities({{p.x - 1, p.y - 1}, {p.x + 1, p.y + 1}})) do
                        if e and e.valid and e.name ~= 'character' and e.health and e.destructible then
                            callback(e, p)
                        end
                    end
                else
                    callback(p)
                end
                cs.create_trivial_smoke({name = 'fire-smoke', position = p})
            end
        end
    end
end

local function shoot_laser(surface, source, enemy)
    local force = source.force
    surface.create_entity {name = 'laser-beam', position = source.position, force = 'player', target = enemy, source = source, max_length = 32, duration = 60}
    enemy.damage(20 * (1 + force.get_ammo_damage_modifier('laser') + force.get_gun_speed_modifier('laser')), force, 'laser', source)
end

local function set_commands()
    local unit = this.target_settings.main_target
    if not unit or not unit.valid then
        return
    end

    local commands = {}

    if this.target_settings.last_set_target == 'main' then
        this.target_settings.last_set_target = 'random'
        commands[#commands + 1] = {
            type = defines.command.attack_area,
            destination = {x = unit.position.x, y = unit.position.y},
            radius = 15,
            distraction = defines.distraction.by_enemy
        }
        commands[#commands + 1] = {
            type = defines.command.build_base,
            destination = {x = unit.position.x, y = unit.position.y}
        }
        commands[#commands + 1] = {
            type = defines.command.attack_area,
            destination = {x = unit.position.x, y = unit.position.y},
            radius = 15,
            distraction = defines.distraction.by_enemy
        }
        commands[#commands + 1] = {
            type = defines.command.build_base,
            destination = {x = unit.position.x, y = unit.position.y}
        }
    else
        commands[#commands + 1] = {
            type = defines.command.attack,
            target = unit,
            distraction = defines.distraction.by_anything
        }
        commands[#commands + 1] = {
            type = defines.command.attack_area,
            destination = {x = unit.position.x, y = unit.position.y},
            radius = 15,
            distraction = defines.distraction.by_enemy
        }
        commands[#commands + 1] = {
            type = defines.command.build_base,
            destination = {x = unit.position.x, y = unit.position.y}
        }
        commands[#commands + 1] = {
            type = defines.command.attack,
            target = unit,
            distraction = defines.distraction.by_anything
        }
        commands[#commands + 1] = {
            type = defines.command.attack_area,
            destination = {x = unit.position.x, y = unit.position.y},
            radius = 15,
            distraction = defines.distraction.by_enemy
        }
        commands[#commands + 1] = {
            type = defines.command.build_base,
            destination = {x = unit.position.x, y = unit.position.y}
        }
        commands[#commands + 1] = {
            type = defines.command.attack,
            target = unit,
            distraction = defines.distraction.by_anything
        }
        this.target_settings.last_set_target = 'main'
    end

    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = commands
    }

    local surface = unit.surface

    surface.set_multi_command({command = command, unit_count = 5000, force = 'aggressors'})
    this.target_settings.commands = commands
end

local function set_forces()
    local aggressors = game.forces.aggressors
    local aggressors_frenzy = game.forces.aggressors_frenzy
    local enemy = game.forces.enemy
    if not aggressors then
        aggressors = game.create_force('aggressors')
    end
    if not aggressors_frenzy then
        aggressors_frenzy = game.create_force('aggressors_frenzy')
    end

    aggressors.set_friend('aggressors_frenzy', true)
    aggressors.set_cease_fire('aggressors_frenzy', true)
    aggressors.set_friend('enemy', true)
    aggressors.set_cease_fire('enemy', true)

    aggressors_frenzy.set_friend('aggressors', true)
    aggressors_frenzy.set_cease_fire('aggressors', true)
    aggressors_frenzy.set_friend('enemy', true)
    aggressors_frenzy.set_cease_fire('enemy', true)

    enemy.set_friend('aggressors', true)
    enemy.set_cease_fire('aggressors', true)
    enemy.set_friend('aggressors_frenzy', true)
    enemy.set_cease_fire('aggressors_frenzy', true)
end

local function on_init()
    this.states = {}
    this.state_count = 0
    this.settings.frenzy_length = 3600
    this.settings.frenzy_burst_length = 160
    this.settings.update_rate = 60
    this.target_settings = {}

    set_forces()
end

local function on_wave_created(event)
    if not this.settings.enabled then
        return
    end

    local wave_number = event.wave_number
    if not wave_number then
        return
    end

    this.settings.wave_number = wave_number

    if wave_number % 50 == 0 then
        local state = Public.get_any()
        if state then
            local old = state:get_melee_speed()
            state:set_attack_speed(old + 0.05)
        end
    elseif wave_number % 100 == 0 then
        Public.enemy_weapon_damage('aggressors')
        Public.enemy_weapon_damage('aggressors_frenzy')
    end
end

local function on_unit_group_created(event)
    if not this.settings.enabled then
        return
    end

    local unit_group = event.unit_group
    if not unit_group or not unit_group.valid then
        return
    end

    for _, entity in pairs(unit_group.members) do
        if not Public.get_unit(entity.unit_number) then
            local data = {
                entity = entity
            }
            local state = Public.new(data)
            state:set_burst_frenzy()
        end
    end
end

local function on_target_aquired(event)
    if not this.settings.enabled then
        return
    end

    local target = event.target
    if not target or not target.valid then
        return
    end

    if this.target_settings.main_target and this.target_settings.main_target.valid then
        if this.target_settings.main_target.unit_number ~= target.unit_number then
            this.target_settings.main_target = event.target
        end
    else
        this.target_settings.main_target = event.target
    end

    local tick = game.tick

    if not this.target_settings.last_set_commands then
        set_commands()
        this.target_settings.last_set_commands = tick + 200
        this.target_settings.last_set_target = 'main'
    end

    if tick > this.target_settings.last_set_commands then
        set_commands()
    end
end

local function on_entity_created(event)
    if not this.settings.enabled then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local state = Public.get_unit(entity.unit_number)

    if not state then
        local data = {
            entity = entity
        }
        state = Public.new(data)
        state:set_burst_frenzy()
        if event.boss_unit then
            state:set_boss()
        end
    else
        if event.boss_unit then
            state:set_boss()
        end
    end
end

local function on_evolution_factor_changed(event)
    if not this.settings.enabled then
        return
    end

    local evolution_factor = event.evolution_factor
    if not evolution_factor then
        return
    end

    local forces = game.forces

    forces.aggressors.evolution_factor = evolution_factor
    forces.aggressors_frenzy.evolution_factor = evolution_factor
end

local function on_entity_died(event)
    if not this.settings.enabled then
        return
    end

    local entity = event.entity
    if not entity.valid then
        return
    end

    local state = Public.get_unit(entity.unit_number)
    if state then
        state:remove()
    end
end

local function on_entity_damaged(event)
    if not this.settings.enabled then
        return
    end
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    local state = Public.get_unit(entity.unit_number)
    if not state then
        return
    end

    local max = entity.prototype.max_health

    if state.boss_unit then
        state:spawn_children()
    end

    if state.boss_unit and entity.health <= max / 2 and state.teleported < 5 then
        state.teleported = state.teleported + 1
        if random(1, 4) == 1 then
            state:switch_position()
        end
    end
end

--- Creates a new state for a boss unit.
---@param data table
---@return table
function Public.new(data)
    local state = setmetatable({}, {__index = Public._esp})
    local tick = game.tick
    state.entity = data.entity
    state.surface_id = state.entity.surface_index
    state.force = game.forces.aggressors
    state.unit_number = state.entity.unit_number
    state.teleported = 0
    state.id = state.entity.unit_number
    if data.delayed then
        state.delayed = tick + data.delayed
        state.ttl = data.ttl or (tick + data.delayed) + 7200 -- 2 minutes duration
    else
        state.ttl = data.ttl or tick + 3600 -- 1 minutes duration
        state:validate()
    end

    set_timeout_in_ticks(this.settings.update_rate, work_token, {unit_number = state.unit_number})

    this.states[state.id] = state
    this.state_count = this.state_count + 1

    return state
end

-- Adjusts the damage
function Public.enemy_weapon_damage(force)
    if not force then
        return
    end

    local e = game.forces[force]

    local data = {
        ['artillery-shell'] = 0.05,
        ['biological'] = 0.06,
        ['beam'] = 0.08,
        ['bullet'] = 0.08,
        ['capsule'] = 0.08,
        ['electric'] = 0.08,
        ['flamethrower'] = 0.08,
        ['laser'] = 0.08,
        ['landmine'] = 0.08,
        ['melee'] = 0.08
    }

    for k, v in pairs(data) do
        local new = Difficulty.get().value * v

        local e_old = e.get_ammo_damage_modifier(k)

        e.set_ammo_damage_modifier(k, new + e_old)
    end
end

-- Gets a given unit
--- @param unit_number number
---@return table|nil
function Public.get_unit(unit_number)
    return this.states[unit_number]
end

-- Gets a boss unit
---@return table|nil
function Public.get_boss_unit()
    for _, state in pairs(this.states) do
        if state and state.boss_unit then
            return state
        end
    end
end

-- Gets a first matched unit
---@return table|nil
function Public.get_any()
    for _, state in pairs(this.states) do
        if state then
            return state
        end
    end
end

-- Removes the given entity from tracking
function Public._esp:remove()
    this.states[self.id] = nil
    this.state_count = this.state_count - 1
end

-- Sets the entity force
function Public._esp:set_force()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    entity.force = game.forces.aggressors
    self.force = entity.force
end

-- Grants the unit a frenzy attack speed
function Public._esp:set_frenzy()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    if self.frenzied then
        return
    end

    self.frenzied = true

    entity.force = game.forces.aggressors_frenzy
    self.force = entity.force
end

-- Grants the unit a frenzy attack speed for a short time
function Public._esp:set_burst_frenzy()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    if self.frenzied then
        return
    end

    self.frenzied = true
    set_timeout_in_ticks(this.settings.frenzy_burst_length, restore_force_token, {force_name = self.force.name, unit_number = self.unit_number})

    entity.force = game.forces.aggressors_frenzy
    self.force = entity.force
end

-- Spawns biters that are one tier higher than the entity
function Public._esp:spawn_children()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local tier = tiers[entity.name]

    if not tier then
        return
    end

    local max = entity.prototype.max_health

    if entity.health <= max / 2 and not self.spawned_children then
        self.spawned_children = true
        Public.buried_biter(entity.surface, entity.position, 1, tier)
    end
end

-- Sets unit_group for the given unit if any
function Public._esp:unit_group(unit_group)
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    if not unit_group then
        return
    end

    self.unit_group = unit_group
end

--- Creates a beam.
function Public._esp:beam()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    Beams.new_beam_delayed(entity.surface, random(500, 3000))
end

--- Creates a laser.
function Public._esp:laser(boss)
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local limit = boss or 3

    local surface = entity.surface

    local enemies = surface.find_entities_filtered {radius = 10, limit = limit, force = 'player', position = entity.position}
    if enemies == nil or #enemies == 0 then
        return
    end
    for i = 1, #enemies, 1 do
        local enemy = enemies[i]
        if enemy and enemy.valid and enemy.health and enemy.health > 0 and enemy.destructible then
            shoot_laser(surface, entity, enemy)
        end
    end
end

--- Creates spew.
function Public._esp:spew_damage()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local position = {entity.position.x + (-5 + random(0, 10)), entity.position.y + (-5 + random(0, 10))}

    entity.surface.create_entity({name = 'acid-stream-spitter-medium', position = position, target = position, source = position})
end

--- Creates a projectile.
function Public._esp:fire_projectile()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local position = {entity.position.x + (-10 + random(0, 20)), entity.position.y + (-10 + random(0, 20))}

    entity.surface.create_entity(
        {
            name = projectiles[random(1, #projectiles)],
            position = entity.position,
            force = entity.force.name,
            source = entity.position,
            target = position,
            max_range = 16,
            speed = 0.01
        }
    )
end

--- Creates a aoe attack.
function Public._esp:aoe_attack()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local position = {x = entity.position.x + (-10 + random(0, 20)), y = entity.position.y + (-10 + random(0, 20))}

    local target = {
        valid = true,
        position = position
    }

    local damage = tier_damage[entity.name]
    if not damage then
        return
    end

    aoe_punch(entity, target, random(damage.min, damage.max))
end

--- Creates aoe attack.
function Public._esp:area_of_spit_attack(range)
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    area_of_effect(
        entity,
        range or 10,
        function(p)
            do_projectile(entity.surface, 'acid-stream-spitter-big', p, entity.force, p)
        end,
        false
    )
end

function Public._esp:find_targets()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local unit_group_command_step_length = Public.get('unit_group_command_step_length')
    local step_length = unit_group_command_step_length

    local obstacles =
        entity.surface.find_entities_filtered {
        position = entity.position,
        radius = step_length / 2,
        type = {'simple-entity', 'tree'},
        limit = 50
    }
    if obstacles then
        shuffle_distance(obstacles, entity.position)
        self.commands = self.commands or {}
        for ii = 1, #obstacles, 1 do
            if obstacles[ii].valid then
                self.commands[#self.commands + 1] = {
                    type = defines.command.attack,
                    target = obstacles[ii],
                    distraction = defines.distraction.by_anything
                }
            end
        end
    end
end

--- Attack target
function Public._esp:attack_target()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local tick = game.tick
    local orders = self.moving_to_attack_target

    if this.target_settings.commands and this.target_settings.commands.commands then
        this.target_settings.commands = nil
        return
    end

    if not this.target_settings.commands then
        return
    end

    local compound_commands = deepcopy(this.target_settings.commands)

    if not orders then
        self:find_targets()
        self.moving_to_attack_target = tick + 200
        orders = self.moving_to_attack_target
        if self.commands and next(self.commands) then
            for _, entry in pairs(self.commands) do
                compound_commands[#compound_commands + 1] = entry
            end
        end
        local command = {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = compound_commands
        }
        entity.set_command(command)
    end

    if tick > orders then
        self:find_targets()
        self.moving_to_attack_target = tick + 200
        if self.commands and next(self.commands) then
            for _, entry in pairs(self.commands) do
                compound_commands[#compound_commands + 1] = entry
            end
        end

        local command = {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = compound_commands
        }
        entity.set_command(command)
    end
    self.commands = nil
end

-- Sets the attack speed for the given force
function Public._esp:set_attack_speed(speed)
    if not speed then
        speed = 1
    end

    self.force.set_gun_speed_modifier('melee', speed)
    self.force.set_gun_speed_modifier('biological', speed * 2)
end

-- Gets the melee speed for the given force
---@return number
function Public._esp:get_melee_speed()
    return self.force.get_gun_speed_modifier('melee')
end

--- Sets a new position near the LuaEntity.
---@return table|nil
function Public._esp:switch_position()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local position = {entity.position.x + (-5 + random(0, 15)), entity.position.y + (5 + random(0, 15))}

    local rand = entity.surface.find_non_colliding_position(entity.name, position, 0.2, 0.5)
    if rand then
        self.entity.teleport(rand)
    end

    return position
end

--- Validates if a state is valid.
---@return boolean|integer
function Public._esp:validate()
    if not self.id then
        self:remove()
        return false
    end
    if self.entity and self.entity.valid then
        return true
    else
        self:remove()
        return false
    end
end

--- Sets a unit as a boss unit
function Public._esp:set_boss()
    local entity = self.entity
    if not entity or not entity.valid then
        return
    end

    local tick = game.tick

    self.boss_unit = true

    if this.settings.wave_number > 1499 then
        if this.settings.wave_number % 100 == 0 then
            self.go_havoc = true
            self.havoc_interval = tick + 50
            self.clear_go_havoc = tick + 3600
        end
    end
end

function Public._esp:work(tick)
    if self.go_frenzy then
        self:set_frenzy()
    end

    if self.go_havoc and self.clear_go_havoc > tick then
        if tick > self.havoc_interval then
            self:fire_projectile()
            self:area_of_spit_attack()
            if random(1, 10) == 1 then
                self:aoe_attack()
            end
            self.havoc_interval = tick + 50
        end
    end

    self:attack_target()

    if self.boss_unit then
        if random(1, 20) == 1 then
            self:spew_damage()
        elseif random(1, 30) == 1 then
            self:set_burst_frenzy()
        elseif random(1, 50) == 1 then
            self:fire_projectile()
        elseif random(1, 60) == 1 then
            self:laser(6)
        elseif random(1, 80) == 1 then
            if this.settings.wave_number >= 1000 then
                self:area_of_spit_attack()
            end
        elseif random(1, 100) == 1 then
            if this.settings.wave_number >= 1000 then
                self:aoe_attack()
            end
        end
    elseif tick < self.ttl then
        if random(1, 40) == 1 then
            self:spew_damage()
        elseif random(1, 50) == 1 then
            self:set_burst_frenzy()
        elseif random(1, 60) == 1 then
            self:laser()
        end
    else
        self:remove()
    end
end

Public.set_module_status = function()
    on_init()
    this.settings.enabled = not this.settings.enabled
end

Event.on_init(on_init)
Event.add(de.on_entity_died, on_entity_died)
Event.add(de.on_entity_damaged, on_entity_damaged)
Event.add(ev.on_wave_created, on_wave_created)
Event.add(ev.on_unit_group_created, on_unit_group_created)
Event.add(ev.on_entity_created, on_entity_created)
Event.add(ev.on_target_aquired, on_target_aquired)
Event.add(ev.on_evolution_factor_changed, on_evolution_factor_changed)
Event.add(ev.on_game_reset, on_init)

return Public
