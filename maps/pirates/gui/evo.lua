-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


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

		if Boats.is_boat_at_sea() then
			local krakens = false
			if memory.active_sea_enemies and memory.active_sea_enemies.krakens then
				for i = 1, Kraken.kraken_slots do
					if memory.active_sea_enemies.krakens[i] then krakens = true break end
				end
			end
			if krakens then
				evolution_leagues = evo - (memory.dynamic_kraken_evo or 0)
				evolution_kraken = Balance.kraken_static_evo + (memory.dynamic_kraken_evo or 0)
				evolution_total = evo + Balance.kraken_static_evo
			else
				evolution_leagues = evo
				evolution_total = evo
			end
		else
			if destination and destination.dynamic_data then
				evolution_leagues = destination.dynamic_data.evolution_accrued_leagues
				evolution_time = destination.dynamic_data.evolution_accrued_time
				evolution_nests = destination.dynamic_data.evolution_accrued_nests
				evolution_silo = destination.dynamic_data.evolution_accrued_silo
				evolution_sandwurms = destination.dynamic_data.evolution_accrued_sandwurms
			end
			evolution_total = (evolution_leagues or 0) + (evolution_time or 0) + (evolution_nests or 0) + (evolution_silo or 0) + (evolution_sandwurms or 0) + (evolution_kraken or 0)
		end

		local str = {'',{'pirates.gui_evo_tooltip_1', string.format('%.2f', evolution_total)}}

		if evolution_leagues or evolution_time or evolution_nests or evolution_silo or evolution_sandwurms then
			str[#str+1] = {'','\n'}
		end

		for _, type in ipairs(types) do
			if type == 'leagues' then
				if evolution_leagues then
					str[#str+1] = {'','\n',{'pirates.gui_evo_tooltip_2', string.format('%.2f', evolution_leagues)}}
				end
			elseif type == 'kraken' then
				if evolution_kraken then
					str[#str+1] = {'','\n',{'pirates.gui_evo_tooltip_3', string.format('%.2f', evolution_kraken)}}
				end
			elseif type == 'time' then
				if evolution_time then
					str[#str+1] = {'','\n',{'pirates.gui_evo_tooltip_4', string.format('%.2f', evolution_time)}}
				end
			elseif type == 'silo' then
				if evolution_silo then
					str[#str+1] = {'','\n',{'pirates.gui_evo_tooltip_5', string.format('%.2f', evolution_silo)}}
				end
			elseif type == 'nests' then
				if evolution_nests then
					str[#str+1] = {'','\n',{'pirates.gui_evo_tooltip_6', string.format('%.2f', evolution_nests)}}
				end
			elseif type == 'sandwurms' then
				if evolution_sandwurms then
					str[#str+1] = {'','\n',{'pirates.gui_evo_tooltip_7', string.format('%.2f', evolution_sandwurms)}}
				end
			end
		end

		button.number = evolution_total
		button.tooltip = str
		
		if evolution_total > 1.0 then
			button.sprite = 'entity/behemoth-worm-turret'
		elseif evolution_total >= 0.9 then
			button.sprite = 'entity/behemoth-biter'
		elseif evolution_total >= 0.5 then
			button.sprite = 'entity/big-biter'
		elseif evolution_total >= 0.4 then
			button.sprite = 'entity/medium-spitter'
		elseif evolution_total >= 0.25 then
			button.sprite = 'entity/small-spitter'
		elseif evolution_total >= 0.2 then
			button.sprite = 'entity/medium-biter'
		else
			button.sprite = 'entity/small-biter'
		end
	end
end


return Public