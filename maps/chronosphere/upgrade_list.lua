local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Public = {}

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_ceil = math.ceil

Public.tokens = {
    ['biters'] = {name = 'token_biters', sprite = 'virtual-signal/signal-B', tooltip = {'chronosphere.token_info_biters'}, enabled = false},
    ['ammo'] = {name = 'token_ammo', sprite = 'virtual-signal/signal-A', tooltip = {'chronosphere.token_info_ammo'}, enabled = true},
    ['tech'] = {name = 'token_tech', sprite = 'virtual-signal/signal-T', tooltip = {'chronosphere.token_info_tech'}, enabled = false},
    ['ecology'] = {name = 'token_ecology', sprite = 'virtual-signal/signal-E', tooltip = {'chronosphere.token_info_ecology'}, enabled = false},
    ['weapons'] = {name = 'token_weapons', sprite = 'virtual-signal/signal-W', tooltip = {'chronosphere.token_info_weapons'}, enabled = false}
}

function Public.add_ammo_tokens(player)
    local objective = Chrono_table.get_table()
    local inventory = player.get_inventory(defines.inventory.character_main)
    if not inventory or not inventory.valid then
        return
    end
    local count = inventory.remove({name = 'pistol', count = 5})
    objective.research_tokens.ammo = objective.research_tokens.ammo + count
    script.raise_event(objective.events['update_upgrades_gui'], {})
end

function Public.coin_scaling()
    local difficulty = Difficulty.get().difficulty_vote_value
    return Balance.upgrades_coin_cost_difficulty_scaling(difficulty)
end

function Public.upgrade_count()
    --override the number here after adding new upgrades! Otherwise it won't work
    --(during reset it needs static number, at that point the list of upgrades isn't built yet!)
    return 27
end

function Public.upgrade1(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_train_armor'},
        sprite = 'recipe/locomotive',
        max_level = 36,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_train_armor_message'},
        tooltip = {'chronosphere.upgrade_train_armor_tooltip', 36, objective.max_health},
        jump_limit = objective.upgrades[1],
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 500 * coin_scaling * (1 + 2 * objective.upgrades[1])
            },
            item2 = {name = 'copper-plate', tt = 'item-name', sprite = 'item/copper-plate', count = 1500}
        },
        virtual_cost = {
            virtual1 = {
                type = 'biters',
                name = Public.tokens.biters.name,
                tt = 'chronosphere',
                sprite = Public.tokens.biters.sprite,
                count = 100 * (1 + objective.upgrades[1] ^ 2) * coin_scaling
            }
        }
    }
    return upgrade
end

function Public.upgrade2(coin_scaling)
    local objective = Chrono_table.get_table()
    local difficulty = Difficulty.get().difficulty_vote_value
    local upgrade = {
        name = {'chronosphere.upgrade_filter'},
        sprite = 'recipe/effectivity-module',
        max_level = 9,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_filter_message'},
        tooltip = {
            'chronosphere.upgrade_filter_tooltip',
            math_floor(100 * Balance.machine_pollution_transfer_from_inside_factor(difficulty, objective.upgrades[2]))
        },
        jump_limit = (1 + objective.upgrades[2]) * 3 or 0,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 5000 * coin_scaling},
            item2 = {name = 'electronic-circuit', tt = 'item-name', sprite = 'item/electronic-circuit', count = math_min(1 + objective.upgrades[2], 3) * 500 + 500},
            item3 = {name = 'advanced-circuit', tt = 'item-name', sprite = 'item/advanced-circuit', count = math_max(math_min(1 + objective.upgrades[2], 6) - 3, 0) * 500},
            item4 = {name = 'processing-unit', tt = 'item-name', sprite = 'item/processing-unit', count = math_max(math_min(1 + objective.upgrades[2], 9) - 6, 0) * 500}
        },
        virtual_cost = {
            virtual1 = {
                type = 'ecology',
                name = Public.tokens.ecology.name,
                tt = 'chronosphere',
                sprite = Public.tokens.ecology.sprite,
                count = 200 * (1 + objective.upgrades[2] ^ 2)
            }
        }
    }
    return upgrade
end

