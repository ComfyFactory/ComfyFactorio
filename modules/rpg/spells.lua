local Public = require 'modules.rpg.table'

local spells = {}
local random = math.random

local function create_projectiles(data)
    local self = data.self
    local player = data.player
    local damage_entity = data.damage_entity
    local position = data.position
    local surface = data.surface
    local force = data.force
    local target_pos = data.target_pos
    local range = data.range

    local function do_projectile(player_surface, name, _position, _force, target, max_range)
        player_surface.create_entity(
            {
                name = name,
                position = _position,
                force = _force,
                source = _position,
                target = target,
                max_range = max_range,
                speed = 0.4
            }
        )
    end

    if self.aoe then
        for _ = 1, self.amount do
            local damage_area = {
                left_top = {x = position.x - 2, y = position.y - 2},
                right_bottom = {x = position.x + 2, y = position.y + 2}
            }
            do_projectile(surface, self.entityName, position, force, target_pos, range)
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
        do_projectile(surface, self.entityName, position, force, target_pos, range)
        if self.damage then
            for _, e in pairs(surface.find_entities_filtered({area = damage_area})) do
                damage_entity(e)
            end
        end
    end
    Public.cast_spell(player)
    Public.remove_mana(player, self.mana_cost)
end

local function create_entity(data)
    local self = data.self
    local player = data.player
    local mana = data.mana
    local position = data.position
    local surface = data.surface
    local force = data.force
    local tame_unit_effects = data.tame_unit_effects

    if self.biter then
        local e = surface.create_entity({name = self.entityName, position = position, force = force})
        tame_unit_effects(player, e)
        Public.remove_mana(player, self.mana_cost)
        return
    end

    if self.aoe then
        for x = 1, -1, -1 do
            for y = 1, -1, -1 do
                local pos = {x = position.x + x, y = position.y + y}
                if surface.can_place_entity {name = self.entityName, position = pos} then
                    if self.mana_cost > mana then
                        break
                    end
                    local e = surface.create_entity({name = self.entityName, position = pos, force = force})
                    e.direction = player.character.direction
                    Public.remove_mana(player, self.mana_cost)
                end
            end
        end
    else
        if surface.can_place_entity {name = self.entityName, position = position} then
            local e = surface.create_entity({name = self.entityName, position = position, force = force})
            e.direction = player.character.direction
            Public.remove_mana(player, self.mana_cost)
        end
    end
    Public.cast_spell(player)
    Public.remove_mana(player, self.mana_cost)
end

local function insert_onto(data)
    local self = data.self
    local player = data.player

    player.insert({name = self.entityName, count = self.amount})
    Public.cast_spell(player)
    Public.remove_mana(player, self.mana_cost)
end

