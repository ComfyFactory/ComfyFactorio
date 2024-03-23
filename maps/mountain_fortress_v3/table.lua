-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    players = {},
    traps = {},
    scheduler = {
        start_after = 0,
        surface = nil,
        operation = nil,
        next_operation = nil
    }
}
local stateful_settings = {
    reversed = true
}
local Public = {}
local random = math.random

Public.events = {
    reset_map = Event.generate_event_name('reset_map'),
    on_entity_mined = Event.generate_event_name('on_entity_mined'),
    on_market_item_purchased = Event.generate_event_name('on_market_item_purchased')
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

Global.register(
    stateful_settings,
    function(tbl)
        stateful_settings = tbl
    end
)

Public.zone_settings = {
    zone_depth = 704,
    zone_width = 510
}

Public.valid_enemy_forces = {
    ['enemy'] = true,
    ['aggressors'] = true,
    ['aggressors_frenzy'] = true
}

Public.pickaxe_upgrades = {
    'Wood',
    'Plastic',
    'Bone',
    'Alabaster',
    'Lead',
    'Zinc',
    'Tin',
    'Salt',
    'Bauxite',
    'Borax',
    'Bismuth',
    'Amber',
    'Galena',
    'Calcite',
    'Aluminium',
    'Silver',
    'Gold',
    'Copper',
    'Marble',
    'Brass',
    'Flourite',
    'Platinum',
    'Nickel',
    'Iron',
    'Manganese',
    'Apatite',
    'Uraninite',
    'Turquoise',
    'Hematite',
    'Glass',
    'Magnetite',
    'Concrete',
    'Pyrite',
    'Steel',
    'Zircon',
    'Titanium',
    'Silicon',
    'Quartz',
    'Garnet',
    'Flint',
    'Tourmaline',
    'Beryl',
    'Topaz',
    'Chrysoberyl',
    'Chromium',
    'Tungsten',
    'Corundum',
    'Tungsten',
    'Diamond',
    'Penumbrite',
    'Meteorite',
    'Crimtane',
    'Obsidian',
    'Demonite',
    'Mythril',
    'Adamantite',
    'Chlorophyte',
    'Densinium',
    'Luminite'
}

function Public.reset_main_table()
    -- @start
    -- these 3 are in case of stop/start/reloading the instance.
    this.soft_reset = true
    this.restart = false
    this.shutdown = false
    this.announced_message = false
    -- @end
    this.breach_wall_warning = false
    this.icw_locomotive = nil
    this.game_lost = false
    this.death_mode = false
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.extra_wagons = 0
    this.gap_between_zones = {
        set = false,
        gap = 900,
        neg_gap = -500,
        highest_pos = 0
    }
    this.gap_between_locomotive = {
        hinders = {},
        gap = 900,
        neg_gap = -3520, -- earlier 2112 (3 zones, whereas 704 is one zone)
        neg_gap_collapse = -5520, -- earlier 2112 (3 zones, whereas 704 is one zone)
        highest_pos = nil
    }
    this.force_chunk = false
    this.bw = false
    this.debug_vars = {
        enabled = true,
        vars = {
            mining_chance = {}
        }
    }
    this.allow_decon = true
    this.block_non_trusted_opening_trains = true
    this.allow_decon_main_surface = true
    this.flamethrower_damage = {}
    this.mined_scrap = 0
    this.print_tech_to_discord = true
    this.biters_killed = 0
    this.cleared_nauvis = false
    this.locomotive_pos = {tbl = {}}
    this.trusted_only_car_tanks = true
    --!grief prevention
    this.enable_arties = 6 -- default to callback 6
    --!snip
    this.enemy_spawners = {
        spawners = {},
        enabled = false
    }
    this.poison_deployed = false
    this.robotics_deployed = false
    this.upgrades = {
        showed_text = false,
        landmine = {
            limit = 25,
            bought = 0,
            built = 0
        },
        flame_turret = {
            limit = 6,
            bought = 0,
            built = 0
        },
        unit_number = {
            landmine = {},
            flame_turret = {}
        },
        has_upgraded_health_pool = false,
        has_upgraded_tile_when_mining = false,
        explosive_bullets_purchased = false,
        xp_points_upgrade = 0,
        aura_upgrades = 0,
        aura_upgrades_max = 12, -- = (aura_limit - locomotive_aura_radius) / 5
        locomotive_aura_radius = 40,
        train_upgrade_contribution = 0,
        xp_points = 0,
        health_upgrades = 0,
        pickaxe_tier = 1
    }
    this.orbital_strikes = {
        enabled = true
    }
    this.pickaxe_speed_per_purchase = 0.09
    this.breached_wall = 1
    this.final_battle = false
    this.disable_link_chest_cheese_mode = true
    this.left_top = {
        x = 0,
        y = 0
    }
    this.biters = {
        amount = 0,
        limit = 512
    }
    this.traps = {}
    this.munch_time = true
    this.magic_requirement = 50
    this.loot_stats = {
        rare = 48,
        normal = 48
    }
    this.coin_amount = 1
    this.difficulty_set = false
    this.bonus_xp_on_join = 250
    this.main_market_items = {}
    this.spill_items_to_surface = false
    this.spectate = {}
    this.placed_trains_in_zone = {
        limit = 1,
        randomized = false,
        zones = {}
    }
    this.market_limits = {
        chests_outside_limit = 8,
        aura_limit = 100, -- limited to save UPS
        pickaxe_tier_limit = 59,
        health_upgrades_limit = 100,
        xp_points_limit = 40
    }
    this.marked_fixed_prices = {
        chests_outside_cost = 3000,
        health_cost = 14000,
        pickaxe_cost = 3000,
        aura_cost = 4000,
        xp_point_boost_cost = 2500,
        explosive_bullets_cost = 10000,
        flamethrower_turrets_cost = 3000,
        land_mine_cost = 2,
        car_health_upgrade_pool_cost = 100000,
        tile_when_mining_cost = random(45000, 70000),
        redraw_mystical_chest_cost = 3000
    }
    this.collapse_grace = true
    this.corpse_removal_disabled = false
    this.locomotive_biter = nil
    this.disconnect_wagon = false
    this.collapse_amount = false
    this.collapse_speed = false
    this.y_value_position = 20
    this.spawn_near_collapse = {
        active = true,
        total_pos = 35,
        compare = -150,
        compare_next = 200,
        distance_from = 2
    }
    this.spidertron_unlocked_at_zone = 11
    this.spidertron_unlocked_enabled = false
    -- this.void_or_tile = 'lab-dark-2'
    this.void_or_tile = 'out-of-map'
    this.validate_spider = {}
    this.check_afk_players = true
    this.winter_mode = false
    this.sent_to_discord = false
    this.random_seed = random(100000000, 1000000000)
    this.difficulty = {
        multiply = 0.25,
        highest = 10,
        lowest = 4
    }
    this.mining_bonus_till_wave = 300
    this.mining_bonus = 0
    this.disable_mining_boost = false
    this.market_announce = game.tick + 1200
    this.check_heavy_damage = true
    this.prestige_system_enabled = false
    this.mystical_chest_completed = 0
    this.mystical_chest_enabled = true
    this.check_if_threat_below_zero = true
    this.mc_rewards = {
        current = {},
        temp_boosts = {}
    }
    this.adjusted_zones = {
        scrap = {},
        forest = {},
        size = nil,
        shuffled_zones = nil,
        starting_zone = true,
        reversed = stateful_settings.reversed,
        disable_terrain = false
    }
    this.alert_zone_1 = false -- alert the players
    this.radars_reveal_new_chunks = false -- allows for the player to explore the map instead,

    this.mining_utils = {
        rocks_yield_ore_maximum_amount = 500,
        type_modifier = 1,
        rocks_yield_ore_base_amount = 40,
        rocks_yield_ore_distance_modifier = 0.020
    }

    this.wagons_in_the_wild = {}

    for k, _ in pairs(this.players) do
        this.players[k] = {}
    end
end

function Public.enable_bw(state)
    this.bw = state or false
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.get_stateful_settings(key)
    if key then
        return stateful_settings[key]
    else
        return stateful_settings
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.set_stateful_settings(key, value)
    if key and (value or value == false) then
        stateful_settings[key] = value
        return stateful_settings[key]
    elseif key then
        return stateful_settings[key]
    else
        return stateful_settings
    end
end

function Public.remove(key, sub_key)
    if key and sub_key then
        if this[key] and this[key][sub_key] then
            this[key][sub_key] = nil
        end
    elseif key then
        if this[key] then
            this[key] = nil
        end
    end
end

Event.on_init(Public.reset_main_table)

return Public
