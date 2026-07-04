local Public = {}

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Event = require 'utils.event'

function Public.format_town_modifier(modifier)
    return string.format('%.0f%%', 100 * 1 / modifier)
end

local function calculate_modifier_for_town(town_center)
    local active_player_age_threshold = 2 * 60 * 60 * 60

    local this = ScenarioTable.get_table()
    local max_res = 0
    for _, tc in pairs(this.town_centers) do
        max_res = math.max(tc.evolution.worms, max_res)
    end
    local research_modifier = math.min(math.max(max_res, 0.01) / math.max(town_center.evolution.worms, 0.01), 5)

    local active_player_count = 0
    for _, player in pairs(town_center.market.force.players) do
        if game.tick - player.last_online < active_player_age_threshold then
            active_player_count = active_player_count + 1
        end
    end
    local player_modifier = math.max(active_player_count, 1) ^ -0.35
    local rested_modifier = 0.5 * ((town_center.town_rest and town_center.town_rest.current_modifier) or 0)

    return player_modifier * research_modifier + rested_modifier
end

local function update_modifiers()
    local this = ScenarioTable.get_table()
    for _, town_center in pairs(this.town_centers) do
        if not town_center.research_balance then
            town_center.research_balance = {}
            town_center.research_balance.previous_modifier = 1
        end
        town_center.research_balance.current_modifier = calculate_modifier_for_town(town_center)

        if math.abs(town_center.research_balance.current_modifier / town_center.research_balance.previous_modifier - 1) > 0.2 then
            town_center.market.force.print("Your research cost is now "
                .. Public.format_town_modifier(town_center.research_balance.current_modifier)
                .. ' (previously ' .. Public.format_town_modifier(town_center.research_balance.previous_modifier) .. ')', { 255, 255, 0 })
            town_center.research_balance.previous_modifier = town_center.research_balance.current_modifier
        end
    end
end

local function update_research_progress()
    local this = ScenarioTable.get_table()

    for _, town_center in pairs(this.town_centers) do
        local force = town_center.market.force
        if force.current_research then
            if town_center.research_balance.last_research
                and town_center.research_balance.last_research == force.current_research
            then
                local diff = force.research_progress - town_center.research_balance.last_progress
                force.research_progress = math.min(force.research_progress + diff * (town_center.research_balance.current_modifier - 1), 1)
            end
            town_center.research_balance.last_progress = force.research_progress
            town_center.research_balance.last_research = force.current_research
        end
    end
end

function Public.player_changes_town_status()
    update_modifiers()
end

Event.add(defines.events.on_tick, update_research_progress)
Event.on_nth_tick(61, update_modifiers)

return Public
