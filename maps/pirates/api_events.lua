-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Memory = require("maps.pirates.memory")
local Balance = require("maps.pirates.balance")
local Math = require("maps.pirates.math")
local Common = require("maps.pirates.common")
local SurfacesCommon = require("maps.pirates.surfaces.common")
local CoreData = require("maps.pirates.coredata")
local Utils = require("maps.pirates.utils_local")
local _inspect = require("utils.inspect").inspect
local Ai = require("maps.pirates.ai")
-- local Structures = require 'maps.pirates.structures.structures'
local Boats = require("maps.pirates.structures.boats.boats")
local Surfaces = require("maps.pirates.surfaces.surfaces")
-- local Progression = require 'maps.pirates.progression'
local IslandEnum = require("maps.pirates.surfaces.islands.island_enum")
local Roles = require("maps.pirates.roles.roles")
local Permissions = require("maps.pirates.permissions")
-- local Gui = require 'maps.pirates.gui.gui'
-- local Sea = require 'maps.pirates.surfaces.sea.sea'
-- local Hold = require 'maps.pirates.surfaces.hold'
-- local Cabin = require 'maps.pirates.surfaces.cabin'
-- local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
-- local Ores = require 'maps.pirates.ores'
-- local Parrot = require 'maps.pirates.parrot'
local Kraken = require("maps.pirates.surfaces.sea.kraken")
local Jailed = require("utils.datastore.jail_data")
local Crew = require("maps.pirates.crew")
local Quest = require("maps.pirates.quest")
local Shop = require("maps.pirates.shop.shop")
local Loot = require("maps.pirates.loot")
local Task = require("utils.task")
local Token = require("utils.token")
local Classes = require("maps.pirates.roles.classes")
local Ores = require("maps.pirates.ores")
local Server = require("utils.server")
-- local Modifers = require 'player_modifiers'
local GuiWelcome = require("maps.pirates.gui.welcome")

local tick_tack_trap = require("maps.pirates.locally_maintained_comfy_forks.tick_tack_trap") --'enemy' force, but that's okay

local Public = {}

function Public.silo_die()
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()
    local force = memory.force
    if memory.game_lost == true then
        return
    end

    destination.dynamic_data.rocketsilohp = 0
    if
        destination.dynamic_data.rocketsilos
        and destination.dynamic_data.rocketsilos[1]
        and destination.dynamic_data.rocketsilos[1].valid
    then
        local surface = destination.dynamic_data.rocketsilos[1].surface
        surface.create_entity({
            name = "big-artillery-explosion",
            position = destination.dynamic_data.rocketsilos[1].position,
        })

        if memory.boat and memory.boat.surface_name and surface.name == memory.boat.surface_name then
            if CoreData.rocket_silo_death_causes_loss then
                -- Crew.lose_life()
                Crew.try_lose({ "pirates.loss_silo_destroyed" })
            elseif not destination.dynamic_data.rocket_launched then
                if
                    destination.static_params
                    and destination.static_params.base_cost_to_undock
                    and destination.static_params.base_cost_to_undock["launch_rocket"] == true
                then
                    Crew.try_lose({ "pirates.loss_silo_destroyed_before_necessary_launch" })
                else
                    Common.notify_force(force, { "pirates.silo_destroyed" })
                end
            end
        end

        destination.dynamic_data.rocketsilos[1].die()
        destination.dynamic_data.rocketsilos = nil
    end
end

local function biters_chew_stuff_faster(event)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()

    if
        not (
            event.cause
            and event.cause.valid
            and event.cause.force
            and event.cause.force.name
            and event.entity
            and event.entity.valid
            and event.entity.force
            and event.entity.force.name
        )
    then
        return
    end
    if event.cause.force.name ~= memory.enemy_force_name then
        return
    end --Enemy Forces only

    if event.entity.force.name == "neutral" or event.entity.force.name == "environment" then
        event.entity.health = event.entity.health - event.final_damage_amount * 5
        event.final_damage_amount = event.final_damage_amount * 6
        if destination and destination.type == Surfaces.enum.ISLAND and destination.subtype == IslandEnum.enum.MAZE then
            event.entity.health = event.entity.health - event.final_damage_amount
            event.final_damage_amount = event.final_damage_amount * 2
        end
    elseif event.entity.name == "pipe" then
        event.entity.health = event.entity.health - event.final_damage_amount * 0.5
        event.final_damage_amount = event.final_damage_amount * 1.5
    elseif event.entity.name == "stone-furnace" then
        event.entity.health = event.entity.health - event.final_damage_amount * 0.5
        event.final_damage_amount = event.final_damage_amount * 1.5
    elseif
        event.entity.name == "wooden-chest"
        or event.entity.name == "stone-chest"
        or event.entity.name == "steel-chest"
    then
        event.entity.health = event.entity.health - event.final_damage_amount * 0.5
        event.final_damage_amount = event.final_damage_amount * 1.5
    end
end

local function handle_damage_in_restricted_areas(event)
    -- local memory = Memory.get_crew_memory()
    local entity = event.entity

    if event.cause and event.cause.valid and entity and entity.valid then
        local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(entity.surface.name)
        -- local dest = Common.current_destination()
        if
            surfacedata.type == Surfaces.enum.CROWSNEST
            or surfacedata.type == Surfaces.enum.LOBBY
            or surfacedata.type == Surfaces.enum.CABIN
        then
            entity.health = entity.health + event.final_damage_amount
        end
    end
end

local function handle_damage_to_silo(event)
    local memory = Memory.get_crew_memory()
    local entity = event.entity

    if event.cause and event.cause.valid and entity and entity.valid and entity.force.name == memory.force_name then
        local destination = Common.current_destination()
        if
            destination.dynamic_data.rocketsilos
            and destination.dynamic_data.rocketsilos[1]
            and destination.dynamic_data.rocketsilos[1].valid
            and entity == Common.current_destination().dynamic_data.rocketsilos[1]
        then
            if string.sub(event.cause.force.name, 1, 4) ~= "crew" then -- may as well check this
                -- play alert sound for all crew members
                if memory.seconds_until_alert_sound_can_be_played_again <= 0 then
                    memory.seconds_until_alert_sound_can_be_played_again = Balance.alert_sound_max_frequency_in_seconds

                    for _, player_index in pairs(memory.crewplayerindices) do
                        local player = game.players[player_index]
                        player.play_sound({ path = "utility/alert_destroyed", volume_modifier = 1 })
                    end
                end

                local damage = event.original_damage_amount
                    / Balance.silo_resistance_factor
                    * (1 + Balance.biter_timeofday_bonus_damage(event.cause.surface.darkness))
                local remaining_health = Common.entity_damage_healthbar(entity, damage, destination.dynamic_data)
                if remaining_health and remaining_health <= 0 then
                    Public.silo_die()
                else
                    destination.dynamic_data.rocketsilohp = remaining_health
                end
            else
                entity.health = entity.prototype.max_health
            end
        end
    end
end

local function handle_damage_to_enemyboat_spawners(event)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()

    if
        destination.dynamic_data.enemyboats
        and #destination.dynamic_data.enemyboats > 0
        and event.entity
        and event.entity.valid
        and event.entity.force.name == memory.enemy_force_name
    then
        for i = 1, #destination.dynamic_data.enemyboats do
            local eb = destination.dynamic_data.enemyboats[i]
            if eb.spawner and eb.spawner.valid and event.entity == eb.spawner then
                -- if eb.spawner and eb.spawner.valid and event.entity == eb.spawner and eb.state == Structures.Boats.enum_state.APPROACHING then
                local damage = event.final_damage_amount
                local remaining_health = Common.entity_damage_healthbar(event.entity, damage)

                if remaining_health and remaining_health <= 0 then
                    event.entity.die()
                end
            end
        end
    end
end

-- Does not include krakens or biter boat spawners
local function handle_damage_to_elite_spawners(event)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()

    if
        destination.dynamic_data.elite_spawners
        and #destination.dynamic_data.elite_spawners > 0
        and event.entity
        and event.entity.valid
        and event.entity.force.name == memory.enemy_force_name
    then
        for i = 1, #destination.dynamic_data.elite_spawners do
            local spawner = destination.dynamic_data.elite_spawners[i]
            if spawner and spawner.valid and event.entity == spawner then
                local damage = event.final_damage_amount

                local remaining_health = Common.entity_damage_healthbar(event.entity, damage)

                if remaining_health and remaining_health <= 0 then
                    event.entity.die()
                end
            end
        end
    end
end

local function handle_damage_to_elite_biters(event)
    local memory = Memory.get_crew_memory()

    local elite_biters = memory.elite_biters
    if elite_biters and event.entity and event.entity.valid and event.entity.force.name == memory.enemy_force_name then
        if elite_biters[event.entity.unit_number] then
            local damage = event.final_damage_amount

            local remaining_health = Common.entity_damage_healthbar(event.entity, damage)

            if remaining_health and remaining_health <= 0 then
                event.entity.die()
            end
        end
    end
end

local function handle_damage_to_artillery(event)
    local memory = Memory.get_crew_memory()

    if not (event.entity and event.entity.valid and event.entity.name and event.entity.name == "artillery-turret") then
        return
    end

    if
        event.cause
        and event.cause.valid
        and event.cause.name
        and Utils.contains(CoreData.enemy_units, event.cause.name)
    then
        if event.cause.force.name ~= memory.enemy_force_name then
            return
        end

        -- play alert sound for all crew members
        if memory.seconds_until_alert_sound_can_be_played_again <= 0 then
            memory.seconds_until_alert_sound_can_be_played_again = Balance.alert_sound_max_frequency_in_seconds

            for _, player_index in pairs(memory.crewplayerindices) do
                local player = game.players[player_index]
                player.play_sound({ path = "utility/alert_destroyed", volume_modifier = 1 })
            end
        end

        -- remove resistances:
        -- event.entity.health = event.entity.health + event.final_damage_amount - event.original_damage_amount

        local damage = event.original_damage_amount / Balance.cannon_resistance_factor
        damage = damage * (1 + Balance.biter_timeofday_bonus_damage(event.cause.surface.darkness))
        local remaining_health = Common.entity_damage_healthbar(event.entity, damage, memory.boat)

        if remaining_health and remaining_health <= 0 then
            event.entity.die()
        end
    else
        event.entity.health = event.entity.prototype.max_health --nothing else should damage it
    end
end

