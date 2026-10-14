local _,F=...
local P={};F.Pets=P
P.maxTokens=1000000000
function P.ChangeTokens(delta,code,reference)
  local s=P.state;if not s or type(delta)~="number" or delta~=math.floor(delta)then return end
  if F.History then F.History.Check(s)end
  local before=s.tokens;s.tokens=math.max(0,math.min(P.maxTokens,before+delta))
  local receipt=F.History and s.tokens~=before and F.History.Append(s,s.tokens-before,code,reference)
  return receipt,s.tokens-before
end
P.tokenIcon="Interface\\Icons\\INV_Misc_Coin_01"
function P.TokenText(amount)return "|T"..P.tokenIcon..":14:14|t "..string.format("%.0f",amount).." tokens" end
P.species=F.PetData.names
P.rarities={"Common","Uncommon","Rare","Epic","Legendary"}
P.colors={{0.9,0.9,0.9},{0.2,1,0.2},{0.3,0.6,1},{0.8,0.4,1},{1,0.6,0.15}}
-- Quality zero is equipment-only; pet quality remains Common through Legendary.
P.rarities[0]="Poor";P.colors[0]={0.62,0.62,0.62}
P.items={food={name="Food",cost=2,icon="INV_Misc_Food_14"},medicine={name="Healing herbs",cost=4,icon="INV_Misc_Herb_03"}}
P.random=math.random
local function clamp(n)return math.max(0,math.min(100,n))end
local function whole(n,min,max)return type(n)=="number" and n==math.floor(n) and n>=min and n<=max end
local function readable(value)
  if issecretvalue and issecretvalue(value)then return false end
  return not canaccessvalue or canaccessvalue(value)
end
P.enemyLevels={}
-- Hunter Snake Trap creatures are summons, never world-farming sources.
P.excludedKillNPCs={[19833]=true,[19921]=true}
function P.ExcludedKill(guid)
  if not readable(guid) or type(guid)~="string"then return false end
  local npc=tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
  local entry=P.enemyLevels[guid]
  return P.excludedKillNPCs[npc] or (entry and entry.excluded and F.Now()-entry.seen<=60) or false
end
function P.ObserveEnemy(unit)
  if not UnitGUID or not UnitLevel or not readable(unit) or type(unit)~="string" then return end
  local guid,level=UnitGUID(unit),UnitLevel(unit)
  if not readable(guid) or type(guid)~="string" then return end
  local now=F.Now();local count=0
  for key,entry in pairs(P.enemyLevels)do if now-entry.seen>60 then P.enemyLevels[key]=nil else count=count+1 end end
  local controlled=UnitPlayerControlled and UnitPlayerControlled(unit)
  if guid:match("^Creature%-") and ((readable(controlled) and (controlled==true or controlled==1)) or P.ExcludedKill(guid))then
    if count<128 or P.enemyLevels[guid]then P.enemyLevels[guid]={seen=now,excluded=true}end
    return
  end
  if not readable(level)then
    -- Keep only an ordinary flag against a readable identity, never the level.
    if not P.enemyLevels[guid] and count<128 then P.enemyLevels[guid]={seen=now,restricted=true}end
    return
  end
  local classification=UnitClassification and UnitClassification(unit)
  local prior=P.enemyLevels[guid]
  local boss=(readable(classification) and classification=="worldboss") or unit:match("^boss%d+$")~=nil
  if prior and F.Now()-prior.seen<=60 and prior.boss then boss=true end
  -- A skull has no numeric level. Recognized world bosses/boss-unit frames use
  -- the level-63 bracket in this addon's loot rules; arbitrary skull mobs do not.
  if level==-1 and boss then level=63 end
  -- A dying unit may briefly return zero/nil before PARTY_KILL arrives.
  -- Keep its last readable positive observation until the normal expiry.
  if not whole(level,1,1000) then
    if level==-1 then P.enemyLevels[guid]=nil end
    return
  end
  if count<128 or P.enemyLevels[guid] then
    local prior=P.enemyLevels[guid]
    -- Keep a known elite classification if the corpse later reports normal/nil.
    -- Never retain or compare a restricted classification value.
    local elite=(prior and prior.elite) or (readable(classification) and
      (classification=="elite" or classification=="rareelite")) or false
    P.enemyLevels[guid]={level=level,seen=now,elite=elite,boss=boss}
  end
