local shuffle = table.shuffle_table

local Public = require 'maps.mountain_fortress_v3.table'

function Public.get_random_buff(fetch_all, only_force)
    local buffs =
    {
        {
            name = 'character_running_speed_modifier',
            discord = 'Running speed modifier - run faster!',
            tooltip = { 'mtn_v3_buffs.character_running_speed_modifier_tooltip' },
            poll_name = 'Running speed',
            modifier = 'force',
            per_force = true,
            limit = 25,
            state = 0.05
        },
        {
            name = 'manual_mining_speed_modifier',
            discord = 'Mining speed modifier - mine faster!',
            tooltip = { 'mtn_v3_buffs.manual_mining_speed_modifier_tooltip' },
            poll_name = 'Mining speed',
            modifier = 'force',
            per_force = true,
            limit = 25,
            state = 0.15
        },
        {
            name = 'laboratory_speed_modifier',
            discord = 'Laboratory speed modifier - labs work faster!',
            tooltip = { 'mtn_v3_buffs.laboratory_speed_modifier_tooltip' },
            poll_name = 'Laboratory speed',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.15
        },
        {
            name = 'laboratory_productivity_bonus',
            discord = 'Laboratory productivity bonus - labs dupe things!',
            tooltip = { 'mtn_v3_buffs.laboratory_productivity_bonus_tooltip' },
            poll_name = 'Laboratory productivity',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.15
        },
        {
            name = 'worker_robots_storage_bonus',
            discord = 'Robot storage bonus - robots carry more!',
            tooltip = { 'mtn_v3_buffs.worker_robots_storage_bonus_tooltip' },
            poll_name = 'Robot storage',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 1
        },
        {
            name = 'worker_robots_battery_modifier',
            discord = 'Robot battery bonus - robots work longer!',
            tooltip = { 'mtn_v3_buffs.worker_robots_battery_modifier_tooltip' },
            poll_name = 'Robot battery',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 1
        },
        {
            name = 'worker_robots_speed_modifier',
            discord = 'Robot speed modifier - robots move faster!',
            tooltip = { 'mtn_v3_buffs.worker_robots_speed_modifier_tooltip' },
            poll_name = 'Robot speed',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.5
        },
        {
            name = 'mining_drill_productivity_bonus',
            discord = 'Drill productivity bonus - drills work faster!',
            tooltip = { 'mtn_v3_buffs.mining_drill_productivity_bonus_tooltip' },
            poll_name = 'Drill productivity',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.5
        },
        {
            name = 'character_health_bonus',
            discord = 'Character health bonus - more health!',
            tooltip = { 'mtn_v3_buffs.character_health_bonus_tooltip' },
            poll_name = 'Character health',
            modifier = 'force',
            per_force = true,
            limit = 50,
            state = 250
        },
        {
            name = 'distance',
            discord = 'RPG reach distance bonus - reach further!',
            tooltip = { 'mtn_v3_buffs.distance_tooltip' },
            poll_name = 'RPG reach distance',
            modifier = 'rpg_distance',
            per_force = true,
            modifiers = { 'character_resource_reach_distance_bonus', 'character_item_pickup_distance_bonus', 'character_loot_pickup_distance_bonus', 'character_reach_distance_bonus' },
            limit = 20,
            state = 0.05
        },
        {
            name = 'manual_crafting_speed_modifier',
            discord = 'Crafting speed modifier - craft faster!',
            tooltip = { 'mtn_v3_buffs.manual_crafting_speed_modifier_tooltip' },
            poll_name = 'Crafting speed',
            modifier = 'force',
            per_force = true,
            limit = 25,
            state = 0.12
        },
        {
            name = 'xp_bonus',
            discord = 'RPG XP point bonus - more XP points from kills etc.',
            tooltip = { 'mtn_v3_buffs.xp_bonus_tooltip' },
            poll_name = 'RPG XP point',
            modifier = 'rpg',
            per_force = true,
            limit = 25,
            state = 0.12
        },
        {
            name = 'xp_level',
            discord = 'RPG XP level bonus - start with more XP levels',
            tooltip = { 'mtn_v3_buffs.xp_level_tooltip' },
            poll_name = 'RPG XP level',
            modifier = 'rpg',
            per_force = true,
            limit = 5,
            state = 20
        },
        {
            name = 'chemicals_s',
            discord = 'Starting items supplies - start with some sulfur',
            tooltip = { 'mtn_v3_buffs.chemicals_s_tooltip' },
            poll_name = 'Starting items (sulfur)',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 50,
            items =
            {
                { name = 'sulfur', count = 50 }
            }
        },
        {
            name = 'chemicals_p',
            discord = 'Starting items supplies - start with some plastic bar',
            tooltip = { 'mtn_v3_buffs.chemicals_p_tooltip' },
            poll_name = 'Starting items (plastic bar)',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 50,
            items =
            {
                { name = 'plastic-bar', count = 100 }
            }
        },
        {
            name = 'supplies',
            discord = 'Starting items supplies - start with some copper and iron plates',
            tooltip = { 'mtn_v3_buffs.supplies_tooltip' },
            poll_name = 'Starting items (copper and iron plates)',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 100,
            items =
            {
                { name = 'iron-plate', count = 100 },
                { name = 'copper-plate', count = 100 }
            }
        },
        {
            name = 'supplies_1',
            discord = 'Starting items supplies - start with more copper and iron plates',
            tooltip = { 'mtn_v3_buffs.supplies_1_tooltip' },
            poll_name = 'Starting items (more copper and iron plates)',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 200,
            items =
            {
                { name = 'iron-plate', count = 200 },
                { name = 'copper-plate', count = 200 }
            }
        },
        {
            name = 'supplies_2',
            discord = 'Starting items supplies - start with even more copper and iron plates',
            tooltip = { 'mtn_v3_buffs.supplies_2_tooltip' },
            poll_name = 'Starting items (even more copper and iron plates)',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 400,
            items =
            {
                { name = 'iron-plate', count = 400 },
                { name = 'copper-plate', count = 400 }
            }
        },
        {
            name = 'defense_3',
            discord = 'Defense starting supplies - start with rocket launcher and ammo',
            tooltip = { 'mtn_v3_buffs.defense_3_tooltip' },
            poll_name = 'Starting items (rocket launcher and ammo)',
            modifier = 'starting_items',
            quality_item = 'rocket-launcher',
            limit = 5,
            add_per_buff = 1,
            items =
            {
                { name = 'rocket-launcher', count = 1 },
                { name = 'rocket', count = 100 }
            }
        },
        {
            name = 'armor',
            discord = 'Armor starting supplies - start with some armor and solar panels',
            tooltip = { 'mtn_v3_buffs.armor_tooltip' },
            poll_name = 'Starting items (armor and solar panels)',
            modifier = 'starting_items',
            quality_item = 'modular-armor',
            limit = 5,
            add_per_buff = 1,
            items =
            {
                { name = 'modular-armor', count = 1 },
                { name = 'solar-panel-equipment', count = 2 }
            }
        },
        {
            name = 'production_1',
            discord = 'Production starting supplies - start with some steel furnaces and solid fuel',
            tooltip = { 'mtn_v3_buffs.production_1_tooltip' },
            poll_name = 'Starting items (steel furnaces and solid fuel)',
            modifier = 'starting_items',
            limit = 2,
            add_per_buff = 1,
            items =
            {
                { name = 'steel-furnace', count = 4 },
                { name = 'solid-fuel', count = 100 }
            }
        },
        {
            name = 'fast_startup_1',
            discord = 'Assembling starting supplies - start with some assembling machines T2',
            tooltip = { 'mtn_v3_buffs.fast_startup_1_tooltip' },
            poll_name = 'Starting items (assembling machines T2)',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items =
            {
                { name = 'assembling-machine-2', count = 2 }
            }
        },
        {
            name = 'fast_startup_2',
            discord = 'Assembling starting supplies - start with some assembling machines T3',
            tooltip = { 'mtn_v3_buffs.fast_startup_2_tooltip' },
            poll_name = 'Starting items (assembling machines T3)',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items =
            {
                { name = 'assembling-machine-3', count = 2 }
            }
        },
        {
            name = 'logistics_startup',
            discord = 'Logistics starting supplies - start with belts, inserters and small electric poles',
            tooltip = { 'mtn_v3_buffs.logistics_startup_tooltip' },
            poll_name = 'Starting items (logistics)',
            modifier = 'starting_items',
            limit = 2,
            add_per_buff = 1,
            items =
            {
                { name = 'transport-belt', count = 50 },
                { name = 'inserter', count = 10 },
                { name = 'small-electric-pole', count = 10 }
            }
        },
        {
            name = 'character_inventory_slots_bonus',
            discord = 'Inventory bonus - carry more building supplies!',
            tooltip = { 'mtn_v3_buffs.character_inventory_slots_bonus_tooltip' },
            poll_name = 'Inventory slots',
            modifier = 'force',
            per_force = true,
            limit = 3,
            state = 5
        },
        {
            name = 'character_build_distance_bonus',
            discord = 'Build distance bonus - place buildings further away!',
            tooltip = { 'mtn_v3_buffs.character_build_distance_bonus_tooltip' },
            poll_name = 'Build distance',
            modifier = 'force',
            per_force = true,
            limit = 3,
            state = 1
        },
        {
            name = 'heal-thy-buildings',
            discord = 'Repair starting supplies - start with some repair packs',
            tooltip = { 'mtn_v3_buffs.heal-thy-buildings_tooltip' },
            poll_name = 'Starting items (repair packs)',
            modifier = 'starting_items',
            limit = 20,
            add_per_buff = 2,
            items =
            {
                { name = 'repair-pack', count = 5 }
            }
        },
        {
            name = 'extra_wagons',
            discord = 'Extra wagon at start',
            tooltip = { 'mtn_v3_buffs.extra_wagons_tooltip' },
            poll_name = 'Starting items (extra wagon)',
            modifier = 'locomotive',
            limit = 3,
            state = 1
        },
        {
            name = 'american_oil',
            discord = 'Oil tech - start with some crude oil barrels',
            tooltip = { 'mtn_v3_buffs.american_oil_tooltip' },
            poll_name = 'Starting items (crude oil barrels)',
            modifier = 'starting_items',
            limit = 40,
            add_per_buff = 20,
            items =
            {
                { name = 'crude-oil-barrel', count = 20 }
            }
        },
        {
            name = 'steel_plates',
            discord = 'Steel tech - start with some steel plates',
            tooltip = { 'mtn_v3_buffs.steel_plates_tooltip' },
            poll_name = 'Starting items (steel plates)',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 100,
            items =
            {
                { name = 'steel-plate', count = 100 }
            }
        },
        {
            name = 'gun_turrets',
            discord = 'Gun turrets - start with some gun turrets',
            tooltip = { 'mtn_v3_buffs.gun_turrets_tooltip' },
            poll_name = 'Starting items (gun turrets)',
            modifier = 'starting_items',
            limit = 4,
            add_per_buff = 2,
            items =
            {
                { name = 'gun-turret', count = 2 },
                { name = 'piercing-rounds-magazine', count = 100 }
            }
        },
        {
            name = 'red_science',
            discord = 'Science tech - start with some red science packs',
            tooltip = { 'mtn_v3_buffs.red_science_tooltip' },
            poll_name = 'Starting items (red science packs)',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 10,
            items =
            {
                { name = 'automation-science-pack', count = 10 }
            }
        },
        {
            name = 'roboport_equipement',
            discord = 'Equipement tech - start with a personal roboport',
            tooltip = { 'mtn_v3_buffs.roboport_equipement_tooltip' },
            poll_name = 'Starting items (personal roboport)',
            modifier = 'starting_items',
            quality_item = 'personal-roboport-equipment',
            limit = 5,
            add_per_buff = 1,
            items =
            {
                { name = 'personal-roboport-equipment', count = 1 }
            }
        },
        {
            name = 'mk1_tech_unlocked',
            discord = 'Equipement tech - start with power armor tech unlocked.',
            tooltip = { 'mtn_v3_buffs.mk1_tech_unlocked_tooltip' },
            poll_name = 'Tech unlock (power armor)',
            modifier = 'tech',
            limit = 1,
            add_per_buff = 1,
            techs =
            {
                { name = 'power-armor', count = 1 }
            }
        },
        {
            name = 'steel_axe_unlocked',
            discord = 'Equipement tech - start with steel axe tech unlocked.',
            tooltip = { 'mtn_v3_buffs.steel_axe_unlocked_tooltip' },
            poll_name = 'Tech unlock (steel axe)',
            modifier = 'tech',
            limit = 1,
            add_per_buff = 1,
            techs =
            {
                { name = 'steel-axe', count = 1 }
            }
        },
        {
            name = 'military_2_unlocked',
            discord = 'Equipement tech - start with military 2 tech unlocked.',
            tooltip = { 'mtn_v3_buffs.military_2_unlocked_tooltip' },
            poll_name = 'Tech unlock (military 2)',
            modifier = 'tech',
            limit = 1,
            add_per_buff = 1,
            techs =
            {
                { name = 'military-2', count = 1 }
            }
        },
        {
            name = 'starting_car',
            discord = 'Vehicle starting supplies - start with a car',
            tooltip = { 'mtn_v3_buffs.starting_car_tooltip' },
            poll_name = 'Starting Car',
            modifier = 'starting_items',
            quality_item = 'car',
            requires_tech = 'military-2',
            limit = 5,
            add_per_buff = 1,
            items =
            {
                { name = 'car', count = 1 }
            }
        },
        {
            name = 'starting_tank',
            discord = 'Vehicle starting supplies - start with a tank',
            tooltip = { 'mtn_v3_buffs.starting_tank_tooltip' },
            poll_name = 'Starting Tank',
            modifier = 'starting_items',
            quality_item = 'tank',
            requires_item_quality = { name = 'car', quality = 'legendary' },
            limit = 5,
            add_per_buff = 1,
            items =
            {
                { name = 'tank', count = 1 }
            }
        },
        {
            name = 'all_the_fish',
            discord = 'Wagon is full of fish!',
            tooltip = { 'mtn_v3_buffs.all_the_fish_tooltip' },
            poll_name = 'Fishes',
            modifier = 'fish',
            limit = 1,
            add_per_buff = 1
        }
    }

    if Public.is_modded_pt2 then
        buffs[#buffs + 1] =
        {
            name = 'quality_buildings_uncommon',
            discord = 'Grants uncommon quality of buildings generating free loot!',
            tooltip = { 'mtn_v3_buffs.quality_buildings_uncommon_tooltip' },
            poll_name = 'Wild buildings (uncommon)',
            limit = 1,
            quality = 'uncommon',
            dlc = true,
            state = 1
        }
        buffs[#buffs + 1] =
        {
            name = 'quality_buildings_rare',
            discord = 'Grants rare quality of buildings generating free loot!',
            tooltip = { 'mtn_v3_buffs.quality_buildings_rare_tooltip' },
            poll_name = 'Wild buildings (rare)',
            limit = 1,
            quality = 'rare',
            dlc = true,
            state = 1
        }
        buffs[#buffs + 1] =
        {
            name = 'quality_buildings_epic',
            discord = 'Grants epic quality of buildings generating free loot!',
            tooltip = { 'mtn_v3_buffs.quality_buildings_epic_tooltip' },
            poll_name = 'Wild buildings (epic)',
            limit = 1,
            quality = 'epic',
            dlc = true,
            state = 1
        }
        buffs[#buffs + 1] =
        {
            name = 'quality_buildings_legendary',
            discord = 'Grants legendary quality of buildings generating free loot!',
            tooltip = { 'mtn_v3_buffs.quality_buildings_legendary_tooltip' },
            poll_name = 'Wild buildings (legendary)',
            limit = 1,
            quality = 'legendary',
            dlc = true,
            state = 1
        }
    end

    if only_force then
        local force_buffs = {}
        for _, buff in pairs(buffs) do
            if buff.per_force then
                force_buffs[#force_buffs + 1] = buff
            end
        end

        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)

        return force_buffs[1]
    end

    if fetch_all then
        return buffs
    end

    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)

    return buffs[1]
end

return Public
