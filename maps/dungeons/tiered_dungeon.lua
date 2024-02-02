-- Deep dark dungeons by mewmew --

require 'modules.mineable_wreckage_yields_scrap'
require 'modules.satellite_score'
require 'modules.charging_station'

-- Tuning constants
local MIN_ROOMS_TO_DESCEND = 30  --最小探索几个房间

local MapInfo = require 'modules.map_info'
local Room_generator = require 'utils.functions.room_generator'
local RPG = require 'modules.rpg.main'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local BiterRaffle = require 'utils.functions.biter_raffle'
local Functions = require 'maps.dungeons.functions'
local Get_noise = require 'utils.get_noise'
local Alert = require 'utils.alert'
local Research = require 'maps.dungeons.research'
local DungeonsTable = require 'maps.dungeons.table'
local BottomFrame = require 'utils.gui.bottom_frame'
local Autostash = require 'modules.autostash'
local Panel = require 'utils.gui.config'
Panel.get('gui_config').spaghett.noop = true
local Collapse = require 'modules.collapse'
local Changelog = require 'modules.changelog'
--require 'maps.dungeons.boss_arena'
require 'modules.melee_mode'--近战模式

local Biomes = {}
Biomes.dirtlands = require 'maps.dungeons.biome_dirtlands'
Biomes.desert = require 'maps.dungeons.biome_desert'
Biomes.red_desert = require 'maps.dungeons.biome_red_desert'
Biomes.grasslands = require 'maps.dungeons.biome_grasslands'
Biomes.concrete = require 'maps.dungeons.biome_concrete'
Biomes.doom = require 'maps.dungeons.biome_doom'
Biomes.deepblue = require 'maps.dungeons.biome_deepblue'
Biomes.glitch = require 'maps.dungeons.biome_glitch'
Biomes.acid_zone = require 'maps.dungeons.biome_acid_zone'
Biomes.rainbow = require 'maps.dungeons.biome_rainbow'
Biomes.treasure = require 'maps.dungeons.biome_treasure'
Biomes.market = require 'maps.dungeons.biome_market'
Biomes.laboratory = require 'maps.dungeons.biome_laboratory'
local Token = require 'utils.token'  --引入token系统
local Task = require 'utils.task'  --引入定时任务系统

local math_random = math.random
local math_round = math.round

require 'maps.dungeons.biters_die_item'  --引入掉落物系统

local function on_gui_opened(event)--打开GUI界面的时候触发
	local player = game.get_player(event.player_index)
	if not player or not player.valid then
		return
	end
    --game.print(event.gui_type) --输出调试信息
	--game.print(event.player_index) --输出调试信息
	game.forces.player.technologies["logistic-robotics"].researched = true--解锁并研究物流机器人科技，否则无法设置回收区
	game.forces.player.worker_robots_storage_bonus = 64--设置机器人系列搬运量加值
	game.forces.player.character_trash_slot_count = 512--设置回收区槽位数量，数量越多越卡.建议不要超过1000
    game.forces.player.stack_inserter_capacity_bonus=64--设置集装机械臂系列抓取量加值
end
--local Event = require 'utils.event' --引入event模块--注意一个文件只能引用一次，一般在文件首部
--Event.add(defines.events.on_gui_opened, on_gui_opened) --注册这个事件以调用--注意一个文件只能引用一次，一般在文件尾部

local function enable_hard_rooms(position, surface_index)
    local dungeon_table = DungeonsTable.get_dungeontable()
    local floor = surface_index - dungeon_table.original_surface_index
    -- can make it out to ~200 before hitting the "must explore more" limit
    -- 140 puts hard rooms halfway between the only dirtlands and the edge
    local floor_mindist = 140 - floor * 10
    if floor_mindist < 80 then -- all dirtlands within this
       return true
    end
    return position.x ^ 2 + position.y ^ 2 > floor_mindist^2
end

local function get_biome(position, surface_index)
    --if not a then return "concrete" end
    if position.x ^ 2 + position.y ^ 2 < 6400 then
        return 'dirtlands'
    end

    local seed = game.surfaces[surface_index].map_gen_settings.seed
    local seed_addition = 100000

    local a = 1
    if Get_noise('dungeons', position, seed + seed_addition * a) > 0.66 then
        return 'glitch'
    end
    if enable_hard_rooms(position, surface_index) then
       a = a + 1
       if Get_noise('dungeons', position, seed + seed_addition * a) > 0.60 then
	  return 'doom'
       end
       a = a + 1
       if Get_noise('dungeons', position, seed + seed_addition * a) > 0.62 then
	  return 'acid_zone'
       end
       a = a + 1
       if Get_noise('dungeons', position, seed + seed_addition * a) > 0.60 then
	  return 'concrete'
       end
    else
       a = a + 3
    end
    a = a + 1
    if Get_noise('dungeons', position, seed + seed_addition * a) > 0.71 then
        return 'rainbow'
    end
    a = a + 1
    if Get_noise('dungeons', position, seed + seed_addition * a) > 0.53 then
        return 'deepblue'
    end
    a = a + 1
    if Get_noise('dungeons', position, seed + seed_addition * a) > 0.22 then
        return 'grasslands'
    end
    a = a + 1
    if Get_noise('dungeons', position, seed + seed_addition * a) > 0.22 then
        return 'desert'
    end
    a = a + 1
    if Get_noise('dungeons', position, seed + seed_addition * a) > 0.22 then
        return 'red_desert'
    end

    return 'dirtlands'
end

local function draw_arrows_gui()
    for _, player in pairs(game.connected_players) do
        if not player.gui.top.dungeon_down then
            player.gui.top.add({type = 'sprite-button', name = 'dungeon_down', sprite = 'utility/editor_speed_down', tooltip = {'dungeons_tiered.descend'}})
        end
        if not player.gui.top.dungeon_up then
            player.gui.top.add({type = 'sprite-button', name = 'dungeon_up', sprite = 'utility/editor_speed_up', tooltip = {'dungeons_tiered.ascend'}})
        end
    end
end

