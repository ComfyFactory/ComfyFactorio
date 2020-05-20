local Event = require 'utils.event'

local Map_score = require 'comfy_panel.map_score'
local BiterRolls = require 'modules.wave_defense.biter_rolls'
local unearthing_worm = require 'functions.unearthing_worm'
local unearthing_biters = require 'functions.unearthing_biters'
local Loot = require 'maps.lumberjack.loot'
local Pets = require 'maps.lumberjack.biter_pets'
local tick_tack_trap = require 'functions.tick_tack_trap'
local RPG = require 'maps.lumberjack.rpg'
local Mining = require 'maps.lumberjack.mining'
local Terrain = require 'maps.lumberjack.terrain'
local BiterHealthBooster = require 'modules.biter_health_booster'

-- tables
local WPT = require 'maps.lumberjack.table'
local WD = require 'modules.wave_defense.table'

-- module
local Public = {}

local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

local grandmaster = '[color=blue]Grandmaster:[/color]'

local treasure_chest_messages = {
    "You notice an old crate within the rubble. It's filled with treasure!",
    "You find a chest underneath the broken rocks. It's filled with goodies!",
    'We has found the precious!'
}

local rare_treasure_chest_messages = {
    'Your magic improves. You have found a chest that is filled with rare treasures!',
    "Oh wonderful magic. You found a chest underneath the broken rocks. It's filled with rare goodies!",
    "You're a wizard Harry! We has found the rare precious!"
}

local disabled_entities = {
    'gun-turret',
    'laser-turret',
    'flamethrower-turret',
    'land-mine'
}

local disabled_threats = {
    ['entity-ghost'] = true,
    ['raw-fish'] = true
}

local defeated_messages = {
    "Oh no, the biters nom'ed the train away!",
    "I'm not 100% sure, but - apparently the train was chewed away.",
    'You had one objective - defend the train *-*',
    "Looks like we're resetting cause you did not defend the train ._.",
    'ohgodno-why-must-you-do-this-to-me'
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math_random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function set_objective_health(entity, final_damage_amount)
    local this = WPT.get_table()
    if final_damage_amount == 0 then
        return
    end
    this.locomotive_health = math_floor(this.locomotive_health - final_damage_amount)
    this.cargo_health = math_floor(this.cargo_health - final_damage_amount)
    if this.locomotive_health > this.locomotive_max_health then
        this.locomotive_health = this.locomotive_max_health
    end
    if this.cargo_health > this.cargo_max_health then
        this.cargo_health = this.cargo_max_health
    end
    if this.locomotive_health <= 0 then
        Public.loco_died()
    end
    local m
    if entity == this.locomotive then
        m = this.locomotive_health / this.locomotive_max_health
        entity.health = 1000 * m
    elseif entity == this.locomotive_cargo then
        m = this.cargo_health / this.cargo_max_health
        entity.health = 600 * m
    end
    rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)
end

local function is_protected(entity)
    local this = WPT.get_table()
    local map_name = 'lumberjack'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return true
    end

    local protected = {this.locomotive, this.locomotive_cargo}
    for i = 1, #protected do
        if protected[i] == entity then
            return true
        end
    end
    return false
end

local function protect_train(event)
    local this = WPT.get_table()
    if event.entity.force.index ~= 1 then
        return
    end --Player Force
    if is_protected(event.entity) then
        if event.entity == this.locomotive_cargo or event.entity == this.locomotive then
            if event.cause then
                if
                    event.cause.force.index == 2 or event.cause.force.name == 'lumber_defense' or
                        event.cause.force.name == 'defenders'
                 then
                    if this.locomotive_health <= 0 then
                        goto continue
                    end
                    set_objective_health(event.entity, event.final_damage_amount)
                end
            end
            ::continue::
        end
        if not event.entity.valid then
            return
        end
        event.entity.health = event.entity.health + event.final_damage_amount
    end
end

local function hidden_biter(entity)
    local surface = entity.surface
    local h = math_floor(math_abs(entity.position.y))
    local m = 1 / Terrain.level_depth
    local count = math_floor(math_random(0, h + Terrain.level_depth) * m) + 1
    local position = surface.find_non_colliding_position('small-biter', entity.position, 16, 0.5)
    if not position then
        position = entity.position
    end

    BiterRolls.wave_defense_set_unit_raffle(h * 0.20)

    for _ = 1, count, 1 do
        local unit
        if math_random(1, 3) == 1 then
            unit = surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = position})
        else
            unit = surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = position})
        end

        if math_random(1, 64) == 1 then
            BiterHealthBooster.add_boss_unit(unit, m * h * 5 + 1, 0.38)
        end
    end
end

local function hidden_worm(entity)
    BiterRolls.wave_defense_set_worm_raffle(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.20)
    entity.surface.create_entity({name = BiterRolls.wave_defense_roll_worm_name(), position = entity.position})
end

