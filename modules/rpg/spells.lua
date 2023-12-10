local Public = require 'modules.rpg.table'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Ai = require 'modules.ai'
local Modifiers = require 'utils.player_modifiers'

local spells = {}
local random = math.random
local floor = math.floor

local states = {
    ['attack'] = 'fire-smoke',
    ['support'] = 'poison-capsule-smoke'
}

local restore_movement_speed_token

local repair_buildings =
    Token.register(
    function(data)
        local entity = data.entity
        if entity and entity.valid then
            local rng = 0.1
            if random(1, 5) == 1 then
                rng = 0.2
            elseif random(1, 8) == 1 then
                rng = 0.4
            end
            local to_heal = entity.prototype.max_health * rng
            if entity.health and to_heal then
                entity.health = entity.health + to_heal
            end
        end
    end
)

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

local function area_of_effect(player, position, state, radius, callback, find_entities)
    if not radius then
        return
    end

    local cs = player.surface
    local cp = position or player.position

    if radius and radius > 256 then
        radius = 256
    end

    local area = get_area(cp, radius)

    if not states[state] then
        return
    end

    for x = area.left_top.x, area.right_bottom.x, 1 do
        for y = area.left_top.y, area.right_bottom.y, 1 do
            local d = floor((cp.x - x) ^ 2 + (cp.y - y) ^ 2)
            if d < radius then
                local p = {x = x, y = y}
                if find_entities then
                    for _, e in pairs(cs.find_entities({{p.x - 1, p.y - 1}, {p.x + 1, p.y + 1}})) do
                        if e and e.valid and e.name ~= 'character' and e.health and e.destructible and e.type ~= 'simple-entity' and e.type ~= 'simple-entity-with-owner' then
                            callback(e, p)
                        end
                    end
                else
                    callback(p)
                end
                cs.create_trivial_smoke({name = states[state], position = p})
            end
        end
    end
end

restore_movement_speed_token =
    Token.register(
    function(event)
        local player_index = event.player_index
        local rpg_t = event.rpg_t

        if rpg_t then
            rpg_t.has_custom_spell_active = nil
        end

        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        if not player.character or not player.character.valid then
            Task.set_timeout_in_ticks(60, restore_movement_speed_token, {player_index = player_index, rpg_t = rpg_t})
            return
        end

        Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'rpg_spell', 0)
        Modifiers.update_player_modifiers(player)
    end
)