local function draw_depth_gui()
    local dungeontable = DungeonsTable.get_dungeontable()
    local forceshp = BiterHealthBooster.get('biter_health_boost_forces')
    for _, player in pairs(game.connected_players) do
        local surface = player.surface
        local techs = Research.techs_remain(surface.index)
        local enemy_force = dungeontable.enemy_forces[surface.index]
        if player.gui.top.dungeon_depth then
            player.gui.top.dungeon_depth.destroy()
        end
        if surface.name == 'gulag' or surface.name == 'nauvis' or surface.name == 'dungeons_floor_arena' then
            return
        end
        local element = player.gui.top.add({type = 'sprite-button', name = 'dungeon_depth'})
        element.caption = {'dungeons_tiered.depth', surface.index - dungeontable.original_surface_index, dungeontable.depth[surface.index]}
        element.tooltip = {
            'dungeons_tiered.depth_tooltip',
            surface.index - dungeontable.original_surface_index, 
            dungeontable.depth[surface.index], 
            Functions.get_dungeon_evolution_factor(surface.index) * 100,
            forceshp[enemy_force.index] * 100,
            math_round(enemy_force.get_ammo_damage_modifier('melee') * 100 + 100, 1),
            Functions.get_base_loot_value(surface.index),
            dungeontable.treasures[surface.index],
            techs
        }

        local style = element.style
        style.minimal_height = 38
        style.maximal_height = 38
        style.minimal_width = 186
        style.top_padding = 2
        style.left_padding = 4
        style.right_padding = 4
        style.bottom_padding = 2
        style.font_color = {r = 0, g = 0, b = 0}
        style.font = 'default-large-bold'
    end
end

local function expand(surface, position)
    local dungeontable = DungeonsTable.get_dungeontable()
    local forceshp = BiterHealthBooster.get('biter_health_boost_forces')
    local room
    local roll = math_random(1, 100)
    if roll > 90 then
        room = Room_generator.get_room(surface, position, 'big')
    elseif roll > 80 then
        room = Room_generator.get_room(surface, position, 'wide')
    elseif roll > 70 then
        room = Room_generator.get_room(surface, position, 'tall')
    elseif roll > 50 then
        room = Room_generator.get_room(surface, position, 'rect')
    else
        room = Room_generator.get_room(surface, position, 'square')
    end
    if not room then
        return
    end
    local treasure_room_one_in = 32 + 16 * dungeontable.treasures[surface.index] ---以已发现珍宝房的数量生成一个数值
    local market_room_one_in = 128 + 16 * dungeontable.treasures[surface.index] ---以已发现珍宝房的数量生成一个数值
    if dungeontable.surface_size[surface.index] >= 225 and math.random(1, treasure_room_one_in) == 1 and room.room_tiles[1] then  --判断探索房间数大于xx且随机一个数值
	log('Found treasure room, change was 1 in ' .. treasure_room_one_in)
        Biomes['treasure'](surface, room)
        if room.room_tiles[1] then
            dungeontable.treasures[surface.index] = dungeontable.treasures[surface.index] + 1
            game.print({'dungeons_tiered.treasure_room', surface.index - dungeontable.original_surface_index}, {r = 0.22, g = 0.88, b = 0.88})
        end
    elseif Research.room_is_lab(surface.index) then
        Biomes['laboratory'](surface, room)
        if room.room_tiles[1] then
            Research.unlock_research(surface.index)
        end
    elseif math.random(1, market_room_one_in) == 1 and room.room_tiles[1] then --商店房间出现概率
        local text = ('[font=infinite][color=#E99696]在[/color][color=#E9A296]' .. surface.index - dungeontable.original_surface_index .. '[/color][color=#E9AF96]层[/color][color=#E9BB96]收[/color][color=#E9C896]到[/color][color=#E9D496]了[/color][color=#E9E096]来[/color][color=#E5E996]自[/color][color=#D8E996]？[/color][color=#CCE996]？[/color][color=#BFE996]？[/color][color=#B3E996]的[/color][color=#A6E996]通[/color][color=#9AE996]讯[/color][color=#96E99E]信[/color][color=#96E9AB]息[/color][color=#96E9B7]，[/color][color=#96E9C3]努[/color][color=#96E9D0]力[/color][color=#96E9DC]解[/color][color=#96E9E9]读[/color][color=#96E9EF]中[/color][color=#96E9F8].[/color][color=#96E9FA].[/color][color=#96E9FF].[/color][/font]')
        game.print(text)
        Biomes['market'](surface, room)
    else
        local name = get_biome(position, surface.index)
        Biomes[name](surface, room)
    end

    if not room.room_tiles[1] then
        return
    end

    dungeontable.depth[surface.index] = dungeontable.depth[surface.index] + 1
    dungeontable.surface_size[surface.index] = 200 + (dungeontable.depth[surface.index] - 100 * (surface.index - dungeontable.original_surface_index)) / 4

    local evo = Functions.get_dungeon_evolution_factor(surface.index)

    local force = dungeontable.enemy_forces[surface.index]
    force.evolution_factor = evo

    if evo > 1 then
        forceshp[force.index] = 3 + ((evo - 1) * 4)
        local damage_mod = (evo - 1) * 0.35
        force.set_ammo_damage_modifier('melee', damage_mod)
        force.set_ammo_damage_modifier('biological', damage_mod)
        force.set_ammo_damage_modifier('artillery-shell', damage_mod)
        force.set_ammo_damage_modifier('flamethrower', damage_mod)
        force.set_ammo_damage_modifier('laser', damage_mod)
    else
        forceshp[force.index] = 1 + evo * 2
    end

    forceshp[force.index] = math_round(forceshp[force.index], 2)
    draw_depth_gui()
end

