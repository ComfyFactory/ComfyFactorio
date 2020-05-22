local Public = {}

local Chrono_table = require 'maps.chronosphere.table'

local function create_button(player)
  local button = player.gui.top.add({ type = "sprite-button", name = "minimap_button", sprite = "utility/map"})
  button.visible = false
end

function Public.toggle_button(player)
  if not player.gui.top["minimap_button"] then
    create_button(player)
  end
  local button = player.gui.top["minimap_button"]
  if player.surface.name == "cargo_wagon" then
    button.visible = true
  else
    button.visible = false
  end
end

local function get_player_data(player)
  local objective = Chrono_table.get_table()
	local player_data = objective.icw.players[player.index]
	if objective.icw.players[player.index] then return player_data end

	objective.icw.players[player.index] = {
		surface = objective.active_surface_index,
		zoom = 0.30,
		map_size = 360,
	}
	return objective.icw.players[player.index]
end

local function kill_minimap(player)
	local element = player.gui.screen.icw_map_frame
	if element then element.destroy() end
end

local function draw_minimap(player)
  local objective = Chrono_table.get_table()
  local surface = game.surfaces[objective.active_surface_index]
  local position = objective.locomotive.position
  local frame = player.gui.screen.icw_map_frame
  if not frame then
    frame = player.gui.screen.add({ type = "frame", name = "icw_map_frame", caption = {"chronosphere.minimap"}})
    frame.location = {x = 10, y = 45}
  end
	local element = frame["icw_map"]
	if not element then
		local player_data = get_player_data(player)
		element = player.gui.screen.icw_map_frame.add({
			type = "camera",
			name = "icw_map",
			position = position,
			surface_index = surface.index,
			zoom = player_data.zoom,
			tooltip = {"chronosphere.minimap_tooltip"}
		})
		element.style.margin = 1
		element.style.minimal_height = player_data.map_size
		element.style.minimal_width = player_data.map_size
		return
	end
	element.position = position
end

function Public.minimap(player)
  if player.gui.screen["icw_map_frame"] then
    kill_minimap(player)
  else
    if player.surface.name == "cargo_wagon" then
      draw_minimap(player)
    end
  end
end

function Public.update_minimap()
	for k, player in pairs(game.connected_players) do
		if player.character and player.character.valid then
			if player.surface.name == "cargo_wagon" and player.gui.screen.icw_map then
				Public.draw_minimap(player)
			end
		end
	end
end

function Public.toggle_minimap(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	if element.name ~= "icw_map" then return end
	local player = game.players[event.player_index]
	local player_data = get_player_data(player)
	if event.button == defines.mouse_button_type.right then
		player_data.zoom = player_data.zoom - 0.07
		if player_data.zoom < 0.07 then player_data.zoom = 0.07 end
		element.zoom = player_data.zoom
		return
	end
	if event.button == defines.mouse_button_type.left then
		player_data.zoom = player_data.zoom + 0.07
		if player_data.zoom > 2 then player_data.zoom = 2 end
		element.zoom = player_data.zoom
		return
	end
	if event.button == defines.mouse_button_type.middle then
		player_data.map_size = player_data.map_size + 50
		if player_data.map_size > 650 then player_data.map_size = 250 end
		element.style.minimal_height = player_data.map_size
		element.style.minimal_width = player_data.map_size
		element.style.maximal_height = player_data.map_size
		element.style.maximal_width = player_data.map_size
		return
	end
end

return Public
