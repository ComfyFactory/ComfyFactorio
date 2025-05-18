-- map by Cogito
-- heavily modified by Gerkiz

local Global = require 'utils.global'
local Session = require 'utils.datastore.session_data'
local Event = require 'utils.event'
local Server = require 'utils.server'
local MapFuntions = require 'utils.tools.map_functions'
local CommonFunctions = require 'utils.common'
local LayersFunctions = require 'maps.planet_prison.mod.layers'
local AIFunctions = require 'maps.planet_prison.ai'
local Blueprints = require 'maps.planet_prison.mod.bp'
local AfkFunctions = require 'maps.planet_prison.mod.afk'
local Timers = require 'utils.timers'
local ClaimsFunctions = require 'maps.planet_prison.mod.claims'
local MapConfig = require 'maps.planet_prison.config'
local Token = require 'utils.token'
local Color = require 'utils.color_presets'
local PlayerList = require 'utils.gui.player_list'
local PlayerShip = require 'maps.planet_prison.bp.player_ship'
local Merchant = require 'maps.planet_prison.bp.merchant'
local Reset = require 'utils.functions.soft_reset'
local Commands = require 'utils.commands'
local Discord = require 'utils.discord_handler'
local init_player

PlayerList.settings.disable_camera_for_non_admins = true
-- require 'modules.thirst'
local minable_wreckage_enabled = script.active_mods['MineableWreckage'] or false

local this =
{
    active_surface = nil,
    last_friend = nil,
    remove_offline_players =
    {
        players = {},
        -- time = 216000, -- 1h
        -- time = 5184000, -- 24h
        time = 1728000, -- 8h
        enabled = true
    }
}
local floor = math.floor
local ceil = math.ceil
local Public = {}
local insert = table.insert
local remove = table.remove
local random = math.random

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

this.maps =
{
    {
        name = 'flooded-metropolia',
        height = 2000,
        width = 2000,
        water = 1,
        terrain_segmentation = 8,
        property_expression_names =
        {
            moisture = 0,
            temperature = 30.
        },
        cliff_settings =
        {
            richness = 0
        },
        starting_area = 'none',
        autoplace_controls =
        {
            ['coal'] = { frequency = 0, size = 0, richness = 0 },
            ['stone'] = { frequency = 0, size = 0, richness = 0 },
            ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['crude-oil'] =
            {
                frequency = 1000,
                size = 1
            },
            ['trees'] =
            {
                frequency = 4
            },
            ['enemy-base'] =
            {
                frequency = 0
            }
        }
    },
    {
        name = 'swampy-rivers',
        height = 2500,
        width = 2500,
        water = 1,
        terrain_segmentation = 6,
        property_expression_names =
        {
            moisture = 0,
            temperature = 25.
        },
        cliff_settings =
        {
            richness = 0
        },
        starting_area = 'none',
        autoplace_controls =
        {
            ['coal'] = { frequency = 0, size = 0, richness = 0 },
            ['stone'] = { frequency = 0, size = 0, richness = 0 },
            ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['crude-oil'] =
            {
                frequency = 900,
                size = 1
            },
            ['trees'] =
            {
                frequency = 4
            },
            ['enemy-base'] =
            {
                frequency = 0
            }
        }
    }
}

local function exclude_surface(surface, state)
    for _, force in pairs(game.forces) do
        force.set_surface_hidden(surface, state or true)
    end
end

local function get_arena_map()
    local active_surface_index = this.active_surface_index
    if not active_surface_index then
        return game.surfaces.arena
    end
    return game.surfaces[active_surface_index]
end

local function assign_perks(player)
    this.perks[player.name] =
    {
        flashlight_enable = true,
        minimap = false,
        chat_global = true
    }
    return this.perks[player.name]
end

local assign_camouflage = function (ent, common)
    local shade = common.rand_range(20, 200)
    ent.color =
    {
        r = shade,
        g = shade,
        b = shade
    }
    ent.disable_flashlight()
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local delay_move_player_token =
    Token.register(
        function (event)
            local player_index = event.player_index
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end
            init_player(player)
        end
    )

local set_noise_hostile_hook =
    Token.register(
        function (data)
            local ent = data
            if not ent or not ent.valid then
                return
            end
            ent.force = 'enemy'
            if ent.name == 'character' then
                assign_camouflage(ent, CommonFunctions)

                if CommonFunctions.rand_range(1, 25) == 1 then
                    ent.insert({ name = 'submachine-gun', count = 1 })
                    ent.insert({ name = 'firearm-magazine', count = 20 })
                elseif CommonFunctions.rand_range(1, 5) == 1 then
                    ent.insert({ name = 'shotgun', count = 1 })
                    ent.insert({ name = 'shotgun-shell', count = 20 })
                else
                    ent.insert({ name = 'pistol', count = 1 })
                    ent.insert({ name = 'firearm-magazine', count = 20 })
                end

                if CommonFunctions.rand_range(1, 800) == 1 then
                    ent.insert({ name = 'modular-armor', count = 1 })
                elseif CommonFunctions.rand_range(1, 400) == 1 then
                    ent.insert({ name = 'heavy-armor', count = 1 })
                else
                    ent.insert({ name = 'light-armor', count = 1 })
                end
            else
                if CommonFunctions.rand_range(1, 500) == 1 then
                    ent.insert({ name = 'uranium-rounds-magazine', count = 200 })
                elseif CommonFunctions.rand_range(1, 250) == 1 then
                    ent.insert({ name = 'piercing-rounds-magazine', count = 200 })
                else
                    ent.insert({ name = 'firearm-magazine', count = 200 })
                end
            end
        end
    )

local set_neutral_to_entity =
    Token.register(
        function (entity)
            entity.force = 'neutral'
        end
    )

local fetch_common =
    Token.register(
        function ()
            return CommonFunctions
        end
    )