local function hidden_biter_pet(event)
    if math_random(1, 2048) ~= 1 then
        return
    end
    BiterRolls.wave_defense_set_unit_raffle(math.sqrt(event.entity.position.x ^ 2 + event.entity.position.y ^ 2) * 0.25)
    local unit
    if math_random(1, 3) == 1 then
        unit =
            event.entity.surface.create_entity(
            {name = BiterRolls.wave_defense_roll_spitter_name(), position = event.entity.position}
        )
    else
        unit =
            event.entity.surface.create_entity(
            {name = BiterRolls.wave_defense_roll_biter_name(), position = event.entity.position}
        )
    end
    Pets.biter_pets_tame_unit(game.players[event.player_index], unit, true)
end

local function hidden_treasure(event)
    local player = game.players[event.player_index]
    local rpg_t = RPG.get_table()
    local magic = rpg_t[player.index].magic
    if math.random(1, 320) ~= 1 then
        return
    end
    if magic > 50 then
        player.print(
            rare_treasure_chest_messages[math.random(1, #rare_treasure_chest_messages)],
            {r = 0.98, g = 0.66, b = 0.22}
        )
        Loot.add_rare(event.entity.surface, event.entity.position, 'wooden-chest', magic)
        return
    end
    player.print(treasure_chest_messages[math.random(1, #treasure_chest_messages)], {r = 0.98, g = 0.66, b = 0.22})
    Loot.add(event.entity.surface, event.entity.position, 'wooden-chest')
end

local function biters_chew_rocks_faster(event)
    if event.entity.force.index ~= 3 then
        return
    end --Neutral Force
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.cause.force.index ~= 2 then
        return
    end --Enemy Force

    event.entity.health = event.entity.health - event.final_damage_amount * 2.5
end

local function give_coin(player)
    player.insert({name = 'coin', count = 1})
end

local function on_player_mined_entity(event)
    local this = WPT.get_table()
    local entity = event.entity
    local player = game.players[event.player_index]
    if not player.valid then
        return
    end
    if not entity.valid then
        return
    end

    local map_name = 'lumberjack'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    if disabled_threats[entity.name] then
        return
    end

    Mining.on_player_mined_entity(event)

    if entity.type == 'unit' or entity.type == 'unit-spawner' then
        if math_random(1, 160) == 1 then
            tick_tack_trap(entity.surface, entity.position)
            return
        end
        if math.random(1, 32) == 1 then
            hidden_biter(event.entity)
            return
        end
    end

    if entity.type ~= 'simple-entity' or entity.type ~= 'tree' then
        this.mined_scrap = this.mined_scrap + 1
        give_coin(player)

        if math.random(1, 32) == 1 then
            hidden_biter(event.entity)
            return
        end
        if math.random(1, 512) == 1 then
            hidden_worm(event.entity)
            return
        end
        hidden_biter_pet(event)
        hidden_treasure(event)
        if math_random(1, 160) == 1 then
            tick_tack_trap(entity.surface, entity.position)
            return
        end
    end

    if entity.force.name ~= 'defenders' then
        return
    end
    local positions = {}
    local r = math.ceil(entity.prototype.max_health / 32)
    for x = r * -1, r, 1 do
        for y = r * -1, r, 1 do
            positions[#positions + 1] = {x = entity.position.x + x, y = entity.position.y + y}
        end
    end
    positions = shuffle(positions)
    for i = 1, math.ceil(entity.prototype.max_health / 32), 1 do
        if not positions[i] then
            return
        end
        if math_random(1, 3) ~= 1 then
            unearthing_biters(entity.surface, positions[i], math_random(5, 10))
        else
            unearthing_worm(entity.surface, positions[i])
        end
    end
end

local function on_entity_damaged(event)
    if not event.entity then
        return
    end
    if not event.entity.valid then
        return
    end
    if not event.entity.health then
        return
    end
    protect_train(event)
    biters_chew_rocks_faster(event)
end

local function on_player_repaired_entity(event)
    local this = WPT.get_table()
    if not event.entity then
        return
    end
    if not event.entity.valid then
        return
    end
    if not event.entity.health then
        return
    end
    local entity = event.entity
    if entity == this.locomotive_cargo or entity == this.locomotive then
        set_objective_health(entity, -1)
    end
end

local function on_entity_died(event)
    local this = WPT.get_table()

    local entity = event.entity
    if not entity.valid then
        return
    end

    local map_name = 'lumberjack'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    if disabled_threats[entity.name] then
        return
    end

    Mining.on_entity_died(event)

    if entity.type == 'unit' or entity.type == 'unit-spawner' then
        this.biters_killed = this.biters_killed + 1
        if math_random(1, 512) == 1 then
            tick_tack_trap(entity.surface, entity.position)
            return
        end
        if math.random(1, 32) == 1 then
            hidden_biter(event.entity)
            return
        end
    end

    if entity.type ~= 'simple-entity' or entity.type ~= 'tree' then
        if math.random(1, 32) == 1 then
            hidden_biter(event.entity)
            return
        end
        if math.random(1, 512) == 1 then
            hidden_worm(event.entity)
            return
        end
        if math_random(1, 512) == 1 then
            tick_tack_trap(entity.surface, entity.position)
            return
        end
    end
    if entity.force.name ~= 'defenders' then
        return
    end
    local positions = {}
    local r = math.ceil(entity.prototype.max_health / 32)
    for x = r * -1, r, 1 do
        for y = r * -1, r, 1 do
            positions[#positions + 1] = {x = entity.position.x + x, y = entity.position.y + y}
        end
    end
    positions = shuffle(positions)
    for i = 1, math.ceil(entity.prototype.max_health / 32), 1 do
        if not positions[i] then
            return
        end
        if math_random(1, 3) ~= 1 then
            unearthing_biters(entity.surface, positions[i], math_random(5, 10))
        else
            unearthing_worm(entity.surface, positions[i])
        end
    end
end

local function on_robot_built_entity(event)
    local map_name = 'lumberjack'

    if string.sub(event.created_entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local y = event.created_entity.position.y
    local ent = event.created_entity
    if y >= 150 then
        game.print(grandmaster .. ' I do not approve, ' .. ent.name .. ' was obliterated.', {r = 1, g = 0.5, b = 0.1})
        ent.die()
        return
    else
        for _, e in pairs(disabled_entities) do
            if e == event.created_entity.name then
                if y >= 0 then
                    ent.active = false
                    if event.player_index then
                        game.print(
                            grandmaster .. " Can't build here. I disabled your " .. ent.name .. '.',
                            {r = 1, g = 0.5, b = 0.1}
                        )
                        return
                    end
                end
            end
        end
    end
end

local function on_built_entity(event)
    local map_name = 'lumberjack'

    if string.sub(event.created_entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local player = game.players[event.player_index]
    local y = event.created_entity.position.y
    local ent = event.created_entity
    if y >= 150 then
        player.print(grandmaster .. ' I do not approve, ' .. ent.name .. ' was obliterated.', {r = 1, g = 0.5, b = 0.1})
        ent.die()
        return
    else
        for _, e in pairs(disabled_entities) do
            if e == event.created_entity.name then
                if y >= 0 then
                    ent.active = false
                    if event.player_index then
                        player.print(
                            grandmaster .. " Can't build here. I disabled your " .. ent.name .. '.',
                            {r = 1, g = 0.5, b = 0.1}
                        )
                        return
                    end
                end
            end
        end
    end
end

function Public.set_scores()
    local this = WPT.get_table()
    local wagon = this.locomotive_cargo
    if not wagon then
        return
    end
    if not wagon.valid then
        return
    end
    local score = math_floor(wagon.position.y * -1)
    for _, player in pairs(game.connected_players) do
        if score > Map_score.get_score(player) then
            Map_score.set_score(player, score)
        end
    end
end

function Public.loco_died()
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    local wave_defense_table = WD.get_table()
    Public.set_scores()
    if not this.locomotive.valid then
        wave_defense_table.game_lost = true
        wave_defense_table.target = nil
        game.print(
            grandmaster .. ' ' .. defeated_messages[math.random(1, #defeated_messages)],
            {r = 1, g = 0.5, b = 0.1}
        )
        game.print(grandmaster .. ' Better luck next time.', {r = 1, g = 0.5, b = 0.1})
        Public.reset_map()
        return
    end
    this.locomotive_health = 0
    this.locomotive.color = {0.49, 0, 255, 1}
    rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)
    wave_defense_table.game_lost = true
    wave_defense_table.target = nil
    game.print(grandmaster .. ' ' .. defeated_messages[math.random(1, #defeated_messages)], {r = 1, g = 0.5, b = 0.1})
    game.print(grandmaster .. ' Better luck next time.', {r = 1, g = 0.5, b = 0.1})
    game.print(grandmaster .. ' Game will soft-reset shortly.', {r = 1, g = 0.5, b = 0.1})
    game.forces.enemy.set_friend('player', true)
    game.forces.player.set_friend('enemy', true)

    local fake_shooter =
        surface.create_entity({name = 'character', position = this.locomotive.position, force = 'enemy'})
    surface.create_entity(
        {
            name = 'atomic-rocket',
            position = this.locomotive.position,
            force = 'enemy',
            speed = 1,
            max_range = 1200,
            target = this.locomotive,
            source = fake_shooter
        }
    )

    surface.spill_item_stack(this.locomotive.position, {name = 'coin', count = 512}, false)
    surface.spill_item_stack(this.locomotive_cargo.position, {name = 'coin', count = 512}, false)
    this.game_reset_tick = game.tick + 1800
    for _, player in pairs(game.connected_players) do
        player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
    end
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)

return Public