function Public.upgrade3(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_accumulators'},
        sprite = 'recipe/accumulator',
        max_level = 24,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_accumulators_message'},
        tooltip = {'chronosphere.upgrade_accumulators_tooltip'},
        jump_limit = objective.upgrades[3],
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 3000 * coin_scaling * (1 + objective.upgrades[3] / 4)
            },
            item2 = {name = 'battery', tt = 'item-name', sprite = 'item/battery', count = 100 * (1 + objective.upgrades[3])}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 6 * (1 + objective.upgrades[3] / 2)}
        }
    }
    return upgrade
end

function Public.upgrade4(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_loot_pickup'},
        sprite = 'recipe/long-handed-inserter',
        max_level = 4,
        type = 'player',
        enabled = true,
        message = {'chronosphere.upgrade_loot_pickup_message'},
        tooltip = {'chronosphere.upgrade_loot_pickup_tooltip', objective.upgrades[4]},
        jump_limit = 0,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 1000 * coin_scaling * (1 + objective.upgrades[4])
            },
            item2 = {name = 'long-handed-inserter', tt = 'entity-name', sprite = 'recipe/long-handed-inserter', count = 400}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 10 * (1 + objective.upgrades[4])}
        }
    }
    return upgrade
end

function Public.upgrade5(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_inventory_size'},
        sprite = 'entity/character',
        max_level = 4,
        type = 'player',
        enabled = true,
        message = {'chronosphere.upgrade_inventory_size_message'},
        tooltip = {'chronosphere.upgrade_inventory_size_tooltip'},
        jump_limit = (1 + objective.upgrades[5]) * 5,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 2500 * coin_scaling * (1 + objective.upgrades[5])
            },
            item2 = {name = 'wooden-chest', tt = 'entity-name', sprite = 'item/wooden-chest', count = math_max(0, 250 - math_abs(objective.upgrades[5]) * 250)},
            item3 = {name = 'iron-chest', tt = 'entity-name', sprite = 'item/iron-chest', count = math_max(0, 250 - math_abs(objective.upgrades[5] - 1) * 250)},
            item4 = {name = 'steel-chest', tt = 'entity-name', sprite = 'item/steel-chest', count = math_max(0, 250 - math_abs(objective.upgrades[5] - 2) * 250)},
            item5 = {
                name = 'logistic-chest-storage',
                tt = 'entity-name',
                sprite = 'item/logistic-chest-storage',
                count = math_max(0, 250 - math_abs(objective.upgrades[5] - 3) * 250)
            }
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 10 * (1 + objective.upgrades[5])}
        }
    }
    return upgrade
end

function Public.upgrade6(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_repair'},
        sprite = 'recipe/repair-pack',
        max_level = 4,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_repair_message'},
        tooltip = {'chronosphere.upgrade_repair_tooltip', objective.upgrades[6]},
        jump_limit = 0,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 1000 * coin_scaling * (1 + objective.upgrades[6])
            },
            item2 = {name = 'repair-pack', tt = 'item-name', sprite = 'recipe/repair-pack', count = 200 * (1 + objective.upgrades[6])}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 10 * (1 + objective.upgrades[6])}
        }
    }
    return upgrade
end

function Public.upgrade7(coin_scaling)
    local upgrade = {
        name = {'chronosphere.upgrade_water'},
        sprite = 'fluid/water',
        max_level = 1,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_water_message'},
        tooltip = {'chronosphere.upgrade_water_tooltip'},
        jump_limit = 0,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 2000 * coin_scaling},
            item2 = {name = 'pipe', tt = 'entity-name', sprite = 'item/pipe', count = 500},
            item3 = {name = 'pump', tt = 'entity-name', sprite = 'item/pump', count = 10}
        },
        virtual_cost = {}
    }
    return upgrade
end

function Public.upgrade8(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_output'},
        sprite = 'recipe/cargo-wagon',
        max_level = 2,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_output_message'},
        tooltip = {'chronosphere.upgrade_output_tooltip'},
        jump_limit = 0,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 2000 * coin_scaling},
            item2 = {name = 'fast-inserter', tt = 'entity-name', sprite = 'recipe/fast-inserter', count = (1 - objective.upgrades[8]) * 200},
            item3 = {name = 'constant-combinator', tt = 'entity-name', sprite = 'recipe/constant-combinator', count = objective.upgrades[8] * 200}
        },
        virtual_cost = {}
    }
    return upgrade