end
function P.EligibleKill(guid)
  if not readable(guid) or type(guid)~="string"then return false end
  for _,unit in ipairs({"target","focus","mouseover","pettarget","boss1","boss2","boss3","boss4","boss5"})do P.ObserveEnemy(unit)end
  -- A party target can die before our one-second observation tick runs.
  local raid=IsInRaid and IsInRaid()
  for i=1,raid and 40 or 4 do P.ObserveEnemy((raid and "raid" or "party")..i.."target")end
  local entry=P.enemyLevels[guid]
  if P.ExcludedKill(guid)then return false,"summon"end
  if not entry or F.Now()-entry.seen>60 then return false end
  if entry.restricted then return false,"restricted" end
  local level
  if UnitEffectiveLevel then level=UnitEffectiveLevel("player") elseif UnitLevel then level=UnitLevel("player")end
  if not readable(level) then return false,"restricted" end
  if not whole(level,1,1000) and UnitLevel then level=UnitLevel("player")end
  if not readable(level)then return false,"restricted" end
  if not whole(level,1,1000) then return false end
  local diff=entry.level-level
  -- Classic difficulty bands: red +5+, orange +3/+4, yellow -2 through +2.
  -- Use the observed level even after the target disappears on death.
  if diff>=5 then return true,"red" end
  if diff>=3 then return true,"orange" end
  if diff>=-2 then return true,"yellow" end
  local grayAPI=UnitQuestTrivialLevelRange or GetQuestGreenRange
  if not grayAPI then return diff>=-4,"green" end
  local grayRange
  if UnitQuestTrivialLevelRange then grayRange=grayAPI("player")else grayRange=grayAPI()end
  if not readable(grayRange)then return false,"restricted" end
  return whole(grayRange,0,1000) and -diff<=grayRange,"green"
end
function P.KillXPReward(difficulty,elite)
  local amount
  if difficulty=="green" then amount=1
  elseif difficulty=="yellow" then amount=P.random(2,3)
  elseif difficulty=="orange" then amount=P.random(3,4)
  elseif difficulty=="red" then amount=P.random(4,5)
  else return 0 end
  return amount+(elite and 1 or 0)
