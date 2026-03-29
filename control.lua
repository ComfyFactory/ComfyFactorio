require 'utils.data_stages'
_LIFECYCLE = _STAGE.control -- Control stage
_DEBUG = false
_DUMP_ENV = false
_PROFILE = false

require 'utils.created_events'
require 'utils.server'
require 'utils.event'
require 'utils.dev_server'
require 'utils.server_commands'
require 'utils.gui.init'
require 'utils.admin_handler'
require 'utils.utils'
require 'utils.math.math'
require 'utils.pause_game'
require 'utils.table'
require 'utils.whisper_notice'
require 'utils.datastore.init'
require 'utils.chatbot'
require 'utils.common_commands'
require 'utils.antigrief'
require 'utils.debug.command'
require 'utils.role.main'
require 'modules.floaty_chat'
require 'modules.show_inventory'
require 'modules.inserter_drops_pickup'
require 'modules.autostash'

require 'utils.remote_chunks'

if _DUMP_ENV then
    require 'utils.dump_env'
end

if _PROFILE then
    require 'utils.profiler'
end

---------------- ENABLE MAPS HERE ----------------
--!Make sure only one map is enabled at a time.
--!Remove the "--" in front of the line to enable.
--!All lines with the "require" keyword are different maps.

--![[OARC - Multiplayer spawn]]--
--require 'maps.oarc.main'

--![[Comfylatron has seized the Fish Train and turned it into a time machine]]--
--require 'maps.chronosphere.main'

--![[Guide a Train through rough terrain, while defending it from the biters]]--
--require 'utils.templates.Mountain_Fortress_v3_BP.map_loader'
--require 'maps.mountain_fortress_v3.main'

--![[Launch rockets in increasingly harder getting worlds.]]--
--require 'maps.journey.main'

--![[Infestation Islands]]--
--require 'maps.infestation_islands.main'

--![[Infinite random dungeon with RPG]]--
--require 'maps.dungeons.main'

--![[Defend the market against waves of biters]]--
--require 'maps.fish_defender_v2.main'
--require 'maps.crab_defender.main'

--![[Adventure as a crew of pirates]]--
--require 'maps.pirates.main'

--![[East VS West Survival PVP, where you breed biters with science flasks]]--
--require 'maps.biter_hatchery.main'

--![[Fight in a world where everyone are prisoners]]
--require 'maps.planet_prison'

--![[Chop trees to gain resources]]--
--require 'maps.choppy'
--require 'maps.choppy_dx'

--![[Minesweeper?]]--
--require 'maps.minesweeper.main'

--![[A map where you build towns and fight against other towns and the biters.]]--
--require 'maps.scrap_towny_ffa.main'

--![[North VS South Survival PVP, feed the opposing team's biters with science flasks. Disable Autostash, Group and Poll modules.]]--
--require 'maps.biter_battles_v2.main'
--require 'maps.biter_battles.biter_battles'

--![[Infinitely expanding mazes]]--
--require 'maps.stone_maze.main'
--require 'maps.labyrinth'

--![[Extreme survival mode with thirst and limited building room]]--
--require 'maps.desert_oasis'

--![[The trees are your enemy here]]--
--require 'maps.overgrowth'

--![[Wave Defense Map split in 4 Quarters]]--
--require 'maps.quarters'

--![[Flee from the collapsing map with portable base inside train]]--
--require 'maps.railway_troopers_v2.main'
--require 'maps.railway_troopers.main'

--![[Territorial Control - reveal the map as you walk through the mist]]--
--require 'maps.territorial_control'

--![[Deep Jungle - dangerous map]]--
--require 'maps.deep_jungle.main'

--![[You fell in a dark cave, will you survive?]]--
--require 'maps.cave_choppy.main'
--require 'maps.cave_miner'
--require 'maps.cave_miner_v2.main'

--![[Hungry boxes eat your items, but reward you with new territory to build.]]--
--require 'maps.expanse.main'

--![[Dangerous forest with unique map revealing]]--
--require 'maps.spooky_forest'

--![[Defeat the biters and unlock new areas]]--
--require 'maps.spiral_troopers'

--![[A map where you cross a river and fight against the biters.]]--
--require 'maps.crossing'

--![[Test map spawns all entities for testing]]--
--require 'maps.test_map.main'

---------------- !ENABLE MODULES HERE ----------------
--require 'modules.rpg.main'
--require 'modules.admins_operate_biters'
--require 'modules.the_floor_is_lava'
--require 'modules.biters_landfill_on_death'
--require 'modules.autodecon_when_depleted'
--require 'modules.biter_noms_you'
--require 'modules.biters_avoid_damage'
--require 'modules.biters_double_damage'
--require 'modules.burden'
--require 'modules.comfylatron'
--require 'modules.dangerous_goods'
--require 'modules.explosive_biters'
--require 'modules.explosive_player_respawn'
--require 'modules.explosives_are_explosive'
--require 'modules.fish_respawner'
--require 'modules.fluids_are_explosive'
--require 'modules.hunger'
--require 'modules.hunger_games'
--require 'modules.pistol_buffs'
--require 'modules.players_trample_paths'
--require 'modules.railgun_enhancer'
--require 'modules.restrictive_fluid_mining'
--require 'modules.robot_limits'
--require 'modules.satellite_score'
--require 'modules.show_health'
--require 'modules.splice_double'
--require 'modules.ores_are_mixed'
--require 'modules.team_teleport'
--require 'modules.surrounded_by_worms'
--require 'modules.no_blueprint_library'
--require 'modules.explosives'
--require 'modules.biter_pets'
--require 'modules.no_solar'
--require 'modules.biter_reanimator'
--require 'modules.force_health_booster'
--require 'modules.immersive_cargo_wagons.main'
--require 'modules.wave_defense.main'
--require 'modules.fjei.main'
--require 'modules.charging_station'
--require 'modules.landmine_effects'
--require 'modules.crawl_into_pipes'
--require 'modules.no_acid_puddles'
--require 'modules.simple_tags'
--require 'modules.turret_filler'
---------------------------------------------------------------

--- this file exists only for the panel to sync and start from within the panel
-- it does nothing if it's not synced from within the panel
require 'map_loader'

local loaded = _G.package.loaded
function require(path)
    return loaded[normalize_path(path)] or error('Can only require files at runtime that have been required in the control stage.', 2)
end
