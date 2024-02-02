local Public = {}

local FLOOR_ZERO_ROCK_ORE = 40
local ROCK_ORE_INCREASE_PER_FLOOR = 15
local FLOOR_FOR_MAX_ROCK_ORE = 15
local LOOT_EVOLUTION_SCALE_FACTOR = 0.9
local LOOT_MULTIPLIER = 3000
local EVOLUTION_PER_FLOOR = 0.06

local BiterRaffle = require 'utils.functions.biter_raffle'
local LootRaffle = require 'utils.functions.loot_raffle'
local Get_noise = require 'utils.get_noise'
local DungeonsTable = require 'maps.dungeons.table'

local table_shuffle_table = table.shuffle_table
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor

-- Epic loot chest is 0.05 * (floor + 1) * 4000 * 8 + rand(512,1024)
-- So floor 0 = 2112 .. 2624
-- floor 4 = 8512 .. 9024
-- floor 9 = 16512 .. 17024
-- floor 19 = 32512 .. 33024
LootRaffle.TweakItemWorth({
	['modular-armor'] = 512, -- floors 1-5 from research.lua
	['power-armor'] = 4096, -- floors 8-13 from research.lua
	['personal-laser-defense-equipment'] = 1536, -- floors 10-14 from research.lua
	['power-armor-mk2'] = 24576, -- floors 14-21 from research.lua
	-- reduce ammo/follower rates
    ['firearm-magazine'] = 8,
    ['piercing-rounds-magazine'] = 16,
    ['uranium-rounds-magazine'] = 128,
    ['shotgun-shell'] = 8,
    ['piercing-shotgun-shell'] = 64,
    ['flamethrower-ammo'] = 128,
    ['rocket'] = 16,
    ['explosive-rocket'] = 128,
    ['grenade'] = 32,
    ['cluster-grenade'] = 128,
    ['poison-capsule'] = 64,
    ['slowdown-capsule'] = 32,
    ['defender-capsule'] = 96,
    ['distractor-capsule'] = 512,
    ['destroyer-capsule'] = 2048,
})