spells[#spells + 1] = {
    name = {'entity-name.stone-wall'},
    entityName = 'stone-wall',
    level = 1,
    type = 'item',
    mana_cost = 60,
    tick = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/stone-wall',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.wooden-chest'},
    entityName = 'wooden-chest',
    level = 1,
    type = 'item',
    mana_cost = 50,
    tick = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/wooden-chest',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.iron-chest'},
    entityName = 'iron-chest',
    level = 10,
    type = 'item',
    mana_cost = 110,
    tick = 200,
    aoe = true,
    enabled = true,
    sprite = 'recipe/iron-chest',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.steel-chest'},
    entityName = 'steel-chest',
    level = 30,
    type = 'item',
    mana_cost = 150,
    tick = 300,
    aoe = true,
    enabled = true,
    sprite = 'recipe/steel-chest',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.transport-belt'},
    entityName = 'transport-belt',
    level = 1,
    type = 'item',
    mana_cost = 80,
    tick = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/transport-belt',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.fast-transport-belt'},
    entityName = 'fast-transport-belt',
    level = 10,
    type = 'item',
    mana_cost = 110,
    tick = 200,
    aoe = true,
    enabled = true,
    sprite = 'recipe/fast-transport-belt',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.express-transport-belt'},
    entityName = 'express-transport-belt',
    level = 30,
    type = 'item',
    mana_cost = 150,
    tick = 300,
    aoe = true,
    enabled = true,
    sprite = 'recipe/express-transport-belt',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.underground-belt'},
    entityName = 'underground-belt',
    level = 1,
    type = 'item',
    mana_cost = 80,
    tick = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/underground-belt',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.fast-underground-belt'},
    entityName = 'fast-underground-belt',
    level = 10,
    type = 'item',
    mana_cost = 110,
    tick = 200,
    aoe = true,
    enabled = true,
    sprite = 'recipe/fast-underground-belt',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.express-underground-belt'},
    entityName = 'express-underground-belt',
    level = 30,
    type = 'item',
    mana_cost = 150,
    tick = 300,
    aoe = true,
    enabled = true,
    sprite = 'recipe/express-underground-belt',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.pipe'},
    entityName = 'pipe',
    level = 1,
    type = 'item',
    mana_cost = 50,
    tick = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/pipe',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.pipe-to-ground'},
    entityName = 'pipe-to-ground',
    level = 1,
    type = 'item',
    mana_cost = 100,
    tick = 100,
    aoe = true,
    enabled = true,
    sprite = 'recipe/pipe-to-ground',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.tree'},
    entityName = 'tree-05',
    level = 30,
    type = 'entity',
    mana_cost = 100,
    tick = 350,
    aoe = true,
    enabled = true,
    sprite = 'entity/tree-05',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.sand-rock-big'},
    entityName = 'sand-rock-big',
    level = 60,
    type = 'entity',
    mana_cost = 80,
    tick = 350,
    aoe = true,
    enabled = true,
    sprite = 'entity/sand-rock-big',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.small-biter'},
    entityName = 'small-biter',
    level = 30,
    biter = true,
    type = 'entity',
    mana_cost = 55,
    tick = 200,
    enabled = true,
    sprite = 'entity/small-biter',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.small-spitter'},
    entityName = 'small-spitter',
    level = 30,
    biter = true,
    type = 'entity',
    mana_cost = 55,
    tick = 200,
    enabled = true,
    sprite = 'entity/small-spitter',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.medium-biter'},
    entityName = 'medium-biter',
    level = 60,
    biter = true,
    type = 'entity',
    mana_cost = 100,
    tick = 300,
    enabled = true,
    sprite = 'entity/medium-biter',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.medium-spitter'},
    entityName = 'medium-spitter',
    level = 60,
    biter = true,
    type = 'entity',
    mana_cost = 100,
    tick = 300,
    enabled = true,
    sprite = 'entity/medium-spitter',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.biter-spawner'},
    entityName = 'biter-spawner',
    level = 100,
    biter = true,
    type = 'entity',
    mana_cost = 800,
    tick = 1420,
    enabled = false,
    sprite = 'entity/biter-spawner',
    callback = function(data)
        create_entity(data)
    end
}
spells[#spells + 1] = {
    name = {'entity-name.spitter-spawner'},
    entityName = 'spitter-spawner',
    level = 100,
    biter = true,
    type = 'entity',
    mana_cost = 800,
    tick = 1420,
    enabled = false,
    sprite = 'entity/spitter-spawner',
    callback = function(data)
        create_entity(data)
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
    tick = 150,
    enabled = true,
    sprite = 'recipe/shotgun-shell',
    callback = function(data)
        create_projectiles(data)
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
    tick = 150,
    enabled = true,
    sprite = 'recipe/grenade',
    callback = function(data)
        create_projectiles(data)
    end
}
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
    tick = 200,
    enabled = true,
    sprite = 'recipe/cluster-grenade',
    callback = function(data)
        create_projectiles(data)
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
    tick = 150,
    enabled = true,
    sprite = 'recipe/cannon-shell',
    callback = function(data)
        create_projectiles(data)
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
    tick = 200,
    enabled = true,
    sprite = 'recipe/explosive-cannon-shell',
    callback = function(data)
        create_projectiles(data)
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
    tick = 200,
    enabled = true,
    sprite = 'recipe/uranium-cannon-shell',
    callback = function(data)
        create_projectiles(data)
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
    tick = 320,
    enabled = true,
    sprite = 'recipe/rocket',
    callback = function(data)
        create_projectiles(data)
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
    tick = 100,
    enabled = true,
    sprite = 'recipe/explosives',
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
    mana_cost = 150,
    tick = 100,
    enabled = true,
    sprite = 'recipe/repair-pack',
    callback = function(data)
        local self = data.self
        local player = data.player
        local position = data.position

        Public.repair_aoe(player, position)
        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
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
    mana_cost = 70,
    tick = 100,
    enabled = true,
    sprite = 'virtual-signal/signal-S',
    callback = function(data)
        create_projectiles(data)
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
    tick = 320,
    enabled = false,
    sprite = 'entity/tank',
    callback = function(data)
        create_entity(data)
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
    tick = 320,
    enabled = false,
    sprite = 'entity/spidertron',
    callback = function(data)
        create_entity(data)
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
    tick = 320,
    enabled = true,
    sprite = 'item/raw-fish',
    callback = function(data)
        insert_onto(data)
    end
}
spells[#spells + 1] = {
    name = {'spells.dynamites'},
    entityName = 'explosives',
    target = false,
    amount = 3,
    capsule = true,
    damage = false,
    range = 30,
    force = 'player',
    level = 25,
    type = 'special',
    mana_cost = 140,
    tick = 320,
    enabled = true,
    sprite = 'item/explosives',
    callback = function(data)
        insert_onto(data)
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
    tick = 320,
    enabled = true,
    sprite = 'entity/compilatron',
    callback = function(data)
        local self = data.self
        local player = data.player
        local position = data.position
        local surface = data.surface

        Public.suicidal_comfylatron(position, surface)
        Public.cast_spell(player)
        Public.remove_mana(player, self.mana_cost)
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
    tick = 320,
    enabled = true,
    sprite = 'recipe/distractor-capsule',
    callback = function(data)
        create_projectiles(data)
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
    tick = 2000,
    enabled = true,
    sprite = 'virtual-signal/signal-W',
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
    end
}

