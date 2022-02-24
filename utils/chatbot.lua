local Event = require 'utils.event'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'

local font_color = Color.warning
local font_welcome = {r = 150, g = 100, b = 255, a = 255}
local font = 'default-game'


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
    ['lag'] = brain[4],
    ['lagging'] = brain[4],
    ['trust'] = brain[5],
    ['trusted'] = brain[5],
    ['untrusted'] = brain[5]
}

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.print('[font=' .. font .. ']' .. 'Join the comfy discord >> getcomfy.eu/discord' .. '[/font]', font_welcome)
end

local function process_bot_answers(event)
    local player = game.players[event.player_index]
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
