--map by gerkiz and kyte
--luacheck: ignore
local Event = require 'utils.event'
require 'maps.wip.func'
local Map = require 'modules.map_info'
local Task = require 'utils.task_token'
max_island_radius = 256

local set_gamestate_token =
    Task.register(
    function()
        global.gamestate = 1
    end
)

local function create_stage_gui(player)
    if player.gui.top.stage_gui then
        return
    end
    local element = player.gui.top.add({type = 'frame', name = 'stage_gui', caption = ' '})
    local style = element.style
    style.minimal_height = 38
    style.maximal_height = 38
    style.minimal_width = 140
    style.top_padding = 2
    style.left_padding = 4
    style.right_padding = 4
    style.bottom_padding = 2
    style.font_color = {r = 155, g = 85, b = 25}
    style.font = 'default-large-bold'
end

function update_stage_gui()
    if not global.stages then
        return
    end
    local caption = 'Level: ' .. global.current_level
    caption = caption .. '  |  Stage: '
    local stage = global.current_stage
    if stage > #global.stages - 1 then
        stage = #global.stages - 1
    end
    caption = caption .. stage
    caption = caption .. '/'
    caption = caption .. #global.stages - 1
    caption = caption .. '  |  Bugs remaining: '
    caption = caption .. global.alive_enemies

    for _, player in pairs(game.connected_players) do
        if player.gui.top.stage_gui then
            player.gui.top.stage_gui.caption = caption
        end
    end
end

local function bring_players()
    local surface = game.surfaces[1]
    for _, player in pairs(game.connected_players) do
        if player.position.y < -1 then
            if player.character then
                if player.character.valid then
                    local p = surface.find_non_colliding_position('character', {0, 2}, 8, 0.5)
                    if not p then
                        player.teleport({0, 2}, surface)
                    end
                    player.teleport(p, surface)
                end
            end
        end
    end
end

local function drift_corpses_toward_beach()
    local surface = game.surfaces[1]
    for _, corpse in pairs(surface.find_entities_filtered({name = 'character-corpse'})) do
        if corpse.position.y < 0 then
            if surface.get_tile(corpse.position).collides_with('resource-layer') then
                corpse.clone {
                    position = {corpse.position.x, corpse.position.y + (math.random(50, 250) * 0.01)},
                    surface = surface,
                    force = corpse.force.name
                }
                corpse.destroy()
            end
        end
    end
end

local function set_next_level()
    global.alive_enemies = 0
    global.alive_boss_enemy_count = 0

    global.current_level = global.current_level + 1
    if global.current_level > 1 then
        bring_players()
    end

    global.current_stage = 1

    global.path_tiles = nil

    --game.print("Level " .. global.current_level)
    update_stage_gui()

    global.gamestate = 2
end

local function earn_credits(amount)
    for _, player in pairs(game.connected_players) do
        player.play_sound {path = 'utility/armor_insert', volume_modifier = 0.85}
    end
    game.print(amount .. ' credits have been transfered to the factory.', {r = 255, g = 215, b = 0})
    global.credits = global.credits + amount
end

local function wait_until_stage_is_beaten()
    if global.alive_enemies >= 0 then
        return
    end
    local reward_amount
    local gamestate = 2
    local base_reward = 250 * global.current_level

    if global.stages[global.current_stage].size then
        if global.current_stage < #global.stages - 1 then
            reward_amount = base_reward + global.current_stage * global.current_level * 50
        else
            reward_amount = base_reward + global.current_stage * global.current_level * 150
        end
    else
        game.print('Final Stage complete!')
        game.print('Level is collapsing!!', {r = 255, g = 0, b = 0})
        gamestate = 6
    end

    if reward_amount then
        earn_credits(reward_amount)
        update_stage_gui()
    end
    global.current_stage = global.current_stage + 1
    global.gamestate = gamestate
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    -- create_stage_gui(player)

    -- update_stage_gui()

    if player.online_time > 0 then
        return
    end
    player.insert({name = 'pistol', count = 1})
    player.insert({name = 'firearm-magazine', count = 32})
end

local function on_init()
    local T = Map.Pop_info()
    T.localised_category = 'wip'
    T.main_caption_color = {r = 150, g = 150, b = 0}
    T.sub_caption_color = {r = 0, g = 150, b = 0}

    game.create_force('enemy_spawners')
    game.forces.enemy_spawners.set_friend('enemy', true)
    game.forces.enemy.set_friend('enemy_spawners', true)

    local surface = game.surfaces[1]
    surface.request_to_generate_chunks({x = 0, y = 0}, 6)

    local mgs = game.surfaces[1].map_gen_settings
    mgs.water = 9.9
    mgs.property_expression_names = {
        ['control-setting:aux:bias'] = '0.500000',
        ['control-setting:aux:frequency:multiplier'] = '6.000000',
        ['control-setting:moisture:bias'] = '-0.050000',
        ['control-setting:moisture:frequency:multiplier'] = '6.000000',
        elevation = '0_17-island'
    }
    game.surfaces[1].map_gen_settings = mgs

    local blacklist = {
        ['dark-mud-decal'] = true,
        ['sand-dune-decal'] = true,
        ['light-mud-decal'] = true,
        ['puberty-decal'] = true,
        ['sand-decal'] = true,
        ['red-desert-decal'] = true
    }
    global.decorative_names = {}
    for k, v in pairs(game.decorative_prototypes) do
        if not blacklist[k] then
            if v.autoplace_specification then
                global.decorative_names[#global.decorative_names + 1] = k
            end
        end
    end

    global.shopping_chests = {}
    global.dump_chests = {}
    global.registerd_shopping_chests = {}
    global.credits = 0
    game.create_force('shopping_chests')
    game.forces.player.set_friend('shopping_chests', true)
    game.forces.shopping_chests.set_friend('player', true)

    local tree_raffle = {}
    for _, e in pairs(game.entity_prototypes) do
        if e.type == 'tree' then
            table.insert(tree_raffle, e.name)
        end
    end

    global.tree_raffle = tree_raffle

    local corpses_raffle = {}
    for _, e in pairs(game.entity_prototypes) do
        if e.type == 'corpse' then
            table.insert(corpses_raffle, e.name)
        end
    end

    global.corpses_raffle = corpses_raffle

    global.stages = {}
    local island_level = 12
    for _ = 1, 20 do
        global.stages[#global.stages + 1] = {
            size = 16 + (32 + island_level) * 1.5
        }
        island_level = island_level + 5
    end

    global.stages[#global.stages].final = true

    global.level_vectors = {}
    global.alive_boss_enemy_entities = {}
    global.current_level = 0
    global.gamestate = 0
    Task.set_timeout_in_ticks(30, set_gamestate_token)

    game.forces.player.set_spawn_position({0, 2}, surface)
end

local gamestate_functions = {
    [1] = set_next_level,
    [2] = draw_main_island,
    [3] = draw_the_island,
    [4] = wait_until_stage_is_beaten
}

local function on_tick()
    if game.tick % 25 == 0 and gamestate_functions[global.gamestate] then
        gamestate_functions[global.gamestate]()
    end
    if game.tick % 150 == 0 then
        drift_corpses_toward_beach()
        if global.infini_chest and global.infini_chest.valid then
            global.infini_chest.insert({name = 'firearm-magazine', count = 1})
        end
    end
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
