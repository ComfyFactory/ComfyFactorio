local colors = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}}
local function add_light(e)
	local color = colors[math.random(1, 3)]
	local light_nr = rendering.draw_light({sprite="utility/light_small", orientation=1, scale=1, intensity=1, minimum_darkness=0, oriented=false, color=color, target=e, target_offset={0, -0.5}, surface=e.surface})
end

local function on_chunk_generated(event)	
	local surface = event.surface
	local seed = surface.map_gen_settings.seed
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local set_tiles = surface.set_tiles
	local get_tile = surface.get_tile
	
	local entities = surface.find_entities_filtered({type = {"simple-entity", "tree", "fish"}, area = event.area})
	if #entities > 1 then table.shuffle_table(entities) end
	for k, e in pairs(entities) do
		add_light(e)
		if k > 7 then break end
	end
	
	rendering.draw_sprite({sprite = "tile/lab-white", x_scale = 32, y_scale = 32, target = event.area.left_top, surface = surface, tint = {r = 0.6, g = 0.6, b = 0.6, a = 0.6}, render_layer = "ground"})
end

local function on_init()
	local surface = game.surfaces.nauvis
	surface.daytime = 0.43
	surface.freeze_daytime = true
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)