end
local function validSave(s)
  if type(s)~="table" or s.version~=1 or type(s.pets)~="table" or #s.pets>512 or type(s.inventory)~="table" then return false end
  for _,key in ipairs({"nextID","playSeconds","rewardSeconds"})do
    local n=s[key];if type(n)~="number" or n~=n or n<0 or n>1e12 then return false end
  end
  if not whole(s.tokens,0,P.maxTokens) or not whole(s.nextID,1,1000000)then return false end
  for key in pairs(P.items)do if not whole(s.inventory[key],0,10000000)then return false end end
  local ids={}
  for _,pet in ipairs(s.pets)do
    if type(pet)~="table" or not whole(pet.id,1,1000000) or ids[pet.id] or not whole(pet.species,1,#P.species)
      or not whole(pet.rarity,1,5) or not whole(pet.level,1,100) or not whole(pet.best,0,100) or not whole(pet.wins,0,10000000)then return false end
    ids[pet.id]=true
    for _,key in ipairs({"health","food","energy","age","born","xp"})do
      local n=pet[key];if type(n)~="number" or n~=n or n<0 or n>1e12 then return false end
    end
    if pet.health>100 or pet.food>100 or pet.energy>100 then return false end
    if pet.deadAt~=nil and (type(pet.deadAt)~="number" or pet.deadAt~=pet.deadAt)then return false end
  end
  return true
end
P.ValidSave=validSave
function P.Init()
  P.victory=nil;P.defeat=nil;P.lastRound=nil;P.progressEvents={};P.levelPreview=nil
  P.instantHeals={};P.cityRestAwake={};P.restHealTimers={}
  local s=F.char.pets
  local invalid=s~=nil and not validSave(s)
  if invalid then F.char.petQuarantine=s;s=nil end
  local fresh=s==nil
  if not s then
    s={version=1,pets={},active=nil,nextID=1,tokens=100,inventory={food=2,medicine=2},playSeconds=0,rewardSeconds=0,share=false}
    F.char.pets=s
  end
  if invalid then P.notice="Unreadable pet save preserved in a backup. Started a fresh stable." end
  P.state=s
  local receipts=type(s.pvpRecent)=="table" and s.pvpRecent or {};s.pvpRecent={}
  local count=0;local now=F.Now()
  for guid,when in pairs(receipts)do
    if count<128 and type(guid)=="string" and #guid<=100 and guid:match("^Player%-") and whole(when,0,1e12) and now>=when and now-when<300 then
      s.pvpRecent[guid]=when;count=count+1
    end
  end
  if F.History then F.History.Initialize(s,fresh)end
  -- Retired care currency: refund stock once, including legacy imports.
  if whole(s.inventory.toy,0,10000000)then P.ChangeTokens(math.min(P.maxTokens-s.tokens,s.inventory.toy*3),"MIGRATION","toys")end
  s.inventory.toy=nil
  for _,pet in ipairs(s.pets)do pet.happy=nil;pet.retirementLocked=pet.retirementLocked==true end
  s.review=nil;s.seal=nil -- Retire preview integrity flags; this is a personal game.
  s.packs=type(s.packs)=="table" and s.packs or {}
  for i=1,6 do s.packs[i]=0 end -- Crates are purchased directly; retired free entitlements cannot bypass cost.
  s.bossClaims=type(s.bossClaims)=="table" and s.bossClaims or {}
  s.bossEggs=type(s.bossEggs)=="table" and s.bossEggs or {}
  if not whole(s.nextTreatDrop,0,1e12)then s.nextTreatDrop=0 end
  for key,value in pairs(s.bossEggs)do if not whole(key,85,100) or not whole(value,0,100000)then s.bossEggs[key]=nil end end
  for key,value in pairs(s.bossClaims)do if type(key)~="string" or type(value)~="number" or value~=value or F.Now()-value>604800 then s.bossClaims[key]=nil end end
  if s.sharingDefaults~=1 then s.share=true;s.sharingDefaults=1 end
  P.state=s
  for key,item in pairs(P.items)do
    if s.inventory[key]>20 then P.ChangeTokens(math.min(P.maxTokens-s.tokens,(s.inventory[key]-20)*item.cost),"MIGRATION",key);s.inventory[key]=20 end
  end
  for _,pet in ipairs(s.pets)do P.EnsureAbilities(pet);P.EnsureTowerSeed(pet)end
  if P.InitCollection then P.InitCollection()end
  if P.ArchiveUnsupportedPets then P.ArchiveUnsupportedPets()end
  if P.InitTalents then P.InitTalents()end
  if F.Achievements then F.Achievements.Initialize()end
  if F.Integrity then F.Integrity.Initialize()end
  if F.Trades then F.Trades.Initialize()end
  if F.Inspect then F.Inspect.Initialize()end
  if F.HistoryPeers then F.HistoryPeers.Initialize()end
  if F.Witnesses then F.Witnesses.Initialize()end
  -- Quitting mid-fight counts as a retreat, never a free healed battle.
  if s.battle then s.battle=nil;P.notice="Your pet retreated when the session ended." end
  if P.ResetResourceDisplay then P.ResetResourceDisplay()end
end
function P.Active()
  for _,pet in ipairs(P.state.pets)do if pet.id==P.state.active and not pet.deadAt then return pet end end
end
function P.Die(pet,reason)
  if pet.deadAt then return end
  local round=P.state.battle and P.lastRound
  local impact=round and round.at+math.max(0,#round.events-1)*(P.eventDuration or 0.55)+(P.impactDelay or 0.2)
  P.defeat={pet=pet,round=round,floor=P.state.battle and P.state.battle.floor,
    at=(GetTime and GetTime() or F.Now())+math.max(0,(impact or 0)-(P.sceneClock or 0))}
  pet.health=0;pet.deadAt=F.Now();pet.deathReason=reason;P.state.battle=nil
  P.notice=P.species[pet.species].." has died. Kept in the memorial; retirement grants 50% less talent XP."
end
function P.Select(id)
  if P.state.battle then return false,"Finish the battle first." end
  for _,pet in ipairs(P.state.pets)do if pet.id==id and not pet.deadAt then P.state.active=id;P.floor=math.min(100,pet.best+1);P.notice="Equipped "..P.species[pet.species]..".";return true end end
  return false,"This pet is in the memorial. Death is permanent."
end
-- Saved energy remains a percentage for inspect/trade compatibility.
P.supplyCap=20
P.combatXPCap=12
function P.MaxEnergy()return 100+P.TalentBonus("energyCapacity")end
function P.EnergyPoints(pet)return pet.energy*P.MaxEnergy()/100 end
function P.SupplyCost(item)return P.items[item].cost*(item=="medicine" and P.state.battle and 1.5 or 1)end
function P.HealingAmount(item)
  return item=="food" and 10*(1+P.TalentBonus("feedingHealing")) or (40+P.RacialBonus("herbHealing"))*(1+P.TalentBonus("herbHealingBonus"))
end
function P.AddSupply(item,count)
  local prior=P.state.inventory[item];local earned=math.min(count,math.max(0,P.supplyCap-prior))
  P.state.inventory[item]=prior+earned;return earned
end
function P.InRestArea()
  local rested=IsResting and IsResting()
  return readable(rested) and rested==true
end
function P.RestRate(pet)
  local rested=P.InRestArea()
  return (pet.resting and (1/6)*(1+P.RacialBonus("rest"))*(rested and 1.25 or 1) or 1/100)*100/P.MaxEnergy()
end
function P.Buy(item,count)
  count=count or 1
  if not whole(count,1,100)then return false,"Choose 1 to 100 supplies." end
  local entry=P.items[item];if not entry then return false,"Unknown item." end
  if P.state.inventory[item]+count>P.supplyCap then return false,"You can carry at most 20 of each supply." end
  local cost=P.SupplyCost(item)
  if P.state.tokens<cost*count then return false,"Not enough pet tokens." end
  P.ChangeTokens(-cost*count,"SUPPLIES",item);P.state.inventory[item]=P.state.inventory[item]+count;return true
end
function P.Care(item)
  local pet=P.Active();if not pet then return false,"Adopt or select a living pet." end
  if P.state.battle then return false,"Use the tower Heal button during battle." end
  if item=="medicine" and pet.health>=100 then return false,"Your pet is already at full health." end
  if item=="rest" then
    pet.resting=not pet.resting and (pet.energy<100 or pet.health<100)
    pet.cityRest=nil;P.cityRestAwake[pet.id]=P.InRestArea() and not pet.resting or nil
    P.restHealTimers[pet.id]=nil;return true
  end
  if not P.items[item] or P.state.inventory[item]<1 then return false,"Buy that care item with pet tokens first." end
  P.state.inventory[item]=P.state.inventory[item]-1
  if item=="food" then pet.food=clamp(pet.food+35);pet.health=clamp(pet.health+P.HealingAmount("food"))
  else pet.health=clamp(pet.health+P.HealingAmount("medicine"))end
  return true
end
function P.Tick(seconds)
  if not P.state then return end
  local s=P.state
  local now=GetTime and GetTime() or F.Now()
  for id,event in pairs(P.progressEvents)do if now-event.at>10 then P.progressEvents[id]=nil end end
  seconds=math.max(0,math.min(5,seconds)) -- No offline catch-up or long loading-screen penalties.
  local active=P.Active()
  local inRestArea=P.InRestArea()
  if not inRestArea then P.cityRestAwake={}end
  -- Combatants never recover through camp care. Benched pets may still rest.
  local fighting={}
  if s.battle then
    fighting[s.battle.petID]=true
    for _,unit in ipairs(s.battle.allies or {})do fighting[unit.pet.id]=true end
  end
  s.rewardSeconds=s.rewardSeconds+seconds
  if s.rewardSeconds>=300 then P.AwardTokens(math.floor(s.rewardSeconds/300)*2,"onlineTokens");s.rewardSeconds=s.rewardSeconds%300 end
  s.playSeconds=s.playSeconds+seconds
  local timers={}
  for _,pet in ipairs(s.pets)do
    if not pet.deadAt then
      if pet.cityRest and not inRestArea then pet.resting=false;pet.cityRest=nil end
      if fighting[pet.id]then
        pet.resting=false;pet.cityRest=nil
      else
        if inRestArea and not pet.resting and not P.cityRestAwake[pet.id] and (pet.energy<100 or pet.health<100)then
          pet.resting=true;pet.cityRest=true
        end
        if pet==active or pet.resting then
          pet.age=pet.age+seconds
          pet.food=clamp(pet.food-seconds/300*(1-P.TalentBonus("foodSavings")))
          if pet.food<10 then
            -- Hunger pauses recovery and cannot kill a companion.
            pet.health=math.max(1,clamp(pet.health-seconds/60))
            pet.energy=math.max(1,clamp(pet.energy-seconds/60))
          else
            local rate=P.RestRate(pet)
            local fillTime=math.max(0,100-pet.energy)/rate
            pet.energy=clamp(pet.energy+seconds*rate)
            if pet.energy>100-0.0000001 then pet.energy=100 end
            if pet.resting and pet.energy>=100 and pet.health<100 then
              local elapsed=(P.restHealTimers[pet.id] or 0)+math.max(0,seconds-fillTime)
              local healing=math.floor((elapsed+0.000001)/5)
              if healing>0 then
                local maxHP=P.Stats(pet)
                pet.health=clamp(pet.health+healing*100/maxHP)
              end
              timers[pet.id]=math.max(0,elapsed-healing*5)
            end
          end
          if pet.resting and pet.energy>=100 and pet.health>=100 then
            pet.resting=false;pet.cityRest=nil;timers[pet.id]=nil
          end
        end
      end
    end
  end
  P.restHealTimers=timers
end
P.progressEvents={}
P.progressSerial=0
function P.RestText(pet)
  if not pet or not pet.resting then return "" end
  if pet.food<10 then return "Rest paused: feed your pet" end
  if pet.energy>=100 and pet.health<100 then return "Rest: +1 HP / 5s" end
  local seconds=math.ceil(math.max(0,100-pet.energy)/P.RestRate(pet)-0.0000001)
  return string.format("Rest: %d:%02d remaining",math.floor(seconds/60),seconds%60)
end
function P.AddXP(pet,amount,source)
  local cap=P.LevelCap and P.LevelCap() or 10
  if not pet or pet.deadAt or pet.level>=cap then return 0 end
  local before,beforeXP=pet.level,pet.xp
  amount=math.max(0,math.floor(amount))
  local capacity=-pet.xp
  for level=pet.level,cap-1 do capacity=capacity+20+level*5 end
  amount=math.min(amount,capacity)
  if amount==0 then return 0 end
  pet.xp=pet.xp+amount
  while pet.level<cap and pet.xp>=20+pet.level*5 do pet.xp=pet.xp-(20+pet.level*5);pet.level=pet.level+1 end
  if pet.level>=cap then pet.xp=0 end
  if pet.level>before then
    pet.health=100
    local battle=P.state and P.state.battle
    if battle and battle.petID==pet.id then
      battle.maxHP,battle.attack,battle.armor,battle.speed=P.Stats(pet)
      battle.hp=battle.maxHP;battle.statBreakdown=P.StatBreakdown(pet)
      battle.pendingHeal=nil;battle.healAbility=nil
    end
  end
  -- UI-only receipts belong to this pet, never to the global popup queue.
  P.progressSerial=P.progressSerial+1
  local prior=P.progressEvents[pet.id]
  local now=GetTime and GetTime() or F.Now()
  local fresh=source~="tower" and prior and prior.source~="tower" and now>=prior.at and now-prior.at<1
  local sameDing=fresh and prior.level==pet.level and prior.level>prior.fromLevel
  P.progressEvents[pet.id]={serial=P.progressSerial,dingSerial=sameDing and (prior.dingSerial or prior.serial) or P.progressSerial,
    sound=sameDing and prior.sound or nil,source=source,at=now,amount=amount+(fresh and prior.amount or 0),
    fromLevel=fresh and prior.fromLevel or before,fromXP=fresh and prior.fromXP or beforeXP,level=pet.level,xp=pet.xp}
  return amount
end
-- PARTY_KILL provides kill evidence even when the player earns no experience.
-- Nearby party/raid members and their combat pets count; strangers do not.
function P.KillSource(sourceGUID)
  if not readable(sourceGUID) or type(sourceGUID)~="string"then return false,false end
  local restricted=false
  for _,unit in ipairs({"player","pet"})do
    local guid=UnitGUID(unit)
    if not readable(guid)then restricted=true end
    if readable(guid) and guid and sourceGUID==guid then return true,unit=="player" end
  end
  local raid=IsInRaid and IsInRaid()
  for i=1,raid and 40 or 4 do
    local unit=(raid and "raid" or "party")..i
    local guid,petGUID=UnitGUID(unit),UnitGUID((raid and "raidpet" or "partypet")..i)
    if not readable(guid) or not readable(petGUID)then restricted=true end
    if (readable(guid) and guid and sourceGUID==guid) or (readable(petGUID) and petGUID and sourceGUID==petGUID)then
      if UnitInRange then
        local inRange,checked=UnitInRange(unit)
        -- Forever can hide distance even for a visible, identified party member.
        -- Use the independent visibility check without inspecting hidden values.
        if readable(inRange) and readable(checked)then
          if checked then return inRange==true,false end
        else restricted=true end
      end
      local visible=UnitIsVisible and UnitIsVisible(unit)
      return readable(visible) and visible==true,false,restricted or not readable(visible)
    end
  end
  return false,false,restricted
end
-- Small kill rewards supplement the tower; loot remains the focus outdoors.
-- Small rewards and repeat limits keep casual combat progression balanced.
P.recentKills={}
function P.RewardPvPKill(guid)
  if not readable(guid) or type(guid)~="string" or #guid>100 or not guid:match("^Player%-")then return false end
  local s=P.state;local now=F.Now();s.pvpRecent=s.pvpRecent or {}
  local count=0
  for key,when in pairs(s.pvpRecent)do
    if now<when or now-when>=300 then s.pvpRecent[key]=nil else count=count+1 end
  end
  if s.pvpRecent[guid] or count>=128 then return false end
  s.pvpRecent[guid]=now
  local a=s.achievements;if a then a.pvpKills=math.min(1000000,(a.pvpKills or 0)+1)end
  local pet=P.Active()
  if pet and pet.health>0 then
    P.RestorePetHealth(pet,10)
    pet.food=clamp(pet.food+5);pet.energy=clamp(pet.energy+10*100/P.MaxEnergy())
  end
  return true
end
function P.HiddenDungeonKill(destGUID)
  -- PARTY_KILL itself confirms a group kill. Use only the event's occurrence;
  -- hidden values are never compared, indexed, retained or converted to text.
  if not IsInInstance then return end
  local inside,kind=IsInInstance()
  if not readable(inside) or not readable(kind) or inside~=true or (kind~="party" and kind~="raid")then return end
  local guid
  if readable(destGUID)then
    if type(destGUID)~="string" or not destGUID:match("^Creature%-")then return end
    guid=destGUID
  end
  local eligible,observed
  if guid then
    eligible=P.EligibleKill(guid);observed=P.enemyLevels[guid]
    if P.ExcludedKill(guid)then return end
    if not eligible and observed and observed.level then
      if P.RollKillLoot then P.RollKillLoot(guid)end -- Real gray critters may still drop their pet.
      P.killStatus="Enemy is gray or otherwise ineligible.";return
    end
  end
  -- Loot is independent of XP caps, active companions and pet level caps.
  -- Only five-player dungeons may use the player's level when details hide.
  local fallbackLevel
  if kind=="party"then
    local level
    if UnitEffectiveLevel then level=UnitEffectiveLevel("player")elseif UnitLevel then level=UnitLevel("player")end
    if readable(level) and whole(level,1,1000)then fallbackLevel=level end
  end
  if guid and P.RollKillLoot then P.RollKillLoot(guid,eligible and observed and observed.level,fallbackLevel,observed and (observed.elite or observed.boss))
  elseif fallbackLevel and P.RollEquipmentLoot then P.RollEquipmentLoot(fallbackLevel,nil,true);if P.RollCoinPouch then P.RollCoinPouch()end end
  local pet=P.Active()
  if not pet then P.killStatus="No living pet equipped.";return end
  if pet.level>=P.LevelCap()then P.killStatus="Pet is at its unlocked level cap.";return end
  local now=F.Now()
  for key,when in pairs(P.recentKills)do if now-when>=300 then P.recentKills[key]=nil end end
  if guid and P.recentKills[guid]then P.killStatus="Repeated kill ignored.";return end
  if not P.combatWindow or now-P.combatWindow>=60 or now<P.combatWindow then P.combatWindow=now;P.combatXP=0 end
  if (P.combatXP or 0)>=P.combatXPCap then P.killStatus="Twelve XP per minute limit reached.";return end
  local earned=P.AddXP(pet,1,"kill")
  if earned>0 then
    if guid then P.recentKills[guid]=now end
    P.combatXP=(P.combatXP or 0)+1
    P.notice="+"..earned.." pet XP: dungeon party kill (restricted details).";P.killStatus=P.notice
  end
end
function P.KillXPStatus()
  local used=P.combatWindow and F.Now()-P.combatWindow<60 and (P.combatXP or 0) or 0
  local pet=P.Active()
  F.Print((pet and ("Pet level "..pet.level.." / cap "..P.LevelCap()..". ") or "No living pet equipped. ")
    ..used.."/12 combat XP this minute. Last check: "..(P.killStatus or "No party kill event received this session."))
end
function P.CombatKill(event,sourceGUID,destGUID)
  if event~="PARTY_KILL" or not P.state or not UnitGUID then return end
  P.killStatus="Kill received; checking eligibility."
  -- Forever's standalone kill event may carry restricted identities. Never
  -- compare, parse, stringify or retain those values in addon code.
  if not readable(sourceGUID) or not readable(destGUID) then
    P.killStatus="WoW restricted kill identities.";P.HiddenDungeonKill(destGUID);return
  end
  if not sourceGUID or type(destGUID)~="string" then return end
  local accepted,personal,restricted=P.KillSource(sourceGUID)
  if not accepted then
    P.killStatus="Killer not matched to a readable nearby party member or pet."
    if restricted then P.HiddenDungeonKill(destGUID)end
    return
  end
  local isPlayer=destGUID:match("^Player%-")~=nil
  if not isPlayer and not destGUID:match("^Creature%-") then return end
  -- Confirmed PvP credit is independent of the NPC XP budget and pet level cap.
  -- The saved five-minute receipt also prevents a reload from paying it twice.
  if isPlayer and not P.RewardPvPKill(destGUID)then P.killStatus="Repeated PvP kill ignored.";return end
  local eligible,difficulty=P.EligibleKill(destGUID)
  if P.ExcludedKill(destGUID)then P.killStatus="Summoned creature ignored.";return end
  if not eligible and difficulty=="restricted" and IsInInstance then
    local inside,kind=IsInInstance()
    if readable(inside) and readable(kind) and inside==true and (kind=="party" or kind=="raid")then P.HiddenDungeonKill(destGUID);return end
  end
  -- Pet farming remains available on gray critters. Gear uses a verified enemy
  -- level and the green-through-red eligibility gate, independent of XP's cap.
  if not isPlayer and F.Witnesses then F.Witnesses.Observe(destGUID)end
  local observed=P.enemyLevels[destGUID]
  if not isPlayer and P.RollKillLoot then P.RollKillLoot(destGUID,eligible and observed and observed.level,nil,observed and (observed.elite or observed.boss))end
  if not eligible then
    P.killStatus="Enemy is gray or has no recent readable level."
    return
  end
  local pet=P.Active();if not pet then P.killStatus="No living pet equipped.";return end
  local now=F.Now()
  for guid,when in pairs(P.recentKills)do if now-when>=300 then P.recentKills[guid]=nil end end
  if P.recentKills[destGUID] then P.killStatus="Repeated kill ignored.";return end
  if not P.combatWindow or now-P.combatWindow>=60 or now<P.combatWindow then P.combatWindow=now;P.combatXP=0 end
  local entry=P.enemyLevels[destGUID]
  local elite=not isPlayer and entry and entry.elite
  local amount=math.min(P.KillXPReward(difficulty,elite),math.max(0,P.combatXPCap-(P.combatXP or 0)))
  local canDrop=not isPlayer and personal and now>=P.state.nextTreatDrop
  if amount<=0 then P.killStatus="Twelve XP per minute limit reached.";if not canDrop then return end end
  P.recentKills[destGUID]=now;P.combatXP=(P.combatXP or 0)+amount
  local earned=P.AddXP(pet,amount,"kill")
  if earned>0 then P.notice="+"..earned.." pet XP: "..(isPlayer and "PvP kill" or "NPC kill")..".";P.killStatus=P.notice
  elseif pet.level>=P.LevelCap()then P.killStatus="Pet is at its unlocked level cap." end
  -- One percent from eligible personal NPC kills; at most one per 30 minutes.
  -- The cooldown is saved, and the existing level/repeat guards still apply.
  if canDrop and P.state.inventory.food<P.supplyCap and P.random(1,100)==1 then
    P.AddSupply("food",1);P.state.nextTreatDrop=now+1800
    P.notice="Found food! +1 food in your supplies."..(earned>0 and " +"..earned.." pet XP." or "")
  end
end
function P.UseCare(item)
  if item=="medicine" then
    if P.state.battle then return P.RequestHeal()end
    local pet=P.Active();if pet and pet.health>=100 then return false,"Your pet is already at full health." end
  end
  if not P.Active() or P.state.battle then return P.Care(item)end
  if P.items[item] and P.state.inventory[item]<1 then
    local ok,message=P.Buy(item);if not ok then return ok,message end
  end
  local ok,message=P.Care(item)
  if ok then P.notice=item=="rest" and (P.Active().resting and "Resting beside the camp." or "Ready for adventure.") or "Your companion enjoyed the care." end
  return ok,message
end
function P.PauseBattle()
  if not P.state.battle then return false,"Start a battle first." end
  P.state.battle.paused=not P.state.battle.paused;return true
end
function P.Age(seconds)
  return string.format("%dh %02dm",math.floor(seconds/3600),math.floor(seconds/60)%60)
end
P.peers={};P.replyTimes={}
local prefix="FWLPet1"
local function peerKey(name)
  local key=name:lower():gsub("%s","")
  local realm=GetRealmName and GetRealmName():lower():gsub("%s","")
  local short,suffix=key:match("^([^%-]+)%-(.+)$")
  return suffix==realm and short or key
end
function P.RegisterSharing()
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return false end
  if not P.registered and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix);P.registered=ok and readable(result) and (result==true or result==((Enum and Enum.RegisterAddonMessagePrefixResult and Enum.RegisterAddonMessagePrefixResult.Success) or 0) or result==((Enum and Enum.RegisterAddonMessagePrefixResult and Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix) or 1))
  end
  return P.registered
end
function P.SetSharing(enabled)
  P.state.share=not not enabled;P.peers={};P.replyTimes={};P.pendingInspect=nil;P.nextShare=F.Now()+2
  if enabled then P.RegisterSharing()end
end
function P.Packet()
  local p=P.Active();if not p then return end
  return table.concat({"3",p.species,p.rarity,p.level,math.floor(p.age),p.best,p.wins},",")
end
function P.InspectTarget()
  if not P.state.share then return false,"Enable pet sharing before inspecting another player." end
  local player=UnitIsPlayer and UnitIsPlayer("target");local self=UnitIsUnit and UnitIsUnit("target","player")
  if not readable(player) or not readable(self) or not player or self then return false,"Target another player with Companions Forever." end
  local name=GetUnitName and GetUnitName("target",true) or UnitName("target")
  return P.RequestBasicInspect(name)
end
function P.RequestBasicInspect(name)
  if not P.state.share then return false,"Enable pet sharing before inspecting another player."end
  if not readable(name) or type(name)~="string" or #name==0 or #name>100 or name:find("[|%c]") or not P.RegisterSharing() then return false,"Pet inspection is unavailable." end
  if P.nextInspect and F.Now()<P.nextInspect then return false,"Wait a few seconds before inspecting again." end
  P.nextInspect=F.Now()+5;P.pendingInspect={name=peerKey(name),expires=F.Now()+10}
  local ok=pcall(C_ChatInfo.SendAddonMessage,prefix,"ASK3","WHISPER",name)
  if not ok then P.pendingInspect=nil;return false,"Could not request this player's pet." end
  P.notice="Requested pet from "..name..". They need pet sharing enabled.";return true
end
function P.Receive(message,channel,sender)
  if not P.state or not P.state.share then return end
  if not readable(message) or not readable(channel) or not readable(sender) then return end
  if type(sender)~="string" or #sender==0 or #sender>100 or sender:find("[|%c]") or type(message)~="string" or #message>180 then return end
  if sender==(UnitName and UnitName("player"))then return end
  local now=F.Now()
  if channel=="WHISPER" then
    if message=="ASK3" then
      if not P.RegisterSharing() or now<(P.nextReply or 0) or now-(P.replyTimes[sender] or -1000)<30 then return end
      P.replyTimes[sender]=now;P.nextReply=now+1
      pcall(C_ChatInfo.SendAddonMessage,prefix,P.Packet() or "NONE3","WHISPER",sender);return
    end
    if not P.pendingInspect or now>P.pendingInspect.expires or peerKey(sender)~=P.pendingInspect.name then return end
    if message=="NONE3" then P.pendingInspect=nil;P.notice=sender.." has no active companion.";return end
  elseif channel~="PARTY" and channel~="RAID" and channel~="GUILD" then return end
  local prior=P.peers[sender]
  if channel~="WHISPER" and prior and now-prior.seen<30 then return end
  local version,sp,rar,lv,age,best,wins=message:match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
  if version~="3" then return end
  sp,rar,lv,age,best,wins=tonumber(sp),tonumber(rar),tonumber(lv),tonumber(age),tonumber(best),tonumber(wins)
  if not (whole(sp,1,#P.species) and whole(rar,1,5) and whole(lv,1,100) and whole(age,0,315360000) and whole(best,0,100) and whole(wins,0,10000000)) then return end
  if P.IsAllowedSpecies and not P.IsAllowedSpecies(sp)then return end
  local count=0;for _ in pairs(P.peers)do count=count+1 end
  if count>=40 and not prior then
    if channel~="WHISPER" then return end
    local oldest;for name,entry in pairs(P.peers)do if not oldest or entry.seen<P.peers[oldest].seen then oldest=name end end
    if oldest then P.peers[oldest]=nil end
  end
  P.peers[sender]={seen=now,species=sp,rarity=rar,level=lv,age=age,best=best,wins=wins}
  if channel=="WHISPER" then P.pendingInspect=nil;P.inspectName=sender;P.notice="Viewing "..sender.."'s companion." end
end
function P.Share()
  if not P.state.share or not P.RegisterSharing() then return end
  local packet=P.Packet();if not packet then return end
  if IsInGuild and IsInGuild()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"GUILD")end
  if IsInRaid and IsInRaid()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"RAID")
  elseif IsInGroup and IsInGroup()then pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"PARTY")end
