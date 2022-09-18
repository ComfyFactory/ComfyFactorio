-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


-- local Memory = require 'maps.pirates.memory'
-- local Roles = require 'maps.pirates.roles.roles'
-- local Balance = require 'maps.pirates.balance'
local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
-- local Loot = require 'maps.pirates.loot'
local _inspect = require 'utils.inspect'.inspect

-- local Hold = require 'maps.pirates.surfaces.hold'

local Public = {}


function Public.generate_merchant_trades(market)
	-- local memory = Memory.get_crew_memory()

	if market and market.valid then

		local game_completion_progress = Common.game_completion_progress()
		market.add_market_item{price = {{'coin', 8000}, {'raw-fish', 100}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}}
		market.add_market_item{price = {{'coin', 5000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'battery-equipment', count = 1}}
		market.add_market_item{price = {{'coin', 2000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'solar-panel-equipment', count = 5}}
		market.add_market_item{price = {{'coin', 1000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'night-vision-equipment', count = 1}}
		market.add_market_item{price = {{'coin', 2000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'energy-shield-equipment', count = 1}}
		market.add_market_item{price = {{'coin', 1000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'personal-roboport-equipment', count = 1}}

		if game_completion_progress >= 0.96 then
			market.add_market_item{price = {{'coin', 8000}, {'raw-fish', 100}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}}
			market.add_market_item{price = {{'coin', 12000}, {'raw-fish', 100}}, offer = {type = 'give-item', item = 'power-armor', count = 1}}
			market.add_market_item{price = {{'coin', 5000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'battery-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 2000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'energy-shield-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 1000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'personal-roboport-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 8000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'battery-mk2-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 2000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'solar-panel-equipment', count = 5}}
			market.add_market_item{price = {{'coin', 6000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 1000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'night-vision-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 5000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'energy-shield-mk2-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 4000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'personal-roboport-mk2-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 8000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'exoskeleton-equipment', count = 1}}
			market.add_market_item{price = {{'coin', 10000}, {'raw-fish', 10}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment', count = 1}}
		end
		if game_completion_progress >= 2 then
				market.add_market_item{price = {{'coin', 24000}, {'raw-fish', 100}}, offer = {type = 'give-item', item = 'power-armor-mk2', count = 1}}
		end
	end
end


return Public