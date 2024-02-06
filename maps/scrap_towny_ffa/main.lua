require 'modules.custom_death_messages'
require 'modules.flashlight_toggle_button'
require 'modules.global_chat_toggle'
require 'modules.biters_yield_coins'
local Reset = require 'maps.scrap_towny_ffa.reset'
require 'maps.scrap_towny_ffa.mining'
require 'maps.scrap_towny_ffa.building'
require 'maps.scrap_towny_ffa.spaceship'
require 'maps.scrap_towny_ffa.town_center'
require 'maps.scrap_towny_ffa.market'
require 'maps.scrap_towny_ffa.slots'
require 'maps.scrap_towny_ffa.wreckage_yields_scrap'
require 'maps.scrap_towny_ffa.rocks_yield_ore_veins'
require 'maps.scrap_towny_ffa.worms_create_oil_patches'
require 'maps.scrap_towny_ffa.spawners_contain_biters'
require 'maps.scrap_towny_ffa.explosives_are_explosive'
require 'maps.scrap_towny_ffa.fluids_are_explosive'
require 'maps.scrap_towny_ffa.trap'
require 'maps.scrap_towny_ffa.turrets_drop_ammo'
require 'maps.scrap_towny_ffa.vehicles'
require 'maps.scrap_towny_ffa.suicide'

local Event = require 'utils.event'
local Autostash = require 'modules.autostash'
local MapDefaults = require 'maps.scrap_towny_ffa.map_defaults'
local BottomFrame = require 'utils.gui.bottom_frame'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Nauvis = require 'maps.scrap_towny_ffa.nauvis'
local Biters = require 'maps.scrap_towny_ffa.biters'
local Pollution = require 'maps.scrap_towny_ffa.pollution'
local Fish = require 'maps.scrap_towny_ffa.fish_reproduction'
local Team = require 'maps.scrap_towny_ffa.team'
local Radar = require 'maps.scrap_towny_ffa.limited_radar'
local Limbo = require 'maps.scrap_towny_ffa.limbo'
local Evolution = require 'maps.scrap_towny_ffa.evolution'
local mod_gui = require('mod-gui')
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Where = require 'utils.commands.where'
local Inventory = require 'modules.show_inventory'
local JailData = require 'utils.datastore.jail_data'

Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_toggle_button(true)

