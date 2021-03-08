local Event = require 'utils.event'
local msg = {
  [1] = {'amap.relax1'},
  [2] = {'amap.relax2'},
  [3] = {'amap.relax3'},
  [4] = {'amap.relax4'},
  [5] = {'amap.relax5'},
  [6] = {'amap.relax6'},
  [7] = {'amap.relax7'},
  [8] = {'amap.relax8'},
  [9] = {'amap.relax9'},
  [10] = {'amap.relax10'},
  [11] = {'amap.relax11'},
  [12] = {'amap.relax12'},
  [13] = {'amap.relax13'},
  [14] = {'amap.relax14'},
  [15] = {'amap.relax15'},
  [16] = {'amap.relax16'},
  [17] = {'amap.relax17'},
  [18] = {'amap.relax18'},
  [19] = {'amap.relax19'},
  [20] = {'amap.relax20'},

}

local on_tick = function()
  local roll = math.random(1, #msg)
  game.print(msg[roll],{r = 0.22, g = 0.88, b = 0.22})
end

Event.on_nth_tick(108000, on_tick)
