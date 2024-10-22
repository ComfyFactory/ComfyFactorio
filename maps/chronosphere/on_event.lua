local Alert = require 'utils.alert'
local Balance = require 'maps.chronosphere.balance'
local Event_functions = require 'maps.chronosphere.event_functions'
local Chrono_table = require 'maps.chronosphere.table'
local Minimap = require 'maps.chronosphere.minimap'
local Ores = require 'maps.chronosphere.ores'
local World_functions = require 'maps.chronosphere.world_functions'

local Public = {}

function Public.on_player_changed_position(event)
    local objective = Chrono_table.get_table()
    if objective.world.id == 1 and objective.world.variant.id == 11 then --lava planet
        Event_functions.lava_planet(event)
    end
end

function Public.on_research_finished(event)
    Event_functions.research_loot(event)
    Event_functions.flamer_nerfs()
    Event_functions.mining_buffs(event)
    Event_functions.jump_timers(event)
end

function Public.on_player_mined_entity(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    local objective = Chrono_table.get_table()
    if entity.type == 'tree' then
        Event_functions.tree_loot()
        if objective.world.id == 4 then --choppy planet
            Event_functions.trap(entity, false)
            Event_functions.choppy_loot(event)
        end
    elseif entity.name == 'huge-rock' or entity.name == 'big-rock' or entity.name == 'big-sand-rock' then
        if objective.world.id == 3 then --rocky worlds
            event.buffer.clear()
            -- elseif objective.world.id == 5 then --maze worlds
            --     --nothing
        else
            Ores.prospect_ores(entity, entity.surface, entity.position)
        end
    elseif World_functions.is_scrap(entity.name) then
        Event_functions.scrap_loot(event)
        event.buffer.clear()
    end
end

function Public.pre_player_mined_item(event)
    local objective = Chrono_table.get_table()
    if objective.world.id == 3 then --rocky worlds
        if event.entity.name == 'huge-rock' or event.entity.name == 'big-rock' or event.entity.name == 'big-sand-rock' then
            Event_functions.trap(event.entity, false)
            event.entity.destroy()
            Event_functions.rocky_loot(event)
        end
    end
end

function Public.on_pre_player_left_game(event)
    local playertable = Chrono_table.get_player_table()
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    if player.controller_type == defines.controllers.editor then
        player.toggle_map_editor()
    end
    if player.character then
        playertable.offline_players[#playertable.offline_players + 1] = { index = event.player_index, tick = game.tick }
    end
end

function Public.on_player_joined_game(event)
    local objective = Chrono_table.get_table()
    local playertable = Chrono_table.get_player_table()
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    if not playertable.flame_boots[event.player_index] then
        playertable.flame_boots[event.player_index] = {}
    end
    playertable.flame_boots[event.player_index] = { fuel = 1 }
    if not playertable.flame_boots[event.player_index].steps then
        playertable.flame_boots[event.player_index].steps = {}
    end

    local surface = game.surfaces[objective.active_surface_index]

    if player.online_time == 0 then
        player.teleport(surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 32, 0.5) or { 0, 0 }, surface)
        for item, amount in pairs(Balance.starting_items) do
            player.insert({ name = item, count = amount })
        end
    end

    if player.surface.index ~= objective.active_surface_index and player.surface.name ~= 'cargo_wagon' then
        player.character = nil
        player.set_controller({ type = defines.controllers.god })
        player.create_character()
        player.teleport(surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 32, 0.5) or { 0, 0 }, surface)
        for item, amount in pairs(Balance.starting_items) do
            player.insert({ name = item, count = amount })
        end
    end

    local tile = surface.get_tile(player.position.x, player.position.y)
    if tile.valid then
        if tile.name == 'out-of-map' then
            player.teleport(surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 32, 0.5) or { 0, 0 }, surface)
        end
    end
    Minimap.update_surface(player)
    Minimap.toggle_button(player)
end

