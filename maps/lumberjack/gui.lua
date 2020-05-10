local RPG = require 'maps.lumberjack.rpg'
local WPT = require 'maps.lumberjack.table'
local floor = math.floor
local format_number = require 'util'.format_number

local function create_gui(player)
    local label
    local line

    local frame = player.gui.top.add({type = 'frame', name = 'lumberjack'})
    frame.style.minimal_height = 38
    frame.style.maximal_height = 38

    label = frame.add({type = 'label', caption = ' ', name = 'label'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    label = frame.add({type = 'label', caption = ' ', name = 'global_pool'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'scrap_mined'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'biters_killed'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    line = frame.add({type = 'line', direction = 'vertical'})
    line.style.left_padding = 4
    line.style.right_padding = 4

    label = frame.add({type = 'label', caption = ' ', name = 'train_upgrades'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
end

local function update_gui(player)
    local rpg = RPG.get_table()
    local st = WPT.get_table()

    if not player.gui.top.lumberjack then
        create_gui(player)
    end
    local gui = player.gui.top.lumberjack

    if rpg.global_pool == 0 then
        gui.global_pool.caption = 'XP: 0'
        gui.global_pool.tooltip = 'Dig, handcraft or run to increase the pool!'
    elseif rpg.global_pool > 0 then
        gui.global_pool.caption = 'XP: ' .. format_number(floor(rpg.global_pool), true)
        gui.global_pool.tooltip = 'Get this number over 5k to get some of this mad XP! \\o/'
    end

    gui.scrap_mined.caption = ' [img=entity.tree-01][img=entity.rock-huge]: ' .. format_number(st.mined_scrap, true)
    gui.scrap_mined.tooltip = 'Amount of trees/rocks harvested.'

    gui.biters_killed.caption = ' [img=entity.small-biter]: ' .. format_number(st.biters_killed, true)
    gui.biters_killed.tooltip = 'Amount of biters killed.'

    gui.train_upgrades.caption = ' [img=entity.locomotive]: ' .. format_number(st.train_upgrades, true)
    gui.train_upgrades.tooltip = 'Amount of train upgrades.'
end

return update_gui
