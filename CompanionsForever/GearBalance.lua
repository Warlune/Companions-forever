local _,F=...
local P=F.Pets
-- One budget point buys 4 health, 1 attack, 1 armor or 1 speed.
-- Normal gear gets 4 points per rarity step; an equip effect costs 1 point.
-- Keep IDs, names, slots and effects so saved/traded items remain the same assets.
P.normalGearBudget={hp=1,attack=4,armor=4,speed=4,effect=4,total=16}
for _,d in ipairs(P.gearTypes)do
  if not d.hardSet and not d.hardTier then
    local budget=d.effect and 12 or 16
    local oldHP=d.hp or 0;local score=oldHP;local keys={}
    for _,key in ipairs({'attack','armor','speed'})do
      if (d[key] or 0)>0 then score=score+d[key]*4;keys[#keys+1]=key end
    end
    if #keys==0 then d.hp=budget
    else
      local used=0;local targets={}
      for _,key in ipairs(keys)do
        targets[key]=d[key]*budget/score
        -- Never lower an existing normal item's stat to meet the new budget.
        used=used+d[key]*4
      end
      while used+oldHP+4<=budget do
        local best=keys[1]
        for _,key in ipairs(keys)do if targets[key]-d[key]>targets[best]-d[best] then best=key end end
        if oldHP>0 and targets[best]-d[best]<.5 then break end
        d[best]=d[best]+1;used=used+4
      end
      if oldHP>0 then d.hp=budget-used end
    end
  end
end
