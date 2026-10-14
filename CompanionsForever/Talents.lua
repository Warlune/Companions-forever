local _,F=...
local P=F.Pets
P.talentBranches={
  {key="vitality",name="Endurance",nodes={
    {key="health",ranks=5,name="Vitality",icon="Spell_Holy_WordFortitude",amount=0.01,help="+1% maximum health per rank."},
    {key="armor",ranks=2,name="Thick Hide",icon="Spell_Nature_ResistNature",amount=0.5,help="+0.5 percentage points of armor per rank."},
    {key="resistance",ranks=3,name="Resilience",icon="Spell_Holy_BlessingOfProtection",amount=0.02,help="2% less poison and burn damage per rank."},
    {key="onlineTokens",ranks=3,name="Steady Income",icon="INV_Misc_Coin_01",amount=0.1,help="+10% online tokens per rank. Fractions carry over between payments."},
  }},
  {key="power",name="Expertise",nodes={
    {key="attack",ranks=4,name="Power",icon="Ability_DualWield",amount=0.01,help="+1% attack per rank."},
    {key="training",ranks=2,name="Mentor",icon="Ability_Hunter_FerociousInspiration",amount=0.02,help="+2% retirement training XP per rank."},
    {key="towerTokens",ranks=2,name="Tower Bounty",icon="INV_Misc_Coin_02",amount=0.05,help="+5% tower victory tokens per rank. Fractions carry over between victories."},
    {key="rarity",ranks=5,name="Lucky Find",icon="INV_Misc_Gem_Opal_01",amount=30,help="Per rank: +0.3 percentage points to a crate's top non-Mythic rarity; 0.3% chance to upgrade dropped loot one tier. Drops never exceed Legendary or their level bracket."},
  }},
  {key="agility",name="Exploration",nodes={
    {key="speed",ranks=3,name="Agility",icon="Ability_Rogue_Sprint",amount=0.01,help="+1% speed per rank."},
    {key="petDrop",ranks=2,name="Tracker",icon="Ability_Hunter_Pathfinding",amount=75,help="+0.75 percentage points to solo farmable pet drops per rank. 5% becomes 6.5% at 2/2. Shared party drops stay 5%."},
    {key="herbDrop",ranks=4,name="Herbalist",icon="INV_Misc_Herb_02",amount=25,help="+0.25 percentage points to herb drops per rank. 0.5% becomes 1.5% at 4/4."},
    {key="gearDrop",ranks=5,name="Scavenger",icon="INV_Misc_Bag_08",amount=30,help="+0.3 percentage points to equipment drops per rank. 3% becomes 4.5% at 5/5."},
  }},
  {key="care",name="Care",nodes={
    {key="energyCapacity",ranks=2,name="Deep Reserves",icon="Spell_Nature_Lightning",amount=5,help="+5 maximum energy per rank. +10 at full rank."},
    {key="foodSavings",ranks=4,name="Steady Appetite",icon="INV_Misc_Food_14",amount=0.05,help="Food drains 5% more slowly per rank, including tower entry. 20% at full rank."},
    {key="feedingHealing",ranks=2,name="Comfort Food",icon="INV_Misc_Food_65",amount=0.05,help="Food restores 5% more health per rank. 10% more at full rank."},
    {key="herbHealingBonus",ranks=2,name="Herbal Care",icon="INV_Misc_Herb_03",amount=0.05,help="Herbs restore 5% more health per rank, in and out of battle. 10% more at full rank."},
  }},
}
function P.TalentNode(key,tier)
  for _,branch in ipairs(P.talentBranches)do if branch.key==key then
    local before=0
    for i,node in ipairs(branch.nodes)do
      if i==tier then return node,before end
      before=before+node.ranks
    end
  end end
end
function P.BranchRanks(branch)
  local total=0;for _,node in ipairs(branch.nodes)do total=total+node.ranks end;return total
end
function P.MaxTraining()
  return 40 -- More choices, not more earned points.
end
function P.TalentRank(key,tier)
  local node,before=P.TalentNode(key,tier)
  return node and math.max(0,math.min(node.ranks,(P.state.training[key] or 0)-before)) or 0
