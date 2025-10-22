---@diagnostic disable: deprecated
local Session = require 'utils.datastore.session_data'
local Modifiers = require 'utils.player_modifiers'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'
local BottomFrame = require 'utils.gui.bottom_frame'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'
local Task = require 'utils.task_token'
local CustomEvents = require 'utils.created_events'

local this =
{
    enabled = true,
    players = {},
    bottom_button = false
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local Public = {}

local clear_corpse_button_name = Gui.uid_name()
local floor = math.floor

local clear_chunk_token =
    Task.register(
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

local remove_offline_players_token =
    Task.register(
        function (event)
            local list = event.list
            if not list then
                return
            end
            game.remove_offline_players(list)
        end
    )

local function tick_to_hours(t)
    local seconds = t * 60
    local minutes = floor((seconds) * 60)
    return floor((minutes) * 60)
end

local function hours_to_tick(t)
    local seconds = t / 60
    local minutes = floor((seconds) / 60)
    return floor((minutes) / 60)
end

Commands.new('clear_all_enemies', 'Iterates over the current player surface and removes all generated enemies.')
    :require_admin()
    :require_validation("This will remove all enemies from the map.")
    :add_parameter('surface', true, 'surface')
    :add_parameter('force', true, 'string')
    :callback(
        function (player, surface_arg, force_arg)
            local surface = surface_arg or player.surface
            local force = force_arg or 'enemy'
            local count = 0
            for c in surface.get_chunks() do
                for _, entity in pairs(surface.find_entities_filtered({ area = { { c.x * 32, c.y * 32 }, { c.x * 32 + 32, c.y * 32 + 32 } }, force = force })) do
                    if entity and entity.valid then
                        entity.destroy()
                        count = count + 1
                    end
                end
            end
            if count == 0 then
                player.print('No enemies to remove were found!')
                return false
            end

            game.print(mapkeeper .. ' ' .. player.name .. ' removed ' .. count .. ' enemies.')
            Discord.send_notification_raw(nil, player.name .. ' removed ' .. count .. ' enemies.')
            return true
        end
    )

Commands.new('remove_chunks', 'Iterates over a surface and removes chunks that are charted but does not have any player entitie.')
    :require_validation("This will remove all chunks that are charted but does not have any player entities.")
    :require_admin()
    :add_parameter('force', true, 'string')
    :callback(
        function (player, args)
            local surface = player.surface
            local chunks = surface.get_chunks()
            local tick = 0
            local force = args or player.force.name

            local chunks_to_remove = {}

            for chunk in chunks do
                if surface.is_chunk_generated(chunk) then
                    local area =
                    {
                        left_top = { chunk.area.left_top.x - 64, chunk.area.left_top.y - 64 },
                        right_bottom = { chunk.area.right_bottom.x + 64, chunk.area.right_bottom.y + 64 }
                    }

                    local ents = surface.find_entities_filtered { area = area, force = { force } }
                    local total_count = #ents

                    if total_count <= 0 then
                        chunks_to_remove[#chunks_to_remove + 1] = chunk
                    end
                end
                if chunks_to_remove and #chunks_to_remove >= 10 then
                    tick = tick + 2
                    Task.set_timeout_in_ticks(tick, clear_chunk_token,
                        { chunk = chunks_to_remove, surface_index = surface.index })

                    chunks_to_remove = {}
                end
            end

            game.print(mapkeeper .. ' ' .. player.name .. ' scheduled ' .. surface.name .. ' for chunk removal.')
            Discord.send_notification_raw(nil, player.name .. ' scheduled ' .. surface.name .. ' for chunk removal.')
            return true
        end
    )

Commands.new('remove_offline_players', 'Remove offline players.')
    :require_validation("This will remove offline players that has not connected in the given hours.")
    :add_parameter('hours', false, "number")
    :require_admin()
    :callback(
        function (player, hours)
            local surface = player.surface
            local remove_players = {}
            local tick = 0
            local count = 0
            local converted_hours = tick_to_hours(hours)
            local converted_game_tick = hours_to_tick(game.tick)

            if game.tick < converted_hours then
                player.print('Cannot remove players that has not been offline for less than ' .. hours .. ' hours when the server has been running for ' .. converted_game_tick .. ' hours.')
                return false
            end

            for _, p in pairs(game.players) do
                if p.last_online < converted_hours then
                    count = count + 1
                    remove_players[#remove_players + 1] = p.name

                    if remove_players and #remove_players >= 10 then
                        tick = tick + 2
                        Task.set_timeout_in_ticks(tick, remove_offline_players_token,
                            { list = remove_players })

                        remove_players = {}
                    end
                end
            end


            local message = player.name .. ' scheduled ' .. surface.name .. ' for offline player removal of count: ' .. count .. '.'
            game.print(mapkeeper .. ' ' .. message)
            Discord.send_notification_raw(nil, message)
            return true
        end
    )

Commands.new('playtime', 'Gets a single player total playtime or nil.')
    :require_backend()
    :add_parameter('target', false, 'string')
    :callback(
        function (player, target)
            Session.get_and_print_to_player(player, target)
            return true
        end
    )


Commands.new('refresh', 'Reloads game script')
    :require_admin()
    :require_validation("Running this command will freeze the server if run in multiplayer.")
    :add_alias('reload')
    :callback(
        function (player)
            game.print('Reloading game script...', { color = Color.warning })
            Server.to_discord_bold(player.name .. ' is reloading the game script.')
            Discord.send_notification_raw(nil, player.name .. ' is reloading the game script.')
            game.reload_script()
            return true
        end
    )

Commands.new('spaghetti', 'Toggle between disabling bots.')
    :require_admin()
    :require_validation()
    :is_activated()
    :add_parameter('true/false', true, 'boolean')
    :callback(
        function (player, args)
            local force = player.force
            if args == 'true' then
                game.print('The world has been spaghettified!', { color = Color.success })
                force.technologies['logistic-system'].enabled = false
                force.technologies['construction-robotics'].enabled = false
                force.technologies['logistic-robotics'].enabled = false
                force.technologies['robotics'].enabled = false
                force.technologies['personal-roboport-equipment'].enabled = false
                force.technologies['personal-roboport-mk2-equipment'].enabled = false
                force.technologies['worker-robots-storage-1'].enabled = false
                force.technologies['worker-robots-storage-2'].enabled = false
                force.technologies['worker-robots-storage-3'].enabled = false
                force.technologies['worker-robots-speed-1'].enabled = false
                force.technologies['worker-robots-speed-2'].enabled = false
                force.technologies['worker-robots-speed-3'].enabled = false
                force.technologies['worker-robots-speed-4'].enabled = false
                force.technologies['worker-robots-speed-5'].enabled = false
                force.technologies['worker-robots-speed-6'].enabled = false
                this.spaghetti_enabled = true
                return true
            elseif args == 'false' then
                game.print('The world is no longer spaghett!', { color = Color.yellow })
                force.technologies['logistic-system'].enabled = true
                force.technologies['construction-robotics'].enabled = true
                force.technologies['logistic-robotics'].enabled = true
                force.technologies['robotics'].enabled = true
                force.technologies['personal-roboport-equipment'].enabled = true
                force.technologies['personal-roboport-mk2-equipment'].enabled = true
                force.technologies['worker-robots-storage-1'].enabled = true
                force.technologies['worker-robots-storage-2'].enabled = true
                force.technologies['worker-robots-storage-3'].enabled = true
                force.technologies['worker-robots-speed-1'].enabled = true
                force.technologies['worker-robots-speed-2'].enabled = true
                force.technologies['worker-robots-speed-3'].enabled = true
                force.technologies['worker-robots-speed-4'].enabled = true
                force.technologies['worker-robots-speed-5'].enabled = true
                force.technologies['worker-robots-speed-6'].enabled = true
                this.spaghetti_enabled = false
                return true
            end
            return false
        end
    )

Commands.new('generate_map', 'Pregenerates map.')
    :require_admin()
    :require_validation()
    :add_parameter('radius', false, 'number')
    :callback(
        function (player, args)
            local radius = args
            local surface = player.surface
            if surface.is_chunk_generated({ radius, radius }) then
                player.print('Map generation is already generated')
                return true
            end
            surface.request_to_generate_chunks({ 0, 0 }, radius)
            surface.force_generate_chunk_requests()
            for _, pl in pairs(game.connected_players) do
                pl.play_sound { path = 'utility/new_objective', volume_modifier = 1 }
            end
            player.print('Map generation done')
            return true
        end
    )

Commands.new('repair', 'Revives all ghost entities and inserts all missing modules into the entities.')
    :require_admin()
    :add_alias('fix')
    :add_alias('revive')
    :require_validation()
    :add_parameter('1-50', true, 'number')
    :callback(
        function (player, args)
            if args < 1 then
                player.print('[ERROR] Value is too low.')
                return false
            end

            if args > 50 then
                player.print('[ERROR] Value is too big.')
                return false
            end

            local radius = { { x = (player.position.x + -args), y = (player.position.y + -args) }, { x = (player.position.x + args), y = (player.position.y + args) } }

            local c = 0
            local modules = 0
            for _, v in pairs(player.surface.find_entities_filtered { type = 'entity-ghost', area = radius }) do
                if v and v.valid then
                    c = c + 1
                    local _, entity, item_proxy = v.silent_revive()
                    if entity and entity.valid then
                        if item_proxy and item_proxy.valid then
                            for _, plan in pairs(item_proxy.insert_plan) do
                                if entity.get_module_inventory().index == plan.items.in_inventory[1].inventory then
                                    item_proxy.proxy_target.get_module_inventory().insert { name = plan.id.name, quality = plan.id.quality, count = 999 }
                                    modules = modules + 1
                                end
                            end
                            item_proxy.destroy()
                        end
                    end
                end
            end



            if c == 0 then
                player.print('No entities to repair were found!')
                return false
            end

            if modules > 0 then
                Discord.send_notification_raw(nil, player.name .. ' repaired ' .. c .. ' entities and inserted all missing modules into the entities.')
                return 'Repaired ' .. c .. ' entities and inserted all missing modules into the entities.'
            end

            Discord.send_notification_raw(nil, player.name .. ' repaired ' .. c .. ' entities.')
            return 'Repaired ' .. c .. ' entities!'
        end
    )

Commands.new('dump_layout', 'Dump the current map-layout.')
    :require_admin()
    :require_validation('This will lag the server if ran')
    :callback(
        function (player, _)
            local surface = player.surface
            game.write_file('layout.lua', '', false)

            local area =
            {
                left_top = { x = 0, y = 0 },
                right_bottom = { x = 32, y = 32 }
            }

            local entities = surface.find_entities_filtered { area = area }
            local tiles = surface.find_tiles_filtered { area = area }

            for _, e in pairs(entities) do
                local str = '{position = {x = ' .. e.position.x
                str = str .. ', y = '
                str = str .. e.position.y
                str = str .. '}, name = "'
                str = str .. e.name
                str = str .. '", direction = '
                str = str .. tostring(e.direction)
                str = str .. ', force = "'
                str = str .. e.force.name
                str = str .. '"},'
                if e.name ~= 'character' then
                    game.write_file('layout.lua', str .. '\n', true)
                end
            end

            game.write_file('layout.lua', '\n', true)
            game.write_file('layout.lua', '\n', true)
            game.write_file('layout.lua', 'Tiles: \n', true)

            for _, t in pairs(tiles) do
                local str = '{position = {x = ' .. t.position.x
                str = str .. ', y = '
                str = str .. t.position.y
                str = str .. '}, name = "'
                str = str .. t.name
                str = str .. '"},'
                game.write_file('layout.lua', str .. '\n', true)
            end
            return 'Dumped layout as file: layout.lua'
        end
    )

Commands.new('creative', 'Enables creative_mode.')
    :require_admin()
    :add_parameter('true/false', false, 'boolean')
    :require_validation()
    :is_activated()
    :callback(
        function (player, args)
            local force = player.force
            if args == 'true' then
                game.print('[CREATIVE] ' .. player.name .. ' has activated creative-mode!', { color = Color.warning })
                Server.to_discord_bold(table.concat { '[Creative] ' .. player.name .. ' has activated creative-mode!' })

                Modifiers.set('creative_enabled', true)

                this.creative_enabled = true

                force.enable_all_prototypes()
                for _, _player in pairs(game.connected_players) do
                    player.cheat_mode = true
                    if _player.character ~= nil then
                        Public.insert_all_items(_player)
                    end
                end
            elseif args == 'false' then
                game.print('[CREATIVE] ' .. player.name .. ' has deactivated creative-mode!', { color = Color.warning })
                Server.to_discord_bold(table.concat { '[Creative] ' .. player.name .. ' has deactivated creative-mode!' })

                Modifiers.set('creative_enabled', false)

                this.creative_enabled = false

                for _, _player in pairs(game.connected_players) do
                    Public.remove_all_items(player)
                    _player.cheat_mode = false
                end
            end
        end
    )

Commands.new('delete_uncharted_chunks', 'Deletes all chunks that are not charted. Can reduce filesize of the savegame. May be unsafe to use in certain custom maps.')
    :require_admin()
    :require_validation()
    :callback(
        function (player, _)
            local forces = {}
            for _, force in pairs(game.forces) do
                if force.index == 1 or force.index > 3 then
                    table.insert(forces, force)
                end
            end

            local is_charted
            local count = 0
            for _, surface in pairs(game.surfaces) do
                for chunk in surface.get_chunks() do
                    is_charted = false
                    for _, force in pairs(forces) do
                        if force.is_chunk_charted(surface, { chunk.x, chunk.y }) then
                            is_charted = true
                            break
                        end
                    end
                    if not is_charted then
                        surface.delete_chunk({ chunk.x, chunk.y })
                        count = count + 1
                    end
                end
            end

            local message = player.name .. ' deleted ' .. count .. ' uncharted chunks!'
            game.print(message, { color = Color.warning })
            Server.to_discord_bold(table.concat { message })
        end
    )

local function clear_corpses(cmd)
    local player
    local trusted = Session.get_trusted_table()
    local param
    if cmd and cmd.player then
        player = cmd.player
        param = 50
    elseif cmd then
        player = game.player
        param = tonumber(cmd.parameter)
    end

    if not player or not player.valid then
        return
    end
    local p = player.print
    if not trusted[player.name] then
        if not player.admin then
            p('[ERROR] Only admins and trusted weebs are allowed to run this command!', { color = Color.fail })
            return
        end
    end
    if param == nil then
        player.print('[ERROR] Must specify radius!', { color = Color.fail })
        return
    end
    if param < 0 then
        player.print('[ERROR] Value is too low.', { color = Color.fail })
        return
    end
    if param > 500 then
        player.print('[ERROR] Value is too big.', { color = Color.fail })
        return
    end
    local pos = player.position

    local i = 0

    local radius = { { x = (pos.x + -param), y = (pos.y + -param) }, { x = (pos.x + param), y = (pos.y + param) } }

    for _, entity in pairs(player.surface.find_entities_filtered { area = radius, type = { 'corpse' } }) do
        if entity.corpse_expires then
            entity.destroy()
            i = i + 1
        end
    end
    local corpse = 'corpse'

    if i > 1 then
        corpse = 'corpses'
    end
    if i == 0 then
        player.print('[color=blue][Cleaner][/color] No corpses to clear!', { color = Color.warning })
    else
        player.print('[color=blue][Cleaner][/color] Cleared ' .. i .. ' ' .. corpse .. '!', { color = Color.success })
    end
end

commands.add_command(
    'clear-corpses',
    'Clears all the biter corpses..',
    function (cmd)
        clear_corpses(cmd)
    end
)

local on_player_joined_game = function (player)
    Public.insert_all_items(player)
end

local quality = has_space_age() and 'legendary' or 'normal'

function Public.insert_all_items(player)
    if this.creative_enabled and not this.players[player.index] then
        if player.character ~= nil then
            if player.get_inventory(defines.inventory.character_armor) then
                player.get_inventory(defines.inventory.character_armor).clear()
            end
            player.insert { name = 'power-armor-mk2', count = 1, quality = quality }
            Modifiers.update_single_modifier(player, 'character_inventory_slots_bonus', 'creative', #prototypes.item)
            Modifiers.update_single_modifier(player, 'character_mining_speed_modifier', 'creative', 150)
            Modifiers.update_single_modifier(player, 'character_health_bonus', 'creative', 2000)
            Modifiers.update_single_modifier(player, 'character_crafting_speed_modifier', 'creative', 150)
            Modifiers.update_single_modifier(player, 'character_resource_reach_distance_bonus', 'creative', 150)
            Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'creative', 2)
            Modifiers.update_player_modifiers(player)

            this.players[player.index] = true

            local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
            if p_armor and p_armor.valid then
                p_armor.put({ name = 'fission-reactor-equipment', quality = quality })
                p_armor.put({ name = 'fission-reactor-equipment', quality = quality })
                p_armor.put({ name = 'fission-reactor-equipment', quality = quality })
                p_armor.put({ name = 'exoskeleton-equipment', quality = quality })
                p_armor.put({ name = 'exoskeleton-equipment', quality = quality })
                p_armor.put({ name = 'exoskeleton-equipment', quality = quality })
                p_armor.put({ name = 'energy-shield-mk2-equipment', quality = quality })
                p_armor.put({ name = 'energy-shield-mk2-equipment', quality = quality })
                p_armor.put({ name = 'energy-shield-mk2-equipment', quality = quality })
                p_armor.put({ name = 'energy-shield-mk2-equipment', quality = quality })
                p_armor.put({ name = 'personal-roboport-mk2-equipment', quality = quality })
                p_armor.put({ name = 'night-vision-equipment', quality = quality })
                p_armor.put({ name = 'battery-mk2-equipment', quality = quality })
                p_armor.put({ name = 'battery-mk2-equipment', quality = quality })
            end
            local item = prototypes.item
            local i = 0
            for _k, _v in pairs(item) do
                i = i + 1
                if _k and _v.type ~= 'mining-tool' then
                    player.character_inventory_slots_bonus = Modifiers.get_single_modifier(player, 'character_inventory_slots_bonus', 'creative')
                    player.insert { name = _k, count = _v.stack_size, quality = quality }
                    player.print('[CREATIVE] Inserted all base items.', { color = Color.success })
                end
            end
        end
    end
end

function Public.remove_all_items(player)
    if player.character ~= nil then
        if player.get_inventory(defines.inventory.character_armor) then
            player.get_inventory(defines.inventory.character_armor).clear()
        end
        player.clear_items_inside()
        Modifiers.reset_player_modifiers(player)
        this.players[player.index] = nil
    end
end

local function create_clear_corpse_frame(player, bottom_frame_data)
    local button

    bottom_frame_data = bottom_frame_data or BottomFrame.get_player_data(player)

    if Gui.get_mod_gui_top_frame() then
        button =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = clear_corpse_button_name,
                    sprite = 'entity/behemoth-biter',
                    tooltip = { 'commands.clear_corpse' },
                    style = Gui.button_style
                }
            )
        if button then
            button.style.font_color = { 165, 165, 165 }
            button.style.font = 'default-semibold'
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 40
            button.style.padding = -2
        end
    else
        button =
            player.gui.top[clear_corpse_button_name] or
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    sprite = 'entity/behemoth-biter',
                    name = clear_corpse_button_name,
                    tooltip = { 'commands.clear_corpse' },
                    style = Gui.button_style
                }
            )
        button.style.font_color = { r = 0.11, g = 0.8, b = 0.44 }
        button.style.font = 'heading-1'
        button.style.minimal_height = 40
        button.style.maximal_width = 40
        button.style.minimal_width = 38
        button.style.maximal_height = 38
        button.style.padding = 1
        button.style.margin = 0
    end

    if this.bottom_button and bottom_frame_data ~= nil and not bottom_frame_data.top then
        if button and button.valid then
            button.destroy()
        end
    end
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key then
        this[key] = value or false
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(
    function ()
        Modifiers.set('creative_enabled', false)
        this.creative_are_you_sure = false
        this.creative_enabled = false
        this.spaghetti_are_you_sure = false
        this.spaghetti_enabled = false
    end
)