end
local events=CreateFrame("Frame");P.events=events;events:RegisterEvent("CHAT_MSG_ADDON")
-- COMBAT_LOG_EVENT_UNFILTERED is forbidden to addons on Forever. PARTY_KILL
-- is a separate supported event with (attackerGUID, targetGUID) payload.
events:RegisterEvent("PARTY_KILL")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("UNIT_TARGET")
events:SetScript("OnEvent",function(_,event,p,message,channel,sender)
  if not P.state then return end
  if event=="PARTY_KILL" then
    P.CombatKill(event,p,message)
  elseif event=="PLAYER_TARGET_CHANGED" then P.ObserveEnemy("target")
  elseif event=="PLAYER_FOCUS_CHANGED" then P.ObserveEnemy("focus")
  elseif event=="UPDATE_MOUSEOVER_UNIT" then P.ObserveEnemy("mouseover")
  elseif event=="NAME_PLATE_UNIT_ADDED" then if readable(p) and type(p)=="string" then P.ObserveEnemy(p)end
  elseif event=="UNIT_TARGET" then if readable(p) and type(p)=="string" and (p=="pet" or p:match("^party%d+$") or p:match("^raid%d+$")) then P.ObserveEnemy(p.."target")end
  elseif readable(p) and p==prefix then P.Receive(message,channel,sender)end
end)
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
  if not P.state then return end
  local battle=P.state.battle
  if P.BattleVisible and P.BattleVisible() and not (battle and battle.paused) then
    P.sceneClock=(P.sceneClock or 0)+math.min(dt,0.25)
  end
  P.AdvanceBattle(dt,P.BattleVisible and P.BattleVisible())
  if P.AdvanceVictory then P.AdvanceVictory()end
  elapsed=elapsed+dt;if elapsed<1 then return end
  P.ObserveEnemy("target")
  P.ObserveEnemy("focus");P.ObserveEnemy("pettarget")
  for i=1,4 do P.ObserveEnemy("party"..i.."target")end
  for i=1,5 do P.ObserveEnemy("boss"..i)end
  P.Tick(elapsed);elapsed=0
  if F.Now()>=(P.nextShare or 0)then
    P.nextShare=F.Now()+120;P.Share()
    for sender,entry in pairs(P.peers)do if F.Now()-entry.seen>600 then P.peers[sender]=nil end end
    for sender,when in pairs(P.replyTimes)do if F.Now()-when>60 then P.replyTimes[sender]=nil end end
  end
  if P.pendingInspect and F.Now()>P.pendingInspect.expires then P.pendingInspect=nil;P.notice="No pet reply. Both players need compatible companions and pet sharing enabled." end
  if P.Render then P.Render()end
end)
