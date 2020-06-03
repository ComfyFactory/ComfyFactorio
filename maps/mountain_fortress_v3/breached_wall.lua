local Collapse = require 'modules.collapse'
local Terrain = require 'maps.mountain_fortress_v3.terrain'
local Balance = require 'maps.mountain_fortress_v3.balance'
local RPG = require 'maps.mountain_fortress_v3.rpg'
local WPT = require 'maps.mountain_fortress_v3.table'
local Event = require 'utils.event'

local raise_event = script.raise_event
local floor = math.floor
local sqrt = math.sqrt

local keeper = '[color=blue]Mapkeeper:[/color] '

local function distance(player)
    local rpg_t = RPG.get_table()
    local rpg_extra = RPG.get_extra_table()
    local bonus = rpg_t[player.index].bonus
    local breached_wall = WPT.get('breached_wall')

    local distance_to_center = floor(sqrt(player.position.x ^ 2 + player.position.y ^ 2))
    local location = distance_to_center
    if location < Terrain.level_depth * bonus - 10 then
        return
    end

    local max = Terrain.level_depth * bonus
    local breach_max = Terrain.level_depth * breached_wall
    local breach_max_times = location >= breach_max
    local max_times = location >= max
    if max_times then
        if breach_max_times then
            rpg_extra.breached_walls = rpg_extra.breached_walls + 1
            rpg_extra.reward_new_players = 150 * rpg_extra.breached_walls
            WPT.get().breached_wall = breached_wall + 1
            raise_event(Balance.events.breached_wall, {})
            game.print(keeper .. player.name .. ' was the first to reach zone ' .. breached_wall .. '.')
            if breached_wall == 5 then
                game.print(keeper .. 'Warning, Artilleries have been spotted north!')
            end
        end
        if not Collapse.start_now() then
            Collapse.start_now(true)
            game.print(keeper .. 'Warning, collapse has begun!')
        end
        rpg_t[player.index].bonus = bonus + 1
        player.print(keeper .. 'Survivor! Well done. You have completed zone: ' .. bonus)
        RPG.gain_xp(player, 150 * bonus)

        return
    end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    distance(player)
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
