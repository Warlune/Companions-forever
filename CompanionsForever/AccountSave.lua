local _,F=...
local P,I,H=F.Pets,F.Integrity,F.History
local A={version=1};F.AccountSave=A
local function copy(v,seen)
  if type(v)~="table"then return v end
  seen=seen or {};if seen[v]then return seen[v]end
  local t={};seen[v]=t;for k,x in pairs(v)do t[k]=copy(x,seen)end;return t
end
A.Copy=copy
local function maximum(a,b)
  for k,v in pairs(b or {})do
    if type(v)=="number"then a[k]=math.max(type(a[k])=="number" and a[k] or 0,v)
    elseif v==true then a[k]=true
    elseif type(v)=="table"then if type(a[k])~="table"then a[k]={}end;maximum(a[k],v)
    elseif a[k]==nil then a[k]=v end
  end
end
function A.Identity()
  local realm=GetRealmName and GetRealmName();local owner=I.Owner()
  if not I.Safe(realm,80) or owner=="unknown"then return end
  -- Realm names distinguish Forever PvP/PvE rulesets. Never join unknown realms.
  return realm:lower():gsub("%s", ""),owner
end
local function normalize(source)
  if source~=nil and not P.ValidSave(source)then error("An old save needs recovery; it was not replaced.")end
  local character=F.char;local temporary={pets=copy(source),hardTowerSeed=character.hardTowerSeed}
  if temporary.pets and not F.Mailbox.Validate(temporary.pets)then error("Mailbox data needs recovery; all deliveries have been kept.")end
  F.char=temporary
  local ok,why=pcall(P.Init)
  local result=temporary.pets;F.char=character
  if not ok then error(why)end
  if I.broken or H.broken or F.Trades.broken then error("A save or pending trade needs history recovery before merging.")end
  return result