local function draw_light(player) --玩家光亮值
    if not player.character then
        return
    end
    local rpg = RPG.get('rpg_t')
    local x = rpg[player.index].level --更改为读取RPG等级
    local scale = 3
    if x < 30 then 
        scale = 3
    end --如果小于80就返回0
    if x >= 35 then 
        scale = x/11
    end --如果大于80就返回x除11的值给scale
    if scale >= 30 then 
        scale = 30 
    end --如果scale的值大于30则等于30
    rendering.draw_light(
        {
            sprite = 'utility/light_medium',
            scale = scale * 1,
            intensity = scale,
            minimum_darkness = 0,
            oriented = true,--手电筒
            color = {32, 32, 32},
            target = player.character,
            surface = player.surface,
            visible = true,
            only_in_alt_mode = true --细节模式切换
        }
    )
    if player.character.is_flashlight_enabled() then
        player.character.disable_flashlight()
    end
end

local function dungeons_help(player)--定义帮助信息
    local message1 = ('此地图已启用装甲外部充电功能.\n屏幕顶部的[img=item.battery-mk2-equipment]可为装甲内的电池模块进行充电')--预定义消息
    local message2 = ('此地图已启用危险爆炸物功能.\n箱子里如果有炸药的情况下被破坏,将会引起破坏力极强的大爆炸(包括物理上)')--预定义消息
    local message3 = ('此地图已启用树木自然增长功能.\n活着的树木会向周围的土地慢慢延伸,如果铺设了地砖则很难扎根')--预定义消息
    local message4 = ('此地图已启用搬运量增强功能.\n集装机械臂和机器人的搬运能力被大大增强了,同时人物背包回收槽位也已扩展')--预定义消息
    local message5 = ('此地图已启用快捷整理背包功能.\n右下角蓝图按钮附近的[entity=behemoth-biter]和[item=wooden-chest]图标是清理尸体和整理背包，整理矿物到附近的炉子和整理物品到附近的箱子!')--预定义消息
    local message6 = ('此地图已启用蓝图物流请求功能.\n将蓝图放入 [entity=logistic-chest-requester] or [entity=logistic-chest-buffer] 将自动设置物流请求以匹配蓝图.放入后,将箱子关闭后执行物流请求.您可以在Comfy菜单->Config中自行禁用此功能')--预定义消息
    local message7 = ('此地图已启用增强型RPG功能.\nRPG魔法的设置面板按钮一般是关闭按钮旁边的齿轮按钮!RPG里面魔法的开关需要点击RPG设置中的[img=item.raw-fish]图标让[virtual-signal=signal-red]变为[virtual-signal=signal-green]才是开启之后手持物品[img=item.raw-fish]左键食用即可释放魔法!')--预定义消息
    local message8 = ('此地图已启用近战模式锁定功能.\n左上角按钮[img=item.dummy-steel-axe]和[img=item.pistol]是自动切换近战和远程模式，只有近战模式下(不装备武器和弹药)才能触发RPG的肉搏伤害加成!')--预定义消息
    local message9 = ('此地图已启用信任机制功能.\n如果联机模式遇到不能使用红绿图、整理背包、删除尸体与RPG魔法，可让管理员执行 /trust xxx 命令授予信任后再尝试使用,此命令为Comfy系列场景地图特有')--预定义消息
    local roll = math_random(1, 9)
    if roll == 9 then
        Alert.alert_player_warning(player, 5,message9)--发送消息
    elseif roll == 8 then
        Alert.alert_player_warning(player, 5,message8)--发送消息
    elseif roll == 7 then
        Alert.alert_player_warning(player, 5,message7)--发送消息
    elseif roll == 6 then
        Alert.alert_player_warning(player, 5,message6)--发送消息
    elseif roll == 5 then
        Alert.alert_player_warning(player, 5,message5)--发送消息
    elseif roll == 4 then
        Alert.alert_player_warning(player, 5,message4)--发送消息
    elseif roll == 3 then
        Alert.alert_player_warning(player, 5,message3)--发送消息
    elseif roll == 2 then
        Alert.alert_player_warning(player, 5,message2)--发送消息
    else
        Alert.alert_player_warning(player, 5,message1)--发送消息
    end
end


local function init_player(player, surface)
    if surface == game.surfaces['dungeons_floor0'] then
        if player.character then
	    player.disassociate_character(player.character)
            player.character.destroy()
        end

        if not player.connected then
        log('BUG Player ' .. player.name .. ' is not connected; how did we get here?')
        end

        player.set_controller({type = defines.controllers.god})
        player.teleport(surface.find_non_colliding_position('character', {0, 0}, 50, 0.5), surface)
        dungeons_help(player)--随机发送一条帮助信息

        if not player.create_character() then
        log('BUG: create_character for ' .. player.name .. ' failed')
        end

        player.insert({name = 'submachine-gun', count = 1})--初始物品-冲锋枪
        player.insert({name = 'firearm-magazine', count = 128})--初始物品-普通子弹
        player.insert({name = 'raw-fish', count = 8})--初始物品-鱼
        player.insert({name = 'poison-capsule', count = 8})--初始物品-剧毒胶囊
        player.insert({name = 'slowdown-capsule', count = 8})--初始物品-减速胶囊
        player.insert({name = 'distractor-capsule', count = 16})--初始物品-掩护无人机胶囊
        player.insert({name = 'defender-capsule', count = 16})--初始物品-防御无人机胶囊
        player.insert({name = 'loader', count = 8})--初始物品-装卸机
        player.insert({name = 'fast-loader', count = 4})--初始物品-装卸机-快速
        player.insert({name = 'express-loader', count = 2})--初始物品-装卸机-极速
        player.insert({name = 'linked-chest', count = 2})--初始物品-关联箱
        player.insert({name = 'coin', count = 1000})--初始物品-金币
        player.set_quick_bar_slot(1, 'raw-fish')--设置快捷栏-鱼
        player.set_quick_bar_slot(2, 'poison-capsule')--设置快捷栏-剧毒胶囊
        player.set_quick_bar_slot(3, 'slowdown-capsule')--设置快捷栏-减速胶囊
        player.set_quick_bar_slot(4, 'distractor-capsule')--设置快捷栏-掩护无人机胶囊
        player.set_quick_bar_slot(5, 'defender-capsule')--设置快捷栏-防御无人机胶囊
        player.set_quick_bar_slot(6, 'loader')--设置快捷栏-装卸机
        player.set_quick_bar_slot(7, 'fast-loader')--设置快捷栏-装卸机-快速
        player.set_quick_bar_slot(8, 'express-loader')--设置快捷栏-装卸机-极速
        player.set_quick_bar_slot(9, 'linked-chest')--设置快捷栏-关联箱
        player.set_quick_bar_slot(10, 'coin')--设置快捷栏-金币

    else
        if player.surface == surface then
            player.teleport(surface.find_non_colliding_position('character', {0, 0}, 50, 0.5), surface)
            dungeons_help(player)--随机发送一条帮助信息
        end
    end
