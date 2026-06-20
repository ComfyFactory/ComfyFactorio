local Public = {}
local SA = script.active_mods['space-age']
local Raffle = require 'utils.math.raffle'
local MissionData = require 'maps.expanse.mission_data'
local Server = require 'utils.server'

function Public.init_space(expanse)

    local space_force = game.forces.space_force or game.create_force('space_force')
    local platform = space_force.create_space_platform({name = 'Orbit', planet = 'nauvis', starter_pack = 'space-platform-starter-pack'})
    if not platform then return end
    platform.apply_starter_pack()

    expanse.space_platform = platform
    local surface = platform.surface
    local bp = '0eNql3Otu2zgUBOB30W+noEhKsvMqiyJQUjkrwJfUl2KDwO++suNNF00LSP5+NU18RpHImWGo4XkrHlfH7mXXbw7F/VvRP203++L+r7di3z9v2tX5e5t23RX3xVO7e97ePbavxaz4fmxX/eF1+O6qe+4239rda3GaFf3mW/dPcV+evs6KbnPoD333Dnb5z+vD5rh+7HbDB2a/A33Z7oeK7eZ8zQHlrp4Vr+d/Tn+63ifcOAo3TsZNY3Cnw+YxsNOfQvUBu9+u2t3dS7vpVr95DmX1pXoHT1+q8fD1WPh4E3wzDv5G9PlI9NsezWLKvI7jccswYaZMwf1JxP1L+9Tdvazaw3K7W9/9fXz8fIFwuUAY8Hfd92O3Pzws+9Wh2+3PP993T+ePvvP9QwhmH18P9GiHT/wYLrZsV/vurBEfMLvt+uHxuFxesA67Y/e/a6z7/b7fPD+clWn40eUqD+t2uG4/4Pz38c/3FqfSYNJQl2kqDabB5wlTacqIV+Nn0hTYeiJrpz2MZiJrp6HPJzzqCTJcLia40RSTC+PdaApsOX5m/BF24PShX11N/9c7nb/r0/z0J9FZbo8DzqXk/Av+Wt9gfY31FdZnrE9YH7G+tPpg5Xh1vHl89jj0OPNw4ivvrrxvkPcN8r5B3jfI+wZ53yDvG+R9Y7xvjPeN8b4x3jfG+8Z43xjvG+N9g7yvkfc18r5G3tfI+xp5XyPva+R9bbyvjfe18b423tfG+9p4Xxvva+P97fPmClDdDFArQKUAWQGSAkQEmGO9DqKOoQ6hjqAOoI5fafXByvHqePP47HHocebhxEfelThyqjsqfKq8Kv3uPdcBzOp+Wd0vq/tldb+s7pfR/TK6X0b3y+h+Gd0vo/tldL+M7pfN/bK5Xzb3y+Z+2dwvm/tlc79s7pfR/TK6X0b3y+h+Gd0vo/tldb+k7pfU/ZK6X1L3S+p+Cd0vofsldL+E7pfQ/RK6X0L3S+h+ydwvmfslc79k7pfM/ZK5XzL3S+Z+Cd0vofsldL+E7pfQ/RK6Hwt3ROGOKNwRhTuicEcU7ojCHVG4Iwp3NOGOJtzRhDuacEcT7mjCHU24owl3ROG+fd5dAcqbAQICLLB+jvUN1tdYX2F9xvqE9VEnkNXj9MOr483js8ehx5mHEx95h7RH1WHVu+puQNkNprrBRDeY5gaT3GCKG0xwg+ltMLkNpraBxDaQ1gaS2kBKG0hoA+lsIJkNpLKBRDaQxgaT2IB/UuO6EpeVuKrERSWuKXFJiStKXFDaetKWk7aatMWkrSVtKWkrSVtIlvYXdInvrSK+tor41iriS6uI76wiyjRufOK+J2574q4nbnrinidueeKOp2142n6nbXfabqdtdtpep2112k4nbnRGe0EV7f1UtNdT0d5ORXs5FdHhNJihuQyNZWgqQ9/tYSYDIxmYyMBABuYxMI6BaQwMY1gWw6IYlsSwIIblMCyGYSkMC2FgBgMjGJjAwAAG5i8wfpHQ4TR4r7l7jd1r6l5D95i5x8g9Ju4xcI95e4zbY9oew/aWtbeovSXtLWhvOXuL2VvK3kL2mLHHiD0m7DFgj/l6jNejwuKRXjzRiwd68TwvHufF07x4mNfO8tpRXjvJawd57RyvHeO1U7x2iBfP7mPjFOybgm1TsGsKNk3BninYMsU6pljDFOuXYu1SrFuKNUuxXinWKqU2nmNjNOyLhm3RsCsaNkXDnmjYEs06ollDNOuHZu3QrBuaNUOzXmjWCm1c9ddZ0R+69fChn53VZ8WPbre/4FV1XOTFoqqrUFYhn07/Aueyh3s='
    local inv = game.create_inventory(1)
    inv.insert({name = 'blueprint'})
    local item = inv[1]
    item.import_stack(bp)
    item.build_blueprint({surface = surface, position = {0,0}, force = space_force})
    inv.destroy()
    local items = {
        {name = 'space-platform-foundation', count = 234},
        {name = 'cargo-bay', quality = 'legendary', count = 12},
        {name = 'solar-panel', quality = 'legendary', count = 8},
        --{name = 'radar', count = 4}
    }
    for _, stack in pairs(items) do
        platform.hub.insert(stack)
    end