function Public.reset()
    Modifiers.set('creative_enabled', false)
    this.creative_are_you_sure = false
    this.creative_enabled = false
    this.spaghetti_are_you_sure = false
    this.spaghetti_enabled = false
    this.players = {}
end

function Public.bottom_button(value)
    print('Setting bottom button.')
    this.bottom_button = value or false
end

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        if not this.enabled then
            return
        end

        local player = game.players[event.player_index]
        on_player_joined_game(player)
        create_clear_corpse_frame(player)

        if this.bottom_button then
            BottomFrame.add_inner_frame({ player = player, element_name = clear_corpse_button_name, tooltip = { 'commands.clear_corpse' }, sprite = 'entity/behemoth-biter' })
        end
    end
)

Gui.on_click(
    clear_corpse_button_name,
    function (event)
        if not this.enabled then
            return
        end
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Clear Corpse')
        if is_spamming then
            return
        end
        clear_corpses(event)
    end
)

Event.add(
    CustomEvents.events.bottom_quickbar_location_changed,
    function (event)
        if not this.enabled then
            return
        end
        local player_index = event.player_index
        if not player_index then
            return
        end
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local bottom_frame_data = event.data
        create_clear_corpse_frame(player, bottom_frame_data)
    end
)

function Public.set_enabled(value)
    this.enabled = value or false
end

Public.clear_corpses = clear_corpses

return Public
