local _,F=...
local P,H,S=F.Pets,F.Pets.HardMode,F.Style
local function label(parent,size)
  local t=parent:CreateFontString(nil,"OVERLAY");t:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,"OUTLINE");t:SetJustifyH("LEFT");return t
end
local function apply(fn)
  local ok,msg=fn();if msg then P.notice=msg end;P.Render();return ok
end
local styleIcons={"Ability_Hunter_BeastTaming","Ability_Warrior_SavageBlow","Ability_Warrior_DefensiveStance","Spell_Arcane_ArcaneTorrent"}
local function choice(parent,x,y,size,icon,title,help,callback)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(size,size)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2});b:SetBackdropColor(.06,.04,.09,1)
  b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",3,-3);b.art:SetPoint("BOTTOMRIGHT",-3,3);b.art:SetTexture("Interface\\Icons\\"..icon)
  b.glow=b:CreateTexture(nil,"OVERLAY");b.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");b.glow:SetBlendMode("ADD");b.glow:SetVertexColor(1,.72,.18)
  b.glow:SetPoint("CENTER");b.glow:SetSize(size*1.85,size*1.85);b.glow:Hide()
  b.caption=label(b,11);b.caption:SetPoint("TOP",b,"BOTTOM",0,-4);b.caption:SetSize(size+50,16);b.caption:SetJustifyH("CENTER");b.caption:SetText(title)
  b:SetScript("OnClick",function()apply(callback)end)
  b:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(title);GameTooltip:AddLine(help,1,1,1,true);GameTooltip:Show()end)
  b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  b:SetScript("OnUpdate",function(self,dt)
    if not self.selected then return end
    self.pulse=(self.pulse or 0)+dt
    self.glow:SetAlpha(F.db.settings.reduceMotion and .8 or .68+.24*math.sin(self.pulse*4))
  end)
  function b:Select(selected)
    if self.selected~=selected then
      self.selected=selected;self.pulse=0
      -- Use the client's native animated selection glow when it is available.
      if selected and ActionButton_ShowOverlayGlow then pcall(ActionButton_ShowOverlayGlow,self)
      elseif not selected and ActionButton_HideOverlayGlow then pcall(ActionButton_HideOverlayGlow,self)end
    end
    self.glow:SetShown(selected);self:SetBackdropBorderColor(selected and 1 or .32,selected and .75 or .22,selected and .2 or .4,1)
  end
  return b
end
local function totals()
  local b=P.state.battle;local ally={hp=0,maxHP=0,attack=0,armor=0,speed=0,n=0};local enemy={hp=0,maxHP=0,attack=0,armor=0,speed=0,n=0}
  local team=H.Team();for i=1,3 do local pet=team[i];if pet then
    local hp,maxHP=H.Health(pet,true);local _,attack,armor,speed=P.Stats(pet)
    local u=H.Unit(pet.id);if u then attack,armor,speed=u.attack,u.armor,u.speed end
    ally.hp=ally.hp+hp;ally.maxHP=ally.maxHP+maxHP;if hp>0 then ally.attack=ally.attack+attack;ally.armor=ally.armor+armor;ally.speed=ally.speed+speed;ally.n=ally.n+1 end
  end end
  local enemies=b and b.enemies or P.Enemies(P.floor or 1)
  local _,snapshot=P.VisualEvent(P.lastRound,P.sceneClock or 0)
  if not P.lastRound or P.lastRound.enemy.floor~=(P.floor or 1)then snapshot=nil end
  for i,e in ipairs(enemies)do
    enemy.hp=enemy.hp+(snapshot and snapshot.enemyHP[i] or e.hp or e.maxHP);enemy.maxHP=enemy.maxHP+e.maxHP
    if (snapshot and snapshot.enemyHP[i] or e.hp or e.maxHP)>0 then enemy.attack=enemy.attack+e.attack*(e.actions or 1);enemy.armor=enemy.armor+e.armor;enemy.speed=enemy.speed+e.speed;enemy.n=enemy.n+1 end
  end
  return ally,enemy
end
local function teamLine(t)
  return string.format("HP %d / %d\nAttack %.1f\nAvg armor %.1f%%   -   Speed %.1f",math.ceil(t.hp),t.maxHP,t.attack,t.armor/math.max(1,t.n),t.speed/math.max(1,t.n))