end

local function on_player_died(event)
    local message1 = ('[font=infinite][color=#E99696]快[/color][color=#E9A296]趁[/color][color=#E9AF96]他[/color][color=#E9BB96]小[/color][color=#E9C896]黑[/color][color=#E9D496]屋[/color][color=#E9E096]坐[/color][color=#E5E996]牢[/color][color=#D8E996]，[/color][color=#CCE996]含[/color][color=#BFE996]泪[/color][color=#B3E996]舔[/color][color=#A6E996]包[/color][color=#9AE996]哇[/color][color=#96E99E]！[/color][color=#96E9AB]！[/color][color=#96E9B7]！[/color][/font]')--预定义消息
    game.print(message1, {r = 0.2, g = 0.95, b = 0.88})
end

local function on_entity_spawned(event)
    local dungeontable = DungeonsTable.get_dungeontable()
    local forceshp = BiterHealthBooster.get('biter_health_boost_forces')
    local spawner = event.spawner
    local unit = event.entity
    local surface = spawner.surface
    local force = unit.force

    local spawner_tier = dungeontable.spawner_tier
    if not spawner_tier[spawner.unit_number] then
        Functions.set_spawner_tier(spawner, surface.index)
    end

    local e = Functions.get_dungeon_evolution_factor(surface.index)
    for _ = 1, spawner_tier[spawner.unit_number], 1 do
        local name = BiterRaffle.roll('mixed', e)
        local non_colliding_position = surface.find_non_colliding_position(name, unit.position, 16, 1)
        local bonus_unit
        if non_colliding_position then
            bonus_unit = surface.create_entity({name = name, position = non_colliding_position, force = force})
        else
            bonus_unit = surface.create_entity({name = name, position = unit.position, force = force})
        end
        bonus_unit.ai_settings.allow_try_return_to_spawner = true
        bonus_unit.ai_settings.allow_destroy_when_commands_fail = true

        if math_random(1, 256) == 1 then
            BiterHealthBooster.add_boss_unit(bonus_unit, forceshp[force.index] * 8, 0.25)
        end
    end

    if math_random(1, 256) == 1 then
        BiterHealthBooster.add_boss_unit(unit, forceshp[force.index] * 8, 0.25)
    end
end

local function on_chunk_generated(event)
    local surface = event.surface
    if surface.name == 'nauvis' or surface.name == 'gulag' or surface.name == 'dungeons_floor_arena' then
        return
    end

    local left_top = event.area.left_top

    local tiles = {}
    local i = 1
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = {x = left_top.x + x, y = left_top.y + y}
            tiles[i] = {name = 'out-of-map', position = position}
            i = i + 1
        end
    end
    surface.set_tiles(tiles, true)

    local rock_positions = {}
    -- local set_tiles = surface.set_tiles
    -- local nauvis_seed = game.surfaces[surface.index].map_gen_settings.seed
    -- local s = math_floor(nauvis_seed * 0.1) + 100
    -- for a = 1, 7, 1 do
    -- 	local b = a * s
    -- 	local c = 0.0035 + a * 0.0035
    -- 	local d = c * 0.5
    -- 	local seed = nauvis_seed + b
    -- 	if math_abs(Get_noise("dungeon_sewer", {x = left_top.x + 16, y = left_top.y + 16}, seed)) < 0.12 then
    -- 		for x = 0, 31, 1 do
    -- 			for y = 0, 31, 1 do
    -- 				local position = {x = left_top.x + x, y = left_top.y + y}
    -- 				local noise = math_abs(Get_noise("dungeon_sewer", position, seed))
    -- 				if noise < c then
    -- 					local tile_name = surface.get_tile(position).name
    -- 					if noise > d and tile_name ~= "deepwater-green" then
    -- 						set_tiles({{name = "water-green", position = position}}, true)
    -- 						if math_random(1, 320) == 1 and noise > c - 0.001 then table_insert(rock_positions, position) end
    -- 					else
    -- 						set_tiles({{name = "deepwater-green", position = position}}, true)
    -- 						if math_random(1, 64) == 1 then
    -- 							surface.create_entity({name = "fish", position = position})
    -- 						end
    -- 					end
    -- 				end
    -- 			end
    -- 		end
    -- 	end
    -- end

    for _, p in pairs(rock_positions) do
        Functions.place_border_rock(surface, p)
    end

    if left_top.x == 32 and left_top.y == 32 then
        Functions.draw_spawn(surface)
        for _, p in pairs(game.connected_players) do
            init_player(p, surface)
        end
        game.forces.player.chart(surface, {{-128, -128}, {128, 128}})
    end
end

local function on_player_joined_game(event)
    draw_arrows_gui()
    draw_depth_gui()
    if game.tick == 0 then
        return
    end
    local player = game.players[event.player_index]
    if player.online_time == 0 then
       init_player(player, game.surfaces['dungeons_floor0'])
    end
    if player.character == nil and player.ticks_to_respawn == nil then
       log('BUG: ' .. player.name .. ' is missing associated character and is not waiting to respawn')
       init_player(player, game.surfaces['dungeons_floor0'])
    end
    draw_light(player)
end

local function spawner_death(entity)
    local dungeontable = DungeonsTable.get_dungeontable()
    local tier = dungeontable.spawner_tier[entity.unit_number]

    if not tier then
        Functions.set_spawner_tier(entity, entity.surface.index)
        tier = dungeontable.spawner_tier[entity.unit_number]
    end

    for _ = 1, tier * 2, 1 do
        Functions.spawn_random_biter(entity.surface, entity.position)
    end

    dungeontable.spawner_tier[entity.unit_number] = nil
