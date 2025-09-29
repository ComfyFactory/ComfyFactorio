local Public = {}

Public.treasures = {
    ['wooden-chest'] = {
        tech_bonus = 0.1,
        amount_multiplier = 1,
        description = 'an old wooden crate.'
    },
    ['iron-chest'] = {
        tech_bonus = 0.15,
        amount_multiplier = 1.5,
        description = 'an antique iron crate.'
    },
    ['steel-chest'] = {
        tech_bonus = 0.2,
        amount_multiplier = 2,
        description = 'a shiny metal box!'
    },
    ['crash-site-spaceship-wreck-medium-1'] = {
        tech_bonus = 0.25,
        amount_multiplier = 2.5,
        description = 'a spaceship wreck piece!'
    },
    ['crash-site-spaceship-wreck-medium-2'] = {
        tech_bonus = 0.25,
        amount_multiplier = 2.5,
        description = 'a space station wreck piece, containing some precious scrap!'
    },
    ['crash-site-spaceship-wreck-medium-3'] = {
        tech_bonus = 0.25,
        amount_multiplier = 2.5,
        description = 'a wreck piece, containing rare scrap!'
    },
    ['crash-site-spaceship-wreck-big-1'] = {
        tech_bonus = 0.30,
        amount_multiplier = 3,
        description = 'a big wreck.'
    },
    ['crash-site-spaceship-wreck-big-2'] = {
        tech_bonus = 0.30,
        amount_multiplier = 3,
        description = 'a station wreck!'
    },
    ['crash-site-spaceship-wreck-big-1'] = {
        tech_bonus = 0.35,
        amount_multiplier = 3.5,
        description = 'a crashed space ship! The cargo is still intact!'
    },
    ['crash-site-spaceship-wreck-big-2'] = {
        tech_bonus = 0.35,
        amount_multiplier = 3.5,
        description = 'a crashed space ship!'
    },
    ['big-ship-wreck-3'] = {
        tech_bonus = 0.35,
        amount_multiplier = 3.5,
        description = 'a crashed starship!'
    },
    ['crash-site-chest-1'] = {
        tech_bonus = 0.40,
        amount_multiplier = 4,
        description = 'a drop pod capsule! It is filled with useful loot!'
    },
    ['crash-site-chest-2'] = {
        tech_bonus = 0.40,
        amount_multiplier = 4,
        description = 'a cargo pod capsule! It is filled with nice things!'
    },
    ['crash-site-spaceship'] = {
        tech_bonus = 0.5,
        amount_multiplier = 5,
        description = 'a big crashed spaceship! There are treasures inside..'
    }
}

Public.chat_color = {200, 200, 200}

Public.starting_items = {
    ['pistol'] = 1,
    ['firearm-magazine'] = 8,
    ['wood'] = 8,
    ['raw-fish'] = 3
}

Public.reveal_chain_brush_sizes = {
    ['unit'] = 7,
    ['unit-spawner'] = 15,
    ['turret'] = 9
}

Public.spawn_market_items = {
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'rail', count = 2}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'rail-signal', count = 1}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'rail-chain-signal', count = 1}},
    {price = {{ name = 'raw-fish', count = 8}}, offer = {type = 'give-item', item = 'train-stop'}},
    {price = {{ name = 'raw-fish', count = 50}}, offer = {type = 'give-item', item = 'locomotive'}},
    {price = {{ name = 'raw-fish', count = 20}}, offer = {type = 'give-item', item = 'cargo-wagon'}},
    {price = {{ name = 'raw-fish', count = 3}}, offer = {type = 'give-item', item = 'decider-combinator'}},
    {price = {{ name = 'raw-fish', count = 3}}, offer = {type = 'give-item', item = 'arithmetic-combinator'}},
    {price = {{ name = 'raw-fish', count = 2}}, offer = {type = 'give-item', item = 'constant-combinator'}},
    {price = {{ name = 'raw-fish', count = 4}}, offer = {type = 'give-item', item = 'programmable-speaker'}},
    {price = {{ name = 'raw-fish', count = 2}}, offer = {type = 'give-item', item = 'small-lamp'}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 2}},
    {price = {{ name = 'raw-fish', count = 2}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine'}},
    {price = {{ name = 'raw-fish', count = 2}}, offer = {type = 'give-item', item = 'grenade'}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'land-mine'}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'explosives', count = 3}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'wood', count = 10}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'iron-ore', count = 10}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'copper-ore', count = 10}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'stone', count = 10}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'coal', count = 10}},
    {price = {{ name = 'raw-fish', count = 1}}, offer = {type = 'give-item', item = 'uranium-ore', count = 5}},
    {price = {{ name = 'wood', count = 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{ name = 'iron-ore', count = 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{ name = 'copper-ore', count = 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{ name = 'stone', count = 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{ name = 'coal', count = 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{ name = 'uranium-ore', count = 7}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}}
}

Public.pickaxe_tiers = {
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
    'Netherite',
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

return Public