local function do_projectile(player_surface, name, _position, _force, target, max_range)
    player_surface.create_entity(
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

local function create_projectiles(data)
    local self = data.self
    local player = data.player
    local rpg_t = data.rpg_t
    local damage_entity = data.damage_entity
    local position = data.position
    local surface = data.surface
    local force = data.force
    local target_pos = data.target_pos
    local range = data.range
    local projectile_types = Public.projectile_types

    if self.aoe then
        for _ = 1, self.amount do
            if self.mana_cost > rpg_t.mana then
                break
            end

            local damage_area = {
                left_top = {x = position.x - 2, y = position.y - 2},
                right_bottom = {x = position.x + 2, y = position.y + 2}
            }
            do_projectile(surface, projectile_types[self.entityName].name, position, force, target_pos, range)
            Public.remove_mana(player, self.mana_cost)
            if self.damage then
                for _, e in pairs(surface.find_entities_filtered({area = damage_area})) do
                    damage_entity(e)
                end
            end
        end
    else
        local damage_area = {
            left_top = {x = position.x - 2, y = position.y - 2},
            right_bottom = {x = position.x + 2, y = position.y + 2}
        }
        do_projectile(surface, projectile_types[self.entityName].name, position, force, target_pos, range)
        Public.remove_mana(player, self.mana_cost)

        if self.damage then
            for _, e in pairs(surface.find_entities_filtered({area = damage_area})) do
                damage_entity(e)
            end
        end
    end

    Public.cast_spell(player)
    return true
end

local function create_entity(data)
    local self = data.self
    local player = data.player
    local rpg_t = data.rpg_t
    local position = data.position
    local surface = data.surface
    local force = data.force
    local tame_unit_effects = data.tame_unit_effects

    local last_spell_cast = rpg_t.last_spell_cast

    if last_spell_cast then
        if Public.get_last_spell_cast(player) then
            Public.cast_spell(player, true)
            return false
        end
    end

    Public.set_last_spell_cast(player, position)

    if self.biter then
        if surface.can_place_entity {name = self.entityName, position = position} then
            local e = surface.create_entity({name = self.entityName, position = position, force = force})
            tame_unit_effects(player, e)
            Public.remove_mana(player, self.mana_cost)
            return true
        else
            Public.cast_spell(player, true)
            return false
        end
    end

    if self.aoe then
        local has_cast = false
        for x = 1, -1, -1 do
            for y = 1, -1, -1 do
                local pos = {x = position.x + x, y = position.y + y}
                if surface.can_place_entity {name = self.entityName, position = pos} then
                    if self.mana_cost > rpg_t.mana then
                        break
                    end
                    local e = surface.create_entity({name = self.entityName, position = pos, force = force})
                    has_cast = true
                    e.direction = player.character.direction
                    Public.remove_mana(player, self.mana_cost)
                end
            end
        end
        if has_cast then
            return true
        else
            Public.cast_spell(player, true)
            return false
        end
    else
        if surface.can_place_entity {name = self.entityName, position = position} then
            local e = surface.create_entity({name = self.entityName, position = position, force = force})
            e.direction = player.character.direction
            Public.remove_mana(player, self.mana_cost)
        else
            Public.cast_spell(player, true)
            return false
        end
    end

    Public.cast_spell(player)
    return true
end

local function insert_onto(data)
    local self = data.self
    local player = data.player
    local rpg_t = data.rpg_t

    if self.aoe then
        for _ = 1, self.amount do
            if self.mana_cost > rpg_t.mana then
                break
            end

            player.insert({name = self.entityName, count = self.amount})
            Public.remove_mana(player, self.mana_cost)
        end
    else
        player.insert({name = self.entityName, count = self.amount})
        Public.remove_mana(player, self.mana_cost)
    end

    Public.cast_spell(player)
    return true
end

spells[#spells + 1] = {
    name = {'entity-name.stone-wall'},
    entityName = 'stone-wall',
    level = 1,
    type = 'item',
    mana_cost = 60,
    cooldown = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/stone-wall',
    tooltip = 'Spawns some walls',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.wooden-chest'},
    entityName = 'wooden-chest',
    level = 1,
    type = 'item',
    mana_cost = 50,
    cooldown = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/wooden-chest',
    tooltip = 'Spawns some wooden chests',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.iron-chest'},
    entityName = 'iron-chest',
    level = 10,
    type = 'item',
    mana_cost = 110,
    cooldown = 200,
    aoe = true,
    enabled = true,
    sprite = 'recipe/iron-chest',
    tooltip = 'Spawns some iron chests',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.steel-chest'},
    entityName = 'steel-chest',
    level = 30,
    type = 'item',
    mana_cost = 150,
    cooldown = 300,
    aoe = true,
    enabled = true,
    sprite = 'recipe/steel-chest',
    tooltip = 'Spawns some steel chests',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.transport-belt'},
    entityName = 'transport-belt',
    level = 1,
    type = 'item',
    mana_cost = 80,
    cooldown = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/transport-belt',
    tooltip = 'Spawns some transport belts',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.fast-transport-belt'},
    entityName = 'fast-transport-belt',
    level = 10,
    type = 'item',
    mana_cost = 110,
    cooldown = 200,
    aoe = true,
    enabled = true,
    sprite = 'recipe/fast-transport-belt',
    tooltip = 'Spawns some fast transport belts',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.express-transport-belt'},
    entityName = 'express-transport-belt',
    level = 30,
    type = 'item',
    mana_cost = 150,
    cooldown = 300,
    aoe = true,
    enabled = true,
    sprite = 'recipe/express-transport-belt',
    tooltip = 'Spawns some express transport belts',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.underground-belt'},
    entityName = 'underground-belt',
    level = 1,
    type = 'item',
    mana_cost = 80,
    cooldown = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/underground-belt',
    tooltip = 'Spawns some underground belts',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.fast-underground-belt'},
    entityName = 'fast-underground-belt',
    level = 10,
    type = 'item',
    mana_cost = 110,
    cooldown = 200,
    aoe = true,
    enabled = true,
    sprite = 'recipe/fast-underground-belt',
    tooltip = 'Spawns some fast underground belts',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.express-underground-belt'},
    entityName = 'express-underground-belt',
    level = 30,
    type = 'item',
    mana_cost = 150,
    cooldown = 300,
    aoe = true,
    enabled = true,
    sprite = 'recipe/express-underground-belt',
    tooltip = 'Spawns some express underground belts',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.pipe'},
    entityName = 'pipe',
    level = 1,
    type = 'item',
    mana_cost = 50,
    cooldown = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/pipe',
    tooltip = 'Spawns some pipes',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.pipe-to-ground'},
    entityName = 'pipe-to-ground',
    level = 1,
    type = 'item',
    mana_cost = 100,
    cooldown = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/pipe-to-ground',
    tooltip = 'Spawns some pipe to ground',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.tree'},
    entityName = 'tree-05',
    level = 30,
    type = 'entity',
    mana_cost = 100,
    cooldown = 350,
    aoe = true,
    enabled = true,
    sprite = 'entity/tree-05',
    tooltip = 'Spawns some trees',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.sand-rock-big'},
    entityName = 'sand-rock-big',
    level = 60,
    type = 'entity',
    mana_cost = 120,
    cooldown = 350,
    aoe = true,
    enabled = true,
    sprite = 'entity/sand-rock-big',
    tooltip = 'Spawns some sandy rocks',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.small-biter'},
    entityName = 'small-biter',
    level = 30,
    biter = true,
    type = 'entity',
    mana_cost = 55,
    cooldown = 200,
    enabled = true,
    sprite = 'entity/small-biter',
    tooltip = 'Spawns a small biter',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.small-spitter'},
    entityName = 'small-spitter',
    level = 30,
    biter = true,
    type = 'entity',
    mana_cost = 55,
    cooldown = 200,
    enabled = true,
    sprite = 'entity/small-spitter',
    tooltip = 'Spawns a small spitter',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.medium-biter'},
    entityName = 'medium-biter',
    level = 60,
    biter = true,
    type = 'entity',
    mana_cost = 100,
    cooldown = 300,
    enabled = true,
    sprite = 'entity/medium-biter',
    tooltip = 'Spawns a medium biter',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.medium-spitter'},
    entityName = 'medium-spitter',
    level = 60,
    biter = true,
    type = 'entity',
    mana_cost = 100,
    cooldown = 300,
    enabled = true,
    sprite = 'entity/medium-spitter',
    tooltip = 'Spawns a medium spitter',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.biter-spawner'},
    entityName = 'biter-spawner',
    level = 100,
    biter = true,
    type = 'entity',
    mana_cost = 800,
    cooldown = 1420,
    enabled = false,
    log_spell = true,
    sprite = 'entity/biter-spawner',
    tooltip = 'Spawns a biter spawner',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.spitter-spawner'},
    entityName = 'spitter-spawner',
    level = 100,
    biter = true,
    type = 'entity',
    mana_cost = 800,
    cooldown = 1420,
    enabled = false,
    log_spell = true,
    sprite = 'entity/spitter-spawner',
    tooltip = 'Spawns a spitter spawner',
    callback = function(data)
        return create_entity(data)
    end
}

spells[#spells + 1] = {
    name = {'item-name.shotgun-shell'},
    entityName = 'shotgun-shell',
    target = true,
    amount = 1,
    damage = true,
    force = 'player',
    level = 10,
    type = 'item',
    mana_cost = 40,
    cooldown = 150,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/shotgun-shell',
    tooltip = 'Spawns some shotgun shells',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'item-name.grenade'},
    entityName = 'grenade',
    target = true,
    amount = 1,
    damage = true,
    force = 'player',
    level = 30,
    type = 'item',
    mana_cost = 100,
    cooldown = 150,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/grenade',
    tooltip = 'Spawns a nade where the mouse cursor is at',
    callback = function(data)
        return create_projectiles(data)
    end
}
if _DEBUG then
    spells[#spells + 1] = {
        name = 'Kewl Nade',
        entityName = 'cluster-grenade',
        target = true,
        amount = 20,
        damage = true,
        aoe = true,
        force = 'player',
        level = 1,
        type = 'item',
        mana_cost = -1,
        cooldown = 0,
        enabled = true,
        log_spell = false,
        sprite = 'recipe/cluster-grenade',
        tooltip = 'Spawns a cluster nade where the mouse cursor is at',
        callback = function(data)
            local player = data.player
            player.insert({name = 'raw-fish'})
            return create_projectiles(data)
        end
    }