end

--make expansion rocks very durable against biters
local function on_entity_damaged(event)
    local dungeontable = DungeonsTable.get_dungeontable()
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.surface.name == 'nauvis' or entity.surface.name == 'dungeons_floor_arena' then
        return
    end
    local size = dungeontable.surface_size[entity.surface.index]
    if size < math.abs(entity.position.y) or size < math.abs(entity.position.x) then
        if entity.name == 'rock-big' then
            entity.health = entity.health + event.final_damage_amount
        end
        return
    end
    if entity.force.index ~= 3 then
        return
    end --Neutral Force
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.cause.force.index ~= 2 then
        return
    end --Enemy Force
    if math_random(1, 256) == 1 then
        return
    end
    if entity.name ~= 'rock-big' then
        return
    end
    entity.health = entity.health + event.final_damage_amount
end

local function on_player_mined_entity(event)
    local dungeontable = DungeonsTable.get_dungeontable()
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.name == 'rock-big' then
        local size = dungeontable.surface_size[entity.surface.index]
        if size < math.abs(entity.position.y) or size < math.abs(entity.position.x) then
            entity.surface.create_entity({name = entity.name, position = entity.position})
            entity.destroy()
	    local player = game.players[event.player_index]
            RPG.gain_xp(player, -10)
            Alert.alert_player_warning(player, 30, {'dungeons_tiered.too_small'}, {r = 0.98, g = 0.22, b = 0})
            event.buffer.clear()
            return
        end
    end
    if entity.type == 'simple-entity' then
        Functions.mining_events(entity)
        Functions.rocky_loot(event)
    end
    if entity.name ~= 'rock-big' then
        return
    end
    expand(entity.surface, entity.position)
end

local function on_entity_died(event)
    -- local rpg_extra = RPG.get('rpg_extra')
    -- local hp_units = BiterHealthBooster.get('biter_health_boost_units')
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.type == 'unit-spawner' then
        spawner_death(entity)
    end
    if entity.name ~= 'rock-big' then
        return
    end
    expand(entity.surface, entity.position)
end

local function get_map_gen_settings()
    local settings = {
        ['seed'] = math_random(1, 1000000),
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {treat_missing_as_default = false},
            ['decorative'] = {treat_missing_as_default = false}
        }
    }
    return settings
end

local function get_lowest_safe_floor(player)--获取最低安全层
    local dungeontable = DungeonsTable.get_dungeontable()
    local rpg = RPG.get('rpg_t')
    local level = rpg[player.index].level
    local sizes = dungeontable.surface_size
    local safe = dungeontable.original_surface_index
    local min_size = 200 + MIN_ROOMS_TO_DESCEND / 4
    for key, size in pairs(sizes) do
        --if size >= min_size and level >= (key + 1 - dungeontable.original_surface_index) * 10 and game.surfaces[key + 1] then --等级值的运算
        if size >= min_size and level >= (key + 1 - dungeontable.original_surface_index) * 1 and game.surfaces[key + 1] then --等级值的运算
            safe = key + 1
        else
            break
        end
    end
    if safe >= dungeontable.original_surface_index + 50 then
        safe = dungeontable.original_surface_index + 50
    end
    return safe
end

local function descend(player, button, shift)
    local dungeontable = DungeonsTable.get_dungeontable()
    local rpg = RPG.get('rpg_t')
    if player.surface.index >= dungeontable.original_surface_index + 50 then
        --player.print({'dungeons_tiered.max_depth'})--您已到达最深处了
        Alert.alert_player_warning(player, 20,{"dungeons_tiered.max_depth"})--发送消息
        return
    end
    if player.position.x ^ 2 + player.position.y ^ 2 > 400 then
        --player.print({'dungeons_tiered.only_on_spawn'})
        Alert.alert_player_warning(player, 20,{"dungeons_tiered.only_on_spawn"})--发送消息
        return
    end
    if rpg[player.index].level < (player.surface.index - dungeontable.original_surface_index) * 1 + 5 then --每层需要的等级差+基础等级
        --player.print({'dungeons_tiered.level_required', (player.surface.index - dungeontable.original_surface_index) * 1 + 5})
        Alert.alert_player_warning(player, 20,{'dungeons_tiered.level_required', (player.surface.index - dungeontable.original_surface_index) * 1 + 5})--发送消息
        return
    end
    local surface = game.surfaces[player.surface.index + 1]
    if not surface then
        if dungeontable.surface_size[player.surface.index] < 200 + MIN_ROOMS_TO_DESCEND/4 then
            --player.print({'dungeons_tiered.floor_size_required', MIN_ROOMS_TO_DESCEND})
            Alert.alert_player_warning(player, 20,{'dungeons_tiered.floor_size_required', MIN_ROOMS_TO_DESCEND})--发送消息
            return
        end
        surface = game.create_surface('dungeons_floor' .. player.surface.index - dungeontable.original_surface_index + 1, get_map_gen_settings())
        if surface.index % 5 == dungeontable.original_surface_index then  --每5层出现一个大尺寸出生点
            dungeontable.spawn_size = 60
        else
            dungeontable.spawn_size = 42
        end
        surface.request_to_generate_chunks({0, 0}, 2)
        surface.force_generate_chunk_requests()
        surface.daytime = 0.25 + 0.30 * (surface.index / (dungeontable.original_surface_index + 50)) --白天黑夜的比例
        surface.freeze_daytime = false --常白天
        surface.min_brightness = 0--最低亮度
        surface.brightness_visual_weights = {1, 1, 1}
        dungeontable.surface_size[surface.index] = 200
        dungeontable.treasures[surface.index] = 0
        --game.print({'dungeons_tiered.first_visit', player.name, rpg[player.index].level, surface.index - dungeontable.original_surface_index}, {r = 0.8, g = 0.5, b = 0})
        Alert.alert_all_players(15, {'dungeons_tiered.first_visit', player.name, rpg[player.index].level, surface.index - dungeontable.original_surface_index}, {r = 0.8, g = 0.5, b = 0})
        --Alert.alert_all_players(15, {"dungeons_tiered.first_visit", player.name, rpg[player.index].level, surface.index - 2}, {r=0.8,g=0.2,b=0},"recipe/artillery-targeting-remote", 0.7)
    end
    if button == defines.mouse_button_type.right then
        surface = game.surfaces[math.min(get_lowest_safe_floor(player), player.surface.index + 5)]
    end
    if shift then
        surface = game.surfaces[get_lowest_safe_floor(player)]
    end
    player.teleport(surface.find_non_colliding_position('character', {0, 0}, 50, 0.5), surface)
    player.character.destructible=true 
    local message = ('复活防蹲点机制：\n已到其他楼层，保护已解除\n祝你好运!') --预定义消息
    Alert.alert_player_warning(player, 2,message) --发送消息
    dungeons_help(player)--随机发送一条帮助信息
    --Alert.alert_player_warning(player, 20,{"dungeons_tiered.travel_down"})--发送消息
    --player.print({"dungeons_tiered.travel_down"})
