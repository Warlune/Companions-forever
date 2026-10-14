local _,F=...
local P,S=F.Pets,F.Style
local R={queue={}};P.RewardPresentation=R
local driver=CreateFrame("Frame");R.driver=driver;driver:Hide()
local OPEN_AT,OPENED_AT,FADE_AT,REVEAL_AT,END_AT=1.05,2.15,3.2,3.8,6.3
local DURATION_SCALE=.65 -- 35% shorter, including the native lid animation.
local chestEffects={
  {rays=1,sparks=0,height=.22,flash=.12,shake=.25},
  {rays=3,sparks=4,height=.32,flash=.22,shake=.4},
  {rays=5,sparks=24,height=.38,flash=.65,rings=2,shake=1,orbit=6},
  {rays=7,sparks=40,height=.38,flash=.85,rings=3,shake=1.9,orbit=10},
  {rays=9,sparks=56,height=.38,flash=1,rings=4,shake=2.8,orbit=14},
}
-- Native Classic spell assets (wowdev listfile): fireworks, arcane explosion,
-- shadow casting, holy nova and the level-up pillar. At most three actors.
local spellReveals={
  {},{{166166,0}},{{166165,0},{165576,.2}},
  {{166810,0},{165576,.15},{165578,.45}},
  {{166464,0},{166350,.2},{166170,.5}},
}
local revealSounds={nil,51402,51561,31578,63971}
local function soundOnce(opening,key,id)
  if opening[key]then return end
  opening[key]=true
  if id and PlaySound then pcall(PlaySound,id,"SFX")end
end
local function updateSpells(f,since,opacity,motion)
  if not f.modelReady then return end
  for i,entry in ipairs(f.spells)do
    local spec=f.spellProfile[i]
    local show=motion and spec and since>=spec[2] and opacity>0
    if show and not entry.started then
      entry.started=true
      local ok,accepted=pcall(entry.actor.SetModelByFileID,entry.actor,spec[1])
      entry.failed=not ok or accepted==false
    end
    if show and not entry.failed and entry.actor:IsLoaded() then
      if not entry.fitted then
        local ok,x,y,z,tx,ty,tz=pcall(entry.actor.GetMaxBoundingBox,entry.actor)
        if ok and (type(x)=="table" or type(x)=="userdata") and x.GetXYZ and y and y.GetXYZ then
          local lower,upper=x,y;x,y,z=lower:GetXYZ();tx,ty,tz=upper:GetXYZ()
        end
        local extent=type(x)=="number" and type(tx)=="number" and type(y)=="number" and type(ty)=="number" and type(z)=="number" and type(tz)=="number" and math.max(tx-x,ty-y,tz-z)
        entry.actor:SetScale(extent and extent>0 and math.max(.01,math.min(.35,1.9/extent)) or .15)
        -- Start the burst after asynchronous loading, so its first frames are visible.
        pcall(entry.actor.SetAnimation,entry.actor,0,0,1,0)
        entry.fitted=true
      end
      entry.actor:SetAlpha(opacity*.85);entry.actor:Show()
    else entry.actor:Hide()end
  end
end
local originalReward=P.Reward
local function notify(opening)
  if not opening or opening.notified then return end
  opening.notified=true
  for _,entry in ipairs(opening.notifications or {})do
    originalReward(unpack(entry.args,1,entry.n))
  end