end

function Public.init_nonspace(expanse)
    local map_gen_settings = {
        width = 40,
        height = 40,
        starting_area = 'none',
        seed = math.random(1, 1000000),
        water = 'none',
        autoplace_controls = {},
        autoplace_settings = {
            entity = { treat_missing_as_default = false, settings = {} },
            tile   = { treat_missing_as_default = false, settings = {} },
            decorative = { treat_missing_as_default = false, settings = {} },
        },
        default_enable_all_autoplace_controls = false
    }
    local surface = game.surfaces['NonOrbit'] or game.create_surface('NonOrbit',map_gen_settings)
    game.forces.player.set_surface_hidden(surface, true)
    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()
    local position = surface.find_non_colliding_position('cargo-landing-pad', {0, 0}, 30, 1)
    local pad = surface.create_entity({name = 'cargo-landing-pad', position = position or {3, 3}, force = game.forces.player})
    pad.destructible = false
    pad.minable_flag = false
    expanse.nonspace_pad = pad
    local position2 = surface.find_non_colliding_position('rocket-silo', {0, 0}, 30, 1)
    local silo = surface.create_entity({name = 'rocket-silo', position = position2 or {-3, -3}, force = game.forces.player})
    silo.destructible = false
    silo.minable_flag = false
    expanse.nonspace_silo = silo
end

function Public.launch_rockets(expanse)
    local silos = expanse.rocket_silos or {}
    if expanse.missions[4].level == 0 then return end --we expect rocket silo research done first, at all cases
    for unit_number, data in pairs(silos) do
        local silo = data.entity
        if not silo or not silo.valid then
            table.remove(expanse.rocket_silos, unit_number)
            break
        end
        local inventory = silo.get_inventory(defines.inventory.rocket_silo_rocket)
        local weight = 0
        for i = 1, #inventory, 1 do
            local slot = inventory[i]
            if slot and slot.valid_for_read then
                local itemweight = prototypes.item[slot.name].weight
                weight = weight + itemweight * slot.count
            end
        end
        if silo.rocket_silo_status == defines.rocket_silo_status.rocket_ready and weight >= 999500 then
            local station = SA and expanse.space_platform.hub or expanse.nonspace_pad
            silo.launch_rocket({type = defines.cargo_destination.station, station = station})
        end
    --/cc local station = storage.tokens.maps_expanse_main.space_platform.hub   local silo = storage.tokens.maps_expanse_main.rocket_silos[442260].entity    silo.launch_rocket({type = defines.cargo_destination.station, station = station})
    end
end

local function silo_renders(silo, tier)
    local id = rendering.draw_sprite {
        sprite = 'virtual-signal/signal-grey',
        surface = silo.surface,
        target = {
            entity = silo,
            offset = { 0, -1.5 }
        },
        x_scale = 1.1,
        y_scale = 1.1,
        render_layer = '190',
        only_in_alt_mode = true
    }
    local id2 = rendering.draw_sprite {
        sprite = 'virtual-signal/signal-' .. tier,
        surface = silo.surface,
        target = {
            entity = silo,
            offset = { 0, -1.5 }
        },
        x_scale = 0.75,
        y_scale = 0.75,
        render_layer = '191',
        only_in_alt_mode = true
    }
    return { id, id2}
end

