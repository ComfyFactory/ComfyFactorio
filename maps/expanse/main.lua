-- a map where you feed hungry boxes, which unlocks new territory, with even more hungry boxes by mewmew

--CONFIGS
local cell_size = 15                 -- size of each territory to unlock
local chance_to_receive_token = 0.20 -- chance of a hungry chest, dropping a token after unlocking, can be above 1 for multiple

local SA = script.active_mods['space-age']
require 'modules.backpack_research'

local Event = require 'utils.event'
local Functions = require 'maps.expanse.functions'
local SpaceMissions = require 'maps.expanse.space_missions'
local MissionData = require 'maps.expanse.mission_data'
local GetNoise = require 'utils.math.get_noise'
local Global = require 'utils.global'
local Map_info = require 'modules.map_info'
local Gui = require 'utils.gui'
local format_number = require 'util'.format_number
local Autostash = require 'modules.autostash'
local FT = require 'utils.functions.flying_texts'
local Raffle = require 'utils.math.raffle'
local Reset = require 'utils.functions.soft_reset'

local expanse = {
    events = {
        gui_update = Event.generate_event_name('expanse_gui_update'),
        mission_gui_update = Event.generate_event_name('expanse_missions_gui_update'),
        invasion_warn = Event.generate_event_name('invasion_warn'),
        invasion_detonate = Event.generate_event_name('invasion_detonate'),
        invasion_trigger = Event.generate_event_name('invasion_trigger'),
        victory = Event.generate_event_name('victory'),
        map_reset = Event.generate_event_name('expanse_map_reset')
    }
}
Global.register(
    expanse,
    function (tbl)
        expanse = tbl
    end
)

local main_button_name = Gui.uid_name()
local missions_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local close_main_frame_button_name = Gui.uid_name()
local missions_frame_name = Gui.uid_name()
local close_missions_button_name = Gui.uid_name()

local function create_button(player)
    local buttons = {}
    if Gui.get_mod_gui_top_frame() then
        buttons[1] =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = main_button_name,
                    sprite = 'item/requester-chest',
                    tooltip = {'expanse.stats_button'},
                    style = Gui.button_style
                }
            )
        buttons[2] = Gui.add_mod_button(
            player,
            {
                type = 'sprite-button',
                name = missions_button_name,
                sprite = 'item/rocket-part',
                tooltip = {'expanse.missions_button'},
                style = Gui.button_style
            }
        )
        for _, button in pairs(buttons) do
            button.style.font_color = { 165, 165, 165 }
            button.style.font = 'default-semibold'
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 40
            button.style.padding = -2
        end
    else
        buttons[1] =
            player.gui.top[main_button_name] or
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    sprite = 'item/requester-chest',
                    name = main_button_name,
                    tooltip = {'expanse.stats_button'},
                    style = Gui.button_style
                }
            )
        buttons[2] =
            player.gui.top[main_button_name] or
            player.gui.top.add(
                player,
                {
                    type = 'sprite-button',
                    name = missions_button_name,
                    sprite = 'item/rocket-part',
                    tooltip = {'expanse.missions_button'},
                    style = Gui.button_style
                }
            )
        for _, button in pairs(buttons) do
            button.style.font_color = { r = 0.11, g = 0.8, b = 0.44 }
            button.style.font = 'heading-1'
            button.style.minimal_height = 40
            button.style.maximal_width = 40
            button.style.minimal_width = 38
            button.style.maximal_height = 38
            button.style.padding = 1
            button.style.margin = 0
        end
    end
end

local function set_nauvis()
    local surface = game.surfaces[1]
    local map_gen_settings = surface.map_gen_settings
    map_gen_settings.autoplace_controls = {
        ['coal'] = { frequency = 6, size = 0.7, richness = 0.5 },
        ['stone'] = { frequency = 6, size = 0.4, richness = 0.5 },
        ['copper-ore'] = { frequency = 6, size = 0.7, richness = 0.95 },
        ['iron-ore'] = { frequency = 6, size = 0.7, richness = 1 },
        ['uranium-ore'] = { frequency = 10, size = 0.7, richness = 1 },
        ['crude-oil'] = { frequency = 20, size = 1.5, richness = 1.5 },
        ['trees'] = { frequency = 1.75, size = 1.25, richness = 1 },
        ['enemy-base'] = { frequency = 10, size = 10, richness = 2 },
        ['water'] = {frequency = 12, size = 0.25 , richness = 1}
    }
    map_gen_settings.seed = math.random(1, 4000000000)
    map_gen_settings.starting_area = 0.08
    surface.map_gen_settings = map_gen_settings
    for chunk in surface.get_chunks() do
        surface.delete_chunk({ chunk.x, chunk.y })
    end
