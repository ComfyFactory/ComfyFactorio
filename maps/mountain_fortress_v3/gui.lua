local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local RPG = require 'modules.rpg.main'
local IC_Gui = require 'maps.mountain_fortress_v3.ic.gui'
local IC_Minimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local SpamProtection = require 'utils.spam_protection'
local Polls = require 'utils.gui.poll'
local BottomFrame = require 'utils.gui.bottom_frame'

local format_number = require 'util'.format_number

local main_button_name = Gui.uid_name()
local spectate_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local floor = math.floor

local function validate_entity(entity)
    if not (entity and entity.valid) then
        return false
    end

    return true
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

local function create_button(player)
    local b =
        player.gui.top.add(
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'item/dummy-steel-axe',
            tooltip = 'Shows statistics!',
            style = Gui.button_style
        }
    )
    b.style.minimal_height = 38
    b.style.maximal_height = 38
end

local function spectate_button(player)
    if player.gui.top[spectate_button_name] then
        return
    end

    if Public.get('final_battle') then
        return
    end

    local b =
        player.gui.top.add {
        type = 'sprite-button',
        name = spectate_button_name,
        sprite = 'utility/ghost_time_to_live_modifier_icon',
        tooltip = 'Spectate!\nThis will kill your character.',
        style = Gui.button_style
    }

    b.style.maximal_height = 38
end

