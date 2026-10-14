local _,F=...
local P,H,A=F.Pets,F.Pets.HardMode,F.Achievements
P.controlAbilityCatalog=true
P.enemySpells.stun={name="Hammer of Justice",label="Stunned",turns=1,help="Skips the next pet action. Herbs still work."}

-- Keep every historical kind/ID unchanged. Only future ordinary loot uses this
-- canonical pool; an identical profile in a different equipment slot is valid.
P.distinctGearPools={normal={},special={}}
local seen={}
for id,d in ipairs(P.gearTypes)do
  if not d.hardSet and not d.hardTier then
    local key=table.concat({d.slot,d.hp or 0,d.attack or 0,d.armor or 0,d.speed or 0,d.effect or ""},":")
    if not seen[key]then
      seen[key]=true
      local pool=d.effect and P.distinctGearPools.special or P.distinctGearPools.normal
      pool[#pool+1]=id
    end
  end
end
function P.RollGearKind(rarity)
  local pools=P.distinctGearPools
  local pool=rarity>=3 and P.random(1,10000)<=100 and pools.special or pools.normal
  return pool[P.random(1,#pool)]
end

function A.RewardTooltipText(d,kind)
  if kind=="tokens"then return tostring(d.tokens or 0).." tokens"end
  if kind=="crate"then return P.BagDefinition({crate=d.crate}).name end
  if kind=="pet"then return A.PetKnown(d) and (P.rarities[d.rarity].." "..P.species[d.pet]) or "Secret companion"end
  if kind=="frame"then return A.FrameVisible(d.frame) and (A.frames[d.frame].name.." portrait frame") or "Secret portrait frame"end
  return A.RewardText(d,A.PetKnown(d),false)
end
function A.ShowRewardTooltip(owner,d,kind)
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(d.name)
  GameTooltip:AddLine(A.RewardTooltipText(d,kind),1,.82,.3,true)
  local done=P.state.achievements.claimed[d.id]
  GameTooltip:AddLine(A.Settled(d) and "Claimed" or (done or A.Progress(d)>=d.goal) and "Ready to claim" or "Complete this achievement to claim.",1,1,1,true)
  GameTooltip:Show()
end

function P.IsManualAbility(a)
  return a and (P.IsHealingAbility(a) or a.control~=nil)
end
local ensureAbilities=P.EnsureAbilities
function P.EnsureAbilities(pet)
  ensureAbilities(pet)
  local saved=type(pet.autoSpecials)=="table" and pet.autoSpecials or {}
  pet.autoSpecials={}
  for _,id in ipairs(pet.abilities)do
    if saved[id]==true and P.IsManualAbility(P.specialAbilities[id])then pet.autoSpecials[id]=true end
  end
end
function P.SpecialIsAuto(pet,slot)
  return pet and type(pet.autoSpecials)=="table" and pet.autoSpecials[pet.abilities[slot]]==true
end
function P.ChooseAbility(pet,healing)
  local list={}
  for _,a in ipairs(P.Abilities(pet))do
    if healing and P.IsHealingAbility(a) or not healing and not P.IsManualAbility(a)then list[#list+1]=a end
  end
  if #list>0 then return list[P.random(1,#list)]end
end
local help=P.AbilityHelp
function P.EnemySpecialHelp(enemy)
  local a=enemy and P.specialAbilities[enemy.abilityID]
  return a and ("\nSpecial: "..a.ability.."\n"..help(a):gsub(" Select its special button to use it next turn%.","")) or ""
end
function P.AbilityHelp(a)
  return (type(a)=="table" and (P.IsManualAbility(a) and "Manual special (optional auto)\n" or "Automatic special\n") or "")..help(a)
end
function P.ApplyControl(target,ability,turn,source)
  if not ability.control or (target.controlReadyTurn or -1)>turn or target.hp<=0 then return end
  target.controlReadyTurn=turn+3
  if target.pet then target.effects[ability.control]={turns=1,source=source or 1}
  else target.control=ability.control end
end
function P.ControlBlocked(target,turn)
  if target.controlSkippedAt==turn then return true end
  if target.control then target.control=nil;target.controlSkippedAt=turn;return true end
  return false
end
local function specialTarget()
  local b=P.state and P.state.battle
  -- Selection also controls the preview and auto-use preferences before combat.
  local pet=H.Target()
  return pet,b and pet and H.Unit(pet.id,b),b
end
function P.ToggleAutoSpecial(slot)
  local pet=specialTarget()
  if type(slot)~="number" or slot~=math.floor(slot) or slot<1 or slot>2 or not pet then return false,"Choose a special."end
  local a=P.Abilities(pet)[slot]
  if not P.IsManualAbility(a)then return false,"This ability is already automatic."end
  pet.autoSpecials=type(pet.autoSpecials)=="table" and pet.autoSpecials or {}
  local id=pet.abilities[slot];pet.autoSpecials[id]=not pet.autoSpecials[id] or nil
  return true,a.ability..(pet.autoSpecials[id] and ": automatic use enabled." or ": manual use enabled.")
end
function P.SpecialChoice(slot)
  local pet,u,b=specialTarget()
  local ability=pet and P.Abilities(pet)[slot]
  if not ability or not P.IsManualAbility(ability)then return nil,"This special is automatic.",ability end
  if not b or not u then return nil,"Available during a tower battle.",ability end
  if pet.deadAt or u.hp<=0 then return nil,"This pet has fallen.",ability end
  if u.queuedSpecial==slot then return true,"Selected for next action. Click to cancel.",ability end
  local cooldown=P.SpecialCooldown(u,ability)
  if cooldown>0 then return nil,"Ready in "..cooldown.." pet turns.",ability end
  return true,"Use on this pet's next action.",ability
end
function P.RequestSpecial(slot)
  if type(slot)~="number" or slot~=math.floor(slot) or slot<1 or slot>2 then return false,"Invalid ability slot."end
  local ready,why,ability=P.SpecialChoice(slot)
  if not ready then return false,why end
  local _,u=specialTarget()
  u.queuedSpecial=u.queuedSpecial~=slot and slot or nil
  return true,u.queuedSpecial and (ability.ability.." selected for next action.") or "Special cancelled."
end
function P.AutoAction(u,pet)
  if u.queuedSpecial then
    local ability=P.Abilities(pet)[u.queuedSpecial]
    if ability and P.SpecialCooldown(u,ability)==0 then
      if u.effects and (u.effects.stun or u.effects.freeze and not P.IsHealingAbility(ability))then return "guard"end
      u.manualSpecialAttempt=u.queuedSpecial;u.queuedSpecial=nil;u.nextAbility=ability;return "burst"
    end
    if not ability then u.queuedSpecial=nil end
  end
  local choices,ready={},{}
  for slot,a in ipairs(P.Abilities(pet))do
    if not P.IsManualAbility(a) or P.SpecialIsAuto(pet,slot) and (not P.IsHealingAbility(a) or u.hp<u.maxHP*.85)then
      choices[#choices+1]=a;if P.SpecialCooldown(u,a)==0 then ready[#ready+1]=a end
    end
  end
  -- Keep the original RNG cadence for pets with zero or one special.
  local pick=#choices>0 and P.random(1,#choices) or nil
  local a=pick and (#ready>0 and ready[(pick-1)%#ready+1] or choices[pick]) or nil
  u.nextAbility=a
  local style=P.styles[pet.style or 1] or P.styles[1]
  local burst=a and P.SpecialCooldown(u,a)==0 and style.burst or 0
  local guard=(u.guardStreak or 0)>=1 and 0 or style.guard
  local roll=P.random(1,style.strike+guard+burst)
  return roll<=guard and "guard" or roll<=guard+burst and "burst" or "strike"
end

-- Enemies draw from the same full ability catalogue without borrowing player
-- rolled strength. One special per cooldown, even on a multi-action rare.
local defaults={bite={1.8,0},flurry={1.65,0},cleave={.9,0},renew={.8,.18},drain={1.1,.6},shield={1,0,.55}}
function H.TryEnemySpecial(b,e,target,record)
  if e.defenseTurn~=b.turn then e.shield=nil;e.defenseTurn=b.turn end
  local a=P.specialAbilities[e.abilityID]
  if not a or b.turn<(e.nextSpecialTurn or e.index%3)then return false end
  e.nextSpecialTurn=b.turn+(a.cooldown or 3)
  if a.reworked then
    P.ResolveSpecialAbility(e,a,b.allies,b.enemies or {e},target,b.turn,function(source,label,n,t,kind,missed)
      record(type(source)=='number'and source or source.index,label,n,t.index,kind,missed)
    end)
    return true
  end
  local d=defaults[a.effect];local dealt=0
  for _,t in ipairs(b.allies)do
    if t.hp>0 and (t==target or a.effect=="cleave")then
      local hit=P.random(1,100)<=P.HitChance(e.speed,t.speed*(t.effects.slow and .65 or 1))
      local mitigation=t.guarding and .25 or t.shield and (1-(type(t.shield)=="number" and t.shield or .55)) or 1
      local power=e.attack*(a.power or d[1])*mitigation
      local crit=hit and e.critChance and P.random(1,100)<=e.critChance
      if crit then power=power*(e.critMultiplier or 1.5)end
      local n=hit and math.max(1,math.floor(power*(1-math.min(60,t.armor)/100))) or 0
      if hit and P.GearEffects(t.pet).ward and P.random(1,100)<=8 then n=math.max(1,math.floor(n*.75))end
      n=math.min(t.hp,n);t.hp=t.hp-n;dealt=dealt+n
      if hit and a.control and not t.guarding then P.ApplyControl(t,a,b.turn,e.index)end
      record(e.index,a.ability,n,t.index,"cast",not hit)
    end
  end
  local heal=a.effect=="renew" and e.maxHP*(a.healing or d[2]) or a.effect=="drain" and dealt*(a.healing or d[2]) or 0
  heal=math.min(e.maxHP-e.hp,math.floor(heal))
  if heal>0 then e.hp=e.hp+heal;record(e.index,a.ability,heal,e.index,"heal")end
  if a.effect=="shield"then e.shield=a.reduction or d[3]end
  return true
end

local function buttons(parent,compact)
  local result={}
  for slot=1,2 do
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate");result[slot]=b
    b:SetSize(compact and 34 or 44,compact and 34 or 44)
    b:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",3,-3);b.art:SetPoint("BOTTOMRIGHT",-3,3)
    b.status=b:CreateFontString(nil,"OVERLAY");b.status:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",11,"OUTLINE");b.status:SetAllPoints()
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetScript("OnClick",function(self,button)local _,why
      if button=="RightButton"then _,why=P.ToggleAutoSpecial(self.slot)else _,why=P.RequestSpecial(self.slot)end
      P.notice=why;P.Render()
    end)
    b:SetScript("OnEnter",function(self)
      local _,why,a=P.SpecialChoice(self.slot);if not a then return end
      GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(a.ability)
      GameTooltip:AddLine(P.AbilityHelp(a),1,1,1,true);GameTooltip:AddLine(why,.7,.85,1,true)
      local pet=specialTarget();GameTooltip:AddLine(P.SpecialIsAuto(pet,self.slot) and "Auto: ON. Right-click for manual use." or "Auto: OFF. Right-click to add to rotation.",.5,1,.5,true);GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end);b:Hide()
  end
  return result
end
local function refresh(view,compact,show)
  if not view then return end
  if not rawget(view,"specialButtons")then view.specialButtons=buttons(compact and view.footer or view.home,compact)end
  local pet,u=specialTarget();local abilities=pet and P.Abilities(pet) or {}
  local size=compact and 34 or 44;local width=compact and 284 or 476
  local slots={};for i,a in ipairs(abilities)do if P.IsManualAbility(a)then slots[#slots+1]=i end end
  local count=3+#slots;local gap=width/count;local y=compact and -322 or -598
  local main=compact and view.battle or view.fight
  if show then for i,b in ipairs(main)do b:ClearAllPoints();b:SetPoint("TOPLEFT",compact and view.footer or view.home,"TOPLEFT",gap*(i-.5)-b:GetWidth()/2,y)end end
  for i,b in ipairs(view.specialButtons)do
    local slot=slots[i];local a=slot and abilities[slot];b.slot=slot;b:SetShown(show and a~=nil)
    if a then
      b:ClearAllPoints();b:SetPoint("TOPLEFT",compact and view.footer or view.home,"TOPLEFT",gap*(i+2.5)-size/2,y)
      b.art:SetTexture("Interface\\Icons\\"..a.icon)
      local ready=P.SpecialChoice(slot);b:SetEnabled(true);b.art:SetDesaturated(not ready)
      local selected=u and u.queuedSpecial==slot
      b:SetBackdropBorderColor(selected and 1 or .45,selected and .82 or .45,selected and .15 or .45,1)
      local cooldown=P.SpecialCooldown(u,a)
      b.status:SetText(selected and "Next" or cooldown>0 and cooldown or P.SpecialIsAuto(pet,slot) and "Auto" or "")
    else
      b.status:SetText("")
    end
  end
end
local render=P.Render
function P.Render(...)local result=render(...);if P.state then refresh(P.window,false,P.mode=="tower")end;return result end
local compass=P.RenderCompass
function P.RenderCompass(...)local result=compass(...);if P.state then refresh(P.mini,true,P.miniMode=="tower")end;return result end

-- Queues and turn cooldowns belong to one encounter, never to the pet.
local function resetBattleSpecials(b)
  if not b then return end
  local function reset(u)
    u.cooldown=0;u.specialCooldowns=nil;u.queuedSpecial=nil;u.manualSpecialAttempt=nil
    u.nextAbility=nil;u.healAbility=nil
  end
  reset(b)
  for _,u in ipairs(b.allies or {})do reset(u)end
end
local function refreshSpecials()
  refresh(P.window,false,P.mode=="tower")
  refresh(P.mini,true,P.miniMode=="tower")
end
local startBattle=P.StartBattle
function P.StartBattle(...)
  local prior=P.state and P.state.battle
  local ok,why=startBattle(...)
  if ok and P.state.battle and P.state.battle~=prior then
    resetBattleSpecials(P.state.battle);refreshSpecials()
  end
  return ok,why
end
local battleAction=P.BattleAction
function P.BattleAction(...)
  local prior=P.state and P.state.battle
  local ok,why=battleAction(...)
  if prior and P.state.battle~=prior then
    resetBattleSpecials(prior);refreshSpecials()
  end
  return ok,why
end
