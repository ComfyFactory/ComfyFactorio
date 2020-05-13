local Event = require 'utils.event'
local Power = require 'maps.lumberjack.power'
local ICW = require 'maps.lumberjack.icw.main'
local WPT = require 'maps.lumberjack.table'
local RPG = require 'maps.lumberjack.rpg'
require 'maps.lumberjack.locomotive_market'

local Public = {}

local energy_upgrade = 50000000

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.index] then
        return false
    end
    return true
end

local function rebuild_energy_overworld(data)
    local this = data.this
    local surface = data.surface
    if this.ow_energy then
        if this.ow_energy.valid then
            local position = this.ow_energy.position
            local area = {
                left_top = {x = position.x - 2, y = position.y - 2},
                right_bottom = {x = position.x + 2, y = position.y + 2}
            }
            if Public.contains_positions(this.locomotive.position, area) then
                return
            end
            this.old_ow_energy = this.ow_energy.energy
            this.ow_energy.destroy()
            this.energy['lumberjack'] = nil
        end
    end
    this.ow_energy =
        surface.create_entity {
        name = 'hidden-electric-energy-interface',
        position = {
            x = this.locomotive.position.x,
            y = this.locomotive.position.y + 2
        },
        create_build_effect_smoke = false,
        force = game.forces.enemy
    }

    this.ow_energy.destructible = false
    this.ow_energy.minable = false
    this.ow_energy.operable = false

    this.ow_energy.power_production = 0
    if this.energy_purchased then
        this.ow_energy.electric_buffer_size = energy_upgrade
    else
        this.ow_energy.electric_buffer_size = 10000000
    end
    if this.old_ow_energy then
        this.ow_energy.energy = this.old_ow_energy
    end
end

local function rebuild_energy_loco(data, rebuild)
    local this = data.this
    local surface = data.surface
    local pos = {x = -19, y = 3}

    if rebuild then
        local radius = 1024
        local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
        for _, entity in pairs(surface.find_entities_filtered {area = area, name = 'electric-energy-interface'}) do
            entity.destroy()
        end
        this.energy.loco = nil
        this.lo_energy = nil
    end

    this.lo_energy =
        surface.create_entity {
        name = 'electric-energy-interface',
        position = pos,
        create_build_effect_smoke = false,
        force = game.forces.enemy
    }

    rendering.draw_text {
        text = 'Power to overworld',
        surface = surface,
        target = this.lo_energy,
        target_offset = {0, -1.5},
        color = {r = 0, g = 1, b = 0},
        alignment = 'center'
    }

    this.lo_energy.minable = false
    this.lo_energy.destructible = false
    this.lo_energy.operable = false
    this.lo_energy.power_production = 0
    if this.energy_purchased then
        this.lo_energy.electric_buffer_size = energy_upgrade
    else
        this.lo_energy.electric_buffer_size = 10000000
    end
end

local function property_boost(data)
    local rng = math.random
    local xp_floating_text_color = {r = rng(0, 250), g = 128, b = 0}
    local visuals_delay = 1800
    local this = data.this
    local aura = this.locomotive_xp_aura
    local rpg = data.rpg
    local loco = this.locomotive.position
    local area = {
        left_top = {x = loco.x - aura, y = loco.y - aura},
        right_bottom = {x = loco.x + aura, y = loco.y + aura}
    }

    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end
        if Public.contains_positions(player.position, area) then
            local pos = player.position
            RPG.gain_xp(player, 0.4 * (rpg[player.index].bonus + this.xp_points))

            player.create_local_flying_text {
                text = '+' .. '',
                position = {x = pos.x, y = pos.y - 2},
                color = xp_floating_text_color,
                time_to_live = 60,
                speed = 3
            }
            rpg[player.index].xp_since_last_floaty_text = 0
            rpg[player.index].last_floaty_text = game.tick + visuals_delay
        end
    end
end

local function train_rainbow()
    local this = WPT.get_table()
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end
    local color = {
        a = math.sin((game.tick + 60) / 784) * 127 + 127,
        r = math.sin((game.tick + 120) / 1700) * 127 + 127,
        b = math.sin((game.tick + 600 + 440) / 1800) * 127 + 127,
        g = math.sin((game.tick + 1200 + 770) / 1900) * 127 + 127
    }
    this.locomotive.color = color
    rendering.set_text(this.health_text, 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health)
    if this.circle then
        rendering.destroy(this.circle)
    end
    this.circle =
        rendering.draw_circle {
        surface = game.surfaces[this.active_surface_index],
        target = this.locomotive,
        color = this.locomotive.color,
        filled = false,
        radius = this.locomotive_xp_aura,
        only_in_alt_mode = true
    }
end

