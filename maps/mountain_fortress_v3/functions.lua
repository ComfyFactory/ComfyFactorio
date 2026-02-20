local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local Color = require 'utils.color_presets'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Global = require 'utils.global'
local Alert = require 'utils.alert'
local WD = require 'modules.wave_defense.table'
local RPG = require 'modules.rpg.main'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local math2d = require 'math2d'
local Misc = require 'utils.commands.misc'
local Core = require 'utils.core'
local Beams = require 'modules.render_beam'
local Modifiers = require 'utils.player_modifiers'
local Session = require 'utils.datastore.session_data'
local ICMinimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Score = require 'utils.gui.score'
local Gui = require 'utils.gui'
local FunctionColor = { r = 0.98, g = 0.66, b = 0.22 }
local CustomEvents = require 'utils.created_events'

local zone_settings = Public.zone_settings
local remove_boost_movement_speed_on_respawn
local de = defines.events
local is_modded = Public.is_modded
local random = math.random
local floor = math.floor
local round = math.round
local sqrt = math.sqrt
local remove = table.remove
local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8
local tile_damage = 50

local notice_frame_name = Gui.uid_name()
local close_notice_frame_name = Gui.uid_name()

local this =
{
    power_sources = { index = 1 },
    refill_turrets = { index = 1 },
    magic_crafters = { index = 1 },
    magic_fluid_crafters = { index = 1 },
    art_table = { index = 1 },
    editor_mode = {},
    techs = {},
    limit_types = {},
    starting_items =
    {
        ['pistol'] =
        {
            count = 1
        },
        ['firearm-magazine'] =
        {
            count = 16
        },
        ['rail'] =
        {
            count = 16
        },
        ['wood'] =
        {
            count = 16
        },
        ['explosives'] =
        {
            count = 32
        }
    }
}

local disabled_ents =
{
    ['rail-support'] = true,
    ['rail-ramp'] = true,
    ['railgun-turret'] = true,
}

local random_respawn_messages =
{
    'The doctors stitched you up as best they could.',
    'Ow! Your right leg hurts.',
    'Ow! Your left leg hurts.',
    'You can feel your whole body aching.',
    "You still have some bullet wounds that aren't patched up.",
    'You feel dizzy but adrenalin is granting you speed.',
    'Adrenalin is kicking in, but your body is damaged.'
}

local health_values =
{
    '0.35',
    '0.40',
    '0.45',
    '0.50',
    '0.55',
    '0.60',
    '0.65',
    '0.70',
    '0.75',
    '0.80',
    '0.85',
    '0.90',
    '0.95',
    '1'
}

Global.register(
    this,
    function (t)
        this = t
    end
)



local artillery_target_entities =
{
    'character',
    'tank',
    'car',
    'radar',
    'lab',
    'stone-furnace',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon',
    'artillery-turret',
    'laser-turret',
    'gun-turret',
    'flamethrower-turret',
    'rocket-silo',
    'spidertron'
}

local fishy_callback_token =
    Task.register(
        function (event)
            local entity = event.entity
            if not entity or not entity.valid then
                return
            end
            if entity.type ~= 'item-entity' then
                return
            end
            local fishy_baits = Public.get('fishy_baits')
            if entity.stack and entity.stack.name == 'cooked-fish' then
                local fish_nom_cooldown = WD.get('fish_nom_cooldown') or 0
                local fish_alert_cooldown = WD.get('fish_alert_cooldown') or 0

                if game.tick >= fish_nom_cooldown then
                    WD.set('fish_nom_cooldown', game.tick + 400)
                    local threat = WD.get('threat')
                    WD.set('threat', threat + 100)
                    fishy_baits['cooked_fish'] = fishy_baits['cooked_fish'] and fishy_baits['cooked_fish'] + 1 or 1

                    if game.tick >= fish_alert_cooldown then
                        WD.set('fish_alert_cooldown', game.tick + 4000)
                        local msg = 'The biters feast on the cooked fish near collapse! Threat increased by 100!'
                        Alert.alert_all_players(60, msg)
                    end
                end
            end
            if entity.stack and entity.stack.name == 'grilled-fish' then
                local fish_nom_cooldown = WD.get('fish_nom_cooldown') or 0
                local fish_alert_cooldown = WD.get('fish_alert_cooldown') or 0

                if game.tick >= fish_nom_cooldown then
                    WD.set('fish_nom_cooldown', game.tick + 50) -- 50 ticks = 2.5 seconds, decreased from 400 ticks = 20 seconds
                    local threat = WD.get('threat')
                    WD.set('threat', threat + 200)
                    fishy_baits['grilled_fish'] = fishy_baits['grilled_fish'] and fishy_baits['grilled_fish'] + 1 or 1

                    if game.tick >= fish_alert_cooldown then
                        WD.set('fish_alert_cooldown', game.tick + 4000)
                        local msg = 'The biters feast on the grilled fish near collapse! Threat increased by 200!'
                        Alert.alert_all_players(60, msg)
                    end
                end
            end
        end
    )

local surface_validation_token =
    Task.register(
        function (event)
            local player_index = event.player_index
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end

            if (player.physical_position.x < 700) then
                return true
            elseif (player.physical_position.x > 700) then
                return false
            end
        end
    )

local exit_editor_mode_token =
    Task.register(
        function (event)
            local player_index = event.player_index
            this.editor_mode[player_index] = nil
        end
    )