end
function P.AwardTokens(amount,source)
  local s=P.state;s.tokenFractions=type(s.tokenFractions)=="table" and s.tokenFractions or {}
  local carry=tonumber(s.tokenFractions[source]) or 0
  if carry~=carry or carry<0 or carry>=1 then carry=0 end
  local value=amount*(1+P.TalentBonus(source))+carry
  local earned=math.floor(value+0.000001);s.tokenFractions[source]=math.max(0,value-earned)
  P.ChangeTokens(math.min(P.maxTokens-s.tokens,earned),source=="onlineTokens" and "ONLINE" or "TOWER","");return earned
end
P.trainerRacials={
  Human={name="Patient Teacher",key="training",amount=0.01,help="+1% retirement training XP"},
  Orc={name="Pack Commander",key="attack",amount=0.01,help="+1% pet attack"},
  Dwarf={name="Sturdy Training",key="armor",amount=0.5,help="+0.5 percentage points pet armor"},
  NightElf={name="Forest Stride",key="speed",amount=0.01,help="+1% pet speed"},
  Scourge={name="Herbal Preservation",key="herbHealing",amount=2,help="Herbs restore 2 additional health percentage points"},
  Tauren={name="Enduring Companion",key="health",amount=0.01,help="+1% pet maximum health"},
  Gnome={name="Careful Accounting",key="onlineTokens",amount=0.02,help="+2% online token income (fractional gains accumulate)"},
  Troll={name="Restful Rhythm",key="rest",amount=0.02,help="+2% resting energy recovery"},
}
function P.TrainerRacial()
  if not UnitRace then return end
  local _,race=UnitRace("player")
  if issecretvalue and issecretvalue(race)then return end
  if canaccessvalue and not canaccessvalue(race)then return end
  return type(race)=="string" and P.trainerRacials[race] or nil
end
function P.RacialBonus(key)local racial=P.TrainerRacial();return racial and racial.key==key and racial.amount or 0 end
function P.RacialText()local r=P.TrainerRacial();return r and (r.name..": "..r.help) or "No racial bonus for this character race." end
function P.TalentBonus(key)
  local t=P.state and P.state.training or {}
  for _,branch in ipairs(P.talentBranches)do
    for tier,node in ipairs(branch.nodes)do if node.key==key then
      return P.TalentRank(branch.key,tier)*node.amount+P.RacialBonus(key)
    end end
  end
  return P.RacialBonus(key)
end
local function number(n)return string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")end
local talentEffects={
  health={100,"% maximum health"},attack={100,"% attack"},speed={100,"% speed"},
  armor={1," percentage points of armor"},resistance={100,"% less poison/burn damage"},
  onlineTokens={100,"% online tokens"},towerTokens={100,"% tower victory tokens"},
  training={100,"% retirement XP"},rarity={.01,"% chance to upgrade loot one rarity"},
  petDrop={.01," percentage points to solo pet drops"},gearDrop={.01," percentage points to gear drops"},
  herbDrop={.01," percentage points to herb drops"},energyCapacity={1," maximum energy"},
  foodSavings={100,"% less food used"},feedingHealing={100,"% more healing from Feed"},
  herbHealingBonus={100,"% more healing from herbs"},
}
function P.TalentEffectText(key,value)
  if key=="rarity"then return "+"..number(value*.01).." points to top crate rarity; "..number(value*.01).."% drop upgrade chance"end
  local effect=talentEffects[key]
  return ((key=="resistance" or key=="foodSavings" or key=="rarity") and "" or "+")..number(value*effect[1])..effect[2]
end
-- Keep hover text to the effect per rank and this talent's committed bonus.
function P.TalentTooltip(key,tier)
  local node=P.TalentNode(key,tier);local rank=P.TalentRank(key,tier)
  if node.key=="petDrop"then
    return node.name.." ("..rank.."/"..node.ranks..")\n"
      .."More pet drops from enemies while solo.\n"
      .."Drop chance: "..number(P.DropChance("pet")*.01).."% (base "..number(F.PetData.lootOdds.pet*.01).."%). Party unchanged."
  end
  return node.name.." ("..rank.."/"..node.ranks..")\n"
    ..P.TalentEffectText(node.key,node.amount).." per rank.\n"
    .."Current bonus: "..P.TalentEffectText(node.key,rank*node.amount).."."