function Public.get_dungeon_evolution_factor(surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local e = dungeontable.depth[surface_index] * EVOLUTION_PER_FLOOR / 100
    if dungeontable.tiered then
        e = math.min(e, (surface_index - dungeontable.original_surface_index) * EVOLUTION_PER_FLOOR + EVOLUTION_PER_FLOOR)
    end
    return e
end

function Public.get_loot_evolution_factor(surface_index)
    return Public.get_dungeon_evolution_factor(surface_index) * LOOT_EVOLUTION_SCALE_FACTOR
end

local function blacklist(surface_index, special)
    local dungeontable = DungeonsTable.get_dungeontable()
    local evolution_factor = Public.get_loot_evolution_factor(surface_index)
    if special then
	-- treasure rooms act as if they are 3 levels farther down.
	evolution_factor = evolution_factor + 3 * EVOLUTION_PER_FLOOR
    end
    local blacklists = {}
    --general unused items on dungeons
    blacklists['cliff-explosives'] = true
    --items that would trivialize stuff if dropped too early
    if dungeontable.item_blacklist then
        if evolution_factor < 0.9 then -- floor 18
            blacklists['power-armor-mk2'] = true
            blacklists['fusion-reactor-equipment'] = true
            blacklists['rocket-silo'] = true
	        blacklists['atomic-bomb'] = true
        end
        if evolution_factor < 0.7 then -- floor 14
            blacklists['energy-shield-mk2-equipment'] = true
            blacklists['personal-laser-defense-equipment'] = true
            blacklists['personal-roboport-mk2-equipment'] = true
            blacklists['battery-mk2-equipment'] = true
            blacklists['artillery-turret'] = true
            blacklists['artillery-wagon'] = true
            blacklists['power-armor'] = true
        end
	if evolution_factor < 0.55 then -- floor 11
            blacklists['discharge-defense-equipment'] = true
            blacklists['discharge-defense-remote'] = true
            blacklists['nuclear-reactor'] = true
	end
        if evolution_factor < 0.4 then -- floor 8
            blacklists['steam-turbine'] = true
            blacklists['heat-exchanger'] = true
            blacklists['heat-pipe'] = true
            blacklists['express-loader'] = true
            blacklists['modular-armor'] = true
            blacklists['energy-shield-equipment'] = true
            blacklists['battery-equipment'] = true
        end
    end
    return blacklists
end

local function special_loot(value)
    local items = {
        [1] = {item = 'tank-machine-gun', value = 16384},
        [2] = {item = 'tank-cannon', value = 32728},
        [3] = {item = 'artillery-wagon-cannon', value = 65536}
    }
    if math_random(1, 20) == 1 then
        local roll = math_random(1, #items)
        if items[roll].value < value then
            return {loot = {name = items[roll].item, count = 1}, value = value - items[roll].value}
        end
    end
    return {loot = nil, value = value}
end

function Public.roll_spawner_name()
    if math_random(1, 3) == 1 then
        return 'spitter-spawner'
    end
    return 'biter-spawner'
end

function Public.roll_worm_name(surface_index)
    return BiterRaffle.roll('worm', Public.get_dungeon_evolution_factor(surface_index))
end

function Public.get_crude_oil_amount(surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local amount = math_random(200000, 400000) + Public.get_dungeon_evolution_factor(surface_index) * 500000
    if dungeontable.tiered then
        amount = amount / 4
    end
    return amount
end

function Public.get_common_resource_amount(surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local amount = math_random(350, 700) + Public.get_dungeon_evolution_factor(surface_index) * 16000
    if dungeontable.tiered then
        amount = amount / 8
        local floor = surface_index - dungeontable.original_surface_index
	-- rocks stop going up here, so more than make up for it in resources on ground
	if floor > FLOOR_FOR_MAX_ROCK_ORE then
	    amount = amount * (1+(floor - FLOOR_FOR_MAX_ROCK_ORE)/10)
	end
    end
    return amount
end

function Public.get_base_loot_value(surface_index)
    return Public.get_loot_evolution_factor(surface_index) * LOOT_MULTIPLIER
end

local function get_loot_value(surface_index, multiplier)
    return Public.get_base_loot_value(surface_index) * multiplier
end

function Public.common_loot_crate(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 1) + math_random(8, 16), 16, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'wooden-chest', position = position, force = 'player'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.destructible=false
end

function Public.uncommon_loot_crate(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 2) + math_random(32, 64), 16, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'iron-chest', position = position, force = 'player'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.destructible=false
end

function Public.rare_loot_crate(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 4) + math_random(128, 256), 32, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'steel-chest', position = position, force = 'player'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.destructible=false
end

function Public.epic_loot_crate(surface, position, special)
    local dungeontable = DungeonsTable.get_dungeontable()
    local loot_value = get_loot_value(surface.index, 8) + math_random(512, 1024)
    if special then
	loot_value = loot_value * 1.5
    end
    local bonus_loot = nil
    if dungeontable.tiered and loot_value > 32000 and Public.get_dungeon_evolution_factor(surface.index) > 1 then
        local bonus = special_loot(loot_value)
        bonus_loot = bonus.loot
        loot_value = bonus.value
    end
    local item_stacks = LootRaffle.roll(loot_value, 48, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'logistic-chest-storage', position = position, force = 'player'})
    if bonus_loot then
        container.insert(bonus_loot)
    end
    if item_stacks then
        for _, item_stack in pairs(item_stacks) do
            container.insert(item_stack)
        end
    end
    container.destructible=false
end

function Public.crash_site_chest(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 3) + math_random(160, 320), 48, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'crash-site-chest-' .. math_random(1, 2), position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
end

function Public.market(surface, position)--随机的商店交换列表--价格不能超过6w5
    local offers = {
        --{price = {{'pistol', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(3, 4)}},
        --{price = {{'submachine-gun', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        --{price = {{'shotgun', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(12, 18)}},
        --{price = {{'combat-shotgun', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(7, 10)}},
        --{price = {{'rocket-launcher', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(7, 10)}},
        --{price = {{'flamethrower', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(12, 18)}},
        --{price = {{'light-armor', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        --{price = {{'heavy-armor', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(15, 20)}},
        --{price = {{'modular-armor', 1}}, offer = {type = 'give-item', item = 'advanced-circuit', count = math_random(15, 20)}},
        --{price = {{'night-vision-equipment', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(3, 4)}},
        --{price = {{'solar-panel-equipment', 1}}, offer = {type = 'give-item', item = 'copper-plate', count = math_random(15, 25)}},
        --{price = {{'red-wire', 100}}, offer = {type = 'give-item', item = 'copper-cable', count = math_random(75, 100)}},
        --{price = {{'green-wire', 100}}, offer = {type = 'give-item', item = 'copper-cable', count = math_random(75, 100)}},
        --{price = {{'empty-barrel', 10}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(6, 8)}},
        --{price = {{'arithmetic-combinator', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(15, 25)}},
        --{price = {{'decider-combinator', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(15, 25)}},
        --{price = {{'constant-combinator', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(9, 12)}},
        --{price = {{'power-switch', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(9, 12)}},
        --{price = {{'programmable-speaker', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(20, 30)}},
        --{price = {{'belt-immunity-equipment', 1}}, offer = {type = 'give-item', item = 'advanced-circuit', count = math_random(2, 3)}},
        --{price = {{'discharge-defense-remote', 1}}, offer = {type = 'give-item', item = 'electronic-circuit', count = 1}},
        --{price = {{'rail-signal', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        --{price = {{'rail-chain-signal', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        --{price = {{'train-stop', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(75, 100)}},
        --{price = {{'locomotive', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(30, 40)}},
        --{price = {{'cargo-wagon', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        --{price = {{'fluid-wagon', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        --{price = {{'car', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        --{price = {{'radar', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        --{price = {{'cannon-shell', 10}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(7, 10)}},
        --{price = {{'uranium-cannon-shell', 10}}, offer = {type = 'give-item', item = 'uranium-238', count = math_random(7, 10)}},
        {price={{'coin',math_random(80,120)}},offer={type='give-item',item='wood',count=math_random(1000,3000)}},--木材
        {price={{'coin',math_random(320,480)}},offer={type='give-item',item='coal',count=math_random(1000,3000)}},--煤矿
        {price={{'coin',math_random(160,240)}},offer={type='give-item',item='stone',count=math_random(1000,3000)}},--石矿
        {price={{'coin',math_random(160,240)}},offer={type='give-item',item='iron-ore',count=math_random(1000,3000)}},--铁矿
        {price={{'coin',math_random(160,240)}},offer={type='give-item',item='copper-ore',count=math_random(1000,3000)}},--铜矿
        {price={{'coin',math_random(6400,9600)}},offer={type='give-item',item='uranium-ore',count=math_random(1000,3000)}},--铀矿
        {price={{'coin',math_random(40,60)}},offer={type='give-item',item='raw-fish',count=math_random(25,175)}},--鲜鱼
        {price={{'coin',math_random(400,600)}},offer={type='give-item',item='automation-science-pack',count=math_random(50,150)}},--机自研究包(红瓶)
        {price={{'coin',math_random(640,960)}},offer={type='give-item',item='logistic-science-pack',count=math_random(50,150)}},--物流研究包(绿瓶)
        {price={{'coin',math_random(3200,4800)}},offer={type='give-item',item='military-science-pack',count=math_random(50,150)}},--军备研究包(灰瓶)
        {price={{'coin',math_random(4000,6000)}},offer={type='give-item',item='chemical-science-pack',count=math_random(50,150)}},--化工研究包(蓝瓶)
        {price={{'coin',math_random(22400,33600)}},offer={type='give-item',item='production-science-pack',count=math_random(50,150)}},--生产研究包(紫瓶)
        {price={{'coin',math_random(28000,42000)}},offer={type='give-item',item='utility-science-pack',count=math_random(50,150)}},--效能研究包(黄瓶)
        {price={{'coin',math_random(40000,60000)}},offer={type='give-item',item='space-science-pack',count=math_random(50,150)}},--太空研究包(白瓶)
        {price={{'coin',math_random(700,1050)}},offer={type='give-item',item='radar',count=math_random(13,37)}},--雷达
        {price={{'coin',math_random(200,300)}},offer={type='give-item',item='stone-wall',count=math_random(25,75)}},--墙壁
        {price={{'coin',math_random(240,360)}},offer={type='give-item',item='solar-panel-equipment',count=math_random(1,3)}},--太阳能模块
        {price={{'coin',math_random(20800,31200)}},offer={type='give-item',item='fusion-reactor-equipment',count=math_random(1,3)}},--聚变堆模块
        {price={{'coin',math_random(240,360)}},offer={type='give-item',item='battery-equipment',count=math_random(1,3)}},--电池组模块
        {price={{'coin',math_random(4800,7200)}},offer={type='give-item',item='battery-mk2-equipment',count=math_random(1,3)}},--电池组模块MK2
        {price={{'coin',math_random(240,360)}},offer={type='give-item',item='belt-immunity-equipment',count=math_random(1,5)}},--锚定模块
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='exoskeleton-equipment',count=math_random(1,3)}},--外骨骼模块
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='personal-roboport-equipment',count=math_random(1,3)}},--机器人指令模块
        {price={{'coin',math_random(24000,36000)}},offer={type='give-item',item='personal-roboport-mk2-equipment',count=math_random(1,3)}},--机器人指令模块MK2
        {price={{'coin',math_random(240,360)}},offer={type='give-item',item='night-vision-equipment',count=math_random(1,3)}},--夜视模块
        {price={{'coin',math_random(240,360)}},offer={type='give-item',item='energy-shield-equipment',count=math_random(1,3)}},--能量盾模块
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='energy-shield-mk2-equipment',count=math_random(1,3)}},--能量盾模块MK2
        {price={{'coin',math_random(5072,7608)}},offer={type='give-item',item='personal-laser-defense-equipment',count=math_random(1,3)}},--激光防御模块
        {price={{'coin',math_random(6560,9840)}},offer={type='give-item',item='discharge-defense-equipment',count=math_random(1,3)}},--放电防御模块
        {price={{'coin',math_random(1000,1500)}},offer={type='give-item',item='gun-turret',count=math_random(13,37)}},--机枪炮塔
        {price={{'coin',math_random(5200,7800)}},offer={type='give-item',item='laser-turret',count=math_random(13,37)}},--激光炮塔
        {price={{'coin',math_random(4600,6900)}},offer={type='give-item',item='flamethrower-turret',count=math_random(13,37)}},--火焰炮塔
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='spidertron-remote',count=math_random(1,2)}},--蜘蛛机甲遥控器
        {price={{'coin',math_random(60,90)}},offer={type='give-item',item='rocket-launcher',count=math_random(1,2)}},--火箭筒
        {price={{'coin',math_random(208,312)}},offer={type='give-item',item='combat-shotgun',count=math_random(1,2)}},--冲锋霰弹枪
        {price={{'coin',math_random(70,105)}},offer={type='give-item',item='submachine-gun',count=math_random(1,2)}},--冲锋枪
        {price={{'coin',math_random(90,135)}},offer={type='give-item',item='shotgun',count=math_random(1,2)}},--霰弹枪
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='discharge-defense-remote',count=math_random(1,2)}},--放电防御瞄准器
        {price={{'coin',math_random(600,900)}},offer={type='give-item',item='grenade',count=math_random(25,75)}},--手雷
        {price={{'coin',math_random(2200,3300)}},offer={type='give-item',item='defender-capsule',count=math_random(25,75)}},--防御无人机胶囊
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='uranium-rounds-magazine',count=math_random(50,150)}},--贫铀弹匣
        {price={{'coin',math_random(2600,3900)}},offer={type='give-item',item='flamethrower-ammo',count=math_random(25,75)}},--油料储罐
        {price={{'coin',math_random(2800,4200)}},offer={type='give-item',item='rocket',count=math_random(50,150)}},--火箭弹
        {price={{'coin',math_random(4400,6600)}},offer={type='give-item',item='explosive-rocket',count=math_random(50,150)}},--爆破火箭弹
        {price={{'coin',math_random(18400,27600)}},offer={type='give-item',item='atomic-bomb',count=math_random(1,10)}},--原子火箭弹
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='piercing-shotgun-shell',count=math_random(50,150)}},--穿甲霰弹
        {price={{'coin',math_random(1600,2400)}},offer={type='give-item',item='cannon-shell',count=math_random(50,150)}},--制式炮弹
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='explosive-cannon-shell',count=math_random(50,150)}},--爆破炮弹
        {price={{'coin',math_random(4000,6000)}},offer={type='give-item',item='uranium-cannon-shell',count=math_random(50,150)}},--贫铀炮弹
        {price={{'coin',math_random(6400,9600)}},offer={type='give-item',item='explosive-uranium-cannon-shell',count=math_random(50,150)}},--爆破贫铀炮弹
        {price={{'coin',math_random(600,900)}},offer={type='give-item',item='land-mine',count=math_random(25,75)}},--地雷
        {price={{'coin',math_random(5200,7800)}},offer={type='give-item',item='cluster-grenade',count=math_random(25,75)}},--集束手雷
        {price={{'coin',math_random(1000,1500)}},offer={type='give-item',item='poison-capsule',count=math_random(25,75)}},--剧毒胶囊
        {price={{'coin',math_random(1000,1500)}},offer={type='give-item',item='slowdown-capsule',count=math_random(25,75)}},--减速胶囊
        {price={{'coin',math_random(10400,15600)}},offer={type='give-item',item='distractor-capsule',count=math_random(25,75)}},--掩护无人机胶囊
        {price={{'coin',math_random(24000,36000)}},offer={type='give-item',item='destroyer-capsule',count=math_random(12,50)}},--进攻无人机胶囊
        {price={{'coin',math_random(320,480)}},offer={type='give-item',item='firearm-magazine',count=math_random(50,150)}},--标准弹匣
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='piercing-rounds-magazine',count=math_random(50,150)}},--穿甲弹匣
        {price={{'coin',math_random(400,600)}},offer={type='give-item',item='shotgun-shell',count=math_random(50,150)}},--霰弹
        {price={{'coin',math_random(416,624)}},offer={type='give-item',item='car',count=math_random(1,5)}},--汽车
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='tank',count=math_random(1,5)}},--坦克
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='modular-armor',count=math_random(1,5)}},--模块装甲
        {price={{'coin',math_random(12160,18240)}},offer={type='give-item',item='power-armor',count=math_random(1,3)}},--能量装甲
        {price={{'coin',math_random(160,240)}},offer={type='give-item',item='light-armor',count=math_random(1,7)}},--轻型护甲
        {price={{'coin',math_random(1120,1680)}},offer={type='give-item',item='heavy-armor',count=math_random(1,7)}},--重型护甲
        {price={{'coin',math_random(300,450)}},offer={type='give-item',item='burner-mining-drill',count=math_random(13,37)}},--热能采矿机
        {price={{'coin',math_random(540,810)}},offer={type='give-item',item='assembling-machine-1',count=math_random(13,37)}},--组装机1型
        {price={{'coin',math_random(360,540)}},offer={type='give-item',item='repair-pack',count=math_random(25,75)}},--修理包
        {price={{'coin',math_random(560,840)}},offer={type='give-item',item='electric-mining-drill',count=math_random(13,37)}},--电力采矿机
        {price={{'coin',math_random(180,270)}},offer={type='give-item',item='boiler',count=math_random(13,37)}},--锅炉
        {price={{'coin',math_random(120,180)}},offer={type='give-item',item='steam-engine',count=math_random(3,10)}},--蒸汽机
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='assembling-machine-2',count=math_random(13,37)}},--组装机2型
        {price={{'coin',math_random(220,330)}},offer={type='give-item',item='lab',count=math_random(3,10)}},--研究中心
        {price={{'coin',math_random(800,1200)}},offer={type='give-item',item='steel-furnace',count=math_random(13,37)}},--钢炉
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='solar-panel',count=math_random(13,37)}},--太阳能板
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='accumulator',count=math_random(13,37)}},--蓄电器
        {price={{'coin',math_random(560,840)}},offer={type='give-item',item='pumpjack',count=math_random(5,15)}},--抽油机
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='speed-module',count=math_random(13,37)}},--速度插件1
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='effectivity-module',count=math_random(13,37)}},--节能插件1
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='productivity-module',count=math_random(13,37)}},--产能插件1
        {price={{'coin',math_random(2200,3300)}},offer={type='give-item',item='electric-furnace',count=math_random(13,37)}},--电炉
        {price={{'coin',math_random(6800,10200)}},offer={type='give-item',item='assembling-machine-3',count=math_random(13,37)}},--组装机3型
        {price={{'coin',math_random(1160,1740)}},offer={type='give-item',item='beacon',count=math_random(3,10)}},--插件效果分享塔
        {price={{'coin',math_random(560,840)}},offer={type='give-item',item='oil-refinery',count=math_random(3,10)}},--炼油厂
        {price={{'coin',math_random(2600,3900)}},offer={type='give-item',item='heat-exchanger',count=math_random(13,37)}},--换热器
        {price={{'coin',math_random(720,1080)}},offer={type='give-item',item='steam-turbine',count=math_random(3,10)}},--汽轮机
        {price={{'coin',math_random(1000,1500)}},offer={type='give-item',item='heat-pipe',count=math_random(13,37)}},--热管
        {price={{'coin',math_random(16000,24000)}},offer={type='give-item',item='speed-module-2',count=math_random(13,37)}},--速度插件2
        {price={{'coin',math_random(16000,24000)}},offer={type='give-item',item='effectivity-module-2',count=math_random(13,37)}},--节能插件2
        {price={{'coin',math_random(16000,24000)}},offer={type='give-item',item='productivity-module-2',count=math_random(13,37)}},--产能插件2
        {price={{'coin',math_random(220,330)}},offer={type='give-item',item='chemical-plant',count=math_random(3,10)}},--化工厂
        {price={{'coin',math_random(7400,11000)}},offer={type='give-item',item='speed-module-3',count=math_random(1,3)}},--速度插件3
        {price={{'coin',math_random(7400,11000)}},offer={type='give-item',item='effectivity-module-3',count=math_random(1,4)}},--节能插件3
        {price={{'coin',math_random(7400,11000)}},offer={type='give-item',item='productivity-module-3',count=math_random(1,3)}},--产能插件3
        {price={{'coin',math_random(28000,42000)}},offer={type='give-item',item='nuclear-reactor',count=math_random(3,10)}},--核反应堆
        {price={{'coin',math_random(32000,48000)}},offer={type='give-item',item='centrifuge',count=math_random(13,37)}},--离心机
        {price={{'coin',math_random(64,96)}},offer={type='give-item',item='offshore-pump',count=math_random(5,15)}},--供水泵
        {price={{'coin',math_random(40,60)}},offer={type='give-item',item='pipe',count=math_random(25,75)}},--管道
        {price={{'coin',math_random(300,450)}},offer={type='give-item',item='pipe-to-ground',count=math_random(13,37)}},--地下管道
        {price={{'coin',math_random(900,1350)}},offer={type='give-item',item='storage-tank',count=math_random(13,37)}},--储液罐
        {price={{'coin',math_random(300,450)}},offer={type='give-item',item='pump',count=math_random(13,37)}},--管道泵
        {price={{'coin',math_random(120,180)}},offer={type='give-item',item='transport-belt',count=math_random(25,75)}},--基础传送带
        {price={{'coin',math_random(480,720)}},offer={type='give-item',item='fast-transport-belt',count=math_random(25,75)}},--高速传送带
        {price={{'coin',math_random(2200,3300)}},offer={type='give-item',item='express-transport-belt',count=math_random(25,75)}},--极速传送带
        {price={{'coin',math_random(400,600)}},offer={type='give-item',item='underground-belt',count=math_random(13,37)}},--基础地下传送带
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='fast-underground-belt',count=math_random(13,37)}},--高速地下传送带
        {price={{'coin',math_random(6000,9000)}},offer={type='give-item',item='express-underground-belt',count=math_random(13,37)}},--极速地下传送带
        {price={{'coin',math_random(460,690)}},offer={type='give-item',item='splitter',count=math_random(13,37)}},--基础分流器
        {price={{'coin',math_random(1360,2040)}},offer={type='give-item',item='fast-splitter',count=math_random(13,37)}},--高速分流器
        {price={{'coin',math_random(5200,7800)}},offer={type='give-item',item='express-splitter',count=math_random(13,37)}},--极速分流器
        {price={{'coin',math_random(800,1200)}},offer={type='give-item',item='steel-chest',count=math_random(13,37)}},--钢制箱
        {price={{'coin',math_random(40,60)}},offer={type='give-item',item='small-electric-pole',count=math_random(13,37)}},--小型电线杆
        {price={{'coin',math_random(280,420)}},offer={type='give-item',item='big-electric-pole',count=math_random(13,37)}},--远程输电塔
        {price={{'coin',math_random(700,1050)}},offer={type='give-item',item='medium-electric-pole',count=math_random(13,37)}},--中型电线杆
        {price={{'coin',math_random(1900,2850)}},offer={type='give-item',item='substation',count=math_random(13,37)}},--广域配电站
        {price={{'coin',math_random(2200,3300)}},offer={type='give-item',item='logistic-robot',count=math_random(13,37)}},--物流机器人
        {price={{'coin',math_random(1600,2400)}},offer={type='give-item',item='construction-robot',count=math_random(13,37)}},--建设机器人
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='logistic-chest-passive-provider',count=math_random(13,37)}},--被动供货箱(红箱)
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='logistic-chest-active-provider',count=math_random(13,37)}},--主动供货箱(紫箱)
        {price={{'coin',math_random(1200,1800)}},offer={type='give-item',item='logistic-chest-storage',count=math_random(13,37)}},--被动存货箱(黄箱)
        {price={{'coin',math_random(2000,3000)}},offer={type='give-item',item='logistic-chest-buffer',count=math_random(13,37)}},--主动存货箱(绿箱)
        {price={{'coin',math_random(2400,3600)}},offer={type='give-item',item='logistic-chest-requester',count=math_random(13,37)}},--优先集货箱(蓝箱)
        {price={{'coin',math_random(3800,5700)}},offer={type='give-item',item='roboport',count=math_random(3,10)}},--机器人指令平台
        {price={{'coin',math_random(40,60)}},offer={type='give-item',item='burner-inserter',count=math_random(13,37)}},--热能机械臂
        {price={{'coin',math_random(100,150)}},offer={type='give-item',item='inserter',count=math_random(13,37)}},--电力机械臂
        {price={{'coin',math_random(260,390)}},offer={type='give-item',item='fast-inserter',count=math_random(13,37)}},--高速机械臂
        {price={{'coin',math_random(440,660)}},offer={type='give-item',item='filter-inserter',count=math_random(13,37)}},--筛选机械臂
        {price={{'coin',math_random(160,240)}},offer={type='give-item',item='long-handed-inserter',count=math_random(13,37)}},--加长机械臂
        {price={{'coin',math_random(1800,2700)}},offer={type='give-item',item='stack-inserter',count=math_random(13,37)}},--集装机械臂
        {price={{'coin',math_random(2200,3300)}},offer={type='give-item',item='stack-filter-inserter',count=math_random(13,37)}},--集装筛选机械臂
        {price={{'coin',math_random(700,1050)}},offer={type='give-item',item='locomotive',count=math_random(1,5)}},--内燃机车
        {price={{'coin',math_random(300,450)}},offer={type='give-item',item='cargo-wagon',count=math_random(1,5)}},--货运车厢
        {price={{'coin',math_random(280,420)}},offer={type='give-item',item='fluid-wagon',count=math_random(1,5)}},--液罐车厢
        {price={{'coin',math_random(40960,64000)}},offer={type='give-item',item='spidertron',count=math_random(1,1)}},--蜘蛛机甲
        {price={{'coin',math_random(40960,64000)}},offer={type='give-item',item='power-armor-mk2',count=math_random(1,1)}},--能量装甲MK2
        {price={{'coin',math_random(1280,6400)}},offer={type='give-item',item='loader',count=math_random(10,50)}},--基础装卸机
        {price={{'coin',math_random(2560,12800)}},offer={type='give-item',item='fast-loader',count=math_random(10,50)}},--高速装卸机
        {price={{'coin',math_random(5120,25600)}},offer={type='give-item',item='express-loader',count=math_random(10,50)}},--极速装卸机    
        {price={{'coin',math_random(400,600)}},offer={type='give-item',item='gate',count=math_random(13,37)}},--闸门
        {price={{'coin',math_random(8000,12000)},{'submachine-gun',math_random(1,5)}},offer={type='give-item',item='tank-machine-gun',count=math_random(1,3)}},--特殊道具-车载机枪
        {price={{'coin',math_random(11200,16800)},{'combat-shotgun',math_random(1,5)}},offer={type='give-item',item='tank-cannon',count=math_random(1,3)}},--特殊道具-坦克炮
        {price={{'express-transport-belt',math_random(500,1000)},{'express-underground-belt',math_random(250,500)},{'express-splitter',math_random(100,200)}},offer={type='give-item',item='linked-chest',count=math_random(1,1)}},--调试道具-关联箱
        --{price={{'raw-fish',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(40,100)}},--鲜鱼
        --{price={{'copper-cable',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(20,50)}},--铜线
        --{price={{'copper-plate',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(40,100)}},--铜板
        --{price={{'electronic-circuit',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(120,300)}},--电路板
        --{price={{'iron-stick',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(20,50)}},--铁棒
        --{price={{'iron-plate',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(40,100)}},--铁板
        --{price={{'iron-gear-wheel',math_random(40,100)}},offer={type='give-item',item='coin',count=math_random(80,200)}},--铁齿轮
        --{price={{'steel-plate',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(212,362)}},--钢材
        --{price={{'empty-barrel',math_random(9,15)}},offer={type='give-item',item='coin',count=math_random(85,145)}},--空桶
        --{price={{'engine-unit',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(382,652)}},--内燃机
        --{price={{'uranium-238',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(170,290)}},--铀-238
        --{price={{'uranium-235',math_random(45,60)}},offer={type='give-item',item='coin',count=math_random(1350,1800)}},--铀-235
        --{price={{'uranium-fuel-cell',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(510,870)}},--铀燃料棒
        {price={{'plastic-bar',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(63,108)}},--塑料
        {price={{'solid-fuel',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(85,145)}},--固体燃料
        {price={{'sulfur',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(63,108)}},--硫磺
        {price={{'advanced-circuit',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(382,952)}},--集成电路
        {price={{'electric-engine-unit',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(637,1587)}},--电动机
        {price={{'explosives',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(85,145)}},--炸药
        {price={{'rocket-fuel',math_random(9,15)}},offer={type='give-item',item='coin',count=math_random(180,290)}},--火箭燃料
        {price={{'used-up-uranium-fuel-cell',math_random(43,73)}},offer={type='give-item',item='coin',count=math_random(510,870)}},--乏燃料棒
        {price={{'battery',math_random(45,60)}},offer={type='give-item',item='coin',count=math_random(360,680)}},--电池
        {price={{'flying-robot-frame',math_random(45,60)}},offer={type='give-item',item='coin',count=math_random(2070,3360)}},--机器人构架
        {price={{'low-density-structure',math_random(10,12)}},offer={type='give-item',item='coin',count=math_random(370,644)}},--轻质框架
        {price={{'processing-unit',math_random(45,60)}},offer={type='give-item',item='coin',count=math_random(3150,6200)}},--处理器
        {price={{'nuclear-fuel',math_random(1,2)}},offer={type='give-item',item='coin',count=math_random(200,410)}},--核能燃料
        {price={{'rocket-control-unit',math_random(10,11)}},offer={type='give-item',item='coin',count=math_random(1250,2675)}},--火箭控制器
        {price={{'satellite',math_random(1,2)}},offer={type='give-item',item='coin',count=math_random(20000,31000)}}--卫星
        --{price={{'crude-oil-barrel',math_random(20,50)}},offer={type='give-item',item='coin',count=math_random(50,400)}}--石油桶--注意末尾行逗号
        }
    table.shuffle_table(offers)
    local market = surface.create_entity({name = 'market', position = position, force = 'player'})
    market.destructible = false
    market.minable = false
    market.add_market_item{price={{'crude-oil-barrel',math_random(20,50)}},offer={type='give-item',item='coin',count=math_random(50,400)}} --石油桶
    local text = '[font=infinite]Buys[/font]:'
    --for i = 1, math.random(6, 8), 1 do
    for i = 1,math.random(5, 7),1 do --循环次数，商品数量
    market.add_market_item(offers[i])
    text = text .. '<[img=item.' .. offers[i].price[1][1] .. ']' .. offers[i].price[1][2] .. '/' .. offers[i].offer.count .. '[img=item.' .. offers[i].offer.item .. ']>' --占用字符太多了,所以物品数量只能少一些
    --text = text .. offers[i].price[1][2] .. '/' .. offers[i].offer.count .. '=[img=item.' .. offers[i].offer.item .. ']' --占用字符太多了,所以物品数量只能少一些
    --text = text .. '[img=item.' .. offers[i].offer.item .. ']'
    end
    game.forces.player.add_chart_tag(surface, {position = position, text = text})--生成商店后自动加该商店物品列表标签
    game.print('[font=infinite][color=#96E99E]费[/color][color=#96E9AB]尽[/color][color=#96E9B7]九[/color][color=#96E9C3]牛[/color][color=#96E9D0]二[/color][color=#96E9DC]虎[/color][color=#96E9E9]之[/color][color=#96DCE9]力[/color][color=#96D0E9]破[/color][color=#96C3E9]译[/color][color=#96B7E9]后[/color][color=#96ABE9]发[/color][color=#969EE9]现[/color][color=#9A96E9]居[/color][color=#A696E9]然[/color][color=#B396E9]只[/color][color=#BF96E9]是[/color][color=#CC96E9]黑[/color][color=#D896E9]心[/color][color=#E596E9]店[/color][color=#E996E0]长[/color][color=#E996D4]的[/color][color=#E996C8]广[/color][color=#E996BB]告[/color][color=#E996AF]！[/color][color=#E996A2]！[/color][/font]\n' .. text,{r = 0.22, g = 0.88, b = 0.88})
end

function Public.laboratory(surface, position)
    local lab = surface.create_entity({name = 'lab', position = position, force = 'player'})
    lab.destructible = false
    lab.minable = true
    local evo = Public.get_dungeon_evolution_factor(surface.index)
    local amount = math.min(200, math_floor(evo * 100))
    amount = math.max(amount, 1)
    lab.insert({name = 'automation-science-pack', count = math.min(200, math_floor(amount * 5))})
    if evo >= 0.1 then
        lab.insert({name = 'logistic-science-pack', count = math.min(200, math_floor(amount * 4))})
    end
    if evo >= 0.2 then
        lab.insert({name = 'military-science-pack', count = math.min(200, math_floor(amount * 3))})
    end
    if evo >= 0.4 then
        lab.insert({name = 'chemical-science-pack', count = math.min(200, math_floor(amount * 2))})
    end
    if evo >= 0.6 then
        lab.insert({name = 'production-science-pack', count = amount})
    end
    if evo >= 0.8 then
        lab.insert({name = 'utility-science-pack', count = amount})
    end
    if evo >= 1 then
        lab.insert({name = 'space-science-pack', count = amount})
    end
end

function Public.add_room_loot_crates(surface, room)
    if not room.room_border_tiles[1] then
        return
    end
    for key, tile in pairs(room.room_tiles) do
        if math_random(1, 384) == 1 then
            Public.common_loot_crate(surface, tile.position)
        else
            if math_random(1, 1024) == 1 then
                Public.uncommon_loot_crate(surface, tile.position)
            else
                if math_random(1, 4096) == 1 then
                    Public.rare_loot_crate(surface, tile.position)
                else
                    if math_random(1, 16384) == 1 then
                        Public.epic_loot_crate(surface, tile.position)
                    end
                end
            end
        end
    end
end

function Public.set_spawner_tier(spawner, surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local tier = math_floor(Public.get_dungeon_evolution_factor(surface_index) * 8 - math_random(0, 8)) + 1
    if tier < 1 then
        tier = 1
    end
    dungeontable.spawner_tier[spawner.unit_number] = tier
    --[[
	rendering.draw_text{
		text = "-Tier " .. tier .. "-",
		surface = spawner.surface,
		target = spawner,
		target_offset = {0, -2.65},
		color = {25, 0, 100, 255},
		scale = 1.25,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	]]
end

function Public.spawn_random_biter(surface, position)
    local dungeontable = DungeonsTable.get_dungeontable()
    local name = BiterRaffle.roll('mixed', Public.get_dungeon_evolution_factor(surface.index))
    local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
    local unit
    if non_colliding_position then
        unit = surface.create_entity({name = name, position = non_colliding_position, force = dungeontable.enemy_forces[surface.index]})
    else
        unit = surface.create_entity({name = name, position = position, force = dungeontable.enemy_forces[surface.index]})
    end
    unit.ai_settings.allow_try_return_to_spawner = false
    unit.ai_settings.allow_destroy_when_commands_fail = false
end

function Public.place_border_rock(surface, position)
    local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
    table_shuffle_table(vectors)
    local key = false
    for k, v in pairs(vectors) do
        local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
        if tile.name == 'out-of-map' then
            key = k
            break
        end
    end
    local pos = {x = position.x + 0.5, y = position.y + 0.5}
    if key then
        pos = {pos.x + vectors[key][1] * 0.45, pos.y + vectors[key][2] * 0.45}
    end
    surface.create_entity({name = 'rock-big', position = pos})
end

function Public.create_scrap(surface, position)
    local scraps = {
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-6'
    }
    surface.create_entity({name = scraps[math_random(1, #scraps)], position = position, force = 'player'})
end

function Public.on_marked_for_deconstruction(event)
    local disabled_for_deconstruction = {
        ['fish'] = true,
        ['rock-huge'] = true,
        ['rock-big'] = true,
        ['sand-rock-big'] = true,
        ['crash-site-spaceship-wreck-small-1'] = true,
        ['crash-site-spaceship-wreck-small-2'] = true,
        ['crash-site-spaceship-wreck-small-3'] = true,
        ['crash-site-spaceship-wreck-small-4'] = true,
        ['crash-site-spaceship-wreck-small-5'] = true,
        ['crash-site-spaceship-wreck-small-6'] = true
    }
    if event.entity and event.entity.valid then
        if disabled_for_deconstruction[event.entity.name] then
            event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
        end
    end
end

local function get_ore_amount(surface_index)
   local floor = surface_index - DungeonsTable.get_dungeontable().original_surface_index

   local amount = FLOOR_ZERO_ROCK_ORE + ROCK_ORE_INCREASE_PER_FLOOR * math.min(FLOOR_FOR_MAX_ROCK_ORE, floor)
   return math_random(math_floor(amount * 0.7), math_floor(amount * 1.3))
end

local function reward_ores(amount, mined_loot, surface, player, entity)
    local a = 0
    if player then
        a = player.insert {name = mined_loot, count = amount}
    end
    amount = amount - a
    if amount > 0 then
        if amount >= 50 then
            for i = 1, math_floor(amount / 50), 1 do
                local e = surface.create_entity {name = 'item-on-ground', position = entity.position, stack = {name = mined_loot, count = 50}}
                if e and e.valid then
                    e.to_be_looted = true
                end
                amount = amount - 50
            end
        end
        if amount > 0 then
            if amount < 5 then
                surface.spill_item_stack(entity.position, {name = mined_loot, count = amount}, true)
            else
                local e = surface.create_entity {name = 'item-on-ground', position = entity.position, stack = {name = mined_loot, count = amount}}
                if e and e.valid then
                    e.to_be_looted = true
                end
            end
        end
    end
end

local function flying_text(surface, position, text, color)
    surface.create_entity(
        {
            name = 'flying-text',
            position = {position.x, position.y - 0.5},
            text = text,
            color = color
        }
    )
end

function Public.rocky_loot(event)
    if not event.entity or not event.entity.valid then
        return
    end
    local allowed = {
        ['rock-big'] = true,
        ['rock-huge'] = true,
        ['sand-rock-big'] = true
    }
    if not allowed[event.entity.name] then
        return
    end
    local player = game.players[event.player_index]
    local amount = math.ceil(get_ore_amount(player.surface.index))
    local rock_mining
    local floor = player.surface.index - DungeonsTable.get_dungeontable().original_surface_index;
    if floor < 10 then
       -- early game science uses less copper and more iron/stone
       rock_mining = {'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'copper-ore', 'copper-ore', 'stone', 'stone', 'coal', 'coal', 'coal'}
    else
	-- end game prod 3 base uses (for all-sciences) 1 stone : 2 coal : 3.5 copper : 4.5 iron
	-- this is a decent approximation which will still require some modest amount of mining setup
	-- coal gets 3 to compensate for coal-based power generation
	rock_mining = {'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'copper-ore', 'copper-ore', 'copper-ore', 'stone', 'coal', 'coal', 'coal'}
    end
    local mined_loot = rock_mining[math_random(1, #rock_mining)]
    local text = '+' .. amount .. ' [item=' .. mined_loot .. ']'
    flying_text(player.surface, player.position, text, {r = 0.98, g = 0.66, b = 0.22})
    reward_ores(amount, mined_loot, player.surface, player, player)
    event.buffer.clear()
end

function Public.mining_events(entity)
    if math_random(1, 16) == 1 then
        Public.spawn_random_biter(entity.surface, entity.position)
        return
    end
    if math_random(1, 24) == 1 then
        Public.common_loot_crate(entity.surface, entity.position)
        return
    end
    if math_random(1, 128) == 1 then
        Public.uncommon_loot_crate(entity.surface, entity.position)
        return
    end
    if math_random(1, 512) == 1 then
        Public.rare_loot_crate(entity.surface, entity.position)
        return
    end
    if math_random(1, 1024) == 1 then
        Public.epic_loot_crate(entity.surface, entity.position)
        return
    end
end

function Public.draw_spawn(surface)
    local dungeontable = DungeonsTable.get_dungeontable()
    local spawn_size = dungeontable.spawn_size

    for _, e in pairs(surface.find_entities({{spawn_size * -1, spawn_size * -1}, {spawn_size, spawn_size}})) do
        e.destroy()
    end

    local tiles = {}
    local i = 1
    for x = spawn_size * -1, spawn_size, 1 do
        for y = spawn_size * -1, spawn_size, 1 do
            local position = {x = x, y = y}
            if math_abs(position.x) < 2 or math_abs(position.y) < 2 then
                tiles[i] = {name = 'dirt-7', position = position}
                i = i + 1
                tiles[i] = {name = 'stone-path', position = position}
                i = i + 1
            else
                tiles[i] = {name = 'dirt-7', position = position}
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)

    tiles = {}
    i = 1
    for x = -2, 2, 1 do
        for y = -2, 2, 1 do
            local position = {x = x, y = y}
            if math_abs(position.x) > 1 or math_abs(position.y) > 1 then
                tiles[i] = {name = 'black-refined-concrete', position = position}
                i = i + 1
            else
                tiles[i] = {name = 'purple-refined-concrete', position = position}
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)

    tiles = {}
    i = 1
    for x = spawn_size * -1, spawn_size, 1 do
        for y = spawn_size * -1, spawn_size, 1 do
            local position = {x = x, y = y}
            local r = math.sqrt(position.x ^ 2 + position.y ^ 2)
            if r < 2 then
                tiles[i] = {name = 'purple-refined-concrete', position = position}
                --tiles[i] = {name = "water-mud", position = position}
                i = i + 1
            else
                if r < 2.5 then
                    tiles[i] = {name = 'black-refined-concrete', position = position}
                    --tiles[i] = {name = "water-shallow", position = position}
                    i = i + 1
                else
                    if r < 4.5 then
                        tiles[i] = {name = 'dirt-7', position = position}
                        i = i + 1
                        tiles[i] = {name = 'concrete', position = position}
                        i = i + 1
                    end
                end
            end
        end
    end
    surface.set_tiles(tiles, true)

    local decoratives = {'brown-hairy-grass', 'brown-asterisk', 'brown-fluff', 'brown-fluff-dry', 'brown-asterisk', 'brown-fluff', 'brown-fluff-dry'}
    local a = spawn_size * -1 + 1
    local b = spawn_size - 1
    for _, decorative_name in pairs(decoratives) do
        local seed = game.surfaces[surface.index].map_gen_settings.seed + math_random(1, 1000000)
        for x = a, b, 1 do
            for y = a, b, 1 do
                local position = {x = x + 0.5, y = y + 0.5}
                if surface.get_tile(position).name == 'dirt-7' or math_random(1, 5) == 1 then
                    local noise = Get_noise('decoratives', position, seed)
                    if math_abs(noise) > 0.37 then
                        surface.create_decoratives {
                            check_collision = false,
                            decoratives = {{name = decorative_name, position = position, amount = math.floor(math.abs(noise * 3)) + 1}}
                        }
                    end
                end
            end
        end
    end

    local entities = {}
    i = 1
    for x = spawn_size * -1 - 16, spawn_size + 16, 1 do
        for y = spawn_size * -1 - 16, spawn_size + 16, 1 do
            local position = {x = x, y = y}
            if position.x <= spawn_size and position.y <= spawn_size and position.x >= spawn_size * -1 and position.y >= spawn_size * -1 then
                if position.x == spawn_size then
                    entities[i] = {name = 'rock-big', position = {position.x + 0.95, position.y}}
                    i = i + 1
                end
                if position.y == spawn_size then
                    entities[i] = {name = 'rock-big', position = {position.x, position.y + 0.95}}
                    i = i + 1
                end
                if position.x == spawn_size * -1 or position.y == spawn_size * -1 then
                    entities[i] = {name = 'rock-big', position = position}
                    i = i + 1
                end
            end
        end
    end

    for k, e in pairs(entities) do
        if k % 3 > 0 then
            surface.create_entity(e)
        end
    end

    if dungeontable.tiered then
        if surface.index > dungeontable.original_surface_index then
            table.insert(dungeontable.transport_surfaces, surface.index)
            dungeontable.transport_chests_inputs[surface.index] = {}
            for iv = 1, 2, 1 do
                local chest = surface.create_entity({name = 'linked-chest', position = {-12 + iv * 8, -4}, force = 'player'})
                dungeontable.transport_chests_inputs[surface.index][iv] = chest
                chest.destructible = false
                chest.minable = false
            end
            dungeontable.transport_poles_outputs[surface.index] = {}
            for ix = 1, 2, 1 do
                local pole = surface.create_entity({name = 'constant-combinator', position = {-15 + ix * 10, -5}, force = 'player'})
                dungeontable.transport_poles_outputs[surface.index][ix] = pole
                pole.destructible = false
                pole.minable = false
            end
        end
        dungeontable.transport_chests_outputs[surface.index] = {}
        for ic = 1, 2, 1 do
            local chest = surface.create_entity({name = 'linked-chest', position = {-12 + ic * 8, 4}, force = 'player'})
            dungeontable.transport_chests_outputs[surface.index][ic] = chest
            chest.destructible = false
            chest.minable = false
        end
        dungeontable.transport_poles_inputs[surface.index] = {}
        for ib = 1, 2, 1 do
            local pole = surface.create_entity({name = 'medium-electric-pole', position = {-15 + ib * 10, 5}, force = 'player'})
            dungeontable.transport_poles_inputs[surface.index][ib] = pole
            pole.destructible = false
            pole.minable = false
        end
    end

    local trees = {'dead-grey-trunk', 'dead-tree-desert', 'dry-hairy-tree', 'dry-tree', 'tree-04'}
    local size_of_trees = #trees
    local r = 4
    for x = spawn_size * -1, spawn_size, 1 do
        for y = spawn_size * -1, spawn_size, 1 do
            local position = {x = x + 0.5, y = y + 0.5}
            if position.x > 5 and position.y > 5 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
            if position.x <= -4 and position.y <= -4 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
            if position.x > 5 and position.y <= -4 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
            if position.x <= -4 and position.y > 5 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
        end
    end
    surface.set_tiles(tiles, true)
end

return Public