end

function Public.upgrade9(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_storage'},
        sprite = 'item/logistic-chest-storage',
        max_level = 4,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_storage_message'},
        tooltip = {'chronosphere.upgrade_storage_tooltip'},
        jump_limit = (1 + objective.upgrades[9]) * 5,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 3000 * coin_scaling * (1 + objective.upgrades[9])
            },
            item2 = {name = 'wooden-chest', tt = 'entity-name', sprite = 'item/wooden-chest', count = math_max(0, 250 - math_abs(objective.upgrades[9]) * 250)},
            item3 = {name = 'iron-chest', tt = 'entity-name', sprite = 'item/iron-chest', count = math_max(0, 250 - math_abs(objective.upgrades[9] - 1) * 250)},
            item4 = {name = 'steel-chest', tt = 'entity-name', sprite = 'item/steel-chest', count = math_max(0, 250 - math_abs(objective.upgrades[9] - 2) * 250)},
            item5 = {
                name = 'logistic-chest-storage',
                tt = 'entity-name',
                sprite = 'item/logistic-chest-storage',
                count = math_max(0, 250 - math_abs(objective.upgrades[9] - 3) * 250)
            }
        },
        virtual_cost = {}
    }
    return upgrade
end

function Public.upgrade10(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_poison'},
        sprite = 'recipe/poison-capsule',
        max_level = 4,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_poison_message'},
        tooltip = {'chronosphere.upgrade_poison_tooltip', math_ceil(objective.poisontimeout / 6)},
        jump_limit = 0,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 1000 * coin_scaling},
            item2 = {name = 'poison-capsule', tt = 'item-name', sprite = 'recipe/poison-capsule', count = 50}
        },
        virtual_cost = {
            virtual1 = {type = 'ammo', name = Public.tokens.ammo.name, tt = 'chronosphere', sprite = Public.tokens.ammo.sprite, count = 10}
        }
    }
    return upgrade
end

function Public.upgrade11()
    local upgrade = {
        name = {'chronosphere.upgrade_fusion'},
        sprite = 'recipe/fusion-reactor-equipment',
        max_level = 999,
        type = 'player',
        enabled = true,
        message = {'chronosphere.upgrade_fusion_message'},
        tooltip = {'chronosphere.upgrade_fusion_tooltip'},
        jump_limit = 24,
        cost = {
            item1 = {name = 'low-density-structure', tt = 'item-name', sprite = 'item/low-density-structure', count = 70},
            item2 = {name = 'processing-unit', tt = 'item-name', sprite = 'item/processing-unit', count = 50},
            item3 = {name = 'solar-panel-equipment', tt = 'equipment-name', sprite = 'item/solar-panel-equipment', count = 16}
        },
        virtual_cost = {
            virtual1 = {type = 'weapons', name = Public.tokens.weapons.name, tt = 'chronosphere', sprite = Public.tokens.weapons.sprite, count = 160}
        }
    }
    return upgrade
end

function Public.upgrade12()
    local upgrade = {
        name = {'chronosphere.upgrade_mk2'},
        sprite = 'recipe/power-armor-mk2',
        max_level = 999,
        type = 'player',
        enabled = true,
        message = {'chronosphere.upgrade_mk2_message'},
        tooltip = {'chronosphere.upgrade_mk2_tooltip'},
        jump_limit = 28,
        cost = {
            item1 = {name = 'low-density-structure', tt = 'item-name', sprite = 'item/low-density-structure', count = 100},
            item3 = {name = 'power-armor', tt = 'item-name', sprite = 'item/power-armor', count = 1}
        },
        virtual_cost = {
            virtual1 = {type = 'weapons', name = Public.tokens.weapons.name, tt = 'chronosphere', sprite = Public.tokens.weapons.sprite, count = 300}
        }
    }
    return upgrade
end

