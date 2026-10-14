local _,F=...
local P,S=F.Pets,F.Style

local icons={food="INV_Misc_Food_14",rest="Spell_Nature_Sleep",medicine="INV_Misc_Herb_03",adopt="INV_Egg_02",next="Ability_Hunter_BeastCall",fight="Ability_DualWield",pause="INV_Misc_PocketWatch_01",open="INV_Misc_Book_09",inspect="Ability_Hunter_EagleEye"}
local function text(parent,value,x,y,width,height,color)
  local t=S.Text(parent,value,x,y,width,"GameFontHighlightSmall",color or S.gold);t:SetHeight(height);return t
end
local function sprite(parent,size)
  local art=parent:CreateTexture(nil,"ARTWORK");art:SetSize(size,size);return art
end
local function showSprite(art,pet,flip)
  art:SetShown(not not pet);if P.StyleSparklyPortrait then P.StyleSparklyPortrait(art,pet)end;if not pet then return end
  local model=P.ModelFor(pet)
  local portrait=P.portraits and P.portraits[pet.species]
  if portrait then
    art:SetTexCoord(0,1,0,1);art:SetTexture(portrait)
    art.cfPortraitAsset=portrait;art.cfPortraitDisplay=nil;art.cfPortraitRenderer=nil
  elseif rawget(art,"cfPortraitAsset") or rawget(art,"cfPortraitDisplay")~=model.display or rawget(art,"cfPortraitRenderer")~=SetPortraitTextureFromCreatureDisplayID then
    art.cfPortraitAsset=nil
    art:SetTexCoord(0,1,0,1)
    art:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    local ok=true
    if SetPortraitTextureFromCreatureDisplayID then ok=pcall(SetPortraitTextureFromCreatureDisplayID,art,model.display)end
    if ok then art.cfPortraitDisplay=model.display;art.cfPortraitRenderer=SetPortraitTextureFromCreatureDisplayID end
  end
  if art.SetDesaturation and P.DeathFade then art:SetDesaturation(P.DeathFade(pet))
  else art:SetDesaturated(pet.deadAt~=nil)end
  if P.StyleSparklyPortrait then P.StyleSparklyPortrait(art,pet)end
end
local function showPet(art,pet,flip)
  showSprite(art,pet,flip)
  local view=rawget(art,"modelView")
  if not view then
    view=P.CreateArena(art:GetParent(),true);art.modelView=view
    if view.scene then
      view.scene:SetAllPoints(art)
      view.scene:SetScript("OnUpdate",function(_,dt)
        view:Poll(dt);art:SetShown(not view:Ready())
        if art.SetDesaturation then art:SetDesaturation(P.DeathFade(view.states[0] and view.states[0].unit))end
      end)
    end
  end
  if view.scene then
    view:Sync(pet,{},pet and (tostring(pet.id or pet.species)..tostring(pet.deadAt)) or "empty")
    view.scene:SetShown(pet~=nil);art:SetShown(pet~=nil and not view:Ready())
  end
end
P.ShowPetArt=showPet
P.ShowPetPortrait=showSprite
function P.PreviewBackground(parent,art)
  local bg=parent:CreateTexture(nil,"BORDER",nil,1);bg:SetAllPoints(art)
  return bg
end
function P.UpdatePreviewBackground(bg)
  local faction=S.Faction()=="Alliance" and "Alliance" or "Horde"
  local choice=tonumber(F.char.campScene) or 1
  if choice<1 or choice>5 or choice~=math.floor(choice)then choice=1 end
  local custom=choice>1
  local path="Interface\\AddOns\\CompanionsForever\\Art\\"..(custom and "Camp"..faction..choice or "PetScenes"..faction)..".tga"
  if rawget(bg,"cfScenePath")~=path then bg:SetTexture(path,"CLAMP","CLAMP","LINEAR");bg.cfScenePath=path end
  if custom then bg:SetTexCoord(0,1,0,1)else bg:SetTexCoord(0,0.5,0.2,0.8)end
  bg:SetAlpha(S.HighContrast() and 0.3 or 1)
end

local function act(fn)local ok,message=fn();if not ok and message then
  P.notice=message
  if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(message,1,0.2,0.2)end
end;P.Render()end
local function tip(frame,title,body)
  frame:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(title)
    GameTooltip:AddLine(type(body)=="function" and body() or body,1,1,1,true);GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
