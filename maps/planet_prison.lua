-- map by Cogito
-- heavily modified by Gerkiz

local Global = require 'utils.global'
local Session = require 'utils.datastore.session_data'
local Event = require 'utils.event'
local Server = require 'utils.server'
local MapFuntions = require 'tools.map_functions'
local CommonFunctions = require 'utils.common'
local LayersFunctions = require 'maps.planet_prison.mod.layers'
local AIFunctions = require 'utils.ai'
local Blueprints = require 'maps.planet_prison.mod.bp'
local AfkFunctions = require 'maps.planet_prison.mod.afk'
local Timers = require 'utils.timers'
local ClaimsFunctions = require 'maps.planet_prison.mod.claims'
local MapConfig = require 'maps.planet_prison.config'
local Token = require 'utils.token'
local Color = require 'utils.color_presets'
-- require 'modules.thirst'

local this = {
    remove_offline_players = {
        players = {},
        time = 216000, -- 1h
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
    function(tbl)
        this = tbl
    end
)

this.maps = {
    {
        name = 'flooded-metropolia',
        height = 2000,
        width = 2000,
        water = 1,
        terrain_segmentation = 8,
        property_expression_names = {
            moisture = 0,
            temperature = 30.
        },
        cliff_settings = {
            richness = 0
        },
        starting_area = 'none',
        autoplace_controls = {
            ['iron-ore'] = {
                frequency = 0
            },
            ['copper-ore'] = {
                frequency = 0
            },
            ['uranium-ore'] = {
                frequency = 0
            },
            ['stone'] = {
                frequency = 0
            },
            ['coal'] = {
                frequency = 0
            },
            ['crude-oil'] = {
                frequency = 1000,
                size = 1
            },
            ['trees'] = {
                frequency = 4
            },
            ['enemy-base'] = {
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
        property_expression_names = {
            moisture = 0,
            temperature = 25.
        },
        cliff_settings = {
            richness = 0
        },
        starting_area = 'none',
        autoplace_controls = {
            ['iron-ore'] = {
                frequency = 0
            },
            ['copper-ore'] = {
                frequency = 0
            },
            ['uranium-ore'] = {
                frequency = 0
            },
            ['stone'] = {
                frequency = 0
            },
            ['coal'] = {
                frequency = 0
            },
            ['crude-oil'] = {
                frequency = 900,
                size = 1
            },
            ['trees'] = {
                frequency = 4
            },
            ['enemy-base'] = {
                frequency = 0
            }
        }
    }
}

local function assign_perks(player)
    this.perks[player.name] = {
        flashlight_enable = true,
        minimap = false,
        chat_global = true
    }
    return this.perks[player.name]
end

local assign_camouflage = function(ent, common)
    local shade = common.rand_range(20, 200)
    ent.color = {
        r = shade,
        g = shade,
        b = shade
    }
    ent.disable_flashlight()
end

local set_noise_hostile_hook =
    Token.register(
    function(data)
        local ent = data
        if not ent or not ent.valid then
            return
        end
        ent.force = 'enemy'
        if ent.name == 'character' then
            assign_camouflage(ent, CommonFunctions)

            if CommonFunctions.rand_range(1, 5) == 1 then
                ent.insert({name = 'shotgun', count = 1})
                ent.insert({name = 'shotgun-shell', count = 20})
            else
                ent.insert({name = 'pistol', count = 1})
                ent.insert({name = 'firearm-magazine', count = 20})
            end
        else
            ent.insert({name = 'firearm-magazine', count = 200})
        end
    end
)

local set_neutral_to_entity =
    Token.register(
    function(entity)
        entity.force = 'neutral'
    end
)

local fetch_common =
    Token.register(
    function()
        return CommonFunctions
    end
)

local industrial_zone_layers = {
    {
        type = 'LuaTile',
        name = 'concrete',
        objects = {
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
        objects = {
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
        objects = {
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
        objects = {
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
        objects = {
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
        objects = {
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
        objects = {
            'big-electric-pole',
            'medium-electric-pole'
        },
        elevation = 0.9,
        resolution = 0.9,
        hook = set_neutral_to_entity,
        deps = nil
    }
}

local swampy_rivers_layers = {
    {
        type = 'LuaTile',
        name = 'speedy_tiles',
        objects = {
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
        objects = {
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
        objects = {
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
        objects = {
            'sand-rock-big',
            'rock-big',
            'rock-huge'
        },
        elevation = 0.5,
        resolution = 0.1,
        hook = set_neutral_to_entity,
        deps = nil
    },
    {
        type = 'LuaEntity',
        name = 'walls',
        objects = {
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
        objects = {
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
        objects = {
            'big-electric-pole',
            'medium-electric-pole'
        },
        elevation = 0.9,
        resolution = 0.9,
        hook = set_neutral_to_entity,
        deps = nil
    }
}

this.presets = {
    ['flooded-metropolia'] = industrial_zone_layers,
    ['swampy-rivers'] = swampy_rivers_layers
}

this.entities_cache = nil
this.surface = nil
this.last_friend = nil
local function pick_map()
    return this.maps[CommonFunctions.rand_range(1, #this.maps)]
end

local function find_force(name)
    for _, f in pairs(game.forces) do
        if f.name == name then
            return f
        end
    end

    return nil
end

local init_player_ship_bp =
    Token.register(
    function(data)
        local player = data.player
        local entity = data.entity
        entity.force = player.force
        if entity.name == 'crash-site-chest-1' then
            for _, stack in pairs(MapConfig.player_ship_loot) do
                entity.insert(stack)
            end
        end
    end
)

this.events = {
    merchant = {
        alive = false,
        moving = false,
        spawn_tick = 0,
        embark_tick = 0,
        position = {x = 0, y = 0},
        offer = MapConfig.merchant_offer
    }
}

local init_merchant_bp =
    Token.register(
    function(data)
        local entity = data.entity
        entity.force = 'merchant'
        entity.rotatable = false
        entity.minable = false
        if entity.name ~= 'market' then
            entity.operable = false
        else
            for _, entry in pairs(this.events.merchant.offer) do
                entity.add_market_item(entry)
            end
        end
    end
)

local function create_orbit_group()
    local orbit = game.permissions.create_group('orbit')
    for _, perm in pairs(MapConfig.permission_orbit) do
        orbit.set_allows_action(perm, false)
    end
end

this.bp = {
    player_ship = require('planet_prison.bp.player_ship'),
    merchant = require('planet_prison.bp.merchant')
}
local function init_game()
    LayersFunctions.init()
    ClaimsFunctions.init(MapConfig.claim_markers, MapConfig.claim_max_distance)

    local map = pick_map()
    local preset = this.presets[map.name]
    this.surface = game.create_surface('arena', map)
    this.surface.brightness_visual_weights = {
        1 / 0.85,
        1 / 0.85,
        1 / 0.85
    }
    this.surface.ticks_per_day = 25000 * 4
    this.perks = {}
    this.events.merchant.spawn_tick = game.tick + 5000
    this.events.raid_groups = {}
    this.events.raid_init = false
    this.events.annihilation = false
    this.events.reset_time = nil

    create_orbit_group()
    game.map_settings.pollution.enabled = false
    game.map_settings.enemy_evolution.enabled = false
    game.difficulty_settings.technology_price_multiplier = 0.3
    game.difficulty_settings.research_queue_setting = 'always'

    LayersFunctions.set_collision_mask({'water-tile'})

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

    Blueprints.push_blueprint('player_ship', this.bp.player_ship)
    Blueprints.set_blueprint_hook('player_ship', init_player_ship_bp)
    Blueprints.push_blueprint('merchant', this.bp.merchant)
    Blueprints.set_blueprint_hook('merchant', init_merchant_bp)
end

local explode_ship_update =
    Token.register(
    function(data)
        local id = data.id
        local time_left = data.time_left
        local ship = data.ship
        local time = CommonFunctions.get_time(time_left)
        for _, ent in pairs(ship.entities) do
            if not ent.valid then
                return false
            end
        end

        rendering.set_text(id, time)
        return true
    end
)

local explode_ship =
    Token.register(
    function(data)
        local ship = data.ship
        local id = data.id
        local surface = data.surface
        for _, ent in pairs(Blueprints.reference_get_entities(ship)) do
            if not ent.valid then
                goto continue
            end

            local explosion = {
                name = 'massive-explosion',
                position = ent.position
            }
            surface.create_entity(explosion)

            ::continue::
        end

        local bb = Blueprints.reference_get_bounding_box(ship)
        LayersFunctions.remove_excluding_bounding_box(bb)
        Blueprints.destroy_reference(surface, ship)
        rendering.destroy(id)
    end
)

local function do_spawn_point(player)
    local point = {
        x = CommonFunctions.get_axis(player.position, 'x'),
        y = CommonFunctions.get_axis(player.position, 'y') - 2
    }
    local instance = Blueprints.build(player.surface, 'player_ship', point, player)
    LayersFunctions.push_excluding_bounding_box(instance.bb)
    local time_left = MapConfig.self_explode

    local object = {
        text = CommonFunctions.get_time(time_left),
        surface = player.surface,
        color = {
            r = 255,
            g = 20,
            b = 20
        },
        target = {
            x = point.x - 2,
            y = point.y - 3
        },
        scale = 2.0
    }

    local id = rendering.draw_text(object)
    local data = {id = id, time_left = time_left, ship = instance, surface = player.surface}

    local timer = Timers.set_timer(time_left, explode_ship)
    Timers.set_timer_on_update(timer, explode_ship_update)
    Timers.set_timer_dependency(timer, data)
    Timers.set_timer_start(timer)
end

local function get_non_obstructed_position(s, radius)
    local chunk

    for i = 1, 32 do
        chunk = s.get_random_chunk()
        chunk.x = chunk.x * 32
        chunk.y = chunk.y * 32

        local search_info = {
            position = chunk,
            radius = radius
        }

        local tiles = s.find_tiles_filtered(search_info)
        for _, tile in pairs(tiles) do
            if string.find(tile.name, 'water') ~= nil or string.find(tile.name, 'out') ~= nil then
                goto continue
            end
        end

        search_info = {
            position = chunk,
            radius = radius,
            force = {'neutral', 'enemy'},
            invert = true
        }
        local ents = s.find_entities_filtered(search_info)
        if not ents or #ents == 0 then
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
        button = {
            type = 'button',
            name = 'merchant_find',
            caption = 'Merchant'
        }
        player.gui.left.add(button)
    end

    button = {
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

    local button = {
        type = 'button',
        name = 'manual_toggle',
        caption = 'Manual'
    }
    player.gui.left.add(button)

    button = {
        type = 'button',
        name = 'chat_toggle',
        caption = chat_type
    }
    player.gui.left.add(button)
end

local function draw_orbit_gui(player)
    local button = {
        type = 'button',
        name = 'annihilate',
        caption = 'Annihilate'
    }
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

    Server.start_scenario('planet_prison')
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

            local query = {
                name = 'atomic-rocket',
                position = {
                    player.position.x - 100,
                    player.position.y - 100
                },
                target = {
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

    if elem.name == 'comfy_panel_top_button' then
        if not p.admin then
            if p.gui.left['comfy_panel'] and p.gui.left['comfy_panel'].valid then
                p.gui.left['comfy_panel'].destroy()
            end
            redraw_gui(p)
            return p.print('Comfy panel is disabled in this scenario.', Color.fail)
        end
    elseif elem.name == 'chat_toggle' then
        if perks.chat_global then
            elem.caption = 'NAP chat'
            perks.chat_global = false
            p.print('Global chat is disabled.', Color.success)
        else
            elem.caption = 'Global chat'
            perks.chat_global = true
            p.print('Global chat is enabled.', Color.success)
        end
    elseif elem.name == 'flashlight_toggle' then
        if perks.flashlight_enable then
            perks.flashlight_enable = false
            if p.character and p.character.valid then
                p.character.disable_flashlight()
                p.print('Flashlight is disabled.', Color.success)
            end
        else
            perks.flashlight_enable = true
            if p.character and p.character.valid then
                p.character.enable_flashlight()
                p.print('Flashlight is enabled.', Color.success)
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

        local text_box = {
            type = 'text-box',
            text = MapConfig.manual,
            name = 'manual_toggle_frame'
        }
        text_box = p.gui.center.add(text_box)
        text_box.style.minimal_width = 512
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

local function init_player(p)
    p.teleport({0, 0}, 'arena')
    local s = p.surface
    local position = get_non_obstructed_position(s, 10)

    this.perks[p.name] = nil
    p.teleport(position, 'arena')
    --p.name = get_random_name() --player name is read only
    local pf = game.forces[p.name]
    if not pf then
        p.force = game.create_force(p.name)
    else
        p.force = pf
    end
    p.force.set_friend('neutral', true)
    p.force.set_friend('player', false)
    p.force.share_chart = false
    this.perks[p.name] = {
        flashlight_enable = true,
        minimap = false,
        chat_global = true
    }

    for i = 1, 7 do
        p.force.technologies['inserter-capacity-bonus-' .. i].enabled = false
        p.force.technologies['inserter-capacity-bonus-' .. i].researched = false
    end

    if not p.character or not p.character.valid then
        p.set_controller({type = defines.controllers.god})
        p.create_character()
    end

    local merch = find_force('merchant')
    if merch then
        p.force.set_friend(merch, true)
        merch.set_friend(p.force, true)
    end

    p.force.research_queue_enabled = true
    for _, tech in pairs(p.force.technologies) do
        for name, status in pairs(MapConfig.technologies) do
            if tech.name == name then
                tech.researched = status
                tech.enabled = status
            end
        end
    end

    p.minimap_enabled = false
    redraw_gui(p)
    do_spawn_point(p)
end

local function player_reconnected(connected)
    local offline_players = this.remove_offline_players
    if not offline_players then
        return
    end
    if not offline_players.enabled then
        return
    end
    if #offline_players.players > 0 then
        for i = 1, #offline_players.players do
            if offline_players.players[i] then
                local player = game.get_player(offline_players.players[i].index)
                if player and player.valid and player.index == connected.index then
                    offline_players.players[i] = nil
                end
            end
        end
    end
end

local function on_player_joined_game(e)
    local p = game.players[e.player_index]
    player_reconnected(p)

    if this.perks and this.perks[p.name] then
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
    this.events.merchant.position = {
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

    local point = {
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
    local query = {
        area = bb,
        force = {
            'enemy',
            'neutral',
            'player'
        },
        invert = true
    }
    local objects = surf.find_entities_filtered(query)
    if next(objects) == nil then
        log('B')
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
    local deps = {
        points = points,
        inner = inner
    }
    CommonFunctions.for_bounding_box_extra(surf, outer, _get_outer_points, deps)

    local agents = {}
    for i, point in ipairs(points) do
        if CommonFunctions.rand_range(1, info.chance) ~= 1 then
            goto continue
        end

        local query = {
            name = 'character',
            position = point
        }

        local agent = surf.create_entity(query)
        local stash = {}
        for attr, value in pairs(info.gear[(i % #info.gear) + 1]) do
            local prop = {
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
            group = {
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
        offline_players.players[#offline_players.players + 1] = {
            index = event.player_index,
            name = player.name,
            tick = ticker
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
        for i = 1, #offline_players.players, 1 do
            if offline_players.players[i] then
                local player = game.get_player(offline_players.players[i].index)
                if player and player.valid then
                    if player.connected then
                        offline_players.players[i] = nil
                    else
                        if offline_players.players[i].tick < game.tick - offline_players.time then
                            if this.perks and this.perks[player.name] then
                                this.perks[player.name] = nil
                            end
                            ClaimsFunctions.on_player_died(player)
                            ClaimsFunctions.clear_player_base(player)

                            if game.forces[player.name] then
                                game.merge_forces(player.name, 'neutral')
                            end
                            Session.clear_player(player)
                            game.remove_offline_players({player})
                            offline_players.players[i] = nil
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
    local s = this.surface
    if not s then
        log('on_tick: surface empty!')
        return
    end

    local tick = game.tick

    local surf = this.surface
    if not surf or not surf.valid then
        return
    end

    if tick % 4 == 0 then
        AIFunctions.do_job(surf, AIFunctions.command.seek_and_destroy_player)
    end

    LayersFunctions.do_job(surf)
    cause_event(s)

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
    if CommonFunctions.rand_range(1, 30) ~= 1 then
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
    if e.surface.name ~= 'arena' then
        return
    end

    make_ore_patch(e)
    LayersFunctions.push_chunk(e.position)
end

local valid_ents = {
    ['crash-site-spaceship-wreck-small-1'] = true,
    ['crash-site-spaceship-wreck-small-2'] = true,
    ['crash-site-spaceship-wreck-small-3'] = true,
    ['crash-site-spaceship-wreck-small-4'] = true,
    ['crash-site-spaceship-wreck-small-5'] = true,
    ['crash-site-spaceship-wreck-small-6'] = true,
    ['sand-rock-big'] = true,
    ['rock-big'] = true,
    ['rock-huge'] = true
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
            local cand = {
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

    if game.forces[p.name] then
        game.merge_forces(p.name, 'neutral')
    end
    p.force = 'player'
    if p.connected then
        return
    end
    Session.clear_player(p)
    game.remove_offline_players({p})
end

local function on_player_respawned(e)
    local p = game.players[e.player_index]
    init_player(p)
end

local function on_player_dropped_item(e)
    if not this.last_friend then
        this.last_friend = {}
    end

    local p = game.players[e.player_index]
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

        if p.force.get_cease_fire(peer.name) then
            p.print(string.format("You're in the NAP with %s already", peer.name))
            return
        end

        if this.last_friend[peer.name] == p.name then
            p.force.set_cease_fire(peer.name, true)
            p.force.set_friend(peer.name, true)
            peer.force.set_cease_fire(p.name, true)
            peer.force.set_friend(p.name, true)
            p.print(string.format('The NAP was formed with %s', peer.name))
            peer.print(string.format('The NAP was formed with %s', p.name))
            this.last_friend[p.name] = ''
            this.last_friend[peer.name] = ''
            return
        end

        this.last_friend[p.name] = peer.name
        p.print(string.format('You want to form the NAP with %s', peer.name))
        peer.print(string.format('The %s wants to form NAP with you', p.name))
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

        if not p.force.get_cease_fire(peer.name) then
            p.print(string.format("You don't have the NAP with %s", p.name))
            return
        end

        p.force.set_cease_fire(peer.name, false)
        p.force.set_friend(peer.name, false)
        peer.force.set_cease_fire(p.name, false)
        peer.force.set_friend(p.name, false)

        this.last_friend[p.name] = ''
        this.last_friend[peer.name] = ''
        p.print(string.format("You're no longer in the NAP with %s", peer.name))
        peer.print(string.format("You're no longer in the NAP with %s", p.name))
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
        for i = 1, particles do
            local blood = {
                name = 'blood-particle',
                position = {
                    x = ent.position.x,
                    y = ent.position.y
                },
                movement = {
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
    local explosion = {
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

local coin_drops = {
    ['character'] = true,
    ['gun-turret'] = true
}

local function hostile_death(e)
    local ent = e.entity
    local loot = e.loot
    if not coin_drops[ent.name] then
        return false
    end

    loot.insert({name = 'coin', count = random(30, 70)})

    return true
end

local function character_death(e)
    local ent = e.entity
    if ent.name ~= 'character' then
        return false
    end

    local explosion = {
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

    local query = {
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
    local ent = e.created_entity
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
        end
    end
end

local function on_research_finished(e)
    local r = e.research
    if not r.valid then
        return
    end

    local reward = {
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

    game.merge_forces(player.name, 'neutral')
    player.spectator = true
    redraw_gui(player)

    local orbit_perms = game.permissions.get_group('orbit')
    orbit_perms.add_player(player)
end

local function on_rocket_launched(e)
    local surf = this.surface
    local pid = e.player_index
    surf.print('>> The rocket was launched')
    if pid == nil then
        surf.print('>> Nobody escaped by it')
    else
        local player = game.players[pid]
        surf.print(string.format('>> The %s was able to escape', player.name))
        move_to_orbit(player)
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
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_chunk_charted, on_chunk_charted)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_tick, on_tick_reset)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)

return Public