local function fish_tag()
    local this = WPT.get_table()
    if not this.locomotive_cargo then
        return
    end
    if not this.locomotive_cargo.valid then
        return
    end
    if not this.locomotive_cargo.surface then
        return
    end
    if not this.locomotive_cargo.surface.valid then
        return
    end
    if this.locomotive_tag then
        if this.locomotive_tag.valid then
            if
                this.locomotive_tag.position.x == this.locomotive_cargo.position.x and
                    this.locomotive_tag.position.y == this.locomotive_cargo.position.y
             then
                return
            end
            this.locomotive_tag.destroy()
        end
    end
    this.locomotive_tag =
        this.locomotive_cargo.force.add_chart_tag(
        this.locomotive_cargo.surface,
        {
            icon = {type = 'item', name = 'raw-fish'},
            position = this.locomotive_cargo.position,
            text = ' '
        }
    )
end

local function set_player_spawn_and_refill_fish()
    local this = WPT.get_table()
    if not this.locomotive_cargo then
        return
    end
    if not this.locomotive_cargo.valid then
        return
    end
    this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert(
        {name = 'raw-fish', count = math.random(2, 5)}
    )
    local position =
        this.locomotive_cargo.surface.find_non_colliding_position(
        'stone-furnace',
        this.locomotive_cargo.position,
        16,
        2
    )
    if not position then
        return
    end
    game.forces.player.set_spawn_position({x = position.x, y = position.y}, this.locomotive_cargo.surface)
end

local direction_lookup = {
    [-1] = {
        [1] = defines.direction.southwest,
        [0] = defines.direction.west,
        [-1] = defines.direction.northwest
    },
    [0] = {
        [1] = defines.direction.south,
        [-1] = defines.direction.north
    },
    [1] = {
        [1] = defines.direction.southeast,
        [0] = defines.direction.east,
        [-1] = defines.direction.northeast
    }
}

local function rand_range(start, stop)
    local this = WPT.get_table()

    if not this.rng then
        this.rng = game.create_random_generator()
    end

    return this.rng(start, stop)
end

local function get_axis(point, axis)
    local function safe_get(t, k)
        local res, value =
            pcall(
            function()
                return t[k]
            end
        )
        if res then
            return value
        end

        return nil
    end

    if point.position then
        return get_axis(point.position, axis)
    end

    if point[axis] then
        return point[axis]
    end

    if safe_get(point, 'target') then
        return get_axis(point.target, axis)
    end

    if #point ~= 2 then
        log('get_axis: invalid point format')
        return nil
    end

    if axis == 'x' then
        return point[1]
    end

    return point[2]
end

local function get_direction(src, dest)
    local src_x = get_axis(src, 'x')
    local src_y = get_axis(src, 'y')
    local dest_x = get_axis(dest, 'x')
    local dest_y = get_axis(dest, 'y')

    local step = {
        x = nil,
        y = nil
    }

    local precision = rand_range(1, 10)
    if dest_x - precision > src_x then
        step.x = 1
    elseif dest_x < src_x - precision then
        step.x = -1
    else
        step.x = 0
    end

    if dest_y - precision > src_y then
        step.y = 1
    elseif dest_y < src_y - precision then
        step.y = -1
    else
        step.y = 0
    end

    return direction_lookup[step.x][step.y]
end

local function get_distance(a, b)
    local h = (get_axis(a, 'x') - get_axis(b, 'x')) ^ 2
    local v = (get_axis(a, 'y') - get_axis(b, 'y')) ^ 2

    return math.sqrt(h + v)
end

local function move_to(ent, trgt, min_distance)
    local state = {
        walking = false
    }

    local distance = get_distance(trgt.position, ent.position)
    if min_distance < distance then
        local dir = get_direction(ent.position, trgt.position)
        if dir then
            state = {
                walking = true,
                direction = dir
            }
        end
    end

    ent.walking_state = state
    return state.walking
end

local function tick()
    local this = WPT.get_table()
    if this.energy_shared then
        Public.power_source_overworld()
        Public.power_source_locomotive()
    end
    if game.tick % 120 == 0 then
        Public.boost_players_around_train()
    end
    if game.tick % 80 == 0 then
        train_rainbow()
    end

    if game.tick % 30 == 0 then
        if game.tick % 1800 == 0 then
            set_player_spawn_and_refill_fish()
        end
        --Public.spawn_player()

        fish_tag()
    end
end

function Public.boost_players_around_train()
    local rpg = RPG.get_table()
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end

    local data = {
        this = this,
        surface = surface,
        rpg = rpg
    }
    property_boost(data)
end

