local _,F=...
local P=F.Pets
-- Stable IDs, fresh mechanics: saved pets keep their IDs and rolled strength.
local changes={
 ['Savage Bite']={power=1.5,execute=true,brief='Deal 150% attack damage; 50% more against a target below 35% health.'},
 ['Flurry']={power=.55,hits=3,brief='Three separate 55% attacks against one enemy. Each can hit or miss.'},
 ['Wild Nova']={power=.9,brief='Deal 90% attack damage to every enemy.'},
 ['Wild Growth']={power=.8,healing=.18,brief='Strike for 80% attack and restore 18% of your maximum health.'},
 ['Life Drain']={power=1.1,healing=.6,brief='Deal 110% attack damage and heal for 60% of damage dealt.'},
 ['Iron Hide']={power=1,reduction=.55,brief='Strike for 100% attack and reduce incoming damage by 55% until your next action.'},
 ['Rending Bite']={power=1.1,dot=.3,dotTurns=3,brief='Strike for 110% attack; a landed hit bleeds for 30% attack on the next three actions.'},
 ['Crushing Jaw']={power=1.5,pierce=.5,brief='Deal 150% attack damage, ignoring half the target\'s armor.'},
 ['Lunging Strike']={power=1.2,targetMode='fastest',accurate=true,brief='An unavoidable 120% strike at the fastest enemy.'},
 ['Horn Gore']={power=1,splash=.6,pierce=.25,brief='Gore the target for 100% attack and one other enemy for 60%; ignore 25% armor.'},
 ['Stonebreaker']={power=1.2,shred=15,brief='Strike for 120% attack and reduce the target\'s armor by 15 points for two actions.'},
 ['Quick Claws']={power=.65,hits=2,accurate=true,brief='Two unavoidable strikes, each dealing 65% attack damage.'},
 ['Tail Lash']={power=1.1,splash=.8,brief='Strike the target for 110% attack and lash one other enemy for 80%.'},
 ['Wing Buffet']={power=.55,spread='all',weaken=.2,brief='Hit all enemies for 55% attack; landed hits reduce their attack by 20% for two actions.'},
 ['Pouncing Fury']={power=1.3,opener=true,brief='Deal 130% attack damage; double damage against a target above 90% health.'},
 ['Mechanical Barrage']={power=.6,hits=3,spread='random',brief='Fire three 60% attacks at independently chosen living enemies.'},
 ['Frost Burst']={power=.65,slow=.3,brief='Hit every enemy for 65% attack and slow landed targets by 30% for two actions.'},
 ['Flame Wave']={power=.55,dot=.2,dotTurns=2,brief='Hit all enemies for 55% attack; landed hits burn for 20% attack on their next two actions.'},
 ['Thunder Clap']={power=.6,shred=8,brief='Hit all enemies for 60% attack and reduce their armor by 8 points for two actions.'},
 ['Shadow Pulse']={power=.7,drain=.2,brief='Hit all enemies for 70% attack and heal for 20% of the total damage.'},
 ['Arcane Burst']={power=.7,pierce=.5,brief='Hit every enemy for 70% attack, ignoring half their armor.'},
 ['Rejuvenating Song']={power=.4,healing=0,regen=.05,regenTurns=3,healMode='all',brief='Strike for 40% attack. All living allies recover 5% maximum health on their next three actions.'},
 ['Mending Roots']={power=.6,healing=.14,cleanse='poison',guard=.2,brief='Strike for 60%, heal 14% maximum health, remove poison and reduce damage by 20% until your next action.'},
 ['Soothing Mist']={power=.5,healing=.2,healMode='lowest',cleanse='burn',brief='Strike for 50% attack; heal the most injured ally for 20% maximum health and remove its burn.'},
 ['Renewing Light']={power=.4,healing=.1,healMode='all',brief='Strike for 40% attack and heal every living ally for 10% of its maximum health.'},
 ['Self Repair']={power=.3,healing=.4,missingHeal=true,cleanse='dots',brief='Strike for 30% attack, repair 40% of your missing health and remove poison, burn and bleed.'},
 ['Vampiric Bite']={power=1.1,healing=.5,wounded=true,brief='Deal 110% attack and drain half the damage. Deal 50% more while below half health.'},
 ['Soul Sip']={power=.8,healing=.75,targetMode='caster',purge=true,brief='Target a spellcaster first, remove its shield and deal 80% attack; heal for 75% of damage.'},
 ['Leeching Claws']={power=.6,hits=2,healing=.5,brief='Two 60% attacks; each landed strike contributes to a 50% life drain.'},
 ['Essence Drain']={power=1,healing=.65,healMode='lowest',brief='Deal 100% attack; heal the most injured ally for 65% of damage dealt.'},
 ['Blood Feast']={power=1.2,healing=.25,killHeal=.18,brief='Deal 120% attack and drain 25% of damage. A killing blow also heals 18% maximum health.'},
 ['Shell Guard']={power=.7,reduction=0,barrier=.25,brief='Strike for 70% attack and gain a barrier absorbing 25% maximum health until your next action.'},
 ['Barkskin']={power=.8,reduction=.25,reflect=.3,brief='Strike for 80%; reduce damage by 25% and reflect 30% of damage taken until your next action.'},
 ['Stone Hide']={power=.6,reduction=.5,cleanse='all',brief='Strike for 60%, remove harmful effects and reduce damage by 50% until your next action.'},
 ['Shadow Veil']={power=.9,reduction=0,evade=true,brief='Strike for 90% attack and evade the next damaging hit before your next action.'},
 ['Crystal Carapace']={power=.6,reduction=.25,healMode='all',brief='Strike for 60% attack and shield every living ally for 25% damage reduction until each ally\'s next action.'},
 ['Frost Nova']={brief='Hit all enemies for 45% attack and freeze landed targets for one action. Brief control immunity follows.'},
 ['Hammer of Justice']={brief='Strike for 70% attack and stun the target for one action. Brief control immunity follows.'},
 ['Rift Fang']={power=1.4,pierce=1,purge=true,brief='Remove the target\'s shield and deal 140% attack, ignoring all armor.'},
 ["Titan's Bite"]={power=1.25,titan=true,brief='Deal 125% attack plus 5% of the target\'s maximum health, capped at 100% extra attack.'},
 ['Sundering Horn']={power=1.4,targetMode='armor',shred=20,brief='Strike the most armored enemy for 140% and strip 20 armor points for two actions.'},
 ['Tempest Claws']={power=.55,hits=2,spread='all',brief='Two sweeping strikes, each dealing 55% attack to every enemy.'},
 ['Astral Barrage']={power=.45,hits=3,ramp=true,brief='Three strikes at one target: 45%, 67.5%, then 90% attack if it survives.'},
 ['Void Pounce']={power=1.4,targetMode='lowest',execute=true,brief='Pounce on the lowest-health enemy for 140%; deal 50% more below 35% target health.'},
 ['Starfall Pulse']={power=.7,extraLowest=.6,brief='Hit all enemies for 70% attack, then hit the lowest-health survivor for another 60%.'},
 ['Volcanic Roar']={power=.9,selfCost=.05,dot=.25,dotTurns=2,brief='Spend 5% maximum health (never lethal); hit all enemies for 90% and burn landed targets for two 25% ticks.'},
 ['Glacial Ring']={power=.4,barrier=.12,brief='Freeze landed enemies with a 40% sweep and gain a 12% health barrier until your next action.'},
 ['Dream Renewal']={power=.4,healing=0,healMode='all',cleanse='all',regen=.04,regenTurns=3,brief='Strike for 40%; cleanse all living allies and restore 4% of their maximum health on each of three actions.'},
 ['Phoenix Mend']={power=.4,healing=.25,emergencyBarrier=.2,brief='Strike for 40% and heal 25% maximum health. If cast below 25% health, also gain a 20% health barrier.'},
 ['Ancient Regrowth']={power=.6,healing=.12,regen=.08,regenTurns=3,brief='Strike for 60%, heal 12% maximum health and restore another 8% on each of your next three actions.'},
 ['Abyssal Siphon']={power=.65,spread='all',healing=.3,cooldown=4,overflowBarrier=true,brief='Drain all enemies for 65% attack; heal for 30% of total damage. Excess healing becomes a barrier, capped at 25% health.'},
 ['Blood Moon Bite']={power=1,healing=.5,dot=.25,dotTurns=3,brief='Strike for 100% and drain half the damage; a landed hit adds three 25% attack bleed ticks.'},
 ['Soul Harvest']={power=1.2,healing=.3,targetMode='lowest',killHeal=.1,killTeam=true,brief='Strike the weakest enemy for 120% and drain 30%. A kill also heals all living allies for 10% maximum health.'},
 ['Obsidian Shell']={power=.7,reduction=.35,barrier=.15,healMode='lowest',brief='Strike for 70%; protect the most injured ally with 35% damage reduction and a 15% health barrier until its next action.'},
 ['Astral Ward']={power=.3,reduction=0,barrier=.12,healMode='all',brief='Strike for 30% attack and give every living ally a barrier worth 12% of its health until its next action.'},
 ["Titan's Verdict"]={power=.8,targetMode='attack',weaken=.25,brief='Strike the strongest attacker for 80%, stun it for one action and weaken its attack by 25% for two actions.'},
}
for _,a in ipairs(P.specialAbilities)do
 local c=assert(changes[a.ability],a.ability)
 for k,v in pairs(c)do a[k]=v end
 a.cooldown=a.cooldown or 3
 a.reworked=true;a.legacy=nil;a.hidden=a.hardOnly and true or nil