end
function P.Reward(kind,title,detail,icon,species,rarity,...)
  local item={kind=kind,title=title,detail=detail,icon=icon,species=species,rarity=rarity or 1,rolls=select(3,...),furnishings=select(4,...)}
  if R.tower and (kind=="item" or kind=="crate_found")then R.tower[#R.tower+1]=item end
  if R.opening then
    if kind=="crate"then R.opening.title=title;return end
    if kind=="item" or kind=="pet"then
      R.opening.result=item
      local notices=R.opening.notifications;notices[#notices+1]={args={kind,title,detail,icon,species,rarity,...},n=6+select("#",...)}
      return
    end
  end
  return originalReward(kind,title,detail,icon,species,rarity,...)
end
local loot=P.TowerLoot
function P.TowerLoot(b,...)
  b.presentationLoot={};local prior=R.tower;R.tower=b.presentationLoot
  local ok,result=pcall(loot,b,...);R.tower=prior
  if not ok then error(result)end
  return result
end
function P.TowerRewardRows(v)
  local rows={}
  local function add(n,label,icon)if n and n>0 then rows[#rows+1]={text="+"..n.." "..label,icon=icon,color=S.gold}end end
  add(v.tokens,"tokens","INV_Misc_Coin_01");add(v.treats,"food","INV_Misc_Food_14");add(v.herbs,"herb","INV_Misc_Herb_01")
  for _,item in ipairs(v.loot or {})do rows[#rows+1]={text=(item.detail or item.title or "Reward"):match("^[^\n]+"),icon=item.icon,color=P.colors[item.rarity] or S.gold}end
  return rows
end
function P.AdvanceVictory()
  local v=P.CurrentVictory();if not v or v.advanced or (P.sceneClock or 0)<v.readyAt+3.6 then return false end
  v.advanced=true
  if v.floor>=100 then return false end -- Never enter Hard Mode automatically.
  P.floor=math.min(v.floor+1,P.Unlocked());P.lastRound=nil;P.victory=nil
  if P.Render then P.Render()end
  return true
end
function P.VictoryPending()
  local v=P.CurrentVictory()
  return v~=nil and not v.advanced
end
local readiness=P.BattleReadiness
function P.BattleReadiness(...)
  if P.VictoryPending()then return false,"Finishing this floor. Wait for rewards and automatic progression.","Finishing floor..."end
  return readiness(...)
end
local startBattle=P.StartBattle
function P.StartBattle(...)
  if P.VictoryPending()then return false,"Wait for the tower to finish advancing."end
  return startBattle(...)
end
function P.UpdateTowerRewards(f)
  local v=f.tower and P.CurrentVictory();local age=v and (P.sceneClock or 0)-v.readyAt
  if not age or age<0 or age>=3.6 then
    if rawget(f,"rewardRows")then for _,row in ipairs(f.rewardRows)do row:Hide()end end;return
  end
  if not rawget(f,"rewardRows")then
    f.rewardLayer=CreateFrame("Frame",nil,f);f.rewardLayer:SetAllPoints();f.rewardLayer:EnableMouse(false)
    f.rewardLayer:SetFrameLevel(f.hud:GetFrameLevel()+30)
    f.rewardRows={}
  end
  if f.rewardReceipt~=v then
    local rows=P.TowerRewardRows(v)
    for i=#f.rewardRows+1,#rows do
      local row=CreateFrame("Frame",nil,f.rewardLayer);f.rewardRows[i]=row;row:SetSize(f.width-28,38);row:EnableMouse(false)
      row.readableBackdrop=row:CreateTexture(nil,"BACKGROUND");row.readableBackdrop:SetAllPoints();row.readableBackdrop:SetColorTexture(.015,.015,.015,1);row.readableBackdrop:Hide()
      row.icon=row:CreateTexture(nil,"OVERLAY");row.icon:SetSize(22,22);row.icon:SetPoint("LEFT",0,0)
      row.label=row:CreateFontString(nil,"OVERLAY");row.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",f.width>300 and 16 or 12,"OUTLINE")
      row.label:SetPoint("LEFT",row.icon,"RIGHT",6,0);row.label:SetPoint("RIGHT");row.label:SetHeight(38);row.label:SetJustifyH("LEFT");row.label:SetMaxLines(2)
    end
    f.rewardReceipt=v;f.rewardCount=#rows
    for i,row in ipairs(f.rewardRows)do local item=rows[i];row.used=not not item
      if item then row.rewardText=item.text;row.rewardColor=item.color;row.icon:SetTexture("Interface\\Icons\\"..item.icon)end
    end
  end
  local high=S.HighContrast();local motion=not F.db.settings.reduceMotion
  local font=math.max(f.width>300 and 16 or 12,S.MinimumTextSize())
  local spacing=math.max(40,font*2+12)
  local total=math.max(1,f.rewardCount)*spacing
  -- A separate high layer prevents health bars and combat text cutting through
  -- receipts. Fit all rows inside even the compact battle scene.
  f.rewardLayer:SetFrameLevel(f.hud:GetFrameLevel()+30)
  f.rewardLayer:SetScale(math.min(1,(f.height-20)/total))
  for i,row in ipairs(f.rewardRows)do
    row.readableBackdrop:SetShown(high)
    row:SetSize(f.width-28,spacing-4)
    row.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",font,"OUTLINE")
    row.label:SetHeight(spacing-8)
    if row.used then
      local value=row.rewardText
      row.label:SetText(high and value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","") or value)
      S.RarityText(row.label,row.rewardColor)
    end
    row:SetShown(row.used);row:SetAlpha(motion and math.min(1,age/.2,(3.6-age)/.5) or 1)
    row:ClearAllPoints();row:SetPoint("CENTER",f.rewardLayer,"CENTER",0,(f.rewardCount-1)*spacing/2-(i-1)*spacing+(motion and age*7 or 0))
  end
end
-- Presentation observes successful transactions. It never rolls or grants loot.
for _,name in ipairs({"Adopt","Rescue","BuyEquipmentBox","OpenBagCrate"})do
  local original=P[name]
  P[name]=function(...)
    if R.opening then return original(...)end
    if name=="OpenBagCrate"then local item=P.CrateItem(...);if item and (P.coinPouches[item.crate] or (P.xpTreats and P.xpTreats[item.crate]))then return original(...)end end
    local index=(name=="Adopt" or name=="BuyEquipmentBox") and select(1,...) or 1
    if name=="OpenBagCrate"then
      local item=P.CrateItem(...);local equipment=item and P.equipmentCrates[item.crate]
      index=equipment and equipment.box or item and item.crate or 1
    end
    local bagItem=name=="OpenBagCrate" and P.CrateItem(...)
    local containerRarity=bagItem and P.CrateRarity(bagItem.crate) or (name=="Rescue" and 1 or P.ContainerRarity(index))
    local opening={title="Opening crate",notifications={},container=P.CrateModel(index),containerRarity=containerRarity};R.opening=opening
    local called,ok,result=pcall(original,...);R.opening=nil
    if not called then notify(opening);error(ok)end
    if ok and opening.result then
      -- Public party/guild chat needs the opening action's client context.
      -- Local reward text still waits for the visual reveal in notify().
      if P.AnnounceChestReward then
        for _,entry in ipairs(opening.notifications)do P.AnnounceChestReward(unpack(entry.args,1,entry.n))end
      end
      if #R.queue>=12 then notify(table.remove(R.queue,1))end
      R.queue[#R.queue+1]=opening
      driver:Show()
    else notify(opening)end
    return ok,result
  end
end
local function owner()
  if P.window and P.window:IsShown()then return P.window,"large"end
  if F.compass and F.compass:IsShown()then return F.compass,"compact"end
  if F.petIcon and F.petIcon:IsShown()then return F.petIcon,"mini"end
end
local function loadedChest(f)
  local actor=f.actor
  if f.loaded or not actor or not actor:IsLoaded()then return end
  local ok,x,y,z,tx,ty,tz=pcall(actor.GetMaxBoundingBox,actor)
  if ok and (type(x)=="table" or type(x)=="userdata") and x.GetXYZ and y and y.GetXYZ then
    local lower,upper=x,y;x,y,z=lower:GetXYZ();tx,ty,tz=upper:GetXYZ()
  end
  if type(x)~="number" or type(y)~="number" or type(z)~="number" or type(tx)~="number" or type(ty)~="number" or type(tz)~="number"then return end
  local extent=math.max(tx-x,ty-y,tz-z)
  if extent<=0 or extent~=extent then return end
  -- World objects have very different native sizes; fit the complete lid too.
  f.fittedScale=math.max(.001,math.min(10,1.6/extent))
  actor:SetUseCenterForOrigin(true,true,true);actor:SetScale(f.fittedScale)
  actor:SetPosition(0,0,0);actor:SetYaw(math.pi*1.25);actor:SetAlpha(1);actor:Show()
  f.loaded=true;f.sequence=147;actor:SetAnimation(f.container.animatedLid and 147 or 0,0,1,0)
end
local function requestChest(f,usePath)
  f.loaded=false;f.sequence=nil
  local fn=not usePath and f.actor.SetModelByFileID or f.actor.SetModelByPath
  local asset=usePath and f.container.path or f.container.id
  local ok,accepted=pcall(fn,f.actor,asset)
  f.modelError=not ok and tostring(accepted) or accepted==false and "Chest asset rejected" or nil
  if ok and accepted~=false then loadedChest(f)end
  return ok and accepted~=false
end
local function build(parent)
  local f=CreateFrame("Frame",nil,parent,"BackdropTemplate");R.frame=f;f:EnableMouse(false)
  f:SetClipsChildren(true)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16});f:SetBackdropColor(.025,.02,.035,.94)
  f.hud=CreateFrame("Frame",nil,f);f.hud:SetAllPoints();f.hud:EnableMouse(false)
  f.hud:SetClipsChildren(true)
  f.rewardViewport=CreateFrame("Frame",nil,f);f.rewardViewport:EnableMouse(false);f.rewardViewport:SetClipsChildren(true)
  f.petView=P.CreateArena(f.rewardViewport,true)
  -- Native spell textures, projected from the chest mouth rather than a border halo.
  f.glow=f.hud:CreateTexture(nil,"ARTWORK");f.glow:SetTexture(166223);f.glow:SetBlendMode("ADD")
  f.rarityGlow=f.hud:CreateTexture(nil,"ARTWORK");f.rarityGlow:SetTexture(166223);f.rarityGlow:SetBlendMode("ADD");f.rarityGlow:SetAlpha(0)
  f.rays={}
  for i=1,9 do
    local ray=f.hud:CreateTexture(nil,"ARTWORK");ray:SetTexture(166223);ray:SetBlendMode("ADD");f.rays[i]=ray
  end
  f.particles={};f.rings={}
  for i=1,56 do local t=f.hud:CreateTexture(nil,"ARTWORK");t:SetTexture(166961);t:SetBlendMode("ADD");f.particles[i]=t end
  for i=1,4 do local t=f.hud:CreateTexture(nil,"ARTWORK");t:SetTexture(165963);t:SetBlendMode("ADD");f.rings[i]=t end
  f.flash=f.hud:CreateTexture(nil,"ARTWORK");f.flash:SetTexture(166223);f.flash:SetBlendMode("ADD")
  f.spark=f.hud:CreateTexture(nil,"ARTWORK");f.spark:SetTexture(166961);f.spark:SetBlendMode("ADD")
  f.fallback=f:CreateTexture(nil,"ARTWORK");f.fallback:SetTexture("Interface\\Icons\\INV_Box_01");f.fallback:SetPoint("CENTER",0,5)
  f.art=f.hud:CreateTexture(nil,"OVERLAY");f.art:SetPoint("CENTER",0,20)
  f.label=f.hud:CreateFontString(nil,"OVERLAY");f.label:SetPoint("BOTTOMLEFT",8,10);f.label:SetPoint("BOTTOMRIGHT",-8,10);f.label:SetJustifyH("CENTER");f.label:SetMaxLines(3)
  f.loaded=false;f.sequence=147;f.pathTried=false;f.spells={};f.container=P.CrateModel(nil)
  local ok,err=pcall(function()
    local scene=CreateFrame("ModelScene",nil,f);f.scene=scene;scene:SetAllPoints();scene:EnableMouse(false)
    scene:SetCameraNearClip(.1);scene:SetCameraFarClip(100);scene:SetCameraFieldOfView(math.rad(36))
    scene:SetCameraPosition(0,-4.6,2.2);scene:SetCameraOrientationByAxisVectors(0,.902134,-.431456,-1,0,0,0,.431456,.902134)
    scene:SetLightVisible(true);scene:SetLightAmbientColor(.8,.8,.8);scene:SetLightDiffuseColor(1,.95,.85);scene:SetLightDirection(-.4,1,-1)
    local actor=scene:CreateActor("CompanionsForeverLootChest","CompanionsForeverActorTemplate");f.actor=actor
    actor.cfArena={ModelLoaded=function()loadedChest(f)end}
    actor:SetUseCenterForOrigin(true,true,true);actor:SetPosition(0,0,0);actor:SetScale(.5);actor:SetYaw(math.pi*1.25);actor:Show()
    -- WoW listfile 219372: world/skillactivated/containers/treasurechest01.m2.
    -- Client game-object animations: Closed 147, Open 148, Opened 149.
    if not requestChest(f,false)then requestChest(f,true);f.pathTried=true end
    for i=1,3 do
      local spell=scene:CreateActor("CompanionsForeverChestSpell"..i,"CompanionsForeverActorTemplate")
      spell:SetUseCenterForOrigin(true,true,true);spell:SetPosition(0,0,0);spell:Hide()
      f.spells[i]={actor=spell}
    end
  end)
  f.modelReady=ok;if not ok then f.modelError=tostring(err);if rawget(f,"scene")then f.scene:Hide()end end
  f:Hide();return f
end
local function prepareFurniture(f,item)
  f.furnitureViews=rawget(f,"furnitureViews") or {}
  local island=F.Housing and F.Housing.Island
  local entries=item.furnishings or {}
  for _,view in ipairs(f.furnitureViews)do view.host:Hide();view.active=false end
  for index=1,math.min(2,#entries)do
    local entry=entries[index];local decor=island and island.decorByKey[entry.key]
    if decor and decor.asset then
      local view=f.furnitureViews[index]
      if not view then
        view={};f.furnitureViews[index]=view
        view.host=CreateFrame("Frame",nil,f.rewardViewport);view.host:EnableMouse(false)
        view.icon=view.host:CreateTexture(nil,"OVERLAY");view.icon:SetPoint("CENTER");view.icon:SetSize(48,48);view.icon:SetTexture("Interface\\Icons\\INV_Crate_01")
        local ok=pcall(function()
          view.scene=CreateFrame("ModelScene",nil,view.host);view.scene:SetAllPoints();view.scene:EnableMouse(false)
          view.scene:SetCameraNearClip(.01);view.scene:SetCameraFarClip(10000);view.scene:SetCameraFieldOfView(math.rad(36))
          view.scene:SetLightVisible(true);view.scene:SetLightAmbientColor(.8,.8,.8);view.scene:SetLightDiffuseColor(1,.95,.85);view.scene:SetLightDirection(-.4,1,-1)
          view.actor=view.scene:CreateActor();view.actor:SetUseCenterForOrigin(true,true,true);view.actor:SetPosition(0,0,0);view.actor:SetYaw(-.6)
        end)
        if not ok then view.failed=true end
      end
      view.active=true;view.ready=false;view.age=0;view.asset=decor.asset;view.pathTried=false
      view.host:ClearAllPoints()
      view.host:SetPoint("TOPLEFT",f.rewardViewport,"TOPLEFT",0,0)
      view.host:SetPoint("BOTTOMRIGHT",f.rewardViewport,"BOTTOMRIGHT",0,0)
      view.index=index;view.count=math.min(2,#entries)
      if view.actor then
        view.actor:Hide();view.actor:SetScale(1)
        local ok,accepted=pcall(view.actor.SetModelByFileID,view.actor,decor.asset.id)
        view.failed=not ok or accepted==false
      end
      view.host:Hide()
    end
  end
end
local function updateFurniture(f,elapsed,reveal,alpha)
  local active=false;local island=F.Housing and F.Housing.Island
  for _,view in ipairs(f.furnitureViews or {})do if view.active then
    active=true;view.age=view.age+elapsed
    local width=f.rewardViewport:GetWidth()/view.count
    view.host:ClearAllPoints();view.host:SetPoint("TOPLEFT",f.rewardViewport,"TOPLEFT",(view.index-1)*width,0)
    view.host:SetSize(width,f.rewardViewport:GetHeight())
    if not view.ready and view.actor and island then
      local ok,w,d,h=pcall(function()
        if not view.failed and view.actor:IsLoaded()then return island.ModelBounds(view.actor)end
      end)
      if ok and w then
        local fitted=pcall(island.FitPreview,view.actor,view.scene,w*view.count,d,h)
        if fitted then view.ready=true;view.actor:Show()end
      end
      if not view.ready and not view.pathTried and (view.failed or view.age>1)and view.asset.path then
        view.pathTried=true
        local accepted,result=pcall(view.actor.SetModelByFileID,view.actor,view.asset.path)
        view.failed=not accepted or result==false
      end
    end
    view.host:SetShown(reveal);view.host:SetAlpha(alpha)
    view.icon:SetShown(not view.ready)
    if view.scene then view.scene:SetShown(view.ready)end
  end end
  return active
end
function R.UpdateChest(dt)
  if not R.current and #R.queue==0 then driver:Hide();return end
  local parent,mode=owner()
  if not parent then
    -- Closing every addon view must not swallow an already earned reward alert.
    notify(R.current);for _,opening in ipairs(R.queue)do notify(opening)end
    return
  end
  local f=R.frame or build(parent)
  local high=S.HighContrast()
  f:SetBackdropColor(.025,high and .025 or .02,high and .025 or .035,high and 1 or .94)
  if not R.current then
    R.current=table.remove(R.queue,1);R.age=0;R.waitAge=0;f.sequence=false
    local container=R.current.container or P.CrateModel(nil)
    if f.container~=container then
      f.container=container;f.pathTried=false
      if f.modelReady and not requestChest(f,false)then requestChest(f,true);f.pathTried=true end
    end
    f.fallback:SetTexture("Interface\\Icons\\"..container.icon)
    local item=R.current.result;local color=P.colors[item.rarity] or S.gold
    prepareFurniture(f,item)
    f.rewardColor=color;f.glow:SetVertexColor(unpack(color));f.spark:SetVertexColor(unpack(color));f.rarityGlow:SetVertexColor(unpack(color))
    f.effect=chestEffects[item.rarity] or chestEffects[1]
    f.spellProfile=spellReveals[item.rarity] or spellReveals[1]
    for _,entry in ipairs(f.spells)do entry.started=false;entry.failed=false;entry.fitted=false;entry.actor:Hide()end
    if f.petView.scene then
      f.petView:Sync(item.species and {species=item.species,rarity=item.rarity,rolls=item.rolls} or nil,{},R.current)
      f.petView.scene:Hide()
    end
    for _,ray in ipairs(f.rays)do ray:SetVertexColor(unpack(color))end
    for _,list in ipairs({f.particles,f.rings})do for _,t in ipairs(list)do t:SetVertexColor(unpack(color));t:SetAlpha(0)end end
    f.flash:SetVertexColor(unpack(color));f.flash:SetAlpha(0)
    f:SetBackdropBorderColor(.4,.4,.4,1);f.label:SetTextColor(.9,.9,.9,1)
    f.glow:SetAlpha(0);f.spark:SetAlpha(0);for _,ray in ipairs(f.rays)do ray:SetAlpha(0)end
    if item.species then P.ShowPetPortrait(f.art,{species=item.species,rarity=item.rarity,rolls=item.rolls})
    else
      if P.StyleSparklyPortrait then P.StyleSparklyPortrait(f.art,nil)end
      f.art.cfPortraitDisplay=nil;f.art.cfPortraitRenderer=nil;f.art:SetTexture("Interface\\Icons\\"..(item.icon or "INV_Crate_01"));f.art:SetTexCoord(0,1,0,1);f.art:SetDesaturated(false)
    end
  end
  local size=mode=="large" and 260 or mode=="compact" and 190 or 112
  if f.presentationParent~=parent or f.presentationMode~=mode then
    f.presentationParent=parent;f.presentationMode=mode
    f:SetParent(parent);f:SetFrameLevel(parent:GetFrameLevel()+40);f.hud:SetFrameLevel(f:GetFrameLevel()+4)
    f.rewardViewport:SetFrameLevel(f:GetFrameLevel()+5)
    f.rewardViewport:ClearAllPoints();f.rewardViewport:SetPoint("CENTER",0,size*.065);f.rewardViewport:SetSize(size*.8,size*.66)
    if f.petView.scene then f.petView.scene:SetAllPoints(f.rewardViewport);f.petView.scene:SetFrameLevel(f:GetFrameLevel()+6)end
    if f.modelReady then f.scene:SetFrameLevel(f:GetFrameLevel()+1)end
    f:ClearAllPoints();f:SetPoint("CENTER",mode=="mini" and parent.button or parent,"CENTER",0,mode=="large" and 20 or 0);f:SetSize(size,size)
    f.fallback:SetSize(size*.4,size*.4);f.glow:SetSize(size*.42,size*.18);f.glow:ClearAllPoints();f.glow:SetPoint("CENTER",0,-size*.035)
    f.spark:SetSize(size*.24,size*.24);f.spark:ClearAllPoints();f.spark:SetPoint("CENTER",0,-size*.015)
    f.art:SetSize(size*.55,size*.55);f.art:ClearAllPoints();f.art:SetPoint("CENTER",0,size*.065)
    f.rarityGlow:SetSize(size*.72,size*.60);f.rarityGlow:ClearAllPoints();f.rarityGlow:SetPoint("CENTER",0,size*.065)
  end
  f.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",math.max(mode=="mini" and 11 or 12,S.MinimumTextSize()),"OUTLINE");f.label:SetHeight(size*.28)
  local elapsed=math.max(0,math.min(dt,.1))
  f:SetBackdropBorderColor(high and 1 or .4,high and 1 or .4,high and 1 or .4,1)
  f.label.fwRarity=false;S.TextColor(f.label,{.9,.9,.9})
  f.rarityGlow:SetAlpha(0)
  if f.modelReady and not f.loaded then
    loadedChest(f);R.waitAge=(R.waitAge or 0)+elapsed
    if not f.loaded and R.waitAge>=3 and not f.pathTried then requestChest(f,true);f.pathTried=true end
    if not f.loaded and R.waitAge<8 then
      f.art:Hide();f.glow:SetAlpha(0);f.fallback:Show();f.scene:Show()
      f.label:SetText("Loading "..f.container.label:lower().."...");f:SetAlpha(1);f:Show();return
    end
  end
  -- Contrast changes readability; Reduced Motion alone controls animation.
  R.age=R.age+elapsed/DURATION_SCALE;local age=R.age;local motion=not F.db.settings.reduceMotion
  local sequence=not motion and 149 or age<OPEN_AT and 147 or age<OPENED_AT and 148 or 149
  if f.loaded then
    -- Every crate shakes; higher rarities rock harder without showing color early.
    local strength=f.container.animatedLid and f.effect.shake or math.max(.6,f.effect.shake)
    local shake=motion and age>.2 and age<OPEN_AT and math.sin((age-.2)/(OPEN_AT-.2)*math.pi)*strength or 0
    f.actor:SetYaw(math.pi*1.25+math.sin(age*42)*.065*shake)
    f.actor:SetRoll(math.sin(age*34)*.035*shake)
    -- The wooden world crate has no lid sequence. Give it a small magical
    -- lift/pulse before the burst and reward reveal, using the actual 3D model.
    local pop=not f.container.animatedLid and motion and age>=OPEN_AT and age<OPENED_AT and math.sin((age-OPEN_AT)/(OPENED_AT-OPEN_AT)*math.pi) or 0
    f.actor:SetPosition(math.sin(age*42)*.025*shake,0,pop*.1)
    f.actor:SetScale(f.fittedScale*(1+pop*.08))
  end
  if f.loaded and f.sequence~=sequence then
    f.sequence=sequence;pcall(f.actor.SetAnimation,f.actor,f.container.animatedLid and sequence or 0,0,1/DURATION_SCALE,0)
  end
  if age>=OPEN_AT then soundOnce(R.current,"openSound",44331)end
  if age>=OPENED_AT then soundOnce(R.current,"revealSound",revealSounds[R.current.result.rarity])end
  local reveal=age>=REVEAL_AT
  local chestAlpha=motion and math.max(0,math.min(1,(REVEAL_AT-age)/(REVEAL_AT-FADE_AT))) or (reveal and 0 or 1)
  local petAlpha=motion and math.max(0,math.min(1,(age-REVEAL_AT)/.35)) or 1
  local petReady=false
  if f.petView.scene then
    f.petView:Poll(elapsed);petReady=R.current.result.species~=nil and f.petView:Ready()
    f.petView.scene:SetShown(reveal and petReady);f.petView.scene:SetAlpha(petAlpha)
  end
  local furniture=updateFurniture(f,elapsed,reveal,petAlpha)
  f.art:SetShown(reveal and not petReady and not furniture);f.art:SetAlpha(petAlpha)
  f.fallback:SetShown(not f.loaded and not reveal);f.fallback:SetAlpha(chestAlpha)
  if f.modelReady then f.scene:SetShown(f.loaded and chestAlpha>0);f.scene:SetAlpha(chestAlpha)end
  -- Do not expose rarity until the lid has reached its opened pose.
  local effect=f.effect;local since=age-OPENED_AT
  local burst=since>=0 and (motion and math.min(1,since/.3) or 1)*chestAlpha or 0
  updateSpells(f,since,chestAlpha,motion)
  -- Light the actual chest as well as its spell textures. These ModelScene
  -- controls are local to this widget, not world lighting or graphics CVars.
  if f.modelReady then
    local color=f.rewardColor;local power=burst*effect.flash*(motion and (.9+.1*math.sin(since*3)) or 1)
    f.scene:SetLightAmbientColor(.8-power*.42+color[1]*power*.2,.8-power*.42+color[2]*power*.2,.8-power*.42+color[3]*power*.2)
    f.scene:SetLightDiffuseColor(1-power*(1-color[1]),.95+power*(color[2]-.95),.85+power*(color[3]-.85))
    f.scene:SetLightDirection(-.4,1,-1+power*1.8)
  end
  f.glow:SetAlpha((.35+effect.flash*.6)*burst);f.spark:SetAlpha(effect.flash*burst)
  if motion then f.spark:SetRotation(since*.35)else f.spark:SetRotation(0)end
  for i,ray in ipairs(f.rays)do
    local angle=(i-(effect.rays+1)/2)*.16
    local height=size*effect.height*(1-math.abs(angle)*.2)*math.max(.01,burst)
    local sway=motion and math.sin(since*1.8+i)*.04*burst or 0;angle=angle+sway
    ray:SetSize(size*(i%2==0 and .085 or .12),height);ray:SetRotation(angle)
    ray:ClearAllPoints();ray:SetPoint("CENTER",f,"CENTER",-math.sin(angle)*height*.5,-size*.035+math.cos(angle)*height*.5)
    ray:SetAlpha(i<=effect.rays and burst*(.26+effect.flash*.38) or 0)
  end
  -- A brief mouth burst, expanding spell rings, then rising/outward sparks.
  f.flash:SetSize(size*.6,size*.4);f.flash:ClearAllPoints();f.flash:SetPoint("CENTER",f,"CENTER",0,-size*.035)
  f.flash:SetAlpha(motion and since>=0 and math.max(0,1-since/.55)*effect.flash or 0)
  for i,t in ipairs(f.rings)do
    local time=since-(i-1)*.24;local life=math.max(0,math.min(1,time/1.25))
    t:SetSize(size*(.12+life*.62),size*(.08+life*.35));t:ClearAllPoints();t:SetPoint("CENTER",f,"CENTER",0,-size*.035+life*size*.12)
    t:SetRotation(motion and since*(i%2==0 and -.45 or .45) or 0)
    t:SetAlpha(motion and i<=(effect.rings or 0) and time>=0 and (1-life)*.85*chestAlpha or 0)
  end
  for i,t in ipairs(f.particles)do
    local phase=motion and (math.max(0,since)-((i-1)%7)*.065)%1.6/1.6 or .45
    local angle=((i*2.399963)%math.pi)-math.pi/2
    local distance=size*effect.height*phase
    local x,y=math.sin(angle)*distance*.75,-size*.035+math.cos(angle)*distance
    if i<=(effect.orbit or 0) then
      local spin=i*2.399963+(motion and since*3 or 0)
      x=math.cos(spin)*size*.3*burst;y=-size*.035+phase*size*.36+math.sin(spin)*size*.05
    end
    t:ClearAllPoints();t:SetPoint("CENTER",f,"CENTER",x,y)
    local diameter=size*(.016+(i%3)*.008);t:SetSize(diameter,diameter)
    t:SetAlpha(i<=effect.sparks and since>=(i-1)%7*.065 and burst*math.sin(phase*math.pi)*.9 or 0)
  end
  if reveal then
    S.RarityText(f.label,f.rewardColor)
    f.rarityGlow:SetAlpha(R.current.result.rarity>1 and (high and .22 or .4)*petAlpha or 0)
    notify(R.current)
  elseif R.current.containerRarity then
    S.RarityText(f.label,P.colors[R.current.containerRarity] or S.gold)
  end
  local value=reveal and R.current.result.detail:match("^[^\n]+") or R.current.title
  f.label:SetText(high and value:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","") or value)
  f:SetAlpha(motion and math.max(0,math.min(1,age/.15,(END_AT-age)/.3)) or 1);f:Show()
  if age>=END_AT then f:Hide();R.current=nil;if #R.queue==0 then driver:Hide()end end
end
driver:SetScript("OnUpdate",function(_,dt)if F.ready and P.state then R.UpdateChest(dt)end end)