end
function P.ShowTalentTooltip(owner,value)
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
  local title,body=value:match("^([^\n]+)\n(.*)$")
  GameTooltip:SetText(title or value)
  if body then for line in body:gmatch("[^\n]+")do GameTooltip:AddLine(line,1,1,1,true)end end
  GameTooltip:Show()
end
function P.UpgradeRarity(rarity)
  local bonus=P.TalentBonus("rarity")
  if rarity<5 and bonus>0 and P.random(1,10000)<=bonus then return rarity+1 end
  return rarity
end
P.styles={
  {name="Balanced",strike=60,guard=20,burst=20,help="Mix attacks, specials and occasional guards."},
  {name="Aggressive",strike=75,guard=10,burst=15,help="Favor attacks; guard less often."},
  {name="Defensive",strike=45,guard=35,burst=20,help="Guard more often while keeping attacks moving."},
  {name="Specialist",strike=45,guard=15,burst=40,help="Favor a ready offensive special. Healing stays manual."},
}
-- Keep the first three points unchanged, then ease the quadratic ramp.
-- Existing total XP is re-evaluated without resetting ranks or earned progress.
function P.TrainingNeeded(level)return 100+50*level+4*math.max(0,level-2)^2 end
function P.TrainingTotal(level)
  local total=0;for i=0,level-1 do total=total+P.TrainingNeeded(i)end;return total
end
function P.InitTalents()
  local s=P.state
  s.training=type(s.training)=="table" and s.training or {}
  local t=s.training
  if t.rules~=3 then
    -- New node effects and pacing: refund old allocations once, keep earned XP.
    for _,branch in ipairs(P.talentBranches)do t[branch.key]=0 end
    t.rules=3
  end
  if t.lootLayout~=1 then
    -- Reordered prerequisites: return only the affected branch allocations once.
    t.power=0;t.agility=0;t.lootLayout=1
  end
  local function whole(n,hi)return type(n)=="number" and n==math.floor(n) and n>=0 and n<=hi end
  t.total=whole(t.total,100000000) and t.total or 0
  t.level=0;t.xp=t.total
  while t.level<P.MaxTraining() and t.xp>=P.TrainingNeeded(t.level)do t.xp=t.xp-P.TrainingNeeded(t.level);t.level=t.level+1 end
  if t.level==P.MaxTraining() then t.xp=0 end
  local spent=0
  for _,branch in ipairs(P.talentBranches)do
    local rank=t[branch.key]
    rank=whole(rank,P.BranchRanks(branch)) and rank or 0
    rank=math.min(rank,t.level-spent);t[branch.key]=rank;spent=spent+rank
  end
  t.points=t.level-spent
  for _,pet in ipairs(s.pets)do if not P.styles[pet.style or 0]then pet.style=1 end end
end
function P.LevelCap()return math.min(100,10+10*math.floor(((P.state.training or {}).level or 0)/3))end
function P.XPNeeded(pet)return 20+pet.level*5 end
function P.XPText(pet)
  if pet.level>=P.LevelCap()then return "CAP "..P.LevelCap()end
  return math.floor(pet.xp or 0).." / "..P.XPNeeded(pet)
end
function P.SpendTalent(key,tier)
  if P.state.battle then return false,"Finish the battle before training." end
  local t=P.state.training
  for _,branch in ipairs(P.talentBranches)do if branch.key==key then
    local node,before=P.TalentNode(key,tier or 1)
    if tier and (not node or t[key]<before or t[key]>=before+node.ranks)then
      return false,"Fill the preceding node first. Each node shows its own rank limit."
    end
    if t.points<1 or t[key]>=P.BranchRanks(branch)then return false,"Earn training points by retiring companions of any level." end
    t[key]=t[key]+1;t.points=t.points-1;return true
  end end
  return false,"Unknown talent."
