local public = {}

public.player_ship_loot = {
   {
      name = "piercing-rounds-magazine",
      count = 35,
   },
   {
      name = "grenade",
      count = 2,
   },
   {
      name = "submachine-gun",
      count = 1,
   },
   {
      name = "light-armor",
      count = 1,
   },
   {
      name = "iron-plate",
      count = 30,
   },
   {
      name = "copper-plate",
      count = 10,
   },
   {
      name = "raw-fish",
      count = 2,
   },
   {
      name = "small-lamp",
      count = 1
   }
}

public.self_explode = 60 * 60 * 10

public.wreck_loot = {
   ["iron-plate"] = {
      rare = 0.1,
      count = { 20, 40 },
   },
   ["copper-plate"] = {
      rare = 0.1,
      count = { 10, 30 },
   },
   ["empty-barrel"] = {
      rare = 0.4,
      count = { 1, 1},
   },
   ["copper-cable"] = {
      rare = 0.5,
      count = { 5, 20 },
   },
   ["electronic-circuit"] = {
      rare = 0.6,
      count = { 5, 20 },
   },
   ["firearm-magazine"] = {
      rare = 0.4,
      count = { 1, 2 },
   },
   ["steel-plate"] = {
      rare = 0.8,
      count = { 1, 5 },
   },
   ["explosives"] = {
      rare = 0.85,
      count = { 1, 5 },
   },
   ["advanced-circuit"] = {
      rare = 0.9,
      count = { 1, 5 },
   },
   ["processing-unit"] = {
      rare = 0.95,
      count = { 1, 2 },
   },
   ["electric-engine-unit"] = {
      rare = 0.95,
      count = { 1, 1 },
   },
   ["battery"] = {
      rare = 0.95,
      count = { 1, 2 },
   },
   ["piercing-rounds-magazine"] = {
      rare = 0.99,
      count = { 1, 2 },
   },
}

public.technologies = {
   ["military"] = true,
   ["artillery"] = false,
   ["artillery-shell-range-1"] = false,
   ["artillery-shell-speed-1"] = false,
   ["automation-3"] = false,
   ["battery-equipment"] = false,
   ["battery-mk2-equipment"] = false,
   ["belt-immunity-equipment"] = false,
   ["combat-robotics-2"] = false,
   ["combat-robotics-3"] = false,
   ["discharge-defense-equipment"] = false,
   ["energy-shield-equipment"] = false,
   ["energy-shield-mk2-equipment"] = false,
   ["exoskeleton-equipment"] = false,
   ["explosive-rocketry"] = false,
   ["flamethrower"] = false,
   ["fusion-reactor-equipment"] = false,
   ["kovarex-enrichment-process"] = false,
   ["land-mine"] = false,
   ["logistics-3"] = false,
   ["military-4"] = false,
   ["modular-armor"] = false,
   ["night-vision-equipment"] = false,
   ["nuclear-fuel-reprocessing"] = false,
   ["nuclear-power"] = false,
   ["personal-laser-defense-equipment"] = false,
   ["personal-roboport-equipment"] = false,
   ["personal-roboport-mk2-equipment"] = false,
   ["power-armor"] = false,
   ["power-armor-mk2"] = false,
   ["refined-flammables-1"] = false,
   ["refined-flammables-2"] = false,
   ["refined-flammables-3"] = false,
   ["refined-flammables-4"] = false,
   ["refined-flammables-5"] = false,
   ["refined-flammables-6"] = false,
   ["refined-flammables-7"] = false,
   ["rocketry"] = false,
   ["solar-panel-equipment"] = false,
   ["stack-inserter"] = false,
   ["stronger-explosives-2"] = false,
   ["stronger-explosives-3"] = false,
   ["stronger-explosives-4"] = false,
   ["stronger-explosives-5"] = false,
   ["stronger-explosives-6"] = false,
   ["stronger-explosives-7"] = false,
   ["physical-projectile-damage-4"] = false,
   ["physical-projectile-damage-5"] = false,
   ["physical-projectile-damage-6"] = false,
   ["physical-projectile-damage-7"] = false,
   ["weapon-shooting-speed-4"] = false,
   ["weapon-shooting-speed-5"] = false,
   ["weapon-shooting-speed-6"] = false,
   ["energy-weapons-damage-1"] = false,
   ["energy-weapons-damage-2"] = false,
   ["energy-weapons-damage-3"] = false,
   ["energy-weapons-damage-4"] = false,
   ["energy-weapons-damage-5"] = false,
   ["energy-weapons-damage-6"] = false,
   ["energy-weapons-damage-7"] = false,
   ["laser-turret-speed-2"] = false,
   ["laser-turret-speed-3"] = false,
   ["laser-turret-speed-4"] = false,
   ["laser-turret-speed-5"] = false,
   ["laser-turret-speed-6"] = false,
   ["laser-turret-speed-7"] = false,
   ["follower-robot-count-3"] = false,
   ["follower-robot-count-4"] = false,
   ["follower-robot-count-5"] = false,
   ["follower-robot-count-6"] = false,
   ["follower-robot-count-7"] = false,
   ["tanks"] = false,
   ["uranium-ammo"] = false,
   ["uranium-processing"] = false,
   ["atomic-bomb"] = false,
}

