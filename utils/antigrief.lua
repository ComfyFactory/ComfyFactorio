--antigrief things made by mewmew
--rewritten by gerkiz--
--as an admin, write either /trust or /untrust and the players name in the chat to grant/revoke immunity from protection

local Event = require 'utils.event'
local Session = require 'utils.datastore.session_data'
local Global = require 'utils.global'
local Utils = require 'utils.core'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Jail = require 'utils.datastore.jail_data'
local FancyTime = require 'utils.tools.fancy_time'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Discord = require 'utils.discord_handler'

local Public = {}
local match = string.match
local de = defines.events
local sub = string.sub
local format = string.format
local floor = math.floor
local random = math.random
local abs = math.abs

local this = {
    enabled = true,
    max_count_decon = 1500,
    landfill_history = {},
    capsule_history = {},
    friendly_fire_history = {},
    mining_history = {},
    whitelist_mining_history = {},
    corpse_history = {},
    message_history = {},
    cancel_crafting_history = {},
    deconstruct_history = {},
    scenario_history = {},
    whitelist_types = {},
    permission_group_editing = {},
    players_warned = {},
    damage_history = {},
    punish_cancel_craft = false,
    do_not_check_trusted = false,
    enable_autokick = false,
    enable_autoban = false,
    enable_jail = true,
    enable_capsule_warning = true,
    enable_capsule_cursor_warning = true,
    required_playtime = 2592000,
    capsule_bomb_threshold = 8,
    damage_entity_threshold = 20,
    enable_jail_when_decon = true,
    enable_jail_on_long_texts = true,
    filtered_types_on_decon = {},
    decon_surface_blacklist = 'nauvis',
    players_warn_when_decon = {},
    players_warn_on_long_texts = {},
    on_cancelled_deconstruction = {tick = 0, count = 0},
    limit = 2000,
    admin_button_validation = {}
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

local chests = {
    ['container'] = true,
    ['logistic-container'] = true
}

-- Clears the player from players_warn_when_decon tbl.
local clear_player_decon_warnings =
    Token.register(
    function(event)
        local player_index = event.player_index
        if this.players_warn_when_decon[player_index] then
            this.players_warn_when_decon[player_index] = nil
        end
    end
)

-- Clears the player from players_warn_on_long_texts tbl.
local clear_players_warn_on_long_texts =
    Token.register(
    function(event)
        local player_index = event.player_index
        if this.players_warn_on_long_texts[player_index] then
            this.players_warn_on_long_texts[player_index] = nil
        end
    end
)

Global.register(
    this,
    function(t)
        this = t
    end
)

local function increment(t, v)
    t[#t + 1] = (v or 1)
end

-- Removes the first 100 entries of a table
local function overflow(t)
    table.remove(t, 1)
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

local function damage_player(player, kill, print_to_all)
    local msg = ' tried to destroy our base, but it backfired!'
    if player.character then
        if kill then
            player.character.die('enemy')
            if print_to_all then
                game.print(player.name .. msg, Color.yellow)
            end
            return
        end
        player.character.health = player.character.health - random(50, 100)
        player.character.surface.create_entity({name = 'water-splash', position = player.position})
        local messages = {
            'Ouch.. That hurt! Better be careful now.',
            'Just a fleshwound.',
            'Better keep those hands to yourself or you might loose them.'
        }
        player.print(messages[random(1, #messages)], Color.yellow)
        if player.character.health <= 0 then
            player.character.die('enemy')
            game.print(player.name .. msg, Color.yellow)
            return
        end
    end
end

local function do_action(player, prefix, msg, ban_msg, kill)
    if not prefix or not msg or not ban_msg then
        return
    end
    kill = kill or false

    damage_player(player, kill)
    Utils.action_warning(prefix, msg)

    if this.players_warned[player.index] == 2 then
        if this.enable_autoban then
            Server.ban_sync(player.name, ban_msg, '<script>')
        end
    elseif this.players_warned[player.index] == 1 then
        this.players_warned[player.index] = 2
        if this.enable_jail then
            Jail.try_ul_data(player, true, 'script')
        elseif this.enable_autokick then
            game.kick_player(player, msg)
        end
    else
        this.players_warned[player.index] = 1
    end
end

local function on_marked_for_deconstruction(event)
    if not this.enabled then
        return
    end

    if not event.player_index then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if Session.get_trusted_player(player) or this.do_not_check_trusted then
        return
    end

    local playtime = player.online_time
    if Session.get_session_player(player) then
        playtime = player.online_time + Session.get_session_player(player)
    end
    if playtime < this.required_playtime then
        event.entity.cancel_deconstruction(game.get_player(event.player_index).force.name)
        player.print('You have not grown accustomed to this technology yet.', {r = 0.22, g = 0.99, b = 0.99})
    end
end

local function on_player_ammo_inventory_changed(event)
    if not this.enabled then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.admin then
        return
    end
    if Session.get_trusted_player(player) or this.do_not_check_trusted then
        return
    end

    local playtime = player.online_time
    if Session.get_session_player(player) then
        playtime = player.online_time + Session.get_session_player(player)
    end
    if playtime < this.required_playtime then
        if this.enable_capsule_cursor_warning then
            local nukes = player.remove_item({name = 'atomic-bomb', count = 1000})
            if nukes > 0 then
                Utils.action_warning('[Nuke]', player.name .. ' tried to equip nukes but was not trusted.')
                damage_player(player)
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    if not this.enabled then
        if not Session.get_trusted_player(player) then
            Session.set_trusted_player(player)
        end
        return
    end

    if match(player.name, '^[Ili1|]+$') then
        Server.ban_sync(player.name, '', '<script>') -- No reason given, to not give them any hints to change their name
    end
end

local function on_player_built_tile(event)
    if not this.enabled then
        return
    end
    local placed_tiles = event.tiles
    if placed_tiles[1].old_tile.name ~= 'deepwater' and placed_tiles[1].old_tile.name ~= 'water' and placed_tiles[1].old_tile.name ~= 'water-green' then
        return
    end
    local player = game.get_player(event.player_index)

    local surface = event.surface_index

    --landfill history--

    if not this.landfill_history then
        this.landfill_history = {}
    end

    if this.limit > 0 and #this.landfill_history > this.limit then
        overflow(this.landfill_history)
    end
    local t = abs(floor((game.tick) / 60))
    local formatted = FancyTime.short_fancy_time(t)
    local str = '[' .. formatted .. '] '
    str = str .. player.name .. ' at X:'
    str = str .. placed_tiles[1].position.x
    str = str .. ' Y:'
    str = str .. placed_tiles[1].position.y
    str = str .. ' '
    str = str .. 'surface:' .. surface
    increment(this.landfill_history, str)
    Server.log_antigrief_data('landfill', str)
end

local function on_built_entity(event)
    if not this.enabled then
        return
    end

    local created_entity = event.created_entity

    if created_entity.type == 'entity-ghost' then
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        if player.admin then
            return
        end
        if Session.get_trusted_player(player) or this.do_not_check_trusted then
            return
        end

        local playtime = player.online_time
        if Session.get_session_player(player) then
            playtime = player.online_time + Session.get_session_player(player)
        end

        if playtime < this.required_playtime then
            created_entity.destroy()
            player.print('You have not grown accustomed to this technology yet.', {r = 0.22, g = 0.99, b = 0.99})
        end
    end
end

--Capsule History and Antigrief
local function on_player_used_capsule(event)
    if not this.enabled then
        return
    end

    local player = game.get_player(event.player_index)

    if this.do_not_check_trusted then
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
        local msg
        if this.enable_capsule_warning then
            if surface.count_entities_filtered({force = 'enemy', area = {{x - 10, y - 10}, {x + 10, y + 10}}, limit = 1}) > 0 then
                return
            end
            local count = 0
            local entities = player.surface.find_entities_filtered {force = player.force, area = {{x - 5, y - 5}, {x + 5, y + 5}}}

            for i = 1, #entities do
                local e = entities[i]
                local entity_name = e.name
                if entity_name ~= name and entity_name ~= 'entity-ghost' and not blacklisted_types[e.type] then
                    count = count + 1
                end
            end

            if count <= this.capsule_bomb_threshold then
                return
            end

            local prefix = '[Capsule]'
            msg = format(player.name .. ' damaged: %s with: %s', get_entities(name, entities), name)
            local ban_msg = format('Damaged: %s with: %s. This action was performed automatically. Visit getcomfy.eu/discord for forgiveness', get_entities(name, entities), name)

            do_action(player, prefix, msg, ban_msg, true)
        else
            msg = player.name .. ' used ' .. name
        end

        if not this.capsule_history then
            this.capsule_history = {}
        end
        if this.limit > 0 and #this.capsule_history > this.limit then
            overflow(this.capsule_history)
        end

        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. msg
        str = str .. ' at X:'
        str = str .. floor(position.x)
        str = str .. ' Y:'
        str = str .. floor(position.y)
        str = str .. ' '
        str = str .. 'surface:' .. player.surface.index
        increment(this.capsule_history, str)
        Server.log_antigrief_data('capsule', str)
    end
end

--Friendly Fire History
local function on_entity_died(event)
    if not this.enabled then
        return
    end

    local cause = event.cause
    local name

    if (cause and cause.name == 'character' and cause.player and cause.force.name == event.entity.force.name and not blacklisted_types[event.entity.type]) then
        local player = cause.player
        name = player.name

        if not this.friendly_fire_history then
            this.friendly_fire_history = {}
        end

        if this.limit > 0 and #this.friendly_fire_history > this.limit then
            overflow(this.friendly_fire_history)
        end

        local chest
        if chests[event.entity.type] then
            local entity = event.entity
            local inv = entity.get_inventory(1)
            local contents = inv.get_contents()
            local item_types = ''

            for n, count in pairs(contents) do
                if n == 'explosives' then
                    item_types = item_types .. n .. ' count: ' .. count .. ' '
                end
            end

            if string.len(item_types) > 0 then
                chest = event.entity.name .. ' with content ' .. item_types
            else
                chest = event.entity.name
            end
        else
            chest = event.entity.name
        end

        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. name .. ' destroyed '
        str = str .. chest
        str = str .. ' at X:'
        str = str .. floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index
        increment(this.friendly_fire_history, str)
        Server.log_antigrief_data('friendly_fire', str)
    elseif not blacklisted_types[event.entity.type] and this.whitelist_types[event.entity.type] then
        if cause then
            if cause.force.name ~= 'player' then
                return
            end
        end
        if not this.friendly_fire_history then
            this.friendly_fire_history = {}
        end

        if this.limit > 0 and #this.friendly_fire_history > this.limit then
            overflow(this.friendly_fire_history)
        end
        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        if cause and cause.name == 'character' and cause.player then
            str = str .. cause.player.name .. ' destroyed '
        else
            str = str .. 'someone destroyed '
        end
        str = str .. event.entity.name
        str = str .. ' at X:'
        str = str .. floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index

        if cause and cause.name == 'character' and cause.player then
            increment(this.friendly_fire_history, str)
            Server.log_antigrief_data('friendly_fire', str)
        else
            increment(this.friendly_fire_history, str)
            Server.log_antigrief_data('friendly_fire', str)
        end
    end
end

--Mining Thieves History
local function on_player_mined_entity(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if this.whitelist_types[entity.type] then
        if not this.whitelist_mining_history then
            this.whitelist_mining_history = {}
        end
        if this.limit > 0 and #this.whitelist_mining_history > this.limit then
            overflow(this.whitelist_mining_history)
        end
        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. player.name .. ' mined '
        str = str .. entity.name
        str = str .. ' at X:'
        str = str .. floor(entity.position.x)
        str = str .. ' Y:'
        str = str .. floor(entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. entity.surface.index
        increment(this.whitelist_mining_history, str)
        Server.log_antigrief_data('whitelist_mining', str)
        return
    end

    if not entity.last_user then
        return
    end
    if entity.last_user.name == player.name then
        return
    end
    if entity.force.name ~= player.force.name then
        return
    end
    if blacklisted_types[event.entity.type] then
        return
    end
    if not this.mining_history then
        this.mining_history = {}
    end

    if this.limit > 0 and #this.mining_history > this.limit then
        overflow(this.mining_history)
    end

    local t = abs(floor((game.tick) / 60))
    local formatted = FancyTime.short_fancy_time(t)
    local str = '[' .. formatted .. '] '
    str = str .. player.name .. ' mined '
    str = str .. event.entity.name
    str = str .. ' at X:'
    str = str .. floor(event.entity.position.x)
    str = str .. ' Y:'
    str = str .. floor(event.entity.position.y)
    str = str .. ' '
    str = str .. 'surface:' .. event.entity.surface.index
    increment(this.mining_history, str)
    Server.log_antigrief_data('mining', str)
end

local function on_gui_opened(event)
    if not this.enabled then
        return
    end
    if not event.entity then
        return
    end
    if event.entity.name ~= 'character-corpse' then
        return
    end
    local player = game.get_player(event.player_index)
    local corpse_owner = game.get_player(event.entity.character_corpse_player_index)
    if not corpse_owner then
        return
    end

    if corpse_owner.force.name ~= player.force.name then
        return
    end

    if player.controller_type == defines.controllers.spectator then
        return
    end

    local corpse_content = #event.entity.get_inventory(defines.inventory.character_corpse)
    if corpse_content <= 0 then
        return
    end

    if player.name ~= corpse_owner.name then
        Utils.action_warning('[Corpse]', player.name .. ' is looting ' .. corpse_owner.name .. '´s body.')
        if not this.corpse_history then
            this.corpse_history = {}
        end
        if this.limit > 0 and #this.corpse_history > this.limit then
            overflow(this.corpse_history)
        end

        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. player.name .. ' opened '
        str = str .. corpse_owner.name .. ' body'
        str = str .. ' at X:'
        str = str .. floor(event.entity.position.x)
        str = str .. ' Y:'
        str = str .. floor(event.entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. event.entity.surface.index
        increment(this.corpse_history, str)
        Server.log_antigrief_data('corpse', str)
    end
end

local function on_pre_player_mined_item(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if entity.name ~= 'character-corpse' then
        return
    end

    local corpse_owner = game.get_player(entity.character_corpse_player_index)
    if not corpse_owner then
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
        Utils.action_warning('[Corpse]', player.name .. ' has looted ' .. corpse_owner.name .. '´s body.')
        if not this.corpse_history then
            this.corpse_history = {}
        end
        if this.limit > 0 and #this.corpse_history > this.limit then
            overflow(this.corpse_history)
        end

        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. player.name .. ' mined '
        str = str .. corpse_owner.name .. ' body'
        str = str .. ' at X:'
        str = str .. floor(entity.position.x)
        str = str .. ' Y:'
        str = str .. floor(entity.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. entity.surface.index
        increment(this.corpse_history, str)
        Server.log_antigrief_data('corpse', str)
    end
end

local function on_console_chat(event)
    if not event.player_index then
        return
    end
    local player = game.get_player(event.player_index)

    if not this.message_history then
        this.message_history = {}
    end
    if this.limit > 0 and #this.message_history > this.limit then
        overflow(this.message_history)
    end

    local t = abs(floor((game.tick) / 60))
    local formatted = FancyTime.short_fancy_time(t)
    local str = '[' .. formatted .. '] '
    local message = event.message
    str = str .. player.name .. ': ' .. message
    increment(this.message_history, str)

    local message_length = string.len(message) >= 500
    if message_length then
        if this.enable_jail_on_long_texts and not player.admin then
            if not this.players_warn_on_long_texts[player.index] then
                this.players_warn_on_long_texts[player.index] = 1
                Task.set_timeout_in_ticks(108000, clear_players_warn_on_long_texts, {player_index = player.index})
            end
            local warnings = this.players_warn_on_long_texts[player.index]
            if warnings then
                if warnings == 1 or warnings == 2 then
                    Utils.print_to(player, '[Spam] Warning! Do not type long sentences!')
                    this.players_warn_on_long_texts[player.index] = this.players_warn_on_long_texts[player.index] + 1
                elseif warnings == 3 then
                    Utils.print_to(player, '[Spam] Warning! Do not type long sentences! This is your final warning!')
                    this.players_warn_on_long_texts[player.index] = this.players_warn_on_long_texts[player.index] + 1
                else
                    Jail.try_ul_data(player, true, 'script', 'Spammed ' .. this.players_warn_on_long_texts[player.index] .. ' times. Has been warned multiple times before getting jailed and muted.', true)
                    this.players_warn_on_long_texts[player.index] = nil
                end
            end
        end
    end
end

local function on_player_cursor_stack_changed(event)
    if not this.enabled then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.admin then
        return
    end
    if Session.get_trusted_player(player) or this.do_not_check_trusted then
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
    if Session.get_session_player(player) then
        playtime = player.online_time + Session.get_session_player(player)
    end

    if playtime < this.required_playtime then
        if this.enable_capsule_cursor_warning then
            if ammo_names[name] then
                local item_to_remove = player.remove_item({name = name, count = 1000})
                if item_to_remove > 0 then
                    Utils.action_warning('[Capsule]', player.name .. ' equipped ' .. name .. ' but was not trusted.')
                    damage_player(player)
                end
            end
        end
    end
end

local function on_player_cancelled_crafting(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)

    local crafting_queue_item_count = event.items.get_item_count()
    local free_slots = player.get_main_inventory().count_empty_stacks()
    local crafted_items = #event.items

    if crafted_items > free_slots then
        if this.punish_cancel_craft then
            player.character.character_inventory_slots_bonus = crafted_items + #player.get_main_inventory()
            for i = 1, crafted_items do
                player.character.get_main_inventory().insert(event.items[i])
            end

            player.character.die('player')

            Utils.action_warning('[Crafting]', player.name .. ' canceled their craft of item ' .. event.recipe.name .. ' of total count ' .. crafting_queue_item_count .. ' in raw items (' .. crafted_items .. ' slots) but had no inventory left.')
        end

        if not this.cancel_crafting_history then
            this.cancel_crafting_history = {}
        end
        if this.limit > 0 and #this.cancel_crafting_history > this.limit then
            overflow(this.cancel_crafting_history)
        end

        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. player.name .. ' canceled item ' .. event.recipe.name
        str = str .. ' count was a total of: ' .. crafting_queue_item_count
        str = str .. ' at X:'
        str = str .. floor(player.position.x)
        str = str .. ' Y:'
        str = str .. floor(player.position.y)
        str = str .. ' '
        str = str .. 'surface:' .. player.surface.index
        increment(this.cancel_crafting_history, str)
        Server.log_antigrief_data('cancel_crafting', str)
    end
end

local function on_init()
    if not this.enabled then
        return
    end
    local branch_version = '0.18.35'
    local is_branch_18 = sub(branch_version, 3, 4)
    local get_active_version = sub(game.active_mods.base, 3, 4)
    local default = game.permissions.get_group('Default')

    game.forces.player.research_queue_enabled = true

    is_branch_18 = is_branch_18 .. sub(branch_version, 6, 7)
    get_active_version = get_active_version .. sub(game.active_mods.base, 6, 7)
    if get_active_version >= is_branch_18 then
        default.set_allows_action(defines.input_action.flush_opened_entity_fluid, false)
        default.set_allows_action(defines.input_action.flush_opened_entity_specific_fluid, false)
    end
end

local function on_permission_group_added(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local group = event.group

    if group then
        Utils.log_msg('[Permission_Group]', player.name .. ' added ' .. group.name)
    end
end

local function on_permission_group_deleted(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local name = event.group_name
    local id = event.id
    if name then
        Utils.log_msg('[Permission_Group]', player.name .. ' deleted ' .. name .. ' with ID: ' .. id)
    end
end

local function on_player_deconstructed_area(event)
    if not this.enabled then
        return
    end

    local surface = event.surface

    local surface_name = this.decon_surface_blacklist
    if sub(surface.name, 0, #surface_name) ~= surface_name then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local area = event.area
    local count = surface.count_entities_filtered({area = area, type = 'resource', invert = true})
    local max_count = 0
    local is_trusted = Session.get_trusted_player(player)
    if is_trusted then
        max_count = this.max_count_decon
    end

    if next(this.filtered_types_on_decon) then
        local filtered_count = surface.count_entities_filtered({area = area, type = this.filtered_types_on_decon})
        if filtered_count and filtered_count > 0 then
            surface.cancel_deconstruct_area {
                area = area,
                force = player.force
            }
        end
    end

    if count and count >= max_count then
        surface.cancel_deconstruct_area {
            area = area,
            force = player.force
        }
        if not is_trusted then
            return
        end

        local msg = '[Deconstruct] ' .. player.name .. ' tried to deconstruct: ' .. count .. ' entities!'
        Utils.print_to(nil, msg)
        Server.to_discord_embed(msg)

        if not this.deconstruct_history then
            this.deconstruct_history = {}
        end
        if this.limit > 0 and #this.deconstruct_history > this.limit then
            overflow(this.deconstruct_history)
        end

        local t = abs(floor((game.tick) / 60))
        local formatted = FancyTime.short_fancy_time(t)
        local str = '[' .. formatted .. '] '
        str = str .. msg
        str = str .. ' at lt_x:'
        str = str .. floor(area.left_top.x)
        str = str .. ' at lt_y:'
        str = str .. floor(area.left_top.y)
        str = str .. ' at rb_x:'
        str = str .. floor(area.right_bottom.x)
        str = str .. ' at rb_y:'
        str = str .. floor(area.right_bottom.y)
        str = str .. ' '
        str = str .. 'surface:' .. player.surface.index
        increment(this.deconstruct_history, str)
        Server.log_antigrief_data('deconstruct', str)

        if this.enable_jail_when_decon and not player.admin then
            if not this.players_warn_when_decon[player.index] then
                this.players_warn_when_decon[player.index] = 1
                local r = random(7200, 18000)
                Task.set_timeout_in_ticks(r, clear_player_decon_warnings, {player_index = player.index})
            end
            local warnings = this.players_warn_when_decon[player.index]
            if warnings then
                if warnings == 1 or warnings == 2 then
                    Utils.print_to(player, '[Deconstruct] Warning! Do not deconstruct that many entities at once!')
                    this.players_warn_when_decon[player.index] = this.players_warn_when_decon[player.index] + 1
                elseif warnings == 3 then
                    Utils.print_to(player, '[Deconstruct] Warning! Do not deconstruct that many entities at once! This is your final warning!')
                    this.players_warn_when_decon[player.index] = this.players_warn_when_decon[player.index] + 1
                else
                    Jail.try_ul_data(player, true, 'script', 'Deconstructed ' .. count .. ' entities. Has been warned 3 times before getting jailed.')
                    this.players_warn_when_decon[player.index] = nil
                end
            end
        end
    end
end

local function on_cancelled_deconstruction(event)
    local player_index = event.player_index
    if player_index then
        return
    end

    local tick = event.tick
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local handler = this.on_cancelled_deconstruction

    if tick ~= handler.tick then
        handler.tick = tick
        handler.count = 0
    end

    handler.count = handler.count + 1

    local player = entity.last_user
    if player and player.valid and player.connected then
        local is_trusted = Session.get_trusted_player(player)
        if not is_trusted then
            return
        end
    end

    if entity.force.name == 'neutral' then
        return
    end

    if tick == handler.tick and handler.count >= this.max_count_decon then
        return
    end

    entity.order_deconstruction(entity.force)
end

local function on_permission_group_edited(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local group = event.group
    if group then
        local action = ''
        for k, v in pairs(defines.input_action) do
            if event.action == v then
                action = k
            end
        end
        Utils.log_msg('[Permission_Group]', player.name .. ' edited ' .. group.name .. ' with type: ' .. event.type .. ' with action: ' .. action)
    end
    if event.other_player_index then
        local other_player = game.get_player(event.other_player_index)
        if other_player and other_player.valid then
            Utils.log_msg('[Permission_Group]', player.name .. ' moved ' .. other_player.name .. ' with type: ' .. event.type .. ' to group: ' .. group.name)
        end
    end
    local old_name = event.old_name
    local new_name = event.new_name
    if old_name and new_name then
        Utils.log_msg('[Permission_Group]', player.name .. ' renamed ' .. group.name .. '. New name: ' .. new_name .. '. Old Name: ' .. old_name)
    end
end

local function on_permission_string_imported(event)
    if not this.enabled then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    Utils.log_msg('[Permission_Group]', player.name .. ' imported a permission string')
end

local function on_player_muted(event)
    if not this.enabled then
        return
    end

    local player = game.get_player(event.player_index)

    local message = {
        title = 'Muted :mute:',
        description = 'A player was muted.',
        color = 'failure',
        field1 = {
            text1 = 'Player:',
            text2 = player.name,
            inline = 'false'
        }
    }
    Discord.send_notification_obj(message)
end

local function on_player_unmuted(event)
    if not this.enabled then
        return
    end

    local player = game.get_player(event.player_index)

    local message = {
        title = 'Unmuted :speaker:',
        description = 'A player was unmuted.',
        color = 'success',
        field1 = {
            text1 = 'Player:',
            text2 = player.name,
            inline = 'false'
        }
    }
    Discord.send_notification_obj(message)
end

--- This is used for the RPG module, when casting capsules.
---@param player userdata
---@param position table
---@param msg string
function Public.insert_into_capsule_history(player, position, msg)
    if not this.capsule_history then
        this.capsule_history = {}
    end
    if this.limit > 0 and #this.capsule_history > this.limit then
        overflow(this.capsule_history)
    end
    local t = abs(floor((game.tick) / 60))
    local formatted = FancyTime.short_fancy_time(t)
    local str = '[' .. formatted .. '] ' .. msg
    str = str .. ' at X:'
    str = str .. floor(position.x)
    str = str .. ' Y:'
    str = str .. floor(position.y)
    str = str .. ' '
    str = str .. 'surface:' .. player.surface.index
    increment(this.capsule_history, str)
    Server.log_antigrief_data('capsule', str)
end

--- This will reset the table of antigrief
function Public.reset_tables()
    this.landfill_history = {}
    this.capsule_history = {}
    this.friendly_fire_history = {}
    this.mining_history = {}
    this.whitelist_mining_history = {}
    this.corpse_history = {}
    this.message_history = {}
    this.cancel_crafting_history = {}
end

--- Add entity type to the whitelist so it gets logged.
---@param key string
---@param value string|boolean
function Public.whitelist_types(key, value)
    if key and value then
        this.whitelist_types[key] = value
    end

    return this.whitelist_types[key]
end

--- If the event should also check trusted players.
---@param value boolean
function Public.do_not_check_trusted(value)
    this.do_not_check_trusted = value or false
    return this.do_not_check_trusted
end

--- Sets the capsuled bomb threshold for the script to take action
---@param value number
function Public.set_capsule_bomb_threshold(value)
    this.capsule_bomb_threshold = value or 1500
    return this.capsule_bomb_threshold
end

--- Sets the max count of entities that can be deconstructed at once.
---@param value number
function Public.set_max_count_decon(value)
    this.max_count_decon = value or 1500
    return this.max_count_decon
end

--- If ANY actions should be performed when a player misbehaves.
---@param value boolean
function Public.enable_capsule_warning(value)
    this.enable_capsule_warning = value or false
    return this.enable_capsule_warning
end

--- If ANY actions should be performed when a player misbehaves.
---@param value boolean
function Public.enable_capsule_cursor_warning(value)
    this.enable_capsule_cursor_warning = value or false
    return this.enable_capsule_cursor_warning
end

--- If the script should jail a person instead of kicking them
---@param value boolean
function Public.enable_jail(value)
    this.enable_jail = value or false
    return this.enable_jail
end

--- If the script should jail a person whenever they deconstruct multiple times.
---@param value boolean
function Public.enable_jail_when_decon(value)
    this.enable_jail_when_decon = value or false
    return this.enable_jail_when_decon
end

--- If the script should jail a person whenever they type long texts multiple times.
---@param value boolean
function Public.enable_jail_on_long_texts(value)
    this.enable_jail_on_long_texts = value or false
    return this.enable_jail_on_long_texts
end

--- If the script should jail a person whenever they deconstruct multiple times.
---@param value string
function Public.decon_surface_blacklist(value)
    this.decon_surface_blacklist = value or 'nauvis'
    return this.decon_surface_blacklist
end

--- Defines if on_player_deconstructed_area should also check for other types.
---@param tbl table
function Public.filtered_types_on_decon(tbl)
    if tbl then
        this.filtered_types_on_decon = tbl
    end
end

--- Defines what the threshold for amount of times before the script should take action.
---@param value number
function Public.damage_entity_threshold(value)
    if value then
        this.damage_entity_threshold = value
    end

    return this.damage_entity_threshold
end

--- Defines what the limit should be set for each table before resetting it.
---@param value number
function Public.set_limit_per_table(value)
    if value then
        if value == 0 then
            this.limit = 0
        elseif value > 10 then
            this.limit = value
        end
    end

    return this.limit
end

--- Appends a new message to the scenario history tab in the admin panel.
---@param message string
function Public.append_scenario_history(player, entity, message)
    if not this.scenario_history then
        this.scenario_history = {}
    end
    if this.limit > 0 and #this.scenario_history > this.limit + 8000 then
        overflow(this.scenario_history)
    end
    local t = abs(floor((game.tick) / 60))
    local formatted = FancyTime.short_fancy_time(t)
    local str = '[' .. formatted .. '] ' .. message
    str = str .. ' at X:'
    str = str .. floor(entity.position.x)
    str = str .. ' Y:'
    str = str .. floor(entity.position.y)
    str = str .. ' '
    str = str .. 'surface:' .. player.surface.index
    increment(this.scenario_history, str)
    Server.log_antigrief_data('scenario', str)
end

--- Returns the table.
---@param key string|nil
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Change or add a value
---@param key any
---@param value any
---@return boolean|string|integer|table
function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(on_init)
Event.add(de.on_player_mined_entity, on_player_mined_entity)
Event.add(de.on_entity_died, on_entity_died)
Event.add(de.on_built_entity, on_built_entity)
Event.add(de.on_gui_opened, on_gui_opened)
Event.add(de.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(de.on_player_deconstructed_area, on_player_deconstructed_area)
Event.add(de.on_cancelled_deconstruction, on_cancelled_deconstruction)
Event.add(de.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
Event.add(de.on_player_built_tile, on_player_built_tile)
Event.add(de.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(de.on_player_used_capsule, on_player_used_capsule)
Event.add(de.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
Event.add(de.on_player_cancelled_crafting, on_player_cancelled_crafting)
Event.add(de.on_player_joined_game, on_player_joined_game)
Event.add(de.on_permission_group_added, on_permission_group_added)
Event.add(de.on_permission_group_deleted, on_permission_group_deleted)
Event.add(de.on_permission_group_edited, on_permission_group_edited)
Event.add(de.on_permission_string_imported, on_permission_string_imported)
Event.add(de.on_console_chat, on_console_chat)
Event.add(de.on_player_muted, on_player_muted)
Event.add(de.on_player_unmuted, on_player_unmuted)

return Public
