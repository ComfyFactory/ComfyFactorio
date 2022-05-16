local Collapse = require 'modules.collapse'
local Balance = require 'maps.mountain_fortress_v3.balance'
local RPG = require 'modules.rpg.main'
local WPT = require 'maps.mountain_fortress_v3.table'
local Alert = require 'utils.alert'
local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Color = require 'utils.color_presets'

local raise_event = script.raise_event
local floor = math.floor
local abs = math.abs
local random = math.random
local sub = string.sub
local sqrt = math.sqrt
local zone_settings = WPT.zone_settings

local clear_breach_text_and_render = function()
    local beam1 = WPT.get('zone1_beam1')
    if beam1 and beam1.valid then
        beam1.destroy()
    end
    local beam2 = WPT.get('zone1_beam2')
    if beam2 and beam2.valid then
        beam2.destroy()
    end
    local zone1_text1 = WPT.get('zone1_text1')
    if zone1_text1 then
        rendering.set_text(zone1_text1, 'Collapse has started!')
    end
    local zone1_text2 = WPT.get('zone1_text2')
    if zone1_text2 then
        rendering.set_text(zone1_text2, 'Collapse has started!')
    end
    local zone1_text3 = WPT.get('zone1_text3')
    if zone1_text3 then
        rendering.set_text(zone1_text3, 'Collapse has started!')
    end
end

local collapse_message =
    Token.register(
    function(data)
        local pos = data.position
        local message = ({'breached_wall.collapse_start'})
        local collapse_position = {
            position = pos
        }
        Alert.alert_all_players_location(collapse_position, message)
    end
)

local spidertron_unlocked =
    Token.register(
    function()
        local message = ({'breached_wall.spidertron_unlocked'})
        Alert.alert_all_players(30, message, nil, 'achievement/tech-maniac', 0.1)
    end
)

local first_player_to_zone =
    Token.register(
    function(data)
        local player = data.player
        if not player or not player.valid then
            return
        end
        local breached_wall = data.breached_wall
        local message = ({'breached_wall.first_to_reach', player.name, breached_wall})
        Alert.alert_all_players(10, message)
    end
)

local artillery_warning =
    Token.register(
    function()
        local message = ({'breached_wall.artillery_warning'})
        Alert.alert_all_players(10, message)
    end
)

local spidertron_too_far =
    Token.register(
    function(data)
        local player = data.player
        local message = ({'breached_wall.cheating_through', player.name})
        Alert.alert_all_players(30, message)
    end
)

