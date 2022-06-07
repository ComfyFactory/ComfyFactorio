local Event = require 'utils.event'
local Market = require 'maps.mountain_fortress_v3.basic_markets'
local LocomotiveMarket = require 'maps.mountain_fortress_v3.locomotive.market'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WPT = require 'maps.mountain_fortress_v3.table'
local ICFunctions = require 'maps.mountain_fortress_v3.ic.functions'
local Session = require 'utils.datastore.session_data'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local RPG = require 'modules.rpg.main'
local Gui = require 'utils.gui'
local Alert = require 'utils.alert'
local Math2D = require 'math2d'
local PermissionGroups = require 'maps.mountain_fortress_v3.locomotive.permission_groups'

local Public = {}

local rpg_main_frame = RPG.main_frame_name
local random = math.random
local floor = math.floor
local round = math.round

local clear_items_upon_surface_entry = {
    ['entity-ghost'] = true,
    ['small-electric-pole'] = true,
    ['medium-electric-pole'] = true,
    ['big-electric-pole'] = true,
    ['substation'] = true
}

local valid_armors = {
    ['modular-armor'] = true,
    ['power-armor'] = true,
    ['power-armor-mk2'] = true
}

local function add_random_loot_to_main_market(rarity)
    local main_market_items = WPT.get('main_market_items')
    local items = Market.get_random_item(rarity, true, false)
    if not items then
        return false
    end

    local types = game.item_prototypes

    for k, v in pairs(main_market_items) do
        if not v.static then
            main_market_items[k] = nil
        end
    end

    for k, v in pairs(items) do
        local price = v.price[1][2] + random(1, 15) * rarity
        local value = v.price[1][1]
        local stack = 1
        if v.offer.item == 'coin' then
            price = v.price[1][2]
            stack = v.offer.count
            if not stack then
                stack = v.price[1][2]
            end
        end

        if not main_market_items[v.offer.item] then
            main_market_items[v.offer.item] = {
                stack = stack,
                value = value,
                price = price,
                tooltip = types[v.offer.item].localised_name,
                upgrade = false
            }
        end
    end
end

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
    if not game.get_player(player.name) then
        return false
    end
    return true
end

local function give_passive_xp(data)
    local xp_floating_text_color = {r = 188, g = 201, b = 63}
    local visuals_delay = 1800
    local loco_surface = WPT.get('loco_surface')
    if not (loco_surface and loco_surface.valid) then
        return
    end
    local locomotive_xp_aura = WPT.get('locomotive_xp_aura')
    local locomotive = WPT.get('locomotive')
    local xp_points = WPT.get('xp_points')
    local aura = locomotive_xp_aura
    local rpg = data.rpg
    local loco = locomotive.position
    local area = {
        left_top = {x = loco.x - aura, y = loco.y - aura},
        right_bottom = {x = loco.x + aura, y = loco.y + aura}
    }

    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end
        if player.afk_time < 200 and not RPG.get_last_spell_cast(player) then
            if Math2D.bounding_box.contains_point(area, player.position) or player.surface.index == loco_surface.index then
                if player.surface.index == loco_surface.index then
                    PermissionGroups.add_player_to_permission_group(player, 'limited')
                elseif ICFunctions.get_player_surface(player) then
                    return PermissionGroups.add_player_to_permission_group(player, 'limited')
                else
                    PermissionGroups.add_player_to_permission_group(player, 'near_locomotive')
                end

                local pos = player.position
                RPG.gain_xp(player, 0.5 * (rpg[player.index].bonus + xp_points))

                player.create_local_flying_text {
                    text = '+' .. '',
                    position = {x = pos.x, y = pos.y - 2},
                    color = xp_floating_text_color,
                    time_to_live = 60,
                    speed = 3
                }
                rpg[player.index].xp_since_last_floaty_text = 0
                rpg[player.index].last_floaty_text = game.tick + visuals_delay
                RPG.set_last_spell_cast(player, player.position)
                if player.gui.screen[rpg_main_frame] then
                    local f = player.gui.screen[rpg_main_frame]
                    local d = Gui.get_data(f)
                    if d.exp_gui and d.exp_gui.valid then
                        d.exp_gui.caption = floor(rpg[player.index].xp)
                    end
                end
            else
                local active_surface_index = WPT.get('active_surface_index')
                local surface = game.surfaces[active_surface_index]
                if surface and surface.valid then
                    if player.surface.index == surface.index then
                        PermissionGroups.add_player_to_permission_group(player, 'main_surface')
                    end
                end
            end
        end
    end
end

