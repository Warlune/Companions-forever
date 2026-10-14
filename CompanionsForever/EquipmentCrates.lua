local _,F=...
local P=F.Pets
-- Separate from adoption crates. Permanent IDs travel with unopened bag items.
P.equipmentCrates={}
for i=3,6 do
  local box=P.equipmentBoxes[i]
  P.equipmentCrates[i+10]={name=box.name,icon=P.CrateModel(i).icon,box=i,rarity=P.ContainerRarity(i)}
end
function P.EquipmentCrateDescription(id)
  local d=P.equipmentCrates[id];local box=d and P.equipmentBoxes[d.box]
  if not box then return "Unknown equipment crate."end
  local lines={"One permanent equipment item.",P.CrateOddsHelp("gear",d.box)}
  lines[#lines+1]="Right-click to open once."
  lines[#lines+1]="Replaces this crate in your bag. Trade requires matching updated addons."
  return table.concat(lines,"\n")
end
function P.RollEquipmentCrateDrop(level)
  local I=F.Integrity
  if not P.GearRarityRange(level) or (P.BagCount()>=P.BagCapacity() and not (F.Mailbox and F.Mailbox.CanReceive()))
    or not I or I.broken or I.count>=I.limit then return end
  -- 1% per eligible kill; weights preserve 2 : 1 : .10 : .05 among tiers.
  if P.random(1,10000)>100 then return end
  local roll=P.random(1,315)
  return P.GrantCrate(roll<=200 and 13 or roll<=300 and 14 or roll<=310 and 15 or 16,"Enemy equipment crate")
end
function P.OpenEquipmentCrate(id)
  if P.openingBagCrate then return false,"A crate is already being opened."end
  local s=P.state;local crate=P.CrateItem(id);local d=crate and P.equipmentCrates[crate.crate]
  if not d then return false,"That equipment crate is no longer in your bag."end
  if s.battle then return false,"Finish the battle before opening a crate."end
  local reserved=F.Trades and F.Trades.RecordReserved("gear") or 0
  if P.BagCount()>P.BagCapacity() or #s.gear+reserved>=500
    or s.nextGearID+(F.Trades and F.Trades.Reserved("bag") or 0)>1000000000 then return false,"Make room in your bag first."end
  local I,H=F.Integrity,F.History;local ledger=s.integrity;local history=s.tokenHistory
  local record=ledger and ledger.records and ledger.records[crate.assetID]
  if not I or I.broken or not H or H.broken or not history or history.seq>=1000000000
    or not record or record.status~="owned" or I.count>=I.limit or ledger.sequence>=1000000000 then
    return false,"Asset history needs recovery or is full. Crate preserved."
  end
  local valid,why=I.Check({audit=true,ownWires={I.Encode("crate",crate)},remoteWires={}})
  if not valid then return false,why end
  if not H.Check(s) or history.seq>=1000000000 then return false,"Token history needs review. Crate preserved."end
  local index;for i,item in ipairs(s.crates)do if item==crate then index=i;break end end
  if not index then return false,"That crate is no longer in your bag."end
  P.openingBagCrate=true
  local called,ok,result=pcall(function()
    local box=P.equipmentBoxes[d.box];local rarity,kind=P.RollCrateReward("gear",d.box)
    local item={id=s.nextGearID,kind=kind,rarity=rarity,found=math.floor(F.Now()),isNew=true}
    I.Stamp("gear",item,"S")
    if not item.assetID then return false,"Asset history is unavailable. Crate preserved."end
    H.Birth(item,"B",crate.assetID,crate.crate,0)
    record.child=item.assetID;I.Consumed("crate",crate)
    -- Commit the one-for-one exchange before any presentation callbacks.
    table.remove(s.crates,index);s.gear[#s.gear+1]=item;s.nextGearID=s.nextGearID+1
    local gear=P.gearTypes[item.kind];local name=P.rarities[rarity].." "..gear.name
    P.FindHistory(name.." - "..box.name)
    P.Reward("crate","Opening "..box.name,"One permanent equipment item...",d.icon)
    P.Reward("item","Equipment found!",name.."\n"..P.GearDescription(item),gear.icon,nil,rarity)
    P.notice="Found "..name..". Open Equipment to equip it."
    return true,item
  end)
  P.openingBagCrate=nil
  if not called then error(ok)end
  return ok,result
end