local function tier3_object(_expanse, surface, left_top, repeats)
    local position = surface.find_non_colliding_position_in_box('electric-mining-drill', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
    if position and math.random(1, math.max(1, 15 - repeats)) == 1 then
        local entities = {}
        for x = -1, 1, 1 do
            for y = -1, 1, 1 do
                entities[#entities + 1] = {name = 'uranium-ore', position = {x = position.x + x, y = position.y + y}, amount = 2500}
            end
        end
        for _, entity in pairs(entities) do
            surface.create_entity(entity)
        end
        return true
    end
    return false
end

local function tier4_object(expanse, surface, left_top, repeats)
    local position = surface.find_non_colliding_position_in_box('rocket-silo', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
    if position and math.random(1, math.max(1, 20 - repeats)) == 1 then
        if expanse.tiered_specials[4].unlocks == 3 then
            for _ = 1, 2, 1 do
                local pos = surface.find_non_colliding_position_in_box('crude-oil', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'crude-oil', position = pos, amount = 500000})
                end
            end
            return true
        elseif expanse.tiered_specials[4].unlocks == 2 then
            local pad = surface.create_entity({name = 'cargo-landing-pad', position = position, force = game.forces.player})
            pad.minable_flag = false
            pad.destructible = false
            expanse.landing_pad = pad
            game.forces.player.recipes['cargo-landing-pad'].enabled = true
            return true
        elseif expanse.tiered_specials[4].unlocks == 1 then
            local silo = surface.create_entity({name = 'rocket-silo', position = position, force = game.forces.player})
            silo.minable_flag = false
            silo.destructible = false
            local renders = silo_renders(silo, 4)
            local silos = expanse.rocket_silos
            silos[silo.unit_number] = {entity = silo, tier = 4, renders = renders}
            return true
        end
    end
    return false
end

local function tier5_object(expanse, surface, left_top, repeats)
    local position = surface.find_non_colliding_position_in_box('rocket-silo', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
    local unlocks = expanse.tiered_specials[5].unlocks
    local tier = 5 + ( (SA and 5 or 1) - unlocks)
    if position and math.random(1, math.max(1, 25 - repeats)) == 1 then
        local silo = surface.create_entity({name = 'rocket-silo', position = position, force = game.forces.player})
        silo.minable_flag = false
        silo.destructible = false
        local renders = silo_renders(silo, tier)
        local silos = expanse.rocket_silos
        silos[silo.unit_number] = {entity = silo, tier = tier, renders = renders}
        return true
    end
    return false
end

local function tier6_object(_expanse, surface, left_top, repeats) --vulcanus
    local position = {x = left_top.x + 7, y = left_top.y + 7}
    if position and math.random(1, math.max(1, 5 - repeats) + 2) == 1 then
        local objects = {
            ['lava'] = 1,
            ['tungsten-ore'] = 3,
            ['sulfur'] = 3,
            ['calcite'] = 3,
            ['coal'] = 2,
            ['rocks'] = 3
        }
        local roll = Raffle.raffle(objects)
        if roll == 'lava' then
            local tiles = {}
            for x = -5, 5, 1 do
                for y = -5, 5, 1 do
                    tiles[#tiles+1] = {position = {x = position.x + x, y = position.y + y}, name = 'lava-hot'}
                end
            end
            surface.set_tiles(tiles)
        elseif roll == 'titanium-ore' or roll == 'calcite' or roll == 'coal' then
            for _ = 1, 36, 1 do
                local pos = surface.find_non_colliding_position_in_box(roll, {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = roll, position = pos, amount = 2500 + math.random(1, 500)})
                end
            end
        elseif roll == 'sulfur' then
            for _ = 1, 5, 1 do
                local pos = surface.find_non_colliding_position_in_box('sulfuric-acid-geyser', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'sulfuric-acid-geyser', position = pos, amount = 300000})
                end
            end
        elseif roll == 'rocks' then
            for _ = 1, 8, 1 do
                local pos = surface.find_non_colliding_position_in_box('big-volcanic-rock', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'big-volcanic-rock', position = pos})
                end
            end
        end
        if _DEBUG then
            game.print('Generated ' .. roll .. ' at [gps=' .. position.x .. ',' .. position.y .. ',' .. surface.name .. ']')
        end
        return true
    end
    return false
end

local function tier7_object(_expanse, surface, left_top, repeats) --fulgora
    local position = {x = left_top.x + 7, y = left_top.y + 7}
    if position and math.random(1, math.max(1, 5 - repeats) + 2) == 1 then
        local objects = {
            ['ruins'] = 2,
            ['scrap'] = 3,
            ['vault-ruin'] = 1
        }
        local roll = Raffle.raffle(objects)
        if roll == 'ruins' then
            local list = {
                'fulgoran-ruin-small',
                'fulgoran-ruin-small',
                'fulgoran-ruin-small',
                'fulgoran-ruin-medium',
                'fulgoran-ruin-medium',
                'fulgoran-ruin-big',
                'fulgoran-ruin-stonehenge',
                'fulgoran-ruin-colossal',
            }
            local roll2 = list[math.random(1, #list)]
            for _ = 1, 8, 1 do
                local pos = surface.find_non_colliding_position_in_box(roll2, {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = roll2, position = pos})
                end
            end
            return true
        elseif roll == 'scrap' then
            for _ = 1, 36, 1 do
                local pos = surface.find_non_colliding_position_in_box(roll, {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = roll, position = pos, amount = 2500 + math.random(1, 500)})
                end
            end
            return true
        elseif roll == 'vault-ruin' then
            local entities = surface.find_entities_filtered({force = 'enemy', area = {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}})
            for _, e in pairs(entities) do
                e.destroy()
            end
            local pos = surface.find_non_colliding_position_in_box('fulgoran-ruin-vault', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
            if pos then
                surface.create_entity({name = 'fulgoran-ruin-vault', position = pos})
                return true
            end
        end
    end
    return false
end

local function tier8_object(_expanse, surface, left_top, repeats) --gleba
    local position = {x = left_top.x + 7, y = left_top.y + 7}
    if position and math.random(1, math.max(1, 5 - repeats) + 2) == 1 then
        local objects = {
            ['natural-jellynut-soil'] = 1,
            ['natural-yumako-soil'] = 1,
            ['red-swamp'] = 2,
            ['green-swamp'] = 2
        }
        local roll = Raffle.raffle(objects)
        if roll == 'natural-jellynut-soil' or roll == 'natural-yumako-soil' then
            local tiles = {}
            for x = -5, 5, 1 do
                for y = -5, 5, 1 do
                    tiles[#tiles+1] = {position = {x = position.x + x, y = position.y + y}, name = roll}
                end
            end
            surface.set_tiles(tiles)
            local tree = roll == 'natural-yumako-soil' and 'yumako-tree' or 'jellystem'
            for _ = 1, 8, 1 do
                local pos = surface.find_non_colliding_position_in_box(tree, {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = tree, position = pos, tick_grown = game.tick})
                end
            end
        elseif roll == 'red-swamp' then
            local tiles = {}
            for x = -6, 6, 1 do
                for y = -6, 6, 1 do
                    tiles[#tiles+1] = {position = {x = position.x + x, y = position.y + y}, name = 'wetland-jellynut'}
                end
            end
            surface.set_tiles(tiles)
            for _ = 1, 3, 1 do
                local pos = surface.find_non_colliding_position_in_box('gleba-spawner', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'gleba-spawner', position = pos})
                end
            end
            for _ = 1, 10, 1 do
                local pos = surface.find_non_colliding_position_in_box('iron-stromatolite', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'iron-stromatolite', position = pos})
                end
            end
        elseif roll == 'green-swamp' then
            local tiles = {}
            for x = -6, 6, 1 do
                for y = -6, 6, 1 do
                    tiles[#tiles+1] = {position = {x = position.x + x, y = position.y + y}, name = 'wetland-yumako'}
                end
            end
            surface.set_tiles(tiles)
            for _ = 1, 3, 1 do
                local pos = surface.find_non_colliding_position_in_box('gleba-spawner', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'gleba-spawner', position = pos})
                end
            end
            for _ = 1, 10, 1 do
                local pos = surface.find_non_colliding_position_in_box('copper-stromatolite', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = 'copper-stromatolite', position = pos})
                end
            end
        end

        return true
    end
    return false
end

local function tier9_object(_expanse, surface, left_top, repeats) --aquilo
    local position = {x = left_top.x + 7, y = left_top.y + 7}
    if position and math.random(1, math.max(1, 5 - repeats) + 2) == 1 then
        local objects = {
            ['ammoniacal-ocean'] = 1,
            ['lithium-iceberg-big'] = 3,
            ['lithium-iceberg-huge'] = 1,
            ['lithium-brine'] = 2,
            ['fluorine-vent'] = 2
        }
        local roll = Raffle.raffle(objects)
        if roll == 'ammoniacal-ocean' then
            local tiles = {}
            for x = -5, 5, 1 do
                for y = -5, 5, 1 do
                    tiles[#tiles+1] = {position = {x = position.x + x, y = position.y + y}, name = 'ammoniacal-ocean'}
                end
            end
            surface.set_tiles(tiles)
        elseif roll == 'lithium-brine' or roll == 'fluorine-vent' then
            for _ = 1, 5, 1 do
                local pos = surface.find_non_colliding_position_in_box(roll, {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = roll, position = pos, amount = 300000})
                end
            end
        elseif roll == 'lithium-iceberg-big' or roll == 'lithium-iceberg-huge' then
            for _ = 1, 8, 1 do
                local pos = surface.find_non_colliding_position_in_box(roll, {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
                if pos then
                    surface.create_entity({name = roll, position = pos})
                end
            end
        end
        return true
    end
    return false
end

local function tier10_object(expanse, surface, left_top) --finale
    local position = surface.find_non_colliding_position_in_box('rocket-silo', {{left_top.x, left_top.y}, {left_top.x + 15, left_top.y + 15}}, 1, false)
    if position then
        local silo = surface.create_entity({name = 'rocket-silo', position = position, force = game.forces.player})
        silo.minable_flag = false
        silo.destructible = false
        local renders = silo_renders(silo, 0)
        local silos = expanse.rocket_silos
        silos[silo.unit_number] = {entity = silo, tier = 10, renders = renders}
        expanse.tiered_specials[10].specials = 0
        return true
    end
    return false
end

function Public.place_special_tiered_object(expanse, tier, surface, left_top, custom_tier)
    local success
    local repeats = expanse.tiered_specials[tier].tiles
    if expanse.tiered_specials[tier].unlocks > 0 then
        local tiers = {
            [3] = tier3_object,
            [4] = tier4_object,
            [5] = tier5_object,
            [6] = tier6_object,
            [7] = tier7_object,
            [8] = tier8_object,
            [9] = tier9_object,
            [10] = tier10_object
        }
        if tier > 2 and tier < 10 then
            success = tiers[tier](expanse, surface, left_top, repeats)
        elseif tier == 10 then
            if custom_tier == 10 then
                success = tiers[10](expanse, surface, left_top)
            else
                success = tiers[custom_tier](expanse, surface, left_top, repeats)
            end
        end
    end
    if success then
        expanse.tiered_specials[tier].unlocks = expanse.tiered_specials[tier].unlocks - 1
    else
        expanse.tiered_specials[tier].tiles = expanse.tiered_specials[tier].tiles + 1
    end
end

function Public.convert_tiles(surface, left_top, tier, cell_size)
    local list = {}
    if SA and tier == 6 then --vulcanus
        list = {
            ['dirt-1'] = 'volcanic-ash-cracks',
            ['dirt-2'] = 'volcanic-ash-soil',
            ['dirt-3'] = 'volcanic-ash-dark',
            ['dirt-4'] = 'volcanic-smooth-stone-warm',
            ['dirt-5'] = 'volcanic-smooth-stone-warm',
            ['dirt-6'] = 'volcanic-smooth-stone-warm',
            ['dirt-7'] = 'volcanic-cracks-warm',
            ['dry-dirt'] = 'volcanic-ash-dark',
            ['sand-1'] = 'volcanic-ash-dark',
            ['sand-2'] = 'volcanic-ash-dark',
            ['sand-3'] = 'volcanic-ash-dark',
            ['red-desert-0'] = 'volcanic-ash-dark',
            ['red-desert-1'] = 'volcanic-ash-dark',
            ['red-desert-2'] = 'volcanic-ash-dark',
            ['red-desert-3'] = 'volcanic-ash-dark',
            ['grass-1'] = 'volcanic-smooth-stone',
            ['grass-2'] = 'volcanic-smooth-stone',
            ['grass-3'] = 'volcanic-smooth-stone',
            ['grass-4'] = 'volcanic-smooth-stone',
            ['water'] = 'lava',
            ['deepwater'] = 'lava-hot',
        }
    elseif SA and tier == 7 then --fulgora
        list = {
            ['dirt-1'] = 'fulgoran-dust',
            ['dirt-2'] = 'fulgoran-dust',
            ['dirt-3'] = 'fulgoran-dust',
            ['dirt-4'] = 'fulgoran-dust',
            ['dirt-5'] = 'fulgoran-dust',
            ['dirt-6'] = 'fulgoran-dust',
            ['dirt-7'] = 'fulgoran-conduit',
            ['dry-dirt'] = 'fulgoran-dunes',
            ['sand-1'] = 'fulgoran-sand',
            ['sand-2'] = 'fulgoran-sand',
            ['sand-3'] = 'fulgoran-sand',
            ['red-desert-0'] = 'fulgoran-rock',
            ['red-desert-1'] = 'fulgoran-rock',
            ['red-desert-2'] = 'fulgoran-rock',
            ['red-desert-3'] = 'fulgoran-rock',
            ['grass-1'] = 'fulgoran-paving',
            ['grass-2'] = 'fulgoran-paving',
            ['grass-3'] = 'fulgoran-paving',
            ['grass-4'] = 'fulgoran-paving',
            ['water'] = 'water-green',
            ['deepwater'] = 'deepwater-green',

        }

    elseif SA and tier == 8 then --gleba
        list = {
            ['dirt-1'] = 'midland-cracked-lichen-dark',
            ['dirt-2'] = 'midland-cracked-lichen-dark',
            ['dirt-3'] = 'midland-cracked-lichen',
            ['dirt-4'] = 'midland-cracked-lichen',
            ['dirt-5'] = 'midland-cracked-lichen-dull',
            ['dirt-6'] = 'midland-cracked-lichen-dull',
            ['dirt-7'] = 'highland-dark-rock',
            ['dry-dirt'] = 'highland-dark-rock',
            ['sand-1'] = 'midland-turquoise-bark-2',
            ['sand-2'] = 'midland-turquoise-bark-2',
            ['sand-3'] = 'midland-turquoise-bark',
            ['red-desert-0'] = 'lowland-red-infection',
            ['red-desert-1'] = 'lowland-red-vein-dead',
            ['red-desert-2'] = 'lowland-red-vein-4',
            ['red-desert-3'] = 'lowland-red-vein',
            ['grass-1'] = 'lowland-olive-blubber',
            ['grass-2'] = 'lowland-olive-blubber-2',
            ['grass-3'] = 'lowland-olive-blubber-3',
            ['grass-4'] = 'lowland-brown-blubber',
            ['water'] = 'wetland-green-slime',
            ['deepwater'] = 'wetland-blue-slime',
        }

    elseif SA and tier == 9 then --aquilo
        list = {
            ['dirt-1'] = 'snow-lumpy',
            ['dirt-2'] = 'snow-lumpy',
            ['dirt-3'] = 'snow-lumpy',
            ['dirt-4'] = 'snow-crests',
            ['dirt-5'] = 'snow-crests',
            ['dirt-6'] = 'snow-crests',
            ['dirt-7'] = 'snow-flat',
            ['dry-dirt'] = 'snow-flat',
            ['sand-1'] = 'ice-rough',
            ['sand-2'] = 'ice-rough',
            ['sand-3'] = 'ice-rough',
            ['red-desert-0'] = 'ice-smooth',
            ['red-desert-1'] = 'ice-smooth',
            ['red-desert-2'] = 'ice-smooth',
            ['red-desert-3'] = 'ice-smooth',
            ['grass-1'] = 'snow-patchy',
            ['grass-2'] = 'snow-patchy',
            ['grass-3'] = 'snow-patchy',
            ['grass-4'] = 'snow-patchy',
            ['water'] = 'brash-ice',
            ['deepwater'] = 'ammoniacal-ocean',
        }

    end
    local converted_tiles = {}
    for x = 0, cell_size, 1 do
        for y = 0, cell_size, 1 do
            local position = {x = left_top.x + x, y = left_top.y + y}
            local tile = surface.get_tile(position.x, position.y)
            if tile and tile.valid and list[tile.name] then
                converted_tiles[#converted_tiles+1] = {position = position, name = list[tile.name]}
            end
        end
    end
    surface.set_tiles(converted_tiles, true, false)
end

function Public.convert_entities(surface, left_top, tier, cell_size)
    local list = {}
    if SA and tier == 6 then --vulcanus
        list = {
            ['tree-01'] = 'ashland-lichen-tree',
            ['tree-02'] = 'ashland-lichen-tree',
            ['tree-02-red'] = 'ashland-lichen-tree',
            ['tree-03'] = 'ashland-lichen-tree',
            ['tree-04'] = 'ashland-lichen-tree',
            ['tree-05'] = 'ashland-lichen-tree',
            ['tree-06'] = 'ashland-lichen-tree',
            ['tree-06-brown'] = 'ashland-lichen-tree',
            ['tree-07'] = 'ashland-lichen-tree',
            ['tree-08'] = 'ashland-lichen-tree',
            ['tree-08-brown'] = 'ashland-lichen-tree',
            ['tree-08-red'] = 'ashland-lichen-tree',
            ['tree-09'] = 'ashland-lichen-tree',
            ['tree-09-brown'] = 'ashland-lichen-tree',
            ['tree-09-red'] = 'ashland-lichen-tree',
            ['dead-grey-trunk'] = 'ashland-lichen-tree-flaming',
            ['dead-dry-hairy-tree'] = 'ashland-lichen-tree-flaming',
            ['dry-hairy-tree'] = 'ashland-lichen-tree-flaming',
            ['dead-tree-desert'] = 'ashland-lichen-tree-flaming',
            ['dry-tree'] = 'ashland-lichen-tree-flaming',
            ['stone'] = 'calcite',
            ['copper-ore'] = 'coal',
            ['iron-ore'] = 'tungsten-ore',
            ['big-rock'] = 'big-volcanic-rock'

        }
    elseif SA and tier == 7 then --fulgora
        list = {
            ['tree-01'] = 'fulgoran-ruin-small',
            ['tree-02'] = 'fulgoran-ruin-small',
            ['tree-02-red'] = 'fulgoran-ruin-big',
            ['tree-03'] = 'fulgoran-ruin-small',
            ['tree-04'] = 'fulgoran-ruin-small',
            ['tree-05'] = 'fulgoran-ruin-small',
            ['tree-06'] = 'fulgoran-ruin-small',
            ['tree-06-brown'] = 'fulgoran-ruin-attractor',
            ['tree-07'] = 'fulgoran-ruin-medium',
            ['tree-08'] = 'fulgoran-ruin-medium',
            ['tree-08-brown'] = 'fulgoran-ruin-attractor',
            ['tree-08-red'] = 'fulgoran-ruin-medium',
            ['tree-09'] = 'fulgoran-ruin-medium',
            ['tree-09-brown'] = 'fulgoran-ruin-attractor',
            ['tree-09-red'] = 'fulgoran-ruin-big',
            ['dead-grey-trunk'] = 'fulgoran-ruin-big',
            ['dead-dry-hairy-tree'] = 'fulgoran-ruin-big',
            ['dry-hairy-tree'] = 'fulgoran-ruin-big',
            ['dead-tree-desert'] = 'fulgoran-ruin-big',
            ['stone'] = 'scrap',
            ['copper-ore'] = 'scrap',
            ['iron-ore'] = 'scrap',
            ['coal'] = 'scrap',
            ['spitter-spawner'] = 'rocket-turret',
            ['biter-spawner'] = 'rocket-turret',
            ['small-biter'] = 'defender',
            ['small-spitter'] = 'destroyer',
            ['small-worm-turret'] = 'gun-turret'

        }
    elseif SA and tier == 8 then --gleba
        list = {
            ['tree-01'] = 'stingfrond',
            ['tree-02'] = 'stingfrond',
            ['tree-02-red'] = 'boompuff',
            ['tree-03'] = 'boompuff',
            ['tree-04'] = 'boompuff',
            ['tree-05'] = 'funneltrunk',
            ['tree-06'] = 'funneltrunk',
            ['tree-06-brown'] = 'funneltrunk',
            ['tree-07'] = 'lickmaw',
            ['tree-08'] = 'lickmaw',
            ['tree-08-brown'] = 'lickmaw',
            ['tree-08-red'] = 'sunnycomb',
            ['tree-09'] = 'sunnycomb',
            ['tree-09-brown'] = 'sunnycomb',
            ['tree-09-red'] = 'sunnycomb',
            ['dead-grey-trunk'] = 'teflilly',
            ['dead-dry-hairy-tree'] = 'teflilly',
            ['dry-hairy-tree'] = 'teflilly',
            ['dead-tree-desert'] = 'teflilly',
            ['copper-ore'] = 'copper-stromatolite',
            ['iron-ore'] = 'iron-stromatolite',
            ['coal'] = 'stone',
            ['spitter-spawner'] = 'gleba-spawner',
            ['biter-spawner'] = 'gleba-spawner',
            ['small-biter'] = 'small-wriggler-pentapod',
            ['small-spitter'] = 'small-strafer-pentapod',
            ['small-worm-turret'] = 'small-stomper-pentapod'
        }
    elseif SA and tier == 9 then --aquilo
        list = {
            ['tree-01'] = 'lithium-iceberg-big',
            ['tree-02'] = 'lithium-iceberg-big',
            ['tree-02-red'] = 'lithium-iceberg-big',
            ['tree-03'] = 'lithium-iceberg-big',
            ['tree-04'] = 'lithium-iceberg-big',
            ['tree-05'] = 'lithium-iceberg-big',
            ['tree-06'] = 'lithium-iceberg-big',
            ['tree-06-brown'] = 'lithium-iceberg-big',
            ['tree-07'] = 'lithium-iceberg-big',
            ['tree-08'] = 'lithium-iceberg-big',
            ['tree-08-brown'] = 'lithium-iceberg-big',
            ['tree-08-red'] = 'lithium-iceberg-big',
            ['tree-09'] = 'lithium-iceberg-big',
            ['tree-09-brown'] = 'lithium-iceberg-big',
            ['tree-09-red'] = 'lithium-iceberg-big',
            ['dead-grey-trunk'] = 'lithium-iceberg-big',
            ['dead-dry-hairy-tree'] = 'lithium-iceberg-big',
            ['dry-hairy-tree'] = 'lithium-iceberg-big',
            ['dead-tree-desert'] = 'lithium-iceberg-big',
            ['copper-ore'] = 'lithium-iceberg-big',
            ['iron-ore'] = 'lithium-iceberg-big',
            ['coal'] = 'lithium-iceberg-big',
            ['stone'] = 'lithium-iceberg-big',
        }
    end
    local names = {}
    for name, _ in pairs(list) do
        names[#names+1] = name
    end
    local old_entities = surface.find_entities_filtered({name = names, area = {{left_top.x - 1, left_top.y - 1}, {left_top.x + cell_size + 1, left_top.y + cell_size + 1}}})
    for _, entity in pairs(old_entities) do
        if entity and entity.valid and list[entity.name] then
            if entity.type == 'resource' then
                surface.create_entity({name = list[entity.name], position = entity.position, amount = entity.amount})
            else
                local new_entity = surface.create_entity({name = list[entity.name], position = entity.position})
                if new_entity.name == 'gun-turret' then
                    new_entity.insert({name = 'uranium-rounds-magazine', count = 100})
                elseif new_entity.name == 'rocket-turret' then
                    new_entity.insert({name = 'rocket', count = 100})
                elseif new_entity.type == 'combat-robot' then
                    new_entity.time_to_live = 10 * 60 * 60
                    local e = surface.find_entities_filtered{force = {'enemy', 'neutral'}, position = new_entity.position, radius = 10, limit = 1, type = {'ammo-turret', 'simple-entity', 'logistic-container'}}
                    if e and e[1] then
                        new_entity.combat_robot_owner = e[1]
                    end
                end
            end
            entity.destroy()
        end
    end
end

function Public.convert_decoratives(surface, left_top, tier, cell_size)
    local list = {}
    if SA and tier == 6 then
        list = {
            ['enemy-decal'] = 'vulcanus-dune-decal',
            ['enemy-decal-transparent'] = 'vulcanus-dune-decal'
        }
    elseif SA and tier == 7 then
        list = {
            ['enemy-decal'] = 'small-fulgora-rock',
            ['enemy-decal-transparent'] = 'small-fulgora-rock'
        }
    elseif SA and tier == 8 then
        list = {
            ['enemy-decal'] = 'curly-roots-orange',
            ['enemy-decal-transparent'] = 'curly-roots-orange'
        }

    elseif SA and tier == 9 then
        list = {
            ['enemy-decal'] = 'aquilo-ice-decal-blue',
            ['enemy-decal-transparent'] = 'aquilo-snowy-decal'
        }
    end
    local names = {}
    for name, _ in pairs(list) do
        names[#names+1] = name
    end
    local old_decorations = surface.find_decoratives_filtered({name = names, area = {{left_top.x - 2, left_top.y - 2}, {left_top.x + cell_size + 2, left_top.y + cell_size + 2}}})
    local decoratives = {}
    for _, deco in pairs(old_decorations) do
        if deco and deco.valid and list[deco.name] then
            decoratives[#decoratives+1] = {name = list[deco.name], position = deco.position, amount = deco.amount}
        end
    end
     surface.create_decoratives({decoratives = decoratives})
end

function Public.unlock_mission_tier(expanse, tier)
    if expanse.missions[tier].level == 0 then
        expanse.missions[tier].level = 1
        game.print({'expanse.missions_tier_unlock', tier}, {color = {r = 0.88, g = 0, b = 0}})
        script.raise_event(expanse.events.mission_gui_update, { tier = tier })
    end
end

function Public.split_key(key)
    return string.match(key, '^(.-)|(.+)$')
end

local function upgrade_mission_level(expanse, tier)
    local maxlevel = SA and #MissionData.costs[tier] or #MissionData.nonspace_costs[tier]
    local level = expanse.missions[tier].level
    local rewards = SA and MissionData.rewards or MissionData.nonspace_rewards
    for type, reward in pairs(rewards[tier][level]) do
        if type == 'research' then
            local techs = game.forces.player.technologies
            for tech, progress in pairs(reward) do
                if progress + techs[tech].saved_progress >= 1 then
                    techs[tech].researched = true
                    game.forces.player.print({'technology-researched', '[technology=' .. tech .. ']'})
                    game.forces.player.play_sound({path = 'utility/research_completed'})
                else
                    techs[tech].saved_progress = techs[tech].saved_progress + progress
                end
            end
        elseif type == 'production' then
            for item, count in pairs(reward) do
                expanse.space_production[item] = (expanse.space_production[item] or 0) + count
            end
        elseif type == 'once' then
            local hub = SA and expanse.space_platform.hub or expanse.nonspace_pad
            local inventory = hub.get_inventory(SA and defines.inventory.hub_main or defines.inventory.cargo_landing_pad_main)
            for item, count in pairs(reward) do
                local name, quality = Public.split_key(item)
                inventory.insert({name = name, count = count, quality = quality})
            end
        elseif type == 'script' then
            if reward['victory'] then
                script.raise_event(expanse.events.victory, {})
            elseif reward['new-ship'] then
                game.print({'expanse.script-new-ship', reward['new-ship']})
            elseif reward['spoiling'] then
                game.difficulty_settings.spoil_time_modifier = game.difficulty_settings.spoil_time_modifier + reward['spoiling']
            end
        end
    end
    expanse.missions[tier].level = math.min(expanse.missions[tier].level + 1, maxlevel)
    if expanse.missions[tier].level == maxlevel then
        game.print({'expanse.missions_maxlevel', tier})
        Server.to_discord_embed({'expanse.missions_maxlevel', tier}, true)
    else
        game.print({'expanse.missions_levelup', tier, expanse.missions[tier].level})
        Server.to_discord_embed({'expanse.missions_levelup', tier, expanse.missions[tier].level}, true)
    end
    expanse.missions[tier].delivered = {}
    script.raise_event(expanse.events.mission_gui_update, { tier = tier })
end

function Public.rocket_delivery(expanse, pod)
    local inventory = pod.get_inventory(defines.inventory.cargo_unit)
    local tier = expanse.cargo_pods[pod.unit_number].tier
    local reqs = SA and MissionData.costs[tier] or MissionData.nonspace_costs[tier]
    local level = expanse.missions[tier].level
    local full = true
    if _DEBUG and level > 0 and inventory.get_item_count('infinity-chest') > 0 then
        inventory.clear()
        goto continue
    end
    for _, item in pairs(inventory.get_contents()) do
        local key = item.name .. '|' .. item.quality
        local req = reqs[level] or {}
        if (req[key] or 0) > (expanse.missions[tier].delivered[key] or 0) then
            local used = math.min(req[key] - (expanse.missions[tier].delivered[key] or 0), item.count)
            expanse.missions[tier].delivered[key] = math.min((expanse.missions[tier].delivered[key] or 0) + item.count, req[key])
            inventory.remove({name = item.name, quality = item.quality, count = used})
        end
    end
    script.raise_event(expanse.events.mission_gui_update, { tier = tier })
    expanse.cargo_pods[pod.unit_number] = nil
    if level < 1 then return end

    for item, amount in pairs(reqs[level]) do
        if (expanse.missions[tier].delivered[item] or 0) < amount then
            full = false
            break
        end
    end
    ::continue::
    if full then
        upgrade_mission_level(expanse, tier)
    end
end

function Public.deliver_goods(expanse)
    if game.tick < 10000 then return end
    local hub = SA and expanse.space_platform.hub or expanse.nonspace_pad
    local launcher = SA and hub or expanse.nonspace_silo
    local inventory = hub.get_inventory(SA and defines.inventory.hub_main or defines.inventory.cargo_landing_pad_main)
    inventory.sort_and_merge()
    local itemamount = inventory.get_item_count()
    if itemamount == 0 then return end
    local landing_pad = expanse.landing_pad
    local destination = {type = defines.cargo_destination.surface, surface = game.surfaces[expanse.active_surface_index]}
    if landing_pad and landing_pad.valid then
        destination = {type = defines.cargo_destination.station, station = landing_pad}
    end
    for _ = 1, math.min(12, math.max(1, math.ceil(itemamount / 200))), 1 do
        local pod = launcher.create_cargo_pod()
        if not pod or not pod.valid then break end
        local pod_inventory = pod.get_inventory(defines.inventory.cargo_unit)
        for i = 1, 20, 1 do
            if not inventory[i].valid_for_read then break end
            local inserted = pod_inventory.insert(inventory[i])
            inventory[i].count = inventory[i].count - inserted
        end
        inventory.sort_and_merge()
        pod.cargo_pod_destination = destination
    end
end

function Public.produce_space_goods(expanse)
    if game.tick < 10000 then return end
    local hub = SA and expanse.space_platform.hub or expanse.nonspace_pad
    local inventory = hub.get_inventory(SA and defines.inventory.hub_main or defines.inventory.cargo_landing_pad_main)
    for item, count in pairs(expanse.space_production) do
        local name, quality = Public.split_key(item)
        inventory.insert({name = name, count = count, quality = quality})
    end
end


function Public.reset_space(expanse)
    if SA then
        expanse.space_platform.destroy()
    else
        expanse.nonspace_pad.destructible = true
        expanse.nonspace_pad.destroy()
        expanse.nonspace_silo.destructible = true
        expanse.nonspace_silo.destroy()
    end
end





return Public