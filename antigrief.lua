--antigrief things made by mewmew
--rewritten by gerkiz--
--as an admin, write either /trust or /untrust and the players name in the chat to grant/revoke immunity from protection

local Event = require 'utils.event'
local session = require 'utils.session_data'
local Global = require 'utils.global'
local Utils = require 'utils.core'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'

local Public = {}
local match = string.match
local capsule_bomb_threshold = 8

local format = string.format

local this = {
    landfill_history = {},
    capsule_history = {},
    friendly_fire_history = {},
    mining_history = {},
    corpse_history = {},
    cancel_crafting_history = {},
    whitelist_types = {},
    players_warned = {},
    log_tree_harvest = false,
    do_not_check_trusted = true,
    protect_entities = true,
    enable_autokick = true,
    enable_autoban = false
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
    ['artillery-targeting-remote'] = true,
    ['poison-capsule'] = true,
    ['cluster-grenade'] = true,
    ['grenade'] = true,
    ['atomic-bomb'] = true,
    ['cliff-explosives'] = true,
    ['rocket'] = true
}

local protected = {
    ['reactor'] = true,
    ['roboport'] = true,
    ['rocket-silo'] = true,
    ['solar-panel'] = true,
    ['generator'] = true,
    ['splitter'] = true,
    ['transport-belt'] = true,
    ['underground-belt'] = true,
    ['assembling-machine'] = true,
    ['storage-tank'] = true,
    ['pump'] = true,
    ['mining-drill'] = true,
    ['market'] = true,
    ['accumulator'] = true,
    ['ammo-turret'] = true,
    ['artillery-turret'] = true,
    ['artillery-wagon'] = true,
    ['beacon'] = true,
    ['boiler'] = true,
    ['burner-generator'] = true,
    ['car'] = true,
    ['cargo-wagon'] = true,
    ['constant-combinator'] = true,
    ['straight-rail'] = true,
    ['curved-rail'] = true,
    ['decider-combinator'] = true,
    ['electric-pole'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true,
    ['fluid-wagon'] = true,
    ['furnace'] = true,
    ['gate'] = true,
    ['heat-interface'] = true,
    ['heat-pipe'] = true,
    ['inserter'] = true,
    ['lab'] = true,
    ['lamp'] = true,
    ['loader'] = true,
    ['locomotive'] = true,
    ['logistic-robot'] = true,
    ['offshore-pump'] = true,
    ['pipe-to-ground'] = true,
    ['pipe'] = true
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local function increment(t, k, v)
    t[k][#t[k] + 1] = (v or 1)
end

local function get_entities(item_name, entities)
    local set = {}
    for i = 1, #entities do
        local e = entities[i]
        local name = e.name

        if name ~= item_name and name ~= 'entity-ghost' then
            local count = set[name]
            if count then
                set[name] = count + 1
            else
                set[name] = 1
            end
        end
    end

    local list = {}
    local i = 1
    for k, v in pairs(set) do
        list[i] = v
        i = i + 1
        list[i] = ' '
        i = i + 1
        list[i] = k
        i = i + 1
        list[i] = ', '
        i = i + 1
    end
    list[i - 1] = nil

    return table.concat(list)
end

local function damage_player(player, kill)
    local msg = ' tried to destroy our base, but it backfired!'
    if player.character then
        if kill then
            player.character.die('enemy')
            game.print(player.name .. msg, Color.yellow)
            return
        end
        player.character.health = player.character.health - math.random(50, 100)
        player.character.surface.create_entity({name = 'water-splash', position = player.position})
        local messages = {
            'Ouch.. That hurt! Better be careful now.',
            'Just a fleshwound.',
            'Better keep those hands to yourself or you might loose them.'
        }
        player.print(messages[math.random(1, #messages)], Color.yellow)
        if player.character.health <= 0 then
            player.character.die('enemy')
            game.print(player.name .. msg, Color.yellow)
            return
        end
    end
end

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
            Utils.action_warning('{Nuke}', player.name .. ' tried to equip nukes but was not trusted.')
            damage_player(player)
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if match(player.name, '^[Ili1|]+$') then
        Server.ban_sync(player.name, '', '<script>') -- No reason given, to not give them any hints to change their name
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

    if not this.landfill_history[player.index] then
        this.landfill_history[player.index] = {}
    end

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
    increment(this.landfill_history, player.index, str)
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
    local item = event.item

    if not item then
        return
    end

    local name = item.name

    local position = event.position
    local x, y = position.x, position.y
    local surface = player.surface

    if ammo_names[name] then
        if
            surface.count_entities_filtered({force = 'enemy', area = {{x - 10, y - 10}, {x + 10, y + 10}}, limit = 1}) >
                0
         then
            return
        end

        local count = 0
        local entities =
            player.surface.find_entities_filtered {force = player.force, area = {{x - 5, y - 5}, {x + 5, y + 5}}}

        for i = 1, #entities do
            local e = entities[i]
            local entity_name = e.name
            if entity_name ~= name and entity_name ~= 'entity-ghost' and not blacklisted_types[e.type] then
                count = count + 1
            end
        end

        if count <= capsule_bomb_threshold then
            return
        end

        local msg = format(player.name .. ' damaged: %s with: %s', get_entities(name, entities), name)

        if this.players_warned[event.player_index] == 2 then
            if this.enable_autoban then
                Server.ban_sync(
                    player.name,
                    format(
                        'Damaged: %s with: %s. This action was performed automatically. Visit getcomfy.eu/discord for forgiveness',
                        get_entities(name, entities),
                        name
                    ),
                    '<script>'
                )
            end
        elseif this.players_warned[event.player_index] == 1 then
            this.players_warned[event.player_index] = true
            if this.enable_autokick then
                game.kick_player(player, msg)
            end
        else
            this.players_warned[event.player_index] = 1
            damage_player(player, true)
            Utils.print_to(nil, msg)
        end
        if not this.capsule_history[player.index] then
            this.capsule_history[player.index] = {}
        end
        if #this.capsule_history[player.index] > 100 then
            this.capsule_history[player.index] = {}
        end

        local t = math.abs(math.floor((game.tick) / 3600))
        local str = '[' .. t .. '] '
        str = str .. msg
        str = str .. ' at X:'
        str = str .. math.floor(position.x)
        str = str .. ' Y:'
        str = str .. math.floor(position.y)
        str = str .. ' '
        str = str .. 'surface:' .. player.surface.index
        increment(this.capsule_history, player.index, str)
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

        if not this.friendly_fire_history[cause.player.index] then
            this.friendly_fire_history[cause.player.index] = {}
        end

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
        increment(this.friendly_fire_history, player.index, str)
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
            if not this.friendly_fire_history[cause.player.index] then
                this.friendly_fire_history[cause.player.index] = {}
            end
            if #this.friendly_fire_history[cause.player.index] > 100 then
                this.friendly_fire_history[cause.player.index] = {}
            end
            increment(this.friendly_fire_history, cause.player.index, str)
        else
            if not this.friendly_fire_history[99999] then
                this.friendly_fire_history[99999] = {}
            end
            if #this.friendly_fire_history[99999] > 100 then
                this.friendly_fire_history[99999] = {}
            end
            increment(this.friendly_fire_history, 99999, str)
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
        if not this.mining_history[player.index] then
            this.mining_history[player.index] = {}
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
        increment(this.mining_history, player.index, str)

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
    if not this.mining_history[player.index] then
        this.mining_history[player.index] = {}
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
    increment(this.mining_history, player.index, str)
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
        Utils.action_warning('{Corpse}', player.name .. ' is looting ' .. corpse_owner.name .. '´s body.')
        if not this.corpse_history[player.index] then
            this.corpse_history[player.index] = {}
        end
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
        increment(this.corpse_history, player.index, str)
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
        Utils.action_warning('{Corpse}', player.name .. ' has looted ' .. corpse_owner.name .. '´s body.')
        if not this.corpse_history[player.index] then
            this.corpse_history[player.index] = {}
        end
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
        increment(this.corpse_history, player.index, str)
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
                Utils.action_warning('{Capsule}', player.name .. ' equipped ' .. name .. ' but was not trusted.')
                damage_player(player)
            end
        end
    end
end

local function on_player_cancelled_crafting(event)
    local tracker = session.get_session_table()
    local player = game.players[event.player_index]

    local playtime = player.online_time
    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end

    local count = #event.items

    if playtime < 1296000 then
        if count > 40 then
            Utils.action_warning(
                '{Crafting}',
                player.name ..
                    ' canceled their craft of item ' .. event.recipe.name .. ' of total count ' .. count .. '.'
            )
            if not this.cancel_crafting_history[player.index] then
                this.cancel_crafting_history[player.index] = {}
            end
            if #this.cancel_crafting_history[player.index] > 100 then
                this.cancel_crafting_history[player.index] = {}
            end

            local t = math.abs(math.floor((game.tick) / 3600))
            local str = '[' .. t .. '] '
            str = str .. player.name .. ' canceled '
            str = str .. ' item ' .. event.recipe.name
            str = str .. ' count was a total of: ' .. count
            str = str .. ' at X:'
            str = str .. math.floor(player.position.x)
            str = str .. ' Y:'
            str = str .. math.floor(player.position.y)
            str = str .. ' '
            str = str .. 'surface:' .. player.surface.index
            increment(this.cancel_crafting_history, player.index, str)
        end
    end
end

local function protect_entities(event)
    local entity = event.entity

    local function is_protected(e)
        if protected[e.type] then
            return true
        end

        return false
    end

    if is_protected(entity) then
        entity.health = entity.health + event.final_damage_amount
    end
end

--- Protect entities from the player force
---@param event
local function on_entity_damaged(event)
    if not this.protect_entities then
        return
    end

    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if event.force.index ~= 1 then
        return
    end

    if entity.force.index ~= 1 then
        return
    end

    protect_entities(event)
end

--- Enabling this will protect all entities except for those in the not_protected table.
---@param boolean true/false
function Public.protect_entities(value)
    if value then
        this.protect_entities = value
    end
end

--- This will reset the table of this
function Public.reset_tables()
    this.landfill_history = {}
    this.capsule_history = {}
    this.friendly_fire_history = {}
    this.mining_history = {}
    this.corpse_history = {}
    this.cancel_crafting_history = {}
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
Event.add(defines.events.on_player_cancelled_crafting, on_player_cancelled_crafting)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)

return Public