local custom_surface_funcs_token =
    Task.register(
        function ()
            local active_surface_index = Public.get('active_surface_index')
            if not active_surface_index then return end
            local surface = game.get_surface(active_surface_index)
            if not (surface and surface.valid) then
                return
            end

            if not Public.is_modded_pt2 then
                return
            end

            if surface.name == 'fortress' then
                local entities = surface.find_entities_filtered { name = artillery_target_entities, force = 'player' }
                if #entities == 0 then
                    return
                end

                local entity = entities[random(#entities)]
                if entity and entity.valid then
                    local position = { x = entity.position.x + random(-120, 120), y = entity.position.y + random(-120, 120) }
                    surface.create_entity({ name = 'lightning', position = position, force = 'enemy' })
                end
            end
        end
    )

local function debug_str(msg)
    local debug = Public.get('debug')
    if not debug then
        return
    end
    Server.output_script_data('Mtn: ' .. msg)
end

local function draw_notice_frame(player)
    if not this.show_wip then
        return
    end

    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', notice_frame_name, nil, close_notice_frame_name, 'Notice', true, 2)

    if not main_frame or not inside_table then
        return
    end


    local main_frame_style = main_frame.style
    main_frame_style.width = 600
    main_frame.auto_center = true

    local content_flow = inside_table.add { type = 'flow', direction = 'horizontal' }
    content_flow.style.top_padding = 16
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontally_stretchable = false

    local sprite_flow = content_flow.add { type = 'flow' }
    sprite_flow.style.vertical_align = 'center'
    sprite_flow.style.vertically_stretchable = false

    sprite_flow.add { type = 'sprite', sprite = 'utility/warning_icon' }

    local label_flow = content_flow.add { type = 'flow' }
    label_flow.style.horizontal_align = 'left'
    label_flow.style.top_padding = 10
    label_flow.style.left_padding = 24

    local info_message = '[font=heading-1]Work in progress - balance not guaranteed[/font]\n\nPlease note that this experience is a work in progress, and the gameplay balance may vary significantly.\nSome features are still being fine-tuned, so expect occasional bugs or unbalanced elements.\nPlease post your feedbacks in #mount-fortress.\n\nEnjoy and explore, but proceed with caution! ☺\n\n/Gerkiz'

    label_flow.style.horizontally_stretchable = false
    local label = label_flow.add { type = 'label', caption = info_message }
    label.style.single_line = false
    label.style.font = 'heading-2'

    player.opened = main_frame
end

local function show_text(msg, pos, surface, player)
    surface.create_entity(
        {
            name = 'compi-speech-bubble',
            position = pos,
            text = msg,
            source = player.character,
            lifetime = 30
        })
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local pause_waves_custom_callback_token =
    Task.register(
        function (event)
            local final_battle = Public.get('final_battle')
            if final_battle then
                return
            end

            local wave_number = WD.get_wave()
            if wave_number >= 200 then
                Collapse.start_now(event.start, not event.start)
                local status_str = event.start and 'is active once again!' or 'has stopped!'
                Alert.alert_all_players(30, 'Collapse ' .. status_str, nil, 'achievement/tech-maniac', 0.6)
            end
        end
    )

local magicka_custom_callback_token =
    Task.register(
        function (event)
            if not event then
                return
            end

            local player = event.player
            if not player or not player.valid then
                return
            end

            local mc_rewards = Public.get('mc_rewards')
            if not mc_rewards or not mc_rewards.active_boosts then
                return
            end

            local rpg_t = event.rpg_t
            if not rpg_t then
                return
            end

            if rpg_t.magicka < 10 then
                rpg_t.magicka = 10
            end

            if mc_rewards.active_boosts.lucky then
                if not rpg_t.previous_magicka then
                    rpg_t.previous_magicka = rpg_t.magicka
                    rpg_t.magicka = rpg_t.magicka + 100
                end
            else
                if rpg_t.previous_magicka then
                    rpg_t.magicka = rpg_t.magicka - 100
                    if rpg_t.magicka < 10 then
                        rpg_t.magicka = 10
                    end
                    rpg_t.previous_magicka = nil
                end
            end
        end
    )

local x_marks_the_spot_custom_callback_token =
    Task.register(
        function (event)
            local player = game.get_player(event.player_index)
            if not player or not player.valid then
                return
            end

            Public.changed_surface(player)
        end
    )

local function do_refill_turrets()
    local refill_turrets = this.refill_turrets
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local turret_data = refill_turrets[index]
    local turret = turret_data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)
        return
    end

    refill_turrets.index = index + 1

    local data = turret_data.data
    if data.liquid then
        turret.set_fluid(1, data)
    elseif data then
        turret.insert(data)
    end
end

local function do_magic_crafters()
    local magic_crafters = this.magic_crafters
    local limit = #magic_crafters
    if limit == 0 then
        return
    end

    local index = magic_crafters.index

    for _ = 1, magic_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 1 then
                fcount = 1
            end

            if fcount > 0 then
                if entity.get_output_inventory().can_insert({ name = data.item, count = fcount, quality = data.quality }) then
                    entity.get_output_inventory().insert { name = data.item, count = fcount, quality = data.quality }
                    entity.products_finished = entity.products_finished + fcount
                    data.last_tick = round(tick - (count - fcount) / rate)
                end
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local magic_fluid_crafters = this.magic_fluid_crafters
    local limit = #magic_fluid_crafters

    if limit == 0 then
        return
    end

    local index = magic_fluid_crafters.index

    for _ = 1, magic_fluid_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_fluid_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_fluid_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                local fluidbox_index = data.fluidbox_index

                local fb_data = entity.get_fluid(fluidbox_index) or { name = data.item, amount = 0 }
                fb_data.amount = fb_data.amount + fcount
                fb_data.quality = data.quality
                entity.set_fluid(fluidbox_index, fb_data)

                entity.products_finished = entity.products_finished + fcount

                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_fluid_crafters.index = index
end

local artillery_target_callback =
    Task.register(
        function (data)
            local position = data.position
            local entity = data.entity
            local index = data.index

            local art_table = this.art_table
            local outpost = art_table[index]
            if not outpost then
                return
            end

            if not entity.valid then
                outpost.last_fire_tick = 0
                return
            end

            local tx, ty = position.x, position.y
            local fired_at_target = false

            local pos = entity.position
            local x, y = pos.x, pos.y
            local dx, dy = tx - x, ty - y
            local d = dx * dx + dy * dy
            if d >= 1024 and d <= 441398 then -- 704 in depth~
                if entity.name == 'character' then
                    entity.surface.create_entity
                    {
                        name = 'artillery-projectile',
                        position = position,
                        target = entity,
                        force = 'enemy',
                        speed = 1.5
                    }
                    fired_at_target = true
                elseif entity.name ~= 'character' then
                    entity.surface.create_entity
                    {
                        name = 'rocket',
                        position = position,
                        target = entity,
                        force = 'enemy',
                        speed = 1.5
                    }
                    fired_at_target = true
                end
            end

            if not fired_at_target then
                outpost.last_fire_tick = 0
            end
        end
    )

local function do_beams_away()
    local wave_number = WD.get_wave()
    local orbital_strikes = Public.get('orbital_strikes')
    if not orbital_strikes or not orbital_strikes.enabled then
        return
    end

    if wave_number > 500 then
        local difficulty_index = Difficulty.get('index')
        local wave_nth = 9999
        if difficulty_index == 1 then
            wave_nth = 500
        elseif difficulty_index == 2 then
            wave_nth = 250
        elseif difficulty_index == 3 then
            wave_nth = 100
        end

        if wave_number % wave_nth == 0 then
            local active_surface_index = Public.get('active_surface_index')
            local surface = game.get_surface(active_surface_index)

            if not orbital_strikes[wave_number] then
                orbital_strikes[wave_number] = true
                Beams.new_beam_delayed(surface, random(500, 3000))
            end
        end
    end
end

local function do_clear_enemy_spawners()
    local tick = game.tick
    if tick % 500 ~= 0 then
        return
    end

    local enemy_spawners = Public.get('enemy_spawners')
    if not enemy_spawners or not enemy_spawners.enabled then
        return
    end

    for unit_number, spawner in pairs(enemy_spawners.spawners) do
        local entity = spawner.entity

        if entity and entity.valid then
            entity.health = entity.health - 15
            entity.surface.create_entity({ name = 'blood-explosion-small', position = entity.position })
            if entity.health <= 1 then
                entity.die('enemy')
                enemy_spawners.spawners[unit_number] = nil
            end
        else
            enemy_spawners.spawners[unit_number] = nil
        end
    end
end

local function do_clear_rocks_slowly()
    local rocks_to_remove = Public.get('rocks_to_remove')
    if not rocks_to_remove or not next(rocks_to_remove) then
        return
    end

    for _ = 1, 300 do
        local entity = table.remove(rocks_to_remove, #rocks_to_remove)

        if entity and entity.valid then
            entity.destroy()
        end
    end
end

local function do_replace_tiles_slowly()
    local active_surface_index = Public.get('active_surface_index')
    if not active_surface_index then return end
    local surface = game.get_surface(active_surface_index)
    if not (surface and surface.valid) then
        return
    end

    local tiles_to_replace = Public.get('tiles_to_replace')
    if not tiles_to_replace or not next(tiles_to_replace) then
        return
    end

    for _ = 1, 1000 do
        local tile = table.remove(tiles_to_replace, #tiles_to_replace)
        if tile and tile.valid then
            surface.set_tiles({ { name = 'water-shallow', position = tile.position } }, true)
        end
    end
end


local function do_custom_surface_funcs()
    if not Public.get('do_custom_surface_funcs') then
        return
    end

    Task.set_timeout_in_ticks(30, custom_surface_funcs_token)
end

local function do_season_fix()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local current_season = Public.get('current_season')

    if current_season and current_season.valid then
        current_season.destroy()
    end

    Public.set(
        'current_season',
        rendering.draw_text
        {
            text = 'Season: ' .. Public.get_stateful('season'),
            surface = surface,
            target = { -0, 12 },
            color = { r = 0.98, g = 0.77, b = 0.22 },
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    )
end

local do_season_fix_token = Task.register(do_season_fix)

local elements = { "piercing", "acid", "explosive", "poison", "fire" }

local enemy_unit_types =
{
    biter =
    {
        small = { t1 = { 1, 100 }, t2 = { 100, 250 }, t3 = { 250, 300 } },
        medium = { t1 = { 100, 300 }, t2 = { 300, 350 }, t3 = { 350, 400 } },
        big = { t1 = { 300, 550 }, t2 = { 550, 600 }, t3 = { 600, 800 } },
        behemoth = { t1 = { 600, 900 }, t2 = { 900, 1000 }, t3 = { 1000, 1400 } },
    },

    spitter =
    {
        small = { t1 = { 1, 100 }, t2 = { 100, 250 }, t3 = { 250, 300 } },
        medium = { t1 = { 100, 300 }, t2 = { 300, 350 }, t3 = { 350, 400 } },
        big = { t1 = { 300, 550 }, t2 = { 550, 600 }, t3 = { 600, 800 } },
        behemoth = { t1 = { 600, 900 }, t2 = { 900, 1000 }, t3 = { 1000, 1400 } },
    },

    space_age =
    {
        wriggler =
        {
            small = { t1 = { 1, 100 }, t2 = { 50, 300 } },
            medium = { t1 = { 150, 450 }, t2 = { 450, 550 } },
            big = { t1 = { 400, 600 } }
        },
        strafer =
        {
            small = { t1 = { 200, 750 } },
            medium = { t1 = { 750, 900 } },
            big = { t1 = { 900, 1050 } }
        },
        stomper =
        {
            small = { t1 = { 600, 1100 } },
            medium = { t1 = { 1100, 1200 } },
            big = { t1 = { 1200, 1300 } }
        },
        demolisher =
        {
            small = { t1 = { 1300, 1600 } },
            medium = { t1 = { 1600, 1700 } },
            big = { t1 = { 1700, 1800 } }
        }
    },

    boss =
    {
        biter =
        {
            t1 = { 200, 900 },
            t2 = { 900, 1000 },
            t3 = { 1000, 1100 },
            t4 = { 1100, 1200 },
            t5 = { 1200, 1300 },
            t6 = { 1300, 1400 },
            t7 = { 1400, 1500 }
        },
        spitter =
        {
            t1 = { 200, 900 },
            t2 = { 900, 1000 },
            t3 = { 1000, 1100 },
            t4 = { 1100, 1200 },
            t5 = { 1200, 1300 },
            t6 = { 1300, 1400 },
            t7 = { 1400, 1500 }
        }
    }
}


local function level_weight(level, min, max, multiplier)
    if not min or not max or min >= max then
        return 0
    end
    if level < min then
        return 0
    end

    if level >= max then
        return round((max - min) * (multiplier or 2.75), 6)
    end

    local progress = (level - min) / (max - min)
    local eased = progress ^ 1.25
    return round(eased * (max - min) * (multiplier or 2.75), 6)
end


local function fill_raffles(level)
    local raffles =
    {
        biter_raffle = {},
        spitter_raffle = {},
        boss_raffle = {}
    }

    for family, groups in pairs(enemy_unit_types) do
        if family == "boss" then
            for boss_kind, tiers in pairs(groups) do
                for tier, range in pairs(tiers) do
                    for _, element in ipairs(elements) do
                        local weight = level_weight(level, range[1], range[2], 2.75)
                        if weight then
                            local name = string.format("mtn-addon-boss-%s-%s-%s", element, boss_kind, tier)
                            raffles.boss_raffle[name] = weight
                        end
                    end
                end
            end
        elseif family == "space_age" and Public.is_modded_pt2 then
            for type_name, sizes in pairs(groups) do
                for size, tiers in pairs(sizes) do
                    for _, range in pairs(tiers) do
                        local weight = level_weight(level, range[1], range[2], 2.75)
                        if weight then
                            local proto_name = string.format("%s-%s-pentapod", size, type_name)
                            if type_name == "demolisher" then
                                proto_name = string.format("%s-%s", size, type_name)
                            end
                            raffles.biter_raffle[proto_name] = weight
                        end
                    end
                end
            end
        else
            for size, tiers in pairs(groups) do
                for tier, range in pairs(tiers) do
                    for _, element in ipairs(elements) do
                        local weight = level_weight(level, range[1], range[2], 2.75)
                        if weight then
                            local name = string.format("mtn-addon-%s-%s-%s-%s", size, element, family, tier)
                            raffles[family .. "_raffle"][name] = weight
                        end
                    end
                end
            end
        end
    end

    return raffles
end


local set_unit_raffle_token =
    Task.register(function (event)
        local level = event.level
        local raffles

        if not is_modded then
            raffles =
            {
                biter_raffle =
                {
                    ['small-biter'] = round(1000 - level * 1.75, 6),
                    ['medium-biter'] = round(level, 6),
                },
                spitter_raffle =
                {
                    ['small-spitter'] = round(1000 - level * 1.75, 6),
                    ['medium-spitter'] = round(level, 6),
                }
            }

            if level > 500 then
                raffles.biter_raffle['big-biter'] = round((level - 500) * 2, 6)
                raffles.spitter_raffle['big-spitter'] = round((level - 500) * 2, 6)
            end

            if level > 800 then
                raffles.biter_raffle['behemoth-biter'] = round((level - 800) * 2.75, 6)
                raffles.spitter_raffle['behemoth-spitter'] = round((level - 800) * 2.75, 6)
            end
        else
            raffles = fill_raffles(level)

            raffles.biter_raffle = raffles.biter_raffle or {}
            raffles.spitter_raffle = raffles.spitter_raffle or {}
            raffles.boss_raffle = raffles.boss_raffle or {}
        end

        for _, tbl in pairs(raffles) do
            for k, v in pairs(tbl) do
                tbl[k] = math.max(v or 0, 0)
            end
        end

        for k, v in pairs(raffles) do
            WD.set(k, v)
        end
    end)


local set_worm_raffle_token =
    Task.register(
        function (event)
            local level = event.level
            if not is_modded then
                WD.set(
                    'worm_raffle',
                    {
                        ['small-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['medium-worm-turret'] = round(level, 6),
                        ['big-worm-turret'] = 0,
                        ['behemoth-worm-turret'] = 0
                    }
                )
                local worm_raffle = WD.get('worm_raffle') --[[@as table]]

                if level > 500 then
                    worm_raffle['medium-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['big-worm-turret'] = round((level - 500) * 2, 6)
                end
                if level > 800 then
                    worm_raffle['behemoth-worm-turret'] = round((level - 800) * 3, 6)
                end
                for k, _ in pairs(worm_raffle) do
                    if worm_raffle[k] < 0 then
                        worm_raffle[k] = 0
                    end
                end
            else
                WD.set(
                    'worm_raffle',
                    {
                        ['small-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['mtn-addon-small-explosive-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['mtn-addon-small-fire-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['mtn-addon-small-piercing-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['mtn-addon-small-poison-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['mtn-addon-small-electric-worm-turret'] = round(1000 - level * 1.75, 6),
                        ['medium-worm-turret'] = round(level, 6),
                        ['big-worm-turret'] = 0,
                        ['behemoth-worm-turret'] = 0
                    }
                )
                local worm_raffle = WD.get('worm_raffle') --[[@as table]]

                if level > 500 then
                    worm_raffle['mtn-addon-medium-explosive-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['mtn-addon-medium-fire-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['mtn-addon-medium-piercing-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['mtn-addon-medium-poison-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['mtn-addon-medium-electric-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['medium-worm-turret'] = round(500 - (level - 500), 6)
                    worm_raffle['big-worm-turret'] = round((level - 500) * 2, 6)
                end
                if level > 800 then
                    worm_raffle['mtn-addon-big-explosive-worm-turret'] = round((level - 800) * 3, 6)
                    worm_raffle['mtn-addon-big-fire-worm-turret'] = round((level - 800) * 3, 6)
                    worm_raffle['mtn-addon-big-piercing-worm-turret'] = round((level - 800) * 3, 6)
                    worm_raffle['mtn-addon-big-poison-worm-turret'] = round((level - 800) * 3, 6)
                    worm_raffle['mtn-addon-big-electric-worm-turret'] = round((level - 800) * 3, 6)
                    worm_raffle['behemoth-worm-turret'] = round((level - 800) * 3, 6)
                end
                for k, _ in pairs(worm_raffle) do
                    if worm_raffle[k] < 0 then
                        worm_raffle[k] = 0
                    end
                end
            end
        end
    )

local function do_artillery_turrets_targets()
    local art_table = this.art_table
    local index = art_table.index

    if index > #art_table then
        art_table.index = 1
        return
    end

    art_table.index = index + 1

    local outpost = art_table[index]

    local now = game.tick
    if now - outpost.last_fire_tick < 480 then
        return
    end

    local turrets = outpost.artillery_turrets
    for i = #turrets, 1, -1 do
        local turret = turrets[i]
        if not turret.valid then
            fast_remove(turrets, i)
        end
    end

    local count = #turrets
    if count == 0 then
        fast_remove(art_table, index)
        return
    end

    local turret = turrets[1]
    local area = outpost.artillery_area
    local surface = turret.surface

    local entities = surface.find_entities_filtered { area = area, name = artillery_target_entities, force = 'player' }

    if #entities == 0 then
        return
    end

    local position = turret.position

    outpost.last_fire_tick = now

    for i = 1, count do
        local entity = entities[random(#entities)]
        if entity and entity.valid then
            local data = { position = position, entity = entity, index = index }
            Task.set_timeout_in_ticks(i * 60, artillery_target_callback, data)
        end
    end
end

local function add_magic_crafter_output(entity, output, distance, quality)
    local magic_fluid_crafters = this.magic_fluid_crafters
    local magic_crafters = this.magic_crafters
    local rate = output.min_rate + output.distance_factor * distance

    local fluidbox_index = output.fluidbox_index
    local data =
    {
        entity = entity,
        quality = quality,
        last_tick = game.tick,
        base_rate = round(rate, 8),
        rate = round(rate, 8),
        item = output.item,
        fluidbox_index = fluidbox_index
    }

    if fluidbox_index then
        magic_fluid_crafters[#magic_fluid_crafters + 1] = data
    else
        magic_crafters[#magic_crafters + 1] = data
    end
end

Public.deactivate_callback =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.active = false
                entity.operable = false
                entity.destructible = false
            end
        end
    )

Public.neutral_force =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.force = 'neutral'
            end
        end
    )

Public.enemy_force =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.force = 'enemy'
            end
        end
    )

Public.active_not_destructible_callback =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.active = true
                entity.operable = false
                entity.destructible = false
            end
        end
    )

Public.disable_minable_callback =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.minable_flag = false
            end
        end
    )

Public.disable_minable_and_ICW_callback =
    Task.register(
        function (entity)
            if entity and entity.valid then
                local wagons_in_the_wild = Public.get('wagons_in_the_wild')
                entity.minable_flag = false
                entity.destructible = false
                ICW.register_wagon(entity)

                wagons_in_the_wild[entity.unit_number] = entity
            end
        end
    )

Public.remove_colliding_entities_callback =
    Task.register(
        function (data)
            local entity = data.entity

            if not (entity and entity.valid) then
                return
            end

            local surface = entity.surface
            local position = entity.position
            local radius = data.radius or 6

            local entities = surface.find_entities_filtered { position = position, radius = radius, type = data.type or 'simple-entity' }
            for _, e in pairs(entities) do
                if e ~= entity and e.valid then
                    e.destroy()
                end
            end
        end
    )

Public.disable_destructible_callback =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.destructible = false
                entity.minable_flag = false
            end
        end
    )
Public.disable_active_callback =
    Task.register(
        function (entity)
            if entity and entity.valid then
                entity.active = false
            end
        end
    )

local disable_active_callback = Public.disable_active_callback

Public.refill_turret_callback =
    Task.register(
        function (turret, data)
            local refill_turrets = this.refill_turrets
            local callback_data = data.callback_data
            turret.direction = 3

            refill_turrets[#refill_turrets + 1] = { turret = turret, data = callback_data }
        end
    )

Public.refill_artillery_turret_callback =
    Task.register(
        function (turret, data)
            local refill_turrets = this.refill_turrets
            local art_table = this.art_table
            local index = art_table.index

            turret.active = false
            turret.direction = 3

            refill_turrets[#refill_turrets + 1] = { turret = turret, data = data.callback_data }

            local artillery_data = art_table[index]
            if not artillery_data then
                artillery_data = {}
            end

            local artillery_turrets = artillery_data.artillery_turrets
            if not artillery_turrets then
                artillery_turrets = {}
                artillery_data.artillery_turrets = artillery_turrets

                local pos = turret.position
                local x, y = pos.x, pos.y
                local adjusted_zones = Public.get('adjusted_zones')
                if adjusted_zones.reversed then
                    artillery_data.artillery_area = { { x - 112, y - 212 }, { x + 112, y } }
                else
                    artillery_data.artillery_area = { { x - 112, y }, { x + 112, y + 212 } }
                end
                artillery_data.last_fire_tick = 0

                art_table[#art_table + 1] = artillery_data
            end

            artillery_turrets[#artillery_turrets + 1] = turret
        end
    )

Public.refill_liquid_turret_callback =
    Task.register(
        function (turret, data)
            local refill_turrets = this.refill_turrets
            local callback_data = data.callback_data
            callback_data.liquid = true

            refill_turrets[#refill_turrets + 1] = { turret = turret, data = callback_data }
        end
    )

Public.power_source_callback =
    Task.register(
        function (turret)
            local power_sources = this.power_sources
            power_sources[#power_sources + 1] = turret
        end
    )

Public.magic_item_crafting_callback =
    Task.register(
        function (entity, data)
            local callback_data = data.callback_data
            if not (entity and entity.valid) then
                return
            end

            entity.minable_flag = false
            entity.destructible = false
            entity.operable = false

            local force = game.forces.player

            local tech = callback_data.tech
            if not callback_data.testing then
                if tech then
                    if not force.technologies[tech].researched then
                        entity.destroy()
                        return
                    end
                end
            end

            local quality_buildings = Public.get_stateful('quality_buildings')
            local quality = quality_buildings or 'normal'

            local recipe = callback_data.recipe
            if recipe then
                entity.set_recipe(recipe, quality)
            else
                local furance_item = callback_data.furance_item
                if furance_item then
                    local item_stack = { name = furance_item, count = 1, quality = quality }
                    local inv = entity.get_inventory(defines.inventory.crafter_output)
                    inv.insert(item_stack)
                end
            end

            local p = entity.position
            local x, y = p.x, p.y
            local distance = sqrt(x * x + y * y)

            local output = callback_data.output
            if #output == 0 then
                add_magic_crafter_output(entity, output, distance, quality)
            else
                for i = 1, #output do
                    local o = output[i]
                    add_magic_crafter_output(entity, o, distance, quality)
                end
            end

            if not callback_data.keep_active then
                Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
            end
        end
    )

Public.magic_item_crafting_callback_weighted =
    Task.register(
        function (entity, data)
            local callback_data = data.callback_data
            if not (entity and entity.valid) then
                return
            end

            local weights = callback_data.weights
            local loot = callback_data.loot
            local destructible = callback_data.destructible

            if not destructible then
                entity.destructible = false
            end

            entity.minable_flag = false
            entity.operable = false

            local p = entity.position

            local i = random() * weights.total

            local index = table.binary_search(weights, i)
            if (index < 0) then
                index = bit32.bnot(index)
            end

            local stack = loot[index].stack
            if not stack then
                return
            end

            local force = game.forces.player

            local tech = stack.tech
            if not callback_data.testing then
                if tech then
                    if force.technologies[tech] then
                        if not force.technologies[tech].researched then
                            entity.destroy()
                            return
                        end
                    end
                end
            end

            local quality_buildings = Public.get_stateful('quality_buildings')
            local quality = 'normal'

            if random(1, 32) == 1 then
                quality = quality_buildings or 'normal'
            end

            local recipe = stack.recipe
            if recipe then
                entity.set_recipe(recipe, quality)
            else
                local furance_item = stack.furance_item
                if furance_item then
                    local item_stack = { name = furance_item, count = 1, quality = quality }
                    local inv = entity.get_inventory(defines.inventory.crafter_output)
                    inv.insert(item_stack)
                end
            end

            local x, y = p.x, p.y
            local distance = sqrt(x * x + y * y)

            local output = stack.output
            if #output == 0 then
                add_magic_crafter_output(entity, output, distance, quality)
            else
                for o_i = 1, #output do
                    local o = output[o_i]
                    add_magic_crafter_output(entity, o, distance, quality)
                end
            end

            if not callback_data.keep_active then
                Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
            end
        end
    )

function Public.prepare_weighted_loot(loot)
    local total = 0
    local weights = {}

    for i = 1, #loot do
        local v = loot[i]
        total = total + v.weight
        weights[#weights + 1] = total
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    --entity.destructible = false

    local i = random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.insert { name = stack.name, count = count }
end

local function calc_players()
    local players = game.connected_players
    local check_afk_players = Public.get('check_afk_players')
    if not check_afk_players then
        return #players
    end
    local total = 0
    Core.iter_connected_players(
        function (player)
            if player.afk_time < 36000 then
                total = total + 1
            end
        end
    )
    if total <= 0 then
        total = #players
    end
    return total
end

remove_boost_movement_speed_on_respawn =
    Task.register(
        function (data)
            local player = data.player
            if not player or not player.valid then
                return
            end


            Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'v3_move_boost')
            Modifiers.update_player_modifiers(player)

            if not Public.is_task_done() then return end
            player.print('[color=yellow][Temporary Boost][/color] Movement speed bonus removed!', { color = Color.info })
            local rpg_t = RPG.get_value_from_player(player.index)
            if not rpg_t then
                return
            end

            rpg_t.has_boost_on_respawn = nil
        end
    )

local boost_movement_speed_on_respawn =
    Task.register(
        function (data)
            local player = data.player
            if not player or not player.valid then
                return
            end
            if not player.character or not player.character.valid then
                return
            end

            local rpg_t = RPG.get_value_from_player(player.index)
            if not rpg_t then
                return
            end

            if rpg_t.has_boost_on_respawn then
                return
            end

            rpg_t.has_boost_on_respawn = true

            Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'v3_move_boost', 1)
            Modifiers.update_player_modifiers(player)

            Task.set_timeout_in_ticks(800, remove_boost_movement_speed_on_respawn, { player = player })
            player.print('[color=yellow][Temporary Boost][/color] Movement speed bonus applied! Be quick and fetch your corpse!', { color = Color.info })
        end
    )

local function on_wave_created(event)
    if not event or not event.wave_number then
        return
    end

    local wave_number = event.wave_number

    if wave_number % 50 == 0 then
        if wave_number >= 1500 then
            WD.set_pause_wave_in_ticks(random(36000, 54000))
        else
            WD.set_pause_wave_in_ticks(random(18000, 54000))
        end
    end
end

local function on_primary_target_missing()
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    WD.set('target', locomotive)
    local target_settings = WD.get_es('target_settings')
    target_settings.main_target = locomotive
    WD.set_main_target(locomotive)
end

local function on_player_cursor_stack_changed(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local item = player.cursor_stack

    if not item then
        return
    end

    if not item.valid_for_read then
        return
    end

    local name = item.name

    local blacklisted_spawn_items =
    {
        ['spidertron-remote'] = true,
        ['artillery-targeting-remote'] = true,
    }

    if blacklisted_spawn_items[name] then
        player.print('You are not allowed to use this item.', { color = Color.warning })
        player.cursor_stack.clear()
        return
    end
end

local function on_chart_tag_added(event)
    local tag = event.tag
    if not tag then return end
    local force = event.force
    if not force then return end

    local charts = Public.get('charts')
    if not charts then return end
    if not charts.tags then return end


    charts.tags[#charts.tags + 1] = tag
end

function Public.clear_all_chart_tags()
    local charts = Public.get('charts')
    if not charts then return end
    if not charts.tags then return end

    for i = 1, #charts.tags do
        local tag = charts.tags[i]
        if tag and tag.valid then
            tag.destroy()
        end
    end

    charts.tags = {}
end

function Public.set_unit_raffle()
    local unit_settings = WD.get('unit_settings')
    unit_settings.custom_unit_raffle = set_unit_raffle_token
end

function Public.get_rpg_from_player(player)
    local rpg_t = RPG.get_value_from_player(player.index)
    if not rpg_t then
        return
    end
    return rpg_t
end

function Public.set_xp_yield()
    RPG.set_rpg_xp_yield(
        {
            ['biter-spawner'] = 64,
            ['spitter-spawner'] = 64,
            ['behemoth-biter'] = 64,
            ['behemoth-spitter'] = 64,
            ['big-biter'] = 8,
            ['big-spitter'] = 8,
            ['medium-biter'] = 4,
            ['medium-spitter'] = 4,
            ['small-wriggler-pentapod'] = 1,
            ['medium-wriggler-pentapod'] = 4,
            ['big-wriggler-pentapod'] = 8,
            ['small-wriggler-pentapod-premature'] = 1,
            ['medium-wriggler-pentapod-premature'] = 4,
            ['big-wriggler-pentapod-premature'] = 8,
            ['small-strafer-pentapod'] = 10,
            ['medium-strafer-pentapod'] = 20,
            ['big-strafer-pentapod'] = 40,
            ['small-stomper-pentapod'] = 40,
            ['medium-stomper-pentapod'] = 80,
            ['big-stomper-pentapod'] = 160,
            ['small-demolisher'] = 100,
            ['medium-demolisher'] = 200,
            ['big-demolisher'] = 400,
            ['small-biter'] = 1,
            ['small-spitter'] = 1,
            ['small-worm-turret'] = 16,
            ['medium-worm-turret'] = 32,
            ['big-worm-turret'] = 64,
            ['behemoth-worm-turret'] = 128,
            ['mtn-addon-small-piercing-biter-t1'] = 2,
            ['mtn-addon-small-piercing-biter-t2'] = 3,
            ['mtn-addon-small-piercing-biter-t3'] = 4,
            ['mtn-addon-small-acid-biter-t1'] = 2,
            ['mtn-addon-small-acid-biter-t2'] = 3,
            ['mtn-addon-small-acid-biter-t3'] = 4,
            ['mtn-addon-small-explosive-biter-t1'] = 2,
            ['mtn-addon-small-explosive-biter-t2'] = 3,
            ['mtn-addon-small-explosive-biter-t3'] = 4,
            ['mtn-addon-small-poison-biter-t1'] = 2,
            ['mtn-addon-small-poison-biter-t2'] = 3,
            ['mtn-addon-small-poison-biter-t3'] = 4,
            ['mtn-addon-small-fire-biter-t1'] = 2,
            ['mtn-addon-small-fire-biter-t2'] = 3,
            ['mtn-addon-small-fire-biter-t3'] = 4,
            ['mtn-addon-small-piercing-spitter-t1'] = 2,
            ['mtn-addon-small-piercing-spitter-t2'] = 3,
            ['mtn-addon-small-piercing-spitter-t3'] = 4,
            ['mtn-addon-small-acid-spitter-t1'] = 2,
            ['mtn-addon-small-acid-spitter-t2'] = 3,
            ['mtn-addon-small-acid-spitter-t3'] = 4,
            ['mtn-addon-small-explosive-spitter-t1'] = 2,
            ['mtn-addon-small-explosive-spitter-t2'] = 3,
            ['mtn-addon-small-explosive-spitter-t3'] = 4,
            ['mtn-addon-small-poison-spitter-t1'] = 2,
            ['mtn-addon-small-poison-spitter-t2'] = 3,
            ['mtn-addon-small-poison-spitter-t3'] = 4,
            ['mtn-addon-small-fire-spitter-t1'] = 2,
            ['mtn-addon-small-fire-spitter-t2'] = 3,
            ['mtn-addon-small-fire-spitter-t3'] = 4,
            ['mtn-addon-medium-piercing-biter-t1'] = 6,
            ['mtn-addon-medium-piercing-biter-t2'] = 7,
            ['mtn-addon-medium-piercing-biter-t3'] = 8,
            ['mtn-addon-medium-acid-biter-t1'] = 6,
            ['mtn-addon-medium-acid-biter-t2'] = 7,
            ['mtn-addon-medium-acid-biter-t3'] = 8,
            ['mtn-addon-medium-explosive-biter-t1'] = 6,
            ['mtn-addon-medium-explosive-biter-t2'] = 7,
            ['mtn-addon-medium-explosive-biter-t3'] = 8,
            ['mtn-addon-medium-poison-biter-t1'] = 6,
            ['mtn-addon-medium-poison-biter-t2'] = 7,
            ['mtn-addon-medium-poison-biter-t3'] = 8,
            ['mtn-addon-medium-fire-biter-t1'] = 6,
            ['mtn-addon-medium-fire-biter-t2'] = 7,
            ['mtn-addon-medium-fire-biter-t3'] = 8,
            ['mtn-addon-medium-piercing-spitter-t1'] = 6,
            ['mtn-addon-medium-piercing-spitter-t2'] = 7,
            ['mtn-addon-medium-piercing-spitter-t3'] = 8,
            ['mtn-addon-medium-acid-spitter-t1'] = 6,
            ['mtn-addon-medium-acid-spitter-t2'] = 7,
            ['mtn-addon-medium-acid-spitter-t3'] = 8,
            ['mtn-addon-medium-explosive-spitter-t1'] = 6,
            ['mtn-addon-medium-explosive-spitter-t2'] = 7,
            ['mtn-addon-medium-explosive-spitter-t3'] = 8,
            ['mtn-addon-medium-poison-spitter-t1'] = 6,
            ['mtn-addon-medium-poison-spitter-t2'] = 7,
            ['mtn-addon-medium-poison-spitter-t3'] = 8,
            ['mtn-addon-medium-fire-spitter-t1'] = 6,
            ['mtn-addon-medium-fire-spitter-t2'] = 7,
            ['mtn-addon-medium-fire-spitter-t3'] = 8,
            ['mtn-addon-big-piercing-biter-t1'] = 10,
            ['mtn-addon-big-piercing-biter-t2'] = 12,
            ['mtn-addon-big-piercing-biter-t3'] = 14,
            ['mtn-addon-big-acid-biter-t1'] = 10,
            ['mtn-addon-big-acid-biter-t2'] = 12,
            ['mtn-addon-big-acid-biter-t3'] = 14,
            ['mtn-addon-big-explosive-biter-t1'] = 10,
            ['mtn-addon-big-explosive-biter-t2'] = 12,
            ['mtn-addon-big-explosive-biter-t3'] = 14,
            ['mtn-addon-big-poison-biter-t1'] = 10,
            ['mtn-addon-big-poison-biter-t2'] = 12,
            ['mtn-addon-big-poison-biter-t3'] = 14,
            ['mtn-addon-big-fire-biter-t1'] = 10,
            ['mtn-addon-big-fire-biter-t2'] = 12,
            ['mtn-addon-big-fire-biter-t3'] = 14,
            ['mtn-addon-big-piercing-spitter-t1'] = 10,
            ['mtn-addon-big-piercing-spitter-t2'] = 12,
            ['mtn-addon-big-piercing-spitter-t3'] = 14,
            ['mtn-addon-big-acid-spitter-t1'] = 10,
            ['mtn-addon-big-acid-spitter-t2'] = 12,
            ['mtn-addon-big-acid-spitter-t3'] = 14,
            ['mtn-addon-big-explosive-spitter-t1'] = 10,
            ['mtn-addon-big-explosive-spitter-t2'] = 12,
            ['mtn-addon-big-explosive-spitter-t3'] = 14,
            ['mtn-addon-big-poison-spitter-t1'] = 10,
            ['mtn-addon-big-poison-spitter-t2'] = 12,
            ['mtn-addon-big-poison-spitter-t3'] = 14,
            ['mtn-addon-big-fire-spitter-t1'] = 10,
            ['mtn-addon-big-fire-spitter-t2'] = 12,
            ['mtn-addon-big-fire-spitter-t3'] = 14,
            ['mtn-addon-behemoth-piercing-biter-t1'] = 20,
            ['mtn-addon-behemoth-piercing-biter-t2'] = 22,
            ['mtn-addon-behemoth-piercing-biter-t3'] = 24,
            ['mtn-addon-behemoth-acid-biter-t1'] = 20,
            ['mtn-addon-behemoth-acid-biter-t2'] = 22,
            ['mtn-addon-behemoth-acid-biter-t3'] = 24,
            ['mtn-addon-behemoth-explosive-biter-t1'] = 20,
            ['mtn-addon-behemoth-explosive-biter-t2'] = 22,
            ['mtn-addon-behemoth-explosive-biter-t3'] = 24,
            ['mtn-addon-behemoth-poison-biter-t1'] = 20,
            ['mtn-addon-behemoth-poison-biter-t2'] = 22,
            ['mtn-addon-behemoth-poison-biter-t3'] = 24,
            ['mtn-addon-behemoth-fire-biter-t1'] = 20,
            ['mtn-addon-behemoth-fire-biter-t2'] = 22,
            ['mtn-addon-behemoth-fire-biter-t3'] = 24,
            ['mtn-addon-behemoth-piercing-spitter-t1'] = 20,
            ['mtn-addon-behemoth-piercing-spitter-t2'] = 22,
            ['mtn-addon-behemoth-piercing-spitter-t3'] = 24,
            ['mtn-addon-behemoth-acid-spitter-t1'] = 20,
            ['mtn-addon-behemoth-acid-spitter-t2'] = 22,
            ['mtn-addon-behemoth-acid-spitter-t3'] = 24,
            ['mtn-addon-behemoth-explosive-spitter-t1'] = 20,
            ['mtn-addon-behemoth-explosive-spitter-t2'] = 22,
            ['mtn-addon-behemoth-explosive-spitter-t3'] = 24,
            ['mtn-addon-behemoth-poison-spitter-t1'] = 20,
            ['mtn-addon-behemoth-poison-spitter-t2'] = 22,
            ['mtn-addon-behemoth-poison-spitter-t3'] = 24,
            ['mtn-addon-behemoth-fire-spitter-t1'] = 20,
            ['mtn-addon-behemoth-fire-spitter-t2'] = 22,
            ['mtn-addon-behemoth-fire-spitter-t3'] = 24,
            ['mtn-addon-small-explosive-worm-turret'] = 20,
            ['mtn-addon-small-fire-worm-turret'] = 20,
            ['mtn-addon-small-piercing-worm-turret'] = 20,
            ['mtn-addon-small-poison-worm-turret'] = 20,
            ['mtn-addon-small-electric-worm-turret'] = 20,
            ['mtn-addon-medium-explosive-worm-turret'] = 30,
            ['mtn-addon-medium-fire-worm-turret'] = 30,
            ['mtn-addon-medium-piercing-worm-turret'] = 30,
            ['mtn-addon-medium-poison-worm-turret'] = 30,
            ['mtn-addon-medium-electric-worm-turret'] = 30,
            ['mtn-addon-big-explosive-worm-turret'] = 40,
            ['mtn-addon-big-fire-worm-turret'] = 40,
            ['mtn-addon-big-piercing-worm-turret'] = 40,
            ['mtn-addon-big-poison-worm-turret'] = 40,
            ['mtn-addon-big-electric-worm-turret'] = 40,
            ['mtn-addon-giant-worm-turret'] = 80
        })
end

function Public.set_threat_values()
    WD.set('threat_values',
        {
            ['biter-spawner'] = 128,
            ['spitter-spawner'] = 128,
            ['behemoth-biter'] = 64,
            ['behemoth-spitter'] = 64,
            ['big-biter'] = 16,
            ['big-spitter'] = 16,
            ['medium-biter'] = 4,
            ['medium-spitter'] = 4,
            ['small-biter'] = 1,
            ['small-spitter'] = 1,
            ['small-worm-turret'] = 16,
            ['medium-worm-turret'] = 32,
            ['big-worm-turret'] = 64,
            ['behemoth-worm-turret'] = 128,

            -- space age
            ['small-wriggler-pentapod'] = 1,
            ['medium-wriggler-pentapod'] = 4,
            ['big-wriggler-pentapod'] = 16,
            ['small-wriggler-pentapod-premature'] = 1,
            ['medium-wriggler-pentapod-premature'] = 4,
            ['big-wriggler-pentapod-premature'] = 16,

            ['small-strafer-pentapod'] = 10,
            ['medium-strafer-pentapod'] = 20,
            ['big-strafer-pentapod'] = 40,

            ['small-stomper-pentapod'] = 40,
            ['medium-stomper-pentapod'] = 80,
            ['big-stomper-pentapod'] = 160,

            ['small-demolisher'] = 100,
            ['medium-demolisher'] = 200,
            ['big-demolisher'] = 400,

            -- custom biters/spitters
            ['mtn-addon-small-piercing-biter-t1'] = 2,
            ['mtn-addon-small-piercing-biter-t2'] = 3,
            ['mtn-addon-small-piercing-biter-t3'] = 4,
            ['mtn-addon-small-acid-biter-t1'] = 2,
            ['mtn-addon-small-acid-biter-t2'] = 3,
            ['mtn-addon-small-acid-biter-t3'] = 4,
            ['mtn-addon-small-explosive-biter-t1'] = 2,
            ['mtn-addon-small-explosive-biter-t2'] = 3,
            ['mtn-addon-small-explosive-biter-t3'] = 4,
            ['mtn-addon-small-poison-biter-t1'] = 2,
            ['mtn-addon-small-poison-biter-t2'] = 3,
            ['mtn-addon-small-poison-biter-t3'] = 4,
            ['mtn-addon-small-fire-biter-t1'] = 2,
            ['mtn-addon-small-fire-biter-t2'] = 3,
            ['mtn-addon-small-fire-biter-t3'] = 4,
            ['mtn-addon-small-piercing-spitter-t1'] = 2,
            ['mtn-addon-small-piercing-spitter-t2'] = 3,
            ['mtn-addon-small-piercing-spitter-t3'] = 4,
            ['mtn-addon-small-acid-spitter-t1'] = 2,
            ['mtn-addon-small-acid-spitter-t2'] = 3,
            ['mtn-addon-small-acid-spitter-t3'] = 4,
            ['mtn-addon-small-explosive-spitter-t1'] = 2,
            ['mtn-addon-small-explosive-spitter-t2'] = 3,
            ['mtn-addon-small-explosive-spitter-t3'] = 4,
            ['mtn-addon-small-poison-spitter-t1'] = 2,
            ['mtn-addon-small-poison-spitter-t2'] = 3,
            ['mtn-addon-small-poison-spitter-t3'] = 4,
            ['mtn-addon-small-fire-spitter-t1'] = 2,
            ['mtn-addon-small-fire-spitter-t2'] = 3,
            ['mtn-addon-small-fire-spitter-t3'] = 4,

            ['mtn-addon-medium-piercing-biter-t1'] = 6,
            ['mtn-addon-medium-piercing-biter-t2'] = 7,
            ['mtn-addon-medium-piercing-biter-t3'] = 8,
            ['mtn-addon-medium-acid-biter-t1'] = 6,
            ['mtn-addon-medium-acid-biter-t2'] = 7,
            ['mtn-addon-medium-acid-biter-t3'] = 8,
            ['mtn-addon-medium-explosive-biter-t1'] = 6,
            ['mtn-addon-medium-explosive-biter-t2'] = 7,
            ['mtn-addon-medium-explosive-biter-t3'] = 8,
            ['mtn-addon-medium-poison-biter-t1'] = 6,
            ['mtn-addon-medium-poison-biter-t2'] = 7,
            ['mtn-addon-medium-poison-biter-t3'] = 8,
            ['mtn-addon-medium-fire-biter-t1'] = 6,
            ['mtn-addon-medium-fire-biter-t2'] = 7,
            ['mtn-addon-medium-fire-biter-t3'] = 8,
            ['mtn-addon-medium-piercing-spitter-t1'] = 6,
            ['mtn-addon-medium-piercing-spitter-t2'] = 7,
            ['mtn-addon-medium-piercing-spitter-t3'] = 8,
            ['mtn-addon-medium-acid-spitter-t1'] = 6,
            ['mtn-addon-medium-acid-spitter-t2'] = 7,
            ['mtn-addon-medium-acid-spitter-t3'] = 8,
            ['mtn-addon-medium-explosive-spitter-t1'] = 6,
            ['mtn-addon-medium-explosive-spitter-t2'] = 7,
            ['mtn-addon-medium-explosive-spitter-t3'] = 8,
            ['mtn-addon-medium-poison-spitter-t1'] = 6,
            ['mtn-addon-medium-poison-spitter-t2'] = 7,
            ['mtn-addon-medium-poison-spitter-t3'] = 8,
            ['mtn-addon-medium-fire-spitter-t1'] = 6,
            ['mtn-addon-medium-fire-spitter-t2'] = 7,
            ['mtn-addon-medium-fire-spitter-t3'] = 8,

            ['mtn-addon-big-piercing-biter-t1'] = 24,
            ['mtn-addon-big-piercing-biter-t2'] = 26,
            ['mtn-addon-big-piercing-biter-t3'] = 28,
            ['mtn-addon-big-acid-biter-t1'] = 24,
            ['mtn-addon-big-acid-biter-t2'] = 26,
            ['mtn-addon-big-acid-biter-t3'] = 28,
            ['mtn-addon-big-explosive-biter-t1'] = 24,
            ['mtn-addon-big-explosive-biter-t2'] = 26,
            ['mtn-addon-big-explosive-biter-t3'] = 28,
            ['mtn-addon-big-poison-biter-t1'] = 24,
            ['mtn-addon-big-poison-biter-t2'] = 26,
            ['mtn-addon-big-poison-biter-t3'] = 28,
            ['mtn-addon-big-fire-biter-t1'] = 24,
            ['mtn-addon-big-fire-biter-t2'] = 26,
            ['mtn-addon-big-fire-biter-t3'] = 28,
            ['mtn-addon-big-piercing-spitter-t1'] = 24,
            ['mtn-addon-big-piercing-spitter-t2'] = 26,
            ['mtn-addon-big-piercing-spitter-t3'] = 28,
            ['mtn-addon-big-acid-spitter-t1'] = 24,
            ['mtn-addon-big-acid-spitter-t2'] = 26,
            ['mtn-addon-big-acid-spitter-t3'] = 28,
            ['mtn-addon-big-explosive-spitter-t1'] = 24,
            ['mtn-addon-big-explosive-spitter-t2'] = 26,
            ['mtn-addon-big-explosive-spitter-t3'] = 28,
            ['mtn-addon-big-poison-spitter-t1'] = 24,
            ['mtn-addon-big-poison-spitter-t2'] = 26,
            ['mtn-addon-big-poison-spitter-t3'] = 28,
            ['mtn-addon-big-fire-spitter-t1'] = 24,
            ['mtn-addon-big-fire-spitter-t2'] = 26,
            ['mtn-addon-big-fire-spitter-t3'] = 28,

            ['mtn-addon-behemoth-piercing-biter-t1'] = 110,
            ['mtn-addon-behemoth-piercing-biter-t2'] = 120,
            ['mtn-addon-behemoth-piercing-biter-t3'] = 130,
            ['mtn-addon-behemoth-acid-biter-t1'] = 110,
            ['mtn-addon-behemoth-acid-biter-t2'] = 120,
            ['mtn-addon-behemoth-acid-biter-t3'] = 130,
            ['mtn-addon-behemoth-explosive-biter-t1'] = 110,
            ['mtn-addon-behemoth-explosive-biter-t2'] = 120,
            ['mtn-addon-behemoth-explosive-biter-t3'] = 130,
            ['mtn-addon-behemoth-poison-biter-t1'] = 110,
            ['mtn-addon-behemoth-poison-biter-t2'] = 120,
            ['mtn-addon-behemoth-poison-biter-t3'] = 130,
            ['mtn-addon-behemoth-fire-biter-t1'] = 110,
            ['mtn-addon-behemoth-fire-biter-t2'] = 120,
            ['mtn-addon-behemoth-fire-biter-t3'] = 130,
            ['mtn-addon-behemoth-piercing-spitter-t1'] = 110,
            ['mtn-addon-behemoth-piercing-spitter-t2'] = 120,
            ['mtn-addon-behemoth-piercing-spitter-t3'] = 130,
            ['mtn-addon-behemoth-acid-spitter-t1'] = 110,
            ['mtn-addon-behemoth-acid-spitter-t2'] = 120,
            ['mtn-addon-behemoth-acid-spitter-t3'] = 130,
            ['mtn-addon-behemoth-explosive-spitter-t1'] = 110,
            ['mtn-addon-behemoth-explosive-spitter-t2'] = 120,
            ['mtn-addon-behemoth-explosive-spitter-t3'] = 130,
            ['mtn-addon-behemoth-poison-spitter-t1'] = 110,
            ['mtn-addon-behemoth-poison-spitter-t2'] = 120,
            ['mtn-addon-behemoth-poison-spitter-t3'] = 130,
            ['mtn-addon-behemoth-fire-spitter-t1'] = 110,
            ['mtn-addon-behemoth-fire-spitter-t2'] = 120,
            ['mtn-addon-behemoth-fire-spitter-t3'] = 130,

            ['mtn-addon-boss-piercing-biter-t1'] = 170,
            ['mtn-addon-boss-acid-biter-t1'] = 170,
            ['mtn-addon-boss-explosive-biter-t1'] = 170,
            ['mtn-addon-boss-poison-biter-t1'] = 170,
            ['mtn-addon-boss-fire-biter-t1'] = 170,
            ['mtn-addon-boss-piercing-spitter-t1'] = 170,
            ['mtn-addon-boss-acid-spitter-t1'] = 170,
            ['mtn-addon-boss-explosive-spitter-t1'] = 170,
            ['mtn-addon-boss-poison-spitter-t1'] = 170,
            ['mtn-addon-boss-fire-spitter-t1'] = 170,
            ['mtn-addon-boss-piercing-biter-t2'] = 190,
            ['mtn-addon-boss-acid-biter-t2'] = 190,
            ['mtn-addon-boss-explosive-biter-t2'] = 190,
            ['mtn-addon-boss-poison-biter-t2'] = 190,
            ['mtn-addon-boss-fire-biter-t2'] = 190,
            ['mtn-addon-boss-piercing-spitter-t2'] = 190,
            ['mtn-addon-boss-acid-spitter-t2'] = 190,
            ['mtn-addon-boss-explosive-spitter-t2'] = 190,
            ['mtn-addon-boss-poison-spitter-t2'] = 190,
            ['mtn-addon-boss-fire-spitter-t2'] = 190,
            ['mtn-addon-boss-piercing-biter-t3'] = 210,
            ['mtn-addon-boss-acid-biter-t3'] = 210,
            ['mtn-addon-boss-explosive-biter-t3'] = 210,
            ['mtn-addon-boss-poison-biter-t3'] = 210,
            ['mtn-addon-boss-fire-biter-t3'] = 210,
            ['mtn-addon-boss-piercing-spitter-t3'] = 210,
            ['mtn-addon-boss-acid-spitter-t3'] = 210,
            ['mtn-addon-boss-explosive-spitter-t3'] = 210,
            ['mtn-addon-boss-poison-spitter-t3'] = 210,
            ['mtn-addon-boss-fire-spitter-t3'] = 210,
            ['mtn-addon-boss-piercing-biter-t4'] = 230,
            ['mtn-addon-boss-acid-biter-t4'] = 230,
            ['mtn-addon-boss-explosive-biter-t4'] = 230,
            ['mtn-addon-boss-poison-biter-t4'] = 230,
            ['mtn-addon-boss-fire-biter-t4'] = 230,
            ['mtn-addon-boss-piercing-spitter-t4'] = 230,
            ['mtn-addon-boss-acid-spitter-t4'] = 230,
            ['mtn-addon-boss-explosive-spitter-t4'] = 230,
            ['mtn-addon-boss-poison-spitter-t4'] = 230,
            ['mtn-addon-boss-fire-spitter-t4'] = 230,
            ['mtn-addon-boss-piercing-biter-t5'] = 250,
            ['mtn-addon-boss-acid-biter-t5'] = 250,
            ['mtn-addon-boss-explosive-biter-t5'] = 250,
            ['mtn-addon-boss-poison-biter-t5'] = 250,
            ['mtn-addon-boss-fire-biter-t5'] = 250,
            ['mtn-addon-boss-piercing-spitter-t5'] = 250,
            ['mtn-addon-boss-acid-spitter-t5'] = 250,
            ['mtn-addon-boss-explosive-spitter-t5'] = 250,
            ['mtn-addon-boss-poison-spitter-t5'] = 250,
            ['mtn-addon-boss-fire-spitter-t5'] = 250,
            ['mtn-addon-boss-piercing-biter-t6'] = 270,
            ['mtn-addon-boss-acid-biter-t6'] = 270,
            ['mtn-addon-boss-explosive-biter-t6'] = 270,
            ['mtn-addon-boss-poison-biter-t6'] = 270,
            ['mtn-addon-boss-fire-biter-t6'] = 270,
            ['mtn-addon-boss-piercing-spitter-t6'] = 270,
            ['mtn-addon-boss-acid-spitter-t6'] = 270,
            ['mtn-addon-boss-explosive-spitter-t6'] = 270,
            ['mtn-addon-boss-poison-spitter-t6'] = 270,
            ['mtn-addon-boss-fire-spitter-t6'] = 270,
            ['mtn-addon-boss-piercing-biter-t7'] = 290,
            ['mtn-addon-boss-acid-biter-t7'] = 290,
            ['mtn-addon-boss-explosive-biter-t7'] = 290,
            ['mtn-addon-boss-poison-biter-t7'] = 290,
            ['mtn-addon-boss-fire-biter-t7'] = 290,
            ['mtn-addon-boss-piercing-spitter-t7'] = 290,
            ['mtn-addon-boss-acid-spitter-t7'] = 290,
            ['mtn-addon-boss-explosive-spitter-t7'] = 290,
            ['mtn-addon-boss-poison-spitter-t7'] = 290,
            ['mtn-addon-boss-fire-spitter-t7'] = 290,

            -- worms
            ['mtn-addon-small-explosive-worm-turret'] = 20,
            ['mtn-addon-small-fire-worm-turret'] = 20,
            ['mtn-addon-small-piercing-worm-turret'] = 20,
            ['mtn-addon-small-poison-worm-turret'] = 20,
            ['mtn-addon-small-electric-worm-turret'] = 20,
            ['mtn-addon-medium-explosive-worm-turret'] = 40,
            ['mtn-addon-medium-fire-worm-turret'] = 40,
            ['mtn-addon-medium-piercing-worm-turret'] = 40,
            ['mtn-addon-medium-poison-worm-turret'] = 40,
            ['mtn-addon-medium-electric-worm-turret'] = 40,
            ['mtn-addon-big-explosive-worm-turret'] = 80,
            ['mtn-addon-big-fire-worm-turret'] = 80,
            ['mtn-addon-big-piercing-worm-turret'] = 80,
            ['mtn-addon-big-poison-worm-turret'] = 80,
            ['mtn-addon-big-electric-worm-turret'] = 80,
            ['mtn-addon-giant-worm-turret'] = 120,
        })

    local unit_settings = WD.get('unit_settings')
    unit_settings.scale_units_by_health =
    {
        ['small-wriggler-pentapod'] = 1,
        ['medium-wriggler-pentapod'] = 0.75,
        ['big-wriggler-pentapod'] = 0.5,

        ['small-wriggler-pentapod-premature'] = 1,
        ['medium-wriggler-pentapod-premature'] = 0.75,
        ['big-wriggler-pentapod-premature'] = 0.5,

        ['small-strafer-pentapod'] = 0.7,
        ['medium-strafer-pentapod'] = 0.5,
        ['big-strafer-pentapod'] = 0.3,

        ['small-stomper-pentapod'] = 0.7,
        ['medium-stomper-pentapod'] = 0.5,
        ['big-stomper-pentapod'] = 0.3,

        ['small-demolisher'] = 0.4,
        ['medium-demolisher'] = 0.3,
        ['big-demolisher'] = 0.1,

        ['small-biter'] = 1,
        ['medium-biter'] = 0.75,
        ['big-biter'] = 0.5,
        ['behemoth-biter'] = 0.25,
        ['small-spitter'] = 1,
        ['medium-spitter'] = 0.75,
        ['big-spitter'] = 0.5,
        ['behemoth-spitter'] = 0.25,
        ['mtn-addon-small-piercing-biter-t1'] = 0.50,
        ['mtn-addon-small-piercing-biter-t2'] = 0.50,
        ['mtn-addon-small-piercing-biter-t3'] = 0.50,
        ['mtn-addon-small-acid-biter-t1'] = 0.50,
        ['mtn-addon-small-acid-biter-t2'] = 0.50,
        ['mtn-addon-small-acid-biter-t3'] = 0.50,
        ['mtn-addon-small-explosive-biter-t1'] = 0.50,
        ['mtn-addon-small-explosive-biter-t2'] = 0.50,
        ['mtn-addon-small-explosive-biter-t3'] = 0.50,
        ['mtn-addon-small-poison-biter-t1'] = 0.50,
        ['mtn-addon-small-poison-biter-t2'] = 0.50,
        ['mtn-addon-small-poison-biter-t3'] = 0.50,
        ['mtn-addon-small-fire-biter-t1'] = 0.50,
        ['mtn-addon-small-fire-biter-t2'] = 0.50,
        ['mtn-addon-small-fire-biter-t3'] = 0.50,

        ['mtn-addon-small-piercing-spitter-t1'] = 0.50,
        ['mtn-addon-small-piercing-spitter-t2'] = 0.50,
        ['mtn-addon-small-piercing-spitter-t3'] = 0.50,
        ['mtn-addon-small-acid-spitter-t1'] = 0.50,
        ['mtn-addon-small-acid-spitter-t2'] = 0.50,
        ['mtn-addon-small-acid-spitter-t3'] = 0.50,
        ['mtn-addon-small-explosive-spitter-t1'] = 0.50,
        ['mtn-addon-small-explosive-spitter-t2'] = 0.50,
        ['mtn-addon-small-explosive-spitter-t3'] = 0.50,
        ['mtn-addon-small-poison-spitter-t1'] = 0.50,
        ['mtn-addon-small-poison-spitter-t2'] = 0.50,
        ['mtn-addon-small-poison-spitter-t3'] = 0.50,
        ['mtn-addon-small-fire-spitter-t1'] = 0.50,
        ['mtn-addon-small-fire-spitter-t2'] = 0.50,
        ['mtn-addon-small-fire-spitter-t3'] = 0.50,

        ['mtn-addon-medium-piercing-biter-t1'] = 0.25,
        ['mtn-addon-medium-piercing-biter-t2'] = 0.25,
        ['mtn-addon-medium-piercing-biter-t3'] = 0.25,
        ['mtn-addon-medium-acid-biter-t1'] = 0.25,
        ['mtn-addon-medium-acid-biter-t2'] = 0.25,
        ['mtn-addon-medium-acid-biter-t3'] = 0.25,
        ['mtn-addon-medium-explosive-biter-t1'] = 0.25,
        ['mtn-addon-medium-explosive-biter-t2'] = 0.25,
        ['mtn-addon-medium-explosive-biter-t3'] = 0.25,
        ['mtn-addon-medium-poison-biter-t1'] = 0.25,
        ['mtn-addon-medium-poison-biter-t2'] = 0.25,
        ['mtn-addon-medium-poison-biter-t3'] = 0.25,
        ['mtn-addon-medium-fire-biter-t1'] = 0.25,
        ['mtn-addon-medium-fire-biter-t2'] = 0.25,
        ['mtn-addon-medium-fire-biter-t3'] = 0.25,
        ['mtn-addon-medium-piercing-spitter-t1'] = 0.25,
        ['mtn-addon-medium-piercing-spitter-t2'] = 0.25,
        ['mtn-addon-medium-piercing-spitter-t3'] = 0.25,
        ['mtn-addon-medium-acid-spitter-t1'] = 0.25,
        ['mtn-addon-medium-acid-spitter-t2'] = 0.25,
        ['mtn-addon-medium-acid-spitter-t3'] = 0.25,
        ['mtn-addon-medium-explosive-spitter-t1'] = 0.25,
        ['mtn-addon-medium-explosive-spitter-t2'] = 0.25,
        ['mtn-addon-medium-explosive-spitter-t3'] = 0.25,
        ['mtn-addon-medium-poison-spitter-t1'] = 0.25,
        ['mtn-addon-medium-poison-spitter-t2'] = 0.25,
        ['mtn-addon-medium-poison-spitter-t3'] = 0.25,
        ['mtn-addon-medium-fire-spitter-t1'] = 0.25,
        ['mtn-addon-medium-fire-spitter-t2'] = 0.25,
        ['mtn-addon-medium-fire-spitter-t3'] = 0.25,

        ['mtn-addon-big-piercing-biter-t1'] = 0.25,
        ['mtn-addon-big-piercing-biter-t2'] = 0.25,
        ['mtn-addon-big-piercing-biter-t3'] = 0.25,
        ['mtn-addon-big-acid-biter-t1'] = 0.25,
        ['mtn-addon-big-acid-biter-t2'] = 0.25,
        ['mtn-addon-big-acid-biter-t3'] = 0.25,
        ['mtn-addon-big-explosive-biter-t1'] = 0.25,
        ['mtn-addon-big-explosive-biter-t2'] = 0.25,
        ['mtn-addon-big-explosive-biter-t3'] = 0.25,
        ['mtn-addon-big-poison-biter-t1'] = 0.25,
        ['mtn-addon-big-poison-biter-t2'] = 0.25,
        ['mtn-addon-big-poison-biter-t3'] = 0.25,
        ['mtn-addon-big-fire-biter-t1'] = 0.25,
        ['mtn-addon-big-fire-biter-t2'] = 0.25,
        ['mtn-addon-big-fire-biter-t3'] = 0.25,
        ['mtn-addon-big-piercing-spitter-t1'] = 0.25,
        ['mtn-addon-big-piercing-spitter-t2'] = 0.25,
        ['mtn-addon-big-piercing-spitter-t3'] = 0.25,
        ['mtn-addon-big-acid-spitter-t1'] = 0.25,
        ['mtn-addon-big-acid-spitter-t2'] = 0.25,
        ['mtn-addon-big-acid-spitter-t3'] = 0.25,
        ['mtn-addon-big-explosive-spitter-t1'] = 0.25,
        ['mtn-addon-big-explosive-spitter-t2'] = 0.25,
        ['mtn-addon-big-explosive-spitter-t3'] = 0.25,
        ['mtn-addon-big-poison-spitter-t1'] = 0.25,
        ['mtn-addon-big-poison-spitter-t2'] = 0.25,
        ['mtn-addon-big-poison-spitter-t3'] = 0.25,
        ['mtn-addon-big-fire-spitter-t1'] = 0.25,
        ['mtn-addon-big-fire-spitter-t2'] = 0.25,
        ['mtn-addon-big-fire-spitter-t3'] = 0.25,

        ['mtn-addon-behemoth-piercing-biter-t1'] = 0.25,
        ['mtn-addon-behemoth-piercing-biter-t2'] = 0.25,
        ['mtn-addon-behemoth-piercing-biter-t3'] = 0.25,
        ['mtn-addon-behemoth-acid-biter-t1'] = 0.25,
        ['mtn-addon-behemoth-acid-biter-t2'] = 0.25,
        ['mtn-addon-behemoth-acid-biter-t3'] = 0.25,
        ['mtn-addon-behemoth-explosive-biter-t1'] = 0.25,
        ['mtn-addon-behemoth-explosive-biter-t2'] = 0.25,
        ['mtn-addon-behemoth-explosive-biter-t3'] = 0.25,
        ['mtn-addon-behemoth-poison-biter-t1'] = 0.25,
        ['mtn-addon-behemoth-poison-biter-t2'] = 0.25,
        ['mtn-addon-behemoth-poison-biter-t3'] = 0.25,
        ['mtn-addon-behemoth-fire-biter-t1'] = 0.25,
        ['mtn-addon-behemoth-fire-biter-t2'] = 0.25,
        ['mtn-addon-behemoth-fire-biter-t3'] = 0.25,
        ['mtn-addon-behemoth-piercing-spitter-t1'] = 0.25,
        ['mtn-addon-behemoth-piercing-spitter-t2'] = 0.25,
        ['mtn-addon-behemoth-piercing-spitter-t3'] = 0.25,
        ['mtn-addon-behemoth-acid-spitter-t1'] = 0.25,
        ['mtn-addon-behemoth-acid-spitter-t2'] = 0.25,
        ['mtn-addon-behemoth-acid-spitter-t3'] = 0.25,
        ['mtn-addon-behemoth-explosive-spitter-t1'] = 0.25,
        ['mtn-addon-behemoth-explosive-spitter-t2'] = 0.25,
        ['mtn-addon-behemoth-explosive-spitter-t3'] = 0.25,
        ['mtn-addon-behemoth-poison-spitter-t1'] = 0.25,
        ['mtn-addon-behemoth-poison-spitter-t2'] = 0.25,
        ['mtn-addon-behemoth-poison-spitter-t3'] = 0.25,
        ['mtn-addon-behemoth-fire-spitter-t1'] = 0.25,
        ['mtn-addon-behemoth-fire-spitter-t2'] = 0.25,
        ['mtn-addon-behemoth-fire-spitter-t3'] = 0.25,

        ['mtn-addon-boss-piercing-biter-t1'] = 0.10,
        ['mtn-addon-boss-acid-biter-t1'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t1'] = 0.10,
        ['mtn-addon-boss-poison-biter-t1'] = 0.10,
        ['mtn-addon-boss-fire-biter-t1'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t1'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t1'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t1'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t1'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t1'] = 0.10,
        ['mtn-addon-boss-piercing-biter-t2'] = 0.10,
        ['mtn-addon-boss-acid-biter-t2'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t2'] = 0.10,
        ['mtn-addon-boss-poison-biter-t2'] = 0.10,
        ['mtn-addon-boss-fire-biter-t2'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t2'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t2'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t2'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t2'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t2'] = 0.10,
        ['mtn-addon-boss-piercing-biter-t3'] = 0.10,
        ['mtn-addon-boss-acid-biter-t3'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t3'] = 0.10,
        ['mtn-addon-boss-poison-biter-t3'] = 0.10,
        ['mtn-addon-boss-fire-biter-t3'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t3'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t3'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t3'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t3'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t3'] = 0.10,
        ['mtn-addon-boss-piercing-biter-t4'] = 0.10,
        ['mtn-addon-boss-acid-biter-t4'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t4'] = 0.10,
        ['mtn-addon-boss-poison-biter-t4'] = 0.10,
        ['mtn-addon-boss-fire-biter-t4'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t4'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t4'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t4'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t4'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t4'] = 0.10,
        ['mtn-addon-boss-piercing-biter-t5'] = 0.10,
        ['mtn-addon-boss-acid-biter-t5'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t5'] = 0.10,
        ['mtn-addon-boss-poison-biter-t5'] = 0.10,
        ['mtn-addon-boss-fire-biter-t5'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t5'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t5'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t5'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t5'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t5'] = 0.10,
        ['mtn-addon-boss-piercing-biter-t6'] = 0.10,
        ['mtn-addon-boss-acid-biter-t6'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t6'] = 0.10,
        ['mtn-addon-boss-poison-biter-t6'] = 0.10,
        ['mtn-addon-boss-fire-biter-t6'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t6'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t6'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t6'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t6'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t6'] = 0.10,
        ['mtn-addon-boss-piercing-biter-t7'] = 0.10,
        ['mtn-addon-boss-acid-biter-t7'] = 0.10,
        ['mtn-addon-boss-explosive-biter-t7'] = 0.10,
        ['mtn-addon-boss-poison-biter-t7'] = 0.10,
        ['mtn-addon-boss-fire-biter-t7'] = 0.10,
        ['mtn-addon-boss-piercing-spitter-t7'] = 0.10,
        ['mtn-addon-boss-acid-spitter-t7'] = 0.10,
        ['mtn-addon-boss-explosive-spitter-t7'] = 0.10,
        ['mtn-addon-boss-poison-spitter-t7'] = 0.10,
        ['mtn-addon-boss-fire-spitter-t7'] = 0.10,
    }
    unit_settings.scale_worms_by_health =
    {
        ['land-mine'] = 0.5, -- not active as of now
        ['gun-turret'] = 0.5, -- not active as of now
        ['flamethrower-turret'] = 0.4, -- not active as of now
        ['artillery-turret'] = 0.25, -- not active as of now
        ['small-worm-turret'] = 0.8,
        ['medium-worm-turret'] = 0.6,
        ['big-worm-turret'] = 0.3,
        ['behemoth-worm-turret'] = 0.3,
        ['mtn-addon-small-explosive-worm-turret'] = 0.50,
        ['mtn-addon-small-fire-worm-turret'] = 0.50,
        ['mtn-addon-small-piercing-worm-turret'] = 0.50,
        ['mtn-addon-small-poison-worm-turret'] = 0.50,
        ['mtn-addon-small-electric-worm-turret'] = 0.50,
        ['mtn-addon-medium-explosive-worm-turret'] = 0.25,
        ['mtn-addon-medium-fire-worm-turret'] = 0.25,
        ['mtn-addon-medium-piercing-worm-turret'] = 0.25,
        ['mtn-addon-medium-poison-worm-turret'] = 0.25,
        ['mtn-addon-medium-electric-worm-turret'] = 0.25,
        ['mtn-addon-big-explosive-worm-turret'] = 0.1,
        ['mtn-addon-big-fire-worm-turret'] = 0.1,
        ['mtn-addon-big-piercing-worm-turret'] = 0.1,
        ['mtn-addon-big-poison-worm-turret'] = 0.1,
        ['mtn-addon-big-electric-worm-turret'] = 0.1,
        ['mtn-addon-giant-worm-turret'] = 0.05,
    }
end

function Public.set_worm_raffle()
    local unit_settings = WD.get('unit_settings')
    unit_settings.custom_worm_raffle = set_worm_raffle_token
end

function Public.find_rocks_and_slowly_remove()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.get_surface(active_surface_index)
    if not (surface and surface.valid) then
        return
    end

    local ents = surface.find_entities_filtered({ type = 'simple-entity' })
    if ents and #ents > 0 then
        Public.set('rocks_to_remove', ents)
    end
end

function Public.find_void_tiles_and_replace()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.get_surface(active_surface_index)
    if not (surface and surface.valid) then
        return
    end

    if not Public.get('find_void_tiles_and_replace') then
        Public.set('find_void_tiles_and_replace', true)

        local cp = Collapse.get_position()
        local rp = Collapse.get_reverse_position()

        local area =
        {
            left_top = { x = (-zone_settings.zone_width / 2) + 10, y = rp.y },
            right_bottom = { x = (zone_settings.zone_width / 2) - 10, y = cp.y }
        }

        local adjusted_zones = Public.get('adjusted_zones')

        if adjusted_zones.reversed then
            area =
            {
                left_top = { x = ((zone_settings.zone_width / 2) + 10) * -1, y = cp.y },
                right_bottom = { x = math.abs((-zone_settings.zone_width / 2) - 10), y = rp.y },
            }
        end

        local tiles = surface.find_tiles_filtered({ area = area, name = { 'out-of-map', 'water', 'deepwater', 'water-green', 'deepwater-green', 'void-tile', 'lava-hot' } })
        if tiles and #tiles > 0 then
            Public.set('tiles_to_replace', tiles)
        end
    end
end

function Public.set_difficulty()
    local final_battle = Public.get('final_battle')
    if final_battle then
        return
    end
    local pre_final_battle = Public.get('pre_final_battle')
    if pre_final_battle then
        return
    end

    local game_lost = Public.get('game_lost')
    if game_lost then
        return
    end
    local Diff = Difficulty.get()
    if not Diff then
        return
    end
    local wave_defense_table = WD.get_table()
    local check_if_threat_below_zero = Public.get('check_if_threat_below_zero')
    local collapse_amount = Public.get('collapse_amount')
    local collapse_speed = Public.get('collapse_speed')
    local difficulty = Public.get('difficulty')
    if not difficulty then
        return
    end
    local mining_bonus_till_wave = Public.get('mining_bonus_till_wave')
    local mining_bonus = Public.get('mining_bonus')
    local disable_mining_boost = Public.get('disable_mining_boost')
    local wave_number = WD.get_wave()
    local player_count = calc_players()

    if not Diff.value then
        Diff.value = 0.1
    end

    if not wave_defense_table.enforce_max_active_biters then
        if Diff.index == 1 then
            wave_defense_table.max_active_biters = 768 + player_count * (90 * Diff.value)
        elseif Diff.index == 2 then
            wave_defense_table.max_active_biters = 845 + player_count * (90 * Diff.value)
        elseif Diff.index == 3 then
            wave_defense_table.max_active_biters = 1000 + player_count * (90 * Diff.value)
        end

        if wave_defense_table.max_active_biters >= 4000 then
            wave_defense_table.max_active_biters = 4000
        end
    end

    -- threat gain / wave
    if Diff.index == 1 then
        wave_defense_table.threat_gain_multiplier = 1.2 + player_count * Diff.value * 0.1
    elseif Diff.index == 2 then
        wave_defense_table.threat_gain_multiplier = 2 + player_count * Diff.value * 0.1
    elseif Diff.index == 3 then
        wave_defense_table.threat_gain_multiplier = 4 + player_count * Diff.value * 0.1
    end

    -- local amount = player_count * 0.40 + 2 -- too high?
    local amount = player_count * difficulty.multiply + 2
    amount = floor(amount)
    if amount < difficulty.lowest then
        amount = difficulty.lowest
    elseif amount > difficulty.highest then
        amount = difficulty.highest -- lowered from 20 to 10
    end

    local wave = WD.get('wave_number')

    local threat_check = nil

    if check_if_threat_below_zero then
        threat_check = wave_defense_table.threat <= 0
    end

    if Diff.index == 1 then
        if wave < 100 then
            wave_defense_table.wave_interval = 4500
        else
            wave_defense_table.wave_interval = 3600 - player_count * 60
        end

        if wave_defense_table.wave_interval < 2000 or threat_check then
            wave_defense_table.wave_interval = 2000
        end
    elseif Diff.index == 2 then
        if wave < 100 then
            wave_defense_table.wave_interval = 3000
        else
            wave_defense_table.wave_interval = 2600 - player_count * 60
        end
        if wave_defense_table.wave_interval < 1800 or threat_check then
            wave_defense_table.wave_interval = 1800
        end
    elseif Diff.index == 3 then
        if wave < 100 then
            wave_defense_table.wave_interval = 3000
        else
            wave_defense_table.wave_interval = 1600 - player_count * 60
        end
        wave_defense_table.wave_interval = 1600 - player_count * 60
        if wave_defense_table.wave_interval < 1600 or threat_check then
            wave_defense_table.wave_interval = 1600
        end
    end

    if collapse_amount then
        Collapse.set_amount(collapse_amount)
    else
        Collapse.set_amount(amount)
    end
    if collapse_speed then
        Collapse.set_speed(collapse_speed)
    else
        if player_count >= 1 and player_count <= 8 then
            Collapse.set_speed(8)
        elseif player_count > 8 and player_count <= 20 then
            Collapse.set_speed(7)
        elseif player_count > 20 and player_count <= 35 then
            Collapse.set_speed(6)
        elseif player_count > 35 then
            Collapse.set_speed(5)
        end
    end

    if player_count >= 1 and not disable_mining_boost then
        local force = game.forces.player

        if wave_number < mining_bonus_till_wave then
            if player_count <= 5 then
                mining_bonus = 3
            elseif player_count <= 10 then
                mining_bonus = 1
            else
                mining_bonus = 0
            end
        end

        local previous_mining_bonus = Public.get('previous_mining_bonus') or 0

        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - previous_mining_bonus

        if force.manual_mining_speed_modifier < 0 then
            force.manual_mining_speed_modifier = 0
        end

        -- If mining bonuses are still enabled (wave number check)
        if wave_number < mining_bonus_till_wave then
            -- Apply new bonus if changed
            if mining_bonus ~= previous_mining_bonus then
                Server.output_script_data('Mining bonus changed from ' .. previous_mining_bonus .. ' to ' .. mining_bonus)
            end

            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + mining_bonus
            Public.set('previous_mining_bonus', mining_bonus)
            Public.set('mining_bonus', mining_bonus)
        else
            Server.output_script_data('Mining bonus is disabled, as the wave number is ' .. wave_number .. ' and mining_bonus_till_wave is ' .. mining_bonus_till_wave)
            Server.output_script_data('Force manual mining speed modifier is now: ' .. force.manual_mining_speed_modifier)
            Public.set('disable_mining_boost', true)
            Public.set('previous_mining_bonus', 0)
        end

        -- Final clamp
        if force.manual_mining_speed_modifier < 0 then
            force.manual_mining_speed_modifier = 0
        end
    end
end

function Public.render_direction(surface, reversed)
    local counter = Public.get('soft_reset_counter')
    local winter_mode = Public.get('winter_mode')
    local text = 'Welcome to Mountain Fortress v3!'
    if winter_mode then
        text = 'Welcome to Wintery Mountain Fortress v3!'
    end

    if Public.get('space_age') then
        text = 'Welcome to Mountain Fortress v3 - Space Age!'
    end

    Public.set(
        'current_season',
        rendering.draw_text
        {
            text = 'Season: ' .. Public.get_stateful('season'),
            surface = surface,
            target = { -0, 12 },
            color = { r = 0.98, g = 0.77, b = 0.22 },
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    )

    Task.set_timeout_in_ticks(25, do_season_fix_token, {})
    Task.set_timeout_in_ticks(50, do_season_fix_token, {})

    if counter then
        Public.set('counter',
            rendering.draw_text
            {
                text = text .. '\nRun: ' .. counter,
                surface = surface,
                target = { -0, 10 },
                color = FunctionColor,
                scale = 3,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            })
    else
        Public.set('counter', rendering.draw_text
            {
                text = text,
                surface = surface,
                target = { -0, 10 },
                color = FunctionColor,
                scale = 3,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            })
    end

    local x_min = -zone_settings.zone_width / 2
    local x_max = zone_settings.zone_width / 2

    if reversed then
        local inc = 0
        for i = 1, 5 do
            Public.set('direction_' .. i,
                rendering.draw_text
                {
                    text = '▲',
                    surface = surface,
                    target = { -0, -20 - inc },
                    color = FunctionColor,
                    scale = 3,
                    font = 'heading-1',
                    alignment = 'center',
                    scale_with_zoom = false
                })
            inc = inc + 10
        end
        Public.set('direction_attack', rendering.draw_text
            {
                text = 'Biters will attack this area.',
                surface = surface,
                target = { -0, -70 },
                color = FunctionColor,
                scale = 3,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            })
        surface.create_entity({ name = 'electric-beam', position = { x_min, -74 }, source = { x_min, -74 }, target = { x_max, -74 } })
        surface.create_entity({ name = 'electric-beam', position = { x_min, -74 }, source = { x_min, -74 }, target = { x_max, -74 } })
    else
        local inc = 0
        for i = 1, 5 do
            Public.set('direction_' .. i, rendering.draw_text
                {
                    text = '▼',
                    surface = surface,
                    target = { -0, 20 + inc },
                    color = FunctionColor,
                    scale = 3,
                    font = 'heading-1',
                    alignment = 'center',
                    scale_with_zoom = false
                })
            inc = inc + 10
        end
        Public.set('direction_attack', rendering.draw_text
            {
                text = 'Biters will attack this area.',
                surface = surface,
                target = { -0, 70 },
                color = FunctionColor,
                scale = 3,
                font = 'heading-1',
                alignment = 'center',
                scale_with_zoom = false
            })
        surface.create_entity({ name = 'electric-beam', position = { x_min, 74 }, source = { x_min, 74 }, target = { x_max, 74 } })
        surface.create_entity({ name = 'electric-beam', position = { x_min, 74 }, source = { x_min, 74 }, target = { x_max, 74 } })
    end
end

function Public.boost_difficulty()
    local difficulty_set = Public.get('difficulty_set')
    if difficulty_set then
        return
    end

    local force = game.forces.player

    force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.5
    force.character_running_speed_modifier = force.character_running_speed_modifier + 0.15
    force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier + 0.15
    Public.set('coin_amount', 1)
    Public.set('upgrades').flame_turret.limit = 12
    Public.set('upgrades').landmine.limit = 50
    Public.set('locomotive_health', 10000)
    Public.set('locomotive_max_health', 10000)
    Public.set('bonus_xp_on_join', 500)
    WD.set('next_wave', game.tick + 3600 * 15)
    Public.set('spidertron_unlocked_at_zone', 10)
    WD.set_normal_unit_current_health(1.2)
    WD.set_unit_health_increment_per_wave(0.30)
    WD.set_boss_unit_current_health(2)
    WD.set_boss_health_increment_per_wave(1.5)
    WD.set('death_mode', false)
    Public.set('difficulty_set', true)
end

function Public.set_spawn_position()
    local collapse_pos = Collapse.get_position()
    local locomotive = Public.get('locomotive')
    local final_battle = Public.get('final_battle')
    if final_battle then
        return
    end
    if not locomotive or not locomotive.valid then
        return
    end
    --TODO check if final battle
    local l = locomotive.position

    local retries = 0

    local function check_tile(surface, tile, tbl, inc)
        if not (surface and surface.valid) then
            return false
        end
        if not tile then
            return false
        end
        local get_tile = surface.get_tile(tile)
        if get_tile.valid and (get_tile.name == 'out-of-map' or get_tile.name == 'void-tile') then
            remove(tbl, inc - inc + 1)
            return true
        else
            return false
        end
    end

    ::retry::

    local y_value_position = Public.get('y_value_position')
    local locomotive_positions = Public.get('locomotive_pos')
    local total_pos = #locomotive_positions.tbl

    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local spawn_near_collapse = Public.get('spawn_near_collapse')

    if spawn_near_collapse.active then
        local collapse_position = surface.find_non_colliding_position('rocket-silo', collapse_pos, 64, 2)
        if not collapse_position then
            collapse_position = surface.find_non_colliding_position('solar-panel', collapse_pos, 32, 2)
        end
        if not collapse_position then
            collapse_position = surface.find_non_colliding_position('steel-chest', collapse_pos, 32, 2)
        end
        local sizeof = locomotive_positions.tbl[total_pos - total_pos + 1]
        if not sizeof then
            goto continue
        end

        if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
            retries = retries + 1
            if retries == 2 then
                goto continue
            end
            goto retry
        end

        local locomotive_position = surface.find_non_colliding_position('steel-chest', sizeof, 128, 1)
        local distance_from = floor(math2d.position.distance(locomotive_position, locomotive.position))
        local l_y = l.y
        local t_y = locomotive_position.y
        local c_y = collapse_pos.y
        local adjusted_zones = Public.get('adjusted_zones')

        local compare_pos
        local compare_next
        if adjusted_zones.reversed then
            compare_pos = l_y - t_y >= spawn_near_collapse.compare
            compare_next = c_y - t_y >= spawn_near_collapse.compare_next
        else
            compare_pos = l_y - t_y <= spawn_near_collapse.compare
            compare_next = c_y - t_y <= spawn_near_collapse.compare_next
        end

        if total_pos > spawn_near_collapse.total_pos then
            if compare_pos then
                if locomotive_position then
                    if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
                        debug_str('total_pos was higher - found oom')
                        retries = retries + 1
                        if retries == 2 then
                            goto continue
                        end
                        goto retry
                    end
                    debug_str('total_pos was higher - spawning at locomotive_position')
                    WD.set_spawn_position(locomotive_position)
                end
            elseif compare_next then
                if distance_from >= spawn_near_collapse.distance_from then
                    local success = check_tile(surface, locomotive_position, locomotive_positions.tbl, total_pos)
                    if success then
                        debug_str('distance_from was higher - found oom')
                        return
                    end
                    debug_str('distance_from was higher - spawning at locomotive_position')
                    WD.set_spawn_position({ x = locomotive_position.x, y = collapse_pos.y - y_value_position })
                else
                    debug_str('distance_from was lower - spawning at locomotive_position')
                    WD.set_spawn_position({ x = locomotive_position.x, y = collapse_pos.y - y_value_position })
                end
            else
                if collapse_position then
                    debug_str('total_pos was higher - spawning at collapse_position')
                    collapse_position = { x = collapse_position.x, y = collapse_position.y - y_value_position }
                    WD.set_spawn_position(collapse_position)
                end
            end
        else
            if collapse_position then
                debug_str('total_pos was lower - spawning at collapse_position')
                collapse_position = { x = collapse_position.x, y = collapse_position.y - y_value_position }
                WD.set_spawn_position(collapse_position)
            end
        end
    end

    ::continue::
end

local function on_marked_for_deconstruction(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if not event.player_index then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.surface.name:find('platform') then
        return
    end


    if player.controller_type == defines.controllers.remote then
        entity.cancel_deconstruction(player.force, player)
        player.print("You cannot deconstruct while in remote view!", { r = 1, g = 0.5, b = 0.5 })
    end
end


function Public.on_player_joined_game(event)
    local players = Public.get('players')
    local player = game.players[event.player_index]
    local starting_planet = Public.get_planet()

    Difficulty.clear_top_frame(player)
    Modifiers.update_player_modifiers(player)
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index or starting_planet]

    local current_task = Public.get('current_task')
    if not current_task.done then
        local init_surface = game.get_surface('Init')
        if init_surface and init_surface.valid then
            surface = init_surface
            Score.init_player_table(player, true)
            Modifiers.reset_player_modifiers(player)
            WD.destroy_wave_gui(player)
            ICMinimap.kill_minimap(player)
            Event.raise(Public.events.reset_map, { player_index = player.index })
            Public.add_player_to_permission_group(player, 'init_island', true)
        end
    end



    if player.online_time < 1 then
        if not players[player.index] then
            players[player.index] = {}
        end
        local message = ({ 'main.greeting', player.name })
        Alert.alert_player(player, 15, message)
        if Public.get('death_mode') then
            local death_message = ({ 'main.death_mode_warning' })
            Alert.alert_player(player, 15, death_message)
        end
        player.clear_items_inside()
        -- if Public.is_modded then
        --     draw_notice_frame(player)
        -- end

        for item, data in pairs(this.starting_items) do
            player.insert({ name = item, count = data.count })
        end
    end

    ICW_Func.is_minimap_valid(player, surface)

    if player.online_time < 1 then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    else
        local p = { x = player.physical_position.x, y = player.physical_position.y }
        local get_tile = surface.get_tile(p.x, p.y)
        if get_tile.valid and (get_tile.name == 'out-of-map' or get_tile.name == 'void-tile') then
            local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0)
            if pos then
                player.teleport(pos, surface)
            else
                pos = game.forces.player.get_spawn_position(surface)
                player.teleport(pos, surface)
            end
        end
    end



    local locomotive = Public.get('locomotive')

    if not locomotive or not locomotive.valid then
        return
    end

    local adjusted_zones = Public.get('adjusted_zones')
    local distance_from_train
    if adjusted_zones.reversed then
        distance_from_train = player.physical_position.y < locomotive.position.y
    else
        distance_from_train = player.physical_position.y > locomotive.position.y
    end

    if distance_from_train then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    end

    if player.surface.name == 'nauvis' or player.surface.index == '1' then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    end
end

function Public.on_player_created(event)
    local player = game.players[event.player_index]
    draw_notice_frame(player)
end

function Public.on_player_left_game()
    Public.set_difficulty()
end

function Public.is_creativity_mode_on()
    local creative_enabled = Misc.get('creative_enabled')
    if creative_enabled then
        WD.set('next_wave', 1000)
        Public.set_difficulty()
    end
end

function Public.disable_creative()
    Misc.set('creative_enabled', false)
end

function Public.on_player_respawned(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    if player.character and player.character.valid then
        Task.set_timeout_in_ticks(15, boost_movement_speed_on_respawn, { player = player })
        player.character.health = round(player.character.health * health_values[random(1, #health_values)])
        player.print(random_respawn_messages[random(1, #random_respawn_messages)])
    end
end

function Public.on_player_driving_changed_state(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local unit_number = entity.unit_number

    local wagons_in_the_wild = Public.get('wagons_in_the_wild')
    if not wagons_in_the_wild or not next(wagons_in_the_wild) then
        return
    end

    local wagon = wagons_in_the_wild[unit_number]
    if not wagon or not wagon.valid then
        wagons_in_the_wild[unit_number] = nil
        return
    end

    wagon.destructible = true

    wagons_in_the_wild[unit_number] = nil
end

function Public.on_pre_player_toggled_map_editor(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.name == 'Gerkiz' or not game.is_multiplayer() then
        return
    end

    if this.editor_mode[player.index] then
        return
    end

    this.editor_mode[player.index] = true

    player.toggle_map_editor()
    Task.set_timeout_in_ticks(5, exit_editor_mode_token, { player_index = player.index })
end

function Public.on_player_changed_surface(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local force = game.forces.player
    if force.technologies['rocket-silo'].researched then
        return
    end

    if player.controller_type == defines.controllers.remote then
        return
    end

    if player.controller_type == defines.controllers.spectator then
        return
    end

    local surface_index = event.surface_index
    if not surface_index then
        Server.output_script_data('No surface index found - old one was removed.')
    end

    local starting_planet = Public.get_planet()

    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index or starting_planet]



    if player.physical_surface.name == 'nauvis' or player.physical_surface.index == '1' then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    end
end

function Public.hinder_buildings_on_planet(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local starting_planet = Public.get_planet()

    if string.sub(entity.surface.name, 0, #starting_planet) == Public.init_name then
        entity.destroy()
        return
    end

    if string.sub(entity.surface.name, 0, #starting_planet) ~= starting_planet then
        return
    end

    local position = entity.position

    if disabled_ents[entity.name] then
        if event.player_index then
            local player = game.get_player(event.player_index)
            if player and player.valid then
                player.create_local_flying_text(
                    {
                        position = entity.position,
                        text = (entity.name .. ' cannot be built on the main surface.'),
                        color = { 255, 0, 0 },
                    }
                )

                player.physical_surface.spill_item_stack({ position = position, stack = { name = entity.name, count = 1, quality = 'normal' } })
            end
        else
            local robot = event.robot
            if robot and robot.valid then
                robot.surface.create_entity(
                    {
                        name = 'compi-speech-bubble',
                        position = entity.position,
                        text = (entity.name .. ' cannot be built on the main surface.'),
                        source = robot,
                        lifetime = 200
                    }
                )
                robot.surface.spill_item_stack({ position = entity.position, stack = { name = entity.name, count = 1 } })
            end
        end

        entity.destroy()
        return
    end
end

function Public.on_player_changed_position(event)
    local active_surface_index = Public.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local position = player.physical_position

    if not (position.x < Public.zone_settings.zone_width / 2 and position.x >= -Public.zone_settings.zone_width / 2) then
        return
    end

    if player.controller_type == defines.controllers.spectator then
        return
    end
    local starting_planet = Public.get_planet()

    if string.sub(player.physical_surface.name, 0, #starting_planet) ~= starting_planet then
        return
    end

    local surface = game.surfaces[active_surface_index]
    local adjusted_zones = Public.get('adjusted_zones')

    local p = { x = player.physical_position.x, y = player.physical_position.y }
    local config_tile = Public.get('void_or_tile')
    if config_tile == 'lab-dark-2' then
        local get_tile = surface.get_tile(p.x, p.y)
        if get_tile.valid and get_tile.name == 'lab-dark-2' then
            if random(1, 2) == 1 then
                if random(1, 2) == 1 then
                    show_text('This path is not for players!', p, surface, player)
                end
                player.physical_surface.create_entity({ name = 'fire-flame', position = player.physical_position })
                player.character.health = player.character.health - tile_damage
                if player.character.health == 0 then
                    player.character.die()
                    local message = ({ 'main.death_message_' .. random(1, 7), player.name })
                    game.print(message, { color = FunctionColor })
                end
            end
        end
    end

    if adjusted_zones.reversed then
        if position.y < -74 and (position.x < Public.zone_settings.zone_width / 2 and position.x >= -Public.zone_settings.zone_width / 2) then
            if player.character ~= nil then
                player.character.teleport({ position.x, position.y + 1 }, surface)
            end
            player.print(({ 'main.forcefield' }), { color = FunctionColor })
            if player.character then
                player.character.health = player.character.health - 5
                player.character.surface.create_entity({ name = 'water-splash', position = position })
                if player.character.health <= 0 then
                    player.character.die('enemy')
                end
            end
        end
    else
        if position.y >= 74 and (position.x < Public.zone_settings.zone_width / 2 and position.x >= -Public.zone_settings.zone_width / 2) then
            if player.character ~= nil then
                player.character.teleport({ position.x, position.y - 1 }, surface)
            end
            player.print(({ 'main.forcefield' }), { color = FunctionColor })
            if player.character then
                player.character.health = player.character.health - 5
                player.character.surface.create_entity({ name = 'water-splash', position = position })
                if player.character.health <= 0 then
                    player.character.die('enemy')
                end
            end
        end
    end
end

local disable_recipes = function (force)
    force.recipes['cargo-wagon'].enabled = false
    force.recipes['fluid-wagon'].enabled = false
    force.recipes['car'].enabled = false
    force.recipes['tank'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['artillery-turret'].enabled = false
    force.recipes['artillery-shell'].enabled = false
    force.recipes['locomotive'].enabled = false
    force.recipes['pistol'].enabled = false
    force.recipes['discharge-defense-equipment'].enabled = false

    -- local current_planet = Public.get_planet()
    -- if Public.is_modded_pt2 and current_planet == 'fortress' then
    --     force.recipes['thruster'].enabled = false
    -- end
end

function Public.disable_tech()
    local force = game.forces.player
    if not Public.is_modded_pt2 then
        force.technologies['landfill'].enabled = false
    end
    force.technologies['spidertron'].enabled = false
    force.technologies['spidertron'].researched = false
    force.technologies['atomic-bomb'].enabled = false
    force.technologies['atomic-bomb'].researched = false
    force.technologies['artillery'].enabled = false
    force.technologies['artillery'].researched = false
    force.technologies['artillery-shell-range-1'].enabled = false
    force.technologies['artillery-shell-range-1'].researched = false
    force.technologies['artillery-shell-speed-1'].enabled = false
    force.technologies['artillery-shell-speed-1'].researched = false
    if Public.get('spaces_age') then
        force.technologies['artillery-shell-damage-1'].enabled = false
        force.technologies['artillery-shell-damage-1'].researched = false
        force.technologies['elevated-rail'].enabled = false
        force.technologies['elevated-rail'].researched = false
        force.technologies['rail-support-foundations'].enabled = false
        force.technologies['rail-support-foundations'].researched = false
        force.recipes['railgun-turret'].enabled = false
        force.recipes['thruster'].enabled = false
    end
    force.technologies['lamp'].researched = true
    force.technologies['railway'].researched = true
    force.technologies['land-mine'].enabled = false
    force.technologies['fluid-wagon'].enabled = false
    force.technologies['cliff-explosives'].enabled = false

    disable_recipes(force)
end

local disable_tech = Public.disable_tech

---@param event EventData.on_research_finished
function Public.on_research_finished(event)
    disable_tech()

    local research = event.research
    local bonus_drill = game.forces.bonus_drill
    local player = game.forces.player

    local research_name = research.name
    local force = research.force

    if event.tick > 2000 then
        if Public.get('print_tech_to_discord') and force.name == 'player' then
            Server.to_discord_embed_raw('<a:Modded:835932131036364810> ' .. research_name:gsub('^%l', string.upper) .. ' has been researched!')
        end
    end

    if research.name == 'toolbelt' then
        Public.set('toolbelt_researched_count', 10)
    end

    if research.name == 'rocket-silo' then
        for _, f in pairs(game.forces) do
            f.set_surface_hidden(game.surfaces.nauvis, false)
        end
    end

    if script.active_mods.quality then
        local quality_list = Public.get('quality_list')
        if research.name == 'quality-module' then
            quality_list[#quality_list + 1] = 'uncommon'
        end
        if research.name == 'quality-module-2' then
            quality_list[#quality_list + 1] = 'rare'
        end
        if research.name == 'epic-quality' then
            quality_list[#quality_list + 1] = 'epic'
        end
        if research.name == 'legendary-quality' then
            quality_list[#quality_list + 1] = 'legendary'
        end
    end

    research.force.character_inventory_slots_bonus = (player.mining_drill_productivity_bonus * 50) + (Public.get('toolbelt_researched_count') or 0)
    if bonus_drill then
        bonus_drill.mining_drill_productivity_bonus = bonus_drill.mining_drill_productivity_bonus + 0.03
        if bonus_drill.mining_drill_productivity_bonus >= 3 then
            bonus_drill.mining_drill_productivity_bonus = 3
        end
    end

    local players = game.connected_players
    for i = 1, #players do
        local p = players[i]
        Modifiers.update_player_modifiers(p)
    end

    if research.name == 'steel-axe' then
        local msg = 'Steel-axe technology has been researched, 100% has been applied.\nBuy Pickaxe-upgrades in the market to boost it even more!'
        Alert.alert_all_players(30, msg, nil, 'achievement/tech-maniac', 0.6)
    end

    local force_name = research.force.name
    if not force_name then
        return
    end
    local flamethrower_damage = Public.get('flamethrower_damage')
    flamethrower_damage[force_name] = -0.85
    if research.name == 'military' then
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end

    if string.sub(research.name, 0, 18) == 'refined-flammables' then
        flamethrower_damage[force_name] = flamethrower_damage[force_name] + 0.10
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end
end

function Public.set_player_to_god(player)
    if player.character and player.character.valid then
        return false
    end

    if not player.character and player.controller_type ~= defines.controllers.spectator then
        player.print('[color=blue][Spectate][/color] It seems that you are not in the realm of the living.', { color = Color.warning })
        return false
    end

    local spectate = Public.get('spectate')

    if spectate[player.index] and spectate[player.index].delay and spectate[player.index].delay > game.tick then
        local cooldown = floor((spectate[player.index].delay - game.tick) / 60) + 1 .. ' seconds!'
        player.print('[color=blue][Spectate][/color] Retry again in ' .. cooldown, { color = Color.warning })
        return false
    end

    local old_group = game.permissions.get_group(spectate[player.index].old_group)
    if old_group then
        old_group.add_player(player)
    end

    spectate[player.index] = nil

    player.set_controller({ type = defines.controllers.god })
    player.create_character()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.get_surface(active_surface_index)
    if not surface or not surface.valid then
        return false
    end

    local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0)
    if pos then
        player.teleport(pos, surface)
    else
        pos = game.forces.player.get_spawn_position(surface)
        player.teleport(pos, surface)
    end


    Event.raise(
        CustomEvents.events.bottom_quickbar_respawn_raise,
        {
            player_index = player.index
        }
    )

    player.tag = ''

    game.print('[color=blue][Spectate][/color] ' .. player.name .. ' is no longer spectating!')
    Server.to_discord_bold(table.concat { '*** ', '[Spectate] ' .. player.name .. ' is no longer spectating!', ' ***' })
    return true
end

function Public.set_player_to_spectator(player)
    if player.in_combat then
        player.print('[color=blue][Spectate][/color] You are in combat. Try again soon.', { color = Color.warning })
        return false
    end


    if player.driving then
        return player.print('[color=blue][Spectate][/color] Please exit the vehicle before continuing', { color = Color.warning })
    end

    local spectate = Public.get('spectate')

    if not spectate[player.index] then
        spectate[player.index] =
        {
            verify = false
        }
        player.print('[color=blue][Spectate][/color] Please click the spectate button again if you really want to this.', { color = Color.warning })
        return false
    end

    if player.character and player.character.valid then
        player.character.die()
    end

    spectate[player.index].old_group = player.permission_group.name

    local spectate_group = game.permissions.get_group('spectator')
    if spectate_group then
        spectate_group.add_player(player)
    end

    player.character = nil
    player.spectator = true
    player.tag = '[img=utility/create_ghost_on_entity_death_modifier_icon]'
    player.set_controller({ type = defines.controllers.spectator })
    game.print('[color=blue][Spectate][/color] ' .. player.name .. ' is now spectating.')
    Server.to_discord_bold(table.concat { '*** ', '[Spectate] ' .. player.name .. ' is now spectating.', ' ***' })

    if spectate[player.index] and not spectate[player.index].delay then
        spectate[player.index].verify = true
        spectate[player.index].delay = game.tick + 3600
    end


    return true
end

Public.firearm_magazine_ammo = { name = 'firearm-magazine', count = 200 }
Public.piercing_rounds_magazine_ammo = { name = 'piercing-rounds-magazine', count = 200 }
Public.uranium_rounds_magazine_ammo = { name = 'uranium-rounds-magazine', count = 200 }
Public.light_oil_ammo = { name = 'light-oil', amount = 100 }
Public.artillery_shell_ammo = { name = 'artillery-shell', count = 15 }
Public.laser_turrent_power_source = { buffer_size = 2400000, power_production = 40000 }
Public.pause_waves_custom_callback_token = pause_waves_custom_callback_token
Public.x_marks_the_spot_custom_callback_token = x_marks_the_spot_custom_callback_token
Public.magicka_custom_callback_token = magicka_custom_callback_token
Public.fishy_callback_token = fishy_callback_token
Public.surface_validation_token = surface_validation_token

function Public.get_func(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.show_all_gui(player)
    for _, child in pairs(player.gui.top.children) do
        child.visible = true
    end
end

function Public.clear_spec_tag(player)
    if player.tag == '[Spectator]' then
        player.tag = ''
    end
end

function Public.equip_players(starting_items, recreate)
    local players = Public.get('players')

    for _, player in pairs(game.players) do
        if player.character and player.character.valid then
            player.character.destroy()
        end
        player.clear_items_inside()
        if player.connected then
            if not player.character then
                player.set_controller({ type = defines.controllers.god })
                player.create_character()
            end
            if player.character ~= nil then
                player.character.destructible = true
            end
            Modifiers.update_player_modifiers(player)
            if not recreate then
                starting_items = starting_items or this.starting_items
                if this.starting_items['modular-armor'] then
                    player.insert({ name = 'modular-armor', count = 1 })
                end

                for item, item_data in pairs(this.starting_items) do
                    if item ~= 'modular-armor' then
                        local equip = prototypes.equipment[item]
                        if equip then
                            local p_armor = player.get_inventory(defines.inventory.character_armor)
                            if p_armor and p_armor.valid and p_armor[1] and p_armor[1].valid_for_read and p_armor[1].grid and p_armor[1].grid.valid then
                                for _ = 1, item_data.count do
                                    p_armor[1].grid.put({ name = item })
                                end
                            else
                                player.insert({ name = item, count = item_data.count })
                            end
                        else
                            player.insert({ name = item, count = item_data.count })
                        end
                    end
                end
            end
            Public.show_all_gui(player)
            Public.clear_spec_tag(player)
        else
            if player.character then
                player.character.destructible = true
            end
            players[player.index] = nil
            Session.clear_player(player)
            game.remove_offline_players({ player.index })
        end
    end
end

function Public.reset_func_table()
    this.power_sources = { index = 1 }
    this.refill_turrets = { index = 1 }
    this.magic_crafters = { index = 1 }
    this.magic_fluid_crafters = { index = 1 }
    this.techs = {}
    this.limit_types = {}
    this.starting_items =
    {
        ['pistol'] =
        {
            count = 1
        },
        ['firearm-magazine'] =
        {
            count = 16
        },
        ['rail'] =
        {
            count = 16
        },
        ['wood'] =
        {
            count = 16
        },
        ['explosives'] =
        {
            count = 32
        }
    }
end

Gui.on_click(
    close_notice_frame_name,
    function (event)
        local player = event.player
        if not player or not player.valid then
            return
        end

        local screen = player.gui.screen[notice_frame_name]

        if screen and screen.valid then
            screen.destroy()
        end
    end)

local on_player_joined_game = Public.on_player_joined_game
local on_player_left_game = Public.on_player_left_game
local on_research_finished = Public.on_research_finished
local on_player_changed_position = Public.on_player_changed_position
local hinder_buildings_on_planet = Public.hinder_buildings_on_planet
local on_player_respawned = Public.on_player_respawned
local on_player_driving_changed_state = Public.on_player_driving_changed_state
local on_pre_player_toggled_map_editor = Public.on_pre_player_toggled_map_editor
local on_player_changed_surface = Public.on_player_changed_surface
local set_difficulty = Public.set_difficulty

Event.add(de.on_player_joined_game, on_player_joined_game)
Event.add(de.on_player_left_game, on_player_left_game)
Event.add(de.on_research_finished, on_research_finished)
Event.add(de.on_player_changed_position, on_player_changed_position)
Event.add(de.on_built_entity, hinder_buildings_on_planet)
Event.add(de.on_robot_built_entity, hinder_buildings_on_planet)
Event.add(de.on_player_respawned, on_player_respawned)
Event.add(de.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(de.on_pre_player_toggled_map_editor, on_pre_player_toggled_map_editor)
Event.add(de.on_player_changed_surface, on_player_changed_surface)
Event.add(de.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
Event.add(de.on_chart_tag_added, on_chart_tag_added)
Event.add(de.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.on_nth_tick(10, do_refill_turrets)
Event.on_nth_tick(10, do_magic_crafters)
Event.on_nth_tick(10, do_magic_fluid_crafters)
Event.on_nth_tick(60, do_artillery_turrets_targets)
Event.on_nth_tick(25, do_beams_away)
Event.on_nth_tick(30, do_clear_enemy_spawners)
Event.on_nth_tick(35, do_clear_rocks_slowly)
Event.on_nth_tick(35, do_replace_tiles_slowly)
Event.on_nth_tick(200, do_custom_surface_funcs)
Event.on_nth_tick(60, set_difficulty)
Event.add(CustomEvents.events.on_wave_created, on_wave_created)
Event.add(CustomEvents.events.on_primary_target_missing, on_primary_target_missing)

return Public
