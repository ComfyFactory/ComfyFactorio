local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local Public = require 'maps.mountain_fortress_v3.table'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'

Commands.new('icw_reconnect_train', { 'mtn_v3_commands.reconnect_trains_help' })
	:require_admin()
	:require_validation()
	:callback(
		function (player)
			local suc = ICW_Func.reconstruct_all_trains(true)
			Discord.send_notification(
				{
					title = "Train reconnection requested",
					description = player.name .. ' requested reconnection of all trains via ICW.',
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
				player.print({ 'mtn_v3_commands.train_reconnection_queued' })
			else
				player.print({ 'mtn_v3_commands.failed_to_reconnect_all_trains' })
			end
			return true
		end
	)
