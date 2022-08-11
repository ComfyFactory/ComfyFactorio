-- a map where you feed hungry boxes, which unlocks new territory, with even more hungry boxes by mewmew

--CONFIGS
local cell_size = 15 -- size of each territory to unlock
local chance_to_receive_token = 0.35 -- chance of a hungry chest, dropping a token after unlocking, can be above 1 for multiple

require 'modules.satellite_score'
require 'modules.backpack_research'

local Event = require 'utils.event'
local Functions = require 'maps.expanse.functions'
local GetNoise = require 'utils.get_noise'
local Global = require 'utils.global'
local Map_info = require 'modules.map_info'
local Gui = require 'utils.gui'
local format_number = require 'util'.format_number
local Random = require 'maps.chronosphere.random'
local Autostash = require 'modules.autostash'

local expanse = {
    events = {
        gui_update = Event.generate_event_name('expanse_gui_update'),
        invasion_warn = Event.generate_event_name('invasion_warn'),
        invasion_detonate = Event.generate_event_name('invasion_detonate'),
        invasion_trigger = Event.generate_event_name('invasion_trigger')
    }
}
Global.register(
    expanse,
    function(tbl)
        expanse = tbl
    end
)

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local function create_button(player)
    if not player.gui.top[main_button_name] then
        local b =
            player.gui.top.add(
            {
                type = 'sprite-button',
                name = main_button_name,
                sprite = 'item/logistic-chest-requester',
                tooltip = 'Show Expanse statistics!'
            }
        )
        b.style.minimal_height = 38
        b.style.maximal_height = 38
    end
end

local function set_nauvis()
    local surface = game.surfaces[1]
    local map_gen_settings = surface.map_gen_settings
    map_gen_settings.autoplace_controls = {
        ['coal'] = {frequency = 10, size = 0.7, richness = 0.5},
        ['stone'] = {frequency = 10, size = 0.7, richness = 0.5},
        ['copper-ore'] = {frequency = 10, size = 0.7, richness = 0.75},
        ['iron-ore'] = {frequency = 10, size = 0.7, richness = 1},
        ['uranium-ore'] = {frequency = 10, size = 0.7, richness = 1},
        ['crude-oil'] = {frequency = 20, size = 1.5, richness = 1.5},
        ['trees'] = {frequency = 1.75, size = 1.25, richness = 1},
        ['enemy-base'] = {frequency = 10, size = 2, richness = 1}
    }
    map_gen_settings.starting_area = 0.25
    surface.map_gen_settings = map_gen_settings
    for chunk in surface.get_chunks() do
        surface.delete_chunk({chunk.x, chunk.y})
    end
end

local function reset()
    expanse.grid = {}
    expanse.containers = {}
    expanse.cost_stats = {}
    expanse.invasion_candidates = {}
    expanse.schedule = {}
    expanse.size = 1
    Autostash.insert_into_furnace(true)

    local map_gen_settings = {
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {treat_missing_as_default = false},
            ['decorative'] = {treat_missing_as_default = false}
        },
        autoplace_controls = {
            ['coal'] = {frequency = 0, size = 0, richness = 0},
            ['stone'] = {frequency = 0, size = 0, richness = 0},
            ['copper-ore'] = {frequency = 0, size = 0, richness = 0},
            ['iron-ore'] = {frequency = 0, size = 0, richness = 0},
            ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
            ['crude-oil'] = {frequency = 0, size = 0, richness = 0},
            ['trees'] = {frequency = 0, size = 0, richness = 0},
            ['enemy-base'] = {frequency = 0, size = 0, richness = 0}
        }
    }
    game.create_surface('expanse', map_gen_settings)

    if expanse.override_nauvis then
        set_nauvis()
    end

    local source_surface = game.surfaces[expanse.source_surface]
    source_surface.request_to_generate_chunks({x = 0, y = 0}, 4)
    source_surface.force_generate_chunk_requests()

    local surface = game.surfaces.expanse
    surface.request_to_generate_chunks({x = 0, y = 0}, 4)
    surface.force_generate_chunk_requests()

    for _, player in pairs(game.players) do
        player.teleport({-4, -4}, source_surface)
    end

    Functions.expand(expanse, {x = 0, y = 0})

    for _, player in pairs(game.players) do
        player.teleport(surface.find_non_colliding_position('character', {expanse.square_size * 0.5, expanse.square_size * 0.5}, 8, 0.5), surface)
    end
