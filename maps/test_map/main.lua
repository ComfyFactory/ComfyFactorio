-- Test Map for testing general game mechanics

local Event = require 'utils.event'
local Task = require 'utils.task_token'
local Misc = require 'utils.commands.misc'

local spacing = 3
local entities_per_row = 200
local category_spacing = 5

local skip_types =
{
	['character'] = true,
	['item-entity'] = true,
	['item-request-proxy'] = true,
	['particle'] = true,
	['particle-source'] = true,
	['leaf-particle'] = true,
	['tile-ghost'] = true,
	['deconstructible-tile-proxy'] = true,
	['item-on-ground'] = true,
	['arrow'] = true,
	['artillery-flare'] = true,
	['beam'] = true,
	['cliff'] = true,
	['corpse'] = true,
	['rail-remnants'] = true,
	['highlight-box'] = true,
	['speech-bubble'] = true,
}

local skip_names =
{
	['player'] = true,
	['character'] = true,
}

local function create_entity_grid(surface, start_x, start_y, entities)
	local x = start_x
	local y = start_y
	local count = 0
	local created_count = 0

	for _, entity_name in pairs(entities) do
		if not skip_names[entity_name] then
			local position = { x = x, y = y }

			local safe_pos = surface.find_non_colliding_position(entity_name, position, 5, 0.5)
			if safe_pos then
				position = safe_pos
			end

			local success, err = pcall(function ()
				local entity = surface.create_entity(
					{
						name = entity_name,
						position = position,
						force = 'player'
					})
				if entity and entity.valid then
					entity.active = false
					if entity.type == 'unit' or entity.type == 'turret' then
						if entity.force then
							entity.force = 'neutral'
						end
					end
					return true
				end
				return false
			end)

			if success then
				created_count = created_count + 1
			end

			count = count + 1
			x = x + spacing

			if count % entities_per_row == 0 then
				x = start_x
				y = y + spacing
			end
		end
	end

	return y + category_spacing, created_count
end

local function spawn_all_entities(surface)
	game.print('[Test Map] Spawning all entities... This may take a moment.')

	local start_time = game.tick
	local current_y = 0
	local total_created = 0

	local entity_groups = {}

	for name, prototype in pairs(prototypes.entity) do
		local entity_type = prototype.type

		if not skip_types[entity_type] and not skip_names[name] then
			if not entity_groups[entity_type] then
				entity_groups[entity_type] = {}
			end
			table.insert(entity_groups[entity_type], name)
		end
	end

	local belt = 'transport-belt'

	for x = 1, 32 do
		for y = 1, 32 do
			surface.create_entity({ name = belt, position = { x = x - 50, y = y }, force = 'player' })
		end
	end

	local sorted_types = {}
	for entity_type, _ in pairs(entity_groups) do
		table.insert(sorted_types, entity_type)
	end
	table.sort(sorted_types)

	for _, entity_type in ipairs(sorted_types) do
		local entities = entity_groups[entity_type]
		table.sort(entities) -- Sort entity names alphabetically

		local label_pos = { x = -5, y = current_y + 2 }
		pcall(function ()
			surface.create_entity(
				{
					name = 'flying-text',
					position = label_pos,
					text = entity_type .. ' (' .. #entities .. ')',
					color = { r = 1, g = 1, b = 0 }
				})
		end)

		local new_y, created = create_entity_grid(surface, 0, current_y, entities)
		total_created = total_created + created
		current_y = new_y

		game.print('[Test Map] Placed ' .. created .. ' ' .. entity_type .. ' entities')
	end

	local end_time = game.tick
	local elapsed = (end_time - start_time) / 60

	game.print('[Test Map] Finished! Created ' .. total_created .. ' entities in ' .. string.format('%.2f', elapsed) .. ' seconds')
	game.print('[Test Map] Total entity types: ' .. #sorted_types)
end

local spawn_all_entities_token =
	Task.register(
		function (event)
			local surface = event.surface
			local player = event.player
			if not storage.test_map_initialized then
				game.print('[Test Map] Initializing test map...')

				game.map_settings.enemy_expansion.enabled = false
				game.map_settings.enemy_evolution.enabled = false
				game.map_settings.pollution.enabled = false

				local surface = player.surface
				spawn_all_entities(surface)

				storage.test_map_initialized = true
				player.print('[Test Map] All entities are pawned in a grid below.')
				player.set_controller({ type = defines.controllers.god })
				player.create_character()
				local players = Misc.get('players')
				players[player.index] = false
				Misc.insert_all_items(player)
			end
		end
	)

local chart_surface_token =
	Task.register(
		function (event)
			local surface = event.surface
			local player = event.player
			game.print('[Test Map] Charting surface...')
			game.forces.player.chart(surface, { { -100, -1000 }, { 100, 1000 } })
		end
	)

local function on_player_joined_game(event)
	local player = game.get_player(event.player_index)
	if not player then
		return
	end

	Task.set_timeout_in_ticks(10, chart_surface_token, { surface = player.surface, player = player })

	Task.set_timeout_in_ticks(100, spawn_all_entities_token, { surface = player.surface, player = player })

	if player.online_time < 5 then
		player.teleport({ 0, -0 }, player.surface)
		player.insert({ name = 'iron-plate', count = 100 })
		player.insert({ name = 'copper-plate', count = 100 })
		player.insert({ name = 'steel-plate', count = 50 })
		player.insert({ name = 'electronic-circuit', count = 50 })
	end
end

local function on_init()
	Misc.set('creative_enabled', true)

	game.surfaces[1].clear()
	local map_gen_settings = {}

	map_gen_settings.seed = math.random(10000, 99999)
	map_gen_settings.starting_area = 0.1

	map_gen_settings.width = 4000
	map_gen_settings.height = 1800
	map_gen_settings.water = 0.10
	map_gen_settings.terrain_segmentation = 3
	map_gen_settings.cliff_settings = { cliff_elevation_interval = 32, cliff_elevation_0 = 32 }
	map_gen_settings.autoplace_controls =
	{
		['coal'] = { frequency = 6, size = 1.2, richness = 1.5 },
		['stone'] = { frequency = 6, size = 1.2, richness = 1.5 },
		['copper-ore'] = { frequency = 6, size = 1.6, richness = 2 },
		['iron-ore'] = { frequency = 6, size = 1.6, richness = 2 },
		['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
		['crude-oil'] = { frequency = 5, size = 1.25, richness = 2 },
		['trees'] = { frequency = 1, size = 0.15, richness = 0.5 },
		['enemy-base'] = { frequency = 'none', size = 'none', richness = 'none' }
	}
	map_gen_settings.autoplace_settings =
	{
		['tile'] = { treat_missing_as_default = false },
	}
	map_gen_settings.property_expression_names =
	{
		['tile:water:probability'] = -10000,
		['tile:deep-water:probability'] = -10000
	}

	game.surfaces[1].map_gen_settings = map_gen_settings
	storage.test_map_initialized = false
end

-- Register events
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
