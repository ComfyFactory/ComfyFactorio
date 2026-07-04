local ScenarioTable = require 'maps.scrap_towny_ffa.table'

storage.game_mode = ScenarioTable.mode('game_mode') or 2

if ScenarioTable.enabled('persist_last_winner') or ScenarioTable.enabled('auto_reset_on_win') then
    local store = require 'maps.scrap_towny_ffa.game_settings_store'
    storage.last_winner_name = store.last_winner_name or ''
    storage.auto_reset_enabled = ScenarioTable.enabled('auto_reset_on_win') and store.auto_reset_enabled
else
    storage.last_winner_name = storage.last_winner_name or ''
    storage.auto_reset_enabled = false
end
