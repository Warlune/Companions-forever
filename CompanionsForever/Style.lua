local _, F = ...
local S = {}; F.Style = S
S.gold = {0.94,0.77,0.42}; S.ink = {0.22,0.13,0.07}; S.muted = {0.64,0.68,0.74}
S.panels={}
S.texts={}
-- Keep our windows above the gameplay HUD, but yield to ordinary game panels.
-- Changing only our own strata avoids moving/protecting Blizzard's frames.
local windows,watched={},{}
local panelNames={"WorldMapFrame","AuctionFrame","AuctionHouseFrame","GameMenuFrame","SettingsPanel"}
local panelSlots={"left","center","right","doublewide","fullscreen"}
local function shown(frame)return frame and frame.IsShown and frame:IsShown()end
function S.RefreshWindowLayers()
  local covered=false
  for frame in pairs(watched)do if shown(frame)then covered=true;break end end
  if not covered and GetUIPanel then
    for _,slot in ipairs(panelSlots)do
      if shown(GetUIPanel(slot))then covered=true;break end
    end
  end
  local strata=covered and "LOW" or "HIGH"
  for frame,last in pairs(windows)do
    if last~=strata then frame:SetFrameStrata(strata);windows[frame]=strata end
  end
end
local function watchPanel(frame)
  if not frame or watched[frame] or windows[frame] then return end
  watched[frame]=true
  frame:HookScript("OnShow",S.RefreshWindowLayers)
  frame:HookScript("OnHide",S.RefreshWindowLayers)
end
local function discoverPanels()
  for _,name in ipairs(panelNames)do watchPanel(_G[name])end
  S.RefreshWindowLayers()
end
function S.RegisterWindow(frame,order)
  windows[frame]=false
  -- Leave room for each window's model scenes, HUDs and popup children.
  -- Sharing a root level interleaves children from overlapping windows.
  frame:SetFrameLevel(10+100*((order or 1)-1))
  frame:SetToplevel(false)
  frame:HookScript("OnShow",S.RefreshWindowLayers)
  if not S.windowLayerEvents then
    local events=CreateFrame("Frame");S.windowLayerEvents=events
    events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent",discoverPanels)
    if hooksecurefunc then
      if ShowUIPanel then hooksecurefunc("ShowUIPanel",function(panel)watchPanel(panel);S.RefreshWindowLayers()end)end
      if HideUIPanel then hooksecurefunc("HideUIPanel",S.RefreshWindowLayers)end
    end
  end
  discoverPanels()
end
-- Only the large window opts in. A small visible-only tick also detects when
-- the cursor enters a child control, without replacing its tooltip handlers.
local function readableNumber(value)
  return not (issecretvalue and issecretvalue(value)) and (not canaccessvalue or canaccessvalue(value)) and type(value)=="number"
end
local function screenRect(frame)
  local scale=frame:GetEffectiveScale()
  local l,r,b,t=frame:GetLeft(),frame:GetRight(),frame:GetBottom(),frame:GetTop()
  if readableNumber(scale)and scale>0 and readableNumber(l)and readableNumber(r)and readableNumber(b)and readableNumber(t)then return l*scale,r*scale,b*scale,t*scale end
end
function S.ModelCovered(scene)
  local root=scene
  while root and windows[root]==nil do root=root:GetParent()end
  if not root then return false end
  local l,r,b,t=screenRect(scene);if not l then return false end
  for frame in pairs(windows)do
    if frame~=root and shown(frame)and frame:GetFrameLevel()>root:GetFrameLevel()then
      local fl,fr,fb,ft=screenRect(frame)
      if fl and l<fr and r>fl and b<ft and t>fb then return true end
    end
  end
  return false
end
function S.WatchModelOcclusion(parent,scene)
  -- Overlapping native ModelScenes can leave depth silhouettes through a higher
  -- window. Suspend only the covered 3D scene; keep visibility preferences intact.
  local hidden=false
  local watcher=CreateFrame('Frame',nil,parent);scene.cfOcclusionWatcher=watcher
  watcher:SetScript('OnUpdate',function()
    if S.ModelCovered(scene)then
      if scene:IsShown()then scene:Hide();hidden=true end
    elseif hidden then hidden=false;scene:Show()end
  end)
end
function S.CursorOverWindow(frame)
  -- Use screen coordinates: focus-based hover helpers can miss child models
  -- and controls. Frame bounds are in the frame's effective-scale units.
  if not GetCursorPosition then return true end
  local x,y=GetCursorPosition()
  local scale=frame:GetEffectiveScale()
  local left,right,bottom,top=frame:GetLeft(),frame:GetRight(),frame:GetBottom(),frame:GetTop()
  if not (readableNumber(x) and readableNumber(y) and readableNumber(scale)
    and readableNumber(left) and readableNumber(right) and readableNumber(bottom) and readableNumber(top)) or scale<=0 then return true end
  x,y=x/scale,y/scale
  return x>=left and x<=right and y>=bottom and y<=top