end
spells[#spells + 1] = {
    name = {'item-name.cluster-grenade'},
    entityName = 'cluster-grenade',
    target = true,
    amount = 2,
    damage = true,
    force = 'player',
    level = 50,
    type = 'item',
    mana_cost = 225,
    cooldown = 200,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/cluster-grenade',
    tooltip = 'Spawns a cluster nade where the mouse cursor is at',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'item-name.cannon-shell'},
    entityName = 'cannon-shell',
    target = true,
    amount = 1,
    damage = true,
    force = 'player',
    level = 30,
    type = 'item',
    mana_cost = 125,
    cooldown = 150,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/cannon-shell',
    tooltip = 'Spawns a cannon shell where the mouse cursor is at',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'item-name.explosive-cannon-shell'},
    entityName = 'explosive-cannon-shell',
    target = true,
    amount = 2,
    damage = true,
    force = 'player',
    level = 50,
    type = 'item',
    mana_cost = 250,
    cooldown = 200,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/explosive-cannon-shell',
    tooltip = 'Spawns a explosive cannon shell where the mouse cursor is at',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'item-name.uranium-cannon-shell'},
    entityName = 'uranium-cannon-shell',
    target = true,
    amount = 2,
    damage = true,
    force = 'player',
    level = 70,
    type = 'item',
    mana_cost = 400,
    cooldown = 200,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/uranium-cannon-shell',
    tooltip = 'Spawns a uranium cannon shell where the mouse cursor is at',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'item-name.rocket'},
    entityName = 'rocket',
    range = 240,
    target = true,
    amount = 4,
    damage = true,
    force = 'enemy',
    level = 40,
    type = 'item',
    mana_cost = 60,
    cooldown = 320,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/rocket',
    tooltip = 'Spawns a rocket where the mouse cursor is at',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.pointy_explosives'},
    entityName = 'pointy_explosives',
    target = true,
    amount = 1,
    range = 0,
    damage = true,
    force = 'player',
    level = 70,
    type = 'special',
    mana_cost = 100,
    cooldown = 100,
    enabled = true,
    log_spell = true,
    sprite = 'recipe/explosives',
    special_sprite = 'recipe=explosives',
    tooltip = 'Spawns a pointy explosive',
    callback = function(data)
        local self = data.self
        local player = data.player
        local Explosives = data.explosives
        local position = data.position

        local entities =
            player.surface.find_entities_filtered {
            force = player.force,
            type = 'container',
            area = {{position.x - 1, position.y - 1}, {position.x + 1, position.y + 1}}
        }

        local detonate_chest
        for i = 1, #entities do
            local e = entities[i]
            detonate_chest = e
        end
        if detonate_chest and detonate_chest.valid then
            local success = Explosives.detonate_chest(detonate_chest)
            if success then
                Public.remove_mana(player, self.mana_cost)
            end
            Public.cast_spell(player)
            return true
        end
    end
}
spells[#spells + 1] = {
    name = {'spells.repair_aoe'},
    entityName = 'repair_aoe',
    target = true,
    amount = 1,
    range = 50,
    damage = false,
    force = 'player',
    level = 45,
    type = 'special',
    mana_cost = 400,
    cooldown = 2400,
    enabled = true,
    enforce_cooldown = true,
    log_spell = true,
    sprite = 'recipe/repair-pack',
    special_sprite = 'recipe=repair-pack',
    tooltip = 'Repairs multiple entities in a range',
    callback = function(data)
        local self = data.self
        local rpg_t = data.rpg_t
        local player = data.player
        local position = data.position

        local range = Public.get_area_of_effect_range(player)

        area_of_effect(
            player,
            position,
            'support',
            range,
            function(entity)
                if entity.prototype.max_health ~= entity.health then
                    if self.mana_cost < rpg_t.mana then
                        Task.set_timeout_in_ticks(10, repair_buildings, {entity = entity})
                        Public.remove_mana(player, self.mana_cost)
                    end
                end
            end,
            true
        )

        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
        return true
    end
}
spells[#spells + 1] = {
    name = {'spells.acid_stream'},
    entityName = 'acid-stream-spitter-big',
    target = true,
    amount = 2,
    range = 0,
    damage = true,
    force = 'player',
    level = 50,
    type = 'special',
    mana_cost = 700,
    cooldown = 2500,
    enabled = true,
    enforce_cooldown = true,
    sprite = 'virtual-signal/signal-S',
    special_sprite = 'virtual-signal=signal-S',
    tooltip = 'Creates a puddle of acid stream',
    callback = function(data)
        local self = data.self
        local player = data.player
        local position = data.position

        local range = Public.get_area_of_effect_range(player)

        area_of_effect(
            player,
            position,
            'attack',
            range,
            function(p)
                do_projectile(player.surface, 'acid-stream-spitter-big', p, player.force, p)
            end,
            false
        )

        Public.remove_mana(player, self.mana_cost)
        Public.cast_spell(player)
        return true
    end
}
spells[#spells + 1] = {
    name = {'spells.tank'},
    entityName = 'tank',
    amount = 1,
    capsule = true,
    force = 'player',
    level = 1000,
    type = 'special',
    mana_cost = 10000, -- they who know, will know
    cooldown = 320,
    enabled = false,
    sprite = 'entity/tank',
    special_sprite = 'entity=tank',
    tooltip = 'Spawns a tank',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.spidertron'},
    entityName = 'spidertron',
    amount = 1,
    capsule = true,
    force = 'player',
    level = 2000,
    type = 'special',
    mana_cost = 19500, -- they who know, will know
    cooldown = 320,
    enabled = false,
    log_spell = true,
    sprite = 'entity/spidertron',
    special_sprite = 'entity=spidertron',
    tooltip = 'Spawns a spidertron',
    callback = function(data)
        return create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.raw_fish'},
    entityName = 'raw-fish',
    target = false,
    amount = 4,
    capsule = true,
    damage = false,
    range = 30,
    force = 'player',
    level = 50,
    type = 'special',
    mana_cost = 140,
    cooldown = 320,
    enabled = true,
    sprite = 'item/raw-fish',
    special_sprite = 'item=raw-fish',
    tooltip = 'Spawns some fishies',
    callback = function(data)
        return insert_onto(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.dynamites'},
    entityName = 'explosives',
    target = false,
    amount = 3,
    aoe = true,
    capsule = true,
    damage = false,
    range = 30,
    force = 'player',
    level = 25,
    type = 'special',
    mana_cost = 140,
    cooldown = 320,
    enabled = true,
    sprite = 'item/explosives',
    special_sprite = 'item=explosives',
    tooltip = 'Spawns some explosives',
    callback = function(data)
        return insert_onto(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.comfylatron'},
    entityName = 'suicidal_comfylatron',
    target = false,
    amount = 4,
    damage = false,
    range = 30,
    force = 'player',
    level = 60,
    type = 'special',
    mana_cost = 150,
    cooldown = 320,
    enabled = true,
    log_spell = true,
    sprite = 'entity/compilatron',
    special_sprite = 'entity=compilatron',
    tooltip = 'Spawns a suicide comfylatron',
    callback = function(data)
        local self = data.self
        local player = data.player
        local position = data.position
        local surface = data.surface

        Public.suicidal_comfylatron(position, surface)
        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
        return true
    end
}
spells[#spells + 1] = {
    name = {'spells.distractor'},
    entityName = 'distractor-capsule',
    target = true,
    amount = 1,
    damage = false,
    range = 30,
    force = 'player',
    level = 50,
    type = 'special',
    mana_cost = 220,
    cooldown = 320,
    enabled = true,
    sprite = 'recipe/distractor-capsule',
    special_sprite = 'recipe=distractor-capsule',
    tooltip = 'Spawns disctractors',
    callback = function(data)
        return create_projectiles(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.warp'},
    entityName = 'warp-gate',
    target = true,
    force = 'player',
    level = 60,
    type = 'special',
    mana_cost = 340,
    cooldown = 2000,
    enabled = true,
    log_spell = true,
    sprite = 'virtual-signal/signal-W',
    special_sprite = 'virtual-signal=signal-W',
    tooltip = 'Warps you back to base',
    callback = function(data)
        local player = data.player
        local surface = data.surface

        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
        Public.remove_mana(player, 999999)
        Public.damage_player_over_time(player, random(8, 16))
        player.play_sound {path = 'utility/armor_insert', volume_modifier = 1}
        Public.cast_spell(player)
        return true
    end
}
spells[#spells + 1] = {
    name = {'spells.charge'},
    entityName = 'haste',
    target = false,
    force = 'player',
    level = 25,
    type = 'special',
    mana_cost = 100,
    cooldown = 2000,
    check_if_active = true,
    enabled = true,
    log_spell = true,
    sprite = 'virtual-signal/signal-info',
    special_sprite = 'virtual-signal=signal-info',
    tooltip = 'Gives you a temporary movement boost.',
    callback = function(data)
        local self = data.self
        local player = data.player
        local rpg_t = data.rpg_t
        rpg_t.has_custom_spell_active = true

        Public.remove_mana(player, self.mana_cost)
        for _ = 1, 3 do
            player.play_sound {path = 'utility/armor_insert', volume_modifier = 1}
        end

        Task.set_timeout_in_ticks(300, restore_movement_speed_token, {player_index = player.index, rpg_t = rpg_t})
        Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'rpg_spell', 1)
        Modifiers.update_player_modifiers(player)
        Public.cast_spell(player)
        return true
    end
}
spells[#spells + 1] = {
    name = {'spells.eternal_blades'},
    entityName = 'eternal_blades',
    target = false,
    force = 'player',
    level = 200,
    type = 'special',
    mana_cost = 350,
    cooldown = 1000,
    enabled = true,
    enforce_cooldown = true,
    log_spell = true,
    sprite = 'virtual-signal/signal-info',
    special_sprite = 'virtual-signal=signal-info',
    tooltip = 'Damages enemies in radius when cast. This is a WIP spell that might get disabled.',
    callback = function(data)
        local self = data.self
        local player = data.player
        local position = data.position

        local range = Public.get_area_of_effect_range(player)

        local damage = Public.get_player_level(player)

        damage = damage / 4

        area_of_effect(
            player,
            position,
            'attack',
            range,
            function(entity)
                if entity.force.index ~= player.force.index then
                    local get_health_pool = Public.has_health_boost(entity, damage, damage, player.character)
                    if get_health_pool then
                        local max_unit_health = floor(get_health_pool * 0.00015)
                        if max_unit_health <= 0 then
                            max_unit_health = 4
                        end
                        if max_unit_health >= 10 then
                            max_unit_health = 10
                        end
                        local final = floor(damage * max_unit_health)
                        Public.set_health_boost(entity, final, player.character)
                        if entity.valid and entity.health <= 0 and get_health_pool <= 0 then
                            entity.die(entity.force.name, player.character)
                        end
                    else
                        if entity.valid then
                            entity.health = entity.health - damage
                            if entity.health <= 0 then
                                entity.die(entity.force.name, player.character)
                            end
                        end
                    end
                end
            end,
            true
        )

        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
        return true
    end
}

spells[#spells + 1] = {
    name = {'spells.drone_enemy'},
    entityName = 'drone_enemy',
    target = false,
    force = 'player',
    level = 200,
    type = 'special',
    mana_cost = 1000,
    cooldown = 18000,
    enabled = true,
    enforce_cooldown = true,
    log_spell = true,
    sprite = 'virtual-signal/signal-info',
    special_sprite = 'virtual-signal=signal-info',
    tooltip = 'Creates a drone that searches for enemies and destroys them. This is a WIP spell that might get disabled.',
    callback = function(data)
        local self = data.self
        local player = data.player
        Ai.create_char({player_index = player.index, command = 1, search_local = true})

        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
        return true
    end
}

spells[#spells + 1] = {
    name = {'spells.drone_mine'},
    entityName = 'drone_mine',
    target = false,
    force = 'player',
    level = 200,
    type = 'special',
    mana_cost = 1000,
    cooldown = 18000,
    enabled = true,
    enforce_cooldown = true,
    log_spell = true,
    sprite = 'virtual-signal/signal-info',
    special_sprite = 'virtual-signal=signal-info',
    tooltip = 'Creates a drone that mines entities around you. This is a WIP spell that might get disabled.',
    callback = function(data)
        local self = data.self
        local player = data.player
        Ai.create_char({player_index = player.index, command = 2, search_local = false})

        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
        return true
    end
}

Public.projectile_types = {
    ['explosives'] = {name = 'grenade', count = 0.5, max_range = 32, tick_speed = 1},
    ['distractor-capsule'] = {name = 'distractor-capsule', count = 1, max_range = 32, tick_speed = 1},
    ['land-mine'] = {name = 'grenade', count = 1, max_range = 32, tick_speed = 1},
    ['grenade'] = {name = 'grenade', count = 1, max_range = 40, tick_speed = 1},
    ['cluster-grenade'] = {name = 'cluster-grenade', count = 1, max_range = 40, tick_speed = 3},
    ['artillery-shell'] = {name = 'artillery-projectile', count = 1, max_range = 60, tick_speed = 3},
    ['cannon-shell'] = {name = 'cannon-projectile', count = 1, max_range = 60, tick_speed = 1},
    ['explosive-cannon-shell'] = {name = 'explosive-cannon-projectile', count = 1, max_range = 60, tick_speed = 1},
    ['explosive-uranium-cannon-shell'] = {
        name = 'explosive-uranium-cannon-projectile',
        count = 1,
        max_range = 60,
        tick_speed = 1
    },
    ['uranium-cannon-shell'] = {name = 'uranium-cannon-projectile', count = 1, max_range = 60, tick_speed = 1},
    ['atomic-bomb'] = {name = 'atomic-rocket', count = 1, max_range = 80, tick_speed = 20},
    ['explosive-rocket'] = {name = 'explosive-rocket', count = 1, max_range = 48, tick_speed = 1},
    ['rocket'] = {name = 'rocket', count = 1, max_range = 48, tick_speed = 1},
    ['flamethrower-ammo'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 28, tick_speed = 1},
    ['crude-oil-barrel'] = {name = 'flamethrower-fire-stream', count = 3, max_range = 24, tick_speed = 1},
    ['petroleum-gas-barrel'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 24, tick_speed = 1},
    ['light-oil-barrel'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 24, tick_speed = 1},
    ['heavy-oil-barrel'] = {name = 'flamethrower-fire-stream', count = 4, max_range = 24, tick_speed = 1},
    ['acid-stream-spitter-big'] = {
        name = 'acid-stream-spitter-big',
        count = 3,
        max_range = 16,
        tick_speed = 1,
        force = 'enemy'
    },
    ['lubricant-barrel'] = {name = 'acid-stream-spitter-big', count = 3, max_range = 16, tick_speed = 1},
    ['shotgun-shell'] = {name = 'shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['piercing-shotgun-shell'] = {name = 'piercing-shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['firearm-magazine'] = {name = 'shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['piercing-rounds-magazine'] = {name = 'piercing-shotgun-pellet', count = 16, max_range = 24, tick_speed = 1},
    ['uranium-rounds-magazine'] = {name = 'piercing-shotgun-pellet', count = 32, max_range = 24, tick_speed = 1},
    ['cliff-explosives'] = {name = 'cliff-explosives', count = 1, max_range = 48, tick_speed = 2}
}

Public.get_projectiles = Public.projectile_types
Public.all_spells = spells

--- Gets a spell by index.
---@param rpg_t table
---@param spell_name string
---@return int|boolean, table|boolean
function Public.get_spell_by_index(rpg_t, spell_name)
    local _spells = Public.get_all_spells_filtered(rpg_t)
    for index, data in pairs(_spells) do
        if data and data.name[1] == spell_name then
            return index, data
        end
        if data and data.name == spell_name then
            return index, data
        end
    end

    return false, false
end

--- Gets a spell by name.
---@param rpg_t table
---@param spell_name string
---@return table|boolean
function Public.get_spell_by_name(rpg_t, spell_name)
    local _spells = Public.get_all_spells_filtered(rpg_t)
    for _, data in pairs(_spells) do
        if data and data.name[1] == spell_name then
            return data
        end
        if data and data.name == spell_name then
            return data
        end
    end

    return false
end

--- Gets a spell by name.
---@param rpg_t table
---@param spell_index string
---@return int|boolean, table|boolean
function Public.match_spell_by_index(rpg_t, spell_index)
    local _spells = Public.get_all_spells_filtered(rpg_t)
    for index, data in pairs(_spells) do
        if index == spell_index then
            return index, data
        end
    end

    return false, false
end

--- Retrieves the spells table or a given spell.
---@param key string
function Public.get_spells(key)
    if game then
        return error('Calling Public.get_spells() after on_init() or on_load() has run is a desync risk.', 2)
    end
    if Public.all_spells[key] then
        return Public.all_spells[key]
    else
        return Public.all_spells
    end
end

--- Disables a spell.
---@param key string/number
-- Table would look like:
-- Public.disable_spell({1, 2, 3, 4, 5, 6, 7, 8})
function Public.disable_spell(key)
    if game then
        return error('Calling Public.disable_spell() after on_init() or on_load() has run is a desync risk.', 2)
    end

    if type(key) == 'table' then
        for _, k in pairs(key) do
            Public.all_spells[k].enabled = false
        end
    elseif Public.all_spells[key] then
        Public.all_spells[key].enabled = false
    end
end

--- Clears the spell table.
function Public.clear_spell_table()
    if game then
        return error('Calling Public.clear_spell_table() after on_init() or on_load() has run is a desync risk.', 2)
    end

    Public.all_spells = {}
end

--- Adds a spell to the rpg_spells
---@param tbl table
function Public.set_new_spell(tbl)
    if game then
        return error('Calling Public.set_new_spell() after on_init() or on_load() has run is a desync risk.', 2)
    end

    if tbl then
        if not tbl.name then
            return error('A spell requires a name. <string>', 2)
        end
        if not tbl.entityName then
            return error('A spell requires an object to create. <string>', 2)
        end
        if not tbl.target then
            tbl.target = false
        end
        if not tbl.amount then
            tbl.amount = 1
        end
        if not tbl.range then
            tbl.range = 0
        end
        if not tbl.damage then
            tbl.damage = 0
        end
        if not tbl.force then
            return error('A spell requires a force. <string>', 2)
        end
        if not tbl.level then
            return error('A spell requires a level. <integer>', 2)
        end
        if not tbl.type then
            return error('A spell requires a type. <item/entity/special>', 2)
        end
        if not tbl.sprite then
            return error('A spell requires a sprite. <string>', 2)
        end
        if not tbl.mana_cost then
            tbl.mana_cost = 100
        end
        if not tbl.cooldown then
            tbl.cooldown = 0
        end
        if not tbl.enforce_cooldown then
            tbl.enforce_cooldown = false
        end
        if not tbl.enabled then
            tbl.enabled = false
        end
        if not tbl.log_spell then
            tbl.log_spell = false
        end
        if not tbl.check_if_active then
            tbl.check_if_active = false
        end
        if not tbl.callback then
            return error('A spell requires a callback. <function>', 2)
        end

        Public.all_spells[#Public.all_spells + 1] = tbl
    end
end

--- This rebuilds all spells. Make sure to make changes on_init if you don't
--  want all spells enabled.
function Public.rebuild_spells()
    local new_spells = {}
    local spell_names = {}

    for i = 1, #spells do
        if spells[i].enabled then
            new_spells[#new_spells + 1] = spells[i]
            spell_names[#spell_names + 1] = spells[i].name
        end
    end

    return new_spells, spell_names
end

--- This rebuilds all spells. Make sure to make changes on_init if you don't
--  want all spells enabled.
function Public.get_all_spells_filtered(rpg_t)
    local new_spells = {}
    local spell_names = {}

    for i = 1, #spells do
        if spells[i].enabled and rpg_t and rpg_t.level >= spells[i].level then
            new_spells[#new_spells + 1] = spells[i]
            spell_names[#spell_names + 1] = spells[i].name
        end
    end

    return new_spells, spell_names
end

--- This will disable the cooldown of all spells.
function Public.disable_cooldowns_on_spells()
    if game then
        return error('Calling Public.disable_cooldowns_on_spells() after on_init() or on_load() has run is a desync risk.', 2)
    end

    local new_spells = {}

    for i = 1, #spells do
        local spell = spells[i]
        if spell.enabled then
            if not spell.enforce_cooldown then
                spell.cooldown = 0
                new_spells[#new_spells + 1] = spell
            else
                new_spells[#new_spells + 1] = spell
            end
        end
    end

    Public.all_spells = new_spells

    return new_spells
end

return Public
