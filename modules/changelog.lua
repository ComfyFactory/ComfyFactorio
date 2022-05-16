local Gui = require 'utils.gui'
local Token = require 'utils.token'

local module_name = Gui.uid_name()

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
end

local create_changelog_token = Token.register(create_changelog)

Gui.on_click(
    module_name,
    function(event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

Gui.add_tab_to_gui({name = module_name, caption = 'Changelog', id = create_changelog_token, admin = false})

return Public