local function handle_damage_to_krakens(event)
    if not event.entity then
        return
    end
    if not event.entity.valid then
        return
    end
    if not event.entity.name then
        return
    end
    if event.entity.name ~= "biter-spawner" then
        return
    end

    local memory = Memory.get_crew_memory()

    if event.entity.force.name ~= memory.enemy_force_name then
        return
    end

    local surface_name = memory.boat and memory.boat.surface_name
    if surface_name ~= memory.sea_name then
        return
    end

    local unit_number = event.entity.unit_number

    if event.damage_type.name and event.damage_type.name == "poison" then
        event.final_damage_amount = event.final_damage_amount / 1.25
    elseif event.damage_type.name and (event.damage_type.name == "explosion") then
        event.final_damage_amount = event.final_damage_amount / 1.5
    elseif event.damage_type.name and (event.damage_type.name == "fire") then
        event.final_damage_amount = event.final_damage_amount / 1.25
    end
    -- and additionally:
    if event.cause and event.cause.valid and event.cause.name == "artillery-turret" then
        event.final_damage_amount = event.final_damage_amount / 1.5
    end

    if event.damage_type.name and (event.damage_type.name == "laser") then
        event.final_damage_amount = event.final_damage_amount / 7 --laser turrets are in range. give some resistance
    end

    -- There should be a better way to do it than this...
    if memory.healthbars and memory.healthbars[unit_number] then
        local kraken_id = memory.healthbars[unit_number].id
        local remaining_health = Common.entity_damage_healthbar(event.entity, event.final_damage_amount)
        if remaining_health and remaining_health <= 0 then
            Kraken.kraken_die(kraken_id)
        end
    end
end

local function handle_damage_to_players(event)
    local memory = Memory.get_crew_memory()

    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if not event.cause.name then
        return
    end

    -- if not (event.cause.name == 'small-biter') or (event.cause.name == 'small-spitter') or (event.cause.name == 'medium-biter') or (event.cause.name == 'medium-spitter') or (event.cause.name == 'big-biter') or (event.cause.name == 'big-spitter') or (event.cause.name == 'behemoth-biter') or (event.cause.name == 'behemoth-spitter') then return end

    if not (event.entity and event.entity.valid and event.entity.name and event.entity.name == "character") then
        return
    end

    if not event.entity.player or not event.entity.player.valid then
        return
    end

    local player_index = event.entity.player.index
    local player = game.players[player_index]

    if not player then
        return
    end
    if not player.valid then
        return
    end
    if not player.character then
        return
    end
    if not player.character.valid then
        return
    end

    local class = Classes.get_class(player_index)
    local damage_multiplier = 1

    --game.print('on damage info: {name: ' .. event.damage_type.name .. ', object_name: ' .. event.damage_type.object_name .. '}')

    if event.damage_type.name == "poison" then --make all poison damage stronger against players
        damage_multiplier = damage_multiplier * Balance.poison_damage_multiplier
    else
        if class then
            if class == Classes.enum.SCOUT then
                damage_multiplier = damage_multiplier * Balance.scout_damage_taken_multiplier
                -- merchant is disabled
                -- elseif class == Classes.enum.MERCHANT then
                -- 	damage_multiplier = damage_multiplier * 1.10
            elseif class == Classes.enum.SAMURAI then
                damage_multiplier = damage_multiplier * Balance.samurai_damage_taken_multiplier
            elseif class == Classes.enum.HATAMOTO then
                damage_multiplier = damage_multiplier * Balance.hatamoto_damage_taken_multiplier
            elseif class == Classes.enum.ROCK_EATER then
                damage_multiplier = damage_multiplier * Balance.rock_eater_damage_taken_multiplier
            elseif class == Classes.enum.IRON_LEG then
                if
                    memory.class_auxiliary_data[player_index]
                    and memory.class_auxiliary_data[player_index].iron_leg_active
                then
                    damage_multiplier = damage_multiplier * Balance.iron_leg_damage_taken_multiplier
                end
            elseif class == Classes.enum.VETERAN then
                local chance = Balance.veteran_on_hit_slow_chance
                if Math.random() <= chance then
                    -- only certain targets accept stickers
                    if Utils.contains(CoreData.enemy_units, event.cause.name) then
                        player.surface.create_entity({
                            name = "slowdown-sticker",
                            position = player.character.position,
                            speed = 1.5,
                            force = player.force,
                            target = event.cause,
                        })
                    end
                end
                -- else
                -- 	damage_multiplier = damage_multiplier * (1 + Balance.bonus_damage_to_humans())
            end
        end
    end

    if event.cause.force.name == memory.enemy_force_name then
        damage_multiplier = damage_multiplier * (1 + Balance.biter_timeofday_bonus_damage(event.cause.surface.darkness))
    end --Enemy Forces

    -- game.print('name: ' .. event.cause.name .. ' damage: ' .. event.final_damage_amount)
    -- game.print('multiplier: ' .. damage_multiplier)

    if damage_multiplier > 1 then
        event.entity.health = event.entity.health - event.final_damage_amount * (damage_multiplier - 1)
    elseif damage_multiplier < 1 and event.final_health > 0 then --lethal damage case isn't this easy
        event.entity.health = event.entity.health + event.final_damage_amount * (1 - damage_multiplier)
    end

    -- deal with damage reduction on lethal damage for players
    -- Piratux wrote this — it tracks player health (except passive regen), and intervenes on a lethal damage event, should work most of the time.
    local global_memory = Memory.get_global_memory()

    if damage_multiplier < 1 and event.final_health <= 0 then
        local damage_dealt = event.final_damage_amount * damage_multiplier
        if damage_dealt < global_memory.last_players_health[player_index] then
            event.entity.health = global_memory.last_players_health[player_index] - damage_dealt
        end
    end

    global_memory.last_players_health[player_index] = event.entity.health
end

local function handle_enemy_nighttime_damage_bonus(event)
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if not event.cause.name then
        return
    end
    if not event.cause.surface then
        return
    end
    if not event.cause.surface.valid then
        return
    end

    if event.entity.name == "character" then
        return
    end

    if event.damage_type.name == "impact" then
        return
    end --avoid circularity

    local memory = Memory.get_crew_memory()

    -- if not (event.cause.name == 'small-biter') or (event.cause.name == 'small-spitter') or (event.cause.name == 'medium-biter') or (event.cause.name == 'medium-spitter') or (event.cause.name == 'big-biter') or (event.cause.name == 'big-spitter') or (event.cause.name == 'behemoth-biter') or (event.cause.name == 'behemoth-spitter') then return end
    if event.cause.force.name ~= memory.enemy_force_name then
        return
    end --Enemy Forces

    local bonusDamage = event.final_damage_amount * Balance.biter_timeofday_bonus_damage(event.cause.surface.darkness)

    if bonusDamage > 0 then
        event.entity.damage(bonusDamage, event.cause.force, "impact", event.cause)
    end
end

local function handle_damage_dealt_by_players(event)
    local memory = Memory.get_crew_memory()

    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if not event.entity.valid then
        return
    end
    if event.cause.name ~= "character" then
        return
    end
    if event.entity.name == "character" then
        return
    end

    local character = event.cause
    local player = character.player

    local physical = event.damage_type.name == "physical"
    local acid = event.damage_type.name == "acid"

    local player_index = player.index
    local class = Classes.get_class(player_index)

    -- Lethal damage must be unaffected, otherwise enemy will never die.
    -- @Future reference: when implementing damage changes for mobs with healthbar, make this check with healthbar health too
    if event.final_health > 0 then
        if physical then
            -- QUARTERMASTER BUFFS
            local nearby_players = player.surface.find_entities_filtered({
                position = player.position,
                radius = Balance.quartermaster_range,
                type = { "character" },
            })

            for _, p2 in pairs(nearby_players) do
                if p2.player and p2.player.valid then
                    local p2_index = p2.player.index
                    if event.entity.valid and Classes.get_class(p2_index) == Classes.enum.QUARTERMASTER then
                        -- event.entity.damage((Balance.quartermaster_bonus_physical_damage - 1) * event.final_damage_amount, character.force, 'impact', character) --triggers this function again, but not physical this time
                        Common.damage_hostile_entity(
                            event.entity,
                            (Balance.quartermaster_bonus_physical_damage - 1) * event.final_damage_amount
                        )
                        event.final_damage_amount = event.final_damage_amount
                            * Balance.quartermaster_bonus_physical_damage
                    end
                end
            end

            -- PISTOL BUFFS
            if character.shooting_state.state ~= defines.shooting.not_shooting then
                local weapon = character.get_inventory(defines.inventory.character_guns)[character.selected_gun_index]
                local ammo = character.get_inventory(defines.inventory.character_ammo)[character.selected_gun_index]
                if
                    event.entity.valid
                    and weapon.valid_for_read
                    and ammo.valid_for_read
                    and weapon.name == "pistol"
                    and (
                        ammo.name == "firearm-magazine"
                        or ammo.name == "piercing-rounds-magazine"
                        or ammo.name == "uranium-rounds-magazine"
                    )
                then
                    -- event.entity.damage((Balance.pistol_damage_multiplier() - 1) * event.final_damage_amount, character.force, 'impact', character) --triggers this function again, but not physical this time
                    Common.damage_hostile_entity(
                        event.entity,
                        (Balance.pistol_damage_multiplier() - 1) * event.final_damage_amount
                    )
                    event.final_damage_amount = event.final_damage_amount * Balance.pistol_damage_multiplier()
                end
            end
        end

        if class and class == Classes.enum.SCOUT then
            -- event.entity.health = event.entity.health + (1 - Balance.scout_damage_dealt_multiplier) * event.final_damage_amount
            Common.damage_hostile_entity(
                event.entity,
                -(1 - Balance.scout_damage_dealt_multiplier) * event.final_damage_amount
            )
            event.final_damage_amount = event.final_damage_amount * Balance.scout_damage_dealt_multiplier
        elseif class and (class == Classes.enum.SAMURAI or class == Classes.enum.HATAMOTO) then
            local samurai = class == Classes.enum.SAMURAI
            local hatamoto = class == Classes.enum.HATAMOTO

            local no_weapon = not (
                character.get_inventory(defines.inventory.character_guns)
                and character.get_inventory(defines.inventory.character_guns)[character.selected_gun_index]
                and character.get_inventory(defines.inventory.character_guns)[character.selected_gun_index].valid_for_read
            )

            local melee = (physical or acid) and no_weapon

            local extra_damage_to_deal = 0

            local big_number = 1000

            local extra_physical_damage_from_research_multiplier = 1 + memory.force.get_ammo_damage_modifier("bullet")

            if melee then
                if physical then
                    if samurai then
                        extra_damage_to_deal = Balance.samurai_damage_dealt_with_melee
                            * extra_physical_damage_from_research_multiplier
                    elseif hatamoto then
                        extra_damage_to_deal = Balance.hatamoto_damage_dealt_with_melee
                            * extra_physical_damage_from_research_multiplier
                    end
                elseif acid then --this hacky stuff is to implement repeated spillover splash damage, whilst getting around the fact that if overkill damage takes something to zero health, we can't tell in that event how much double-overkill damage should be dealt by reading off its HP. This code assumes that characters only deal acid damage via this function.
                    extra_damage_to_deal = event.original_damage_amount * big_number
                end
            else
                if samurai then
                    -- event.entity.health = event.entity.health + (1 - Balance.samurai_damage_dealt_when_not_melee_multiplier) * event.final_damage_amount
                    Common.damage_hostile_entity(
                        event.entity,
                        -(1 - Balance.samurai_damage_dealt_when_not_melee_multiplier) * event.final_damage_amount
                    )
                    event.final_damage_amount = event.final_damage_amount
                        * Balance.samurai_damage_dealt_when_not_melee_multiplier
                elseif hatamoto then
                    -- event.entity.health = event.entity.health + (1 - Balance.hatamoto_damage_dealt_when_not_melee_multiplier) * event.final_damage_amount
                    Common.damage_hostile_entity(
                        event.entity,
                        -(1 - Balance.hatamoto_damage_dealt_when_not_melee_multiplier) * event.final_damage_amount
                    )
                    event.final_damage_amount = event.final_damage_amount
                        * Balance.hatamoto_damage_dealt_when_not_melee_multiplier
                end
            end

            -- @TODO: This should preferably be reworked, so that "event_on_entity_damaged()" could be simpler by just returning multiplier, although doing AoE is quite fun.
            -- @TODO: "event.entity.health >= extra_damage_to_deal" is pointless when enemy has virtual healthbar
            if extra_damage_to_deal > 0 then
                if event.entity.health >= extra_damage_to_deal then
                    -- event.entity.damage(extra_damage_to_deal, character.force, 'impact', character) --using .damage rather than subtracting from health directly plays better with entities which use healthbars
                    Common.damage_hostile_entity(event.entity, extra_damage_to_deal)
                    event.final_damage_amount = event.final_damage_amount + extra_damage_to_deal
                else
                    local surplus = (extra_damage_to_deal - event.entity.health) * 0.8
                    event.entity.die(character.force, character)
                    local nearest = player.surface.find_nearest_enemy({
                        position = player.position,
                        max_distance = 2,
                        force = player.force,
                    })
                    if nearest and nearest.valid then
                        nearest.damage(surplus / big_number, character.force, "acid", character)
                    end
                end
            end
        end
    end