local industrial_zone_layers =
{
    {
        type = 'LuaTile',
        name = 'concrete',
        objects =
        {
            'concrete'
        },
        elevation = 0.3,
        resolution = 0.2,
        hook = nil,
        deps = nil
    },
    {
        type = 'LuaTile',
        name = 'stones',
        objects =
        {
            'stone-path'
        },
        elevation = 0.2,
        resolution = 0.4,
        hook = nil,
        deps = nil
    },
    {
        type = 'LuaTile',
        name = 'shallows',
        objects =
        {
            'water-shallow'
        },
        elevation = 0.7,
        resolution = 0.01,
        hook = nil,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'scrap',
        objects =
        {
            'crash-site-spaceship-wreck-small-1',
            'crash-site-spaceship-wreck-small-2',
            'crash-site-spaceship-wreck-small-3',
            'crash-site-spaceship-wreck-small-4',
            'crash-site-spaceship-wreck-small-5',
            'crash-site-spaceship-wreck-small-6'
        },
        elevation = 0.5,
        resolution = 0.1,
        hook = set_neutral_to_entity,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'walls',
        objects =
        {
            'stone-wall'
        },
        elevation = 0.5,
        resolution = 0.09,
        hook = set_neutral_to_entity,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'hostile',
        objects =
        {
            'character',
            'gun-turret'
        },
        elevation = 0.92,
        resolution = 0.99,
        hook = set_noise_hostile_hook,
        deps = fetch_common
    },
    {
        type = 'LuaEntity',
        name = 'structures',
        objects =
        {
            'big-electric-pole',
            'medium-electric-pole'
        },
        elevation = 0.9,
        resolution = 0.9,
        hook = set_neutral_to_entity,
        deps = nil
    }
}

if minable_wreckage_enabled then
    industrial_zone_layers[4].objects = { 'mineable-wreckage' }
end

local swampy_rivers_layers =
{
    {
        type = 'LuaTile',
        name = 'speedy_tiles',
        objects =
        {
            'black-refined-concrete'
        },
        elevation = 0.3,
        resolution = 0.2,
        hook = nil,
        deps = nil
    },
    {
        type = 'LuaTile',
        name = 'nuclear',
        objects =
        {
            'nuclear-ground'
        },
        elevation = 0.2,
        resolution = 0.4,
        hook = nil,
        deps = nil
    },
    {
        type = 'LuaTile',
        name = 'shallows',
        objects =
        {
            'water-shallow'
        },
        elevation = 0.7,
        resolution = 0.01,
        hook = nil,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'rocky',
        objects =
        {
            'big-sand-rock',
            'big-rock',
            'huge-rock'
        },
        elevation = 0.5,
        resolution = 0.1,
        hook = set_neutral_to_entity,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'walls',
        objects =
        {
            'stone-wall'
        },
        elevation = 0.5,
        resolution = 0.09,
        hook = set_neutral_to_entity,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'hostile',
        objects =
        {
            'character',
            'gun-turret'
        },
        elevation = 0.92,
        resolution = 0.99,
        hook = set_noise_hostile_hook,
        deps = fetch_common
    },
    {
        type = 'LuaEntity',
        name = 'structures',
        objects =
        {
            'big-electric-pole',
            'medium-electric-pole'
        },
        elevation = 0.9,
        resolution = 0.9,
        hook = set_neutral_to_entity,
        deps = nil
    }
}

this.presets =
{
    industrial_zone_layers,
    swampy_rivers_layers,
    industrial_zone_layers,
    swampy_rivers_layers,
    industrial_zone_layers,
    swampy_rivers_layers,
    industrial_zone_layers,
    swampy_rivers_layers
}

