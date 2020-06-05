local Event = require 'utils.event'
local RPG = require 'maps.mountain_fortress_v3.rpg'
local WPT = require 'maps.mountain_fortress_v3.table'
local Gui = require 'utils.gui'
local floor = math.floor
local format_number = require 'util'.format_number

local Public = {}
local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

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
    player.gui.top.add(
        {
            type = 'sprite-button',
            name = main_button_name,
            sprite = 'item/dummy-steel-axe',
            tooltip = 'Shows statistics!'
        }
    )
end

local function create_main_frame(player)
    local label
    local line
    if player.gui.top['wave_defense'] then
        player.gui.top['wave_defense'].visible = true
    end

    local frame = player.gui.top.add({type = 'frame', name = main_frame_name})
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

    label = frame.add({type = 'label', caption = ' ', name = 'train_upgrades'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not player then
        return
    end

    if not player.gui.top[main_button_name] then
        create_button(player)
    end
end

local function on_gui_click(event)
    local element = event.element
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end
    if not element.valid then
        return
    end

    local locomotive = WPT.get('locomotive')

    local name = element.name

    if name == main_button_name then
        if player.surface ~= locomotive.surface then
            local s = player.gui.left.icw_map
            if s and s.visible then
                player.gui.left.icw_map.visible = false
                return
            elseif s and not s.visible then
                player.gui.left.icw_map.visible = true
                return
            end
            return
        end
        if player.gui.top[main_frame_name] then
            local s = player.gui.top[main_frame_name]
            if s and s.visible then
                if player.gui.top['wave_defense'] then
                    player.gui.top['wave_defense'].visible = false
                end
                if player.gui.top['difficulty_gui'] then
                    player.gui.top['difficulty_gui'].visible = false
                end
                player.gui.top[main_frame_name].visible = false
                return
            elseif s and not s.visible then
                for _, child in pairs(player.gui.left.children) do
                    child.destroy()
                end
                if player.gui.top['wave_defense'] then
                    player.gui.top['wave_defense'].visible = true
                end
                if player.gui.top['difficulty_gui'] then
                    player.gui.top['difficulty_gui'].visible = true
                end
                player.gui.top[main_frame_name].visible = true
                return
            end
        else
            for _, child in pairs(player.gui.left.children) do
                child.destroy()
            end
            create_main_frame(player)
        end
    elseif name ~= main_button_name then
        if player.gui.top[main_frame_name] then
            local s = player.gui.top[main_frame_name]
            if s and s.visible then
                player.gui.top[main_frame_name].visible = false
                return
            end
        end
    end
end
local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local locomotive = WPT.get('locomotive')
    local icw_locomotive = WPT.get('icw_locomotive')
    local loco_surface = icw_locomotive.surface

    if player.gui.top[main_button_name] then
        player.gui.top[main_button_name].tooltip = 'Shows statistics!'
        player.gui.top[main_button_name].sprite = 'item/dummy-steel-axe'
    end

    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    if not loco_surface then
        return
    end
    if not loco_surface.valid then
        return
    end

    if player.surface == locomotive.surface then
        local s = player.gui.left.icw_map
        if s and s.visible then
            player.gui.left.icw_map.visible = false
        end
        player.gui.top[main_button_name].tooltip = 'Shows statistics!'
        player.gui.top[main_button_name].sprite = 'item/dummy-steel-axe'
    elseif player.surface == loco_surface then
        if player.gui.top['wave_defense'] then
            player.gui.top['wave_defense'].visible = false
        end
        if player.gui.top['difficulty_gui'] then
            player.gui.top['difficulty_gui'].visible = false
        end
        if player.gui.top[main_button_name] then
            player.gui.top[main_button_name].tooltip = 'Hide locomotive minimap!'
            player.gui.top[main_button_name].sprite = 'utility/map'
        end
        if player.gui.top[main_frame_name] then
            local vis = player.gui.top[main_frame_name].visible
            if vis then
                player.gui.top[main_frame_name].visible = false
                return
            end
        end
    end
end

function Public.update_gui(player)
    local rpg = RPG.get_table()
    local this = WPT.get()

    if not player.gui.top[main_frame_name] then
        return
    end

    if not player.gui.top[main_frame_name].visible then
        return
    end
    local gui = player.gui.top[main_frame_name]

    if rpg.global_pool == 0 then
        gui.global_pool.caption = 'XP: 0'
        gui.global_pool.tooltip = 'Dig, handcraft or run to increase the pool!'
    elseif rpg.global_pool > 0 then
        gui.global_pool.caption = 'XP: ' .. format_number(floor(rpg.global_pool), true)
        gui.global_pool.tooltip = 'Amount of XP that is stored inside the global xp pool.'
    end

    gui.scrap_mined.caption = ' [img=entity.tree-01][img=entity.rock-huge]: ' .. format_number(this.mined_scrap, true)
    gui.scrap_mined.tooltip = 'Amount of trees/rocks harvested.'

    gui.biters_killed.caption = ' [img=entity.small-biter]: ' .. format_number(this.biters_killed, true)
    gui.biters_killed.tooltip = 'Amount of biters killed.'

    gui.landmine.caption =
        ' [img=entity.land-mine]: ' ..
        format_number(this.upgrades.landmine.built, true) .. ' / ' .. format_number(this.upgrades.landmine.limit, true)
    gui.landmine.tooltip = 'Amount of land-mines that can be built.'

    gui.flame_turret.caption =
        ' [img=entity.flamethrower-turret]: ' ..
        format_number(this.upgrades.flame_turret.built, true) ..
            ' / ' .. format_number(this.upgrades.flame_turret.limit, true)
    gui.flame_turret.tooltip = 'Amount of flamethrower-turrets that can be built.'

    gui.train_upgrades.caption = ' [img=entity.locomotive]: ' .. format_number(this.train_upgrades, true)
    gui.train_upgrades.tooltip = 'Amount of train upgrades.'
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
