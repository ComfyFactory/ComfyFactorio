local Table = require 'modules.ubiquity.table'

local crash_site = {
	-- containers
	'big-ship-wreck-1',
	'big-ship-wreck-2',
	'big-ship-wreck-3',
	'crash-site-chest-1',
	'crash-site-chest-2',
	'crash-site-spaceship-wreck-medium-1',
	'crash-site-spaceship-wreck-medium-2',
	'crash-site-spaceship-wreck-medium-3',
	'crash-site-spaceship-wreck-big-1',
	'crash-site-spaceship-wreck-big-2',
	'crash-site-spaceship',
	'kr-crash-site-lab-repaired',
	'kr-crash-site-generator',
	'kr-crash-site-chest-1',
	'kr-crash-site-chest-2',
	'kr-crash-site-assembling-machine-1-repaired',
	'kr-crash-site-assembling-machine-2-repaired',
}

local function is_crash_site(entity)
	if not entity.valid then
		return false
	end
	local f = false
	for i = 1, #crash_site, 1 do
		if entity.name == crash_site[i] then
			f = true
		end
	end
	return f
end

local function mining_sound(target)
	if game.tick % 15 ~= 0 then
		return
	end
	local surface = target.surface
	local position = target.position
	local path = 'entity-mining/' .. target.name
	surface.play_sound({path = path, position = position, volume_modifier = 1, override_sound_type = 'game-effect'})
end

local function on_tick()
	local ubitable = Table.get_table()
	for index, player in pairs(game.players) do
		if player.character ~= nil then
			local mining = player.mining_state.mining
			if ubitable.mining[index] ~= mining then
				ubitable.mining[index] = mining
				-- state change
				if mining == true then
					local target = player.selected
					if target ~= nil and target.valid then
						if is_crash_site(target) then
							-- mining crash site
							mining_sound(target)
							ubitable.mining_target[index] = target
						end
					end
				else
					local target = ubitable.mining_target[index]
					if target ~= nil then
						ubitable.mining_target[index] = nil
					end
				end
			else
				if mining == true then
					local target = player.selected
					if target ~= nil and target.valid then
						if is_crash_site(target) then
							-- mining crash site
							mining_sound(target)
						end
					end
				end
			end
		end
	end
end

local on_init = function()
	local ubitable = Table.get_table()
	ubitable.mining = {}
	ubitable.mining_target = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
