--luacheck: ignore
local branch_version = '1.1' -- define what game version we're using
local sub = string.sub

-- Non-applicable stages are commented out.
_STAGE = {
    --settings = 1,
    --data = 2,
    --migration = 3,
    control = 4,
    init = 5,
    load = 6,
    --config_change = 7,
    runtime = 8
}

function get_game_version()
    local get_active_branch = sub(game.active_mods.base, 3, 4)
    local is_branch_experimental = sub(branch_version, 3, 4)
    if get_active_branch >= is_branch_experimental then
        return true
    else
        return false
    end
end

function is_loaded(module)
    local res = package.loaded[module]
    if res then
        return res
    else
        return false
    end
end
