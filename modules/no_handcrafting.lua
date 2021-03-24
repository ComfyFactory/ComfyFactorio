-- Disables all hand-crafting recipes and spawns a assembling-machine-2 close to spawn --- by Quadrum
-- "would make it so there is only 1 crafting machine that can not be mined and players have to fight over what it is making in the beginning" ~mewmew

local function disable_recipe(recipe, force)
    force.set_hand_crafting_disabled_for_recipe(recipe.name, 1)
end

local function on_player_joined_game()
    if game.tick == 0 then
        local surface = game.surfaces[1]

        local power_source = surface.create_entity({name = 'solar-panel', position = {x = -4, y = 3}, force = 'player'})
        power_source.destructible = false
        power_source.minable = true

        local power_pole = surface.create_entity({name = 'small-electric-pole', position = {x = -4, y = 1}, force = 'player'})
        power_pole.destructible = false
        power_pole.minable = true

        local assembler = surface.create_entity({name = 'assembling-machine-2', position = {x = -4, y = -1}, force = 'player'})
        assembler.destructible = false
        assembler.minable = false
        assembler.operable = true
    end
end

local function on_pre_player_crafted_item(event)
    local recipe = event.recipe
    local player = game.players[event.player_index]
    local count = event.queued_count

    player.cancel_crafting({index = 1, count = count})
    disable_recipe(recipe, player.force)
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_pre_player_crafted_item, on_pre_player_crafted_item)
