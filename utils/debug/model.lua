local Gui = require 'utils.gui'
local table = require 'utils.table'
local api = require 'utils.debug.runtime-api-stable'

local gui_names = Gui.names
local type = type
local concat = table.concat
local inspect = table.inspect
local pcall = pcall
---@diagnostic disable-next-line: deprecated
local loadstring = loadstring
local classes = api.classes

local Public = {}

local luaObject = { '{', nil, ", name = '", nil, "'}" }
local luaPlayer = { "{LuaPlayer, name = '", nil, "', index = ", nil, '}' }
local luaEntity = { "{LuaEntity, name = '", nil, "', unit_number = ", nil, '}' }
local luaGuiElement = { "{LuaGuiElement, name = '", nil, "'}" }

local function get(obj, prop)
    return obj[prop]
end

local function get_name_safe(obj)
    local s, r = pcall(get, obj, 'name')
    if not s then
        return 'nil'
    else
        return r or 'nil'
    end
end

local function get_lua_object_type_safe(obj)
    local s, r = pcall(get, obj, 'object_name')

    if not s then
        return type(obj)
    end

    return r
end

local function inspect_process(item)
    local object_name = get_lua_object_type_safe(item)
    if object_name and classes[object_name] then
        local class = classes[object_name]
        local attrs = class.attributes
        local info = { __type = object_name }
        local shown = 0
        for key in pairs(attrs) do
            local ok, val =
                pcall(
                    function ()
                        return item[key]
                    end
                )
            if ok and (type(val) ~= 'table' and type(val) ~= 'userdata') then
                info[key] = val
                shown = shown + 1
            end
        end
        return serpent.line(info, { comment = false, numformat = '%g' })
    end

    if type(item) ~= 'table' or type(item.__self) ~= 'userdata' then
        return item
    end

    local suc, valid = pcall(get, item, 'valid')
    if not suc then
        return get_lua_object_type_safe(item) or '{NoHelp LuaObject}'
    end
    if not valid then
        return '{Invalid LuaObject}'
    end

    local obj_type = get_lua_object_type_safe(item)
    if not obj_type then
        return '{NoHelp LuaObject}'
    end

    if obj_type == 'LuaPlayer' then
        luaPlayer[2] = item.name or 'nil'
        luaPlayer[4] = item.index or 'nil'
        return concat(luaPlayer)
    elseif obj_type == 'LuaEntity' then
        luaEntity[2] = item.name or 'nil'
        luaEntity[4] = item.unit_number or 'nil'
        return concat(luaEntity)
    elseif obj_type == 'LuaGuiElement' then
        local name = item.name
        luaGuiElement[2] = gui_names and gui_names[name] or name or 'nil'
        return concat(luaGuiElement)
    else
        luaObject[2] = obj_type
        luaObject[4] = get_name_safe(item)
        return concat(luaObject)
    end
end

local inspect_options = { process = inspect_process }
function Public.dump(data)
    return inspect(data, inspect_options)
end

local dump = Public.dump

function Public.dump_ignore_builder(ignore)
    local function process(item)
        if ignore[item] then
            return nil
        end

        return inspect_process(item)
    end

    local options = { process = process }
    return function (data)
        return inspect(data, options)
    end
end

function Public.dump_function(func)
    local res = { 'upvalues:\n' }

    ---@diagnostic disable-next-line: deprecated
    if debug.getupvalue == nil then
        return concat(res)
    end

    local i = 1
    while true do
        ---@diagnostic disable-next-line: deprecated
        local n, v = debug.getupvalue(func, i)

        if n == nil then
            break
        elseif n ~= '_ENV' then
            res[#res + 1] = n
            res[#res + 1] = ' = '
            res[#res + 1] = dump(v)
            res[#res + 1] = '\n'
        end

        i = i + 1
    end

    return concat(res)
end

function Public.dump_text(text)
    local func = loadstring('return ' .. text)
    if not func then
        return false
    end

    local suc, var = pcall(func)

    if not suc then
        return false
    end

    local dvar = dump(var)
    if dvar:find('function_handlers') then
        dvar = '{}' -- desync handler
    end

    return true, dvar
end

return Public
