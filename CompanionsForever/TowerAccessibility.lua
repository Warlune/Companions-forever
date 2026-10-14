local _,F=...
local P,H=F.Pets,F.Pets.HardMode
local function hide(f)
  for _,bar in ipairs(rawget(f,"petHeadHealth") or {})do bar:Hide()end
end
local function place(f,bar,index)
  local arena=f.arena;local scene=arena and arena.scene
  local state=arena and arena.states[1-index]
  if scene and state and state.loaded and scene.Project3DPointTo2D then
    local x,y,z=state.visualX or state.x,state.y or 0,state.height or 2
    -- Native actor coordinates include its current movement. Translation is
    -- scaled with the actor; the grounded model height is in scene units.
    if state.actor and state.actor.GetPosition then
      local ok,ax,ay,az=pcall(state.actor.GetPosition,state.actor)
      if ok and type(ax)=="number" and type(ay)=="number" and type(az)=="number"then
        local scale=state.scale or 1
        x,y,z=ax*scale,ay*scale,az*scale+(state.height or 2)-(state.z or 0)
      end
    end
    local ok,px,py=pcall(scene.Project3DPointTo2D,scene,x,y,z)
    if ok and type(px)=="number" and type(py)=="number" and px==px and py==py then
      local width,height=scene:GetWidth(),scene:GetHeight()
      -- Do not pin the bar to the window edge if its pet leaves the view.
      if px<0 or px>width or py<0 or py>height then bar:Hide();return end
      if bar.anchorTarget~=scene or bar.anchorX~=px or bar.anchorY~=py then
        bar:ClearAllPoints();bar:SetPoint("BOTTOM",scene,"BOTTOMLEFT",px,py+6)
        bar.anchorTarget=scene;bar.anchorX=px;bar.anchorY=py
      end
      bar:Show();return
    end
  end
  -- If the model is still loading, attach to the displayed portrait rather
  -- than inventing a fixed position in the battle window.
  local art=index==1 and f.pet or rawget(f,"hardFallback") and f.hardFallback[index]
  if art and art:IsShown()then
    if bar.anchorTarget~=art then
      bar:ClearAllPoints();bar:SetPoint("BOTTOM",art,"TOP",0,6)
      bar.anchorTarget=art;bar.anchorX=nil;bar.anchorY=nil
    end
    bar:Show()
  else bar:Hide()end
end
function P.UpdatePetHeadHealthPositions(f)
  if not f.tower or not F.db.settings.towerPetHealthBars then hide(f);return end
  for i,bar in ipairs(rawget(f,"petHeadHealth") or {})do
    if bar.pet then place(f,bar,i)else bar:Hide()end
  end
end
local function update(f)
  if not f.tower or not F.db.settings.towerPetHealthBars then hide(f);return end
  local arena=f.arena;local scene=arena and arena.scene
  if not scene then hide(f);return end
  local width,height=scene:GetWidth(),scene:GetHeight()
  if width<=0 or height<=0 then hide(f);return end
  if not rawget(f,"petHeadHealth")then f.petHeadHealth={}end
  local team=H.Team()
  for i=1,3 do
    local pet=team[i];local bar=f.petHeadHealth[i]
    if pet then
      if not bar then
        bar=CreateFrame("StatusBar",nil,f.hud,"BackdropTemplate");f.petHeadHealth[i]=bar
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        bar:SetBackdropColor(.55,.035,.025,1);bar:SetBackdropBorderColor(.04,.04,.04,1)
        bar:EnableMouse(false)
        bar.amount=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        bar.amount:SetPoint("BOTTOM",bar,"TOP",0,1);bar.amount:SetJustifyH("CENTER");bar.amount:SetTextColor(1,1,1)
      end
      local font=math.max(12,math.min(20,tonumber(F.db.settings.textSize) or 12))
      local bw=math.min(width-8,math.max(76,font*6));local bh=math.max(7,math.floor(font*.6))
      bar:SetSize(bw,bh);bar.amount:SetSize(math.max(bw,font*10),font+4)
      bar.amount:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",font,"OUTLINE")
      bar.pet=pet
      local hp,maxHP=H.Health(pet,true)
      bar:SetMinMaxValues(0,maxHP);bar:SetValue(hp)
      if hp>0 and hp/maxHP<.25 then bar:SetStatusBarColor(.85,.08,.05)else bar:SetStatusBarColor(.05,.65,.12)end
      bar.amount:SetText(math.ceil(hp).." / "..math.ceil(maxHP));place(f,bar,i)
    elseif bar then bar.pet=nil;bar:Hide()end
  end
end
local refresh=P.HardRefreshScene
P.HardRefreshScene=function(f)refresh(f);update(f)end