local function spairs(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    table.sort(
        keys,
        function(a, b)
            return t[b] < t[a]
        end
    )
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function init_score_board(player)
    local this = ScenarioTable.get_table()
    local saved_frame = this.score_gui_frame[player.index]
    if saved_frame and saved_frame.valid then
        return
    end

    local flow = mod_gui.get_frame_flow(player)
    local frame = flow.add {type = 'frame', style = mod_gui.frame_style, caption = 'Town survival', direction = 'vertical'}
    frame.style.vertically_stretchable = false
    this.score_gui_frame[player.index] = frame
end

local function update_score()
    local this = ScenarioTable.get_table()

    for _, player in pairs(game.connected_players) do
        if this.winner then
            Reset.show_mvps(player)
        else
            local frame = this.score_gui_frame[player.index]
            if not (frame and frame.valid) then
                init_score_board(player)
            end
            if frame and frame.valid then
                frame.clear()

                local inner_frame = frame.add {type = 'frame', style = 'inside_shallow_frame', direction = 'vertical'}

                local subheader = inner_frame.add {type = 'frame', style = 'subheader_frame'}
                subheader.style.horizontally_stretchable = true
                subheader.style.vertical_align = 'center'

                local days = this.required_time_to_win / 24

                subheader.add {type = 'label', style = 'subheader_label', caption = {'', 'Survive for ' .. days .. ' days (' .. this.required_time_to_win .. 'h) to win!'}}

                if not next(subheader.children) then
                    subheader.destroy()
                end

                local information_table = inner_frame.add {type = 'table', column_count = 3, style = 'bordered_table'}
                information_table.style.margin = 4
                information_table.style.column_alignments[3] = 'right'

                for _, caption in pairs({'Rank', 'Town (players online/total)', 'Survival time'}) do
                    local label = information_table.add {type = 'label', caption = caption}
                    label.style.font = 'default-bold'
                end

                local town_ages = {}
                for _, town_center in pairs(this.town_centers) do
                    if town_center ~= nil then
                        local age = game.tick - town_center.creation_tick
                        town_ages[town_center] = age
                    end
                end

                local rank = 1

                for town_center, age in spairs(town_ages) do
                    local position = information_table.add {type = 'label', caption = '#' .. rank}
                    if town_center == this.town_centers[player.force.name] then
                        position.style.font = 'default-semibold'
                        position.style.font_color = {r = 1, g = 1}
                    end
                    local label =
                        information_table.add {
                        type = 'label',
                        caption = town_center.town_name .. ' (' .. #town_center.market.force.connected_players .. '/' .. #town_center.market.force.players .. ')'
                    }
                    label.style.font = 'default-semibold'
                    label.style.font_color = town_center.color
                    local age_hours = age / 60 / 3600
                    local total_age = string.format('%.1f', age_hours)
                    information_table.add {type = 'label', caption = total_age .. 'h'}

                    rank = rank + 1

                    if tonumber(total_age) >= this.required_time_to_win then
                        this.winner = {
                            name = town_center.town_name,
                            research_counter = town_center.research_counter,
                            upgrades = town_center.upgrades,
                            health = town_center.health,
                            coin_balance = town_center.coin_balance
                        }
                    end
                end

                -- Outlander section
                information_table.add {type = 'label', caption = '-'}
                local outlander_on = #game.forces['player'].connected_players + #game.forces['rogue'].connected_players
                local outlander_total = #game.forces['player'].players + #game.forces['rogue'].players

                local label =
                    information_table.add {
                    type = 'label',
                    caption = 'Outlanders' .. ' (' .. outlander_on .. '/' .. outlander_total .. ')'
                }
                label.style.font_color = {170, 170, 170}
                information_table.add {type = 'label', caption = '-'}
            end
        end
    end
end

local function on_init()
    JailData.normies_can_jail(false)
    Autostash.insert_into_furnace(true)
    Autostash.insert_to_neutral_chests(true)
    Autostash.insert_into_wagon(true)
    Autostash.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    Where.module_disabled(true)
    Inventory.module_disabled(true)

    --log("on_init")
    game.enemy_has_vision_on_land_mines = false
    game.draw_resource_selection = true
    game.disable_tutorial_triggers()

    MapDefaults.initialize()
    Limbo.initialize()
    Nauvis.initialize(true)
    Team.initialize()
end

local tick_actions = {
    [60 * 0] = Radar.reset, -- each minute, at 00 seconds
    [60 * 5] = Team.update_town_chart_tags, -- each minute, at 05 seconds
    [60 * 10] = Team.set_all_player_colors, -- each minute, at 10 seconds
    [60 * 15] = Fish.reproduce, -- each minute, at 15 seconds
    [60 * 25] = Biters.unit_groups_start_moving, -- each minute, at 25 seconds
    [60 * 30] = Radar.reset, -- each minute, at 30 seconds
    [60 * 45] = Biters.validate_swarms, -- each minute, at 45 seconds
    [60 * 50] = Biters.swarm, -- each minute, at 50 seconds
    [60 * 55] = Pollution.market_scent -- each minute, at 55 seconds
}

local function on_nth_tick(event)
    -- run each second
    local tick = event.tick
    local seconds = tick % 3600 -- tick will recycle minute
    if not tick_actions[seconds] then
        return
    end
    tick_actions[seconds]()
end

local function handle_changes()
    ScenarioTable.set('restart', true)
    ScenarioTable.set('soft_reset', false)
    print('Received new changes from backend.')
end

local function ui_smell_evolution()
    for _, player in pairs(game.connected_players) do
        -- Only for non-townies
        if player.force.index == game.forces.player.index or player.force.index == game.forces['rogue'].index then
            local e = Evolution.get_evolution(player.position)
            local extra
            if e < 0.1 then
                extra = 'A good place to found a town. Build a furnace to get started.'
            else
                extra = 'Not good to start a new town. Maybe somewhere else?'
            end
            player.create_local_flying_text(
                {
                    position = {x = player.position.x, y = player.position.y},
                    text = 'You smell the evolution around here: ' .. string.format('%.0f', e * 100) .. '%. ' .. extra,
                    color = {r = 1, g = 1, b = 1}
                }
            )
        end
    end
end

Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick) -- once every second
Event.on_nth_tick(60 * 30, ui_smell_evolution)
Event.on_nth_tick(60, update_score)

Server.on_scenario_changed(
    'Towny',
    function(data)
        local scenario = data.scenario
        if scenario == 'Towny' then
            handle_changes()
        end
    end
)

--Disable the comfy main gui since we got too many goodies there.
Event.add(
    defines.events.on_gui_click,
    function(event)
        local element = event.element
        if not element or not element.valid then
            return
        end
        local fish_button = Gui.top_main_gui_button
        local main_frame_name = Gui.main_frame_name
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end
        if element.name == fish_button then
            if not player.admin then
                if player.gui.left[main_frame_name] and player.gui.left[main_frame_name].valid then
                    player.gui.left[main_frame_name].destroy()
                end
                return player.print('Comfy panel is disabled in this scenario.', Color.fail)
            end
        end
    end
)

require 'maps.scrap_towny_ffa.terrain'
