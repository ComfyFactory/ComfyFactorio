--tank battles (royale)-- by mewmew
-- modified heavily by gerkiz

local Event = require 'utils.event'
local Global = require 'utils.global'
local simplex_noise = require 'utils.simplex_noise'.d2
local Core = require 'utils.core'
local Server = require 'utils.server'
local Map = require 'modules.map_info'

local this = {}
local arena_size = 160
local insert = table.insert
local random = math.random

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local tile_blacklist = {
    ['water'] = true,
    ['deepwater'] = true,
    ['water-green'] = true,
    ['deepwater-green'] = true,
    ['out-of-map'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['lab-dark-1'] = true,
    ['lab-dark-2'] = true,
    ['lab-white'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
    ['water-wube'] = true,
    ['tile-unknown'] = true,
    ['tutorial-grid'] = true
}

local loot = {
    {{name = 'flamethrower-ammo', count = 16}, weight = 2},
    {{name = 'piercing-shotgun-shell', count = 16}, weight = 2},
    {{name = 'explosive-rocket', count = 8}, weight = 2},
    {{name = 'rocket', count = 8}, weight = 2},
    {{name = 'grenade', count = 16}, weight = 2},
    {{name = 'cluster-grenade', count = 8}, weight = 2},
    {{name = 'defender-capsule', count = 6}, weight = 1},
    {{name = 'distractor-capsule', count = 3}, weight = 1},
    {{name = 'cannon-shell', count = 8}, weight = 16},
    {{name = 'explosive-cannon-shell', count = 8}, weight = 16},
    {{name = 'uranium-cannon-shell', count = 8}, weight = 6},
    {{name = 'explosive-uranium-cannon-shell', count = 8}, weight = 6},
    {{name = 'energy-shield-equipment', count = 1}, weight = 2},
    {{name = 'fusion-reactor-equipment', count = 1}, weight = 2},
    {{name = 'repair-pack', count = 1}, weight = 6},
    {{name = 'coal', count = 16}, weight = 3},
    {{name = 'nuclear-fuel', count = 1}, weight = 1},
    {{name = 'gate', count = 16}, weight = 2},
    {{name = 'stone-wall', count = 16}, weight = 2}
}
local loot_raffle = {}
for _, item in pairs(loot) do
    for _ = 1, item.weight, 1 do
        insert(loot_raffle, item[1])
    end
end

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function create_gui(player)
    local frame = player.gui.left['status_players']
    if frame and frame.valid then
        return
    end

    frame = player.gui.left.add({type = 'frame', name = 'status_players', direction = 'vertical'})

    local lbl = frame.add({type = 'label', caption = 'Waiting for more players before round starts.'})
    lbl.style.font_color = {r = 0.98, g = 0.66, b = 0.22}
    lbl.style.font = 'default-listbox'

    frame.visible = false
end

local function check_winners()
    local scores = this.tank_battles_score
    if not scores or not next(scores) then
        return
    end

    for _, score in pairs(scores) do
        if score > 0 then
            return true
        end
    end
    return false
end

local function get_noise(name, pos)
    local seed = this.noise_seed
    local noise = {}
    local noise_seed_add = 25000
    if name == 'rocks' then
        noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
        seed = seed + noise_seed_add
        noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
        local noise_amp = noise[1] + noise[2] * 0.2
        return noise_amp
    end
    seed = seed + noise_seed_add
    seed = seed + noise_seed_add
    if name == 'rocks_2' then
        noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
        seed = seed + noise_seed_add
        noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
        local noise_amp = noise[1] + noise[2] * 0.2
        return noise_amp
    end
    seed = seed + noise_seed_add
    seed = seed + noise_seed_add
    if name == 'terrain' then
        noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
        seed = seed + noise_seed_add
        noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
        local noise_amp = noise[1] + noise[2] * 0.2
        return noise_amp
    end
end

local function create_tank_battle_score_gui()
    if not check_winners() then
        return
    end

    local scores = {}
    Core.iter_connected_players(
        function(player_amp)
            if this.tank_battles_score[player_amp.index] then
                insert(scores, {name = player_amp.name, score = this.tank_battles_score[player_amp.index], color = player_amp.color})
            end
        end
    )

    if scores and #scores == 0 then
        return
    end

    Core.iter_connected_players(
        function(player)
            local frame = player.gui.left['tank_battle_score']
            if frame and frame.valid then
                frame.destroy()
            end

            frame = player.gui.left.add({type = 'frame', name = 'tank_battle_score', direction = 'vertical'})

            local lbl = frame.add({type = 'label', caption = 'Won rounds'})
            lbl.style.font_color = {r = 0.98, g = 0.66, b = 0.22}
            lbl.style.font = 'default-listbox'

            local t = frame.add({type = 'table', column_count = 2})

            for _ = 1, #scores, 1 do
                for y = 1, #scores, 1 do
                    if not scores[y + 1] then
                        break
                    end
                    if scores[y]['score'] < scores[y + 1]['score'] then
                        local key = scores[y]
                        scores[y] = scores[y + 1]
                        scores[y + 1] = key
                    end
                end
            end

            for i = 1, 8, 1 do
                if scores[i] then
                    local player_name = scores[i].name
                    local player_color = scores[i].color
                    local player_score = scores[i].score
                    local l = t.add({type = 'label', caption = player_name})
                    player_color = {r = player_color.r * 0.6 + 0.4, g = player_color.g * 0.6 + 0.4, b = player_color.b * 0.6 + 0.4, a = 1}
                    l.style.font_color = player_color
                    l.style.font = 'default-bold'
                    t.add({type = 'label', caption = player_score})
                end
            end
        end
    )
end

local function get_valid_random_spawn_position(surface)
    local chunks = {}
    for chunk in surface.get_chunks() do
        insert(chunks, {x = chunk.x, y = chunk.y})
    end
    chunks = shuffle(chunks)

    for _, chunk in pairs(chunks) do
        if chunk.x * 32 < arena_size and chunk.y * 32 < arena_size and chunk.x * 32 >= arena_size * -1 and chunk.y * 32 >= arena_size * -1 then
            local area = {{chunk.x * 32 - 64, chunk.y * 32 - 64}, {chunk.x * 32 + 64, chunk.y * 32 + 64}}
            if surface.count_entities_filtered({name = 'tank', area = area}) == 0 then
                local pos = surface.find_non_colliding_position('tank', {chunk.x * 32 + 16, chunk.y * 32 + 16}, 16, 8)
                return pos
            end
        end
    end

    local pos = surface.find_non_colliding_position('tank', {0, 0}, 32, 4)
    if pos then
        return pos
    end

    return {0, 0}
end

local function put_players_into_arena()
    Core.iter_connected_players(
        function(player)
            local permissions_group = game.permissions.get_group('Default')
            permissions_group.add_player(player.name)

            if player.character then
                player.character.destroy()
                player.character = nil
            end

            player.create_character()

            player.insert({name = 'combat-shotgun', count = 1})
            player.insert({name = 'rocket-launcher', count = 1})
            player.insert({name = 'flamethrower', count = 1})

            local surface = game.get_surface('nauvis')

            local pos = get_valid_random_spawn_position(surface)

            player.force.chart(surface, {{x = -1 * arena_size, y = -1 * arena_size}, {x = arena_size, y = arena_size}})

            if pos then
                player.teleport(pos, surface)
            else
                pos = get_valid_random_spawn_position(surface)
            end
            local tank = surface.create_entity({name = 'tank', force = game.forces[player.name], position = pos})
            tank.insert({name = 'coal', count = 24})
            tank.insert({name = 'cannon-shell', count = 16})
            tank.set_driver(player)
        end
    )
end

local function get_arena_layout_modifiers()
    this.arena_layout_modifiers = {}
    local proto = game.entity_prototypes

    local tree_raffle = {}
    for _, e in pairs(proto) do
        if e.type == 'tree' then
            insert(tree_raffle, e.name)
        end
    end
    this.arena_layout_modifiers.arena_tree = tree_raffle[random(1, #tree_raffle)]
    this.arena_layout_modifiers.arena_tree_chance = random(4, 20)
    this.arena_layout_modifiers.arena_tree_noise = random(0, 75) * 0.01

    local entity_raffle = {}
    local types = {'furnace', 'assembling-machine', 'power-switch', 'programmable-speaker', 'reactor'}
    for _, e in pairs(proto) do
        for _, t in pairs(types) do
            if e.type == t then
                insert(entity_raffle, e.name)
            end
        end
    end
    this.arena_layout_modifiers.secret_entity = entity_raffle[random(1, #entity_raffle)]

    local tile_raffle = {}

    for _, t in pairs(game.tile_prototypes) do
        if not tile_blacklist[t.name] then
            insert(tile_raffle, t.name)
        end
    end
    this.arena_layout_modifiers.arena_tile_1 = tile_raffle[random(1, #tile_raffle)]
    this.arena_layout_modifiers.arena_tile_2 = tile_raffle[random(1, #tile_raffle)]
end

local function regenerate_arena()
    local surface = game.get_surface('nauvis')
    for chunk in surface.get_chunks() do
        surface.set_chunk_generated_status({x = chunk.x, y = chunk.y}, defines.chunk_generated_status.custom_tiles)
    end

    this.noise_seed = nil
    ---@diagnostic disable-next-line: param-type-mismatch
    surface.request_to_generate_chunks({0, 0}, math.ceil(arena_size / 32) + 3)

    get_arena_layout_modifiers()

    surface.force_generate_chunk_requests()
    surface.daytime = 1
    surface.freeze_daytime = 1

    this.current_arena_size = arena_size

    put_players_into_arena()

    this.game_stage = 'ongoing_game'
end

local function shrink_arena()
    local surface = game.get_surface('nauvis')

    if this.current_arena_size < 0 then
        return
    end

    local shrink_width = 8
    local current_arena_size = this.current_arena_size
    local tiles = {}

    for x = arena_size * -1, arena_size, 1 do
        for y = current_arena_size * -1 - shrink_width, current_arena_size * -1, 1 do
            local pos = {x = x, y = y}
            local tile = surface.get_tile(pos.x, pos.y)
            if tile.name ~= 'water' and tile.name ~= 'deepwater' then
                if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then
                    if random(1, 3) ~= 1 then
                        insert(tiles, {name = 'water', position = pos})
                    end
                end
            end
        end
    end

    for x = arena_size * -1, arena_size, 1 do
        for y = current_arena_size, current_arena_size + shrink_width, 1 do
            local pos = {x = x, y = y}
            local tile = surface.get_tile(pos.x, pos.y)
            if tile.name ~= 'water' and tile.name ~= 'deepwater' then
                if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then
                    if random(1, 3) ~= 1 then
                        insert(tiles, {name = 'water', position = pos})
                    end
                end
            end
        end
    end

    for x = current_arena_size * -1 - shrink_width, current_arena_size * -1, 1 do
        for y = arena_size * -1, arena_size, 1 do
            local pos = {x = x, y = y}
            local tile = surface.get_tile(pos.x, pos.y)
            if tile.name ~= 'water' and tile.name ~= 'deepwater' then
                if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then
                    if random(1, 3) ~= 1 then
                        insert(tiles, {name = 'water', position = pos})
                    end
                end
            end
        end
    end

    for x = current_arena_size, current_arena_size + shrink_width, 1 do
        for y = arena_size * -1, arena_size, 1 do
            local pos = {x = x, y = y}
            local tile = surface.get_tile(pos.x, pos.y)
            if tile.name ~= 'water' and tile.name ~= 'deepwater' then
                if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then
                    if random(1, 3) ~= 1 then
                        insert(tiles, {name = 'water', position = pos})
                    end
                end
            end
        end
    end

    this.current_arena_size = this.current_arena_size - 1

    surface.set_tiles(tiles, true)
end

local function get_arena_entity(surface, pos)
    local noise = get_noise('rocks', pos)
    local noise2 = get_noise('rocks_2', pos)

    if noise > -0.1 and noise < 0.1 and noise2 > -0.3 and noise2 < 0.3 then
        return {name = 'rock-big', position = pos}
    end

    if random(1, 16) == 1 and noise2 > 0.78 then
        if surface.can_place_entity({name = 'wooden-chest', position = pos, force = 'enemy'}) then
            return {name = 'wooden-chest', position = pos, force = 'enemy'}
        end
    end

    if random(1, 16) == 1 and noise2 < -0.78 then
        if surface.can_place_entity({name = 'wooden-chest', position = pos, force = 'enemy'}) then
            return {name = 'wooden-chest', position = pos, force = 'enemy'}
        end
    end

    if random(1, this.arena_layout_modifiers.arena_tree_chance) == 1 and noise > this.arena_layout_modifiers.arena_tree_noise then
        return {name = this.arena_layout_modifiers.arena_tree, position = pos}
    end

    if random(1, 1024) == 1 then
        if random(1, 16) == 1 then
            if surface.can_place_entity({name = this.arena_layout_modifiers.secret_entity, position = pos, force = 'enemy'}) then
                return {name = this.arena_layout_modifiers.secret_entity, position = pos, force = 'enemy'}
            end
        end
        if random(1, 64) == 1 then
            if surface.can_place_entity({name = 'big-worm-turret', position = pos, force = 'enemy'}) then
                return {name = 'big-worm-turret', position = pos, force = 'enemy'}
            end
        end
        if random(1, 32) == 1 then
            if surface.can_place_entity({name = 'medium-worm-turret', position = pos, force = 'enemy'}) then
                return {name = 'medium-worm-turret', position = pos, force = 'enemy'}
            end
        end
        if random(1, 512) == 1 then
            if surface.can_place_entity({name = 'behemoth-biter', position = pos, force = 'enemy'}) then
                return {name = 'behemoth-biter', position = pos, force = 'enemy'}
            end
        end
        if random(1, 64) == 1 then
            if surface.can_place_entity({name = 'big-biter', position = pos, force = 'enemy'}) then
                return {name = 'big-biter', position = pos, force = 'enemy'}
            end
        end
    end
end

local function render_arena_chunk(event)
    if not this.noise_seed then
        this.noise_seed = random(1, 2097152)
    end
    local surface = event.surface
    local left_top = event.area.left_top

    for _, entity in pairs(surface.find_entities_filtered({area = event.area})) do
        if entity and entity.valid then
            if entity.name ~= 'character' then
                entity.destroy()
            end
        end
    end

    local tiles = {}
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos = {x = left_top.x + x, y = left_top.y + y}
            if pos.x > arena_size or pos.y > arena_size or pos.x < arena_size * -1 or pos.y < arena_size * -1 then
                insert(tiles, {name = 'water', position = pos})
            else
                local noise = get_noise('terrain', pos)
                if noise > 0 then
                    insert(tiles, {name = this.arena_layout_modifiers.arena_tile_1, position = pos})
                else
                    insert(tiles, {name = this.arena_layout_modifiers.arena_tile_2, position = pos})
                end
                local entity = get_arena_entity(surface, pos)
                if entity then
                    surface.create_entity(entity)
                end
            end
        end
    end
    surface.set_tiles(tiles, true)
end

local function kill_idle_players()
    Core.iter_connected_players(
        function(player)
            if player.character then
                if player.afk_time > 600 then
                    local area = {{player.position.x - 1, player.position.y - 1}, {player.position.x + 1, player.position.y + 1}}
                    local water_tile_count = player.surface.count_tiles_filtered({name = {'water', 'deepwater'}, area = area})
                    if water_tile_count and water_tile_count > 3 then
                        player.character.die()
                        game.print(player.name .. ' drowned.', {r = 150, g = 150, b = 0})
                    else
                        if player.afk_time > 9000 then
                            player.character.die()
                            game.print(player.name .. ' was idle for too long.', {r = 150, g = 150, b = 0})
                        end
                    end
                end
            end
        end
    )
end

local function check_for_game_over()
    kill_idle_players()

    local alive_players = 0

    create_tank_battle_score_gui()

    Core.iter_connected_players(
        function(player)
            if player.character and player.driving then
                alive_players = alive_players + 1
            end
        end
    )

    if alive_players > 1 then
        return
    end

    local player
    Core.iter_connected_players(
        function(player_amp)
            if player_amp.character and player_amp.driving then
                player = player_amp
            end
        end
    )

    if alive_players == 1 then
        if not this.tank_battles_score[player.index] then
            this.tank_battles_score[player.index] = 1
        else
            this.tank_battles_score[player.index] = this.tank_battles_score[player.index] + 1
        end
        game.print(player.name .. ' has won the battle!', {r = 150, g = 150, b = 0})
        Server.to_discord_embed(player.name .. ' has won the battle!')
        create_tank_battle_score_gui()
    end

    if alive_players == 0 then
        game.print('No players alive! Round ends in a draw!', {r = 150, g = 150, b = 0})
        Server.to_discord_embed('No players alive! Round ends in a draw!')
    end

    this.game_stage = 'lobby'
end

local function set_unique_player_force(player)
    local player_force = game.forces[player.name]
    if not player_force then
        player_force = game.create_force(player.name)
        player_force.share_chart = false
        player_force.clear_chart(player.surface.name)
        player_force.technologies['follower-robot-count-1'].researched = true
        player_force.technologies['follower-robot-count-2'].researched = true
        player_force.technologies['follower-robot-count-3'].researched = true
        player_force.technologies['follower-robot-count-4'].researched = true
        player_force.technologies['follower-robot-count-5'].researched = true
    end
    player.force = player_force
end

local function remove_unique_player_force(player)
    if not player or not player.valid then
        return
    end

    local player_force = game.forces[player.name]
    local enemy_force = game.forces.enemy
    if player_force then
        print('remove_unique_player_force - removing force with name: ' .. player.name)
        game.merge_forces(player_force, enemy_force)
    end
end

local function on_chunk_charted(event)
    local force = event.force
    local surface = game.get_surface('nauvis')

    if not surface or not surface.valid then
        return
    end
    if force.valid then
        force.clear_chart(surface)
    end
end

local function check_obsolete_forces()
    for _, force in pairs(game.forces) do
        if force and force.valid then
            if force.name ~= 'enemy' and force.name ~= 'player' and force.name ~= 'neutral' then
                if #force.connected_players == 0 then
                    remove_unique_player_force(force)
                end
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)

    set_unique_player_force(player)

    create_gui(player)

    create_tank_battle_score_gui()

    player.map_view_settings = {
        ['show-player-names'] = false
    }
    player.show_on_map = false
    local game_view_settings = {
        show_minimap = false
    }
    player.game_view_settings = game_view_settings

    if player.character then
        player.character.destroy()
    end

    if this.game_stage == 'ongoing_game' then
        player.print("There is currently an ongoing match - please wait until it's over.")
    end

    local permissions_group = game.permissions.get_group('Spectator')
    permissions_group.add_player(player.name)
    player.teleport({0, 0}, 'nauvis')
end

local function on_player_driving_changed_state(event)
    local player = game.get_player(event.player_index)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if not player.driving then
        entity.set_driver(player)
    end
end

local function on_player_left_game(event)
    local player = game.get_player(event.player_index)

    remove_unique_player_force(player)
end

local function on_marked_for_deconstruction(event)
    local entity = event.entity
    if entity and entity.valid then
        local player = game.get_player(event.player_index)
        entity.cancel_deconstruction(player.force.name)
    end
end

local function on_chunk_generated(event)
    render_arena_chunk(event)
end

local function on_player_respawned(event)
    local player = game.get_player(event.player_index)

    local permissions_group = game.permissions.get_group('Spectator')
    permissions_group.add_player(player.name)
    player.character.destroy()
    player.character = nil

    player.print('You are now spectating.', {r = 0, g = 150, b = 150})
end

local function lobby()
    local connected_players_count = #game.connected_players

    if connected_players_count < 2 then
        Core.iter_connected_players(
            function(player)
                create_gui(player)
                local gui = player.gui.left.status_players
                if gui and gui.valid then
                    gui.visible = true
                end
            end
        )
        return
    end

    Core.iter_connected_players(
        function(player)
            local gui = player.gui.left.status_players
            if gui and gui.valid then
                gui.visible = false
            end
        end
    )

    if not this.lobby_timer then
        this.lobby_timer = 1200
    end
    if this.lobby_timer % 600 == 0 then
        if this.lobby_timer <= 0 then
            game.print('Round has started!', {r = 0, g = 150, b = 150})
            Server.to_discord_embed('Round has started!')
        else
            game.print('Round will begin in ' .. this.lobby_timer / 60 .. ' seconds.', {r = 0, g = 150, b = 150})
            Server.to_discord_embed('Round will begin in ' .. this.lobby_timer / 60 .. ' seconds.')
        end
    end
    this.lobby_timer = this.lobby_timer - 300
    if this.lobby_timer >= 0 then
        return
    end
    this.lobby_timer = nil
    this.game_stage = 'regenerate_arena'
end

local function on_tick()
    local tick = game.tick
    if tick % 300 == 0 then
        if this.game_stage == 'lobby' then
            lobby()
        end
        if this.game_stage == 'regenerate_arena' then
            regenerate_arena()
        end
        if this.game_stage == 'ongoing_game' then
            shrink_arena()
            check_for_game_over()
        end
    end
    if tick % 1000 == 0 then
        check_obsolete_forces()
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if entity.name == 'wooden-chest' then
        local loot_amp = loot_raffle[random(1, #loot_raffle)]
        entity.surface.spill_item_stack(entity.position, loot_amp, true)
    end
end

local function on_player_died(event)
    local player = game.get_player(event.player_index)
    local str = ' '
    if event.cause then
        if event.cause.name ~= nil then
            str = ' by ' .. event.cause.name
        end
        if event.cause.name == 'character' then
            str = ' by ' .. event.cause.player.name
        end
        if event.cause.name == 'tank' then
            local driver = event.cause.get_driver()
            if driver.player then
                str = ' by ' .. driver.player.name
            end
        end
    end
    Core.iter_connected_players(
        function(target_player)
            if target_player.name ~= player.name then
                player.print(player.name .. ' was killed' .. str, {r = 0.99, g = 0.0, b = 0.0})
            end
        end
    )
end

local function on_console_chat(event)
    if not event.message then
        return
    end
    if not event.player_index then
        return
    end
    local player = game.get_player(event.player_index)

    local color = player.color
    color.r = color.r * 0.6 + 0.35
    color.g = color.g * 0.6 + 0.35
    color.b = color.b * 0.6 + 0.35
    color.a = 1

    Core.iter_connected_players(
        function(target_player)
            if target_player.name ~= player.name then
                target_player.print(player.name .. ': ' .. event.message, color)
            end
        end
    )
end

Event.on_init(
    function()
        local surface = game.get_surface('nauvis')
        local mgs = surface.map_gen_settings
        mgs.width = 400
        mgs.height = 400
        surface.map_gen_settings = mgs
        surface.clear()

        local spectator_permission_group = game.permissions.create_group('Spectator')
        for action_name, _ in pairs(defines.input_action) do
            spectator_permission_group.set_allows_action(defines.input_action[action_name], false)
        end
        spectator_permission_group.set_allows_action(defines.input_action.write_to_console, true)
        spectator_permission_group.set_allows_action(defines.input_action.gui_click, true)
        spectator_permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
        spectator_permission_group.set_allows_action(defines.input_action.start_walking, true)
        spectator_permission_group.set_allows_action(defines.input_action.open_character_gui, true)
        spectator_permission_group.set_allows_action(defines.input_action.edit_permission_group, true)
        spectator_permission_group.set_allows_action(defines.input_action.toggle_show_entity_info, true)

        get_arena_layout_modifiers()

        this.tank_battles_score = {}
        this.game_stage = 'lobby'

        local T = Map.Pop_info()
        T.main_caption = 'The eternal battle of tanks'
        T.sub_caption = 'a playground made for tanks'
        T.text =
            table.concat(
            {
                'The opponent wants your tank destroyed! Destroy their tank to win the round!\n',
                '\n',
                "The tank doors has oddly malfunctioned and you're locked inside.\n",
                '\n',
                'Destroying wooden chests seems to grant loot.\n'
            }
        )
    end
)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_chunk_charted, on_chunk_charted)