local function pick_map()
    return this.maps[CommonFunctions.rand_range(1, #this.maps)]
end

local function find_force(name)
    for _, f in pairs(game.forces) do
        if f.name == string.gsub(name, '_custom', '') then
            return f
        end
    end

    return nil
end

local init_player_ship_bp =
    Token.register(
        function (data)
            local player = data.player
            local entity = data.entity
            entity.force = player.force
            if entity.name == 'crash-site-chest-1' then
                local offers = this.events.player_loot
                shuffle(offers)

                for i = 1, math.min(5, #offers) do
                    entity.insert(offers[i])
                end
            end
        end
    )

this.events =
{
    merchant =
    {
        alive = false,
        moving = false,
        spawn_tick = 0,
        embark_tick = 0,
        position = { x = 0, y = 0 },
        offer = MapConfig.merchant_offer
    },
    player_loot = MapConfig.player_ship_loot,
}

local init_merchant_bp =
    Token.register(
        function (data)
            local entity = data.entity
            entity.force = 'merchant'
            entity.rotatable = false
            entity.minable = false
            if entity.name ~= 'market' then
                entity.operable = false
            else
                local offers = this.events.merchant.offer
                shuffle(offers)

                for i = 1, math.min(5, #offers) do
                    if offers[i] and offers[i].price[1] then
                        offers[i].price[1].count = math.random(offers[i].price[1].count, offers[i].price[1].count * 2)
                    end
                    entity.add_market_item(offers[i])
                end
            end
        end
    )

local function create_orbit_group()
    local orbit = game.permissions.create_group('orbit')
    for _, perm in pairs(MapConfig.permission_orbit) do
        ---@diagnostic disable-next-line: param-type-mismatch
        orbit.set_allows_action(perm, false)
    end
end

this.bp =
{
    player_ship = PlayerShip,
    merchant = Merchant
}

local function get_player_force(player, clean)
    if clean then return player.name end
    return player.name .. '_custom'
end

local function init_game()
    Commands.restore_states()
    Blueprints.push_blueprint('player_ship', this.bp.player_ship)
    Blueprints.set_blueprint_hook('player_ship', init_player_ship_bp)
    Blueprints.push_blueprint('merchant', this.bp.merchant)
    Blueprints.set_blueprint_hook('merchant', init_merchant_bp)
    LayersFunctions.init()
    ClaimsFunctions.init(MapConfig.claim_markers, MapConfig.claim_max_distance)


    local map = pick_map()
    local preset = this.presets[CommonFunctions.rand_range(1, #this.presets)]
    local surface

    if not this.active_surface_index then
        surface = game.create_surface('arena', map)
    else
        surface = Reset.soft_reset_map(game.surfaces[this.active_surface_index], map, {}, true, true)
    end
    exclude_surface(surface)
    this.active_surface_index = surface.index
    surface.brightness_visual_weights =
    {
        1 / 0.85,
        1 / 0.85,
        1 / 0.85
    }
    surface.ticks_per_day = 25000 * 4
    this.active_surface = surface.index
    this.perks = {}
    this.events.merchant.spawn_tick = game.tick + 5000
    this.events.raid_groups = {}
    this.events.raid_init = false
    this.events.annihilation = false
    this.events.reset_time = nil
    this.hard_restart = false
    this.announced_message = false
    this.annihilate_gui_button = false
    this.last_friend = {}
    this.last_friend_initiated = {}
    this.remove_offline_players =
    {
        players = {},
        -- time = 216000, -- 1h
        -- time = 5184000, -- 24h
        time = 1728000, -- 8h
        enabled = true
    }

    create_orbit_group()
    game.map_settings.pollution.enabled = false
    game.map_settings.enemy_evolution.enabled = false
    game.difficulty_settings.technology_price_multiplier = 0.3

    LayersFunctions.set_collision_mask({ 'water_tile' })

    for _, layer in pairs(preset) do
        LayersFunctions.add_noise_layer(layer.type, layer.name, layer.objects, layer.elevation, layer.resolution)
        if layer.hook ~= nil then
            if layer.hook and type(layer.hook) == 'number' then
                LayersFunctions.add_noise_layer_hook(layer.name, layer.hook)
            else
                local token = Token.register(layer.hook)
                LayersFunctions.add_noise_layer_hook(layer.name, token)
            end
        end

        if layer.deps ~= nil then
            if layer.deps and type(layer.deps) == 'number' then
                LayersFunctions.add_noise_layer_dependency(layer.name, layer.deps)
            else
                local token = Token.register(layer.deps)
                LayersFunctions.add_noise_layer_dependency(layer.name, token)
            end
        end
    end

    local default_group = game.permissions.get_group('Default')
    for _, perm in pairs(MapConfig.permission_non_gps) do
        ---@diagnostic disable-next-line: param-type-mismatch
        default_group.set_allows_action(perm, false)
    end

    local time = 10
    for _, player in pairs(game.connected_players) do
        player.spectator = false
        if player.character == nil then
            player.set_controller({ type = defines.controllers.god })
            player.create_character()
            player.character.active = false
        end

        local timer = Timers.set_timer(time, delay_move_player_token)
        time = time + 20
        Timers.set_timer_dependency(timer, { player_index = player.index })
        Timers.set_timer_start(timer)
    end
end

local explode_ship_update =
    Token.register(
        function (data)
            local id = data.id
            local time_left = data.time_left
            local ship = data.ship
            local time = CommonFunctions.get_time(time_left)
            for _, ent in pairs(ship.entities) do
                if not ent.valid then
                    return false
                end
            end

            id.text = time
            return true
        end
    )

local explode_ship =
    Token.register(
        function (data)
            local ship = data.ship
            local id = data.id
            local active_surface = data.active_surface
            local surface = game.get_surface(active_surface)
            if not surface or not surface.valid then
                return
            end

            for _, ent in pairs(Blueprints.reference_get_entities(ship)) do
                if not ent.valid then
                    goto continue
                end

                local explosion =
                {
                    name = 'massive-explosion',
                    position = ent.position
                }
                surface.create_entity(explosion)

                ::continue::
            end

            local bb = Blueprints.reference_get_bounding_box(ship)
            LayersFunctions.remove_excluding_bounding_box(bb)
            Blueprints.destroy_reference(surface, ship)
            if id and id.valid then
                id.destroy()
            end
        end
    )

local function do_spawn_point(player)
    local point =
    {
        x = CommonFunctions.get_axis(player.position, 'x'),
        y = CommonFunctions.get_axis(player.position, 'y') - 2
    }
    local instance = Blueprints.build(player.surface, 'player_ship', point, player)
    LayersFunctions.push_excluding_bounding_box(instance.bb)
    local time_left = MapConfig.self_explode

    local object =
    {
        text = CommonFunctions.get_time(time_left),
        surface = player.surface,
        color =
        {
            r = 255,
            g = 20,
            b = 20
        },
        target =
        {
            x = point.x - 2,
            y = point.y - 3
        },
        scale = 2.0
    }

    local id = rendering.draw_text(object)
    local data = { id = id, time_left = time_left, ship = instance, active_surface = player.surface.index }

    local timer = Timers.set_timer(time_left, explode_ship)
    Timers.set_timer_on_update(timer, explode_ship_update)
    Timers.set_timer_dependency(timer, data)
    Timers.set_timer_start(timer)
end

local function get_non_obstructed_position(s, radius)
    local chunk

    for _ = 1, 32 do
        chunk = s.get_random_chunk()
        chunk.x = chunk.x * 32
        chunk.y = chunk.y * 32

        local search_info =
        {
            position = chunk,
            radius = radius
        }

        local tiles = s.find_tiles_filtered(search_info)
        for _, tile in pairs(tiles) do
            if string.find(tile.name, 'water') ~= nil or string.find(tile.name, 'out') ~= nil then
                goto continue
            end
        end

        local force_search_info =
        {
            position = chunk,
            radius = radius,
            force = { 'neutral', 'enemy' },
            invert = true
        }
        local ents = s.find_entities_filtered(force_search_info)
        if not ents or #ents == 0 then
            break
        end

        local char_search_info =
        {
            position = chunk,
            radius = radius,
            name = { 'character' },
        }

        local chars = s.find_entities_filtered(char_search_info)
        if not chars or #chars == 0 then
            break
        end

        ::continue::
    end

    return chunk
end

local function draw_normal_gui(player)
    local button
    local merchant = this.events.merchant
    if merchant.alive then
        button =
        {
            type = 'button',
            name = 'merchant_find',
            caption = 'Merchant'
        }
        player.gui.left.add(button)
    end

    button =
    {
        type = 'button',
        name = 'flashlight_toggle',
        caption = 'Toggle flashlight'
    }
    player.gui.left.add(button)
end

local function draw_common_gui(player)
    local perks = this.perks[player.name]
    if not perks then
        perks = assign_perks(player)
    end
    local chat_type = 'Global chat'
    if not perks.chat_global then
        chat_type = 'NAP chat'
    end

    local button =
    {
        type = 'button',
        name = 'manual_toggle',
        caption = 'Manual'
    }
    player.gui.left.add(button)

    button =
    {
        type = 'button',
        name = 'chat_toggle',
        caption = chat_type
    }
    player.gui.left.add(button)
end

local function draw_orbit_gui(player)
    local button =
    {
        type = 'button',
        name = 'annihilate',
        caption = 'Annihilate'
    }
    if not this.annihilate_gui_button then
        this.annihilate_gui_button = true
        for _ = 1, 5 do
            player.print('>> You are in orbit. Use the button to annihilate the planet.', { color = Color.warning })
        end
    end
    player.gui.left.add(button)
end

local function redraw_gui(player)
    player.gui.left.clear()
    draw_common_gui(player)
    if player.spectator == true then
        draw_orbit_gui(player)
    else
        draw_normal_gui(player)
    end
end

local function print_merchant_position(player)
    local position = this.events.merchant.position
    local perks = this.perks[player.name]
    if not perks then
        perks = assign_perks(player)
    end
    if perks and perks.minimap then
        player.print(string.format('>> You received a broadcast with [gps=%d,%d,%s] coordinates', position.x, position.y, player.surface.name))
    else
        player.print(string.format('>> You were able to spot him %s from your location', CommonFunctions.get_readable_direction(player.position, position)))
    end
end

local function on_tick_reset()
    if this.events.reset_time == nil then
        return
    end

    if this.events.reset_time > game.tick then
        return
    end

    if game.tick < 200 then return end

    if this.hard_restart and not this.announced_message then
        local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
        game.print(message)
        Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
        Server.start_scenario('Planet_Prison')
        this.announced_message = true
        return
    end

    init_game()
    this.events.reset_time = nil
end

local function annihilate(caller)
    this.events.annihilation = true
    for _, player in pairs(game.connected_players) do
        if player.name == caller.name then
            goto continue
        end

        local coeff
        for i = 1, 5 do
            if i % 2 == 0 then
                coeff = -1
            else
                coeff = 1
            end

            local query =
            {
                name = 'atomic-rocket',
                position =
                {
                    player.position.x - 100,
                    player.position.y - 100
                },
                target =
                {
                    player.position.x + (8 * i * coeff),
                    player.position.y + (8 * i * coeff)
                },
                speed = 0.1
            }

            player.surface.create_entity(query)
            player.print('>> Annihilation in progress...')
        end
        ::continue::
    end

    game.print('>> Game will reset shortly.')
    this.events.reset_time = game.tick + (60 * 15)
end

local function on_gui_click(e)
    local elem = e.element
    local p = game.players[e.player_index]
    local perks = this.perks[p.name]
    if not perks then
        perks = assign_perks(p)
    end

    if not elem.valid then
        return
    end

    if elem.name == 'chat_toggle' then
        if perks.chat_global then
            elem.caption = 'NAP chat'
            perks.chat_global = false
            p.print('Global chat is disabled.', { color = Color.success })
        else
            elem.caption = 'Global chat'
            perks.chat_global = true
            p.print('Global chat is enabled.', { color = Color.success })
        end
    elseif elem.name == 'flashlight_toggle' then
        if perks.flashlight_enable then
            perks.flashlight_enable = false
            if p.character and p.character.valid then
                p.character.disable_flashlight()
                p.print('Flashlight is disabled.', { color = Color.success })
            end
        else
            perks.flashlight_enable = true
            if p.character and p.character.valid then
                p.character.enable_flashlight()
                p.print('Flashlight is enabled.', { color = Color.success })
            end
        end
    elseif elem.name == 'merchant_find' then
        print_merchant_position(p)
    elseif elem.name == 'manual_toggle' then
        local children = p.gui.center.children
        if #children >= 1 then
            p.gui.center.clear()
            return
        end

        local text_box =
        {
            type = 'text-box',
            text = MapConfig.manual,
            name = 'manual_toggle_frame'
        }
        text_box = p.gui.center.add(text_box)
        text_box.style.minimal_width = 600
        text_box.read_only = true
        text_box.word_wrap = true
    elseif elem.name == 'manual_toggle_frame' then
        local children = p.gui.center.children
        if #children >= 1 then
            p.gui.center.clear()
            return
        end
    elseif elem.name == 'annihilate' then
        if this.events.annihilation == true then
            return
        end

        elem.destroy()
        annihilate(p)
    end
end

init_player = function (p, non_tp)
    local surface = get_arena_map()

    if #game.forces > 62 then
        p.print('>> Too many players on the server. Please wait for a slot to open up.', { color = Color.fail })
        p.teleport({ 0, 0 }, surface.name)
        local s = p.surface
        local position = get_non_obstructed_position(s, 10)
        p.teleport(position, surface.name)
        if p.character ~= nil then
            p.character.destroy()
        end
        p.set_controller({ type = defines.controllers.spectator })
        return
    end

    if not non_tp then
        p.teleport({ 0, 0 }, surface.name)
        local s = p.surface
        local position = get_non_obstructed_position(s, 15)
        p.teleport(position, surface.name)
    end
    this.perks[p.name] = nil
    local player_force = get_player_force(p)
    local pf = game.forces[player_force]
    if not pf then
        game.create_force(player_force)
    end
    p.force = player_force

    p.force.set_friend('neutral', true)
    p.force.set_friend('player', false)
    p.force.share_chart = false
    this.perks[p.name] =
    {
        flashlight_enable = true,
        minimap = false,
        chat_global = true,
        init = true
    }

    for i = 1, 7 do
        p.force.technologies['inserter-capacity-bonus-' .. i].enabled = false
        p.force.technologies['inserter-capacity-bonus-' .. i].researched = false
    end

    if not p.character or not p.character.valid then
        p.set_controller({ type = defines.controllers.god })
        p.create_character()
    end

    local merch = find_force('merchant')
    if merch then
        p.force.set_friend(merch, true)
        merch.set_friend(p.force, true)
    end

    for _, tech in pairs(p.force.technologies) do
        for name, status in pairs(MapConfig.technologies) do
            if tech.name == name then
                tech.researched = status
                tech.enabled = status
            end
        end
    end

    p.minimap_enabled = false
    p.force.set_surface_hidden(surface, true)
    p.force.set_surface_hidden('Gulag', true)
    p.force.set_surface_hidden('nauvis', true)
    local default_group = game.permissions.get_group('Default')
    default_group.add_player(p)
    p.character.active = true
    redraw_gui(p)
    if not non_tp then
        do_spawn_point(p)
    end
end

local function player_reconnected(connected)
    local offline_players = this.remove_offline_players
    if not offline_players then
        return
    end
    if not offline_players.enabled then
        return
    end
    if not next(offline_players.players) then
        return
    end

    for index, saved_player in pairs(offline_players.players) do
        if saved_player and saved_player.index then
            local player = game.get_player(saved_player.index)
            if player and player.valid and player.index == connected.index then
                table.remove(offline_players.players, index)
                break
            end
        end
    end
end

local function on_player_joined_game(e)
    local p = game.players[e.player_index]
    player_reconnected(p)
    redraw_gui(p)

    if this.perks and this.perks[p.name] and this.perks[p.name].init and not this.perks[p.name].merged then
        return
    end

    init_player(p)
end

local function _build_merchant_bp(surf, position)
    local instance = Blueprints.build(surf, 'merchant', position, nil)
    LayersFunctions.push_excluding_bounding_box(instance.bb)
end

local function _remove_merchant_bp(surf)
    local refs = Blueprints.get_references('merchant')
    local bb = Blueprints.reference_get_bounding_box(refs[1])
    LayersFunctions.remove_excluding_bounding_box(bb)
    Blueprints.destroy_references(surf, 'merchant')
    this.events.merchant.position =
    {
        x = 0,
        y = 0
    }
end

local function spawn_merchant(s)
    local merchant = this.events.merchant
    local position = get_non_obstructed_position(s, 10)
    local merch
    if not merchant.moving then
        merch = game.create_force('merchant')
    else
        merch = find_force('merchant')
    end

    merchant.position = position
    merchant.alive = true
    merchant.moving = false
    merchant.embark_tick = game.tick + 90000
    _build_merchant_bp(s, position)

    s.print('>> Merchant appeared in the area')
    for _, p in pairs(game.players) do
        p.force.set_friend(merch, true)
        merch.set_friend(p.force, true)
        print_merchant_position(p)
        redraw_gui(p)
    end
end

local function embark_merchant(s)
    this.events.merchant.alive = false
    this.events.merchant.moving = true
    this.events.merchant.spawn_tick = game.tick + 10000

    s.print('>> Merchant is moving to new location')
    _remove_merchant_bp(s)
    for _, player in pairs(game.players) do
        redraw_gui(player)
    end
end

local function redraw_gui_connected()
    for _, player in pairs(game.players) do
        redraw_gui(player)
    end
end

local function merchant_event(s)
    local e = this.events
    local m = e.merchant
    if not m.alive and m.spawn_tick <= game.tick then
        spawn_merchant(s)
    end

    if m.alive and not m.moving and m.embark_tick <= game.tick then
        embark_merchant(s)
    end
end

local function _get_outer_points(surf, x, y, deps)
    local inner = deps.inner
    local points = deps.points

    local point =
    {
        x = x,
        y = y
    }

    if CommonFunctions.point_in_bounding_box(point, inner) then
        return
    end

    local tile = surf.get_tile(point)
    if string.find(tile.name, 'water') ~= nil or string.find(tile.name, 'out') ~= nil then
        return
    end

    insert(points, point)
end

local function _calculate_attack_costs(surf, bb)
    local query =
    {
        area = bb,
        force =
        {
            'enemy',
            'neutral',
            'player'
        },
        invert = true
    }
    local objects = surf.find_entities_filtered(query)
    if next(objects) == nil then
        return 0
    end

    local cost = 0
    local costs = MapConfig.base_costs
    for _, obj in pairs(objects) do
        for name, coeff in pairs(costs) do
            if obj.name == name then
                cost = cost + coeff
            end
        end
    end

    return cost
end

local function _get_raid_info(surf, bb)
    local pick = nil
    local cost = _calculate_attack_costs(surf, bb)
    for _, entry in pairs(MapConfig.raid_costs) do
        if entry.cost <= cost then
            pick = entry
        else
            break
        end
    end

    return pick
end

local function _create_npc_group(claim, surf)
    local inner = CommonFunctions.create_bounding_box_by_points(claim)
    local info = _get_raid_info(surf, inner)
    if info == nil then
        return {}
    end

    local outer = CommonFunctions.deepcopy(inner)
    CommonFunctions.enlarge_bounding_box(outer, 10)

    local points = {}
    local deps =
    {
        points = points,
        inner = inner
    }
    CommonFunctions.for_bounding_box_extra(surf, outer, _get_outer_points, deps)

    local agents = {}
    for i, point in ipairs(points) do
        if CommonFunctions.rand_range(1, info.chance) ~= 1 then
            goto continue
        end

        local query =
        {
            name = 'character',
            position = point
        }

        local agent = surf.create_entity(query)
        local stash = {}
        for attr, value in pairs(info.gear[(i % #info.gear) + 1]) do
            local prop =
            {
                name = value
            }

            if attr == 'ammo' then
                prop.count = 20
            elseif attr == 'weap' then
                prop.count = 1
            elseif attr == 'armor' then
                prop.count = 1
            end

            insert(stash, prop)
        end

        for _, stack in pairs(stash) do
            agent.insert(stack)
        end

        assign_camouflage(agent, CommonFunctions)

        insert(agents, agent)
        ::continue::
    end

    return agents
end

local function populate_raid_event(surf)
    local claims, group
    local status = false
    local groups = this.events.raid_groups

    for _, p in pairs(game.connected_players) do
        groups[p.name] = {}
        claims = ClaimsFunctions.get_claims(p.name)
        for _, claim in pairs(claims) do
            if #claim == 0 then
                goto continue
            end

            status = true
            group =
            {
                agents = _create_npc_group(claim, surf),
                objects = claim
            }
            insert(groups[p.name], group)

            ::continue::
        end
    end

    return status
end

local function on_pre_player_left_game(event)
    local offline_players = this.remove_offline_players
    if not offline_players then
        return
    end
    if not offline_players.enabled then
        return
    end
    local player = game.players[event.player_index]
    local ticker = game.tick

    if player.character then
        local tick_until_removal = this.remove_offline_players.time
        if player.online_time < 216000 then
            tick_until_removal = 54000 -- Clear players after 15 minutes when they have less than 1 hour of playtime
        end

        offline_players.players[#offline_players.players + 1] =
        {
            index = event.player_index,
            name = player.name,
            tick = ticker + tick_until_removal
        }
    end
end

local function remove_offline_players()
    local offline_players = this.remove_offline_players
    if not offline_players then
        return
    end
    if not offline_players.enabled then
        return
    end
    if #offline_players.players > 0 then
        for index, saved_player in pairs(offline_players.players) do
            if saved_player and saved_player.index then
                local player = game.get_player(saved_player.index)
                if player and player.valid then
                    if player.connected then
                        offline_players.players[index] = nil
                    else
                        if game.tick > saved_player.tick then
                            if this.perks and this.perks[player.name] then
                                this.perks[player.name] = nil
                            end

                            if #player.force.players > 1 and #player.force.connected_players > 0 then
                                saved_player.tick = game.tick + offline_players.time
                                break
                            end

                            ClaimsFunctions.on_player_died(player)
                            ClaimsFunctions.clear_player_base(player)

                            local player_force = get_player_force(player)

                            if game.forces[player_force] then
                                game.merge_forces(player_force, 'neutral')
                            end
                            Session.clear_player(player)
                            game.remove_offline_players({ player })
                            table.remove(offline_players.players, index)
                        end
                    end
                end
            end
        end
    end
end

local function raid_event(surf)
    local raid_groups = this.events.raid_groups
    if this.events.raid_init then
        if surf.daytime > 0.01 and surf.daytime <= 0.1 then
            for name, groups in pairs(raid_groups) do
                for i = #groups, 1, -1 do
                    local group = groups[i]
                    local agents = group.agents
                    for j = #agents, 1, -1 do
                        local agent = agents[j]
                        if agent.valid then
                            agent.destroy()
                        end

                        remove(agents, j)
                    end

                    if #agents == 0 then
                        remove(group, i)
                    end
                end

                if #groups == 0 then
                    raid_groups[name] = nil
                end
            end

            this.events.raid_init = false
        end
    else
        if surf.daytime < 0.4 or surf.daytime > 0.6 then
            return
        end

        if populate_raid_event(surf) then
            this.events.raid_init = true
        end
    end

    if game.tick % 4 ~= 0 then
        return
    end

    for name, groups in pairs(raid_groups) do
        local exists = false
        for _, p in pairs(game.connected_players) do
            if p.name == name then
                exists = true
                break
            end
        end

        if not exists then
            raid_groups[name] = nil
            goto continue
        end

        for _, group in pairs(groups) do
            AIFunctions.do_job(surf, AIFunctions.command.attack_objects, group)
        end

        ::continue::
    end
end

local function cause_event(s)
    merchant_event(s)
    raid_event(s)
end

local function on_tick()
    local s = this.active_surface
    if not s then
        log('on_tick: surface empty!')
        return
    end

    local tick = game.tick

    local surf = game.get_surface(this.active_surface)
    if not surf or not surf.valid then
        return
    end

    if tick % 4 == 0 then
        AIFunctions.do_job(surf, AIFunctions.command.seek_and_destroy_player)
    end

    LayersFunctions.do_job(surf)
    cause_event(surf)

    if (tick + 1) % 60 == 0 then
        Timers.do_job()
    end
    if (tick + 1) % 100 == 0 then
        AfkFunctions.on_inactive_players(15)
    end
    if (tick + 1) % 500 == 0 then
        remove_offline_players()
    end
end

local function make_ore_patch(e)
    if CommonFunctions.rand_range(1, 60) ~= 1 then
        return
    end

    local surf = e.surface
    local point = e.area.left_top
    MapFuntions.draw_entity_circle(point, 'stone', surf, 6, true, 1000000)
    MapFuntions.draw_entity_circle(point, 'coal', surf, 12, true, 1000000)
    MapFuntions.draw_entity_circle(point, 'copper-ore', surf, 18, true, 1000000)
    MapFuntions.draw_entity_circle(point, 'iron-ore', surf, 24, true, 1000000)
    MapFuntions.draw_noise_tile_circle(point, 'water', surf, 4)
end

local function on_chunk_generated(e)
    local surface = get_arena_map()
    if e.surface.name ~= surface.name then
        return
    end

    make_ore_patch(e)
    LayersFunctions.push_chunk(e.position)
end

local valid_ents =
{
    ['crash-site-spaceship-wreck-small-1'] = true,
    ['crash-site-spaceship-wreck-small-2'] = true,
    ['crash-site-spaceship-wreck-small-3'] = true,
    ['crash-site-spaceship-wreck-small-4'] = true,
    ['crash-site-spaceship-wreck-small-5'] = true,
    ['crash-site-spaceship-wreck-small-6'] = true,
    ['mineable-wreckage'] = true,
    ['big-sand-rock'] = true,
    ['big-rock'] = true,
    ['huge-rock'] = true
}

local function mined_wreckage(e)
    local ent = e.entity
    if not ent.valid then
        return
    end
    if not valid_ents[ent.name] then
        return
    end

    e.buffer.clear()

    local candidates = {}

    local chance = CommonFunctions.rand_range(0, 1000)
    for name, attrs in pairs(MapConfig.wreck_loot) do
        local prob = attrs.rare * 100
        if prob < chance then
            local cand =
            {
                name = name,
                count = CommonFunctions.rand_range(attrs.count[1], attrs.count[2])
            }
            insert(candidates, cand)
        end
    end

    local count = #candidates
    if count == 0 then
        return
    end

    local cand = candidates[CommonFunctions.rand_range(1, count)]
    if e.buffer and cand then
        e.buffer.insert(cand)
    end
end

local function on_player_mined_entity(e)
    local ent = e.entity
    if not ent.valid then
        return
    end

    mined_wreckage(e)
    -- ClaimsFunctions.on_player_mined_entity(ent)
end

local function on_player_died(e)
    local index = e.player_index
    if not index then
        return -- banned/kicked somewhere else
    end

    local p = game.players[index]
    ClaimsFunctions.on_player_died(p)
    ClaimsFunctions.clear_player_base(p)
    local player_force = get_player_force(p)

    if game.forces[player_force] then
        game.merge_forces(player_force, 'neutral')
    end
    p.force = 'player'
    if p.connected then
        return
    end
    Session.clear_player(p)
    game.remove_offline_players({ p })
end

local function on_player_respawned(e)
    local p = game.players[e.player_index]
    init_player(p)
end

local function on_player_dropped_item(e)
    local p = game.players[e.player_index]
    local player_force = get_player_force(p)

    local ent = e.entity
    if ent.stack.name == 'raw-fish' then
        local ent_list =
            p.surface.find_entities_filtered(
                {
                    name = 'character',
                    position = ent.position,
                    radius = 2
                }
            )
        if not ent_list then
            return
        end

        local peer = nil
        for _, char in pairs(ent_list) do
            if char.player and char.player.name ~= p.name then
                peer = char.player
                break
            end
        end

        if peer == nil then
            return
        end

        local peer_force = get_player_force(peer)


        if game.forces[peer_force] and p.force.get_cease_fire(peer_force) then
            p.print(string.format(">> You're in the NAP with %s already", peer.name), { color = Color.warning })
            return
        end

        if this.last_friend[peer.name] == p.name then
            p.print(string.format('>> The NAP was formed with %s', peer.name), { color = Color.success })
            peer.print(string.format('>> The NAP was formed with %s', p.name), { color = Color.success })

            if this.last_friend_initiated[peer.name] then
                if game.forces[player_force] then
                    game.merge_forces(player_force, peer_force)
                    this.perks[p.name].merged = true
                    p.print(string.format('>> You merged forces with %s', peer.name), { color = Color.success })
                    peer.print(string.format('>> %s merged forces with your force!', p.name), { color = Color.success })
                    this.last_friend_initiated[peer.name] = nil
                end
            end


            this.last_friend[p.name] = ''
            this.last_friend[peer.name] = ''
            return
        end

        this.last_friend[p.name] = peer.name
        this.last_friend_initiated[p.name] = true
        p.print(string.format('>> You want to form the NAP with %s', peer.name), { color = Color.warning })
        peer.print(string.format('>> %s wants to form NAP with you', p.name), { color = Color.warning })
    elseif ent.stack.name == 'coal' then
        local ent_list =
            p.surface.find_entities_filtered(
                {
                    name = 'character',
                    position = ent.position,
                    radius = 2
                }
            )
        if not ent_list then
            return
        end

        local peer = nil
        for _, char in pairs(ent_list) do
            if char.player and char.player.name ~= p.name then
                peer = char.player
                break
            end
        end

        if peer == nil then
            return
        end

        local peer_force = get_player_force(peer)

        if game.forces[peer_force] and p.force.name ~= peer_force and not p.force.get_cease_fire(peer_force) then
            p.print(string.format(">> You don't have the NAP with %s", p.name), { color = Color.warning })
            return
        end

        local clean_force_name = string.gsub(p.force.name, '_custom', '')
        if clean_force_name == peer.name then
            init_player(p, true)
        else
            init_player(peer, true)
        end

        this.last_friend[p.name] = ''
        this.last_friend[peer.name] = ''
        p.print(string.format(">> You're no longer in the NAP with %s", peer.name), { color = Color.warning })
        peer.print(string.format(">> You're no longer in the NAP with %s", p.name), { color = Color.warning })
    end
end

local function on_chunk_charted(e)
    local f_perks = this.perks[e.force.name]
    game.forces.neutral.clear_chart()

    if not f_perks then
        return
    end

    if not f_perks.minimap then
        e.force.clear_chart()
    end
end

local function on_entity_damaged(e)
    local ent = e.entity

    if ent.force.name == 'merchant' then
        if not ent.force.get_friend(e.force) then
            return
        end

        ent.force.set_friend(e.force, false)
        e.force.set_friend(ent.force, false)
    end

    if ent.name == 'character' then
        local hp = 1.0 - ent.get_health_ratio()
        local particles = 45 * hp
        local coeff = CommonFunctions.rand_range(-20, 20) / 100.0
        for _ = 1, particles do
            local blood =
            {
                name = 'blood-particle',
                position =
                {
                    x = ent.position.x,
                    y = ent.position.y
                },
                movement =
                {
                    (CommonFunctions.rand_range(-20, 20) / 100.0) + coeff,
                    (CommonFunctions.rand_range(-20, 20) / 100.0) + coeff
                },
                frame_speed = 0.01,
                vertical_speed = 0.02,
                height = 0.01
            }
            ent.surface.create_particle(blood)
        end
    end
end

local function merchant_death(e)
    local ent = e.entity
    if ent.force.name ~= 'merchant' then
        return false
    end

    if ent.name ~= 'character' and ent.name ~= 'market' then
        return false
    end

    local s = ent.surface
    local explosion =
    {
        name = 'massive-explosion',
        position = ent.position
    }
    s.create_entity(explosion)
    _remove_merchant_bp(s)

    this.events.merchant.alive = false
    this.events.merchant.moving = false
    this.events.merchant.spawn_tick = game.tick + 1000
    game.merge_forces('merchant', 'neutral')

    s.print('>> Merchant died')
    for _, player in pairs(game.players) do
        redraw_gui(player)
    end

    return true
end

local coin_drops =
{
    ['character'] = true,
    ['gun-turret'] = true
}

local function hostile_death(e)
    local ent = e.entity
    local loot = e.loot
    if not coin_drops[ent.name] then
        return false
    end

    loot.insert({ name = 'coin', count = random(10, 30) })

    return true
end

local function character_death(e)
    local ent = e.entity
    if ent.name ~= 'character' then
        return false
    end

    local explosion =
    {
        name = 'blood-explosion-big',
        position = ent.position
    }
    ent.surface.create_entity(explosion)
end

local function on_entity_died(e)
    if not e.entity.valid then
        return
    end

    if merchant_death(e) then
        return
    end

    hostile_death(e)
    character_death(e)
    -- ClaimsFunctions.on_entity_died(e.entity)

    if valid_ents[e.entity.name] then
        e.entity.destroy()
    end
end

local function merchant_exploit_check(ent)
    if ent.type ~= 'electric-pole' then
        return
    end

    local refs = Blueprints.get_references('merchant')
    if not refs or #refs <= 0 then
        return
    end

    local bp_ent = Blueprints.reference_get_entities(refs[1])[1]
    local surf = bp_ent.surface

    local query =
    {
        type = 'electric-pole',
        position = bp_ent.position,
        radius = 18
    }
    local ents = surf.find_entities_filtered(query)
    for _, s_ent in pairs(ents) do
        if s_ent.valid and s_ent.force.name ~= 'merchant' then
            s_ent.die()
        end
    end
end

local function on_built_entity(e)
    local ent = e.entity
    if not ent or not ent.valid then
        return
    end

    -- ClaimsFunctions.on_built_entity(ent)
    merchant_exploit_check(ent)
end

local function on_market_item_purchased(e)
    local p = game.players[e.player_index]
    local m = e.market
    local o = m.get_market_items()[e.offer_index].offer
    local perks = this.perks[p.name]
    if not perks then
        perks = assign_perks(p)
    end

    if o.effect_description == 'Construct a GPS receiver' then
        perks.minimap = true
        p.minimap_enabled = true
        p.print('You bought the GPS receiver!', { color = Color.success })
        p.print('(unlocked minimap)', { color = Color.success })
    end
end

local function stringify_color(color)
    local r, g, b = color.r, color.g, color.b
    if r <= 1 then
        r = floor(r * 255)
    end

    if g <= 1 then
        g = floor(g * 255)
    end

    if b <= 1 then
        b = floor(b * 255)
    end

    return string.format('%d,%d,%d', r, g, b)
end

local function create_console_message(p, message)
    local prefix_fmt = '[color=%s]%s:[/color]'
    local msg_fmt = '[color=%s]%s[/color]'
    local color = stringify_color(p.chat_color)
    local prefix = string.format(prefix_fmt, color, p.name)
    local p_msg = string.format(msg_fmt, color, message)

    if this.perks[p.name].chat_global then
        msg_fmt = '[color=red]global:[/color] %s %s'
    else
        msg_fmt = '[color=green]nap:[/color] %s %s'
    end

    return string.format(msg_fmt, prefix, p_msg)
end

local function filter_out_gps(message)
    local msg = string.gsub(message, '%[gps=%-?%d+%,?%s*%-?%d+%]', '[gps]')
    return msg
end

local function on_console_chat(e)
    local pid = e.player_index

    if not pid then
        return
    end

    local p = game.players[pid]
    local msg = create_console_message(p, e.message)
    if this.perks[p.name].chat_global then
        for _, peer in pairs(game.players) do
            if peer.name ~= p.name then
                local perks = this.perks[peer.name]
                if not perks then
                    perks = assign_perks(peer)
                end
                if perks and perks.minimap then
                    peer.print(msg)
                else
                    peer.print(filter_out_gps(msg))
                end
            end
        end
    else
        for _, f in pairs(game.forces) do
            if p.force.get_cease_fire(f) then
                local peer = f.players[1]
                local player_force = get_player_force(p, true)
                if peer.name ~= player_force then
                    local perks = this.perks[peer.name]
                    if not perks then
                        perks = assign_perks(peer)
                    end
                    if perks and perks.minimap then
                        peer.print(msg)
                    else
                        peer.print(filter_out_gps(msg))
                    end
                end
            end
        end
    end
end

local function on_research_finished(e)
    local r = e.research
    if not r.valid then
        return
    end

    local reward =
    {
        name = 'coin',
        count = ceil(r.research_unit_count * 3)
    }
    local f = r.force
    for _, player in pairs(f.players) do
        if player.can_insert(reward) then
            player.insert(reward)
        end
    end
end

local function move_to_orbit(player)
    local char = player.character
    player.character = nil
    char.destroy()

    game.merge_forces(get_player_force(player), 'neutral')
    player.spectator = true
    redraw_gui(player)

    local orbit_perms = game.permissions.get_group('orbit')
    orbit_perms.add_player(player)
end

local function on_marked_for_deconstruction(event)
    local entity = event.entity
    local player = game.get_player(event.player_index)
    if entity and entity.valid and player and player.valid then
        entity.cancel_deconstruction(player.force.name)
    end
end

local function on_rocket_launch_ordered(e)
    local surf = game.get_surface(this.active_surface)
    if not surf or not surf.valid then
        return
    end

    local entity = e.rocket and e.rocket and e.rocket.valid and e.rocket
    surf.print('>> The rocket was launched', { color = Color.warning })

    local rocket_inventory = e.rocket.cargo_pod.get_inventory(defines.inventory.cargo_unit)
    local slot = rocket_inventory[1]
    if slot and slot.valid and slot.valid_for_read then
        if slot.name == 'satellite' then
            local force = entity.force
            surf.print(string.format('>> %s has won this round!', string.gsub(force.name, '_custom', '')), { color = Color.warning })
            Server.to_discord_embed(string.gsub(force.name, '_custom', '') .. ' has launched the rocket and won the game!')

            for _, player in pairs(force.connected_players) do
                move_to_orbit(player)
            end
        end
    end
end

Public.explode_ship = explode_ship

Event.on_init(init_game)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_built_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_player_kicked, on_player_died)
Event.add(defines.events.on_player_banned, on_player_died)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_chunk_charted, on_chunk_charted)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_tick, on_tick_reset)
Event.on_nth_tick(500, redraw_gui_connected)
Event.add(defines.events.on_rocket_launch_ordered, on_rocket_launch_ordered)

Commands.new('reset_game', 'Usable only for admins - controls the scenario!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            game.print(player.name .. ', has reset the game!',
                { r = 0.98, g = 0.66, b = 0.22 })
            Discord.send_notification_raw('Planet Prison', player.name .. ' has reset the game!')
            init_game()
        end
    )

Commands.new('hard_reset_game', 'Usable only for admins - controls the scenario!')
    :require_admin()
    :require_validation()
    :callback(
        function (player)
            this.hard_restart = true
            Discord.send_notification_raw('Planet Prison', player.name .. ' has hard reset the game!')
            local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
            game.print(message)
            Server.to_discord_bold(table.concat { '*** ', message, ' ***' })
            Server.start_scenario('Planet_Prison')
        end
    )
Server.on_scenario_changed(
    'Planet_Prison',
    function (data)
        local scenario = data.scenario
        if scenario == 'Planet_Prison' then
            this.hard_restart = true
        end
    end
)

return Public