end

local function ascend(player, button, shift)
    local dungeontable = DungeonsTable.get_dungeontable()
    if player.surface.index <= dungeontable.original_surface_index then
        --player.print({'dungeons_tiered.min_depth'})
        Alert.alert_player_warning(player, 20,{"dungeons_tiered.min_depth"})--发送消息
        return
    end
    if player.position.x ^ 2 + player.position.y ^ 2 > 400 then
        --player.print({'dungeons_tiered.only_on_spawn'})
        Alert.alert_player_warning(player, 20,{"dungeons_tiered.only_on_spawn"})--发送消息
        return
    end
    local surface = game.surfaces[player.surface.index - 1]
    if button == defines.mouse_button_type.right then
        surface = game.surfaces[math.max(dungeontable.original_surface_index, player.surface.index - 5)]
    end
    if shift then
        surface = game.surfaces[dungeontable.original_surface_index]
    end
    player.teleport(surface.find_non_colliding_position('character', {0, 0}, 50, 0.5), surface)
    player.character.destructible=true 
    local message = ('复活防蹲点机制：\n已到其他楼层，保护已解除\n祝你好运!') --预定义消息
    Alert.alert_player_warning(player, 2,message) --发送消息
    dungeons_help(player)--随机发送一条帮助信息
    --Alert.alert_player_warning(player, 20,{"dungeons_tiered.travel_up"})--发送消息
    --player.print({"dungeons_tiered.travel_up"})
end

local function on_built_entity(event)
    local dungeontable = DungeonsTable.get_dungeontable()
    local entity = event.created_entity
    if not entity or not entity.valid then
        return
    end
    if entity.name == 'spidertron' then
        if entity.surface.index < dungeontable.original_surface_index + 4 then  --5层以后才可以使用蜘蛛
            local player = game.players[event.player_index]
            local try_mine = player.mine_entity(entity, true)
            if not try_mine then
                if entity.valid then
                    entity.destroy()
                    player.insert({name = 'spidertron', count = 1})
                end
            end
            Alert.alert_player_warning(player, 8, {'dungeons_tiered.spidertron_not_allowed'})
        end
    end
end

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local button = event.button
    local shift = event.shift
    local player = game.players[event.element.player_index]
    if event.element.name == 'dungeon_down' then
        descend(player, button, shift)
        return
    elseif event.element.name == 'dungeon_up' then
        ascend(player, button, shift)
        return
    end
end

local function on_surface_created(event)
    local dungeontable = DungeonsTable.get_dungeontable()
    local forceshp = BiterHealthBooster.get('biter_health_boost_forces')
    local force = game.create_force('enemy' .. event.surface_index)
    dungeontable.enemy_forces[event.surface_index] = force
    forceshp[force.index] = 1
    dungeontable.depth[event.surface_index] = 100 * event.surface_index - (dungeontable.original_surface_index * 100)
    BiterHealthBooster.set_surface_activity(game.surfaces[event.surface_index].name, true)
end

local function on_player_changed_surface(event)
    draw_depth_gui()
    draw_light(game.players[event.player_index])
end

--local Token = require 'utils.token'  --引入token系统
--local Task = require 'utils.task'  --引入定时任务系统

local un_player_destructible =
Token.register(  
    function(player)
        if player and player.character.valid then 
            player.character.destructible=true 
            local message = ('复活防蹲点机制：保护已解除，\n祝你好运!') --预定义消息
            Alert.alert_player_warning(player, 2,message) --发送消息
        end
    end
)--定义一个token系统上的解除无敌的的任务

local function on_player_respawned(event)--复活
    draw_light(game.players[event.player_index])--设置光亮值
    local player = game.players[event.player_index]--获取玩家id
    player.character.destructible=false  --赋予无敌
    local message = ('复活防蹲点机制：赋予保护20s!\n此窗口即是倒计时!')--预定义消息-如果玩家下线则没法解除 所以转移楼层也会解除
    Alert.alert_player_warning(player, 20,message)--发送消息
    Task.set_timeout_in_ticks(60*20, un_player_destructible, player)  --定时20s以后调用解除无敌
    local entities = player.surface.find_entities_filtered{position=player.position, radius = 20 , name =biter_name,force = game.forces.enemy}
        if #entities ~= 0 then for k,v in pairs(entities) do v.die() end
    end--循环查找范围内阵营为enemy的虫子，执行死亡操作
    player.insert({name = 'raw-fish', count = 4})--初始物品-鱼
    player.insert({name = 'poison-capsule', count = 2})--初始物品-剧毒胶囊
    player.insert({name = 'slowdown-capsule', count = 2})--初始物品-减速胶囊
    player.insert({name = 'distractor-capsule', count = 4})--初始物品-掩护无人机胶囊
    player.insert({name = 'defender-capsule', count = 2})--初始物品-防御无人机胶囊
end

-- local function on_player_changed_position(event)
--   local player = game.players[event.player_index]
--   local position = player.position
-- 	local surface = player.surface
-- 	if surface.index < 2 then return end
-- 	local size = dungeontable.surface_size[surface.index]
-- 	if (size >= math.abs(player.position.y) and size < math.abs(player.position.y) + 1) or (size >= math.abs(player.position.x) and size < math.abs(player.position.x) + 1) then
--       Alert.alert_player_warning(player, 30, {"dungeons_tiered.too_small"}, {r=0.98,g=0.22,b=0})
--   end
-- end

