local Event = require 'utils.event'
--local Power = require 'maps.mountain_fortress_v3.power'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WPT = require 'maps.mountain_fortress_v3.table'
local RPG = require 'maps.mountain_fortress_v3.rpg'
require 'maps.mountain_fortress_v3.locomotive_market'

local Public = {}

local rnd = math.random

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

local function property_boost(data)
    local xp_floating_text_color = {r = 0, g = 127, b = 33}
    local visuals_delay = 1800
    local this = data.this
    local locomotive_surface = data.locomotive_surface
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
        if Public.contains_positions(player.position, area) or player.surface.index == locomotive_surface.index then
            local pos = player.position
            RPG.gain_xp(player, 0.3 * (rpg[player.index].bonus + this.xp_points))

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

local function fish_tag()
    local this = WPT.get()
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
    local this = WPT.get()
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

local function set_locomotive_health()
    local this = WPT.get()
    local locomotive_health = WPT.get('locomotive_health')
    local locomotive_max_health = WPT.get('locomotive_max_health')
    local m = locomotive_health / locomotive_max_health
    this.locomotive.health = 1000 * m
    rendering.set_text(this.health_text, 'HP: ' .. locomotive_health .. ' / ' .. locomotive_max_health)
end

local function tick()
    if game.tick % 120 == 0 then
        Public.boost_players_around_train()
    end

    if game.tick % 30 == 0 then
        if game.tick % 1800 == 0 then
            set_player_spawn_and_refill_fish()
        end
        set_locomotive_health()
        fish_tag()
    end
end

function Public.boost_players_around_train()
    local rpg = RPG.get_table()
    local this = WPT.get()
    if not this.active_surface_index then
        return
    end
    local surface = game.surfaces[this.active_surface_index]
    local icw_table = ICW.get_table()
    local unit_surface = this.locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    if not this.locomotive then
        return
    end
    if not this.locomotive.valid then
        return
    end

    local data = {
        this = this,
        surface = surface,
        locomotive_surface = locomotive_surface,
        rpg = rpg
    }
    property_boost(data)
end

function Public.render_train_hp()
    local this = WPT.get()
    local surface = game.surfaces[this.active_surface_index]

    local names = {
        'Hanakocz',
        'Redlabel',
        'Hanakocz',
        'Gerkiz',
        'Hanakocz',
        'Mewmew',
        'Gerkiz',
        'Hanakocz',
        'Redlabel',
        'Gerkiz',
        'Hanakocz',
        'Redlabel',
        'Gerkiz',
        'Hanakocz'
    }

    local size_of_names = #names

    local n = names[rnd(1, size_of_names)]

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
        text = n .. 's Comfy Train',
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

function Public.locomotive_spawn(surface, position)
    local this = WPT.get()
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

    this.loco_surface = locomotive.surface
    this.locomotive_index = locomotive
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

Event.on_nth_tick(5, tick)

return Public