local function create_main_frame(player)
    local label
    local line
    if player.gui.top['wave_defense'] then
        player.gui.top['wave_defense'].visible = true
    end

    local frame = player.gui.top.add({type = 'frame', name = main_frame_name, style = 'finished_game_subheader_frame'})
    frame.location = {x = 1, y = 40}
    frame.style.minimal_height = 38
    frame.style.maximal_height = 38

    label = frame.add({type = 'label', caption = ' ', name = 'label'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'

    label = frame.add({type = 'label', caption = ' ', name = 'global_pool'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'scrap_mined'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'pickaxe_tier'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'biters_killed'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'landmine'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'flame_turret'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'train_upgrade_contribution'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'defense_enabled'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
end

local function hide_all_gui(player)
    for _, child in pairs(player.gui.top.children) do
        if child.name ~= spectate_button_name and child.name ~= 'minimap_button' and child.name ~= 'wave_defense' then
            child.visible = false
        end
    end
end

local function show_all_gui(player)
    for _, child in pairs(player.gui.top.children) do
        if child.name ~= spectate_button_name and child.name ~= 'minimap_button' then
            child.visible = true
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end

    if not player.gui.top[spectate_button_name] then
        spectate_button(player)
    end

    if not player.gui.top[main_button_name] then
        create_button(player)
    end
end

local function changed_surface(player)
    local main_toggle_button_name = Gui.main_toggle_button_name
    local poll_button = Polls.main_button_name
    local rpg_button = RPG.draw_main_frame_name
    local rpg_frame = RPG.main_frame_name
    local rpg_settings = RPG.settings_frame_name
    local main = Public.get('locomotive')
    local icw_locomotive = Public.get('icw_locomotive')
    local wagon_surface = icw_locomotive.surface
    local main_toggle_button = player.gui.top[main_toggle_button_name]
    local info = player.gui.top[main_button_name]
    local wd = player.gui.top['wave_defense']
    local spectate = player.gui.top[spectate_button_name]
    local minimap_button = player.gui.top['minimap_button']
    local rpg_b = player.gui.top[rpg_button]
    local poll_b = player.gui.top[poll_button]
    local rpg_f = player.gui.screen[rpg_frame]
    local rpg_s = player.gui.screen[rpg_settings]
    local diff = player.gui.top[Difficulty.top_button_name]
    local charging = player.gui.top['charging_station']
    local charging_frame = BottomFrame.get_section(player, 'charging_station')
    local frame = player.gui.top[main_frame_name]
    local spell_gui_frame_name = RPG.spell_gui_frame_name
    local spell_cast_buttons = player.gui.screen[spell_gui_frame_name]

    if info then
        info.tooltip = ({'gui.info_tooltip'})
        info.sprite = 'item/dummy-steel-axe'
    end

    if not main then
        return
    end
    if not main.valid then
        return
    end

    if not wagon_surface then
        return
    end
    if not wagon_surface.valid then
        return
    end

    if player.surface == main.surface then
        local minimap = player.gui.left.icw_main_frame
        if main_toggle_button and not main_toggle_button.visible then
            main_toggle_button.visible = true
        end
        if minimap and minimap.visible then
            minimap.visible = false
        end
        if rpg_b and not rpg_b.visible then
            rpg_b.visible = true
        end
        if poll_b and not poll_b.visible then
            poll_b.visible = true
        end
        if minimap_button and not minimap_button.visible then
            minimap_button.visible = false
        end
        if spell_cast_buttons and not spell_cast_buttons.visible then
            spell_cast_buttons.visible = true
        end
        if diff and not diff.visible then
            diff.visible = true
        end
        if wd and not wd.visible then
            wd.visible = true
        end
        if spectate and not spectate.visible then
            spectate.visible = true
        end
        if charging and not charging.visible then
            charging.visible = true
        end
        if charging_frame and not charging_frame.enabled then
            charging_frame.enabled = true
        end
        if info then
            info.tooltip = ({'gui.info_tooltip'})
            info.sprite = 'item/dummy-steel-axe'
            info.visible = true
        end
    elseif player.surface == wagon_surface then
        if main_toggle_button and main_toggle_button.visible then
            main_toggle_button.visible = false
        end
        if wd then
            wd.visible = false
        end
        if spectate then
            spectate.visible = false
        end
        if minimap_button and not minimap_button.visible then
            minimap_button.visible = false
        end
        if rpg_b then
            rpg_b.visible = false
        end
        if poll_b then
            poll_b.visible = false
        end
        if spell_cast_buttons and spell_cast_buttons.visible then
            spell_cast_buttons.visible = false
        end
        if rpg_f then
            rpg_f.destroy()
        end
        if rpg_s then
            rpg_s.destroy()
        end
        if diff then
            diff.visible = false
        end
        if charging then
            charging.visible = false
        end
        if charging_frame and charging_frame.enabled then
            charging_frame.enabled = false
        end
        if info then
            info.tooltip = ({'gui.hide_minimap'})
            info.sprite = 'utility/map'
            info.visible = true
        end
        if player.gui.top[main_frame_name] then
            if frame then
                frame.visible = false
                return
            end
        end
    else
        if main_toggle_button and main_toggle_button.visible then
            main_toggle_button.visible = false
        end
        if poll_b then
            poll_b.visible = false
        end
        if rpg_b then
            rpg_b.visible = false
        end
        if spectate then
            spectate.visible = false
        end
        if info and info.visible then
            info.visible = false
        end
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element.valid then
        return
    end

    local name = element.name

    if name == main_button_name then
        local player = game.players[event.player_index]
        if not validate_player(player) then
            return
        end
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Mtn Gui Click')
        if is_spamming then
            return
        end

        local locomotive = Public.get('locomotive')
        if not validate_entity(locomotive) then
            return
        end

        if not player or not player.valid then
            return
        end
        if not player.surface or not player.surface.valid then
            return
        end
        if player.surface ~= locomotive.surface then
            local minimap = player.gui.left.icw_main_frame
            if minimap and minimap.visible then
                minimap.visible = false
                return
            elseif minimap and not minimap.visible then
                minimap.visible = true
                return
            end
            return
        end
        if player.gui.top[main_frame_name] then
            local info = player.gui.top[main_frame_name]
            local wd = player.gui.top['wave_defense']
            local diff = player.gui.top[Difficulty.top_button_name]

            if info and info.visible then
                if wd then
                    wd.visible = false
                end
                if diff then
                    diff.visible = false
                end
                info.visible = false
                return
            elseif wd and not wd.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if wd then
                    wd.visible = true
                end
                if diff then
                    diff.visible = true
                end
                return
            elseif info and not info.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if wd then
                    wd.visible = true
                end
                if diff then
                    diff.visible = true
                end
                info.visible = true
                return
            end
        else
            for _, child in pairs(player.gui.left.children) do
                child.destroy()
            end
            create_main_frame(player)
        end
    end
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end
    changed_surface(player)
end

local function enable_guis(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local main_toggle_button_name = Gui.main_toggle_button_name
    local main_toggle_button = player.gui.top[main_toggle_button_name]
    local rpg_button = RPG.draw_main_frame_name
    local info = player.gui.top[main_button_name]
    local wd = player.gui.top['wave_defense']
    local spectate = player.gui.top[spectate_button_name]
    local rpg_b = player.gui.top[rpg_button]
    local diff = player.gui.top[Difficulty.top_button_name]
    local charging = player.gui.top['charging_station']
    local charging_frame = BottomFrame.get_section(player, 'charging_station')

    IC_Gui.remove_toolbar(player)
    IC_Minimap.toggle_button(player)

    if info then
        info.tooltip = ({'gui.info_tooltip'})
        info.sprite = 'item/dummy-steel-axe'
    end

    if main_toggle_button and not main_toggle_button.visible then
        main_toggle_button.visible = false
    end

    local minimap = player.gui.left.icw_main_frame
    if minimap and minimap.visible then
        minimap.visible = false
    end

    if rpg_b and not rpg_b.visible then
        rpg_b.visible = true
    end

    if diff and not diff.visible then
        diff.visible = true
    end
    if wd and not wd.visible then
        wd.visible = true
    end
    if spectate and not spectate.visible then
        spectate.visible = true
    end
    if charging and not charging.visible then
        charging.visible = true
    end
    if charging_frame and not charging_frame.enabled then
        charging_frame.enabled = true
    end
    if info then
        info.tooltip = ({'gui.info_tooltip'})
        info.sprite = 'item/dummy-steel-axe'
        info.visible = true
    end
end

function Public.update_gui(player)
    if not validate_player(player) then
        return
    end

    if not player.gui.top[main_frame_name] then
        return
    end

    if not player.gui.top[main_frame_name].visible then
        return
    end
    local gui = player.gui.top[main_frame_name]

    local rpg_extra = RPG.get('rpg_extra')
    local mined_scrap = Public.get('mined_scrap')
    local biters_killed = Public.get('biters_killed')
    local upgrades = Public.get('upgrades')

    if rpg_extra.global_pool == 0 then
        gui.global_pool.caption = 'XP: 0'
        gui.global_pool.tooltip = ({'gui.global_pool_tooltip'})
    elseif rpg_extra.global_pool >= 0 then
        gui.global_pool.caption = 'XP: ' .. format_number(floor(rpg_extra.global_pool), true)
        gui.global_pool.tooltip = ({'gui.global_pool_amount', floor(rpg_extra.global_pool)})
    end

    gui.scrap_mined.caption = ' [img=entity.tree-01][img=entity.rock-huge]: ' .. format_number(mined_scrap, true)
    gui.scrap_mined.tooltip = ({'gui.amount_harvested'})

    local pickaxe_upgrades = Public.pickaxe_upgrades
    local pick_tier = pickaxe_upgrades[upgrades.pickaxe_tier]
    local speed = math.round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100)
    local train_upgrade_contribution = upgrades.train_upgrade_contribution
    if upgrades.train_upgrade_contribution > 0 then
        train_upgrade_contribution = upgrades.train_upgrade_contribution / 1000
    end

    gui.pickaxe_tier.caption = ' [img=item.dummy-steel-axe]: ' .. pick_tier .. ' (' .. upgrades.pickaxe_tier .. ')'
    gui.pickaxe_tier.tooltip = ({'gui.current_pickaxe_tier', pick_tier, speed})

    gui.biters_killed.caption = ' [img=entity.small-biter]: ' .. format_number(biters_killed, true)
    gui.biters_killed.tooltip = ({'gui.biters_killed'})

    gui.landmine.caption = ' [img=entity.land-mine]: ' .. format_number(upgrades.landmine.built, true) .. ' / ' .. format_number(upgrades.landmine.limit, true)
    gui.landmine.tooltip = ({'gui.land_mine_placed'})

    gui.flame_turret.caption = ' [img=entity.flamethrower-turret]: ' .. format_number(upgrades.flame_turret.built, true) .. ' / ' .. format_number(upgrades.flame_turret.limit, true)
    gui.flame_turret.tooltip = ({'gui.flamethrowers_placed'})

    gui.train_upgrade_contribution.caption = ' [img=entity.locomotive]: ' .. train_upgrade_contribution .. 'k'
    gui.train_upgrade_contribution.tooltip = ({'gui.train_upgrade_contribution'})

    local robotics_deployed = Public.get('robotics_deployed')

    if robotics_deployed then
        gui.defense_enabled.caption = ' [img=item.destroyer-capsule]: Deployed'
        gui.defense_enabled.tooltip = ({'gui.robotics_deployed'})
    else
        gui.defense_enabled.caption = ' [img=item.destroyer-capsule]: Standby'
        gui.defense_enabled.tooltip = ({'gui.robotics_standby'})
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(Public.events.reset_map, enable_guis)

Gui.on_click(
    spectate_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Mtn v3 Spectate Button')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        if Public.get('final_battle') then
            return player.print('Not possible during the final battle.', Color.warning)
        end

        if player.character and player.character.valid then
            local success = Public.set_player_to_spectator(player)
            if success then
                hide_all_gui(player)
            end
        else
            local success = Public.set_player_to_god(player)
            if success then
                show_all_gui(player)
            end
        end
    end
)

Public.changed_surface = changed_surface

return Public
