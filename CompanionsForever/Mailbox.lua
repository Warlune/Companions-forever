local _,F=...
local P,I=F.Pets,F.Integrity
local M={earnedLimit=200};F.Mailbox=M
-- Letters contain only shipped information. Opening a letter never grants
-- anything; the beta gift requires an explicit, receipt-checked collection.
M.letters={
  {id="feedback130",subject="Have an idea or found a bug?",sender="Companions Forever",body="We would love to hear from you!\n\nIf you have ideas, suggestions or bugs to report, please leave a comment on the Companions Forever CurseForge page.\n\nI will also be making a Discord server for the addon soon. Stay tuned for more details!\n\nFor bugs, tell us what happened, what you were doing, and which addon version you are using. A screenshot or Lua error message helps too.\n\nCompanions Forever is still in beta, and your feedback helps shape future updates.\n\nThank you for playing and helping us improve!"},
  {id="housingWelcome130",subject="Housing is here - still in beta!",sender="Companions Forever",body="Welcome to housing in Companions Forever 1.3.0!\n\nBuild and decorate your own island, give your companions a home, and discover new furnishings, workstations and expeditions. Open Housing from the main addon window to get started.\n\nHousing and Companions Forever are still in beta. More updates, fixes and balance adjustments are on the way. Please keep sharing your feedback and bug reports!\n\nTo help you get started, enjoy 3 Furniture Crates. Collect them below, then right-click them in your bag to discover furnishings.\n\nThis gift can be collected once per ruleset, shared across characters in that ruleset. Make room for three items in your bag; your crates will wait here until you collect them.\n\nThank you for playing and helping us build Companions Forever!"},
  {id="betaThanks122",subject="Thank you for playing the beta!",sender="Companions Forever",body="Thank you for playing the Companions Forever beta!\n\nYour adventures, bug reports, suggestions and patience have helped make this addon better for everyone. Thank you for being part of it.\n\nAs a small thank-you, please enjoy:\n\n1 Azeroth's Adoption Chest\n1 Azeroth's Equipment Chest\n\nBoth chests use your active tower mode and loot-rarity talents when opened.\n\nThis gift can be collected once per ruleset, shared across your characters in that ruleset. Make room for two items in your bag, then press Collect.\n\nThe beta still has a few weeks to go, and more updates are on the way. Keep the feedback coming!"},
  {id="gettingStarted",subject="Your first companion",sender="The Stable Keeper",body="CAMP\nChoose and equip a pet from your stable. Feed restores food, Rest restores energy, and Heal spends herbs to restore health.\n\nTOWER\nChoose a floor and press Fight. Your pet attacks automatically. Select a pet to see its manual ability buttons. Pause stops the fight.\n\nEQUIPMENT\nDrag items between bag slots or onto an equipment slot. Right-click an XP Treat to give flat XP to your equipped pet. Food is for feeding; XP Treats grant experience.\n\nCOLLECTION\nBrowse discovered pets, abilities, achievements and frames. Claim completed achievements, then choose a frame to show around your mini pet and Camp portrait.\n\nMAIL & SETTINGS\nGifts and overflow wait here until you collect them. Click Mail again to close. Settings has window size, text size, high contrast and reduced motion."},
  {id="release120",subject="Welcome to 1.2.0",sender="Companions Forever",body="Your adventure continues!\n\nNormal and Hard Mode are together in one addon, with the collection spellbook, Sparkly companions, XP Treats, stacking coin pouches and new achievements.\n\nThis inbox holds gifts, overflow deliveries and announcements. Select an attachment to collect it when you have room. Deliveries never expire.\n\nClick Mail again to close the inbox and return to your adventure."},
  {id="sharing",subject="Your shared adventure",sender="The Stable Keeper",body="Characters on this account and realm share pets, equipment, tokens, talents and progress.\n\nLog into each alt once to merge its old save. The highest token balance and progression are kept, rather than added together.\n\nMigration overflow waits here, with pets' equipped gear attached. Old saves are backed up. Other realms keep separate adventures.\n\nMake room in your stable or bags, then collect each attachment. Nothing expires."},
}
local gifts={
  betaThanks122={crates={6,16},full="Make room for two items in your bag. Your gifts will stay in this mail.",success="Collected your Azeroth pet and equipment chests. Thank you for playing!"},
  housingWelcome130={crates={61,61,61},full="Make room for three items in your bag. Your furniture crates will stay in this mail.",success="Collected 3 Furniture Crates. Welcome to housing!"},
}
local function giftRecord(id)
  if F.db[id]==nil then F.db[id]={}end
  -- Fail closed if the saved claim record needs recovery.
  if type(F.db[id])~="table"then return {claimed=true,read=true,deleted=true}end
  local root=F.db[id]
  local scope=F.AccountSave and F.AccountSave.Identity()
  if not scope then return {claimed=true,read=true,deleted=true}end
  if root.scopes==nil then root.scopes={}end
  if type(root.scopes)~="table"then return {claimed=true,read=true,deleted=true}end
  if root.scopes[scope]==nil then
    -- The old global record never identified its recipient realm. Only the
    -- actual adventure's claim flag proves this ruleset received the gift.
    local claimed=P.state and P.state[id]==true
    root.scopes[scope]={claimed=claimed or nil,read=claimed and root.read or nil,deleted=claimed and root.deleted or nil}
  end
  if type(root.scopes[scope])~="table"then return {claimed=true,read=true,deleted=true}end
  local record=root.scopes[scope]
  if P.state and P.state[id]==true then record.claimed=true end
  return record
