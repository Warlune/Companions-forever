local _,F=...
local P,D,A=F.Pets,F.PetData,F.Achievements
A.adventureCatalog=true
-- Achievement-only Classic models: no world drop or ordinary crate pool entry.
for _,entry in ipairs({{2364,"Bloodbanner Wolf",3},{2365,"Cloudskip Hare",103},{2366,"Horizonwing Owl",30},{2367,"Vaultkeeper Whelp",40},{2368,"Cryptlight Hound",27},{2369,"Aetherbound Sprite",42}})do
  local id,name,base=unpack(entry);local species,model={},{}
  for k,v in pairs(D.species[base])do species[k]=v end
  for k,v in pairs(P.models[base])do model[k]=v end
  species.name=name;species.raid=false;D.species[id]=species;D.names[id]=name;P.models[id]=model
  D.hiddenSpecies[id]=true;D.allowedSpecies[id]=true
end
local entries={
 {id="pvp1",name="First Blood",text="Earn 1 tracked enemy-player kill.",metric="pvpKills",goal=1,tokens=25},
 {id="pvp10",name="Stand Your Ground",text="Earn 10 tracked enemy-player kills.",metric="pvpKills",goal=10,tokens=75},
 {id="pvp50",name="Skirmisher",text="Earn 50 tracked enemy-player kills.",metric="pvpKills",goal=50,tokens=200,crate=3},
 {id="pvp100",name="Battlefield Regular",text="Earn 100 tracked enemy-player kills.",metric="pvpKills",goal=100,tokens=400,crate=4},
 {id="pvp250",name="Against All Comers",text="Earn 250 tracked enemy-player kills.",metric="pvpKills",goal=250,tokens=1000,crate=5},
 {id="pvp1000",name="A Thousand Rivalries",text="Earn 1,000 tracked enemy-player kills.",metric="pvpKills",goal=1000,tokens=2500,pet=2364,rarity=4,secret=true},
 {id="jumps25",name="Spring in Your Step",text="Jump 25 times.",metric="jumps",goal=25,tokens=25},
 {id="jumps250",name="Can't Sit Still",text="Jump 250 times.",metric="jumps",goal=250,tokens=75},
 {id="jumps1000",name="Hop to It",text="Jump 1,000 times.",metric="jumps",goal=1000,tokens=150,crate=2},
 {id="jumps5000",name="The Floor Is Lava",text="Jump 5,000 times.",metric="jumps",goal=5000,tokens=400,crate=4},
 {id="jumps20000",name="Gravity Is a Suggestion",text="Jump 20,000 times.",metric="jumps",goal=20000,tokens=1500,pet=2365,rarity=4,secret=true},
 {id="east8",name="Eastern Footsteps",text="Visit 8 tracked Eastern Kingdoms zones.",metric="east",goal=8,tokens=75},
 {id="west8",name="Western Footsteps",text="Visit 8 tracked Kalimdor zones.",metric="west",goal=8,tokens=75},
 {id="both8",name="Across the Great Sea",text="Visit at least 8 tracked zones on each main continent.",metric="both",goal=8,tokens=250,crate=3},
 {id="east20",name="Stories of the Eastern Kingdoms",text="Visit 20 tracked Eastern Kingdoms zones.",metric="east",goal=20,tokens=400,crate=4},
 {id="west20",name="Stories of Kalimdor",text="Visit 20 tracked Kalimdor zones.",metric="west",goal=20,tokens=400,crate=4},
 {id="desert3",name="Sand Between Your Toes",text="Visit Thousand Needles, Tanaris and Silithus.",metric="desert",goal=3,tokens=125},
 {id="cold3",name="A Breath of Frost",text="Visit Dun Morogh, Alterac Mountains and Winterspring.",metric="cold",goal=3,tokens=125},
 {id="horizons30",name="Old Roads, New Horizons",text="Visit 30 zones, including all four tracked Forever zones.",metric="horizons",goal=30,tokens=700,crate=5},
 {id="zones45",name="No Horizon Too Far",text="Visit 45 different outdoor zones.",metric="zones",goal=45,tokens=2000,pet=2366,rarity=4,secret=true},
 {id="dungeon1",name="Down the Rabbit Hole",text="Complete 1 dungeon by defeating its final boss.",metric="dungeons",goal=1,tokens=50},
 {id="dungeon5",name="Into the Depths",text="Complete 5 dungeon runs.",metric="dungeons",goal=5,tokens=125},
 {id="dungeon25",name="Dungeon Regular",text="Complete 25 dungeon runs.",metric="dungeons",goal=25,tokens=500,crate=4},
 {id="dungeon100",name="Keeper of the Vaults",text="Complete 100 dungeon runs.",metric="dungeons",goal=100,tokens=2500,pet=2367,rarity=4,secret=true},
 {id="unique3",name="Three Doors Opened",text="Complete 3 different dungeons.",metric="uniqueDungeons",goal=3,tokens=200,crate=3},
 {id="unique10",name="Keys to Azeroth",text="Complete 10 different dungeons.",metric="uniqueDungeons",goal=10,tokens=1800,pet=2368,rarity=4,secret=true},
 {id="bosses25",name="Boss Business",text="Defeat 25 dungeon bosses.",metric="dungeonBosses",goal=25,tokens=300,crate=3},
 {id="newDungeon1",name="Something Beneath the Surface",text="Complete your first new Forever dungeon.",metric="foreverDungeons",goal=1,tokens=100},
 {id="newUnique4",name="Secrets of Forever",text="Complete 4 different new Forever dungeons.",metric="uniqueForever",goal=4,tokens=2000,pet=2369,rarity=4,secret=true},
 {id="newDungeon25",name="Forever Delver",text="Complete 25 runs of the new Forever dungeons.",metric="foreverDungeons",goal=25,tokens=900,crate=5},
}
local icons={pvpKills="Ability_DualWield",jumps="Ability_Rogue_Sprint",dungeons="INV_Misc_Key_14",dungeonBosses="Ability_Warrior_Challange",uniqueDungeons="INV_Misc_Key_04",foreverDungeons="Spell_Arcane_PortalIronForge",uniqueForever="Spell_Arcane_PortalDarnassus",cold="Spell_Frost_FrostBolt02",desert="Spell_Nature_Earthquake"}
for _,d in ipairs(entries)do
  d.icon=icons[d.metric] or "INV_Misc_Map_01";d.order=#A.list+1;A.list[d.order]=d;A.byID[d.id]=d
  if d.pet then D.secretAchievements[d.pet]=d.name end