local function is_around_train(data)
    local entity = data.entity
    local aura = data.aura + 20
    local loco = data.locomotive.position
    local area = {
        left_top = {x = loco.x - aura, y = loco.y - aura},
        right_bottom = {x = loco.x + aura, y = loco.y + aura}
    }
    local pos = entity.position

    if Math2D.bounding_box.contains_point(area, pos) then
        return true
    end
    return false
end

local function fish_tag()
    local locomotive_cargo = WPT.get('locomotive_cargo')
    if not (locomotive_cargo and locomotive_cargo.valid) then
        return
    end
    if not (locomotive_cargo.surface and locomotive_cargo.surface.valid) then
        return
    end

    local locomotive_tag = WPT.get('locomotive_tag')

    if locomotive_tag then
        if locomotive_tag.valid then
            if locomotive_tag.position.x == locomotive_cargo.position.x and locomotive_tag.position.y == locomotive_cargo.position.y then
                return
            end
            locomotive_tag.destroy()
        end
    end
    WPT.set(
        'locomotive_tag',
        locomotive_cargo.force.add_chart_tag(
            locomotive_cargo.surface,
            {
                icon = {type = 'item', name = 'raw-fish'},
                position = locomotive_cargo.position,
                text = ' '
            }
        )
    )
end

local function set_player_spawn()
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local position = locomotive.surface.find_non_colliding_position('stone-furnace', locomotive.position, 16, 2)
    if not position then
        return
    end
    game.forces.player.set_spawn_position({x = position.x, y = position.y}, locomotive.surface)
end

local function refill_fish()
    local locomotive_cargo = WPT.get('locomotive_cargo')
    if not locomotive_cargo then
        return
    end
    if not locomotive_cargo.valid then
        return
    end
    locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = 'raw-fish', count = random(2, 5)})
end

local function set_carriages()
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    if not locomotive.train then
        return
    end

    local carriages = locomotive.train.carriages
    local t = {}
    for i = 1, #carriages do
        local e = carriages[i]
        if (e and e.valid) then
            t[e.unit_number] = true
        end
    end

    WPT.set('carriages_numbers', t)
    WPT.set('carriages', locomotive.train.carriages)
end

local function get_driver_action(entity)
    if not entity or not entity.valid then
        return
    end

    local driver = entity.get_driver()
    if not driver or not driver.valid then
        return
    end

    local player = driver.player
    if not player or not player.valid then
        return
    end

    if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == 'raw-fish' then
        player.print('[color=blue][Locomotive][/color] Unequip your fishy if you want to drive.')
        driver.driving = false
        return
    end

    local armor = driver.get_inventory(defines.inventory.character_armor)
    if armor and armor[1] and armor[1].valid_for_read and valid_armors[armor[1].name] then
        player.print('[color=blue][Locomotive][/color] Unequip your armor if you want to drive.')
        driver.driving = false
    end
end

local function set_locomotive_health()
    local locomotive_health = WPT.get('locomotive_health')
    local locomotive_max_health = WPT.get('locomotive_max_health')
    local locomotive = WPT.get('locomotive')

    local function check_health()
        local m = locomotive_health / locomotive_max_health
        if locomotive_health > locomotive_max_health then
            WPT.set('locomotive_health', locomotive_max_health)
        end
        rendering.set_text(WPT.get('health_text'), 'HP: ' .. round(locomotive_health) .. ' / ' .. round(locomotive_max_health))
        local carriages = WPT.get('carriages')
        if carriages then
            for i = 1, #carriages do
                local entity = carriages[i]
                if not (entity and entity.valid) then
                    return
                end
                get_driver_action(entity)
                local cargo_health = 600
                if entity.type == 'locomotive' then
                    entity.health = 1000 * m
                else
                    entity.health = cargo_health * m
                end
            end
        end
    end

    if not (locomotive and locomotive.valid) then
        return
    end

    check_health()
end

local function validate_index()
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local icw_table = ICW.get_table()
    local icw_locomotive = WPT.get('icw_locomotive')
    local loco_surface = icw_locomotive.surface
    local unit_surface = locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]
    if loco_surface.valid then
        WPT.set('loco_surface', locomotive_surface)
    end
end

