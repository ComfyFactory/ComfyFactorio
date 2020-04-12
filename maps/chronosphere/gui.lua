local Public_gui = {}

local math_floor = math.floor
local math_ceil = math.ceil
local math_abs = math.abs
local math_max = math.max
local math_min = math.min

local function create_gui(player)
	local frame = player.gui.top.add({ type = "frame", name = "chronosphere"})
	frame.style.maximal_height = 38

	local label = frame.add({ type = "label", caption = " ", name = "label"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local label = frame.add({ type = "label", caption = " ", name = "jump_number"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.right_padding = 4
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

  local label = frame.add({ type = "label", caption = " ", name = "charger"})
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.font_color = {r = 255, g = 200, b = 200} --255 200 200 --150 0 255

  local label = frame.add({ type = "label", caption = " ", name = "charger_value"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 255, g = 200, b = 200}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 96
	progressbar.style.maximal_width = 96
	progressbar.style.top_padding = 10

  local label = frame.add({ type = "label", caption = " ", name = "timer"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 255, g = 200, b = 200}

  local label = frame.add({ type = "label", caption = " ", name = "timer_value", tooltip = " "})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 255, g = 200, b = 200}

  local label = frame.add({ type = "label", caption = " ", name = "timer2"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 0, g = 200, b = 0}

  local label = frame.add({ type = "label", caption = " ", name = "timer_value2"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 0, g = 200, b = 0}

  -- local line = frame.add({type = "line", direction = "vertical"})
	-- line.style.left_padding = 4
	-- line.style.right_padding = 8

	local button = frame.add({type = "button", caption = " ", name = "planet_button"})
	button.style.font = "default-bold"
	button.style.font_color = { r=0.99, g=0.99, b=0.99}
	button.style.minimal_width = 75

	local button = frame.add({type = "button", caption = " ", name = "upgrades_button"})
	button.style.font = "default-bold"
	button.style.font_color = { r=0.99, g=0.99, b=0.99}
	button.style.minimal_width = 75

  -- local label = frame.add({ type = "label", caption = " ", name = "evo"})
	-- label.style.font = "default-bold"
	-- label.style.right_padding = 1
	-- label.style.minimal_width = 10
	-- label.style.font_color = {r = 150, g = 0, b = 255}

  -- local label = frame.add({ type = "label", caption = " ", name = "evo_value"})
	-- label.style.font = "default-bold"
	-- label.style.right_padding = 1
	-- label.style.minimal_width = 10
	-- label.style.font_color = {r = 150, g = 0, b = 255}

  -- local label = frame.add({ type = "label", caption = " ", name = "planet"})
	-- label.style.font = "default-bold"
	-- label.style.right_padding = 1
	-- label.style.minimal_width = 10
	-- label.style.font_color = {r = 0, g = 100, b = 200}

  -- local label = frame.add({ type = "label", caption = "[Upgrades]", name = "upgrades", tooltip = " "})
	-- label.style.font = "default-bold"
	-- label.style.right_padding = 1
	-- label.style.minimal_width = 10
	-- label.style.font_color = {r=0.33, g=0.66, b=0.9}

end

local function update_planet_gui(player)
	if not player.gui.screen["gui_planet"] then return end
	local planet = global.objective.planet[1]
	local evolution = game.forces["enemy"].evolution_factor
	local evo_color = {
    r = math_floor(255 * 1 * math_max(0, math_min(1, 1.2 - evolution * 2))),
    g = math_floor(255 * 1 * math_max(math_abs(0.5 - evolution * 1.5), 1 - evolution * 4)),
    b = math_floor(255 * 4 * math_max(0, 0.25 - math_abs(0.5 - evolution)))
  }
	local frame = player.gui.screen["gui_planet"]

	frame["planet_name"].caption = {"chronosphere.gui_planet_0", planet.name.name}
	frame["planet_ores"]["iron-ore"].number = planet.name.iron
	frame["planet_ores"]["copper-ore"].number = planet.name.copper
	frame["planet_ores"]["coal"].number = planet.name.coal
	frame["planet_ores"]["stone"].number = planet.name.stone
	frame["planet_ores"]["uranium-ore"].number = planet.name.uranium
	frame["planet_ores"]["oil"].number = planet.name.oil
	frame["richness"].caption = {"chronosphere.gui_planet_2", planet.ore_richness.name}
	frame["planet_biters"].caption = {"chronosphere.gui_planet_3", math_floor(evolution * 1000) / 10}
	frame["planet_biters"].style.font_color = evo_color

	frame["planet_biters3"].caption = {"chronosphere.gui_planet_4_1", global.objective.passivejumps * 2.5, global.objective.passivejumps * 10}
	frame["planet_time"].caption = {"chronosphere.gui_planet_5", planet.day_speed.name}

end

function Public_gui.update_gui(player)
  local objective = global.objective
	update_planet_gui(player)
	if not player.gui.top.chronosphere then create_gui(player) end
	local gui = player.gui.top.chronosphere

	gui.label.caption = {"chronosphere.gui_1"}
	gui.jump_number.caption = objective.chronojumps

	local interval = objective.chrononeeds
	gui.progressbar.value = 1 - (objective.chrononeeds - objective.chronotimer) / interval

	gui.charger.caption = {"chronosphere.gui_2"}
	gui.charger_value.caption = objective.chronotimer .. " / " .. objective.chrononeeds

  gui.timer.caption = {"chronosphere.gui_3"}
	gui.timer_value.caption = math_floor((objective.chrononeeds - objective.chronotimer) / 60) .. " min, " .. (objective.chrononeeds - objective.chronotimer) % 60 .. " s"
	if objective.chronojumps > 5 then
		local overstay_timer_min = math_floor((objective.chrononeeds * 0.75 - objective.passivetimer) / 60)
		local evo_timer_min = math_floor((objective.chrononeeds * 0.5 - objective.passivetimer) / 60)
		local first_part = "If overstaying this, other planets can evolve: " .. overstay_timer_min .. " min, " .. (objective.chrononeeds * 0.75 - objective.passivetimer) % 60 .. " s"
		if overstay_timer_min < 0 then
			first_part = "If overstaying this, other planets can evolve: " .. overstay_timer_min .. " min, " .. 59 - ((objective.chrononeeds * 0.75 - objective.passivetimer) % 60) .. " s"
		end
		local second_part = "This planet gets additional evolution growth in: " ..evo_timer_min .. " min, " .. (objective.chrononeeds * 0.5 - objective.passivetimer) % 60 .. " s"
		if evo_timer_min < 0 then
			second_part = "This planet gets additional evolution growth in: " ..evo_timer_min .. " min, " .. 59 -((objective.chrononeeds * 0.5 - objective.passivetimer) % 60) .. " s"
		end
		gui.timer_value.tooltip = first_part .. "\n" .. second_part
	else
		gui.timer_value.tooltip = "After planet 5, biters will get additional permanent evolution for staying too long on each planet."
	end

	gui.planet_button.caption = {"chronosphere.gui_planet_button"}
	gui.upgrades_button.caption = {"chronosphere.gui_upgrades_button"}

	--gui.planet.caption = "Planet: " .. objective.planet[1].name.name .. " | Ores: " .. objective.planet[1].ore_richness.name
  local acus = 0
  if global.acumulators then acus = #global.acumulators else acus = 0 end
  local bestcase = math_floor((objective.chrononeeds - objective.chronotimer) / (1 + math_floor(acus/10)))
	local nukecase = objective.dangertimer
	if objective.planet[1].name.id == 19 and objective.passivetimer > 31 then
		gui.timer2.caption = {"chronosphere.gui_3_2"}
		gui.timer_value2.caption = math_floor(nukecase / 60) .. " min, " .. nukecase % 60 .. " s"
		gui.timer2.style.font_color = {r=0.98, g=0, b=0}
		gui.timer_value2.style.font_color = {r=0.98, g=0, b=0}
	else
		gui.timer2.caption = {"chronosphere.gui_3_1"}
		gui.timer_value2.caption = math_floor(bestcase / 60) .. " min, " .. bestcase % 60 .. " s (when using " .. acus * 0.3 .. "MW)"
		gui.timer2.style.font_color = {r = 0, g = 200, b = 0}
		gui.timer_value2.style.font_color = {r = 0, g = 200, b = 0}
	end


  local evolution = game.forces["enemy"].evolution_factor
  --gui.evo.caption = {"chronosphere.gui_4"}
  --gui.evo_value.caption = math_floor(evolution * 100) .. "%"
  local chests = {
    [1] = {c = "250 wooden chests + Jump number 5\n"},
    [2] = {c = "250 iron chests + Jump number 10\n"},
    [3] = {c = "250 steel chests + Jump number 15\n"},
    [4] = {c = "250 storage chests + Jump number 20\n"},
    [5] = {c = "--\n"}
  }
  local upgt = {
    [1] = {t = "[1]: + 2500 Train Max HP. Current: " .. objective.max_health .. "\n    Cost : " .. math_floor(500 * (1 + objective.hpupgradetier /2)) .. " coins + 1500 copper plates\n"},
    [2] = {t = "[2]: Pollution Filter. Actual value of pollution made: " .. math_floor(300/(objective.filterupgradetier/3+1) * global.difficulty_vote_value) .. "%\n    Buyable once per 3 jumps.\n    Cost: 5000 coins + 2000 green circuits + Jump number " .. (objective.filterupgradetier + 1) * 3 .. "\n"},
    [3] = {t = "[3]: Add additional row of Acumulators.\n    Cost : " .. math_floor(2000 * (1 + objective.acuupgradetier /4)) .. " coins + 200 batteries\n"},
    [4] = {t = "[4]: Add item pickup distance to players.Current: +" .. objective.pickupupgradetier .. ",\n    Cost: " .. 1000 * (1 + objective.pickupupgradetier) .. " coins + 400 red inserters\n"},
    [5] = {t = "[5]: Add +10 inventory slots. Buyable once per 5 jumps.\n    Cost: " .. 2000 * (1 + objective.invupgradetier) .." coins + " .. chests[objective.invupgradetier + 1].c},
    [6] = {t = "[6]: Use up more repair tools on train at once. Current: +" .. objective.toolsupgradetier .. "\n    Cost: " .. 1000 * (1 + objective.toolsupgradetier) .. " coins + " .. 200 * (1 + objective.toolsupgradetier) .. " repair tools\n"},
    [7] = {t = "[7]: Add piping through wagon sides to create water sources for each wagon.\n    Cost: 2000 coins + 500 pipes\n"},
    [8] = {t = "[8]: Add comfylatron chests that output outside (into cargo wagon 2 and 3)\n    Cost: 2000 coins + 100 fast inserters\n"},
    [9] = {t = "[9]: Add storage chests to the sides of wagons.\n    Buyable once per 5 jumps.\n    Cost: 5000 coins + "  .. chests[objective.boxupgradetier + 1].c},
		[10] = {t = "[P]: Poison defense. Triggers automatically when train has low HP.\n    Actual charges: " .. objective.poisondefense .. " / 4\n    Recharge timer for next use: " .. math_ceil(objective.poisontimeout /6) .. "min\n    Cost: 1000 coins + 50 poison capsules\n"},
		[11] = {t = "[A]: 1x mk1 armor + 300 railgun darts + 100 low density structures -> 1x mk2 armor\n"},
		[12] = {t = "[R]: 16x personal solar + 200 railgun darts + 100 low density structures -> 1x fusion reactor\n"},
		[13] = {t = "[C]: Train computer fixing for Comfylatron. Finish this to fullfill the main objective.\n    Tier 1 costs: 5000 coins, 1000 advanced circuits, 2000 copper plates.\n    Discards very poor planets.\n"},
		[14] = {t = "[C]: Train power and navigation fixing for Comfylatron. Finish this to fullfill the main objective.\n    Tier 2 costs: 10000 coins, 1000 processing units, 1 nuclear reactor.\n   Discards poor planets.\n"},
		[15] = {t = "[C]: Train time machine processor fixing for Comfylatron. Finish this to fullfill the main objective.\n   Tier 3 costs per part: 2000 coins, 100 rocket control units, 100 low density structures, 50 uranium fuel cells.\n    Parts finished: " .. objective.computerparts .. " / 10\n"},
		[16] = {t = "[C]: Train is repaired. Synchronize the time to unlock final map to finish the main objective.\n    Costs: 1 rocket silo, 1 satellite.\n    Warning: after buying this, the next jump destination is locked to final map,\n    that means 100% evolution and no resources.\n"}
  }
  local maxed = {
    [1] = {t = "[1]: Train HP maxed.\n"},
    [2] = {t = "[2]: Pollution Filter maxed. Pollution made: " .. math_floor(300/(objective.filterupgradetier/3+1)) .. "%\n"},
    [3] = {t = "[3]: Acumulators maxed.\n"},
    [4] = {t = "[4]: Pickup distance maxed.\n"},
    [5] = {t = "[5]: Inventory maxed. Research Mining Productivity for more.\n"},
    [6] = {t = "[6]: Repairing at top speed of 5 packs.\n"},
    [7] = {t = "[7]: Piping created. Don't spill it!\n"},
    [8] = {t = "[8]: Output chests created.\n"},
    [9] = {t = "[9]: Storage chests fully upgraded.\n"},
		[10] = {t = "[C]: Train's next destination is Fish Market.\n"}
  }
  local tooltip = "Insert needed items into chest with upgrade number.\nUpgrading can take a minute.\n\n"
  if objective.hpupgradetier < 36 then tooltip = tooltip .. upgt[1].t else tooltip = tooltip .. maxed[1].t end
  if objective.filterupgradetier < 9 then tooltip = tooltip .. upgt[2].t else tooltip = tooltip .. maxed[2].t end
  if objective.acuupgradetier < 24 then tooltip = tooltip .. upgt[3].t else tooltip = tooltip .. maxed[3].t end
  if objective.pickupupgradetier < 4 then tooltip = tooltip .. upgt[4].t else tooltip = tooltip .. maxed[4].t end
  if objective.invupgradetier < 4 then tooltip = tooltip .. upgt[5].t else tooltip = tooltip .. maxed[5].t end
  if objective.toolsupgradetier < 4 then tooltip = tooltip .. upgt[6].t else tooltip = tooltip .. maxed[6].t end
  if objective.waterupgradetier < 1 then tooltip = tooltip .. upgt[7].t else tooltip = tooltip .. maxed[7].t end
  if objective.outupgradetier < 1 then tooltip = tooltip .. upgt[8].t else tooltip = tooltip .. maxed[8].t end
  if objective.boxupgradetier < 4 then tooltip = tooltip .. upgt[9].t else tooltip = tooltip .. maxed[9].t end
	tooltip = tooltip .. upgt[10].t
	if objective.chronojumps >= 24 then
		tooltip = tooltip .. upgt[11].t .. upgt[12].t
	else
		tooltip = tooltip .. "Armor and reactor can be bought since jump 24 (for railgun darts).\n"
	end
	if objective.computerupgrade == 0 and objective.chronojumps >= 15 and objective.computermessage == 1 then
		tooltip = tooltip .. upgt[13].t
	elseif objective.computerupgrade == 1 and objective.chronojumps >= 20 and objective.computermessage == 3 then
		tooltip = tooltip .. upgt[14].t
	elseif objective.computerupgrade == 2 and objective.chronojumps >= 25 and objective.computermessage == 5 then
		if objective.computerparts < 10 then
			tooltip = tooltip .. upgt[15].t
		elseif objective.computerparts == 10 then
			tooltip = tooltip .. upgt[16].t
		end
	elseif objective.computerupgrade == 3 and objective.chronojumps >= 25 then
		tooltip = tooltip .. maxed[10].t
	end
  --gui.upgrades.tooltip =  tooltip


  -- if evolution < 10 then
  --   gui.evo.style.font_color = {r = 255, g = 255, b = 0}
  -- elseif evolution >= 10 and evolution < 50 then
  --   gui.evo.style.font_color = {r = 200, g = 0, b = 0}
  -- elseif evolution >= 50 and evolution < 90 then
  --   gui.evo.style.font_color = {r = 0, g = 140, b = 255}
  -- else
  --   gui.evo.style.font_color = {r = 0, g = 255, b = 0}
  -- end
  -- gui.evo.style.font_color = {
  --   r = math_floor(255 * 1 * math_max(0, math_min(1, 1.2 - evolution * 2))),
  --   g = math_floor(255 * 1 * math_max(math_abs(0.5 - evolution * 1.5), 1 - evolution * 4)),
  --   b = math_floor(255 * 4 * math_max(0, 0.25 - math_abs(0.5 - evolution)))
  -- }
  -- gui.evo_value.style.font_color = gui.evo.style.font_color
end

local function upgrades_gui(player)
	if player.gui.screen["gui_upgrades"] then player.gui.screen["gui_upgrades"].destroy() return end
	local frame = player.gui.screen.add{type = "frame", name = "gui_upgrades", caption = "ChronoTrain Upgrades", direction = "vertical"}
  frame.location = {x = 350, y = 45}
  frame.style.minimal_height = 300
  frame.style.maximal_height = 300
  frame.style.minimal_width = 330
  frame.style.maximal_width = 630
  frame.add({type = "label", caption = {"chronosphere.gui_upgrades_1"}})
  frame.add({type = "button", name = "close_upgrades", caption = "Close"})
end

local function planet_gui(player)
	if player.gui.screen["gui_planet"] then player.gui.screen["gui_planet"].destroy() return end
	local planet = global.objective.planet[1]
	local evolution = game.forces["enemy"].evolution_factor
  --gui.evo.caption = {"chronosphere.gui_4"}
  --gui.evo_value.caption = math_floor(evolution * 100) .. "%"
	local frame = player.gui.screen.add{type = "frame", name = "gui_planet", caption = "Planet Info", direction = "vertical"}
  frame.location = {x = 650, y = 45}
  frame.style.minimal_height = 300
  frame.style.maximal_height = 500
  frame.style.minimal_width = 200
  frame.style.maximal_width = 400
	local l = {}
	l[1] = frame.add({type = "label", name = "planet_name", caption = {"chronosphere.gui_planet_0", planet.name.name}})
  l[2] = frame.add({type = "label", caption = {"chronosphere.gui_planet_1"}})
	local table0 = frame.add({type = "table", name = "planet_ores", column_count = 3})
	table0.add({type = "sprite-button", name = "iron-ore", sprite = "item/iron-ore", enabled = false, number = planet.name.iron})
	table0.add({type = "sprite-button", name = "copper-ore", sprite = "item/copper-ore", enabled = false, number = planet.name.copper})
	table0.add({type = "sprite-button", name = "coal", sprite = "item/coal", enabled = false, number = planet.name.coal})
	table0.add({type = "sprite-button", name = "stone", sprite = "item/stone", enabled = false, number = planet.name.stone})
	table0.add({type = "sprite-button", name = "uranium-ore", sprite = "item/uranium-ore", enabled = false, number = planet.name.uranium})
	table0.add({type = "sprite-button", name = "oil", sprite = "fluid/crude-oil", enabled = false, number = planet.name.oil})
	l[3] = frame.add({type = "label", name = "richness", caption = {"chronosphere.gui_planet_2", planet.ore_richness.name}})
	frame.add({type = "line"})
	frame.add({type = "label", name = "planet_biters", caption = {"chronosphere.gui_planet_3", math_floor(evolution * 1000) / 10}})
	frame.add({type = "label", name = "planet_biters2", caption = {"chronosphere.gui_planet_4"}})
	frame.add({type = "label", name = "planet_biters3", caption = {"chronosphere.gui_planet_4_1", global.objective.passivejumps * 2.5, global.objective.passivejumps * 10}})
	frame.add({type = "line"})
	frame.add({type = "label", name = "planet_time", caption = {"chronosphere.gui_planet_5", planet.day_speed.name}})
	frame.add({type = "line"})
  local close = frame.add({type = "button", name = "close_planet", caption = "Close"})
	close.style.horizontal_align = "center"
	-- for i = 1, 3, 1 do
	-- 	l[i].style.font = "default-game"
	-- end
end

function Public_gui.on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "upgrades_button" then
		upgrades_gui(player)
		return
	elseif event.element.name == "planet_button" then
		planet_gui(player)
		return
	end

	if event.element.type ~= "button" and event.element.type ~= "sprite-button" then return end
	local name = event.element.name
	if name == "close_upgrades" then upgrades_gui(player) return end
  if name == "close_planet" then planet_gui(player) return end
end



return Public_gui