end
local function assets(s)
  local rows,byID,owners={},{},{}
  local function add(kind,item)
    if not I.ValidID(item.assetID) or byID[item.assetID]then error("Duplicate or missing asset history; merge paused.")end
    local row={kind=kind,item=item,record=copy(s.integrity.records[item.assetID])};rows[#rows+1]=row;byID[item.assetID]=row
  end
  for _,pet in ipairs(s.pets)do add("pet",pet)end
  for _,item in ipairs(s.gear)do add("gear",item)end
  for _,item in ipairs(s.crates)do add("crate",item)end
  for _,entry in ipairs(s.mailbox or {})do
    add(entry.kind,entry.item);for _,gear in ipairs(entry.gear or {})do add("gear",gear)end
  end
  local gearIDs={}
  for _,row in ipairs(rows)do if row.kind=="gear"then
    if gearIDs[row.item.id]then error("Conflicting equipment IDs; merge paused.")end
    gearIDs[row.item.id]=row.item.assetID
  end end
  for _,row in ipairs(rows)do if row.kind=="pet"then
    row.equipment={}
    for slot,id in pairs(row.item.gear or {})do
      local asset=gearIDs[id]
      if not asset or owners[asset]then error("Conflicting equipped gear; merge paused.")end
      row.equipment[slot]=asset;owners[asset]=row.item.assetID
    end
  end end
  return rows,byID
end
local function rebind(s,owner)
  local rows=assets(s)
  for _,row in ipairs(rows)do
    local item=row.item;local r=s.integrity.records[item.assetID]
    if not r or r.status~="owned" or r.fingerprint~=I.Fingerprint(row.kind,item) or r.revision~=item.assetRevision
      or (r.owner~=owner and r.revision>=999999998)then error("Asset ownership needs recovery before switching characters.")end
  end
  for _,row in ipairs(rows)do
    local item=row.item;local r=s.integrity.records[item.assetID]
    if r.owner~=owner then r.owner=owner;r.revision=r.revision+1;item.assetRevision=r.revision end
  end
end
function A.Merge(shared,source)
  local out=copy(shared)
  if shared.trade or source.trade then error("Finish the pending trade on its original character, then reload to merge.")end
  local left=assets(out);local right=assets(source)
  local records=out.integrity.records
  for id,r in pairs(source.integrity.records)do
    local prior=records[id]
    if prior and prior.fingerprint~=r.fingerprint then error("Conflicting asset histories; merge paused.")end
    if not prior then records[id]=copy(r)
    elseif prior.status=="consumed"then -- Consumption is terminal, even in an older imported history.
    elseif r.status=="consumed" or r.revision>prior.revision then records[id]=copy(r)
    elseif r.revision==prior.revision then
      if r.owner~=prior.owner then error("Asset owners conflict at the same revision; merge paused.")end
      -- Sender and recipient alts record the same transfer as sent/owned.
      -- Preserve the recipient's real item rather than deleting an inter-alt gift.
      if r.status=="owned" and prior.status=="sent"then records[id]=copy(r)end
    end
  end
  local recordCount=0;for _ in pairs(records)do recordCount=recordCount+1 end
  if recordCount>I.limit then error("Combined asset history is full. Old saves remain backed up.")end
  out.integrity.sequence=math.max(out.integrity.sequence,source.integrity.sequence)
  local chosen,order={},{}
  for _,rows in ipairs({left,right})do for _,row in ipairs(rows)do
    local item=row.item;local r=records[item.assetID]
    if r and r.status=="owned" and r.revision==item.assetRevision and row.record and row.record.status=="owned" and row.record.owner==r.owner then
      if r.fingerprint~=I.Fingerprint(row.kind,item)then error("An asset does not match its history; merge paused.")end
      if not chosen[item.assetID]then chosen[item.assetID]=copy(row);order[#order+1]=item.assetID end
    end
  end end
  for _,rows in ipairs({left,right})do for _,row in ipairs(rows)do
    local id=row.item.assetID
    if records[id].status=="owned" and not chosen[id]then error("A newer asset receipt has no matching item. Merge paused; saves kept.")end
  end end
  -- Keep coherent talent allocations from the source with more earned points.
  if source.training.total>out.training.total then out.training=copy(source.training)end
  if source.hardMode.trainingPurchased>out.hardMode.trainingPurchased then
    out.hardMode.training=copy(source.hardMode.training);out.hardMode.trainingPurchased=source.hardMode.trainingPurchased
  end
  maximum(out.hardMode.cleared,source.hardMode.cleared)
  out.hardMode.unlocked=out.hardMode.unlocked or source.hardMode.unlocked
  maximum(out.achievements,source.achievements)
  out.mailRead=out.mailRead or {};maximum(out.mailRead,source.mailRead)
  out.mailDeleted=out.mailDeleted or {};maximum(out.mailDeleted,source.mailDeleted)
  out.betaThanks122=out.betaThanks122==true or source.betaThanks122==true
  out.housingWelcome130=out.housingWelcome130==true or source.housingWelcome130==true
  maximum(out.bagSlots,source.bagSlots)
  out.bagCreditsUsed=math.max(out.bagCreditsUsed or 0,source.bagCreditsUsed or 0)
  maximum(out.inventory,source.inventory)
  maximum(out.bossClaims,source.bossClaims);maximum(out.bossEggs,source.bossEggs)
  maximum(out.lootClaims,source.lootClaims)
  out.knownAbilities=out.knownAbilities or {};maximum(out.knownAbilities,source.knownAbilities)
  out.seenAbilities=out.seenAbilities or {};maximum(out.seenAbilities,source.seenAbilities)
  for species,e in pairs(source.collection)do
    local prior=out.collection[species]
    if not prior then out.collection[species]=copy(e)else
      prior.count=math.max(prior.count,e.count);prior.rarity=math.max(prior.rarity,e.rarity)
      prior.first=math.min(prior.first,e.first);prior.sparkly=prior.sparkly or e.sparkly;prior.isNew=prior.isNew or e.isNew
    end
  end
  for _,key in ipairs({"playSeconds","nextTreatDrop","tradeSequence"})do out[key]=math.max(out[key] or 0,source[key] or 0)end
  -- Prior trade receipts must survive, including their replay protection.
  for id,receipt in pairs(source.tradeHistory or {})do
    local old=out.tradeHistory[id]
    if old and (old.outcome~=receipt.outcome or old.pair~=receipt.pair)then error("Trade receipts conflict; merge paused.")end
    if not old then out.tradeHistory[id]=copy(receipt)end
  end
  local trades=0;for _ in pairs(out.tradeHistory)do trades=trades+1 end
  if trades>2000 then error("Combined trade history is full. Saves kept for recovery.")end
  -- These are already-earned, unclaimed legacy rewards, not fresh random rolls.
  for _,key in ipairs({"finds","towerLoot"})do
    for _,entry in ipairs(source[key] or {})do out[key][#out[key]+1]=copy(entry)end
  end
  out.pendingCrates=(out.pendingCrates or 0)+(source.pendingCrates or 0)
  if #out.finds>20000 or #out.towerLoot>20000 or out.pendingCrates>20000 then error("Combined waiting rewards need recovery; saves kept.")end
  for _,key in ipairs({"archivedPets","archivedFinds"})do
    out[key]=out[key] or {};for _,entry in ipairs(source[key] or {})do out[key][#out[key]+1]=copy(entry)end
  end
  -- Housing shares the pet records, but has its own three spaces. Preserve
  -- those residents by asset identity while the merge reassigns local IDs.
  local housing=out.housingLife
  local oldPetAssets,housedAssets={},{}
  for _,pet in ipairs(shared.pets)do oldPetAssets[pet.id]=pet.assetID end
  if housing and housing.slots then for slot=1,3 do
    local resident=housing.slots[slot]
    local asset=resident and oldPetAssets[resident.petID]
    if asset and chosen[asset] and not chosen[asset].item.deadAt then housedAssets[asset]=true end
  end end
  local activeIDs,teamIDs={},{}
  for _,rows in ipairs({left,right})do for _,row in ipairs(rows)do if row.kind=="pet"then
    local s=rows==left and shared or source
    if row.item.id==s.active then activeIDs[#activeIDs+1]=row.item.assetID end
    if rows==left then for slot,id in pairs(s.hardMode.team)do if row.item.id==id then teamIDs[slot]=row.item.assetID end end end
  end end end
  out.pets={};out.gear={};out.crates={};out.mailbox={};out.active=nil;out.hardMode.team={}
  local nextPet,nextGear=math.max(shared.nextID,source.nextID),math.max(shared.nextGearID,source.nextGearID)
  local equipmentOwners={};local petIDs={}
  for _,id in ipairs(order)do local row=chosen[id];local item=row.item
    if row.kind=="pet"then
      if nextPet>=1000000 then error("Stable ID capacity reached; saves kept.")end
      item.id=nextPet;nextPet=nextPet+1;petIDs[id]=item.id;item.gear={}
      for slot,asset in pairs(row.equipment)do if chosen[asset]then
        if equipmentOwners[asset]then error("Duplicate equipped item; saves kept.")end
        equipmentOwners[asset]={pet=id,slot=slot}
      end end
    else
      if nextGear>1000000000 then error("Bag ID capacity reached; saves kept.")end
      item.id=nextGear;nextGear=nextGear+1
    end
  end
  for asset,owner in pairs(equipmentOwners)do chosen[owner.pet].item.gear[owner.slot]=chosen[asset].item.id end
  local capacity=out.hardMode.unlocked or out.achievements.tower>=100
  capacity=capacity and 16 or 9
  local living,bag=0,0;local bagCapacity=P.freeBagSlots
  for _,value in pairs(out.bagSlots)do if value==true then bagCapacity=bagCapacity+1 end end
  local function mail(row,gear)
    out.mailSequence=(out.mailSequence or 0)+1
    out.mailbox[#out.mailbox+1]={id=out.mailSequence,kind=row.kind,item=row.item,gear=gear,source="Alt save merge",at=F.Now()}
  end
  for _,id in ipairs(order)do local row=chosen[id];if row.kind=="pet"then
    local gear={};for _,asset in pairs(row.equipment)do if chosen[asset]then gear[#gear+1]=chosen[asset].item end end
    if #out.pets<512 and (row.item.deadAt or housedAssets[id] or living<capacity) and #out.gear+#gear<=500 then
      out.pets[#out.pets+1]=row.item;if not row.item.deadAt and not housedAssets[id]then living=living+1 end
      for _,item in ipairs(gear)do out.gear[#out.gear+1]=item end
    else mail(row,gear)end
  end end
  for _,id in ipairs(order)do local row=chosen[id];if row.kind~="pet" and not equipmentOwners[id]then
    local key=row.kind=="gear" and "gear" or "crates";local limit=key=="gear" and 500 or (P.maxCrateRecords or 100)
    if bag<bagCapacity and #out[key]<limit then out[key][#out[key]+1]=row.item;bag=bag+1 else mail(row)end
  end end
  local available={};for _,pet in ipairs(out.pets)do if not pet.deadAt then available[pet.id]=true end end
  -- IslandDiscovery remaps housing slots, pending XP and expedition IDs.
  for _,id in ipairs(activeIDs)do if available[petIDs[id]] and not housedAssets[id]then out.active=petIDs[id];break end end
  for slot,id in pairs(teamIDs)do if available[petIDs[id]] and not housedAssets[id]then out.hardMode.team[slot]=petIDs[id]end end
  out.nextID=nextPet;out.nextGearID=nextGear
  out.hardMode.restXPPet=nil;out.hardMode.restXPSeconds=0
  out.tokens=math.max(shared.tokens,source.tokens)
  H.broken=nil
  if not H.Append(out,out.tokens-shared.tokens,"ALTMERGE","")then error("Token history is full; balances and old saves kept.")end
  return out
end
function A.Initialize()
  A.profile=nil;A.error=nil
  local scope,owner=A.Identity();if not scope then A.error="Waiting for your character and realm to load.";return false end
  A.scope,A.owner=scope,owner
  if F.db.sharedGames~=nil and type(F.db.sharedGames)~="table"then A.error="The shared account index needs recovery. Saved data kept.";return false end
  F.db.sharedGames=F.db.sharedGames or {}
  local profile=F.db.sharedGames[scope]
  local marker=F.char.sharedGame
  if profile and (type(profile)~="table" or profile.version~=A.version or type(profile.members)~="table" or type(profile.state)~="table" or not I.Safe(profile.owner,180))then
    A.error="The shared save needs recovery. Existing saves and backups have been kept.";return false
  end
  if marker~=nil and type(marker)~="table"then A.error="The character's migration record needs recovery. Saved data kept.";return false end
  if profile and marker and marker.scope==scope and profile.owner==owner and F.ready and F.char.pets==P.state then
    P.Init();profile.state=P.state;A.profile=profile;return true
  end
  if marker and (not profile or marker.scope~=scope)then
    A.error="The shared account save is missing or belongs to another realm. Your character backup has been kept; restore the account save before continuing."
    return false
  end
  if profile and profile.state.trade and profile.owner~=owner then
    A.error="Finish the pending trade on "..profile.owner..", then log into this character. The shared stable is kept safe."
    return false
  end
  if profile and not profile.members[owner] and F.char.pets and F.char.pets.trade then
    -- Keep this character's old escrow operational until its trade is resolved.
    P.Init();A.error="Finish this character's pending trade, then reload to merge its save.";F.Print(A.error);return true
  end
  local original=F.char.pets
  if original and not marker and not F.char.beforeSharedGame then F.char.beforeSharedGame=copy(original)end
  local ok,result=pcall(function()
    if profile and profile.version~=A.version then error("Unsupported shared-save version. Update the addon; save kept.")end
    local state
    if not profile then
      state=normalize(original)
      if not state.trade and (P.StableCount()>P.stableCapacity or P.BagCount()>P.BagCapacity())then
        local empty=copy(state)
        empty.pets={};empty.gear={};empty.crates={};empty.mailbox={};empty.integrity.records={}
        empty.finds={};empty.towerLoot={};empty.pendingCrates=0;empty.archivedPets={};empty.archivedFinds={}
        empty.active=nil;empty.hardMode.team={}
        state=A.Merge(state,empty)
      end
    elseif not profile.members[owner] and original and not marker then
      local source=normalize(original);local current=normalize(profile.state)
      state=A.Merge(current,source)
    else state=normalize(profile.state)end
    -- An in-flight trade keeps its exact owner/revision until it finishes.
    if not state.trade then rebind(state,owner)end
    if not F.Mailbox.Validate(state)then error("Merged deliveries need recovery; original saves kept.")end
    return state
  end)
  if not ok then
    F.char.pets=original;P.state=nil;A.error="Account merge paused: "..tostring(result);F.Print(A.error);return false
  end
  -- Commit only after all import, history and ownership checks succeed.
  profile=profile or {version=A.version,members={},created=F.Now()}
  profile.state=result;profile.owner=owner;profile.members[owner]=profile.members[owner] or {at=F.Now(),imported=original~=nil}
  F.db.sharedGames[scope]=profile;A.profile=profile
  F.char.sharedGame={version=A.version,scope=scope,owner=owner}
  F.char.pets=result;P.Init();profile.state=P.state
  H.Event("ALT","")
  return true
end
function A.Logout()
  if A.profile and F.char and P.state==F.char.pets then
    A.profile.state=P.state;A.profile.owner=A.owner
    -- Only the account file owns gameplay after migration. Keep the old backup.
    F.char.pets=nil
  end
end
