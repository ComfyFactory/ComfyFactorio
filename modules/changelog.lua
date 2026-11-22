local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local Token = require 'utils.token'

local module_name = Gui.uid_name()

local changelog =
{
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
    local panel_width = Style.content_width(data.player, frame)
    local width = math.max(1, panel_width - 2 * Style.spacing.md)

    for i, version in ipairs(changelog.versions) do
        local release = Style.surface(frame, 'release_' .. i, panel_width)
        local title = Style.text(release, { '', 'Version ', version.ver }, width, Style.colors.heading)
        title.style.font = 'default-bold'
        local date = Style.text(release, version.date, width, Style.colors.muted)
        date.style.bottom_margin = Style.spacing.xs
        Style.text(release, version.desc, width)
    end
end

local create_changelog_token = Token.register(create_changelog)

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Changelog')
    end
)

Gui.add_tab_to_gui({ name = module_name, caption = 'Changelog', id = create_changelog_token, admin = false })

return Public
