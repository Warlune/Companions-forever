local _,F=...
local P,S=F.Pets,F.Style
local sizes={{0.5,"50%"},{0.65,"65%"},{0.75,"75%"},{0.85,"85%"},{1,"100% (default)"},{1.15,"115%"},{1.3,"130%"},{1.5,"150%"}}
local fonts={{0,"Default"},{12,"12 point"},{13,"13 point"},{14,"14 point"},{16,"16 point"}}
local function finite(n)return type(n)=="number" and n==n and math.abs(n)<100000 end
local function dragTime()return GetTime and GetTime() or F.Now()end
function F.PlaceMinimap()
  local button=F.minimapButton;if not button or not Minimap then return end
  local angle=finite(F.char.minimapAngle) and F.char.minimapAngle or 225
  local radians=math.rad(angle)
  local x,y=math.cos(radians),math.sin(radians)
  if GetMinimapShape and GetMinimapShape()~="ROUND" then
    local edge=math.max(math.abs(x),math.abs(y));x=x/edge;y=y/edge
  end
  local scale=(Minimap:GetEffectiveScale() or 1)/(button:GetEffectiveScale() or 1)
  button:ClearAllPoints()
  button:SetPoint("CENTER",Minimap,"CENTER",x*(Minimap:GetWidth()/2+8)*scale,y*(Minimap:GetHeight()/2+8)*scale)
end
function F.PlacePetIcon()
  local w=F.petIcon;if not w then return end
  local p=F.char.petIconPosition;w:ClearAllPoints()
  local scale=(w:GetEffectiveScale() or 1)/(UIParent:GetEffectiveScale() or 1)
  if type(p)=="table" and finite(p.x) and finite(p.y) then
    w:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",p.x/scale,p.y/scale)
  else w:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-80/scale,-270/scale)end
end
function F.TogglePetIcon(show)
  if show==nil then show=F.char.petIconHidden end
  F.char.petIconHidden=not show;F.char.petIconManuallyHidden=not show;F.RenderPetIcon()
end
function F.LayoutPetIcon()
  local w=F.petIcon;if not w then return end
  local font=math.max(11,S.MinimumTextSize());local width=math.max(108,font*8.5)
  local row=font+5;local artHeight=math.max(82,row*4)
  w:SetSize(width+8,artHeight+row*4+12);w.button:SetSize(width,artHeight)
  local scale=F.AccessibleScale(F.db.settings.miniScale,width+8,artHeight+row*4+12)
  if rawget(w,"cfMiniScale")~=scale then
    w.cfMiniScale=scale;w:SetScale(scale);F.PlacePetIcon()
  end
  w.rarity:Hide() -- The border and hover details already identify rarity.
  w.level:ClearAllPoints();w.level:SetPoint("TOPLEFT",4,-4-artHeight);w.level:SetSize(width,row)
  w.xp:ClearAllPoints();w.xp:SetPoint("TOPLEFT",4,-4-artHeight-row);w.xp:SetSize(width,row)
  w.xpText:ClearAllPoints();w.xpText:SetPoint("CENTER");w.xpText:SetSize(width,row)
  w.energy:ClearAllPoints();w.energy:SetPoint("TOPLEFT",4,-6-artHeight-row*2);w.energy:SetSize(width,row)
  w.energyText:ClearAllPoints();w.energyText:SetPoint("CENTER");w.energyText:SetSize(width,row)
  w.tokens:ClearAllPoints();w.tokens:SetPoint("TOPLEFT",4,-8-artHeight-row*3)
  w.tokens:SetSize(width*(w.tokenGainAmount and w.tokenGainAmount>0 and 0.6 or 1),row)
  w.tokenGain:ClearAllPoints();w.tokenGain:SetPoint("TOPRIGHT",-4,-8-artHeight-row*3);w.tokenGain:SetSize(width*0.4,row)
  w.tokenWidth=width;w.tokenRow=row
  w.gain:SetSize(width,row*2)
  w.needsHUD.width=width;w.needsHUD.height=artHeight
  w.hide:ClearAllPoints();w.hide:SetPoint("TOPRIGHT",0,0)
  local loot=P.rewardFrame
  if loot then
    loot:SetAllPoints(w.button)
    local iconSize=math.max(32,math.min(52,artHeight-row*2-8))
    loot.art:ClearAllPoints();loot.art:SetPoint("TOP",0,-4);loot.art:SetSize(iconSize,iconSize)
    loot.title:ClearAllPoints();loot.title:SetPoint("BOTTOMLEFT",0,row);loot.title:SetSize(width,row)
    loot.rarity:ClearAllPoints();loot.rarity:SetPoint("BOTTOMLEFT",0,0);loot.rarity:SetSize(width,row)
  end