end
local function buildCommand(w)
  local f=S.Panel(w.home,492,-94,488,424);w.hardCommand=f
  f:SetBackdropBorderColor(.65,.4,.86,1);f:SetBackdropColor(.025,.014,.045,1)
  local art=f:CreateTexture(nil,"BORDER");f.art=art;art:SetPoint("TOPLEFT",3,-3);art:SetPoint("BOTTOMRIGHT",-3,3)
  art:SetTexture("Interface\\AddOns\\CompanionsForever\\Art\\HardTower.tga");art:SetAlpha(.15)
  local heading=label(f,18);f.heading=heading;heading:SetPoint("TOPLEFT",16,-14);heading:SetText("THE ASCENDANT SPIRE");heading:SetTextColor(.9,.73,1)
  f.prev=S.Button(f,"<",16,-46,34,function()if not P.state.battle then P.floor=math.max(1,P.floor-1);P.lastRound=nil;P.victory=nil;P.Render()end end)
  f.next=S.Button(f,">",438,-46,34,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1);P.lastRound=nil;P.victory=nil;P.Render()end end)
  f.prev:SetParent(w.scene.hud);f.prev:ClearAllPoints();f.prev:SetPoint("BOTTOMLEFT",w.scene,"BOTTOMLEFT",6,6)
  f.next:SetParent(w.scene.hud);f.next:ClearAllPoints();f.next:SetPoint("BOTTOMRIGHT",w.scene,"BOTTOMRIGHT",-6,6)
  f.floor=label(f,14);f.floor:SetPoint("TOPLEFT",60,-48);f.floor:SetSize(368,20);f.floor:SetJustifyH("CENTER")
  f.allyTitle=label(f,12);f.allyTitle:SetPoint("TOPLEFT",16,-84);f.allyTitle:SetText("YOUR TEAM");f.allyTitle:SetTextColor(.4,1,.6)
  f.enemyTitle=label(f,12);f.enemyTitle:SetPoint("TOPLEFT",258,-84);f.enemyTitle:SetText("ELITE TEAM");f.enemyTitle:SetTextColor(1,.7,.35)
  f.ally=label(f,12);f.ally:SetPoint("TOPLEFT",16,-104);f.ally:SetSize(224,56)
  f.enemy=label(f,12);f.enemy:SetPoint("TOPLEFT",258,-104);f.enemy:SetSize(214,56)
  f.styleTitle=label(f,12);f.styleTitle:SetPoint("TOPLEFT",16,-174);f.styleTitle:SetSize(456,18)
  f.styles={};for i,style in ipairs(P.styles)do
    f.styles[i]=choice(f,40+(i-1)*112,-201,42,styleIcons[i],style.name,style.help.." Select a team pet to choose its style. Locked during battle.",function()return H.SetStyle(i)end)
  end
  local tacticTitle=label(f,12);f.tacticTitle=tacticTitle;tacticTitle:SetPoint("TOPLEFT",16,-280);tacticTitle:SetText("TEAM TACTIC  -  change during battle")
  f.tactics={};for i,t in ipairs(H.tactics)do
    f.tactics[i]=choice(f,40+(i-1)*112,-307,42,t.icon,t.name,t.help.." Takes effect for the next combat round. Does not change area attacks.",function()return H.SetTactic(t.key)end)
  end
  local hint=label(f,11);f.hint=hint;hint:SetPoint("BOTTOMLEFT",16,16);hint:SetText("Clear each floor to unlock the next challenge.")
  f:SetScript("OnUpdate",function(self,dt)
    self.elapsed=(self.elapsed or 0)+dt;if self.elapsed<.2 then return end;self.elapsed=0
    if P.state and P.mode=="tower"then local a,e=totals();self.ally:SetText(teamLine(a));self.enemy:SetText(teamLine(e))end
  end)
end
local buildUI=P.BuildUI
function P.BuildUI()
  buildUI();if not rawget(P.window,"hardCommand")then buildCommand(P.window)end
