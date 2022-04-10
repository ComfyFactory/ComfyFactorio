local Event = require 'utils.event'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'

local font_color = Color.warning
local font = 'heading-1'

local brain = {
    [1] = {'Our Discord server is at: https://getcomfy.eu/discord'},
    [2] = {
        'Need an admin? Join our discord at: https://getcomfy.eu/discord,',
        'and report it in #i-need-halp',
        'If you have played for more than 5h in our maps then,',
        'you are eligible to run the command /jail and /free'
    },
    [3] = {'Scenario repository for download:', 'https://github.com/ComfyFactory/ComfyFactorio'},
    [4] = {
        'If you feel like the server is lagging, run the following command:',
        '/server-ups',
        'This will display the server UPS on your top right screen.'
    },
    [5] = {
        "If you're not trusted - ask an admin to trust you."
    }
}

local links = {
    ['admin'] = brain[2],
    ['administrator'] = brain[2],
    ['discord'] = brain[1],
    ['download'] = brain[3],
    ['github'] = brain[3],
    ['greifer'] = brain[2],
    ['grief'] = brain[2],
    ['griefer'] = brain[2],
    ['griefing'] = brain[2],
    ['mod'] = brain[2],
    ['moderator'] = brain[2],
    ['scenario'] = brain[3],
    ['stealing'] = brain[2],
    ['stole'] = brain[2],
    ['troll'] = brain[2],
    ['stutter'] = brain[4],
    ['freeze'] = brain[4],
    ['lag'] = brain[4],
    ['lagging'] = brain[4],
    ['trust'] = brain[5],
    ['trusted'] = brain[5],
    ['untrusted'] = brain[5]
}

local function on_player_created(event)
    local player = game.get_player(event.player_index)
    player.print(
        '[font=' ..
            font ..
                ']' ..
                    '[color=#E99696]J[/color][color=#E9A296]o[/color][color=#E9AF96]i[/color][color=#E9BB96]n[/color] [color=#E9C896]t[/color][color=#E9D496]h[/color][color=#E9E096]e[/color] ☕[color=#E5E996]c[/color][color=#D8E996]o[/color][color=#CCE996]m[/color][color=#BFE996]f[/color][color=#B3E996]y[/color] [color=#A6E996]d[/color][color=#9AE996]i[/color][color=#96E99E]s[/color][color=#96E9AB]c[/color][color=#96E9B7]o[/color][color=#96E9C3]r[/color][color=#96E9D0]d[/color] [color=#96E9DC]>[/color][color=#96E9E9]>[/color] [color=#96DCE9]g[/color][color=#96D0E9]e[/color][color=#96C3E9]t[/color][color=#96B7E9]c[/color][color=#96ABE9]o[/color][color=#969EE9]m[/color][color=#9A96E9]f[/color][color=#A696E9]y[/color][color=#B396E9].[/color][color=#BF96E9]e[/color][color=#CC96E9]u[/color][color=#D896E9]/[/color][color=#E596E9]d[/color][color=#E996E0]i[/color][color=#E996D4]s[/color][color=#E996C8]c[/color][color=#E996BB]o[/color][color=#E996AF]r[/color][color=#E996A2]d[/color]' ..
                        '[/font]'
    )
end

local function process_bot_answers(event)
    local player = game.get_player(event.player_index)
    if player.admin then
        return
    end
    local message = event.message
    message = string.lower(message)
    for word in string.gmatch(message, '%g+') do
        if links[word] then
            for _, bot_answer in pairs(links[word]) do
                player.print('[font=' .. font .. ']' .. bot_answer .. '[/font]', font_color)
            end
            return
        end
    end
end

local function on_console_chat(event)
    if not event.player_index then
        return
    end
    local secs = Server.get_current_time()
    if not secs then
        return
    end
    process_bot_answers(event)
end

Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_console_chat, on_console_chat)
