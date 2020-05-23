local Collapse = require 'modules.collapse'
local Terrain = require 'maps.mountain_fortress_v3.terrain'
local Balance = require 'maps.mountain_fortress_v3.balance'
local WPT = require 'maps.mountain_fortress_v3.table'
local RPG = require 'maps.mountain_fortress_v3.rpg'
local Event = require 'utils.event'

local raise_event = script.raise_event
local floor = math.floor
local sqrt = math.sqrt

local function distance(player)
    local rpg_t = RPG.get_table()
    local rpg_extra = RPG.get_extra_table()
    local breached_wall = WPT.get('breached_wall')
    local distance_to_center = floor(sqrt(player.position.x ^ 2 + player.position.y ^ 2))
    local location = distance_to_center
    if location < Terrain.level_depth * rpg_t[player.index].bonus - 10 then
        return
    end
    local min = Terrain.level_depth * rpg_t[player.index].bonus
    local max = (Terrain.level_depth + 5) * rpg_t[player.index].bonus
    local breach_min = Terrain.level_depth * breached_wall
    local breach_max = (Terrain.level_depth + 5) * breached_wall
    local breach_min_times = location >= breach_min
    local breach_max_times = location <= breach_max
    local min_times = location >= min
    local max_times = location <= max
    if min_times and max_times then
        if not Collapse.start_now() then
            Collapse.start_now(true)
            game.print('[color=blue]Mapkeeper:[/color] Warning, collapse has begun!')
        end
        local level = rpg_t[player.index].bonus
        rpg_t[player.index].bonus = rpg_t[player.index].bonus + 1
        player.print('[color=blue]Mapkeeper:[/color] Survivor! Well done. You have completed level: ' .. level)
        RPG.gain_xp(player, 150 * rpg_t[player.index].bonus)
        if breach_min_times and breach_max_times then
            rpg_extra.breached_walls = rpg_extra.breached_walls + 1
            rpg_extra.reward_new_players = 150 * rpg_extra.breached_walls
            WPT.get().breached_wall = breached_wall + 1
            raise_event(Balance.events.breached_wall, {})
        end
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