end
M.GiftRecord=giftRecord
function M.LetterRead(id)
  if gifts[id]then return giftRecord(id).read==true end
  return (P.state.mailRead or {})[id]==true
end
function M.LetterDeleted(id)
  if gifts[id]then return giftRecord(id).deleted==true end
  return (P.state.mailDeleted or {})[id]==true
end
function M.HasAttachments(entry)
  return type(entry)=="table" and (entry.kind~="letter" or (gifts[entry.id]~=nil and not giftRecord(entry.id).claimed))
end
function M.Attachments(entry)
  local result={}
  if not M.HasAttachments(entry)then return result end
  local function add(kind,item)
    if not item then return end
    if kind=="pet"then
      local species=F.PetData.species[item.species] or {}
      result[#result+1]={name=P.PetName(item),icon=species.icon or "INV_Box_PetCarrier_01",rarity=item.rarity or 1,
        description="Level "..(item.level or 1).." companion. Collect to move this pet to your stable.",count=1}
    else
      local d=P.BagDefinition(item)
      result[#result+1]={name=d.name,icon=d.icon,rarity=item.crate and P.CrateRarity(item.crate) or item.rarity,
        description=P.BagDescription(item),count=1}
    end
  end
  if entry.kind=="letter" and gifts[entry.id]then
    for _,crate in ipairs(gifts[entry.id].crates)do add("crate",{crate=crate})end
  elseif entry.kind=="asset"then
    for _,delivery in ipairs(P.state.mailbox or {})do if delivery.id==entry.delivery.id then
      add(delivery.kind,delivery.item)
      for _,gear in ipairs(delivery.gear or {})do add("gear",gear)end
      break
    end end
  elseif entry.kind=="finds"then add("pet",(P.state.finds or {})[1])
  elseif entry.kind=="rewards"then
    local item=(P.state.towerLoot or {})[1]
    if item then add(item.crate and "crate" or "gear",item)
    elseif (P.state.pendingCrates or 0)>0 then add("crate",{crate=2})end
  end
  return result