end
local function readable(v)return (not issecretvalue or not issecretvalue(v)) and (not canaccessvalue or canaccessvalue(v))end
local function whole(n,lo,hi)return readable(n) and type(n)=="number" and n==math.floor(n) and n>=lo and n<=hi end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local function increment(a,key)a[key]=math.min(1000000,(a[key] or 0)+1)end
local initialize=A.Initialize
function A.Initialize()
  local old=type(P.state.achievements)=="table" and P.state.achievements or {}
  initialize();local a=P.state.achievements
  for _,key in ipairs({"jumps","dungeons","dungeonBosses","foreverDungeons"})do a[key]=whole(old[key],0,1000000) and old[key] or 0 end
  for _,key in ipairs({"dungeonVisits","foreverDungeonVisits","dungeonReceipts","dungeonClears"})do
    a[key]={};local n=0
    for id,v in pairs(type(old[key])=="table" and old[key] or {})do
      local valid=key=="dungeonReceipts" and type(id)=="string" and #id<=30 and id:match("^%d+:%d+$") or key~="dungeonReceipts" and whole(id,1,100000)
      local visits=key=="dungeonVisits" or key=="foreverDungeonVisits"
      if n<128 and valid and (visits and v==true or not visits and whole(v,0,F.Now()))then a[key][id]=v;n=n+1 end
    end
  end
end
-- Same map IDs as the bundled travel data; visits still require physically entering a zone.
local zones={
 east={1416,1417,1418,1419,1420,1421,1422,1423,1424,1425,1426,1427,1428,1429,1430,1431,1432,1433,1434,1435,1436,1437,1453,1455,1458,2548},
 west={1411,1412,1413,1438,1439,1440,1441,1442,1443,1444,1445,1446,1447,1448,1449,1450,1451,1452,1454,1456,1457,2482,2652},
 desert={1441,1446,1451},cold={1426,1416,1452},
}
local function visited(a,key)local n=0;for _,id in ipairs(zones[key])do if a.visited[id]then n=n+1 end end;return n end
local progress=A.Progress
function A.Progress(d)
  local a=P.state.achievements
  if zones[d.metric]then return visited(a,d.metric)
  elseif d.metric=="both"then return math.min(visited(a,"east"),visited(a,"west"))
  elseif d.metric=="horizons"then
    local n=0;for id in pairs(A.foreverZones)do if a.visited[id]then n=n+1 end end
    return n==4 and count(a.visited) or math.min(29,count(a.visited))
  elseif d.metric=="uniqueDungeons"then return count(a.dungeonVisits)
  elseif d.metric=="uniqueForever"then return count(a.foreverDungeonVisits)end
  return progress(d)
