local _,F=...
local P=F.Pets
P.petRollVersion=1
P.rollRandom=math.random -- Separate stream from the existing loot/combat test hooks.
P.abilityQualities={[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Mythic"}
P.abilityColors={[3]={.3,.6,1},[4]={.8,.4,1},[5]={1,.6,.15},[6]={1,.25,.45}}
local function count(pet)return pet.rarity>=4 and 2 or pet.rarity>=3 and 1 or 0 end
-- Four stat percentiles, then a tier and percentile for each ability. Fixed-size,
-- versioned, numeric hexadecimal data; never executable or free-form text.
local function decode(pet)
  local wire=pet and pet.rolls
  if type(wire)~="string" or #wire~=15 or (wire:sub(1,1)~="1" and not (P.sparklyCatalog and wire:sub(1,1)=="2")) or not wire:match("^%x+$")then return end
  local r={stats={},abilities={}}
  for i=1,4 do local n=tonumber(wire:sub(i*2,i*2+1),16);if n<1 or n>100 then return end;r.stats[i]=n end
  for i=1,2 do
    local at=10+(i-1)*3;local tier=tonumber(wire:sub(at,at),16);local n=tonumber(wire:sub(at+1,at+2),16)
    if i<=count(pet)then
      local maximum=pet.rarity==5 and 6 or 5
      if tier<pet.rarity or tier>maximum or n<1 or n>100 then return end
      r.abilities[i]={tier=tier,roll=n}
    elseif tier~=0 or n~=0 then return end
  end
  return r
end
local cache=setmetatable({},{__mode="k"})
function P.DecodePetRolls(pet)
  if type(pet)~="table" or not pet.rolls then return end
  local entry=cache[pet]
  if entry and entry.wire==pet.rolls and entry.rarity==pet.rarity then return entry.value or nil end
  local value=decode(pet);cache[pet]={wire=pet.rolls,rarity=pet.rarity,value=value or false}
  return value
end
function P.RollNewPet(pet)
  if pet.rolls then return end
  local out={"1"}
  for i=1,4 do out[#out+1]=string.format("%02x",P.rollRandom(1,100))end
  for i=1,2 do
    local tier,n=0,0
    if i<=count(pet)then
      tier=pet.rarity;local chance=P.rollRandom(1,10000)
      if tier==3 then tier=chance<=100 and 5 or chance<=700 and 4 or 3
      elseif tier==4 then tier=chance<=600 and 5 or 4
      elseif tier==5 then tier=chance<=200 and 6 or 5 end
      n=P.rollRandom(1,100)
    end
    out[#out+1]=string.format("%x%02x",tier,n)
  end
  pet.rolls=table.concat(out)
end
local function rounded(n,index)
  return index<=2 and math.floor(n) or math.floor(n*100+.5)/100
end
function P.RolledBaseStats(pet,base)
  local r=P.DecodePetRolls(pet);if not r then return base end
  local low=95+pet.rarity
  for i=1,4 do base[i]=rounded(base[i]*(low+8*(r.stats[i]-1)/99)/100,i)end
  return base
end
function P.BaseRollRange(pet,index)
  if index<1 or index>4 then return end
  local r=P.DecodePetRolls(pet);if not r then return end
  local family=F.PetData.families[F.PetData.species[pet.species].family]
  local quality=1+(pet.rarity-1)*.06
  local bases={math.floor((55+pet.level*9)*family.hp*quality),math.floor((9+pet.level*2.4)*family.attack*quality),family.armor+pet.rarity-1,family.speed+math.floor(pet.level/10)}
  return rounded(bases[index]*(95+pet.rarity)/100,index),rounded(bases[index]*(103+pet.rarity)/100,index),r.stats[index]
end
local defaults={bite={1.8,0},flurry={1.65,0},cleave={.9,0},renew={.8,.18},drain={1.1,.6},shield={1,0,.55}}
function P.AbilityRollFactor(tier,roll)return .9+(tier-3)*.1+(roll-1)/99*.1 end
local abilities=P.Abilities
function P.Abilities(pet)
  local values=abilities(pet);local r=P.DecodePetRolls(pet)
  if not r then return values end
  local out={}
  for i=1,#r.abilities do
    local a=values[i];if not a then break end
    local roll=r.abilities[i];local copy={};for k,v in pairs(a)do copy[k]=v end
    local d=defaults[a.effect];local factor=P.AbilityRollFactor(roll.tier,roll.roll)
    copy.basePower=a.power or d[1];copy.baseHealing=a.healing or d[2];copy.baseReduction=a.reduction or d[3]
    copy.power=copy.basePower*factor;copy.healing=copy.baseHealing*factor
    if copy.baseReduction then copy.reduction=math.min(.75,copy.baseReduction*factor)end
    copy.rollTier=roll.tier;copy.rollPercentile=roll.roll
    out[i]=copy
  end
  return out
end
