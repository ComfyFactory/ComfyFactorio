local Public = {}
local CommonFunctions = require 'maps.planet_prison.mod.common'
local Global = require 'utils.global'

local this = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

--[[
init - Initialize claim system.
@param names - Table of entity names that should be used as a marker.
@param max_distance - Maximal distance allowed between markers
--]]
Public.init = function(names, max_distance)
    if type(names) ~= 'table' then
        names = {names}
    end

    this._claims_info = {}
    this._claims_visible_to = {}
    this._claim_markers = names
    this._claim_max_dist = max_distance
end

local function claim_new_claim(ent)
    local point = {
        {
            x = CommonFunctions.get_axis(ent.position, 'x'),
            y = CommonFunctions.get_axis(ent.position, 'y')
        }
    }

    local claims = this._claims_info
    if claims[ent.force.name] == nil then
        claims[ent.force.name] = {}
        claims[ent.force.name].polygons = {}
        claims[ent.force.name].claims = {}
        claims[ent.force.name].collections = {}
    end

    table.insert(claims[ent.force.name].collections, point)
end

local function claim_on_build_entity(ent)
    local max_dist = this._claim_max_dist
    local force = ent.force.name
    local data = this._claims_info[force]

    if data == nil then
        claim_new_claim(ent)
        return
    end

    local in_range = false
    local collections = data.collections
    for i = 1, #collections do
        local points = collections[i]

        for _, point in pairs(points) do
            point = point
            local dist = CommonFunctions.get_distance(point, ent.position)
            if max_dist < dist then
                goto continue
            end

            in_range = true
            point = {
                x = CommonFunctions.get_axis(ent.position, 'x'),
                y = CommonFunctions.get_axis(ent.position, 'y')
            }
            table.insert(points, point)
            data.claims[i] = CommonFunctions.get_convex_hull(points)

            break
            ::continue::
        end
    end

    if not in_range then
        claim_new_claim(ent, deps)
    end
end

local function claims_in_markers(name)
    for _, marker in pairs(this._claim_markers) do
        if name == marker then
            return true
        end
    end

    return false
end

--[[
on_build_entity - Event processing function.
@param ent - Entity
--]]
Public.on_built_entity = function(ent)
    if not claims_in_markers(ent.name) then
        return
    end

    local deps = {
        CommonFunctions = CommonFunctions
    }
    claim_on_build_entity(ent, deps)
end

local function claim_on_entity_died(ent)
    local force = ent.force.name
    local data = this._claims_info[force]
    if data == nil then
        return
    end

    for i = 1, #data.collections do
        local points = data.collections[i]

        for j = 1, #points do
            local point = points[j]
            if CommonFunctions.positions_equal(point, ent.position) then
                table.remove(points, j)

                data.claims[i] = CommonFunctions.get_convex_hull(points)
                break
            end
        end

        if #points == 0 then
            table.remove(data.claims, i)
            table.remove(data.collections, i)
            break
        end
    end

    if #data.claims == 0 then
        this._claims_info[force] = nil
    end
end

--[[
on_entity_died - Event processing function.
@param ent - Entity
--]]
Public.on_entity_died = function(ent)
    if not claims_in_markers(ent.name) then
        return
    end
    claim_on_entity_died(ent)
end

--[[
on_player_mined_entity - Event processing function.
@param ent - Entity
--]]
Public.on_player_mined_entity = function(ent)
    Public.on_entity_died(ent)
end

--[[
on_player_died - Event processing function
@param player - Player
--]]
Public.on_player_died = function(player)
    this._claims_info[player.name] = nil
end

--[[
get_claims - Get all claims data points for given force.
@param f_name - Force name.
--]]
Public.get_claims = function(f_name)
    if this._claims_info[f_name] == nil then
        return {}
    end

    return this._claims_info[f_name].claims
end

local function claims_update_visiblity()
    if #this._claims_visible_to == 0 then
        for _, info in pairs(this._claims_info) do
            for _, id in pairs(info.polygons) do
                if rendering.is_valid(id) then
                    rendering.set_visible(id, false)
                end
            end
        end
        return
    end

    for _, info in pairs(this._claims_info) do
        for _, id in pairs(info.polygons) do
            if rendering.is_valid(id) then
                rendering.set_visible(id, true)
                rendering.set_players(id, this._claims_visible_to)
            end
        end
    end
end

--[[
set_visibility_to - Specifies who can see the claims and redraws.
@param name - Name of a player.
--]]
Public.set_visibility_to = function(name)
    for _, p in pairs(this._claims_visible_to) do
        if p == name then
            return
        end
    end

    table.insert(this._claims_visible_to, name)
    claims_update_visiblity()
end

--[[
remove_visibility_from - Remove the claim visibility from the player.
@param name - Name of a player.
--]]
Public.remove_visibility_from = function(name)
    for i = 1, #this._claims_visible_to do
        local p = this._claims_visible_to[i]
        if p == name then
            table.remove(this._claims_visible_to, i)
            claims_update_visiblity()
            break
        end
    end
end

return Public
