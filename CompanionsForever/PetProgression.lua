local _,F=...
local P,D=F.Pets,F.PetData
function P.PetName(pet)return P.species[pet.species] end
P.packs=D.packs
local function clamp(v)return math.max(0,math.min(100,v))end
local function integer(v,lo,hi)return type(v)=="number" and v==math.floor(v) and v>=lo and v<=hi end
local function readable(v)
  if issecretvalue and issecretvalue(v)then return false end
  return not canaccessvalue or canaccessvalue(v)
end
P.stableCapacity=9
function P.LivingCount()
  local n=0;for _,pet in ipairs(P.state.pets)do if not pet.deadAt then n=n+1 end end;return n+(F.Trades and F.Trades.Reserved("pet") or 0)
end
function P.IsHoused(pet)
  local life=F.Housing and F.Housing.Island and F.Housing.Island.Life
  return life and life.IsHoused(pet.id) or false
end
function P.StableCount()
  local n=0
  for _,pet in ipairs(P.state.pets)do
    if not pet.deadAt and not P.IsHoused(pet)then n=n+1 end
  end
  return n+(F.Trades and F.Trades.Reserved("pet") or 0)
end
local function room()
  if P.state.nextID+(F.Trades and F.Trades.RecordReserved("pet") or 0)>=1000000 then return false,"Your stable records are full."end
  if P.state.battle then return false,"Finish the battle first." end
  if #P.state.pets+(F.Trades and F.Trades.Reserved("pet") or 0)>=512 then return false,"The stable and memorial have reached 512 records." end
  if P.StableCount()>=P.stableCapacity then return false,"Your stable holds "..P.stableCapacity.." living companions. Retire a pet of any level to make room." end
  return true
