local _,F=...
local P=F.Pets
local function text(parent,size)
  local t=parent:CreateFontString(nil,"OVERLAY")
  t:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,"OUTLINE");t:SetJustifyH("CENTER");t:SetSize(120,26);t:Hide();return t
end
local effects={
  {key="poison",icon="Spell_Nature_CorrosiveBreath"},{key="burn",icon="Spell_Fire_Fire"},
  {key="stun",icon="Spell_Holy_SealOfMight"},{key="freeze",icon="Spell_Frost_FrostNova"},{key="slow",icon="Spell_Shadow_Cripple"},
}
function P.CombatTextEvent(event)
  if not event then return end
  local healing=event.kind=="heal" or event.label=="Ability heal" or event.label=="Renewal" or event.label=="Leech"
  if healing and event.amount>0 then return "+"..math.ceil(event.amount).." HP",{.2,1,.3},event.target or event.actor end
  if event.kind=="guard" or event.label=="Guard"then return "Guard",{.5,.8,1},event.target or event.actor end
  if event.missed then return "Miss",{.85,.85,.85},event.target or (event.actor<=0 and 1 or 0)end
  if event.amount and event.amount>0 then
    local ally=event.actor>0 or event.kind=="tick"
    return (ally and "-" or "")..math.ceil(event.amount),ally and {1,.15,.15} or {1,1,1},event.target or (ally and 0 or 1)
  end
end
local function floating(f,value,color,target,stamp)
  f.damageCursor=(f.damageCursor or 0)%#f.damageTexts+1
  local t=f.damageTexts[f.damageCursor];t.value=value;t.target=target or 0;t.at=stamp
  t:SetText(value);t:SetTextColor(unpack(color));t:Show()
end
function P.UpdateCombatText(f)
  if not f.tower and not rawget(f,"damageTexts")then return end
  if not rawget(f,"damageTexts") then
    f.damageTexts={};f.debuffIcons={};f.damageCursor=0
    for i=1,20 do f.damageTexts[i]=text(f.hud,f.width>300 and 18 or 14);f.damageTexts[i].at=false end
    for ally=1,3 do for column,d in ipairs(effects)do
      local b=CreateFrame("Button",nil,f.hud);f.debuffIcons[#f.debuffIcons+1]=b
      b:SetSize(16,16);b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",8+(ally-1)*88+(column-1)*17,62)
      b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetAllPoints();b.art:SetTexture("Interface\\Icons\\"..d.icon)
      b.turns=text(b,10);b.turns:SetAllPoints();b.turns:Show();b.key=d.key;b.ally=ally;b.remaining=false;b.damage=false;b:Hide()
      b:SetScript("OnEnter",function(self)
        local spell=P.enemySpells[self.key];GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(spell.label)
        GameTooltip:AddLine((self.petName or "Companion")..": "..(self.remaining or 0).." pet turn(s) remaining.",1,1,1)
        GameTooltip:AddLine(spell.help,1,1,1,true)
        if self.damage then GameTooltip:AddLine(self.damage.." damage per tick before talent resistance.",1,.4,.4,true)end
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end end
  end
  local now=P.sceneClock or 0;local round=f.tower and f.round
  if not round then
    if not rawget(f,"damageRound")then return end
    for _,t in ipairs(f.damageTexts)do t:Hide();t.at=false end
    for _,b in ipairs(f.debuffIcons)do b:Hide();b.remaining=false end
    f.damageRound=false;return
  end
  if f.damageRound~=round then f.damageRound=round;f.damageIndex=0 end
  local index=math.min(#round.events,math.floor((now-round.at-P.impactDelay)/P.eventDuration)+1)
  for i=(f.damageIndex or 0)+1,index do
    local stamp=round.at+(i-1)*P.eventDuration+P.impactDelay
    local value,color,target=P.CombatTextEvent(round.events[i])
    if value and now-stamp<1.25 then floating(f,value,color,target,stamp)end
  end
  f.damageIndex=math.max(f.damageIndex or 0,index)
  local _,snapshot=P.VisualEvent(round,now)
  local active=P.state.battle~=nil or now<round.at+round.duration
  for _,b in ipairs(f.debuffIcons)do
    local pet=round.team and round.team[b.ally] or b.ally==1 and round.pet
    local state=snapshot and (snapshot.allyEffects and snapshot.allyEffects[b.ally] or b.ally==1 and snapshot.effects)
    local turns=active and pet and state and state[b.key]
    if turns and (not b.remaining or turns>b.remaining)then floating(f,P.enemySpells[b.key].label,{.5,.75,1},1-b.ally,now)end
    b.remaining=turns or false;b:SetShown(not not turns)
    if turns then
      b.turns:SetText(turns);b.petName=P.species[pet.species]
      local unit=P.HardMode.Unit(pet.id);b.damage=unit and unit.effects and unit.effects[b.key] and unit.effects[b.key].damage or false
    end
  end
  for i,t in ipairs(f.damageTexts)do if t.at then
    local age=now-t.at;t:SetShown(age>=0 and age<1.25)
    if age>=1.25 then t.at=false end
    if age>=0 and age<1.25 then
      local target=t.target;local ally=target<=0;local slot=ally and 1-target or target
      local x=ally and .25 or (.65+math.floor((slot-1)/3)*.17)
      local y=f.hudHeight+f.arenaHeight*(.35+((slot-1)%3)*.15)
      t:ClearAllPoints();t:SetPoint("CENTER",f,"TOPLEFT",f.width*x+(i%3-1)*12,-y+(F.db.settings.reduceMotion and 0 or age*28))
      t:SetAlpha(math.min(1,(1.25-age)*3))
    end
  end end
end
function P.StatHelp(pet,index)
  local hp,attack,armor,speed=P.Stats(pet)
  local battle=P.state.battle;local other=battle and battle.enemy and battle.enemy.speed or speed
  local hit=P.HitChance(speed,other)
  local lines={
    string.format("%d maximum HP. Your pet can take this much damage before dying in a tower fight.",hp),
    string.format("%.1f attack. Basic damage varies by about 10%%, then enemy armor reduces it. Specials use their listed attack multiplier.",attack),
    string.format("%.1f%% armor. It reduces incoming damage by %.1f%% (maximum 60%%). A 100-damage hit becomes about %d damage before other defenses.",armor,math.min(60,armor),math.max(1,math.floor(100*(1-math.min(60,armor)/100)))),
    string.format("%.1f speed. Higher speed acts earlier in each round and improves hit chance against slower enemies. Slowed reduces effective speed to %.1f.",speed,speed*.65),
    string.format("%.0f%% hit chance against %s. Faster opponents are harder to hit.",hit,battle and "the current enemy" or "an equally fast enemy"),
    string.format("%.0f%% miss chance against %s. A miss deals no attack damage.",100-hit,battle and "the current enemy" or "an equally fast enemy"),
    "Level "..pet.level..". "..P.XPText(pet)..". Your current pet level cap is "..P.LevelCap()..".",
  }
  return lines[index] or ""
end
