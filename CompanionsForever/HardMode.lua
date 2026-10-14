local _,F=...
local P=F.Pets
local H={version=1,sets={},kinds={},Normal={}};P.HardMode=H
for _,name in ipairs({"Init","Unlocked","FloorStatus","BattleReadiness","StartBattle","BattleAction","AdvanceBattle","Tick","OpenPage","Enemies","TowerXP","TowerLoot","HealChoice","RequestHeal","UseCare","CycleStyle","CurrentVictory","Select","AddXP","AbilityHelp"})do H.Normal[name]=P[name]end
local function whole(n,lo,hi)return type(n)=="number" and n==math.floor(n) and n>=lo and n<=hi end
local function find(id)for _,pet in ipairs(P.state.pets)do if pet.id==id then return pet end end end
local function lab()return P.state.hardMode end
-- Stable, append-only item IDs. Ordinary loot excludes hard-mode sets.
local baseGearCount=#P.gearTypes
H.sets={
  {name="Emberguard",two="+3 armor",four="Guardian Ward + Renewal",icons={"INV_Sword_04","INV_Helmet_09","INV_Chest_Chain_04","INV_Jewelry_Necklace_04","INV_Misc_Gem_Ruby_02"}},
  {name="Thornweaver",two="+5% attack",four="Leech: heal 3% of actual attack damage",icons={"INV_Misc_MonsterFang_02","INV_Helmet_03","INV_Chest_Leather_01","INV_Jewelry_Necklace_01","INV_Misc_Gem_Emerald_02"}},
  {name="Duskwalker",two="+2 speed",four="Keen Strikes + True Aim",icons={"INV_Weapon_ShortBlade_01","INV_Helmet_15","INV_Chest_Leather_03","INV_Jewelry_Necklace_03","INV_Misc_Gem_Sapphire_02"}},
}
for set,definition in ipairs(H.sets)do
  H.kinds[set]={}
  for i,slot in ipairs(P.gearSlots)do
    local kind=#P.gearTypes+1;H.kinds[set][i]=kind
    P.gearTypes[kind]={name=definition.name.." "..P.gearSlotNames[slot],slot=slot,icon=definition.icons[i],hardSet=set,petXP=20,minRarity=4,
      hp=slot=="body" and 32 or slot=="head" and 16 or 6,attack=slot=="weapon" and 12 or 3,armor=slot=="body" and 1.5 or slot=="head" and .5 or nil}
  end
end
H.tierKinds={[1]=H.kinds}
for tier=2,3 do
  H.tierKinds[tier]={}
  for set,definition in ipairs(H.sets)do
    H.tierKinds[tier][set]={}
    for i,slot in ipairs(P.gearSlots)do
      local kind=#P.gearTypes+1;H.tierKinds[tier][set][i]=kind
      P.gearTypes[kind]={name=(tier==2 and "Ascendant " or "Mythic ")..definition.name.." "..P.gearSlotNames[slot],slot=slot,icon=definition.icons[i],hardSet=set,hardTier=tier,petXP=tier==2 and 35 or 50,minRarity=4,
        hp=(slot=="body" and 50 or slot=="head" and 25 or 10)*(tier==3 and 1.8 or 1.08),
        attack=(slot=="weapon" and 20 or 5)*(tier==3 and 2 or 1.08),armor=(slot=="body" and 2 or slot=="head" and 1 or 0)*(tier==3 and 1.5 or 1)}
    end
  end
end
-- Append new families after all 45 original pieces; saved kind IDs never move.
H.sets[4]={name="Lifebloom",two="+5% maximum health",four="Renewal + Leech",icons={"INV_Staff_13","INV_Helmet_09","INV_Chest_Leather_01","INV_Jewelry_Necklace_01","INV_Misc_Gem_Emerald_02"}}
H.sets[5]={name="Stormfang",two="+3% attack and +1 speed",four="Keen Strikes + Guardian Ward",icons={"INV_Sword_04","INV_Helmet_15","INV_Chest_Chain_04","INV_Jewelry_Necklace_04","INV_Misc_Gem_Sapphire_02"}}
P.hardGearCatalog=true
for tier=1,3 do
  for set=4,#H.sets do
    H.tierKinds[tier][set]={}
    for i,slot in ipairs(P.gearSlots)do
      local original=P.gearTypes[H.tierKinds[tier][1][i]];local d={}
      for key,value in pairs(original)do d[key]=value end
      d.name=(tier==2 and "Ascendant " or tier==3 and "Mythic " or "")..H.sets[set].name.." "..P.gearSlotNames[slot]
      d.hardSet=set;d.hardTier=tier;d.icon=H.sets[set].icons[i];d.expandedHardGear=true
      local kind=#P.gearTypes+1;P.gearTypes[kind]=d;H.tierKinds[tier][set][i]=kind
    end
  end
