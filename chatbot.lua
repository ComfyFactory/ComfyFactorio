local event = require 'utils.event'
local message_color = {r = 0.5, g = 0.3, b = 1}

local brain = {
    [1] = {"Our Discord server is at https://getcomfy.eu/discord"},
    [2] = {"Need an admin? Type @Mods in game chat to notify moderators,", "or put a message in the discord help channel."}
}

local links = {
    ["discord"] = brain[1],
    ["admin"] = brain[2],
    ["administrator"] = brain[2],
    ["mod"] = brain[2],
    ["moderator"] = brain[2],
    ["grief"] = brain[2],
    ["troll"] = brain[2],
    ["trolling"] = brain[2],
    ["stealing"] = brain[2],
    ["stole"] = brain[2],
    ["griefer"] = brain[2],
    ["greifer"] = brain[2]
}

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.print("Join the comfy discord >> getcomfy.eu/discord", message_color)
end

commands.add_command(
    'trust',
    'Promotes a player to the global.trusted_players',
    function(cmd)
        local player = game.player
        local target_player = game.players[cmd.parameter]
        local p

        if player then
            p = player.print
            if not player.admin then
                p("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                return
            end
        else
            p = log
        end

        if target_player ~= nil then 
            if global.trusted_players[target_player.name] == true then game.print(target_player.name .. " is already trusted!") return end
            global.trusted_players[target_player.name] = true
            game.print(target_player.name .. " is now a trusted player.", {r=0.22, g=0.99, b=0.99})
            for _, a in pairs(game.connected_players) do
                if a.admin == true and a.name ~= player.name then
                    a.print("[ADMIN]: " .. player.name .. " trusted " .. target_player.name, {r = 1, g = 0.5, b = 0.1})
                end
            end
        end
    end
)

commands.add_command(
    'untrust',
    'Demotes a player to the global.trusted_players',
    function(cmd)
        local player = game.player
        local target_player = game.players[cmd.parameter]
        local p

        if player then
            p = player.print
            if not player.admin then
                p("You're not admin!", {r = 1, g = 0.5, b = 0.1})
                return
            end
        else
            p = log
        end

        if target_player ~= nil then 
            if global.trusted_players[target_player.name] == false then game.print(target_player.name .. " is already untrusted!") return end
            global.trusted_players[target_player.name] = false
            game.print(target_player.name .. " is now untrusted.", {r=0.22, g=0.99, b=0.99})
            for _, a in pairs(game.connected_players) do
                if a.admin == true and a.name ~= player.name then
                    a.print("[ADMIN]: " .. player.name .. " untrusted " .. target_player.name, {r = 1, g = 0.5, b = 0.1})
                end
            end
        end
    end
)

local function process_bot_answers(event)
    local player = game.players[event.player_index]
    if player.admin == true then return end 
    local message = event.message
    message = string.lower(message)
    for word in string.gmatch(message, "%g+") do
        if links[word] then
            local player = game.players[event.player_index]
            for _, bot_answer in pairs(links[word]) do
                player.print(bot_answer, message_color)
            end
            return
        end
    end
end

local function on_console_chat(event)
    if not event.player_index then return end
    process_bot_answers(event)  
end

--share vision of silent-commands with other admins
local function on_console_command(event)        
    if event.command ~= "silent-command" then return end
    if not event.player_index then return end
    local player = game.players[event.player_index] 
    for _, p in pairs(game.connected_players) do
        if p.admin == true and p.name ~= player.name then
            p.print(player.name .. " did a silent-command: " .. event.parameters, {r=0.22, g=0.99, b=0.99})
        end
    end     
end

event.add(defines.events.on_player_created, on_player_created)
event.add(defines.events.on_console_chat, on_console_chat)
event.add(defines.events.on_console_command, on_console_command)