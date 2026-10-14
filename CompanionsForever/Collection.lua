local _,F=...
local P,D=F.Pets,F.PetData
local function integer(n,lo,hi)return type(n)=="number" and n==math.floor(n) and n>=lo and n<=hi end
local function readable(v)
  if issecretvalue and issecretvalue(v)then return false end
  return not canaccessvalue or canaccessvalue(v)
end
local function safeText(s)return type(s)=="string" and #s<=120 and not s:find("[|%c]")end
P.gearSlots={"weapon","head","body","collar","trinket"}
P.gearSlotNames={weapon="Weapon",head="Head",body="Body",collar="Collar",trinket="Trinket"}
P.gearSlotIcons={weapon="INV_Sword_04",head="INV_Helmet_03",body="INV_Chest_Leather_01",collar="INV_Jewelry_Necklace_01",trinket="INV_Misc_Gem_Emerald_02"}
P.freeBagSlots=20
P.maxBagSlots=80
P.maxCrateRecords=2400 -- 80 full stacks; each unit keeps its own receipt.
function P.BagSlotUnlocked(slot)
  return integer(slot,1,P.maxBagSlots) and (slot<=P.freeBagSlots or P.state.bagSlots[slot]==true)
end
function P.BagCapacity()
  local count=P.freeBagSlots
  for slot=P.freeBagSlots+1,P.maxBagSlots do if P.state.bagSlots[slot]then count=count+1 end end
  return count
end
function P.BagUnlockCredits()
  local used=P.state.bagCreditsUsed
  return 5-(integer(used,0,5) and used or 0)
end
function P.BagSlotPrice()
  local count=P.BagCapacity()
  if count<P.maxBagSlots and P.BagUnlockCredits()>0 then return 0 end
  local bought=math.max(0,count-P.freeBagSlots-(5-P.BagUnlockCredits()))
  return count<P.maxBagSlots and (1+bought*(bought+1)/2) or nil
end
function P.UnlockBagSlot(slot)
  local s=P.state
  if s.battle then return false,"Finish the battle before expanding your bag." end
  if not integer(slot,P.freeBagSlots+1,P.maxBagSlots) or P.BagSlotUnlocked(slot)then
    return false,"That slot is already unlocked or is not a bag slot."
  end
  local cost=P.BagSlotPrice()
  if not cost or s.tokens<cost then return false,"Unlocking a slot costs "..P.TokenText(cost or 0).."." end
  if P.BagUnlockCredits()>0 then
    s.bagCreditsUsed=5-P.BagUnlockCredits()+1
    P.notice="Bag slot unlocked. "..P.BagUnlockCredits().." free unlocks left."
  else
    local _,paid=P.ChangeTokens(-cost,"BAGSLOT",tostring(slot))
    if paid~=-cost then return false,"Could not purchase this bag slot."end
    P.notice="Bag slot unlocked for "..P.TokenText(cost).."."
  end
  s.bagSlots[slot]=true
  return true
