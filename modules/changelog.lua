local Event = require 'utils.event'
local Tabs = require 'comfy_panel.main'
local SpamProtection = require 'utils.spam_protection'
local Token = require 'utils.token'

local module_name = 'Changelog'

local changelog = {
    versions = {}
}

local Public = {}

function Public.SetVersions(versions)
    for i = 1, #versions do
	local v = versions[i]
	if v.ver == nil or v.date == nil or v.desc == nil then
	    log('ERROR in changelog.SetVersions missing ver, date or desc from version#' .. i .. ' got:\n' .. serpent.line(v))
	    return
	end
    end
    changelog.versions = versions
end

local function create_changelog(data)
    local frame = data.frame
    frame.clear()
    frame.style.padding = 4
    frame.style.margin = 0

    local scroll =
        frame.add {
        type = 'scroll-pane',
        name = 'scroll_changelog',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    for i = 1, #changelog.versions do
	local v = changelog.versions[i]
	local l = scroll.add {type = 'label', caption = 'Version ' .. v.ver .. ' -- ' .. v.date}
	l.style.font = 'heading-1'
	l.style.font_color = {r = 0.2, g = 0.9, b = 0.2}
	l.style.minimal_width = 780
	l.style.horizontal_align = 'center'
	l.style.vertical_align = 'center'

	local c = scroll.add {type = 'label', caption = v.desc}
	c.style.font = 'heading-2'
	c.style.single_line = false
	c.style.font_color = {r = 0.85, g = 0.85, b = 0.88}
	c.style.minimal_width = 780
	c.style.horizontal_align = 'left'
	c.style.vertical_align = 'center'

	local line_v = scroll.add {type = 'line'}
	line_v.style.top_margin = 4
	line_v.style.bottom_margin = 4
    end

    local b = frame.add {type = 'button', caption = 'CLOSE', name = 'close_changelog'}
    b.style.font = 'heading-2'
    b.style.padding = 2
    b.style.top_margin = 3
    b.style.left_margin = 333
    b.style.horizontal_align = 'center'
    b.style.vertical_align = 'center'
end

local create_changelog_token = Token.register(create_changelog)

local function on_gui_click(event)
    if not event or not event.element or not event.element.valid then
        return
    end

    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    local name = event.element.name

    if not name then
        return
    end

    if name == 'tab_' .. module_name then
        if SpamProtection.is_spamming(player, nil, 'Changelog Main Button') then
            return
        end
    end

    if name == 'close_changelog' then
        if SpamProtection.is_spamming(player, nil, 'Changelog Close Button') then
            return
        end
        player.gui.left.comfy_panel.destroy()
        return
    end
end

Tabs.add_tab_to_gui({name = module_name, id = create_changelog_token, admin = false})

Event.add(defines.events.on_gui_click, on_gui_click)

return Public