end
P.respecCost=25
-- Commit a reviewed batch only after every allocation passes validation.
function P.ConfirmTalentPlan(plan,baseline)
  if P.state.battle then return false,"Finish the battle before training." end
  local t=P.state.training;local spent=0
  if type(plan)~="table" or type(baseline)~="table" then return false,"Select talents first." end
  for _,branch in ipairs(P.talentBranches)do
    local key=branch.key;local added=plan[key] or 0
    if baseline[key]~=t[key] then return false,"Talents changed. Review your selections again." end
    if type(added)~="number" or added~=math.floor(added) or added<0 or t[key]+added>P.BranchRanks(branch) then
      return false,"Invalid talent selection."
    end
    spent=spent+added
  end
  if spent<1 or spent>t.points then return false,"Not enough available talent points." end
  for _,branch in ipairs(P.talentBranches)do t[branch.key]=t[branch.key]+(plan[branch.key] or 0)end
  t.points=t.points-spent
  P.notice="Confirmed "..spent.." talent point"..(spent==1 and "." or "s.")
  return true
end
function P.RespecTalents()
  if P.state.battle then return false,"Finish the battle before resetting talents." end
  local t=P.state.training
  if t.points==t.level then return false,"You have no spent talent points to refund." end
  if P.state.tokens<P.respecCost then return false,"You need "..P.respecCost.." tokens to reset talents." end
  P.ChangeTokens(-P.respecCost,"RESPEC","")
  for _,branch in ipairs(P.talentBranches)do t[branch.key]=0 end
  t.points=t.level
  P.notice="Talents reset. All points refunded; trainer XP and pet level caps kept."
  return true
end
-- Ten XP per reward point keeps the existing trainer curve and saved progress.
-- Milestones boost only the level portion; Mentor and death apply to the sum.
function P.RetirementBreakdown(pet)
  if not pet then return nil end
  local d={level=pet.level*10,rarity=({10,30,50,70,100})[pet.rarity],milestonePercent=math.floor(pet.level/10)*25}
  if pet.recovery then d.level=math.max(0,pet.level-1)*10;d.rarity=0 end
  d.milestone=d.level*d.milestonePercent/100
  d.mentorPercent=P.TalentBonus("training")*100
  d.mentor=(d.level+d.rarity+d.milestone)*d.mentorPercent/100
  d.subtotal=d.level+d.rarity+d.milestone+d.mentor
  d.penalty=pet.deadAt and d.subtotal*0.5 or 0
  d.recoveryPenalty=pet.recovery and (d.subtotal-d.penalty)*.75 or 0
  d.total=math.floor(d.subtotal-d.penalty-d.recoveryPenalty+0.000001)
  return d
end
function P.SetRetirementLock(id,locked)
  for _,pet in ipairs(P.state.pets)do if pet.id==id then
    pet.retirementLocked=not not locked
    if P.talents then P.talents.confirm=false end
    return true
  end end
  return false,"That companion is no longer in your stable."
end
function P.RetirementValue(pet)
  if pet and pet.retirementLocked then return 0 end
  if P.state.training.level>=P.MaxTraining()then return 0 end
  local d=P.RetirementBreakdown(pet);return d and d.total or 0
end
function P.RetirementTokens(pet)
  if not pet or pet.retirementLocked or P.state.training.level<P.MaxTraining()then return 0 end
  local value=math.min(30,math.floor(pet.level/5)+pet.rarity*2)*100/30
  -- Free recovery pets cannot be claimed and retired for free currency.
  if pet.recovery then value=math.min(30,math.floor(math.max(0,pet.level-1)/5))*100/30*.25 end
  if pet.deadAt then value=value*.5 end
  return math.min(math.floor(value),math.max(0,P.maxTokens-P.state.tokens))
end
function P.RetirementReward(pet)
  if P.state.training.level>=P.MaxTraining()then return P.RetirementTokens(pet),"tokens" end
  return P.RetirementValue(pet),"XP"
end
function P.RetirementRewardText(pet)
  local value,unit=P.RetirementReward(pet);return value.." "..unit