end
function S.EnableMovementFade(frame)
  local elapsed,alpha=0,1
  frame:HookScript("OnHide",function()alpha=1;elapsed=0;frame:SetAlpha(1)end)
  frame:HookScript("OnUpdate",function(self,dt)
    elapsed=elapsed+dt;if elapsed<0.05 then return end
    local step=math.min(elapsed,0.1)*4;elapsed=0
    local speed=GetUnitSpeed and GetUnitSpeed("player")
    local readable=not (issecretvalue and issecretvalue(speed)) and (not canaccessvalue or canaccessvalue(speed))
    local moving=readable and type(speed)=="number" and speed>0
    local hovered=S.CursorOverWindow(self)
    local target=moving and not hovered and not rawget(self,"cfDragging") and 0.25 or 1
    local nextAlpha=target>alpha and math.min(target,alpha+step) or math.max(target,alpha-step)
    if nextAlpha~=alpha then alpha=nextAlpha;self:SetAlpha(alpha)end
  end)
end
function S.HighContrast()
  return F.db and F.db.settings.highContrast
end
-- Rarity is information, not decoration. Keep its hue on the solid dark
-- accessibility background, lifting dark colors to a readable luminance.
function S.RarityColor(color)
  if not S.HighContrast() then return color end
  local function linear(c)return c<=.04045 and c/12.92 or ((c+.055)/1.055)^2.4 end
  local r,g,b=unpack(color)
  for i=1,20 do
    if .2126*linear(r)+.7152*linear(g)+.0722*linear(b)>=.28 then break end
    r=r+(1-r)*.08;g=g+(1-g)*.08;b=b+(1-b)*.08
  end
  return {r,g,b}
end
function S.RarityText(text,color)
  text.fwRarity=true;S.TextColor(text,color)
end
function S.TextColor(text,color)
  text.fwColor=color
  text:SetTextColor(unpack(rawget(text,"fwRarity") and S.RarityColor(color) or S.HighContrast() and {1,1,1} or color))
end
function S.ReadableFont(text,font)
  text.fwFont=font
  text:SetFontObject(font)
  -- SetFont overrides survive SetFontObject on the client. Read the shared
  -- source font rather than the label's previously enlarged font.
  local source=_G[font]
  local path,size,flags
  if source and source.GetFont then path,size,flags=source:GetFont()
  else path,size,flags=text:GetFont()end
  if path and size and F.db then
    text:SetFont(path,math.max(size,S.MinimumTextSize()),flags)
  end
end
function S.MinimumTextSize()
  local size=tonumber(F.db and F.db.settings.textSize)
  if size==12 or size==13 or size==14 or size==16 then return size end
  return 0
end
function S.Faction()
  return UnitFactionGroup("player")
end
function S.ApplyTheme()
  local theme=S.Theme()
  for _,panel in ipairs(S.panels)do
    panel:SetBackdropColor(unpack(theme.panel))
    if rawget(panel,"paper") then panel.paper:SetShown(not S.HighContrast())end
    panel:SetBackdropBorderColor(unpack(S.HighContrast() and {0.8,0.8,0.8,1} or {0.29,0.32,0.38,1}))
  end
  for _,text in ipairs(S.texts)do
    S.ReadableFont(text,text.fwFont)
    S.TextColor(text,text.fwColor)
  end

end
function S.Theme()
  if S.HighContrast() then
    return {bg={0.025,0.025,0.025,1},panel={0.035,0.035,0.035,1},accent={0.22,0.22,0.22,1},fade={0.04,0.04,0.04,1},crest=S.Faction()=="Alliance" and "Interface\\Timer\\Alliance-Logo" or "Interface\\Timer\\Horde-Logo"}
  end
  if S.Faction()=="Alliance" then
    return {bg={0.065,0.071,0.080,1},panel={0.07,0.085,0.11,1},accent={0.26,0.32,0.37,1},fade={0.08,0.092,0.11,1},crest="Interface\\Timer\\Alliance-Logo"}
  end
  return {bg={0.09,0.075,0.055,1},panel={0.085,0.08,0.10,1},accent={0.55,0.20,0.14,1},crest="Interface\\Timer\\Horde-Logo"}
