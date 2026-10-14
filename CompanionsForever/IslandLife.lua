local _,F=...
local I,P=F.Housing.Island,F.Pets
local L={price=10,limit=100,offlineCap=28800,crateID=61};I.Life=L
local function bonus(pet,job,stat)return L.HousingBonus and L.HousingBonus(pet,job,stat)or 0 end
local function scaled(pet,job,stat,amount)return L.HousingScale and L.HousingScale(pet,job,stat,amount)or amount end
local function restSeconds(pet,job,seconds)return math.ceil(seconds/(1+bonus(pet,job,'rest')/100))end
L.jobs={'roam','food','gold','xp','herbs','expedition'}
L.jobNames={roam='Roam',food='Cook food',gold='Find gold',xp='Train',herbs='Grow herbs',expedition='Expedition crew'}
L.difficulties={
 {name='Coastal waters',level=15,gold=12,gear=2,crate=2},
 {name='Open sea',level=45,gold=30,gear=3,crate=3},
 {name='Uncharted waters',level=80,gold=65,gear=4,crate=4},
}
local function number(n,default,lo,hi)
 return type(n)=='number'and n==n and n>=lo and n<=hi and math.floor(n)or default
end
function L.Pet(id)
 for _,pet in ipairs(P.state and P.state.pets or {})do if pet.id==id and not pet.deadAt then return pet end end
end
function L.Library()
 local a=F.db.housingLibrary
 if type(a)~='table'then a={};F.db.housingLibrary=a end
 for _,key in ipairs({'unlocked','places','secrets','sources'})do if type(a[key])~='table'then a[key]={}end end
 return a
end
function L.State()
 -- Use the shared adventure save, so changing characters cannot double-work pets.
 local s=P.state.housingLife
 if type(s)~='table'then s={};P.state.housingLife=s end
 if type(s.slots)~='table'then s.slots={}end
 if type(s.workProgress)~='table'then s.workProgress={}end
 for j=1,3 do if type(s.workProgress[j])~='table'then s.workProgress[j]={}end end
 if type(s.pending)~='table'then s.pending={}end
 local q=s.pending
 for _,key in ipairs({'food','herbs','gold'})do q[key]=number(q[key],0,0,100000000)end
 if type(q.xp)~='table'then q.xp={}end
 if type(q.items)~='table'then q.items={}end
 if type(s.stats)~='table'then s.stats={}end
 s.last=number(s.last,F.Now(),0,1e12);s.seed=number(s.seed,17391,1,2147483646);s.cityRest=s.cityRest==true
 return s
end
local utilityJobs={food=true,gold=true,xp=true,herbs=true}
function L.SaveWork(index,slot)
 if slot and utilityJobs[slot.job]then
  local duration=slot.workDuration or L.WorkSeconds(L.Pet(slot.petID),slot.job)
  L.State().workProgress[index][slot.job]=math.max(0,math.min(.999999,(slot.elapsed or 0)/duration))
 end
end
function L.RestoreWork(index,slot)
 slot.workDuration=utilityJobs[slot.job]and L.WorkSeconds(L.Pet(slot.petID),slot.job)or nil
 slot.elapsed=slot.workDuration and (L.State().workProgress[index][slot.job]or 0)*slot.workDuration or 0
end
function L.IsHoused(id)
 if not P.state or type(P.state.housingLife)~='table'then return false end
 for _,v in pairs(P.state.housingLife.slots or {})do if type(v)=='table'and v.petID==id then return true end end
 return false