end
function M.ClaimGift(id)
  local gift=gifts[id];if not gift then return false,"This letter has no gift."end
  local countNeeded=#gift.crates
  local s=P.state;local record=giftRecord(id);local H,A=F.History,F.AccountSave
  if M.claiming or record.claimed then return false,"This thank-you gift has already been collected."end
  if s.battle or s.trade then return false,"Finish your battle or trade before collecting mail."end
  if P.BagCount()+countNeeded>P.BagCapacity() or #s.crates+countNeeded>P.maxCrateRecords or s.nextGearID+countNeeded>1000000000 then
    return false,gift.full
  end
  if I.broken or H.broken or not s.integrity or I.count+countNeeded>I.limit or s.integrity.sequence+countNeeded>1000000000
    or not H.Check(s) or s.tokenHistory.seq+countNeeded>1000000000 or I.Owner()=="unknown"then
    return false,"Asset history needs recovery or is full. Your gifts remain unclaimed."
  end
  -- Stage the entire bundle together. Any failed receipt rolls back the claim.
  local ledger,history,count,origins=s.integrity,s.tokenHistory,I.count,H.origins
  M.claiming=true;s.integrity=A.Copy(ledger);s.tokenHistory=A.Copy(history);H.origins=A.Copy(origins)
  local ok,items=pcall(function()
    local gifts={}
    for offset,crate in ipairs(gift.crates)do
      local item={id=s.nextGearID+offset-1,crate=crate,rarity=P.CrateRarity(crate),isNew=true}
      I.Stamp("crate",item,"S");H.Birth(item,"R",nil,crate,0)
      if not item.assetID or not item.birth or not H.CheckBirth(item,item.birth)then error("Gift receipt unavailable")end
      gifts[#gifts+1]=item
    end
    return gifts
  end)
  if not ok then
    s.integrity,s.tokenHistory,I.count,H.origins=ledger,history,count,origins;M.claiming=nil
    return false,"Could not prepare the gift receipts. Your gifts remain unclaimed."
  end
  for _,item in ipairs(items)do s.crates[#s.crates+1]=item end
  s.nextGearID=s.nextGearID+countNeeded;s[id]=true
  record.claimed=true;record.read=true;M.claiming=nil
  return true,gift.success
end
function M.ClaimBetaGift()return M.ClaimGift("betaThanks122")end
local init=P.Init
function P.Init(...)
  local result=init(...);local s=P.state
  if s then
    for _,entry in ipairs(s.mailbox or {})do
      if entry.kind=="crate" and entry.item then entry.item.rarity=P.CrateRarity(entry.item.crate)end
    end
    local old=type(s.mailRead)=="table" and s.mailRead or {};s.mailRead={}
    local deleted=type(s.mailDeleted)=="table" and s.mailDeleted or {};s.mailDeleted={}
    for _,letter in ipairs(M.letters)do s.mailRead[letter.id]=old[letter.id]==true end
    for _,letter in ipairs(M.letters)do if deleted[letter.id]==true then s.mailDeleted[letter.id]=true end end
    if old.sharing==nil and F.db.settings.hideMergeNotice then s.mailRead.sharing=true end
  end
  return result
end
function M.MarkRead(id)
  for _,letter in ipairs(M.letters)do if letter.id==id then
    if gifts[id]then giftRecord(id).read=true end
    P.state.mailRead=P.state.mailRead or {};P.state.mailRead[id]=true;return true
  end end
end
function M.Unread()
  local n=0
  for _,letter in ipairs(M.letters)do if not M.LetterDeleted(letter.id) and (not M.LetterRead(letter.id) or M.HasAttachments({kind="letter",id=letter.id}))then n=n+1 end end
  return n
end
-- The envelope tracks unread mail; uncollected attachments keep the Mail
-- button's NEW reminder without making an already-read letter pulse forever.
function M.HasUnreadMail()
  for _,letter in ipairs(M.letters)do
    if not M.LetterDeleted(letter.id) and not M.LetterRead(letter.id)then return true end
  end
  for _,entry in ipairs(P.state.mailbox or {})do if entry.read~=true then return true end end
  for _,key in ipairs({"finds","towerLoot"})do
    for _,item in ipairs(P.state[key] or {})do if item.mailRead~=true then return true end end
  end
  return (P.state.pendingCrates or 0)>(tonumber(P.state.mailPendingRead) or 0)
end
function M.MarkEntryRead(entry)
  if entry.kind=="letter"then return M.MarkRead(entry.id)end
  if entry.kind=="asset"then
    for _,delivery in ipairs(P.state.mailbox or {})do
      if delivery.id==entry.delivery.id then delivery.read=true;return end
    end
  elseif entry.kind=="finds" or entry.kind=="rewards"then
    for _,item in ipairs(P.state[entry.kind=="finds" and "finds" or "towerLoot"] or {})do item.mailRead=true end
    if entry.kind=="rewards"then P.state.mailPendingRead=P.state.pendingCrates or 0 end
  end
end
function M.InboxCount()
  local letters=0
  for _,letter in ipairs(M.letters)do if not M.LetterDeleted(letter.id)then letters=letters+1 end end
  return M.Count()+letters+(#(P.state.finds or {})>0 and 1 or 0)+(P.WaitingLootCount()>0 and 1 or 0)
end
-- Resolve visible rows directly, even if a migrated inbox has many deliveries.
function M.InboxEntry(index)
  local deliveries=P.state.mailbox or {};local e=deliveries[index]
  if e then
    local name=e.kind=="pet" and P.PetName(e.item) or P.BagDefinition(e.item).name
    local icon
    if e.kind=="pet"then icon=(F.PetData.species[e.item.species] or {}).icon or "INV_Box_PetCarrier_01"
    else icon=P.BagDefinition(e.item).icon end
    return {id="asset:"..e.id,kind="asset",delivery=e,subject=name,sender=e.source or "The Stable Keeper",icon=icon,
      body="An attachment is waiting for you.\n\n"..(e.kind=="pet" and ("Level "..e.item.level.." "..name.."\n"..P.Specialty(e.item).."\n"..#(e.gear or {}).." equipped items stay with this pet.") or P.BagDescription(e.item)).."\n\nThis delivery never expires."}
  end
  index=index-#deliveries
  if #(P.state.finds or {})>0 then
    if index==1 then return {id="finds",kind="finds",subject="Companions waiting: "..#P.state.finds,sender="The Stable Keeper",body="Companions from your earlier adventures are waiting. Make room in the stable, then collect the next companion."}end
    index=index-1
  end
  if P.WaitingLootCount()>0 then
    if index==1 then return {id="rewards",kind="rewards",subject="Tower rewards: "..P.WaitingLootCount(),sender="Tower Keeper",body="Your unclaimed tower and dungeon rewards are waiting. Make room in your bags, then collect the next reward."}end
    index=index-1
  end
  local letter
  for _,candidate in ipairs(M.letters)do if not M.LetterDeleted(candidate.id)then
    index=index-1;if index==0 then letter=candidate;break end
  end end
  if letter then return {id=letter.id,kind="letter",subject=letter.subject,sender=letter.sender,body=letter.body,unread=not M.LetterRead(letter.id)}end
end
function M.CanDelete(entry)
  if type(entry)~="table" or entry.kind~="letter" or M.HasAttachments(entry)then return false end
  for _,letter in ipairs(M.letters)do
    if entry.id==letter.id then return not M.LetterDeleted(letter.id) end
  end
  return false
end
function M.Delete(entry)
  if not M.CanDelete(entry)then return false,"Collect attachments before deleting mail."end
  if gifts[entry.id]then giftRecord(entry.id).deleted=true end
  P.state.mailDeleted=P.state.mailDeleted or {};P.state.mailDeleted[entry.id]=true
  M.MarkRead(entry.id)
  return true,"Mail deleted."
end
function M.Collect(entry)
  if not entry then return false,"Choose an attachment first."end
  if P.state.battle or P.state.trade then return false,"Finish your battle or trade before collecting mail."end
  if entry.kind=="letter" and gifts[entry.id]then return M.ClaimGift(entry.id)end
  if entry.kind=="asset"then return M.Claim(entry.delivery.id)
  elseif entry.kind=="finds"then return P.ClaimFind(1)
  elseif entry.kind=="rewards"then
    local ok,result=P.ClaimWaitingCrate()
    P.state.mailPendingRead=math.min(tonumber(P.state.mailPendingRead) or 0,P.state.pendingCrates or 0)
    return ok,result
  end
  return false,"This letter has no attachment."
end
function M.Validate(s)
  if s.mailbox==nil then return true end
  if type(s.mailbox)~="table" or #s.mailbox>I.limit then return false end
  if s.mailSequence~=nil and (type(s.mailSequence)~="number" or s.mailSequence~=math.floor(s.mailSequence) or s.mailSequence<0 or s.mailSequence>=1000000000)then return false end
  local ids,petIDs,bagIDs={},{},{}
  local maxPet,maxBag,maxMail=0,0,0
  local function integer(n,max)return type(n)=="number" and n==math.floor(n) and n>=1 and n<=max end
  local function item(kind,v)
    if type(v)~="table" or not integer(v.id,kind=="pet" and 999999 or 1000000000)then return false end
    local seen=kind=="pet" and petIDs or bagIDs
    if seen[v.id]then return false end;seen[v.id]=true
    if kind=="pet"then
      maxPet=math.max(maxPet,v.id)
      return P.ValidSave({version=1,pets={v},nextID=1,tokens=0,playSeconds=0,rewardSeconds=0,inventory={food=0,medicine=0}})
    end
    maxBag=math.max(maxBag,v.id)
    if kind=="gear"then return integer(v.kind,#P.gearTypes) and type(v.rarity)=="number" and v.rarity>=0 and v.rarity<=5 and v.rarity==math.floor(v.rarity)end
    return kind=="crate" and integer(v.crate,100) and (v.crate<=11 or P.specialCrates[v.crate] or P.equipmentCrates[v.crate] or (P.xpTreats and P.xpTreats[v.crate]))~=nil
  end
  for kind,key in pairs({pet="pets",gear="gear",crate="crates"})do for _,v in ipairs(s[key] or {})do
    if not item(kind,v)then return false end
  end end
  for _,e in ipairs(s.mailbox)do
    if type(e)~="table" or not integer(e.id,1000000000) or ids[e.id] or not item(e.kind,e.item)then return false end
    ids[e.id]=true;maxMail=math.max(maxMail,e.id)
    if e.gear~=nil and (e.kind~="pet" or type(e.gear)~="table" or #e.gear>5)then return false end
    local attached={}
    for _,v in ipairs(e.gear or {})do if not item("gear",v)then return false end;attached[v.id]=v end
    if e.kind=="pet"then
      for slot,id in pairs(e.item.gear or {})do
        local v=attached[id];if not v or P.gearTypes[v.kind].slot~=slot then return false end;attached[id]=nil
      end
      if next(attached)then return false end
    end
  end
  s.nextID=math.max(s.nextID,maxPet+1);s.nextGearID=math.max(s.nextGearID or 1,maxBag+1)
  s.mailSequence=math.max(type(s.mailSequence)=="number" and s.mailSequence or 0,maxMail)
  return true
end
function M.CanReceive()
  local s=P.state
  return s and #(s.mailbox or {})<M.earnedLimit and (s.mailSequence or 0)<999999999 and not I.broken and I.count<I.limit
end
-- Mail holds the actual rolled asset. Claiming never grants/rolls a replacement.
function M.Store(kind,item,gear,source)
  local s=P.state;s.mailbox=s.mailbox or {};s.mailSequence=(s.mailSequence or 0)+1
  local entry={id=s.mailSequence,kind=kind,item=item,gear=gear,source=source or "Overflow",at=F.Now()}
  s.mailbox[#s.mailbox+1]=entry
  return entry
end
function M.Count()return #(P.state and P.state.mailbox or {})end
function M.Claim(id)
  local s=P.state
  if M.claiming or s.battle or s.trade then return false,"Finish your battle or trade before collecting mail."end
  local index,entry
  for i,e in ipairs(s.mailbox or {})do if e.id==id then index,entry=i,e;break end end
  if not entry then return false,"That delivery has already been collected."end
  local pet=entry.kind=="pet"
  if pet and ((not entry.item.deadAt and P.StableCount()>=P.stableCapacity) or #s.pets>=512 or #s.gear+#(entry.gear or {})>500)then
    return false,"Make room in your stable before collecting this pet and its gear."
  end
  local fits=entry.kind=="crate" and P.CanFitBagCrate and P.CanFitBagCrate(entry.item.crate) or P.BagCount()<P.BagCapacity()
  if not pet and (not fits or (entry.kind=="gear" and #s.gear>=500) or (entry.kind=="crate" and #s.crates>=(P.maxCrateRecords or 100)))then
    return false,"Make room in your bag before collecting this delivery."
  end
  local assets={{kind=entry.kind,item=entry.item}}
  for _,gear in ipairs(entry.gear or {})do assets[#assets+1]={kind="gear",item=gear}end
  local seen={}
  for _,a in ipairs(assets)do
    local item=a.item;local r=s.integrity and s.integrity.records[item.assetID]
    if I.broken or not r or seen[item.assetID] or r.status~="owned" or r.owner~=I.Owner()
      or r.revision~=item.assetRevision or r.fingerprint~=I.Fingerprint(a.kind,item)then
      return false,"Delivery history needs recovery. Your mail has been kept."
    end
    seen[item.assetID]=true
  end
  for _,key in ipairs({"pets","gear","crates"})do for _,item in ipairs(s[key])do
    if seen[item.assetID]then return false,"Delivery already exists in your stable or bag. Mail kept for recovery."end
  end end
  for _,e in ipairs(s.mailbox)do if e~=entry then
    if seen[e.item.assetID]then return false,"Duplicate delivery needs recovery. Mail kept."end
    for _,item in ipairs(e.gear or {})do if seen[item.assetID]then return false,"Duplicate delivery needs recovery. Mail kept."end end
  end end
  M.claiming=true
  table.remove(s.mailbox,index)
  local key=pet and "pets" or entry.kind=="gear" and "gear" or "crates"
  s[key][#s[key]+1]=entry.item
  for _,gear in ipairs(entry.gear or {})do s.gear[#s.gear+1]=gear end
  if pet and not entry.item.deadAt and not P.Active()then s.active=entry.item.id end
  if F.History then F.History.Event("MAIL",entry.item.assetID)end
  M.claiming=nil
  return true,"Collected "..(pet and P.PetName(entry.item) or P.BagDefinition(entry.item).name).."."
end
