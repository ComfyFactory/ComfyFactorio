--created by Gerkiz
local Public = require 'maps.infestation_islands.table'
local Event = require 'utils.event'
local Func = require 'maps.infestation_islands.func'
local Map = require 'modules.map_info'
local Task = require 'utils.task_token'
local Scheduler = require 'utils.scheduler'

local set_gamestate_token =
    Task.register(
        function ()
            local this = Public.get()
            this.gamestate = 1
        end
    )

local reset_players_token =
    Task.register(
        function ()
            local surface = game.get_surface(1)

            for _, f in pairs(game.forces) do
                f.reset()
                f.clear_chart(surface)
                f.reset_evolution()
            end
            for _, tech in pairs(game.forces.player.technologies) do
                tech.researched = false
                tech.saved_progress = 0
            end

            local players = game.connected_players
            for i = 1, #players do
                local player = players[i]
                player.set_controller { type = defines.controllers.god }
                player.create_character()
                player.insert({ name = 'raw-fish', count = 3 })
                player.insert({ name = 'grenade', count = 1 })
                player.insert({ name = 'iron-plate', count = 16 })
                player.insert({ name = 'iron-gear-wheel', count = 8 })
                player.insert({ name = 'stone', count = 5 })
                player.insert({ name = 'pistol', count = 1 })
                player.insert({ name = 'firearm-magazine', count = 16 })

                local p = surface.find_non_colliding_position('character', { 0, 2 }, 8, 0.5)
                if not p then
                    player.teleport({ 0, 2 }, surface)
                else
                    player.teleport(p, surface)
                end
            end
        end
    )

local function create_stage_gui(player)
    if player.gui.top.stage_gui then
        return
    end
    local element = player.gui.top.add({ type = 'frame', name = 'stage_gui', caption = ' ' })
    local style = element.style
    style.minimal_height = 54
    style.maximal_height = 54
    style.minimal_width = 140
    style.maximal_width = 420
    style.top_padding = 12
    style.left_padding = 4
    style.right_padding = 4
    style.bottom_padding = 2
    style.font_color = { r = 155, g = 85, b = 25 }
    style.font = 'default-large-bold'
end

local function update_stage_gui(caption_override)
    local this = Public.get()
    if not this.stages then
        return
    end
    local caption = 'Level: ' .. this.current_level
    caption = caption .. '  |  Stage: '
    local stage = this.current_stage
    if stage > #this.stages - 1 then
        stage = #this.stages - 1
    end
    caption = caption .. stage
    caption = caption .. '/'
    caption = caption .. #this.stages - 1
    caption = caption .. '  |  Bugs remaining: '
    caption = caption .. this.alive_enemies


    for _, player in pairs(game.connected_players) do
        if player.gui.top.stage_gui then
            player.gui.top.stage_gui.caption = caption_override or caption
            player.gui.top.stage_gui.tooltip = 'Max biter count: ' .. this.max_biters_per_island
        end
    end
end

local function bring_players()
    local surface = game.surfaces[1]
    for _, player in pairs(game.connected_players) do
        if player.position.y < -1 then
            if player.character then
                if player.character.valid then
                    local p = surface.find_non_colliding_position('character', { 0, 2 }, 8, 0.5)
                    if not p then
                        player.teleport({ 0, 2 }, surface)
                    else
                        player.teleport(p, surface)
                    end
                end
            end
        end
    end
    local this = Public.get()
    this.gamestate = 2
end

local function drift_corpses_toward_beach()
    local surface = game.surfaces[1]
    for _, corpse in pairs(surface.find_entities_filtered({ name = 'character-corpse' })) do
        if corpse.position.y < 0 then
            if surface.get_tile(corpse.position.x, corpse.position.y).collides_with('resource') then
                corpse.clone
                {
                    position = { corpse.position.x, corpse.position.y + (math.random(50, 250) * 0.01) },
                    surface = surface,
                    force = corpse.force.name
                }
                corpse.destroy()
            end
        end
    end
end

local function clear_surface()
    local surface = game.get_surface(1)
    surface.clear()
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    create_stage_gui(player)

    update_stage_gui()

    if player.online_time == 0 then
        player.insert({ name = 'raw-fish', count = 3 })
        player.insert({ name = 'grenade', count = 1 })
        player.insert({ name = 'iron-plate', count = 16 })
        player.insert({ name = 'iron-gear-wheel', count = 8 })
        player.insert({ name = 'stone', count = 5 })
        player.insert({ name = 'pistol', count = 1 })
        player.insert({ name = 'firearm-magazine', count = 16 })
        return
    end
end

