
local Common = require 'maps.pirates.common'
local Balance = require 'maps.pirates.balance'
local Utils = require 'maps.pirates.utils_local'
local Math = require 'maps.pirates.math'
local inspect = require 'utils.inspect'.inspect
local Boats = require 'maps.pirates.structures.boats.boats'
local Memory = require 'maps.pirates.memory'
local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local Public = {}

local GuiCommon = require 'maps.pirates.gui.common'

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

local function get_evolution_percentage()
	local memory = Memory.get_crew_memory()

	local value = Math.floor((memory.evolution_factor or 0) * 1000) * 0.001

	return value
end

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

function Public.update(player)
	local memory = Memory.get_crew_memory()
	local pirates_flow = player.gui.top

	local button = pirates_flow.evo_piratebutton_frame.evo_piratebutton
	if button and button.valid then
		local evolution_factor = get_evolution_percentage()
		local evo = evolution_factor
		-- local current_alien = get_alien_name(evolution_factor)
		-- local sprite = 'entity/' .. current_alien

		-- if evolution_factor == 0 or (memory.boat and (memory.boat.state == Boats.enum_state.ATSEA_SAILING or memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP)) then
		-- 	button.number = 0
		-- 	button.tooltip = 'Local biter evolution\n\n0'
		-- else

			local destination = Common.current_destination()
			local evolution_base
			local evolution_time
			local evolution_silo
			local evolution_nests
			if memory.boat and memory.boat.state and (memory.boat.state == Boats.enum_state.ATSEA_SAILING or memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP) then
				evolution_base = evo - (memory.kraken_evo or 0)
				-- here Kraken.kraken_slots
				local krakens = false
				if memory.active_sea_enemies and memory.active_sea_enemies.krakens then
					for i = 1, Kraken.kraken_slots do
						if memory.active_sea_enemies.krakens[i] then krakens = true break end
					end
				end
				if krakens then --@FIXME: somehow this isn't triggering?
					button.tooltip = string.format('Local biter evolution\n\nBase: %.2f\nKraken: %.2f\nTotal: %.2f', evolution_base, Balance.kraken_spawns_base_extra_evo + (memory.kraken_evo or 0), Balance.kraken_spawns_base_extra_evo + evo)
					button.number = Balance.kraken_spawns_base_extra_evo + evo
				else
					button.tooltip = string.format('Local biter evolution\n\nBase: %.2f\nTotal: %.2f', evolution_base, evo)
					button.number = evo
				end
			else
				evolution_base = (destination and destination.dynamic_data and destination.dynamic_data.evolution_accrued_leagues) or 0
				evolution_time = (destination and destination.dynamic_data and destination.dynamic_data.evolution_accrued_time) or 0
				evolution_nests = (destination and destination.dynamic_data and destination.dynamic_data.evolution_accrued_nests) or 0
				evolution_silo = (destination and destination.dynamic_data and destination.dynamic_data.evolution_accrued_silo) or 0
				button.tooltip = string.format('Local biter evolution\n\nLeagues: %.2f\nTime: %.2f\nNests: %.2f\nSilo: %.2f\nTotal: %.2f', evolution_base, evolution_time, evolution_nests, evolution_silo, evo)
				button.number = evo
			end
		-- end
		-- if sprite then
		-- 	button.sprite = spritem
		-- end
	end
end


return Public