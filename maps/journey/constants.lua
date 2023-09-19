
local Public = {}

Public.mothership_teleporter_position = {x = 0, y = 12}
Public.teleporter_tile = 'lab-dark-2'

Public.mothership_radius = 48

Public.particle_spawn_vectors = {}
for x = Public.mothership_radius * -1 - 32, Public.mothership_radius + 32, 1 do
	for y = Public.mothership_radius * -1 - 64, Public.mothership_radius + 32, 1 do
		local position = {x = x, y = y}
		local distance = math.sqrt(position.x ^ 2 + position.y ^ 2)
		if distance > Public.mothership_radius then
			table.insert(Public.particle_spawn_vectors, {position.x, position.y})
		end
	end
end
Public.size_of_particle_spawn_vectors = #Public.particle_spawn_vectors

Public.world_selector_width = 6
Public.world_selector_height = 8
Public.max_satellites = 3

local area = {
	left_top = {x = -3, y = 4 + math.floor(Public.mothership_radius * 0.5) * -1},
	right_bottom = {x = 3, y = 4 + math.floor(Public.mothership_radius * 0.5) * -1 + Public.world_selector_height},
}

Public.world_selector_areas = {
	[1] = {
		left_top = {x = area.left_top.x - 14, y = area.left_top.y},
		right_bottom = {x = area.left_top.x - 8, y = area.right_bottom.y},
	},
	[2] = area,
	[3] = {
		left_top = {x = area.right_bottom.x + 8, y = area.left_top.y},
		right_bottom = {x = area.right_bottom.x + 14, y = area.right_bottom.y},
	},
}

Public.world_selector_colors = {
	[1] = {r = 200, g = 200, b = 0, a = 255},
	[2] = {r = 150, g = 150, b = 255, a = 255},
	[3] = {r = 200, g = 100, b = 100, a = 255},
}

Public.reroll_selector_area_color = {r = 220, g = 220, b = 220, a = 255}
Public.reroll_selector_area = {
	left_top = {x = -4, y = math.floor(Public.mothership_radius - 6) * -1},
	right_bottom = {x = 4, y = math.floor(Public.mothership_radius - 6) * -1 + 5},
}

Public.mothership_messages = {
	waiting = {
		'Return to me, so we can continue the journey!',
		'Don\'t leave me waiting for so long. Let\'s continue our journey.',
		'Please return to me.',
		'Board me, so we can continue this adventure!',
	},
	answers = {
		'Yes, great idea.',
		'Yes, wonderful.',
		'Yes, definitely.',
		'Yes, i love it!',
		'The calculations say yes.',
		'I don\'t know how to feel about this.',
		'Ask again later, my processors are very busy.',
		'No, this is certainly wrong.',
		'No, i don\'t think so.',
		'No, you are wrong.',
		'No, that would be weird.',
		'The calculations say no.',
	},
}

