
local Common = require 'maps.pirates.common'
local Balance = require 'maps.pirates.balance'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
local _inspect = require 'utils.inspect'.inspect
local Boats = require 'maps.pirates.structures.boats.boats'
local Memory = require 'maps.pirates.memory'
local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local Public = {}

-- local GuiCommon = require 'maps.pirates.gui.common'

-- local button_sprites = {
-- 	['small-biter'] = 0,
-- 	['medium-biter'] = 0.2,
-- 	['small-spitter'] = 0.25,
-- 	['medium-spitter'] = 0.4,
-- 	['big-spitter'] = 0.5,
-- 	['big-biter'] = 0.501,
-- 	['behemoth-spitter'] = 0.9,
-- 	['behemoth-biter'] = 0.901
-- }

-- local function get_alien_name(evolution_factor)
-- 	local last_match = 'fish'
-- 	for name, alien_threshold in pairs(button_sprites) do
-- 		if evolution_factor == alien_threshold then
-- 			return name
-- 		end

-- 		-- next alien evolution_factor isn't reached
-- 		if alien_threshold > evolution_factor then
-- 			return last_match
-- 		end

-- 		-- surpassed this alien evolution_factor
-- 		if alien_threshold < evolution_factor then
-- 			last_match = name
-- 		end
-- 	end

-- 	return last_match
-- end



-- function Public.regular_update(player)

-- end

function Public.full_update(player)
	if Public.regular_update then Public.regular_update(player) end

	local memory = Memory.get_crew_memory()
	local pirates_flow = player.gui.top

	local button = pirates_flow.evo_piratebutton_frame.evo_piratebutton
	if button and button.valid then
		local evo = memory.evolution_factor or 0
		-- local evo = Math.floor(evo * 1000) * 0.001
		-- local current_alien = get_alien_name(evolution_factor)
		-- local sprite = 'entity/' .. current_alien

		-- if evolution_factor == 0 or (memory.boat and (memory.boat.state == Boats.enum_state.ATSEA_SAILING or memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP)) then
		-- 	button.number = 0
		-- 	button.tooltip = 'Local biter evolution\n\n0'
		-- else

		local destination = Common.current_destination()

		local evolution_leagues
		local evolution_kraken
		local evolution_time
		local evolution_silo
		local evolution_nests
		local evolution_sandwurms
		local evolution_total

		local types = {'leagues', 'kraken', 'time', 'silo', 'nests', 'sandwurms'}

		local str = 'Local biter evolution: '

		if memory.boat and memory.boat.state and (memory.boat.state == Boats.enum_state.ATSEA_SAILING or memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP) then
			evolution_leagues = evo - (memory.kraken_evo or 0)
			local krakens = false
			if memory.active_sea_enemies and memory.active_sea_enemies.krakens then
				for i = 1, Kraken.kraken_slots do
					if memory.active_sea_enemies.krakens[i] then krakens = true break end
				end
			end
			if krakens then
				evolution_kraken = Balance.kraken_spawns_base_extra_evo + (memory.kraken_evo or 0)
				evolution_total = evolution_leagues + Balance.kraken_spawns_base_extra_evo
			else
				evolution_total = evolution_leagues
			end
		else
			if destination and destination.dynamic_data then
				evolution_leagues = destination.dynamic_data.evolution_accrued_leagues
				evolution_time = destination.dynamic_data.evolution_accrued_time
				evolution_nests = destination.dynamic_data.evolution_accrued_nests
				evolution_silo = destination.dynamic_data.evolution_accrued_silo
				evolution_sandwurms = destination.dynamic_data.evolution_accrued_sandwurms
			end
			evolution_total = (evolution_leagues or 0) + (evolution_time or 0) + (evolution_nests or 0) + (evolution_silo or 0) + (evolution_sandwurms or 0)
		end

		str = str .. string.format('%.2f\n', evolution_total)
		for _, type in ipairs(types) do
			if type == 'leagues' then
				if evolution_leagues then
					str = str .. string.format('\nLeagues: %.2f', evolution_leagues)
				end
			elseif type == 'kraken' then
				if evolution_kraken then
					str = str .. string.format('\nKraken: %.2f', evolution_kraken)
				end
			elseif type == 'time' then
				if evolution_time then
					str = str .. string.format('\nTime: %.2f', evolution_time)
				end
			elseif type == 'silo' then
				if evolution_silo then
					str = str .. string.format('\nSilo: %.2f', evolution_silo)
				end
			elseif type == 'nests' then
				if evolution_nests then
					str = str .. string.format('\nNests: %.2f', evolution_nests)
				end
			elseif type == 'sandwurms' then
				if evolution_sandwurms then
					str = str .. string.format('\nSandwurms: %.2f', evolution_sandwurms)
				end
			end
		end

		button.number = evolution_total
		button.tooltip = str
	end
end


return Public