end
function F.RenderPetIcon()
  if P.window and rawget(P.window,"miniToggle")then
    P.window.miniToggle:SetText(F.char.petIconHidden and "Mini: off" or "Mini: on")
  end
  local w=F.petIcon;if not w or not P.state then return end
  F.LayoutPetIcon()
  local pet=P.DisplayPet()
  w:SetShown(not F.char.petIconHidden)
  P.ShowPetArt(w.art,pet)
  if P.CreatePortraitFrame and F.Achievements then
    if not rawget(w,"portraitBorder")then
      w.portraitBorder=P.CreatePortraitFrame(w.button,w.art)
      w.portraitBorder:SetFrameLevel(w.button:GetFrameLevel()+3)
    end
    P.UpdatePortraitFrame(w.portraitBorder,F.Achievements.Frame());w.portraitBorder:SetShown(pet~=nil and F.db.settings.showMiniPortraitFrame~=false)
  end
  local color=pet and P.colors[pet.rarity] or S.muted
  w:SetBackdropBorderColor(unpack(color))
  w.rarity:SetText(pet and P.rarities[pet.rarity] or "")
  S.TextColor(w.rarity,color);S.TextColor(w.level,color)
  w.empty:SetShown(not pet)
  w.level:SetText(pet and (pet.resting and P.RestText(pet):gsub(" remaining",""):gsub("Rest paused: feed your pet","Feed to rest") or "Lv "..pet.level) or "Adopt")
  local capped=pet and pet.level>=P.LevelCap()
  w.xp:SetValue(pet and (capped and 1 or pet.xp/(20+pet.level*5)) or 0)
  w.xpText:SetText(pet and (capped and "MAX" or pet.xp.."/"..(20+pet.level*5).." XP") or "")
  w.energy:SetValue(pet and pet.energy or 0)
  w.energyText:SetText(pet and (math.floor(P.EnergyPoints(pet)).."/"..P.MaxEnergy().." Energy") or "Energy")
  F.UpdatePetIconProgress()
  if #P.rewards>0 and P.StartRewards then P.StartRewards()end
end
local function miniAmount(value)
  if value>=1000000 then return string.format("%.1fm",value/1000000)end
  if value>=10000 then return string.format("%.1fk",value/1000)end
  return string.format("%.0f",value)
end
function F.UpdatePetIconProgress(_,dt)
  local w=F.petIcon;if not w or not P.state then return end
  local amount,gain,alpha=P.ResourceDisplay("tokens",not F.db.settings.reduceMotion)
  if w.tokenAmount~=amount then w.tokenAmount=amount;w.tokens:SetText("|T"..P.tokenIcon..":16:16|t "..miniAmount(amount))end
  if w.tokenGainAmount~=gain then
    w.tokenGainAmount=gain;w.tokenGain:SetText(gain>0 and ("+"..miniAmount(gain)) or "")
    w.tokens:SetWidth(w.tokenWidth*(gain>0 and 0.6 or 1))
  end
  if w.tokenGainAlpha~=alpha then w.tokenGainAlpha=alpha;w.tokenGain:SetAlpha(alpha)end
  local pet=P.DisplayPet();local event=P.ProgressEvent(pet)
  local age=event and dragTime()-event.at or 99
  local active=w:IsShown() and event and age>=0 and age<4
  local ding=active and event.level>event.fromLevel
  local motion=not F.db.settings.reduceMotion
  w.needsHUD.needsPet=pet or false;P.UpdateNeeds(w.needsHUD,dragTime(),motion)
  local arena=rawget(w.art,"modelView")
  if arena then
    local battle=P.state.battle;local round=battle and P.lastRound
    local _,snapshot=P.VisualEvent(round,P.sceneClock or 0)
    if arena.StatusEffects then arena:StatusEffects(snapshot and snapshot.effects or (battle and battle.effects),motion)end
    if not ding or not motion or w.effectPetID~=pet.id then
      if arena.levelEffect then arena.levelEffect:Hide()end
      arena.levelEffectAge=nil
    else arena:UpdateLevelEffect(dt or 0)end
    if ding and motion and w.levelSerial~=(event.dingSerial or event.serial) and arena:Ready() then
      if arena:LevelUp()then w.levelSerial=event.dingSerial or event.serial;w.effectPetID=pet.id end
    end
  end
  if ding and not event.sound then
    event.sound=true
    if PlaySoundFile then pcall(PlaySoundFile,567431,"SFX")end
  end
  w.gain:SetShown(not not active)
  if active then
    w.gain:SetText(event.preview and "LEVEL UP!\nPreview" or ((ding and "LEVEL UP!\n" or "").."+"..event.amount.." XP"))
    w.gain:SetAlpha(F.db.settings.reduceMotion and 1 or math.min(1,(4-age)/0.5))
  end