function Public.render_train_hp()
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]

    this.health_text =
        rendering.draw_text {
        text = 'HP: ' .. this.locomotive_health .. ' / ' .. this.locomotive_max_health,
        surface = surface,
        target = this.locomotive,
        target_offset = {0, -2.5},
        color = this.locomotive.color,
        scale = 1.40,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    this.caption =
        rendering.draw_text {
        text = 'Grandmasters Train',
        surface = surface,
        target = this.locomotive,
        target_offset = {0, -4.25},
        color = this.locomotive.color,
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    this.circle =
        rendering.draw_circle {
        surface = surface,
        target = this.locomotive,
        color = this.locomotive.color,
        filled = false,
        radius = this.locomotive_xp_aura,
        only_in_alt_mode = true
    }
end

function Public.spawn_player()
    local rnd = math.random

    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    local position = this.locomotive.position
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end

    if not this.lumberjack_one or not this.lumberjack_one.valid then
        this.lumberjack_one =
            surface.create_entity(
            {
                name = 'character',
                position = {position.x + 5, position.y},
                force = 'player',
                direction = 0
            }
        )
        this.lumberjack_one_caption =
            rendering.draw_text {
            text = 'Lumberjack',
            surface = surface,
            target = this.lumberjack_one,
            target_offset = {0, -2.25},
            color = {r = 0, g = 110, b = 33},
            scale = 0.75,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
    end
    if not this.lumberjack_two or not this.lumberjack_two.valid then
        this.lumberjack_two =
            surface.create_entity(
            {
                name = 'character',
                position = {position.x + -5, position.y},
                force = 'player',
                direction = 0
            }
        )
        this.lumberjack_two_caption =
            rendering.draw_text {
            text = 'Lumberjack',
            surface = surface,
            target = this.lumberjack_two,
            target_offset = {0, -2.25},
            color = {r = 0, g = 110, b = 33},
            scale = 0.75,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
    end
    for _, p in pairs(game.connected_players) do
        if this.lumberjack_one and this.lumberjack_one.valid then
            if rnd(1, 32) == 1 then
                this.lumberjack_one.destroy()
                return
            end
            move_to(this.lumberjack_one, p, rnd(15, 50))
        end
        if this.lumberjack_two and this.lumberjack_two.valid then
            if rnd(1, 32) == 1 then
                this.lumberjack_two.destroy()
                return
            end
            move_to(this.lumberjack_two, p, rnd(15, 50))
        end
    end
end

function Public.locomotive_spawn(surface, position)
    local this = WPT.get_table()
    for y = -6, 6, 2 do
        surface.create_entity(
            {name = 'straight-rail', position = {position.x, position.y + y}, force = 'player', direction = 0}
        )
    end
    this.locomotive =
        surface.create_entity({name = 'locomotive', position = {position.x, position.y + -3}, force = 'player'})
    this.locomotive.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 100})

    this.locomotive_cargo =
        surface.create_entity({name = 'cargo-wagon', position = {position.x, position.y + 3}, force = 'player'})
    this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = 8})

    rendering.draw_light(
        {
            sprite = 'utility/light_medium',
            scale = 5.5,
            intensity = 1,
            minimum_darkness = 0,
            oriented = true,
            color = {255, 255, 255},
            target = this.locomotive,
            surface = surface,
            visible = true,
            only_in_alt_mode = false
        }
    )

    for y = -1, 0, 0.05 do
        local scale = math.random(50, 100) * 0.01
        rendering.draw_sprite(
            {
                sprite = 'item/raw-fish',
                orientation = math.random(0, 100) * 0.01,
                x_scale = scale,
                y_scale = scale,
                tint = {math.random(60, 255), math.random(60, 255), math.random(60, 255)},
                render_layer = 'selection-box',
                target = this.locomotive_cargo,
                target_offset = {-0.7 + math.random(0, 140) * 0.01, y},
                surface = surface
            }
        )
    end

    this.locomotive.color = {0, 255, 0}
    this.locomotive.minable = false
    this.locomotive_cargo.minable = false
    this.locomotive_cargo.operable = true

    local locomotive = ICW.register_wagon(this.locomotive)
    local wagon = ICW.register_wagon(this.locomotive_cargo)
    locomotive.entity_count = 999
    wagon.entity_count = 999
end

function Public.inside(pos, area)
    local lt = area.left_top
    local rb = area.right_bottom

    return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
end
function Public.contains_positions(pos, area)
    if Public.inside(pos, area) then
        return true
    end
    return false
end

function Public.power_source_overworld()
    local this = WPT.get_table()
    local surface = game.surfaces[this.active_surface_index]
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end

    local data = {
        this = this,
        surface = surface
    }

    rebuild_energy_overworld(data)
end

function Public.power_source_locomotive()
    local this = WPT.get_table()
    local icw_table = ICW.get_table()
    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end
    local unit_surface = this.locomotive.unit_number
    local surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    local data = {
        this = this,
        icw_table = icw_table,
        surface = surface
    }

    if not this.lo_energy then
        rebuild_energy_loco(data)
    elseif not this.lo_energy.valid then
        rebuild_energy_loco(data, true)
    end
end

Event.on_nth_tick(5, tick)

return Public