end
-- Twenty standalone Legendaries: 20 budget points versus normal gear's 16.
-- No set bonus or XP bonus; these stay out of ordinary world/crate loot pools.
H.nonSetKinds={}
local standalone={
  weapon={{"Spirebreaker Blade",4,4,0,0},{"Galeclaw Talon",0,4,0,1},{"Ironbark Maul",0,4,1,0},{"Bloodstone Fang",8,3,0,0}},
  head={{"Sentinel's Crown",12,0,1,1},{"Ravager's Visor",12,2,0,0},{"Granite Greathelm",8,0,3,0},{"Windhunter's Hood",8,2,0,1}},
  body={{"Colossus Breastplate",16,0,1,0},{"Bastion Carapace",12,0,2,0},{"Predator's Harness",12,2,0,0},{"Cloudrunner Vest",12,0,0,2}},
  collar={{"Titan's Choker",12,0,2,0},{"Razorwind Chain",4,3,0,1},{"Lifewarden Pendant",16,0,0,1},{"Stormsteel Torque",4,2,2,0}},
  trinket={{"Heart of the Spire",20,0,0,0},{"Tempest Stone",4,2,0,2},{"Aegis Idol",4,0,3,1},{"Fang of Conquest",4,4,0,0}},
}
local standaloneEffects={
  ["Bloodstone Fang"]="leech",["Windhunter's Hood"]="precision",["Bastion Carapace"]="ward",
  ["Lifewarden Pendant"]="renewal",["Fang of Conquest"]="critical",
}
for i,slot in ipairs(P.gearSlots)do
  for _,row in ipairs(standalone[slot])do
    local d={name=row[1],slot=slot,icon=H.sets[1].icons[i],hardTier=1,hardNonSet=true,expandedHardGear=true,minRarity=5}
    d.effect=standaloneEffects[row[1]]
    for j,key in ipairs({"hp","attack","armor","speed"})do if row[j+1]>0 then d[key]=row[j+1]end end
    local kind=#P.gearTypes+1;P.gearTypes[kind]=d;H.nonSetKinds[#H.nonSetKinds+1]=kind
  end