end

local function reset()
    expanse.grid = {}
    expanse.containers = {}
    expanse.cost_stats = {}
    expanse.rocket_silos = {}
    expanse.missions = {
        [4] = {level = 0, delivered = {}},
        [5] = {level = 0, delivered = {}},
        [6] = {level = 0, delivered = {}},
        [7] = {level = 0, delivered = {}},
        [8] = {level = 0, delivered = {}},
        [9] = {level = 0, delivered = {}},
        [10] = {level = 0, delivered = {}},
    }
    expanse.landing_pad = nil
    expanse.space_platform = nil
    expanse.nonspace_pad = nil
    expanse.space_production = {}
    expanse.cargo_pods = {}
    expanse.invasion_candidates = {}
    expanse.lightning_tiles = {}
    expanse.schedule = {}
    expanse.size = 1
    expanse.reset_tick = 0
    expanse.tree = nil
    expanse.rock = nil
    expanse.acid_tank = nil
    expanse.biome_offset = math.random(1, 4)
    expanse.tiered_specials = {
        [1] = {unlocks = 0, tiles = 0},
        [2] = {unlocks = 0, tiles = 0},
        [3] = {unlocks = 4, tiles = 0}, --uranium guaranteed
        [4] = {unlocks = 2, tiles = 0}, --landing pad and silo
        [5] = {unlocks = SA and 5 or 1, tiles = 0}, --silos
        [6] = {unlocks = 80, tiles = 0}, --vulcanus
        [7] = {unlocks = 80, tiles = 0}, --fulgora
        [8] = {unlocks = 80, tiles = 0}, --gleba
        [9] = {unlocks = 80, tiles = 0}, --aquilo
        [10] = {unlocks = 50000, tiles = 0, specials = 1}, --all

    }
    Autostash.insert_into_furnace(true)

    local map_gen_settings = {
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] = {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = { treat_missing_as_default = false },
            ['decorative'] = { treat_missing_as_default = true, settings = {}}
        },
        autoplace_controls = {
            ['coal'] = { frequency = 0, size = 0, richness = 0 },
            ['stone'] = { frequency = 0, size = 0, richness = 0 },
            ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['crude-oil'] = { frequency = 0, size = 0, richness = 0 },
            ['trees'] = { frequency = 0, size = 0, richness = 0 },
            ['enemy-base'] = { frequency = 0, size = 0, richness = 0 }
        }
    }
    if not expanse.active_surface_index then
        expanse.active_surface_index = game.create_surface('expanse', map_gen_settings).index
    else
        game.forces.player.set_spawn_position({8, 8}, game.surfaces[expanse.active_surface_index])
        expanse.active_surface_index = Reset.soft_reset_map(game.surfaces[expanse.active_surface_index], map_gen_settings, {}).index
        expanse.reset_tick = game.tick
    end
    local surface = game.surfaces[expanse.active_surface_index]
    surface.ignore_surface_conditions = true

    if expanse.override_nauvis then
        set_nauvis()
    end

    local source_surface = game.surfaces[expanse.source_surface]
    source_surface.request_to_generate_chunks({ x = 0, y = 0 }, 4)
    source_surface.force_generate_chunk_requests()
    game.forces.player.set_surface_hidden(source_surface, true)

    surface.request_to_generate_chunks({ x = 0, y = 0 }, 4)
    surface.force_generate_chunk_requests()
    local techs = game.forces.player.technologies
    techs['atomic-bomb'].enabled = false
    for _, tech in pairs(MissionData.locked_techs) do
        techs[tech].enabled = false
        techs[tech].visible_when_disabled = true
    end

    for _, player in pairs(game.players) do
        player.teleport({ -4, -4 }, source_surface)
    end
    if SA then
        SpaceMissions.init_space(expanse)
    else
        SpaceMissions.init_nonspace(expanse)
    end

    Functions.expand(expanse, { x = 0, y = 0 })

    for _, player in pairs(game.players) do
        player.teleport(surface.find_non_colliding_position('character', { expanse.square_size * 0.5, expanse.square_size * 0.5 }, 8, 0.5) or {5, 5}, surface)
    end
    script.raise_event(expanse.events.mission_gui_update, {})