end
local buildCompass=P.BuildCompass
function P.BuildCompass(parent)
  buildCompass(parent);local m=P.mini;m.hardChoices={styles={},tactics={}}
  for i,style in ipairs(P.styles)do
    local b=choice(m.footer,10+(i-1)*30,-262,24,styleIcons[i],style.name,style.help.." Style for the selected pet. Locked during battle.",function()return H.SetStyle(i)end)
    b.caption:Hide();m.hardChoices.styles[i]=b
  end
  for i,t in ipairs(H.tactics)do
    local b=choice(m.footer,154+(i-1)*30,-262,24,t.icon,t.name,t.help.." Changes the team's next combat round.",function()return H.SetTactic(t.key)end)
    b.caption:Hide();m.hardChoices.tactics[i]=b
  end
end
local renderCompass=P.RenderCompass
function P.RenderCompass()
  renderCompass();local m=P.mini;if not m or not rawget(m,"hardChoices")or not P.state then return end
  local tower=P.miniMode=="tower";m.style:Hide();local target=H.Target()
  for _,button in ipairs(m.battle)do button.label:Hide()end
  for i,b in ipairs(m.hardChoices.styles)do b:SetShown(tower);b:SetEnabled(target~=nil and not P.state.battle);b:Select(target~=nil and (target.style or 1)==i)end
  for i,b in ipairs(m.hardChoices.tactics)do b:SetShown(tower and #(P.state.battle and P.state.battle.enemies or P.Enemies(P.floor or 1) or {})>1);b:Select((P.state.hardMode.tactic or "order")==H.tactics[i].key)end
end
local render=P.Render
function P.Render()
  render();local w=P.window;if not w or not rawget(w,"hardCommand")or not P.state then return end
  local tower=P.mode=="tower";w.hardCommand:SetShown(tower);w.hardCommand.prev:SetShown(tower);w.hardCommand.next:SetShown(tower);w.side:SetShown(not tower);w.statsPanel:SetShown(not tower)
  if not tower then
    w.readiness:ClearAllPoints();w.readiness:SetPoint("TOPLEFT",w.home,"TOPLEFT",20,-561)
    for i,b in ipairs(w.fight)do b:ClearAllPoints();b:SetPoint("TOPLEFT",w.home,"TOPLEFT",75+(i-1)*145,-582)end
    return
  end
  w.readiness:ClearAllPoints();w.readiness:SetPoint("TOPLEFT",w.home,"TOPLEFT",20,-569)
  for i,b in ipairs(w.fight)do b:ClearAllPoints();b:SetPoint("TOPLEFT",w.home,"TOPLEFT",75+(i-1)*145,-598);b.label:ClearAllPoints();b.label:SetPoint("TOP",b,"BOTTOM",0,-5);b.label:SetWidth(125);b.label:SetHeight(26)end
  local f=w.hardCommand;local b=P.state.battle;local target=H.Target();local a,e=totals()
  local encounter=P.Enemies(b and b.floor or P.floor);f.enemyTitle:SetText(H.IsHard() and (encounter[1].rare and "RARE ELITE  -  5% CRIT" or encounter[1].boss and "BOSS" or "ELITE TEAM") or "ENEMIES")
  f.heading:SetText(H.IsHard() and "THE ASCENDANT SPIRE" or "THE COMPANION TOWER")
  f.art:SetTexture(w.scene.backgroundPath);if H.IsHard()then f.art:SetTexCoord(0,1,0,1)else f.art:SetTexCoord(.5,1,.2,.8)end
  f.allyTitle:SetText(H.IsHard() and "YOUR TEAM" or "YOUR COMPANION")
  f.hint:SetText(H.IsHard() and "Three level-75+ pets. Death is permanent." or H.IsUnlocked() and "Hard Mode and the 16-pet stable unlocked." or "Clear normal floor 100 to unlock Hard Mode and 16 stable slots.")
  local multi=#encounter>1
  f.tacticTitle:SetShown(multi);for _,button in ipairs(f.tactics)do button:SetShown(multi)end
  f.floor:SetText("FLOOR "..(b and b.floor or P.floor).." / 100   -   "..e.n..(H.IsHard() and (encounter[1].rare and " RARE ELITE" or encounter[1].boss and " BOSS" or " ELITES") or " ENEMIES"))
  f.prev:SetEnabled(not b and P.floor>1);f.next:SetEnabled(not b and P.floor<P.Unlocked())
  f.ally:SetText(teamLine(a));f.enemy:SetText(teamLine(e))
  f.styleTitle:SetText("STYLE: "..(target and P.species[target.species] or "select pet")..(b and "  -  LOCKED" or "  -  select before battle"))
  for i,button in ipairs(f.styles)do button:SetEnabled(target~=nil and not b);button:Select(target~=nil and (target.style or 1)==i)end
  for i,button in ipairs(f.tactics)do button:Select((P.state.hardMode.tactic or "order")==H.tactics[i].key)end
end
function H.OpenStable(anchor,slot)
  if P.state.battle then P.notice="Finish or retreat before changing your team.";return false end
  if not H.picker then
    local f=CreateFrame("Frame","CFHardStablePicker",UIParent,"BackdropTemplate");H.picker=f
    f:SetSize(276,326);f:SetClampedToScreen(true);f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12});f:SetBackdropColor(.025,.025,.04,1)
    f.title=label(f,14);f.title:SetPoint("TOPLEFT",12,-12)
    f.close=S.Button(f,"X",240,-7,26,function()f:Hide()end);f.rows={}
    for i=1,16 do
      local b=CreateFrame("Button",nil,f,"BackdropTemplate");f.rows[i]=b
      b:SetSize(80,82);b:SetPoint("TOPLEFT",12+(i-1)%3*86,-42-math.floor((i-1)/3)*88)
      b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2});b:SetBackdropColor(.07,.07,.09,1)
      b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetSize(48,48);b.art:SetPoint("TOP",0,-3)
      b.name=label(b,10);b.name:SetPoint("TOPLEFT",4,-52);b.name:SetSize(72,12);b.name:SetMaxLines(1)
      b.level=label(b,10);b.level:SetPoint("TOPLEFT",4,-65);b.level:SetSize(72,12)
      b:SetScript("OnClick",function(self)
        if not self.pet then return end
        P.viewID=self.pet.id;P.state.hardMode.editSlot=f.slot
        if apply(H.EquipViewed)then f:Hide()end
      end)
      b:SetScript("OnEnter",function(self)
        if not self.pet then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(P.species[self.pet.species])
        GameTooltip:AddLine(H.IsHard() and self.pet.level<75 and "Requires level 75" or "Click to equip in slot "..f.slot..". An existing teammate swaps slots.",1,1,1,true);GameTooltip:Show()
      end);b:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
    f.hint=label(f,11);f.hint:SetPoint("BOTTOMLEFT",12,12);f.hint:SetText("Living pets only  -  Level 75+ to equip")
    UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"CFHardStablePicker")
  end
  local f=H.picker;f:SetParent(anchor);f:SetFrameLevel(anchor:GetFrameLevel()+50);f.slot=slot;f.hint:SetText(H.IsHard() and "Living pets only - Level 75+" or "Select your traveling companion");f:ClearAllPoints();f:SetPoint("BOTTOMLEFT",anchor,"TOPLEFT",0,4);f.title:SetText("Equip team slot "..slot)
  local stable={};for _,pet in ipairs(P.state.pets)do if not pet.deadAt and not P.IsHoused(pet)then stable[#stable+1]=pet end end
  for i,b in ipairs(f.rows)do
    local pet=stable[i];b.pet=pet;b:SetEnabled(pet~=nil and (not H.IsHard() or pet.level>=75))
    local columns=P.stableCapacity>9 and 4 or 3;local cell=columns==4 and 64 or 86
    b:ClearAllPoints();b:SetPoint("TOPLEFT",12+(i-1)%columns*cell,-42-math.floor((i-1)/columns)*cell);b:SetSize(cell-6,cell-6);b:SetShown(i<=P.stableCapacity)
    b.art:SetSize(cell-34,cell-34);b.name:SetWidth(cell-14);b.name:ClearAllPoints();b.name:SetPoint("TOPLEFT",4,-cell+30);b.level:SetWidth(cell-14);b.level:ClearAllPoints();b.level:SetPoint("TOPLEFT",4,-cell+17)
    b.name:SetText(pet and P.species[pet.species] or "Empty");b.level:SetText(pet and "Level "..pet.level or "")
    b.art:SetShown(pet~=nil);if pet then P.ShowPetPortrait(b.art,pet)end
    b:SetBackdropBorderColor(unpack(pet and P.colors[pet.rarity] or {.2,.2,.2,1}))
  end
  f:Show();return true
end
local function frame(parent,enemy,index)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});b:SetBackdropColor(.025,.025,.04,.95)
  b.title=label(b,11);b.title:SetPoint("TOPLEFT",4,-3);b.title:SetMaxLines(1)
  b.hp=CreateFrame("StatusBar",nil,b);b.hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  b.hp:SetPoint("BOTTOMLEFT",4,4);b.hp:SetPoint("BOTTOMRIGHT",-4,4);b.hp:SetHeight(enemy and 11 or 20)
  b.hp:SetStatusBarColor(enemy and .65 or .1,enemy and .12 or .75,.15)
  local bg=b.hp:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.09,.09,.09,1)
  b.amount=label(b.hp,enemy and 10 or 12);b.amount:SetAllPoints();b.amount:SetJustifyH("CENTER")
  b.flash=b:CreateTexture(nil,"OVERLAY");b.flash:SetAllPoints();b.flash:SetColorTexture(.2,1,.35,.3);b.flash:Hide()
  b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  b:SetScript("OnClick",function(self,key)
    if enemy then return end
    if key=="RightButton"then H.OpenStable(self,index)elseif self.unit then apply(function()return H.SelectTarget(self.unit.id)end)end
  end)
  b:SetScript("OnEnter",function(self)
    if not self.unit then return end
    GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(P.species[self.unit.species])
    GameTooltip:AddLine(self.tooltip or "",1,1,1,true);GameTooltip:Show()
  end);b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  return b
