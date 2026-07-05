if not script.active_mods['MineableWreckage'] then
    error('MineableWreckage mod is not enabled! Please download it from the mod website.')
end

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Misc = require 'utils.commands.misc'

require 'modules.custom_death_messages'
require 'modules.flashlight_toggle_button'

if ScenarioTable.mode('chat_mode') == 'alliance' then
    require 'modules.chat_channel_toggle'
else
    require 'modules.global_chat_toggle'
end

require 'modules.biters_yield_coins'

require 'maps.scrap_towny_ffa.building'
require 'maps.scrap_towny_ffa.spaceship'
require 'maps.scrap_towny_ffa.game_settings'

if ScenarioTable.enabled('pvp_offline_shield') or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield')
    or ScenarioTable.enabled('pvp_shield_build_zones') or ScenarioTable.mode('damage_pipeline') == 'extended'
    or ScenarioTable.enabled('market_afk_offer') or ScenarioTable.enabled('market_enemy_display') then
    require 'maps.scrap_towny_ffa.pvp_shield'
end

if ScenarioTable.enabled('pvp_offline_shield') or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield')
    or ScenarioTable.enabled('market_enemy_display')
    or ScenarioTable.enabled('market_afk_offer') or ScenarioTable.mode('damage_pipeline') == 'extended' then
    require 'maps.scrap_towny_ffa.pvp_town_shield'
end

require 'maps.scrap_towny_ffa.town_center'
require 'maps.scrap_towny_ffa.market'

if ScenarioTable.mode('laser_limits') == 'slots' then
    require 'maps.scrap_towny_ffa.slots'
end

require 'maps.scrap_towny_ffa.wreckage_yields_scrap'
require 'maps.scrap_towny_ffa.rocks_yield_ore_veins'
require 'maps.scrap_towny_ffa.worms_create_oil_patches'
require 'maps.scrap_towny_ffa.spawners_contain_biters'

if ScenarioTable.enabled('explosives_are_explosive') then
    require 'maps.scrap_towny_ffa.explosives_are_explosive'
end
if ScenarioTable.enabled('fluids_are_explosive') then
    require 'maps.scrap_towny_ffa.fluids_are_explosive'
end

require 'maps.scrap_towny_ffa.trap'
require 'maps.scrap_towny_ffa.turrets_drop_ammo'

if ScenarioTable.enabled('vehicles_force_handling') then
    require 'maps.scrap_towny_ffa.vehicles'
end

require 'maps.scrap_towny_ffa.suicide'

if ScenarioTable.enabled('turrets_shoot_empty_vehicles') then
    require 'maps.scrap_towny_ffa.empty_vehicle_turrets'
end

if ScenarioTable.mode('win_condition') == 'score' then
    require 'maps.scrap_towny_ffa.score'
end

if ScenarioTable.mode('win_condition') == 'survival'
    or (ScenarioTable.mode('win_condition') == 'score' and ScenarioTable.enabled('rich_scoreboard')) then
    require 'maps.scrap_towny_ffa.score_board'
end

if ScenarioTable.enabled('research_balance') then
    require 'maps.scrap_towny_ffa.research_balance'
end

if ScenarioTable.enabled('hud_research_cost') or ScenarioTable.enabled('research_balance')
    or ScenarioTable.enabled('hud_damage') or ScenarioTable.enabled('dynamic_damage_modifier')
    or ScenarioTable.enabled('market_enemy_display') or ScenarioTable.enabled('pvp_offline_shield')
    or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield') then
    require 'maps.scrap_towny_ffa.town_status'
end

if ScenarioTable.mode('laser_limits') == 'building_limits' then
    require 'maps.scrap_towny_ffa.building_limits'
end

if ScenarioTable.enabled('tech_gating') then
    require 'maps.scrap_towny_ffa.tech_gating'
end

if ScenarioTable.mode('map_mode') == 'fixed' then
    require 'maps.scrap_towny_ffa.map_layout'
end

if ScenarioTable.enabled('logistics_raiding') or ScenarioTable.enabled('pvp_shield_build_zones')
    or ScenarioTable.enabled('ghost_turret_blueprint_block') or ScenarioTable.enabled('map_edge_build_restrictions') then
    require 'maps.scrap_towny_ffa.building_rules'
end