end

local ores = { 'copper-ore', 'iron-ore', 'stone', 'coal', 'iron-ore', 'copper-ore', 'coal' }
local function generate_ore(surface, left_top)
    local seed = game.surfaces[1].map_gen_settings.seed
    local left_top_x = left_top.x
    local left_top_y = left_top.y

    --Draw the mixed ore patches.
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos = { x = left_top_x + x, y = left_top_y + y }
            if surface.can_place_entity({ name = 'iron-ore', position = pos }) then
                local noise = GetNoise('smol_areas', pos, seed)
                if math.abs(noise) > 0.78 or math.abs(noise) < 0.11 then
                    local amount = 500 + math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 4
                    local i = math.floor(noise * 40 + math.abs(pos.x) * 0.05) % 7 + 1
                    surface.create_entity({ name = ores[i], position = pos, amount = amount })
                end
            end
        end
    end
end

local function on_resource_depleted(event)
    local ore = event.entity
    if ore and ore.valid then
        local distance = math.sqrt(ore.position.x ^ 2 + ore.position.y ^ 2)
        if ore.name == 'stone' and distance > 100 then
            if math.random(1, 4) == 1 then
                ore.surface.create_entity({ name = 'uranium-ore', position = ore.position, amount = 200 + math.floor(distance) * math.random(1, 3) })
            end
        end
    end
end

local function on_chunk_generated(event)
    local surface = event.surface

    if string.sub(surface.name, 0, 7) ~= 'expanse' then
        if expanse.override_nauvis then
            if surface.index == 1 then
                for _, e in pairs(surface.find_entities_filtered({ area = event.area, name = { 'iron-ore', 'copper-ore', 'coal', 'stone', 'uranium-ore' } })) do
                    surface.create_entity({ name = e.name, position = e.position, amount = 500 + math.sqrt(e.position.x ^ 2 + e.position.y ^ 2) * 3 })
                    e.destroy()
                end
                generate_ore(surface, event.area.left_top)
                for _, unit in pairs(surface.find_entities_filtered({ area = event.area, type = { 'unit', 'turret', 'unit-spawner', 'fish' }, force = { 'enemy', 'neutral' } })) do
                    unit.active = false
                end
            end
        end
        return
    end
    local left_top = event.area.left_top
    local tiles = {}
    local i = 1

    if left_top.x == 0 and left_top.y == 0 then
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                if x >= expanse.square_size or y >= expanse.square_size then
                    tiles[i] = { name = 'out-of-map', position = { left_top.x + x, left_top.y + y } }
                    i = i + 1
                end
            end
        end
    else
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                tiles[i] = { name = 'out-of-map', position = { left_top.x + x, left_top.y + y } }
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)
end

local function on_area_cloned(event)
    local source_surface = event.source_surface
    local dest_surface = event.destination_surface
    for _, cloned_entity in pairs(dest_surface.find_entities(event.destination_area)) do
        cloned_entity.active = true
        if cloned_entity.type == 'unit-spawner' then
            Functions.spawn_units(cloned_entity)
        end
    end
    for _, source_entity in pairs(source_surface.find_entities(event.source_area)) do
        source_entity.destroy()
    end
end