end
local help=P.AbilityHelp
function P.AbilityHelp(a)
 if type(a)=='table'and a.brief then
  local detail=a.brief
  if a.rollTier then detail='Base effect: '..detail..string.format('\nRolled damage/healing strength: %.0f%% of base.',P.AbilityRollFactor(a.rollTier,a.rollPercentile)*100)end
  return detail..' Own '..(a.cooldown or 3)..'-turn cooldown. One special per pet per turn.'
 end
 return help(a)
end
local function living(list)local out={};for _,u in ipairs(list)do if u.hp>0 then out[#out+1]=u end end;return out end
local function selectUnit(list,mode,fallback)
 local target=fallback and fallback.hp>0 and fallback or list[1]
 for _,u in ipairs(list)do
  if not target or mode=='lowest'and u.hp<target.hp or mode=='injured'and u.hp/u.maxHP<target.hp/target.maxHP or mode=='fastest'and u.speed>target.speed or mode=='armor'and u.armor>target.armor or mode=='attack'and u.attack>target.attack or mode=='caster'and (u.spell or u.abilityID)and not(target.spell or target.abilityID)then target=u end
 end
 return target
end
function P.CombatSpeed(u)return u.speed*(u.abilitySlow and (1-u.abilitySlow.amount)or 1)end
function P.CombatArmor(u)return math.max(0,u.armor-(u.abilityShred and u.abilityShred.amount or 0))end
function P.CombatAttack(u)return u.attack*(u.abilityWeak and (1-u.abilityWeak.amount)or 1)end
function P.BeginAbilityAction(u,emit)
 u.barrier=nil;u.reflect=nil;u.evade=nil
 for _,key in ipairs({'abilityDot','abilityRegen'})do local effect=u[key]
  if effect and u.hp>0 then
   local n=key=='abilityDot'and math.min(u.hp,effect.amount)or math.min(u.maxHP-u.hp,effect.amount)
   u.hp=u.hp+(key=='abilityDot'and -n or n);effect.turns=effect.turns-1
   if n>0 then emit(effect.source or u,effect.label,n,u,key=='abilityDot'and 'tick'or 'heal')end
   if effect.turns<=0 then u[key]=nil end
  end
 end
end
function P.EndAbilityAction(u)
 for _,key in ipairs({'abilityShred','abilityWeak','abilitySlow'})do local effect=u[key]
  if effect then effect.turns=effect.turns-1;if effect.turns<=0 then u[key]=nil end end
 end
end
function P.AbsorbAbilityDamage(target,amount,attacker,emit)
 if target.evade and amount>0 then target.evade=nil;emit(target,'Evade',0,target,'guard');return 0 end
 if target.barrier then local absorbed=math.min(amount,target.barrier);target.barrier=target.barrier-absorbed;amount=amount-absorbed end
 amount=math.min(target.hp,amount)
 if target.reflect and attacker and attacker.hp>0 and amount>0 then
  local n=math.min(attacker.hp,math.floor(amount*target.reflect));attacker.hp=attacker.hp-n
  if n>0 then emit(target,'Thorns',n,attacker,'tick')end
 end
 return amount
end
local function cleanse(u,kind)
 u.effects=u.effects or {}
 if kind=='all'then for _,key in ipairs({'poison','burn','slow','freeze','stun'})do u.effects[key]=nil end;u.control=nil;u.abilitySlow=nil;u.abilityWeak=nil;u.abilityShred=nil end
 if kind=='all'or kind=='dots'then u.effects.poison=nil;u.effects.burn=nil;u.abilityDot=nil
 elseif kind then u.effects[kind]=nil end
end
-- The same resolver is used by Normal, Hard Mode and enemy specials.
-- emit receives real units, keeping each mode's animation snapshots intact.
function P.ResolveSpecialAbility(u,a,enemies,allies,target,turn,emit,gear,rng)
 local dealt,healed,killed=0,0,false;local injured=u.hp<u.maxHP*.25
 gear=gear or {};local roll=rng or P.random
 local factor=a.rollTier and P.AbilityRollFactor(a.rollTier,a.rollPercentile)or 1
 if a.selfCost then u.hp=math.max(1,u.hp-math.floor(u.maxHP*a.selfCost))end
 local function hit(t,mult)
  if not t or t.hp<=0 then return end
  local success=a.accurate or roll(1,100)<=math.min(99,P.HitChance(P.CombatSpeed(u),P.CombatSpeed(t))+(gear.precision and 2 or 0))
  local n=0
  if success then
   if a.purge then t.shield=nil;t.barrier=nil end
   local bonus=(a.execute and t.hp<t.maxHP*.35 and 1.5 or 1)*(a.opener and t.hp>t.maxHP*.9 and 2 or 1)*(a.wounded and u.hp<u.maxHP*.5 and 1.5 or 1)
   local power=P.CombatAttack(u)*mult*bonus*(.9+roll(0,20)/100)
   if gear.critical and roll(1,100)<=5 then power=power*1.25 end
   if u.critChance and roll(1,100)<=u.critChance then power=power*(u.critMultiplier or 1.5)end
   if a.titan then power=power+math.min(t.maxHP*.05,P.CombatAttack(u))end
   local mitigation=t.guarding and .25 or t.shield and 1-(type(t.shield)=='number'and t.shield or .55)or 1
   n=math.max(1,math.floor(power*(1-math.min(60,P.CombatArmor(t))*(1-(a.pierce or 0))/100)*mitigation))
   if t.pet and P.GearEffects(t.pet).ward and roll(1,100)<=8 then n=math.max(1,math.floor(n*.75))end
   n=P.AbsorbAbilityDamage(t,n,u,emit);t.hp=t.hp-n;dealt=dealt+n;killed=killed or t.hp<=0
   if a.control and not t.guarding and P.ApplyControl then P.ApplyControl(t,a,turn,u.index or 0)end
   if t.hp>0 then
    if a.dot then t.abilityDot={amount=math.max(1,math.floor(P.CombatAttack(u)*a.dot*factor)),turns=a.dotTurns,source=u.index or 0,label=a.ability..' tick'}end
    if a.shred then t.abilityShred={amount=a.shred,turns=2}end
    if a.weaken then t.abilityWeak={amount=a.weaken,turns=2}end
    if a.slow then t.abilitySlow={amount=a.slow,turns=2}end
   end
  end
  emit(u,success and a.ability or 'Miss',n,t,'burst',not success)
 end
 local pool=living(enemies);target=selectUnit(pool,a.targetMode,target)
 local power=a.power or ({bite=1.8,flurry=1.65,cleave=.9,renew=.8,drain=1.1,shield=1})[a.effect]
 for step=1,a.hits or 1 do
  if u.hp<=0 then break end
  local mult=power*(a.ramp and (1+(step-1)*.5)or 1)
  if a.spread=='random'then local choices=living(enemies);if #choices>0 then hit(choices[roll(1,#choices)],mult)end
  elseif a.spread=='all'or a.effect=='cleave'then for _,t in ipairs(enemies)do hit(t,mult)end
  else hit(target,mult)end
 end
 if a.splash then for _,t in ipairs(enemies)do if t~=target and t.hp>0 then hit(t,a.splash*factor);break end end end
 if a.extraLowest then hit(selectUnit(living(enemies),'lowest'),a.extraLowest*factor)end
 if u.hp<=0 then return dealt,healed end
 local recipients=a.healMode=='all'and living(allies)or {a.healMode=='lowest'and selectUnit(living(allies),'injured',u)or u}
 for _,r in ipairs(recipients)do
  local amount=a.effect=='renew'and (a.missingHeal and r.maxHP-r.hp or r.maxHP)*(a.healing or .18)or a.effect=='drain'and dealt*(a.healing or .6)or dealt*(a.drain or 0)
  local wanted=math.floor(amount);local n=math.min(r.maxHP-r.hp,wanted);r.hp=r.hp+n;healed=healed+n
  if n>0 then emit(u,a.ability,n,r,'heal')end
  if a.cleanse then cleanse(r,a.cleanse);emit(u,'Cleanse',0,r,'guard')end
  if a.regen then r.abilityRegen={amount=math.max(1,math.floor(r.maxHP*a.regen*factor)),turns=a.regenTurns,source=u.index or 0,label=a.ability}end
  local guard=a.guard or a.effect=='shield'and a.reduction
  if guard and guard>0 then r.shield=math.max(type(r.shield)=='number'and r.shield or 0,guard)end
  local barrier=(a.barrier or 0)+(injured and a.emergencyBarrier or 0)
  if barrier>0 then r.barrier=math.max(r.barrier or 0,math.floor(r.maxHP*barrier*factor))end
  if a.overflowBarrier then r.barrier=math.max(r.barrier or 0,math.min(math.floor(r.maxHP*.25),wanted-n))end
  if a.reflect then r.reflect=a.reflect end;if a.evade then r.evade=true end
 end
 if killed and a.killHeal then for _,r in ipairs(a.killTeam and living(allies)or {u})do
  local n=math.min(r.maxHP-r.hp,math.floor(r.maxHP*a.killHeal*factor));r.hp=r.hp+n;healed=healed+n;if n>0 then emit(u,'Victory heal',n,r,'heal')end
 end end
 if gear.leech and dealt>0 then local n=math.min(u.maxHP-u.hp,math.floor(math.min(dealt*.03,u.maxHP*.03)));u.hp=u.hp+n;healed=healed+n;if n>0 then emit(u,'Leech',n,u,'heal')end end
 return dealt,healed
end