local function on_research_finished(event)
    local research = event.research
    if not research then
        return
    end

    local name = research.name

    if name == 'discharge-defense-equipment' then
        local message = ({'locomotive.discharge_unlocked'})
        Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac', 0.1)
    end
    if name == 'artillery' then
        local message = ({'locomotive.artillery_unlocked'})
        Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac', 0.1)
    end

    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local market_announce = WPT.get('market_announce')
    if market_announce > game.tick then
        return
    end

    local breached_wall = WPT.get('breached_wall')
    add_random_loot_to_main_market(breached_wall)
    local message = ({'locomotive.new_items_at_market'})
    Alert.alert_all_players(5, message, nil, 'achievement/tech-maniac', 0.1)
    LocomotiveMarket.refresh_gui()
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local active_surface = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface]
    if not surface or not surface.valid then
        return
    end

    local itemGhost = player.cursor_ghost
    if itemGhost then
        player.cursor_ghost = nil
    end

    local item = player.cursor_stack
    if item and item.valid_for_read then
        local name = item.name
        if clear_items_upon_surface_entry[name] then
            player.cursor_stack.clear()
        end
    end

    if player.surface.name == 'nauvis' then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    end

    local locomotive_surface = WPT.get('loco_surface')

    if locomotive_surface and locomotive_surface.valid and player.surface.index == locomotive_surface.index then
        return PermissionGroups.add_player_to_permission_group(player, 'limited')
    elseif ICFunctions.get_player_surface(player) then
        return PermissionGroups.add_player_to_permission_group(player, 'limited')
    elseif player.surface.index == surface.index then
        return PermissionGroups.add_player_to_permission_group(player, 'main_surface')
    end
end

local function on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local trusted = Session.get_trusted_table()
    if #trusted == 0 then
        return
    end

    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    if entity.unit_number == locomotive.unit_number then
        if not trusted[player.name] then
            if player.character and player.character.valid and player.character.driving then
                player.character.driving = false
            end
        end
    end
end

function Public.boost_players_around_train()
    local rpg = RPG.get('rpg_t')
    local active_surface_index = WPT.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local locomotive = WPT.get('locomotive')
    if not (locomotive and locomotive.valid) then
        return
    end
    local surface = game.surfaces[active_surface_index]
    local icw_table = ICW.get_table()
    local unit_surface = locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    local data = {
        surface = surface,
        locomotive_surface = locomotive_surface,
        rpg = rpg
    }
    give_passive_xp(data)
end

function Public.is_around_train(entity)
    local locomotive = WPT.get('locomotive')
    local active_surface_index = WPT.get('active_surface_index')

    if not active_surface_index then
        return false
    end
    if not locomotive then
        return false
    end
    if not locomotive.valid then
        return false
    end

    if not entity or not entity.valid then
        return false
    end

    local surface = game.surfaces[active_surface_index]
    local aura = WPT.get('locomotive_xp_aura')

    local data = {
        locomotive = locomotive,
        surface = surface,
        entity = entity,
        aura = aura
    }

    local success = is_around_train(data)
    return success
end

function Public.render_train_hp()
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]

    local locomotive_health = WPT.get('locomotive_health')
    local locomotive_max_health = WPT.get('locomotive_max_health')
    local locomotive = WPT.get('locomotive')
    local locomotive_xp_aura = WPT.get('locomotive_xp_aura')

    WPT.set().health_text =
        rendering.draw_text {
        text = 'HP: ' .. locomotive_health .. ' / ' .. locomotive_max_health,
        surface = surface,
        target = locomotive,
        target_offset = {0, -4.5},
        color = locomotive.color,
        scale = 1.40,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    WPT.set().caption =
        rendering.draw_text {
        text = 'Comfy Choo Choo',
        surface = surface,
        target = locomotive,
        target_offset = {0, -6.25},
        color = locomotive.color,
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }

    WPT.set().circle =
        rendering.draw_circle {
        surface = surface,
        target = locomotive,
        color = locomotive.color,
        filled = false,
        radius = locomotive_xp_aura,
        only_in_alt_mode = true
    }
end

function Public.transfer_pollution()
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local active_surface_index = WPT.get('active_surface_index')
    local active_surface = game.surfaces[active_surface_index]
    if not active_surface or not active_surface.valid then
        return
    end

    local icw_locomotive = WPT.get('icw_locomotive')
    local surface = icw_locomotive.surface
    if not surface or not surface.valid then
        return
    end

    local total_interior_pollution = surface.get_total_pollution()

    local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * Difficulty.get().difficulty_vote_value
    active_surface.pollute(locomotive.position, pollution)
    game.pollution_statistics.on_flow('locomotive', pollution - total_interior_pollution)
    surface.clear_pollution()
end

local boost_players = Public.boost_players_around_train
local pollute_area = Public.transfer_pollution

local function tick()
    local ticker = game.tick

    if ticker % 30 == 0 then
        set_locomotive_health()
        validate_index()
        fish_tag()
    end

    if ticker % 120 == 0 then
        -- tp_player()
        boost_players()
    end

    if ticker % 1200 == 0 then
        set_player_spawn()
        refill_fish()
    end

    if ticker % 2500 == 0 then
        pollute_area()
    end
end

Event.on_nth_tick(5, tick)

Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_train_created, set_carriages)

return Public
