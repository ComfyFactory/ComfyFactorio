local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Event = require 'utils.event'
local Alert = require 'utils.alert'
local Surface = require 'utils.surface'
local Commands = require 'utils.commands'

local this =
{
    settings =
    {
        player_refresh_index = nil,
        force_removal_flag = -2000,
        chunk_iter = nil,
        world_eater_iter = nil,
        timeout_ticks = 216000,
        enabled = false,
        remover_disabled = false,
        _debug = false,
        task_remover = false,
        pollution_enabled = false
    },
    list =
    {
        map = {},
        removal_list = {}
    }
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local cleaner = '[color=blue]Cleaner:[/color] '
local floor = math.floor

local Public = {}

local clear_chunk_token =
    Token.register(
        function (event)
            local chunk = event.chunk
            if not chunk then
                return
            end

            local surface = game.get_surface(event.surface_index)
            if not surface or not surface.valid then
                return
            end

            if chunk and #chunk > 2 then
                for _, c in pairs(chunk) do
                    surface.delete_chunk(c)
                end
            else
                surface.delete_chunk(chunk)
            end
        end
    )

local function debug(str)
    if this.settings._debug then
        print(str)
    end
end

local function notify_all_players(msg)
    local color = { r = 0, g = 255, b = 171 }
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Alert.alert_player(player, 10, msg, color)
    end
end

local function chunk_from_tile_pos(pos)
    return { x = floor(pos.x / 32), y = floor(pos.y / 32) }
end

local function get_next_player()
    if (not this.settings.player_refresh_index or not game.players[this.settings.player_refresh_index]) then
        this.settings.player_refresh_index = 1
    else
        this.settings.player_refresh_index = this.settings.player_refresh_index + 1
    end

    if (this.settings.player_refresh_index > #game.players) then
        this.settings.player_refresh_index = 1
    end

    return this.settings.player_refresh_index
end

local function chunk_is_safe(c_pos, permanent)
    if (this.list.map[c_pos.x] == nil) then
        this.list.map[c_pos.x] = {}
    end

    if (permanent) then
        -- Make sure we don't overwrite...
        this.list.map[c_pos.x][c_pos.y] = -2
    elseif (this.list.map[c_pos.x][c_pos.y] and (this.list.map[c_pos.x][c_pos.y] ~= -2)) then
        this.list.map[c_pos.x][c_pos.y] = -1
    end
end

local function area_is_safe(c_pos, chunk_radius, permanent)
    for i = -chunk_radius, chunk_radius do
        for j = -chunk_radius, chunk_radius do
            chunk_is_safe({ x = c_pos.x + i, y = c_pos.y + j }, permanent)
        end
    end
end

-- Refreshes timers on all chunks around a certain area
local function refresh_area(pos, chunk_radius, bonus_time)
    local c_pos = chunk_from_tile_pos(pos)
    if not c_pos then
        return
    end

    for i = -chunk_radius, chunk_radius do
        local x = c_pos.x + i
        for k = -chunk_radius, chunk_radius do
            local y = c_pos.y + k

            if (this.list.map[x] == nil) then
                this.list.map[x] = {}
            end
            if ((this.list.map[x][y] == nil) or (this.list.map[x][y] >= 0)) then
                this.list.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

-- Refresh all chunks near a single player. Cyles through all connected players.
local function refresh_player_area()
    local player_index = get_next_player()
    if (player_index and game.connected_players[player_index]) then
        local player = game.connected_players[player_index]

        if (not player.character) then
            return
        end

        local this_surface_index = Surface.get_surface_index()

        if (player.surface.index ~= this_surface_index) then
            return
        end

        refresh_area(player.position, 4, 0)
    end
end

-- Gets the next chunk the array map and checks to see if it has timed out.
-- Adds it to the removal list if it has.
local function get_next_chunk()
    local this_surface_index = Surface.get_surface_index()
    local surface = game.get_surface(this_surface_index)
    if not surface or not surface.valid then
        debug('get_next_chunk - Surface was not valid?')
        return
    end

    -- Make sure we have a valid iterator!
    if (not this.settings.chunk_iter or not this.settings.chunk_iter.valid) then
        this.settings.chunk_iter = surface.get_chunks()
    end

    local next_chunk = this.settings.chunk_iter()

    -- Check if we reached the end
    if (not next_chunk) then
        this.settings.chunk_iter = surface.get_chunks()
        next_chunk = this.settings.chunk_iter()
    end

    -- Do we have it in our map?
    if (not this.list.map[next_chunk.x] or not this.list.map[next_chunk.x][next_chunk.y]) then
        return -- Chunk isn't in our map so we don't care?
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = this.list.map[next_chunk.x][next_chunk.y]
    if ((c_timer ~= nil) and (c_timer >= 0) and ((c_timer + this.settings.timeout_ticks) < game.tick)) then
        -- Check chunk actually exists
        if (surface.is_chunk_generated({ x = next_chunk.x, y = next_chunk.y })) then
            this.list.removal_list[#this.list.removal_list + 1] = { pos = { x = next_chunk.x, y = next_chunk.y }, force = false }
            this.list.map[next_chunk.x][next_chunk.y] = nil
        end
    end
end

-- Remove all chunks at same time to reduce impact to FPS/UPS
local function try_remove_chunks()
    local this_surface_index = Surface.get_surface_index()
    local surface = game.get_surface(this_surface_index)
    if not surface or not surface.valid then
        debug('try_remove_chunks - Surface was not valid?')
        return
    end
    local tick = 5

    for key, c_remove in pairs(this.list.removal_list) do
        tick = tick + 6
        local c_pos = c_remove.pos

        -- Confirm chunk is still expired
        if (not this.list.map[c_pos.x] or not this.list.map[c_pos.x][c_pos.y]) then
            -- If it is FORCE removal, then remove it regardless of pollution.
            if (c_remove.force) then
                -- If it is a normal timeout removal, don't do it if there is pollution in the chunk.
                if not this.settings.task_remover then
                    surface.delete_chunk(c_pos)
                else
                    Task.set_timeout_in_ticks(tick, clear_chunk_token, { chunk = c_pos, surface_index = surface.index })
                end
            elseif this.settings.pollution_enabled and (surface.get_pollution({ c_pos.x * 32, c_pos.y * 32 }) > 0) then
                -- Else delete the chunk
                this.list.map[c_pos.x][c_pos.y] = game.tick
            else
                if not this.settings.task_remover then
                    surface.delete_chunk(c_pos)
                else
                    Task.set_timeout_in_ticks(tick, clear_chunk_token, { chunk = c_pos, surface_index = surface.index })
                end
            end
        end

        -- Remove entry
        this.list.removal_list[key] = nil
    end

    -- MUST GET A NEW CHUNK ITERATOR ON DELETE CHUNK!
    this.settings.chunk_iter = nil
    this.settings.world_eater_iter = nil
end

local function remove_chunks()
    local this_surface_index = Surface.get_surface_index()
    local surface = game.get_surface(this_surface_index)
    if not surface or not surface.valid then
        debug('remove_chunks - Surface was not valid?')
        return
    end

    -- Make sure we have a valid iterator!
    if (not this.settings.world_eater_iter or not this.settings.world_eater_iter.valid) then
        this.settings.world_eater_iter = surface.get_chunks()
    end

    local next_chunk = this.settings.world_eater_iter()

    -- Check if we reached the end
    if (not next_chunk) then
        this.settings.world_eater_iter = surface.get_chunks()
        next_chunk = this.settings.world_eater_iter()
    end

    -- Do we have it in our map?
    if (not this.list.map[next_chunk.x] or not this.list.map[next_chunk.x][next_chunk.y]) then
        return -- Chunk isn't in our map so we don't care?
    end
    -- If the chunk isn't marked permament, then check if we can remove it
    local c_timer = this.list.map[next_chunk.x][next_chunk.y]
    if (c_timer == -1) then
        local area =
        {
            left_top = { next_chunk.area.left_top.x - 8, next_chunk.area.left_top.y - 8 },
            right_bottom = { next_chunk.area.right_bottom.x + 8, next_chunk.area.right_bottom.y + 8 }
        }

        local ents = surface.find_entities_filtered { area = area, force = { 'enemy', 'neutral' }, invert = true }
        local total_count = #ents
        local has_last_user_set = false

        local t_type =
        {
            ['character'] = true,
            ['construction-robot'] = true,
            ['logistic-robot'] = true
        }

        if (total_count > 0) then
            for _, v in pairs(ents) do
                if (v.last_user or t_type[v.type]) then
                    has_last_user_set = true
                    break -- This means we're done checking this chunk.
                end
            end

            -- If all entities found have no last user, then KILL all entities!
            if not has_last_user_set then
                for _, v in pairs(ents) do
                    if (v and v.valid) then
                        v.die(nil)
                    end
                end
                -- notify_all_players(cleaner .. next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep - ENTITIES FOUND")
                this.list.map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.
            end
        else
            -- notify_all_players(cleaner .. next_chunk.x .. "," .. next_chunk.y .. " WorldEaterSingleStep - NO ENTITIES FOUND")
            this.list.map[next_chunk.x][next_chunk.y] = game.tick -- Set the timer on it.
        end
    end
end


local function remove_chunks_forced()
    local this_surface_index = Surface.get_surface_index()
    local surface = game.get_surface(this_surface_index)
    if not surface or not surface.valid then
        debug('remove_chunks_forced - Surface was not valid?')
        return
    end

    notify_all_players(cleaner .. 'Manual map cleanup in progress - forced!')

    local chunks = surface.get_chunks()
    local tick = 0

    local chunks_to_remove = {}

    for chunk in chunks do
        local can_delete = true
        -- Do we have it in our map?
        if surface.is_chunk_generated(chunk) then
            local area =
            {
                left_top = { chunk.area.left_top.x - 64, chunk.area.left_top.y - 64 },
                right_bottom = { chunk.area.right_bottom.x + 64, chunk.area.right_bottom.y + 64 }
            }

            local ents = surface.find_entities_filtered { area = area, force = { 'neutral', 'enemy' }, invert = true }
            local total_count = #ents

            if (total_count > 0) then
                for _, v in pairs(ents) do
                    if (v.last_user) then
                        can_delete = false
                    end
                    if v.type == 'character' then
                        can_delete = false
                    end
                end

                if can_delete then
                    chunks_to_remove[#chunks_to_remove + 1] = chunk
                    -- Task.set_timeout_in_ticks(tick, clear_chunk_token, { chunk = chunk, surface_index = surface.index })
                    -- surface.delete_chunk(chunk)
                end
            else
                -- surface.delete_chunk(chunk)
                chunks_to_remove[#chunks_to_remove + 1] = chunk
                -- Task.set_timeout_in_ticks(tick, clear_chunk_token, { chunk = chunk, surface_index = surface.index })
            end
        end

        if chunks_to_remove and #chunks_to_remove >= 10 then
            tick = tick + 2
            Task.set_timeout_in_ticks(tick, clear_chunk_token,
                { chunk = chunks_to_remove, surface_index = surface.index })

            chunks_to_remove = {}
        end
    end
end

-- Marks a safe area around a TILE position to be relatively permanent.
local function mark_area_safe_tiles(pos, chunk_radius, permanent)
    local c_pos = chunk_from_tile_pos(pos)
    if not c_pos then
        return
    end

    area_is_safe(c_pos, chunk_radius, permanent)
end

-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
local function on_tick()
    local tick = game.tick
    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((tick % (30)) == 2) then
        refresh_player_area()
    end

    -- Catch force remove flag
    if (tick == this.settings.force_removal_flag + 60) then
        notify_all_players(cleaner .. 'Manual map cleanup in progress!')
    end

    if (tick == this.settings.force_removal_flag + (60 * 30 + 60)) then
        try_remove_chunks()
        notify_all_players(cleaner .. 'Manual map cleanup done.')
        return
    end

    -- Every tick, check a few points in the 2d array of the only active surface According to /measured-command this
    -- shouldn't take more than 0.1ms on average
    for _ = 1, 20 do
        get_next_chunk()
    end

    if (not this.settings.remover_disabled) then
        remove_chunks()
    end

    -- Allow enable/disable of auto cleanup, can change during runtime.
    local interval_ticks = this.settings.timeout_ticks
    -- Send a broadcast warning before it happens.
    if ((tick % interval_ticks) == interval_ticks - (60 * 30 + 1)) then
        if (#this.list.removal_list > 100) then
            notify_all_players(cleaner .. 'Automated map cleanup in progress!')
        end
    end

    -- Delete all listed chunks across all active surfaces
    if ((tick % interval_ticks) == interval_ticks - 1) then
        if (#this.list.removal_list > 100) then
            try_remove_chunks()
            notify_all_players(cleaner .. 'Automated map cleanup done.')
        end
    end
end

function Public.on_chunk_generated(event)
    local c_pos = chunk_from_tile_pos(event.area.left_top)

    -- Surface must be "added" first.
    if (this.settings == nil) then
        return
    end

    -- If this is the first chunk in that row:
    if (this.list.map[c_pos.x] == nil) then
        this.list.map[c_pos.x] = {}
    end

    -- Only update it if it isn't already set!
    if (this.list.map[c_pos.x][c_pos.y] == nil) then
        this.list.map[c_pos.x][c_pos.y] = game.tick
    end
end

function Public.trigger()
    this.settings.force_removal_flag = game.tick
end

-- Mark an area for "immediate" forced removal
function Public.mark_base_for_removal_forced(pos, chunk_radius)
    local c_pos = chunk_from_tile_pos(pos)
    for i = -chunk_radius, chunk_radius do
        local x = c_pos.x + i
        for k = -chunk_radius, chunk_radius do
            local y = c_pos.y + k

            if (this.list.map[x] ~= nil) then
                this.list.map[x][y] = nil
            end
            this.list.removal_list[#this.list.removal_list + 1] = { pos = { x = x, y = y }, force = true }
        end
        if (table_size(this.list.map[x]) == 0) then
            this.list.map[x] = nil
        end
    end
end

-- Downgrades permanent flag to semi-permanent.
function Public.mark_base_for_removal_non_forced(pos, chunk_radius)
    local c_pos = chunk_from_tile_pos(pos)
    for i = -chunk_radius, chunk_radius do
        local x = c_pos.x + i
        for k = -chunk_radius, chunk_radius do
            local y = c_pos.y + k

            if (this.list.map[x] and this.list.map[x][y] and (this.list.map[x][y] == -2)) then
                this.list.map[x][y] = -1
            end
        end
    end
end

-- Refreshes timers on a chunk containing position
function Public.refresh_chunk_timer(pos, bonus_time)
    local c_pos = chunk_from_tile_pos(pos)

    if (this.list.map[c_pos.x] == nil) then
        this.list.map[c_pos.x] = {}
    end
    if (this.list.map[c_pos.x][c_pos.y] >= 0) then
        this.list.map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function Public.on_sector_scanned(event)
    local this_surface_index = Surface.get_surface_index()
    local radar = event.radar
    local surface = radar.surface

    if (surface.index ~= this_surface_index) then
        return
    end

    refresh_area(radar.position, 14, 0)
end

function Public.toggle_chunk_removal(state)
    this.settings.enabled = state or false
end

Event.add(
    defines.events.on_built_entity,
    function (event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        if this.settings.enabled then
            local surface_index = Surface.get_surface_index()

            if entity.surface.index ~= surface_index then
                return
            end
            mark_area_safe_tiles(entity.position, 2, false)
        end
    end
)

Event.add(
    defines.events.on_player_built_tile,
    function (event)
        local surface_index = event.surface_index
        local tiles = event.tiles

        if this.settings.enabled then
            local this_surface_index = Surface.get_surface_index()

            if surface_index ~= this_surface_index then
                return
            end

            for _, tile in pairs(tiles) do
                mark_area_safe_tiles(tile.position, 2, false)
            end
        end
    end
)

Event.add(
    defines.events.script_raised_built,
    function (event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        if this.settings.enabled then
            local this_surface_index = Surface.get_surface_index()

            if entity.surface.index ~= this_surface_index then
                return
            end

            mark_area_safe_tiles(entity.position, 2, false)
        end
    end
)

Event.add(
    defines.events.on_tick,
    function ()
        if this.settings.enabled then
            on_tick()
        end
    end
)

Event.add(
    defines.events.on_robot_built_entity,
    function (event)
        local entity = event.entity
        if this.settings.enabled then
            local surface_index = Surface.get_surface_index()

            if (entity.surface.index ~= surface_index) then
                return
            end
            mark_area_safe_tiles(entity.position, 2, false)
        end
    end
)

Event.add(
    defines.events.on_sector_scanned,
    function (event)
        if this.settings.enabled then
            Public.on_sector_scanned(event)
        end
    end
)

Event.on_init(
    function ()
        local position = { x = 0, y = 0 }
        mark_area_safe_tiles(position, 2, true)
    end
)


Commands.new('chunk_removal_run', 'Chunk removal')
    :require_role('remove_chunks')
    :callback(function (player)
        player.print('[Chunk removal] - Initiated force removal of chunks.')
        remove_chunks_forced()
    end
    )

Commands.new('chunk_removal_debug', 'Chunk removal')
    :require_role('remove_chunks')
    :callback(function (player)
        if this.settings._debug then
            this.settings._debug = false
            player.print('[Chunk removal] - Debug messages are now disabled.')
        else
            this.settings._debug = true
            player.print('[Chunk removal] - Debug messages are now enabled.')
        end
    end
    )

Commands.new('chunk_removal_toggle_task', 'Chunk removal')
    :require_role('remove_chunks')
    :callback(function (player)
        if this.settings.task_remover then
            this.settings.task_remover = false
            player.print('[Chunk removal] - Tasks are now disabled when removing chunks.')
        else
            this.settings.task_remover = true
            player.print('[Chunk removal] - Tasks are now enabled when removing chunks.')
        end
    end
    )

Commands.new('chunk_removal_pollution_enabled', 'Chunk removal')
    :require_role('remove_chunks')
    :callback(function (player)
        if this.settings.pollution_enabled then
            this.settings.pollution_enabled = false
            player.print('[Chunk removal] - Pollution is now disabled when removing chunks.')
        else
            this.settings.pollution_enabled = true
            player.print('[Chunk removal] - Pollution is now enabled when removing chunks.')
        end
    end
    )

Commands.new('chunk_removal_enabled', 'Chunk removal')
    :require_role('remove_chunks')
    :callback(function (player)
        if this.settings.enabled then
            this.settings.enabled = false
            player.print('[Chunk removal] - is now disabled.')
        else
            this.settings.enabled = true
            player.print('[Chunk removal] - is now enabled.')
        end
    end
    )

Public.mark_area_safe_tiles = mark_area_safe_tiles

return Public