end

local function handle_poison_resistance_in_swamp(event)
    local memory = Memory.get_crew_memory()

    local entity = event.entity
    if not entity.valid then
        return
    end

    if not (event.damage_type.name and event.damage_type.name == "poison") then
        return
    end

    local destination = Common.current_destination()
    if not (destination and destination.subtype == IslandEnum.enum.SWAMP) then
        return
    end

    if destination.surface_name ~= entity.surface.name then
        return
    end

    if
        not (
            (entity.type and entity.type == "tree")
            or (event.entity.force and event.entity.force.name == memory.enemy_force_name)
        )
    then
        return
    end

    event.entity.health = event.entity.health + event.final_damage_amount
    event.final_damage_amount = 0
end

local function handle_maze_walls_damage_resistance(event)
    -- local memory = Memory.get_crew_memory()

    local entity = event.entity
    if not entity.valid then
        return
    end

    local destination = Common.current_destination()
    if not (destination and destination.subtype == IslandEnum.enum.MAZE) then
        return
    end

    if destination.surface_name ~= entity.surface.name then
        return
    end

    if
        not (
            (entity.type and entity.type == "tree")
            or entity.name == "huge-rock"
            or entity.name == "big-rock"
            or entity.name == "big-sand-rock"
        )
    then
        return
    end

    if event.damage_type.name and (event.damage_type.name == "explosion" or event.damage_type.name == "poison") then
        event.entity.health = event.entity.health + event.final_damage_amount
        event.final_damage_amount = 0
    elseif event.damage_type.name and event.damage_type.name == "fire" then
        -- put out forest fires:
        for _, e2 in
            pairs(
                entity.surface.find_entities_filtered({
                    area = {
                        { entity.position.x - 4, entity.position.y - 4 },
                        { entity.position.x + 4, entity.position.y + 4 },
                    },
                    name = "fire-flame-on-tree",
                })
            )
        do
            if e2.valid then
                e2.destroy()
            end
        end
    else
        if event.cause and event.cause.valid then
            if string.sub(event.cause.force.name, 1, 4) == "crew" then --player damage only
                event.entity.health = event.entity.health + event.final_damage_amount * 0.9
                event.final_damage_amount = event.final_damage_amount * 0.1
            end
        end
    end
end

-- functions like this need to be rewritten so they play nicely with healthbars:
-- local function damage_to_enemies(event)
-- 	local memory = Memory.get_crew_memory()

-- 	if not (event.entity and event.entity.valid and event.entity.force and event.entity.force.valid) then return end

-- 	if event.entity.force.name ~= memory.enemy_force_name then return end
-- 	local evo = memory.evolution_factor

-- 	if evo and evo > 1 and event.final_health > 0 then --lethal damage needs to be unaffected, else they never die

-- 		local surplus = evo - 1

-- 		local damage_multiplier = 1/(1 + Common.surplus_evo_biter_health_fractional_modifier(surplus))

-- 		if damage_multiplier < 1 then
-- 			event.entity.health = event.entity.health + event.final_damage_amount * (1 - damage_multiplier)
-- 		end
-- 	end

-- 	-- commented out as this is done elsewhere:
-- 	-- if event.damage_type.name == 'poison' then
-- 	-- 		event.entity.health = event.entity.health + event.final_damage_amount
-- 	-- end
-- end

-- @TODO: Possible rework solution: "event_on_entity_damaged()" should accumulate final damage dealt multiplier, and "fix" entity health or deal proper damage to virtual healthbar at the very end of the function. Entity deaths should be handled at "event_on_entity_died()" instead, to avoid the mess.
-- NOTE: "event.cause" may not always be provided.
-- However, special care needs to be taken when "event.cause" is nil and entity has healthbar (better not ignore such damage or it can cause issues, such as needing to handle their death on "entity_died" functions as opposed to here)
local function event_on_entity_damaged(event)
    local crew_id = nil
    if not crew_id and event.entity.surface.valid then
        crew_id = SurfacesCommon.decode_surface_name(event.entity.surface.name).crewid
    end
    if not crew_id and event.force.valid then
        crew_id = Common.get_id_from_force_name(event.force.name)
    end
    if not crew_id and event.entity.valid then
        crew_id = Common.get_id_from_force_name(event.entity.force.name)
    end
    Memory.set_working_id(crew_id)

    -- local memory = Memory.get_crew_memory()
    -- local difficulty = memory.difficulty

    if not event.entity.valid then
        return
    end

    handle_damage_to_silo(event)
    handle_damage_to_krakens(event)
    handle_damage_to_enemyboat_spawners(event)
    handle_damage_to_elite_spawners(event)
    handle_damage_to_elite_biters(event)
    handle_damage_to_artillery(event)
    handle_damage_in_restricted_areas(event)

    if not (event.entity.valid and event.entity.health) then
        return
    end -- need to call again, healthbar'd object might have been killed by script, so we shouldn't proceed now

    handle_damage_to_players(event)

    handle_enemy_nighttime_damage_bonus(event)

    if not (event.entity.valid and event.entity.health) then
        return
    end -- need to call again, healthbar'd object might have been killed by script, so we shouldn't proceed now

    biters_chew_stuff_faster(event)

    if not (event.entity.valid and event.entity.health) then
        return
    end -- need to call again, healthbar'd object might have been killed by script, so we shouldn't proceed now

    handle_poison_resistance_in_swamp(event)
    handle_maze_walls_damage_resistance(event)

    handle_damage_dealt_by_players(event)

    -- damage_to_enemies(event)
end

function Public.load_some_map_chunks(destination_index, fraction, force_load) --in a 'spear' from the left
    --WARNING: if force_load is true, THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(_inspect{global_memory.working_id}) was observed to vary before and after this function.
    force_load = force_load or false

    local memory = Memory.get_crew_memory()

    local destination_data = memory.destinations[destination_index]
    if not destination_data then
        return
    end
    local surface_name = destination_data.surface_name
    if not surface_name then
        return
    end
    local surface = game.surfaces[surface_name]
    if not surface then
        return
    end

    local w, h = surface.map_gen_settings.width, surface.map_gen_settings.height
    local c = { x = 0, y = 0 }
    if destination_data.static_params and destination_data.static_params.islandcenter_position then
        c = destination_data.static_params.islandcenter_position
        w = w - 2 * Math.abs(c.x)
        h = h - 2 * Math.abs(c.y)
    end
    local l = Math.max(Math.floor(w / 32), Math.floor(h / 32))

    local i, j, s = 0, 0, { x = 0, y = 0 }
    while i < 4 * l ^ 2 and j <= fraction * w / 32 * h / 32 do
        i = i + 1

        if s.y < 0 then
            s.y = -s.y
        elseif s.y > 0 then
            s = { x = s.x + 1, y = 1 - s.y }
        else
            s = { x = 0, y = -(s.x + 1) }
        end

        if s.x <= w / 32 and s.y <= h / 32 / 2 and s.y >= -h / 32 / 2 then
            surface.request_to_generate_chunks({ x = c.x - w / 2 + 32 * s.x, y = c.y + 32 * s.y }, 0.1)
            j = j + 1
        end
    end
    if force_load then
        surface.force_generate_chunk_requests() --WARNING: THIS DOES NOT PLAY NICELY WITH DELAYED TASKS. log(_inspect{global_memory.working_id}) was observed to vary before and after this function.
    end
end

function Public.load_some_map_chunks_random_order(surface, destination_data, fraction) -- The reason we might want to do this is because of algorithms like the labyrinth code, which make directionally biased patterns if you don't generate chunks in a random order
    if not surface then
        return
    end
    if not destination_data then
        return
    end

    local shuffled_chunks
    if not destination_data.dynamic_data then
        destination_data.dynamic_data = {}
    end
    if not destination_data.dynamic_data.shuffled_chunks then
        local w, h = surface.map_gen_settings.width, surface.map_gen_settings.height
        local c = { x = 0, y = 0 }
        if destination_data.static_params and destination_data.static_params.islandcenter_position then
            c = destination_data.static_params.islandcenter_position
            w = w - 2 * Math.abs(c.x)
            h = h - 2 * Math.abs(c.y)
        end

        local chunks_list = {}
        for i = 0, Math.ceil(w / 32 - 1), 1 do
            for j = 0, Math.ceil(h / 32 - 1), 1 do
                table.insert(chunks_list, { x = c.x - w / 2 + 32 * i, y = c.y - h / 2 + 32 * j })
            end
        end

        destination_data.dynamic_data.shuffled_chunks = Math.shuffle(chunks_list)
    end
    shuffled_chunks = destination_data.dynamic_data.shuffled_chunks

    for i = 1, #shuffled_chunks do
        if i > fraction * #shuffled_chunks then
            break
        end
        surface.request_to_generate_chunks(shuffled_chunks[i], 0.2)
    end
end

-- local function event_pre_player_mined_item(event)
-- 	-- figure out which crew this is about:
-- 	-- local crew_id = nil
-- 	-- if event.player_index and game.players[event.player_index].valid then crew_id = Common.get_id_from_force_name(game.players[event.player_index].force.name) end
-- 	-- Memory.set_working_id(crew_id)
-- 	-- local memory = Memory.get_crew_memory()

