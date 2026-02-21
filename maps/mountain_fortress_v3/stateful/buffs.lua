local shuffle = table.shuffle_table

local Public = require 'maps.mountain_fortress_v3.table'

function Public.get_random_buff(fetch_all, only_force)
    local buffs =
    {
        {
            name = 'character_running_speed_modifier',
            discord = 'Running speed modifier - run faster!',
            tooltip = 'Selecting this buff will grant the team 5% increased running speed!',
            poll_name = 'Running speed',
            modifier = 'force',
            per_force = true,
            limit = 25,
            state = 0.05
        },
        {
            name = 'manual_mining_speed_modifier',
            discord = 'Mining speed modifier - mine faster!',
            tooltip = 'Selecting this buff will grant the team 15% increased mining speed!',
            poll_name = 'Mining speed',
            modifier = 'force',
            per_force = true,
            limit = 25,
            state = 0.15
        },
        {
            name = 'laboratory_speed_modifier',
            discord = 'Laboratory speed modifier - labs work faster!',
            tooltip = 'Selecting this buff will grant the team 15% increased laboratory speed!',
            poll_name = 'Laboratory speed',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.15
        },
        {
            name = 'laboratory_productivity_bonus',
            discord = 'Laboratory productivity bonus - labs dupe things!',
            tooltip = 'Selecting this buff will grant the team 15% increased laboratory productivity!',
            poll_name = 'Laboratory productivity',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.15
        },
        {
            name = 'worker_robots_storage_bonus',
            discord = 'Robot storage bonus - robots carry more!',
            tooltip = 'Selecting this buff will grant the team +1 increased robot storage!',
            poll_name = 'Robot storage',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 1
        },
        {
            name = 'worker_robots_battery_modifier',
            discord = 'Robot battery bonus - robots work longer!',
            tooltip = 'Selecting this buff will grant the team 100% increased robot battery!',
            poll_name = 'Robot battery',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 1
        },
        {
            name = 'worker_robots_speed_modifier',
            discord = 'Robot speed modifier - robots move faster!',
            tooltip = 'Selecting this buff will grant the team 50% increased robot speed!',
            poll_name = 'Robot speed',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.5
        },
        {
            name = 'mining_drill_productivity_bonus',
            discord = 'Drill productivity bonus - drills work faster!',
            tooltip = 'Selecting this buff will grant the team 50% increased drill productivity!',
            poll_name = 'Drill productivity',
            modifier = 'force',
            per_force = true,
            limit = 30,
            state = 0.5
        },
        {
            name = 'character_health_bonus',
            discord = 'Character health bonus - more health!',
            tooltip = 'Selecting this buff will grant the team 250 flat increased character health!',
            poll_name = 'Character health',
            modifier = 'force',
            per_force = true,
            limit = 50,
            state = 250
        },
        {
            name = 'distance',
            discord = 'RPG reach distance bonus - reach further!',
            tooltip = 'Selecting this buff will grant the team 5% increased reach distance!',
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
            tooltip = 'Selecting this buff will grant the team 12% increased crafting speed!',
            poll_name = 'Crafting speed',
            modifier = 'force',
            per_force = true,
            limit = 25,
            state = 0.12
        },
        {
            name = 'xp_bonus',
            discord = 'RPG XP point bonus - more XP points from kills etc.',
            tooltip = 'Selecting this buff will grant the team 12% increased XP points from kills etc.',
            poll_name = 'RPG XP point',
            modifier = 'rpg',
            per_force = true,
            limit = 25,
            state = 0.12
        },
        {
            name = 'xp_level',
            discord = 'RPG XP level bonus - start with more XP levels',
            tooltip = 'Selecting this buff will grant the team 20 more XP levels!',
            poll_name = 'RPG XP level',
            modifier = 'rpg',
            per_force = true,
            limit = 5,
            state = 20
        },
        {
            name = 'chemicals_s',
            discord = 'Starting items supplies - start with some sulfur',
            tooltip = 'Selecting this buff will grant the team 50 sulfur at start!',
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
            tooltip = 'Selecting this buff will grant the team 100 plastic bar at start!',
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
            tooltip = 'Selecting this buff will grant the team 100 copper and iron plates at start!',
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
            tooltip = 'Selecting this buff will grant the team 200 copper and iron plates at start!',
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
            tooltip = 'Selecting this buff will grant the team 400 copper and iron plates at start!',
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
            tooltip = 'Selecting this buff will grant the team 1 rocket launcher and 100 rockets at start!',
            poll_name = 'Starting items (rocket launcher and ammo)',
            modifier = 'starting_items',
            limit = 1,
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
            tooltip = 'Selecting this buff will grant the team 1 modular armor and 2 solar panel equipment at start!',
            poll_name = 'Starting items (armor and solar panels)',
            modifier = 'starting_items',
            limit = 1,
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
            tooltip = 'Selecting this buff will grant the team 4 steel furnaces and 100 solid fuel at start!',
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
            tooltip = 'Selecting this buff will grant the team 2 assembling machines T2 at start!',
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
            tooltip = 'Selecting this buff will grant the team 2 assembling machines T3 at start!',
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
            name = 'heal-thy-buildings',
            discord = 'Repair starting supplies - start with some repair packs',
            tooltip = 'Selecting this buff will grant the team 5 repair packs at start!',
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
            tooltip = 'Selecting this buff will grant the team 1 extra wagon at start!',
            poll_name = 'Starting items (extra wagon)',
            modifier = 'locomotive',
            limit = 3,
            state = 1
        },
        {
            name = 'american_oil',
            discord = 'Oil tech - start with some crude oil barrels',
            tooltip = 'Selecting this buff will grant the team 20 crude oil barrels at start!',
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
            tooltip = 'Selecting this buff will grant the team 100 steel plates at start!',
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
            tooltip = 'Selecting this buff will grant the team 2 gun turrets at start!',
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
            tooltip = 'Selecting this buff will grant the team 10 red science packs at start!',
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
            tooltip = 'Selecting this buff will grant the team 1 personal roboport equipment at start!',
            poll_name = 'Starting items (personal roboport)',
            modifier = 'starting_items',
            limit = 4,
            add_per_buff = 1,
            items =
            {
                { name = 'personal-roboport-equipment', count = 1 }
            }
        },
        {
            name = 'mk1_tech_unlocked',
            discord = 'Equipement tech - start with power armor tech unlocked.',
            tooltip = 'Selecting this buff will grant the team power armor tech unlocked at start!',
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
            tooltip = 'Selecting this buff will grant the team steel axe tech unlocked at start!',
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
            tooltip = 'Selecting this buff will grant the team military 2 tech unlocked at start!',
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
            name = 'all_the_fish',
            discord = 'Wagon is full of fish!',
            tooltip = 'Selecting this buff will grant the team 1 wagon full of fish at start!',
            poll_name = 'Fishes',
            modifier = 'fish',
            limit = 1,
            add_per_buff = 1
        }
    }

    if Public.is_modded_pt2 then
        --[[ buffs[#buffs + 1] =
        {
            name = 'quality_trains_uncommon',
            discord = 'Grants uncommon trains at start',
            tooltip = 'Selecting this buff make all trains of type uncommon quality!',
            poll_name = 'Uncommon trains',
            modifier = 'quality_trains',
            limit = 1,
            quality = 'uncommon',
            dlc = true,
            state = 1
        }
        buffs[#buffs + 1] =
        {
            name = 'quality_trains_rare',
            discord = 'Grants rare trains at start',
            tooltip = 'Selecting this buff make all trains of type rare quality!',
            poll_name = 'Rare trains',
            modifier = 'quality_trains',
            limit = 1,
            quality = 'rare',
            dlc = true,
            state = 1
        }

        buffs[#buffs + 1] =
        {
            name = 'quality_trains_epic',
            discord = 'Grants epic trains at start',
            tooltip = 'Selecting this buff make all trains of type epic quality!',
            poll_name = 'Epic trains',
            modifier = 'quality_trains',
            limit = 1,
            quality = 'epic',
            dlc = true,
            state = 1
        }
        buffs[#buffs + 1] =
        {
            name = 'quality_trains_legendary',
            discord = 'Grants legendary trains at start',
            tooltip = 'Selecting this buff make all trains of type legendary quality!',
            poll_name = 'Legendary trains',
            modifier = 'quality_trains',
            limit = 1,
            quality = 'legendary',
            dlc = true,
            state = 1
        } ]]
        buffs[#buffs + 1] =
        {
            name = 'quality_buildings_uncommon',
            discord = 'Grants uncommon quality of buildings generating free loot!',
            tooltip = 'Selecting this buff will grant the team 1 uncommon quality wild buildings that generate free loot!',
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
            tooltip = 'Selecting this buff will grant the team 1 rare quality wild buildings that generate free loot!',
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
            tooltip = 'Selecting this buff will grant the team 1 epic quality wild buildings that generate free loot!',
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
            tooltip = 'Selecting this buff will grant the team legendary quality wild buildings that generate free loot!',
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