function Public.on_player_changed_surface(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    Minimap.toggle_button(player)
    if not player.is_cursor_empty() then
        if player.cursor_stack and player.cursor_stack.valid_for_read then
            local blacklisted = {
                ['small-electric-pole'] = true,
                ['medium-electric-pole'] = true,
                ['big-electric-pole'] = true,
                ['substation'] = true
            }
            if blacklisted[player.cursor_stack.name] then
                player.get_main_inventory().insert(player.cursor_stack)
                player.cursor_stack.clear()
            end
        end
        if player.cursor_ghost then
            player.cursor_ghost = nil
        end
    end
end

local function try_destroy_platform(entity, cause)
    local pos = entity.position
    local surface = entity.surface
    if surface.platform then return end
    local asteroids = {
        ['small-metallic-asteroid'] = { size = 1, amount = 1 },
        ['medium-metallic-asteroid'] = { size = 2, amount = 2 },
        ['big-metallic-asteroid'] = { size = 3, amount = 4 },
        ['huge-metallic-asteroid'] = { size = 6, amount = 6 },
        ['small-carbonic-asteroid'] = { size = 1, amount = 1 },
        ['medium-carbonic-asteroid'] = { size = 2, amount = 2 },
        ['big-carbonic-asteroid'] = { size = 3, amount = 4 },
        ['huge-carbonic-asteroid'] = { size = 6, amount = 6 },
        ['small-oxide-asteroid'] = { size = 1, amount = 1 },
        ['medium-oxide-asteroid'] = { size = 2, amount = 2 },
        ['big-oxide-asteroid'] = { size = 3, amount = 4 },
        ['huge-oxide-asteroid'] = { size = 6, amount = 6 },
        ['small-interstellar-asteroid'] = { size = 1, amount = 1 },
        ['medium-interstellar-asteroid'] = { size = 2, amount = 2 },
        ['big-interstellar-asteroid'] = { size = 3, amount = 4 },
        ['huge-interstellar-asteroid'] = { size = 6, amount = 6 },
    }
    local stone = asteroids[entity.name]
    if cause then
        for i = stone.amount, 0, -1 do
            --register some loot or something. Can't spawn chunks outside the actual space platform!
        end
        return
    end
    local tiles = {}
    local size = stone.size
    for x = -size, size, 1 do
        for y = -size, size, 1 do
            local tile = entity.surface.get_tile(pos.x + x, pos.y + y)
            if tile and tile.valid and tile.name == 'space-platform-foundation' then
                tiles[#tiles + 1] = { position = { x = pos.x + x, y = pos.y + y }, name = 'empty-space' }
            end
        end
    end
    entity.surface.set_tiles(tiles)
end

function Public.on_entity_died(event)
    local objective = Chrono_table.get_table()
    local entity = event.entity
    if entity.type == 'asteroid' then
        try_destroy_platform(entity, event.cause)
    end
    if entity.type == 'tree' and objective.world.id == 4 then --choppy planet
        if event.cause then
            if event.cause.valid then
                if event.cause.force.name ~= 'enemy' then
                    Event_functions.trap(event.entity, false)
                end
            end
        elseif event.damage_type == 'poison' then
            Event_functions.trap(event.entity, false)
        end
    end
    if not entity.valid then
        return
    end
    local fname = entity.force.name
    if fname == 'scrapyard' and entity.name == 'gun-turret' then
        if (objective.world.id == 2 and objective.world.variant.id == 2) or objective.world.id == 5 then --danger + hedge maze
            Event_functions.trap(entity, true)
        end
    elseif fname == 'enemy' then
        if entity.type == 'unit-spawner' then
            Event_functions.spawner_loot(entity.surface, entity.position)
            if objective.world.id == 8 then
                Ores.prospect_ores(entity, entity.surface, entity.position)
            end
            if event.cause and (event.cause.name == 'artillery-turret' or event.cause.name == 'artillery-wagon') then
                Event_functions.nuclear_artillery(entity, event.cause)
            end
        elseif entity.type == 'unit' then
            Event_functions.biter_loot(event)
            local bitertable = Chrono_table.get_biter_table()
            bitertable.active_biters[entity.unit_number] = nil
            if objective.world.id == 8 then
                Event_functions.swamp_loot(event)
            end
        elseif entity.type == 'rocket-silo' then
            Event_functions.danger_silo(entity)
        elseif entity.type == 'turret' then
            Event_functions.biter_loot(event)
            if objective.world.id == 8 then
                Event_functions.swamp_loot(event)
            end
        end
    elseif fname == 'neutral' then
        event.loot.clear()
        if objective.world.id == 2 and objective.world.variant.id == 3 and entity.type == 'container' then --RUR robot spawns
            Event_functions.trap(entity, true)
        end
        if event.cause then
            if event.cause.valid then
                if event.cause.force.index == 2 then
                    Event_functions.shred_simple_entities(entity)
                end
            end
        end
    end
end

local function protect_entity(event)
    local objective = Chrono_table.get_table()
    if Event_functions.isprotected(event.entity) then
        if event.cause then
            if event.cause == objective.comfylatron or event.entity == objective.comfylatron then
                return
            end
            if event.cause.force.index == 2 or event.cause.force.name == 'scrapyard' then
                Event_functions.set_objective_health(event.final_damage_amount)
            end
        elseif objective.world.id == 2 and objective.world.variant.id == 2 then
            Event_functions.set_objective_health(event.final_damage_amount)
        end
        if not event.entity.valid then
            return
        end
        event.entity.health = event.entity.health + event.final_damage_amount
        return
    end
    if event.entity.name == 'character' then
        if objective.upgrades[25] > 0 and event.damage_type.name == 'poison' then
            event.entity.health = event.entity.health + event.final_damage_amount * (0.25 * objective.upgrades[25])
        end
    end
end

function Public.on_entity_damaged(event)
    if not event.entity.valid then
        return
    end
    if not event.entity.health then
        return
    end
    local force = event.entity.force.name
    if force == 'neutral' then
        Event_functions.biters_chew_rocks_faster(event)
    elseif force == 'enemy' then
        Event_functions.biter_immunities(event)
    elseif force == 'player' then
        if event.entity.name == 'compilatron' then
            script.raise_event(Chrono_table.events['comfylatron_damaged'], event)
            return
        end
        protect_entity(event)
    end
end

function Public.on_built_entity(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local objective = Chrono_table.get_table()
    --[[ if entity.type == 'entity-ghost' then
        entity.time_to_live = game.forces.player.ghost_time_to_live
    end ]]
    if entity.name == 'spidertron' then
        if objective.world.id ~= 7 or entity.surface.name == 'cargo_wagon' then
            entity.destroy()
            local player = game.players[event.player_index]
            Alert.alert_player_warning(player, 8, { 'chronosphere.spidertron_not_allowed' })
            player.insert({ name = 'spidertron', count = 1 })
        end
    end
end

function Public.on_pre_player_died(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    local surface = player.surface
    local poisons = surface.count_entities_filtered { position = player.position, radius = 10, name = 'poison-cloud' }
    if poisons > 0 then
        local objective = Chrono_table.get_table()
        objective.poison_mastery_unlocked = objective.poison_mastery_unlocked + 1
        if objective.poison_mastery_unlocked == 10 then
            game.print({ 'chronosphere.message_poison_mastery_unlock' }, { r = 0.98, g = 0.66, b = 0.22 })
        end
    end
end

function Public.script_raised_revive(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.force.name == "player" then
        entity.minable = false
        entity.destructible = false
        if entity.name == 'solar-panel' or entity.name == 'substation' then
            entity.operable = false
        end
    end
    if entity.force.name == "scrapyard" then
        if entity.name == "gun-turret" then
            local objective = Chrono_table.get_table()
            if objective.chronojumps > 2 then
                entity.insert({ name = "uranium-rounds-magazine", count = 128 })
            else
                entity.insert({ name = "firearm-magazine", count = 12 })
            end
        elseif entity.name == "artillery-turret" then
            entity.insert({ name = "artillery-shell", count = 30 })
        elseif entity.name == "accumulator" then
            entity.energy = 5000000
        elseif entity.name == "storage-tank" then
            entity.insert_fluid({ name = "light-oil", amount = 15000 })
        end
    end
    if entity.force.name == "neutral" then
        if entity.is_entity_with_health then
            entity.health = math.random(-10, entity.max_health)
            if entity.health <= 0 then entity.die(entity.force) end
        end
    end
end

return Public
