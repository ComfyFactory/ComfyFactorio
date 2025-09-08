local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local Public = require 'maps.mountain_fortress_v3.table'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'

Commands.new('icw_reconnect_train', 'Usable only for admins - reconnects all trains!')
	:require_admin()
	:require_validation()
	:callback(
		function (player)
			local suc = ICW_Func.reconstruct_all_trains(true)
			Discord.send_notification(
				{
					title = "Trains reconnected",
					description = player.name .. ' is reconnecting all trains via icw module.',
					color = "success",
					fields =
					{
						{
							title = "Server",
							description = Public.discord_name,
							inline = "false"
						}
					}
				}
			)
			if suc then
				player.print(mapkeeper .. 'All trains have been reconnected!')
			else
				player.print(mapkeeper .. 'Failed to reconnect all trains!')
			end
			return true
		end
	)
