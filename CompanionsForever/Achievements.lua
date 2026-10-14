local _,F=...
local P,D=F.Pets,F.PetData
local A={};F.Achievements=A
-- Reserved IDs: achievement-only companions reuse supported Classic models.
-- Never add these to the farming or ordinary crate pools.
D.hiddenSpecies=D.hiddenSpecies or {}
for _,entry in ipairs({{2348,"Moonlit Sentinel",4},{2349,"Emberheart Whelpling",38},{2350,"Crownshadow Prowler",25},{2351,"Runebound Whelp",37},{2352,"Astral Darter",42},{2353,"Umbral Stalker",28},{2354,"Cinderbound Hatchling",38},{2355,"Opaline Sprite",43},{2356,"Frostleaf Owl",30},{2357,"Wildbloom Guardian",45},{2358,"Amethyst Familiar",41},{2359,"Mossfoot Hopper",163},{2360,"Wayfarer Owl",30},{2361,"Eternal Menagerie Whelp",40},{2362,"Wintercrown Cub",9}})do
  local id,name,base=unpack(entry);local data,model={},{}
  for k,v in pairs(D.species[base])do data[k]=v end
  for k,v in pairs(P.models[base])do model[k]=v end
  data.name=name;data.raid=false;D.species[id]=data;D.names[id]=name;P.models[id]=model
  D.hiddenSpecies[id]=true;D.allowedSpecies[id]=true
