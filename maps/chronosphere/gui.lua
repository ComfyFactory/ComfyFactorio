local Chrono_table = require 'maps.chronosphere.table'
local Public_gui = {}

local math_floor = math.floor
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local Upgrades = require 'maps.chronosphere.upgrade_list'
local Production = require 'maps.chronosphere.production_list'
local ProdFunctions = require 'maps.chronosphere.production'
local Balance = require "maps.chronosphere.balance"
local Difficulty = require 'modules.difficulty_vote'
local Minimap = require 'maps.chronosphere.minimap'

local function create_gui(player)
    local frame = player.gui.top.add({type = 'frame', name = 'chronosphere'})
    frame.style.maximal_height = 38
    local label
    local button

    label = frame.add({type = 'label', caption = ' ', name = 'label'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    label = frame.add({type = 'label', caption = ' ', name = 'jump_number'})
    label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
    label.style.font = 'default-bold'
    label.style.right_padding = 4
    label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

    label = frame.add({type = 'label', caption = ' ', name = 'charger'})
    label.style.font = 'default-bold'
    label.style.left_padding = 4
    label.style.font_color = {r = 255, g = 200, b = 200} --255 200 200 --150 0 255

    label = frame.add({type = 'label', caption = ' ', name = 'charger_value'})
    label.style.font = 'default-bold'
    label.style.right_padding = 1
    label.style.minimal_width = 10
    label.style.font_color = {r = 255, g = 200, b = 200}

    local progressbar = frame.add({type = 'progressbar', name = 'progressbar', value = 0})
    progressbar.style = 'achievement_progressbar'
    progressbar.style.minimal_width = 96
    progressbar.style.maximal_width = 96
    progressbar.style.top_padding = 1

    label = frame.add({type = 'label', caption = ' ', name = 'timer'})
    label.style.font = 'default-bold'
    label.style.right_padding = 1
    label.style.minimal_width = 10
    label.style.font_color = {r = 255, g = 200, b = 200}

    label = frame.add({type = 'label', caption = ' ', name = 'timer_value', tooltip = ' '})
    label.style.font = 'default-bold'
    label.style.right_padding = 1
    label.style.minimal_width = 10
    label.style.font_color = {r = 255, g = 200, b = 200}

    label = frame.add({type = 'label', caption = ' ', name = 'timer2'})
    label.style.font = 'default-bold'
    label.style.right_padding = 1
    label.style.minimal_width = 10
    label.style.font_color = {r = 0, g = 200, b = 0}

    label = frame.add({type = 'label', caption = ' ', name = 'timer_value2'})
    label.style.font = 'default-bold'
    label.style.right_padding = 1
    label.style.minimal_width = 10
    label.style.font_color = {r = 0, g = 200, b = 0}

    -- local line = frame.add({type = "line", direction = "vertical"})
    -- line.style.left_padding = 4
    -- line.style.right_padding = 8

    button = frame.add({type = 'button', caption = ' ', name = 'world_button'})
    button.style.font = 'default-bold'
    button.style.font_color = {r = 0.99, g = 0.99, b = 0.99}
    button.style.minimal_width = 75

    button = frame.add({type = 'button', caption = ' ', name = 'upgrades_button'})
    button.style.font = 'default-bold'
    button.style.font_color = {r = 0.99, g = 0.99, b = 0.99}
    button.style.minimal_width = 75
end

local function switch_upgrades(player, button)
    local playertable = Chrono_table.get_player_table()
    if not button then
        button = 1
    end
    playertable.active_upgrades_gui[player.index] = button
    local upgrades = Upgrades.upgrades()
    if not player.gui.screen['gui_upgrades'] then
        return
    end
    local frame = player.gui.screen['gui_upgrades']
    local t2 = frame['production_table']
    if button == 4 then
        t2.visible = true
        for i = 1, #upgrades, 1 do
            frame['upgrades_table' .. i].visible = false
        end
    else
        t2.visible = false
        for i = 1, #upgrades, 1 do
            local t = frame['upgrades_table' .. i]
            if button == 1 then
                if upgrades[i].type == 'train' and upgrades[i].enabled then
                    t.visible = true
                else
                    t.visible = false
                end
            elseif button == 2 then
                if upgrades[i].type == 'player' and upgrades[i].enabled then
                    t.visible = true
                else
                    t.visible = false
                end
            elseif button == 3 then
                if upgrades[i].type == 'quest' and upgrades[i].enabled then
                    t.visible = true
                else
                    t.visible = false
                end
            end
        end
    end
end

local function calculate_xp(key)
	local production_table = Chrono_table.get_production_table()
	local level = ProdFunctions.calculate_factory_level(production_table.experience[key], false)
	return level - math.floor(level)
end

local function update_upgrades_gui(player)
    local objective = Chrono_table.get_table()
    local playertable = Chrono_table.get_player_table()
    local production_table = Chrono_table.get_production_table()
    if not player.gui.screen['gui_upgrades'] then
        return
    end
    local upgrades = Upgrades.upgrades()
    local frame = player.gui.screen['gui_upgrades']
    local tokens = frame['tokens']
    for token, value in pairs(objective.research_tokens) do
        tokens['token_' .. token].number = value
    end

    for i = 1, #upgrades, 1 do
        local t = frame['upgrades_table' .. i]
        t['upgrade' .. i].number = objective.upgrades[i]
        t['upgrade' .. i].tooltip = upgrades[i].tooltip
        t['upgrade_label' .. i].tooltip = upgrades[i].tooltip

        if objective.upgrades[i] == upgrades[i].max_level then
            t['maxed' .. i].visible = true
            t['jump_req' .. i].visible = false
            for index, _ in pairs(upgrades[i].virtual_cost) do
                t[index .. '-v' .. i].visible = false
            end
            for index, _ in pairs(upgrades[i].cost) do
                t[index .. '-' .. i].visible = false
            end
        else
            t['maxed' .. i].visible = false
            t['jump_req' .. i].visible = true
            t['jump_req' .. i].number = upgrades[i].jump_limit
            for index, item in pairs(upgrades[i].virtual_cost) do
                t[index .. '-v' .. i].visible = true
                t[index .. '-v' .. i].number = item.count
            end
            for index, item in pairs(upgrades[i].cost) do
                t[index .. '-' .. i].visible = true
                t[index .. '-' .. i].number = item.count
            end
        end
    end
    local t2 = frame['production_table']
    for key, product in pairs(Production) do
        t2['product' .. key].number = math.floor((production_table.experience[key] / 1000) ^ (1 / 2))
        t2['product_bar' .. key].value = calculate_xp(key)
        t2['product_bar' .. key].tooltip = math.floor(calculate_xp(key) * 1000) / 10 .. '%'
    end
    switch_upgrades(player, playertable.active_upgrades_gui[player.index])
end

local function world_gui(player)
    local objective = Chrono_table.get_table()
    if player.gui.screen['gui_world'] then
        player.gui.screen['gui_world'].destroy()
        return
    end
    local world = objective.world
    local evolution = game.forces['enemy'].evolution_factor
    local frame = player.gui.screen.add {type = 'frame', name = 'gui_world', caption = {'chronosphere.gui_world_button'}, direction = 'vertical'}
    frame.location = {x = 650, y = 45}
    frame.style.minimal_height = 300
    frame.style.maximal_height = 500
    frame.style.minimal_width = 200
    frame.style.maximal_width = 400
    local l = {}
    l[1] = frame.add({type = 'label', name = 'world_name', caption = {'chronosphere.gui_world_0', world.variant.name}})
    l[2] = frame.add({type = 'label', caption = {'chronosphere.gui_world_1'}})
    local table0 = frame.add({type = 'table', name = 'world_ores', column_count = 3})
    table0.add({type = 'sprite-button', name = 'iron-ore', sprite = 'item/iron-ore', enabled = false, number = world.variant.fe})
    table0.add({type = 'sprite-button', name = 'copper-ore', sprite = 'item/copper-ore', enabled = false, number = world.variant.cu})
    table0.add({type = 'sprite-button', name = 'coal', sprite = 'item/coal', enabled = false, number = world.variant.c})
    table0.add({type = 'sprite-button', name = 'stone', sprite = 'item/stone', enabled = false, number = world.variant.s})
    table0.add({type = 'sprite-button', name = 'uranium-ore', sprite = 'item/uranium-ore', enabled = false, number = world.variant.u})
    table0.add({type = 'sprite-button', name = 'oil', sprite = 'fluid/crude-oil', enabled = false, number = world.variant.o})
    l[3] = frame.add({type = 'label', name = 'richness', caption = {'chronosphere.gui_world_2', world.ores.name}})
    frame.add({type = 'label', name = 'world_time', caption = {'chronosphere.gui_world_5', world.dayspeed.name}})
    frame.add({type = 'line'})
    frame.add({type = 'label', name = 'world_biters', caption = {'chronosphere.gui_world_3', math_floor(evolution * 100, 1)}})
    frame.add({type = 'label', name = 'world_biters2', caption = {'chronosphere.gui_world_4'}})
    frame.add({type = 'label', name = 'world_biters3', caption = {'chronosphere.gui_world_4_1', objective.overstaycount * 2.5, objective.overstaycount * 10}})
    frame.add({type = 'line'})
    frame.add({type = 'label', name = 'overstay_time', caption = {'chronosphere.gui_world_7', '', ''}})

    frame.add({type = 'line'})

    local close = frame.add({type = 'button', name = 'close_world', caption = 'Close'})
    close.style.horizontal_align = 'center'
end

local function update_world_gui(player)
    local objective = Chrono_table.get_table()
    local difficulty = Difficulty.get().difficulty_vote_value

    if not player.gui.screen['gui_world'] then
        return
    end
    local world = objective.world
    local evolution = game.forces['enemy'].evolution_factor
    local evo_color = {
        r = math_floor(255 * 1 * math_max(0, math_min(1, 1.2 - evolution * 2))),
        g = math_floor(255 * 1 * math_max(math_abs(0.5 - evolution * 1.5), 1 - evolution * 4)),
        b = math_floor(255 * 4 * math_max(0, 0.25 - math_abs(0.5 - evolution)))
    }
    local frame = player.gui.screen['gui_world']

    frame['world_name'].caption = {'chronosphere.gui_world_0', world.variant.name}
    frame['world_ores']['iron-ore'].number = world.variant.fe
    frame['world_ores']['copper-ore'].number = world.variant.cu
    frame['world_ores']['coal'].number = world.variant.c
    frame['world_ores']['stone'].number = world.variant.s
    frame['world_ores']['uranium-ore'].number = world.variant.u
    frame['world_ores']['oil'].number = world.variant.o
    frame['richness'].caption = {'chronosphere.gui_world_2', world.ores.name}
    frame['world_biters'].caption = {'chronosphere.gui_world_3', math_floor(evolution * 100, 1)}
    frame['world_biters'].style.font_color = evo_color

    frame['world_biters3'].caption = {'chronosphere.gui_world_4_1', objective.overstaycount * 2.5, objective.overstaycount * 10}
    frame['world_time'].caption = {'chronosphere.gui_world_5', world.dayspeed.name}

    if objective.jump_countdown_start_time == -1 then
        if objective.chronojumps >= Balance.jumps_until_overstay_is_on(difficulty) then
            local time_until_overstay = (objective.chronochargesneeded * 0.75 / objective.passive_chronocharge_rate - objective.passivetimer)
            if time_until_overstay < 0 then
                frame['overstay_time'].caption = {'chronosphere.gui_overstayed'}
            else
                frame['overstay_time'].caption = {'chronosphere.gui_world_6', math_floor(time_until_overstay / 60), math_floor(time_until_overstay % 60)}
            end
        else
            frame['overstay_time'].caption = {'chronosphere.gui_world_7', Balance.jumps_until_overstay_is_on(difficulty)}
        end
    else
        if objective.chronojumps >= Balance.jumps_until_overstay_is_on(difficulty) then
            local overstayed = (objective.chronochargesneeded * 0.75 / objective.passive_chronocharge_rate < objective.jump_countdown_start_time)
            if overstayed then
                frame['overstay_time'].caption = {'chronosphere.gui_overstayed'}
            else
                frame['overstay_time'].caption = {'chronosphere.gui_not_overstayed'}
            end
        else
            frame['overstay_time'].caption = {'chronosphere.gui_world_7', Balance.jumps_until_overstay_is_on(difficulty)}
        end
    end
end

local function ETA_seconds_until_full(power, storedbattery) -- in watts and joules
    local objective = Chrono_table.get_table()

    local n = objective.chronochargesneeded - objective.chronocharges

    if n <= 0 then
        return 0
    else
        local eta = math_max(0, n - storedbattery / 1000000) / (power / 1000000 + objective.passive_chronocharge_rate)
        if eta < 1 then
            return 1
        end
        return math_floor(eta)
    end
end

function Public_gui.update_gui(player)
    local objective = Chrono_table.get_table()
    local difficulty = Difficulty.get().difficulty_vote_value

    local tick = game.tick
    update_world_gui(player)
    update_upgrades_gui(player)
    if not player.gui.top.chronosphere then
        create_gui(player)
    end
    local gui = player.gui.top.chronosphere

    gui.label.caption = {'chronosphere.gui_1'}
    gui.jump_number.caption = objective.chronojumps

    gui.charger.caption = {'chronosphere.gui_2'}

    if (objective.chronochargesneeded < 100000) then
        gui.charger_value.caption = string.format('%.2f', objective.chronocharges / 1000) .. ' / ' .. math_floor(objective.chronochargesneeded) / 1000 .. ' GJ'
    else
        gui.charger_value.caption = string.format('%.2f', objective.chronocharges / 1000000) .. ' / ' .. math_floor(objective.chronochargesneeded) / 1000000 .. ' TJ'
    end

    local interval = objective.chronochargesneeded
    gui.progressbar.value = 1 - (objective.chronochargesneeded - objective.chronocharges) / interval

    --[[
	if (objective.chronochargesneeded<1000) then
		gui.charger_value.caption =  objective.chronocharges .. "/" .. objective.chronochargesneeded .. " MJ"
	elseif (objective.chronochargesneeded<10000) then
		gui.charger_value.caption =  math_floor(objective.chronocharges/10)/100 .. " / " .. math_floor(objective.chronochargesneeded/10)/100 .. " GJ"
	elseif (objective.chronochargesneeded<1000000) then
		gui.charger_value.caption =  math_floor(objective.chronocharges/100)/10 .. " / " .. math_floor(objective.chronochargesneeded/100)/10 .. " GJ"
	elseif (objective.chronochargesneeded<10000000) then
		gui.charger_value.caption =  math_floor(objective.chronocharges/10000)/100 .. " / " .. math_floor(objective.chronochargesneeded/10000)/100 .. " TJ"
	else
		gui.charger_value.caption =  math_floor(objective.chronocharges/100000)/10 .. " / " .. math_floor(objective.chronochargesneeded/100000)/10 .. " TJ"
	end
	]]
    if objective.jump_countdown_start_time == -1 then
        local powerobserved, storedbattery, seconds_ETA = 0, 0, 0
        seconds_ETA = ETA_seconds_until_full(powerobserved, storedbattery)

        gui.timer.caption = {'chronosphere.gui_3'}
        gui.timer_value.caption = math_floor(seconds_ETA / 60) .. 'm' .. seconds_ETA % 60 .. 's'
        gui.timer_value.style.font_color = {r = 0, g = 0.98, b = 0}

        if objective.world.id == 2 and objective.world.variant.id == 2 and objective.passivetimer > 31 then
            local nukecase = objective.dangertimer
            gui.timer2.caption = {'chronosphere.gui_3_2'}
            gui.timer_value2.caption = math_floor(nukecase / 60) .. 'm' .. nukecase % 60 .. 's'
            gui.timer2.style.font_color = {r = 0.98, g = 0, b = 0}
            gui.timer_value2.style.font_color = {r = 0.98, g = 0, b = 0}
        else
            local bestcase = 0
            if objective.accumulators then
                bestcase = math_floor(ETA_seconds_until_full(#objective.accumulators * 300000, storedbattery))
                gui.timer2.caption = {'chronosphere.gui_3_1'}
                gui.timer_value2.caption = math_floor(bestcase / 60) .. 'm' .. bestcase % 60 .. 's (drawing ' .. #objective.accumulators * 0.3 .. 'MW)'
                gui.timer2.style.font_color = {r = 0, g = 200, b = 0}
                gui.timer_value2.style.font_color = {r = 0, g = 200, b = 0}
            end
        end
        --end
        if objective.chronojumps >= Balance.jumps_until_overstay_is_on(difficulty) then
            local time_until_overstay = (objective.chronochargesneeded * 0.75 / objective.passive_chronocharge_rate - objective.passivetimer)
            local time_until_evo = (objective.chronochargesneeded * 0.5 / objective.passive_chronocharge_rate - objective.passivetimer)
            if time_until_evo <= seconds_ETA then
                gui.timer_value.style.font_color = {r = 0.98, g = 0.5, b = 0}
            end
            if time_until_overstay <= seconds_ETA then
                gui.timer_value.style.font_color = {r = 0.98, g = 0, b = 0}
            end

            local evo_timer = {math_floor(time_until_overstay / 60), math_floor(time_until_overstay) % 60, math_floor(time_until_evo / 60), math_floor(time_until_evo) % 60}
            if time_until_overstay < 0 then
                evo_timer[2] = 59 - evo_timer[2]
            end
            if time_until_evo < 0 then
                evo_timer[4] = 59 - evo_timer[4]
            end
            gui.timer_value.tooltip = {'chronosphere.gui_biters_evolve', evo_timer[1], evo_timer[2], evo_timer[3], evo_timer[4]}
        else
            gui.timer_value.tooltip = ''
        end
    else
        gui.timer.caption = {'chronosphere.gui_3_3'}
        gui.timer_value.caption = 180 - (objective.passivetimer - objective.jump_countdown_start_time) .. 's'
        gui.timer.tooltip = ''
        gui.timer_value.tooltip = ''
        gui.timer2.caption = ''
        gui.timer_value2.caption = ''
    end

    gui.world_button.caption = {'chronosphere.gui_world_button'}
    gui.upgrades_button.caption = {'chronosphere.gui_upgrades_button'}
end

local function upgrades_gui(player)
    if player.gui.screen['gui_upgrades'] then
        player.gui.screen['gui_upgrades'].destroy()
        return
    end
    local objective = Chrono_table.get_table()
    local playertable = Chrono_table.get_player_table()
    local production_table = Chrono_table.get_production_table()
    local v_costs = {}
    local costs = {}
    local upgrades = Upgrades.upgrades()
    local frame = player.gui.screen.add {type = 'frame', name = 'gui_upgrades', caption = 'ChronoTrain Upgrades', direction = 'vertical'}
    frame.location = {x = 350, y = 45}
    frame.style.minimal_height = 300
    frame.style.maximal_height = 900
    frame.style.minimal_width = 330
    frame.style.maximal_width = 630
    frame.add({type = 'label', caption = {'chronosphere.gui_upgrades_1'}})
    frame.add({type = 'label', caption = {'chronosphere.gui_upgrades_2'}})
    frame.add({type = 'label', caption = {'chronosphere.gui_upgrades_3'}})
    local switches = frame.add({type = 'table', name = 'upgrades_switch', column_count = 4})
    switches.add({type = 'button', caption = {'chronosphere.gui_upgrades_switch1'}, name = 'upgrade_switch1', tooltip = {'chronosphere.gui_upgrades_switch_tt1'}})
    switches.add({type = 'button', caption = {'chronosphere.gui_upgrades_switch2'}, name = 'upgrade_switch2', tooltip = {'chronosphere.gui_upgrades_switch_tt2'}})
    switches.add({type = 'button', caption = {'chronosphere.gui_upgrades_switch3'}, name = 'upgrade_switch3', tooltip = {'chronosphere.gui_upgrades_switch_tt3'}})
    switches.add({type = 'button', caption = {'chronosphere.gui_upgrades_switch4'}, name = 'upgrade_switch4', tooltip = {'chronosphere.gui_upgrades_switch_tt4'}})
    local tokens = frame.add({type = 'table', name = 'tokens', column_count = 6})
    tokens.add({type = 'label', caption = {'chronosphere.gui_tokens'}})
    for token, value in pairs(objective.research_tokens) do
        tokens.add(
            {
                type = 'sprite-button',
                name = 'token_' .. token,
                enabled = Upgrades.tokens[token].enabled,
                sprite = Upgrades.tokens[token].sprite,
                number = value,
                tooltip = Upgrades.tokens[token].tooltip
            }
        )
    end

    for i = 1, #upgrades, 1 do
        local upg_table = frame.add({type = 'table', name = 'upgrades_table' .. i, column_count = 10})
        upg_table.add({type = 'sprite-button', name = 'upgrade' .. i, enabled = false, sprite = upgrades[i].sprite, number = objective.upgrades[i], tooltip = upgrades[i].tooltip})
        local name = upg_table.add({type = 'label', name = 'upgrade_label' .. i, caption = upgrades[i].name, tooltip = upgrades[i].tooltip})
        name.style.width = 200

        local maxed =
            upg_table.add({type = 'sprite-button', name = 'maxed' .. i, enabled = false, sprite = 'virtual-signal/signal-check', tooltip = 'Upgrade maxed!', visible = false})
        local jumps =
            upg_table.add(
            {
                type = 'sprite-button',
                name = 'jump_req' .. i,
                enabled = false,
                sprite = 'virtual-signal/signal-J',
                number = upgrades[i].jump_limit,
                tooltip = {'chronosphere.gui_upgrades_jumps'},
                visible = true
            }
        )
        for index, item in pairs(upgrades[i].virtual_cost) do
            v_costs[index] =
                upg_table.add(
                {
                    type = 'sprite-button',
                    name = index .. '-v' .. i,
                    number = item.count,
                    sprite = item.sprite,
                    enabled = false,
                    tooltip = {item.tt .. '.' .. item.name},
                    visible = true
                }
            )
        end

        for index, item in pairs(upgrades[i].cost) do
            costs[index] =
                upg_table.add(
                {
                    type = 'sprite-button',
                    name = index .. '-' .. i,
                    number = item.count,
                    sprite = item.sprite,
                    enabled = false,
                    tooltip = {item.tt .. '.' .. item.name},
                    visible = true
                }
            )
        end
        if objective.upgrades[i] == upgrades[i].max_level then
            maxed.visible = true
            jumps.visible = false
            for index, _ in pairs(upgrades[i].virtual_cost) do
                v_costs[index].visible = false
            end
            for index, _ in pairs(upgrades[i].cost) do
                costs[index].visible = false
            end
        else
            maxed.visible = false
            jumps.visible = true
            for index, _ in pairs(upgrades[i].cost) do
                costs[index].visible = true
            end
            for index, _ in pairs(upgrades[i].virtual_cost) do
                v_costs[index].visible = true
            end
        end
        --if upgrades[i].type == "quest" then upg_table.visible = false end
    end
    local prod_table = frame.add({type = 'table', name = 'production_table', column_count = 4})
    for key, product in pairs(Production) do
        local recipe = Production[key].recipe_override or Production[key].name
        prod_table.add(
            {
                type = 'sprite-button',
                name = 'product' .. key,
                enabled = false,
                sprite = 'recipe/' .. recipe,
                number = math.floor((production_table.experience[key] / 1000) ^ (1 / 2))
            }
        )
        local xp_bar = prod_table.add({type = 'progressbar', name = 'product_bar' .. key, value = calculate_xp(key)})
        xp_bar.style = 'achievement_progressbar'
    end
    switch_upgrades(player, playertable.active_upgrades_gui[player.index])
    frame.add({type = 'line', direction = 'horizontal'})
    local close = frame.add({type = 'button', name = 'close_upgrades', caption = 'Close'})
    close.style.horizontally_stretchable = true
end

function Public_gui.on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local player = game.players[event.element.player_index]
    if event.element.name == 'upgrades_button' then
        upgrades_gui(player)
        return
    elseif event.element.name == 'world_button' then
        world_gui(player)
        return
    elseif event.element.name == 'minimap_button' then
        Minimap.minimap(player, false)
    elseif event.element.name == 'icw_map' or event.element.name == 'icw_map_frame' then
        Minimap.toggle_minimap(event)
    elseif event.element.name == 'switch_auto_map' then
        Minimap.toggle_auto(player)
    end

    if event.element.type ~= 'button' and event.element.type ~= 'sprite-button' then
        return
    end
    local name = event.element.name
    if name == 'close_upgrades' then
        upgrades_gui(player)
        return
    end
    if name == 'close_world' then
        world_gui(player)
        return
    end
    if name == 'upgrade_switch1' then
        switch_upgrades(player, 1)
        return
    end
    if name == 'upgrade_switch2' then
        switch_upgrades(player, 2)
        return
    end
    if name == 'upgrade_switch3' then
        switch_upgrades(player, 3)
        return
    end
    if name == 'upgrade_switch4' then
        switch_upgrades(player, 4)
        return
    end
    if name == 'token_ammo' then
        Upgrades.add_ammo_tokens(player)
        return
    end
end

return Public_gui
