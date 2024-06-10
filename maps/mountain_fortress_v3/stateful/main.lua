local Public = require 'maps.mountain_fortress_v3.stateful.table'
local Event = require 'utils.event'
local WD = require 'modules.wave_defense.table'
local Beam = require 'modules.render_beam'
local RPG = require 'modules.rpg.main'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

Public.stateful_gui = require 'maps.mountain_fortress_v3.stateful.gui'
Public.stateful_blueprints = require 'maps.mountain_fortress_v3.stateful.blueprints'

local random = math.random

local valid_types = {
    ['unit'] = true,
    ['turret'] = true
}

---@param event EventData.on_entity_died
local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if not Public.valid_enemy_forces[entity.force.name] then
        return
    end

    local objectives = Public.get_stateful('objectives')

    local damage_type = event.damage_type
    if not damage_type then
        return
    end
    local killed_enemies = objectives.killed_enemies_type
    if not killed_enemies then
        return
    end

    if killed_enemies.damage_type ~= damage_type.name then
        return
    end

    if valid_types[entity.type] then
        killed_enemies.actual = killed_enemies.actual + 1
    end
end

Event.add(
    defines.events.on_research_finished,
    function (event)
        local research = event.research
        if not research then
            return
        end

        local name = research.name
        local objectives = Public.get_stateful('objectives')
        if not objectives then
            return
        end
        if not objectives.research_level_selection then
            return
        end

        if name == objectives.research_level_selection.name then
            objectives.research_level_selection.research_count = objectives.research_level_selection.research_count + 1
        end
    end
)

Event.on_nth_tick(
    150,
    function ()
        local final_battle = Public.get_stateful('final_battle')
        if not final_battle then
            return
        end

        local collection = Public.get_stateful('collection')
        if not collection then
            return
        end

        if collection.final_arena_disabled then
            return
        end

        if collection.gather_time and collection.gather_time <= 0 and collection.survive_for and collection.survive_for > 0 then
            local spawn_positions = table.deepcopy(Public.get_stateful('stateful_spawn_points'))

            if not spawn_positions then
                Public.set_stateful(
                    'stateful_spawn_points',
                    {
                        { { x = -205, y = -37 },  { x = 195, y = 37 } },
                        { { x = -205, y = -112 }, { x = 195, y = 112 } },
                        { { x = -205, y = -146 }, { x = 195, y = 146 } },
                        { { x = -205, y = -112 }, { x = 195, y = 112 } },
                        { { x = -205, y = -72 },  { x = 195, y = 72 } },
                        { { x = -205, y = -146 }, { x = 195, y = 146 } },
                        { { x = -205, y = -37 },  { x = 195, y = 37 } },
                        { { x = -205, y = -5 },   { x = 195, y = 5 } },
                        { { x = -205, y = -23 },  { x = 195, y = 23 } },
                        { { x = -205, y = -5 },   { x = 195, y = 5 } },
                        { { x = -205, y = -72 },  { x = 195, y = 72 } },
                        { { x = -205, y = -23 },  { x = 195, y = 23 } },
                        { { x = -205, y = -54 },  { x = 195, y = 54 } },
                        { { x = -205, y = -80 },  { x = 195, y = 80 } },
                        { { x = -205, y = -54 },  { x = 195, y = 54 } },
                        { { x = -205, y = -80 },  { x = 195, y = 80 } },
                        { { x = -205, y = -103 }, { x = 195, y = 103 } },
                        { { x = -205, y = -150 }, { x = 195, y = 150 } },
                        { { x = -205, y = -103 }, { x = 195, y = 103 } },
                        { { x = -205, y = -150 }, { x = 195, y = 150 } }
                    }
                )

                spawn_positions = Public.get_stateful('stateful_spawn_points')
            end

            local sizeof = #spawn_positions

            local area = spawn_positions[random(1, sizeof)]

            local locomotive = Public.get('locomotive')
            if not locomotive or not locomotive.valid then
                return
            end

            area[1].y = area[1].y + locomotive.position.y
            area[2].y = area[2].y + locomotive.position.y

            if random(1, 2) == 1 then
                WD.set_spawn_position(area[1])
            else
                WD.set_spawn_position(area[2])
            end

            WD.set_main_target()
            WD.build_worm_custom()
            -- WD.place_custom_nest(locomotive.surface, area[1], 'aggressors_frenzy')
            Event.raise(WD.events.on_spawn_unit_group_simple, { fs = true, bypass = true, random_bosses = true, scale = 32, force = 'aggressors_frenzy' })
            return
        end

        if collection.survive_for and collection.survive_for == 0 then
            if not collection.game_won then
                collection.game_won = true
            end
        end
    end
)

Event.add(
    defines.events.on_player_crafted_item,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local item = event.item_stack
        if not item or not item.valid_for_read then
            return
        end

        local objectives = Public.get_stateful('objectives')

        local handcrafted_items_any = objectives.handcrafted_items_any
        if handcrafted_items_any then
            handcrafted_items_any.actual = handcrafted_items_any.actual + item.count
        end

        local handcrafted_items = objectives.handcrafted_items
        if handcrafted_items then
            if item.name ~= handcrafted_items.name then
                return
            end

            handcrafted_items.actual = handcrafted_items.actual + item.count
        end
    end
)

Event.add(
    defines.events.on_rocket_launched,
    function (event)
        local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
        local slot = rocket_inventory[1]
        if slot and slot.valid and slot.valid_for_read then
            local objectives = Public.get_stateful('objectives')

            local launch_item = objectives.launch_item
            if launch_item then
                if slot.name ~= launch_item.name then
                    return
                end

                launch_item.actual = launch_item.actual + slot.count
            end
        end
    end
)

Event.add(
    RPG.events.on_spell_cast_success,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local spell_name = event.spell_name
        local amount = event.amount

        if not player.character or not player.character.valid then
            return
        end

        local objectives = Public.get_stateful('objectives')

        local cast_spell_any = objectives.cast_spell_any
        if cast_spell_any then
            cast_spell_any.actual = cast_spell_any.actual + amount
        end

        local cast_spell = objectives.cast_spell
        if cast_spell then
            if spell_name ~= cast_spell.name then
                return
            end

            cast_spell.actual = cast_spell.actual + amount
        end
    end
)

Event.on_nth_tick(
    14400,
    function ()
        local final_battle = Public.get_stateful('final_battle')
        if not final_battle then
            return
        end

        local collection = Public.get_stateful('collection')
        if not collection then
            return
        end

        if collection.final_arena_disabled then
            return
        end

        local active_surface_index = Public.get('active_surface_index')
        local surface = game.get_surface(active_surface_index)
        if not surface or not surface.valid then
            return
        end

        if collection.gather_time and collection.gather_time <= 0 and collection.survive_for > 0 then
            Beam.new_beam(surface, game.tick + 350)
        end
    end
)

Event.add(defines.events.on_pre_player_died, Public.on_pre_player_died)
Event.add(Public.events.on_market_item_purchased, Public.on_market_item_purchased)
Event.add(BiterHealthBooster.events.custom_on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_died, on_entity_died)

return Public