end
function L.ValidateSave()
 local s=L.State();local seen={}
 for index,progress in pairs(s.workProgress)do
  if type(index)~='number'or index%1~=0 or index<1 or index>3 then s.workProgress[index]=nil
  else for job,value in pairs(progress)do if not utilityJobs[job]or type(value)~='number'or value~=value or value<0 or value>=1 then progress[job]=nil end end end
 end
 for j,slot in pairs(s.slots)do
  if type(j)~='number'or j%1~=0 or j<1 or j>3 or type(slot)~='table'or not L.Pet(slot.petID)or seen[slot.petID]then s.slots[j]=nil
  else
   seen[slot.petID]=true;slot.elapsed=number(slot.elapsed,0,0,3599);slot.rest=number(slot.rest,0,0,600);slot.xpElapsed=number(slot.xpElapsed,0,0,59)
   if not L.jobNames[slot.job]then slot.job='roam'end
   slot.workDuration=number(slot.workDuration,nil,1,3600)
   if utilityJobs[slot.job]then
    if s.workProgress[j][slot.job]==nil then L.SaveWork(j,slot)end
    L.RestoreWork(j,slot)
   end
  end
 end
 for id,xp in pairs(s.pending.xp)do local n=number(xp,0,0,100000000);if not L.Pet(id)or n==0 then s.pending.xp[id]=nil else s.pending.xp[id]=n end end
 local items={}
 for j=1,math.min(150,#s.pending.items)do local r=s.pending.items[j]
  if type(r)=='table'then
   if type(r.furniture)=='string'and I.decorByKey[r.furniture]then items[#items+1]={furniture=r.furniture}
   elseif number(r.crate,0,1,1000)>0 and (P.equipmentCrates[r.crate]or F.PetData.packs[r.crate])then items[#items+1]={crate=r.crate}
   elseif number(r.kind,0,1,100000)>0 and P.gearTypes[r.kind]and number(r.rarity,0,1,6)>0 then items[#items+1]={kind=r.kind,rarity=r.rarity}end
  end
 end
 s.pending.items=items
 s.stats.work=number(s.stats.work,0,0,100000000);s.stats.expeditions=number(s.stats.expeditions,0,0,100000000)
 s.difficulty=number(s.difficulty,1,1,#L.difficulties);s.repeatTrip=s.repeatTrip==true
 local t=s.trip
 if t then
  local valid=type(t)=='table'and L.difficulties[t.difficulty]and type(t.ids)=='table'and #t.ids>=1 and #t.ids<=3
  local ids={}
  if valid then for _,id in ipairs(t.ids)do if not seen[id]or ids[id]then valid=false;break end;ids[id]=true end end
  if not valid then s.trip=nil;s.repeatTrip=false
  else t.duration=number(t.duration,1800,1,3600);t.elapsed=number(t.elapsed,0,0,t.duration-1);t.chance=number(t.chance,0,0,100);t.rounds=number(t.rounds,0,0,80);if type(t.outcome)~='boolean'then t.outcome=nil end
   for _,key in ipairs({'outputBonus','taskXPBonus'})do local value=t[key];if type(value)~='number'or value~=value or value<0 or value>50 then t[key]=0 end end
  end
 end
 if L.IsHoused(P.state.active)then P.state.active=nil end
 if P.state.hardMode then for j,id in pairs(P.state.hardMode.team or {})do if L.IsHoused(id)then P.state.hardMode.team[j]=nil end end end
end
function L.Unlocked(key)
 local d=I.decorByKey[key];if not d then return false end
 return not d.unlock or L.Library().unlocked[key]==true
end
function L.Unlock(key,source)
 if not I.decorByKey[key]then return false end
 local a=L.Library();local fresh=not L.Unlocked(key);a.unlocked[key]=true
 if fresh and source then a.sources[key]=source end
 return fresh
end
function L.Station(job)
 if job=='roam'then return true end
 for _,o in ipairs(F.char.islandPrototype and F.char.islandPrototype.items or {})do
  if I.decorByKey[o.key]and I.decorByKey[o.key].station==job then return o end
 end
end
function L.Assign(id,targetSlot)
 if P.state.battle then return false,'Finish the tower battle first.'end
 if L.IsHoused(id)then return false,'This pet already lives on the island.'end
 local pet=L.Pet(id);if not pet then return false,'Choose a living pet.'end
 local s=L.State();L.Advance(F.Now())
 if targetSlot and (type(targetSlot)~='number'or targetSlot%1~=0 or targetSlot<1 or targetSlot>3)then return false,'Choose a housing slot.'end
 if targetSlot and s.slots[targetSlot]then return false,'That housing slot is occupied.'end
 local slot=targetSlot;for j=1,3 do if not slot and not s.slots[j]then slot=j;break end end
 if not slot then return false,'The island already has three pets.'end
 s.slots[slot]={petID=id,job='roam',elapsed=0,rest=0};pet.resting=false;pet.cityRest=nil
 if P.state.active==id then P.state.active=nil;for _,other in ipairs(P.state.pets)do if not other.deadAt and not L.IsHoused(other.id)then P.state.active=other.id;break end end end
 if P.state.hardMode then for j=1,3 do if P.state.hardMode.team[j]==id then P.state.hardMode.team[j]=nil end end end
 return true,P.PetName(pet)..' moved to housing.'
end
function L.CancelExpedition()
 local s=L.State();if not s.trip then return false,'No expedition is underway.'end
 -- Do not catch up here: cancellation explicitly discards this unfinished trip.
 s.trip=nil;s.repeatTrip=false
 for _,slot in pairs(s.slots)do if slot.job=='expedition'then slot.elapsed=0 end end
 return true,'Expedition canceled. This trip has no rewards.'
end
function L.Remove(id)
 L.Advance(F.Now());local s=L.State()
 if s.trip then for _,petID in ipairs(s.trip.ids)do if petID==id then return false,'Cancel the expedition first; its rewards will be lost.'end end end
 for j=1,3 do if s.slots[j]and s.slots[j].petID==id then
  if P.StableCount()>=P.stableCapacity then return false,'Make room in your stable before returning this pet.'end
  L.SaveWork(j,s.slots[j]);s.slots[j]=nil;return true,'Pet returned to the stable.'
 end end
 return false,'This pet is not housed.'
end
function L.SetJob(id,job)
 local valid=false;for _,key in ipairs(L.jobs)do if job==key then valid=true end end
 if not valid then return false,'Unknown assignment.'end
 L.Advance(F.Now());local s=L.State()
 if s.trip then for _,pid in ipairs(s.trip.ids)do if pid==id then return false,'Cancel or finish the expedition first.'end end end
 if not L.Station(job)then return false,'Place the '..(L.stationNames and L.stationNames[job]or job)..' first.'end
 for index,slot in pairs(s.slots)do if slot.petID==id then L.SaveWork(index,slot);slot.job=job;L.RestoreWork(index,slot);return true,L.jobNames[job]end end
 return false,'Move this pet to housing first.'
end
local function random(s,n)s.seed=s.seed*48271%2147483647;return s.seed%n+1 end
function L.Team()
 local s=L.State();local team={}
 for j=1,3 do local slot=s.slots[j];local pet=slot and L.Pet(slot.petID)
  if pet and slot.job=='expedition'then team[#team+1]=pet end
 end
 return team
end
function L.Power(pet)
 local hp,attack,armor,speed=P.Stats(pet)
 return math.max(1,hp*.12+attack*2+armor+speed*.3)
end
function L.ExpeditionChance(difficulty,team)
 local d=L.difficulties[difficulty];if not d then return 0 end
 local power=0;for _,pet in ipairs(team or L.Team())do power=power+L.Power(pet)end
 return math.floor(math.max(5,math.min(95,70*power/(40+d.level*4))))
end
function L.StartExpedition(difficulty,repeatTrip,internal)
 local s=L.State();local d=L.difficulties[difficulty]
 if not internal then L.Advance(F.Now())end
 if not d then return false,'Choose an expedition difficulty.'end
 if s.trip then return false,'Your crew is already at sea.'end
 if #s.pending.items>=150 then return false,'Claim your waiting finds before departing.'end
 if not L.Station('expedition')then return false,'Discover and place the expedition boat first.'end
 local team=L.Team();if #team==0 then return false,'Assign at least one housing pet to the expedition crew.'end
 local ids={};for _,pet in ipairs(team)do
  if pet.energy<80*(1-bonus(pet,'expedition','thrift')/100)then return false,'The crew needs more energy before departure.'end
  for _,slot in pairs(s.slots)do if slot.petID==pet.id and slot.rest>0 then return false,'The crew is resting.'end end
  ids[#ids+1]=pet.id
 end
 s.trip={ids=ids,difficulty=difficulty,elapsed=0,duration=L.TripSeconds(),chance=L.ExpeditionChance(difficulty,team)}
 s.trip.outputBonus=L.TeamHousingBonus and L.TeamHousingBonus('output',ids)or 0;s.trip.taskXPBonus=L.TeamHousingBonus and L.TeamHousingBonus('taskXP',ids)or 0
 s.difficulty=difficulty;s.repeatTrip=repeatTrip==true
 for _,pet in ipairs(team)do pet.energy=math.max(0,pet.energy-80*(1-bonus(pet,'expedition','thrift')/100))end
 return true,'Crew departed for '..d.name..'.'
end
local function pendingItem(s,item)
 -- Stop departures when storage fills; never create an unbounded saved table.
 if #s.pending.items<150 then s.pending.items[#s.pending.items+1]=item;return true end
 return false
end
-- Reward recipients are captured when work finishes, so switching the equipped
-- pet or removing a resident before Claim cannot redirect earned XP.
function L.QueueXP(s,amount,includeEquipped)
 local recipients={}
 for _,slot in pairs(s.slots)do recipients[slot.petID]=true end
 if includeEquipped and P.state.active then recipients[P.state.active]=true end
 for id in pairs(recipients)do if L.Pet(id)then s.pending.xp[id]=math.min(100000000,(s.pending.xp[id]or 0)+amount)end end
end
function L.GiveXP(pet,amount,show)
 local earned=P.AddXP(pet,amount,'utility')or 0
 if show and earned>0 then
  L.xpNotices=L.xpNotices or {};L.xpSerial=(L.xpSerial or 0)+1
  local prior=L.xpNotices[pet.id];local now=F.Now()
  L.xpNotices[pet.id]={serial=L.xpSerial,amount=earned+(prior and prior.at==now and prior.amount or 0),at=now}
 end
 return earned
end
function L.IsResting(slot)
 return slot and ((slot.rest or 0)>0 or L.State().cityRest==true)
end
function L.Activity(slot,pet,state)
 if not slot or not pet then return 'Empty slot',0 end
 local names={roam='Roaming',food='Cooking',gold='Finding gold',xp='Training',herbs='Growing herbs',expedition='Awaiting expedition'}
 local progress=0;local label=names[slot.job]or 'Roaming'
 if state.trip then for _,id in ipairs(state.trip.ids)do if id==pet.id then label='Expedition';progress=state.trip.elapsed/(state.trip.duration or 1800)end end end
 if slot.job~='roam'and slot.job~='expedition'then
  if L.Station(slot.job)then progress=(slot.elapsed or 0)/L.WorkSeconds(pet,slot.job)else label='Needs workstation'end
 end
 if (slot.rest or 0)>0 and not state.cityRest or state.cityRest and slot.job=='roam'then label='Resting';progress=(pet.energy or 0)/100 end
 return label,math.max(0,math.min(1,progress))
end
function L.FinishTrip(s)
 local trip=s.trip;local d=L.difficulties[trip.difficulty];s.trip=nil
 local won=random(s,100)<=trip.chance
 local result={difficulty=trip.difficulty,success=won,team=#trip.ids,at=F.Now()}
 if won then
  local tokens=L.ExpeditionTokens(trip.difficulty,trip.duration or 1800,trip.outputBonus)
  s.pending.gold=math.min(100000000,s.pending.gold+tokens)
  local find=L.ExpeditionFindType(random(s,100))
  if find=='crate'then pendingItem(s,{crate=d.crate})
  elseif find=='gear'then pendingItem(s,L.RollExpeditionGear(trip.difficulty,function(n)return random(s,n)end))
  elseif find=='furniture'then
   local pool={};for _,entry in ipairs(I.decor)do if entry.unlock=='expedition'and not L.Unlocked(entry.key)then pool[#pool+1]=entry.key end end
   if #pool>0 then pendingItem(s,{furniture=pool[random(s,#pool)]})else s.pending.gold=math.min(100000000,s.pending.gold+1)end
  end
  s.stats.expeditions=(s.stats.expeditions or 0)+1
 end
 L.QueueXP(s,math.floor(20*(1+(trip.taskXPBonus or 0)/100)+.5),false)
 for _,id in ipairs(trip.ids)do for _,slot in pairs(s.slots)do if slot.petID==id then slot.rest=restSeconds(L.Pet(id),'expedition',600);slot.elapsed=0 end end end
 s.lastTrip=result
end
function L.Advance(now)
 if L.advancing then return end;L.advancing=true
 local s=L.State();now=number(now,F.Now(),0,1e12)
 local seconds=math.min(L.offlineCap,math.max(0,now-s.last));s.last=math.max(s.last,now)
 local live=seconds<=60
 for index,slot in pairs(s.slots)do if utilityJobs[slot.job]then
  local duration=L.WorkSeconds(L.Pet(slot.petID),slot.job)
  if slot.workDuration and duration~=slot.workDuration then L.SaveWork(index,slot);L.RestoreWork(index,slot)else slot.workDuration=duration end
 end end
 -- Step at payout, rest and voyage boundaries for online/offline parity.
 while seconds>0 do
  local step=math.min(seconds,300)
  for _,slot in pairs(s.slots)do
   -- City rest still gates expedition departures, even while utility work
   -- continues. Stop at both boundaries so catch-up cannot delay a repeat.
   if slot.rest>0 then step=math.min(step,slot.rest)end
   if (slot.rest<=0 or s.cityRest)and slot.job~='roam'and slot.job~='expedition'and L.Station(slot.job)then step=math.min(step,math.max(1,L.WorkSeconds(L.Pet(slot.petID),slot.job)-slot.elapsed))end
  end
  if s.trip then step=math.min(step,math.max(1,(s.trip.duration or 1800)-s.trip.elapsed))end
  if step<=0 then break end
  seconds=seconds-step
  local aboard={};if s.trip then for _,id in ipairs(s.trip.ids)do aboard[id]=true end end
  for j=1,3 do local slot=s.slots[j];local pet=slot and L.Pet(slot.petID)
   if pet then
    slot.xpElapsed=number(slot.xpElapsed,0,0,59)+step
    local minutes=math.floor(slot.xpElapsed/60);slot.xpElapsed=slot.xpElapsed%60
    if minutes>0 then L.GiveXP(pet,scaled(pet,slot.job,'insight',minutes*3)+(L.SharedHousingXP and L.SharedHousingXP(pet,minutes*3)or 0),live)end
    if s.cityRest then pet.energy=math.min(100,(pet.energy or 0)+step/3*(1+bonus(pet,slot.job,'rest')/100));slot.rest=math.max(0,(slot.rest or 0)-step)end
   end
   if slot and not pet then s.slots[j]=nil
   elseif pet and not aboard[pet.id]then
    local remain=step
    if slot.rest>0 and not s.cityRest then local used=math.min(remain,slot.rest);slot.rest=slot.rest-used;remain=remain-used;pet.energy=slot.rest==0 and 100 or math.min(100,pet.energy+used/3*(1+bonus(pet,slot.job,'rest')/100))end
    if remain>0 then
     if slot.job=='roam'or slot.job=='expedition'or not L.Station(slot.job)then pet.energy=math.min(100,pet.energy+remain/3)
     else
      slot.elapsed=slot.elapsed+remain
      local interval=L.WorkSeconds(pet,slot.job)
      while slot.elapsed>=interval do
       slot.elapsed=slot.elapsed-interval
       local cost=20*(1-bonus(pet,slot.job,'thrift')/100)
       if pet.energy<cost and not s.cityRest then slot.rest=restSeconds(pet,slot.job,300);slot.elapsed=0;break end
       if not s.cityRest then pet.energy=math.max(0,pet.energy-cost)end;s.stats.work=(s.stats.work or 0)+1
       if slot.job=='food'or slot.job=='herbs'then s.pending[slot.job]=math.min(100000000,s.pending[slot.job]+scaled(pet,slot.job,'output',1))
       elseif slot.job=='gold'then s.pending.gold=math.min(100000000,s.pending.gold+scaled(pet,slot.job,'output',2))
       elseif slot.job=='xp'then L.QueueXP(s,scaled(pet,slot.job,'output',25),true)end
       L.QueueXP(s,scaled(pet,slot.job,'taskXP',20),false)
       if pet.energy<cost and not s.cityRest then slot.rest=restSeconds(pet,slot.job,300);break end
      end
     end
    end
   end
  end
  if s.trip then s.trip.elapsed=s.trip.elapsed+step;if s.trip.elapsed>=(s.trip.duration or 1800) then L.FinishTrip(s)end
  elseif s.repeatTrip and #s.pending.items<149 then L.StartExpedition(s.difficulty,true,true)end
 end
 for index,slot in pairs(s.slots)do L.SaveWork(index,slot)end
 L.advancing=nil
end
function L.Claim()
 L.Advance(F.Now());local s=L.State();local q=s.pending;local parts={}
 for _,key in ipairs({'food','herbs'})do local amount=q[key];if amount>0 then
  local item=key=='herbs'and 'medicine'or 'food';local before=P.state.inventory[item]or 0
  local kept=math.min(amount,math.max(0,20-before));P.state.inventory[item]=math.min(20,before+kept);q[key]=0
  parts[#parts+1]=kept..' '..key..(amount>kept and ' ('..(amount-kept)..' overflow discarded)'or '')
 end end
 if q.gold>0 then local _,paid=P.ChangeTokens(q.gold,'HOUSINGWORK','');q.gold=q.gold-(paid or 0);parts[#parts+1]=(paid or 0)..' gold'end
  for id,xp in pairs(q.xp)do local pet=L.Pet(id);if pet then local earned=L.GiveXP(pet,xp,true);parts[#parts+1]=earned..' XP for '..P.PetName(pet)end;q.xp[id]=nil end
 local index=1
 while index<=#q.items do local reward=q.items[index];local ok
  if reward.furniture then ok=I.decorByKey[reward.furniture]~=nil;if ok then L.Unlock(reward.furniture,'expedition');parts[#parts+1]=I.decorByKey[reward.furniture].name end
  elseif reward.crate then ok=P.GrantCrate(reward.crate,'Housing expedition',true)
  elseif reward.kind then ok=P.GrantGear(reward.kind,reward.rarity,'Housing expedition')end
  if not ok then index=index+1 else
   -- Commit each successful delivery immediately. A later grant failure must
   -- not make earlier deliveries available for a second claim.
   table.remove(q.items,index)
   parts[#parts+1]=reward.crate and 'Crate received' or reward.kind and 'Gear received' or 'Blueprint learned'
  end
 end
 return true,#parts>0 and table.concat(parts,', ')or (#q.items>0 and 'Make room for the remaining rewards.'or 'No rewards waiting.')
end
function L.PendingText()
 local q=L.State().pending;local xp=0;for _,n in pairs(q.xp)do xp=xp+n end
 return string.format('%d food  |  %d herbs  |  %dg  |  %d XP  |  %d finds',q.food,q.herbs,q.gold,xp,#q.items)
end
-- Assignment is enforced at gameplay entry points, not merely hidden in UI.
local selectPet=P.Select
function P.Select(id)if L.IsHoused(id)then return false,'Return this pet from housing before equipping it.'end;return selectPet(id)end
local retire=P.RetirePet
function P.RetirePet(id)if L.IsHoused(id)then return false,'Return this pet from housing before retiring it.'end;return retire(id)end
local eligible=F.Trades.Eligible
function F.Trades.Eligible(kind,id)
 if kind=='pet'and L.IsHoused(id)then return false,'Return this pet from housing before trading it.'end
 if kind=='crate'and P.CrateItem(id)and P.CrateItem(id).crate==L.crateID then return false,'Furniture crates cannot be traded.'end
 return eligible(kind,id)
end
local readiness=P.BattleReadiness
function P.BattleReadiness(...)
 local team=P.HardMode.IsHard()and P.HardMode.Team()or {P.Active()}
 for _,pet in pairs(team)do if pet and L.IsHoused(pet.id)then return false,'A team pet is assigned to housing. Return it first.','Pet is housed'end end
 return readiness(...)
end
local tick=P.Tick
function L.UpdateCityRest()
 if not P.state then return end
 -- Settle the previous state first; a city transition must not turn work done
 -- elsewhere or the whole offline interval into city energy recovery.
 L.Advance(F.Now());L.State().cityRest=P.InRestArea and P.InRestArea()or false
end
local restEvents=CreateFrame('Frame');restEvents:RegisterEvent('PLAYER_UPDATE_RESTING');restEvents:RegisterEvent('PLAYER_ENTERING_WORLD')
restEvents:SetScript('OnEvent',function()L.UpdateCityRest()end)
function P.Tick(dt)
 local energies={};for _,pet in ipairs(P.state and P.state.pets or {})do if L.IsHoused(pet.id)then energies[pet.id]={pet.energy,pet.food,pet.health,pet.age};pet.resting=false;pet.cityRest=nil;P.cityRestAwake[pet.id]=true end end
 tick(dt)
 for id,saved in pairs(energies)do local pet=L.Pet(id);if pet then pet.energy,pet.food,pet.health,pet.age=unpack(saved);pet.resting=false;pet.cityRest=nil end end
 if P.state then L.UpdateCityRest()end
end