end
local help=A.ProgressHelp
function A.ProgressHelp(d)
  if d.metric=="pvpKills"then return "Uses the addon's confirmed PvP kill counter, including saved kills. Repeated kills of the same opponent are subject to its existing cooldown; duels do not count."end
  if d.metric=="jumps"then return "Counts jump takeoffs while playing, starting with 1.1.15. Swimming, flying, falling off ledges and repeated presses in the same jump do not count."end
  if d.metric=="dungeons" or d.metric=="uniqueDungeons" or d.metric=="foreverDungeons" or d.metric=="uniqueForever" or d.metric=="dungeonBosses"then
    return "Tracking starts with 1.1.15. Requires a successful dungeon boss event. Clears require a recognized final boss or WoW's complete encounter checklist. Raids and entering a dungeon do not count. Duplicate boss events are ignored; clears of the same instance map have a 5-minute cooldown. Forever includes Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands and City of Dalaran; other new dungeons require the client checklist."
  end
  if zones[d.metric] or d.metric=="both" or d.metric=="horizons"then return "Uses your saved outdoor zone visits. Physically enter each zone; opening the map does not count. Old Roads, New Horizons also needs Mount Hyjal, Zephras Isle, Riverglades and Shen'dralas."end
  return help(d)
end
-- No replacement of movement functions. A secure post-hook arms a short-lived
-- observer; only an actual takeoff counts, once until landing.
local jump=CreateFrame("Frame");A.jumpTracker=jump;jump:Hide()
local jumpArmed,jumpCounted,jumpAge,jumpElapsed=false,false,0,0
local grounded=false
local function flag(fn,...)
  if type(fn)~="function"then return nil end
  local ok,v=pcall(fn,...);if not ok or not readable(v)then return nil end;return not not v
end
local function jumpAllowed()
  return flag(IsSwimming)==false and flag(IsFlying)==false and flag(UnitOnTaxi,"player")==false and flag(UnitIsDeadOrGhost,"player")==false
end
function A.JumpRequested()
  if not P.state or not P.state.achievements or jumpArmed or not grounded or not jumpAllowed()then return end
  jumpArmed=true;jumpCounted=false;jumpAge=0;jumpElapsed=0