end

local ores = {'copper-ore', 'iron-ore', 'stone', 'coal'}
local function generate_ore(surface, left_top)
    local seed = game.surfaces[1].map_gen_settings.seed
    local left_top_x = left_top.x
    local left_top_y = left_top.y

    --Draw the mixed ore patches.
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local pos = {x = left_top_x + x, y = left_top_y + y}
            if surface.can_place_entity({name = 'iron-ore', position = pos}) then
                local noise = GetNoise('smol_areas', pos, seed)
                if math.abs(noise) > 0.78 then
                    local amount = 500 + math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 2
                    local i = math.floor(noise * 40 + math.abs(pos.x) * 0.05) % 4 + 1
                    surface.create_entity({name = ores[i], position = pos, amount = amount})
                end
            end
        end
    end
end

local function on_chunk_generated(event)
    local surface = event.surface

    if surface.name ~= 'expanse' then
        if expanse.override_nauvis then
            if surface.index == 1 then
                for _, e in pairs(surface.find_entities_filtered({area = event.area, name = {'iron-ore', 'copper-ore', 'coal', 'stone', 'uranium-ore'}})) do
                    surface.create_entity({name = e.name, position = e.position, amount = 500 + math.sqrt(e.position.x ^ 2 + e.position.y ^ 2) * 2})
                    e.destroy()
                end
                generate_ore(surface, event.area.left_top)
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
                    tiles[i] = {name = 'out-of-map', position = {left_top.x + x, left_top.y + y}}
                    i = i + 1
                end
            end
        end
    else
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                tiles[i] = {name = 'out-of-map', position = {left_top.x + x, left_top.y + y}}
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)
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
        local colored_player_name =
            table.concat({'[color=', player.color.r * 0.6 + 0.35, ',', player.color.g * 0.6 + 0.35, ',', player.color.b * 0.6 + 0.35, ']', player.name, '[/color]'})
        game.print(colored_player_name .. ' unlocked new grounds! [gps=' .. math.floor(expansion_position.x) .. ',' .. math.floor(expansion_position.y) .. ',expanse]')
        expanse.size = (expanse.size or 1) + 1
        if math.random(1, 4) == 1 then
            if player.surface.count_tiles_filtered({position = expansion_position, radius = 6, collision_mask = 'water-tile'}) > 40 then
                return
            end
            local render = rendering.draw_sprite{
                sprite = 'utility/danger_icon',
                surface = player.surface,
                target = expansion_position,
                x_scale = 2,
                y_scale = 2
            }
            table.insert(expanse.invasion_candidates, {surface = player.surface, position = expansion_position, render = render})
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

local inf_ores = {'iron-ore', 'iron-ore', 'copper-ore', 'coal'}
local function infini_rock(entity)
    if entity.type ~= 'simple-entity' then
        return
    end
    local a = math.floor(expanse.square_size * 0.5)
    if entity.position.x == a and entity.position.y == a then
        entity.surface.create_entity({name = 'rock-big', position = {a, a}})
        entity.surface.spill_item_stack(entity.position, {name = inf_ores[math.random(1, 4)], count = math.random(80, 160)}, true, nil, true)
        entity.surface.spill_item_stack(entity.position, {name = 'stone', count = math.random(15, 30)}, true, nil, true)
    end
end

local function infini_tree(entity)
    if entity.type ~= 'tree' then
        return
    end
    local a = math.floor(expanse.square_size * 0.5)
    if entity.position.x == a and entity.position.y == a - 3 then
        entity.surface.create_entity({name = 'tree-0' .. math.random(1, 9), position = {a, a - 3}})
    end
end

