local _,F=...
local P,H=F.Pets,F.Pets.HardMode
local abilityHelp=P.AbilityHelp
function P.AbilityHelp(effect)
  if effect=="shield" or type(effect)=="table" and effect.effect=="shield" and not effect.power then return "Strike and reduce incoming hits by 55% until this pet's next action. Three-turn cooldown."end
  return abilityHelp(effect)
end
local function whole(n,lo,hi)return type(n)=="number" and n==math.floor(n) and n>=lo and n<=hi end
local function living(units)local out={};for _,u in ipairs(units)do if u.hp>0 then out[#out+1]=u end end;return out end
local function damage(power,armor)return math.max(1,math.floor(power*(1-math.min(60,armor)/100)))end
local function unit(id,b)
  b=b or P.state.battle;if b and not b.hard and b.petID==id then return b end;if b and b.allies then for _,u in ipairs(b.allies)do if u.pet.id==id then return u end end end
end
H.Unit=unit
function H.Health(pet,visual)
  local b=P.state.battle;local u=unit(pet.id,b)
  local round=P.lastRound
  local instant=P.instantHeals and P.instantHeals[pet.id]
  if visual and u and instant and instant.round==round and not (P.victory and P.victory.round==round) then return u.hp,u.maxHP end
  if visual and round and not round.team and round.pet and round.pet.id==pet.id and (b or (P.sceneClock or 0)<round.at+round.duration) then
    local _,state=P.VisualEvent(round,P.sceneClock or 0)
    if state then return state.hp,state.maxHP or round.maxHP end
  end
  if visual and round and round.team and (b or (P.sceneClock or 0)<round.at+round.duration) then
    local _,snapshot=P.VisualEvent(round,P.sceneClock or 0)
    for i,p in ipairs(round.team)do if p.id==pet.id and snapshot and snapshot.allyHP then return snapshot.allyHP[i],snapshot.allyMaxHP[i]end end
  end
  if u then return u.hp,u.maxHP end
  local maxHP=P.Stats(pet);return math.min(maxHP,math.ceil(maxHP*pet.health/100)),maxHP
end
function H.EquipViewed()
  if P.state.battle then return false,"Finish the encounter before changing your team."end
  local selected;for _,pet in ipairs(P.state.pets)do if pet.id==P.viewID and not pet.deadAt then selected=pet end end
  if not selected or (H.IsHard() and selected.level<75)then return false,"Select a living level-75+ pet in Camp."end
  if not H.IsHard()then return H.Normal.Select(selected.id)end
  local h=P.state.hardMode;local slot=h.editSlot or 1;local prior=h.team[slot]
  for i=1,3 do local id=h.team[i];if id==selected.id then h.team[i]=prior;break end end
  h.team[slot]=selected.id;h.target=selected.id;P.lastRound=nil;P.victory=nil
  return true,P.species[selected.species].." equipped in team slot "..slot..". All three fight together."
end
function P.Unlocked()return H.IsUnlocked() and math.min(100,P.state.hardMode.best+1) or 0 end
H.tactics={
  {key="lowest",name="Lowest HP",icon="Ability_Hunter_SniperShot",help="Focus the living enemy with the lowest current HP. Ties follow frame order."},
  {key="highest",name="Highest HP",icon="Spell_Holy_WordFortitude",help="Focus the living enemy with the highest current HP. Ties follow frame order."},
  {key="order",name="In order",icon="Ability_Hunter_MarkedForDeath",help="Defeat enemies in numbered frame order: top row left to right, then the bottom row."},
  {key="random",name="Random",icon="INV_Misc_Dice_01",help="Choose a random living enemy for each pet attack."},
}
function H.SetTactic(key)
  for _,t in ipairs(H.tactics)do if t.key==key then P.state.hardMode.tactic=key;return true end end
  return false,"Unknown tactic."
end
function H.TargetEnemy(enemies)
  local targets=living(enemies);local key=P.state.hardMode.tactic or "order"
  if #targets==0 then return end
  if key=="random"then return targets[P.random(1,#targets)]end
  local target=targets[1]
  for _,e in ipairs(targets)do if key=="lowest" and e.hp<target.hp or key=="highest" and e.hp>target.hp then target=e end end
  return target
end
function H.SetStyle(index)
  if P.state.battle then return false,"Fighting styles are locked during battle."end
  if not whole(index,1,#P.styles)then return false,"Unknown fighting style."end
  local pet=H.Target();if not pet then return false,"Select a team pet first."end
  pet.style=index;return true
end
function P.CycleStyle()
  local pet=H.Target();return H.SetStyle(((pet and pet.style or 1)%#P.styles)+1)
end
function P.FloorStatus(floor)return P.state.hardMode and P.state.hardMode.cleared and P.state.hardMode.cleared[floor] and "Completed" or floor<=P.Unlocked() and "Not cleared" or "Locked"end
function P.BattleReadiness(floor)
  if P.state.trade then return false,"Finish or safely cancel your pending trade before entering the tower.","Finish pending trade"end
  if P.state.battle then return false,"A team battle is in progress.","Team battle in progress"end
  if not H.IsUnlocked() or not whole(floor,1,100) or floor>P.Unlocked()then return false,"Clear the previous hard floor first.","Floor locked"end
  local team=H.Team();if not team[1] or not team[2] or not team[3] then return false,"Equip three living level-75+ pets in Camp.","Equip three pets"end
  local seen={}
  for _,pet in ipairs(team)do
    if pet.deadAt then return false,"Replace fallen "..P.species[pet.species].." using the right-click stable picker.","Replace fallen teammate"end
    if seen[pet.id] or pet.level<75 then return false,"Equip three different level-75+ pets.","Requires three level-75+ pets"end;seen[pet.id]=true
    if pet.health<40 or P.EnergyPoints(pet)<9 or pet.food<15 then
      return false,P.species[pet.species].." needs 40% health, 9 energy and 15 food. Care for your team before entering.","Team needs care"
    end
  end
  return true,"All three pets fight. Costs each pet 9 energy and 5 food. Select a portrait to target healing.","3 pets ready - all enemies Elite"
end
local function sync(b)
  for _,u in ipairs(b.allies)do
    if u.hp<=0 then
      u.hp=0;u.pet.health=0;u.pet.deadAt=u.pet.deadAt or F.Now();u.pet.deathReason="Fell in the hard tower on floor "..b.floor;u.pet.resting=false
    else u.pet.health=math.min(100,u.hp/u.maxHP*100)end
  end
  if not P.Active()then for _,u in ipairs(b.allies)do if not u.pet.deadAt then P.state.active=u.pet.id;break end end end
  local first=b.allies[1]
  b.hp=first.hp;b.maxHP=first.maxHP;b.attack=first.attack;b.armor=first.armor;b.speed=first.speed;b.effects=first.effects
  b.cooldown=first.cooldown;b.statBreakdown=P.StatBreakdown(first.pet)
end
function P.StartBattle(floor)
  if not H.IsUnlocked()then return false,"Clear normal floor 100 first."end
  local ok,msg=P.BattleReadiness(floor);if not ok then return false,msg end
  local team=H.Team();local b={hard=true,allies={},team=team,enemies=P.Enemies(floor),floor=floor,petID=team[1].id,
    turn=0,elapsed=0,paused=false,cooldown=0,effects={}}
  for i,pet in ipairs(team)do
    local hp,attack,armor,speed=P.Stats(pet)
    pet.energy=math.max(0,pet.energy-9*100/P.MaxEnergy());pet.food=math.max(0,pet.food-5*(1-P.TalentBonus("foodSavings")));pet.resting=false
    b.allies[i]={pet=pet,index=1-i,maxHP=hp,hp=math.ceil(hp*pet.health/100),attack=attack,armor=armor,speed=speed,effects={},cooldown=0,turn=0,guardStreak=0}
  end
  for _,enemy in ipairs(b.enemies)do enemy.hp=enemy.maxHP end;b.enemy=b.enemies[1]
  P.state.active=team[1].id;P.state.battle=b;sync(b);P.lastRound=nil;P.victory=nil;P.defeat=nil;P.floor=floor
  P.notice="Hard "..floor..": 3 pets vs "..#b.enemies.." level-"..b.enemy.level.." elites. Click a pet, then Heal.";return true
end
function H.HealReady(pet)
  if not pet then return false,"Select a deployed pet to heal."end
  if pet.deadAt then return false,"That pet has died. Replace it with a living pet."end
  local hp,maxHP=H.Health(pet)
  if hp<=0 then return false,"That pet has died. Replace it with a living pet."end
  if hp>=maxHP then return false,"That pet is already at full health."end
  if P.state.inventory.medicine<1 and P.state.tokens<P.SupplyCost("medicine")then return false,"Need a healing herb or tokens."end
  return true
end
function H.PayHerb()
  if P.state.inventory.medicine>0 then P.state.inventory.medicine=P.state.inventory.medicine-1;return true end
  local cost=P.SupplyCost("medicine");if P.state.tokens<cost then return false end
  P.ChangeTokens(-cost,"BATTLEHERB","hard");return true
end
function P.HealChoice()
  local pet=H.Target();local ok,msg=H.HealReady(pet);if not ok then return nil,msg end
  return "heal","Heal "..P.species[pet.species].." with one herb (or "..P.SupplyCost("medicine").." tokens)."
end
function P.RequestHeal()
  local pet=H.Target();local ok,msg=H.HealReady(pet);if not ok then return false,msg end
  if not H.PayHerb()then return false,"No healing supplies."end
  local b=P.state.battle;local u=unit(pet.id,b);local amount
  if u then
    amount=math.min(u.maxHP-u.hp,math.ceil(u.maxHP*P.HealingAmount("medicine")/100));u.hp=u.hp+amount;sync(b)
  else
    local hp,maxHP=H.Health(pet);amount=math.min(maxHP-hp,math.ceil(maxHP*P.HealingAmount("medicine")/100))
    pet.health=math.min(100,(hp+amount)/maxHP*100);P.lastRound=nil
  end
  P.RecordInstantHeal(pet,amount)
  P.notice="Healed "..P.species[pet.species].." for "..amount.." HP. All pets keep attacking."
  return true
end
local function snapshot(b)
  local s={hp=b.allies[1].hp,maxHP=b.allies[1].maxHP,enemyHP={},effects={},allyHP={},allyMaxHP={},allyEffects={}}
  for i,u in ipairs(b.allies)do
    s.allyHP[i]=u.hp;s.allyMaxHP[i]=u.maxHP;s.allyEffects[i]={}
    for key,e in pairs(u.effects)do s.allyEffects[i][key]=e.turns end
  end
  s.effects=s.allyEffects[1]
  for i,e in ipairs(b.enemies)do s.enemyHP[i]=e.hp end;return s
end
function P.BattleAction(action)
  local b=P.state.battle;if not b or not b.allies then return false,"No team battle."end
  if action=="retreat"then sync(b);P.state.battle=nil;P.lastRound=nil;P.notice="Team retreated. Damage and spent supplies remain.";return true end
  if action~="auto" and action~="strike" and action~="guard" and action~="burst" and action~="heal"then return false,"Unknown team action."end
  local round={at=P.sceneClock or 0,pet=b.team[1],team=b.team,enemies=b.enemies,enemy=b.enemy,events={},start=snapshot(b),maxHP=b.maxHP,action=action,hit=0,hurt=0,heal=0}
  P.lastRound=round
  local function record(actor,label,amount,target,kind,missed)
    local event=snapshot(b);event.actor=actor;event.label=label;event.amount=amount or 0;event.target=target;event.kind=kind;event.missed=missed
    round.events[#round.events+1]=event
    for _,enemy in ipairs(b.enemies)do if enemy.hp<=0 and not enemy.defeatedAt then enemy.defeatedAt=round.at+(#round.events-1)*(P.eventDuration or 1.4)+(P.impactDelay or .2)end end
  end
  local function emit(source,label,amount,target,kind,missed)
    record(type(source)=='number'and source or source.index,label,amount,target.index,kind,missed)
    if kind=='heal'then round.heal=round.heal+amount end
  end
  local actors={}
  for _,u in ipairs(b.allies)do
    if u.hp>0 then actors[#actors+1]={ally=u,speed=P.CombatSpeed(u)*(u.effects.slow and .65 or 1),order=1-u.index}end
  end
  for _,e in ipairs(b.enemies)do if e.hp>0 then for strike=1,(e.actions or 1)do actors[#actors+1]={enemy=e,speed=P.CombatSpeed(e),order=3+e.index+(strike-1)*10}end end end
  table.sort(actors,function(a,c)return a.speed==c.speed and a.order<c.order or a.speed>c.speed end)
  for _,actor in ipairs(actors)do
    if #living(b.enemies)==0 or #living(b.allies)==0 then break end
    local u=actor.ally
    local acting=u or actor.enemy
    if acting.hp>0 and acting.abilityTickTurn~=b.turn then P.BeginAbilityAction(acting,emit);acting.abilityTickTurn=b.turn end
    if u and u.hp>0 then
      -- A defense lasts until its owner's next action, including attacks from
      -- faster enemies in the following round. Do not expire it globally.
      u.guarding=false;u.shield=false
      local stunned=u.effects.stun~=nil;local frozen=u.effects.freeze~=nil;local slowed=u.effects.slow~=nil
      for _,key in ipairs({"poison","burn","freeze","slow","stun"})do local effect=u.effects[key]
        if effect then
          if effect.damage then local hurt=math.min(u.hp,math.max(1,math.floor(effect.damage*(1-P.TalentBonus("resistance")))));u.hp=u.hp-hurt;round.hurt=round.hurt+hurt;record(effect.source,P.enemySpells[key].label.." tick",hurt,u.index,"tick")end
          effect.turns=effect.turns-1;if effect.turns<=0 then u.effects[key]=nil end
          if u.hp<=0 then break end
        end
      end
      if u.hp>0 then
        local effects=P.GearEffects(u.pet)
        if effects.renewal and (b.turn+1)%5==0 then local n=math.min(u.maxHP-u.hp,math.floor(u.maxHP*.02));u.hp=u.hp+n;if n>0 then record(u.index,"Renewal",n,u.index,"heal")end end
        local chosen=(action=="auto" or action=="heal") and P.AutoAction(u,u.pet) or action
        local ability=u.nextAbility or P.ChooseAbility(u.pet,false) or P.Ability(u.pet);u.nextAbility=nil
        if chosen=="burst" and (not ability or P.SpecialCooldown(u,ability)>0)then chosen="strike"end
        P.TickSpecialCooldowns(u)
        local offensive=chosen=="strike" or (chosen=="burst" and not P.IsHealingAbility(ability));local delayed=false
        if slowed and offensive then u.attackProgress=(u.attackProgress or 0)+.65;if u.attackProgress<1 then delayed=true else u.attackProgress=u.attackProgress-1 end end
        if u.effects.stun or stunned or offensive and (frozen or delayed)then
          if u.manualSpecialAttempt then u.queuedSpecial=u.manualSpecialAttempt;u.manualSpecialAttempt=nil end
          record(u.index,stunned and "Stunned" or frozen and "Frozen - attack skipped" or "Slowed - winding up",0,u.index,"skip")
        elseif chosen=="guard"then u.guarding=true;record(u.index,"Guard",0,u.index,"guard")
        elseif chosen=='burst'and ability.reworked then
          local dealt=P.ResolveSpecialAbility(u,ability,b.enemies,b.allies,H.TargetEnemy(b.enemies),b.turn,emit,effects)
          round.hit=round.hit+dealt;P.StartSpecialCooldown(u,ability);u.manualSpecialAttempt=nil
        else
          local effect=chosen=="burst" and ability.effect or "strike"
          local mult=chosen=="burst" and ability.power or effect=="bite" and 1.8 or effect=="flurry" and 1.65 or effect=="cleave" and .9 or effect=="renew" and .8 or effect=="drain" and 1.1 or 1
          local target=H.TargetEnemy(b.enemies);local actual=0
          local power=P.CombatAttack(u)*(.9+P.random(0,20)/100)
          if effects.critical and P.random(1,100)<=5 then power=power*1.25 end
          for _,e in ipairs(b.enemies)do if e.hp>0 and (e==target or effect=="cleave")then
            local hit=P.random(1,100)<=math.min(99,P.HitChance(actor.speed,e.speed)+(effects.precision and 2 or 0))
            local amount=hit and P.AbsorbAbilityDamage(e,damage(power*mult*(e.shield and (1-e.shield) or 1),P.CombatArmor(e)),u,emit) or 0;e.hp=e.hp-amount;actual=actual+amount;round.hit=round.hit+amount
            if hit and chosen=="burst" and ability.control then P.ApplyControl(e,ability,b.turn)end
            record(u.index,hit and (chosen=="burst" and ability.ability or "Strike") or "Miss",amount,e.index,chosen,not hit)
          end end
          local healAmount=effect=="renew" and math.floor(u.maxHP*(ability.healing or .18)) or effect=="drain" and math.floor(actual*(ability.healing or .6)) or 0
          if effects.leech then healAmount=healAmount+math.floor(math.min(actual*.03,u.maxHP*.03))end
          local n=math.min(u.maxHP-u.hp,healAmount);u.hp=u.hp+n;if n>0 then record(u.index,"Ability heal",n,u.index,"heal")end
          u.shield=effect=="shield" and (ability.reduction or .55);if chosen=="burst"then P.StartSpecialCooldown(u,ability);u.manualSpecialAttempt=nil end
        end
        u.guardStreak=chosen=="guard" and (u.guardStreak or 0)+1 or 0;u.turn=u.turn+1
      end
    elseif actor.enemy and actor.enemy.hp>0 then
      local e=actor.enemy;local targets=living(b.allies);local t=targets[P.random(1,#targets)]
      if P.ControlBlocked and P.ControlBlocked(e,b.turn)then record(e.index,"Controlled - action skipped",0,e.index,"skip")
      elseif not (H.TryEnemySpecial and H.TryEnemySpecial(b,e,t,record)) then
      local cast=e.spell and (b.turn+e.index)%e.spellEvery==0;local spell=cast and P.enemySpells[e.spell]
      local hit=P.random(1,100)<=P.HitChance(P.CombatSpeed(e),P.CombatSpeed(t)*(t.effects.slow and .65 or 1))
      if not hit then record(e.index,"Miss",0,t.index,"strike",true)
      else
        local heavy=(b.turn+1)%3==0
        local power=P.CombatAttack(e)*(spell and .65 or heavy and (e.rare and 1.35 or 1.85) or 1)*(t.guarding and .25 or t.shield and (1-(type(t.shield)=="number" and t.shield or .55)) or 1)
        local crit=e.critChance and P.random(1,100)<=e.critChance
        if crit then power=power*(e.critMultiplier or 1.5)end
        local n=damage(power,P.CombatArmor(t));local effects=P.GearEffects(t.pet)
        if effects.ward and P.random(1,100)<=8 then n=math.max(1,math.floor(n*.75))end
        n=P.AbsorbAbilityDamage(t,n,e,emit);t.hp=t.hp-n;round.hurt=round.hurt+n
        if spell and t.hp>0 and not t.guarding then t.effects[e.spell]={turns=spell.turns,source=e.index,damage=spell.power and damage(e.attack*spell.power,t.armor)}end
        record(e.index,(crit and "CRITICAL! " or "")..(spell and spell.name or heavy and "Elite heavy attack" or "Attack"),n,t.index,spell and "cast" or "strike")
        round.events[#round.events].critical=not not crit
      end
      end
    end
    if acting.abilityEndTurn~=b.turn then P.EndAbilityAction(acting);acting.abilityEndTurn=b.turn end
  end
  b.turn=b.turn+1;sync(b)
  round.duration=math.max(1.6,#round.events*(P.eventDuration or 1.4)+.3)
  if #living(b.allies)==0 then
    P.defeat={pet=b.team[1],round=round,floor=b.floor,at=(GetTime and GetTime() or F.Now())+round.duration}
    P.state.battle=nil;P.victory=nil;P.notice="Your team has died. Replace the fallen pets with living companions.";return true
  end
  if #living(b.enemies)==0 and not b.rewarded then
    b.rewarded=true;local first=not P.state.hardMode.cleared[b.floor]
    P.state.battle=nil;local earned=0
    for _,u in ipairs(b.allies)do
      if not u.pet.deadAt then u.pet.wins=u.pet.wins+1 end
      do local old=u.pet.level;local savedHealth=u.pet.health;local xp=P.AddXP(u.pet,P.TowerXP(b.floor,first),"tower");earned=earned+xp
        if u.pet.level>old then u.maxHP=P.Stats(u.pet);u.hp=u.maxHP
        else u.pet.health=savedHealth end
        local receipt=P.progressEvents[u.pet.id];if xp>0 and receipt then receipt.at=(GetTime and GetTime() or F.Now())+round.duration end
      end
    end
    local tokens=P.AwardTokens(first and 30+b.floor*3 or 3,"towerTokens")
    P.TowerLoot(b);round.final=snapshot(b)
    P.victory={hard=true,petID=b.petID,floor=b.floor,first=first,xp=earned,tokens=tokens,treats=0,herbs=0,loot=b.presentationLoot,round=round,readyAt=round.at+round.duration}
    P.notice="Hard floor "..b.floor.." cleared by your team. +"..tokens.." tokens."
  else
    b.enemy=living(b.enemies)[1];P.notice="Round "..b.turn..": "..#living(b.allies).." pets / "..#living(b.enemies).." elites remaining."
  end
  return true
end
function P.AdvanceBattle(dt,visible)
  local b=P.state.battle;if not b or b.paused or not visible then return end
  b.elapsed=b.elapsed+math.min(dt,.25)
  if b.elapsed<(P.lastRound and P.lastRound.duration or 1.6)then return end
  b.elapsed=0;P.BattleAction("auto");if P.Render then P.Render()end
end
local tick=P.Tick
function P.Tick(seconds)tick(seconds)end
local open=P.OpenPage
function P.OpenPage(mode)
  if mode=="tower" and not P.state.battle then local team=H.Team();for i=1,3 do local pet=team[i];if pet and not pet.deadAt then P.state.active=pet.id;break end end end
  return open(mode)
end

H.Combat={}
for _,name in ipairs({"Unlocked","FloorStatus","BattleReadiness","StartBattle","BattleAction","AdvanceBattle","Tick","OpenPage","HealChoice","RequestHeal","CycleStyle","AbilityHelp"})do H.Combat[name]=P[name];P[name]=H.Normal[name]end