end
local function buildPetIcon()
  local w=S.Panel(UIParent,0,0,76,121);F.petIcon=w
  _G.CompanionsForeverPetWindow=w
  -- Only the explicit mini toggle/hide button persists a hidden state.
  -- Loading screens and UIParent hides must not change that preference.
  S.RegisterWindow(w,1);w:SetClampedToScreen(true);w:SetMovable(true)
  F.PlacePetIcon()
  local b=CreateFrame("Button",nil,w);w.button=b;b:SetPoint("TOPLEFT",4,-4);b:SetSize(68,64)
  b:RegisterForDrag("LeftButton");b:RegisterForClicks("LeftButtonUp","RightButtonUp")
  b:SetScript("OnDragStart",function()w:StartMoving()end)
  b:SetScript("OnDragStop",function()
    w:StopMovingOrSizing();b.draggedUntil=dragTime()+0.2
    local scale=w:GetEffectiveScale()/UIParent:GetEffectiveScale()
    F.char.petIconPosition={x=w:GetRight()*scale-UIParent:GetWidth(),y=w:GetTop()*scale-UIParent:GetHeight()}
  end)
  b:SetScript("OnClick",function(_,key)
    if b.draggedUntil and dragTime()<=b.draggedUntil then return end
    if key=="RightButton" then P.ToggleCompass()else P.TogglePreferred()end
  end)
  w.art=b:CreateTexture(nil,"ARTWORK");w.art:SetAllPoints()
  w.empty=b:CreateTexture(nil,"BACKGROUND");w.empty:SetAllPoints();w.empty:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming")
  w.rarity=S.Text(w,"",4,-68,68,"GameFontNormalSmall",S.gold);w.rarity:SetJustifyH("CENTER")
  w.level=S.Text(w,"",4,-81,68,"GameFontNormalSmall",S.gold);w.level:SetJustifyH("CENTER")
  w.xp=CreateFrame("StatusBar",nil,w);w.xp:SetPoint("TOPLEFT",4,-96);w.xp:SetSize(68,18)
  w.xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");w.xp:SetStatusBarColor(0.55,0.3,0.9);w.xp:SetMinMaxValues(0,1)
  local bg=w.xp:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.05,0.03,0.08,1)
  w.xpText=S.Text(w.xp,"",0,-3,68,"GameFontHighlightSmall",{1,1,1});w.xpText:SetJustifyH("CENTER")
  w.energy=CreateFrame("StatusBar",nil,w);w.energy:SetMinMaxValues(0,100)
  w.energy:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");w.energy:SetStatusBarColor(1,1,0)
  local energyBG=w.energy:CreateTexture(nil,"BACKGROUND");energyBG:SetAllPoints();energyBG:SetColorTexture(0.08,0.08,0.02,1)
  w.energyText=S.Text(w.energy,"",0,0,68,"GameFontHighlightSmall",{1,1,1});w.energyText:SetJustifyH("CENTER")
  w.energyText:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",11,"OUTLINE")
  w.tokens=S.Text(w,"",0,0,108,"GameFontHighlightSmall",S.gold);w.tokens:SetJustifyH("CENTER")
  w.tokenGain=S.Text(w,"",0,0,108,"GameFontHighlightSmall",{0.3,1,0.3});w.tokenGain:SetJustifyH("CENTER");w.tokens:SetWordWrap(false);w.tokenGain:SetWordWrap(false)
  w.tokenAmount=false;w.tokenGainAmount=false;w.tokenGainAlpha=false
  -- ModelScenes render above their parent's textures/font strings. Keep XP on
  -- its own HUD above the model and loot reveal, including the first pet found.
  w.progressHUD=CreateFrame("Frame",nil,b);w.progressHUD:SetAllPoints();w.progressHUD:SetFrameLevel(b:GetFrameLevel()+8);w.progressHUD:EnableMouse(false)
  w.gain=S.Text(w.progressHUD,"",0,-2,68,"GameFontNormalSmall",S.gold);w.gain:SetJustifyH("CENTER");w.gain:SetHeight(30)
  w.gain:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",12,"OUTLINE");w.gain:Hide()
  w.needsHUD=CreateFrame("Frame",nil,b);w.needsHUD:SetAllPoints()
  w.needsHUD:SetFrameLevel(b:GetFrameLevel()+2);w.needsHUD:EnableMouse(false)
  w.needsHUD.width=68;w.needsHUD.height=64;w.needsHUD.tower=false;P.BuildNeeds(w.needsHUD)
  for _,z in ipairs(w.needsHUD.needs.sleep)do z:EnableMouse(false)end
  w.needsHUD.needs.hungry:EnableMouse(false)
  w:SetScript("OnUpdate",F.UpdatePetIconProgress)
  local hide=S.Button(w,"-",56,0,20,function()F.TogglePetIcon(false)end);hide:SetHeight(18);hide:SetFrameLevel(w:GetFrameLevel()+10);w.hide=hide
  b:SetScript("OnEnter",function(self)
    local pet=P.DisplayPet();GameTooltip:SetOwner(self,"ANCHOR_LEFT")
    GameTooltip:SetText(pet and (P.rarities[pet.rarity].." "..P.PetName(pet)) or "Companions Forever",unpack(pet and P.colors[pet.rarity] or S.gold))
    if pet then
      GameTooltip:AddLine("Health "..math.floor(pet.health).."% | XP "..P.XPText(pet),1,1,1)
      if pet.resting then GameTooltip:AddLine(P.RestText(pet)..". At full energy, recover 1 HP every 5 seconds until healthy. Herbs heal immediately.",0.7,0.85,1,true)end
      if pet.food<25 then GameTooltip:AddLine("Hungry: feed food. Below 10 food, health and energy drain to 1.",1,0.3,0.3,true)end
    end
    GameTooltip:AddLine("Tokens: "..string.format("%.0f",P.state.tokens),1,0.82,0.3)
    if w.lastLoot then
      GameTooltip:AddLine("Last find: "..w.lastLoot.title,1,0.82,0.3,true)
      GameTooltip:AddLine(w.lastLoot.detail,1,1,1,true)
    end
    GameTooltip:AddLine("Drag to move. Left-click: open. Right-click: compact view.\nHide with -; restore with /cfpets pet or Settings.",1,1,1,true);GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  F.RenderPetIcon()
end
function F.AccessibleScale(requested,width,height)
  requested=tonumber(requested) or 1
  if requested~=requested then requested=1 end
  return math.max(0.1,math.min(math.max(0.5,math.min(1.5,requested)),(UIParent:GetWidth()-40)/width,(UIParent:GetHeight()-40)/height))
end
function F.PlaceDesktop()
  local window=F.compass;if not window then return end
  local p=F.char.petPosition
  window:ClearAllPoints()
  if type(p)=="table" and finite(p.x) and finite(p.y) then
    window:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",p.x,p.y)
  else window:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-40,-220)end
