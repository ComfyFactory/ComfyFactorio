--- Resources for use in interacting with discord.
return {
    --- The names of the discord channels that can be referenced by name.
    -- See features.server.to_discord_named
    channel_names = {
        mtn_channel = 'mount-fortress',
        bb_channel = 'biter_battles',
        bot_quarters = 'bot-quarters',
        announcements = 'announcements',
        mod_lounge = 'mods-lounge',
        dev = 'dev',
        helpdesk = 'helpdesk'
    },
    --- The strings that mention the discord role.
    -- Has to be used with features.server.to_discord_raw variants else the mention is sanitized server side.
    role_mentions = {
        test_role = '<@&821767672642797649>',
        mtn_fortress = '<@&821485320133410846>',
        fish_defender = '<@&821485656576360538>',
        biter_battles = '<@&821486037401600000>',
        chronosphere = '<@&821485811430064179>',
        modded = '<@&520169053055221770>',
        map_updates = '<@&821509848746295336>',
        mods = '<@&497677008705290251>'
    }
}
