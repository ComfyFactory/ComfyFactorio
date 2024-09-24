local Event = require 'utils.event'

Event.add(
    defines.events.on_entity_damaged,
    function (event)
        local entity = event.entity
        if not entity.valid then
            return
        end
        if event.entity.name ~= 'character' then
            return
        end
        local player = game.get_player(event.entity.player)
        if not player.character then
            return
        end
        if player.character then
            if player.character.health == nil then
                return
            end
            local index = player.index
            local health = math.ceil(player.character.health)
            if storage.player_health == nil then
                storage.player_health = {}
            end
            if storage.player_health[index] == nil then
                storage.player_health[index] = health
            end
            if storage.player_health[index] ~= health then
                if health < storage.player_health[index] then
                    local text = health .. ' (-' .. math.floor(event.final_damage_amount) .. ')'
                    if health > 200 then
                        player.surface.create_entity {
                            name = 'flying-text',
                            color = { b = 0.2, r = 0.1, g = 1, a = 0.8 },
                            text = text,
                            position = { player.position.x, player.position.y - 2 }
                        }
                    elseif health > 100 then
                        player.surface.create_entity { name = 'flying-text', color = { r = 1, g = 1, b = 0 }, text = text, position = { player.position.x, player.position.y - 2 } }
                    else
                        player.surface.create_entity {
                            name = 'flying-text',
                            color = { b = 0.1, r = 1, g = 0, a = 0.8 },
                            text = text,
                            position = { player.position.x, player.position.y - 2 }
                        }
                    end
                end
                storage.player_health[index] = health
            end
        end
    end
)