function P.BuildRacialIcon(parent,x,y)
  local b=CreateFrame("Frame",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(26,26);b:EnableMouse(true)
  b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetAllPoints()
  tip(b,"Trainer racial",P.RacialText);P.UpdateRacialIcon(b);return b
end
function P.UpdateRacialIcon(b)
  local racial=P.TrainerRacial()
  local icons={training="INV_Misc_Book_09",attack="Racial_Orc_BerserkerStrength",armor="Spell_Shadow_UnholyStrength",speed="Ability_Ambush",herbHealing="Spell_Shadow_Undead",health="Spell_Nature_WarStomp",onlineTokens="INV_Misc_Coin_01",rest="Racial_Troll_Berserk"}
  local path="Interface\\Icons\\"..(racial and icons[racial.key] or "INV_Misc_QuestionMark")
  if b.racialPath~=path then b.art:SetTexture(path);b.racialPath=path end;b:SetShown(racial~=nil)
end
local function icon(parent,key,label,x,y,size,fn,help)
  local b=CreateFrame("Button",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(size,size)
  b:SetNormalTexture("Interface\\Icons\\"..icons[key]);b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
  local border=b:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Buttons\\UI-Quickslot2");border:SetPoint("CENTER");border:SetSize(size*1.6,size*1.6)
  b.label=text(parent,label,x-10,y-size-3,size+20,20);b.label:SetJustifyH("CENTER")
  if key=="food" or key=="medicine"then
    b.count=text(b,"",0,-size+17,size-2,18,{1,1,1});b.count:SetJustifyH("RIGHT")
    b:SetScript("OnUpdate",function()local value=P.state and P.state.inventory[key] or 0;if b.lastCount~=value then b.lastCount=value;b.count:SetText(value)end end)
  end
  b:SetScript("OnClick",function()act(fn)end);tip(b,label,help or label)
  return b
end
local function shown(b,value)b:SetShown(value);b.label:SetShown(value)end
local careColors={health={0,1,0},food={1,0.5,0},energy={1,1,0}}
local function meter(parent,x,y,width,label,color)
  local b=CreateFrame("StatusBar",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(width,19)
  b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");b:SetMinMaxValues(0,100);b:SetStatusBarColor(unpack(color))
  local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0,0,0,0.9)
  b.label=text(b,label,4,0,width-8,19,{1,1,1})
  b.label:SetShadowColor(0,0,0,1);b.label:SetShadowOffset(1,-1);return b
end
local function frameHealth(bar)
  local frame=CreateFrame("Frame",nil,bar,"BackdropTemplate")
  frame:SetPoint("TOPLEFT",-4,4);frame:SetPoint("BOTTOMRIGHT",4,-4)
  frame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
  frame:SetBackdropBorderColor(0.72,0.68,0.56,1);frame:EnableMouse(false)
  bar.healthFrame=frame
  bar.label:SetShadowColor(0,0,0,1);bar.label:SetShadowOffset(1,-1)
end
local function fill(bar,value,label)bar:SetValue(value or 0);bar.label:SetText(label)end
-- Pet XP uses the same delayed reward receipt as the finishing attack.
function P.UpdatePetXP(bar,pet)
  bar.pet=pet;bar:SetShown(pet~=nil);if not pet then return end
  local level,xp=pet.level,pet.xp or 0
  local event=P.progressEvents and P.progressEvents[pet.id]
  if event and (GetTime and GetTime() or F.Now())<event.at then level,xp=event.fromLevel,event.fromXP end
  local cap=level>=P.LevelCap();local needed=P.XPNeeded({level=level})
  bar:SetMinMaxValues(0,needed);bar:SetValue(cap and needed or math.max(0,math.min(needed,xp)))
  P.StyleXPBar(bar,not not bar.label)
  if bar.label then bar.label:SetText("Lv "..level.." | "..(cap and "Level cap" or math.floor(xp).." / "..needed.." XP"))end
end
function P.BuildPetXP(parent,numbers)
  local bar=CreateFrame("StatusBar",nil,parent);bar.label=false;bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:EnableMouse(false)
  local bg=bar:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.025,.015,.045,1)
  local skin=P.StyleXPBar(bar,numbers);bar.rim=skin.rim;bar.cells=skin.cells
  bar:SetScript("OnSizeChanged",function(self)P.StyleXPBar(self,numbers);if self.label then self.label:SetWidth(math.max(1,self:GetWidth()-8))end end)
  if numbers then
    bar.label=text(bar,"",0,0,100,20,{1,1,1});bar.label:ClearAllPoints();bar.label:SetPoint("BOTTOM",bar,"TOP",0,4);bar.label:SetHeight(20);bar.label:SetJustifyH("CENTER")
    bar.label:SetShadowColor(0,0,0,1);bar.label:SetShadowOffset(1,-1)
  end
  local elapsed=0
  bar:SetScript("OnUpdate",function(self,dt)elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0;P.UpdatePetXP(self,self.pet)end)
  bar:Hide();return bar
end
-- Decorative copies of Forever's target-frame geometry. Never inherit a
-- secure unit template or register a fake pet as a real game unit.
local function unitFrame(parent)
  local f=CreateFrame("Frame",nil,parent);f:SetSize(232,100);f:EnableMouse(true)
  local portraitBG=f:CreateTexture(nil,"BACKGROUND")
  portraitBG:SetColorTexture(0.06,0.05,0.04,1);portraitBG:SetSize(58,58);portraitBG:SetPoint("TOPRIGHT",-26,-19)
  f.portrait=sprite(f,58);f.portrait:SetDrawLayer("BACKGROUND",1);f.portrait:SetPoint("TOPRIGHT",-26,-19)
  local mask=f:CreateMaskTexture();mask:SetAtlas("CircleMask");mask:SetAllPoints(f.portrait)
  f.portrait:AddMaskTexture(mask);portraitBG:AddMaskTexture(mask)
  local content=CreateFrame("Frame",nil,f);content:SetAllPoints();content:SetFrameLevel(f:GetFrameLevel()+1)
  f.nameplate=content:CreateTexture(nil,"BACKGROUND");f.nameplate:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Type",true);f.nameplate:SetPoint("TOPRIGHT",-75,-25)
  f.hp=meter(content,22,-40,126,"",{0,0.85,0})
  f.hp:SetHeight(20);f.hp:GetStatusBarTexture():SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health")
  f.hp.label:Hide()
  f.resource=meter(content,22,-61,134,"",{0.9,0.7,0.1});f.resource:SetHeight(10);f.resource.label:Hide()
  -- Artwork above the fills keeps the original beveled edges and portrait ring.
  local trim=CreateFrame("Frame",nil,f);trim:SetAllPoints();trim:SetFrameLevel(f:GetFrameLevel()+3);trim:EnableMouse(false)
  f.healthFrame=trim
  local border=trim:CreateTexture(nil,"ARTWORK");border:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn",true);border:SetPoint("CENTER")
  f.eliteDragon=trim:CreateTexture(nil,"OVERLAY",nil,1)
  f.eliteDragon:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",true);f.eliteDragon:SetPoint("TOPRIGHT",-11,-7);f.eliteDragon:Hide()
  local circle=trim:CreateTexture(nil,"OVERLAY",nil,2);circle:SetAtlas("UI-HUD-UnitFrame-SmallCircle",true);circle:SetPoint("BOTTOMRIGHT",-13,7)
  f.name=text(trim,"",26,-25,119,14,S.gold);f.name:SetMaxLines(1)
  f.percent=text(trim,"",24,-42,47,16,{1,1,1})
  f.amount=text(trim,"",70,-42,76,16,{1,1,1});f.amount:SetJustifyH("RIGHT")
  f.detail=text(trim,"",24,-61,122,10,{1,1,1});f.detail:SetJustifyH("CENTER")
  f.level=text(trim,"",0,0,30,22,S.gold);f.level:ClearAllPoints();f.level:SetPoint("CENTER",circle,"CENTER",0,0);f.level:SetJustifyH("CENTER")
  f.dingArrow=CreateFrame("Frame",nil,trim);f.dingArrow:SetSize(14,16)
  f.dingArrow:SetPoint("LEFT",f.level,"RIGHT",1,2);f.dingArrow:Hide()
  for i=0,3 do
    local line=f.dingArrow:CreateTexture(nil,"OVERLAY");line:SetColorTexture(1,0.8,0.15,1)
    line:SetSize(2+i*4,2);line:SetPoint("TOP",0,-i*2)
  end
  local stem=f.dingArrow:CreateTexture(nil,"OVERLAY");stem:SetColorTexture(1,0.8,0.15,1)
  stem:SetSize(4,8);stem:SetPoint("TOP",0,-8)
  for _,label in ipairs({f.name,f.percent,f.amount,f.detail,f.level})do
    label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
  end
  tip(f,"Tower companion",function()return f.tooltip or ""end)
  f:Hide();return f
end
local function healthValue(f,current,maximum)
  maximum=math.max(1,maximum or 1);current=math.max(0,math.min(maximum,current or 0))
  f.hp:SetValue(current/maximum*100)
  f.percent:SetText(math.floor(current/maximum*100).."%")
  f.amount:SetText(tostring(math.floor(current)))
  f.tooltip=(f.unitName or "Companion").."\nHealth: "..math.floor(current).." / "..maximum..(f.isEnemy and "\nTower floor "..f.unitLevel or "\nLevel "..f.unitLevel)..(f.isElite and "\nElite" or "")
  if f.combatUnit and f.isEnemy then
    local e=f.combatUnit;local spell=e.spell and P.enemySpells[e.spell]
    f.tooltip=f.tooltip.."\nCombat level: "..e.combatLevel.."\nAttack: "..e.attack.."\nArmor: "..e.armor.."%\nSpeed: "..e.speed
      ..(spell and "\n"..spell.name.." (every "..e.spellEvery.." rounds): "..spell.help or "\nNo spells")
  end
end
local function unitInfo(f,unit,enemy)
  if not unit then f:Hide();return end
  f.unitName=P.species[unit.species];f.unitLevel=unit.level or unit.floor
  f.isEnemy=enemy;f.isElite=not not unit.elite
  f.combatUnit=unit
  showSprite(f.portrait,unit)
  f.name:SetText(f.unitName);f.level:SetText(f.unitLevel)
  f.nameplate:SetVertexColor(enemy and 0.8 or 0.1,enemy and 0.05 or 0.5,0.05)
  f.eliteDragon:SetShown(f.isElite)
  local cap=P.LevelCap()
  f.resource:SetStatusBarColor(0.55,0.25,0.85)
  f.resource:SetValue(enemy and 0 or unit.level>=cap and 100 or (unit.xp or 0)/P.XPNeeded(unit)*100)
  f.detail:SetText(enemy and (unit.rare and "RARE ELITE" or f.isElite and "ELITE" or "Enemy "..unit.index) or "XP "..P.XPText(unit))
end
-- Small pixel glyphs stay sharp without requiring a particular font or new artwork.
local function pixelMark(parent,rows,color)
  local mark=CreateFrame("Frame",nil,parent);mark:SetSize(#rows[1]*2,#rows*2)
  mark:SetFrameLevel(parent:GetFrameLevel()+11)
  for y,row in ipairs(rows)do for x=1,#row do if row:sub(x,x)=="1" then
    local shadow=mark:CreateTexture(nil,"ARTWORK");shadow:SetColorTexture(0,0,0,0.85);shadow:SetSize(3,3);shadow:SetPoint("TOPLEFT",(x-1)*2+1,-(y-1)*2-1)
    local pixel=mark:CreateTexture(nil,"OVERLAY");pixel:SetColorTexture(unpack(color));pixel:SetSize(2,2);pixel:SetPoint("TOPLEFT",(x-1)*2,-(y-1)*2)
  end end end
  mark:EnableMouse(true);mark:Hide();return mark
end
function P.BuildNeeds(f)
  f.needs={sleep={}}
  local alert=CreateFrame("Frame",nil,f,"BackdropTemplate");f.needs.alert=alert
  alert:SetAllPoints();alert:SetFrameLevel(f:GetFrameLevel()+9);alert:EnableMouse(false)
  alert:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
  alert:SetBackdropColor(1,0,0,0.08);alert:SetBackdropBorderColor(1,0.1,0.1,1);alert:Hide()
  for i=1,3 do
    local z=pixelMark(f,{"11111","00010","00100","01000","11111"},{0.7,0.85,1,1})
    tip(z,"Sleeping","Resting restores energy while food is at least 10, then heals 1 HP every 5 seconds at full energy. Your pet wakes when both health and energy are full.")
    f.needs.sleep[i]=z
  end
  f.needs.hungry=pixelMark(f,{"11000000","01100000","00110000","00011000","00110000","01100000","00110000","00011000"},{1,0.8,0.25,1})
  tip(f.needs.hungry,"Hungry","Food is below 25. Below 10, health and energy drain to a minimum of 1. Hunger cannot kill your pet. Feed it food and use herbs for health.")
end
function P.UpdateNeeds(f,t,motion)
  local pet=f.needsPet
  local alive=pet and not pet.deadAt and not f.tower
  local cx,cy=f.width*0.5,-f.height*0.62
  local head=cy+f.height*0.28
  for i,z in ipairs(f.needs.sleep)do
    local visible=alive and pet.resting
    z:SetShown(not not visible)
    if visible then
      local phase=motion and (t/2.4+(i-1)/3)%1 or (i-1)/3
      z:SetPoint("CENTER",f,"TOPLEFT",math.floor(cx+f.width*0.14+phase*18),math.floor(head+phase*24))
      z:SetAlpha(motion and math.min(1,phase*6,(1-phase)*6) or 1)
    end
  end
  local hungry=alive and (pet.food or 100)<25
  f.needs.alert:SetShown(not not hungry)
  if hungry then f.needs.alert:SetAlpha(motion and (0.35+0.65*(0.5+0.5*math.sin(t*3))) or 0.8)end
  f.needs.hungry:SetShown(not not hungry)
  if hungry then f.needs.hungry:SetPoint("CENTER",f,"TOPLEFT",math.floor(cx-f.width*0.17+(motion and math.sin(t*5)*2 or 0)),math.floor(cy))end
end
local function updateOutcome(f)
  local now=P.sceneClock or 0
  for i,art in ipairs(f.enemies)do
    local enemy=f.displayEnemies[i]
    local alpha=1
    if enemy and enemy.defeatedAt and now>=enemy.defeatedAt then
      alpha=F.db.settings.reduceMotion and 0 or math.max(0,1-(now-enemy.defeatedAt)/0.65)
    end
    art:SetAlpha(alpha)
    -- The shared tower HUD owns health frames when installed. Never re-show
    -- the retired portrait bars between its throttled updates.
    if enemy then f.enemyHP[i]:SetShown(not P.HardRefreshScene and alpha>0)end
  end
  local fade=P.DeathFade(f.needsPet)
  if f.bg.SetDesaturation then f.bg:SetDesaturation(fade)else f.bg:SetDesaturated(fade>=1)end
  if f.pet.SetDesaturation then f.pet:SetDesaturation(fade)else f.pet:SetDesaturated(fade>=1)end
end
local function stage(parent,x,y,width,height)
  local f=S.Panel(parent,x,y,width,height);f.width=width;f.height=height
  f.displayEnemies={};f.round=false;f.tower=false
  -- Above the BackdropTemplate's fill, below the ARTWORK pet sprites.
  f.bg=f:CreateTexture(nil,"BORDER",nil,1);f.bg:SetPoint("TOPLEFT",6,-6);f.bg:SetPoint("BOTTOMRIGHT",-6,6)
  f.pet=sprite(f,height*0.88);f.enemies={};f.enemyHP={}
  f.hud=CreateFrame("Frame",nil,f);f.hud:SetAllPoints();f.hud:SetFrameLevel(f:GetFrameLevel()+10);f.hud:EnableMouse(false)
  P.BuildNeeds(f)
  for i=1,6 do f.enemies[i]=sprite(f,height*0.88);f.enemyHP[i]=unitFrame(f.hud)end
  f.enemy=f.enemies[1]
  f.leftHP=unitFrame(f.hud)

  f.progressText=text(f.hud,"",10,-height*0.34,width-20,40,S.gold);f.progressText:SetJustifyH("CENTER")
  f.progressText:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",18,"OUTLINE")
  f.float=text(f.hud,"",10,-50,width-20,28,{1,0.85,0.3});f.float:SetJustifyH("CENTER")
  f.caption=text(f.hud,"",8,-height+29,width-116,24,{1,1,1});f.caption:SetJustifyH("CENTER");f.caption:SetMaxLines(1)
  f.caption:SetWidth(width-16)
  f.campPrev=S.Button(f.hud,"<",8,-height+30,26,function()F.char.campScene=((F.char.campScene or 1)-2)%5+1;P.Render()end)
  f.campNext=S.Button(f.hud,">",width-34,-height+30,26,function()F.char.campScene=(F.char.campScene or 1)%5+1;P.Render()end)
  f.arena=P.CreateArena(f);f.rotating=false
  f:EnableMouse(true);f:RegisterForDrag("LeftButton")
  local function startRotation(self)
    if self.tower or not self.allowRotation or not GetCursorPosition then return end
    self.rotateX=GetCursorPosition();self.rotating=true;GameTooltip:Hide()
  end
  local function rotateToCursor(self)
    local x=GetCursorPosition();self.arena:Rotate((x-self.rotateX)/self:GetEffectiveScale()*0.01);self.rotateX=x
  end
  local function stopRotation(self)
    if self.rotating then rotateToCursor(self) end
    self.rotating=false
  end
  f:SetScript("OnMouseDown",function(self,button)if button=="LeftButton"then startRotation(self)end end)
  f:SetScript("OnMouseUp",function(self,button)if button=="LeftButton"then stopRotation(self)end end)
  f:SetScript("OnDragStart",function(self)if not self.rotating then startRotation(self)end end)
  f:SetScript("OnDragStop",stopRotation)
  f:SetScript("OnHide",function(self)self.rotating=false end)
  f:SetScript("OnUpdate",function(self,dt)
    if self.rotating then
      if self.tower or not self.allowRotation then self.rotating=false
      elseif IsMouseButtonDown and not IsMouseButtonDown("LeftButton")then stopRotation(self)
      else rotateToCursor(self)end
    end
    local t=P.sceneClock or 0;local round=self.round;local age=round and t-round.at or 9
    local motion=not F.db.settings.reduceMotion;local attack=0;local reply=0;local event
    local b=P.state and P.state.battle
    self.arena:Update(round,dt or 0,not not (self.tower and b and b.paused),motion)
    self.pet:SetShown(self.needsPet and not (self.arena.states[0] and self.arena.states[0].loaded) or false)
    for i,art in ipairs(self.enemies)do art:SetShown(self.displayEnemies[i]~=nil and not (self.arena.states[i] and self.arena.states[i].loaded))end
    if self.tower and round and age<(round.duration or 1.6) then
      local snapshot
      event,snapshot=P.VisualEvent(round,t)
      if event then
        local offset=motion and not event.missed and math.sin((age%0.55)/0.55*math.pi)*width*0.055 or 0
        attack=event.actor==0 and offset or 0;reply=event.actor~=0 and offset or 0
        self.float:SetText("")
        healthValue(self.leftHP,snapshot.hp,snapshot.maxHP or round.maxHP)
        for i,e in ipairs(round.enemies)do healthValue(self.enemyHP[i],snapshot.enemyHP[i],e.maxHP)end
      else self.float:SetText("")end
    else self.float:SetText("")end
    if P.UpdateCombatText then P.UpdateCombatText(self)end
    if P.UpdateTowerRewards then P.UpdateTowerRewards(self)end
    local bob=motion and math.floor(math.sin(t*2)*2) or 0
    local actorY=self.tower and -(self.hudHeight+self.arenaHeight*0.52) or -self.height*0.62
    self.pet:SetPoint("CENTER",self,"TOPLEFT",width*(self.tower and 0.23 or 0.5)+attack,actorY+bob)
    for i,art in ipairs(self.enemies)do
      art:SetPoint("CENTER",self,"TOPLEFT",width*((self.enemyCount or 1)==1 and 0.73 or 0.54+(i-1)*0.17)-(event and event.actor==i and reply or 0),actorY)
    end
    self.pet:SetVertexColor(1,event and event.actor~=0 and event.amount>0 and motion and 0.6 or 1,1)
    if P.UpdatePetHeadHealthPositions then P.UpdatePetHeadHealthPositions(self)end
    P.UpdateNeeds(self,self.tower and t or (GetTime and GetTime() or t),motion)
    updateOutcome(self)
    P.UpdateProgressScene(self,dt or 0,motion)
    self.hardHudElapsed=(type(self.hardHudElapsed)=="number" and self.hardHudElapsed or 0)+(dt or 0)
    if P.HardRefreshScene and self.hardHudElapsed>=.05 then self.hardHudElapsed=0;P.HardRefreshScene(self)end
  end)
  return f
end
local function renderStage(f,pet,tower)
  f.tower=tower;f.needsPet=pet or false;f.allowRotation=not tower and pet~=nil and not (P.window and f==P.window.scene and P.mode=="peers")
  if P.CreatePortraitFrame and F.Achievements then
    if not rawget(f,"portraitBorder")then
      f.portraitBorder=P.CreatePortraitFrame(f,f)
      f.portraitBorder:ClearAllPoints();f.portraitBorder:SetPoint("TOPLEFT",6,-6);f.portraitBorder:SetPoint("BOTTOMRIGHT",-6,30)
      f.portraitBorder:SetFrameLevel(f:GetFrameLevel()+7)
    end
    P.UpdatePortraitFrame(f.portraitBorder,F.Achievements.Frame())
    local compact=P.mini and f==P.mini.scene
    local enabled=F.db.settings[compact and "showCompactPortraitFrame" or "showLargePortraitFrame"]~=false
    f.portraitBorder:SetShown(enabled and not tower and pet~=nil and (compact or P.mode~="peers"))
  end
  if rawget(f,"testDing")then f.testDing:SetEnabled(not not (pet and pet.id and not pet.deadAt))end
  local choice=tonumber(F.char.campScene) or 1;if choice<1 or choice>5 or choice~=math.floor(choice)then choice=1 end
  local faction=S.Faction()=="Alliance" and "Alliance" or "Horde"
  local custom=not tower and choice>1
  local path="Interface\\AddOns\\CompanionsForever\\Art\\"..(custom and "Camp"..faction..choice or "PetScenes"..faction)..".tga"
  local hard=tower and P.HardMode and P.HardMode.IsHard()
  if hard then path="Interface\\AddOns\\CompanionsForever\\Art\\HardTower.tga"end
  if f.backgroundPath~=path then f.bg:SetTexture(path,"CLAMP","CLAMP","LINEAR");f.backgroundPath=path end
  if custom or hard then f.bg:SetTexCoord(0,1,0,1)else f.bg:SetTexCoord(tower and 0.5 or 0,tower and 1 or 0.5,0.2,0.8)end
  f.bg:SetAlpha(S.HighContrast() and 0.25 or 1)
  f.campPrev:SetShown(not tower);f.campNext:SetShown(not tower)
  f.caption:ClearAllPoints();f.caption:SetPoint("TOPLEFT",tower and 8 or 42,-f.height+29);f.caption:SetWidth(f.width-(tower and 16 or 84))

  local b=P.state.battle;local result=tower and P.CurrentVictory()
  local defeat=tower and not pet and P.DisplayPet() and P.defeat
  local r=result and result.round or defeat and defeat.round or P.lastRound
  local recent=tower and r and r.enemy.floor==(P.floor or 1) and (result or defeat or (P.sceneClock or 0)-r.at<(r.duration or 3)+2)
  local age=r and (P.sceneClock or 0)-r.at or 9
  local _,step=P.VisualEvent((b or recent) and r or nil,P.sceneClock or 0)
  local enemies=tower and (b and b.enemies or recent and r.enemies or P.Enemies(P.floor or 1)) or {}
  f.round=tower and (b or recent) and r or false;f.displayEnemies=enemies
  f.enemyCount=#enemies
  local shownPet=pet or (recent and r.pet) or nil
  f.needsPet=shownPet or false
  local key=tower and (b and b.enemies or recent and r.enemies or "floor"..(hard and "hard" or "normal")..(P.floor or 1).."pet"..tostring(shownPet and shownPet.id)) or ("camp"..tostring(shownPet and (shownPet.id or shownPet.species))..tostring(shownPet and shownPet.deadAt))
  local scale=(f.width-12)/464
  local enemyScale=scale*(#enemies>1 and 0.75 or 1)
  f.hudHeight=tower and 94 or 0
  f.arenaHeight=f.height-f.hudHeight-26
  if f.arena.scene then
    f.arena.scene:ClearAllPoints()
    f.arena.scene:SetPoint("TOPLEFT",f,"TOPLEFT",6,-f.hudHeight-16)
    f.arena.scene:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-6,30)
    f.arena:Sync(shownPet,enemies,key)
    f.arena:Update(f.round,0,not not (tower and b and b.paused),not F.db.settings.reduceMotion)
  end
  local function place(frame,column,row,frameScale)
    frameScale=frameScale or scale
    frame:SetScale(frameScale);frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT",f,"TOPLEFT",(6+column*(f.width-12)/2)/frameScale,-row*86)
    -- Slightly larger type in the compass while keeping the native bar geometry.
    local path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    for _,label in ipairs({frame.name,frame.percent,frame.amount,frame.level})do
      label:SetFont(path,frameScale<0.7 and 16 or 12,"OUTLINE")
    end
    frame.detail:SetFont(path,frameScale<0.7 and 13 or 10,"OUTLINE")
  end
  place(f.leftHP,0,0);unitInfo(f.leftHP,shownPet,false)
  showSprite(f.pet,shownPet)
  local petSize=tower and math.min(f.height*0.65,f.arenaHeight*0.95) or f.height*0.88
  f.pet:SetSize(petSize,petSize)
  for i,art in ipairs(f.enemies)do
    local e=enemies[i];showSprite(art,e,true)
    local size=math.min(f.height*(#enemies>1 and 0.44 or 0.65),f.arenaHeight*0.85)*(e and e.elite and 1.15 or 1)
    art:SetSize(size,size)
    local bar=f.enemyHP[i]
    place(bar,1,i-1,enemyScale)
    unitInfo(bar,e,true);bar:SetShown(e~=nil and not P.HardRefreshScene)
    if e then healthValue(bar,step and step.enemyHP[i] or e.hp or e.maxHP,e.maxHP)end
  end
  f.leftHP:SetShown(tower and shownPet~=nil and not P.HardRefreshScene)
  -- The elite label now lives inside the native frame's lower strip.
  f.float:ClearAllPoints();f.float:SetPoint("TOPLEFT",10,-f.hudHeight+4)
  if tower then
    local maxHP=b and b.maxHP or shownPet and P.Stats(shownPet) or 1
    if step then healthValue(f.leftHP,step.hp,step.maxHP or r.maxHP)
    elseif shownPet then healthValue(f.leftHP,b and b.hp or math.floor(maxHP*(shownPet.health or 0)/100),maxHP)end
    f.caption:SetText(b and (b.paused and "Paused" or "Round "..(b.turn+1).." - 1 vs "..#enemies) or "Floor "..(P.floor or 1).." - "..P.FloorStatus(P.floor or 1))
  else f.caption:SetText(pet and (pet.resting and P.RestText(pet) or P.rarities[pet.rarity].." "..P.PetName(pet)) or "Your next companion awaits")end
  if pet and P.ModelUnavailable(pet.species)then f.caption:SetText("Model unavailable - showing substitute")end
  f.pet:SetShown(shownPet~=nil and not (f.arena.states[0] and f.arena.states[0].loaded))
  for i,art in ipairs(f.enemies)do art:SetShown(enemies[i]~=nil and not (f.arena.states[i] and f.arena.states[i].loaded))end
  P.UpdateNeeds(f,GetTime and GetTime() or P.sceneClock or 0,not F.db.settings.reduceMotion)
  updateOutcome(f)
end
local function careIcons(parent,x,y,size,gap)
  local result={}
  for i,entry in ipairs({{"food","Feed"},{"rest","Rest"},{"medicine","Heal"}})do
    local key=entry[1]
    result[i]=icon(parent,key,entry[2],x+(i-1)*gap,y,size,function()return P.UseCare(key)end,function()
      local item=P.items[key]
      return item and ((key=="food" and ("+35 food, +"..P.HealingAmount("food").."% health. ") or ("+"..P.HealingAmount("medicine").."% health. "))..P.state.inventory[key].." available. When empty: "..P.SupplyCost(key).." tokens.") or "Restores energy, then 1 HP every 5 sec. Needs 10+ food. Wakes when full; click to wake early."
    end)
  end
  return result
end
local function fightIcons(parent,x,y,size,gap)
  return {
    icon(parent,"fight","Fight",x,y,size,function()return P.StartBattle(P.floor or 1)end,function()
      local _,message=P.BattleReadiness(P.floor or 1)
      return message.."\nAttacks and guards are automatic; healing requires your click."
    end),
    icon(parent,"pause","Pause",x+gap,y,size,P.PauseBattle,"Pause or resume this pet battle. Hidden battle views pause automatically."),
    icon(parent,"medicine","Heal",x+gap*2,y,size,P.RequestHeal,function()
      local _,description=P.HealChoice()
      if P.HardMode and P.HardMode.IsHard()then return description.." Instantly heals the selected pet without using an attack turn."end
      return description..". Instant herb heal; does not use an attack turn."
    end)}
end
function P.BattleVisible()
  return (P.window and P.window:IsShown() and P.mode=="tower") or (P.mini and P.mini:IsShown() and F.compass and F.compass:IsShown() and P.miniMode=="tower")
end
function P.ToggleCompass(show)
  F.char.navPets=show==nil and not F.char.navPets or show
  if F.char.navPets then F.char.preferredView="compact";if P.window then P.window:Hide()end end
  F.UpdateNavigator();P.Render()
end
function P.TogglePreferred()
  if F.char.preferredView=="compact"then P.ToggleCompass()else P.Toggle()end
end
function P.BuildCompass(parent)
  local m=S.Panel(parent,8,-129,284,356);P.mini=m;P.miniMode="care";P.floor=P.floor or 1
  m.careButton=S.Button(m,"Camp",8,-8,80,function()P.miniMode="care";P.Render()end)
  m.towerButton=S.Button(m,"Tower",98,-8,80,function()P.miniMode="tower";P.Render()end)
  m.openButton=S.Button(m,"Open",188,-8,86,function()P.OpenPage(P.miniMode=="tower" and "tower" or "collection")end)
  m.scene=stage(m,8,-40,268,137)
  m.footer=CreateFrame("Frame",nil,m);m.footer:SetSize(284,356);m.footer:SetPoint("TOPLEFT")
  m.style=S.Button(m.footer,"",44,-179,196,function()act(P.CycleStyle)end)
  m.stats=text(m.footer,"",10,-182,264,20);m.stats:SetJustifyH("CENTER")
  m.petXP=P.BuildPetXP(m.footer,true);m.petXP:SetPoint("TOPLEFT",10,-186);m.petXP:SetSize(264,10)
  m.readiness=text(m.footer,"",10,-205,264,22);m.readiness:SetJustifyH("CENTER");m.readiness:SetMaxLines(1)
  m.health=meter(m.footer,10,-208,127,"",careColors.health);m.food=meter(m.footer,147,-208,127,"",careColors.food)
  frameHealth(m.health)
  m.energy=meter(m.footer,10,-232,264,"",careColors.energy)
  for _,entry in ipairs({{m.health,"Health"},{m.food,"Food"},{m.energy,"Energy"}})do
    entry[1]:EnableMouse(true);tip(entry[1],entry[2],"Out of 100. Use Feed, Rest or Heal to care for your companion.")
  end
  m.care=careIcons(m.footer,37,-263,34,86);m.battle=fightIcons(m.footer,37,-263,34,86);m.enter=m.battle[1]
  m.prev=S.Button(m.footer,"<",10,-232,32,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  m.next=S.Button(m.footer,">",242,-232,32,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1)end;P.Render()end)
  m.floor=text(m.footer,"",50,-233,184,22);m.floor:SetJustifyH("CENTER")
  m.notice=text(m.footer,"",10,-324,160,24);m.notice:SetMaxLines(1)
  m.stock=P.BuildResourceBar(m.footer,10,-352,264,true)
  m.supplies=S.Button(m.footer,"Supplies",178,-321,96,function()P.OpenStore(m)end)
  tip(m,"Companion",function()return P.notice or "Open the large view to adopt, switch companions and inspect other players."end)
  m.adopt=S.Button(m.footer,"Adopt companion",49,-265,186,function()P.OpenAdopt()end)
  m:Hide()
end
function P.RenderCompass()
  local m=P.mini;if not m or not P.state or not m:IsShown()then return end
  local pet=P.Active();local tower=P.miniMode=="tower";local b=P.state.battle
  if not b and pet then P.floor=math.max(1,math.min(P.floor or 1,P.Unlocked()))end
  local extra=tower and 190 or 60
  local layoutChanged=m.towerLayout~=tower;m.towerLayout=tower
  m:SetHeight(400+extra);m.footer:ClearAllPoints();m.footer:SetPoint("TOPLEFT",0,-extra)
  -- Leave a separate line above Camp XP without making the compact window taller.
  m.scene.height=137+extra-(tower and 0 or 20);m.scene:SetHeight(m.scene.height)
  m.scene.caption:ClearAllPoints();m.scene.caption:SetPoint("TOPLEFT",8,-m.scene.height+29)
  renderStage(m.scene,pet or (not tower and P.DisplayPet()),tower)
  m.stock.refresh()
  m.style:SetShown(tower);m.stats:SetShown(not tower)
  m.style:SetText("Style: "..P.styles[pet and pet.style or 1].name);m.style:SetEnabled(pet~=nil and not b)
  m.stats:SetText(pet and ("Lv "..pet.level.." | XP "..pet.xp.." | "..P.TokenText(P.state.tokens)) or "A new friend for your journey")
  P.UpdatePetXP(m.petXP,not tower and pet or nil);m.stats:SetShown(not tower and not pet)
  fill(m.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0));fill(m.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0))
  fill(m.energy,pet and pet.energy or 0,"Energy "..math.floor(pet and P.EnergyPoints(pet) or 0).." / "..P.MaxEnergy())
  m.energy:SetShown(not tower)
  m.health:SetShown(not tower);m.food:SetShown(not tower);m.prev:SetShown(tower);m.next:SetShown(tower);m.floor:SetShown(tower)
  m.floor:SetText("Floor "..(b and b.floor or P.floor).." | "..P.FloorStatus(b and b.floor or P.floor))
  local ready,_,summary=P.BattleReadiness(P.floor or 1)
  m.readiness:SetShown(tower);m.readiness:SetText(b and P.StatusText(b) or summary);S.TextColor(m.readiness,ready and {0.4,1,0.4} or S.gold)
  for _,control in ipairs(m.care)do shown(control,not tower and pet~=nil)end
  m.care[2].label:SetText(pet and pet.resting and "Wake" or "Rest")
  for _,control in ipairs(m.battle)do shown(control,tower and pet~=nil)end
  m.enter:SetEnabled(not b and not (P.VictoryPending and P.VictoryPending()));m.battle[2].label:SetText(b and b.paused and "Resume" or "Pause")
  m.enter.label:SetText(P.VictoryPending and P.VictoryPending() and "Wait" or P.FloorStatus(P.floor)=="Completed" and "Replay" or "Fight")
  m.battle[2]:SetEnabled(b~=nil);m.battle[3]:SetEnabled(b~=nil and P.HealChoice()~=nil)
  m.battle[3].label:SetText("Heal")
  m.adopt:SetShown(pet==nil);m.notice:SetText(P.notice or "Hover an icon for details")
  if layoutChanged and F.char.navPets then F.UpdateNavigator()end
end
function P.SettingsButton(parent,x,y)
  local b=CreateFrame("Button",nil,parent);b:SetPoint("TOPLEFT",x,y);b:SetSize(26,26)
  b:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
  b:SetScript("OnClick",function()F.ToggleSettings()end)
  tip(b,"Settings","Appearance and accessibility options.");return b
end
function P.BuildCrateOdds(parent,odds,x,y,width,index)
  parent.oddsRows=rawget(parent,"oddsRows") or {};local visible=0;local highest=1
  for rarity,chance in ipairs(odds)do if chance>0 then
    visible=visible+1
    local color=P.CrateOddsColor(rarity);highest=rarity
    local row=parent.oddsRows[visible]
    if not row then
      local swatch=parent:CreateTexture(nil,"ARTWORK");swatch:SetPoint("TOPLEFT",x,y-(visible-1)*20-4);swatch:SetSize(3,12)
      local label=text(parent,"",x+8,y-(visible-1)*20,width-60,20,color)
      local value=text(parent,"",x+width-50,y-(visible-1)*20,50,20,color);value:SetJustifyH("RIGHT")
      row={label=label,value=value,swatch=swatch};parent.oddsRows[visible]=row
    end
    row.rarity=rarity;row.chance=chance;row.label:SetText(P.CrateOddsLabel(rarity));row.value:SetText(string.format("%g%%",chance))
    S.TextColor(row.label,color);S.TextColor(row.value,color);row.swatch:SetColorTexture(unpack(color))
    row.label:Show();row.value:Show();row.swatch:Show()
  end end
  for i=visible+1,#parent.oddsRows do local row=parent.oddsRows[i];row.label:Hide();row.value:Hide();row.swatch:Hide()end
  parent:SetBackdropBorderColor(unpack(S.RarityColor(P.CrateOddsColor(index and P.ContainerRarity(index) or highest))))
end
function P.BuildCrateModel(parent,index)
  local model=P.CrateModel(index)
  local f=CreateFrame("Frame",nil,parent);f:SetPoint("TOPLEFT",8,-39);f:SetSize(110,105);f:EnableMouse(false);f:SetClipsChildren(true)
  f.loaded=false;f.age=0;f.pathTried=false
  local icon=f:CreateTexture(nil,"ARTWORK");icon:SetTexture("Interface\\Icons\\"..model.icon);icon:SetSize(64,64);icon:SetPoint("CENTER");f.fallback=icon
  local function fit()
    if f.loaded or not f.actor:IsLoaded()then return end
    local ok,x,y,z,tx,ty,tz=pcall(f.actor.GetMaxBoundingBox,f.actor)
    if ok and (type(x)=="table" or type(x)=="userdata") and x.GetXYZ and y and y.GetXYZ then
      local lower,upper=x,y;x,y,z=lower:GetXYZ();tx,ty,tz=upper:GetXYZ()
    end
    if not ok or type(x)~="number" or type(y)~="number" or type(z)~="number" or type(tx)~="number" or type(ty)~="number" or type(tz)~="number"then return end
    local extent=math.max(tx-x,ty-y,tz-z);if extent<=0 or extent~=extent then return end
    f.actor:SetUseCenterForOrigin(true,true,true);f.actor:SetScale(math.max(.001,math.min(10,1.8/extent)))
    f.actor:SetPosition(0,0,0);f.actor:SetYaw(math.pi*1.25);f.actor:SetAlpha(1);f.actor:Show()
    pcall(f.actor.SetAnimation,f.actor,model.animatedLid and 147 or 0,0,1,0)
    f.loaded=true;icon:Hide();f:SetScript("OnUpdate",nil)
  end
  local ok=pcall(function()
    local scene=CreateFrame("ModelScene",nil,f);f.scene=scene;scene:SetAllPoints();scene:EnableMouse(false)
    scene:SetCameraNearClip(.1);scene:SetCameraFarClip(100);scene:SetCameraFieldOfView(math.rad(36))
    scene:SetCameraPosition(0,-4.6,2.2);scene:SetCameraOrientationByAxisVectors(0,.902134,-.431456,-1,0,0,0,.431456,.902134)
    scene:SetLightVisible(true);scene:SetLightAmbientColor(.85,.85,.85);scene:SetLightDiffuseColor(1,.95,.85);scene:SetLightDirection(-.4,1,-1)
    f.actor=scene:CreateActor("CompanionsForeverCratePreview"..index,"CompanionsForeverActorTemplate")
    f.actor.cfArena={ModelLoaded=fit}
    f.actor:SetModelByFileID(model.id);fit()
  end)
  if ok and not f.loaded then
    f:SetScript("OnUpdate",function(_,dt)
      f.age=f.age+dt;fit()
      if not f.loaded and f.age>=3 and not f.pathTried then f.pathTried=true;pcall(f.actor.SetModelByPath,f.actor,model.path)end
      if not f.loaded and f.age>=8 then f.scene:Hide();f:SetScript("OnUpdate",nil)end
    end)
  elseif not ok and rawget(f,"scene")then f.scene:Hide()end
  parent.containerPreview=f
end
function P.CrateTabs(parent,selected)
  local pet=S.Button(parent,"Pet",658,-12,132,function()P.OpenPage("adoption")end)
  local gear=S.Button(parent,"Gear",800,-12,132,function()P.OpenPage("boxes")end)
  pet:SetEnabled(selected~="adoption");gear:SetEnabled(selected~="boxes")
end
function P.BuildUI()
  if P.window then return end
  local w=S.Panel(UIParent,0,0,1000,738);P.window=w;P.mode="collection";P.page=1;P.floor=P.floor or 1
  _G.CompanionsForeverMainWindow=w;UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverMainWindow"
  w:ClearAllPoints();w:SetPoint("CENTER");S.RegisterWindow(w,3);w:SetClampedToScreen(true);w:SetMovable(true);w:EnableMouse(true);w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart",function(self)self.cfDragging=true;self:StartMoving()end)
  w:SetScript("OnDragStop",function(self)self.cfDragging=nil;self:StopMovingOrSizing()end)
  S.EnableMovementFade(w)
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3);close:SetScript("OnClick",function()w:Hide()end)
  text(w,"COMPANIONS FOREVER",22,-16,560,26)
  text(w,"YOUR COMPANIONS. YOUR ADVENTURE.",310,-18,430,24,S.muted)
  S.Button(w,"Compact",844,-14,110,function()w:Hide();P.ToggleCompass(true)end)
  w.miniToggle=S.Button(w,F.char.petIconHidden and "Mini: off" or "Mini: on",748,-14,86,function()F.TogglePetIcon()end)
  tip(w.miniToggle,"Mini pet window","Show or hide the small floating pet window. Drag that window to move it.")
  w.tabs={}
  for i,entry in ipairs({{"collection","Camp"},{"tower","Tower"},{"equipment","Equipment"},{"talents","Talents"},{"journal","Collection"},{"adoption","Crates"},{"peers","Inspect"}})do
    local mode=entry[1]
    w.tabs[mode]=S.Button(w,entry[2],20+(i-1)*138,-52,130,function()P.OpenPage(mode)end)
    w.tabs[mode]:SetHeight(32)
    if mode=="collection" or mode=="journal" or mode=="equipment" then
      local mark=text(w.tabs[mode],"NEW",53,6,36,14);mark:SetJustifyH("RIGHT");mark:Hide();w.tabs[mode].newMark=mark
    end
  end
  w.home=CreateFrame("Frame",nil,w);w.home:SetAllPoints(w)
  w.scene=stage(w.home,20,-94,456,400)
  w.health=meter(w.home,20,-509,220,"",careColors.health);w.food=meter(w.home,256,-509,220,"",careColors.food)
  frameHealth(w.health)
  w.energy=meter(w.home,20,-542,456,"",careColors.energy)
  w.petXP=P.BuildPetXP(w.home,true);w.petXP:SetPoint("TOPLEFT",20,-586);w.petXP:SetSize(456,10)
  w.care=careIcons(w.home,75,-608,45,145);w.fight=fightIcons(w.home,75,-582,45,145)
  w.readiness=text(w.home,"",20,-561,456,20);w.readiness:SetJustifyH("CENTER");w.readiness:SetMaxLines(1)
  w.side=S.Panel(w.home,492,-94,268,424)
  w.name=text(w.side,"",14,-14,240,46);w.meta=text(w.side,"",14,-60,240,82,S.muted)
  w.retire=S.Button(w.side,"Retire",182,-14,72,function()P.OpenRetirement(w.retire.petID)end)
  w.retirementLock=S.Button(w.side,"",148,-14,30,function()
    local id=w.retire.petID
    for _,pet in ipairs(P.state.pets)do if pet.id==id then P.SetRetirementLock(id,not pet.retirementLocked);break end end
    P.Render()
  end)
  w.retirementLock.pieces={}
  for index,part in ipairs({{10,4,2,8},{18,4,2,8},{10,4,10,2},{8,11,14,11},{14,14,2,5}})do
    local art=w.retirementLock:CreateTexture(nil,"OVERLAY",nil,index==5 and 2 or 1);art:SetPoint("TOPLEFT",part[1],-part[2]);art:SetSize(part[3],part[4])
    art:SetColorTexture(.9,.72,.25,1);w.retirementLock.pieces[#w.retirementLock.pieces+1]=art
  end
  w.retirementLock.pieces[5]:SetColorTexture(.08,.06,.02,1)
  tip(w.retirementLock,"Retirement lock","Lock this pet to prevent retirement. Click again to unlock. This does not prevent battling or trading.")
  tip(w.retire,"Retire companion","Review talent XP and confirm permanent retirement. Gear returns to the bag; the collection discovery stays unlocked.")
  w.statsPanel=S.Panel(w.home,776,-94,204,424);w.statRows={};w.statLabels={}
  text(w.statsPanel,"PET STATS",12,-8,110,22)
  w.racial=P.BuildRacialIcon(w.statsPanel,163,-333)
  text(w.statsPanel,"Total",126,-8,66,22):SetJustifyH("RIGHT")
  text(w.statsPanel,"Base + |cff33ff66Gear|r + |cff55aaffTalents|r",10,-32,184,22,S.muted)
  w.statParts={};w.statHighlights={}
  for i,label in ipairs({"Max health","Attack","Armor","Speed","Hit chance","Miss chance","XP"})do
    local y=i<=4 and (-54-(i-1)*44) or (-236-(i-5)*24)
    w.statLabels[i]=text(w.statsPanel,label,12,y,100,22,S.muted)
    local help=CreateFrame("Frame",nil,w.statsPanel);help:SetPoint("TOPLEFT",10,y);help:SetSize(184,i<=4 and 43 or 23);help:EnableMouse(true)
    tip(help,label,function()
      local pet=P.Active();for _,candidate in ipairs(P.state.pets)do if candidate.id==P.viewID then pet=candidate;break end end
      if not pet then return "Select a companion."end
      return P.StatHelp and P.StatHelp(pet,i) or "Select a companion to view its current stats."
    end)
    local value=text(w.statsPanel,"",110,y,82,22);value:SetJustifyH("RIGHT");w.statRows[i]=value
    if i<=4 then w.statHighlights[i]=P.BuildStatRollBar(w.statsPanel,w.statLabels[i],value)end
    if i<=4 then w.statParts[i]=text(w.statsPanel,"",12,y-22,180,24,{1,1,1})end
  end
  text(w.statsPanel,"SPECIAL ABILITIES",12,-308,180,22)
  w.abilityIcons={}
  w.abilityEmpty=text(w.statsPanel,"Rare quality or higher",12,-333,180,22,S.muted)
  for i=1,2 do
    local b=CreateFrame("Frame",nil,w.statsPanel,"BackdropTemplate");w.abilityIcons[i]=b
    b:SetPoint("TOPLEFT",12+(i-1)*44,-333);b:SetSize(28,28);b:EnableMouse(true)
    b:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",2,-2);b.art:SetPoint("BOTTOMRIGHT",-2,2)
    b:SetScript("OnEnter",function(self)
      local ability=self.ability;if not ability then return end
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(ability.ability)
      GameTooltip:AddLine(P.AbilityHelp(ability),1,1,1,true)
      if not F.db.settings.shortPetTooltips then GameTooltip:AddLine("Each special has its own cooldown. One special per pet per turn. "..(P.IsHealingAbility(ability) and "Select its special button to use it next turn." or "Used by Special turns in your fighting style."),0.65,0.8,1,true)end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end);b:Hide()
  end
  text(w.statsPanel,"ACTIVE EFFECTS",12,-360,180,22)
  w.effects=text(w.statsPanel,"",12,-386,180,32)
  w.statsPanel:EnableMouse(true)
  tip(w.statsPanel,"Combat stats","Hover a stat or effect for details. Speed affects turn order and hit chance. Effects end after battle.")
  tip(w.side,"Pet progression","Gain XP in the tower or from eligible kills (12 base XP/min). Retire pets in Talents to raise the level cap.")
  tip(w.scene,"Companion details",function()
    local pet=P.Active()
    if P.mode=="collection" and P.viewID then for _,candidate in ipairs(P.state.pets)do if candidate.id==P.viewID then pet=candidate;break end end end
    if not pet then return "Adopt a companion to begin." end
    local details={}
    for _,ability in ipairs(P.Abilities(pet))do details[#details+1]=ability.ability..": "..P.AbilityHelp(ability)end
    return "Left-drag to rotate.\nXP: "..P.XPText(pet).."\nLifespan: "..P.Age(pet.age).."\n"..P.Specialty(pet).."\n"..(#details>0 and table.concat(details,"\n") or P.AbilityText(pet)).."\nEach special has its own cooldown. One special per pet per turn."
  end)
  w.collection=S.Panel(w.side,6,-146,256,272);local c=w.collection;c.rows={}
  for i=1,16 do
    local row=CreateFrame("Button",nil,c,"BackdropTemplate");c.rows[i]=row
    row:SetPoint("TOPLEFT",16+((i-1)%3)*76,-8-math.floor((i-1)/3)*66);row:SetSize(64,62)
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2});row:SetBackdropColor(0.035,0.035,0.045,1)
    row.art=sprite(row,54);row.art:SetPoint("CENTER")
    row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    row.info=text(row,"",2,-42,60,18);row.info:SetJustifyH("CENTER")
    row.selected=row:CreateTexture(nil,"OVERLAY");row.selected:SetAllPoints();row.selected:SetTexture("Interface\\Buttons\\CheckButtonHilight");row.selected:SetBlendMode("ADD")
    row:SetScript("OnClick",function(self)if self.petID then P.viewID=self.petID;P.MarkPetSeen(self.petID);P.Render()end end)
    tip(row,"Companion",function()
      local pet=row.pet
      return pet and (P.rarities[pet.rarity].." "..P.PetName(pet).."\nLevel "..pet.level.." | "..(pet.deadAt and "Memorial" or pet.id==P.state.active and "Equipped" or "Stabled").."\n"..P.Specialty(pet).."\nClick to preview; drag to move or swap stable slots. Equip selects your traveling companion.") or "Empty companion slot. Drag a pet here to move it."
    end)
  end
  c.prev=S.Button(c,"<",8,-204,30,function()P.page=math.max(1,P.page-1);P.Render()end)
  c.next=S.Button(c,">",218,-204,30,function()P.page=P.page+1;P.Render()end)
  c.page=text(c,"",40,-204,176,22);c.page:SetJustifyH("CENTER")
  S.Button(c,"Adopt",8,-238,114,function()P.OpenAdopt()end)
  c.equip=S.Button(c,"Equip",134,-238,114,function()act(function()return P.Select(P.viewID)end)end)
  w.gearPreview=S.Panel(w.home,492,-530,488,124);w.gearPreview.slots={}
  text(w.gearPreview,"EQUIPPED GEAR",12,-8,210,24)
  S.Button(w.gearPreview,"Go to Equipment",276,-6,200,function()P.OpenEquipment()end)
  for i,slot in ipairs(P.gearSlots)do
    local b=CreateFrame("Frame",nil,w.gearPreview,"BackdropTemplate");w.gearPreview.slots[i]=b;b.slot=slot
    b:SetPoint("TOPLEFT",12+(i-1)*94,-38);b:SetSize(88,78);b:EnableMouse(true)
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOP",0,-2);b.art:SetSize(38,38)
    b.label=text(b,P.gearSlotNames[slot],0,-42,88,18);b.label:SetJustifyH("CENTER")
    b.status=text(b,"",0,-60,88,18);b.status:SetJustifyH("CENTER")
    b:SetScript("OnEnter",function(self)P.EquipmentTooltip(self,b.item,"Read-only preview. Use Go to Equipment to make changes.")end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  w.tower=S.Panel(w.side,6,-146,256,272);local t=w.tower
  tip(t,"Tower challenge",function()
    local floor=P.state.battle and P.state.battle.floor or P.floor
    return floor%10==0 and "An elite leads this fight: more health, damage and armor. Its heavy attack hits harder every third round. Prepare supplies and use Heal yourself." or "Clear this floor to unlock the next. Every tenth floor is an elite encounter."
  end)
  t.info=text(t,"",12,-12,232,98)
  t.style=S.Button(t,"",12,-159,232,function()act(P.CycleStyle)end)
  tip(t.style,"Fighting style",function()
    local pet=P.Active();local style=P.styles[pet and pet.style or 1]
    return style.help.." No consecutive automatic guards. Change styles between fights."
  end)
  S.Button(t,"<",12,-118,40,function()if not P.state.battle then P.floor=math.max(1,P.floor-1)end;P.Render()end)
  S.Button(t,">",204,-118,40,function()if not P.state.battle then P.floor=math.min(P.Unlocked(),P.floor+1)end;P.Render()end)
  t.floor=text(t,"",57,-120,142,24);t.floor:SetJustifyH("CENTER")
  text(t,"Click Heal to save your pet.\nDefeat is permanent.\nNo consecutive auto guards.",12,-198,232,68)
  w.social=S.Panel(w.side,6,-146,256,272);local p=w.social
  p.share=S.Button(p,"",8,-8,240,function()P.SetSharing(not P.state.share);P.Render()end)
  S.Button(p,"Inspect target",8,-48,240,function()act(P.InspectTarget)end)
  p.text=text(p,"",12,-94,232,86)
  S.Button(p,"Trade",8,-192,240,function()P.OpenTrade()end)
  S.Button(p,"<",8,-234,35,function()P.inspectName=nil;P.page=math.max(1,P.page-1);P.Render()end)
  S.Button(p,">",213,-234,35,function()P.inspectName=nil;P.page=P.page+1;P.Render()end)
  p.page=text(p,"",46,-236,164,24);p.page:SetJustifyH("CENTER")
  w.notice=text(w,"",22,-662,732,28);w.notice:SetMaxLines(2)
  w.settingsCog=P.SettingsButton(w,948,-702)
  S.Button(w,"Supplies",800,-704,132,function()P.OpenStore(w)end)
  w.stock=P.BuildResourceBar(w,22,-694,732,false)
  w:Hide()
end
-- All full-size destinations share a single owner and navigation bar.
function P.NewPage()
  P.BuildUI()
  local page=CreateFrame("Frame",nil,P.window);page:SetPoint("TOPLEFT",20,-94);page:SetSize(960,550)
  page:EnableMouse(true);page:Hide();return page
end
function P.OpenPage(mode)
  F.char.preferredView="large"
  if mode=="store" then P.OpenStore();return end
  P.BuildUI();P.mode=mode;P.page=1
  if P.supplyTrays then for _,tray in ipairs(P.supplyTrays)do tray:Hide()end end
  if mode=="peers" and P.BuildInspect and not P.inspect then P.BuildInspect()end
  if mode=="trade" and not P.trade then P.BuildTrade()end
  if mode=="journal" and not P.journal then P.BuildJournal()end
  if mode=="equipment" and not P.equipment then P.BuildEquipment()end
  if mode=="talents" and not P.talents then P.BuildTalents()end
  if mode=="boxes" and not P.boxes then P.BuildEquipmentBoxes()end
  if mode=="adoption" and not P.adoption then P.OpenAdopt();return end
  if mode=="settings" and not F.settings then F.OpenSettings();return end
  P.window:Show()
  if F.compass then P.ToggleCompass(false)end
  P.Render()
end
function P.Toggle()
  P.BuildUI()
  if P.window:IsShown()then P.window:Hide()else P.OpenPage(P.mode or "collection")end
end
function P.OpenStore(parent)
  P.BuildUI();parent=parent or (F.compass and F.compass:IsShown() and P.mini) or P.window
  parent=parent or P.window
  local tray=rawget(parent,"supplyTray")
  if not tray then
    tray=S.Panel(parent,0,0,268,166);parent.supplyTray=tray
    tray:ClearAllPoints();tray:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-8,42)
    tray:SetFrameLevel(parent:GetFrameLevel()+30);tray:EnableMouse(true)
    text(tray,"SUPPLIES",10,-8,202,24)
    S.Button(tray,"X",232,-6,26,function()tray:Hide()end)
    tray.quantity=1;tray.rows={};tray.buttons={}
    tray.amount=S.Button(tray,"Buy quantity: 1",10,-38,248,function()
      tray.quantity=tray.quantity==1 and 5 or tray.quantity==5 and 10 or 1;P.RenderStore()
    end)
    for i,key in ipairs({"food","medicine"})do
      local itemKey=key;local item=P.items[key];local y=-76-(i-1)*42
      tray.rows[key]=text(tray,"",10,y,150,36)
      tray.buttons[key]=S.Button(tray,"",164,y,94,function()
        local ok,msg=P.Buy(itemKey,tray.quantity)
        P.notice=ok and ("Bought "..tray.quantity.." "..item.name..".") or msg;P.Render();P.RenderStore()
      end)
    end
    P.supplyTrays=P.supplyTrays or {};P.supplyTrays[#P.supplyTrays+1]=tray
    tray:Hide()
  end
  tray:SetShown(not tray:IsShown());P.RenderStore()
end
function P.RenderStore()
  for _,tray in ipairs(P.supplyTrays or {})do if tray:IsShown()then
    tray.amount:SetText("Buy quantity: "..tray.quantity)
    for key,label in pairs(tray.rows)do
      local item=P.items[key]
      label:SetText("|TInterface\\Icons\\"..item.icon..":18|t "..item.name.." ("..P.state.inventory[key]..")")
      tray.buttons[key]:SetText(P.TokenText(P.SupplyCost(key)*tray.quantity))
      tray.buttons[key]:SetEnabled(P.state.tokens>=P.SupplyCost(key)*tray.quantity and P.state.inventory[key]+tray.quantity<=P.supplyCap)
    end
  end end
end
function P.OpenAdopt()
  if not P.adoption then
    local a=P.NewPage();P.adoption=a
    a.crateTitle=text(a,"CRATES",22,-16,500,28)
    P.CrateTabs(a,"adoption")
    a.cards={}
    for i,pack in ipairs(P.packs)do
      local index=i;local x=16+((i-1)%3)*320;local y=-58-math.floor((i-1)/3)*190
      local c=S.Panel(a,x,y,308,180);a.cards[i]=c
      text(c,pack.name,12,-7,284,30)
      P.BuildCrateModel(c,i)
      P.BuildCrateOdds(c,P.CrateOdds("pet",i),126,-42,170,i)
      c.open=S.Button(c,"",12,-148,222,function()act(function()return P.Adopt(index)end)end)
      c.owned=text(c,"",246,-148,50,24)
      tip(c,pack.name,function()return "One random companion; duplicates possible.\n"..P.CrateOddsHelp("pet",index)end)
    end
    a.info=text(a,"",20,-487,920,44,S.muted)
    a.rescue=S.Button(a,"Free recovery crate",20,-440,244,function()act(P.Rescue)end)
    tip(a.rescue,"Free recovery crate","Requires an empty stable, including memorials. One Common starter pet. Train it to earn retirement XP.")
    a.claim=S.Button(a,"Claim raid companion",286,-440,270,function()act(function()return P.ClaimBoss(a.bossSpecies)end)end)
    a.close=S.Button(a,"Back to pets",578,-440,222,function()P.OpenPage("collection")end)
    a.notice=text(a,"",20,-526,920,24);a.notice:SetMaxLines(2)
  end
  P.OpenPage("adoption")
end
function P.RenderAdopt()
  local a=P.adoption;if not a or not a:IsShown() or not P.state then return end
  a.crateTitle:SetText(P.HardMode and P.HardMode.IsHard() and "CRATES - HARD MODE" or "CRATES")

  local s=P.state
  local reserved=F.Trades and F.Trades.RecordReserved("pet") or 0
  local full=P.StableCount()>=P.stableCapacity or #s.pets+reserved>=512 or s.nextID+reserved>=1000000
  for i,c in ipairs(a.cards)do
    P.BuildCrateOdds(c,P.CrateOdds("pet",i),126,-42,170,i)
    c.open:SetText(full and "Stable full" or "Buy - "..P.TokenText(P.packs[i].cost))
    c.open:SetEnabled(not full and not s.battle and s.tokens>=P.packs[i].cost)
    c.owned:SetText("1 pet")
  end
  local count=0;for species in pairs(s.collection or {})do if (not P.IsAllowedSpecies or P.IsAllowedSpecies(species)) and not (F.PetData.hiddenSpecies and F.PetData.hiddenSpecies[species])then count=count+1 end end
  a.info:SetText(P.TokenText(s.tokens).." | "..count.." / "..(P.RosterCount and P.RosterCount() or #P.species).." species found\nEmpty stable? Use the free recovery crate. Earn 2 tokens per 5 minutes online.")
  a.rescue:SetEnabled(#s.pets==0 and not s.battle)
  a.bossSpecies=false;for i=85,100 do if (s.bossEggs[i] or 0)>0 then a.bossSpecies=i;break end end
  a.claim:SetEnabled(not not a.bossSpecies and not s.battle and P.StableCount()<P.stableCapacity)
  tip(a.claim,"Raid companion",a.bossSpecies and ("Claim epic "..P.species[a.bossSpecies]..". Other waiting boss companions remain saved.") or "Supported raid bosses have a 5% chance to grant their own epic companion. One roll per boss per seven days.")
  a.notice:SetText(P.notice or "Choose an adoption crate. Your equipped pet stays with you.")
end
function P.UpdateNewMarkers()
  local w=P.window;if not w or not P.state then return end
  local pets,collection,gear=false,#P.state.finds>0,false
  for _,pet in ipairs(P.state.pets)do if pet.isNew then pets=true;break end end
  for _,entry in pairs(P.state.collection)do if entry.isNew then collection=true;break end end
  for _,item in ipairs(P.state.gear)do if item.isNew then gear=true;break end end
  for _,item in ipairs(P.state.crates or {})do if item.isNew then gear=true;break end end
  if (P.state.pendingCrates or 0)>0 then gear=true end
  w.tabs.collection.newMark:SetShown(pets)
  w.tabs.journal.newMark:SetShown(collection)
  w.tabs.equipment.newMark:SetShown(gear)
end
function P.Render()
  if F.RenderPetIcon then F.RenderPetIcon()end
  P.RenderCompass();local w=P.window;if not w or not P.state or not w:IsShown()then return end
  w:SetScale(F.AccessibleScale(F.db.settings.ledgerScale,1000,738))
  if P.mode=="peers" and P.BuildInspect and not P.inspect then P.BuildInspect()end
  local home=P.mode=="collection" or P.mode=="tower" or (P.mode=="peers" and not P.BuildInspect)
  w.home:SetShown(home)
  for key,frame in pairs({journal=P.journal,equipment=P.equipment,adoption=P.adoption,settings=F.settings,talents=P.talents,boxes=P.boxes,trade=P.trade,peers=P.inspect})do frame:SetShown(P.mode==key)end
  for key,button in pairs(w.tabs)do button:SetEnabled(P.mode~=key and not (key=="adoption" and P.mode=="boxes"))end
  P.UpdateNewMarkers()
  w.notice:SetText(P.notice or "A world of companions to discover.")
  w.stock.refresh()
  if P.RenderJournal then P.RenderJournal();P.RenderEquipment();P.RenderEquipmentBoxes()end
  P.RenderStore();P.RenderAdopt()
  if P.RenderTalents then P.RenderTalents()end
  if P.RenderTrade then P.RenderTrade()end
  if P.RenderInspect then P.RenderInspect()end
  if not home then return end
  local s=P.state;local pet=P.Active();local tower=P.mode=="tower";local social=P.mode=="peers";local viewed=pet;local owner
  if not s.battle and P.Active()then P.floor=math.max(1,math.min(P.floor or 1,P.Unlocked()))end
  if social then
    local rows={};for name,entry in pairs(P.peers)do rows[#rows+1]={name=name,pet=entry}end
    table.sort(rows,function(a,b)return a.name:lower()<b.name:lower()end)
    if P.inspectName then for i,row in ipairs(rows)do if row.name==P.inspectName then P.page=i;break end end end
    P.page=math.max(1,math.min(P.page,math.max(1,#rows)));local row=rows[P.page];viewed=row and row.pet;owner=row and row.name
    w.social.share:SetText(s.share and "Sharing: ON" or "Sharing: OFF")
    w.social.text:SetText(viewed and (owner.."\nHighest floor: "..viewed.best.." / 100\nTower wins: "..viewed.wins.."\nAlive: "..P.Age(viewed.age)) or "Target an opted-in addon user, or browse shared guild/group pets.")
    w.social.page:SetText(#rows>0 and (P.page.." / "..#rows.." pets") or "No shared pets")
  end
  if not social and not tower and P.viewID then
    for _,candidate in ipairs(s.pets)do if candidate.id==P.viewID then viewed=candidate;break end end
  end
  renderStage(w.scene,viewed,tower)
  P.UpdatePetXP(w.petXP,not tower and not social and viewed or nil)
  P.UpdateRacialIcon(w.racial)
  local abilities=P.Abilities(viewed)
  for i,b in ipairs(w.abilityIcons)do
    b.ability=abilities[i] or false;b:SetShown(not not b.ability)
    if b.ability then b.art:SetTexture("Interface\\Icons\\"..b.ability.icon);b:SetBackdropBorderColor(unpack(b.ability.rollTier and P.abilityColors[b.ability.rollTier] or P.colors[viewed.rarity]))end
  end
  w.abilityEmpty:SetShown(#abilities==0)
  w.abilityEmpty:SetText(viewed and viewed.rarity>=3 and "Specials not shared" or "Rare quality or higher")
  w.name:SetText(viewed and (P.rarities[viewed.rarity].." "..P.PetName(viewed)) or "Your adventure begins")
  local canRetire=viewed and viewed.id and not tower and not social
  w.retire.petID=canRetire and viewed.id or false;w.retire:SetShown(not not canRetire)
  w.retire:SetEnabled(not s.battle and not (canRetire and viewed.retirementLocked));w.name:SetWidth(canRetire and 128 or 240)
  w.retirementLock:SetShown(not not canRetire)
  w.retirementLock.pieces[2]:SetShown(canRetire and viewed.retirementLocked or false)
  w.retirementLock:SetAlpha(canRetire and viewed.retirementLocked and 1 or .65)
  S.TextColor(w.name,viewed and P.colors[viewed.rarity] or S.gold)
  if viewed then
    local hp,attack,armor,speed=P.Stats(viewed)
    local ability=P.Ability(viewed)
    local battle=tower and s.battle
    if battle then hp,attack,armor,speed=battle.maxHP,battle.attack,battle.armor,battle.speed end
    local effectiveSpeed=battle and battle.effects.slow and speed*0.65 or speed
    local target=tower and (battle and battle.enemy or P.Enemy(P.floor or 1))
    local hit=math.min(99,P.HitChance(effectiveSpeed,target and target.speed or effectiveSpeed)+(not social and P.GearEffects and P.GearEffects(viewed).precision and 2 or 0))
    local function number(n)return string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")end
    local values={hp,number(attack),armor.."%",string.format("%.1f",speed),hit.."%",(100-hit).."%",social and "Shared" or P.XPText(viewed)}
    for i,value in ipairs(values)do
      w.statRows[i]:SetText(value)
      if P.SetStatRollLabel then
        P.SetStatRollLabel(w.statLabels[i],viewed,i)
        P.SetStatRollLabel(w.statRows[i],viewed,i,S.gold)
      end
      P.SetStatRollBar(w.statHighlights[i],viewed,i)
    end
    local breakdown=battle and battle.statBreakdown or P.StatBreakdown(viewed)
    for i,row in ipairs(breakdown)do
      w.statParts[i]:SetText(social and "Details not shared" or (number(row.base).." + |cff33ff66"..number(row.gear).."|r + |cff55aaff"..number(row.talent).."|r"))
    end
    w.effects:SetText(P.StatusText(battle):gsub(" / ","\n"))
    w.meta:SetText((social and "Shared" or viewed.deadAt and "Memorial" or viewed.id==s.active and "EQUIPPED" or "Preview").." | Level "..viewed.level.."\n"..P.SpecialtyLabel(viewed).."\n"..P.AbilityText(viewed,"\n"))
  else
    w.meta:SetText("Adopt a Warcraft companion.\n"..(P.RosterCount and P.RosterCount() or #P.species).." species to discover.")
    for i,value in ipairs(w.statRows)do
      value:SetText("-")
      if P.SetStatRollLabel then P.SetStatRollLabel(w.statLabels[i],nil,i);P.SetStatRollLabel(value,nil,i,S.gold)end
      P.SetStatRollBar(w.statHighlights[i],nil,i)
    end
    for _,value in ipairs(w.statParts)do value:SetText("")end;w.effects:SetText("No companion")
  end
  fill(w.health,pet and pet.health or 0,"Health "..math.floor(pet and pet.health or 0).." / 100")
  fill(w.food,pet and pet.food or 0,"Food "..math.floor(pet and pet.food or 0).." / 100")
  fill(w.energy,pet and pet.energy or 0,"Energy "..math.floor(pet and P.EnergyPoints(pet) or 0).." / "..P.MaxEnergy())
  for _,b in ipairs({w.health,w.food,w.energy})do b:SetShown(not tower and not social and viewed==pet)end
  for _,b in ipairs(w.care)do shown(b,not tower and not social and viewed==pet and pet~=nil)end
  for _,b in ipairs(w.fight)do shown(b,tower)end
  local ready,_,summary=P.BattleReadiness(P.floor or 1)
  w.readiness:SetShown(tower);w.readiness:SetText(summary);S.TextColor(w.readiness,ready and {0.4,1,0.4} or S.gold)
  w.fight[1]:SetEnabled(not s.battle and pet~=nil and not (P.VictoryPending and P.VictoryPending()));w.fight[2].label:SetText(s.battle and s.battle.paused and "Resume" or "Pause")
  w.fight[1].label:SetText(P.VictoryPending and P.VictoryPending() and "Wait" or P.FloorStatus(P.floor)=="Completed" and "Replay" or "Fight")
  w.fight[2]:SetEnabled(s.battle~=nil);w.fight[3]:SetEnabled(s.battle~=nil and P.HealChoice()~=nil)
  w.fight[3].label:SetText("Heal")
  w.care[2].label:SetText(pet and pet.resting and "Wake" or "Rest")
  w.collection:SetShown(not tower and not social);w.tower:SetShown(tower);w.social:SetShown(social)
  if not tower and not social then
    w.collection.equip:SetEnabled(viewed~=nil and not viewed.deadAt and viewed.id~=s.active and not s.battle)
    w.collection.equip:SetText(viewed and viewed.id==s.active and "Equipped" or "Equip")
    local pets,pages=P.GetStableLayout();P.page=math.max(1,math.min(P.page,pages))
    w.collection.page:SetText(P.StableCount().." / "..P.stableCapacity.." pets"..(pages>1 and (" | "..P.page.."/"..pages) or ""))
    w.collection.prev:SetShown(pages>1);w.collection.next:SetShown(pages>1)
    for i,row in ipairs(w.collection.rows)do
      row.stableSlot=(P.page-1)*P.stableCapacity+i
      local item=pets[row.stableSlot];row.petID=item and item.id;row.pet=item;row:SetShown(i<=P.stableCapacity)
      local cols=P.stableCapacity>9 and 4 or 3;local dx,dy=228/cols,198/cols
      row:ClearAllPoints();row:SetPoint("TOPLEFT",16+((i-1)%cols)*dx,-8-math.floor((i-1)/cols)*dy);row:SetSize(dx-10,dy-4)
      row.art:SetSize(dy-12,dy-12);row.info:ClearAllPoints();row.info:SetPoint("BOTTOMLEFT",2,0);row.info:SetWidth(dx-14)
      row.art:SetShown(item~=nil);row.selected:SetShown(item~=nil and item==viewed)
      if item then
        P.ShowPetPortrait(row.art,item);row.art:SetDesaturated(item.deadAt~=nil)
        row.info:SetText((item.id==s.active and "* " or item.isNew and "+ " or "")..(P.stableCapacity>9 and "" or "Lv ")..item.level)
        S.TextColor(row.info,P.colors[item.rarity]);row:SetBackdropBorderColor(unpack(P.colors[item.rarity]))
      else row.info:SetText("");row:SetBackdropBorderColor(0.2,0.2,0.2,1)end
    end
  elseif tower then
    local b=s.battle;local floor=b and b.enemy.floor or P.floor;local e=b and b.enemy or P.Enemy(floor)
    w.tower.info:SetText((floor%10==0 and "ELITE CHAMBER" or "THE NEXT CHALLENGE").."\n"..P.species[e.species].." | "..e.maxHP.." HP\nCombat level "..e.combatLevel.." | "..(e.spell and P.enemySpells[e.spell].name or "No spells").."\n"..P.FloorStatus(floor).." | Best: "..(pet and pet.best or 0))
    w.tower.floor:SetText("Floor "..floor.." / 100")
    w.tower.style:SetText("Style: "..P.styles[pet and pet.style or 1].name);w.tower.style:SetEnabled(pet~=nil and not b)
  end
  w.gearPreview:SetShown(not tower and not social)
  for _,slot in ipairs(w.gearPreview.slots)do
    local item=viewed and viewed.gear and P.GearItem(viewed.gear[slot.slot]);slot.item=item
    slot.art:SetTexture("Interface\\Icons\\"..(item and P.gearTypes[item.kind].icon or P.gearSlotIcons[slot.slot]))
    slot.art:SetDesaturated(not item);slot.status:SetText(item and "Equipped" or "Empty")
    S.TextColor(slot.status,item and P.colors[item.rarity] or S.muted)
  end
  w.notice:SetText(P.notice or "Care for a companion. Explore together. Face the tower when ready.")
  w.stock.refresh()
end