end
function F.BuildDesktop()
  if F.compass then return end
  local c=S.Panel(UIParent,0,0,300,400);F.compass=c
  _G.CompanionsForeverCompactWindow=c;UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverCompactWindow"
  c:SetScript("OnHide",function(self)
    if not F.char.navPets then return end -- Explicit close/toggle already saved.
    if self:IsShown() then return end -- Only the parent UI was hidden.
    local escape=IsKeyDown and IsKeyDown("ESCAPE")
    if escape==true then F.char.navPets=false;return end
    -- Taxi state may update after the client closes special windows.
    local function settle()
      if not F.char.navPets or self:IsShown() then return end
      local taxi=UnitOnTaxi and UnitOnTaxi("player")
      if issecretvalue and issecretvalue(taxi)then taxi=nil end
      if taxi==true then F.UpdateNavigator()else F.char.navPets=false end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.1,settle)else settle()end
  end)
  F.PlaceDesktop();S.RegisterWindow(c,2);c:SetClampedToScreen(true);c:SetMovable(true);c:EnableMouse(true);c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart",c.StartMoving)
  c:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing()
    local scale=self:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x=self:GetRight()*scale-UIParent:GetWidth()
    local y=self:GetTop()*scale-UIParent:GetHeight()
    F.char.petPosition={x=x,y=y}
  end)
  P.SettingsButton(c,238,-5)
  S.Text(c,"COMPANIONS FOREVER",12,-12,215,"GameFontNormalSmall",S.gold)
  local close=CreateFrame("Button",nil,c,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-1,-1)
  close:SetScript("OnClick",function()P.ToggleCompass(false)end)
  P.BuildCompass(c);P.mini:ClearAllPoints();P.mini:SetPoint("TOPLEFT",8,-34)
  -- Independent minimap launcher; no delivery addon is required.
  if Minimap then
    local button=CreateFrame("Button","CompanionsForeverMinimapButton",UIParent)
    F.minimapButton=button;button:SetSize(32,32);F.PlaceMinimap()
    button:SetFrameStrata("LOW");button:SetFrameLevel(Minimap:GetFrameLevel()+16)
    button:SetClampedToScreen(true);button:EnableMouse(true);button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart",function(self)
      GameTooltip:Hide()
      self:SetScript("OnUpdate",function()
        local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale()
        x=x/scale-cx;y=y/scale-cy
        local angle=x==0 and (y>=0 and 90 or -90) or math.deg(math.atan(y/x))
        if x<0 then angle=angle+180 end
        F.char.minimapAngle=angle%360;F.PlaceMinimap()
      end)
    end)
    button:SetScript("OnDragStop",function(self)self:SetScript("OnUpdate",nil);self.draggedUntil=dragTime()+0.2 end)
    local icon=button:CreateTexture(nil,"ARTWORK");icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming");icon:SetSize(21,21);icon:SetPoint("CENTER")
    local border=button:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");border:SetSize(54,54);border:SetPoint("TOPLEFT",-1,1)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:SetScript("OnClick",function(self,key)
      if self.draggedUntil and dragTime()<=self.draggedUntil then return end
      if key=="RightButton" then P.ToggleCompass()else P.Toggle()end
    end)
    button:SetScript("OnEnter",function(self)
      GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText(F.displayName)
      GameTooltip:AddLine("Left-click: camp and tower",1,1,1);GameTooltip:AddLine("Right-click: compact window",1,1,1)
      GameTooltip:AddLine("Drag around the minimap to move. /cfpets pet restores your pet icon.",1,1,1,true);GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  buildPetIcon()
  F.UpdateNavigator()
end
function F.UpdateNavigator()
  local c=F.compass;if not c then return end
  local height=442+(P.miniMode=="tower" and 190 or 60)
  c:SetHeight(height);c:SetScale(F.AccessibleScale(F.db.settings.compassScale,300,height))
  c:SetShown(not not F.char.navPets);P.mini:SetShown(not not F.char.navPets)
  P.RenderCompass()
end
function F.CloseCombatWindows()
  if not F.ready or not F.db or F.db.settings.closeInCombat~=true then return end
  -- These are addon windows only; leave the mini portrait and its preference alone.
  F.char.navPets=false
  if P.window then P.window:Hide()end
  if F.compass then F.compass:Hide()end
  if P.mini then P.mini:Hide()end
  F.settingsReturnCompact=nil;F.settingsReturnPage=nil
end
function F.ApplySettings()
  S.ApplyTheme();F.UpdateNavigator();P.Render()
  for key,control in pairs(F.dropdowns or {})do
    local label=control.options[1][2]
    for _,option in ipairs(control.options)do if F.db.settings[key]==option[1]then label=option[2]end end
    control.button:SetText(label.."  |TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:16:16|t")
  end
  if InCombatLockdown and InCombatLockdown()then F.CloseCombatWindows()end
end
function F.ToggleSettings()
  if P.window and P.window:IsShown() and P.mode=="settings"then
    if F.settingsReturnCompact then P.ToggleCompass(true)
    else P.OpenPage(F.settingsReturnPage or "collection")end
    F.settingsReturnCompact=nil;F.settingsReturnPage=nil;return
  end
  F.settingsReturnCompact=F.compass and F.compass:IsShown() or false
  F.settingsReturnPage=P.mode~="settings" and P.mode or "collection"
  F.OpenSettings()
end
function F.OpenSettings()
  if F.settings then P.OpenPage("settings");F.ApplySettings();return end
  local w=P.NewPage();F.settings=w
  if F.Errors then F.Errors.BuildSettings(w)end
  S.Text(w,"Companions Forever settings",20,-18,490,"GameFontNormalLarge",S.gold)
  local popup=CreateFrame("Frame","CompanionsForeverSizeMenu",w);popup:SetAllPoints(w);popup:SetFrameLevel(w:GetFrameLevel()+30);popup:EnableMouse(true)
  popup:SetScript("OnMouseDown",function(self)self:Hide()end)
  UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverSizeMenu"
  w:SetScript("OnHide",function()popup:Hide()end)
  local menu=S.Panel(popup,0,0,246,160);menu:EnableMouse(true);local choices={}
  w.sizeMenu=popup;w.sizeChoices=choices
  F.dropdowns={}
  local function dropdown(key,title,x,y,options)
    S.Text(w,title,x,y,246,"GameFontNormal",S.gold)
    local button=S.Button(w,"",x,y-25,246,function()
      if popup:IsShown() and popup.key==key then popup:Hide();return end
      popup.key=key;menu:ClearAllPoints();menu:SetPoint("TOPLEFT",F.dropdowns[key].button,"BOTTOMLEFT",0,-2);menu:SetHeight(#options*30+12)
      for i,option in ipairs(options)do
        if not choices[i] then choices[i]=S.Button(menu,"",6,-6-(i-1)*30,234,function()end)end
        local value=option[1];choices[i]:SetText(option[2]);choices[i]:Show()
        choices[i]:SetScript("OnClick",function()F.db.settings[key]=value;popup:Hide();F.ApplySettings()end)
      end
      for i=#options+1,#choices do choices[i]:Hide()end
      popup:Show()
    end)
    F.dropdowns[key]={button=button,options=options}
  end
  dropdown("ledgerScale","Large window",20,-62,sizes)
  dropdown("compassScale","Compact window",294,-62,sizes)
  dropdown("textSize","Minimum text size",20,-128,fonts)
  dropdown("miniScale","Mini window",294,-128,sizes)

  S.Check(w,"High contrast",18,-202,"highContrast")
  S.Check(w,"Reduced motion",18,-238,"reduceMotion")
  local function option(label,x,y,key)
    local b=S.Check(w,"",x,y,key)
    S.Text(b,label,32,-3,212,"GameFontHighlight"):SetHeight(38)
    return b
  end
  w.petRolls=option("Pet rolls in chat",18,-276,"petRollChat")
  S.Button(w,"Show pet icon",294,-202,246,function()F.TogglePetIcon(true)end)
  S.Button(w,"Reset icon positions",294,-240,246,function()
    F.char.petIconPosition=nil;F.char.minimapAngle=nil;F.PlacePetIcon();F.PlaceMinimap();F.TogglePetIcon(true)
  end)
  option("Party kill witnesses",18,-316,"partyWitnesses")
  option("Tower: HP above pets",294,-276,"towerPetHealthBars")
  option("Short pet tooltips",294,-316,"shortPetTooltips")
  option("Show pet roll ranges",18,-356,"showPetRollRanges")
  w.closeInCombat=option("Close in combat",18,-398,"closeInCombat")
  w.closeInCombat:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Close in combat")
    GameTooltip:AddLine("Closes large and compact windows when your character enters combat. The mini pet stays open.",1,1,1,true);GameTooltip:Show()
  end)
  w.closeInCombat:SetScript("OnLeave",function()GameTooltip:Hide()end)
  if F.HardModePresentation then F.HardModePresentation.Settings(w)end
  -- These sections share the right column, never the same visible space.
  local appearance=S.Button(w,"Appearance",566,-18,120,function()w.showSettingsSection("appearance")end)
  local chat=S.Button(w,"Chat",694,-18,120,function()w.showSettingsSection("chat")end)
  local reports=S.Button(w,"Error reports",822,-18,120,function()w.showSettingsSection("errors")end)
  local chatPanel=S.Panel(w,566,-54,376,484);w.chatPanel=chatPanel
  S.Text(chatPanel,"Drop announcements",16,-12,344,"GameFontNormalLarge",S.gold)
  local party=S.Check(chatPanel,"",12,-54,"announcePartyDrops")
  S.Text(party,"Announce drops in party chat",32,-3,300,"GameFontHighlight"):SetHeight(40)
  local guild=S.Check(chatPanel,"",12,-108,"receiveGuildDrops")
  S.Text(guild,"Receive CF guild messages",32,-3,300,"GameFontHighlight"):SetHeight(40)
  S.Text(chatPanel,"Only pets and gear are shared. Hover a gear name to see its stats. Guild notices appear quietly in CF messages.\n\nYour own reward messages still appear. Both players need an updated CF build.",16,-174,344,"GameFontHighlightSmall",S.muted):SetHeight(120)
  local delivery=S.Text(chatPanel,"",16,-312,344,"GameFontHighlightSmall",S.muted);delivery:SetHeight(112)
  local shareParty=S.Button(chatPanel,"Share party",16,-444,166,function()if F.DropAnnouncements then F.DropAnnouncements.Draft('PARTY')end end)
  local function refreshDelivery()
    local n=F.DropAnnouncements
    delivery:SetText(n and n.StatusText() or "")
    shareParty:SetEnabled(n and n.last and IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) or false)
  end
  chatPanel:SetScript("OnShow",refreshDelivery)
  local deliveryElapsed=0
  chatPanel:SetScript("OnUpdate",function(_,elapsed)
    deliveryElapsed=deliveryElapsed+(elapsed or 0)
    if deliveryElapsed>=1 then deliveryElapsed=0;refreshDelivery()end
  end)
  w.settingsSectionButtons={appearance=appearance,chat=chat,errors=reports}
  w.showSettingsSection=function(section)
    w.settingsSection=section
    if w.hardAppearancePanel then w.hardAppearancePanel:SetShown(section=="appearance")end
    if F.Errors and F.Errors.panel then F.Errors.panel:SetShown(section=="errors")end
    chatPanel:SetShown(section=="chat")
    appearance:SetEnabled(section~="appearance");chat:SetEnabled(section~="chat");reports:SetEnabled(section~="errors")
  end
  w.showSettingsSection("appearance")
  local notice=S.Text(w,"",294,-399,246,"GameFontHighlightSmall",S.gold);notice:SetHeight(48)
  local credits=S.Panel(w,20,-452,520,86)
  S.Text(credits,"Special Thanks",12,-10,496,"GameFontNormal",S.gold):SetHeight(26)
  S.Text(credits,"Sylie  /  Unda  /  Obijay  /  Shampanda",12,-42,496,"GameFontHighlight"):SetHeight(32)
  local import=S.Button(w,"Import old Waylaid pets",294,-356,246,function()
    if F.char.sharedGame then F.AccountSave.ShowNotice(true);return end
    popup:Hide()
    if F.char.legacyImportedAt then notice:SetText("Already imported. Your current progress has been kept.");return end
    if F.Pets.state.battle then notice:SetText("Finish your battle first.");return end
    local legacy=WaylaidForeverCharDB or ForeverWaylaidCharDB
    if not (type(legacy)=="table" and type(legacy.pets)=="table")then
      notice:SetText("Enable updated Waylaid Forever on this character and log in once, then try again.");return
    end
    F.confirmImport:Show()
  end)
  if F.char.sharedGame then import:SetText("About account sharing")end
  local confirm=S.Panel(w,20,-342,520,118);F.confirmImport=confirm;confirm:SetFrameLevel(w:GetFrameLevel()+35);confirm:EnableMouse(true)
  S.Text(confirm,"Replace your stable with old Waylaid pets?\nYour current stable will be saved as a backup.",12,-10,496,"GameFontHighlightSmall",S.gold)
  S.Button(confirm,"Import",12,-73,160,function()
    local _,message=F.ImportLegacy(true);confirm:Hide();notice:SetText(message);P.Render()
  end)
  S.Button(confirm,"Keep current",184,-73,160,function()confirm:Hide()end)
  confirm:Hide();popup:Hide();P.OpenPage("settings");F.ApplySettings()
end