end
local function addPet(species,rarity,source,quiet,mail,commit)
  local s=P.state
  local I,H=F.Integrity,F.History
  if I and (I.broken or not s.integrity or I.count>=I.limit or s.integrity.sequence>=1000000000)then
    return false,"Asset history needs recovery or is full. No companion created."
  end
  if H and (H.broken or not s.tokenHistory or s.tokenHistory.seq>=1000000000)then
    return false,"Token history needs recovery or is full. No companion created."
  end
  local pet={id=s.nextID,species=species,rarity=rarity,level=1,xp=0,health=100,food=100,energy=100,born=F.Now(),age=0,best=0,wins=0,source=source}
  P.EnsureAbilities(pet)
  P.EnsureTowerSeed(pet)
  if P.RollNewPet then P.RollNewPet(pet)end
  if F.Integrity then F.Integrity.Stamp("pet",pet,"S")end
  if F.Integrity and not pet.assetID then return false,"Asset history is unavailable. No companion created."end
  pet.isNew=true
  s.nextID=s.nextID+1
  if mail then F.Mailbox.Store("pet",pet,nil,source)else
    s.pets[#s.pets+1]=pet
    if not P.Active()then s.active=pet.id;P.floor=1 end
    P.viewID=pet.id;P.page=math.ceil(#s.pets/P.stableCapacity)
    if P.GetStableLayout then
      local _,_,positions=P.GetStableLayout();P.page=math.ceil((positions[pet.id] or 1)/P.stableCapacity)
    end
  end
  -- Commit payment or consume the source crate before discovery/UI callbacks.
  -- A presentation failure must never leave a rewarded crate usable again.
  if commit then commit(pet)end
  if F.History and not pet.birth then F.History.Birth(pet,"R",nil,0,0)end
  P.notice="Adopted "..P.rarities[rarity].." "..P.species[species]..(s.active==pet.id and " - equipped." or ". Select Equip to travel together.")
  if P.RecordDiscovery then P.RecordDiscovery(species,rarity,source)end
  if P.RecordAbilityDiscovery then P.RecordAbilityDiscovery(pet)end
  if P.IsSparkly and P.IsSparkly(pet) then
    local entry=s.collection and s.collection[species];if entry then entry.sparkly=true end
    P.notice="Discovered "..P.PetName(pet).."!"
    F.Print("|cffb4efffSparkly companion!|r "..P.rarities[rarity].." "..P.species[species])
  end
  if P.Reward and not quiet then P.Reward("pet","Companion found!",P.rarities[rarity].." "..P.PetName(pet),source,species,rarity,pet.id,nil,pet.rolls)end
  if mail then P.notice="Companion sent to Mail. Make room in your stable to collect it.";F.Print(P.notice)end
  return true,pet
end
function P.GrantPet(species,rarity,source,quiet,commit)
  if not integer(species,1,#P.species) or not integer(rarity,1,5)then return false,"Invalid companion." end
  if P.IsAllowedSpecies and not P.IsAllowedSpecies(species)then return false,"This model is outside the Classic / Season of Discovery roster." end
  local ok,msg=room()
  if not ok then
    if F.Mailbox and F.Mailbox.CanReceive() and P.state.nextID+(F.Trades and F.Trades.RecordReserved("pet") or 0)<1000000 then return addPet(species,rarity,source,quiet,true,commit)end
    return ok,msg
  end
  return addPet(species,rarity,source,quiet,nil,commit)
end
function P.Rescue()
  for _,entry in ipairs(P.state.mailbox or {})do if entry.kind=="pet"then return false,"Collect your waiting companion from Mail first."end end
  if #P.state.pets>0 or (F.Trades and F.Trades.Reserved("pet")>0)then return false,"The free crate requires an entirely empty stable, including memorials." end
  local ok,msg=room();if not ok then return false,msg end
  local pool={3,4,5} -- Wolf pup, Owl, Stonetusk Boar: three verified Classic models.
  local species=pool[P.random(1,3)]
  if P.Reward then P.Reward("crate","Opening a Recovery Crate","One Common wolf pup, owl or boar.","INV_Crate_01")end
  local granted,pet=addPet(species,1,"Free recovery crate")
  if granted then pet.recovery=true end
  return granted,pet
end
function P.Adopt(index)
  index=index or 1
  if not integer(index,1,6)then return false,"Choose an adoption crate." end
  local ok,msg=room();if not ok then return ok,msg end
  local s,pack=P.state,D.packs[index]
  if s.tokens<pack.cost then return false,"This adoption crate costs "..pack.cost.." pet tokens." end
  local rarity=P.RollCrateReward("pet",index)
  local pool=D.rosterPool
  local species=pool and pool[P.random(1,#pool)] or P.random(1,#P.species)
  local granted,pet=addPet(species,rarity,pack.name,true,nil,function(companion)
    local receipt=P.ChangeTokens(-pack.cost,"PETCRATE",tostring(index))
    if F.History and receipt then F.History.Birth(companion,"P",receipt.ref,index,pack.cost,receipt)end
  end)
  if granted and P.Reward then
    P.Reward("crate","Opening "..pack.name,"A companion is waiting inside...",pack.icon)
    P.Reward("pet","Companion found!",P.rarities[rarity].." "..P.PetName(pet),pack.name,species,rarity,pet.id,nil,pet.rolls)
  end
  return granted,pet
end
function P.ClaimBoss(species)
  local ok,msg=room();if not ok then return ok,msg end
  if not integer(species,85,100) or (P.state.bossEggs[species] or 0)<1 then return false,"No boss companion waiting." end
  return addPet(species,P.UpgradeRarity(4),"Raid boss reward",nil,nil,function()
    P.state.bossEggs[species]=P.state.bossEggs[species]-1
  end)
end
P.specialAbilities={
  {effect="bite",ability="Savage Bite",icon="Ability_Druid_FerociousBite"},{effect="flurry",ability="Flurry",icon="Ability_GhoulFrenzy"},
  {effect="cleave",ability="Wild Nova",icon="Spell_Nature_WispSplode"},{effect="renew",ability="Wild Growth",icon="Spell_Nature_ResistNature"},
  {effect="drain",ability="Life Drain",icon="Spell_Shadow_LifeDrain02"},{effect="shield",ability="Iron Hide",icon="Ability_Hunter_Pet_Turtle"},
}
function P.EnsureAbilities(pet)
  local count=pet.rarity>=4 and 2 or pet.rarity>=3 and 1 or 0
  local valid,seen={},{}
  for _,id in ipairs(type(pet.abilities)=="table" and pet.abilities or {})do
    if type(id)=="number" and P.specialAbilities[id] and not seen[id] and #valid<count then valid[#valid+1]=id;seen[id]=true end
  end
  while #valid<count do
    local pool={};for id in ipairs(P.specialAbilities)do if not seen[id] and (not P.CanRollAbility or P.CanRollAbility(id))then pool[#pool+1]=id end end
    local id=pool[P.random(1,#pool)];valid[#valid+1]=id;seen[id]=true
  end
  pet.abilities=valid
end
function P.Abilities(pet)
  local result={}
  if pet and pet.rarity>=3 then
    for _,id in ipairs(pet.abilities or {})do if P.specialAbilities[id]then result[#result+1]=P.specialAbilities[id]end end
  end
  return result
end
function P.Ability(pet)return P.Abilities(pet)[1]end
-- Rolled abilities are copies, so use their stable catalogue name as the key.
function P.SpecialCooldown(unit,ability)
  return unit and ability and unit.specialCooldowns and unit.specialCooldowns[ability.ability] or 0
end
function P.TickSpecialCooldowns(unit)
  unit.cooldown=0 -- Aggregate for old diagnostics; never gates a different ability.
  for key,turns in pairs(unit.specialCooldowns or {})do
    turns=math.max(0,turns-1);unit.specialCooldowns[key]=turns>0 and turns or nil
    unit.cooldown=math.max(unit.cooldown,turns)
  end
end
function P.StartSpecialCooldown(unit,ability)
  unit.specialCooldowns=unit.specialCooldowns or {}
  local turns=ability.cooldown or 3
  unit.specialCooldowns[ability.ability]=turns;unit.cooldown=math.max(unit.cooldown or 0,turns)
end
function P.ChooseAbility(pet,healing)
  local choices={}
  for _,a in ipairs(P.Abilities(pet))do if not not P.IsHealingAbility(a)==healing then choices[#choices+1]=a end end
  if #choices==1 then return choices[1]elseif #choices>1 then return choices[P.random(1,#choices)]end
end
function P.AbilityText(pet,separator)
  if pet.rarity>=3 and not pet.abilities then return "Specials not shared" end
  local names={};for _,a in ipairs(P.Abilities(pet))do names[#names+1]=a.ability end
  return #names>0 and table.concat(names,separator or " / ") or "Basic attacks"
end
function P.Specialty(pet)
  local family=D.species[pet.species].family
  return ({beast="Strong bite: increased attack",swift="Quick feet: highest speed",guardian="Tank: highest health and armor",dragon="Balanced: extra health and armor",nature="Hardy: extra health",elemental="Potent: extra attack and armor",demon="Fierce: highest attack",undead="Resilient: extra health and armor",mechanical="Armored: high defense"})[family] or "Adaptable: balanced stats"
end
function P.SpecialtyLabel(pet)
  return ({beast="Strong attacks",swift="Fast attacks",guardian="Health and armor",dragon="Balanced defenses",nature="Extra health",elemental="Attack and armor",demon="Highest attack",undead="Health and armor",mechanical="Heavy armor"})[D.species[pet.species].family] or "Balanced stats"
end
function P.AbilityHelp(effect)
  if type(effect)=="table"then effect=effect.effect end
  return ({bite="180% attack damage.",flurry="165% attack damage.",cleave="90% attack damage to every enemy.",renew="80% attack damage and restore 18% max health.",drain="110% attack damage; heal for 60% of that hit.",shield="Strike and reduce later hits this round by 55%."})[effect].." Three-round cooldown."
end
function P.IsHealingAbility(ability)
  return ability and (ability.effect=="renew" or ability.effect=="drain")
end
function P.HealChoice()
  local b=P.state.battle
  if not b then
    if P.victory and (P.sceneClock or 0)<P.victory.readyAt then return nil,"The finishing attack is still playing."end
    local pet=P.Active()
    if not pet or pet.deadAt or pet.health<=0 then return nil,"Select a living pet."end
    if pet.health>=100 then return nil,"Your pet is already at full health."end
    if P.state.inventory.medicine<1 and P.state.tokens<P.SupplyCost("medicine")then return nil,"Need a healing herb or tokens."end
    return "heal","Heal with one herb (or "..P.SupplyCost("medicine").." tokens)."
  end
  if b.hp<=0 or not P.Active() then return nil,"Select a living pet."end
  if b.hp>=b.maxHP then return nil,"Your pet is already at full health." end
  if P.state.inventory.medicine>0 then return "heal","Use 1 healing herb" end
  if P.state.tokens>=P.SupplyCost("medicine") then return "heal","Heal for "..P.SupplyCost("medicine").." tokens" end
  return nil,"Need a healing herb or "..P.SupplyCost("medicine").." tokens."
end
function P.RecordInstantHeal(pet,amount)
  P.instantHealSerial=(P.instantHealSerial or 0)+1;P.instantHeals=P.instantHeals or {}
  P.instantHeals[pet.id]={serial=P.instantHealSerial,at=P.sceneClock or 0,amount=amount,round=P.lastRound}
end
-- Keep delayed combat snapshots from undoing a heal that has already landed.
function P.AdjustHealingSnapshots(round,amount,maxHP,enemyDamage)
  if not round or round.team then return end
  local function adjust(state)
    if not state then return end
    state.hp=math.min(maxHP,state.hp+amount)
    for i,damage in pairs(enemyDamage or {})do if state.enemyHP and state.enemyHP[i]then state.enemyHP[i]=math.max(0,state.enemyHP[i]-damage)end end
  end
  adjust(round.start);for _,event in ipairs(round.events)do adjust(event)end;adjust(round.final)
end
function P.RestorePetHealth(pet,percent)
  if not pet or pet.deadAt then return 0 end
  local b=P.state.battle
  local u=P.HardMode and P.HardMode.Unit(pet.id,b) or (b and b.petID==pet.id and b)
  local maxHP=u and u.maxHP or P.Stats(pet)
  local hp=u and u.hp or maxHP*pet.health/100
  if hp<=0 then return 0 end
  local amount=math.min(maxHP-hp,math.ceil(maxHP*percent/100))
  if u then
    u.hp=hp+amount
    if b.hard and b.allies[1]==u then b.hp=u.hp end
    if not b.hard then P.AdjustHealingSnapshots(P.lastRound,amount,maxHP)end
  end
  pet.health=math.min(100,(hp+amount)/maxHP*100)
  if amount>0 then P.RecordInstantHeal(pet,amount)end
  return amount
end
function P.RequestHeal()
  local b=P.state.battle;local pet=P.Active()
  local action,description=P.HealChoice();if not action then return false,description end
  if b then b.pendingHeal=nil end
  if P.state.inventory.medicine>0 then P.state.inventory.medicine=P.state.inventory.medicine-1
  else P.ChangeTokens(-P.SupplyCost("medicine"),"BATTLEHERB","")end
  local amount=P.RestorePetHealth(pet,P.HealingAmount("medicine"))
  P.notice="Healed "..P.species[pet.species].." for "..math.ceil(amount).." HP."
  return true
end
function P.StatBreakdown(pet)
  local family=D.families[D.species[pet.species].family]
  local quality=1+(pet.rarity-1)*0.06
  local base={math.floor((55+pet.level*9)*family.hp*quality),math.floor((9+pet.level*2.4)*family.attack*quality),family.armor+pet.rarity-1,family.speed+math.floor(pet.level/10)}
  if P.RolledBaseStats then base=P.RolledBaseStats(pet,base)end
  local gear=P.GearBonuses and {P.GearBonuses(pet)} or {0,0,0,0}
  local keys={"health","attack","armor","speed"};local rows={}
  for i=1,4 do
    local subtotal=base[i]+gear[i]
    local total=i==3 and math.min(60,subtotal+P.TalentBonus(keys[i])) or subtotal*(1+P.TalentBonus(keys[i]))
    -- Keep fractional attack so a small percentage talent is not discarded.
    -- Health and actual combat damage still resolve to whole points.
    if i==1 then total=math.floor(total)end
    rows[i]={base=base[i],gear=gear[i],talent=total-subtotal,total=total}
    if i==1 then rows[i].gear=math.floor(subtotal)-base[i];rows[i].talent=total-math.floor(subtotal)end
    -- Armor's 60% ceiling can also truncate equipment; display effective gains.
    if i==3 then rows[i].gear=math.min(gear[i],60-base[i]);rows[i].talent=total-base[i]-rows[i].gear end
  end
  return rows
end
function P.Stats(pet)
  local r=P.StatBreakdown(pet);return r[1].total,r[2].total,r[3].total,r[4].total
end
function P.HitChance(speed,targetSpeed)
  return math.max(75,math.min(97,92+math.floor((speed-targetSpeed)/3)))
end
P.enemySpells={
  poison={name="Venom",label="Poison",turns=3,power=0.18,help="Poison damage on the next 3 pet turns."},
  burn={name="Firebolt",label="Burn",turns=2,power=0.28,help="Burn damage on the next 2 pet turns."},
  freeze={name="Frost Nova",label="Frozen",turns=1,help="Stops the next offensive action. Healing and guarding remain available."},
  slow={name="Crippling Hex",label="Slowed",turns=3,help="35% slower attacks and turn speed for 3 pet turns."},
}
function P.StatusText(b)
  local labels={}
  for _,key in ipairs({"poison","burn","freeze","slow","stun"})do
    local effect=b and b.effects and b.effects[key]
    if effect then labels[#labels+1]=P.enemySpells[key].label.." "..effect.turns end
  end
  return #labels>0 and table.concat(labels," / ") or "No harmful effects"
end
function P.Unlocked()
  local pet=P.Active();return math.min(100,pet and pet.best+1 or 1)
end
function P.FloorStatus(floor)
  local pet=P.Active()
  return pet and floor<=pet.best and "Completed" or floor<=P.Unlocked() and "Not cleared" or "Locked"
end
function P.CurrentVictory()
  local pet=P.Active();local result=P.victory
  if result and pet and result.petID==pet.id and result.floor==(P.floor or 1) and not P.state.battle then return result end
end
P.towerRandom=math.random -- Independent from combat/loot rolls.
function P.EnsureTowerSeed(pet)
  if not integer(pet.towerSeed,1,1000000000)then pet.towerSeed=P.towerRandom(1,1000000000)end
  return pet.towerSeed
end
local rareCache=setmetatable({},{__mode="k"})
function P.RareFloors(pet)
  if not pet then return {} end
  local seed=P.EnsureTowerSeed(pet);local cached=rareCache[pet]
  if cached and cached.seed==seed then return cached.floors end
  local result={};rareCache[pet]={seed=seed,floors=result}
  -- One encounter in each quarter; no collision with the ten regular elites.
  for _,range in ipairs({{6,24},{26,49},{51,74},{76,99}})do
    local pool={};for floor=range[1],range[2]do if floor%10~=0 then pool[#pool+1]=floor end end
    seed=(seed*48271)%2147483647
    result[pool[seed%#pool+1]]=true
  end
  return result
end
function P.TowerXP(floor,first)
  -- Normal-tower training is 50% faster; equal-level wins still award less
  -- than a whole level. Replays pay 60% without repeating first-clear loot.
  return math.max(1,math.floor((18+floor*3)*(first and 1 or 0.6)))
end
-- Conditional weights after the 30% normal-tower gear roll. These give
-- 1% Epic at 40-49, 3% at 50-60, and 15/10/5% Rare/Epic/Legendary at 61+.
-- Lower brackets retain their previous rates; world loot is separate.
local towerGearWeights={
  early={low=2,high=4,total=90,[2]=58,[3]=29,[4]=3},
  middle={low=3,high=4,total=10,[3]=9,[4]=1},
  late={low=3,high=5,total=6,[3]=3,[4]=2,[5]=1},
}
function P.RollTowerGearRarity(floor)
  local weights=floor>=61 and towerGearWeights.late or floor>=50 and floor<=60 and towerGearWeights.middle
    or floor>=40 and floor<=49 and towerGearWeights.early
  if not weights then return P.RollGearRarity(math.min(63,floor))end
  local roll=P.random(1,weights.total)
  for rarity=weights.low,weights.high do
    roll=roll-weights[rarity]
    if roll<=0 then return math.min(weights.high,P.UpgradeRarity(rarity))end
  end
end
function P.TowerLoot(b,first)
  if not first then return end
  local rare=b.enemies[1].rare
  local crate=rare and (b.floor<=30 and 3 or 4) or (b.floor%10==0 and P.random(1,100)<=20 and (b.floor<=30 and 3 or 4))
  if crate then P.QueueCrate(crate,"Tower floor "..b.floor)end
  if (rare or b.floor%10==0) and P.random(1,100)<=30 then
    local rarity=P.RollTowerGearRarity(b.floor);local kind=P.RollGearKind(rarity)
    local ok=P.GrantGear(kind,rarity,"Tower floor "..b.floor)
    if not ok then P.QueueTowerGear(kind,rarity,b.floor)end
  end
end
function P.Enemies(floor,petLevel)
  if not integer(floor,1,100)then return end
  local count=floor<=33 and 1 or floor<=66 and 2 or 3
  local result={};local boss=floor%10==0
  -- Elite floors are a deliberate difficulty spike. Their leader holds most
  -- of the budget; extra enemies remain a split budget, never a multiplier.
  local pet=P.state and P.Active()
  petLevel=petLevel or (pet and pet.level) or floor
  -- Keep two levels of advantage, then match 80% of the excess. This is
  -- snapshotted at battle start; XP gained mid-fight cannot change enemies.
  local level=floor+math.floor(math.max(0,petLevel-floor-2)*0.8)
  local rare=P.RareFloors(pet)[floor]
  local totalHP=(42+level*8)*(1+(floor-1)*0.006)*(boss and 1.55 or 1)*(1+(count-1)*0.1)
  local totalAttack=(5+level*1.8)*(1+(floor-1)*0.0015)*(boss and 1.25 or 1)
  local healthBudget,assignedHP=0,0
  for i=1,count do
    local elite=(boss or rare) and i==1
    local hpShare,attackShare=1/count,1/count
    if boss and count>1 then
      local leaderHP=count==2 and 0.65 or 0.55
      local leaderAttack=count==2 and 0.6 or 0.5
      hpShare=i==1 and leaderHP or (1-leaderHP)/(count-1)
      attackShare=i==1 and leaderAttack or (1-leaderAttack)/(count-1)
    end
    healthBudget=healthBudget+math.floor(totalHP*hpShare*(rare and i==1 and 3 or 1))
    -- Vary targets without increasing the encounter's health budget. Stable
    -- floor-based shares keep previews and retries consistent; leaders retain
    -- their existing boss/rare health, while their two guards differ in size.
    if count>1 then
      if not boss and not rare then
        local weights=count==2 and {.75,1.25} or {.7,1,1.3}
        hpShare=weights[1+(i-1+floor)%count]/count
      elseif count==3 and i>1 then
        hpShare=hpShare*((i+floor)%2==0 and .75 or 1.25)
      end
    end
    local spell=floor>=5 and ({"poison","burn","freeze","slow","stun"})[(floor-5+i-1)%4+1] or nil
    result[i]={floor=floor,combatLevel=level,maxHP=math.floor(totalHP*hpShare*(rare and i==1 and 3 or 1)),attack=math.max(1,math.floor(totalAttack*attackShare*(rare and i==1 and 1.15 or 1))),
      armor=math.floor(level/12)+(elite and 3 or 0),speed=7+math.floor(level/10)+(i-1)*3,boss=boss and i==1,elite=elite,rare=rare and i==1,
      spell=spell,spellEvery=elite and 4 or 5,
      species=boss and i==1 and 85+(math.floor(floor/10)-1)%16 or (D.rescuePool and D.rescuePool[1+(floor*7+i*13)%#D.rescuePool] or 1+(floor*7+i*13)%84),index=i}
    assignedHP=assignedHP+result[i].maxHP
  end
  result[count].maxHP=result[count].maxHP+healthBudget-assignedHP
  return result
end
function P.Enemy(floor)local enemies=P.Enemies(floor);return enemies and enemies[1]end
P.towerEntryEnergy=9
function P.BattleReadiness(floor)
  if P.state.trade then return false,"Finish or safely cancel your pending trade before entering the tower.","Finish pending trade"end
  local pet=P.Active()
  if not pet or not integer(floor,1,100) then return false,"Equip a living pet and select a floor from 1 to 100.","Equip a living pet" end
  if P.state.battle then return false,"A battle is already active.",P.state.battle.paused and "Battle paused" or "Battle in progress" end
  if floor>P.Unlocked()then return false,"Clear the previous floor first.","Clear the previous floor first" end
  local needs,help={},{}
  for _,rule in ipairs({{"health",40,"Health","Use herbs to heal"},{"energy",P.towerEntryEnergy,"Energy","Rest in Camp"},{"food",15,"Food","Feed your pet"}})do
    if (rule[1]=="energy" and P.EnergyPoints(pet) or pet[rule[1]])<rule[2] then
      needs[#needs+1]=rule[3].." "..math.floor(rule[1]=="energy" and P.EnergyPoints(pet) or pet[rule[1]]).."/"..rule[2]
      help[#help+1]=rule[4]
    end
  end
  if #needs>0 then
    local summary="Need: "..table.concat(needs," | ")
    return false,summary..". "..table.concat(help,"; ").." before fighting.",summary
  end
  return true,"Ready. Starting a fight costs "..P.towerEntryEnergy.." energy and 5 food. Defeat is permanent.","Ready to fight"
end
function P.StartBattle(floor)
  if P.state.trade then return false,"Finish or safely cancel your pending trade before entering the tower."end
  if P.Active()then P.EnsureAbilities(P.Active())end
  local ready,message=P.BattleReadiness(floor)
  if not ready then return false,message end
  local pet=P.Active();local enemies=P.Enemies(floor)
  local hp,attack,armor,speed=P.Stats(pet)
  pet.energy=pet.energy-P.towerEntryEnergy*100/P.MaxEnergy();pet.food=clamp(pet.food-5*(1-P.TalentBonus("foodSavings")));pet.resting=false
  for _,enemy in ipairs(enemies)do enemy.hp=enemy.maxHP end
  P.state.battle={petID=pet.id,enemies=enemies,enemy=enemies[1],floor=floor,hp=math.ceil(hp*pet.health/100),
    maxHP=hp,attack=attack,armor=armor,speed=speed,statBreakdown=P.StatBreakdown(pet),turn=0,cooldown=0,elapsed=0,paused=false,effects={},attackProgress=0}
  P.lastRound=nil;P.victory=nil;P.defeat=nil;P.floor=floor
  P.notice="Floor "..floor..(enemies[1].elite and " ELITE" or "")..": 1 versus "..#enemies..". Auto battle - defeat is permanent."
  return true
end
local function damage(power,armor)return math.max(1,math.floor(power*(1-armor/100)))end
function P.BattleAction(action,instant)
  local s=P.state;local b=s.battle;local pet=P.Active()
  if not b or not pet or pet.id~=b.petID then return false,"No active battle." end
  if action=="heal"then return P.RequestHeal()end
  if action=="retreat" then s.battle=nil;P.lastRound=nil;P.notice="Retreated safely. Spent supplies and lost health remain.";return true end
  if action~="strike" and action~="guard" and action~="burst" then return false,"Unknown action." end
  local ability=b.healAbility or b.nextAbility or P.ChooseAbility(pet,false) or P.Ability(pet)
  b.healAbility=nil;b.nextAbility=nil
  if action=="burst" and instant then return false,"Special abilities use this pet's next turn."end
  if action=="burst" and (not ability or P.SpecialCooldown(b,ability)>0)then return false,ability and "Ability is cooling down." or "Special abilities require Rare quality or higher." end
  local round={at=P.sceneClock or 0,action=action,enemy=b.enemy,enemies=b.enemies,pet=pet,events={},maxHP=b.maxHP,hit=0,heal=0,hurt=0}
  round.start={hp=b.hp,enemyHP={},effects={}}
  for key,e in pairs(b.effects or {})do round.start.effects[key]=e.turns end
  for i,e in ipairs(b.enemies)do round.start.enemyHP[i]=e.hp end
  local priorRound=P.lastRound
  P.lastRound=round;if not instant then P.TickSpecialCooldowns(b)end
  b.effects=b.effects or {}
  local gearEffects=P.GearEffects and P.GearEffects(pet) or {}
  local actors={{player=true,speed=P.CombatSpeed(b)*(b.effects.slow and 0.65 or 1)}}
  if not instant then for i,e in ipairs(b.enemies)do if e.hp>0 then actors[#actors+1]={index=i,speed=P.CombatSpeed(e)}end end end
  table.sort(actors,function(a,c)if a.speed==c.speed then return (a.index or 0)<(c.index or 0)end;return a.speed>c.speed end)
  local shield=b.shield or false
  local function record(actor,label,amount,target,missed,kind)
    local event={actor=actor,label=label,amount=amount,target=target,missed=missed,kind=kind,hp=b.hp,enemyHP={},effects={}}
    for key,e in pairs(b.effects or {})do event.effects[key]=e.turns end
    for i,e in ipairs(b.enemies)do
      event.enemyHP[i]=e.hp
      if e.hp<=0 and not e.defeatedAt then e.defeatedAt=round.at+#round.events*(P.eventDuration or 0.55)+(P.impactDelay or 0.2) end
    end
    round.events[#round.events+1]=event
  end
  local function landed(speed,targetSpeed,bonus)return P.random(1,100)<=math.min(99,P.HitChance(speed,targetSpeed)+(bonus or 0))end
  local function emit(source,label,amount,target,kind,missed)
    local sourceID=type(source)=='number'and source or source==b and 0 or source.index
    record(sourceID,label,amount,target==b and 0 or target.index,missed,kind)
    if kind=='heal'then round.heal=round.heal+amount end
  end
  for _,actor in ipairs(actors)do
    if b.hp<=0 then break end
    if actor.player then
      if not instant then P.BeginAbilityAction(b,emit);b.shield=nil;shield=false end
      local target=P.HardMode and P.HardMode.TargetEnemy(b.enemies)
      if not target then for _,e in ipairs(b.enemies)do if e.hp>0 then target=e;break end end end
      if not target then break end
      local stunned=b.effects.stun~=nil
      local frozen,slowed=b.effects.freeze~=nil,b.effects.slow~=nil
      for _,key in ipairs(instant and {} or {"poison","burn","freeze","slow","stun"})do
        local effect=b.effects[key]
        if effect then
          if effect.damage then
            local hurt=math.min(b.hp,math.max(1,math.floor(effect.damage*(1-P.TalentBonus("resistance")))));b.hp=b.hp-hurt;round.hurt=round.hurt+hurt
            record(effect.source,P.enemySpells[key].label.." tick",hurt)
          end
          effect.turns=effect.turns-1;if effect.turns<=0 then b.effects[key]=nil end
          if b.hp<=0 then break end
        end
      end
      if b.hp<=0 then break end
      if not instant and gearEffects.renewal and (b.turn+1)%5==0 and b.hp<b.maxHP then
        local restored=math.min(b.maxHP-b.hp,math.floor(b.maxHP*0.02));b.hp=b.hp+restored;round.heal=round.heal+restored
        if restored>0 then record(0,"Renewal",restored)end
      end
      local offensive=action=="strike" or (action=="burst" and not P.IsHealingAbility(ability))
      local delayed=false
      if slowed and not instant then
        b.attackProgress=(b.attackProgress or 0)+0.65
        if b.attackProgress<1 then delayed=true else b.attackProgress=b.attackProgress-1 end
      end
      if stunned or offensive and (frozen or delayed) then
        if b.manualSpecialAttempt then b.queuedSpecial=b.manualSpecialAttempt;b.manualSpecialAttempt=nil end
        record(0,stunned and "Stunned" or frozen and "Frozen - attack skipped" or "Slowed - winding up",0)
      elseif action=="guard" then record(0,"Guard",0)
      elseif action=='burst'and ability.reworked then
        local dealt=P.ResolveSpecialAbility(b,ability,b.enemies,{b},target,b.turn,emit,gearEffects)
        round.hit=round.hit+dealt;shield=b.shield or false;P.StartSpecialCooldown(b,ability);b.manualSpecialAttempt=nil
      else
        local effect=action=="burst" and ability.effect or "strike"
        local power=P.CombatAttack(b)*(0.9+P.random(0,20)/100)
        local multiplier=action=="burst" and ability.power or effect=="bite" and 1.8 or effect=="flurry" and 1.65 or effect=="cleave" and 0.9 or effect=="renew" and 0.8 or effect=="drain" and 1.1 or 1
        local critical=gearEffects.critical and P.random(1,100)<=5
        if critical then power=power*1.25 end
        local hit,actualHit=0,0
        for _,e in ipairs(b.enemies)do
          if e.hp>0 and (e==target or effect=="cleave")then
            local success=landed(actor.speed,e.speed,gearEffects.precision and 2 or 0)
            local amount=success and P.AbsorbAbilityDamage(e,damage(power*multiplier,P.CombatArmor(e)),b,emit) or 0
            actualHit=actualHit+math.min(e.hp,amount)
            e.hp=math.max(0,e.hp-amount);hit=hit+amount
            if success and action=="burst" and ability.control then P.ApplyControl(e,ability,b.turn)end
            record(0,success and ((action=="burst" and ability.ability or "Strike")..(critical and " (critical)" or "")) or "Miss",amount,e.index,not success)
          end
        end
        round.hit=hit
        if gearEffects.leech and actualHit>0 and b.hp<b.maxHP then
          local amount=math.min(actualHit*0.03,b.maxHP*0.03)+(b.leechRemainder or 0)
          local heal=math.min(b.maxHP-b.hp,math.floor(b.maxHP*0.03),math.floor(amount));b.leechRemainder=amount-math.floor(amount)
          b.hp=b.hp+heal;round.heal=round.heal+heal;if heal>0 then record(0,"Leech",heal)end
        end
        if effect=="renew" or effect=="drain" then
          local before=b.hp;b.hp=math.min(b.maxHP,b.hp+math.floor(effect=="renew" and b.maxHP*(ability.healing or 0.18) or actualHit*(ability.healing or 0.6)))
          round.heal=b.hp-before;if round.heal>0 then record(0,"Ability heal",round.heal)end
        end
        shield=effect=="shield" and (ability.reduction or .55)
        if action=="burst" then P.StartSpecialCooldown(b,ability);b.manualSpecialAttempt=nil end
      end
    else
      local e=b.enemies[actor.index]
      if e.hp>0 then P.BeginAbilityAction(e,emit)end
      if e.hp>0 then
        if P.ControlBlocked and P.ControlBlocked(e,b.turn)then record(actor.index,"Controlled - action skipped",0)else
        local heavy=(b.turn+1)%3==0
        local casting=e.spell and (b.turn+e.index)%e.spellEvery==0
        local spell=casting and P.enemySpells[e.spell]
        local success=landed(P.CombatSpeed(e),P.CombatSpeed(b)*(b.effects.slow and 0.65 or 1))
        if not success then record(actor.index,spell and spell.name.." missed" or "Miss",0,nil,true)
        else
          local mitigation=action=="guard" and 0.25 or shield and (1-shield) or 1
          local hit=damage(P.CombatAttack(e)*(spell and 0.65 or heavy and (e.elite and 1.85 or 1.6) or 1)*mitigation,P.CombatArmor(b))
          local ward=gearEffects.ward and P.random(1,100)<=8
          if ward then hit=math.max(1,math.floor(hit*0.75))end
          hit=P.AbsorbAbilityDamage(b,hit,e,emit);b.hp=math.max(0,b.hp-hit);round.hurt=round.hurt+hit
          if spell and b.hp>0 and action~="guard" then
            -- Refresh, never stack the same effect across multiple enemies.
            local prior=b.effects[e.spell]
            local dot=spell.power and damage(e.attack*spell.power,b.armor)
            b.effects[e.spell]={turns=spell.turns,source=e.index,damage=dot and math.max(dot,prior and prior.damage or 0)}
          end
          record(actor.index,spell and (spell.name..(action=="guard" and " (effect blocked)" or "")) or heavy and (e.elite and "Elite heavy attack" or "Heavy attack") or "Attack",hit)
          if ward then record(0,"Guardian Ward",0)end
        end
        end
      end
    end
    if not instant then P.EndAbilityAction(actor.player and b or b.enemies[actor.index])end
  end
  if not instant then b.guardStreak=action=="guard" and (b.guardStreak or 0)+1 or 0;b.turn=b.turn+1 end
  pet.health=clamp(b.hp/b.maxHP*100)
  round.duration=math.max(1.6,#round.events*(P.eventDuration or 0.55)+0.3)
  if b.hp<=0 then P.Die(pet,"Tower floor "..b.floor);return true end
  local living=0;for _,e in ipairs(b.enemies)do if e.hp>0 then living=living+1;if living==1 then b.enemy=e end end end
  if living==0 and not b.rewarded then
    b.rewarded=true
    local first=b.floor>pet.best;pet.best=math.max(pet.best,b.floor);pet.wins=pet.wins+1
    if F.Achievements then F.Achievements.TowerWin(pet,b,first)end
    local priorLevel=pet.level
    local xp=P.AddXP(pet,P.TowerXP(b.floor,first),"tower")
    if pet.level>priorLevel then
      round.final={};for key,value in pairs(round.events[#round.events] or round.start)do round.final[key]=value end
      round.final.hp=b.hp;round.final.maxHP=b.maxHP
    end
    -- First clears are the main income; repeat farming gives only one token.
    local reward=first and (12+math.floor(b.floor/5)+(b.enemies[1].rare and 20 or b.floor%10==0 and 10 or 0)) or 1
    local treat=first and P.random(1,100)<=10 and 1 or 0
    treat=P.AddSupply("food",treat)
    local herbs=first and P.random(1,100)<=15 and P.AddSupply("medicine",1) or 0
    reward=P.AwardTokens(reward,"towerTokens");s.battle=nil
    P.TowerLoot(b,first)
    -- Publish the one XP receipt at the last hit, not before the finishing animation.
    local receipt=P.progressEvents[pet.id]
    if xp>0 and receipt then receipt.at=(GetTime and GetTime() or F.Now())+math.max(0,round.duration-((P.sceneClock or 0)-round.at));receipt.source="tower" end
    P.victory={petID=pet.id,floor=b.floor,first=first,xp=xp,tokens=reward,treats=treat,herbs=herbs,loot=b.presentationLoot,round=round,readyAt=round.at+round.duration}
    P.notice="Floor "..b.floor.." cleared! +"..reward.." tokens. "..(treat>0 and "+1 food! " or "")..(pet.best==100 and "Tower conquered!" or first and "Next floor unlocked." or "Repeat clear.")
  else
    if instant then
      local losses={};for i,e in ipairs(b.enemies)do losses[i]=round.start.enemyHP[i]-e.hp end
      P.AdjustHealingSnapshots(priorRound,round.heal,b.maxHP,losses);P.lastRound=priorRound
    end
    P.notice=instant and (ability.ability..": +"..round.heal.." HP.") or ("Round "..b.turn.." - "..living.." enemies remaining. "..((b.turn+1)%3==0 and "Heavy attacks next round." or "Fighting automatically."))
  end
  if instant then P.RecordInstantHeal(pet,round.heal)end
  return true
end
function P.AdvanceBattle(dt,visible)
  local b=P.state and P.state.battle
  if not b or b.paused or not visible then return end
  b.elapsed=(b.elapsed or 0)+math.min(dt,0.25)
  if b.elapsed<(P.lastRound and P.lastRound.duration or 1.6)then return end
  b.elapsed=0
  local action=P.AutoAction(b,P.Active())
  P.BattleAction(action);if P.Render then P.Render()end
end

-- Rewards use a successful encounter pair or the client's BOSS_KILL event.
-- Arbitrary elite kills and other players' addon messages are not boss evidence.
local function instance()
  if not GetInstanceInfo then return end
  local ok,_,kind,_,_,_,_,_,id=pcall(GetInstanceInfo)
  if ok and readable(kind) and readable(id) and (kind=="party" or kind=="raid") and integer(id,1,100000)then return kind,id end
end
function P.EncounterStart(id,name)
  P.encounter=nil
  if not P.state or not readable(id) or not integer(id,1,100000) then return end
  local kind,map=instance();if not kind then return end
  if not readable(name) or type(name)~="string" or #name>120 then name=nil end
  P.encounter={id=id,name=name,kind=kind,map=map}
end
local function bossReward(id,name,kind,map)
  if F.Achievements and F.Achievements.DungeonBoss then F.Achievements.DungeonBoss(id,name,kind,map)end
  local now=F.Now();local key=map..":"..id;local claims=P.state.bossClaims
  local cooldown=kind=="raid" and 604800 or 86400
  if claims[key] and now-claims[key]<cooldown then return end
  for claim,when in pairs(claims)do if now-when>=604800 then claims[claim]=nil end end
  claims[key]=now
  if kind=="party" then
    P.ChangeTokens(math.min(P.maxTokens-P.state.tokens,3),"BOSS",tostring(id or 0))
    P.notice="Dungeon boss defeated: +3 pet tokens."
    if P.random(1,100)<=20 then
      local ok,item=P.GrantCrate(2)
      if ok then
        P.notice=P.notice..(P.CrateItem(item.id) and " Crate added to your bag; right-click to open." or " Crate sent to Mail; make room in your bag to collect it.")
      else
        P.state.pendingCrates=math.min(100,P.state.pendingCrates+1)
        P.notice=P.notice.." Bag full: claim your waiting crate in Equipment."
        P.Reward("crate_found","Dungeon crate waiting!",D.packs[2].name.."\nBag full: claim it in Equipment.","INV_Crate_01",nil,2)
      end
    end
  else
    P.ChangeTokens(math.min(P.maxTokens-P.state.tokens,10),"BOSS",tostring(id or 0))
    local species=name and D.bosses[name]
    if species and P.random(1,100)<=5 then
      P.state.bossEggs[species]=(P.state.bossEggs[species] or 0)+1
      if P.Reward then P.Reward("item","Raid companion found!",P.species[species],"INV_Egg_02",species,4)end
      P.notice=name.." companion earned! Claim it in Adopt. +10 tokens."
    else P.notice="Raid boss defeated: +10 pet tokens." end
  end
  if P.Render then P.Render()end
end
function P.EncounterEnd(id,name,success)
  local e=P.encounter;P.encounter=nil
  if not e or not readable(id) or not readable(success) or success~=1 or id~=e.id then return end
  local kind,map=instance();if kind~=e.kind or map~=e.map then return end
  -- Names are optional labels, not a reason to lose a verified boss reward.
  if not readable(name) or type(name)~="string" or #name>120 then name=e.name end
  bossReward(id,name,kind,map)
end
function P.BossKill(id,name)
  if not P.state or not readable(id) or not integer(id,1,100000)then return end
  local kind,map=instance();if not kind then return end
  if not readable(name) or type(name)~="string" or #name>120 then name=nil end
  -- The saved map/encounter claim deduplicates BOSS_KILL and ENCOUNTER_END,
  -- whichever arrives first, including after reload and failed reward rolls.
  bossReward(id,name,kind,map)
end
local events=CreateFrame("Frame");P.encounterEvents=events
events:RegisterEvent("ENCOUNTER_START");events:RegisterEvent("ENCOUNTER_END");events:RegisterEvent("BOSS_KILL")
events:SetScript("OnEvent",function(frame,event,id,name,difficulty,groupSize,success)
  if event=="ENCOUNTER_START" then P.EncounterStart(id,name)
  elseif event=="BOSS_KILL"then P.BossKill(id,name)
  else P.EncounterEnd(id,name,success)end
end)