local function infini_resource(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    infini_rock(entity)
    infini_tree(entity)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if player.online_time == 0 then
        local surface = game.surfaces.expanse
        player.teleport(surface.find_non_colliding_position('character', {expanse.square_size * 0.5, expanse.square_size * 0.5}, 32, 0.5), surface)
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
    local removed_count = inventory.remove({name = 'coin', count = 999999})
    if removed_count > 0 then
        for _ = 1, removed_count, 1 do
            player.surface.spill_item_stack(player.position, {name = 'coin', count = 1}, false, nil, false)
        end
        game.print(player.name .. ' dropped their tokens! [gps=' .. math.floor(player.position.x) .. ',' .. math.floor(player.position.y) .. ',' .. player.surface.name .. ']')
    end
end

local function on_init()
    local T = Map_info.Pop_info()
    T.localised_category = 'expanse'
    T.main_caption_color = {r = 170, g = 170, b = 0}
    T.sub_caption_color = {r = 120, g = 120, b = 0}

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
    game.map_settings.enemy_evolution.destroy_factor = 0.005

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

local function on_tick()
    if not next(expanse.schedule) then return end
    for index, stuff in pairs(expanse.schedule) do
        if game.tick >= stuff.tick then
            script.raise_event(expanse.events[stuff.event], stuff.parameters)
            expanse.schedule[index] = nil
        end
    end
end

local function resource_stats(parent, name, count)
    local button = parent.add({type = 'sprite-button', name = name .. '_sprite', sprite = 'item/' .. name, enabled = false})
    local label = parent.add({type = 'label', name = name .. '_label', caption = format_number(tonumber(count), true), tooltip = count})
    label.style.width = 40
    return button, label
end

local function create_main_frame(player)
    local frame = player.gui.screen.add({type = 'frame', name = main_frame_name, caption = 'Expanse hungry chest stats', direction = 'vertical'})
    frame.location = {x = 10, y = 40}
    frame.style.maximal_height = 600
    local evo = game.forces.enemy.evolution_factor
    frame.add({type = 'label', name = 'size', caption = 'Total size unlocked: ' .. expanse.size or 1})
    frame.add({type = 'label', name = 'biters', caption = 'Biter attack: ' .. 3 + math.floor(7 * evo) .. ' positions, ' .. 1 + math.floor(evo * 4) .. ' armies'})
    local scroll = frame.add({type = 'scroll-pane', name = 'scroll_pane', horizontal_scroll_policy = 'never', vertical_scroll_policy = 'auto-and-reserve-space'})
    local frame_table = scroll.add({type = 'table', name = 'resource_stats', column_count = 8})
    for name, count in Random.spairs(expanse.cost_stats, function(t,a,b) return t[a] > t[b] end) do
        resource_stats(frame_table, name, count)
    end
end

local function update_resource_gui(event)
    for _, player in pairs(game.connected_players) do
        if player.gui.screen[main_frame_name] then
            local frame = player.gui.screen[main_frame_name]
            local evo = game.forces.enemy.evolution_factor
            frame['size'].caption = 'Total size unlocked: ' .. expanse.size or 1
            frame['biters'].caption = 'Biter attack: ' .. 3 + math.floor(evo * 10) .. ' positions, ' .. 1 + math.floor(evo * 4) .. ' armies'
            local frame_table = frame['scroll_pane']['resource_stats']
            local count = expanse.cost_stats[event.item] or 0
            if not frame_table[event.item .. '_label'] then
                resource_stats(frame_table, event.item, count)
            else
                frame_table[event.item .. '_label'].caption = format_number(tonumber(count), true)
                frame_table[event.item .. '_label'].tooltip = count
            end
        end
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end
    local name = element.name

    if name == main_button_name then
        local player = game.players[event.player_index]
        if player.gui.screen[main_frame_name] then
            player.gui.screen[main_frame_name].destroy()
        else
            create_main_frame(player)
        end
    end
end

Event.on_init(on_init)
Event.on_nth_tick(60, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_died, infini_resource)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_pre_player_mined_item, infini_resource)
Event.add(defines.events.on_robot_pre_mined, infini_resource)
Event.add(expanse.events.gui_update, update_resource_gui)
Event.add(expanse.events.invasion_warn, Functions.invasion_warn)
Event.add(expanse.events.invasion_detonate, Functions.invasion_detonate)
Event.add(expanse.events.invasion_trigger, Functions.invasion_trigger)
