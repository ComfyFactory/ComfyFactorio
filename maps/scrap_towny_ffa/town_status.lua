local Public = {}

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Team = require 'maps.scrap_towny_ffa.team'
local mod_gui = require 'mod-gui'
local CombatBalance = require 'maps.scrap_towny_ffa.combat_balance'
local ScoreBoard = require 'maps.scrap_towny_ffa.score_board'

local ResearchBalance
if ScenarioTable.enabled('research_balance') then
    ResearchBalance = require 'maps.scrap_towny_ffa.research_balance'
end

local button_id = 'towny_status_button'
local frame_name = 'towny_status_frame'

function Public.enabled()
    return ScenarioTable.enabled('hud_research_cost') or ScenarioTable.enabled('research_balance')
        or ScenarioTable.enabled('hud_damage') or ScenarioTable.enabled('dynamic_damage_modifier')
        or ScenarioTable.enabled('market_enemy_display') or ScenarioTable.enabled('pvp_offline_shield')
        or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield')
end

local function get_button(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)[button_id]
    end
    return player.gui.top[button_id]
end

local function gui_color(color)
    return { r = color[1] / 255, g = color[2] / 255, b = color[3] / 255 }
end

local function get_town_center(player)
    local this = ScenarioTable.get_table()
    return this.town_centers[player.force.name]
end

local function research_cost_line(town_center)
    if not (ScenarioTable.enabled('hud_research_cost') or ScenarioTable.enabled('research_balance')) then
        return
    end
    local modifier = 1
    if town_center.research_balance and town_center.research_balance.current_modifier then
        modifier = town_center.research_balance.current_modifier
    end
    if ResearchBalance then
        return 'Research cost: ' .. ResearchBalance.format_town_modifier(modifier)
    end
    return 'Research cost: ' .. string.format('%.0f%%', 100 * 1 / modifier)
end

local function damage_line(town_center)
    if not (ScenarioTable.enabled('hud_damage') or ScenarioTable.enabled('dynamic_damage_modifier')) then
        return
    end
    local modifier = 1
    if town_center.combat_balance and town_center.combat_balance.current_modifier then
        modifier = town_center.combat_balance.current_modifier
    end
    return 'Damage: ' .. CombatBalance.format_dmg_modifier(modifier)
end

local function pvp_enabled()
    return ScenarioTable.enabled('market_enemy_display') or ScenarioTable.enabled('pvp_offline_shield')
        or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield')
end

local function pvp_lines(town_center)
    if not pvp_enabled() then
        return
    end
    local mgmt = town_center.pvp_shield_mgmt
    if not mgmt then
        return
    end
    return mgmt.enemies_info, mgmt.enemies_color, mgmt.shield_info
end

local enemies_tooltip =
'Enemy players near your town. Red = in town range. Yellow = nearby.'

local shield_tooltip =
'Current league and PvP shield state.'

if ScenarioTable.enabled('pvp_offline_shield') or ScenarioTable.enabled('pvp_afk_shield') then
    shield_tooltip = shield_tooltip .. ' Standby = ready when everyone leaves. Abandoned = offline shield time used up.'
end

local function init_panel(player)
    local this = ScenarioTable.get_table()
    if not this.town_status_gui_frame then
        this.town_status_gui_frame = {}
    end
    local saved_frame = this.town_status_gui_frame[player.index]
    if saved_frame and saved_frame.valid then
        return saved_frame
    end
    local flow = mod_gui.get_frame_flow(player)
    local frame = flow.add
        {
            type = 'frame',
            style = mod_gui.frame_style,
            caption = 'Town status',
            direction = 'vertical',
            name = frame_name
        }
    frame.style.vertically_stretchable = false
    frame.visible = false
    this.town_status_gui_frame[player.index] = frame
    return frame
end

local function populate_panel(player)
    local frame = init_panel(player)
    if not frame or not frame.valid then
        return
    end
    frame.clear()
    local town_center = get_town_center(player)
    if not town_center then
        frame.add { type = 'label', caption = 'You are not in a town.' }
        return
    end
    local inner = frame.add { type = 'frame', style = 'inside_shallow_frame', direction = 'vertical' }
    inner.style.padding = 8
    inner.add { type = 'label', caption = 'Coins: ' .. town_center.coin_balance }
    local research = research_cost_line(town_center)
    if research then
        inner.add { type = 'label', caption = research }
    end
    local damage = damage_line(town_center)
    if damage then
        inner.add { type = 'label', caption = damage }
    end
    local enemies_info, enemies_color, shield_info = pvp_lines(town_center)
    if enemies_info then
        local enemies_label = inner.add { type = 'label', caption = enemies_info }
        enemies_label.tooltip = enemies_tooltip
        if enemies_color then
            enemies_label.style.font_color = gui_color(enemies_color)
        end
    end
    if shield_info then
        local shield_label = inner.add { type = 'label', caption = shield_info }
        shield_label.tooltip = shield_tooltip
    end
end

local function update_visible_panels()
    local this = ScenarioTable.get_table()
    if not this.town_status_gui_frame then
        return
    end
    for _, player in pairs(game.connected_players) do
        if Team.is_towny(player.force) then
            local frame = this.town_status_gui_frame[player.index]
            if frame and frame.valid and frame.visible then
                populate_panel(player)
            end
        end
    end
end

function Public.add_button(player)
    if not Public.enabled() then
        return
    end
    local existing = get_button(player)
    if existing and existing.valid then
        existing.destroy()
    end
    local button
    if Gui.get_mod_gui_top_frame() then
        button = Gui.add_mod_button(player,
            {
                type = 'sprite-button',
                caption = 'Status',
                name = button_id,
                tooltip = 'Town stats',
                style = Gui.button_style
            })
        if button then
            button.visible = false
            button.style.font = 'default-bold'
            button.style.font_color = { r = 0.55, g = 0.85, b = 1 }
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 72
            button.style.padding = -2
        end
    else
        button = player.gui.top.add
            {
                type = 'sprite-button',
                caption = 'Status',
                name = button_id,
                tooltip = 'Town stats'
            }
        button.visible = false
        button.style.font = 'default-bold'
        button.style.font_color = { r = 0.55, g = 0.85, b = 1 }
        button.style.minimal_height = 38
        button.style.minimal_width = 72
    end
end

function Public.close_panel(player)
    local this = ScenarioTable.get_table()
    local frame = this.town_status_gui_frame and this.town_status_gui_frame[player.index]
    if frame and frame.valid then
        frame.visible = false
    end
end

function Public.player_changes_town_status(player, in_town)
    if not Public.enabled() then
        return
    end
    local button = get_button(player)
    if button and button.valid then
        button.visible = in_town
    end
    if not in_town then
        Public.close_panel(player)
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid or element.name ~= button_id then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    local frame = init_panel(player)
    if not frame or not frame.valid then
        return
    end
    if frame.visible then
        frame.visible = false
    else
        ScoreBoard.close_panel(player)
        populate_panel(player)
        frame.visible = true
    end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.on_nth_tick(31, update_visible_panels)

return Public