Public.projectile_types = {
    ['explosives'] = {name = 'grenade', count = 0.5, max_range = 32, tick_speed = 1},
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
Public.spells = spells

--- Retrieves the spells table or a given spell.
---@param key string
function Public.get_spells(key)
    if game then
        return error('Calling Public.get_spells() after on_init() or on_load() has run is a desync risk.', 2)
    end
    if Public.spells[key] then
        return Public.spells[key]
    else
        return Public.spells
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
            Public.spells[k].enabled = false
        end
    elseif Public.spells[key] then
        Public.spells[key].enabled = false
    end
end

--- Clears the spell table.
function Public.clear_spell_table()
    if game then
        return error('Calling Public.clear_spell_table() after on_init() or on_load() has run is a desync risk.', 2)
    end

    Public.spells = {}
end

--- Adds a spell to the rpg_spells
---@param tbl table
function Public.set_new_spell(tbl)
    if game then
        return error('Calling Public.set_new_spell() after on_init() or on_load() has run is a desync risk.', 2)
    end

    if tbl then
        if not tbl.name then
            return error('A spell requires a name. string', 2)
        end
        if not tbl.entityName then
            return error('A spell requires an object to create. string', 2)
        end
        if not tbl.target then
            return error('A spell requires position. boolean', 2)
        end
        if not tbl.amount then
            return error('A spell requires an amount of creation. <integer>', 2)
        end
        if not tbl.range then
            return error('A spell requires a range. <integer>', 2)
        end
        if not tbl.damage then
            return error('A spell requires damage. <damage-area=true/false>', 2)
        end
        if not tbl.force then
            return error('A spell requires a force. string', 2)
        end
        if not tbl.level then
            return error('A spell requires a level. <integer>', 2)
        end
        if not tbl.type then
            return error('A spell requires a type. <item/entity/special>', 2)
        end
        if not tbl.mana_cost then
            return error('A spell requires mana_cost. <integer>', 2)
        end
        if not tbl.tick then
            return error('A spell requires tick. <integer>', 2)
        end
        if not tbl.enabled then
            return error('A spell requires enabled. boolean', 2)
        end

        Public.spells[#Public.spells + 1] = tbl
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

--- This will disable the cooldown of all spells.
function Public.disable_cooldowns_on_spells()
    if game then
        return error('Calling Public.disable_cooldowns_on_spells() after on_init() or on_load() has run is a desync risk.', 2)
    end

    local new_spells = {}

    for i = 1, #spells do
        if spells[i].enabled then
            spells[i].tick = 0
            new_spells[#new_spells + 1] = spells[i]
        end
    end

    Public.spells = new_spells

    return new_spells
end

return Public