--local function transfer_items(surface_index)--下一层物品传递到上一层--因为性能不如原版关联箱，所以注释掉了
--    local dungeontable = DungeonsTable.get_dungeontable()
--    if surface_index > dungeontable.original_surface_index then
--        local inputs = dungeontable.transport_chests_inputs[surface_index]
--        local outputs = dungeontable.transport_chests_outputs[surface_index - 1]
--        for i = 1, 2, 1 do
--            if inputs[i].valid and outputs[i].valid then
--                local input_inventory = inputs[i].get_inventory(defines.inventory.chest)
--                local output_inventory = outputs[i].get_inventory(defines.inventory.chest)
--                input_inventory.sort_and_merge()
--                output_inventory.sort_and_merge()
--                for ii = 1, #input_inventory, 1 do
--                    if input_inventory[ii].valid_for_read then
--                        local count = output_inventory.insert(input_inventory[ii])
--                        input_inventory[ii].count = input_inventory[ii].count - count
--                    end
--                end
--            end
--        end
--    end
--end

-- 用于连接不同图层的电线杆的预处理函数
function force_connect_poles(pole1, pole2)
	if not pole1 then return end
	if not pole1.valid then return end
	if not pole2 then return end
	if not pole2.valid then return end

	-- force connections for testing (by placing many poles around the substations)
	-- for _, e in pairs(pole1.surface.find_entities_filtered{type="electric-pole", position = pole1.position, radius = 10}) do
	-- 	pole1.connect_neighbour(e)
	-- end

	-- for _, e in pairs(pole2.surface.find_entities_filtered{type="electric-pole", position = pole2.position, radius = 10}) do
	-- 	pole2.connect_neighbour(e)
	-- end

	-- NOTE: "connect_neighbour" returns false when the entities are already connected as well
	pole1.disconnect_neighbour(pole2)
	local success = pole1.connect_neighbour(pole2)
	if success then return end

	local pole1_neighbours = pole1.neighbours['copper']
	local pole2_neighbours = pole2.neighbours['copper']

	-- try avoiding disconnecting more poles than needed
	local disconnect_from_pole1 = false
	local disconnect_from_pole2 = false

	if #pole1_neighbours >= #pole2_neighbours then
		disconnect_from_pole1 = true
	end

	if #pole2_neighbours >= #pole1_neighbours then
		disconnect_from_pole2 = true
	end

	if disconnect_from_pole1 then
		-- Prioritise disconnecting last connections as those are most likely redundant (at least for holds, although even then it's not always the case)
		for i = #pole1_neighbours, 1, -1 do
			local e = pole1_neighbours[i]
			-- only disconnect poles from same surface
			if e and e.valid and e.surface.name == pole1.surface.name then
				pole1.disconnect_neighbour(e)
				break
			end
		end
	end

	if disconnect_from_pole2 then
		-- Prioritise disconnecting last connections as those are most likely redundant (at least for holds, although even then it's not always the case)
		for i = #pole2_neighbours, 1, -1 do
			local e = pole2_neighbours[i]
			-- only disconnect poles from same surface
			if e and e.valid and e.surface.name == pole2.surface.name then
				pole2.disconnect_neighbour(e)
				break
			end
		end
	end

	local success2 = pole1.connect_neighbour(pole2)
	if not success2 then
		-- This can happen if in future pole reach connection limit(5) with poles from other surfaces
		log("Error: power fix didn't work")
	end
end
-- 用于连接不同图层的电线杆的预处理函数

local function transfer_signals(surface_index)--上一层信号传递到下一层
    local dungeontable = DungeonsTable.get_dungeontable()
    if surface_index > dungeontable.original_surface_index then
        local inputs = dungeontable.transport_poles_inputs[surface_index - 1]
        local outputs = dungeontable.transport_poles_outputs[surface_index]

        local connect_poles1 = dungeontable.transport_poles_inputs[surface_index - 1][1]
        local connect_poles2 = dungeontable.transport_poles_inputs[surface_index][1]
        force_connect_poles(connect_poles1, connect_poles2)--链接左侧电网
        local connect_poles3 = dungeontable.transport_poles_inputs[surface_index - 1][2]
        local connect_poles4 = dungeontable.transport_poles_inputs[surface_index][2]
        force_connect_poles(connect_poles3, connect_poles4)--链接右侧电网

        for i = 1, 2, 1 do
            if inputs[i].valid and outputs[i].valid then
                local signals = inputs[i].get_merged_signals(defines.circuit_connector_id.electric_pole)
                local combi = outputs[i].get_or_create_control_behavior()
                for ii = 1, 15, 1 do
                    if signals and signals[ii] then
                        combi.set_signal(ii, signals[ii])
                    else
                        combi.set_signal(ii, nil)
                    end
                end
            end
        end
    end
end

local function setup_magic()
    local rpg_spells = RPG.get("rpg_spells")
end

local function on_init()
    -- dungeons depends on rpg.main depends on modules.explosives depends on modules.collapse
    -- without disabling collapse, it starts logging lots of errors after ~1 week.
    Collapse.start_now(false)
    local dungeontable = DungeonsTable.get_dungeontable()
    local forceshp = BiterHealthBooster.get('biter_health_boost_forces')
    local force = game.create_force('dungeon')
    force.set_friend('enemy', false)
    force.set_friend('player', false)

    local surface = game.create_surface('dungeons_floor0', get_map_gen_settings())

    surface.request_to_generate_chunks({0, 0}, 2)
    surface.force_generate_chunk_requests()
    surface.daytime = 0.25
    surface.freeze_daytime = false

    local nauvis = game.surfaces[1]
    nauvis.daytime = 0.25
    nauvis.freeze_daytime = false
    local map_settings = nauvis.map_gen_settings
    map_settings.height = 3
    map_settings.width = 3
    nauvis.map_gen_settings = map_settings
    for chunk in nauvis.get_chunks() do
        nauvis.delete_chunk({chunk.x, chunk.y})
    end

    game.forces.player.manual_mining_speed_modifier = 0.5 --采矿速度

    game.map_settings.enemy_evolution.destroy_factor = 0.0125 --摧毁进化因子
    game.map_settings.enemy_evolution.pollution_factor = 0.0025 --污染进化因子
    game.map_settings.enemy_evolution.time_factor = 0.0005 --时间进化因子
    game.map_settings.enemy_expansion.enabled = true --扩张
    game.map_settings.enemy_expansion.max_expansion_cooldown = 18000 --最大扩张间隔
    game.map_settings.enemy_expansion.min_expansion_cooldown = 3600 --最小扩张间隔
    game.map_settings.enemy_expansion.settler_group_max_size = 128 --最大扩张规模
    game.map_settings.enemy_expansion.settler_group_min_size = 16 --最小扩张规模
    game.map_settings.enemy_expansion.max_expansion_distance = 16 --最大扩张距离
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.90 --污染值仇恨修正

    dungeontable.tiered = true
    dungeontable.depth[surface.index] = 0
    dungeontable.depth[nauvis.index] = 0
    dungeontable.surface_size[surface.index] = 200
    dungeontable.treasures[surface.index] = 0
    dungeontable.item_blacklist = true
    dungeontable.original_surface_index = surface.index
    dungeontable.enemy_forces[nauvis.index] = game.forces.enemy
    dungeontable.enemy_forces[surface.index] = game.create_force('enemy' .. surface.index)
    forceshp[game.forces.enemy.index] = 1
    forceshp[dungeontable.enemy_forces[surface.index].index] = 1
    BiterHealthBooster.set_surface_activity('dungeons_floor0', true)

    game.forces.player.technologies['land-mine'].enabled = false  --禁止地雷科技
    game.forces.player.technologies['landfill'].enabled = false  --禁止悬崖炸药科技
    game.forces.player.technologies['cliff-explosives'].enabled = false  --禁止填海料科技
    Research.Init(dungeontable)
    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(false)
    Autostash.bottom_button(true)
    Autostash.set_dungeons_initial_level(surface.index)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    RPG.set_surface_name('dungeons_floor')
    local rpg_table = RPG.get('rpg_extra')
    rpg_table.personal_tax_rate = 0
    rpg_table.enable_mana = true
    setup_magic()--开启魔法

    local T = MapInfo.Pop_info()
    T.localised_category = 'dungeons_tiered'
    T.main_caption_color = {r = 0, g = 0, b = 0}
    T.sub_caption_color = {r = 150, g = 0, b = 20}
end

local function on_tick()
    local dungeontable = DungeonsTable.get_dungeontable()
    if #dungeontable.transport_surfaces > 0 then
        for _, surface_index in pairs(dungeontable.transport_surfaces) do
            --transfer_items(surface_index)--因为性能不如原版关联箱，所以注释掉了
            transfer_signals(surface_index)
        end
    end
    --[[
	if game.tick % 4 ~= 0 then return end

	local surface = game.surfaces["dungeons"]

	local entities = surface.find_entities_filtered({name = "rock-big"})
	if not entities[1] then return end

	local entity = entities[math_random(1, #entities)]

	surface.request_to_generate_chunks(entity.position, 3)
	surface.force_generate_chunk_requests()

	game.forces.player.chart(surface, {{entity.position.x - 32, entity.position.y - 32}, {entity.position.x + 32, entity.position.y + 32}})

	entity.die()
	]]
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(60, on_tick)
Event.add(defines.events.on_marked_for_deconstruction, Functions.on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
-- Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_surface_created, on_surface_created)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_gui_opened, on_gui_opened) --注册这个事件以调用
Event.add(defines.events.on_player_died, on_player_died)

Changelog.SetVersions({
	{ ver = 'next', date = 'the future', desc = 'Make suggestions in the comfy #dungeons discord channel' },
	{ ver = '1.1.1', date = '2022-04-10', desc = [[
Balancing patch
* Evolution goes up faster with floor level 0.05/level -> 0.06/level; e.g. floor 20 now like floor 24 before
* Now require 100 open rooms to descend
* Treasure rooms
  * Occur less frequently as each subsequent one is found. was 1 in 30 + 10*Nfound now 1 in 30 + 15*Nfound
  * Rebalanced ores to match end-game science needs. Was very low on copper
* Loot
  * Ammo/follower robot frequency ~0.5x previous
  * Loot is calculated at floor evolution * 0.9
  * Loot/box down by 0.75x
* Rocks
  * Ore from rocks from 25 + 25*floor to 40 + 15*floor capped at floor 15
  * Rebalanced to include ~10% more coal to give coal for power
* Require getting to room 100 before you can descend
* Science from rooms 40-160+2.5*floor to 60-300+2.5*floor
* Atomic bomb research moved to 40-50
]]},
	{ ver = '1.1', date = '2022-03-13', desc = [[
* All research is now found at random.
  * Red science floors 0-1
  * Green on floors 1-5
  * Gray on floors 5-10
  * Blue on floors 8-13
  * Blue/gray on floors 10-14
  * Purple on floors 12-19
  * Yellow on floors 14-21
  * White on floors 20-25
  * Atomic Bomb/Spidertron on floors 22-25
* Add melee mode toggle to top bar. Keeps weapons in main inventory if possible.
* Ore from rocks nerfed. Used to hit max value on floor 2, now scales up from
  floors 0-19 along with ore from rooms. After floor 20 ore from rooms scales up faster.
* Treasure rooms
  * Rescaled to have similar total resources regardless of size
  * Unlimited number of rooms but lower frequency
  * Loot is limited to available loot 3 floors lower, but slightly more total value than before.
* Autostash and corpse clearing from Mountain Fortress enabled
* Harder rooms will occur somewhat farther out on the early floors.
* Spawners and worm counts bounded in early rooms.
]]},
	{ ver = '1.0', date = 'past', desc = "Pre-changelog version of multi-floor dungeons" },
})
