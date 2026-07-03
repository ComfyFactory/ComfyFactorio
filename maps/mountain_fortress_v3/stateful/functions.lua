local Public = require 'maps.mountain_fortress_v3.table'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local Stateful = require 'maps.mountain_fortress_v3.stateful.table'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Core = require 'utils.core'
local StatData = require 'utils.datastore.statistics'
local RPG = require 'modules.rpg.main'


local math = math
local ipairs = ipairs
local table = table

local main_frame_name = Gui.uid_name()
local selection_button_name = Gui.uid_name()

local buff_option_colors =
{
    {
        color = { r = 165, g = 42, b = 42 },
        print_color = { r = 0.0, g = 0.55, b = 0.0 }
    },
    {
        color = { r = 124, g = 252, b = 0 },
        print_color = { r = 0.75, g = 0.0, b = 0.0 }
    },
    {
        color = { r = 0, g = 0, b = 128 },
        print_color = { r = 0.0, g = 0.15, b = 0.55 }
    }
}

local function highest_count(tbl)
    if #tbl == 0 then
        return nil
    end

    local highest = 0
    for _, v in ipairs(tbl) do
        if v.count > highest then
            highest = v.count
        end
    end

    if highest == 0 then
        return nil
    end

    local winners = {}
    for _, v in ipairs(tbl) do
        if v.count == highest then
            table.insert(winners, v.index)
        end
    end

    if #winners == 0 then
        return nil
    end

    if #winners == 1 then
        return winners[1]
    end

    return winners[math.random(#winners)]
end

local function clear_main_frame(player)
    local screen = player.gui.screen
    if screen[main_frame_name] and screen[main_frame_name].valid then
        screen[main_frame_name].destroy()
    end
end

local function buff_main_frame(player, voted_index)
    if player.gui.screen[main_frame_name] then
        clear_main_frame(player)
    end

    local buff_selection = Public.get('buff_selection')
    if not buff_selection or not next(buff_selection) then
        return
    end

    if game.tick > buff_selection.closing_timeout then
        return
    end

    local main_frame, inside_frame = Gui.add_main_frame_with_toolbar(player, 'screen', main_frame_name, nil, nil, 'Buff selection')
    if not inside_frame then
        return
    end

    main_frame.force_auto_center()

    for i = 1, #buff_selection.buffs, 1 do
        local buff = buff_selection.buffs[i]
        local button_flow =
            inside_frame.add
            {
                type = 'flow',
                name = tostring(i),
                direction = 'horizontal'
            }
        button_flow.style.horizontal_align = 'center'
        button_flow.style.horizontally_stretchable = true
        local b = button_flow.add({ type = 'button', name = selection_button_name, caption = buff.name .. ' (' .. buff.count .. ')' })
        b.style.horizontal_align = 'center'
        b.style.vertical_align = 'center'
        b.style.font_color = buff.color
        b.style.font = 'heading-2'
        b.tooltip = buff.tooltip
        if voted_index and voted_index == i then
            b.enabled = false
            b.tooltip = b.tooltip .. '\nYou have already voted for this buff.'
        end
    end

    if buff_selection.index and buff_selection.buffs[buff_selection.index] then
        local leader = buff_selection.buffs[buff_selection.index]
        local leader_flow =
            inside_frame.add
            {
                type = 'flow'
            }
        leader_flow.style.horizontal_align = 'center'
        leader_flow.style.horizontally_stretchable = true
        leader_flow.add(
            {
                type = 'label',
                caption = 'Current leader: ' .. leader.name .. ' (' .. leader.count .. ')'
            }
        )
    end

    inside_frame.add({ type = 'line' })

    local timer_flow =
        inside_frame.add
        {
            type = 'flow'
        }
    timer_flow.style.horizontal_align = 'center'
    timer_flow.style.horizontally_stretchable = true

    local b =
        timer_flow.add(
            {
                type = 'button',
                caption = math.floor((buff_selection.closing_timeout - game.tick) / 3600) .. ' minutes left until voting closes.'
            }
        )
    b.style.font_color = { r = 0.66, g = 0.0, b = 0.66 }
    b.style.font = 'default-semibold'
    b.style.minimal_width = 96
    b.enabled = false

    Gui.set_data(main_frame, b)

    inside_frame.add({ type = 'line' })
end

local function set_buffs_voting()
    local buff_selection = Public.get('buff_selection')
    if not buff_selection or not next(buff_selection) then
        return
    end

    local index = highest_count(buff_selection.buffs)
    if not index or not buff_selection.buffs[index] then
        return
    end

    local buff = buff_selection.buffs[index]
    if buff.count <= 0 then
        return
    end

    if buff_selection.index ~= index then
        local message = table.concat({ '*** Current buff has changed to ', buff.name, '! ***' })
        game.print(message, { color = buff.print_color })
    end
    buff_selection.index = index
    buff_selection.name = buff.name
    buff_selection.value = buff.value
end

local function refresh_buff_frames()
    local buff_selection = Public.get('buff_selection')
    if not buff_selection or not next(buff_selection) then
        return
    end

    Core.iter_connected_players(function (player)
        if player and player.valid then
            local frame = player.gui.screen[main_frame_name]
            if frame and frame.valid then
                local voted_index = buff_selection.all_votes[player.name] and buff_selection.all_votes[player.name].index
                buff_main_frame(player, voted_index)
            end
        end
    end)
end

Gui.on_click(
    selection_button_name,
    function (event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Poll buff selection frame name')
        if is_spamming then
            return
        end
        local element = event.element
        if not element or not element.valid then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local buff_selection = Public.get('buff_selection')
        if not buff_selection or not next(buff_selection) then
            return
        end

        local i = tonumber(element.parent.name)

        if game.tick > buff_selection.closing_timeout then
            clear_main_frame(player)
            return
        end

        if buff_selection.all_votes[player.name] and buff_selection.all_votes[player.name].index == i then
            player.print('You have already voted for ' .. buff_selection.buffs[i].name .. '.', { color = buff_selection.buffs[i].print_color })
            clear_main_frame(player)
            return
        end

        if buff_selection.all_votes[player.name] then
            local index = buff_selection.all_votes[player.name].index
            buff_selection.buffs[index].count = buff_selection.buffs[index].count - 1
            if buff_selection.buffs[index].count <= 0 then
                buff_selection.buffs[index].count = 0
            end
        end

        buff_selection.buffs[i].count = buff_selection.buffs[i].count + 1
        buff_selection.all_votes[player.name] = { voted = true, index = i }

        set_buffs_voting()
        refresh_buff_frames()
        clear_main_frame(player)
        local message = '*** ' .. player.name .. ' has voted for ' .. buff_selection.buffs[i].name .. '! ***'
        game.print(message, { color = buff_selection.buffs[i].print_color })
    end
)

function Public.init_buff_selection(buffs)
    local buff_selection = Public.get('buff_selection')
    if not buff_selection then
        Server.output_script_data('buff_selection not found while initing buff selection - check stateful/table.lua')
        return
    end

    if not buffs or #buffs == 0 then
        Server.output_script_data('buffs not found while initing buff selection, buffs equals to zero')
        return
    end

    buff_selection.buffs = {}
    buff_selection.all_votes = {}
    buff_selection.voting_closed = false
    buff_selection.index = nil
    buff_selection.closing_timeout = game.tick + 10800 -- 3 minutes

    for i = 1, #buffs, 1 do
        local buff = buffs[i]
        if not buff or not next(buff) then
            Server.output_script_data('error while iterating buffs while initing buff selection')
            return
        end

        local option_colors = buff_option_colors[i] or buff_option_colors[((i - 1) % #buff_option_colors) + 1]

        buff_selection.buffs[i] =
        {
            name = buff.display_name or Stateful.resolve_buff_poll_name(buff),
            tooltip = buff.tooltip,
            count = 0,
            index = i,
            color = option_colors.color,
            print_color = option_colors.print_color,
            raw = buff
        }
    end
end

function Public.reward_goal_completion()
    local adjusted_zones = Public.get('adjusted_zones')
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local zone = math.floor((math.abs(locomotive.position.y / Public.zone_settings.zone_depth)) % adjusted_zones.size) + 1

    if math.random(1, 2) == 1 then
        local players = game.connected_players
        for i = 1, #players do
            local rng = math.random(2048, 8192)
            local scale_factor = 0.8 + (zone / 20)
            rng = math.floor(rng * scale_factor)
            local player = players[i]
            if player and player.valid then
                if player.can_insert({ name = 'coin', count = rng }) then
                    player.insert({ name = 'coin', count = rng })
                    StatData.get_data(player):increase('coins', rng)
                end
            end
        end
        return 'Coins have been granted to the whole team'
    else
        local rng = math.random(8192, 16384)
        local scale_factor = 0.8 + (zone / 20)
        rng = math.floor(rng * scale_factor)
        RPG.add_to_global_pool(rng)
        return 'XP has been granted to the global pool'
    end
end

function Public.set_multi_command_final_battle()
    local active_surface_index = Public.get('active_surface_index')
    if not active_surface_index then return end
    local surface = game.get_surface(active_surface_index)
    if not surface or not surface.valid then
        return
    end

    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    surface.set_multi_command(
        {
            command =
            {
                type = defines.command.attack,
                target = locomotive,
                distraction = defines.distraction.by_anything
            },
            unit_count = 60,
            force = 'aggressors',
            unit_search_distance = 256
        }
    )
end

Event.on_nth_tick(60, function ()
    local buff_selection = Public.get('buff_selection')
    if not buff_selection or not next(buff_selection) then
        return
    end

    if not buff_selection.voting_started then
        return
    end

    Core.iter_connected_players(function (player)
        if player and player.valid then
            if not buff_selection.voting_closed then
                local frame = player.gui.screen[main_frame_name]
                if not frame or not frame.valid then
                    local voted_index = buff_selection.all_votes[player.name] and buff_selection.all_votes[player.name].index
                    buff_main_frame(player, voted_index)
                else
                    local b = Gui.get_data(frame)
                    if b then
                        local minutes = math.floor((buff_selection.closing_timeout - game.tick) / 3600)
                        local minutes_str = minutes .. ' minutes left until voting closes.'
                        if minutes == 0 then
                            minutes_str = 'Less than 1 minute left until voting closes!'
                        elseif minutes == 1 then
                            minutes_str = 'Voting closes in 1 minute!'
                        end
                        b.caption = minutes_str
                    end
                end
            else
                clear_main_frame(player)
            end
        end
    end)

    buff_selection.closing_timeout = buff_selection.closing_timeout - 1

    if game.tick > buff_selection.closing_timeout and not buff_selection.voting_closed then
        buff_selection.voting_closed = true
        set_buffs_voting()
        local buff = buff_selection.buffs[buff_selection.index]
        if not buff then
            Server.output_script_data('buff not found while voting closed')

            local buff_fallback = Stateful.save_settings()
            Public.notify_won_to_discord(buff_fallback)
            local locomotive = Public.get('locomotive')
            if locomotive and locomotive.valid then
                locomotive.surface.spill_item_stack({ position = locomotive.position, stack = { name = 'coin', count = 512, quality = 'normal' } })
            end
            Public.set('game_reset_tick', 5400)

            Server.output_script_data('fallback buff granted')
            return
        end

        local str = 'Votes have closed! Buff granted: ' .. buff.name .. '!'
        game.print(str)
        Server.to_discord_embed(str)
        Public.set('game_reset_tick', 5400)
        Public.notify_won_to_discord(buff.raw)
        local locomotive = Public.get('locomotive')
        if locomotive and locomotive.valid then
            locomotive.surface.spill_item_stack({ position = locomotive.position, stack = { name = 'coin', count = 512, quality = 'normal' } })
        end

        Stateful.save_settings(buff.raw)

        return
    end
end)

function Public.clear_platforms()
    for _, surface in pairs(game.surfaces) do
        if surface and surface.valid then
            if string.match(surface.name, 'platform-.*') then
                Server.output_script_data('Clearing platform surface: ' .. surface.name)
                game.delete_surface(surface.name)
            end
        end
    end
end

Public.buff_main_frame = buff_main_frame

return Public
