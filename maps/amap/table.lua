local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    players = {},
    traps = {}
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
-- @star
    -- these 3 are in case of stop/start/reloading the finstance
    this.productionsphere={}
    this.productionsphere.experience = {}
    this.productionsphere.assemblers = {}
    this.productionsphere.train_assemblers = {}
    this.shop=nil
    this.biter_follow_number = 25
    this.biter_max=100
    this.biter_command={}
    this.biter_number={}
    this.biter_pets={}
    this.car_pos={}
    this.time_weights={}
    this.had_sipder={}
    this.theta_times=0
    this.frist_target=false
    this.car_name=nil
    this.urgrad_rock_dam=0
    this.urgrad_mine=0
    this.max_flame=28
    this.max_mine=400
    this.now_mine=0
    this.stop_wave=0
    this.stop_time=0
    this.first_build_car={}
        this.upgrade_car={}
    this.player_position={}
    this.reset_time=0
    this.car_wudi={}
    this.ore_record={}
    this.target_last=0
      this.start_game=1
    this.whos_tank={}
    this.tank={}
    this.have_been_put_tank={}
    this.base=false
    this.goal=1
    this.suoquan = false
    this.baolei = 1
    this.just_begun=true
    this.biter_wudi={}
    this.biter_dam=0
    this.turret={}
    this.cap=2
     this.biter_health=0
     this.change_dist=false
     this.spider_health=0
    this.arty=0
    this.health = 0
    this.flame = 0
    this.roll = 1
	this.pass = false
  this.single = true
  this.science = 0
  this.number = 0
  this.first = true
    this.times = 1
    this.change = false
	this.pos = {x=0,y=0}
	this.last = 0
	this.rock = nil
    this.soft_reset = true

    this.game_saved = false
    -- @end
    this.game_lost = false
    this.fullness_enabled = true
    this.left_top = {
        x = 0,
        y = 0
    }
    this.biters = {
        amount = 0,
        limit = 512
    }

    this.explosive_bullets = false

    --!reset player tables
    for _, player in pairs(this.players) do
        player.died = false
    end

end
function Public.get(key)
    if key then
        return this[key]
    else
        return this
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

function Public.get_production_table()
    return this.productionsphere
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
