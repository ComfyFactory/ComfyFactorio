local Global = require 'utils.global'
local Event = require 'utils.event'

local Module = {}

local settings =
{
    enabled = true,
    registered_forces = {},
    roboport_limit = 100,
    logi_robot_limit = 500,
    cons_robot_limit = 500,
    damage_amount = 10
}
Global.register(
    settings,
    function (tbl)
        settings = tbl
    end
)

local function alert(entity)
    local messages =
    {
        ['roboport'] = 'Too many roboports in the network, they start to deteriorate!',
        ['logistic-robot'] = 'Too many logistic robots in same network, they collide with each other often!',
        ['construction-robot'] = 'Too many construction robots in same network, they collide with each other often!',
    }
    for _, player in pairs(game.connected_players) do
        player.add_custom_alert(entity, { type = 'virtual', name = 'signal-deny' }, messages[entity.type], true)
        player.play_sound({ path = 'utility/alert_destroyed' })
    end
end

local function damage_entity(entity)
    entity.health = entity.health - settings.damage_amount
    if entity.health <= 0 then
        alert(entity)
        entity.die(entity.force, entity)
    end
end

local function restrict_roboports(custom_force)
    local force = custom_force or game.forces.player
    local surface_networks = force.logistic_networks
    for _, surface_network in pairs(surface_networks) do
        for _, network in pairs(surface_network) do
            if #network.cells > settings.roboport_limit then
                for _, cell in pairs(network.cells) do
                    --cell.owner.disabled_by_script = false -- doesn't currently work REEEEEEEEEEEEEE, can't disable roboports
                    if math.random(1, 3) == 1 then
                        damage_entity(cell.owner)
                    end
                end
            end
        end
    end
end

local function restrict_robots(custom_force)
    local force = custom_force or game.forces.player
    local surface_networks = force.logistic_networks
    for _, surface_network in pairs(surface_networks) do
        for _, network in pairs(surface_network) do
            if network.all_logistic_robots > settings.logi_robot_limit then
                for _, robot in pairs(network.logistic_robots) do
                    --robot.disabled_by_script = false --works but is graphically meh
                    if math.random(1, 8) == 1 then
                        damage_entity(robot)
                    end
                end
            end
            if network.all_construction_robots > settings.cons_robot_limit then
                for _, robot in pairs(network.construction_robots) do
                    --robot.disabled_by_script = false --works but is graphically meh
                    if math.random(1, 8) == 1 then
                        damage_entity(robot)
                    end
                end
            end
        end
    end
end

local function do_tick()
    if not settings.enabled then return end
    for _, force_data in pairs(settings.registered_forces) do
        local force = game.forces[force_data.force_id]
        if force and force_data.enabled then
            restrict_roboports(force)
            restrict_robots(force)
        end
    end
end

---Gets the amount of damage dealt per second
function Module.get_damage()
    return settings.damage_amount
end

---Sets the amount of damage dealt per second
---@param number integer
function Module.set_damage(number)
    settings.damage_amount = number
end

---Gets the limit to number of logistic robots in single network
function Module.get_logistic_robot_limit()
    return settings.logi_robot_limit
end

---Sets the limit to number of logistic robots in single network
---@param number integer
function Module.set_logistic_robot_limit(number)
    settings.logi_robot_limit = number
end

---Gets the limit to number of construction robots in single network
function Module.get_construction_robot_limit()
    return settings.cons_robot_limit
end

---Sets the limit to number of construction robots in single network
---@param number integer
function Module.set_construction_robot_limit(number)
    settings.cons_robot_limit = number
end

---Gets the limit to number of roboports in single network
function Module.get_roboport_limit()
    return settings.roboport_limit
end

---Sets the limit to number of roboports in single network
---@param number integer
function Module.set_roboport_limit(number)
    settings.roboport_limit = number
end

---Enables the module
---@param enabled boolean
function Module.enable(enabled)
    settings.enabled = enabled
end

---Register or modify the force to be scanned and modified by this module
---@param force LuaForce
---@param enabled boolean
function Module.register_force(force, enabled)
    settings.registered_forces[force.index] = { force_id = force.index, enabled = enabled, force_name = force.name }
end

local function on_init()
    Module.register_force(game.forces.player, true)
end

Event.on_init(on_init)
Event.on_nth_tick(60, do_tick)

return Module