end
function P.RetirementDetails(pet)
  if pet and pet.retirementLocked then return "Locked. Unlock this pet in Camp before retiring it." end
  if pet and P.state.training.level>=P.MaxTraining()then
    return "Maximum trainer level: tokens replace talent XP.\n(2 per rarity tier + 1 per 5 pet levels) x 100/30. Up to 100 tokens; rounded down after penalties."
      ..(pet.deadAt and "\nDeath penalty: -50%." or "")
      ..(pet.recovery and "\nRecovery pet: no rarity bonus; earned levels only, -75%." or "")
      .."\n|cffffd166Total: "..P.RetirementTokens(pet).." tokens|r\nGear returns; collection stays unlocked."
  end
  local d=P.RetirementBreakdown(pet);if not d then return "Select a companion to see its reward." end
  local function number(n)return string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")end
  return "Level "..pet.level..": "..number(d.level).." XP\n"
    ..P.rarities[pet.rarity].." bonus: +"..number(d.rarity).." XP\n"
    .."Level milestone (+"..d.milestonePercent.."%): +"..number(d.milestone).." XP\n"
    .."Mentor (+"..number(d.mentorPercent).."%): +"..number(d.mentor).." XP\n"
    ..(pet.deadAt and "|cffff7777Death penalty (-50%): -"..number(d.penalty).." XP|r" or "Death penalty: none")
    ..(pet.recovery and "\nRecovery pet (-75%): -"..number(d.recoveryPenalty).." XP" or "")
    .."\n|cffffd166Total: "..d.total.." talent XP|r (rounded down)"
end
function P.RetirePet(id)
  if P.state.battle then return false,"Finish the battle before retiring a companion." end
  for i,pet in ipairs(P.state.pets)do if pet.id==id then
    if pet.retirementLocked then return false,"This companion is locked. Unlock it in Camp before retiring it." end
    local value,unit=P.RetirementReward(pet)
    local returning=0
    for _,id in pairs(pet.gear or {})do if P.GearItem(id)then returning=returning+1 end end
    if returning>0 and P.BagCount()+returning>P.BagCapacity() then
      return false,"Make "..returning.." free bag slots for this pet's equipment before retiring it."
    end
    -- Equipment already lives in the shared bag. Removing this owner's record
    -- releases its slots; the discovery ledger is deliberately retained.
    if F.Integrity then F.Integrity.Consumed("pet",pet)end
    table.remove(P.state.pets,i)
    if F.Achievements then F.Achievements.Retired()end
    if unit=="tokens"then local _,paid=P.ChangeTokens(value,"RETIRE",tostring(pet.id));value=paid or 0
    else local t=P.state.training;t.total=t.total+value;P.InitTalents()end
    if P.state.active==id then
      P.state.active=nil
      local life=F.Housing and F.Housing.Island and F.Housing.Island.Life
      for _,other in ipairs(P.state.pets)do
        if not other.deadAt and not (life and life.IsHoused(other.id))then P.state.active=other.id;break end
      end
    end
    if P.viewID==id then P.viewID=nil end
    P.floor=math.min(P.floor or 1,P.Unlocked());P.victory=nil
    local reward=value..(unit=="tokens" and " tokens" or " training XP")
    P.notice=P.species[pet.species].." retired: +"..reward..". Equipment returned; collection kept."
    if P.FindHistory then P.FindHistory("Retired "..P.species[pet.species].." at level "..pet.level..": +"..reward)end
    return true
  end end
  return false,"That companion is no longer in your stable."
end
function P.CycleStyle()
  local pet=P.Active()
  if not pet then return false,"Equip a companion first." end
  if P.state.battle then return false,"Finish the battle before changing fighting style." end
  pet.style=(pet.style or 1)%#P.styles+1;return true
end
function P.AutoAction(b,pet)
  local style=P.styles[pet.style or 1] or P.styles[1]
  local ability=P.ChooseAbility(pet,false)
  b.nextAbility=ability
  local burst=ability and not P.IsHealingAbility(ability) and P.SpecialCooldown(b,ability)==0 and style.burst or 0
  -- Weighted choices give each style variety without an unbounded
  -- streak of guards. A special on cooldown becomes an ordinary attack.
  local guard=(b.guardStreak or 0)>=1 and 0 or style.guard
  local roll=P.random(1,style.strike+guard+burst)
  local action=roll<=guard and "guard" or roll<=guard+burst and "burst" or "strike"
  return action
end