function Public.upgrade13(coin_scaling)
    local upgrade = {
        name = {'chronosphere.upgrade_computer1'},
        sprite = 'item/advanced-circuit',
        max_level = 1,
        type = 'quest',
        enabled = true,
        message = {'chronosphere.upgrade_computer1_message'},
        tooltip = {'chronosphere.upgrade_computer1_tooltip'},
        jump_limit = 15,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 5000 * coin_scaling},
            item2 = {name = 'advanced-circuit', tt = 'item-name', sprite = 'item/advanced-circuit', count = 1000},
            item3 = {name = 'copper-plate', tt = 'item-name', sprite = 'item/copper-plate', count = 2000}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 100}
        }
    }
    return upgrade
end

function Public.upgrade14(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_computer2'},
        sprite = 'item/processing-unit',
        max_level = 1,
        type = 'quest',
        enabled = objective.upgrades[13] == 1,
        message = {'chronosphere.upgrade_computer2_message'},
        tooltip = {'chronosphere.upgrade_computer2_tooltip'},
        jump_limit = 20,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 10000 * coin_scaling},
            item2 = {name = 'processing-unit', tt = 'item-name', sprite = 'item/processing-unit', count = 1000},
            item3 = {name = 'nuclear-reactor', tt = 'entity-name', sprite = 'item/nuclear-reactor', count = 1}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 200}
        }
    }
    return upgrade
end

function Public.upgrade15(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_computer3'},
        sprite = 'item/rocket-control-unit',
        max_level = 10,
        type = 'quest',
        enabled = objective.upgrades[14] == 1,
        message = {'chronosphere.upgrade_computer3_message', objective.upgrades[15] + 1},
        tooltip = {'chronosphere.upgrade_computer3_tooltip'},
        jump_limit = 25,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 2000 * coin_scaling},
            item2 = {name = 'low-density-structure', tt = 'item-name', sprite = 'item/low-density-structure', count = 100},
            item3 = {name = 'rocket-control-unit', tt = 'item-name', sprite = 'item/rocket-control-unit', count = 100},
            item4 = {name = 'uranium-fuel-cell', tt = 'item-name', sprite = 'item/uranium-fuel-cell', count = 50}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 30}
        }
    }
    return upgrade
end

function Public.upgrade16()
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_computer4'},
        sprite = 'item/satellite',
        max_level = 1,
        type = 'quest',
        enabled = objective.upgrades[15] == 10,
        message = {'chronosphere.upgrade_computer4_message'},
        tooltip = {'chronosphere.upgrade_computer4_tooltip'},
        jump_limit = 25,
        cost = {
            item1 = {name = 'rocket-silo', tt = 'entity-name', sprite = 'item/rocket-silo', count = 1},
            item2 = {name = 'satellite', tt = 'item-name', sprite = 'item/satellite', count = 1},
            item3 = {name = 'spidertron', tt = 'entity-name', sprite = 'item/spidertron', count = 2}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 400}
        }
    }
    return upgrade
end

function Public.upgrade17(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_nukeshied'},
        sprite = 'item/rocket',
        max_level = 1,
        type = 'quest',
        enabled = (objective.config.jumpfailure and objective.chronojumps >= 19) or (objective.world.id == 2 and objective.world.variant.id == 2),
        message = {'chronosphere.upgrade_nukeshield_message'},
        tooltip = {'chronosphere.upgrade_nukeshield_tooltip'},
        jump_limit = 0,
        cost = {
            item1 = {name = 'rocket', tt = 'item-name', sprite = 'item/rocket', count = 1000},
            item2 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 5000 * coin_scaling}
        },
        virtual_cost = {
            virtual1 = {type = 'ammo', name = Public.tokens.ammo.name, tt = 'chronosphere', sprite = Public.tokens.ammo.sprite, count = 200},
            virtual2 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 40}
        }
    }
    return upgrade
end

function Public.upgrade18()
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_researchspeed'},
        sprite = 'item/lab',
        max_level = 4,
        type = 'quest',
        enabled = objective.chronojumps >= 7,
        message = {'chronosphere.upgrade_researchspeed_message'},
        tooltip = {'chronosphere.upgrade_researchspeed_tooltip'},
        jump_limit = (1 + objective.upgrades[18]) * 6,
        cost = {
            item1 = {name = 'lab', tt = 'item-name', sprite = 'item/lab', count = 50 * (1 + objective.upgrades[18])},
            item2 = {name = 'speed-module', tt = 'item-name', sprite = 'item/speed-module', count = 20 * (1 + objective.upgrades[18])},
            item3 = {name = 'productivity-module', tt = 'item-name', sprite = 'item/productivity-module', count = 20 * (1 + objective.upgrades[18])},
            item4 = {name = 'speed-module-2', tt = 'item-name', sprite = 'item/speed-module-2', count = 20 * (objective.upgrades[18] / 2)}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 200}
        }
    }
    return upgrade
