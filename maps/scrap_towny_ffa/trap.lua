local math_random = math.random
local Evolution = require 'maps.scrap_towny_ffa.evolution'
local Town_center = require 'maps.scrap_towny_ffa.town_center'
local Scrap = require 'maps.scrap_towny_ffa.scrap'
local unearthing_worm = require 'functions.unearthing_worm'
local unearthing_biters = require 'functions.unearthing_biters'
local tick_tack_trap = require 'functions.tick_tack_trap'

local function trap(entity)
    -- check if within 32 blocks of market
    if entity.type == 'tree' or Scrap.is_scrap(entity) and not Town_center.in_any_town(entity.position) then
        if math_random(1, 1024) == 1 then
            tick_tack_trap(entity.surface, entity.position)
        end
        if math_random(1, 256) == 1 then
            unearthing_worm(entity.surface, entity.position, Evolution.get_worm_evolution(entity))
        end
        if math_random(1, 128) == 1 then
            unearthing_biters(entity.surface, entity.position, math_random(4, 8), Evolution.get_biter_evolution(entity))
        end
    end
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if entity and entity.valid then
        trap(entity)
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
