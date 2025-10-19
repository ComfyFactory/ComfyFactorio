-- This module is used to create events that can be used throughout the game.
-- Without the need of requiring other modules.

local Event = require 'utils.event'
local Public =
{
    events =
    {
        on_entity_mined = Event.generate_event_name('on_entity_mined'),
        custom_on_entity_died = Event.generate_event_name('custom_on_entity_died'),
        remove_surface = Event.generate_event_name('remove_surface'),
        reset_game = Event.generate_event_name('reset_game'),
        init_surfaces = Event.generate_event_name('init_surfaces'),
        on_spell_cast_success = Event.generate_event_name('on_spell_cast_success'),
        on_spell_cast_failure = Event.generate_event_name('on_spell_cast_failure'),
        on_wave_created = Event.generate_event_name('on_wave_created'),
        on_unit_group_created = Event.generate_event_name('on_unit_group_created'),
        on_evolution_factor_changed = Event.generate_event_name('on_evolution_factor_changed'),
        on_game_reset = Event.generate_event_name('on_game_reset'),
        on_target_aquired = Event.generate_event_name('on_target_aquired'),
        on_primary_target_missing = Event.generate_event_name('on_primary_target_missing'),
        on_entity_created = Event.generate_event_name('on_entity_created'),
        on_biters_evolved = Event.generate_event_name('on_biters_evolved'),
        on_spawn_unit_group = Event.generate_event_name('on_spawn_unit_group'),
        on_spawn_unit_group_simple = Event.generate_event_name('on_spawn_unit_group_simple'),
        on_gui_removal = Event.generate_event_name('on_gui_removal'),
        on_gui_closed_main_frame = Event.generate_event_name('on_gui_closed_main_frame'),
        on_player_removed = Event.generate_event_name('on_player_removed'),

        -- config events
        on_config_changed = Event.generate_event_name('on_config_changed'),

        -- server events
        on_server_started = Event.generate_event_name('on_server_started'),
        on_changes_detected = Event.generate_event_name('on_changes_detected'),
        on_player_banned = Event.generate_event_name('on_player_banned'),
        on_player_jailed = Event.generate_event_name('on_player_jailed'),
        on_player_unjailed = Event.generate_event_name('on_player_unjailed'),

        -- bottom frame events
        bottom_quickbar_respawn_raise = Event.generate_event_name('bottom_quickbar_respawn_raise'),
        bottom_quickbar_location_changed = Event.generate_event_name('bottom_quickbar_location_changed'),

        -- poll events
        on_poll_complete = Event.generate_event_name('on_poll_complete'),
        on_poll_created = Event.generate_event_name('on_poll_created')
    }
}

return Public