end

function Public.upgrade19(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_craftingspeed'},
        sprite = 'item/assembling-machine-1',
        max_level = 4,
        type = 'player',
        enabled = true,
        message = {'chronosphere.upgrade_craftingspeed_message'},
        tooltip = {'chronosphere.upgrade_craftingspeed_tooltip'},
        jump_limit = (1 + objective.upgrades[19]) * 5,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 1000 * coin_scaling * (1 + objective.upgrades[19])
            },
            item2 = {name = 'assembling-machine-1', tt = 'entity-name', sprite = 'item/assembling-machine-1', count = 50 * (1 + objective.upgrades[19])},
            item3 = {name = 'assembling-machine-2', tt = 'entity-name', sprite = 'item/assembling-machine-2', count = 50 * (objective.upgrades[19])}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 10 * (1 + objective.upgrades[19])}
        }
    }
    return upgrade
end

function Public.upgrade20(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_discharge'},
        sprite = 'item/discharge-defense-equipment',
        max_level = 5,
        type = 'player',
        enabled = true,
        message = {'chronosphere.upgrade_discharge_message'},
        tooltip = {'chronosphere.upgrade_discharge_tooltip'},
        jump_limit = 5 + (1 + objective.upgrades[20]) * 8,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 5000 * coin_scaling * (1 + objective.upgrades[20])
            },
            item2 = {name = 'discharge-defense-equipment', tt = 'equipment-name', sprite = 'item/discharge-defense-equipment', count = 2 * (1 + objective.upgrades[20])}
        },
        virtual_cost = {
            virtual1 = {type = 'ammo', name = Public.tokens.ammo.name, tt = 'chronosphere', sprite = Public.tokens.ammo.sprite, count = 50 * (1 + objective.upgrades[20])},
            virtual2 = {
                type = 'biters',
                name = Public.tokens.biters.name,
                tt = 'chronosphere',
                sprite = Public.tokens.biters.sprite,
                count = 8000 * (1 + objective.upgrades[20]) ^ 2
            }
        }
    }
    return upgrade
end

function Public.upgrade21()
    local objective = Chrono_table.get_table()
    local difficulty = Difficulty.get().difficulty_vote_value
    local upgrade = {
        name = {'chronosphere.upgrade_spidertron'},
        sprite = 'recipe/spidertron',
        max_level = 2,
        type = 'quest',
        enabled = objective.upgrades[15] == 10 and difficulty >= 1,
        message = {'chronosphere.upgrade_spidertron_message', objective.upgrades[21] + 1},
        tooltip = {'chronosphere.upgrade_spidertron_tooltip'},
        jump_limit = 20,
        cost = {
            item1 = {name = 'automation-science-pack', tt = 'item-name', sprite = 'item/automation-science-pack', count = (1 - objective.upgrades[21]) * 3000},
            item2 = {name = 'logistic-science-pack', tt = 'item-name', sprite = 'item/logistic-science-pack', count = (1 - objective.upgrades[21]) * 3000},
            item3 = {name = 'military-science-pack', tt = 'item-name', sprite = 'item/military-science-pack', count = (1 - objective.upgrades[21]) * 2400},
            item4 = {name = 'chemical-science-pack', tt = 'item-name', sprite = 'item/chemical-science-pack', count = objective.upgrades[21] * 1250},
            item5 = {name = 'production-science-pack', tt = 'item-name', sprite = 'item/production-science-pack', count = objective.upgrades[21] * 1250},
            item6 = {name = 'utility-science-pack', tt = 'item-name', sprite = 'item/utility-science-pack', count = objective.upgrades[21] * 1250}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 100}
        }
    }
    return upgrade
end

