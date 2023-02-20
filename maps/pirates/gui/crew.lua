-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local Roles = require 'maps.pirates.roles.roles'
local Crew = require 'maps.pirates.crew'
local GuiCommon = require 'maps.pirates.gui.common'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'
local Public = {}

local window_name = 'crew'

local function get_selected_player_index(flow)
    if flow.members.body.members_listbox.selected_index ~= 0 then
        return tonumber(flow.members.body.members_listbox.get_item(flow.members.body.members_listbox.selected_index)[2])
    else
        return nil
    end
end

function Public.toggle_window(player)
    local memory = Memory.get_crew_memory()
    local get_global_memory = Memory.get_global_memory()
    local flow, flow2, flow3
    local window

    --*** OVERALL FLOW ***--
    if player.gui.screen[window_name .. '_piratewindow'] then
        player.gui.screen[window_name .. '_piratewindow'].destroy()
        return
    end

    if not Common.is_id_valid(memory.id) then
        return
    end

    window = GuiCommon.new_window(player, window_name)

    flow =
        window.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto-and-reserve-space'
    }
    flow.style.maximal_height = 500
    flow.style.bottom_margin = 10

    --*** PARAMETERS OF RUN ***--

    flow2 =
        flow.add(
        {
            name = 'crew_capacity_and_difficulty',
            type = 'label'
        }
    )
    flow2.style.left_margin = 5
    flow2.style.top_margin = 0
    flow2.style.bottom_margin = -3
    flow2.style.single_line = false
    flow2.style.maximal_width = 190
    flow2.style.font = 'default'

    flow2 =
        flow.add(
        {
            name = 'crew_age',
            type = 'label'
        }
    )
    flow2.style.left_margin = 5
    flow2.style.top_margin = -3
    flow2.style.bottom_margin = 0
    flow2.style.single_line = true
    flow2.style.maximal_width = 200
    flow2.style.font = 'default'

    -- flow2 = flow.add({
    -- 	name = 'crew_difficulty',
    -- 	type = 'label',
    -- })
    -- flow2.style.left_margin = 5
    -- flow2.style.top_margin = -3
    -- flow2.style.bottom_margin = 0
    -- flow2.style.single_line = false
    -- flow2.style.maximal_width = 190
    -- flow2.style.font = 'default'

    --*** MEMBERSHIP BUTTONS ***--

    flow2 =
        flow.add(
        {
            name = 'membership_buttons',
            type = 'flow',
            direction = 'horizontal'
        }
    )

    flow3 =
        flow2.add(
        {
            name = 'leave_crew',
            type = 'button',
            caption = {'pirates.gui_crew_window_buttons_quit_crew'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_buttons_quit_crew_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'leave_spectators',
            type = 'button',
            caption = {'pirates.gui_crew_window_buttons_quit_spectators'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}

    flow3 =
        flow2.add(
        {
            name = 'spectator_join_crew',
            type = 'button',
            caption = {'pirates.gui_crew_window_buttons_join_crew'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}

    flow3 =
        flow2.add(
        {
            name = 'crewmember_join_spectators',
            type = 'button',
            caption = {'pirates.gui_crew_window_buttons_join_spectators'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_buttons_join_spectators_tooltip'}

    --*** MEMBERS AND SPECTATORS ***--

    flow2 = GuiCommon.flow_add_section(flow, 'members', {'pirates.gui_crew_window_crewmembers'})

    flow3 =
        flow2.add(
        {
            name = 'members_listbox',
            type = 'list-box'
        }
    )
    flow3.style.margin = 5
    flow3.style.maximal_height = 350

    flow3 =
        flow2.add(
        {
            name = 'officer_resign',
            type = 'button',
            caption = {'pirates.gui_crew_window_crewmembers_resign_as_officer'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_crewmembers_resign_as_officer_tooltip'}

    flow2 = GuiCommon.flow_add_section(flow, 'spectators', {'pirates.gui_crew_window_spectators'})

    flow3 =
        flow2.add(
        {
            name = 'spectators_listbox',
            type = 'list-box'
        }
    )
    flow3.style.margin = 2
    flow3.style.maximal_height = 150

    --*** DIFFICULTY VOTE ***--

    flow2 = GuiCommon.flow_add_section(flow, 'difficulty_vote', {'pirates.gui_crew_window_vote_for_difficulty'})

    for i, o in ipairs(CoreData.difficulty_options) do
        flow3 =
            flow2.add(
            {
                name = 'difficulty_option_' .. i,
                type = 'button',
                caption = o.text
            }
        )
        flow3.style.minimal_width = 95
        flow3.style.font = 'default-bold'
        flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    end

    --*** CAPTAIN's ACTIONS ***--

    flow2 = GuiCommon.flow_add_section(flow, 'captain', {'pirates.gui_crew_window_captains_actions'})

    if get_global_memory.disband_crews then
        flow3 =
            flow2.add(
            {
                name = 'capn_disband_crew',
                type = 'button',
                caption = {'pirates.gui_crew_window_captains_actions_disband_crew'}
            }
        )
        flow3.style.minimal_width = 95
        flow3.style.font = 'default-bold'
        flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
        flow3.tooltip = {'pirates.gui_crew_window_captains_actions_disband_crew_tooltip'}

        flow3 =
            flow2.add(
            {
                name = 'capn_disband_are_you_sure',
                type = 'button',
                caption = {'pirates.gui_crew_window_captains_actions_disband_crew_check'}
            }
        )
        flow3.style.minimal_width = 95
        flow3.style.font = 'default-bold'
        flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
        flow3.tooltip = {'pirates.gui_crew_window_captains_actions_disband_crew_check_tooltip'}
    end

    flow3 =
        flow2.add(
        {
            name = 'capn_renounce',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_renounce_title'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_renounce_title_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'capn_pass',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_pass_title'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_pass_title_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'capn_plank',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_plank'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_plank_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'line',
            type = 'line'
        }
    )
    flow3.style.width = 50
    flow3.style.left_margin = 20
    flow3.style.top_margin = 4
    flow3.style.bottom_margin = 4

    -- flow3 = flow2.add({
    -- 	name = 'capn_undock_normal',
    -- 	type = 'button',
    -- 	caption = 'Undock Boat',
    -- })
    -- flow3.style.minimal_width = 95
    -- flow3.style.font = 'default-bold'
    -- flow3.style.font_color = {r=0.10, g=0.10, b=0.10}

    flow3 =
        flow2.add(
        {
            name = 'make_officer',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_make_officer'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_make_officer_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'unmake_officer',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_unmake_officer'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_unmake_officer_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'capn_summon_crew',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_summon_crew'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_summon_crew_tooltip'}

    flow3 =
        flow2.add(
        {
            name = 'capn_requisition',
            type = 'button',
            caption = {'pirates.gui_crew_window_captains_actions_tax'}
        }
    )
    flow3.style.minimal_width = 95
    flow3.style.font = 'default-bold'
    flow3.style.font_color = {r = 0.10, g = 0.10, b = 0.10}
    flow3.tooltip = {'pirates.gui_crew_window_captains_actions_tax_tooltip', Common.coin_tax_percentage}

    flow2 =
        flow.add(
        {
            name = 'undock_tip',
            type = 'label'
        }
    )
    flow2.style.left_margin = 5
    flow2.style.top_margin = -8
    flow2.style.bottom_margin = 7
    flow2.style.single_line = false
    flow2.style.maximal_width = 190
    flow2.style.font = 'default'
    flow2.caption = {'pirates.gui_crew_window_captains_actions_undock_tip'}

    GuiCommon.flow_add_close_button(window, window_name .. '_piratebutton')
end

-- function Public.regular_update(player)

-- end

function Public.full_update(player)
    if Public.regular_update then
        Public.regular_update(player)
    end

    if not player.gui.screen[window_name .. '_piratewindow'] then
        return
    end
    local window = player.gui.screen[window_name .. '_piratewindow']
    local flow = window.scroll_pane

    local memory = Memory.get_crew_memory()
    local playercrew_status = GuiCommon.crew_overall_state_bools(player.index)

    --*** WHAT TO SHOW ***--

    flow.difficulty_vote.visible = memory.overworldx and memory.overworldx == 0

    flow.members.body.officer_resign.visible = Common.is_officer(player.index)

    local selected_player_index = get_selected_player_index(flow)
    local other_player_selected = flow.members.body.members_listbox.selected_index ~= 0 and selected_player_index ~= player.index

    flow.captain.visible = Common.is_captain(player)
    flow.undock_tip.visible = Common.is_captain(player)

    flow.captain.body.capn_pass.visible = other_player_selected
    flow.captain.body.capn_plank.visible = other_player_selected

    flow.captain.body.make_officer.visible = other_player_selected and (not Common.is_officer(selected_player_index))
    flow.captain.body.unmake_officer.visible = other_player_selected and Common.is_officer(selected_player_index)

    -- flow.captain.body.capn_undock_normal.visible = memory.boat and memory.boat.state and ((memory.boat.state == Boats.enum_state.LANDED) or (memory.boat.state == Boats.enum_state.APPROACHING) or (memory.boat.state == Boats.enum_state.DOCKED))

    flow.captain.body.capn_summon_crew.visible = false
    flow.captain.body.capn_requisition.visible = true
    -- flow.captain.body.capn_summon_crew.visible = memory.boat and memory.boat.state and (memory.boat.state == Boats.enum_state.RETREATING or memory.boat.state == Boats.enum_state.LEAVING_DOCK)

    local get_global_memory = Memory.get_global_memory()

    if get_global_memory.disband_crews then
        flow.captain.body.capn_disband_are_you_sure.visible = memory.disband_are_you_sure_ticks and memory.disband_are_you_sure_ticks[player.index] and memory.disband_are_you_sure_ticks[player.index] > game.tick - 60 * 2
        flow.captain.body.capn_disband_crew.visible = not flow.captain.body.capn_disband_are_you_sure.visible
    end

    flow.members.visible = true
    flow.spectators.visible = (#memory.spectatorplayerindices > 0)
    -- flow.crew_age.visible = true
    -- -- flow.crew_age.visible = memory.mode and memory.mode == 'speedrun'
    -- flow.crew_difficulty.visible = true

    local count = 0
    if playercrew_status.spectating then
        for _, v in pairs(memory.crewplayerindices) do
            if Common.validate_player(game.players[v]) then
                count = count + 1
            end
        end
    end
    flow.membership_buttons.spectator_join_crew.visible = playercrew_status.spectating and (not (count >= memory.capacity)) and (not memory.run_is_private)

    flow.membership_buttons.leave_crew.visible = playercrew_status.adventuring
    -- flow.membership_buttons.crewmember_join_spectators.visible = playercrew_status.adventuring
    flow.membership_buttons.crewmember_join_spectators.visible = false --disabled spectators for now... might not play well with maze world
    flow.membership_buttons.leave_spectators.visible = playercrew_status.spectating

    flow.membership_buttons.spectator_join_crew.visible =
        flow.membership_buttons.spectator_join_crew.visible and (not (memory.tempbanned_from_joining_data[player.index] and game.tick < memory.tempbanned_from_joining_data[player.index] + Common.ban_from_rejoining_crew_ticks))

    --== UPDATE CONTENT ==--

    if Common.is_id_valid(memory.id) then
        window.caption = memory.name

        flow.crew_age.caption = {'pirates.gui_crew_window_crew_age', Utils.time_mediumform((memory.age or 0) / 60)}
        flow.crew_capacity_and_difficulty.caption = {'pirates.gui_crew_window_crew_capacity_and_difficulty', CoreData.difficulty_options[memory.difficulty_option].text, CoreData.capacity_options[memory.capacity_option].text3}
    end

    if flow.members.visible then
        local wrappedcrew = {}
        for _, index in pairs(memory.crewplayerindices) do
            local player2 = game.players[index]
            local tag_text = Roles.tag_text(player2)

            wrappedcrew[#wrappedcrew + 1] = {'pirates.crewmember_displayform', index, player2.color.r, player2.color.g, player2.color.b, player2.name, tag_text}
        end
        GuiCommon.update_listbox(flow.members.body.members_listbox, wrappedcrew)

        flow.members.header.caption = {'pirates.gui_crew_window_crew_count', (#memory.crewplayerindices or 0)}
    end

    if flow.spectators.visible then
        local wrappedspectators = {}
        for _, index in pairs(memory.spectatorplayerindices) do
            local player2 = game.players[index]

            wrappedspectators[#wrappedspectators + 1] = {'pirates.crewmember_displayform', index, player2.color.r, player2.color.g, player2.color.b, player2.name, ''}
        end
        GuiCommon.update_listbox(flow.spectators.body.spectators_listbox, wrappedspectators)
    end

    -- if flow.captain.body.capn_undock_normal.visible then
    -- 	flow.captain.body.capn_undock_normal.enabled = ((memory.boat.state == Boats.enum_state.LANDED) and Common.query_can_pay_cost_to_leave()) or (memory.boat.state == Boats.enum_state.DOCKED)
    -- end
end

function Public.click(event)
    -- This is only needed since we call click on every single GUI element and if element gets destroyed, it's no good (these checks wouldn't be needed (I think) if GUI was purely event driven)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end

    local player = game.players[event.element.player_index]

    local eventname = event.element.name

    if not player.gui.screen[window_name .. '_piratewindow'] then
        return
    end
    local window = player.gui.screen[window_name .. '_piratewindow']
    local flow = window.scroll_pane

    local memory = Memory.get_crew_memory()

    if eventname == 'crewmember_join_spectators' then
        Crew.join_spectators(player, memory.id)
        return
    end

    if eventname == 'leave_spectators' then
        Crew.leave_spectators(player)
        return
    end

    if eventname == 'spectator_join_crew' then
        Crew.join_crew(player, memory.id)

        if memory.run_is_protected and (not Roles.captain_exists()) then
            Common.notify_player_expected(player, {'pirates.player_joins_protected_run_with_no_captain'})
            Common.notify_player_expected(player, {'pirates.create_new_crew_tip'})
        end
        return
    end

    if eventname == 'leave_crew' then
        Crew.leave_crew(player, true)
        return
    end

    -- if eventname == 'promote_officer' then
    -- 	Roles.promote_to_officer(player)
    -- 	return
    -- end

    -- if eventname == 'demote_officer' then
    -- 	Roles.demote_to_officer(player)
    -- 	return
    -- end

    if string.sub(eventname, 1, 18) and string.sub(eventname, 1, 18) == 'difficulty_option_' then
        Crew.difficulty_vote(player.index, tonumber(string.sub(eventname, 19, -1)))
        return
    end

    if eventname == 'capn_summon_crew' then
        --double check:
        if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
            Crew.summon_crew()
        end
        return
    end

    if eventname == 'capn_requisition' then
        --double check:
        if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
            Roles.captain_tax(memory.playerindex_captain)
        end
        return
    end

    if eventname == 'capn_renounce' then
        Roles.renounce_captainhood(player)
        return
    end

    if eventname == 'officer_resign' then
        Roles.resign_as_officer(player)
        return
    end

    if eventname == 'capn_disband_crew' then
        --double check:
        if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
            if not memory.disband_are_you_sure_ticks then
                memory.disband_are_you_sure_ticks = {}
            end
            memory.disband_are_you_sure_ticks[player.index] = game.tick
        end
        return
    end

    if eventname == 'capn_disband_are_you_sure' then
        --double check:
        if Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN then
            local force = memory.force
            if force and force.valid then
                local message = {'pirates.crew_disbanded', player.name, memory.name, Utils.time_longform((memory.real_age or 0) / 60)}
                Common.notify_game(message)
                Server.to_discord_embed_raw({'', CoreData.comfy_emojis.trashbin .. '[' .. memory.name .. '] ', message}, true)
            end
            Crew.disband_crew(true)
        end
        return
    end

    if eventname == 'capn_pass' then
        local other_id = get_selected_player_index(flow)
        Roles.pass_captainhood(player, game.players[other_id])
        return
    end

    if eventname == 'make_officer' then
        local other_id = get_selected_player_index(flow)
        Roles.make_officer(player, game.players[other_id])
        return
    end

    if eventname == 'unmake_officer' then
        local other_id = get_selected_player_index(flow)
        Roles.unmake_officer(player, game.players[other_id])
        return
    end

    if eventname == 'capn_plank' then
        local other_id = get_selected_player_index(flow)

        Crew.plank(player, game.players[other_id])
        return
    end
end

return Public