public.merchant_offer = {
   {
      price = {
         {
            type = "item",
            name = "iron-plate",
            amount = 10
         },
         {
            type = "item",
            name = "advanced-circuit",
            amount = 2
         },
         {
            type = "item",
            name = "battery",
            amount = 2
         },
         {
            type = "item",
            name = "small-lamp",
            amount = 2
         },
         {
            type = "item",
            name = "copper-cable",
            amount = 5
         },
         {
            type = "item",
            name = "steel-plate",
            amount = 1
         },
      },
      offer = {
         type = "nothing",
         effect_description = "Construct a GPS receiver"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 100
         }
      },
      offer = {
         type = "give-item",
         item = "heavy-armor"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 500
         }
      },
      offer = {
         type = "give-item",
         item = "modular-armor"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 12000
         }
      },
      offer = {
         type = "give-item",
         item = "power-armor"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 100
         }
      },
      offer = {
         type = "give-item",
         item = "night-vision-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 70
         }
      },
      offer = {
         type = "give-item",
         item = "battery-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 300
         }
      },
      offer = {
         type = "give-item",
         item = "battery-mk2-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 700
         }
      },
      offer = {
         type = "give-item",
         item = "exoskeleton-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 2500
         }
      },
      offer = {
         type = "give-item",
         item = "fusion-reactor-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 200
         }
      },
      offer = {
         type = "give-item",
         item = "personal-roboport-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 400
         }
      },
      offer = {
         type = "give-item",
         item = "personal-roboport-mk2-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 90
         }
      },
      offer = {
         type = "give-item",
         item = "solar-panel-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 300
         }
      },
      offer = {
         type = "give-item",
         item = "energy-shield-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 2000
         }
      },
      offer = {
         type = "give-item",
         item = "energy-shield-mk2-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 50
         }
      },
      offer = {
         type = "give-item",
         item = "flamethrower-ammo"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 1
         }
      },
      offer = {
         type = "give-item",
         item = "firearm-magazine"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 5
         }
      },
      offer = {
         type = "give-item",
         item = "piercing-rounds-magazine"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 1000
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "flamethrower"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 50
         }
      },
      offer = {
         type = "give-item",
         item = "defender-capsule"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 200
         }
      },
      offer = {
         type = "give-item",
         item = "distractor-capsule"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 250
         }
      },
      offer = {
         type = "give-item",
         item = "destroyer-capsule"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 70
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "filter-inserter"
      },
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 100
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "stack-inserter"
      },
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 170
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "stack-filter-inserter"
      },
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 65000
         }
      },
      offer = {
         type = "give-item",
         item = "computer"
      }
   },
}

public.manual = [[
[font=heading-1]Planet Prison (1.0.5) - Manual[/font]
[font=default-bold]You did naughty things and was sent to this planet with a one way ticket. Once an industrial site, turned into non-hospitable planet due to pollution and war. Among other inmates, there are still bandits scavenging through the junk looking for rare items.

This is an ultimate survival scenario with very hostile environment.
- You die, you lose everything.
- You leave, you lose everything.
- Technology cost is 10x lower.
- The merchant is a gateway to PvP.
- Flee by a rocket is a win. (Put a car into a rocket and enter the rocket).
- The light is your best friend.
[/font]
[font=heading-1]NAP contractors (A non-aggression pact)[/font]
[font=default-bold]Grab a raw fish [img=item/raw-fish] and drop it on someone with [virtual-signal=signal-Z] button (in default setting). This way you request an inmate to get in NAP with you.[/font]
[font=default-bold]Grab a coal piece [img=item/coal] and drop it on someone with [virtual-signal=signal-Z] button (in default setting). This way you discard NAP with an inname.[/font]

[font=heading-1]Coins[/font]
[font=default-bold]Coins [img=item/coin] are the main medium that you use in the market. You obtain them by researching stuff and pvp activites.[/font]

[font=heading-1]Other[/font]
[font=default-bold]This scenario was made by cogito123. If you find any bugs/balancing issues, report it to getcomfy.eu/discord. Thanks for playing this map.[/font]
]]

return public
