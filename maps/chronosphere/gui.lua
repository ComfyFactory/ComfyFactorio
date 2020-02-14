local math_floor = math.floor
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

  local label = frame.add({ type = "label", caption = " ", name = "timer_value"})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

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
	gui.timer_value.caption = math_floor((objective.chrononeeds - objective.chronotimer) / 60) .. " minutes, " .. (objective.chrononeeds - objective.chronotimer) % 60 .. " seconds"

  local evolution = game.forces["enemy"].evolution_factor
  gui.evo.caption = {"chronosphere.gui_4"}
  gui.evo_value.caption = math_floor(evolution * 100) .. "%"

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
