local Public = {}

local locale_string = {'', nil, nil}
local raw_print = print

function print(str, tag)
    if tag then
        locale_string[2] = tag
    else
        locale_string[2] = '[PRINT]'
    end

    locale_string[3] = str
    log(locale_string)
end

Public.raw_print = raw_print

return Public