end
function S.Text(parent, text, x, y, width, font, color)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
  t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetText(text or "")
  t.fwFont=font or "GameFontHighlight"
  S.ReadableFont(t,t.fwFont)
  S.TextColor(t,color or {1,1,1})
  S.texts[#S.texts+1]=t
  return t
end
function S.Panel(parent, x, y, w, h, parchment)
  local p=CreateFrame("Frame",nil,parent,"BackdropTemplate");p:SetPoint("TOPLEFT",x,y);p:SetSize(w,h)
  p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",tile=true,tileSize=32,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
  p:SetBackdropColor(unpack(S.Theme().panel))
  S.panels[#S.panels+1]=p
  p:SetBackdropBorderColor(0.29,0.32,0.38,1)
  local solid=p:CreateTexture(nil,"BACKGROUND",nil,-8);solid:SetPoint("TOPLEFT",4,-4);solid:SetPoint("BOTTOMRIGHT",-4,4);solid:SetColorTexture(0.04,0.047,0.06,0.97)
  if parchment then
    local tex=p:CreateTexture(nil,"BACKGROUND",nil,1);tex:SetPoint("TOPLEFT",5,-5);tex:SetPoint("BOTTOMRIGHT",-5,5)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("QuestBG-Parchment") then tex:SetAtlas("QuestBG-Parchment")
    else tex:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal") end
    p.paper=tex
    tex:SetShown(not S.HighContrast())
  end
  return p
end
function S.Button(parent, text, x, y, w, fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,26);b:SetText(text);b:SetScript("OnClick",fn)
  local label=b:GetFontString()
  if label then
    label.fwFont="GameFontNormal";S.ReadableFont(label,label.fwFont);S.TextColor(label,S.gold);S.texts[#S.texts+1]=label
  end
  return b
end
-- Shared selection menu: only one can be open, and hiding its owner closes it.
function S.Dropdown(parent,text,x,y,width,options,current,selectValue)
  local button
  button=S.Button(parent,text,x,y,width,function()
    local popup=S.selectionMenu
    if not popup then
      popup=CreateFrame("Frame","CompanionsForeverSelectionMenu",UIParent)
      S.selectionMenu=popup;popup:SetAllPoints(UIParent);popup:SetFrameStrata("FULLSCREEN_DIALOG");popup:SetFrameLevel(200)
      popup:EnableMouse(true);popup:SetScript("OnMouseDown",function(self)self:Hide()end)
      UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverSelectionMenu"
      popup.menu=CreateFrame("Frame",nil,popup,"BackdropTemplate");popup.menu:EnableMouse(true);popup.menu:SetClampedToScreen(true)
      popup.menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
      popup.rows={};popup:Hide()
    end
    if popup:IsShown() and popup.owner==button then popup:Hide();return end
    GameTooltip:Hide();popup.owner=button
    local menu=popup.menu;local rowHeight=math.max(30,S.MinimumTextSize()+16)
    local menuWidth=math.max(width,260);local height=#options*rowHeight+12
    local scale=button:GetEffectiveScale();local rootScale=UIParent:GetEffectiveScale()
    if type(scale)=="number" and type(rootScale)=="number" and rootScale>0 then menu:SetScale(scale/rootScale)else scale=1 end
    menu:SetSize(menuWidth,height);menu:ClearAllPoints()
    local bottom=button:GetBottom()
    if type(bottom)=="number" and bottom<height+8 then menu:SetPoint("BOTTOMLEFT",button,"TOPLEFT",0,2)
    else menu:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-2)end
    menu:SetBackdropColor(.025,.025,.025,1);menu:SetBackdropBorderColor(unpack(S.HighContrast() and {1,1,1,1} or {.65,.55,.35,1}))
    for i,option in ipairs(options)do
      local row=popup.rows[i]
      if not row then
        row=CreateFrame("Button",nil,menu);popup.rows[i]=row
        row.label=S.Text(row,"",30,0,menuWidth-42,"GameFontHighlight",{1,1,1})
        row.check=row:CreateTexture(nil,"OVERLAY");row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");row.check:SetPoint("LEFT",4,0);row.check:SetSize(22,22)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
      end
      local value=option[1]
      row:ClearAllPoints();row:SetPoint("TOPLEFT",6,-6-(i-1)*rowHeight);row:SetSize(menuWidth-12,rowHeight)
      row.label:SetWidth(menuWidth-48);row.label:SetHeight(rowHeight);row.label:SetText(option[2]);S.ReadableFont(row.label,"GameFontHighlight")
      row.check:SetShown(current()==value)
      row:SetScript("OnClick",function()popup:Hide();selectValue(value)end);row:Show()
    end
    for i=#options+1,#popup.rows do popup.rows[i]:Hide()end
    popup:Show()
  end)
  local label=button:GetFontString();if label then label:ClearAllPoints();label:SetPoint("LEFT",8,0);label:SetPoint("RIGHT",-26,0)end
  button.arrow=button:CreateTexture(nil,"OVERLAY");button.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up");button.arrow:SetPoint("RIGHT",-3,0);button.arrow:SetSize(20,20)
  button:HookScript("OnHide",function()local popup=S.selectionMenu;if popup and popup.owner==button then popup:Hide()end end)
  return button
end
function S.Check(parent,text,x,y,key)
  local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(26,26)
  S.Text(b,text,32,-6,360,"GameFontHighlight")
  b:SetScript("OnShow",function(self)self:SetChecked(F.db.settings[key])end)
  b:SetScript("OnClick",function(self) F.db.settings[key]=not not self:GetChecked();F.ApplySettings() end)
  return b
end