function Public.upgrade22(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_train_lasers'},
        sprite = 'item/personal-laser-defense-equipment',
        max_level = 4,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_train_lasers_message'},
        tooltip = {'chronosphere.upgrade_train_lasers_tooltip'},
        jump_limit = (2 + objective.upgrades[22]) * 5,
        cost = {
            item1 = {
                name = 'coin',
                tt = 'item-name',
                sprite = 'item/coin',
                count = 5000 * coin_scaling * (1 + objective.upgrades[22])
            },
            item2 = {name = 'laser-turret', tt = 'item-name', sprite = 'item/laser-turret', count = 25 * (1 + objective.upgrades[22])},
            item3 = {name = 'accumulator', tt = 'entity-name', sprite = 'item/accumulator', count = 25 * (1 + objective.upgrades[22])}
        },
        virtual_cost = {
            virtual1 = {type = 'ammo', name = Public.tokens.ammo.name, tt = 'chronosphere', sprite = Public.tokens.ammo.sprite, count = 20 * (1 + objective.upgrades[22])},
            virtual2 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 10 * (1 + objective.upgrades[22])}
        }
    }
    return upgrade
end

function Public.upgrade23(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_nuclear_artillery'},
        sprite = 'recipe/artillery-turret',
        max_level = 1,
        type = 'quest',
        enabled = objective.upgrades[15] == 10 and game.forces.player.technologies['artillery'].researched == true,
        message = {'chronosphere.upgrade_nuclear_artillery_message'},
        tooltip = {'chronosphere.upgrade_nuclear_artillery_tooltip'},
        jump_limit = 20,
        cost = {
            item1 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 10000 * coin_scaling},
            item2 = {name = 'artillery-turret', tt = 'entity-name', sprite = 'item/artillery-turret', count = 10},
            item3 = {name = 'military-science-pack', tt = 'item-name', sprite = 'item/military-science-pack', count = 1000},
            item4 = {name = 'atomic-bomb', tt = 'item-name', sprite = 'item/atomic-bomb', count = 20},
            item5 = {name = 'rocket-control-unit', tt = 'item-name', sprite = 'item/rocket-control-unit', count = 50},
            item6 = {name = 'satellite', tt = 'item-name', sprite = 'item/satellite', count = 1}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 200}
        }
    }
    return upgrade
end

function Public.upgrade24()
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_nuclear_artillery_ammo'},
        sprite = 'item/atomic-bomb',
        max_level = 100,
        type = 'quest',
        enabled = objective.upgrades[23] == 1,
        message = {'chronosphere.upgrade_nuclear_artillery_ammo_message'},
        tooltip = {'chronosphere.upgrade_nuclear_artillery_ammo_tooltip'},
        jump_limit = 20,
        cost = {
            item1 = {name = 'atomic-bomb', tt = 'item-name', sprite = 'item/atomic-bomb', count = 10}
        },
        virtual_cost = {
            virtual1 = {type = 'biters', name = Public.tokens.biters.name, tt = 'chronosphere', sprite = Public.tokens.biters.sprite, count = 500}
        }
    }
    return upgrade
end

function Public.upgrade25()
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_poison_mastery'},
        sprite = 'item/heavy-armor',
        max_level = 4,
        type = 'quest',
        enabled = objective.poison_mastery_unlocked >= 10,
        message = {'chronosphere.upgrade_poison_mastery_message'},
        tooltip = {'chronosphere.upgrade_poison_mastery_tooltip'},
        jump_limit = 0,
        cost = {
            item1 = {name = 'heavy-armor', tt = 'item-name', sprite = 'item/heavy-armor', count = 10},
            item2 = {name = 'power-armor', tt = 'item-name', sprite = 'item/power-armor', count = (1 + objective.upgrades[25])},
            item3 = {name = 'poison-capsule', tt = 'item-name', sprite = 'recipe/poison-capsule', count = 50 * (1 + objective.upgrades[25])},
            item4 = {name = 'military-science-pack', tt = 'item-name', sprite = 'item/military-science-pack', count = (1 + objective.upgrades[25]) * 100},
            item5 = {name = 'chemical-science-pack', tt = 'item-name', sprite = 'item/chemical-science-pack', count = objective.upgrades[25] * 100}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 20 * (1 + objective.upgrades[25])},
            virtual2 = {type = 'ammo', name = Public.tokens.ammo.name, tt = 'chronosphere', sprite = Public.tokens.ammo.sprite, count = 10 * (1 + objective.upgrades[25])}
        }
    }
    return upgrade
