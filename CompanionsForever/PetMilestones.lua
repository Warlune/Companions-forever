local _,F=...
local P,A,D=F.Pets,F.Achievements,F.PetData
A.petMilestoneCatalog=true
local entries={
  {id="sparkly1",name="A Little Sparkle",text="Discover 1 different Sparkly companion.",metric="sparklyPets",goal=1,tokens=250},
  {id="sparkly3",name="A Shimmering Stable",text="Discover 3 different Sparkly companions.",metric="sparklyPets",goal=3,tokens=500},
  {id="sparkly5",name="Rare Colors",text="Discover 5 different Sparkly companions.",metric="sparklyPets",goal=5,tokens=1000},
  {id="treats10",name="Snack Time",text="Have your companions consume 10 food or XP treats.",metric="treatsEaten",goal=10,tokens=25},
  {id="treats50",name="A Healthy Appetite",text="Have your companions consume 50 food or XP treats.",metric="treatsEaten",goal=50,tokens=75},
  {id="treats250",name="Treats for Everyone",text="Have your companions consume 250 food or XP treats.",metric="treatsEaten",goal=250,tokens=250},
  {id="abilities5",name="Tricks of the Trade",text="Discover 5 different companion abilities.",metric="abilitiesFound",goal=5,tokens=75},
  {id="abilities10",name="A Growing Spellbook",text="Discover 10 different companion abilities.",metric="abilitiesFound",goal=10,tokens=150},
  {id="abilities20",name="Many Talents",text="Discover 20 different companion abilities.",metric="abilitiesFound",goal=20,tokens=300},
  {id="goldStat1",name="A Golden Gift",text="Obtain a companion with a perfect gold stat roll.",metric="goldStat",goal=1,tokens=150},
}
local icons={sparklyPets="Spell_Arcane_StarFire",treatsEaten="INV_Misc_Food_14",abilitiesFound="INV_Misc_Book_09",goldStat="INV_Misc_Gem_Topaz_02"}
for _,d in ipairs(entries)do
  d.icon=icons[d.metric];d.order=#A.list+1;A.list[d.order]=d;A.byID[d.id]=d
end
local initialize=A.Initialize
function A.Initialize()
  local old=type(P.state.achievements)=="table" and P.state.achievements or {}
  initialize();local a=P.state.achievements;local treats=old.treatsEaten
  a.treatsEaten=type(treats)=="number" and treats==math.floor(treats) and treats>=0 and treats<=1000000 and treats or 0
  a.goldStat=old.goldStat==1 and 1 or 0
end
local progress=A.Progress
function A.Progress(d)
  if d.metric=="sparklyPets"then
    local n=0;for species,entry in pairs(P.state.collection or {})do
      if D.allowedSpecies[species] and entry.sparkly==true then n=n+1 end
    end;return n
  elseif d.metric=="abilitiesFound"then
    local n=0;for id,known in pairs(P.state.knownAbilities or {})do
      if known==true and P.specialAbilities[id]then n=n+1 end
    end;return n
  end
  return progress(d)
end
local help=A.ProgressHelp
function A.ProgressHelp(d)
  if d.metric=="sparklyPets"then return "Counts different species marked Sparkly in your collection, including existing discoveries. Repeated copies of the same species count once; retirement and trading do not erase discoveries."
  elseif d.metric=="treatsEaten"then return "Counts food and XP Treats successfully consumed since 1.1.28. Each consumed item counts once, including items from stacks. Herbs, purchases, failed uses and capped-pet XP Treat refusals do not count."
  elseif d.metric=="abilitiesFound"then return "Counts different abilities found in your Collection spellbook, including existing discoveries. Duplicate abilities count once, regardless of quality. Retirement and trading do not erase discoveries."
  elseif d.metric=="goldStat"then return "A gold stat is a perfect 100/100 base roll in health, attack, armor or speed. Silver rolls, ability rolls, levels, gear and talent bonuses do not qualify. Existing owned pets, including memorials, Mail and outgoing trade escrow, are checked on reload. Once earned, progress remains saved."end
  return help(d)
end
-- All real acquisitions and the spellbook's owned-pet backfill use this hook.
-- Inspect previews and pets merely offered by another player do not.
local discover=P.RecordAbilityDiscovery
function P.RecordAbilityDiscovery(pet)
  discover(pet)
  local a=P.state and P.state.achievements
  if not a or a.goldStat==1 then return end
  local rolls=P.DecodePetRolls(pet)
  if rolls then for _,rank in ipairs(rolls.stats)do if rank==100 then a.goldStat=1;return end end end
end
local function ateTreat()
  local a=P.state and P.state.achievements
  if a then a.treatsEaten=math.min(1000000,(a.treatsEaten or 0)+1)end
end
local care=P.Care
function P.Care(item)
  local ok,result=care(item)
  if ok and item=="food"then ateTreat()end
  return ok,result
end
local use=P.UseXPTreat
function P.UseXPTreat(...)
  local ok,result=use(...)
  if ok then ateTreat()end
  return ok,result
end
