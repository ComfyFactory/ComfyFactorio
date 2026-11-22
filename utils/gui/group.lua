-- this script adds a group button to create groups for your players --

local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local Global = require 'utils.global'
local SpamProtection = require 'utils.spam_protection'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Color = require 'utils.color_presets'

local module_name = Gui.uid_name()

local this =
{
    player_group = {},
    join_spam_protection = {},
    tag_groups =
    {
        ['Miner'] = { name = 'Miner', founder = 'script', description = '[img=item/electric-mining-drill]', static = true },
        ['Smeltery'] = { name = 'Smeltery', founder = 'script', description = '[img=item/stone-furnace]', static = true },
        ['Power'] = { name = 'Power', founder = 'script', description = '[img=item/big-electric-pole]', static = true },
        ['Production'] = { name = 'Production', founder = 'script', description = '[img=item/assembling-machine-1]', static = true },
        ['Science'] = { name = 'Science', founder = 'script', description = '[img=item/chemical-science-pack]', static = true },
        ['Trainman'] = { name = 'Trainman', founder = 'script', description = '[img=item/locomotive]', static = true },
        ['Oil processing'] = { name = 'Oil Processing', founder = 'script', description = '[img=fluid/crude-oil]', static = true },
        ['Trooper'] = { name = 'Trooper', founder = 'script', description = '[img=item/submachine-gun]', static = true },
        ['Fortifications'] = { name = 'Fortifications', founder = 'script', description = '[img=item/stone-wall]', static = true },
        ['Support'] = { name = 'Support', founder = 'script', description = '[img=item/repair-pack]', static = true }
    },
    alphanumeric = true
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local Public = {}

local function build_group_gui(data)
    local player = data.player
    local frame = data.frame
    local content_width = math.max(420, Style.content_width(player, frame))
    local inner_width = content_width - 2 * Style.spacing.md
    local show_form = frame.tags.group_form_open == true
    local name_text, description_text = 'Name', 'Description'
    local previous = frame.frame2
    if previous and previous.group_table then
        name_text = previous.group_table.new_group_name.text
        description_text = previous.group_table.new_group_description.text
        if #name_text > 30 then name_text = '' end
        if #description_text > 60 then description_text = '' end
    end
    frame.clear()

    local form = Style.surface(frame, 'frame2', content_width)
    form.add({ type = 'checkbox', name = 'comfy_group_form', caption = { 'gui.create_group' }, state = show_form })
    local fields = form.add({ type = 'flow', name = 'group_table', direction = 'horizontal' })
    fields.visible = show_form
    fields.style.horizontal_spacing = Style.spacing.sm
    fields.style.vertical_align = 'center'
    local name = fields.add({ type = 'textfield', name = 'new_group_name', text = name_text, tooltip = { 'gui.title' } })
    name.style.width = 124
    local description = fields.add({ type = 'textfield', name = 'new_group_description', text = description_text, tooltip = { 'gui.description' } })
    local create_width = 76
    description.style.width = inner_width - 124 - create_width - 2 * Style.spacing.sm
    for _, field in ipairs({ name, description }) do
        field.style.height = Style.dimensions.button_height
    end
    local create = Style.button(fields.add({ type = 'button', name = 'create_new_group', caption = { 'gui.create' } }))
    create.style.width = create_width

    local list = Style.surface(frame, 'groups_table', content_width)
    local groups = {}
    for key, group in pairs(this.tag_groups) do
        if group.name and group.founder and group.description then
            groups[#groups + 1] = key
        end
    end
    table.sort(groups)

    for _, key in ipairs(groups) do
        local group = this.tag_groups[key]
        local line = Style.toolbar(list)
        line.style.minimal_height = Style.dimensions.row_height
        local title = Style.heading(line, group.name)
        title.style.width = 118
        title.tooltip = group.name
        local description_label = line.add({ type = 'label', caption = group.description, tooltip = group.description })
        local count_width, join_width, delete_width = 74, 54, 60
        description_label.style.width = inner_width - 118 - count_width - join_width - delete_width - 4 * Style.spacing.sm
        description_label.style.single_line = true
        description_label.style.font_color = Style.colors.muted

        local members = {}
        for _, member in pairs(game.connected_players) do
            if this.player_group[member.name] == key then
                members[#members + 1] = member.name
            end
        end
        local count = line.add({ type = 'label', caption = { 'gui.group_members_online', #members }, tooltip = table.concat(members, '\n') })
        count.style.font_color = Style.colors.muted
        count.style.width = count_width

        local actions = line.add({ type = 'flow', name = 'group_actions', direction = 'horizontal', tags = { group_name = key } })
        actions.style.horizontal_spacing = Style.spacing.sm
        local joined = this.player_group[player.name] == key
        local can_delete = (player.admin or group.founder == player.name) and not group.static
        local join = Style.button(actions.add({ type = 'button', caption = { joined and 'gui.leave' or 'gui.join' } }))
        join.style.width = join_width
        local delete = Style.button(actions.add({
            type = 'button',
            caption = { 'gui.delete' },
            enabled = can_delete
        }), can_delete and 'danger' or nil)
        delete.style.width = delete_width
    end
end

local build_group_gui_token = Token.register(build_group_gui)

local function refresh_gui()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        local frame = Gui.get_player_active_frame(player)
        if frame and frame.name == 'Groups' and frame.frame2 then
            build_group_gui({ player = player, frame = frame })
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]

    if not this.player_group[player.name] then
        this.player_group[player.name] = '[Group]'
    end

    if not this.join_spam_protection[player.name] then
        this.join_spam_protection[player.name] = game.tick
    end
end

Gui.on_checked_state_changed('comfy_group_form', function (event)
    local frame = Gui.get_player_active_frame(event.player)
    if frame and frame.name == 'Groups' and event.element.parent == frame.frame2 then
        local show_form = event.element.state
        local tags = frame.tags
        tags.group_form_open = show_form or nil
        frame.tags = tags
        frame.frame2.group_table.visible = show_form
    end
end)

local function on_gui_text_changed(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.get_player(event.player_index)

    local name = element.name
    local text = element.text

    if name == 'new_group_name' then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Groups new_group_name')
        if is_spamming then
            return
        end
        if text:len() > 30 then
            element.text = ''
        end
    end
    if name == 'new_group_description' then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Groups new_group_desc')
        if is_spamming then
            return
        end
        if text:len() > 60 then
            element.text = ''
        end
    end
end

local function alphanumeric(str)
    return (string.match(str, '[^%w%s%p]') ~= nil)
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end
    local player = game.get_player(event.player_index)

    local name = element.name

    local frame = Gui.get_player_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Groups' then
        return
    end

    if name == 'create_new_group' then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Group Click')

        if is_spamming then
            return
        end

        local new_group_name = frame.frame2.group_table.new_group_name.text
        local new_group_description = frame.frame2.group_table.new_group_description.text
        if new_group_name ~= '' and new_group_name ~= 'Name' and new_group_description ~= 'Description' then
            if this.alphanumeric then
                if alphanumeric(new_group_name) then
                    player.print('Group name is not valid.', { color = { r = 0.90, g = 0.0, b = 0.0 } })
                    return
                end

                if alphanumeric(new_group_description) then
                    player.print('Group description is not valid.', { color = { r = 0.90, g = 0.0, b = 0.0 } })
                    return
                end
            end

            if string.len(new_group_name) > 64 then
                player.print('Group name is too long. 64 characters maximum.', { color = { r = 0.90, g = 0.0, b = 0.0 } })
                return
            end

            if string.len(new_group_description) > 128 then
                player.print('Description is too long. 128 characters maximum.', { color = { r = 0.90, g = 0.0, b = 0.0 } })
                return
            end

            this.tag_groups[new_group_name] =
            {
                name = new_group_name,
                description = new_group_description,
                founder = player.name
            }
            local color =
            {
                r = player.color.r * 0.7 + 0.3,
                g = player.color.g * 0.7 + 0.3,
                b = player.color.b * 0.7 + 0.3,
                a = 1
            }
            game.print(player.name .. ' has founded a new group!', color)
            game.print('>> ' .. new_group_name, { r = 0.98, g = 0.66, b = 0.22 })
            game.print(new_group_description, { r = 0.85, g = 0.85, b = 0.85 })

            frame.frame2.group_table.new_group_name.text = 'Name'
            frame.frame2.group_table.new_group_description.text = 'Description'
            refresh_gui()
            return
        end
    end

    local actions = element.parent
    local row = actions and actions.parent
    if actions and actions.name == 'group_actions' and row and row.parent == frame.groups_table then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Group Click')

        if is_spamming then
            return
        end

        local group_name = actions.tags.group_name
        local caption = element.caption and element.caption[1]

        if element.type == 'button' and caption == 'gui.join' then
            this.player_group[player.name] = group_name
            local str = '[' .. group_name
            str = str .. ']'
            player.tag = str
            if game.tick - this.join_spam_protection[player.name] > 600 then
                local color =
                {
                    r = player.color.r * 0.7 + 0.3,
                    g = player.color.g * 0.7 + 0.3,
                    b = player.color.b * 0.7 + 0.3,
                    a = 1
                }
                game.print(player.name .. ' has joined group "' .. group_name .. '"', color)
                this.join_spam_protection[player.name] = game.tick
            end
            refresh_gui()
            return
        end

        if element.type == 'button' and caption == 'gui.delete' then
            if this.tag_groups[group_name] and this.tag_groups[group_name].static then
                player.print('Static groups cannot be deleted.', { color = Color.warning })
                return
            end
            for _, players in pairs(game.players) do
                if this.player_group[players.name] then
                    if this.player_group[players.name] == group_name then
                        this.player_group[players.name] = '[Group]'
                        players.tag = ''
                    end
                end
            end
            game.print(player.name .. ' deleted group "' .. group_name .. '"')
            this.tag_groups[group_name] = nil
            refresh_gui()
            return
        end

        if element.type == 'button' and caption == 'gui.leave' then
            this.player_group[player.name] = '[Group]'
            player.tag = ''
            refresh_gui()
            return
        end
    end
end

function Public.alphanumeric_only(value)
    if value then
        this.alphanumeric = value
    else
        this.alphanumeric = false
    end
end

function Public.reset_groups()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        this.player_group[player.name] = '[Group]'
        this.join_spam_protection[player.name] = game.tick
    end
    if this.tag_groups and next(this.tag_groups) then
        for name, data in pairs(this.tag_groups) do
            if not data.static then
                this.tag_groups[name] = nil
            end
        end
    end
end

Gui.add_tab_to_gui({ name = module_name, caption = 'Groups', id = build_group_gui_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Groups')
    end
)

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_text_changed, on_gui_text_changed)

return Public