end

function Public.upgrade26(coin_scaling)
    local objective = Chrono_table.get_table()
    local upgrade = {
        name = {'chronosphere.upgrade_giftmas'},
        sprite = 'entity/tree-01',
        max_level = 4,
        type = 'quest',
        enabled = objective.giftmas_enabled,
        message = {'chronosphere.upgrade_giftmas_message'},
        tooltip = {'chronosphere.upgrade_giftmas_tooltip'},
        jump_limit = 0,
        cost = {
            item1 = {name = 'small-lamp', tt = 'item-name', sprite = 'item/small-lamp', count = 50 * (1 + objective.upgrades[26])},
            item2 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 1000 * coin_scaling * (1 + objective.upgrades[26])}
        },
        virtual_cost = {}
    }
    return upgrade
end

function Public.upgrade27(coin_scaling)
    local upgrade = {
        name = {'chronosphere.upgrade_radar'},
        sprite = 'entity/radar',
        max_level = 1,
        type = 'train',
        enabled = true,
        message = {'chronosphere.upgrade_radar_message'},
        tooltip = {'chronosphere.upgrade_radar_tooltip'},
        jump_limit = 0,
        cost = {
            item1 = {name = 'radar', tt = 'entity-name', sprite = 'entity/radar', count = 200},
            item2 = {name = 'coin', tt = 'item-name', sprite = 'item/coin', count = 1000 * coin_scaling}
        },
        virtual_cost = {
            virtual1 = {type = 'tech', name = Public.tokens.tech.name, tt = 'chronosphere', sprite = Public.tokens.tech.sprite, count = 20}
        }
    }
    return upgrade
end

function Public.upgrades()
    local objective = Chrono_table.get_table()
    if not objective.upgrades then
        objective.upgrades = {}
        for i = 1, Public.upgrade_count(), 1 do
            objective.upgrades[i] = 0
        end
    end
    local coin_scaling = Public.coin_scaling()

    --Each upgrade is automatically added into gui.
    --name : visible name in gui (best if localized)
    --sprite: visible icon
    --cost/item/tt = the first part of localized string, for example coin is in item-name.coin. Can be even scenario's key.
    --Second part of localized string is taken from item's name.
    --First additional parameter for tooltip should match the max_level
    --still need to map upgrade effects in upgrades.lua / process_upgrade() if it should do more than increase level of upgrade
    --virtual token types need to match the names of chronotable.research_tokens[]
    --splitted into a function per upgrade above, so each upgrade can be acessed without needing to construct whole list
    local upgrades = {
        [1] = Public.upgrade1(coin_scaling),
        [2] = Public.upgrade2(coin_scaling),
        [3] = Public.upgrade3(coin_scaling),
        [4] = Public.upgrade4(coin_scaling),
        [5] = Public.upgrade5(coin_scaling),
        [6] = Public.upgrade6(coin_scaling),
        [7] = Public.upgrade7(coin_scaling),
        [8] = Public.upgrade8(coin_scaling),
        [9] = Public.upgrade9(coin_scaling),
        [10] = Public.upgrade10(coin_scaling),
        [11] = Public.upgrade11(coin_scaling),
        [12] = Public.upgrade12(coin_scaling),
        [13] = Public.upgrade13(coin_scaling),
        [14] = Public.upgrade14(coin_scaling),
        [15] = Public.upgrade15(coin_scaling),
        [16] = Public.upgrade16(coin_scaling),
        [17] = Public.upgrade17(coin_scaling),
        [18] = Public.upgrade18(coin_scaling),
        [19] = Public.upgrade19(coin_scaling),
        [20] = Public.upgrade20(coin_scaling),
        [21] = Public.upgrade21(coin_scaling),
        [22] = Public.upgrade22(coin_scaling),
        [23] = Public.upgrade23(coin_scaling),
        [24] = Public.upgrade24(coin_scaling),
        [25] = Public.upgrade25(coin_scaling),
        [26] = Public.upgrade26(coin_scaling),
        [27] = Public.upgrade27(coin_scaling)

        --don't forget to change the count in count function on top after adding more upgrades!
    }
    return upgrades
end

return Public