Public.mothership_gen_settings = {
	['water'] = 0,
	['starting_area'] = 1,
	['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
	['default_enable_all_autoplace_controls'] = false,
	['autoplace_settings'] = {
		['entity'] = {treat_missing_as_default = false},
		['tile'] = {treat_missing_as_default = false},
		['decorative'] = {treat_missing_as_default = false},
	},
	autoplace_controls = {
		['coal'] = {frequency = 0, size = 0, richness = 0},
		['stone'] = {frequency = 0, size = 0, richness = 0},
		['copper-ore'] = {frequency = 0, size = 0, richness = 0},
		['iron-ore'] = {frequency = 0, size = 0, richness = 0},
		['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
		['crude-oil'] = {frequency = 0, size = 0, richness = 0},
		['trees'] = {frequency = 0, size = 0, richness = 0},
		['enemy-base'] = {frequency = 0, size = 0, richness = 0}
	},
}

Public.modifiers = {
	['trees_size'] = {min = 0.01, max = 10, base = 1, dmin = -40, dmax = -20, name = 'Forest Sizes'},
	['trees_richness'] = {min = 0.01, max = 10, base = 1, dmin = -40, dmax = -20, name = 'Amounts Of Trees'},
	['trees_frequency'] = {min = 0.01, max = 10, base = 1, dmin = -40, dmax = -20, name = 'Forest Frequency'},
	['tree_durability'] = {min = 0.1, max = 50, base = 30, dmin = -30, dmax =-15, name = 'Tree Durability'},
	['ore_size'] = {min = 0.8, max = 10, base = 2, dmin = -10, dmax = -5, name = 'Ore Field Size'},
	['ore_frequency'] = {min = 1, max = 1, base = 1, dmin = 0, dmax = 0, name = 'Ore Frequency', static = true},
	['cliff_continuity'] = {min = 1, max = 10, base = 8, dmin = -30, dmax = -15, name = 'Cliff Continuity'},
	['cliff_frequency'] = {min = 5, max = 80, base = 60, dmin = -30, dmax = -15, name = 'Cliff Frequency'},
	['water'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Water'},
	['coal'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Coal'},
	['stone'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Stone'},
	['iron-ore'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Iron Ore'},
	['copper-ore'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Copper Ore'},
	['crude-oil'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Oil'},
	['uranium-ore'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Uranium Ore'},
	['mixed_ore'] = {min = 0.01, max = 10, base = 1, dmin = -20, dmax = -10, name = 'Mixed Ore'},
	['enemy_base_size'] = {min = 0.01, max = 10, base = 1, dmin = 20, dmax = 40, name = 'Nest Sizes'},
	['enemy_base_richness'] = {min = 0.01, max = 10, base = 1, dmin = 20, dmax = 40, name = 'Nest Amounts'},
	['enemy_base_frequency'] = {min = 0.01, max = 10, base = 1, dmin = 20, dmax = 40, name = 'Nest Frequency'},
	['expansion_cooldown'] = {min = 3600, max = 28800, base = 14400, dmin = -20, dmax = -10, name = 'Nest Expansion Cooldown'},
	['enemy_attack_pollution_consumption_modifier'] = {min = 0.25, max = 4, base = 1, dmin = -5, dmax = -2.5, name = 'Nest Pollution Consumption'},
	['max_unit_group_size'] = {min = 10, max = 500, base = 100, dmin = 10, dmax = 20, name = 'Biter Group Size Maximum'},
	['time_factor'] = {min = 0.000001, max = 0.0001, base = 0.000004, dmin = 15, dmax = 30, name = 'Evolution Time Factor'},
	['destroy_factor'] = {min = 0.0002, max = 0.2, base = 0.002, dmin = 15, dmax = 30, name = 'Evolution Destroy Factor'},
	['pollution_factor'] = {min = 0.00000009, max = 0.00009, base = 0.0000009, dmin = 15, dmax = 30, name = 'Evolution Pollution Factor'},
	['ageing'] = {min = 0.01, max = 4, base = 1, dmin = -20, dmax = -10, name = 'Terrain Pollution Consumption'},
	['diffusion_ratio'] = {min = 0.005, max = 0.05, base = 0.02, dmin = 10, dmax = 20, name = 'Pollution Diffusion'},
	['technology_price_multiplier'] = {min = 0.05, max = 5, base = 0.5, dmin = 10, dmax = 20, name = 'Technology Price'},
	['beacon_irritation'] = {min = 100, max = 1200, base = 900, dmin = -20, dmax = -10, name = 'Biter Attack Cooldown', static = true},
	['starting_area'] = {min = 1, max = 1, base = 1, dmin = 0, dmax = 0, name = 'Starting Area Size', static = true}
}

Public.starter_goods_pool = {
    ['basic'] = {
        {'copper-cable', 128, 256},
        {'copper-plate', 64, 128},
        {'iron-gear-wheel', 64, 128},
        {'iron-plate', 64, 128},
        {'petroleum-gas-barrel', 20, 40},
        {'solid-fuel', 256, 512},
        {'steel-plate', 32, 64},
        {'electronic-circuit', 32, 64},
    },
    ['low'] = {
        {'burner-inserter', 64, 128},
        {'burner-mining-drill', 8, 16},
        {'lab', 2, 4},
        {'steel-furnace', 8, 16},
        {'boiler', 2, 4},
        {'steam-engine', 4, 8},
    },
    ['mil'] = {
        {'cliff-explosives', 10, 20},
        {'firearm-magazine', 64, 128},
        {'grenade', 8, 16},
        {'gun-turret', 4, 8},
        {'radar', 4, 8},
        {'stone-wall', 128, 256},
        {'gate', 32, 64},
        {'heavy-armor', 1, 1},
        {'modular-armor', 1, 1},
        {'shotgun-shell', 64, 128},
        {'defender-capsule', 12, 24},
        {'flamethrower-ammo', 20, 40},
        {'slowdown-capsule', 10, 20},
    },
    ['inter'] = {
        {'big-electric-pole', 8, 16},
        {'car', 2, 4},
        {'electric-mining-drill', 4, 8},
        {'inserter', 32, 64},
        {'lab', 2, 4},
        {'long-handed-inserter', 32, 64},
        {'medium-electric-pole', 16, 32},
        {'pipe', 128, 256},
        {'small-lamp', 64, 128},
        {'steel-chest', 16, 32},
        {'transport-belt', 32, 64},
        {'pumpjack', 2, 4},
    },
    ['adv'] = {
        {'accumulator', 8, 16},
        {'electric-furnace', 4, 8},
        {'solar-panel', 8, 16},
        {'stack-inserter', 16, 32},
        {'stack-filter-inserter', 16, 32},
        {'steam-turbine', 4, 8},
        {'substation', 4, 8},
        {'chemical-plant', 3, 6},
        {'oil-refinery', 1, 2},
    },
    ['rare'] = {
        {'green-wire', 256, 512},
        {'red-wire', 256, 512},
        {'heat-exchanger', 1, 2},
        {'heat-pipe', 10, 20},
        {'nuclear-fuel', 4, 8},
        {'nuclear-reactor', 1, 1},
        {'advanced-circuit', 16, 32},
        {'construction-robot', 16, 32},
        {'personal-roboport-equipment', 1, 1},
        {'solar-panel-equipment', 2, 4},
        {'effectivity-module', 5, 10},
    },
}

Public.build_type_whitelist = {
	['arithmetic-combinator'] = true,
	['constant-combinator'] = true,
	['decider-combinator'] = true,
	['electric-energy-interface'] = true,
	['electric-pole'] = true,
	['gate'] = true,
	['heat-pipe'] = true,
	['lamp'] = true,
	['pipe'] = true,
	['pipe-to-ground'] = true,
	['programmable-speaker'] = true,
	['transport-belt'] = true,
	['wall'] = true,
}

Public.unique_world_traits = {
	['lush'] = {
        name = 'Lush',
        desc = 'Pure Vanilla.',
        mods = 1,
        loot = {basic = {1, 1}, low = {1, 1}, mil = {0, 1}, inter = {0, 1}, adv = {0, 0}, rare = {0, 0}}
    },
	['abandoned_library'] = {
        name = 'Abandoned Library',
        desc = 'No blueprints to be found.',
        mods = 3,
        loot = {basic = {0, 1}, low = {0, 1}, mil = {0, 1}, inter = {0, 1}, adv = {1, 1}, rare = {1, 1}}
    },
	['lazy_bastard'] = {
        name = 'Lazy Bastard',
        desc = 'The machine does the job.',
        mods = 4,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {0, 1}, inter = {0, 2}, adv = {0, 1}, rare = {1, 1}}
    },
	['oceanic'] = {
        name = 'Oceanic',
        desc = 'Arrrr, the flame turrets seem to malfunction in this climate.',
        mods = 2,
        loot = {basic = {1, 1}, low = {0, 0}, mil = {0, 2}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['ribbon'] = {
        name = 'Ribbon',
        desc = 'Go right. (or left)',
        mods = 4,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {0, 1}, inter = {0, 2}, adv = {0, 1}, rare = {1, 1}}
    },
	['wasteland'] = {
        name = 'Wasteland',
        desc = 'Rusty treasures.',
        mods = 2,
        loot = {basic = {0, 1}, low = {0, 1}, mil = {1, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['infested'] = {
        name = 'Infested',
        desc = 'They lurk inside.',
        mods = 4,
        loot = {basic = {0, 1}, low = {0, 0}, mil = {1, 1}, inter = {0, 2}, adv = {0, 2}, rare = {1, 1}}
    },
	['pitch_black'] = {
        name = 'Pitch Black',
        desc = 'No light may reach this realm.',
        mods = 2,
        loot = {basic = {1, 1}, low = {0, 1}, mil = {0, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['volcanic'] = {
        name = 'Volcanic',
        desc = 'The floor is (almost) lava.',
        mods = 4,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {1, 1}, inter = {0, 2}, adv = {0, 2}, rare = {1, 1}}
    },
	['matter_anomaly'] = {
        name = 'Matter Anomaly',
        desc = 'Why can\'t I hold all these ores.\nThe laser turret structures seem to malfunction.',
        mods = 2,
        loot = {basic = {1, 1}, low = {0, 1}, mil = {1, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['mountainous'] = {
        name = 'Mountainous',
        desc = 'Diggy diggy hole!',
        mods = 2,
        loot = {basic = {1, 1}, low = {0, 1}, mil = {0, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['eternal_night'] = {
        name = 'Eternal Night',
        desc = 'This world seems to be missing a sun.',
        mods = 2,
        loot = {basic = {1, 1}, low = {0, 1}, mil = {0, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['dense_atmosphere'] = {
        name = 'Dense Atmosphere',
        desc = 'Your roboport structures seem to malfunction.',
        mods = 3,
        loot = {basic = {0, 1}, low = {0, 0}, mil = {0, 1}, inter = {1, 1}, adv = {0, 1}, rare = {1, 1}}
    },
	['undead_plague'] = {
        name = 'Undead Plague',
        desc = 'The dead are restless.',
        mods = 4,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {1, 1}, inter = {0, 2}, adv = {0, 2}, rare = {1, 1}}
    },
	['swamps'] = {
        name = 'Swamps',
        desc = 'No deep water to be found in this world.',
        mods = 3,
        loot = {basic = {0, 1}, low = {0, 0}, mil = {0, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['chaotic_resources'] = {
        name = 'Chaotic Resources',
        desc = 'Something to sort out.',
        mods = 2,
        loot = {basic = {0, 1}, low = {0, 1}, mil = {0, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['low_mass'] = {
        name = 'Low Mass',
        desc = 'You feel light footed and the robots are buzzing.',
        mods = 2,
        loot = {basic = {0, 1}, low = {0, 1}, mil = {0, 0}, inter = {0, 2}, adv = {0, 1}, rare = {0, 1}}
    },
	['eternal_day'] = {
        name = 'Eternal Day',
        desc = 'The sun never moves.',
        mods = 1,
        loot = {basic = {1, 1}, low = {0, 1}, mil = {0, 0}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['quantum_anomaly'] = {
        name = 'Quantum Anomaly',
        desc = 'Research complete.',
        mods = 2,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {0, 1}, inter = {1, 1}, adv = {0, 1}, rare = {0, 1}}
    },
	['replicant_fauna'] = {
        name = 'Replicant Fauna',
        desc = 'The biters feed on your structures.',
        mods = 4,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {1, 1}, inter = {0, 1}, adv = {0, 1}, rare = {1, 1}}
    },
	['tarball'] = {
        name = 'Tarball',
        desc = 'Door stuck, Door stuck...',
        mods = 4,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {0, 1}, inter = {0, 2}, adv = {0, 2}, rare = {1, 1}}
    },
    ['railworld'] = {
        name = 'Railworld',
        desc = 'Long distances better travelled by train...',
        mods = 3,
        loot = {basic = {0, 1}, low = {0, 0}, mil = {0, 1}, inter = {0, 1}, adv = {0, 1}, rare = {0, 1}}
    },
    ['resupply_station'] = {
        name = 'Resupply Station',
        desc = 'Local Orbital Station requires immediate resupply.\n Faster the delivery, more they pay.',
        mods = 2,
        loot = {basic = {0, 0}, low = {0, 0}, mil = {0, 1}, inter = {0, 2}, adv = {0, 2}, rare = {1, 1}}
    },
}

return Public