end
function P.RollGearKind(rarity)
  local normal,special={},{}
  for i=1,baseGearCount do local d=P.gearTypes[i]
    if not d.effect then normal[#normal+1]=i elseif rarity>=3 then special[#special+1]=i end
  end
  local pool=#special>0 and P.random(1,10000)<=100 and special or normal
  return pool[P.random(1,#pool)]
end
function H.Counts(pet)
  local counts={};for i=1,#H.sets do counts[i]=0 end;if not pet then return counts end
  for _,slot in ipairs(P.gearSlots)do local item=pet.gear and P.GearItem(pet.gear[slot]);local d=item and P.gearTypes[item.kind]
    if d and d.hardSet then counts[d.hardSet]=counts[d.hardSet]+1 end
  end;return counts
end
function H.XPBonus(pet)
  local percent=0
  for _,slot in ipairs(P.gearSlots)do
    local item=pet and pet.gear and P.GearItem(pet.gear[slot]);local d=item and P.gearTypes[item.kind]
    if d and d.hardSet and d.slot==slot then percent=percent+d.petXP end
  end
  return percent
end
local breakdown=P.StatBreakdown
function P.StatBreakdown(pet)
  local rows=breakdown(pet);local c=H.Counts(pet)
  -- Health stays in whole points, including the set bonus applied after talents.
  local bonuses={c[4]>=2 and math.floor(rows[1].total/20) or 0,rows[2].total*((c[2]>=2 and .05 or 0)+(c[5]>=2 and .03 or 0)),c[1]>=2 and math.min(3,60-rows[3].total) or 0,(c[3]>=2 and 2 or 0)+(c[5]>=2 and 1 or 0)}
  for i,v in ipairs(bonuses)do rows[i].gear=rows[i].gear+v;rows[i].total=rows[i].total+v end
  return rows
end
local gearEffects=P.GearEffects
function P.GearEffects(pet)
  local effects=gearEffects(pet);local c=H.Counts(pet)
  if c[1]>=4 then effects.ward=true;effects.renewal=true end
  if c[2]>=4 then effects.leech=true end
  if c[3]>=4 then effects.critical=true;effects.precision=true end
  if c[4]>=4 then effects.renewal=true;effects.leech=true end
  if c[5]>=4 then effects.critical=true;effects.ward=true end
  return effects
end
local description=P.GearDescription
function P.GearDescription(item)
  local result=description(item);local d=P.gearTypes[item.kind]
  if d.hardSet then
    result=result.."\n|cff33ff66+"..d.petXP.."% pet XP while equipped (any pet level)|r"
    local def=H.sets[d.hardSet];local c=H.Counts(P.GearOwner(item.id) or P.Active())[d.hardSet]
    result=result.."\n|cffc78cffHard-mode exclusive - Tier "..(d.hardTier or 1).."|r\nDrops on floors "..((d.hardTier or 1)==1 and "26-50" or d.hardTier==2 and "51-75" or "76-100").."\n"..def.name.." ("..c.."/5)\n"..(c>=2 and "|cff33ff66" or "|cff999999").."2 pieces: "..def.two.."|r\n"..(c>=4 and "|cff33ff66" or "|cff999999").."4 pieces: "..def.four.."|r"
  elseif d.hardNonSet then
    result=result.."\n|cffff8000Hard-mode Tier 1 Legendary - Non-set|r\nDrops on floors 26-50. No set bonus."
  end;return result
end

function H.IsHard()return P.state and P.state.hardMode and P.state.hardMode.mode=="hard"end
function H.IsUnlocked()
  local s=P.state;if not s then return false end
  if s.hardMode and s.hardMode.unlocked then return true end
  if s.achievements and (s.achievements.tower or 0)>=100 then return true end
  for _,pet in ipairs(s.pets)do if pet.best>=100 then return true end end
  return false
end
function H.RefreshUnlock()
  local h=lab();if H.IsUnlocked()then h.unlocked=true end
  P.stableCapacity=h.unlocked and 16 or 9
end
function H.Initialize()
  local s=P.state;local old=type(s.hardMode)=="table" and s.hardMode or {}
  local h={version=1,unlocked=old.unlocked==true,best=whole(old.best,0,100) and old.best or 0,team={},target=old.target,editSlot=1,tactic=old.tactic,mode=old.mode=="hard" and "hard" or "normal",cleared={}}
  for floor,value in pairs(type(old.cleared)=="table" and old.cleared or {})do if whole(floor,1,100) and value==true then h.cleared[floor]=true end end
  -- Progress is sequential; a sparse or inconsistent ledger cannot skip floors.
  h.best=0;while h.best<100 and h.cleared[h.best+1]do h.best=h.best+1 end
  local seen={};for i=1,3 do local id=type(old.team)=="table" and old.team[i];if whole(id,1,1000000) and find(id) and not seen[id]then h.team[i]=id;seen[id]=true end end
  local spent=0;h.training={}
  for _,node in ipairs(H.trainingNodes)do
    local value=type(old.training)=="table" and old.training[node.key]
    value=whole(value,0,4) and math.min(value,H.trainingPointCap-spent) or 0
    h.training[node.key]=value;spent=spent+value
  end
  h.trainingPurchased=whole(old.trainingPurchased,spent,H.trainingPointCap) and old.trainingPurchased or spent
  h.trainingRevision=whole(old.trainingRevision,0,1000000000) and old.trainingRevision or 0
  h.jumpTokenProgress=whole(old.jumpTokenProgress,0,99) and old.jumpTokenProgress or 0
  h.jumpXPProgress=whole(old.jumpXPProgress,0,99) and old.jumpXPProgress or 0
  h.restXPSeconds=type(old.restXPSeconds)=="number" and old.restXPSeconds>=0 and old.restXPSeconds<120 and old.restXPSeconds or 0
  h.restXPPet=whole(old.restXPPet,1,1000000) and old.restXPPet or nil
  h.tokenCarry=whole(old.tokenCarry,0,99) and old.tokenCarry or 0
  h.encounterSeed=old.encounterSeed;s.hardMode=h;H.heals={};H.RefreshUnlock()
  if not h.unlocked then h.mode="normal"end
  if h.tactic~="lowest" and h.tactic~="highest" and h.tactic~="random"then h.tactic="order"end
  H.PrepareEncounters();P.floor=H.IsHard() and math.min(100,h.best+1) or H.Normal.Unlocked()
end
H.trainingCosts={400,800,1600,3200}
H.trainingPointCap=16
H.trainingRespecCost=500
H.trainingNodes={
 {key="worldXP",name="World XP",icon="Ability_Hunter_BeastTraining",amount=25,help="Your pet earns 25% more XP per rank from world and dungeon kills. Multiplies XP gear bonuses. The per-fight limit on base kill XP still applies."},
 {key="towerXP",name="Tower XP",icon="INV_Misc_Book_09",amount=10,help="Your pet earns 10% more XP per rank from the normal tower. Multiplies XP gear bonuses. Does not boost hard-tower or retirement XP."},
 {key="tokens",name="Token Finds",icon="INV_Misc_Coin_02",amount=5,help="Earn 5% more tokens per rank from eligible world and dungeon kills. Does not boost sales, crates, online income or tower rewards."},
 {key="rest",name="Quick Rest",icon="Spell_Nature_Sleep",amount=5,help="Resting pets regain energy 5% faster per rank. Works with city and racial bonuses. Does not speed up health recovery."},
 {key="vigor",name="Vigor",icon="Spell_Holy_WordFortitude",bonus="health",amount=.01,help="+1% maximum pet health per rank. Up to +4%."},
 {key="ferocity",name="Ferocity",icon="Ability_DualWield",bonus="attack",amount=.01,help="+1% pet attack per rank. Up to +4%."},
 {key="plating",name="Plating",icon="Spell_Nature_ResistNature",bonus="armor",amount=.5,help="+0.5 percentage points of pet armor per rank. Up to +2 points; the armor cap still applies."},
 {key="reflexes",name="Reflexes",icon="Ability_Rogue_Sprint",bonus="speed",amount=.01,help="+1% pet speed per rank. Up to +4%; affects turn order and hit chance."},
 {key="warding",name="Warding",icon="Spell_Holy_BlessingOfProtection",bonus="resistance",amount=.02,help="2% less poison and burn damage per rank. Up to 8%."},
 {key="medicine",name="Field Medicine",icon="INV_Misc_Herb_03",bonus="herbHealingBonus",amount=.025,help="Herbs heal 2.5% more per rank. Up to +10%; adds to regular healing talents."},
 {key="salvage",name="Salvage",icon="INV_Misc_Bag_08",bonus="gearDrop",amount=5,help="+0.05 percentage points to eligible equipment drops per rank. Up to +0.2 points."},
 {key="fortune",name="Fortune",icon="INV_Misc_Gem_Opal_01",bonus="rarity",amount=5,help="Per rank: +0.05 percentage points to a crate's top non-Mythic rarity; 0.05% chance to upgrade dropped loot one tier. Does not affect Sparkly or Mythic odds."},
 {key="pocketChange",name="Pocket Change",icon="INV_Misc_Coin_01",help="Earn a token by jumping. More ranks mean fewer jumps per token. Only actual jumps count; other token bonuses do not apply."},
 {key="hopAlong",name="Hop Along",icon="Ability_Mount_JungleTiger",help="Your equipped pet earns XP when you jump. More ranks mean fewer jumps per XP. Paused during pet battles or at the level cap. XP bonuses do not apply."},
 {key="daydream",name="Daydream",icon="Spell_Nature_Sleep",help="Your equipped pet earns XP while resting in a city or inn. More ranks shorten the wait. Requires at least 10 food, room to level up, and no pet battle. No offline XP or XP bonuses."},
}
function H.TrainingRank(key)local h=P.state and P.state.hardMode;return h and H.IsUnlocked() and h.training and h.training[key] or 0 end
local function trainingEffect(node,rank)
  if node.bonus then return P.TalentEffectText(node.bonus,rank*node.amount)end
  if node.key=="pocketChange" or node.key=="hopAlong" then
    if rank==0 then return "No reward yet"end
    return "1 "..(node.key=="pocketChange" and "token" or "pet XP").." every "..(120-rank*20).." jumps"
  end
  if node.key=="daydream" then return rank==0 and "No reward yet" or "1 pet XP every "..(140-rank*20).." seconds of eligible rest"end
  local names={worldXP="world/dungeon kill XP",towerXP="normal-tower XP",tokens="world/dungeon kill tokens",rest="resting energy recovery"}
  return "+"..(rank*node.amount).."% "..names[node.key]
end
function H.TrainingTooltip(node)
  local rank=H.TrainingRank(node.key)
  local description=({
    pocketChange="Jumping earns tokens.",
    hopAlong="Jumping gives your equipped pet XP.",
    daydream="Resting in a city or inn gives your fed pet XP.",
  })[node.key] or (trainingEffect(node,1).." per rank.")
  local current=trainingEffect(node,rank)
  if rank==0 and not node.amount then current="Not trained ("..trainingEffect(node,1).." at rank 1)"end
  return node.name.." ("..rank.."/4)\n"..description.."\nCurrent bonus: "..current.."."
end
function H.TrainingSpent()
  local total=0;for _,node in ipairs(H.trainingNodes)do total=total+H.TrainingRank(node.key)end;return total
end
function H.TrainingOwned()return math.min(H.trainingPointCap,math.max(H.TrainingSpent(),lab().trainingPurchased or 0))end
function H.TrainingPointCost()
  local owned=H.TrainingOwned()
  if owned>=H.trainingPointCap then return nil end
  return H.trainingCosts[math.floor(owned/4)+1]
end
function H.TrainingCost()
  if H.TrainingSpent()<H.TrainingOwned()then return 0 end
  return H.TrainingPointCost()
end
function H.BuyTrainingPoint(expected,revision)
  if H.buyingTraining then return false,"Training purchase already in progress."end
  if not H.IsUnlocked()then return false,"Clear normal floor 100 to unlock hard-mode training."end
  if P.state.battle then return false,"Finish your battle before training."end
  local h=lab();local owned=H.TrainingOwned();local cost=H.TrainingPointCost()
  if not cost then return false,"All 16 points purchased."end
  if expected~=owned or revision~=h.trainingRevision then return false,"Your points changed. Review the purchase again."end
  if P.state.tokens<cost then return false,"Need "..cost.." tokens for the next point."end
  H.buyingTraining=true
  local _,paid=P.ChangeTokens(-cost,"HARDTRAIN","point:"..(owned+1))
  if paid~=-cost then H.buyingTraining=nil;return false,"Training purchase could not be completed."end
  h.trainingPurchased=owned+1;h.trainingRevision=h.trainingRevision+1;H.buyingTraining=nil
  return true,"One hard-mode talent point purchased. Select a talent to allocate it."
end
function H.AllocateTraining(key,expected,revision)
  if H.TrainingSpent()>=H.TrainingOwned()then return false,"Buy a talent point first."end
  return H.BuyTraining(key,expected,revision)
end
local baseTalentBonus=P.TalentBonus
local hardBonuses={};for _,node in ipairs(H.trainingNodes)do if node.bonus then hardBonuses[node.bonus]=node end end
function P.TalentBonus(key)
  local node=hardBonuses[key]
  return baseTalentBonus(key)+(node and H.TrainingRank(node.key)*node.amount or 0)
end
function H.BuyTraining(key,expected,revision)
  if H.buyingTraining then return false,"Training purchase already in progress."end
  if not H.IsUnlocked()then return false,"Clear normal floor 100 to unlock hard-mode training."end
  if P.state.battle then return false,"Finish your battle before training."end
  local node;for _,candidate in ipairs(H.trainingNodes)do if candidate.key==key then node=candidate end end
  if not node then return false,"Unknown hard-mode talent."end
  local rank=H.TrainingRank(key)
  if not whole(expected,0,3) or expected~=rank then return false,"Review the current training rank before confirming."end
  if revision and revision~=lab().trainingRevision then return false,"Your talents changed. Select the node again."end
  local cost=H.TrainingCost()
  if not cost then return false,"All 16 hard-mode points are allocated. Respec to change your build."end
  if P.state.tokens<cost then return false,"Need "..cost.." tokens for the next rank."end
  H.buyingTraining=true
  local paid,receipt=0,nil
  if cost>0 then receipt,paid=P.ChangeTokens(-cost,"HARDTRAIN",key..":"..(rank+1))end
  if paid~=-cost then H.buyingTraining=nil;return false,"Training purchase could not be completed."end
  local h=lab();h.trainingPurchased=H.TrainingOwned()+(cost>0 and 1 or 0)
  h.training[key]=rank+1;h.trainingRevision=(h.trainingRevision or 0)+1;H.buyingTraining=nil
  return true,node.name.." "..(rank+1).."/4 trained."
end
function H.RespecTraining(revision)
  if H.buyingTraining or P.state.battle then return false,"Finish the battle before changing talents."end
  local h=lab()
  if not H.IsUnlocked() or H.TrainingSpent()==0 then return false,"No hard-mode points to reset."end
  if revision~=h.trainingRevision then return false,"Your talents changed. Review the respec again."end
  if P.state.tokens<H.trainingRespecCost then return false,"Need 500 tokens to respec hard-mode talents."end
  H.buyingTraining=true
  local _,paid=P.ChangeTokens(-H.trainingRespecCost,"RESPEC","hard")
  if paid~=-H.trainingRespecCost then H.buyingTraining=nil;return false,"Respec payment failed."end
  h.trainingPurchased=H.TrainingOwned()
  for _,node in ipairs(H.trainingNodes)do h.training[node.key]=0 end
  h.jumpTokenProgress=0;h.jumpXPProgress=0;h.restXPSeconds=0;h.restXPPet=nil
  h.trainingRevision=h.trainingRevision+1;H.buyingTraining=nil
  return true,"Hard-mode points returned. Reassign them without buying them again."
end
function H.KillTokens(amount)
  local rank=H.TrainingRank("tokens");if rank==0 or amount<=0 then return amount end
  local bonus=amount*rank*5+lab().tokenCarry;lab().tokenCarry=bonus%100
  return amount+math.floor(bonus/100)
end
local restRate=P.RestRate
function P.RestRate(pet)return restRate(pet)*(pet.resting and (1+H.TrainingRank("rest")*.05) or 1)end
function H.SetMode(mode)
  if P.state.battle then return false,"Finish or retreat before changing towers."end
  if mode~="normal" and mode~="hard"then return false,"Unknown tower."end
  H.RefreshUnlock();if mode=="hard" and not lab().unlocked then return false,"Clear normal floor 100 to unlock Hard Mode and the 16-pet stable."end
  lab().mode=mode;P.floor=mode=="hard" and math.min(100,lab().best+1) or H.Normal.Unlocked()
  P.lastRound=nil;P.victory=nil;P.defeat=nil;H.heals={};if H.picker then H.picker:Hide()end
  return true,mode=="hard" and "Hard Mode: equip three living level-75+ pets." or "Normal tower selected."
end
function H.Team()
  if not H.IsHard()then local pet=P.Active();return pet and {pet} or {}end
  local team={};for i=1,3 do team[i]=find(lab().team[i])end;return team
end
function H.Target()
  if not H.IsHard()then return P.Active()end
  for i=1,3 do local pet=find(lab().team[i]);if pet and pet.id==lab().target then return pet end end
end
function H.SelectTarget(id)
  for i=1,3 do local pet=H.Team()[i];if pet and pet.id==id then lab().target=id;return true,"Selected pet: "..P.species[pet.species]end end
  return false,"Choose a deployed teammate."
end
function H.RewardLoot(b)
  local h=lab();if b.hardLootAwarded then return end;b.hardLootAwarded=true
  local first=not h.cleared[b.floor];h.cleared[b.floor]=true
  while h.best<100 and h.cleared[h.best+1]do h.best=h.best+1 end
  local chance=first and 20 or 10
  if P.random(1,100)<=chance then
    local kind,rarity
    if b.floor<=25 then
      rarity=P.random(1,2)==1 and 4 or 5
      kind=P.RollGearKind(rarity)
    else
      local tier=b.floor>=76 and 3 or b.floor>=51 and 2 or 1
      if tier==1 and P.random(1,100)>25 then
        kind=H.nonSetKinds[P.random(1,#H.nonSetKinds)];rarity=5
      else
        kind=H.tierKinds[tier][P.random(1,#H.sets)][P.random(1,#P.gearSlots)];rarity=4
      end
    end
    local ok=P.GrantGear(kind,rarity,"Hard tower floor "..b.floor)
    if not ok then P.QueueTowerGear(kind,rarity,b.floor)end
  end
end