local check_distance_between_player_and_locomotive = function(player)
    local surface = player.surface
    local position = player.position
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local gap_between_locomotive = WPT.get('gap_between_locomotive')

    if not gap_between_locomotive.highest_pos then
        gap_between_locomotive.highest_pos = locomotive.position
    end

    gap_between_locomotive.highest_pos = locomotive.position
    gap_between_locomotive = WPT.get('gap_between_locomotive')

    local c_y = position.y
    local t_y = gap_between_locomotive.highest_pos.y

    if c_y - t_y <= gap_between_locomotive.neg_gap then
        player.teleport({position.x, locomotive.position.y + gap_between_locomotive.neg_gap + 2}, surface)
        player.print(({'breached_wall.hinder'}), Color.warning)
        if player.character then
            player.character.health = player.character.health - 5
            player.character.surface.create_entity({name = 'water-splash', position = position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local compare_player_pos = function(player)
    local p = player.position
    local index = player.index
    local adjusted_zones = WPT.get('adjusted_zones')
    if not adjusted_zones.size then
        return
    end

    local zone = floor((abs(p.y / zone_settings.zone_depth)) % adjusted_zones.size) + 1

    if adjusted_zones.scrap[zone] then
        RPG.set_value_to_player(index, 'scrap_zone', true)
    else
        local has_scrap = RPG.get_value_from_player(index, 'scrap_zone')
        if has_scrap then
            RPG.set_value_to_player(index, 'scrap_zone', false)
        end
    end

    if adjusted_zones.forest[zone] then
        RPG.set_value_to_player(index, 'forest_zone', true)
    else
        local is_in_forest = RPG.get_value_from_player(index, 'forest_zone')
        if is_in_forest then
            RPG.set_value_to_player(index, 'forest_zone', false)
        end
    end
end

local compare_player_and_train = function(player, entity)
    if not player.driving then
        return
    end

    if not (entity and entity.valid) then
        return
    end

    local position = player.position
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local gap_between_zones = WPT.get('gap_between_zones')
    gap_between_zones.highest_pos = locomotive.position
    gap_between_zones = WPT.get('gap_between_zones')

    local c_y = position.y
    local t_y = gap_between_zones.highest_pos.y
    local spidertron_warning_position = gap_between_zones.neg_gap + 50

    if c_y - t_y <= spidertron_warning_position then
        local surface = player.surface
        surface.create_entity(
            {
                name = 'flying-text',
                position = position,
                text = 'Warning! You are too far away from the main locomotive!',
                color = {r = 0.9, g = 0.0, b = 0.0}
            }
        )
    end

    if c_y - t_y <= gap_between_zones.neg_gap then
        if entity.health then
            entity.health = entity.health - 500
            if entity.health <= 0 then
                entity.die('enemy')
                Task.set_timeout_in_ticks(30, spidertron_too_far, {player = player})
                return
            end
        end
    end
end

local function distance(player)
    local index = player.index
    local bonus = RPG.get_value_from_player(index, 'bonus')
    local rpg_extra = RPG.get('rpg_extra')
    local breached_wall = WPT.get('breached_wall')
    local bonus_xp_on_join = WPT.get('bonus_xp_on_join')
    local enable_arties = WPT.get('enable_arties')

    local p = player.position

    local validate_spider = WPT.get('validate_spider')
    if validate_spider[index] then
        local e = validate_spider[index]
        if not (e and e.valid) then
            validate_spider[index] = nil
        end
        compare_player_and_train(player, validate_spider[index])
    end

    compare_player_pos(player)

    local distance_to_center = floor(sqrt(p.y ^ 2))
    local location = distance_to_center
    if location < zone_settings.zone_depth * bonus - 10 then
        return
    end

    local max = zone_settings.zone_depth * bonus
    local breach_max = zone_settings.zone_depth * breached_wall
    local breach_max_times = location >= breach_max
    local max_times = location >= max
    if max_times then
        if breach_max_times then
            local placed_trains_in_zone = WPT.get('placed_trains_in_zone')
            local biters = WPT.get('biters')
            rpg_extra.breached_walls = rpg_extra.breached_walls + 1
            rpg_extra.reward_new_players = bonus_xp_on_join * rpg_extra.breached_walls
            WPT.set('breached_wall', breached_wall + 1)
            biters.amount = 0
            placed_trains_in_zone.randomized = false
            raise_event(Balance.events.breached_wall, {})
            if WPT.get('breached_wall') == WPT.get('spidertron_unlocked_at_zone') then
                local main_market_items = WPT.get('main_market_items')
                if not main_market_items['spidertron'] then
                    local rng = random(70000, 120000)
                    main_market_items['spidertron'] = {
                        stack = 1,
                        value = 'coin',
                        price = rng,
                        tooltip = 'BiterStunner 9000',
                        upgrade = false,
                        static = true
                    }
                    Task.set_timeout_in_ticks(150, spidertron_unlocked)
                end
            end

            local data = {
                player = player,
                breached_wall = breached_wall
            }
            Task.set_timeout_in_ticks(360, first_player_to_zone, data)
            if breached_wall == 5 then
                if enable_arties == 6 then
                    Task.set_timeout_in_ticks(360, artillery_warning)
                end
            end
        end

        if not Collapse.start_now() then
            clear_breach_text_and_render()
            Collapse.start_now(true)
            local data = {
                position = Collapse.get_position()
            }
            Task.set_timeout_in_ticks(550, collapse_message, data)
        end

        if Collapse.start_now() then
            clear_breach_text_and_render()
        end

        RPG.set_value_to_player(index, 'bonus', bonus + 1)

        RPG.gain_xp(player, bonus_xp_on_join * bonus)
        return
    end
end

local function on_player_changed_position(event)
    local player = game.get_player(event.player_index)
    local surface_name = player.surface.name
    local map_name = 'mountain_fortress_v3'

    if sub(surface_name, 0, #map_name) ~= map_name then
        return
    end

    check_distance_between_player_and_locomotive(player)

    if random(1, 3) ~= 1 then
        return
    end

    distance(player)
end
local function on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    local s = WPT.get('validate_spider')
    if entity.name == 'spidertron' then
        if not s[player.index] then
            s[player.index] = entity
        end
    else
        if s[player.index] then
            s[player.index] = nil
        end
    end
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
