local Event = require 'utils.event'
local Global = require 'utils.global'
local sqrt = math.sqrt
local random = math.random
local floor = math.floor
local ceil = math.ceil

local Public = {}

local this =
{
    settings =
    {
        allowed_surface = 'nauvis',
        average_worm_amount_per_chunk = 1
    }
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local turrets =
{
    [1] = 'small-worm-turret',
    [2] = 'small-worm-turret',
    [3] = 'small-worm-turret',
    [4] = 'small-worm-turret',
    [5] = 'small-worm-turret',
    [6] = 'small-worm-turret',
    [7] = 'small-worm-turret',
    [8] = 'small-worm-turret',
    [9] = 'medium-worm-turret',
    [10] = 'medium-worm-turret',
    [11] = 'medium-worm-turret',
    [12] = 'medium-worm-turret',
    [13] = 'medium-worm-turret',
    [14] = 'medium-worm-turret',
    [15] = 'medium-worm-turret',
    [16] = 'medium-worm-turret',
    [17] = 'medium-worm-turret',
    [18] = 'medium-worm-turret',
    [19] = 'big-worm-turret',
    [20] = 'big-worm-turret',
    [21] = 'big-worm-turret',
    [22] = 'big-worm-turret',
    [23] = 'big-worm-turret',
    [24] = 'big-worm-turret',
    [25] = 'big-worm-turret',
    [26] = 'big-worm-turret',
    [27] = 'big-worm-turret',
    [28] = 'behemoth-worm-turret'
}

local function check_settings()
    if not this then
        this =
        {
            settings =
            {
                allowed_surface = 'nauvis',
                average_worm_amount_per_chunk = 1
            }
        }
    end
end

local tile_coords = {}
for x = 0, 31, 1 do
    for y = 0, 31, 1 do
        tile_coords[#tile_coords + 1] = { x, y }
    end
end

local function on_chunk_generated(event)
    local surface = event.surface
    if surface.name ~= this.settings.allowed_surface then
        return
    end

    local starting_distance = surface.map_gen_settings.starting_area * 800
    local left_top = event.area.left_top
    local chunk_distance_to_center = sqrt(left_top.x ^ 2 + left_top.y ^ 2)
    if starting_distance > chunk_distance_to_center then
        return
    end

    local highest_worm_tier = floor((chunk_distance_to_center - starting_distance) * 0.002) + 1
    --if highest_worm_tier > 4 then highest_worm_tier = 4 end

    check_settings()

    local worm_amount = random(floor(this.settings.average_worm_amount_per_chunk * 0.5), ceil(this.settings.average_worm_amount_per_chunk * 1.5))

    for _ = 1, worm_amount, 1 do
        local coord_modifier = tile_coords[random(1, #tile_coords)]
        local pos = { left_top.x + coord_modifier[1], left_top.y + coord_modifier[2] }
        local name = turrets[random(1, highest_worm_tier)]
        if not name then
            name = turrets[random(1, #turrets)]
        end

        surface.create_entity({ name = name, position = pos, force = 'enemy' })
    end
end

---Sets the allowed surface where worms can spawn.
---@param string any
function Public.allow_surface(string)
    this.settings.allowed_surface = string or 'nauvis'
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.on_init(
    function ()
        check_settings()
    end
)

return Public