local function container_opened(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end
    if entity.force.index ~= 3 then
        return
    end
    local expansion_position = Functions.set_container(expanse, entity)
    if expansion_position then
        local player = game.players[event.player_index]
        local surface = game.get_surface(player.surface.name)
        if not surface or not surface.valid then return end
        local colored_player_name = { 'expanse.colored_text', player.color.r * 0.6 + 0.35, player.color.g * 0.6 + 0.35, player.color.b * 0.6 + 0.35, player.name }
        game.print({ 'expanse.tile_unlock', colored_player_name, { 'expanse.gps', math.floor(expansion_position.x), math.floor(expansion_position.y), game.surfaces[expanse.active_surface_index].name } })
        expanse.size = (expanse.size or 1) + 1
        if math.random(1, 4) == 1 then
            if surface and surface.count_tiles_filtered({ position = expansion_position, radius = 6, collision_mask = 'water_tile' }) > 40 then
                return
            end
            local render = rendering.draw_sprite {
                sprite = 'utility/danger_icon',
                surface = surface,
                target = expansion_position,
                x_scale = 2,
                y_scale = 2
            }
            table.insert(expanse.invasion_candidates, { surface_index = surface.index, position = expansion_position, render = render })
            Functions.check_invasion(expanse)
        end
    end
end

local function on_gui_opened(event)
    container_opened(event)
end

local function on_gui_closed(event)
    container_opened(event)
end

local function assign_acid_tank(entity)
    local tanks = entity.surface.find_entities_filtered { name = 'storage-tank', position = entity.position, radius = 8 }
    for _, tank in pairs(tanks) do
        if tank.get_fluid_count('sulfuric-acid') > 0 then
            return tank
        end
    end
    return nil
end

local function uranium_mining(entity)
    if not game.forces.player.technologies['uranium-processing'].researched then return end
    if not expanse.acid_tank or not expanse.acid_tank.valid then
        expanse.acid_tank = assign_acid_tank(entity)
    end
    local tank = expanse.acid_tank
    if tank and tank.valid then
        local acid = tank.get_fluid_count('sulfuric-acid')
        if acid > 5 then
            tank.remove_fluid { name = 'sulfuric-acid', amount = 4 }
            entity.surface.spill_item_stack({position = entity.position, stack ={ name = 'uranium-ore', count = 4 }, enable_looted = true, allow_belts = true})
            FT.flying_text(nil, entity.surface, tank.position, '-4 [fluid=sulfuric-acid]', { r = 0.88, g = 0.02, b = 0.02 })
        end
    end
end

local function infini_rock(entity)
    if entity.type ~= 'simple-entity' then
        return
    end
    local techs = game.forces.player.technologies
    local inf_ores = {
        ['iron-ore'] = 16,
        ['copper-ore'] = 8,
        ['coal'] = 8,
        ['stone'] = 3,
        ['scrap'] = (SA and techs['recycling'].researched) and 4 or nil,
        ['tungsten-ore'] = (SA and techs['foundry'].researched) and 2 or nil,
        ['calcite'] = (SA and techs['foundry'].researched) and 1 or nil
    }
    local a = math.floor(expanse.square_size * 0.5)
    if entity.position.x == a + 4 and entity.position.y == a - 4 then
        local newrock = entity.surface.create_entity({ name = 'big-rock', position = { a + 4, a - 4 } })
        local roll = Raffle.raffle(inf_ores)
        entity.surface.spill_item_stack({position = entity.position, stack = { name = roll, count = math.random(80, 160) }, enable_looted = true, allow_belts = true})
        uranium_mining(entity)
        if newrock then
        expanse.rock = script.register_on_object_destroyed(newrock)
        end
    end
end

local function infini_tree()
    local techs = game.forces.player.technologies
    local trees = {
        ['tree-01'] = 1,
        ['tree-02'] = 1,
        ['tree-02-red'] = 1,
        ['tree-03'] = 1,
        ['tree-04'] = 1,
        ['tree-05'] = 1,
        ['tree-06'] = 1,
        ['tree-06-brown'] = 1,
        ['tree-07'] = 1,
        ['tree-08'] = 1,
        ['tree-08-brown'] = 1,
        ['tree-08-red'] = 1,
        ['tree-09'] = 1,
        ['tree-09-brown'] = 1,
        ['tree-09-red'] = 1,
        ['ashland-lichen-tree'] = (SA and techs['foundry'].researched) and 7 or nil,
        ['funneltrunk'] = (SA and techs['agriculture'].researched) and 5 or nil,
        ['teflilly'] = (SA and techs['agriculture'].researched) and 5 or nil,
        ['stingfrond'] = (SA and techs['agriculture'].researched) and 5 or nil,
        ['sunnycomb'] = (SA and techs['agriculture'].researched) and 5 or nil,
        ['boompuff'] = (SA and techs['agriculture'].researched) and 2 or nil,
    }
    local a = math.floor(expanse.square_size * 0.5)
    local surface = game.surfaces[expanse.active_surface_index]
    local position = {a - 4, a + 4}

    local newtree = surface.create_entity({ name = Raffle.raffle(trees), position = position, }) --register_plant = true ?
    if newtree then
        expanse.tree = script.register_on_object_destroyed(newtree)
    end
end

local function infini_resource(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.name == 'big-rock' then
        infini_rock(entity)
    end
end

local function infini_resource2(event)
    if event.registration_number == expanse.tree then
        infini_tree()
    elseif event.registration_number == expanse.rock then
        local a = math.floor(expanse.square_size * 0.5)
        infini_rock({type = 'simple-entity', position = {x = a + 4, y = a - 4 }, surface = game.surfaces[expanse.active_surface_index]})
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if player.online_time == 0 then
        local surface = game.surfaces[expanse.active_surface_index]
        player.teleport(surface.find_non_colliding_position('character', { expanse.square_size * 0.5, expanse.square_size * 0.5 }, 32, 0.5) or {0,0}, surface)
    end
    create_button(player)
end

local function on_pre_player_left_game(event)
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end
    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end
    local removed_count = inventory.remove({ name = 'coin', count = 999999 })
    if removed_count > 0 then
        for _ = 1, removed_count, 1 do
            player.surface.spill_item_stack({position = player.position, stack = { name = 'coin', count = 1 }, enable_looted = false, allow_belts = false})
        end
        game.print({ 'expanse.tokens_dropped', player.name, { 'expanse.gps', math.floor(player.position.x), math.floor(player.position.y), player.surface.name } })
    end
end

local function on_init()
    local T = Map_info.Pop_info()
    T.localised_category = 'expanse'
    T.main_caption_color = { r = 170, g = 170, b = 0 }
    T.sub_caption_color = { r = 120, g = 120, b = 0 }

    if not expanse.source_surface then
        expanse.source_surface = 'nauvis'
    end
    if not expanse.token_chance then
        expanse.token_chance = chance_to_receive_token
    end
    if not expanse.price_distance_modifier then
        expanse.price_distance_modifier = 0.006
    end
    if not expanse.max_ore_price_modifier then
        expanse.max_ore_price_modifier = 0.33
    end
    if not expanse.square_size then
        expanse.square_size = cell_size
    end

    expanse.override_nauvis = true -- adds custom mixed ores and raises frequency of resources

    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_cooldown = 1800
    game.map_settings.enemy_expansion.min_expansion_cooldown = 1800
    game.map_settings.enemy_expansion.settler_group_max_size = 8
    game.map_settings.enemy_expansion.settler_group_min_size = 16
    game.map_settings.enemy_evolution.destroy_factor = 0.003   --default game: 0.002
    game.map_settings.enemy_evolution.pollution_factor = 6e-07 --default game: 9e-07
    game.map_settings.enemy_evolution.time_factor = 2e-06      --default game: 4e-06

    --Settings for cave miner
    --[[
	expanse.override_nauvis = false
	expanse.token_chance = 0.75
	expanse.price_distance_modifier = 0.0035
	expanse.max_ore_price_modifier = 0.25
	game.forces.player.technologies.landfill.researched = true
	]]
    reset()
end

local function map_reset(_event)
    SpaceMissions.reset_space(expanse)
    reset()
end

local function victory(_event)
    game.print({'expanse.script-victory'})
    game.play_sound { path = 'utility/game_won', volume_modifier = 0.9 }
    table.insert(expanse.schedule, { tick = game.tick + 120 * 60, event = 'map_reset', parameters = {} })
end


local function on_tick()
    SpaceMissions.launch_rockets(expanse)
    if game.tick % 3600 == 0 then
        SpaceMissions.produce_space_goods(expanse)
        SpaceMissions.deliver_goods(expanse)
    end
    if not next(expanse.schedule) then return end
    for index, stuff in pairs(expanse.schedule) do
        if game.tick >= stuff.tick then
            script.raise_event(expanse.events[stuff.event], stuff.parameters)
            expanse.schedule[index] = nil
        end
    end
end

local function resource_stats(parent, name, quality, count)
    local color = prototypes.quality[quality].color
    local tooltip = {'expanse.colored_text', color.r, color.g, color.b, Functions.get_item_tooltip(name, quality, true)}
    local button = parent.add({ type = 'sprite-button', name = name .. '|' .. quality .. '_sprite', sprite = 'item/' .. name, quality = quality, enabled = false, tooltip = tooltip })
    local label = parent.add({ type = 'label', name = name .. '|' .. quality .. '_label', caption = format_number(tonumber(count), true), tooltip = count })
    label.style.width = 40
    label.style.font_color = color
    return button, label
end

local function create_main_frame(player)
    local frame, inside_frame = Gui.add_main_frame_with_toolbar(player, 'screen', main_frame_name, false, close_main_frame_button_name, { 'expanse.stats_gui' })
    --local frame = player.gui.screen.add({ type = 'frame', name = main_frame_name, caption = { 'expanse.stats_gui' }, direction = 'vertical' })
    if not frame or not inside_frame then return end
    frame.location = { x = 10, y = 50 }
    frame.style.maximal_height = 600
    local invasion_numbers = Functions.invasion_numbers(expanse)
    inside_frame.add({ type = 'label', name = 'size', caption = { 'expanse.stats_size', expanse.size or 1 } })
    inside_frame.add({ type = 'label', name = 'biters', caption = { 'expanse.stats_attack', #expanse.invasion_candidates, invasion_numbers.candidates, invasion_numbers.groups } })
    local scroll = inside_frame.add({ type = 'scroll-pane', name = 'scroll_pane', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto-and-reserve-space' })

    local frame_table = scroll.add({ type = 'table', name = 'resource_stats', column_count = 8 })
    frame_table.style.horizontally_stretchable = true
    frame_table.style.vertically_stretchable = true
    for qname, count in table.spairs(expanse.cost_stats, function (t, a, b) return t[a] > t[b] end) do
        local name, quality = Functions.split_key(qname)
        resource_stats(frame_table, name, quality, count)
    end
end

local function update_resource_gui(event)
    for _, player in pairs(game.connected_players) do
        if player.gui.screen[main_frame_name] then
            local frame = player.gui.screen[main_frame_name]['inside_frame']
            local invasion_numbers = Functions.invasion_numbers(expanse)
            frame['size'].caption = { 'expanse.stats_size', expanse.size or 1 }
            frame['biters'].caption = { 'expanse.stats_attack', #expanse.invasion_candidates, invasion_numbers.candidates, invasion_numbers.groups }
            local frame_table = frame['scroll_pane']['resource_stats']
            local count = expanse.cost_stats[Functions.make_key(event.item, event.quality)] or 0
            if not frame_table[event.item .. '|' .. event.quality .. '_label'] then
                resource_stats(frame_table, event.item, event.quality, count)
            else
                frame_table[event.item .. '|' .. event.quality .. '_label'].caption = format_number(tonumber(count), true)
                frame_table[event.item .. '|' .. event.quality .. '_label'].tooltip = count
            end
        end
    end
end

local function mission_stats(parent, name, quality, count, delivered)
    local color = prototypes.quality[quality].color
    local tooltip = {'expanse.colored_text', color.r, color.g, color.b, Functions.get_item_tooltip(name, quality, false)}
    local button = parent.add({ type = 'sprite-button', name = name .. '|' .. quality .. '_sprite', sprite = 'item/' .. name, quality = quality, enabled = false, tooltip = tooltip })
    local label = parent.add({ type = 'label', name = name .. '|' .. quality .. '_label', caption = {'expanse.missions_progress', format_number(tonumber(delivered), true), format_number(tonumber(count), true)} })
    label.style.minimal_width = 40
    label.style.font_color = delivered == count and {r = 0, g = 0.88, b = 0} or {r = 0.88, g = 0, b = 0}
    return button, label
end

local function mission_rewards(parent, type, reward)
    local type_sprites = {
        ['research'] = 'virtual-signal/signal-science-pack',
        ['production'] = 'virtual-signal/signal-clockwise-circle-arrow',
        ['once'] = 'virtual-signal/signal-1',
        ['script'] = 'virtual-signal/signal-check'
    }
    local things = {''}
    if type == 'research' then
        for tech, progress in pairs(reward) do
            things = {'', things, {'expanse.missions_reward_tech', tech, {'technology-name.' .. tech}, progress * 100}}
        end
    elseif type == 'script' then
        for thing, value in pairs(reward) do
            things = {'', things, {'expanse.script-' .. thing, value}}
            things = {'', things, '\n'}
            if thing == 'new-ship' then
                things = {'', things, {'expanse.ship-desc-' .. value}}
                things = {'', things, '\n'}
            end
        end
    elseif type == 'production' or type == 'once' then
        for qname, count in pairs(reward) do
            local name, quality = Functions.split_key(qname)
            things = {'', things, count}
            things = {'', things, ' [item=' .. name .. ',quality=' .. quality .. ']\n'}
        end
    end
    local tooltip = {'expanse.missions_reward_tooltip', {'expanse.missions_reward_' .. type}, things}
    local type_button = parent.add({ type = 'sprite-button', sprite = type_sprites[type], name = 'reward|' .. type, tooltip = tooltip, enabled = false})
    return type_button
end

local function create_missions_frame(player, location, selected_tab_index)
    local frame, inside_frame = Gui.add_main_frame_with_toolbar(player, 'screen', missions_frame_name, false, close_missions_button_name, { 'expanse.missions_gui' })
    --local frame = player.gui.screen.add({ type = 'frame', name = missions_frame_name, caption = { 'expanse.missions_gui' }, direction = 'vertical' })
    if not frame or not inside_frame then return end
    local pane = inside_frame.add({ type = 'tabbed-pane', name = 'missions_tab_pane' })
    frame.location = location or { x = 210, y = 50 }
    frame.style.maximal_height = 600
    local prod_tab = pane.add({ type = 'tab', caption = 'Production', name = 'mission_tab_prod', style = 'slightly_smaller_tab' })
    local prod_frame = pane.add({ type = 'frame', name = 'prod_frame', direction = 'vertical', style = 'mod_gui_inside_deep_frame' })
    prod_frame.style.padding = 8
    prod_frame.style.horizontally_stretchable = true
    prod_frame.style.vertically_stretchable = true
    pane.add_tab(prod_tab, prod_frame)
    prod_frame.add({ type = 'label', caption = {'expanse.production_label'}, name = 'prod_label'})
    local prod_table = prod_frame.add({ type = 'table', name = 'prod_table', column_count = 10 })
    for qname, count in pairs(expanse.space_production) do
        local name, quality = Functions.split_key(qname)
        resource_stats(prod_table, name, quality, count)
    end
    for i = 4, SA and 10 or 5, 1 do
        local req = MissionData.mission_unlocks[i]
        local level = expanse.missions[i].level
        local tab = pane.add({ type = 'tab', caption = 'M' .. i, name = 'mission_tab_' .. i, style = 'slightly_smaller_tab' })
        local mission_frame = pane.add({ type = 'frame', name = 'mission_frame' .. i, direction = 'vertical', style = 'mod_gui_inside_deep_frame' })
        mission_frame.style.padding = 8
        mission_frame.style.horizontally_stretchable = true
        mission_frame.style.vertically_stretchable = true
        pane.add_tab(tab, mission_frame)
        local mission_table = mission_frame.add({ type = 'table', name = 'mission_table' .. i, column_count = 2})
        mission_table.add({ type = 'sprite-button', name = 'tier' .. i, sprite = 'virtual-signal/signal-' .. (i < 10 and i or 0), tooltip = {'expanse.missions_tier', i, level}, enabled = false })
        mission_table.add({ type = 'label', name = 'mission_label' .. i, caption = {'expanse.missions_tier', i, level} })
        mission_table.add({ type = 'sprite-button', name = 'mission_unlock' .. i, sprite = 'virtual-signal/signal-info', enabled = false})

        local lore_table = mission_table.add({ type = 'table', name = 'lore_table' .. i, column_count = 2})
        lore_table.add({ type = 'sprite-button', name = 'lore-unlock' .. i, sprite = 'virtual-signal/signal-unlock', enabled = false})
        lore_table.add({ type = 'label', name = 'lore-' .. i .. '-u', caption = {'expanse.missions_reqs', req, {'technology-name.' .. req}} })
        -- for s = 0, level, 1 do
        --     local sprite = (s == level) and 'virtual-signal/signal-hourglass' or 'virtual-signal/signal-check'
        --     lore_table.add({ type = 'sprite-button', name = 'lore-' .. i .. '-' .. s, sprite = sprite, enabled = false})
        --     lore_table.add({ type = 'label', name = 'lore-label-' .. i .. '-' .. s, caption = {'expanse-lore.m' .. i .. '-' .. s}})
        -- end

        mission_table.add({ type = 'sprite-button', name = 'dummy' .. i, sprite = 'item/rocket-part', enabled = false, tooltip = {'expanse.missions_mission'} })
        local tier_table = mission_table.add({ type = 'table', name = 'mission_reqs' .. i, column_count = 10 })
        mission_table.add({ type = 'sprite-button', name = 'reward' .. i, sprite = 'virtual-signal/signal-output', enabled = false, tooltip = {'expanse.missions_reward'}})
        local reward_table = mission_table.add({ type = 'table', name = 'reward_table' .. i, column_count = 10})
        if level > 0 then
            local costs = SA and MissionData.costs[i] or MissionData.nonspace_costs[i]
            for qname, count in pairs(costs[expanse.missions[i].level]) do
                local name, quality = Functions.split_key(qname)
                local delivered = expanse.missions[i].delivered[qname] or 0
                mission_stats(tier_table, name, quality, count, delivered)
            end
            local rewards = SA and MissionData.rewards[i] or MissionData.nonspace_rewards[i]
            for type, reward in pairs(rewards[level]) do
                mission_rewards(reward_table, type, reward)
            end
        end
    end
    pane.selected_tab_index = selected_tab_index or 1
end

local function update_mission_gui(_event)
    for _, player in pairs(game.connected_players) do
        if player.gui.screen[missions_frame_name] then
            local frame = player.gui.screen[missions_frame_name]
            local location = frame.location
            local selected_tab_index = frame['inside_frame']['missions_tab_pane'].selected_tab_index
            frame.destroy()
            create_missions_frame(player, location, selected_tab_index)
        end
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end
    local name = element.name
    local player = game.players[event.player_index]

    if name == main_button_name or name == close_main_frame_button_name then
        if player.gui.screen[main_frame_name] then
            player.gui.screen[main_frame_name].destroy()
        else
            create_main_frame(player)
        end
        return
    end
    if name == missions_button_name or name == close_missions_button_name then
        if player.gui.screen[missions_frame_name] then
            player.gui.screen[missions_frame_name].destroy()
        else
            create_missions_frame(player)
        end
        return
    end
end

local function on_research_finished(event)
    local research = event.research
    local force = research.force
    local banned_items = {
        ['cargo-landing-pad'] = (not expanse.landing_pad or not expanse.landing_pad.valid) and true or false,
        ['rocket-silo'] = true,
        ['atomic-bomb'] = true
    }
    for recipe, state in pairs(banned_items) do
        if state == true then
            force.recipes[recipe].enabled = false
        end
    end
    for tier, name in pairs(MissionData.mission_unlocks) do
        if research.name == name then
            SpaceMissions.unlock_mission_tier(expanse, tier)
        end
    end
end

local function on_rocket_launch_ordered(event)
    local silo = event.rocket_silo
    local pod = event.rocket.attached_cargo_pod
    local data = expanse.rocket_silos[silo.unit_number]

    expanse.cargo_pods[pod.unit_number] = {pod = pod, tier = data.tier, source = silo}
end

local function on_cargo_pod_finished_ascending(event)
    local pod = event.cargo_pod
    if not pod or not pod.valid then return end
    local surface = pod.surface
    if surface.index == expanse.active_surface_index then
        SpaceMissions.rocket_delivery(expanse, pod)
    end
end

local function cmd_handler()
	local player = game.player
	local p
	if not (player and player.valid) then
		p = log
	else
		p = player.print
	end
	if player and not player.admin then
		p('You are not an admin!')
		return false, nil, p
	end
	return true, player or {name = 'Server'}, p
end

commands.add_command(
    'expanse-reset',
    'Fully resets the expanse map.',
    function()
		local s, player = cmd_handler()
		if s then
			map_reset()
			game.print((player and player.name or 'Server') .. ' has reset the map.')
		end
	end
)

Event.on_init(on_init)
Event.on_nth_tick(60, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_area_cloned, on_area_cloned)
Event.add(defines.events.on_resource_depleted, on_resource_depleted)
Event.add(defines.events.on_entity_died, infini_resource)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_pre_player_mined_item, infini_resource)
Event.add(defines.events.on_robot_pre_mined, infini_resource)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_rocket_launch_ordered, on_rocket_launch_ordered)
Event.add(defines.events.on_cargo_pod_finished_ascending, on_cargo_pod_finished_ascending)
Event.add(defines.events.on_object_destroyed, infini_resource2)
Event.add(expanse.events.gui_update, update_resource_gui)
Event.add(expanse.events.mission_gui_update, update_mission_gui)
Event.add(expanse.events.invasion_warn, Functions.invasion_warn)
Event.add(expanse.events.invasion_detonate, Functions.invasion_detonate)
Event.add(expanse.events.invasion_trigger, Functions.invasion_trigger)
Event.add(expanse.events.victory, victory)
Event.add(expanse.events.map_reset, map_reset)
