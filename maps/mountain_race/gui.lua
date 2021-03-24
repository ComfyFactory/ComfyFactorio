local Public = {}

function Public.create_top_gui(player)
    local element = player.gui.top.mountain_race
    if element then
        return
    end
    element = player.gui.top.add({type = 'frame', name = 'mountain_race', direction = 'horizontal'})
    element.style.maximal_height = 38

    local team = element.add({type = 'label', caption = 'Loading...'})
    team.style.font = 'heading-2'
    local text = element.add({type = 'label'})
    text.style.font = 'heading-2'
    text.style.font_color = {225, 225, 225}
end

local function get_status_string(mountain_race)
    local north = mountain_race.locomotives.north
    local south = mountain_race.locomotives.south

    if not north then
        return {{255, 65, 65}, 'SOUTH', ' has won the race!'}
    end
    if not south then
        return {{75, 75, 255}, 'NORTH', ' has won the race!'}
    end

    local distance = math.floor(math.abs(north.position.x - south.position.x))
    if distance == 0 then
        return {{200, 200, 0}, 'Teams', ' are equal'}
    end

    if north.position.x > south.position.x then
        return {{75, 75, 255}, 'NORTH', ' is ' .. distance .. ' units in the lead'}
    else
        return {{255, 65, 65}, 'SOUTH', ' is ' .. distance .. ' units in the lead'}
    end
end

function Public.update_top_gui(mountain_race)
    local status = get_status_string(mountain_race)
    for _, player in pairs(game.connected_players) do
        local element = player.gui.top.mountain_race
        if element and element.valid then
            element.children[1].style.font_color = status[1]
            element.children[1].caption = status[2]
            element.children[2].caption = status[3]
        end
    end
end

return Public