local Event = require 'utils.event'
local Autostash = require 'modules.autostash'
local MapDefaults = require 'maps.scrap_towny_ffa.map_defaults'
local BottomFrame = require 'utils.gui.bottom_frame'
local Nauvis = require 'maps.scrap_towny_ffa.nauvis'
local Biters = require 'maps.scrap_towny_ffa.biters'
local Pollution = require 'maps.scrap_towny_ffa.pollution'
local Fish = require 'maps.scrap_towny_ffa.fish_reproduction'
local Team = require 'maps.scrap_towny_ffa.team'
local CombatBalance = require 'maps.scrap_towny_ffa.combat_balance'
local Radar = require 'maps.scrap_towny_ffa.limited_radar'
local Limbo = require 'maps.scrap_towny_ffa.limbo'
local Evolution = require 'maps.scrap_towny_ffa.evolution'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Where = require 'utils.commands.where'
local Inventory = require 'modules.show_inventory'
local JailData = require 'utils.datastore.jail_data'
local FlyingText = require 'utils.functions.flying_texts'

Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_mod_gui_top_frame(true)

local PvPShield
if ScenarioTable.mode('damage_pipeline') == 'extended' then
    PvPShield = require 'maps.scrap_towny_ffa.pvp_shield'
end

local function on_entity_damaged(event)
    if ScenarioTable.mode('damage_pipeline') ~= 'extended' then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    if PvPShield and PvPShield.protect_if_needed(event) then
        return
    end
    CombatBalance.on_entity_damaged(event)
    Team.on_cease_fire_damage(event)
end

local function on_init()
    JailData.normies_can_jail(false)
    Autostash.insert_into_furnace(true)
    Autostash.insert_to_neutral_chests(true)
    Autostash.insert_into_wagon(true)
    Autostash.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    Misc.bottom_button(true)
    Where.module_disabled(true)
    Inventory.module_disabled(true)
    game.enemy_has_vision_on_land_mines = false
    game.draw_resource_selection = true
    MapDefaults.initialize()
    Limbo.initialize()
    Nauvis.initialize(true)
    Team.initialize()
    local this = ScenarioTable.get_table()
    ScenarioTable.apply_survival_hours(this)
end

local tick_actions =
{
    [60 * 0] = Radar.reset,
    [60 * 5] = Team.update_town_chart_tags,
    [60 * 10] = Team.set_all_player_colors,
    [60 * 15] = Fish.reproduce,
    [60 * 25] = Biters.unit_groups_start_moving,
    [60 * 30] = Radar.reset,
    [60 * 45] = Biters.validate_swarms,
    [60 * 50] = Biters.swarm,
    [60 * 55] = Pollution.market_scent
}

local function on_nth_tick(event)
    local seconds = event.tick % 3600
    if tick_actions[seconds] then
        tick_actions[seconds]()
    end
end

local function handle_changes()
    ScenarioTable.set('restart', true)
    ScenarioTable.set('soft_reset', false)
    print('Received new changes from backend.')
end

local function ui_smell_evolution()
    if not ScenarioTable.enabled('evolution_smell_hint') then
        return
    end
    for _, player in pairs(game.connected_players) do
        if player.force.index == game.forces.player.index or player.force.index == game.forces['rogue'].index then
            local e = Evolution.get_evolution(player.physical_position)
            local extra
            if e < 0.1 then
                extra = 'A good place to found a town. Build a furnace to get started.'
            else
                extra = 'Not good to start a new town. Maybe somewhere else?'
            end
            FlyingText.player_flying_text(player,
                {
                    position = { x = player.physical_position.x, y = player.physical_position.y },
                    text = 'You smell the evolution around here: ' .. string.format('%.0f', e * 100) .. '%. ' .. extra,
                    color = { r = 1, g = 1, b = 1 }
                })
        end
    end
end

Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick)

if ScenarioTable.enabled('evolution_smell_hint') then
    Event.on_nth_tick(60 * 30, ui_smell_evolution)
end

if ScenarioTable.mode('damage_pipeline') == 'extended' then
    Event.add(defines.events.on_entity_damaged, on_entity_damaged)
end

Server.on_scenario_changed('Towny', function (data)
    if data.scenario == 'Towny' then
        handle_changes()
    end
end)

Event.add(defines.events.on_gui_click, function (event)
    local element = event.element
    if not element or not element.valid then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    if element.name == Gui.top_main_gui_button then
        if not player.admin then
            local main_frame_name = Gui.main_frame_name
            if player.gui.left[main_frame_name] and player.gui.left[main_frame_name].valid then
                player.gui.left[main_frame_name].destroy()
            end
            return player.print('Comfy panel is disabled in this scenario.', { color = Color.fail })
        end
    end
end)

if ScenarioTable.mode('map_mode') == 'procedural' then
    require 'maps.scrap_towny_ffa.terrain'
end
