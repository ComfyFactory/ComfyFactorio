local Public = require 'maps.mountain_fortress_v3.stateful.table'
local Event = require 'utils.event'
local WD = require 'modules.wave_defense.table'
local Beam = require 'modules.render_beam'

Public.stateful_gui = require 'maps.mountain_fortress_v3.stateful.gui'
Public.stateful_terrain = require 'maps.mountain_fortress_v3.stateful.terrain'
Public.stateful_generate = require 'maps.mountain_fortress_v3.stateful.generate'
Public.stateful_blueprints = require 'maps.mountain_fortress_v3.stateful.blueprints'

local random = math.random
local shuffle = table.shuffle_table

Event.add(
    defines.events.on_research_finished,
    function(event)
        local research = event.research
        if not research then
            return
        end

        local name = research.name
        local objectives = Public.get_stateful('objectives')
        if not objectives then
            return
        end
        if name == objectives.research_level_selection.name then
            objectives.research_level_count = objectives.research_level_count + 1
        end
    end
)

Event.on_nth_tick(
    60,
    function()
        local final_battle = Public.get_stateful('final_battle')
        if not final_battle then
            return
        end

        Public.allocate()

        local collection = Public.get_stateful('collection')
        if not collection then
            return
        end

        if collection.time_until_attack and collection.time_until_attack <= 0 and collection.survive_for > 0 then
            local surface = game.get_surface('boss_room')
            if not surface or not surface.valid then
                return
            end

            local spawn_positions = Public.stateful_spawn_points
            local sizeof = Public.sizeof_stateful_spawn_points
            local rounds_survived = Public.get_stateful('rounds_survived')

            local area = spawn_positions[random(1, sizeof)]

            shuffle(area)

            WD.build_worm_custom()

            WD.set_spawn_position(area[1])
            Event.raise(WD.events.on_spawn_unit_group, {fs = true, bypass = true, random_bosses = true, scale = Public.stateful.scale(20 * (rounds_survived + 1), 100)})
            return
        end

        if collection.time_until_attack and collection.survive_for and collection.survive_for == 0 then
            if not collection.game_won then
                collection.game_won = true
            end
        end
    end
)

Event.on_nth_tick(
    14400,
    -- 200,
    function()
        local final_battle = Public.get_stateful('final_battle')
        if not final_battle then
            return
        end

        local collection = Public.get_stateful('collection')
        if not collection then
            return
        end

        local surface = game.get_surface('boss_room')
        if not surface or not surface.valid then
            return
        end

        if collection.time_until_attack and collection.time_until_attack <= 0 and collection.survive_for > 0 then
            Beam.new_beam(surface, game.tick + 600)
        end
    end
)

Event.add(defines.events.on_pre_player_died, Public.on_pre_player_died)

return Public