end
-- A lightweight 5 Hz ground sample avoids mistaking a space press while already
-- falling for a jump. No UI renders, allocations or character stat reads here.
jump:Show()
jump:SetScript("OnUpdate",function(_,dt)
  jumpElapsed=jumpElapsed+dt;if jumpElapsed<0.2 then return end;local step=jumpElapsed;jumpElapsed=0
  local falling=flag(IsFalling)
  if jumpArmed then
    jumpAge=jumpAge+step
    if not jumpAllowed() or jumpAge>30 then jumpArmed=false
    elseif falling==true and not jumpCounted then
      local a=P.state and P.state.achievements
      jumpCounted=true
      if a then increment(a,"jumps");if P.HardMode and P.HardMode.ConfirmedJump then P.HardMode.ConfirmedJump()end end
    elseif falling==false and (jumpCounted or jumpAge>1)then jumpArmed=false end
  end
  grounded=falling==false
end)
if type(hooksecurefunc)=="function" and type(JumpOrAscendStart)=="function"then pcall(hooksecurefunc,"JumpOrAscendStart",A.JumpRequested)
else jump:Hide()end
-- Sources and current Forever fallback coverage are recorded in data/adventure-achievements-sources.md.
local finals={
 ["ragefire chasm"]={"Bazzalan"},["the deadmines"]={"Edwin VanCleef"},["deadmines"]={"Edwin VanCleef"},
 ["wailing caverns"]={"Mutanus the Devourer"},["shadowfang keep"]={"Archmage Arugal"},["blackfathom deeps"]={"Aku'mai"},
 ["the stockade"]={"Bazil Thredd"},["gnomeregan"]={"Mekgineer Thermaplugg"},["razorfen kraul"]={"Charlga Razorflank"},
 ["scarlet monastery"]={"High Inquisitor Whitemane"},["razorfen downs"]={"Amnennar the Coldbringer"},["uldaman"]={"Archaedas"},
 ["zul'farrak"]={"Chief Ukorz Sandscalp"},["maraudon"]={"Princess Theradras"},["the temple of atal'hakkar"]={"Shade of Eranikus"},
 ["sunken temple"]={"Shade of Eranikus"},["blackrock depths"]={"Emperor Dagran Thaurissan"},["blackrock spire"]={"General Drakkisath","Overlord Wyrmthalak"},
 ["dire maul"]={"Alzzin the Wildshaper","Prince Tortheldrin","King Gordok"},["scholomance"]={"Darkmaster Gandling"},["stratholme"]={"Baron Rivendare","Balnazzar"},
 ["hall of thanes"]={"Durgen Dirgehammer"},["the hall of thanes"]={"Durgen Dirgehammer"},["ruins of lordaeron"]={"Rath'Mael"},
 ["the ruins of lordaeron"]={"Rath'Mael"},["excavation site: wetlands"]={"Relic Guardian"},["city of dalaran"]={"Shade of the Archmage"},
}
local forever={ ["hall of thanes"]=true,["the hall of thanes"]=true,["ruins of lordaeron"]=true,["the ruins of lordaeron"]=true,["excavation site: wetlands"]=true,["city of dalaran"]=true,["the drowned city"]=true,["krol'dok stronghold"]=true,["alcaz prison"]=true,["blackmaw hold"]=true,["shaper's terrace"]=true }
local function instanceName(map)
  if not GetInstanceInfo then return end
  local ok,name,kind,_,_,_,_,_,id=pcall(GetInstanceInfo)
  if not ok or not readable(name) or type(name)~="string" or #name>120 or not readable(kind) or kind~="party" or not readable(id) or id~=map then return end
  return name:lower()
end
local function checklistComplete()
  if not GetInstanceLockTimeRemaining then return false end
  local ok,_,_,total,done=pcall(GetInstanceLockTimeRemaining)
  return ok and whole(total,1,64) and whole(done,1,64) and done==total
end
local function clearDungeon(map,boss,stamp)
  local a=P.state and P.state.achievements;local name=instanceName(map)
  if not a or not name or (a.dungeonClears[map] and stamp-a.dungeonClears[map]<300)then return end
  local final=false
  if boss then for _,known in ipairs(finals[name] or {})do if boss==known then final=true;break end end end
  if not final and not checklistComplete()then return end
  a.dungeonClears[map]=stamp;increment(a,"dungeons")
  if count(a.dungeonVisits)<128 then a.dungeonVisits[map]=true end
  if forever[name]then increment(a,"foreverDungeons");if count(a.foreverDungeonVisits)<128 then a.foreverDungeonVisits[map]=true end end
end
function A.DungeonBoss(id,name,kind,map)
  local a=P.state and P.state.achievements
  if not a or kind~="party" or not whole(id,1,100000) or not whole(map,1,100000) or not instanceName(map)then return end
  local stamp=F.Now();local key=map..":"..id
  if a.dungeonReceipts[key] and stamp-a.dungeonReceipts[key]<120 then return end
  for k,v in pairs(a.dungeonReceipts)do if stamp-v>=120 then a.dungeonReceipts[k]=nil end end
  for k,v in pairs(a.dungeonClears)do if stamp-v>=300 then a.dungeonClears[k]=nil end end
  if count(a.dungeonReceipts)>=128 or count(a.dungeonClears)>=128 then return end
  a.dungeonReceipts[key]=stamp;increment(a,"dungeonBosses")
  if not readable(name) or type(name)~="string" or #name>120 then name=nil end
  clearDungeon(map,name,stamp)
  -- Some clients update the encounter checklist just after the boss event.
  if C_Timer and C_Timer.After then C_Timer.After(0.5,function()
    if P.state and P.state.achievements==a then clearDungeon(map,name,stamp)end
  end)end
end
