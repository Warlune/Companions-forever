local _,F=...
local P,H=F.Pets,F.Pets.HardMode
local function validSeed(n)return type(n)=="number" and n>=1 and n<=2147483646 and n==math.floor(n)end
local function rng(seed)
  local state=math.floor(seed)%2147483647;if state<1 then state=1 end
  return function(lo,hi)state=(state*48271)%2147483647;return lo+state%(hi-lo+1)end
end
function H.PrepareEncounters()
  if not validSeed(F.char.hardTowerSeed)then
    local owner=F.Integrity and F.Integrity.Owner() or "unknown"
    local seed=(F.Now()+math.random(1,1000000))%2147483646
    for i=1,#owner do seed=(seed*31+owner:byte(i))%2147483646 end
    F.char.hardTowerSeed=math.max(1,seed)
  end
  local h=P.state.hardMode;h.encounterSeed=validSeed(h.encounterSeed) and h.encounterSeed or F.char.hardTowerSeed
  if H.layoutSeed==h.encounterSeed then return end
  H.layoutSeed=h.encounterSeed;H.encounters={};H.rareFloors={}
  -- Fixed quarter-end challenges. Existing encounter seeds and clear receipts stay intact.
  for floor=25,100,25 do H.rareFloors[floor]=true end
  H.enemyPool={};local displays={}
  for _,id in ipairs(F.PetData.rosterPool)do
    local model=P.models[id]
    if id<=201 and model and not model.fallback and not displays[model.display]then
      H.enemyPool[#H.enemyPool+1]=id;displays[model.display]=true
    end
  end
  assert(#H.enemyPool>=6,"Hard tower requires six verified Classic models")
end
function H.Encounter(floor)
  H.PrepareEncounters()
  if H.encounters[floor]then return H.encounters[floor]end
  local roll=rng(H.layoutSeed+floor*7919);local result={};local used={}
  local count=floor>=60 and 6 or floor>=40 and 5 or floor>=20 and 4 or 3
  -- Gear progression carries pets past the level cap; the final twenty floors are lethal endgame.
  local base=math.min(100,1+(floor-1)*99/39)
  local late= floor<=40 and 0 or floor<=60 and (floor-40)*.035
    or floor<=80 and .7+(floor-60)*.01 or .9+(floor-80)*.016
  local level=math.floor(80+(floor-1)*30/99)
  for i=1,count do
    local species
    repeat species=H.enemyPool[roll(1,#H.enemyPool)]until not used[species];used[species]=true
    local variant=roll(95,105)/100
    result[i]={floor=floor,level=level,combatLevel=level,index=i,elite=true,rare=false,species=species,
      maxHP=math.floor((650+base*3.5)*(1+late*.9)*variant),attack=math.floor((90+base*.45)*(1+late*1.35)/variant),
      armor=10+base*.06+late*10,speed=18+base*.07+late*6,
      spell=({"burn","poison","slow","freeze"})[roll(1,4)],spellEvery=4,actions=1,
      abilityID=1+(H.layoutSeed+floor*37+i*17)%#P.specialAbilities}
  end
  if H.rareFloors[floor] or floor%10==0 then
    local hp,attack=0,0;for _,enemy in ipairs(result)do hp=hp+enemy.maxHP;attack=attack+enemy.attack end
    local e=result[1];e.species=({85,86,87,88,89,90,91,93,95,99})[roll(1,10)]
    local rare=H.rareFloors[floor]==true
    e.maxHP=rare and hp or math.floor(hp*.85);e.attack=math.floor(attack*(rare and .28 or .35))
    e.rare=rare;e.boss=true;e.actions=rare and 2 or 1
    e.critChance=rare and 5 or nil;e.critMultiplier=rare and 1.5 or nil
    e.packSize=count;e.packHP=hp;e.packAttack=attack
    result={e}
  end
  H.encounters[floor]=result;return result
end
function H.Enemies(floor)
  if type(floor)~="number" or floor~=math.floor(floor) or floor<1 or floor>100 then return end
  local result={}
  for i,template in ipairs(H.Encounter(floor))do local e={};for k,v in pairs(template)do e[k]=v end;result[i]=e end
  return result
end
