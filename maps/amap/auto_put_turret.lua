local Event = require("utils.event")
local ammo={}
ammo={
  [1]={name='firearm-magazine'},
  [2]={name='piercing-rounds-magazine'},
  [3]={name='uranium-rounds-magazine'}
}
local WPT = require 'maps.amap.table'

--�Զ��������ӵ�
local auto_put_turret = function(event)
  local magzine_count = 10 --�Զ�װ������
  local player = game.get_player(event.player_index)
  local this=WPT.get()
  local index=player.index
  if not this.tank[index] then return end
  if not(event.item == nil) then
    if (event.created_entity.name == "gun-turret") then
      for i=1,#ammo do
        local ammoInYourBag = player.get_item_count(ammo[#ammo-i+1].name)
        if ammoInYourBag ~= 0 then
        if ammoInYourBag >= magzine_count then
          event.created_entity.insert{name = ammo[#ammo-i+1].name,count = magzine_count}
          player.remove_item{name = ammo[#ammo-i+1].name,count = magzine_count}
          goto workflow
        end
      end
        -- body...
      end
      ::workflow::

    end
  end
end

--�����¼����ú���
local on_built_entity = function (event)
  auto_put_turret(event)--�Զ��������ӵ�
end


Event.add(defines.events.on_built_entity,on_built_entity)
