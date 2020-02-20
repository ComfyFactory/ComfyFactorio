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
	label.style.font_color = {r = 150, g = 0, b = 255}

  local label = frame.add({ type = "label", caption = " ", name = "charger_value"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 96
	progressbar.style.maximal_width = 96
	progressbar.style.top_padding = 10

  local label = frame.add({ type = "label", caption = " ", name = "timer"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

  local label = frame.add({ type = "label", caption = " ", name = "timer_value", tooltip = " "})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

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

  local line = frame.add({type = "line", direction = "vertical"})
	line.style.left_padding = 4
	line.style.right_padding = 8

  local label = frame.add({ type = "label", caption = " ", name = "evo"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

  local label = frame.add({ type = "label", caption = " ", name = "evo_value"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

  local label = frame.add({ type = "label", caption = " ", name = "planet"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 0, g = 100, b = 200}

  local label = frame.add({ type = "label", caption = "[Upgrades]", name = "upgrades", tooltip = " "})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

end

local function update_gui(player)
  local objective = global.objective
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
		gui.timer_value.tooltip = "If overstaying this, other planets can evolve: " ..math_floor((objective.chrononeeds * 0.75 - objective.passivetimer) / 60) .. " min, " .. (objective.chrononeeds * 0.75 - objective.passivetimer) % 60 .. " s"
	else
		gui.timer_value.tooltip = "After planet 5, biters will get additional permanent evolution for staying too long on each planet."
	end

	gui.planet.caption = "Planet: " .. objective.planet[1].name.name .. " Ores: " .. objective.planet[1].ore_richness.name
  local acus = 0
  if global.acumulators then acus = #global.acumulators else acus = 0 end
  local bestcase = math_floor((objective.chrononeeds - objective.chronotimer) / (1 + math_floor(acus/10)))
  gui.timer2.caption = {"chronosphere.gui_3_1"}
	gui.timer_value2.caption = math_floor(bestcase / 60) .. " min, " .. bestcase % 60 .. " s (when using " .. acus * 0.3 .. "MW)"

  local evolution = game.forces["enemy"].evolution_factor
  gui.evo.caption = {"chronosphere.gui_4"}
  gui.evo_value.caption = math_floor(evolution * 100) .. "%"
  local chests = {
    [1] = {c = "250 wooden chests\n"},
    [2] = {c = "250 iron chests\n"},
    [3] = {c = "250 steel chests\n"},
    [4] = {c = "250 storage chests\n"},
    [5] = {c = "--\n"}
  }
  local upgt = {
    [1] = {t = "[1]: + 2500 Train Max HP. Current: " .. objective.max_health .. "\n    Cost : " .. math_floor(500 * (1 + objective.hpupgradetier /2)) .. " coins + 1500 copper plates\n"},
    [2] = {t = "[2]: Pollution Filter. Actual value of pollution made: " .. math_floor(300/(objective.filterupgradetier/3+1)) .. "%\n    Buyable once per 3 jumps.\n    Cost: 5000 coins + 2000 green circuits\n"},
    [3] = {t = "[3]: Add additional row of Acumulators.\n    Cost : " .. math_floor(2000 * (1 + objective.acuupgradetier /4)) .. " coins + 200 batteries\n"},
    [4] = {t = "[4]: Add item pickup distance to players.Current: +" .. objective.pickupupgradetier .. ",\n    Cost: " .. 1000 * (1 + objective.pickupupgradetier) .. " coins + 400 red inserters\n"},
    [5] = {t = "[5]: Add +5 inventory slots. Buyable once per 5 jumps.\n    Cost: " .. 2000 * (1 + objective.invupgradetier) .." coins + " .. chests[objective.invupgradetier + 1].c},
    [6] = {t = "[6]: Use up more repair tools on train at once. Current: +" .. objective.toolsupgradetier .. "\n    Cost: " .. 1000 * (1 + objective.toolsupgradetier) .. " coins + " .. 200 * (1 + objective.toolsupgradetier) .. " repair tools\n"},
    [7] = {t = "[7]: Add piping through wagon sides to create water sources for each wagon.\n    Cost: 2000 coins + 500 pipes\n"},
    [8] = {t = "[8]: Add comfylatron chests that output outside (into cargo wagon 2 and 3)\n    Cost: 2000 coins + 100 fast inserters\n"},
    [9] = {t = "[9]: Add storage chests to the sides of wagons.\n    Buyable once per 5 jumps.\n    Cost: 5000 coins + "  .. chests[objective.boxupgradetier + 1].c},
		[10] = {t = "[P]: Poison defense. Triggers automatically when train has low HP.\n    Actual charges: " .. objective.poisondefense .. " / 4\n    Recharge timer for next use: " .. math_ceil(objective.poisontimeout /6) .. "min\n    Cost: 1000 coins + 50 poison capsules\n"}
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
  gui.upgrades.tooltip =  tooltip


  -- if evolution < 10 then
  --   gui.evo.style.font_color = {r = 255, g = 255, b = 0}
  -- elseif evolution >= 10 and evolution < 50 then
  --   gui.evo.style.font_color = {r = 200, g = 0, b = 0}
  -- elseif evolution >= 50 and evolution < 90 then
  --   gui.evo.style.font_color = {r = 0, g = 140, b = 255}
  -- else
  --   gui.evo.style.font_color = {r = 0, g = 255, b = 0}
  -- end
  gui.evo.style.font_color = {
    r = math_floor(255 * 1 * math_max(0, math_min(1, 1.2 - evolution * 2))),
    g = math_floor(255 * 1 * math_max(math_abs(0.5 - evolution * 1.5), 1 - evolution * 4)),
    b = math_floor(255 * 4 * math_max(0, 0.25 - math_abs(0.5 - evolution)))
  }
  gui.evo_value.style.font_color = gui.evo.style.font_color
end

return update_gui
