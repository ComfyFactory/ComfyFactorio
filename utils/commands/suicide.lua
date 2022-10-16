commands.add_command(
        'suicide',
        'Kills the player',
        function(cmd)
            local player = game.player

            if not player or not player.valid then
                return
            end
            if not player.character then
                return
            end
            player.character.die()
        end
)