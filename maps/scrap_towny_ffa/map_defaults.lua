local Public = {}

function Public.initialize()
    -- difficulty settings
    game.difficulty_settings.recipe_difficulty = defines.difficulty_settings.recipe_difficulty.normal
    game.difficulty_settings.technology_difficulty = defines.difficulty_settings.technology_difficulty.normal
    game.difficulty_settings.technology_price_multiplier = 0.50
    game.difficulty_settings.research_queue_from_the_start = 'always'

    -- pollution settings
    game.map_settings.pollution.enabled = true
    game.map_settings.pollution.diffusion_ratio = 0.02 -- amount that is diffused to neighboring chunk each second
    game.map_settings.pollution.min_to_diffuse = 15 -- minimum number of pollution units on the chunk to start diffusing
    game.map_settings.pollution.ageing = 1 -- percent of pollution eaten by a chunk's tiles per second
    game.map_settings.pollution.expected_max_per_chunk = 150 -- anything greater than this number of pollution units is visualized similarly
    game.map_settings.pollution.min_to_show_per_chunk = 50
    game.map_settings.pollution.min_pollution_to_damage_trees = 60
    game.map_settings.pollution.pollution_with_max_forest_damage = 150
    game.map_settings.pollution.pollution_per_tree_damage = 50
    game.map_settings.pollution.pollution_restored_per_tree_damage = 10
    game.map_settings.pollution.max_pollution_to_restore_trees = 20
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1

    -- enemy evolution settings
    game.map_settings.enemy_evolution.enabled = true
    game.map_settings.enemy_evolution.time_factor = 0.0 -- percent increase in the evolution factor per second
    game.map_settings.enemy_evolution.destroy_factor = 0.0 -- percent increase in the evolution factor for each spawner destroyed
    game.map_settings.enemy_evolution.pollution_factor = 0.0 -- percent increase in the evolution factor for each pollution unit

    -- enemy expansion settings
    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_distance = 7 -- maximum distance in chunks from the nearest base (4 = 128 tiles)
    game.map_settings.enemy_expansion.friendly_base_influence_radius = 4 -- consider other nests within radius number of chunks (2 = 64 tiles)
    game.map_settings.enemy_expansion.other_base_coefficient = 2.0 -- multiply by coefficient for friendly bases
    game.map_settings.enemy_expansion.neighbouring_base_chunk_coefficient = 0.4 -- multiply by coefficient for friendly bases (^distance)
    game.map_settings.enemy_expansion.enemy_building_influence_radius = 4 -- consider player buildings within radius number of chunks
    game.map_settings.enemy_expansion.building_coefficient = 1.0 -- multiply by coefficient for player buildings
    game.map_settings.enemy_expansion.neighbouring_chunk_coefficient = 0.5 -- multiply by coefficient for player buildings (^distance)
    game.map_settings.enemy_expansion.max_colliding_tiles_coefficient = 0.9 -- percent of unbuildable tiles to not be considered a candidate
    game.map_settings.enemy_expansion.settler_group_min_size = 4 -- min size of group for building a base (multiplied by evo factor, so need evo > 0)
    game.map_settings.enemy_expansion.settler_group_max_size = 12 -- max size of group for building a base (multiplied by evo factor, so need evo > 0)
    game.map_settings.enemy_expansion.min_expansion_cooldown = 1200 -- minimum time before next expansion
    game.map_settings.enemy_expansion.max_expansion_cooldown = 3600 -- maximum time before next expansion

    -- unit group settings
    game.map_settings.unit_group.min_group_gathering_time = 400
    game.map_settings.unit_group.max_group_gathering_time = 2400
    game.map_settings.unit_group.max_wait_time_for_late_members = 3600
    game.map_settings.unit_group.max_group_radius = 30.0
    game.map_settings.unit_group.min_group_radius = 5.0
    game.map_settings.unit_group.max_member_speedup_when_behind = 1.4
    game.map_settings.unit_group.max_member_slowdown_when_ahead = 0.6
    game.map_settings.unit_group.max_group_slowdown_factor = 0.3
    game.map_settings.unit_group.max_group_member_fallback_factor = 3
    game.map_settings.unit_group.member_disown_distance = 10
    game.map_settings.unit_group.tick_tolerance_when_member_arrives = 60
    game.map_settings.unit_group.max_gathering_unit_groups = 30
    game.map_settings.unit_group.max_unit_group_size = 200

    ---- steering settings
    --game.map_settings.steering.default.radius = 1.2
    --game.map_settings.steering.default.separation_force = 0.005
    --game.map_settings.steering.default.separation_factor = 1.2
    --game.map_settings.steering.default.force_unit_fuzzy_goto_behavior = false
    --game.map_settings.steering.moving.radius = 3
    --game.map_settings.steering.moving.separation_force = 0.01
    --game.map_settings.steering.moving.separation_factor = 3
    --game.map_settings.steering.moving.force_unit_fuzzy_goto_behavior = false
end

return Public
