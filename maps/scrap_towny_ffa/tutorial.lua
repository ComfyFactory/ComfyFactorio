local Public = {}

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Event = require 'utils.event'
local Team = require 'maps.scrap_towny_ffa.team'



function Public.register_for_tutorial(player)
    local this = ScenarioTable.get_table()
    this.tutorials[player.index] = {show_after_tick = game.tick + 60 * 5}
end

local function tutorials_tick()
    local this = ScenarioTable.get_table()

    for _, player in pairs(game.connected_players) do
        if this.tutorials[player.index] then
            local tut = this.tutorials[player.index]

            if tut.show_after_tick and game.tick > tut.show_after_tick then
                this.tutorials[player.index].step = 1
                player.set_goal_description("Found a town by building your stone furnace.\n\nThis will also unlock your map.")
                tut.show_after_tick = nil
            end

            if this.tutorials[player.index].step == 1 and Team.is_towny(player.force) then
                this.tutorials[player.index].step = 2
                player.set_goal_description("Great!\nNow mine some scrap from around your town to get resources."
                .. "\n\nCollect 500 iron.")
            end

            if this.tutorials[player.index].step == 2 and player.get_item_count("iron-plate") >= 500 then
                player.set_goal_description("Great!\nThis is the end of the tutorial.\n\n"
                    .. "The goal of the game is to build a town that lasts as long as possible,\nagainst biters and players")

                this.tutorials[player.index].finish_at_tick = game.tick + 60 * 30
                this.tutorials[player.index].step = 3
            end

            if this.tutorials[player.index].step == 3 and game.tick > this.tutorials[player.index].finish_at_tick then
                player.set_goal_description("")
                this.tutorials[player.index] = nil
            end
        end
    end
end

Event.on_nth_tick(60, tutorials_tick)

return Public