local function on_init()
    local storage = Public.get()
    for index, _ in pairs(storage) do
        storage[index] = nil
    end
    local T = Map.Pop_info()
    T.localised_category = 'infestation_islands'
    T.main_caption_color = { r = 150, g = 150, b = 0 }
    T.sub_caption_color = { r = 0, g = 150, b = 0 }

    Scheduler.can_run_scheduler(true)

    local this = Public.get()

    this.game_lost = false

    local surface = game.surfaces[1]
    surface.request_to_generate_chunks({ x = 0, y = 0 }, 6)

    local mgs = game.surfaces[1].map_gen_settings
    mgs.water = 9.9
    mgs.property_expression_names =
    {
        ['control-setting:aux:bias'] = '0.500000',
        ['control-setting:aux:frequency:multiplier'] = '6.000000',
        ['control-setting:moisture:bias'] = '-0.050000',
        ['control-setting:moisture:frequency:multiplier'] = '6.000000',
    }
    game.surfaces[1].map_gen_settings = mgs

    local blacklist =
    {
        ['dark-mud-decal'] = true,
        ['sand-dune-decal'] = true,
        ['light-mud-decal'] = true,
        ['puberty-decal'] = true,
        ['sand-decal'] = true,
        ['red-desert-decal'] = true
    }
    this.decorative_names = {}
    for k, v in pairs(prototypes.decorative) do
        if not blacklist[k] then
            if v.autoplace_specification then
                this.decorative_names[#this.decorative_names + 1] = k
            end
        end
    end

    local tree_raffle = {}
    for _, e in pairs(prototypes.entity) do
        if e.type == 'tree' then
            table.insert(tree_raffle, e.name)
        end
    end

    this.tree_raffle = tree_raffle

    local corpses_raffle = {}
    for _, e in pairs(prototypes.entity) do
        if e.type == 'corpse' then
            table.insert(corpses_raffle, e.name)
        end
    end

    this.corpses_raffle = corpses_raffle

    this.stages = {}
    this.last_level = 10
    local island_level = 12
    for _ = 1, this.last_level + 1 do
        this.stages[#this.stages + 1] =
        {
            size = 16 + (32 + island_level) * 1.5
        }
        island_level = island_level + 5
    end

    this.stages[#this.stages].final = true

    this.final_battle = false

    this.level_vectors = {}
    this.alive_boss_enemy_entities = {}
    this.current_level = 0
    this.gamestate = 0
    Task.set_timeout_in_ticks(30, set_gamestate_token)

    game.forces.player.set_spawn_position({ 0, 2 }, surface)

    this.alive_enemies = 0
    this.alive_boss_enemy_count = 0

    this.current_level = this.current_level + 1
    this.current_stage = 1

    this.completed_levels = {}

    this.market_positions = {}

    this.centered_points = {}

    this.tiles = {}

    this.spawned_markets = {}

    this.path_tiles = nil

    this.max_biters_per_island = 150

    this.seeds = nil

    this.nomed_marked = nil

    this.loot_stats =
    {
        rare = 48,
        normal = 48
    }

    this.infinite_ammo_grants = 1

    this.piercing_ammo_grants = false

    this.last_attack_tick = game.tick

    Func.reset_buried_biters()

    surface.freeze_daytime = false
    surface.ticks_per_day = 25200

    game.forces['player'].technologies['landfill'].enabled = false
    game.forces['player'].technologies['night-vision-equipment'].enabled = false
    game.forces['player'].technologies['artillery-shell-range-1'].enabled = false
    game.forces['player'].technologies['artillery-shell-speed-1'].enabled = false
    game.forces['player'].technologies['artillery'].enabled = false
    game.forces['player'].technologies['atomic-bomb'].enabled = false
end

local gamestate_functions =
{
    [1] = bring_players,
    [2] = Func.draw_main_island,
}

local function on_tick()
    local this = Public.get()
    if game.tick % 25 == 0 and gamestate_functions[this.gamestate] then
        gamestate_functions[this.gamestate]()
    end
    if game.tick % 25 == 0 then
        if this.alive_enemies < 0 then this.alive_enemies = 0 end
        if this.game_lost then
            local message = this.nomed_marked and 'The bugs had a feast on the marked at level ' .. this.nomed_marked .. '!' or 'The bugs had a feast on the marked!'
            update_stage_gui(message)
        else
            update_stage_gui()
        end
    end
    if game.tick % 150 == 0 then
        drift_corpses_toward_beach()
        if this.infini_chest and this.infini_chest.valid then
            local magazine_name = 'firearm-magazine'
            if this.piercing_ammo_grants then
                magazine_name = 'piercing-rounds-magazine'
            end

            this.infini_chest.insert({ name = magazine_name, count = this.infinite_ammo_grants or 1 })
        end
    end

    if game.tick % 200 == 0 then
        if this.game_lost then return end
        Func.check_alive_enemies()
        Func.set_multi_command()
        if this.completed_levels[this.current_level] then
            return
        end

        Func.do_buried_biters()
    end


    if (this.game_lost or this.game_won) and this.game_reset_tick then
        this.game_reset_tick = this.game_reset_tick - 1
        if this.game_reset_tick % 600 == 0 then
            game.print('Game will reset in ' .. this.game_reset_tick / 60 .. ' seconds!', { color = { r = 0.22, g = 0.88, b = 0.22 } })
        end
        if this.game_reset_tick <= 0 then
            if this.render_ammo_text then
                this.render_ammo_text.destroy()
                this.render_ammo_text = nil
            end
            if this.infini_chest and this.infini_chest.valid then
                this.infini_chest.destroy()
                this.infini_chest = nil
            end

            for _, market_data in pairs(this.spawned_markets) do
                if market_data and market_data.market and market_data.market.valid then
                    if market_data.render_protect_text then
                        market_data.render_protect_text.destroy()
                        market_data.render_protect_text = nil
                    end
                    if market_data.render_checkpoint_text then
                        market_data.render_checkpoint_text.destroy()
                        market_data.render_checkpoint_text = nil
                    end
                    market_data.market.destroy()
                end
            end

            this.game_reset_tick = nil
            this.game_lost = false
            this.game_won = false
            Scheduler.can_run_scheduler(false)
            clear_surface()
            on_init()
            Task.set_timeout_in_ticks(500, reset_players_token)
        end
    end
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