end
P.gearTypes={
  {name="Hunter's Fang",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=2},
  {name="Venom Fang",slot="weapon",icon="INV_Misc_MonsterFang_02",attack=1,speed=1},
  {name="Guardian Fang",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,hp=6},
  {name="Iron Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=8,armor=1},
  {name="Runner's Collar",slot="collar",icon="INV_Jewelry_Necklace_03",hp=6,speed=1},
  {name="Spiked Collar",slot="collar",icon="INV_Jewelry_Necklace_04",hp=5,attack=1},
  {name="Life Charm",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=10},
  {name="Wind Charm",slot="trinket",icon="INV_Misc_Gem_Sapphire_02",speed=2},
  {name="Stone Charm",slot="trinket",icon="INV_Misc_Gem_Opal_01",armor=2},
  {name="Scout's Hood",slot="head",icon="INV_Helmet_03",hp=4,speed=1},
  {name="Guardian's Helm",slot="head",icon="INV_Helmet_09",hp=5,armor=1},
  {name="Hunter's Cap",slot="head",icon="INV_Helmet_15",attack=1,hp=4},
  {name="Trail Harness",slot="body",icon="INV_Chest_Leather_01",hp=8,armor=1},
  {name="Runner's Vest",slot="body",icon="INV_Chest_Leather_03",hp=6,speed=1},
  {name="Battle Harness",slot="body",icon="INV_Chest_Chain_04",hp=6,attack=1},
  {name="Stonefang",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=2},
  {name="Razor Talon",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,speed=1},
  {name="Oakwood Maul",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,hp=6},
  {name="Dusk Claw",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,armor=1},
  {name="Boar Tusk",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,hp=4},
  {name="Frostbite Fang",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,speed=1},
  {name="Bronze Beak",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,hp=3,armor=1},
  {name="Wolfbone Blade",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=2},
  {name="Hunter's Thorn",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,hp=3,speed=1},
  {name="Bloodfang",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=2,effect="leech",minRarity=3},
  {name="Storm Talon",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,speed=1,effect="critical",minRarity=3},
  {name="Eagle's Fang",slot="weapon",icon="INV_Misc_MonsterFang_01",attack=1,hp=6,effect="precision",minRarity=3},
  {name="Trail Hood",slot="head",icon="INV_Helmet_09",hp=4,speed=1},
  {name="Ironbark Crown",slot="head",icon="INV_Helmet_09",hp=5,armor=1},
  {name="Tracker's Cap",slot="head",icon="INV_Helmet_09",attack=1,hp=4},
  {name="Feathered Hood",slot="head",icon="INV_Helmet_09",hp=3,speed=2},
  {name="Copper Helm",slot="head",icon="INV_Helmet_09",hp=7,armor=1},
  {name="Dune Mask",slot="head",icon="INV_Helmet_09",attack=1,hp=3},
  {name="Snowcap Hood",slot="head",icon="INV_Helmet_09",hp=5,speed=1},
  {name="Bristle Helm",slot="head",icon="INV_Helmet_09",hp=4,armor=2},
  {name="Ranger's Circlet",slot="head",icon="INV_Helmet_09",attack=1,hp=2,speed=1},
  {name="Seer's Crown",slot="head",icon="INV_Helmet_09",hp=4,speed=1,effect="precision",minRarity=3},
  {name="Ironwatch Helm",slot="head",icon="INV_Helmet_09",hp=5,armor=1,effect="ward",minRarity=3},
  {name="Moonwell Circlet",slot="head",icon="INV_Helmet_09",attack=1,hp=4,effect="renewal",minRarity=3},
  {name="Barkskin Harness",slot="body",icon="INV_Chest_Leather_01",hp=8,armor=1},
  {name="Swiftpaw Vest",slot="body",icon="INV_Chest_Leather_01",hp=6,speed=1},
  {name="Ironhide Coat",slot="body",icon="INV_Chest_Leather_01",attack=1,hp=6},
  {name="Dunehide Vest",slot="body",icon="INV_Chest_Leather_01",hp=10},
  {name="Scaleguard Harness",slot="body",icon="INV_Chest_Leather_01",hp=5,armor=2},
  {name="Woolen Battlecoat",slot="body",icon="INV_Chest_Leather_01",hp=9,speed=1},
  {name="Tracker's Wrap",slot="body",icon="INV_Chest_Leather_01",attack=1,hp=4,speed=1},
  {name="Coppermail Vest",slot="body",icon="INV_Chest_Leather_01",hp=7,armor=1},
  {name="Thornweave Coat",slot="body",icon="INV_Chest_Leather_01",attack=1,hp=7},
  {name="Heartwood Harness",slot="body",icon="INV_Chest_Leather_01",hp=8,armor=1,effect="renewal",minRarity=3},
  {name="Aegis Battlecoat",slot="body",icon="INV_Chest_Leather_01",hp=6,speed=1,effect="ward",minRarity=3},
  {name="Crimson Harness",slot="body",icon="INV_Chest_Leather_01",attack=1,hp=6,effect="leech",minRarity=3},
  {name="Oakroot Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=8,armor=1},
  {name="Fleetpaw Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=6,speed=1},
  {name="Bronze Spikes",slot="collar",icon="INV_Jewelry_Necklace_01",attack=1,hp=5},
  {name="Runed Leather Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=9},
  {name="Shellguard Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=4,armor=2},
  {name="Windwoven Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=3,speed=2},
  {name="Tracker's Chain",slot="collar",icon="INV_Jewelry_Necklace_01",attack=1,hp=3,speed=1},
  {name="Stonebound Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=7,armor=1},
  {name="Wolfhide Collar",slot="collar",icon="INV_Jewelry_Necklace_01",attack=1,hp=4},
  {name="Predator's Chain",slot="collar",icon="INV_Jewelry_Necklace_01",hp=8,armor=1,effect="critical",minRarity=3},
  {name="Lifebloom Collar",slot="collar",icon="INV_Jewelry_Necklace_01",hp=6,speed=1,effect="renewal",minRarity=3},
  {name="Sentinel's Collar",slot="collar",icon="INV_Jewelry_Necklace_01",attack=1,hp=5,effect="ward",minRarity=3},
  {name="Amber Heart",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=10},
  {name="Swiftfeather Charm",slot="trinket",icon="INV_Misc_Gem_Emerald_02",speed=2},
  {name="Granite Idol",slot="trinket",icon="INV_Misc_Gem_Emerald_02",armor=2},
  {name="Hunter's Token",slot="trinket",icon="INV_Misc_Gem_Emerald_02",attack=1,hp=4},
  {name="Copper Beetle",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=5,armor=1},
  {name="Breezestone",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=4,speed=1},
  {name="Carved Boar Idol",slot="trinket",icon="INV_Misc_Gem_Emerald_02",attack=2},
  {name="Moonstone Charm",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=7,speed=1},
  {name="River Pearl",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=8,armor=1},
  {name="Vampire Bat Idol",slot="trinket",icon="INV_Misc_Gem_Emerald_02",hp=10,effect="leech",minRarity=3},
  {name="Thunderheart Charm",slot="trinket",icon="INV_Misc_Gem_Emerald_02",speed=2,effect="critical",minRarity=3},
  {name="Hawkeye Lens",slot="trinket",icon="INV_Misc_Gem_Emerald_02",armor=2,effect="precision",minRarity=3},
}
P.gearEffects={
  leech={name="Leech",text="Equip: Heal for 3% of actual attack damage dealt (maximum 3% of max health per turn)."},
  critical={name="Keen Strikes",text="Equip: Attacks have a 5% chance to deal 25% extra damage."},
  precision={name="True Aim",text="Equip: +2 percentage points to attack hit chance (maximum 99% hit chance)."},
  ward={name="Guardian Ward",text="Equip: 8% chance to reduce a direct enemy hit by 25%. Does not block status effects."},
  renewal={name="Renewal",text="Equip: Restore 2% of max health every fifth pet turn in battle."},
}
function P.GearEffect(item)
  local d=item and P.gearTypes[item.kind]
  return d and item.rarity>=3 and d.effect and P.gearEffects[d.effect]
end
function P.GearEffects(pet)
  local effects={}
  for _,slot in ipairs(P.gearSlots)do
    local item=pet.gear and P.GearItem(pet.gear[slot]);local d=item and P.gearTypes[item.kind]
    if P.GearEffect(item)then effects[d.effect]=true end
  end
  return effects
end
function P.RollGearKind(rarity)
  local normal,special={},{}
  for id,d in ipairs(P.gearTypes)do
    if not d.effect then normal[#normal+1]=id
    elseif rarity>=3 then special[#special+1]=id end
  end
  local pool=#special>0 and P.random(1,10000)<=100 and special or normal
  return pool[P.random(1,#pool)]
end
P.coinPouches={
  [8]={name="Uncommon Coin Pouch",rarity=2,tokens=10},
  [9]={name="Rare Coin Pouch",rarity=3,tokens=25},
  [10]={name="Epic Coin Pouch",rarity=4,tokens=60},
  [11]={name="Legendary Coin Pouch",rarity=5,tokens=150},
}
local containerRarities={2,2,3,3,4,5}
function P.ContainerRarity(index)return containerRarities[index] or 2 end
function P.CrateRarity(index)return P.xpTreats and P.xpTreats[index] and P.xpTreats[index].rarity or P.equipmentCrates and P.equipmentCrates[index] and P.equipmentCrates[index].rarity or P.specialCrates and P.specialCrates[index] and P.specialCrates[index].rarity or P.coinPouches[index] and P.coinPouches[index].rarity or P.ContainerRarity(index) end
function P.RollCoinPouch()
  if not F.Integrity or F.Integrity.broken or F.Integrity.count>=F.Integrity.limit
    then return end
  if P.random(1,10000)>200 then return end
  local roll=P.random(1,10000)
  local index=roll<=8500 and 8 or roll<=9700 and 9 or roll<=9970 and 10 or 11
  return P.GrantCrate(index,"Enemy loot")
end
function P.OpenCoinPouch(id)
  local s=P.state;local item=P.CrateItem(id);local pouch=item and P.coinPouches[item.crate]
  if not pouch then return false,"That coin pouch is no longer in your bag."end
  if P.openingCoinPouch then return false,"A pouch is already being opened."end
  local I=F.Integrity
  if not I or I.broken then return false,"Asset history is unavailable. The pouch has been kept."end
  local ok,why=I.Check({audit=true,ownWires={I.Encode("crate",item)},remoteWires={}})
  if not ok then return false,why end
  local receipt=s.integrity.records[item.assetID]
  if not receipt or receipt.status~="owned" or receipt.owner~=I.Owner() then return false,"Pouch ownership history is missing. The pouch has been kept."end
  if s.tokens>P.maxTokens-pouch.tokens then return false,"Spend some tokens first. Your pouch has been kept."end
  local index;for i,entry in ipairs(s.crates)do if entry==item then index=i;break end end
  if not index then return false,"The pouch is not available."end
  -- No callbacks between consumption and credit. Repeated clicks, stale UI IDs,
  -- copied IDs and restored individual items cannot redeem this receipt again.
  P.openingCoinPouch=true
  I.Consumed("crate",item)
  receipt.tokens=pouch.tokens;receipt.openedAt=F.Now()
  table.remove(s.crates,index)
  P.ChangeTokens(pouch.tokens,"POUCH",item.assetID)
  P.openingCoinPouch=nil
  P.FindHistory("Opened "..pouch.name..": +"..pouch.tokens.." tokens")
  P.Reward("item","Coin pouch opened!",pouch.tokens.." pet tokens","INV_Misc_Bag_10",nil,pouch.rarity)
  P.notice="Opened "..pouch.name..": +"..pouch.tokens.." tokens."
  return true
end
P.rewards={}
function P.Reward(kind,title,detail,icon,species,rarity,petID,amount,petRolls)
  if kind=="xp" or kind=="level" then return end
  if P.AnnounceReward then P.AnnounceReward(kind,title,detail,rarity)end
  local q=P.rewards
  if #q>=30 then table.remove(q,1)end
  q[#q+1]={kind=kind,title=title,detail=detail,icon=icon,species=species,rarity=rarity or 1,petID=petID,amount=amount,rolls=petRolls}
  if P.StartRewards then P.StartRewards()end
end
function P.InitCollection()
  P.collectionRevision=(P.collectionRevision or 0)+1
  local s=P.state
  s.collection=type(s.collection)=="table" and s.collection or {}
  for species,entry in pairs(s.collection)do
    if not integer(species,1,#P.species) or type(entry)~="table" or not integer(entry.count,1,10000000)
      or not integer(entry.rarity,1,5) or not integer(entry.first,0,1e12) or not safeText(entry.source) then s.collection[species]=nil end
  end
  -- Imported collections have no trustworthy acquisition timeline. Preserve them
  -- as legacy records rather than inventing a simultaneous unlock event.
  for _,entry in pairs(s.collection)do entry.isNew=entry.isNew==true or nil end
  local legacy={}
  for _,pet in ipairs(s.pets)do
    local e=legacy[pet.species] or {count=0,rarity=1,first=math.floor(pet.born),source="Existing collection"}
    e.count=e.count+1;e.rarity=math.max(e.rarity,pet.rarity);e.first=math.min(e.first,math.floor(pet.born));legacy[pet.species]=e
  end
  for species,e in pairs(legacy)do
    if not s.collection[species]then s.collection[species]=e
    else s.collection[species].rarity=math.max(s.collection[species].rarity,e.rarity)end
  end
  s.gear=type(s.gear)=="table" and s.gear or {};local cleaned,ids={},{}
  for _,item in ipairs(s.gear)do
    if #cleaned<500 and type(item)=="table" and integer(item.id,1,1000000000) and not ids[item.id]
      and integer(item.kind,1,#P.gearTypes) and integer(item.rarity,0,5)then
      if not integer(item.enemyLevel,0,1000)then item.enemyLevel=nil end
      item.isNew=item.isNew==true or nil;cleaned[#cleaned+1]=item;ids[item.id]=true
    end
  end
  s.gear=cleaned
  local crates={}
  for _,item in ipairs(type(s.crates)=="table" and s.crates or {})do
    if #crates<P.maxCrateRecords and type(item)=="table" and integer(item.id,1,1000000000) and not ids[item.id]
      and (integer(item.crate,1,11) or (P.xpTreats and P.xpTreats[item.crate]) or (P.specialCrates and P.specialCrates[item.crate]) or (P.equipmentCrates and P.equipmentCrates[item.crate]))then
      item.rarity=P.CrateRarity(item.crate);item.isNew=item.isNew==true or nil;crates[#crates+1]=item;ids[item.id]=true
    end
  end
  s.crates=crates;s.pendingCrates=integer(s.pendingCrates,0,20000) and s.pendingCrates or 0
  s.nextGearID=integer(s.nextGearID,1,1000000001) and s.nextGearID or 1
  for _,item in ipairs(s.gear)do s.nextGearID=math.max(s.nextGearID,item.id+1)end
  for _,item in ipairs(s.crates)do s.nextGearID=math.max(s.nextGearID,item.id+1)end
  local equipped={}
  for _,pet in ipairs(s.pets)do
    pet.isNew=pet.isNew==true or nil
    pet.gear=type(pet.gear)=="table" and pet.gear or {}
    -- Keep item kind IDs and ownership stable when upgrading from three slots.
    if pet.gear.weapon==nil then pet.gear.weapon=pet.gear.fang end
    if pet.gear.trinket==nil then pet.gear.trinket=pet.gear.charm end
    pet.gear.fang=nil;pet.gear.charm=nil
    for slot,id in pairs(pet.gear)do
      local item=P.GearItem(id)
      if not item or P.gearTypes[item.kind].slot~=slot or equipped[id]then pet.gear[slot]=nil else equipped[id]=true end
    end
  end
  -- Give existing loose items enough room on the first migration. Never delete
  -- old overflow or repeat this grant on subsequent loads.
  if type(s.bagSlots)~="table" then
    s.bagSlots={}
    for slot=P.freeBagSlots+1,math.min(P.maxBagSlots,P.BagCount())do s.bagSlots[slot]=true end
  else
    for slot,value in pairs(s.bagSlots)do
      if not integer(slot,P.freeBagSlots+1,P.maxBagSlots) or value~=true then s.bagSlots[slot]=nil end
    end
  end
  s.bagCreditsUsed=integer(s.bagCreditsUsed,0,5) and s.bagCreditsUsed or 0
  local pending={}
  for _,entry in ipairs(type(s.finds)=="table" and s.finds or {})do
    if #pending<20000 and type(entry)=="table" and integer(entry.species,1,#P.species) and integer(entry.rarity,1,5) and safeText(entry.source)then pending[#pending+1]=entry end
  end
  s.finds=pending
  s.lootClaims=type(s.lootClaims)=="table" and s.lootClaims or {}
  local count=0;for guid,when in pairs(s.lootClaims)do
    count=count+1
    if count>512 or type(guid)~="string" or #guid>100 or not integer(when,0,1e12) or F.Now()-when>3600 then s.lootClaims[guid]=nil end
  end
  s.findHistory=type(s.findHistory)=="table" and s.findHistory or {}
  local history={}
  for _,entry in ipairs(s.findHistory)do
    if type(entry)=="table" and safeText(entry.text) and integer(entry.at,0,1e12)then history[#history+1]=entry end
  end
  while #history>100 do table.remove(history,1)end;s.findHistory=history
  local waiting={}
  for _,e in ipairs(type(s.towerLoot)=="table" and s.towerLoot or {})do
    if #waiting<20000 and type(e)=="table" and (integer(e.crate,1,6) or (integer(e.kind,1,#P.gearTypes) and integer(e.rarity,0,5) and integer(e.floor,1,100)))then waiting[#waiting+1]=e end
  end
  s.towerLoot=waiting
  P.rewards={}
  if P.rewardFrame then P.rewardFrame.item=nil;P.rewardFrame:Hide()end
end
function P.RecordDiscovery(species,rarity,source)
  local s=P.state;local e=s.collection and s.collection[species]
  if not s.collection then return end
  if not e then e={count=0,rarity=1,first=math.floor(F.Now()),source=source};s.collection[species]=e end
  e.count=e.count+1;e.rarity=math.max(e.rarity,rarity);e.isNew=true
  P.collectionRevision=(P.collectionRevision or 0)+1
  P.FindHistory(P.rarities[rarity].." "..P.species[species].." - "..source)
end
function P.MarkSpeciesSeen(species)
  local entry=P.state.collection[species];if entry then entry.isNew=nil end
  for _,pet in ipairs(P.state.pets)do if pet.species==species then pet.isNew=nil end end
  if P.UpdateNewMarkers then P.UpdateNewMarkers()end
end
function P.MarkPetSeen(id)
  local species
  for _,pet in ipairs(P.state.pets)do if pet.id==id then pet.isNew=nil;species=pet.species;break end end
  if species then
    for _,pet in ipairs(P.state.pets)do if pet.species==species and pet.isNew then species=nil;break end end
    if species and P.state.collection[species]then P.state.collection[species].isNew=nil end
  end
  if P.UpdateNewMarkers then P.UpdateNewMarkers()end
end
function P.FindHistory(text)
  local h=P.state.findHistory;h[#h+1]={at=math.floor(F.Now()),text=text:sub(1,120)}
  if #h>100 then table.remove(h,1)end
end
function P.RollRarity()
  local roll,total=P.random(1,100),0
  for rarity,chance in ipairs(D.lootOdds.rarity)do total=total+chance;if roll<=total then return P.UpgradeRarity(rarity) end end
end
function P.DropChance(kind)return D.lootOdds[kind]+P.TalentBonus(kind=="pet" and "petDrop" or "gearDrop")end
function P.PartyPetRoll(guid)
  if not readable(guid) or type(guid)~="string" or #guid>100 then return end
  -- Every client observing the same public creature GUID uses one shared roll.
  -- No currency/grant packet is trusted and no hidden identity is decoded.
  local seed=73129
  for i=1,#guid do seed=(seed*131+guid:byte(i))%2147483647 end
  seed=(seed*16807)%2147483647;seed=(seed*16807)%2147483647
  return seed%10000+1
end
P.gearRarityWeights={[0]=150,50,30,15,4,1}
function P.GearRarityRange(level)
  if not integer(level,0,1000)then return end
  if level<10 then return 0,1
  elseif level<20 then return 1,2
  elseif level<30 then return 1,3
  elseif level<40 then return 2,3
  elseif level<50 then return 2,4
  elseif level<=60 then return 3,4
  else return 4,5 end
end
function P.RollGearRarity(level)
  local low,high=P.GearRarityRange(level);if not low then return end
  -- Retain relative rarity weights, restricted to this enemy's bracket.
  local total=0;for rarity=low,high do total=total+P.gearRarityWeights[rarity]end
  local roll=P.random(1,total)
  for rarity=low,high do
    roll=roll-P.gearRarityWeights[rarity]
    if roll<=0 then return math.min(high,P.UpgradeRarity(rarity))end
  end
end
function P.CrateItem(id)
  for _,item in ipairs(P.state.crates or {})do if item.id==id then return item end end
end
function P.BagItem(id)return P.GearItem(id) or P.CrateItem(id)end
function P.BagDefinition(item)
  if P.xpTreats and P.xpTreats[item.crate]then return P.xpTreats[item.crate]end
  if P.equipmentCrates and P.equipmentCrates[item.crate]then return P.equipmentCrates[item.crate]end
  if P.specialCrates and P.specialCrates[item.crate]then return P.specialCrates[item.crate]end
  local pouch=P.coinPouches[item.crate];if pouch then return {name=pouch.name,icon="INV_Misc_Bag_10"}end
  if item.crate==7 then return {name="100 Token Gift Crate",icon="INV_Crate_01"}end
  if item.crate then
    local pack=D.packs[item.crate]
    return {name=pack and pack.name or "Unknown reward",icon=pack and pack.icon or "INV_Misc_QuestionMark"}
  end
  return P.gearTypes[item.kind]
end
function P.BagDescription(item)
  local treat=P.xpTreats and P.xpTreats[item.crate]
  if treat then return "Use: grants "..treat.xp.." flat XP to your equipped pet.\nNo gear or talent XP multiplier. Cannot exceed the pet's level cap.\nRight-click to use one. Stacks to 30 per rarity.\nSeparate from food used for feeding."end
  if P.equipmentCrates and P.equipmentCrates[item.crate]then return P.EquipmentCrateDescription(item.crate)end
  local special=P.specialCrates and P.specialCrates[item.crate]
  if special then return "Contains |cff3388ffRare "..P.species[special.species].."|r (level 1).\nSunglasses portrait; original native 3D model.\nUnopened crate can be traded. Both players need v1.1.3 or newer.\nRight-click to open once. Requires stable space."end
  local pouch=P.coinPouches[item.crate];if pouch then return "Contains "..pouch.tokens.." pet tokens.\nRight-click to open one. Stacks to 30 per rarity.\nContents are fixed. Unopened pouches can be traded."end
  if item.crate==7 then return "Contains 100 pet tokens.\nRight-click to open. Developer gift." end
  if item.crate then
    return "One random companion.\n"..P.CrateOddsHelp("pet",item.crate).."\nRight-click to open."
  end
  return P.GearDescription(item)
end
function P.GrantCrate(index,source,quiet)
  local s=P.state
  local special=P.specialCrates and P.specialCrates[index]
  local equipment=P.equipmentCrates and P.equipmentCrates[index]
  local treat=P.xpTreats and P.xpTreats[index]
  if not integer(index,1,11) and not special and not equipment and not treat then return false,"Invalid crate." end
  local room=P.CanFitBagCrate and P.CanFitBagCrate(index) or P.BagCount()<P.BagCapacity()
  local mail=not room or #s.crates+(F.Trades and F.Trades.RecordReserved("crate") or 0)>=P.maxCrateRecords
  if F.Mailbox and (index==7 or special)then mail=true end
  if (mail and not (F.Mailbox and F.Mailbox.CanReceive())) or s.nextGearID+(F.Trades and F.Trades.Reserved("bag") or 0)>1000000000 then return false,"Make room in your bag for the crate." end
  local item={id=s.nextGearID,crate=index,rarity=P.CrateRarity(index),isNew=true}
  if F.Integrity then F.Integrity.Stamp("crate",item,"S")end
  if (P.coinPouches[index] or treat or special or equipment) and not item.assetID then return false,"Asset history is full or unavailable. No item was created."end
  s.nextGearID=s.nextGearID+1
  if mail then F.Mailbox.Store("crate",item,nil,source)else s.crates[#s.crates+1]=item end
  if F.History then F.History.Birth(item,(index==7 or special) and "D" or "R",nil,index,0)end
  local name=P.BagDefinition(item).name
  P.FindHistory(name..(index==7 and " - Developer gift" or " - "..(source or "Dungeon reward")))
  if not quiet then P.Reward((P.coinPouches[index] or treat) and "item" or "crate_found",treat and "XP treat found!" or P.coinPouches[index] and "Coin pouch found!" or "Crate found!",name..(mail and "\nAn attachment is waiting in Mail." or "\nRight-click in your bag to "..(treat and "use one." or "open.")),P.BagDefinition(item).icon,nil,item.rarity)end
  if mail then F.Print(name.." sent to Mail. Make room in your bag to collect it.")end
  return true,item
end
function P.QueueCrate(index,source)
  local ok=P.GrantCrate(index,source)
  if ok then return true end
  local q=P.state.towerLoot or {};P.state.towerLoot=q
  if #q<400 then q[#q+1]={crate=index};P.Reward("crate_found","Crate waiting!",D.packs[index].name.." - claim in Equipment.",D.packs[index].icon,nil,P.CrateRarity(index))end
end
function P.QueueTowerGear(kind,rarity,floor)
  local q=P.state.towerLoot or {};P.state.towerLoot=q
  if #q<400 then q[#q+1]={kind=kind,rarity=rarity,floor=floor};P.Reward("item","Equipment waiting!",P.gearTypes[kind].name.." - claim in Equipment.",P.gearTypes[kind].icon,nil,rarity)end
end
function P.WaitingLootCount()return P.state.pendingCrates+#(P.state.towerLoot or {})end
function P.ClaimWaitingCrate()
  local q=P.state.towerLoot or {};local e=q[1]
  if e then
    local ok,msg
    if e.crate then ok,msg=P.GrantCrate(e.crate,"Tower reward")else ok,msg=P.GrantGear(e.kind,e.rarity,"Tower floor "..e.floor)end
    if ok then table.remove(q,1)end
    return ok,msg
  end
  if P.state.pendingCrates<1 then return false,"No dungeon crate waiting." end
  local ok,msg=P.GrantCrate(2)
  if ok then P.state.pendingCrates=P.state.pendingCrates-1 end
  return ok,msg
end
function P.OpenBagCrate(id)
  if P.openingBagCrate then return false,"A crate is already being opened."end
  local s=P.state;local item=P.CrateItem(id)
  if not item then return false,"That crate is no longer in your bag." end
  if P.xpTreats and P.xpTreats[item.crate]then return P.UseXPTreat(id)end
  if P.equipmentCrates and P.equipmentCrates[item.crate]then return P.OpenEquipmentCrate(id)end
  if P.specialCrates and P.specialCrates[item.crate]then
    local integrity=F.Integrity;local ledger=s.integrity
    local record=ledger and ledger.records and item.assetID and ledger.records[item.assetID]
    if not integrity or integrity.broken or not record or record.status~="owned" then return false,"The gift crate's asset history needs recovery. Crate preserved."end
    if integrity.count>=integrity.limit or ledger.sequence>=1000000000 then return false,"Asset history is full. Crate preserved."end
  end
  if P.coinPouches[item.crate]then return P.OpenCoinPouch(id)end
  if F.History and F.Integrity and item.assetID then
    local ok,why=F.Integrity.Check({audit=true,ownWires={F.Integrity.Encode("crate",item)},remoteWires={}});if not ok then return false,why end
  end
  if item.crate==7 then
    if s.tokens>P.maxTokens-100 then return false,"Spend some tokens before opening this crate." end
    if F.Integrity then F.Integrity.Consumed("crate",item)end
    for i,crate in ipairs(s.crates)do if crate==item then table.remove(s.crates,i);break end end
    P.ChangeTokens(100,"DEVGIFT",item.assetID)
    P.Reward("item","Gift opened!","100 pet tokens","INV_Misc_Coin_01",nil,2)
    return true
  end
  if s.battle then return false,"Finish the battle before opening a crate." end
  if P.StableCount()>=P.stableCapacity or #s.pets>=512 then return false,"Make room in your stable first." end
  local special=P.specialCrates and P.specialCrates[item.crate]
  local pack=special or D.packs[item.crate];local species,rarity
  if special then species,rarity=special.species,special.rarity
  else
    rarity=P.RollCrateReward("pet",item.crate)
    local pool=D.rosterPool;species=pool[P.random(1,#pool)]
  end
  P.openingBagCrate=true
  local called,ok,msg=pcall(function()
    local granted,pet=P.GrantPet(species,rarity,pack.name,true,function(companion)
      if F.History and item.assetID then
        F.History.Birth(companion,"B",item.assetID,item.crate,0)
        local record=s.integrity.records[item.assetID];if record then record.child=companion.assetID end
      end
      if F.Integrity then F.Integrity.Consumed("crate",item)end
      for i,crate in ipairs(s.crates)do if crate==item then table.remove(s.crates,i);break end end
    end)
    if granted then
      P.Reward("crate","Opening "..pack.name,"A companion is waiting inside...",pack.icon)
      P.Reward("pet","Companion found!",P.rarities[rarity].." "..P.PetName(pet),pack.name,species,rarity,pet.id,nil,pet.rolls)
    end
    return granted,pet
  end)
  P.openingBagCrate=nil
  if not called then error(ok)end
  return ok,msg
end
function P.UseBagItem(id)
  if P.CrateItem(id)then return P.OpenBagCrate(id)end
  return P.EquipGear(id)
end
function P.GrantGear(kind,rarity,source)
  if not integer(kind,1,#P.gearTypes) or not integer(rarity,0,5) or rarity<(P.gearTypes[kind].minRarity or 0)then return false,"Invalid equipment." end
  local s=P.state
  local mail=P.BagCount()>=P.BagCapacity() or #s.gear+(F.Trades and F.Trades.RecordReserved("gear") or 0)>=500
  if (mail and not (F.Mailbox and F.Mailbox.CanReceive())) or s.nextGearID+(F.Trades and F.Trades.Reserved("bag") or 0)>1000000000 then return false,"Your bag is full. Sell gear to make space." end
  local item={id=s.nextGearID,kind=kind,rarity=rarity,found=math.floor(F.Now()),isNew=true}
  if F.Integrity then F.Integrity.Stamp("gear",item,"S")end
  s.nextGearID=s.nextGearID+1
  if mail then F.Mailbox.Store("gear",item,nil,source)else s.gear[#s.gear+1]=item end
  if F.History then F.History.Birth(item,"R",nil,0,0)end
  local d=P.gearTypes[kind];local name=P.rarities[rarity].." "..d.name
  P.FindHistory(name.." - "..source)
  P.Reward("item","Equipment found!",name.."\n"..P.GearDescription(item),d.icon,nil,rarity)
  P.notice="Found "..name..". Open Equipment to equip it."
  if mail then P.notice=name.." sent to Mail.";F.Print(P.notice)end
  return true,item
end
P.equipmentBoxes={
  {name="Traveler's Equipment Box",cost=300,odds={80,20,0,0,0}},
  {name="Scout's Equipment Box",cost=600,odds={50,35,13,2,0}},
  {name="Adventurer's Equipment Box",cost=1200,odds={0,70,23,7,0}},
  {name="Veteran's Equipment Box",cost=2400,odds={0,55,32,12,1}},
  {name="Champion's Equipment Box",cost=4800,odds={0,35,40,22,3}},
  {name="Azeroth's Equipment Box",cost=9600,odds={0,15,45,33,7}},
}
-- Shared by shop cards, bag tooltips and opening rolls. Slot six is an
-- exclusive Mythic gear outcome, never a sixth pet rarity.
local hardCrateOdds={{0,0,90,9,1},{0,0,84,14,2},{0,0,75,21,4},{0,0,63,30,7},{0,0,48,40,12},{0,0,30,50,20}}
local mythicCrateOdds={.01,.02,.05,.1,.2,.5}
local function baseCrateOdds(kind,index)
  local definition=(kind=="gear" and P.equipmentBoxes or D.packs)[index]
  if not definition then return end
  if not (P.HardMode and P.HardMode.IsHard())then return definition.odds end
  local odds={unpack(hardCrateOdds[index])}
  if kind=="gear"then odds[6]=mythicCrateOdds[index];odds[3]=odds[3]-odds[6]end
  return odds
end
function P.CrateOdds(kind,index)
  local base=baseCrateOdds(kind,index);if not base then return end
  local odds={unpack(base)}
  local bonus=math.max(0,math.min(10000,math.floor(P.TalentBonus("rarity"))))/100
  local highest=1
  for rarity=1,5 do if (base[rarity] or 0)>0 then highest=rarity end end
  -- Add percentage points to the top advertised ordinary tier. Move the
  -- same weight out of the lowest tiers; never borrow from fixed Mythic odds.
  for rarity=1,highest-1 do
    local moved=math.min(odds[rarity] or 0,bonus)
    odds[rarity]=odds[rarity]-moved;odds[highest]=odds[highest]+moved
    bonus=bonus-moved
  end
  return odds
end
function P.RollCrateReward(kind,index)
  local odds=P.CrateOdds(kind,index);local hard=P.HardMode and P.HardMode.IsHard()
  local scale=(hard or P.TalentBonus("rarity")>0) and 100 or 1;local roll,total=P.random(1,100*scale),0
  for rarity,chance in ipairs(odds)do
    total=total+math.floor(chance*scale+.5)
    if roll<=total then
      if rarity==6 then return 5,P.HardMode.tierKinds[3][P.random(1,#P.HardMode.sets)][P.random(1,#P.gearSlots)]end
      return rarity,kind=="gear" and P.RollGearKind(rarity) or nil
    end
  end
  error("Invalid crate odds")
end
function P.CrateOddsLabel(rarity)return rarity==6 and "Mythic gear" or P.rarities[rarity]end
function P.CrateOddsColor(rarity)return rarity==6 and {1,.36,.65} or P.colors[rarity]end
function P.CrateOddsHelp(kind,index)
  local lines={P.HardMode and P.HardMode.IsHard() and "Hard mode - your rarity chances:" or "Your rarity chances:"}
  for rarity,chance in ipairs(P.CrateOdds(kind,index))do if chance>0 then
    local c=P.CrateOddsColor(rarity)
    lines[#lines+1]=string.format("|cff%02x%02x%02x%s: %g%%|r",math.floor(c[1]*255+.5),math.floor(c[2]*255+.5),math.floor(c[3]*255+.5),P.CrateOddsLabel(rarity),chance)
  end end
  lines[#lines+1]="Includes your active loot-rarity talent bonuses."
  lines[#lines+1]="Bonus adds to the top rarity, taken from the lowest rarity."
  if kind=="gear" and P.HardMode and P.HardMode.IsHard()then lines[#lines+1]="Mythic is a separate gear tier; its chance is fixed."end
  lines[#lines+1]="Contents use your active tower mode when opened."
  return table.concat(lines,"\n")
end
-- Native Classic objects, verified against wowdev/wow-listfile.
local crateModel={id=199739,path="World\\Generic\\PassiveDoodads\\Furniture\\Containers\\Crate03.m2",icon="INV_Crate_01",label="Crate",animatedLid=false}
local chestModel={id=219372,path="World\\SkillActivated\\Containers\\TreasureChest01.m2",icon="INV_Box_01",label="Chest",animatedLid=true}
function P.CrateModel(index)return index and index<=3 and crateModel or chestModel end
-- Preserve price-tier IDs while distinguishing the two container rows.
for i=1,6 do
  if i>3 then D.packs[i].name=D.packs[i].name:gsub("Crate$","Chest")end
  D.packs[i].icon=P.CrateModel(i).icon
  P.equipmentBoxes[i].name=P.equipmentBoxes[i].name:gsub("Box$",P.CrateModel(i).label)
end
function P.BuyEquipmentBox(index)
  local box=P.equipmentBoxes[index];local s=P.state
  if not box then return false,"Choose an equipment box." end
  if s.battle then return false,"Finish the battle first." end
  if s.tokens<box.cost then return false,"This equipment box costs "..box.cost.." tokens." end
  if P.BagCount()>=P.BagCapacity() or #s.gear+(F.Trades and F.Trades.RecordReserved("gear") or 0)>=500 or s.nextGearID+(F.Trades and F.Trades.Reserved("bag") or 0)>1000000000 then return false,"Your bag is full. Sell gear to make space." end
  local rarity,kind=P.RollCrateReward("gear",index)
  local receipt=P.ChangeTokens(-box.cost,"GEARBOX",tostring(index))
  P.Reward("crate","Opening "..box.name,"One permanent equipment item...","INV_Crate_01")
  local ok,item=P.GrantGear(kind,rarity,box.name)
  if ok and F.History and receipt then F.History.Birth(item,"E",receipt.ref,index,box.cost,receipt)end
  return ok,item
end
function P.GearItem(id)
  for _,item in ipairs(P.state.gear or {})do if item.id==id then return item end end
end
function P.GearOwner(id)
  for _,pet in ipairs(P.state.pets)do
    for _,slot in ipairs(P.gearSlots)do if pet.gear and pet.gear[slot]==id then return pet end end
  end
end
function P.GearOwners()
  local owners={}
  for _,pet in ipairs(P.state.pets)do for _,id in pairs(pet.gear or {})do owners[id]=pet end end
  return owners
end
function P.BagCount(owners)
  if P.GetBagLayout and P.state.bagSlots then
    local rows=P.GetBagLayout();local count=0;for _ in pairs(rows)do count=count+1 end
    return count+(F.Trades and F.Trades.Reserved("bag") or 0)
  end
  owners=owners or P.GearOwners()
  local n,stacks=0,{}
  for _,item in ipairs(P.state.crates or {})do
    if P.StackLimit and P.StackLimit(item)>1 then stacks[item.crate]=(stacks[item.crate] or 0)+1 else n=n+1 end
  end
  for _,count in pairs(stacks)do n=n+math.ceil(count/30)end
  for _,item in ipairs(P.state.gear)do if not owners[item.id]then n=n+1 end end
  return n+(F.Trades and F.Trades.Reserved("bag") or 0)
end
function P.GearSellPrice(item)return ({[0]=1,2,5,12,30,75})[item.rarity]end
function P.GearMultiplier(item)return item.rarity==0 and 0.5 or item.rarity end
-- Validate the entire selection before consuming any item or awarding tokens.
function P.SellGearBatch(ids)
  if P.state.battle then return false,"Finish the battle before selling equipment." end
  if type(ids)~="table" or #ids<1 or #ids>500 then return false,"Select equipment to sell." end
  local seen,items,owners,total={},{},P.GearOwners(),0
  for _,id in ipairs(ids)do
    if seen[id] then return false,"An item was selected more than once." end
    seen[id]=true
    local item=P.GearItem(id)
    if not item then return false,"A selected item is no longer in your bag. Select your items again." end
    if owners[id] then return false,"Unequip selected items before selling them." end
    items[#items+1]=item;total=total+P.GearSellPrice(item)
  end
  if P.state.tokens+total>P.maxTokens then return false,"Your token wallet is full." end
  for i=#P.state.gear,1,-1 do if seen[P.state.gear[i].id]then table.remove(P.state.gear,i)end end
  for _,item in ipairs(items)do
    if F.Integrity then F.Integrity.Consumed("gear",item)end
    P.ChangeTokens(P.GearSellPrice(item),"SALE",item.assetID)
    P.FindHistory("v"..F.version.." Sold gear #"..item.id..": "..P.gearTypes[item.kind].name)
  end
  P.notice="Sold "..#items.." equipment items for "..total.." tokens."
  return true
end
function P.SellGear(id)
  if P.state.battle then return false,"Finish the battle before selling equipment." end
  if P.GearOwner(id)then return false,"Unequip this item before selling it." end
  for i,item in ipairs(P.state.gear)do if item.id==id then
    local price=P.GearSellPrice(item)
    if P.state.tokens+price>P.maxTokens then return false,"Your token wallet is full." end
    if F.Integrity then F.Integrity.Consumed("gear",item)end
    table.remove(P.state.gear,i);P.ChangeTokens(price,"SALE",item.assetID)
    P.FindHistory("v"..F.version.." Sold gear #"..id..": "..P.gearTypes[item.kind].name)
    P.notice="Sold "..P.gearTypes[item.kind].name.." for "..price.." tokens."
    return true
  end end
  return false,"That item is no longer in your bag."
end
function P.GearBonuses(pet)
  local hp,attack,armor,speed=0,0,0,0
  for _,slot in ipairs(P.gearSlots)do
    local item=pet.gear and P.GearItem(pet.gear[slot])
    if item then
      local d=P.gearTypes[item.kind];local r=P.GearMultiplier(item)
      hp=hp+(d.hp or 0)*r;attack=attack+(d.attack or 0)*r;armor=armor+(d.armor or 0)*r;speed=speed+(d.speed or 0)*r
    end
  end
  return hp,attack,armor,speed
end
function P.GearDescription(item)
  local d=P.gearTypes[item.kind];local parts={}
  for _,key in ipairs({"hp","attack","armor","speed"})do if d[key] then parts[#parts+1]="+"..d[key]*P.GearMultiplier(item).." "..(key=="hp" and "health" or key)end end
  local description=table.concat(parts," / ");local effect=P.GearEffect(item)
  if effect then description=description.."\n|cff1eff00"..effect.text.." Identical effects do not stack.|r"end
  return description
end
function P.EquipGear(id)
  local pet=P.Active();local item=P.GearItem(id)
  if not pet or not item then return false,"Equip a living companion and choose an item." end
  if P.state.battle then return false,"Finish your battle before changing equipment." end
  local slot=P.gearTypes[item.kind].slot;pet.gear=pet.gear or {}
  if pet.gear[slot]==id then
    if P.BagCount()>=P.BagCapacity() then return false,"Your bag is full. Sell an item before unequipping gear." end
    pet.gear[slot]=nil;P.FindHistory("v"..F.version.." Unequipped gear #"..id.." from pet #"..pet.id);P.notice="Returned "..P.gearTypes[item.kind].name.." to your bag.";return true
  end
  if P.GearOwner(id) and pet.gear[slot] and P.BagCount()>=P.BagCapacity() then
    return false,"Your bag is full. Make room for the replaced item first."
  end
  for _,other in ipairs(P.state.pets)do if other.gear then for key,value in pairs(other.gear)do if value==id then other.gear[key]=nil end end end end
  pet.gear[slot]=id;item.isNew=nil
  P.FindHistory("v"..F.version.." Equipped gear #"..id.." on pet #"..pet.id)
  P.notice="Equipped "..P.gearTypes[item.kind].name.." on "..P.species[pet.species]..". Worn gear is shown above the bag.";return true
end
function P.ClaimFind(index)
  local entry=P.state.finds[index];if not entry then return false,"No companion waiting." end
  return P.GrantPet(entry.species,entry.rarity,entry.source,nil,function()
    table.remove(P.state.finds,index)
  end)
end
function P.SourceText(species)
  if D.specialSources and D.specialSources[species]then return D.specialSources[species]end
  if D.hiddenSpecies and D.hiddenSpecies[species]then return "Secret achievement companion.\nUnlocked through: "..(D.secretAchievements[species] or "a special challenge")..".\nNever found in ordinary crates or wild drops. Discovery remains after retirement or trading."end
  if P.IsAllowedSpecies and not P.IsAllowedSpecies(species)then return "Archived: outside the verified Classic / Forever / SoD roster. Discovery record preserved; unavailable from new rewards." end
  local modelNote=P.ModelUnavailable and P.ModelUnavailable(species) and "Model unavailable; substitute shown.\n" or ""
  local source=D.farmSources[species]
  if source then
    local lines={string.format("Solo: %g%% per kill. Party: 5%% shared; stable room required. No raid farming.",P.DropChance("pet")/100),source.name.." (NPC "..source.npc..")"}
    local hints=D.farmHints and D.farmHints[species] or {};local ordered={}
    local zone=GetRealZoneText and GetRealZoneText() or ""
    for _,h in ipairs(hints)do if zone~="" and h.location:find(zone,1,true)then ordered[#ordered+1]=h end end
    for _,h in ipairs(hints)do if zone=="" or not h.location:find(zone,1,true)then ordered[#ordered+1]=h end end
    for i=1,math.min(3,#ordered)do local h=ordered[i];lines[#lines+1]=h.location..(h.npc~=source.npc and (" ("..h.name..")") or "")end
    lines[#lines+1]=#ordered>0 and "Approx. spawn hints; patrols/realm spawns can vary." or "Location not verified yet."
    lines[#lines+1]="Also available from all crates."
    return modelNote..table.concat(lines,"\n")
  end
  if D.species[species].raid then return modelNote.."All adoption crates, or its matching raid boss reward." end
  if D.verifiedPets and D.verifiedPets[species]then
    return modelNote.."Crate only in this addon.\nModel and portrait tested in the Forever client.\n"..D.verifiedPets[species].source
  end
  return modelNote.."Crate only in this build.\nNo killable Classic source verified.\n"..(D.classicModels and D.classicModels[species] and "Model found in Classic data. A model is not proof of a wild spawn." or "Experimental expansion model; may be unavailable in this client.").."\nA place name in the pet's name is not a farming location."
end
function P.ReportPetRoll(species,roll,cutoff,party)
  if not (F.db and F.db.settings and F.db.settings.petRollChat)then return end
  local won=roll<=cutoff
  local result=won and "|cff33ff33Pet found!|r" or "|cffbbbbbbNo pet|r"
  F.Print(D.farmSources[species].name.." roll "..roll.."/10000 (need "..cutoff.." or less) - "..result..(party and " [Party]" or ""),true)
end
function P.RollKillLoot(guid,enemyLevel,fallbackLevel,elite)
  if not readable(guid) or type(guid)~="string" or not readable(enemyLevel) or not readable(fallbackLevel)then return end
  if P.ExcludedKill(guid)then return end
  local npc=tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
  if not npc then return end
  local s=P.state;local now=math.floor(F.Now());local count=0;local oldest
  for key,when in pairs(s.lootClaims)do
    if now-when>3600 then s.lootClaims[key]=nil
    else count=count+1;if not oldest or when<s.lootClaims[oldest]then oldest=key end end
  end
  if s.lootClaims[guid]then return end
  if count>=512 and oldest then s.lootClaims[oldest]=nil end
  s.lootClaims[guid]=now -- Deduplicate before any random roll, including failed rolls.
  if F.Achievements then F.Achievements.CreatureKill()end
  local species=D.farmByNPC[npc]
  local raid=IsInRaid and IsInRaid()
  local party=not raid and IsInGroup and IsInGroup()
  local hasRoom=(P.StableCount()<P.stableCapacity and #s.pets<512) or (F.Mailbox and F.Mailbox.CanReceive())
  local petEligible=not raid and (not party or hasRoom) and species and (not P.IsAllowedSpecies or P.IsAllowedSpecies(species)) and #s.finds<100
  local petRoll=petEligible and (party and P.PartyPetRoll(guid) or P.random(1,10000))
  local cutoff=party and 500 or P.DropChance("pet")
  if petRoll then P.ReportPetRoll(species,petRoll,cutoff,party)end
  if petEligible and petRoll<=cutoff then
    local rarity=P.RollRarity();local source=("Kill: "..D.farmSources[species].name):sub(1,120)
    local view,page=P.viewID,P.page
    local ok,foundPet=P.GrantPet(species,rarity,source)
    if ok and party and F.Witnesses then F.Witnesses.Found(guid,foundPet)end
    P.viewID=view;P.page=page
    if not ok then
      s.finds[#s.finds+1]={species=species,rarity=rarity,source=source}
      P.Reward("pet","Companion waiting in Mail!",P.rarities[rarity].." "..P.species[species],"INV_Letter_15",species,rarity)
    end
    P.notice="Found "..P.rarities[rarity].." "..P.species[species]..(ok and "!" or "! Claim it from the Collection log after battle or when space is available.")
  end
  local fallback=not P.GearRarityRange(enemyLevel) and P.GearRarityRange(fallbackLevel)~=nil
  local level=fallback and fallbackLevel or enemyLevel
  P.RollEquipmentLoot(level,npc,fallback,elite)
  if P.GearRarityRange(level)then P.RollCoinPouch();if P.RollXPTreat then P.RollXPTreat()end end
end
-- Shared 3% roll and rarity weights for ordinary and restricted dungeon kills.
-- A fallback level is explicitly player-derived; never save it as enemyLevel.
function P.RollEquipmentLoot(level,npc,fallback,elite)
  local s=P.state
  if not readable(npc)then return end
  if npc and P.excludedKillNPCs[npc]then return end
  if not readable(level)then return end
  P.lootDebug=P.lootDebug or {kills=0,eligible=0,full=0,rolls=0,drops=0}
  local debug=P.lootDebug;debug.kills=debug.kills+1
  if not P.GearRarityRange(level)then return end
  debug.eligible=debug.eligible+1
  -- Small currency drops use the same level gate and kill deduplication as gear.
  local rolled=P.random(0,elite==true and 2 or 1)
  if P.HardMode then rolled=P.HardMode.KillTokens(rolled)end
  local gained=math.min(rolled,P.maxTokens-s.tokens)
  if gained>0 then
    P.ChangeTokens(gained,"MOB",tostring(npc or 0))
  end
  if P.random(1,10000)<=50+P.TalentBonus("herbDrop") and s.inventory.medicine<P.supplyCap then
    P.AddSupply("medicine",1)
    P.Reward("supply","Healing herb found!","1 healing herb",P.items.medicine.icon,nil,1)
  end
  if ((P.BagCount()>=P.BagCapacity() or #s.gear+(F.Trades and F.Trades.RecordReserved("gear") or 0)>=500) and not (F.Mailbox and F.Mailbox.CanReceive())) or s.nextGearID+(F.Trades and F.Trades.Reserved("bag") or 0)>1000000000 then debug.full=debug.full+1;return end
  debug.rolls=debug.rolls+1
  if P.random(1,10000)<=P.DropChance("gear") then
    local rarity=P.RollGearRarity(level);local kind=P.RollGearKind(rarity)
    local source=fallback and ("Dungeon kill: player-level fallback "..level) or ("Level "..level.." NPC "..(npc or "unknown"))
    local ok,item=P.GrantGear(kind,rarity,source)
    if ok then
      item.npc=npc
      if fallback then item.fallbackLevel=level else item.enemyLevel=level end
      debug.drops=debug.drops+1
    end
  end
  if P.RollEquipmentCrateDrop then P.RollEquipmentCrateDrop(level)end
end
