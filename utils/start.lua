local Event = require 'utils.event'
local Task = require 'utils.task_token'

local Public = {}

local bp =
'0eNqlm91O20AUhN9lrx2UM7b3J69SocrAUiwlTuQYKEV59yYEF1RXqWe4QiE7Xud82fXq08mru1k/5l3fdoNbvbr2dtvt3erbq9u3P7pmffrf8LLLbuXaIW9c4bpmc3q1bze7dV7kbmiHl8VzOzwsts9d7t2hcG13l3+6lR2uC/c2oM3na55Hf+8eNzfHkSv7/9UKt9vujxfYdqc7OV4UV3XhXo5/y6v6ONVd2+fb89u+cE9N3zbnV3YoJvNBmS99YcLyCx+wNH6+6isf8P8THnEO7fqd5d+XeS/S4c8t9Pm+7fLd4viNuu3zkN3phv+dqqRULaX8R2rG6ECNjtTopNx/uZRSxqVKiWYp0SwnXPbDtsuLXTM8XBgfyPGRHJ+48Z+5zBpPEqkkItVkpVy+t2rC4qH51fQfkyzW+X64kAxyMqrJ+ZWvpMrXUuXryVq4fG/1hNTcKtTkeqgn329upvn1rqV6e6nenqy3l+vtyf3Kk3w8uV95macneXqJZ5B4BpJnkHkGkmcgeQaSZ5B5BpJnkHhGiWckeUbyyRVJipGkGEmKkTxFRJJdlNgliV0i2SX5FJHkU0SSTxGJrHySKm9LqfRjbHbtx4CwEY7RwM6V5LnmV30MsGU3rezGlt30shu5dY2BwAYiG0jypyHAmgZWEw4GFix0sGA5QS872LJrYsA0M2AlW/ZSfoZYKT9ErJSfIsZqANM8gGkiYIzNB8CqA6vYbaxil0fFbmMVeQgz1iiYphRMcwrGSgXTrcIY9Xo06NGoR5McJbBrZsOmamPO8Pm4dalhrNUwVmsY6zXMs6uX9Rk2FRoXeQQOH6swLLBbbtDXKGsxjNUYFlh8rL6wwOGLHD7WWFjUVx9rL4zVF8b6C2MFhrEGwyKHT3MXxsqLMaBg1MWH6ebDdPUxRpMcJXBr3gSaNwHrTbAkN98x4NlAYAORDSQyMB8iNAsDzcKAtTDQLQxMXrswee3C5LUL3dGAdTTQHA3EphDW0UB3NAC7iqHDBrs8WakDTepAkzpgpc4YUDixXSLQLRDYjhGwLSNgZRE0WQRNFoGVRWBlEVhZBFYWgZVFYGURWFkETRZBk0VgZRF0WQRdFkGXRahZxLoiAquIoCkiaN0vYFURPLtiWUEEr4NlVRH0Hhiw0ghaFwy0NhiwEgl6Iwx0nYSgww76EVhvlQErm6A1y0DrlgErn8D2y4BVTmCVE1jlBFY5gVVO0LpmoKknJK27PWnt7Ynrb09cg3viOtyT1uKetB73OWrpujj/gmX16QcvhXvK/f7tQohWhYQQfVqWy+pw+A3SPoD5'

local create_start_token =
    Task.register(
        function (event)
            local player_index = event.player_index
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end
            Public.blueprint(player.surface)
        end
    )

function Public.blueprint(surface)
    local position = { x = 0, y = 5 }
    if not surface or not surface.valid then
        return
    end

    local item = surface.create_entity { name = 'item-on-ground', position = position, stack = { name = 'blueprint', count = 1 } }
    if not item then
        return
    end

    local success = item.stack.import_stack(bp)
    if success <= 0 then
        local tiles = {}
        local ghosts = item.stack.build_blueprint { surface = surface, force = 'player', position = position, build_mode = defines.build_mode.forced }
        for _, ghost in pairs(ghosts) do
            if ghost.ghost_type == 'tile' then
                table.insert(tiles, { name = ghost.ghost_name, position = ghost.position })
                ghost.destroy()
            else
                ghost.destroy()
            end
        end
        for _, tile in pairs(tiles) do
            if tile.name == 'refined-concrete' then
                surface.set_tiles { { name = 'black-refined-concrete', position = tile.position } }
            elseif tile.name == 'hazard-concrete-left' then
                surface.set_tiles { { name = 'brown-refined-concrete', position = tile.position } }
            elseif tile.name == 'stone-path' then
                surface.set_tiles { { name = 'orange-refined-concrete', position = tile.position } }
            elseif tile.name == 'concrete' then
                surface.set_tiles { { name = 'black-refined-concrete', position = tile.position } }
            end
        end
    end

    if item.valid then
        item.destroy()
    end
end

Event.add(
    defines.events.on_player_created,
    function (event)
        if event.player_index ~= 1 then
            return
        end

        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Task.set_timeout_in_ticks(15, create_start_token, { player_index = event.player_index })
    end
)

return Public
