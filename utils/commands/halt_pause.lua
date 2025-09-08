local Commands = require 'utils.commands'
local Server = require 'utils.server'
local Discord = require 'utils.discord_handler'

Commands.new('halt_pause', 'Resumes the game if the backend has paused it.')
	:require_admin()
	:require_backend()
	:require_validation('This will resume the game from the script handler. Are you sure you want to continue?')
	:callback(function (player)
		if not Server.get_paused_state() or not game.tick_paused then
			player.print('The game is currently not paused.')
			return false
		end

		local server_name = Server.get_server_name() or 'CommandHandler'

		Discord.send_notification(
			{
				title = "Game unpaused from backend",
				description = player.name .. ' has triggered to unpause the game from the backend!',
				color = "success",
				fields =
				{
					{
						title = "Server",
						description = server_name,
						inline = "false"
					}
				}
			}
		)
		Server.log_halt_pause(player.name)
		player.print('[Handler] Game will shortly be unpaused. Please wait a moment for the game to resume.')
		return true
	end)
