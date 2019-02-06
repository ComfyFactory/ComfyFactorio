-- prints death messages to all forces with custom texts -- by mewmew

local event = require 'utils.event'
local math_random = math.random
local message_color = {r=0.85, g=0.0, b=0.0}

local messages = {
	["small-biter"] = {" was nibbled to death.", " should not have played with the biters.", " is biter food."},
	["medium-biter"] = {" lost their leg to a hungry biter.", " is biter food.", " was a tasty biter treat."},
	["big-biter"] = {" had their head chomped off.", " is biter food.", " was a tasty biter treat."},
	["behemoth-biter"] = {" was devoured by a behemoth biter.", " was crushed by a behemoth biter.", " is biter food."},
	["small-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time."},
	["medium-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time."},
	["big-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a spitter."},
	["behemoth-spitter"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a spitter."},
	["small-worm-turret"] = {" melted away by acid spit!", " couldn't dodge the spit in time."},
	["medium-worm-turret"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a medium worm turret."},
	["big-worm-turret"] = {" melted away by acid spit!", " couldn't dodge the spit in time.", " got blasted away by a big worm turret."},
	["gun-turret"] = {" was mowed down by a barrage from a gun turret."},
	["laser-turret"] = {" was fatally enlightened by a laser beam."}
}

local function on_player_died(event)
	local player = game.players[event.player_index]
	if event.cause then		
		if not event.cause.name then
			game.print(player.name .. " " .. player.tag .. " was killed." .. str, message_color)
			return
		end
		if messages[event.cause.name] then
			game.print(player.name .. messages[event.cause.name][math.random(1, #messages[event.cause.name])], message_color)
			return
		end
					
		if event.cause.name == "player" then			
			game.print(player.name .. " " .. player.tag .. " was killed by " .. event.cause.player.name " " .. event.cause.player.tag .. ".", message_color)							
			return
		end
		
		if event.cause.name == "tank" then
			local driver = event.cause.get_driver()
			if driver.player then 
				game.print(player.name .. " " .. player.tag .. " was killed by " .. driver.player.name .. " " .. player.tag .. ".", message_color)			
			end
		end
		
		game.print(player.name .. " " .. player.tag .. " was killed by " .. event.cause.name .. ".", message_color)
		return
	end
	for _, p in pairs(game.connected_players) do
		if player.force.name ~= p.force.name then
			if player.tag ~= "" then
				p.print(player.name .. " " .. player.tag .. " was killed.", message_color)
				return
			end
			p.print(player.name .. " was killed.", message_color)
		end
	end
end

event.add(defines.events.on_player_died, on_player_died)