end
A.frames={
  {name="Simple",color={0.5,0.53,0.58},icon="INV_Misc_QuestionMark",help="Available to every trainer."},
  {name="Bronze Pathfinder",color={0.82,0.52,0.25},icon="INV_Shield_04",achievement="tower10"},
  {name="Grove Keeper",color={0.3,0.83,0.47},icon="Spell_Nature_ProtectionformNature",achievement="trainer5"},
  {name="Tower Champion",color={1,0.8,0.25},icon="INV_Crown_01",achievement="tower100"},
  {name="Amethyst Curator",color={0.68,0.38,0.95},achievement="collect50"},
  {name="Azure Archivist",color={0.18,0.62,1},achievement="collect100"},
  {name="Celestial Menagerie",color={0.45,0.85,1},achievement="collect200"},
  {name="Iron Vanguard",color={0.6,0.67,0.72},achievement="kills100"},
  {name="Crimson Hunter",color={0.9,0.2,0.22},achievement="kills1000"},
  {name="Obsidian Slayer",color={0.5,0.35,0.65},achievement="kills10000"},
  {name="Inferno Veteran",color={1,0.38,0.12},achievement="kills100000"},
  {name="Rose Companion",color={0.98,0.48,0.68},achievement="native5"},
  {name="Jade Keeper",color={0.14,0.82,0.64},achievement="native15"},
  {name="Opal Familiar",color={0.78,0.87,1},achievement="native30"},
  {name="Copper Wanderer",color={0.75,0.47,0.3},achievement="zones5"},
  {name="Sapphire Explorer",color={0.25,0.45,0.96},achievement="zones15"},
  {name="Aurora Voyager",color={0.35,1,0.75},achievement="zones30"},
  {name="Zephyr Pioneer",color={0.54,0.9,0.96},achievement="forever1"},
  {name="Forever Horizon",color={0.93,0.65,1},achievement="forever3"},
  {name="Royal Mentor",color={0.65,0.32,0.98},achievement="trainer20"},
}
A.list={
  {id="first",name="A Forever Friend",text="Discover your first companion.",metric="collection",goal=1,tokens=25},
  {id="collect10",name="Creature Enthusiast",text="Discover 10 different collection companions.",metric="collection",goal=10,tokens=100},
  {id="collect25",name="A Growing Menagerie",text="Discover 25 different collection companions.",metric="collection",goal=25,crate=2},
  {id="tower10",name="First Ascent",text="Clear tower floor 10.",metric="tower",goal=10,frame=2},
  {id="tower30",name="Above the Clouds",text="Clear tower floor 30.",metric="tower",goal=30,crate=3},
  {id="tower60",name="The Long Climb",text="Clear tower floor 60.",metric="tower",goal=60,tokens=300},
  {id="tower100",name="Master of the Tower",text="Clear tower floor 100.",metric="tower",goal=100,frame=4},
  {id="trainer5",name="Patient Teacher",text="Reach trainer level 5.",metric="training",goal=5,frame=3},
  {id="retire5",name="Passing the Torch",text="Retire 5 companions since achievement tracking began.",metric="retired",goal=5,crate=2},
  {id="common30",name="Quiet Courage",text="Win on tower floor 30 or higher with a Common pet since achievement tracking began.",metric="common",goal=1,pet=2348,rarity=3,secret=true},
  {id="rare4",name="Rare Company",text="Defeat four rare tower enemies since achievement tracking began. First clears only.",metric="rares",goal=4,pet=2349,rarity=4,secret=true},
  {id="collect50",name="Curator",text="Discover 50 different collection companions.",metric="collection",goal=50,frame=5},
  {id="collect100",name="A Hundred Friends",text="Discover 100 different collection companions.",metric="collection",goal=100,frame=6},
  {id="collect200",name="Living Library",text="Discover 200 different collection companions.",metric="collection",goal=200,frame=7},
  {id="collectall",name="Every Last Paw",text="Discover all 311 normal collection companions.",metric="collection",goal=311,crate=6},
  {id="kills100",name="On the Trail",text="Defeat 100 creatures with personal or nearby party kill credit.",metric="kills",goal=100,frame=8},
  {id="kills1000",name="Seasoned Hunter",text="Defeat 1,000 creatures with personal or nearby party kill credit.",metric="kills",goal=1000,frame=9},
  {id="kills10000",name="Azeroth Defender",text="Defeat 10,000 creatures with personal or nearby party kill credit.",metric="kills",goal=10000,frame=10},
  {id="kills100000",name="A Lifetime of Adventure",text="Defeat 100,000 creatures with personal or nearby party kill credit.",metric="kills",goal=100000,frame=11},
  {id="native5",name="Pocket Companions",text="Own 5 companions in your actual WoW pet collection.",metric="native",goal=5,frame=12},
  {id="native15",name="Critter Connoisseur",text="Own 15 companions in your actual WoW pet collection.",metric="native",goal=15,frame=13},
  {id="native30",name="Pet Parade",text="Own 30 companions in your actual WoW pet collection.",metric="native",goal=30,frame=14},
  {id="zones5",name="Beyond Home",text="Visit 5 different outdoor zones.",metric="zones",goal=5,frame=15},
  {id="zones15",name="Wandering Soul",text="Visit 15 different outdoor zones.",metric="zones",goal=15,frame=16},
  {id="zones30",name="World Wanderer",text="Visit 30 different outdoor zones.",metric="zones",goal=30,frame=17},
  {id="forever1",name="A New Horizon",text="Visit a new Forever zone: Zephras Isle, Riverglades, Mount Hyjal or Shen'dralas.",metric="forever",goal=1,frame=18},
  {id="forever3",name="Forever Explorer",text="Visit 3 of the four new Forever zones.",metric="forever",goal=3,frame=19},
  {id="trainer20",name="Master Mentor",text="Reach trainer level 20.",metric="training",goal=20,frame=20},
  {id="trainer40",name="A Lasting Legacy",text="Reach the maximum trainer level of 40.",metric="training",goal=40,tokens=1500},
  {id="retire50",name="Generations of Friends",text="Retire 50 companions since achievement tracking began.",metric="retired",goal=50,crate=5},
}
-- Keep the exact pre-0.6.53 payouts for one-time upgrade compensation.
A.legacyRewards={}
for _,d in ipairs(A.list)do A.legacyRewards[d.id]={tokens=d.tokens,crate=d.crate,pet=d.pet}end
local revised={
 first={tokens=50},collect10={tokens=200},collect25={tokens=200,crate=3},
 tower10={tokens=150},tower30={tokens=400,crate=4},tower60={tokens=1000,crate=5},
 tower100={tokens=2500,pet=2350,rarity=4,secret=true},trainer5={tokens=150},retire5={tokens=150,crate=3},
 common30={tokens=300},rare4={tokens=600},collect50={tokens=400},
 collect100={tokens=800,pet=2351,rarity=4,secret=true},collect200={tokens=1500,pet=2352,rarity=4,secret=true},
 collectall={tokens=4000,crate=false,pet=2361,rarity=5,secret=true,frame=7},
 kills100={tokens=50},kills1000={tokens=250},kills10000={tokens=1200,pet=2353,rarity=4,secret=true},
 kills100000={tokens=5000,pet=2354,rarity=5,secret=true},native5={tokens=200},native15={tokens=800},
 native30={tokens=1800,pet=2355,rarity=4,secret=true},zones5={tokens=100},zones15={tokens=350},
 zones30={tokens=800,pet=2356,rarity=3,secret=true},forever1={tokens=150},
 forever3={tokens=700,pet=2357,rarity=3,secret=true},trainer20={tokens=700},
 trainer40={tokens=2500,pet=2358,rarity=4,secret=true,frame=20},retire50={tokens=1200,crate=6},
}
for _,d in ipairs(A.list)do for k,v in pairs(revised[d.id] or {})do d[k]=v or nil end end
for _,d in ipairs({
 {id="collect5",name="A Circle of Friends",text="Discover 5 different collection companions.",metric="collection",goal=5,tokens=75},
 {id="collect75",name="Keeper of Stories",text="Discover 75 different collection companions.",metric="collection",goal=75,tokens=500,crate=4},
 {id="collect150",name="A Living Atlas",text="Discover 150 different collection companions.",metric="collection",goal=150,tokens=900,crate=5},
 {id="kills500",name="Boots on the Trail",text="Defeat 500 creatures with personal or nearby party kill credit.",metric="kills",goal=500,tokens=150,crate=2},
 {id="kills5000",name="Defender of the Wilds",text="Defeat 5,000 creatures with personal or nearby party kill credit.",metric="kills",goal=5000,tokens=400,crate=4},
 {id="kills25000",name="No Road Untaken",text="Defeat 25,000 creatures with personal or nearby party kill credit.",metric="kills",goal=25000,tokens=1500,crate=5},
 {id="kills50000",name="Azeroth's Watchkeeper",text="Defeat 50,000 creatures with personal or nearby party kill credit.",metric="kills",goal=50000,tokens=2500,crate=6},
 {id="zones8",name="A Friend off the Path",text="Visit 8 different outdoor zones.",metric="zones",goal=8,tokens=100,pet=2359,rarity=2,secret=true},
 {id="zones20",name="Across the Horizon",text="Visit 20 different outdoor zones.",metric="zones",goal=20,tokens=600,crate=4},
 {id="forever4",name="Every New Horizon",text="Visit all four tracked Forever zones.",metric="forever",goal=4,tokens=1200,crate=6},
 {id="trainer10",name="Lessons Worth Keeping",text="Reach trainer level 10.",metric="training",goal=10,tokens=300,crate=3},
 {id="trainer30",name="A Teacher of Legends",text="Reach trainer level 30.",metric="training",goal=30,tokens=1000,crate=5},
 {id="retire10",name="A Parting Gift",text="Retire 10 companions since achievement tracking began.",metric="retired",goal=10,tokens=200,pet=2360,rarity=3,secret=true},
 {id="common100",name="Ordinary Courage, Extraordinary Heart",text="Clear tower floor 100 with a Common pet.",metric="commonTower",goal=100,tokens=2000,pet=2362,rarity=4,secret=true,frame=4},
 {id="rares20",name="Among the Unusual",text="Defeat 20 rare tower enemies. First clears only; continue across companions.",metric="rares",goal=20,tokens=1800,crate=6},
})do A.list[#A.list+1]=d end
local illustrations={[4]="FrameTowerChampion",[6]="FrameAzureArchivist",[7]="FrameCelestialMenagerie",[10]="FrameObsidianSlayer",[11]="FrameInfernoVeteran",[13]="FrameJadeKeeper",[14]="FrameOpalFamiliar",[17]="FrameAuroraVoyager",[19]="FrameForeverHorizon",[20]="FrameRoyalMentor"}
for id,asset in pairs(illustrations)do A.frames[id].texture="Interface\\AddOns\\CompanionsForever\\Art\\"..asset..".tga"end
D.secretAchievements={}
for _,d in ipairs(A.list)do if d.pet then D.secretAchievements[d.pet]=d.name end end
local icons={commonTower="Ability_Druid_ChallangingRoar",collection="Ability_Hunter_BeastCall",tower="INV_Misc_Key_14",training="INV_Misc_Book_09",retired="Spell_Nature_Rejuvenation",common="Ability_Druid_ChallangingRoar",rares="Ability_Hunter_BeastTaming",kills="Ability_DualWield",native="INV_Box_PetCarrier_01",zones="INV_Misc_Map_01",forever="Spell_Nature_FarSight"}
A.byID={};for i,d in ipairs(A.list)do A.byID[d.id]=d;d.icon=icons[d.metric];d.order=i end
for i,d in ipairs(A.frames)do d.style=(i-1)%5+1;d.icon=nil end
local function whole(n,lo,hi)return type(n)=="number" and n==math.floor(n) and n>=lo and n<=hi end
function A.Initialize()
  local s=P.state;local old=type(s.achievements)=="table" and s.achievements or {}
  local a={claimed={},paid={},rewardSchema=2,tower=0,retired=0,common=0,commonTower=0,rares=0,frame=1,kills=0,pvpKills=0,native=0,visited={}}
  for id,v in pairs(type(old.claimed)=="table" and old.claimed or {})do if A.byID[id] and v==true then a.claimed[id]=true end end
  for _,key in ipairs({"tower","retired","common","commonTower","rares","kills","pvpKills","native"})do if whole(old[key],0,1000000)then a[key]=old[key]end end
  for id in pairs(a.claimed)do
    local record=old.rewardSchema==2 and type(old.paid)=="table" and old.paid[id] or A.legacyRewards[id]
    local paid={};a.paid[id]=paid
    if type(record)=="table"then
      if whole(record.tokens,0,P.maxTokens)then paid.tokens=record.tokens end
      if whole(record.crate,1,6)then paid.crate=record.crate end
      if whole(record.pet,2348,100000) and record.pet==A.byID[id].pet then paid.pet=record.pet end
    end
  end
  for _,pet in ipairs(s.pets)do
    a.tower=math.max(a.tower,pet.best or 0)
    if pet.rarity==1 then a.commonTower=math.max(a.commonTower,pet.best or 0)end
  end
  a.tower=math.min(100,a.tower);a.common=math.min(1,a.common);a.commonTower=math.min(100,math.max(a.commonTower,a.common==1 and 30 or 0))
  local count=0
  for id,v in pairs(type(old.visited)=="table" and old.visited or {})do
    if count<128 and whole(id,1,100000) and v==true then a.visited[id]=true;count=count+1 end
  end
  a.seenAchievements={};a.seenFrames={}
  for id in pairs(A.byID)do if type(old.seenAchievements)=="table" and old.seenAchievements[id]==true or not old.seenAchievements and a.claimed[id]then a.seenAchievements[id]=true end end
  for i in ipairs(A.frames)do if type(old.seenFrames)=="table" and old.seenFrames[i]==true or not old.seenFrames and (i==1 or a.claimed[A.frames[i].achievement])then a.seenFrames[i]=true end end
  s.achievements=a;A.claiming=nil
  if whole(old.frame,1,#A.frames) and A.FrameUnlocked(old.frame)then a.frame=old.frame end
  if A.ScanNative then A.ScanNative();A.VisitZone()end
end
function A.FrameUnlocked(index)
  local d=A.frames[index];local a=P.state and P.state.achievements
  if not d or not a then return index==1 end
  if index==1 or a.claimed[d.achievement]==true then return true end
  for _,reward in ipairs(A.list)do if reward.frame==index and a.claimed[reward.id]then return true end end
  return false
end
function A.FrameVisible(index)return A.frames[index] and (not A.frames[index].texture or A.FrameUnlocked(index))end
function A.PetKnown(d)return d.pet and P.state.collection[d.pet]~=nil end
function A.Frame()local a=P.state and P.state.achievements;return a and A.FrameUnlocked(a.frame) and a.frame or 1 end
function A.SelectFrame(index)
  if not A.FrameUnlocked(index)then return false,"Complete and claim the frame's achievement first."end
  P.state.achievements.frame=index;return true
end
function A.Progress(d)
  local s=P.state;local a=s.achievements
  if d.metric=="collection"then local count=0
    for id in pairs(s.collection)do if D.allowedSpecies[id] and not D.hiddenSpecies[id]then count=count+1 end end
    return count
  elseif d.metric=="training"then return s.training.level
  elseif d.metric=="zones" or d.metric=="forever"then
    local count=0;for id in pairs(a.visited)do if d.metric=="zones" or A.foreverZones[id]then count=count+1 end end;return count
  end
  return a and a[d.metric] or 0
end
function A.TowerWin(pet,battle,first)
  local a=P.state.achievements;if not a then return end
  a.tower=math.max(a.tower,battle.floor)
  if pet.rarity==1 then a.commonTower=math.max(a.commonTower or 0,battle.floor);if battle.floor>=30 then a.common=1 end end
  if first and battle.enemies[1].rare then
    a.rares=math.min(1000000,a.rares+1)
  end
end
function A.Retired()local a=P.state.achievements;if a then a.retired=math.min(1000000,a.retired+1)end end
-- Called only after the normal readable creature-kill receipt is deduplicated.
function A.CreatureKill()local a=P.state.achievements;if a then a.kills=math.min(1000000,a.kills+1)end end
local function readable(v)
  return (not issecretvalue or not issecretvalue(v)) and (not canaccessvalue or canaccessvalue(v))
end
-- Map IDs already used by the bundled Forever travel data. Names are display-only.
A.foreverZones={[2482]="Mount Hyjal",[2521]="Zephras Isle",[2548]="Riverglades",[2652]="Shen'dralas"}
function A.VisitZone()
  local a=P.state and P.state.achievements;if not a or not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetMapInfo then return end
  if IsInInstance then local ok,inside=pcall(IsInInstance);if not ok or not readable(inside) or inside then return end end
  local ok,id=pcall(C_Map.GetBestMapForUnit,"player")
  if not ok or not readable(id) or not whole(id,1,100000)then return end
  for _=1,6 do
    local success,info=pcall(C_Map.GetMapInfo,id)
    if not success or not readable(info) or type(info)~="table" or not readable(info.mapType)then return end
    if info.mapType==3 then
      local count=0;for _ in pairs(a.visited)do count=count+1 end
      if count<128 then a.visited[id]=true end;return
    end
    if info.mapType~=4 or not readable(info.parentMapID) or not whole(info.parentMapID,1,100000)then return end
    id=info.parentMapID
  end
end
function A.ScanNative()
  local a=P.state and P.state.achievements;if not a then return end
  A.nativeAvailable=false
  -- Classic's native companion book; no addon pets or mounts are counted.
  if GetNumCompanions then
    local ok,count=pcall(GetNumCompanions,"CRITTER")
    if ok and readable(count) and whole(count,0,5000)then a.native=math.max(a.native,count);A.nativeAvailable=true end
  end
  -- Newer Classic clients use the collection journal even when the legacy
  -- CRITTER book returns zero. Count owned pets, never the whole catalogue.
  if C_PetJournal and C_PetJournal.GetNumPets then
    local ok,_,owned=pcall(C_PetJournal.GetNumPets)
    if ok and readable(owned) and whole(owned,0,5000)then a.native=math.max(a.native,owned);A.nativeAvailable=true end
  end
  if C_PetJournal and C_PetJournal.GetOwnedPetIDs then
    local ok,ids=pcall(C_PetJournal.GetOwnedPetIDs)
    if ok and readable(ids) and type(ids)=="table" and #ids<=5000 then
      a.native=math.max(a.native,#ids);A.nativeAvailable=true
    end
  end
end
function A.ProgressHelp(d)
  if d.metric=="native"then return A.nativeAvailable and "Counts companions learned in WoW, separate from this addon's stable. Highest observed total is kept." or "WoW's companion count is currently unavailable. Saved progress is kept; no count is guessed."end
  if d.metric=="kills"then return "Counts readable creature kills since 0.6.51, including nearby party credit. PvP and hidden identities are excluded. XP caps do not stop this counter."end
  if d.metric=="zones" or d.metric=="forever"then return "Counts zone visits since 0.6.51. Enter a zone to record it; opening its map does not count. Dungeons and continents do not count as zones."end
  return "Progress stays saved. Each reward can be claimed once per shared realm adventure."
end
function A.Remaining(d)
  local a=P.state.achievements;local paid=a.paid[d.id] or {}
  return {tokens=math.max(0,(d.tokens or 0)-(paid.tokens or 0)),crate=d.crate~=paid.crate and d.crate or nil,pet=d.pet~=paid.pet and d.pet or nil}
end
function A.Settled(d)
  if not P.state.achievements.claimed[d.id]then return false end
  local r=A.Remaining(d);return r.tokens==0 and not r.crate and not r.pet
end
function A.RewardText(d,reveal,remaining)
  local r=remaining and A.Remaining(d) or d;local lines={}
  if r.pet then lines[#lines+1]=reveal and (P.rarities[d.rarity].." "..P.species[d.pet]) or "Secret companion"end
  if d.frame then lines[#lines+1]=A.FrameVisible(d.frame) and (A.frames[d.frame].name.." portrait frame") or "Secret portrait frame"end
  if r.crate then lines[#lines+1]=P.BagDefinition({crate=r.crate}).name end
  if r.tokens and r.tokens>0 then lines[#lines+1]=P.TokenText(r.tokens)end
  return table.concat(lines,"\n")
end
local tracker=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","COMPANION_UPDATE","SPELLS_CHANGED","PET_JOURNAL_LIST_UPDATE","NEW_PET_ADDED","COMPANION_LEARNED","COMPANION_UNLEARNED"})do pcall(tracker.RegisterEvent,tracker,event)end
tracker:SetScript("OnEvent",function(_,event)
  if not P.state or not P.state.achievements then return end
  if event=="COMPANION_UPDATE" or event=="SPELLS_CHANGED" or event=="PET_JOURNAL_LIST_UPDATE" or event=="NEW_PET_ADDED" or event=="COMPANION_LEARNED" or event=="COMPANION_UNLEARNED"then A.nativeDirty=true
  else A.VisitZone();A.ScanNative()end
end)
local elapsed=0
tracker:SetScript("OnUpdate",function(_,dt)
  if not A.nativeDirty then return end;elapsed=elapsed+dt
  if elapsed>=2 then elapsed=0;A.nativeDirty=nil;A.ScanNative()end
end)
function A.Claim(id)
  local d=A.byID[id];local a=P.state.achievements
  if not d or not a then return false,"Unknown achievement."end
  if A.claiming or A.Settled(d)then return false,"This reward has already been claimed or is being delivered."end
  if not a.claimed[id] and A.Progress(d)<d.goal then return false,"Finish this challenge first."end
  if P.state.battle then return false,"Finish your tower battle before claiming rewards."end
  local r=A.Remaining(d)
  if P.state.tokens>P.maxTokens-r.tokens then return false,"Spend some tokens first. Your reward will wait here."end
  local mailPet=r.pet and (P.StableCount()>=P.stableCapacity or #P.state.pets+(F.Trades and F.Trades.Reserved("pet") or 0)>=512)
  if mailPet and not (F.Mailbox and F.Mailbox.CanReceive())then return false,"Stable full and Mail unavailable. This reward will wait here."end
  if r.crate and (P.BagCount()>=P.BagCapacity() or #P.state.crates>=(P.maxCrateRecords or 100))then return false,"Make room in your bag. This achievement reward will wait here."end
  -- Each bundle contains at most one inventory reward, plus tokens and cosmetics.
  -- Grant that reward quietly first; a full stable/bag leaves the entire claim waiting.
  A.claiming=true
  local ok,item=true,nil
  if r.pet then ok,item=P.GrantPet(r.pet,d.rarity,"Achievement: "..d.name,true)
  elseif r.crate then ok,item=P.GrantCrate(r.crate,"Achievement: "..d.name,true)end
  if not ok then A.claiming=nil;return false,item end
  if r.tokens>0 then P.ChangeTokens(r.tokens,"ACHIEVEMENT",id)end
  a.paid[id]={tokens=d.tokens,crate=d.crate,pet=d.pet};a.claimed[id]=true
  if F.History then local receipt=F.History.Event("ACHIEVEMENT",id)
    if item and receipt then F.History.Birth(item,"R",receipt.ref,0,0,receipt)end
  end
  A.claiming=nil
  P.notice="Achievement claimed: "..d.name.." - "..A.RewardText(d,true):gsub("\n"," + ")
  if mailPet then P.notice=P.notice.." | Stable full: pet sent to Mail."end
  if r.pet then P.Reward("pet","Secret companion unlocked!",P.rarities[d.rarity].." "..P.species[d.pet],"Achievement reward",d.pet,d.rarity)
  elseif r.crate then local reward=P.BagDefinition({crate=r.crate});P.Reward("crate_found","Achievement reward!",reward.name,reward.icon,nil,P.CrateRarity(r.crate))end
  F.Print(P.notice)
  return true,item
end

function A.ClaimAll()
  if A.claimingAll or A.claiming then return false,"Rewards are already being delivered."end
  if P.state.battle then return false,"Finish your tower battle before claiming rewards."end
  A.claimingAll=true
  local claimed,mailed,attempted,warning=0,0,{},nil
  local ok,err=pcall(function()
    -- A pet reward can complete another collection milestone earlier in the list.
    -- Revisit the list, but attempt each reward only once in this batch.
    local changed=true
    while changed do
      changed=false
      for _,d in ipairs(A.list)do
        if not attempted[d.id] and not A.Settled(d) and (P.state.achievements.claimed[d.id] or A.Progress(d)>=d.goal)then
          attempted[d.id]=true
          local before=F.Mailbox and F.Mailbox.Count() or 0
          local success,message=A.Claim(d.id)
          if success then
            claimed=claimed+1;changed=true
            mailed=mailed+math.max(0,(F.Mailbox and F.Mailbox.Count() or 0)-before)
            P.state.achievements.seenAchievements[d.id]=true
          else warning=warning or message end
        end
      end
    end
  end)
  A.claimingAll=nil
  if not ok then error(err)end
  local waiting=0
  for _,d in ipairs(A.list)do
    if not A.Settled(d) and (P.state.achievements.claimed[d.id] or A.Progress(d)>=d.goal)then waiting=waiting+1 end
  end
  local message=claimed>0 and ("Claimed "..claimed.." rewards.") or "No rewards claimed."
  if mailed>0 then message=message.." "..mailed.." pets sent to Mail."end
  if waiting>0 then message=message.." "..waiting.." still waiting."end
  P.notice=message..(warning and (" "..warning) or "");F.Print(P.notice)
  return claimed>0,message,claimed,waiting,warning
end

function A.IsNew(id)
  local d=A.byID[id];local a=P.state.achievements
  return d and not (a.seenAchievements or {})[id] and (a.claimed[id] or A.Progress(d)>=d.goal) or false
end
function A.FrameNew(id)return id>1 and A.FrameUnlocked(id) and not (P.state.achievements.seenFrames or {})[id]end
