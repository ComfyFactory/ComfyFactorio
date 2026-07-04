local Public = {}

function Public.initialize()

    game.map_settings.pollution.enabled = true
    game.map_settings.pollution.diffusion_ratio = 0.02
    game.map_settings.pollution.min_to_diffuse = 15
    game.map_settings.pollution.ageing = 1
    game.map_settings.pollution.expected_max_per_chunk = 150
    game.map_settings.pollution.min_to_show_per_chunk = 50
    game.map_settings.pollution.min_pollution_to_damage_trees = 60
    game.map_settings.pollution.pollution_with_max_forest_damage = 150
    game.map_settings.pollution.pollution_per_tree_damage = 50
    game.map_settings.pollution.pollution_restored_per_tree_damage = 10
    game.map_settings.pollution.max_pollution_to_restore_trees = 20
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1

    game.map_settings.enemy_evolution.enabled = true
    game.map_settings.enemy_evolution.time_factor = 0.0
    game.map_settings.enemy_evolution.destroy_factor = 0.0
    game.map_settings.enemy_evolution.pollution_factor = 0.0

    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_distance = 7
    game.map_settings.enemy_expansion.friendly_base_influence_radius = 4
    game.map_settings.enemy_expansion.other_base_coefficient = 2.0
    game.map_settings.enemy_expansion.neighbouring_base_chunk_coefficient = 0.4
    game.map_settings.enemy_expansion.enemy_building_influence_radius = 4
    game.map_settings.enemy_expansion.building_coefficient = 1.0
    game.map_settings.enemy_expansion.neighbouring_chunk_coefficient = 0.5
    game.map_settings.enemy_expansion.max_colliding_tiles_coefficient = 0.9
    game.map_settings.enemy_expansion.settler_group_min_size = 4
    game.map_settings.enemy_expansion.settler_group_max_size = 12
    game.map_settings.enemy_expansion.min_expansion_cooldown = 1200
    game.map_settings.enemy_expansion.max_expansion_cooldown = 3600

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

end

return Public
