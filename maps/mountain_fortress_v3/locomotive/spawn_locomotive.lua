local Public = require 'maps.mountain_fortress_v3.table'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Task = require 'utils.task'
local Token = require 'utils.token'
local MapFunctions = require 'tools.map_functions'

local random = math.random

local function initial_cargo_boxes()
    return {
        {name = 'loader', count = 1},
        {name = 'stone-furnace', count = 2},
        {name = 'coal', count = random(32, 64)},
        {name = 'coal', count = random(32, 64)},
        {name = 'loader', count = 1},
        {name = 'iron-ore', count = random(32, 128)},
        {name = 'copper-ore', count = random(32, 128)},
        {name = 'submachine-gun', count = 1},
        {name = 'loader', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'stone-furnace', count = 2},
        {name = 'submachine-gun', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'loader', count = 1},
        {name = 'submachine-gun', count = 1},
        {name = 'automation-science-pack', count = random(4, 32)},
        {name = 'submachine-gun', count = 1},
        {name = 'stone-wall', count = random(4, 32)},
        {name = 'shotgun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'shotgun', count = 1},
        {name = 'stone-wall', count = random(4, 32)},
        {name = 'gun-turret', count = 1},
        {name = 'gun-turret', count = 1},
        {name = 'gun-turret', count = 1},
        {name = 'gun-turret', count = 1},
        {name = 'stone-wall', count = random(4, 32)},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'shotgun-shell', count = random(4, 5)},
        {name = 'gun-turret', count = 1},
        {name = 'land-mine', count = random(6, 18)},
        {name = 'grenade', count = random(2, 7)},
        {name = 'grenade', count = random(2, 8)},
        {name = 'gun-turret', count = 1},
        {name = 'grenade', count = random(2, 7)},
        {name = 'light-armor', count = random(2, 4)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'gun-turret', count = 1},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-gear-wheel', count = random(7, 15)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'iron-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'copper-plate', count = random(15, 23)},
        {name = 'firearm-magazine', count = random(10, 56)},
        {name = 'firearm-magazine', count = random(10, 56)},
        {name = 'firearm-magazine', count = random(10, 56)},
        {name = 'firearm-magazine', count = random(10, 56)},
        {name = 'rail', count = random(16, 24)},
        {name = 'rail', count = random(16, 24)}
    }
end

local set_loco_tiles =
    Token.register(
    function(data)
        local position = data.position
        local surface = data.surface
        if not surface or not surface.valid then
            return
        end

        local cargo_boxes = initial_cargo_boxes()

        local p = {}

        ---@diagnostic disable-next-line: count-down-loop
        for x = position.x - 5, 1, 3 do
            for y = 1, position.y + 5, 2 do
                if random(1, 3) == 1 then
                    p[#p + 1] = {x = x, y = y}
                end
            end
        end

        if random(1, 6) == 1 then
            MapFunctions.draw_noise_tile_circle(position, 'blue-refined-concrete', surface, 12)
        elseif random(1, 5) == 1 then
            MapFunctions.draw_noise_tile_circle(position, 'black-refined-concrete', surface, 12)
        elseif random(1, 4) == 1 then
            MapFunctions.draw_noise_tile_circle(position, 'cyan-refined-concrete', surface, 12)
        elseif random(1, 3) == 1 then
            MapFunctions.draw_noise_tile_circle(position, 'hazard-concrete-right', surface, 12)
        else
            MapFunctions.draw_noise_tile_circle(position, 'blue-refined-concrete', surface, 12)
        end

        for i = 1, #cargo_boxes, 1 do
            if not p[i] then
                break
            end
            local name = 'crash-site-chest-1'

            if random(1, 3) == 1 then
                name = 'crash-site-chest-2'
            end
            if surface.can_place_entity({name = name, position = p[i]}) then
                local e = surface.create_entity({name = name, position = p[i], force = 'player', create_build_effect_smoke = false})
                e.minable = false
                local inventory = e.get_inventory(defines.inventory.chest)
                inventory.insert(cargo_boxes[i])
            end
        end
    end
)

function Public.locomotive_spawn(surface, position)
    local this = Public.get()
    for y = -6, 6, 2 do
        surface.create_entity({name = 'straight-rail', position = {position.x, position.y + y}, force = 'player', direction = 0})
    end
    this.locomotive = surface.create_entity({name = 'locomotive', position = {position.x, position.y + -3}, force = 'player'})
    this.locomotive.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 100})

    this.locomotive_cargo = surface.create_entity({name = 'cargo-wagon', position = {position.x, position.y + 3}, force = 'player'})
    this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = 8})

    local winter_mode_locomotive = Public.wintery(this.locomotive, 5.5)
    if not winter_mode_locomotive then
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 6.5,
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
    end

    local winter_mode_cargo = Public.wintery(this.locomotive_cargo, 5.5)

    if not winter_mode_cargo then
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = {255, 255, 255},
                target = this.locomotive_cargo,
                surface = surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
    end

    local data = {
        surface = surface,
        position = position
    }

    Task.set_timeout_in_ticks(150, set_loco_tiles, data)

    for y = -1, 0, 0.05 do
        local scale = random(50, 100) * 0.01
        rendering.draw_sprite(
            {
                sprite = 'entity/small-biter',
                orientation = random(0, 100) * 0.01,
                x_scale = scale,
                y_scale = scale,
                tint = {random(60, 255), random(60, 255), random(60, 255)},
                render_layer = 'selection-box',
                target = this.locomotive_cargo,
                target_offset = {-0.7 + random(0, 140) * 0.01, y},
                surface = surface
            }
        )
    end

    this.locomotive.color = {random(2, 255), random(60, 255), random(60, 255)}
    this.locomotive.minable = false
    this.locomotive_cargo.minable = false
    this.locomotive_cargo.operable = true

    local locomotive = ICW.register_wagon(this.locomotive)
    if not locomotive then
        return
    end

    ICW.register_wagon(this.locomotive_cargo)

    this.icw_locomotive = locomotive

    game.forces.player.set_spawn_position({0, 19}, locomotive.surface)
end

return Public
