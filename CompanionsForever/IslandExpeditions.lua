local _,F=...
local L,P=F.Housing.Island.Life,F.Pets
-- Compact turn-based encounter simulation. No world combat APIs, messages,
-- tower state, consumables or permanent pet-health changes are involved.
local function alive(units)local result={};for _,u in ipairs(units)do if u.hp>0 then result[#result+1]=u end end;return result end
function L.SimulateExpedition(team,difficulty,seed)
 local d=L.difficulties[difficulty];if not d or #team==0 then return false,0 end
 local function roll(lo,hi)seed=seed*48271%2147483647;return lo+seed%(hi-lo+1)end
 local allies,enemies={},{}
 for index,pet in ipairs(team)do
  local hp,attack,armor,speed=P.Stats(pet)
  allies[#allies+1]={index=1-index,pet=pet,hp=hp,maxHP=hp,attack=attack,armor=armor,speed=speed,effects={},abilities=P.Abilities(pet)}
 end
 local level=d.level;local strength=d.strength or 1
 for j=1,d.enemies or 3 do enemies[j]={index=j,hp=(90+level*5)*strength,maxHP=(90+level*5)*strength,attack=(12+level*.8)*strength,armor=level*.35*strength,speed=10+level*.35,effects={}}end
 local function emit()end
 local function strike(a,b)
  if roll(1,100)>P.HitChance(P.CombatSpeed(a),P.CombatSpeed(b))then return end
  local power=P.CombatAttack(a)*(.85+roll(1,30)/100)*(roll(1,100)<=8 and 1.5 or 1)
  local amount=math.max(1,math.floor(power*(1-math.min(60,P.CombatArmor(b))/100)*(b.shield and 1-b.shield or 1)))
  b.hp=b.hp-P.AbsorbAbilityDamage(b,amount,a,emit)
 end
 for round=1,80 do
  local order={};for _,a in ipairs(alive(allies))do order[#order+1]={unit=a,ally=true}end;for _,e in ipairs(alive(enemies))do order[#order+1]={unit=e}end
  table.sort(order,function(a,b)local sa,sb=P.CombatSpeed(a.unit),P.CombatSpeed(b.unit);return sa==sb and a.unit.index<b.unit.index or sa>sb end)
  for _,entry in ipairs(order)do if entry.unit.hp>0 then
   local u=entry.unit;P.BeginAbilityAction(u,emit);u.shield=nil
   local targets=alive(entry.ally and enemies or allies)
   if #targets==0 then return entry.ally==true,round end
   if u.hp>0 and not P.ControlBlocked(u,round)then
    local blocked=u.effects.stun or u.effects.freeze
    u.effects.stun=nil;u.effects.freeze=nil
    if not blocked then
     local target=targets[roll(1,#targets)];local ability
     if entry.ally and round%3==0 then
      for _,a in ipairs(u.abilities)do if not P.IsHealingAbility(a)or u.hp<u.maxHP*.85 then ability=a;break end end
     end
     if ability then P.ResolveSpecialAbility(u,ability,enemies,allies,target,round,emit,P.GearEffects(u.pet),roll)
     else strike(u,target)end
    end
   end
   P.EndAbilityAction(u)
  end end
  if #alive(enemies)==0 then return true,round end
  if #alive(allies)==0 then return false,round end
 end
 return false,80
end
function L.ExpeditionChance(difficulty,team)
 team=team or L.Team();if #team==0 then return 0 end
 local key=tostring(difficulty)
 for _,pet in ipairs(team)do
  local hp,a,r,s=P.Stats(pet);key=key..':'..pet.id..':'..hp..':'..a..':'..r..':'..s
  for _,ability in ipairs(P.Abilities(pet))do key=key..':'..ability.ability..':'..(ability.rollTier or 0)..':'..(ability.rollPercentile or 0)end
  local effects=P.GearEffects(pet);for _,name in ipairs({'critical','precision','leech','ward','renewal'})do key=key..':'..tostring(effects[name])end
 end
 L.chanceCache=L.chanceCache or {}
 if L.chanceCache[key]then return L.chanceCache[key]end
 local wins=0
 for attempt=1,40 do if L.SimulateExpedition(team,difficulty,137+attempt*7919)then wins=wins+1 end end
 local chance=math.floor(wins*2.5+.5);L.chanceCache={[key]=chance};return chance
end
local start=L.StartExpedition
function L.StartExpedition(difficulty,repeatTrip,internal)
 local ok,why=start(difficulty,repeatTrip,internal)
 if ok then
  local state=L.State();state.seed=state.seed*48271%2147483647
  local won,rounds=L.SimulateExpedition(L.Team(),difficulty,state.seed)
  state.trip.outcome=won;state.trip.rounds=rounds
 end
 return ok,why
end
-- A finished trip consumes its precomputed encounter result. Reloading or
-- swapping gear after departure cannot reroll the battle.
local finish=L.FinishTrip
function L.FinishTrip(state)
 local trip=state.trip
 if trip.outcome==nil then
  local team={};for _,id in ipairs(trip.ids)do local pet=L.Pet(id);if pet then team[#team+1]=pet end end
  trip.outcome,trip.rounds=L.SimulateExpedition(team,trip.difficulty,state.seed)
 end
 trip.chance=trip.outcome and 100 or 0
 local rounds=trip.rounds;finish(state);state.lastTrip.rounds=rounds
end