end
function P.HardRefreshScene(f)
  if not P.state or not P.state.hardMode then return end
  if not rawget(f,"hardBars")then
    f.lowHealthWarning=CreateFrame("Frame",nil,f.hud,"BackdropTemplate")
    f.lowHealthWarning:SetAllPoints(f);f.lowHealthWarning:SetFrameLevel(f.hud:GetFrameLevel()+1);f.lowHealthWarning:EnableMouse(false)
    f.lowHealthWarning:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=4})
    f.lowHealthWarning:SetBackdropColor(1,0,0,.28);f.lowHealthWarning:SetBackdropBorderColor(1,.05,.05,1);f.lowHealthWarning:Hide()
    f.hardBars={allies={},enemies={}};f.hardFallback={};f.hardHealText={}
    for i=1,3 do
      f.hardBars.allies[i]=frame(f.hud,false,i)
      f.hardHealText[i]=label(f.hud,18);f.hardHealText[i]:SetTextColor(.2,1,.3);f.hardHealText[i]:SetSize(110,24);f.hardHealText[i]:SetJustifyH("CENTER")
      if i>1 then local art=f:CreateTexture(nil,"ARTWORK");f.hardFallback[i]=art;art:SetSize(42,42)end
    end
    for i=1,6 do f.hardBars.enemies[i]=frame(f.hud,true,i)end
  end
  if not f.tower then
    f.lowHealthWarning:Hide()
    for _,group in pairs(f.hardBars)do for _,b in ipairs(group)do b:Hide()end end
    for _,art in pairs(f.hardFallback)do art:Hide()end
    for _,t in ipairs(f.hardHealText)do t:Hide()end
    return
  end
  if H.picker and P.state.battle then H.picker:Hide()end
  f.leftHP:Hide();for _,bar in ipairs(f.enemyHP)do bar:Hide()end
  local team=H.Team();local enemies=f.displayEnemies or {};local width=#enemies==1 and f.width-14 or (f.width-24)/3
  local _,snapshot=P.VisualEvent(f.round,P.sceneClock or 0)
  local lowHealth=false
  for i,b in ipairs(f.hardBars.allies)do
    local pet=team[i];b.unit=pet;b:Hide()
    if not pet then f.hardHealText[i]:Hide();if f.hardFallback[i]then f.hardFallback[i]:Hide()end end
    if pet then
      b:SetSize(width,46);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",7,-7-(i-1)*49)
      b.title:SetSize(width-8,14);b.title:SetText("Lv "..pet.level.." "..P.species[pet.species])
      local hp,maxHP=H.Health(pet,true);b.hp:SetMinMaxValues(0,maxHP);b.hp:SetValue(hp);b.amount:SetText(math.ceil(hp).." / "..maxHP)
      if not pet.deadAt and hp>0 and maxHP>0 and hp/maxHP<.25 then lowHealth=true end
      b:SetBackdropBorderColor(unpack(pet.id==P.state.hardMode.target and {1,.82,.2,1} or P.colors[pet.rarity]))
      b.tooltip="Health: "..math.ceil(hp).." / "..maxHP.."\nLeft click: select for herbs and abilities. Right click: equip a pet."
      local heal=P.instantHeals and P.instantHeals[pet.id];local age=heal and (P.sceneClock or 0)-heal.at or 99
      b.flash:SetShown(age<1.2);if age<1.2 then b.flash:SetAlpha((1.2-age)/1.2)end
      local t=f.hardHealText[i];t:SetShown(age<1.5)
      if age<1.5 then
        t:ClearAllPoints();t:SetPoint("CENTER",f,"TOPLEFT",f.width*.3,-f.hudHeight-f.arenaHeight*(.4+(i-1)*.14)+age*12)
        t:SetText("+"..math.ceil(heal.amount).." HP");t:SetAlpha(math.min(1,(1.5-age)*2))
      end
      if i>1 then local art=f.hardFallback[i];local state=f.arena.states[1-i]
        art:ClearAllPoints();art:SetPoint("CENTER",f,"TOPLEFT",f.width*.28,-f.hudHeight-f.arenaHeight*(.4+(i-1)*.14))
        art:SetShown(not(state and state.loaded));if not(state and state.loaded)then P.ShowPetPortrait(art,pet)end
      end
    end
  end
  f.lowHealthWarning:SetShown(lowHealth)
  if lowHealth then
    local clock=GetTime and GetTime() or P.sceneClock or 0
    f.lowHealthWarning:SetAlpha(F.db.settings.reduceMotion and .55 or .25+.4*(.5+.5*math.sin(clock*math.pi*2)))
  end
  local rowHeight=39
  for i,b in ipairs(f.hardBars.enemies)do
    local e=enemies[i];b.unit=e;b:SetShown(e~=nil)
    if e then
      b:SetSize(width,rowHeight);b:ClearAllPoints();b:SetPoint("TOPLEFT",f,"TOPLEFT",7+((i-1)%3)*(width+5),-7-math.floor((i-1)/3)*(rowHeight+5))
      b.title:SetSize(width-8,rowHeight>24 and 12 or 10);b.title:SetText("|cffffcc55"..i..(e.rare and ". RARE " or H.IsHard() and e.boss and ". Boss " or e.elite and ". Elite " or ". Lv ")..(e.level or e.combatLevel).."|r"..(f.width>300 and " "..P.species[e.species] or ""))
      b.hp:SetHeight(16)
      b.hp:SetStatusBarColor(unpack(e.rare and {.65,.7,.78} or e.elite and {.85,.62,.12} or {.7,.06,.08}))
      b.amount:SetTextColor(1,1,1);b.amount:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",f.width>300 and 12 or 10,"OUTLINE")
      local hp=snapshot and snapshot.enemyHP[i] or e.hp or e.maxHP;b.hp:SetMinMaxValues(0,e.maxHP);b.hp:SetValue(hp);b.amount:SetText(rowHeight>24 and math.ceil(hp).."/"..e.maxHP or "")
      b:SetBackdropBorderColor(.75,.55,.15,1);b.tooltip=(e.rare and "Rare elite - Level " or H.IsHard() and e.boss and "Boss - Level " or e.elite and "Elite - Level " or "Level ")..(e.level or e.combatLevel).."\nHealth: "..math.ceil(hp).." / "..e.maxHP.."\nAttack: "..e.attack..(H.IsHard() and (e.rare and "\nTwo attacks per round. 5% critical chance; 1.5x critical damage." or e.boss and "\nOne attack per round." or "") or "")
      if P.EnemySpecialHelp then b.tooltip=b.tooltip..P.EnemySpecialHelp(e)end
      local art=f.enemies[i];if art then art:ClearAllPoints();art:SetPoint("CENTER",f,"TOPLEFT",f.width*(.65+math.floor((i-1)/3)*.17),-f.hudHeight-f.arenaHeight*(.4+((i-1)%3)*.15));art:SetSize(42,42)end
    end
  end
  local b=P.state.battle
  f.caption:SetText(b and (b.paused and "Paused" or "Round "..(b.turn+1)).." - "..(H.IsHard() and 3 or 1).." vs "..#enemies or (H.IsHard() and "Hard floor " or "Floor ")..(P.floor or 1).." - "..P.FloorStatus(P.floor or 1))
end