-- 	-- if memory.planet[1].type.id == 11 then --rocky planet
-- 	-- 	if event.entity.name == 'huge-rock' or event.entity.name == 'big-rock' or event.entity.name == 'big-sand-rock' then
-- 	-- 		Event_functions.trap(event.entity, false)
-- 	-- 		event.entity.destroy()
-- 	-- 		Event_functions.rocky_loot(event)
-- 	-- 	end
-- 	-- end
-- end

local function player_mined_tree(event)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()
    local player = game.players[event.player_index]
    local entity = event.entity
    local class = Classes.get_class(event.player_index)

    local available = destination.dynamic_data.wood_remaining
    local starting = destination.static_params.starting_wood

    if not (available and destination.type == Surfaces.enum.ISLAND) then
        return
    end

    if destination.subtype == IslandEnum.enum.MAZE then
        if Math.random(1, 38) == 1 then
            tick_tack_trap(memory.enemy_force_name, entity.surface, entity.position)
            return
        end
    end

    local give = {}

    local baseamount = 5
    --minimum 1 wood
    local amount = Math.clamp(
        1,
        Math.max(1, Math.ceil(available)),
        Math.ceil(baseamount * Balance.game_resources_scale() * available / starting)
    )

    destination.dynamic_data.wood_remaining = destination.dynamic_data.wood_remaining - amount

    give[#give + 1] = { name = "wood", count = amount }

    if class == Classes.enum.LUMBERJACK then
        Classes.lumberjack_bonus_items(give)
    else
        if Math.random(Balance.every_nth_tree_gives_coins) == 1 then --tuned
            local a = Balance.coin_amount_from_tree()
            give[#give + 1] = { name = "coin", count = a }
            memory.playtesting_stats.coins_gained_by_trees_and_rocks = memory.playtesting_stats.coins_gained_by_trees_and_rocks
                + a
        end
    end

    Common.give(player, give, entity.position)

    if destination.subtype ~= IslandEnum.enum.FIRST then
        if Math.random(512) == 1 then
            local placed = Ores.try_ore_spawn(entity.surface, entity.position, entity.name, 0, true)
            if placed then
                Common.notify_player_expected(player, { "pirates.ore_discovered" })
            end
        elseif Math.random(1024) == 1 then
            local e = entity.surface.create_entity({
                name = "wooden-chest",
                position = entity.position,
                force = memory.ancient_friendly_force_name,
            })
            if e and e.valid then
                e.minable = false
                e.rotatable = false
                e.destructible = false

                local inv = e.get_inventory(defines.inventory.chest)
                local loot = Loot.wooden_chest_loot()
                for i = 1, #loot do
                    local l = loot[i]
                    inv.insert(l)
                end

                Common.notify_player_expected(player, { "pirates.chest_discovered" })
            end
        end
    end
end

local function player_mined_fish(event)
    local memory = Memory.get_crew_memory()
    local boat = memory.boat
    local destination = Common.current_destination()
    local player = game.players[event.player_index]
    local entity = event.entity
    local class = Classes.get_class(event.player_index)

    -- Prevent dull strategy being staying in sea for long time catching as many fish as possible (as there is kind of infinite amount there)
    -- NOTE: This however doesn't prevent catching fish with inserters, but that shouldn't matter much?
    local boat_is_at_sea = Boats.is_boat_at_sea()
    local fish_caught_while_at_sea = -1
    if boat_is_at_sea and boat and boat.fish_caught_while_at_sea then
        fish_caught_while_at_sea = boat.fish_caught_while_at_sea
    end

    if
        not boat_is_at_sea
        or (boat_is_at_sea and fish_caught_while_at_sea < Balance.maximum_fish_allowed_to_catch_at_sea)
    then
        if fish_caught_while_at_sea ~= -1 then
            boat.fish_caught_while_at_sea = boat.fish_caught_while_at_sea + 1
        end

        local fish_amount = Balance.base_caught_fish_amount
        local to_give = {}

        if class == Classes.enum.FISHERMAN then
            fish_amount = fish_amount + Balance.fisherman_fish_bonus
            to_give[#to_give + 1] = { name = "raw-fish", count = fish_amount }
        elseif class == Classes.enum.MASTER_ANGLER then
            fish_amount = fish_amount + Balance.master_angler_fish_bonus
            to_give[#to_give + 1] = { name = "raw-fish", count = fish_amount }
            to_give[#to_give + 1] = { name = "coin", count = Balance.master_angler_coin_bonus }
        elseif class == Classes.enum.DREDGER then
            fish_amount = fish_amount + Balance.dredger_fish_bonus
            to_give[#to_give + 1] = { name = "raw-fish", count = fish_amount }
            to_give[#to_give + 1] = Loot.dredger_loot()[1]
        else
            to_give[#to_give + 1] = { name = "raw-fish", count = fish_amount }
        end

        Common.give(player, to_give, entity.position)

        if
            destination
            and destination.dynamic_data
            and destination.dynamic_data.quest_type
            and not destination.dynamic_data.quest_complete
        then
            if destination.dynamic_data.quest_type == Quest.enum.FISH then
                destination.dynamic_data.quest_progress = destination.dynamic_data.quest_progress + fish_amount
                Quest.try_resolve_quest()
            end
        end
    else
        Common.notify_player_error(player, { "pirates.cant_catch_fish" })
    end
end

local function player_mined_resource(event)
    local memory = Memory.get_crew_memory()
    -- local destination = Common.current_destination()
    local player = game.players[event.player_index]
    local entity = event.entity
    -- local class = Classes.get_class(event.player_index)

    local give = {}

    -- prospector and chief excavator are disabled
    -- if memory.overworldx > 0 then --no coins on first map, else the optimal strategy is to handmine everything there
    -- 	if memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.PROSPECTOR then
    -- 		local a = 3
    -- 		give[#give + 1] = {name = 'coin', count = a}
    -- 		memory.playtesting_stats.coins_gained_by_ore = memory.playtesting_stats.coins_gained_by_ore + a
    -- 		give[#give + 1] = {name = entity.name, count = 6}
    -- 	elseif memory.classes_table and memory.classes_table[event.player_index] and memory.classes_table[event.player_index] == Classes.enum.CHIEF_EXCAVATOR then
    -- 		local a = 4
    -- 		give[#give + 1] = {name = 'coin', count = a}
    -- 		memory.playtesting_stats.coins_gained_by_ore = memory.playtesting_stats.coins_gained_by_ore + a
    -- 		give[#give + 1] = {name = entity.name, count = 12}
    -- 	else
    -- 		if memory.overworldx > 0 then
    -- 			local a = 1
    -- 			give[#give + 1] = {name = 'coin', count = a}
    -- 			memory.playtesting_stats.coins_gained_by_ore = memory.playtesting_stats.coins_gained_by_ore + a
    -- 		end
    -- 		give[#give + 1] = {name = entity.name, count = 2}
    -- 	end
    -- else
    -- 	give[#give + 1] = {name = entity.name, count = 2}
    -- end

    if memory.overworldx > 0 then --no coins on first map, else the optimal strategy is to handmine everything there
        local a = 1
        give[#give + 1] = { name = "coin", count = a }
        memory.playtesting_stats.coins_gained_by_ore = memory.playtesting_stats.coins_gained_by_ore + a
    end

    local mining_bonus = player.force.mining_drill_productivity_bonus + 1

    local whole_amount = math.floor(mining_bonus)
    local fractional_part = mining_bonus - whole_amount

    local ore_amount = whole_amount
    if math.random() < fractional_part then
        ore_amount = ore_amount + 1
    end

    give[#give + 1] = { name = entity.name, count = ore_amount }

    Common.give(player, give, entity.position)
end

local function player_mined_rock(event)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()
    local player = game.players[event.player_index]
    local entity = event.entity
    -- local class = Classes.get_class(event.player_index)

    -- local available = destination.dynamic_data.rock_material_remaining
    -- local starting = destination.static_params.starting_rock_material

    -- if not (available and destination.type == Surfaces.enum.ISLAND) then return end

    if destination.subtype == IslandEnum.enum.MAZE then
        if Math.random(1, 35) == 1 then
            tick_tack_trap(memory.enemy_force_name, entity.surface, entity.position)
        end
    end

    if destination.subtype == IslandEnum.enum.CAVE then
        Ores.try_give_ore(player, entity.position, entity.name)

        if Math.random(1, 35) == 1 then
            tick_tack_trap(memory.enemy_force_name, entity.surface, entity.position)
        elseif Math.random(1, 20) == 1 then
            entity.surface.create_entity({ name = "compilatron", position = entity.position, force = memory.force })

            if
                destination
                and destination.dynamic_data
                and destination.dynamic_data.quest_type
                and not destination.dynamic_data.quest_complete
            then
                if destination.dynamic_data.quest_type == Quest.enum.COMPILATRON then
                    destination.dynamic_data.quest_progress = destination.dynamic_data.quest_progress + 1
                    Quest.try_resolve_quest()
                end
            end
        elseif Math.random(1, 10) == 1 then
            if Math.random(1, 4) == 1 then
                entity.surface.create_entity({
                    name = Common.get_random_worm_type(memory.evolution_factor),
                    position = entity.position,
                    force = memory.enemy_force_name,
                })
            else
                local biter = entity.surface.create_entity({
                    name = Common.get_random_unit_type(memory.evolution_factor),
                    position = entity.position,
                    force = memory.enemy_force_name,
                })
                Common.try_make_biter_elite(biter)
            end
        end
    else
        local c = event.buffer.get_contents()
        local c2 = {}

        if memory.overworldx >= 0 then --used to be only later levels
            if entity.name == "huge-rock" then
                local a = Math.ceil(1.5 * Balance.coin_amount_from_rock())
                c2[#c2 + 1] = { name = "coin", count = a, color = CoreData.colors.coin }
                memory.playtesting_stats.coins_gained_by_trees_and_rocks = memory.playtesting_stats.coins_gained_by_trees_and_rocks
                    + a
                if Math.random(1, 35) == 1 then
                    c2[#c2 + 1] = { name = "crude-oil-barrel", count = 1, color = CoreData.colors.oil }
                end
            else
                local a = Balance.coin_amount_from_rock()
                c2[#c2 + 1] = { name = "coin", count = a, color = CoreData.colors.coin }
                memory.playtesting_stats.coins_gained_by_trees_and_rocks = memory.playtesting_stats.coins_gained_by_trees_and_rocks
                    + a
                if Math.random(1, 35 * 3) == 1 then
                    c2[#c2 + 1] = { name = "crude-oil-barrel", count = 1, color = CoreData.colors.oil }
                end
            end
        end

        for _, item in ipairs(c) do
            if item.name == "coal" and #c2 <= 1 then --if oil, then no coal
                c2[#c2 + 1] = {
                    name = item.name,
                    count = Math.ceil(item.count * (player.force.mining_drill_productivity_bonus + 1)),
                    color = CoreData.colors.coal,
                }
            elseif item.name == "stone" then
                c2[#c2 + 1] = {
                    name = item.name,
                    count = Math.ceil(item.count * (player.force.mining_drill_productivity_bonus + 1)),
                    color = CoreData.colors.stone,
                }
            end
        end
        Common.give(player, c2, entity.position)

        -- destination.dynamic_data.rock_material_remaining = available

        if Surfaces.get_scope(destination).break_rock then
            destination.dynamic_data.ore_spawn_points_to_avoid = destination.dynamic_data.ore_spawn_points_to_avoid
                or {}
            local points_to_avoid = destination.dynamic_data.ore_spawn_points_to_avoid
            local can_place_ores = true

            -- Sometimes there can be very little amount of rocks here, so it probably isn't bad idea to spawn ore on top of another
            if destination.subtype ~= IslandEnum.enum.WALKWAYS then
                for _, pos in ipairs(points_to_avoid) do
                    if Math.distance(pos, entity.position) < Balance.min_ore_spawn_distance then
                        can_place_ores = false
                        break
                    end
                end
            end

            if can_place_ores then
                local placed = Surfaces.get_scope(destination).break_rock(entity.surface, entity.position, entity.name)
                if placed then
                    points_to_avoid[#points_to_avoid + 1] = { x = entity.position.x, y = entity.position.y }
                end
            end
        end
    end
end

local function event_on_player_mined_entity(event)
    if not event.buffer then
        return
    end
    if not event.player_index then
        return
    end

    local player = game.players[event.player_index]
    if not player.valid then
        return
    end

    local entity = event.entity
    if not entity.valid then
        return
    end

    local crew_id = Common.get_id_from_force_name(player.force.name)
    Memory.set_working_id(crew_id)

    if player.surface.name == "gulag" then
        event.buffer.clear()
        return
    end

    if entity.type == "tree" then
        player_mined_tree(event)
        event.buffer.clear()
    elseif entity.type == "fish" then
        player_mined_fish(event)
        event.buffer.clear()
    elseif
        entity.name == "coal"
        or entity.name == "stone"
        or entity.name == "copper-ore"
        or entity.name == "iron-ore"
    then
        player_mined_resource(event)
        event.buffer.clear()
    elseif entity.name == "huge-rock" or entity.name == "big-rock" or entity.name == "big-sand-rock" then
        player_mined_rock(event)
        event.buffer.clear()
    end
end

local function shred_nearby_simple_entities(entity)
    local memory = Memory.get_crew_memory()
    if memory.evolution_factor < 0.25 then
        return
    end
    local simple_entities = entity.surface.find_entities_filtered({
        type = { "simple-entity", "tree" },
        area = { { entity.position.x - 3, entity.position.y - 3 }, { entity.position.x + 3, entity.position.y + 3 } },
    })
    if #simple_entities == 0 then
        return
    end
    for i = 1, #simple_entities, 1 do
        if not simple_entities[i] then
            break
        end
        if simple_entities[i].valid then
            simple_entities[i].die(memory.enemy_force_name, simple_entities[i])
        end
    end
end

local function base_kill_rewards(event)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    if not (event.force and event.force.valid) then
        return
    end
    local entity_name = entity.name

    -- Don't give coins for friendly biter death
    if
        Utils.contains(CoreData.enemy_units, entity_name)
        and entity.force
        and entity.force.name == memory.force_name
    then
        return
    end

    local revenge_target
    if event.cause and event.cause.valid and event.cause.name == "character" then
        revenge_target = event.cause
    end

    -- This gives enemy loot straight to combat robot owner's inventory instead of dropping it on the ground
    if
        event.cause
        and (event.cause.name == "defender" or event.cause.name == "distractor" or event.cause.name == "destroyer")
    then
        if event.cause.combat_robot_owner and event.cause.combat_robot_owner.valid then
            revenge_target = event.cause.combat_robot_owner
        end
    end

    local class_is_chef = false

    if revenge_target and revenge_target.valid and revenge_target.player and revenge_target.player.index then
        class_is_chef = Classes.get_class(revenge_target.player.index) == Classes.enum.CHEF
    end

    local iron_amount
    local coin_amount
    local fish_amount

    if entity_name == "small-worm-turret" then
        iron_amount = 5
        coin_amount = 50
        fish_amount = 1 * Balance.chef_fish_received_for_worm_kill
        memory.playtesting_stats.coins_gained_by_nests_and_worms = memory.playtesting_stats.coins_gained_by_nests_and_worms
            + coin_amount
    elseif entity_name == "medium-worm-turret" then
        iron_amount = 20
        coin_amount = 90
        fish_amount = 2 * Balance.chef_fish_received_for_worm_kill
        memory.playtesting_stats.coins_gained_by_nests_and_worms = memory.playtesting_stats.coins_gained_by_nests_and_worms
            + coin_amount
    elseif entity_name == "biter-spawner" or entity_name == "spitter-spawner" then
        iron_amount = 30
        coin_amount = 100
        fish_amount = 0 -- cooking spawners don't really fit class fantasy imo
        memory.playtesting_stats.coins_gained_by_nests_and_worms = memory.playtesting_stats.coins_gained_by_nests_and_worms
            + coin_amount
    elseif entity_name == "big-worm-turret" then
        iron_amount = 30
        coin_amount = 140
        fish_amount = 2 * Balance.chef_fish_received_for_worm_kill
        memory.playtesting_stats.coins_gained_by_nests_and_worms = memory.playtesting_stats.coins_gained_by_nests_and_worms
            + coin_amount
    elseif entity_name == "behemoth-worm-turret" then
        iron_amount = 50
        coin_amount = 260
        fish_amount = 3 * Balance.chef_fish_received_for_worm_kill
        memory.playtesting_stats.coins_gained_by_nests_and_worms = memory.playtesting_stats.coins_gained_by_nests_and_worms
            + coin_amount
    elseif memory.overworldx > 0 then --avoid coin farming on first island
        if entity_name == "small-biter" then
            -- if Math.random(2) == 1 then
            -- 	coin_amount = 1
            -- end
            coin_amount = 1
            fish_amount = 0 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "small-spitter" then
            coin_amount = 1
            fish_amount = 0 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "medium-biter" then
            coin_amount = 2
            fish_amount = 1 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "medium-spitter" then
            coin_amount = 2
            fish_amount = 1 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "big-biter" then
            coin_amount = 4
            fish_amount = 2 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "big-spitter" then
            coin_amount = 4
            fish_amount = 2 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "behemoth-biter" then
            coin_amount = 8
            fish_amount = 3 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        elseif entity_name == "behemoth-spitter" then
            coin_amount = 8
            fish_amount = 3 * Balance.chef_fish_received_for_biter_kill
            memory.playtesting_stats.coins_gained_by_biters = memory.playtesting_stats.coins_gained_by_biters
                + coin_amount
        end
    end

    local stack = {}

    if iron_amount and iron_amount > 0 then
        stack[#stack + 1] = { name = "iron-plate", count = iron_amount }
    end

    if coin_amount and coin_amount > 0 then
        stack[#stack + 1] = { name = "coin", count = coin_amount }
    end

    if class_is_chef and fish_amount and fish_amount > 0 then
        stack[#stack + 1] = { name = "raw-fish", count = fish_amount }
    end

    local short_form = (not iron_amount) and true or false

    -- revenge_target.player can be nil if player kills itself
    if revenge_target and revenge_target.player then
        Common.give(
            revenge_target.player,
            stack,
            revenge_target.player.position,
            short_form,
            entity.surface,
            entity.position
        )
    else
        if event.cause and event.cause.valid and event.cause.position then
            Common.give(nil, stack, event.cause.position, short_form, entity.surface, entity.position)
        else
            Common.give(nil, stack, entity.position, short_form, entity.surface)
        end
    end

    if
        (entity_name == "biter-spawner" or entity_name == "spitter-spawner")
        and entity.position
        and entity.surface
        and entity.surface.valid
    then
        --check if its a boat biter entity
        local boat_spawner = false
        if destination.dynamic_data.enemyboats then
            for i = 1, #destination.dynamic_data.enemyboats do
                local eb = destination.dynamic_data.enemyboats[i]
                if eb.spawner and eb.spawner.valid and event.entity == eb.spawner then
                    boat_spawner = true
                    break
                end
            end
        end
        if boat_spawner then
            Ai.revenge_group(entity.surface, entity.position, revenge_target, "biter", 0.3, 2)
        elseif entity_name == "biter-spawner" then
            Ai.revenge_group(entity.surface, entity.position, revenge_target, "biter")
        else
            Ai.revenge_group(entity.surface, entity.position, revenge_target, "spitter")
        end
    end
end

local function spawner_died(event)
    -- local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()

    if destination and destination.type == Surfaces.enum.ISLAND and destination.dynamic_data then
        local not_boat = true
        if destination.dynamic_data.enemyboats and #destination.dynamic_data.enemyboats > 0 then
            for i = 1, #destination.dynamic_data.enemyboats do
                local eb = destination.dynamic_data.enemyboats[i]
                if
                    eb.spawner
                    and eb.spawner.valid
                    and event.entity
                    and event.entity.valid
                    and event.entity == eb.spawner
                then
                    not_boat = false
                    break
                end
            end
        end

        if not_boat then
            local extra_evo = Balance.evolution_per_nest_kill()
            Common.increment_evo(extra_evo)

            destination.dynamic_data.evolution_accrued_nests = destination.dynamic_data.evolution_accrued_nests
                + extra_evo
        end
    end
end

local function event_on_entity_died(event)
    --== MODDING NOTE: event.cause is not always provided.
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    if not (event.force and event.force.valid) then
        return
    end

    local crew_id = Common.get_id_from_force_name(entity.force.name)
    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()
    local boat = memory.boat
    if not Common.is_id_valid(memory.id) then
        return
    end

    base_kill_rewards(event)

    if memory.scripted_biters and entity.type == "unit" and entity.force.name == memory.enemy_force_name then
        memory.scripted_biters[entity.unit_number] = nil
    end

    if entity.force.index == 3 or entity.force.name == "environment" then
        if event.cause and event.cause.valid and event.cause.force.name == memory.enemy_force_name then
            shred_nearby_simple_entities(entity)
        end
    end

    if event.entity and event.entity.valid and event.entity.force and event.entity.force.name == memory.force_name then
        if boat and boat.cannonscount and entity.name == "artillery-turret" then
            boat.cannonscount = boat.cannonscount - 1
            -- if boat.cannonscount <= 0 then
            -- 	Crew.try_lose()
            -- end
            Crew.try_lose({ "pirates.loss_cannon_destroyed" })
        end
    end

    if entity and entity.valid and entity.force and entity.force.name == memory.enemy_force_name then
        if entity.name == "biter-spawner" or entity.name == "spitter-spawner" then
            spawner_died(event)
            -- I think the only reason krakens don't trigger this right now is that they are destroyed rather than .die()
        else
            local destination = Common.current_destination()
            if
                destination
                and destination.dynamic_data
                and destination.dynamic_data.quest_type
                and not destination.dynamic_data.quest_complete
            then
                if destination.dynamic_data.quest_type == Quest.enum.WORMS and entity.type == "turret" then
                    destination.dynamic_data.quest_progress = destination.dynamic_data.quest_progress + 1
                    Quest.try_resolve_quest()
                end
            end
        end
    end

    -- elite biter death
    local elite_biters = memory.elite_biters
    if
        elite_biters
        and entity
        and entity.valid
        and entity.force.name == memory.enemy_force_name
        and elite_biters
        and elite_biters[entity.unit_number]
    then
        local surface = entity.surface
        if surface and surface.valid then
            -- Shoot spit around and spawn biters where spit lands
            local arc_size = (2 * Math.pi) / Balance.biters_spawned_on_elite_biter_death
            for i = 1, Balance.biters_spawned_on_elite_biter_death, 1 do
                local offset = Math.random_vec_in_arc(Math.random(4, 8), arc_size * i, arc_size)
                local target_pos = Math.vector_sum(entity.position, offset)

                local stream = surface.create_entity({
                    name = "acid-stream-spitter-big",
                    position = entity.position,
                    force = memory.enemy_force_name,
                    source = entity.position,
                    target = target_pos,
                    max_range = 500,
                    speed = 0.1,
                })

                if not memory.elite_biters_stream_registrations then
                    memory.elite_biters_stream_registrations = {}
                end
                memory.elite_biters_stream_registrations[#memory.elite_biters_stream_registrations + 1] = {
                    number = script.register_on_object_destroyed(stream),
                    position = target_pos,
                    biter_name = entity.name,
                    surface_name = surface.name, -- surface name is needed to know where biter died
                }
            end
        end

        memory.elite_biters[entity.unit_number] = nil
    end
end

-- function Public.research_apply_buffs(event)
-- 	local memory = Memory.get_crew_memory()
-- 	local force = memory.force

-- 	if Balance.research_buffs[event.research.name] then
-- 		local tech = Balance.research_buffs[event.research.name]
-- 		-- @FIXME: This code is from another scenario but doesn't work
-- 		for k, v in pairs(tech) do
-- 			force[k] = force[k] + v
-- 		end
-- 	end
-- end

local function event_on_research_finished(event)
    -- figure out which crew this is about:
    local research = event.research
    local force = research.force
    local crew_id = Common.get_id_from_force_name(force.name)
    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()

    if not memory.game_lost then --this condition should prevent discord messages being fired when the crew disbands and gets reset
        -- using a localised string means we have to write this out (recall that "" signals concatenation)
        memory.force.print(
            { "", ">> ", { "pirates.research_notification", research.localised_name } },
            CoreData.colors.notify_force_light
        )

        Server.to_discord_embed_raw(
            {
                "",
                "[" .. memory.name .. "] ",
                { "pirates.research_notification", prototypes.technology[research.name].localised_name },
            },
            true
        )
    end

    for _, e in ipairs(research.effects) do
        local t = e.type
        if t == "ammo-damage" then
            local category = e.ammo_category
            local factor = Balance.player_ammo_damage_modifiers()[category]

            if factor then
                local current_m = force.get_ammo_damage_modifier(category)
                local m = e.modifier
                force.set_ammo_damage_modifier(category, current_m + factor * m)
            end
        elseif t == "gun-speed" then
            local category = e.ammo_category
            local factor = Balance.player_gun_speed_modifiers()[category]

            if factor then
                local current_m = force.get_gun_speed_modifier(category)
                local m = e.modifier
                force.set_gun_speed_modifier(category, current_m + factor * m)
            end
        elseif t == "turret-attack" then
            local category = e.ammo_category
            local factor = Balance.player_turret_attack_modifiers()[category]

            if factor then
                local current_m = force.get_turret_attack_modifier(category)
                local m = e.modifier
                force.set_turret_attack_modifier(category, current_m + factor * m)
            end
        end
    end

    Crew.disable_recipes(force)
end

local function event_on_player_joined_game(event)
    local global_memory = Memory.get_global_memory()

    local player = game.players[event.player_index]

    --figure out if we should drop them back into a crew:

    if not Server.get_current_time() then -- don't run this on servers because I'd need to negotiate that with the rest of Comfy
        player.print({ "pirates.thesixthroc_support_toast" }, { r = 1, g = 0.4, b = 0.9 })
    end

    if _DEBUG then
        game.print("Debug mode on. Use /go to get started, /1 /4 /32 etc to change game speed.")
    end

    local crew_to_put_back_in = nil
    for _, memory in pairs(global_memory.crew_memories) do
        if
            Common.is_id_valid(memory.id)
            and memory.crewstatus == Crew.enum.ADVENTURING
            and memory.temporarily_logged_off_player_data[player.index]
        then
            crew_to_put_back_in = memory.id
            break
        end
    end

    -- if not _DEBUG then
    -- 	Gui.info.toggle_window(player)
    -- end

    if crew_to_put_back_in then
        log("INFO: " .. player.name .. " (crew ID: " .. crew_to_put_back_in .. ") joined the game")

        Memory.set_working_id(crew_to_put_back_in)
        Crew.join_crew(player, true)

        local memory = Memory.get_crew_memory()
        if (not memory.run_is_protected) and #memory.crewplayerindices <= 1 then
            Roles.make_captain(player)
        end

        if _DEBUG then
            log("putting player back in their old crew")
        end
    else
        log("INFO: " .. player.name .. " (crew ID: NONE) joined the game")
        if player.character and player.character.valid then
            player.character.destroy()
        end
        player.set_controller({ type = defines.controllers.god })
        player.create_character()

        local spawnpoint = Common.lobby_spawnpoint
        local surface = game.surfaces[CoreData.lobby_surface_name]

        player.teleport(surface.find_non_colliding_position("character", spawnpoint, 32, 0.5) or spawnpoint, surface)
        Permissions.update_privileges(player)

        if not player.name then
            return
        end

        -- start at Common.starting_island_spawnpoint or not?

        if game.tick == 0 then
            Common.ensure_chunks_at(surface, spawnpoint, 5)
        end

        Common.notify_player_expected(player, { "pirates.welcome_main_chat" })

        if not _DEBUG then
            GuiWelcome.show_welcome_window(player)
        end

        player.force = Common.lobby_force_name

        -- NOTE: It was suggested to always spawn players in lobby, in hopes that they may want to create their crew increasing the popularity of scenario. Hence the following code is disabled.

        -- WARNING: If re-enabling autojoin, make sure it respects private/protected runs.

        -- Auto-join the oldest crew:
        -- local ages = {}
        -- for _, memory in pairs(global_memory.crew_memories) do
        -- 	if Common.is_id_valid(memory.id)
        -- 		and (not memory.run_is_private)
        -- 		and memory.crewstatus == Crew.enum.ADVENTURING
        -- 		and memory.capacity
        -- 		and memory.crewplayerindices
        -- 		and #memory.crewplayerindices < memory.capacity
        -- 		and (not (memory.tempbanned_from_joining_data
        -- 			and memory.tempbanned_from_joining_data[player.index]
        -- 			and game.tick < memory.tempbanned_from_joining_data[player.index] + Common.ban_from_rejoining_crew_ticks)) then
        -- 		ages[#ages+1] = {id = memory.id, age = memory.age, large = (memory.capacity >= Common.minimum_run_capacity_to_enforce_space_for)}
        -- 	end
        -- end
        -- table.sort(
        -- 	ages,
        -- 	function(a, b) --true if a should be to the left of b
        -- 		if a.large and (not b.large) then
        -- 			return true
        -- 		elseif (not a.large) and b.large then
        -- 			return false
        -- 		else
        -- 			return a.age > b.age
        -- 		end
        -- 	end
        -- )
        -- if ages[1] then
        -- 	Crew.join_crew(player)

        -- 	local memory = global_memory.crew_memories[ages[1].id]
        -- 	if (not memory.run_is_protected) and #memory.crewplayerindices <= 1 then
        -- 		Roles.make_captain(player)
        -- 	end

        -- 	if ages[2] then
        -- 		if ages[1].large and (not ages[#ages].large) then
        -- 			Common.notify_player_announce(player, {'pirates.goto_oldest_crew_with_large_capacity'})
        -- 		else
        -- 			Common.notify_player_announce(player, {'pirates.goto_oldest_crew'})
        -- 		end
        -- 	end

        -- 	if memory.run_is_protected and (not Roles.captain_exists()) then
        -- 		Common.notify_player_expected(player, {'pirates.player_joins_protected_run_with_no_captain'})
        -- 		Common.notify_player_expected(player, {'pirates.create_new_crew_tip'})
        -- 	end
        -- end
    end

    if player.character and player.character.valid then
        global_memory.last_players_health[event.player_index] = player.character.health
    end
end

local function event_on_pre_player_left_game(event)
    local player = game.players[event.player_index]

    local global_memory = Memory.get_global_memory()

    -- figure out which crew this is about:
    local crew_id = Common.get_id_from_force_name(player.force.name)
    if crew_id then
        log("INFO: " .. player.name .. " (crew ID: " .. crew_id .. ") left the game")
    else
        log("INFO: " .. player.name .. " (crew ID: NONE) left the game")
    end

    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()

    for k, proposal in pairs(global_memory.crewproposals) do
        if proposal and proposal.created_by_player and proposal.created_by_player == event.player_index then
            global_memory.crewproposals[k] = nil
        end
    end

    if not Common.is_id_valid(crew_id) then
        if player.character and player.character.valid then
            player.character.destroy()
        end
        return -- nothing more needed
    end

    if player.controller_type == defines.controllers.editor then
        player.toggle_map_editor()
    end

    for _, id in pairs(memory.crewplayerindices) do
        if player.index == id then
            Crew.leave_crew(player, false, true)
            break
        end
    end
    for _, id in pairs(memory.spectatorplayerindices) do
        if player.index == id then
            Crew.leave_spectators(player, true)
            break
        end
    end

    global_memory.last_players_health[event.player_index] = nil
end

-- local function event_on_player_left_game(event)
-- 	-- n/a
-- end

-- local function on_player_changed_position(event)
-- 	local memory = Chrono_table.get_table()
-- 	if memory.planet[1].type.id == 14 then --lava planet
-- 		Event_functions.lava_planet(event)
-- 	end
-- end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    local jailed = Jailed.get_jailed_table()

    if player.name and jailed and jailed[player.name] then
        -- not quite sure this is necessary, but let's send their items to the crew:
        Common.send_important_items_from_player_to_crew(player, true)
        return
    end

    -- prevent connecting power between surfaces: (for the ship we do this automatically, but no need to let players do it in the general case:)
    if not player.is_cursor_empty() then
        if player.cursor_stack and player.cursor_stack.valid_for_read then
            local blacklisted = {
                ["small-electric-pole"] = true,
                ["medium-electric-pole"] = true,
                ["big-electric-pole"] = true,
                ["substation"] = true,
            }
            if blacklisted[player.cursor_stack.name] then
                player.get_main_inventory().insert(player.cursor_stack)
                player.cursor_stack.clear()
            end
        end
        if player.cursor_ghost then
            player.cursor_ghost = nil
        end
    end

    Permissions.update_privileges(player)

    GuiWelcome.close_welcome_window(player)
end

function Public.player_entered_vehicle(player, vehicle)
    if not vehicle then
        log("no vehicle")
        return
    end
    -- if not vehicle.name then log('no vehicle') return end
    -- if not vehicle.valid then log('vehicle invalid') return end

    local player_relative_pos =
        { x = player.position.x - vehicle.position.x, y = player.position.y - vehicle.position.y }

    local memory = Memory.get_crew_memory()

    local player_boat_relative_pos
    if memory and memory.boat and memory.boat.position then
        player_boat_relative_pos =
            { x = player.position.x - memory.boat.position.x, y = player.position.y - memory.boat.position.y }
    else
        player_boat_relative_pos =
            { x = player.position.x - vehicle.position.x, y = player.position.y - vehicle.position.y }
    end

    local surfacedata = Surfaces.SurfacesCommon.decode_surface_name(player.surface.name)

    if vehicle.name == "car" then
        -- A way to make player driven vehicles work
        if vehicle.minable then
            return
        end

        if
            surfacedata.type ~= Surfaces.enum.CROWSNEST
            and surfacedata.type ~= Surfaces.enum.CABIN
            and surfacedata.type ~= Surfaces.enum.LOBBY
        then
            if player_boat_relative_pos.x < -47 then
                Surfaces.player_goto_cabin(player, { x = 2, y = player_relative_pos.y })
            else
                Surfaces.player_goto_crows_nest(player, player_relative_pos)
            end
            player.play_sound({ path = "utility/picked_up_item" })
        elseif surfacedata.type == Surfaces.enum.CROWSNEST then
            Surfaces.player_exit_crows_nest(player, player_relative_pos)
            player.play_sound({ path = "utility/picked_up_item" })
        elseif surfacedata.type == Surfaces.enum.CABIN then
            Surfaces.player_exit_cabin(player, player_relative_pos)
            player.play_sound({ path = "utility/picked_up_item" })
        end
        vehicle.color = { 148, 106, 52 }

        player.driving = false
    elseif vehicle.name == "locomotive" then
        if
            surfacedata.type ~= Surfaces.enum.HOLD
            and surfacedata.type ~= Surfaces.enum.LOBBY
            and Math.abs(player_boat_relative_pos.y) < 8
        then --<8 in order not to enter holds of boats you haven't bought yet
            Surfaces.player_goto_hold(player, player_relative_pos, 1)
            player.play_sound({ path = "utility/picked_up_item" })
        elseif surfacedata.type == Surfaces.enum.HOLD then
            local current_hold_index = surfacedata.destination_index
            if current_hold_index >= memory.hold_surface_count then
                Surfaces.player_exit_hold(player, player_relative_pos)
            else
                Surfaces.player_goto_hold(player, player_relative_pos, current_hold_index + 1)
            end
            player.play_sound({ path = "utility/picked_up_item" })
        end

        player.driving = false
    end
end

local function event_on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    local vehicle = event.entity

    local crew_id = Common.get_id_from_force_name(player.force.name)
    Memory.set_working_id(crew_id)

    Public.player_entered_vehicle(player, vehicle)
end

function Public.event_on_chunk_generated(event)
    local surface = event.surface
    if not surface then
        return
    end
    if not surface.valid then
        return
    end
    if surface.name == "nauvis" or surface.name == "piratedev1" or surface.name == "gulag" then
        return
    end

    local seed = surface.map_gen_settings.seed
    local name = surface.name

    local surface_name_decoded = Surfaces.SurfacesCommon.decode_surface_name(name)
    local type = surface_name_decoded.type
    -- local subtype = surface_name_decoded.subtype
    local chunk_destination_index = surface_name_decoded.destination_index
    local crewid = surface_name_decoded.crewid

    Memory.set_working_id(crewid)

    local chunk_left_top = event.area.left_top
    local width, height = nil, nil
    local terraingen_coordinates_offset = { x = 0, y = 0 }
    local static_params = {}
    local other_map_generation_data = {}
    local scope
    local overworldx = 0

    local memory = Memory.get_crew_memory()
    if type == Surfaces.enum.ISLAND and memory.destinations and memory.destinations[chunk_destination_index] then
        local destination = memory.destinations[chunk_destination_index]
        scope = Surfaces.get_scope(surface_name_decoded)
        static_params = destination.static_params
        other_map_generation_data = destination.dynamic_data.other_map_generation_data or {}
        terraingen_coordinates_offset = static_params.terraingen_coordinates_offset
        width = static_params.width
        height = static_params.height
        overworldx = destination.overworld_position.x
    end

    if not scope then
        scope = Surfaces[type]
    end

    local noise_params, terrain_fn, chunk_structures_fn
    if scope then
        if scope.Data then
            if scope.Data.noiseparams then
                noise_params = scope.Data.noiseparams
            end
            if (not width) and scope.Data.width then
                width = scope.Data.width
            end
            if (not height) and scope.Data.height then
                height = scope.Data.height
            end
        end
        if scope.terrain then
            terrain_fn = scope.terrain
        end
        if scope.chunk_structures then
            chunk_structures_fn = scope.chunk_structures
        end
    end

    if not terrain_fn then
        return
    end

    if not width then
        width = 999
        log("no surface width? " .. type)
    end
    if not height then
        height = 999
    end

    local tiles, entities, decoratives, specials = {}, {}, {}, {}
    -- local noise_generator = nil
    local noise_generator = Utils.noise_generator(noise_params, seed)

    for y = 0.5, 31.5, 1 do
        for x = 0.5, 31.5, 1 do
            local p = { x = chunk_left_top.x + x, y = chunk_left_top.y + y }

            if p.x >= -width / 2 and p.y >= -height / 2 and p.x <= width / 2 and p.y <= height / 2 then
                terrain_fn({
                    p = Utils.psum({ p, { 1, terraingen_coordinates_offset } }),
                    true_p = p,
                    true_left_top = chunk_left_top,
                    left_top = Utils.psum({ chunk_left_top, { 1, terraingen_coordinates_offset } }),
                    noise_generator = noise_generator,
                    static_params = static_params,
                    tiles = tiles,
                    entities = entities,
                    decoratives = decoratives,
                    specials = specials,
                    seed = seed,
                    other_map_generation_data = other_map_generation_data,
                    iconized_generation = false,
                    overworldx = overworldx,
                })
            else
                tiles[#tiles + 1] =
                    { name = "out-of-map", position = Utils.psum({ p, { 1, terraingen_coordinates_offset } }) }
            end
        end
    end

    if chunk_structures_fn then
        chunk_structures_fn({
            true_left_top = chunk_left_top,
            left_top = Utils.psum({ chunk_left_top, { 1, terraingen_coordinates_offset } }),
            noise_generator = noise_generator,
            static_params = static_params,
            specials = specials,
            entities = entities,
            seed = seed,
            other_map_generation_data = other_map_generation_data,
            biter_base_density_scale = Balance.biter_base_density_scale(),
        })
    end

    local tiles_corrected = {}
    for i = 1, #tiles do
        local t = tiles[i]
        t.position = Utils.psum({ t.position, { -1, terraingen_coordinates_offset } })
        tiles_corrected[i] = t
    end
    local correct_tiles = true --tile borders etc

    if #tiles_corrected > 0 then
        surface.set_tiles(tiles_corrected, correct_tiles)
    end

    local destination = Common.current_destination()

    if destination.dynamic_data then
        if not destination.dynamic_data.structures_waiting_to_be_placed then
            destination.dynamic_data.structures_waiting_to_be_placed = {}
        end

        -- to avoid having chests on water, add a landfill tile underneath them
        local landfill_tiles = {}

        for _, special in pairs(specials) do
            -- recoordinatize:
            special.position = Utils.psum({ special.position, { -1, terraingen_coordinates_offset } })

            if special.name == "buried-treasure" then
                if destination.dynamic_data.buried_treasure and crewid ~= 0 then
                    destination.dynamic_data.buried_treasure[#destination.dynamic_data.buried_treasure + 1] =
                        { treasure = Loot.buried_treasure_loot(), position = special.position }
                end
            elseif special.name == "chest" then
                local e = surface.create_entity({
                    name = "wooden-chest",
                    position = special.position,
                    force = memory.ancient_friendly_force_name,
                })
                if e and e.valid then
                    e.minable = false
                    e.rotatable = false
                    e.destructible = false

                    local water_tiles = surface.find_tiles_filtered({
                        position = special.position,
                        radius = 0.1,
                        collision_mask = "water_tile",
                    })

                    if water_tiles then
                        for _, t in pairs(water_tiles) do
                            landfill_tiles[#landfill_tiles + 1] = { name = "landfill", position = t.position }
                        end
                    end

                    local inv = e.get_inventory(defines.inventory.chest)
                    local loot = Loot.wooden_chest_loot()
                    for i = 1, #loot do
                        local l = loot[i]
                        inv.insert(l)
                    end
                end
            elseif special.name == "market" then
                local e = surface.create_entity({
                    name = "market",
                    position = special.position,
                    force = memory.ancient_friendly_force_name,
                })
                if e and e.valid then
                    e.minable = false
                    e.rotatable = false
                    e.destructible = false

                    for _, o in pairs(special.offers) do
                        e.add_market_item(o)
                    end
                end
            elseif special.name == "big-ship-wreck-2" or special.name == "big-ship-wreck-1" then
                local e = surface.create_entity({
                    name = special.name,
                    position = special.position,
                    force = memory.ancient_friendly_force_name,
                })
                if e and e.valid then
                    e.minable = false
                    e.rotatable = false
                    e.destructible = false

                    local inv = e.get_inventory(defines.inventory.chest)

                    local loot = Loot.iron_chest_loot()

                    for i = 1, #loot do
                        local l = loot[i]
                        inv.insert(l)
                    end
                end
            end

            if special.components then
                destination.dynamic_data.structures_waiting_to_be_placed[#destination.dynamic_data.structures_waiting_to_be_placed + 1] =
                    { data = special, tick = game.tick }
            end
        end

        if #landfill_tiles > 0 then
            surface.set_tiles(landfill_tiles, true, false, false)
        end
    end

    for i = 1, #entities do
        local e = entities[i]
        e.position = Utils.psum({ e.position, { -1, terraingen_coordinates_offset } })
        local e2 = e
        -- e2.build_check_type = defines.build_check_type.ghost_revive
        -- log(_inspect(e2))

        -- Allow placing worms in water in walkways
        -- NOTE: Tile check there is to prevent worms from spawning outside island
        if
            surface.can_place_entity(e2)
            or (
                destination.subtype == IslandEnum.enum.WALKWAYS
                and string.sub(e.name, -11) == "worm-turret"
                and surface.get_tile(e.position.x, e.position.y).name == "water-shallow"
            )
        then
            local ee = surface.create_entity(e)
            if e.indestructible then
                ee.destructible = false
            end
        end
    end

    local decoratives_corrected = {}
    for i = 1, #decoratives do
        local d = decoratives[i]
        d.position = Utils.psum({ d.position, { -1, terraingen_coordinates_offset } })
        decoratives_corrected[i] = d
    end
    if #decoratives_corrected > 0 then
        surface.create_decoratives({ decoratives = decoratives_corrected })
    end
end

local function event_on_rocket_launched(event)
    -- figure out which crew this is about:
    local crew_id = Common.get_id_from_force_name(event.rocket.force.name)
    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()
    local destination = Common.current_destination()

    local rocket_launched_belongs_to_island = false
    if destination.dynamic_data.rocketsilos then
        for i = 1, #destination.dynamic_data.rocketsilos do
            if event.rocket_silo == destination.dynamic_data.rocketsilos[i] then
                rocket_launched_belongs_to_island = true
                break
            end
        end
    end

    -- We don't want to do anything if rocket was launched by silo that doesn't belong to island
    -- NOTE: On rare occasions if rocket was launched but the silo died in the meantime, this will not give rewards to the crew (idk how to fix it though)
    if not rocket_launched_belongs_to_island then
        return
    end

    local rocket_launch_coal_reward = Balance.rocket_launch_fuel_reward()
    local rocket_launch_coin_reward = Balance.rocket_launch_coin_reward()

    destination.dynamic_data.rocket_launched = true
    if memory.stored_fuel then
        memory.stored_fuel = memory.stored_fuel + rocket_launch_coal_reward
        Common.give_items_to_crew({ { name = "coin", count = rocket_launch_coin_reward } })
        memory.playtesting_stats.coins_gained_by_rocket_launches = memory.playtesting_stats.coins_gained_by_rocket_launches
            + rocket_launch_coin_reward
    end

    local force = memory.force
    local message = {
        "pirates.granted_2",
        { "pirates.granted_rocket_launch" },
        Math.floor(rocket_launch_coin_reward / 100) / 10 .. "k [item=coin]",
        Math.floor(rocket_launch_coal_reward / 100) / 10 .. "k [item=coal]",
    }
    Common.notify_force_light(force, message)

    if destination.dynamic_data.quest_type == Quest.enum.TIME and not destination.dynamic_data.quest_complete then
        destination.dynamic_data.quest_progressneeded = 1
        Quest.try_resolve_quest()
    end

    if destination.dynamic_data.quest_type == Quest.enum.NODAMAGE and not destination.dynamic_data.quest_complete then
        destination.dynamic_data.quest_progress = destination.dynamic_data.rocketsilohp
        Quest.try_resolve_quest()
    end

    if destination.dynamic_data.rocketsilos then
        for i = 1, #destination.dynamic_data.rocketsilos do
            local s = destination.dynamic_data.rocketsilos[i]
            if s and s.valid then
                s.destructible = true
                s.die()
            end
        end
        destination.dynamic_data.rocketsilos = nil
    end
end

local function event_on_built_entity(event)
    local entity = event.created_entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end

    if not event.player_index then
        return
    end
    if not game.players[event.player_index] then
        return
    end
    if not game.players[event.player_index].valid then
        return
    end

    local player = game.players[event.player_index]
    local crew_id = Common.get_id_from_force_name(player.force.name)
    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()

    if entity.name == "land-mine" then
        memory.players_to_last_landmine_placement_tick = memory.players_to_last_landmine_placement_tick or {}
        memory.players_to_last_landmine_placement_tick[player.index] = game.tick
    end

    if
        memory.boat
        and memory.boat.surface_name
        and player.surface == game.surfaces[memory.boat.surface_name]
        and entity.valid
        and entity.position
    then
        if
            (entity.type and (entity.type == "underground-belt"))
            or (entity.name == "entity-ghost" and entity.ghost_type and (entity.ghost_type == "underground-belt"))
        then
            if Boats.on_boat(memory.boat, entity.position) then
                -- if (entity.type and (entity.type == 'underground-belt' or entity.type == 'pipe-to-ground')) or (entity.name == 'entity-ghost' and entity.ghost_type and (entity.ghost_type == 'underground-belt' or entity.ghost_type == 'pipe-to-ground')) then
                if not (entity.name and entity.name == "entity-ghost") then
                    player.insert({ name = entity.name, count = 1 })
                end
                entity.destroy()
                Common.notify_player_error(player, { "pirates.error_build_undergrounds_on_boat" })
                return
            end
        end
    end

    -- hanas code for selective spidertrons:
    -- local objective = Chrono_table.get_table()
    -- if entity.name == 'spidertron' then
    --     if objective.world.id ~= 7 or entity.surface.name == 'cargo_wagon' then
    --         entity.destroy()
    --         local player = game.players[event.player_index]
    --         Alert.alert_player_warning(player, 8, {'chronosphere.spidertron_not_allowed'})
    --         player.insert({name = 'spidertron', count = 1})
    --     end
    -- end
end

local function event_on_console_chat(event)
    if not (event.message and event.player_index) then
        return
    end

    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    local global_memory = Memory.get_global_memory()
    local tag = player.tag or ""
    local color = player.chat_color

    local crew_id = Common.get_id_from_force_name(player.force.name)
    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()

    local message_prefix = player.name .. tag
    local full_message = message_prefix .. ": " .. event.message

    if player.force.name == Common.lobby_force_name then
        for _, index in pairs(global_memory.crew_active_ids) do
            local recipient_force_name = global_memory.crew_memories[index].force_name
            game.forces[recipient_force_name].print(message_prefix .. " [LOBBY]: " .. event.message, color)
        end
    else
        if memory.name then
            full_message = message_prefix .. " [" .. memory.name .. "]: " .. event.message
        end
        game.forces.player.print(full_message, color)
    end
end

local function event_on_market_item_purchased(event)
    Shop.event_on_market_item_purchased(event)
end

local remove_boost_movement_speed_on_respawn = Token.register(function(data)
    local player = data.player
    local crew_id = data.crew_id
    if not (player and player.valid) then
        return
    end

    -- their color was strobing, so now reset it to their chat color:
    player.color = player.chat_color

    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()
    if not Common.is_id_valid(memory.id) then
        return
    end --check if crew disbanded
    if memory.game_lost then
        return
    end
    memory.speed_boost_characters[player.index] = nil

    Common.notify_player_expected(player, { "pirates.respawn_speed_bonus_removed" })
end)

local boost_movement_speed_on_respawn = Token.register(function(data)
    local player = data.player
    local crew_id = data.crew_id
    if not player or not player.valid then
        return
    end

    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()
    if not Common.is_id_valid(memory.id) then
        return
    end --check if crew disbanded
    if memory.game_lost then
        return
    end
    memory.speed_boost_characters[player.index] = true

    Task.set_timeout_in_ticks(1200, remove_boost_movement_speed_on_respawn, { player = player, crew_id = crew_id })
    Common.notify_player_expected(player, { "pirates.respawn_speed_bonus_applied" })
end)

local function event_on_player_respawned(event)
    local player = game.players[event.player_index]

    local crew_id = Common.get_id_from_force_name(player.force.name)

    Memory.set_working_id(crew_id)
    local memory = Memory.get_crew_memory()
    local boat = memory.boat

    if player.surface == game.surfaces[Common.current_destination().surface_name] then
        if Boats.is_boat_at_sea() then
            -- assuming sea is always default:
            local seasurface = game.surfaces[memory.sea_name]
            player.teleport(memory.spawnpoint, seasurface)
        elseif boat and (boat.state == Boats.enum_state.LANDED or boat.state == Boats.enum_state.RETREATING) then
            if player.character and player.character.valid then
                Task.set_timeout_in_ticks(360, boost_movement_speed_on_respawn, { player = player, crew_id = crew_id })

                local global_memory = Memory.get_global_memory()
                global_memory.last_players_health[event.player_index] = player.character.health
            end
        end
    end
end

local function event_on_entity_spawned(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end

    local surface = entity.surface
    if not surface then
        return
    end
    if not surface.valid then
        return
    end

    local crew_id = SurfacesCommon.decode_surface_name(surface.name).crewid
    if not Common.is_id_valid(crew_id) then
        return
    end

    Memory.set_working_id(crew_id)
    Common.try_make_biter_elite(entity)
end

local function event_on_gui_opened(event)
    -- If the object is a chest, close the gui
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player then
        return
    end
    if not player.valid then
        return
    end

    if player.permission_group.name == "cabin_privileged" then
        if entity.name == "red-chest" then
            -- Even the captain has to wait for items to be removed from the red chests by loaders:
            player.opened = nil
        end
    elseif player.permission_group.name == "cabin" then
        if
            entity.name == "wooden-chest"
            or entity.name == "iron-chest"
            or entity.name == "steel-chest"
            or entity.name == "red-chest"
            or entity.name == "blue-chest"
        then
            player.opened = nil
        end
    end
end

local event = require("utils.event")
event.add(defines.events.on_built_entity, event_on_built_entity)
event.add(defines.events.on_entity_damaged, event_on_entity_damaged)
event.add(defines.events.on_entity_died, event_on_entity_died)
-- event.add(defines.events.on_player_repaired_entity, event_on_player_repaired_entity)
event.add(defines.events.on_player_joined_game, event_on_player_joined_game)
event.add(defines.events.on_pre_player_left_game, event_on_pre_player_left_game)
-- event.add(defines.events.on_player_left_game, event_on_player_left_game)
-- event.add(defines.events.on_pre_player_mined_item, event_pre_player_mined_item)
event.add(defines.events.on_player_mined_entity, event_on_player_mined_entity)
event.add(defines.events.on_research_finished, event_on_research_finished)
event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
event.add(defines.events.on_player_driving_changed_state, event_on_player_driving_changed_state)
-- event.add(defines.events.on_player_changed_position, event_on_player_changed_position)
-- event.add(defines.events.on_technology_effects_reset, event_on_technology_effects_reset)
-- event.add(defines.events.on_chunk_generated, PiratesApiEvents.on_chunk_generated) --moved to main in order to make the debug properties clear
event.add(defines.events.on_rocket_launched, event_on_rocket_launched)
event.add(defines.events.on_console_chat, event_on_console_chat)
event.add(defines.events.on_market_item_purchased, event_on_market_item_purchased)
event.add(defines.events.on_player_respawned, event_on_player_respawned)
event.add(defines.events.on_entity_spawned, event_on_entity_spawned)
event.add(defines.events.on_gui_opened, event_on_gui_opened)
return Public
