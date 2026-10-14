local _,F=...
local P=F.Pets
P.xpTreatCatalog=true
P.xpTreats={}
for rarity,xp in ipairs({25,50,100,200,400})do
  P.xpTreats[16+rarity]={name=P.rarities[rarity].." XP Treat",rarity=rarity,xp=xp,icon="Ability_Hunter_BeastTraining"}
end
function P.StackLimit(item)return item and item.crate and (P.coinPouches[item.crate] or P.xpTreats[item.crate]) and 30 or 1 end
function P.CanFitBagCrate(index)
  if P.BagCount()<P.BagCapacity()then return true end
  if P.state.trade or P.StackLimit({crate=index})==1 then return false end
  if P.GetBagLayout then
    local rows=P.GetBagLayout()
    for slot,item in pairs(rows)do if item.crate==index and #(P.state.bagLayout[slot])<30 then return true end end
  else
    local n=0;for _,item in ipairs(P.state.crates)do if item.crate==index then n=n+1 end end
    return n%30>0
  end
  return false
end
-- Count the extra slots needed by a trade, allowing incoming units to join
-- matching stacks while preserving enough space to cancel the outgoing offer.
function P.StackReservation(wires,decode)
  local free,needed={},0
  if P.GetBagLayout then
    local rows=P.GetBagLayout()
    for slot,item in pairs(rows)do if P.StackLimit(item)>1 then free[item.crate]=(free[item.crate] or 0)+30-#P.state.bagLayout[slot]end end
  end
  for _,wire in ipairs(wires or {})do local e=decode(wire)
    if e and (e.kind=="gear" or e.kind=="crate")then
      local item=e.item
      if P.StackLimit(item)>1 then
        if (free[item.crate] or 0)==0 then needed=needed+1;free[item.crate]=30 end
        free[item.crate]=free[item.crate]-1
      else needed=needed+1 end
    end
  end
  return needed
end
function P.RollXPTreat()
  local I=F.Integrity
  if not I or I.broken or I.count>=I.limit then return end
  if P.random(1,10000)>200 then return end -- 2% per eligible enemy, independent of other loot.
  local roll=P.random(1,10000)
  local rarity=roll<=6000 and 1 or roll<=8500 and 2 or roll<=9500 and 3 or roll<=9900 and 4 or 5
  return P.GrantCrate(16+rarity,"Enemy XP treat")
end
function P.UseXPTreat(id)
  local s=P.state;local item=P.CrateItem(id);local treat=item and P.xpTreats[item.crate];local pet=P.Active()
  if not treat then return false,"That XP treat is no longer in your bag."end
  if P.usingXPTreat or s.battle or s.trade then return false,"Finish your battle or trade before using an XP treat."end
  if not pet or pet.deadAt then return false,"Equip a living companion first."end
  if pet.level>=P.LevelCap()then return false,"Your equipped pet is at its level cap. The treat has been kept."end
  local I=F.Integrity
  if not I or I.broken then return false,"Item history is unavailable. The treat has been kept."end
  local ok,why=I.Check({audit=true,ownWires={I.Encode("crate",item)},remoteWires={}});if not ok then return false,why end
  local record=s.integrity.records[item.assetID]
  if not record or record.status~="owned" or record.owner~=I.Owner()then return false,"Treat ownership needs recovery. The treat has been kept."end
  local index;for i,v in ipairs(s.crates)do if v==item then index=i;break end end
  if not index then return false,"That treat is unavailable."end
  P.usingXPTreat=true
  -- Consume its individual receipt before XP callbacks; a stack is not a
  -- duplicable quantity counter. One use always redeems exactly one asset.
  I.Consumed("crate",item);table.remove(s.crates,index)
  local called,amount=pcall(P.AddXP,pet,treat.xp,"treat")
  P.usingXPTreat=nil
  if not called then error(amount)end
  record.petID=pet.id;record.xp=amount;record.openedAt=F.Now()
  P.FindHistory("Used "..treat.name..": +"..amount.." XP for "..P.species[pet.species])
  P.notice="Used "..treat.name..": +"..amount.." XP for "..P.species[pet.species].."."
  return true,amount
end
