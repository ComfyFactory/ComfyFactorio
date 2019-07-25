
    -- factorio scenario -- tank conquest -- xalpha made this --

    local blueprint_poi_base_json = require 'maps.tank_conquest.blueprint_poi_base_json'

    local blueprint_poi_flag_one_json = require 'maps.tank_conquest.blueprint_poi_flag_one_json'

    local blueprint_poi_flag_two_json = require 'maps.tank_conquest.blueprint_poi_flag_two_json'

    local blueprint_poi_flag_three_json = require 'maps.tank_conquest.blueprint_poi_flag_three_json'

    local blueprint_poi_fire_json = require 'maps.tank_conquest.blueprint_poi_fire_json'

    local blueprint_poi_laser_json = require 'maps.tank_conquest.blueprint_poi_laser_json'

    global.table_of_properties = {}

    global.table_of_properties.required_number_of_players = 2

    global.table_of_properties.countdown_in_seconds = 2701

    global.table_of_properties.wait_in_seconds = 10

    global.table_of_properties.size_of_the_battlefield = 1000

    global.table_of_properties.amount_of_tickets = 800

    global.table_of_properties.conquest_speed = 5

    global.table_of_properties.acceleration_value = 0.1

    global.table_of_properties.game_stage = 'lobby'

    global.table_of_scores = {}

    global.table_of_flags = {}

    global.table_of_squads = {}

    global.table_of_circles = {}

    local table_of_colors = { squad = { r = 75, g = 155, b = 45 }, team = { r = 65, g = 120, b = 200 }, enemy = { r = 190, g = 55, b = 50 }, neutral = { r = 77, g = 77, b = 77 }, damage = { r = 255, g = 0, b = 255 }, white = { r = 255, g = 255, b = 255 } }

    local event = require 'utils.event'

    local function initialize_forces()

        game.create_force( 'force_player_one' )

        game.create_force( 'force_player_two' )

        game.create_force( 'force_biter_one' )

        game.create_force( 'force_biter_two' )

        game.create_force( 'force_spectator' )

        local force = game.forces[ 'force_player_one' ]

        if global.table_of_properties[ force.name ] == nil then global.table_of_properties[ force.name ] = { name = force.name, enemy = 'force_player_two', icon = '☠', available_tickets = global.table_of_properties.amount_of_tickets } end

        force.set_friend( 'force_biter_two', true )

        force.set_friend( 'force_spectator', true )

        force.set_cease_fire( 'player', true )

        force.share_chart = true

        local force = game.forces[ 'force_player_two' ]

        if global.table_of_properties[ force.name ] == nil then global.table_of_properties[ force.name ] = { name = force.name, enemy = 'force_player_one', icon = '☣', available_tickets = global.table_of_properties.amount_of_tickets } end

        force.set_friend( 'force_biter_one', true )

        force.set_friend( 'force_spectator', true )

        force.set_cease_fire( 'player', true )

        force.share_chart = true

        local force = game.forces[ 'force_biter_one' ]

        force.set_friend( 'force_player_two', true )

        force.set_friend( 'force_biter_two', true )

        force.set_friend( 'force_spectator', true )

        force.set_friend( 'player', true )

        force.share_chart = false

        local force = game.forces[ 'force_biter_two' ]

        force.set_friend( 'force_player_one', true )

        force.set_friend( 'force_biter_one', true )

        force.set_friend( 'force_spectator', true )

        force.set_friend( 'player', true )

        force.share_chart = false

        local force = game.forces[ 'force_spectator' ]

        force.set_spawn_position( { 0, 0 }, game.surfaces[ 'nauvis' ] )

        force.technologies[ 'toolbelt' ].researched = true

        force.set_friend( 'force_player_one', true )

        force.set_friend( 'force_player_two', true )

        force.set_cease_fire( 'force_biter_one', true )

        force.set_cease_fire( 'force_biter_two', true )

        force.set_cease_fire( 'player', true )

        force.set_cease_fire( 'enemy', true )

        force.share_chart = true

        local force = game.forces[ 'player' ]

        force.set_cease_fire( 'force_player_one', true )

        force.set_cease_fire( 'force_player_two', true )

        force.set_cease_fire( 'force_biter_one', true )

        force.set_cease_fire( 'force_biter_two', true )

        force.set_cease_fire( 'force_spectator', true )

        force.share_chart = false

        local spectator = game.permissions.create_group( 'permission_spectator' )

        for action_name, _ in pairs( defines.input_action ) do spectator.set_allows_action( defines.input_action[ action_name ], false ) end

        local table_of_definitions = { defines.input_action.write_to_console, defines.input_action.gui_click, defines.input_action.gui_selection_state_changed, defines.input_action.gui_checked_state_changed, defines.input_action.gui_elem_changed, defines.input_action.gui_text_changed, defines.input_action.gui_value_changed, defines.input_action.start_walking, defines.input_action.open_kills_gui, defines.input_action.open_character_gui, defines.input_action.edit_permission_group, defines.input_action.toggle_show_entity_info, defines.input_action.rotate_entity, defines.input_action.start_research }

        for _, define in pairs( table_of_definitions ) do spectator.set_allows_action( define, true ) end

        for _, force in pairs( game.forces ) do

            game.forces[ force.name ].technologies[ 'artillery' ].enabled = false

            game.forces[ force.name ].technologies[ 'artillery-shell-range-1' ].enabled = false

            game.forces[ force.name ].technologies[ 'artillery-shell-speed-1' ].enabled = false

            game.forces[ force.name ].technologies[ 'atomic-bomb' ].enabled = false

            game.forces[ force.name ].set_turret_attack_modifier( 'flamethrower-turret', 4 )

            game.forces[ force.name ].set_turret_attack_modifier( 'laser-turret', 2 )

            game.forces[ force.name ].set_turret_attack_modifier( 'gun-turret', 6 )

            game.forces[ force.name ].research_queue_enabled = true

        end

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.grab_blueprint_record, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint_string, false )

        game.permissions.get_group( 'Default' ).set_allows_action( defines.input_action.import_blueprint, false )

    end

    function initialize_surface()

        game.map_settings.enemy_evolution.time_factor = 0

        game.map_settings.enemy_evolution.destroy_factor = 0

        game.map_settings.enemy_evolution.pollution_factor = 0

        game.map_settings.pollution.enabled = false

        game.map_settings.enemy_expansion.enabled = true

        game.map_settings.enemy_expansion.settler_group_min_size = 8

        game.map_settings.enemy_expansion.settler_group_max_size = 16

        game.map_settings.enemy_expansion.min_expansion_cooldown = 54000

        game.map_settings.enemy_expansion.max_expansion_cooldown = 108000

        local map_gen_settings = {}

        -- map_gen_settings.default_enable_all_autoplace_controls = false

        map_gen_settings.width = global.table_of_properties.size_of_the_battlefield

        map_gen_settings.height = global.table_of_properties.size_of_the_battlefield

        map_gen_settings.seed = math.random( 1, 2097152 )

        map_gen_settings.water = 'none'

        map_gen_settings.starting_area = 'none'

        map_gen_settings.cliff_settings = { name = 'cliff', cliff_elevation_0 = 0, cliff_elevation_interval = 0 }

        map_gen_settings.autoplace_controls = { [ 'trees' ] = { frequency = 'normal', size = 'normal', richness = 'normal' }, [ 'coal' ] = { frequency = 'none', size = 'none', richness = 'none' }, [ 'stone' ] = { frequency = 'none', size = 'none', richness = 'none' }, [ 'copper-ore' ] = { frequency = 'none', size = 'none', richness = 'none' }, [ 'uranium-ore' ] = { frequency = 'none', size = 'none', richness = 'none' }, [ 'iron-ore' ] = { frequency = 'none', size = 'none', richness = 'none' }, [ 'crude-oil' ] = { frequency = 'none', size = 'none', richness = 'none' }, [ 'enemy-base' ] = { frequency = 'none', size = 'none', richness = 'none' } }

        -- map_gen_settings.autoplace_settings = { entity = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } }, decorative = { treat_missing_as_default = true, settings = { frequency = 'none', size = 'none', richness = 'none' } } }

        if game.surfaces[ 'tank_conquest' ] == nil then

            game.create_surface( 'tank_conquest', map_gen_settings )

        else

            rendering.clear()

            game.surfaces[ 'tank_conquest' ].clear()

            game.surfaces[ 'tank_conquest' ].map_gen_settings = map_gen_settings

         end

    end

    function draw_gui_button( player )

        if player.gui.top[ 'draw_gui_button' ] then player.gui.top[ 'draw_gui_button' ].destroy() end

        local element_frame = player.gui.top.add{ type = 'frame', name = 'draw_gui_button', direction = 'vertical' }

        element_frame.style.minimal_width = 100

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.vertical_align = 'center'

        element_frame.style.horizontal_align  = 'center'

        local element_table = element_frame.add{ type = 'table', column_count = 1 }

        local element_button = element_table.add{ type = 'sprite-button', name = 'event_on_click_menu', caption = 'MENU' }

        -- local element_button = element_table.add{ type = 'sprite-button', name = 'event_on_click_score', caption = 'SCORE' }

        -- local element_button = element_table.add{ type = 'sprite-button', name = 'event_on_click_squad', caption = 'SQUAD' }

        for _, element_item in pairs( element_table.children ) do

            element_item.style.minimal_width = 80

            element_item.style.minimal_height = 30

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.font = 'heading-1'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function draw_gui_status( player )

        if player.gui.top[ 'draw_gui_status' ] then player.gui.top[ 'draw_gui_status' ].destroy() end

        if player.surface.name == 'nauvis' then return end

        if #global.table_of_flags == 0 then return end

        local element_frame = player.gui.top.add{ type = 'frame', name = 'draw_gui_status', direction = 'horizontal' }

        element_frame.style.minimal_height = 38

        element_frame.style.margin = 0

        element_frame.style.padding = 0

        element_frame.style.left_padding = 20

        element_frame.style.right_padding = 20

        element_frame.style.vertical_align = 'center'

        local element_progressbar = element_frame.add{ type = 'progressbar', value = 100 }

        element_progressbar.style.width = 150

        element_progressbar.style.right_padding = 20

        element_progressbar.style.top_padding = 10

        element_progressbar.style.color = table_of_colors.team

        local element_label = element_frame.add{ type = 'label', caption = math.floor( global.table_of_properties[ player.force.name ].available_tickets ) }

        element_label.style.right_padding = 20

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add{ type = 'label', caption = global.table_of_properties[ player.force.name ].icon }

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add{ type = 'label', caption = seconds_to_clock( global.table_of_properties.countdown_in_seconds ) }

        element_label.style.left_padding = 20

        element_label.style.right_padding = 20

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add{ type = 'label', caption = global.table_of_properties[ global.table_of_properties[ player.force.name ].enemy ].icon }

        element_label.style.font_color = table_of_colors.white

        local element_label = element_frame.add{ type = 'label', caption = math.floor( global.table_of_properties[ global.table_of_properties[ player.force.name ].enemy ].available_tickets ) }

        element_label.style.left_padding = 20

        element_label.style.font_color = table_of_colors.white

        local element_progressbar = element_frame.add{ type = 'progressbar', value = 100 }

        element_progressbar.style.width = 150

        element_progressbar.style.left_padding = 20

        element_progressbar.style.top_padding = 10

        element_progressbar.style.color = table_of_colors.enemy

        for _, element_item in pairs( element_frame.children ) do element_item.style.font = 'heading-1' end

    end

    function draw_gui_flags( player )

        if player.gui.top[ 'draw_gui_flags' ] then player.gui.top[ 'draw_gui_flags' ].destroy() end

        if player.surface.name == 'nauvis' then return end

        if #global.table_of_flags == 0 then return end

        local element_frame = player.gui.top.add{ type = 'frame', name = 'draw_gui_flags', direction = 'horizontal' }

        element_frame.style.minimal_width = 38

        element_frame.style.height = 38

        element_frame.style.margin = 0

        element_frame.style.padding = 0

        element_frame.style.vertical_align = 'top'

        element_frame.style.horizontal_align = 'center'

        for _, flag in pairs( global.table_of_flags ) do

            local element_label = element_frame.add{ type = 'label', caption = flag.properties.name }

            element_label.style.width = 38

            element_label.style.height = 38

            element_label.style.margin = 0

            element_label.style.padding = 0

            element_label.style.vertical_align = 'top'

            element_label.style.horizontal_align = 'center'

            element_label.style.font = 'heading-1'

            local color = table_of_colors.white

            if player.force.name ~= 'force_spectator' then

                color = table_of_colors.neutral

                if flag.properties.force.name == global.table_of_properties[ player.force.name ].name and flag.properties.value == 100 then color = table_of_colors.team end

                if flag.properties.force.name == global.table_of_properties[ player.force.name ].enemy and flag.properties.value == 100 then color = table_of_colors.enemy end

            end

            element_label.style.font_color = color

        end

    end

    function draw_gui_menu( player )

        if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

        local element_frame = player.gui.center.add{ type = 'frame', name = 'draw_gui_menu', direction = 'vertical' }

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        local element_table = element_frame.add{ type = 'table', column_count = 6 }

        element_table.style.padding = 0

        element_table.style.margin = 0

        if player.force.name == 'force_spectator' then element_table.add{ type = 'sprite-button', name = 'event_on_click_join', caption = 'JOIN' } end

        if player.force.name ~= 'force_spectator' then element_table.add{ type = 'sprite-button', name = 'event_on_click_lobby', caption = 'LOBBY' } end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.minimal_width = 170

            element_item.style.minimal_height = 170

            element_item.style.font = 'heading-1'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function draw_gui_score( player )

        if player.force.name == 'force_spectator' then return end

        if player.gui.center[ 'draw_gui_score' ] then player.gui.center[ 'draw_gui_score' ].destroy() end

        local element_frame = player.gui.center.add{ type = 'frame', name = 'draw_gui_score', direction = 'vertical' }

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.vertical_align = 'center'

        element_frame.style.horizontal_align = 'center'

        local element_table = element_frame.add{ type = 'table', column_count = 14, draw_horizontal_lines = true }

        element_table.style.padding = 0

        element_table.style.top_padding = 5

        element_table.style.left_padding = 10

        element_table.style.bottom_padding = 5

        element_table.style.margin = 0

        element_table.style.vertical_align = 'center'

        element_table.style.horizontal_align = 'center'

        local element_label = element_table.add{ type = 'label', caption = global.table_of_properties[ player.force.name ].icon }

        local element_label = element_table.add{ type = 'label', caption = '#' }

        local element_label = element_table.add{ type = 'label', caption = 'NAME' }

        local element_label = element_table.add{ type = 'label', caption = 'CLASS' }

        local element_label = element_table.add{ type = 'label', caption = 'K' }

        local element_label = element_table.add{ type = 'label', caption = 'D' }

        local element_label = element_table.add{ type = 'label', caption = 'POINTS' }

        local element_label = element_table.add{ type = 'label', caption = global.table_of_properties[ global.table_of_properties[ player.force.name ].enemy ].icon }

        local element_label = element_table.add{ type = 'label', caption = '#' }

        local element_label = element_table.add{ type = 'label', caption = 'NAME' }

        local element_label = element_table.add{ type = 'label', caption = 'CLASS' }

        local element_label = element_table.add{ type = 'label', caption = 'K' }

        local element_label = element_table.add{ type = 'label', caption = 'D' }

        local element_label = element_table.add{ type = 'label', caption = 'POINTS' }

        for index = 1, 28 do local element_label = element_table.add{ type = 'label', caption = '•' } end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.padding = 0

            element_item.style.right_padding = 10

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.font = 'heading-2'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function draw_gui_squad( player )

        if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() end

        local element_frame = player.gui.left.add{ type = 'frame', name = 'draw_gui_squad', direction = 'vertical' }

        element_frame.style.minimal_width = 50

        element_frame.style.padding = 0

        element_frame.style.margin = 0

        element_frame.style.top_margin = 5

        element_frame.style.left_margin = 5

        local element_table = element_frame.add{ type = 'table', column_count = 4 }

        element_table.style.padding = 0

        element_table.style.margin = 0

        for index = 1, 8 do

            local element_label = element_table.add{ type = 'label', caption = 'SQUAD ' .. index }

            local element_label = element_table.add{ type = 'label' }

            local element_label = element_table.add{ type = 'label' }

            local element_button = element_table.add{ type = 'sprite-button', name = 'aaa_' .. index, caption = 'JOIN' }

            element_button.style.width = 50

            element_button.style.height = 25

            local element_label = element_table.add{ type = 'label', caption = '•' }

            local element_label = element_table.add{ type = 'label', caption = '•' }

            local element_label = element_table.add{ type = 'label', caption = '•' }

            local element_label = element_table.add{ type = 'label', caption = '•' }

        end

        for _, element_item in pairs( element_table.children ) do

            element_item.style.minimal_width = 50

            element_item.style.padding = 0

            element_item.style.margin = 0

            element_item.style.vertical_align = 'center'

            element_item.style.horizontal_align  = 'center'

            element_item.style.font  = 'heading-2'

            element_item.style.font_color = table_of_colors.white

        end

    end

    function create_a_tank( player )

        player.insert( { name = 'light-armor', count = 1 } )

        player.insert( { name = 'submachine-gun', count = 1 } )

        player.insert( { name = 'firearm-magazine', count = 50 } )

        player.insert( { name = 'raw-fish', count = 3 } )

        local table_of_tanks = player.surface.find_entities_filtered( { name = 'tank', force = player.force.name } )

        if #table_of_tanks < #player.force.connected_players then

            local position = player.surface.find_non_colliding_position( 'tank', player.position, 64, 8 )

            if not position then position = { 0, 0 } end

            local property = player.surface.create_entity( { name = 'tank', position = player.position, force = player.force.name } )

            if not property then return end

            property.minable = false

            property.insert( { name = 'wood', count = 50 } )

            property.insert( { name = 'cannon-shell', count = 50 } )

            property.set_driver( player )

        end

    end

    function create_a_base( force_name, base_position )

        local surface = game.surfaces[ 'tank_conquest' ]

        local table_of_items = game.json_to_table( blueprint_poi_base_json )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + base_position.x, y = tile.position.y + base_position.y + 10 } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, entity in pairs( table_of_items.blueprint.entities ) do

            entity.force = game.forces[ force_name ]

            entity.position = { x = entity.position.x + base_position.x, y = entity.position.y + base_position.y + 10 }

            local property = surface.create_entity( entity )

            if not property then return end

            if entity.name == 'infinity-chest' or entity.name == 'substation' or entity.name == 'big-electric-pole' or entity.name == 'medium-electric-pole' or entity.name == 'inserter' or entity.name == 'accumulator' or entity.name == 'solar-panel' or entity.name == 'gun-turret' then

                property.destructible = false

                property.minable = false

                property.rotatable = false

                property.operable = false

            end

            if entity.name == 'wooden-chest' then

                property.destructible = false

                property.minable = false

                property.rotatable = false

            end

            if entity.name == 'stone-wall' or entity.name == 'gate' or entity.name == 'land-mine' then property.minable = false end

        end

    end

    function create_a_flag( flag_name, flag_position, flag_blueprint )

        local surface = game.surfaces[ 'tank_conquest' ]

        local flag = { name = flag_name, position = flag_position, force = { name = 'neutral' }, value = 0, color = table_of_colors.white }

        local table_of_positions = {}

        for x = 1, 18 do for y = 1, 18 do table.insert( table_of_positions, { x = math.floor( flag.position.x + x - 9 ), y = math.floor( flag.position.y + y - 9 ) } ) end end

        local table_of_players = {}

        local draw_flag_border = rendering.draw_rectangle{ surface = surface, target = flag.position, color = flag.color, left_top = { flag.position.x - 9, flag.position.y - 9 }, right_bottom = { flag.position.x + 9, flag.position.y + 9 }, width = 5, filled = false, draw_on_ground = true }

        local draw_flag_force = rendering.draw_text{ text = flag.force.name, surface = surface, target = { flag.position.x, flag.position.y + 0.5 }, color = flag.color, scale = 5, alignment = 'center' }

        local draw_flag_value = rendering.draw_text{ text = flag.value, surface = surface, target = { flag.position.x, flag.position.y - 4 }, color = flag.color, scale = 5, alignment = 'center' }

        local draw_flag_name = rendering.draw_text{ text = flag.name, surface = surface, target = { flag.position.x, flag.position.y - 2 }, color = flag.color, scale = 5, alignment = 'center' }

        local table_of_drawings = { name = draw_flag_name, value = draw_flag_value, force = draw_flag_force, border = draw_flag_border }

        local table_of_properties = { name = flag.name, value = flag.value, force = flag.force, color = flag.color }

        table.insert( global.table_of_flags, { properties = table_of_properties, drawings = table_of_drawings, players = table_of_players, positions = table_of_positions } )

        local table_of_items = game.json_to_table( flag_blueprint )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + flag.position.x - 1, y = tile.position.y + flag.position.y - 1 } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, entity in pairs( table_of_items.blueprint.entities ) do

            entity.force = 'enemy'

            entity.position = { x = entity.position.x + flag.position.x - 1, y = entity.position.y + flag.position.y - 1 }

            local property = surface.create_entity( entity )

            if not property then return end

            if entity.name == 'infinity-chest' or entity.name == 'substation' or entity.name == 'inserter' or entity.name == 'accumulator' or entity.name == 'solar-panel' then

                property.destructible = false

                property.minable = false

                property.rotatable = false

                property.operable = false

            end

            if entity.name == 'wooden-chest' then

                property.force = 'neutral'

                property.destructible = false

                property.minable = false

                property.rotatable = false

            end

            if entity.name == 'stone-wall' or entity.name == 'gate' or entity.name == 'land-mine' then property.minable = false end

        end

    end

    function create_a_point_of_interest( poi_blueprint, poi_position )

        local surface = game.surfaces[ 'tank_conquest' ]

        local table_of_items = game.json_to_table( poi_blueprint )

        for _, tile in pairs( table_of_items.blueprint.tiles ) do tile.position = { x = tile.position.x + poi_position.x, y = tile.position.y + poi_position.y } end

        surface.set_tiles( table_of_items.blueprint.tiles, true )

        for _, entity in pairs( table_of_items.blueprint.entities ) do

            entity.force = 'enemy'

            entity.position = { x = entity.position.x + poi_position.x, y = entity.position.y + poi_position.y }

            local property = surface.create_entity( entity )

            if not property then return end

            if entity.name == 'infinity-chest' or entity.name == 'substation' or entity.name == 'inserter' or entity.name == 'accumulator' or entity.name == 'solar-panel' then

                property.destructible = false

                property.minable = false

                property.rotatable = false

                property.operable = false

            end

            if entity.name == 'wooden-chest' then

                property.force = 'neutral'

                property.destructible = false

                property.minable = false

                property.rotatable = false

            end

            if entity.name == 'stone-wall' or entity.name == 'gate' or entity.name == 'land-mine' then property.minable = false end

        end

    end

    function seconds_to_clock( seconds )

        local seconds = tonumber( seconds )

        if seconds <= 0 then

            return '00:00:00'

        else

            local hours = string.format( '%02.f', math.floor( seconds / 3600 ) )

            local minutes = string.format( '%02.f', math.floor( seconds / 60 - ( hours * 60 ) ) )

            seconds = string.format( '%02.f', math.floor( seconds - hours * 3600 - minutes * 60 ) )

            return hours .. ':' .. minutes .. ':' .. seconds

        end

    end

    function draw_a_polygon( position, radius, angle, sides )

        if not type( position ) == 'table' then return end

        if not type( radius ) == 'number' then return end

        if not type( angle ) == 'number' then return end

        if not type( sides ) == 'number' then return end

        local table_of_positions = {}

        table.insert( table_of_positions, { x = position.x, y = position.y } )

        for index = 1, sides + 1 do

            local x = table_of_positions[ 1 ].x + ( radius * math.cos( angle + ( index + index - 1 ) * math.pi / sides ) )

            local y = table_of_positions[ 1 ].y + ( radius * math.sin( angle + ( index + index - 1 ) * math.pi / sides ) )

            table.insert( table_of_positions, { x = x, y = y } )

        end

        return table_of_positions

    end

    function replace_tiles_of_water()

        local surface = game.surfaces[ 'tank_conquest' ]

        local first_tile = surface.get_tile( { 0, 0 } )

        local table_of_tiles = surface.find_tiles_filtered( { name = { 'water', 'deepwater' } } )

        local table_of_substitutions = {}

        for _, tile in pairs( table_of_tiles ) do table.insert( table_of_substitutions, { name = first_tile.name, position = tile.position } ) end

        surface.set_tiles( table_of_substitutions, true )

    end

    function generate_circle_spawn( surface, spawn_diameter, spawn_position )

        for x = - spawn_diameter, spawn_diameter do for y = - spawn_diameter, spawn_diameter do

            local tile_position = { x = spawn_position.x + x, y = spawn_position.y + y }

            local distance_to_center = math.sqrt( tile_position.x ^ 2 + tile_position.y ^ 2 )

            local tile_name = false

            if distance_to_center < spawn_diameter then

                tile_name = 'deepwater'

                if math.random( 1, 48 ) == 1 then surface.create_entity( { name = 'fish', position = tile_position } ) end

            end

            if distance_to_center < 9.5 then tile_name = 'refined-concrete' end

            if distance_to_center < 7 then tile_name = 'sand-1' end

            if tile_name then surface.set_tiles( { { name = tile_name, position = tile_position } }, true ) end

        end end

    end

    local function event_on_click_join( player )

        local surface = game.surfaces[ 'tank_conquest' ]

        if not surface then return end

        if not player.character then return end

        if #game.forces.force_player_one.connected_players == #game.forces.force_player_two.connected_players then

            local table_of_forces = { 'force_player_one', 'force_player_two' }

            player.force = game.forces[ table_of_forces[ math.random( 1, #table_of_forces ) ] ]

        elseif #game.forces.force_player_one.connected_players < #game.forces.force_player_two.connected_players then

            player.force = game.forces.force_player_one

        else

            player.force = game.forces.force_player_two

        end

        local position = player.force.get_spawn_position( surface )

        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

        player.character.destructible = true

        game.permissions.get_group( 'Default' ).add_player( player.name )

    end

    function event_on_click_lobby( player )

        local surface = game.surfaces[ 'nauvis' ]

        if not player.character then return end

        player.force = game.forces.force_spectator

        local position = player.force.get_spawn_position( surface )

        if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

        player.character.destructible = false

        game.permissions.get_group( 'permission_spectator' ).add_player( player.name )

    end

    local function on_init( surface )

        game.surfaces[ 'nauvis' ].clear()

        game.surfaces[ 'nauvis' ].map_gen_settings = { width = 1, height = 1 }

        initialize_forces()

        -- global.table_of_properties.game_stage = 'do_nothing'

    end

    event.on_init( on_init )

    local function on_tick( event )

        if game.tick % 30 == 0 and global.table_of_damages ~= nil then

            for _, item in pairs( global.table_of_damages ) do item.surface.create_entity( { name = 'flying-text', position = item.position, text = math.ceil( item.damage ), color = table_of_colors.damage } ) end

            global.table_of_damages = nil

        end

        if game.tick % 60 == 0 then

            if global.table_of_properties.game_stage == 'ongoing_game' then

                for _, flag in pairs( global.table_of_flags ) do

                    if flag.properties.value == 100 then

                        local enemy = global.table_of_properties[ flag.properties.force.name ].enemy

                        if global.table_of_properties[ enemy ].available_tickets >= 0 then global.table_of_properties[ enemy ].available_tickets = global.table_of_properties[ enemy ].available_tickets - global.table_of_properties.acceleration_value end

                    end

                    for _, player in pairs( flag.players ) do

                        if flag.properties.force.name == 'neutral' and flag.properties.value == 0 then flag.properties.force.name = player.force.name end

                        if flag.properties.force.name == 'neutral' or flag.properties.force.name == player.force.name and flag.properties.value < 100 then flag.properties.value = flag.properties.value + 1 * global.table_of_properties.conquest_speed end

                        if flag.properties.force.name ~= player.force.name and flag.properties.value > 0 then flag.properties.value = flag.properties.value - 1 * global.table_of_properties.conquest_speed end

                        if flag.properties.value == 0 then flag.properties.force.name = 'neutral' end

                        local force_label = flag.properties.force.name

                        if force_label ~= 'neutral' then force_label = global.table_of_properties[ force_label ].icon end

                        rendering.set_text( flag.drawings.force, force_label )

                        rendering.set_text( flag.drawings.value, flag.properties.value )

                    end

                end

                if global.table_of_properties.countdown_in_seconds >= 0 then global.table_of_properties.countdown_in_seconds = global.table_of_properties.countdown_in_seconds - 1 end

                if global.table_of_properties.countdown_in_seconds < 0 or global.table_of_properties[ 'force_player_one' ].available_tickets < 0 or global.table_of_properties[ 'force_player_two' ].available_tickets < 0 then

                    game.print( 'The battle is over.' )

                    global.table_of_flags = {}

                    global.table_of_properties[ 'force_player_one' ].available_tickets = global.table_of_properties.amount_of_tickets

                    global.table_of_properties[ 'force_player_two' ].available_tickets = global.table_of_properties.amount_of_tickets

                    global.table_of_properties.countdown_in_seconds = 2701

                    global.table_of_properties.wait_in_seconds = 60

                    global.table_of_properties.game_stage = 'lobby'

                    game.print( 'You are now in the lobby, please make yourself comfortable, it continues immediately.' )

                    for _, player in pairs( game.connected_players ) do

                        -- if player.gui.top[ 'draw_gui_button' ] then player.gui.top[ 'draw_gui_button' ].destroy() end

                        if player.gui.top[ 'draw_gui_status' ] then player.gui.top[ 'draw_gui_status' ].destroy() end

                        if player.gui.top[ 'draw_gui_flags' ] then player.gui.top[ 'draw_gui_flags' ].destroy() end

                        -- if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() end

                        -- if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

                        -- draw_gui_score( player )

                        event_on_click_lobby( player )

                    end

                end

                for _, player in pairs( game.connected_players ) do

                    draw_gui_status( player )

                    draw_gui_flags( player )

                end

            end

            if global.table_of_properties.game_stage == 'regenerate_facilities' then

                replace_tiles_of_water()

                create_a_base( 'force_player_one', game.forces[ 'force_player_one' ].get_spawn_position( game.surfaces[ 'tank_conquest' ] ) )

                create_a_base( 'force_player_two', game.forces[ 'force_player_two' ].get_spawn_position( game.surfaces[ 'tank_conquest' ] ) )

                -- create_a_point_of_interest( blueprint_poi_laser_json, { x = 0, y = -150 } )

                create_a_point_of_interest( blueprint_poi_fire_json, { x = 0, y = -150 } )

                create_a_point_of_interest( blueprint_poi_fire_json, { x = 0, y = 250 } )

                local table_of_blueprints = { blueprint_poi_flag_one_json, blueprint_poi_flag_two_json, blueprint_poi_flag_three_json }

                local table_of_names = { 'A', 'B', 'C', 'D', 'E', 'F', 'G' }

                local length_of_names = math.random( 3, #table_of_names )

                local position, radius, angle, sides = { x = 0, y = 50 }, math.random( 50, 100 ), math.random( 45, 180 ), length_of_names

                local table_of_positions = draw_a_polygon( position, radius, angle, sides )

                for index = 1, length_of_names do create_a_flag( table_of_names[ index ], table_of_positions[ index ], table_of_blueprints[ math.random( 1, #table_of_blueprints ) ] ) end

                for _, player in pairs( game.connected_players ) do

                    -- if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() end

                    -- if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

                    -- if player.gui.center[ 'draw_gui_score' ] then player.gui.center[ 'draw_gui_score' ].destroy() end

                    -- draw_gui_button( player )

                    event_on_click_join( player )

                    game.print( player.name .. ' joined ' .. global.table_of_properties[ player.force.name ].icon )

                    create_a_tank( player )

                end

                global.table_of_properties.game_stage = 'ongoing_game'

            end

            if global.table_of_properties.game_stage == 'preparing_spawn_positions' then

                local position_one = { x = -200, y = 50 }

                local position_two = { x = 200, y = 50 }

                game.forces[ 'force_player_one' ].set_spawn_position( position_one, game.surfaces[ 'tank_conquest' ] )

                game.forces[ 'force_player_two' ].set_spawn_position( position_two, game.surfaces[ 'tank_conquest' ] )

                global.table_of_scores = {}

                for _, player in pairs( game.connected_players ) do

                    if player.character then

                        player.character.destroy()

                        player.character = nil

                    end

                    player.create_character()

                    rendering.draw_text{ text = global.table_of_properties[ player.force.name ].icon, target = player.character, target_offset = { 0, - 2.5 }, surface = player.surface, color = table_of_colors.white, scale = 1.5, alignment = 'center' }

                end

                global.table_of_properties.game_stage = 'regenerate_facilities'

            end

            if global.table_of_properties.game_stage == 'regenerate_battlefield' and global.table_of_properties.wait_in_seconds == 0 then

                initialize_surface()

                event_on_click_join( game.connected_players[ 1 ] )

                game.print( 'A new battlefield was created.' )

                global.table_of_properties.game_stage = 'preparing_spawn_positions'

            end

            if global.table_of_properties.game_stage == 'lobby' then

                if #game.connected_players >= global.table_of_properties.required_number_of_players and global.table_of_properties.wait_in_seconds > 0 then

                    if global.table_of_properties.wait_in_seconds % 5 == 0 then game.print( 'The round starts in ' .. global.table_of_properties.wait_in_seconds .. ' seconds.' ) end

                    global.table_of_properties.wait_in_seconds = global.table_of_properties.wait_in_seconds - 1

                end

                if global.table_of_properties.wait_in_seconds == 0 then global.table_of_properties.game_stage = 'regenerate_battlefield' end

            end

        end

        if game.tick == 60 then

            generate_circle_spawn( game.surfaces[ 'nauvis' ], 28, { x = 0, y = 0 } )

            for _, player in pairs( game.connected_players ) do if player.character == nil then player.create_character() end end

        end

    end

    event.add( defines.events.on_tick, on_tick )

    local function on_entity_damaged( event )

        if global.table_of_properties.game_stage == 'lobby' then return end

        if not event.entity.unit_number then return end

        if event.final_damage_amount < 1 then return end

        if global.table_of_damages == nil then global.table_of_damages = {} end

        if global.table_of_damages[ event.entity.unit_number ] == nil then global.table_of_damages[ event.entity.unit_number ] = { surface = event.entity.surface, position = event.entity.position, damage = 0 } end

        global.table_of_damages[ event.entity.unit_number ].damage = global.table_of_damages[ event.entity.unit_number ].damage + event.final_damage_amount

    end

    event.add( defines.events.on_entity_damaged, on_entity_damaged )

    local function on_player_respawned( event )

        local player = game.players[ event.player_index ]

        if player.surface.name == 'nauvis' then return end

        create_a_tank( player )

    end

    event.add( defines.events.on_player_respawned, on_player_respawned )

    local function on_player_died( event )

        local player = game.players[ event.player_index ]

        local message = ''

        if event.cause then

            if event.cause.name ~= nil then message = 'by ' .. event.cause.name end

            if event.cause.name == 'character' then message = 'by ' .. event.cause.player.name end

            if event.cause.name == 'tank' then

                local driver = event.cause.get_driver()

                if driver.player then message = 'by ' .. driver.player.name end

            end

        end

        for _, target_player in pairs( game.connected_players ) do

            if target_player.name ~= player.name then player.print( player.name .. ' was killed ' .. message, { r = 0.99, g = 0.0, b = 0.0 } ) end

        end

        local table_of_entities = player.surface.find_entities_filtered( { name = 'character-corpse' } )

        for _, entity in pairs( table_of_entities ) do

            entity.clear_items_inside()

            entity.destroy()

        end

        local force = global.table_of_properties[ player.force.name ]

        if force ~= nil and force.available_tickets > 0 then force.available_tickets = force.available_tickets - 1 end

        for _, flag in pairs( global.table_of_flags ) do if flag.players[ event.player_index ] ~= nil then flag.players[ event.player_index ] = nil end end

    end

    event.add( defines.events.on_player_died, on_player_died )

    local function on_player_changed_position( event )

        if global.table_of_properties.game_stage == 'lobby' then return end

        local player = game.players[ event.player_index ]

        for flag_index, flag_item in pairs( global.table_of_flags ) do

            if global.table_of_flags[ flag_index ].players[ event.player_index ] ~= nil then global.table_of_flags[ flag_index ].players[ event.player_index ] = nil end

            for _, position in pairs( flag_item.positions ) do

                if math.floor( player.position.x ) == position.x and math.floor( player.position.y ) == position.y or math.ceil( player.position.x ) == position.x and math.ceil( player.position.y ) == position.y then

                    if global.table_of_flags[ flag_index ].players[ event.player_index ] == nil then

                        global.table_of_flags[ flag_index ].players[ event.player_index ] = player

                        break

                    end

                end

            end

            if global.table_of_flags[ flag_index ].players[ event.player_index ] ~= nil then break end

        end

    end

    event.add( defines.events.on_player_changed_position, on_player_changed_position )

    local function on_gui_click( event )

        if not event.element then return end

        local player = game.players[ event.player_index ]

        if event.element.name == 'event_on_click_menu' then

            if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() else draw_gui_menu( player ) end

        end

        if event.element.name == 'event_on_click_score' then

            if player.gui.center[ 'draw_gui_score' ] then player.gui.center[ 'draw_gui_score' ].destroy() else draw_gui_score( player ) end

        end

        if event.element.name == 'event_on_click_squad' then

            if player.gui.left[ 'draw_gui_squad' ] then player.gui.left[ 'draw_gui_squad' ].destroy() else draw_gui_squad( player ) end

        end

        if event.element.name == 'event_on_click_join' then

            event_on_click_join( player )

            if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

        end

        if event.element.name == 'event_on_click_lobby' then

            event_on_click_lobby( player )

            if player.gui.center[ 'draw_gui_menu' ] then player.gui.center[ 'draw_gui_menu' ].destroy() end

        end

    end

    event.add( defines.events.on_gui_click, on_gui_click )

    local function on_player_joined_game( event )

        local surface = game.surfaces[ 'nauvis' ]

        local player = game.players[ event.player_index ]

        player.force = game.forces.force_spectator

        if player.online_time == 0 then

            local position = player.force.get_spawn_position( surface )

            if surface.is_chunk_generated( position ) then player.teleport( surface.find_non_colliding_position( 'character', position, 3, 0.5 ), surface ) else player.teleport( position, surface ) end

            player.character.destructible = false

            game.permissions.get_group( 'permission_spectator' ).add_player( player.name )

        end

        if global.table_of_properties.game_stage == 'ongoing_game' then

            event_on_click_join( player )

            game.print( player.name .. ' joined ' .. global.table_of_properties[ player.force.name ].icon )

            create_a_tank( player )

        end

    end

    event.add( defines.events.on_player_joined_game, on_player_joined_game )
