--antigrief things made by mewmew
--modified by gerkiz--
--as an admin, write either /trust or /untrust and the players name in the chat to grant/revoke immunity from protection

local Event = require 'utils.event'
local session = require 'utils.session_data'
local Server = require 'utils.server'
local Global = require 'utils.global'

local Public = {}

local this = {
    landfill_history = {
        ['unknown'] = {}
    },
    capsule_history = {
        ['unknown'] = {}
    },
    friendly_fire_history = {
        ['unknown'] = {}
    },
    mining_history = {
        ['unknown'] = {}
    },
    corpse_history = {
        ['unknown'] = {}
    },
    whitelist_types = {},
    log_tree_harvest = false,
    do_not_check_trusted = true
}

local blacklisted_types = {
    ['transport-belt'] = true,
    ['wall'] = true,
    ['underground-belt'] = true,
    ['inserter'] = true,
    ['land-mine'] = true,
    ['gate'] = true,
    ['lamp'] = true,
    ['mining-drill'] = true,
    ['splitter'] = true
}

local ammo_names = {
    ['poison-capsule'] = true,
    ['cluster-grenade'] = true,
    ['grenade'] = true,
    ['atomic-bomb'] = true,
    ['cliff-explosives'] = true
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local function on_marked_for_deconstruction(event)
    local tracker = session.get_session_table()
    local trusted = session.get_trusted_table()
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    if player.admin then
        return
    end
    if trusted[player.name] and this.do_not_check_trusted then
        return
    end

    local playtime = player.online_time
    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end
    if playtime < 2592000 then
        event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
        player.print('You have not grown accustomed to this technology yet.', {r = 0.22, g = 0.99, b = 0.99})
    end
end

local function on_player_ammo_inventory_changed(event)
    local tracker = session.get_session_table()
    local trusted = session.get_trusted_table()
    local player = game.players[event.player_index]
    if player.admin then
        return
    end
    if trusted[player.name] and this.do_not_check_trusted then
        return
    end

    local playtime = player.online_time
    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end
    if playtime < 1296000 then
        local nukes = player.remove_item({name = 'atomic-bomb', count = 1000})
        if nukes > 0 then
            player.print('You have not grown accustomed to this technology yet.', {r = 0.22, g = 0.99, b = 0.99})
            Server.to_discord_bold(
                table.concat {'** [Nuke] ' .. player.name .. ' tried to equip nukes but was not trusted. **'}
            )
            game.print(
                '[Nuke] ' .. player.name .. ' tried to equip nukes but was not trusted.',
                {r = 0.22, g = 0.99, b = 0.99}
            )
            player.character.health = 0
        end
    end
end

local function on_player_built_tile(event)
    local placed_tiles = event.tiles
    if
        placed_tiles[1].old_tile.name ~= 'deepwater' and placed_tiles[1].old_tile.name ~= 'water' and
            placed_tiles[1].old_tile.name ~= 'water-green'
     then
        return
    end
    local player = game.players[event.player_index]

    --landfill history--

    if #this.landfill_history[player.index] > 100 then
        this.landfill_history[player.index] = {}
    end
    local t = math.abs(math.floor((game.tick) / 3600))
    local str = '[' .. t .. '] '
    str = str .. player.name .. ' at X:'
    str = str .. placed_tiles[1].position.x
    str = str .. ' Y:'
    str = str .. placed_tiles[1].position.y
    str = str .. ' '
    str = str .. 'surface:' .. event.surface.index
    this.landfill_history[player.index][#this.landfill_history[player.index] + 1] = str
end

local function on_built_entity(event)
    local tracker = session.get_session_table()
    local trusted = session.get_trusted_table()
    if game.tick < 1296000 then
        return
    end

    if event.created_entity.type == 'entity-ghost' then
        local player = game.players[event.player_index]

        if player.admin then
            return
        end
        if trusted[player.name] and this.do_not_check_trusted then
            return
        end

        local playtime = player.online_time
        if tracker[player.name] then
            playtime = player.online_time + tracker[player.name]
        end

        if playtime < 432000 then
            event.created_entity.destroy()
            player.print('You have not grown accustomed to this technology yet.', {r = 0.22, g = 0.99, b = 0.99})
        end
    end
end

--Capsule History and Antigrief
local function on_player_used_capsule(event)
    local trusted = session.get_trusted_table()
    local player = game.players[event.player_index]
    if player.admin then
        return
    end
    if trusted[player.name] and this.do_not_check_trusted then
        return
    end
    local position = event.position

    local item = event.item

    if not item then
        return
    end

    local name = item.name

    if ammo_names[name] then
        if #this.capsule_history[player.index] > 100 then
            this.capsule_history[player.index] = {}
        end

        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        str = str .. player.name .. ' used ' .. name
        str = str .. ' at X:'
        str = str .. math.floor(position.x)
        str = str .. ' Y:'
        str = str .. math.floor(position.y)
        str = str .. ' '
        str = str .. 'surface:' .. player.surface.index
        this.capsule_history[player.index][#this.capsule_history[player.index] + 1] = str
    end
end

--Friendly Fire History
local function on_entity_died(event)
    local cause = event.cause
    local name

    if
        (cause and cause.name == 'character' and cause.player and cause.force.name == event.entity.force.name and
            not blacklisted_types[event.entity.type])
     then
        local player = cause.player
        name = player.name

        if #this.friendly_fire_history[cause.player.index] > 100 then
            this.friendly_fire_history[cause.player.index] = {}
        end

        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        str = str .. name .. ' destroyed '
        str = str .. event.entity.name
        str = str .. ' at X:'
        str = str .. math.floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. math.floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index

        this.friendly_fire_history[cause.player.index][#this.friendly_fire_history[cause.player.index] + 1] = str
    elseif not blacklisted_types[event.entity.type] and this.whitelist_types[event.entity.type] then
        if cause then
            if cause.force.name ~= 'player' then
                return
            end
        end
        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        if cause and cause.name == 'character' and cause.player then
            str = str .. cause.player.name .. ' destroyed '
        else
            str = str .. 'someone destroyed '
        end
        str = str .. event.entity.name
        str = str .. ' at X:'
        str = str .. math.floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. math.floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index

        if cause and cause.name == 'character' and cause.player then
            if #this.friendly_fire_history[cause.player.index] > 100 then
                this.friendly_fire_history[cause.player.index] = {}
            end
            this.friendly_fire_history[cause.player.index][#this.friendly_fire_history[cause.player.index] + 1] = str
        else
            if #this.friendly_fire_history['unknown'] > 100 then
                this.friendly_fire_history['unknown'] = {}
            end
            this.friendly_fire_history['unknown'][#this.friendly_fire_history['unknown'] + 1] = str
        end
    end
end

--Mining Thieves History
local function on_player_mined_entity(event)
    local player = game.players[event.player_index]

    if not player then
        return
    end

    if this.whitelist_types[event.entity.type] then
        if #this.mining_history[player.index] > 100 then
            this.mining_history[player.index] = {}
        end
        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        str = str .. player.name .. ' mined '
        str = str .. event.entity.name
        str = str .. ' at X:'
        str = str .. math.floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. math.floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index

        this.mining_history[player.index][#this.mining_history[player.index] + 1] = str
        return
    end
    if not event.entity.last_user then
        return
    end
    if event.entity.last_user.name == player.name then
        return
    end
    if event.entity.force.name ~= player.force.name then
        return
    end
    if blacklisted_types[event.entity.type] then
        return
    end

    if #this.mining_history[player.index] > 100 then
        this.mining_history[player.index] = {}
    end

    local t = math.abs(math.floor((game.tick) / 3600))
    local str = '[' .. t .. '] '
    str = str .. player.name .. ' mined '
    str = str .. event.entity.name
    str = str .. ' at X:'
    str = str .. math.floor(event.entity.position.x)
    str = str .. ' Y:'
    str = str .. math.floor(event.entity.position.y)
    str = str .. ' '
    str = str .. 'surface:' .. event.entity.surface.index

    this.mining_history[player.index][#this.mining_history[player.index] + 1] = str
end

local function on_gui_opened(event)
    if not event.entity then
        return
    end
    if event.entity.name ~= 'character-corpse' then
        return
    end
    local player = game.players[event.player_index]
    local corpse_owner = game.players[event.entity.character_corpse_player_index]
    if not corpse_owner then
        return
    end

    if corpse_owner.force.name ~= player.force.name then
        return
    end

    local corpse_content = #event.entity.get_inventory(defines.inventory.character_corpse)
    if corpse_content <= 0 then
        return
    end

    if player.name ~= corpse_owner.name then
        game.print(player.name .. ' is looting ' .. corpse_owner.name .. '´s body.', {r = 0.85, g = 0.85, b = 0.85})
        Server.to_discord_bold(
            table.concat {'** [Corpse] ' .. player.name .. ' is looting ' .. corpse_owner.name .. '´s body. **'}
        )
        if #this.corpse_history[player.index] > 100 then
            this.corpse_history[player.index] = {}
        end

        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        str = str .. player.name .. ' opened '
        str = str .. corpse_owner.name .. ' body'
        str = str .. ' at X:'
        str = str .. math.floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. math.floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index

        this.corpse_history[player.index][#this.corpse_history[player.index] + 1] = str
    end
end

local function on_pre_player_mined_item(event)
    if event.entity.name ~= 'character-corpse' then
        return
    end
    local player = game.players[event.player_index]
    local corpse_owner = game.players[event.entity.character_corpse_player_index]
    if not corpse_owner then
        return
    end
    local entity = event.entity
    if not entity then
        return
    end
    local corpse_content = #entity.get_inventory(defines.inventory.character_corpse)
    if corpse_content <= 0 then
        return
    end
    if corpse_owner.force.name ~= player.force.name then
        return
    end
    if player.name ~= corpse_owner.name then
        game.print(player.name .. ' has looted ' .. corpse_owner.name .. '´s body.', {r = 0.85, g = 0.85, b = 0.85})
        Server.to_discord_bold(
            table.concat {'[Corpse] ' .. player.name .. ' has looted ' .. corpse_owner.name .. '´s body.'}
        )
        if #this.corpse_history[player.index] > 100 then
            this.corpse_history[player.index] = {}
        end

        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        str = str .. player.name .. ' mined '
        str = str .. corpse_owner.name .. ' body'
        str = str .. ' at X:'
        str = str .. math.floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. math.floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index

        this.corpse_history[player.index][#this.corpse_history[player.index] + 1] = str
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    if not this.mining_history[player.index] then
        this.mining_history[player.index] = {}
    end
    if not this.capsule_history[player.index] then
        this.capsule_history[player.index] = {}
    end
    if not this.friendly_fire_history[player.index] then
        this.friendly_fire_history[player.index] = {}
    end
    if not this.landfill_history[player.index] then
        this.landfill_history[player.index] = {}
    end
    if not this.corpse_history[player.index] then
        this.corpse_history[player.index] = {}
    end
end

local function on_player_cursor_stack_changed(event)
    local tracker = session.get_session_table()
    local trusted = session.get_trusted_table()
    local player = game.players[event.player_index]
    if player.admin then
        return
    end
    if trusted[player.name] and this.do_not_check_trusted then
        return
    end

    local item = player.cursor_stack

    if not item then
        return
    end

    if not item.valid_for_read then
        return
    end

    local name = item.name

    local playtime = player.online_time
    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end

    if playtime < 1296000 then
        if ammo_names[name] then
            local item_to_remove = player.remove_item({name = name, count = 1000})
            if item_to_remove > 0 then
                player.print('You have not grown accustomed to this technology yet.', {r = 0.22, g = 0.99, b = 0.99})
                Server.to_discord_bold(
                    table.concat {
                        '** [Capsule] ' .. player.name .. ' equipped ' .. name .. ' but was not trusted. **'
                    }
                )
                game.print(
                    '[Capsule] ' .. player.name .. ' equipped ' .. name .. ' but was not trusted.',
                    {r = 0.22, g = 0.99, b = 0.99}
                )
                player.character.health = 0
            end
        end
    end
end

function Public.cursor_stack(event, pattern)
    local player = game.get_player(event.player_index)
    local stack = player.cursor_stack
    return stack and stack.valid_for_read and stack.name:match(pattern)
end

--- Enable this to log when trees are destroyed
---@param value boolean
function Public.log_tree_harvest(value)
    if value then
        this.log_tree_harvest = value
    end
end

--- Add entity type to the whitelist so it gets logged.
---@param key string
---@param value string
function Public.whitelist_types(key, value)
    if key and value then
        this.whitelist_types[key] = value
    end
end

--- If the event should also check trusted players
---@param value string
function Public.do_not_check_trusted(value)
    if value then
        this.do_not_check_trusted = value
    end
end

--- Returns the table
---@param key string
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)

return Public
