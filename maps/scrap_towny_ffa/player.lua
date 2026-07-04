local ScenarioTable = require "maps.scrap_towny_ffa.table"
local Team = require "maps.scrap_towny_ffa.team"
local Event = require "utils.event"
local Spawn = require "maps.scrap_towny_ffa.spawn"
local Info = require "maps.scrap_towny_ffa.info"
local Gui = require "utils.gui"

local Public = {}
local max_ticks_between_spawns = 60 * 10
local min_players_for_enabling_towns = 0

function Public.settings(player)
    player.game_view_settings.show_minimap = false

    player.game_view_settings.show_map_view_options = false

    player.game_view_settings.show_entity_info = true

    player.map_view_settings =
    {
        ["show-logistic-network"] = false,
        ["show-electric-network"] = false,
        ["show-turret-range"] = false,
        ["show-pollution"] = false,
        ["show-train-station-names"] = false,
        ["show-player-names"] = false,
        ["show-networkless-logistic-members"] = false,
        ["show-non-standard-map-info"] = false
    }

    player.show_on_map = false

end

function Public.initialize(player)
    player.teleport({ 0, 0 }, game.surfaces["limbo"])

    Team.set_player_to_outlander(player)

    Team.give_player_items(player)

    Team.give_key(player.index)

    local this = ScenarioTable.get()

    if (this.testing_mode == true) then
        player.cheat_mode = true

        player.force.research_all_technologies()

        player.insert { name = "coin", count = "9900" }
    end
end

function Public.spawn(player)

    local this = ScenarioTable.get_table()

    local surface = game.get_surface(this.active_surface_index)

    if not surface or not surface.valid then
        return
    end

    local spawn_point = Spawn.get_new_spawn_point(player, surface)

    this.strikes[player.name] = 0

    Spawn.clear_spawn_point(spawn_point, surface)

    this.cooldowns_town_placement[player.index] = 0

    this.last_respawn[player.name] = 0

    local position = surface.find_non_colliding_position("character", spawn_point, 50, 1)

    if position then
        player.teleport(position, surface)
    else
        player.teleport(spawn_point, surface)
    end
end

function Public.load_buffs(player)
    if player.force.name ~= "player" and player.force.name ~= "rogue" then
        return
    end

    local this = ScenarioTable.get()

    local player_index = player.index

    if player.character == nil then
        return
    end

    if this.buffs[player_index] == nil then
        this.buffs[player_index] = {}
    end

    if this.buffs[player_index].character_inventory_slots_bonus ~= nil then
        player.character.character_inventory_slots_bonus = this.buffs[player_index].character_inventory_slots_bonus
    end

    if this.buffs[player_index].character_mining_speed_modifier ~= nil then
        player.character.character_mining_speed_modifier = this.buffs[player_index].character_mining_speed_modifier
    end

    if this.buffs[player_index].character_crafting_speed_modifier ~= nil then
        player.character.character_crafting_speed_modifier = this.buffs[player_index].character_crafting_speed_modifier
    end
end

function Public.requests(player)
    local this = ScenarioTable.get()

    if this.requests[player.index] and this.requests[player.index] == "kill-character" then
        if player.character and player.character.valid then

            local inventories =
            {
                player.get_inventory(defines.inventory.character_main),
                player.get_inventory(defines.inventory.character_guns),
                player.get_inventory(defines.inventory.character_ammo),
                player.get_inventory(defines.inventory.character_armor),
                player.get_inventory(defines.inventory.character_vehicle),
                player.get_inventory(defines.inventory.character_trash)
            }

            for _, i in pairs(inventories) do
                i.clear()
            end

            player.print("Your town has fallen since you last played. Good luck next time!", { r = 1, g = 0, b = 0 })

            player.character.die()
        end

        this.requests[player.index] = nil
    end
end

function Public.increment()
    local this = ScenarioTable.get()

    local count = this.players + 1

    this.players = count

    if this.testing_mode then
        this.towns_enabled = true
    else
        if this.players >= min_players_for_enabling_towns then
            this.towns_enabled = true
        end
    end
end

local removed_hud_ids =
{
    "towny_map_position",
    "towny_evo_display",
    "towny_game_mode",
    "towny_research_balance",
    "towny_damage_balance",
}

local function remove_retired_hud(player)
    for _, name in pairs(removed_hud_ids) do
        local element = player.gui.top[name]

        if element and element.valid then
            element.destroy()
        end

        if Gui.get_mod_gui_top_frame() then
            element = Gui.get_button_flow(player)[name]

            if element and element.valid then
                element.destroy()
            end
        end
    end
end

local function setup_player_hud(player)
    remove_retired_hud(player)

    if
        ScenarioTable.mode("win_condition") == "survival" or
        (ScenarioTable.mode("win_condition") == "score" and ScenarioTable.enabled("rich_scoreboard"))
    then
        require("maps.scrap_towny_ffa.score_board").add_score_button(player)
    end

    local TownStatus = require "maps.scrap_towny_ffa.town_status"
    if TownStatus.enabled() then
        TownStatus.add_button(player)
        TownStatus.player_changes_town_status(player, Team.is_towny(player.force))
    end

    if ScenarioTable.enabled("hud_last_winner") and ScenarioTable.enabled("persist_last_winner") then
        Info.add_last_winner_button(player)
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]

    Team.on_player_joined(player)

    Info.toggle_button(player)

    remove_retired_hud(player)
    player.set_goal_description("")
    if
        ScenarioTable.enabled("hud_research_cost") or ScenarioTable.enabled("hud_damage") or
        ScenarioTable.enabled("hud_last_winner") or
        ScenarioTable.enabled("rich_scoreboard") or
        ScenarioTable.enabled("research_balance") or
        ScenarioTable.enabled("dynamic_damage_modifier") or
        ScenarioTable.enabled("market_enemy_display") or
        ScenarioTable.enabled("pvp_offline_shield") or
        ScenarioTable.enabled("pvp_league_shield") or
        ScenarioTable.enabled("pvp_afk_shield") or
        ScenarioTable.mode("win_condition") == "survival"
    then
        setup_player_hud(player)
    end

    Team.set_player_color(player)

    if player.online_time == 0 then
        Public.settings(player)

        Public.increment()

        Public.initialize(player)

        Public.spawn(player)
        Info.show(player)
    end

    Public.load_buffs(player)

    Public.requests(player)
end

local function on_player_respawned(event)
    local this = ScenarioTable.get()

    local player = game.players[event.player_index]

    local surface = player.surface

    Team.give_player_items(player)

    if player.force == game.forces["rogue"] then
        Team.set_player_to_outlander(player)
    end

    if player.force == game.forces["player"] then
        Team.give_key(player.index)
    end

    local spawn_point = Spawn.get_spawn_point(player, surface)

    this.last_respawn[player.name] = game.tick

    local position = surface.find_non_colliding_position("character", spawn_point, 50, 1)

    if position then
        player.teleport(position, surface)
    else
        player.teleport(spawn_point, surface)
    end

    Public.load_buffs(player)
end

local function on_player_died(event)
    local this = ScenarioTable.get()

    local player = game.players[event.player_index]

    if this.strikes[player.name] == nil then
        this.strikes[player.name] = 0
    end

    local ticks_elapsed = game.tick - this.last_respawn[player.name]

    if ticks_elapsed < max_ticks_between_spawns then
        this.strikes[player.name] = this.strikes[player.name] + 1
    else
        this.strikes[player.name] = 0
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)

return Public
